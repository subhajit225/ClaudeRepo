import { LightningElement, track, wire } from 'lwc';
import getAssetList from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import getAccountList  from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';
import getAssetNameList  from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';
const columns = [
    {
        label: 'Asset Id', fieldName: 'assetId', type: 'text'
    },
    {
        label: 'Asset Serial Number', fieldName: 'assetUrl', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'assetName'
            }
        }
    },
    {
        label: 'Account', fieldName: 'accountUrl', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'accountName'
            }
        }
    },
    {
        label: 'Product', fieldName: 'productUrl', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'productName'
            }
        }
    },
    {
        label: 'Status', fieldName: 'Status', type: 'text'
    },
    {
        label: 'Order Line', fieldName: 'orderLineUrl', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'orderLine'
            }
        }
    },
    {
        label: 'Order', fieldName: 'orderUrl', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'orderName'
            }
        }
    },
    {
        label: 'Support Start Date', fieldName: 'StartDate', type: 'date',
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    },
    {
        label: 'Support End Date', fieldName: 'EndDate', type: 'date',
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    },
   
    {
        label: 'Notes', fieldName: 'Notes', type: 'text'
    }

];

export default class AssetsWithMissingSupportDate extends LightningElement {
    userId = Id;
        @track assetDataDisplay = [];
        @track assetData = [];
        @track startDate;
        @track endDate;
        @track endDateError = '';
        clisWithAssets = new Map();
        columns = columns;
        showTable = false;
        disableFilterBTN = false;
        filteredData = [];
        timer;
        filterBy = "Name";
        condition = "Filter In"
        isLoaded = false;
        value;
        saveDraftValues = [];
        showData = true;
        error;
        @track lstIds = [];
        @track metadataProfileName;
        @track accList = [];
        @track assetNameList = [];
        @track productNameList = [];
        /**
         * Lifecycle hook that fires when a component is inserted into the DOM.
         * This method initializes the component by fetching necessary data.
         * 
         * It performs the following operations:
         * 1. Retrieves Rubrik internal accounts
         * 2. Fetches metadata records
         * 3. Retrieves service contract records
         * 
         * @returns {void}
         */
        connectedCallback() {
            this.getexcludedAssetNames();
            this.getRubrikInternalAccounts();
            this.getAssetRecords();
        }
        filterText;


        userProfileName;
    /**
     * Retrieves Rubrik internal accounts from the database.
     * 
     * This function constructs a SOQL query to fetch ID and Accounts_ID__c fields
     * from the RubrikInternalAccounts__c object. It then uses the getContactList
     * method to execute the query and process the results.
     * Amit Mishra
     * @returns {void} This function doesn't return a value, but updates the 'accList' property of the class.
     */
    getRubrikInternalAccounts() {
       let sQuery = 'SELECT ID, Accounts_ID__c FROM RubrikInternalAccounts__c';
       getAccountList({theQuery:sQuery}) 
       .then(result => {
        result = JSON.parse(JSON.stringify(result));
        console.log('accResult:::>'+JSON.stringify(result));
        this.accList = result[0].Accounts_ID__c.split(',');
       })
    }

    getexcludedAssetNames(){
        let sQuery = 'SELECT Label,Values__c FROM Order_control__mdt WHERE Label = \'Missing Support Date Excluded Products\'';
       getAssetNameList({theQuery:sQuery}) 
       .then(result => {
        result = JSON.parse(JSON.stringify(result));
        this.assetNameList = result[0].Values__c.split(',');
       })
    }
    
        getAssetRecords(){
            //Account.Name != \'Unassigned\' AND (AccountId NOT IN :AccountIDs)  AND  and product2.Name NOT IN :excludedAssetName'
            var dateFilterQuery = 'SELECT Id, SerialNumber, Support_Start_Date__c, Premium_Support_End_Date__c, AccountId, Account.Name,'+
                    'Status, Product2Id, Product2.Name, Order_Service_Item__c, Order_Service_Item__r.OrderItemNumber,'+ 
                    'Order_Service_Item__r.OrderId, Order_Service_Item__r.Order.OrderNumber,Description FROM Asset'+
                    ' WHERE Account.Name != \'Unassigned\' AND (NOT Account.Name LIKE \'%Rubrik%\') AND Status = \'Purchased\' AND ((Product2.Name like \'RBK%\' AND'+ 
                    ' SerialNumber  LIKE \'AA%\') OR Product2.product_level__c = \'Hardware\')  AND (Support_Start_Date__c = NULL OR Premium_Support_End_Date__c = NULL)'+
                    ' AND product2.Product_Type__c != \'Spares\'';
            getAssetList({ theQuery: dateFilterQuery })
                .then(result => {
                    this.isLoaded = true;
                    result = JSON.parse(JSON.stringify(result));
                    console.log('result data : ', JSON.stringify(result));
                    result.forEach((asset) => {
                        this.lstIds.push(asset.Id);
                        //let orderNumber = ent.SBQQSC__Order__r.OrderNumber.toString();
                        if(!this.accList.includes(asset.AccountId) && !this.assetNameList.includes(asset.Product2.Name)){
                            if((asset.Description !== null && asset.Description !== undefined
                                && !asset.Description.toLowerCase().includes('no hw support / sw associated') 
                                && !asset.Description.toLowerCase().includes('reviewed by installed base'))
                                ||(asset?.Description == null && asset?.Description == undefined)){
                            let tempAsset = { Id:'',assetUrl: '', assetName: '', accountUrl: '', accountName: '', orderUrl: '', orderName: '', orderLine: '', orderLineUrl:'',Status:'', StartDate: '',EndDate:'', Notes__c: '',productUrl: '', productName: ''};
                                tempAsset.assetId = asset.Id;
                                tempAsset.assetName = asset.SerialNumber
                                tempAsset.assetUrl = '/' + asset.Id;
                                tempAsset.accountUrl = '/'+asset?.AccountId;
                                tempAsset.accountName = asset?.Account.Name;
                                tempAsset.productUrl = '/'+asset?.Product2Id;
                                tempAsset.productName = asset?.Product2.Name;
                                tempAsset.Status = asset?.Status;
                                //tempAsset.orderLine = asset?.
                                tempAsset.orderUrl = asset?.Order_Service_Item__r?.OrderId !== undefined ? '/' + asset?.Order_Service_Item__r?.OrderId : '';
                                tempAsset.orderName = asset?.Order_Service_Item__r !== undefined && asset?.Order_Service_Item__r.Order !== undefined && asset?.Order_Service_Item__r.Order.OrderNumber !== undefined ? asset?.Order_Service_Item__r?.Order?.OrderNumber : '';
                                tempAsset.Notes = asset?.Description;
                                tempAsset.StartDate = asset?.Support_Start_Date__c;
                                tempAsset.EndDate = asset?.Premium_Support_End_Date__c;
                                tempAsset.orderLine = asset?. Order_Service_Item__r?.OrderItemNumber;
                                tempAsset.orderLineUrl = asset.Order_Service_Item__c!== undefined ? '/' + asset.Order_Service_Item__c : '';
                                this.assetData = [...this.assetData, tempAsset];
                        }
                    }
                    })
                    this.assetDataDisplay = this.assetData;
                    this.filteredData = this.assetData;
                    if (this.assetData.length > 0) 
                    {
                        this.showTable = true;
                    //this.getContractLineItems();
                }
                })
        }
        filterHandler(event){
            this.value = event.target;
        }
    
        filterHandle(){
            const {value} = this.value;
            console.log('value :::>'+value);
            window.clearTimeout(this.timer);
            if(value){
                this.timer = window.setTimeout(()=>{
                    this.filteredData = this.assetData.filter(eachObj =>{
                        const val = eachObj[this.filterBy] ? eachObj[this.filterBy]:'';
                        console.log('val :::>'+val);
                        console.log()
                        if(this.condition === 'Filter In'){
                            return val.includes(value);
                        }else{
                            return !val.includes(value);
                        }
                    });
                },0);
            }else{
                this.filteredData = [...this.assetData];
            }
        }
        get FilterByOptions(){
            return [
                {
                    label: 'Name', value: 'name'
                },
                {
                    label: 'Shipment Status', value: 'orderShipmentStatus'
                },
                {
                    label: 'Notes', value: 'notes'
                }
                
            ];
        }
    
        filterByHandler(event){
            this.filterBy = event.target.value;
            console.log('filterBy :::>'+this.filterBy);
        }
    
        conditionHandler(event){
            this.condition = event.target.value;
        }
    
        get ConditionOption(){
            return[
                {
                    label: 'Filter In', value: 'Filter In'
                },
                {
                    label: 'Filter Out', value: 'Filter Out'
                } 
            ]
        }
    
        handleSave(event) {
            this.saveDraftValues = event.detail.draftValues;
            const recordInputs = this.saveDraftValues.slice().map(draft => {
                const fields = Object.assign({}, draft);
                return { fields };
            });
            console.log('recordInputs :::>'+JSON.stringify(recordInputs));
            // Updateing the records using the UiRecordAPi
            const promises = recordInputs.map(recordInput => updateRecord(recordInput));
            Promise.all(promises).then(res => {
                this.ShowToast('Success', 'Records Updated Successfully!', 'success', 'dismissable');
                this.saveDraftValues = [];
                return this.refresh();
            }).catch(error => {
                let msg = this.handleError(error);
                this.ShowToast('Error', `An Error Occured!! ${msg}`, 'error', 'dismissable');
            }).finally(() => {
                this.saveDraftValues = [];
            });
        }
     
        ShowToast(title, message, variant, mode){
            const evt = new ShowToastEvent({
                    title: title,
                    message:message,
                    variant: variant,
                    mode: mode
                });
                this.dispatchEvent(evt);
        }
     
        // This function is used to refresh the table once data updated
        async refresh() {
            await refreshApex(this.getEntitlementRecords);
        }
        handleFilterChange(event) {
		this.filterText = event.target.value;
		try {
			this.filteredData= this.assetDataDisplay.filter((item) => {
			

				if ((item.assetId != undefined && item.assetId.toLowerCase().includes(this.filterText.toLowerCase())) ||					
					(item.assetName && item.assetName.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.accountName != undefined && item.accountName.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.productName != undefined && item.productName.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.Status != undefined && item.Status.includes(this.filterText)) ||
					(item.orderLine != undefined && item.orderLine.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.orderName != undefined && item.orderName.toLowerCase().includes(this.filterText.toLowerCase()))
					) {
					return item
				}

			});
		} catch (err) {
			console.error(err)
		}

		if (this.filterText == '' || this.filterText == undefined) {
			this.filteredData = this.assetDataDisplay;
		} 


	}

    handleError(error) {
        let message = 'Unexpected error';

        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error.body && error.body.message) {
            // Handle Apex exception errors
            message = error.body.message;
        } else if (error.body && error.body.pageErrors && error.body.pageErrors.length > 0) {
            // Handle page-level errors
            message = error.body.pageErrors.map(e => e.message).join(', ');
        } else if (error.body && error.body.fieldErrors) {
            // Handle field-specific errors
            message = Object.values(error.body.fieldErrors)
                .flat()
                .map(e => e.message)
                .join(', ');
        }
        else if (error.statusText) {
            // Handle HTTP errors
            message = error.statusText;
        }

        // Fallback for network errors
        if (error.message) {
            message = error.message;
        }


    return message;
    }
}