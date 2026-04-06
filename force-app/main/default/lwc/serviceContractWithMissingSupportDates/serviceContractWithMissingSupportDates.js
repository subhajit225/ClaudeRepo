import { LightningElement,api, wire, track } from 'lwc';
import getSCList from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import Id from '@salesforce/user/Id';


const columns = [
    {
        label: 'Contract Number', fieldName: 'ContractNumber', type: 'text'
    },
    {
        label: 'Contract Name', fieldName: 'ContractURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'name'
            }
        }
    },
    {
        label: 'Start Date', fieldName: 'supportStartDate', type: 'date',
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    },
    {
        label: 'End Date', fieldName: 'supportEndDate', type: 'date',
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    },
    {
        label: 'Account Name', fieldName: 'accountURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'account'
            }
        }
    },
    {
        label: 'Order Name', fieldName: 'orderURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'order'
            }
        }
    },
    {
        label: 'Notes', fieldName: 'Notes__c', type: 'text'
    },
    
    {
        label: 'Created Date', fieldName: 'createdDate', type: 'date',
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    },
    {
        label: 'Quote', fieldName: 'quoteURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'quote'
            }
        }
    },

];

export default class ServiceContractWithMissingSupportDates extends LightningElement {
    userId = Id;
    @track serviceContractDataDisplay = [];
        @track serviceContractsData = [];
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
        
        connectedCallback() {
            this.getServiceContractRecords();
        }
        filterText;


    
        getServiceContractRecords(){
            var dateFilterQuery = 'SELECT Id,Name, ContractNumber, StartDate,EndDate,AccountId, Account.Name, SBQQSC__Order__c, SBQQSC__Order__r.Order_Number__c, Notes__c, SBQQSC__Quote__r.Id, SBQQSC__Quote__r.Name,CreatedDate FROM ServiceContract WHERE (StartDate = NULL OR EndDate = NULL)';
            getSCList({ theQuery: dateFilterQuery })
                .then(result => {
                    this.isLoaded = true;
                    result = JSON.parse(JSON.stringify(result));
                    console.log('result data : ', JSON.stringify(result));
                    result.forEach((sc) => {
                        this.lstIds.push(sc.Id);
                        //let orderNumber = ent.SBQQSC__Order__r.OrderNumber.toString();
                        if(!sc?.Notes__c?.includes('No Support Dates required for SC')  ||
                          (sc?.Notes__c == null && sc?.Notes__c == undefined)){
                    
                            let tempSC = { Id:'',ContractURL: '', name: '', accountURL: '', account: '', orderURL: '', order: '', quote: '', quoteURL:'',createdDate:'', supportStartDate: '',supportEndDate:'', Notes__c: ''};
                            tempSC.Id = sc.Id;
                            tempSC.ContractNumber=sc.ContractNumber
                            tempSC.ContractURL = '/' + sc.Id;
                            tempSC.name = sc?.Name;
                            tempSC.supportStartDate = sc?.StartDate;
                            tempSC.supportEndDate = sc?.EndDate;
                            tempSC.accountURL = '/' + sc?.AccountId;
                            tempSC.account = sc.Account.Name;
                            tempSC.orderURL = sc.SBQQSC__Order__c !== undefined ? '/'+sc.SBQQSC__Order__c : '';
                            if(sc.SBQQSC__Order__c !== undefined && sc.SBQQSC__Order__r.Order_Number__c !== undefined){
                                tempSC.order = sc?.SBQQSC__Order__r?.Order_Number__c;
                            }
                            //sc?.SBQQSC__Order__r.OrderNumber;
                            //tempEnt1.orderURL = '/' + sc?.SBQQSC__Order__r.Id;
                            tempSC.Notes__c = sc?.Notes__c;
                            tempSC.quoteURL = sc?.SBQQSC__Quote__r?.Name != null || sc?.SBQQSC__Quote__r?.Name !== undefined ? '/'+sc?.SBQQSC__Quote__c : '';
                            tempSC.quote = sc?.SBQQSC__Quote__r?.Name != null || sc?.SBQQSC__Quote__r?.Name !== undefined ? sc?.SBQQSC__Quote__r?.Name : '';
                            tempSC.createdDate = sc?.CreatedDate;
                            this.serviceContractsData = [...this.serviceContractsData, tempSC];
                            }
                    })
                    this.serviceContractDataDisplay = this.serviceContractsData;
                    this.filteredData = this.serviceContractsData;
                    if (this.serviceContractDataDisplay.length > 0) 
                    {
                        this.showTable = true;
                    this.getContractLineItems();
                }
                })
        }
        /**
         * Retrieves contract line items and filters the service contract data display.
         * 
         * This function executes a query to fetch contract line items with a specific product category
         * and filters the current service contract data display to exclude any service contracts
         * that have associated contract line items.
         */
        getContractLineItems() {
            console.log('lstIds', this.lstIds);
            this.isLoaded = false;
            let filterQuery = `SELECT Id , SBQQSC__Product__r.Product_Type__c,CreatedDate, ServiceContractId FROM ContractLineItem where (SBQQSC__Product__r.Category__c like \'%Spare\')`;
            getSCList({ theQuery: filterQuery }).then((res) => {
                this.isLoaded = true;

                const filteredArray = this.serviceContractDataDisplay.filter(item1 =>
                    !res.some(item2 => item1.Id === item2.ServiceContractId)
                );

                this.serviceContractDataDisplay = filteredArray;
                this.filteredData = filteredArray;
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
                    this.filteredData = this.serviceContractsData.filter(eachObj =>{
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
                this.filteredData = [...this.serviceContractsData];
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
			this.filteredData= this.serviceContractDataDisplay.filter((item) => {
			

				if ((item.name != undefined && item.name.toLowerCase().includes(this.filterText.toLowerCase())) ||					
					(item.account && item.account.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.ContractNumber != undefined && item.ContractNumber.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.ContractURL != undefined && item.ContractURL.toLowerCase().includes(this.filterText.toLowerCase())) ||
					(item.order != undefined && item.order.includes(this.filterText)) 
					
					
					) {
					return item
				}

			});
		} catch (err) {
			console.error(err)
		}

		if (this.filterText == '' || this.filterText == undefined) {
			this.filteredData = this.serviceContractDataDisplay;
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