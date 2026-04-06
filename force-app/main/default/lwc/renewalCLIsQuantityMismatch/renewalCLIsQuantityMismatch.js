import { LightningElement, wire, track } from 'lwc';
import getSobjectList from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';

const columns = [
    {
        label: 'CLI', fieldName: 'CLIURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Id'
            }
        }
    },
    {
        label: 'OI #', fieldName: 'OiURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Oi'
            }
        }
    },
    {
        label: 'QLI #', fieldName: 'QliURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Qli'
            }
        }
    },
    {
        label: 'Original Quantity', fieldName: 'SBQQSC__Quantity__c', type: 'text', initialWidth: 150
    },
    {
        label: 'Renewed Quantity', fieldName: 'QuantEntLinksQuantDiff', type: 'text', initialWidth: 165
    },
    {
        label: 'Renewal Quantity', fieldName: 'SBQQSC__RenewalQuantity__c', type: 'text', initialWidth: 150
    },
    {
        label: 'Start Date', fieldName: 'StartDate', type: 'date',
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    },
    {
        label: 'End Date', fieldName: 'EndDate', type: 'date',
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    },
    {
        label: 'Line Type', fieldName: 'LineType', type: 'text'
    }
];

export default class RenewalCLIsQuantityMismatch extends LightningElement {

    columns = columns;
    clisData = [];
    error;
    clisMap = new Map();
    @track renClisQtMiMatchDisplayData = [];
    @track renCLIsQuantMismatch = [];
    @track startDate;
    @track endDate;
    @track endDateError = '';
    showTable = false;
    disableFilterBTN = false;
    errorMsg = '';

    connectedCallback() {
        this.calculateQuarterDates();
        this.handleFilterClick();
    }

    calculateQuarterDates() {
        const today = new Date();
        const currentMonthNumber = today.getMonth();

        let QAStartMonth;
        if (currentMonthNumber >= 2 && currentMonthNumber <= 4) { // February - April
            QAStartMonth = 2; // February
        } else if (currentMonthNumber >= 5 && currentMonthNumber <= 7) { // May - July
            QAStartMonth = 5; // May
        } else if (currentMonthNumber >= 8 && currentMonthNumber <= 10) { // August - October
            QAStartMonth = 8; // August
        } else { // November - January
            QAStartMonth = 11; // November
        }
        console.log('QAStartMonth', QAStartMonth);
        const qtStartDate = new Date(today.getFullYear(), QAStartMonth - 1, 1);
        const qtEndDate = new Date(today.getFullYear(), QAStartMonth + 2, 0);
        const offset = today.getTimezoneOffset();
        this.startDate = new Date(qtStartDate.getTime() - offset * 60000).toISOString().split('T')[0];
        this.endDate = new Date(qtEndDate.getTime() - offset * 60000).toISOString().split('T')[0];
    }

    validateDates(event) {
        const { label, value } = event.target;

        if (label === 'Start Date') {
            this.startDate = value;
        } else if (label === 'End Date') {
            this.endDate = value;
        }

        if (this.endDate < this.startDate) {
            this.endDateError = 'The End Date should not be lesser than the Start Date';
            this.disableFilterBTN = true;
        } else {
            this.endDateError = '';
            this.disableFilterBTN = false;
        }
    }

    handleFilterClick() {
        this.findRenewalCLIs();
    }

    findRenewalCLIs() {
        var theDateFilterQuery = 'SELECT Id,StartDate, EndDate, SBQQSC__RenewalQuantity__c,SBQQSC__Quantity__c,SBQQSC__OrderProduct__c,SBQQSC__OrderProduct__r.Product_Name__c,SBQQSC__OrderProduct__r.Line_Type__c,SBQQSC__QuoteLine__c, SBQQSC__QuoteLine__r.Name, (SELECT Id From Entitlements) FROM ContractLineItem Where ((StartDate >= ' + this.startDate + ' and StartDate <= ' + this.endDate + ')  or (EndDate >= ' + this.startDate + ' and EndDate <= ' + this.endDate + ')) ORDER BY StartDate DESC';
        this.renCLIsQuantMismatch = [];
        this.renClisQtMiMatchDisplayData = [];
        getSobjectList({ theQuery: theDateFilterQuery })
            .then(result => {
                this.clisData = JSON.parse(JSON.stringify(result));
                console.log('result length : ', result.length);
                var entIds = [];
                for (var i in result) {
                    for (var j in result[i].Entitlements) {
                        entIds.push(result[i].Entitlements[j].Id);
                    }
                }
                if (!(Array.isArray(entIds) && entIds.length === 0)) {
                    var theEntQuery = 'SELECT Id,ContractLineItemId, (SELECT Id,Quantity__c FROM Entitlement_Links__r) From Entitlement Where Id IN (\'' + entIds.join('\',\'') + '\')'
                    this.validateCLIRenewalQuant(theEntQuery)
                }
            })
            .catch((error) => {
                console.log('An error occurred:', error.body.message);
                this.errorMsg = error.body.message;
            });
    }

    validateCLIRenewalQuant(theEntQuery) {
        getSobjectList({ theQuery: theEntQuery })
            .then(result => {
                if (result.length !== 0) {
                    for (var i in result) {
                        if (result[i].Entitlement_Links__r != undefined) {
                            var quant = 0;
                            for (var j in result[i].Entitlement_Links__r) {
                                if (result[i].Entitlement_Links__r[j].Quantity__c != undefined) {
                                    quant += result[i].Entitlement_Links__r[j].Quantity__c;
                                }
                            }
                            if (!(this.clisMap.has(result[i].ContractLineItemId))) {
                                this.clisMap.set(result[i].ContractLineItemId, quant);
                            }
                            else {
                                var entLinksSize = this.clisMap.get(result[i].ContractLineItemId);
                                entLinksSize += quant;
                                this.clisMap.set(result[i].ContractLineItemId, entLinksSize);
                            }
                        }
                        else {
                            if (!(this.clisMap.has(result[i].ContractLineItemId))) {
                                this.clisMap.set(result[i].ContractLineItemId, 0);
                            }
                        }
                    }

                    this.clisData.forEach((cli) => {
                        console.log('cli id: ' + cli.Id);
                        let tempEntLinksQuant = this.clisMap.get(cli.Id) != undefined ? this.clisMap.get(cli.Id) : 0;
                        if (cli.SBQQSC__RenewalQuantity__c != cli.SBQQSC__Quantity__c - tempEntLinksQuant) {
                            cli.CLIURL = '/' + cli.Id;
                            if (cli && cli.SBQQSC__OrderProduct__c) {
                                cli.OiURL = '/' + cli.SBQQSC__OrderProduct__c;
                            }
                            if (cli && cli.SBQQSC__OrderProduct__r && cli.SBQQSC__OrderProduct__r.Product_Name__c) {
                                cli.Oi = cli.SBQQSC__OrderProduct__r.Product_Name__c;
                            }
                            if (cli && cli.SBQQSC__QuoteLine__c) {
                                cli.QliURL = '/' + cli.SBQQSC__QuoteLine__c;
                            }
                            if (cli && cli.SBQQSC__QuoteLine__r && cli.SBQQSC__QuoteLine__r.Name) {
                                cli.Qli = cli.SBQQSC__QuoteLine__r.Name;
                            }
                            let entLinksQuant = this.clisMap.get(cli.Id) != undefined ? this.clisMap.get(cli.Id) : 0;
                            let originalQuantity = cli.SBQQSC__Quantity__c != undefined ? cli.SBQQSC__Quantity__c : 0;
                            cli.QuantEntLinksQuantDiff = originalQuantity - entLinksQuant;
                            if (cli && cli.SBQQSC__OrderProduct__r && cli.SBQQSC__OrderProduct__r.Line_Type__c) {
                                cli.LineType = cli.SBQQSC__OrderProduct__r.Line_Type__c;
                            }
                            this.renCLIsQuantMismatch = [...this.renCLIsQuantMismatch, cli];
                        }
                    })

                    this.renClisQtMiMatchDisplayData = this.renCLIsQuantMismatch;
                    if (this.renClisQtMiMatchDisplayData.length > 0) this.showTable = true;
                }
            })
            .catch((error) => {
                console.log('An error occurred:', error);
            });
    }
}