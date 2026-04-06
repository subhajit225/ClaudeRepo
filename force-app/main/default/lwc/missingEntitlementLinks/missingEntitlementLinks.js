import { LightningElement, wire, track } from 'lwc';
import getEntList from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';

const columns = [
    {
        label: 'Name', fieldName: 'EntitlementURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Name'
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
    },
    {
        label: 'Reason', fieldName: 'Reason', type: 'text', wrapText: true, initialWidth: 350
    },

];

export default class MissingEntitlementLinks extends LightningElement {

    @track missingEntLinksDataDisplay = [];
    @track missingEntLinksData = [];
    @track startDate;
    @track endDate;
    @track endDateError = '';
    clisWithAssets = new Map();
    columns = columns;
    showTable = false;
    disableFilterBTN = false;

    connectedCallback() {
        this.getQuarterDates();
        this.onFilterClick();
    }

    getQuarterDates() {
        // const today = new Date();
        // const quarterStartMonth = (Math.floor(today.getMonth() / 3) * 3) +1; // Adding 1 month extra as Rubrik's Fiscal year's starts from May
        // const STDT = new Date(today.getFullYear(), quarterStartMonth, 1);
        // const ENDT = new Date(today.getFullYear(), quarterStartMonth + 3, 0);

        const today = new Date();
        const currentMonth = today.getMonth();

        let QTStartMonth;
        if (currentMonth >= 2 && currentMonth <= 4) { // February - April
            QTStartMonth = 2; // February
        } else if (currentMonth >= 5 && currentMonth <= 7) { // May - July
            QTStartMonth = 5; // May
        } else if (currentMonth >= 8 && currentMonth <= 10) { // August - October
            QTStartMonth = 8; // August
        } else { // November - January
            QTStartMonth = 11; // November
        }
        console.log('QTStartMonth', QTStartMonth);
        const qtSTDate = new Date(today.getFullYear(), QTStartMonth - 1, 1);
        const qtENDDate = new Date(today.getFullYear(), QTStartMonth + 2, 0);

        const offset = today.getTimezoneOffset();
        this.startDate = new Date(qtSTDate.getTime() - offset * 60000).toISOString().split('T')[0];
        this.endDate = new Date(qtENDDate.getTime() - offset * 60000).toISOString().split('T')[0];
    }

    validateStartEndDates(event) {
        // console.log('inside validateStartEndDates');
        const { label, value } = event.target;

        if (label === 'End Date') {
            this.endDate = value;
        } else if (label === 'Start Date') {
            this.startDate = value;
        }

        if (this.endDate < this.startDate) {
            this.disableFilterBTN = true;
            this.endDateError = 'The End Date should not be lesser than the Start Date';
        } else {
            this.disableFilterBTN = false;
            this.endDateError = '';
        }
    }

    onFilterClick() {
        this.identifyMissingENTLinks();
    }

    identifyMissingENTLinks() {
        var dateFilterQuery = 'SELECT Id,Name,StartDate,EndDate,Product__r.name,Order_Service_Item__r.OrderItemNumber, Order_Quantity__c,Quantity__c,Order_Service_Item__r.Previous_Contract_Line_Items__c,Order_Service_Item__r.SerialNumber__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c, Order_Service_Item__r.Program__c,Order_Service_Item__r.Line_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c,Order_Service_Item__r.SBQQ__QuoteLine__c, Order_Service_Item__r.SBQQ__QuoteLine__r.Name,Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,Order_Service_Item__r.order.Order_Sub_Type__c,Product__r.Product_Level__c,Product__r.Product_Type__c,Product__r.Product_Subtype__c,Product__r.License_Category__c,Order_Service_Item__r.order.SD_Status__c,Order_Service_Item__r.order.ProcessType__c,Order_Service_Item__r.product2.Family,Assetid,ContractLineItemId,Asset.name,Product__r.Family,CreatedDate,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,Order_Service_Item__r.SBQQ__RequiredBy__r.product2.Product_Type__c,Order_Service_Item__r.SBQQ__RequiredBy__r.product2.Item_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Item_Type__c,(SELECT id from Entitlement_Links1__r), (SELECT id,Asset__r.Product2.Usable_Capacity__c FROM Scale_Entitlements__r) FROM entitlement WHERE Order_Service_Item__r.order.Is_RWD_Polaris_Quote__c = true and (Order_Service_Item__r.order.Order_Sub_Type__c = \'Renewal\' or Order_Service_Item__r.Program__c = \'Conversion\' or Order_Service_Item__r.Program__c = \'Replaced\') and Order_Service_Item__r.product2.name != \'RS-BT-RCDM-T\' and Type =\'Phone Support\' and ContractLineItem.Product_Category__c !=\'Virtual Addon\' and ((StartDate >= ' + this.startDate + ' and StartDate <= ' + this.endDate + ')  or (EndDate >= ' + this.startDate + ' and EndDate <= ' + this.endDate + ')) ORDER BY StartDate DESC';
        this.missingEntLinksData = [];
        this.missingEntLinksDataDisplay = [];
        getEntList({ theQuery: dateFilterQuery })
            .then(result => {
                result = JSON.parse(JSON.stringify(result));
                console.log('result data : ', JSON.stringify(result));
                this.validateOISerialNumPrevCLIs(result)
                    .then(() => this.vaidateOtherConditions(result))
                    .catch((error) => {
                        // console.error('An error occurred:', error);
                    });
            })
    }

    async validateOISerialNumPrevCLIs(data) {
        return new Promise((resolve, reject) => {
            var cliIds = [];
            data.forEach((ent) => {
                if (ent && ent.Order_Service_Item__r && ent.Order_Service_Item__r.Previous_Contract_Line_Items__c) {
                    var prevCliArr = ent.Order_Service_Item__r.Previous_Contract_Line_Items__c.split(",").map(function (value) {
                        return value.trim();
                    });
                }
                for (var i in prevCliArr) {
                    cliIds.push(prevCliArr[i]);
                }
            })

            if (!(Array.isArray(cliIds) && cliIds.length === 0)) {
                console.log('cliIds : ', JSON.stringify(cliIds));
                var theEntiQuery = 'SELECT Id, ContractLineItemId, Asset.Name from Entitlement Where ContractLineItemId IN (\'' + cliIds.join('\',\'') + '\')'

                getEntList({ theQuery: theEntiQuery })
                    .then(result => {
                        console.log('result length : ', result.length);
                        for (var i in result) {
                            if (!(this.clisWithAssets.has(result[i].ContractLineItemId))) {
                                var asstName = [];
                                if (result[i] && result[i].Asset && result[i].Asset.Name) {
                                    asstName.push(result[i].Asset.Name);
                                    this.clisWithAssets.set(result[i].ContractLineItemId, asstName);
                                }
                                else {
                                    this.clisWithAssets.set(result[i].ContractLineItemId, asstName);
                                }
                            }
                            else {
                                if (result[i] && result[i].Asset && result[i].Asset.Name) {
                                    var tempAssetsArr = this.clisWithAssets.get(result[i].ContractLineItemId);
                                    tempAssetsArr = [...tempAssetsArr, result[i].Asset.Name]
                                    this.clisWithAssets.set(result[i].ContractLineItemId, tempAssetsArr);
                                }
                            }
                        }

                        data.forEach((ent) => {
                            if (ent.Entitlement_Links1__r == undefined) {
                                var prevCliArr = [];
                                var serialNumArr = [];
                                if (ent && ent.Order_Service_Item__r && ent.Order_Service_Item__r.Previous_Contract_Line_Items__c) {
                                    prevCliArr = ent.Order_Service_Item__r.Previous_Contract_Line_Items__c.split(",").map(function (value) {
                                        return value.trim();
                                    });
                                }
                                if (ent && ent.Order_Service_Item__r && ent.Order_Service_Item__r.SerialNumber__c) {
                                    serialNumArr = ent.Order_Service_Item__r.SerialNumber__c.split(",").map(function (value) {
                                        return value.trim();
                                    });
                                }
                                console.log('prevCliArr : ', prevCliArr);
                                console.log('serialNumArr: ', serialNumArr);
                                var prevCLIsAllAssets = [];
                                for (var i in prevCliArr) {
                                    if (this.clisWithAssets.get(prevCliArr[i]) != undefined) {
                                        var tempArry = this.clisWithAssets.get(prevCliArr[i]);
                                        console.log('tempArry : ', JSON.stringify(tempArry));
                                        for (var j in tempArry) {
                                            console.log('j: ' + tempArry[j]);
                                            prevCLIsAllAssets.push(tempArry[j]);
                                        }
                                    }
                                }

                                var unmatchedOISerialNumbers = '';
                                if (!(serialNumArr == undefined && prevCliArr == undefined)) {
                                    for (var i in serialNumArr) {
                                        if (!prevCLIsAllAssets.includes(serialNumArr[i])) {
                                            console.log('Not include');
                                            if (unmatchedOISerialNumbers.length == 0) {
                                                unmatchedOISerialNumbers = serialNumArr[i];
                                            }
                                            else {
                                                unmatchedOISerialNumbers = unmatchedOISerialNumbers + ',' + serialNumArr[i];
                                            }
                                        }
                                    }
                                }
                                let tempEnt = { EntitlementURL: '', Name: '', OiURL: '', Oi: '', QliURL: '', Qli: '', LineType: '', Reason: '', StartDate: '', EndDate: '' };
                                if (unmatchedOISerialNumbers.length > 0) {
                                    tempEnt.EntitlementURL = '/' + ent.Id;
                                    tempEnt.Name = ent.Name;
                                    tempEnt.StartDate = ent.StartDate;
                                    tempEnt.EndDate = ent.EndDate;
                                    tempEnt.OiURL = '/' + ent.Order_Service_Item__c;
                                    tempEnt.Oi = ent.Order_Service_Item__r.OrderItemNumber;
                                    tempEnt.QliURL = '/' + ent.Order_Service_Item__r.SBQQ__QuoteLine__c;
                                    tempEnt.Qli = ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Name;
                                    tempEnt.LineType = ent.Order_Service_Item__r.Line_Type__c
                                    tempEnt.Reason = unmatchedOISerialNumbers + ' not present in the previous clis.';
                                    this.missingEntLinksData = [...this.missingEntLinksData, tempEnt];
                                }
                            }
                        })
                        resolve();
                    })
            }
        });
    }

    async vaidateOtherConditions(data) {
        return new Promise((resolve, reject) => {

            data.forEach((ent) => {

                if (ent.Entitlement_Links1__r == undefined) {
                    if (ent.Product__r.Family == 'Rubrik Scale') {
                        return;
                    }
                    let tempEnt = { EntitlementURL: '', Name: '', OiURL: '', Oi: '', QliURL: '', Qli: '', LineType: '', Reason: '', StartDate: '', EndDate: '' };
                    tempEnt.EntitlementURL = '/' + ent.Id;
                    tempEnt.Name = ent.Name;
                    tempEnt.StartDate = ent.StartDate;
                    tempEnt.EndDate = ent.EndDate;
                    tempEnt.OiURL = '/' + ent.Order_Service_Item__c;
                    tempEnt.Oi = ent.Order_Service_Item__r.OrderItemNumber;
                    tempEnt.QliURL = '/' + ent.Order_Service_Item__r.SBQQ__QuoteLine__c;
                    tempEnt.Qli = ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Name;
                    tempEnt.LineType = ent.Order_Service_Item__r.Line_Type__c
                    this.missingEntLinksData = [...this.missingEntLinksData, tempEnt];
                }

                var productVar = ent && ent.Product__r;

                if ((!(productVar && (ent.Product__r.Product_Subtype__c && ent.Product__r.Product_Subtype__c == 'Scale MSP') &&
                    (ent && ent.Product__r && ent.Product__r.License_Category__c && ent.Product__r.License_Category__c == null))) &&
                    (ent && ent.Order_Service_Item__r && ent.Order_Service_Item__r.product2 && ent.Order_Service_Item__r.product2.Family && ent.Order_Service_Item__r.product2.Family != 'Third Party License') &&
                    ((productVar && ent.Product__r.Product_Level__c && ent.Product__r.Product_Level__c == 'Hybrid Software') ||
                        ((productVar && ent.Product__r.Product_Level__c && ent.Product__r.Product_Level__c == 'OnPrem') &&
                            ((productVar && ent.Product__r.Product_Type__c && ent.Product__r.Product_Type__c == 'Foundation Edition') ||
                                (productVar && ent.Product__r.Product_Type__c && ent.Product__r.Product_Type__c == 'Business Edition') ||
                                (productVar && ent.Product__r.Product_Type__c && ent.Product__r.Product_Type__c == 'Enterprise Edition')) &&
                            (productVar && ent.Product__r.Product_Subtype__c && ent.Product__r.Product_Subtype__c == null)) ||
                        (productVar && ent.Product__r.Product_Level__c && ent.Product__r.Product_Level__c == 'LOD Software')) &&
                    (productVar && ent.Product__r.Product_Subtype__c && ent.Product__r.Product_Subtype__c != 'RCDM') &&
                    (productVar && ent.Product__r.Product_Subtype__c && ent.Product__r.Product_Subtype__c != 'Virtual') &&
                    (productVar && ent.Product__r.Family && ent.Product__r.Family != 'Rubrik Scale')) {

                    if (!(ent && ent.Scale_Entitlements__r && ent.Scale_Entitlements__r.isEmpty())) {
                        var Capacity = 0.0;
                        for (var i in ent.Scale_Entitlements__r) {
                            if (ent && ent.Scale_Entitlements__r[i] && ent.Scale_Entitlements__r[i].Asset__r && ent.Scale_Entitlements__r[i].Asset__r.Product2 && ent.Scale_Entitlements__r[i].Asset__r.Product2.Usable_Capacity__c && ent.Scale_Entitlements__r[i].Asset__r.Product2.Usable_Capacity__c != null) {
                                Capacity += ent.Scale_Entitlements__r[i].Asset__r.Product2.Usable_Capacity__c;
                            }
                        }
                        if (ent && ent.Order_Quantity__c && ent.Order_Quantity__c != Capacity) {
                            let tempEnt1 = { EntitlementURL: '', Name: '', OiURL: '', Oi: '', QliURL: '', Qli: '', LineType: '', Reason: '', StartDate: '', EndDate: '' };
                            tempEnt1.EntitlementURL = '/' + ent.Id;
                            tempEnt1.Name = ent.Name;
                            tempEnt1.StartDate = ent.StartDate;
                            tempEnt1.EndDate = ent.EndDate;
                            tempEnt1.OiURL = '/' + ent.Order_Service_Item__c;
                            tempEnt1.Oi = ent.Order_Service_Item__r.OrderItemNumber;
                            tempEnt1.QliURL = '/' + ent.Order_Service_Item__r.SBQQ__QuoteLine__c;
                            tempEnt1.Qli = ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Name;
                            tempEnt1.LineType = ent.Order_Service_Item__r.Line_Type__c
                            this.missingEntLinksData = [...this.missingEntLinksData, tempEnt1];
                        }
                    }
                }
            })
            this.missingEntLinksDataDisplay = this.missingEntLinksData;
            if (this.missingEntLinksDataDisplay.length > 0) this.showTable = true;
            resolve();
        });
    }
}