import { LightningElement } from 'lwc';
import getSobjectList from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';

const columns = [
    {
        label: 'Asset',
        fieldName: 'assetURL',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'assetName',
            },
        },
    },
    {
        label: 'Order Product',
        fieldName: 'OIURL',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'OINumber',
            }
        }
    },
    {
        label: 'OP Quantity',
        fieldName: 'OIQuant',
        type: 'number',
        cellAttributes: { alignment: 'center' }
    },
    {
        label: 'Entitlement',
        fieldName: 'entURL',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'productName'
            }
        }
    },
    {
        label: 'ENT Status',
        fieldName: 'Status',
        type: 'text'
    },
    {
        label: 'Service Contract',
        fieldName: 'SCURL',
        type: 'url',
        wrapText: true,
        typeAttributes: {
            label: {
                fieldName: 'SCName',
            },
        },
    },
    {
        label: 'Contract Line Item',
        fieldName: 'CLIURL',
        type: 'url',
    },
    { label: 'Notes', fieldName: 'Notes', type: 'text'},
    { label: 'Start Date', fieldName: 'StartDate', type: 'text' },
    { label: 'End Date', fieldName: 'EndDate', type: 'text' },
    { label: 'Issue Category', fieldName: 'issueCategory', type: 'text', wrapText: true }
];

export default class DuplicateEntitlements extends LightningElement {
    columns = columns;
    dupENTRecords = [];
    startDate;
    endDate;
    disableFilterBTN;
    endDateError;

    cmpErrorMSG;
    showTable = false;
    showSpinner = false;

    connectedCallback() {
        this.calculateQuarterDates();
        this.loadEntitlements();
    }

    calculateQuarterDates() {
        const today = new Date();
        const currentMonth = today.getMonth(); // Adding 1 to match Rubrik's fiscal year starting from February

        let quarterStartMonth;
        if (currentMonth >= 2 && currentMonth <= 4) { // February - April
            quarterStartMonth = 2; // February
        } else if (currentMonth >= 5 && currentMonth <= 7) { // May - July
            quarterStartMonth = 5; // May
        } else if (currentMonth >= 8 && currentMonth <= 10) { // August - October
            quarterStartMonth = 8; // August
        } else { // November - January
            quarterStartMonth = 11; // November
        }
        console.log('quarterStartMonth', quarterStartMonth);
        const qtStartDate = new Date(today.getFullYear(), quarterStartMonth - 1, 1);
        const qtEndDate = new Date(today.getFullYear(), quarterStartMonth + 2, 0);
        const offset = today.getTimezoneOffset();
        this.startDate = new Date(qtStartDate.getTime() - offset * 60000).toISOString().split('T')[0];
        this.endDate = new Date(qtEndDate.getTime() - offset * 60000).toISOString().split('T')[0];
    }

    handleFilterClick() {
        try {
            this.showTable = false;
            this.loadEntitlements();
        } catch (error) {
            console.log('An error occurred:', error.body ? error.body.message : error.message);
            this.cmpErrorMSG = error.body ? error.body.message : error.message;
        }
    }

    validateDates(event) {
        const { label, value } = event.target;
        console.log('value:', value);
        if (label === 'Start Date') {
            this.startDate = value;
        } else if (label === 'End Date') {
            this.endDate = value;
        }
        console.log('this.startDate:', this.startDate);
        console.log('this.endDate:', this.endDate);

        if (this.endDate < this.startDate) {
            this.endDateError = 'The End Date should not be lesser than the Start Date';
            this.disableFilterBTN = true;
        } else {
            //this.showTable = false;
            this.endDateError = '';
            this.disableFilterBTN = false;
        }
    }

    async loadEntitlements() {
        this.showSpinner = true;
        let dateFilter = '';
        if (this.startDate && this.endDate) {
            dateFilter =
                'AND ((StartDate >= ' + this.startDate + ' AND StartDate <= ' + this.endDate + ')  OR (EndDate >= ' + this.startDate + ' AND EndDate <= ' + this.endDate + ')) ';
        }

        const ENTquery =
            'SELECT Id, Status, AssetId, Product__c, Asset.Name, Product__r.Name,Notes__c, StartDate, EndDate ' +
            ', Order_Service_Item__r.Quantity, Order_Service_Item__r.Product2.Product_Level__c, Order_Service_Item__r.OrderItemNumber,Order_Service_Item__r.Product_Name__c, Order_Service_Item__c, Order_Service_Item__r.Product2.SBQQSC__EntitlementConversion__c ' +
            ', ContractLineItemId, ServiceContractId, ServiceContract.Name ' +
            ' FROM Entitlement ' +
            " WHERE (Status = 'Active' OR Status ='Inactive') " +
            " AND Type = 'Phone Support' "+
            "AND (NOT Account.Name LIKE '%Unassigned%') AND AssetId != null AND Product__c != null " +
            "AND (NOT Notes__c LIKE '%reviewed by installed base%') AND Entitlement_Status__c != 'Terminated' " +
            dateFilter + " ORDER BY StartDate DESC";
        console.error('ENTquery:', ENTquery);
        try {
            const result = await getSobjectList({ theQuery: ENTquery });
            console.log('### result:', result.length);
            this.dupENTRecords = this.findDuplicates(result);
            this.showSpinner = false;
            if (this.dupENTRecords.length > 0) {
                this.showTable = true;
            } else {
                this.cmpErrorMSG = 'No duplicate entitlements found.';
            }
            console.log('### dupENTRecords:', this.dupENTRecords);
        } catch (error) {
            console.error('An error occurred:', error.body ? error.body.message : error.message);
            this.showSpinner = false;
            let tempError = error.body ? error.body.message : error.message;
            this.cmpErrorMSG = tempError.includes("Too many query rows") ?
                "This report doesn't support long date ranges due to technical limitations. Please try with a shorter date range." +
                "\n\nTechnical Error: " + tempError : tempError;
        }
    }

    findDuplicates(entRecords) {
        let dupENTRecords = [];
        let keyMap = new Map();

        entRecords.forEach((ENT) => {
            let key = ENT.Asset.Name + '-' + ENT.Product__r.Name + '-' + ENT.StartDate + '-' + ENT.EndDate;

            if(ENT.Order_Service_Item__r ){
                console.log('### newENT.Quant:'+ENT.Order_Service_Item__r.Quantity);
            }
            
            const newENT = {
                ...ENT,
                assetName: ENT.Asset.Name,
                OINumber: (ENT.Order_Service_Item__r && ENT.Order_Service_Item__r.OrderItemNumber ? ENT.Order_Service_Item__r.Product_Name__c : undefined),
                OIURL: '/' + ENT.Order_Service_Item__c,
                OIQuant: (ENT.Order_Service_Item__r && ENT.Order_Service_Item__r.Quantity ? ENT.Order_Service_Item__r.Quantity : undefined),
                entURL: '/' + ENT.Id,
                assetURL: '/' + ENT.AssetId,
                /*productName: ENT.Product__r.Name,
                productURL: '/' + ENT.Product__c,*/
                SCName: ENT.ServiceContract && ENT.ServiceContract.Name ? ENT.ServiceContract.Name : undefined,
                SCURL: ENT.ServiceContractId ? '/' + ENT.ServiceContractId : undefined,
                CLIURL: ENT.ContractLineItemId ? '/' + ENT.ContractLineItemId : undefined,
                Notes: ENT.Notes__c,
                issueCategory: 'Duplicate ENT'
            };

            console.log('### newENT.Quant:'+newENT.OIQuant);

            if (keyMap.has(key)) {
                let existingEntitlement = keyMap.get(key);
                dupENTRecords.push(existingEntitlement);
                dupENTRecords.push(newENT);
            } else {
                keyMap.set(key, newENT);
            }

            if (ENT.Order_Service_Item__r &&
                ENT.Order_Service_Item__r.Product2 &&
                ENT.Order_Service_Item__r.Product2.SBQQSC__EntitlementConversion__c &&
                ENT.Order_Service_Item__r.Product2.Product_Level__c &&
                ENT.Order_Service_Item__r.Product2.SBQQSC__EntitlementConversion__c === 'One per quote line'
            ) {
                let onePerQLIKey = ENT.Order_Service_Item__c + '#' + ENT.Order_Service_Item__r.Product2
                if (keyMap.has(onePerQLIKey)) {
                    let existingEntitlement = keyMap.get(onePerQLIKey);
                    existingEntitlement.issueCategory = 'Multiple ENTs: ENT Conversion is One per QLI';
                    newENT.issueCategory = 'Multiple ENTs: ENT Conversion is One per QLI';
                    dupENTRecords.push(existingEntitlement);
                    dupENTRecords.push(newENT);
                } else {
                    keyMap.set(onePerQLIKey, newENT);
                }
            }
        });

        return dupENTRecords;
    }
}