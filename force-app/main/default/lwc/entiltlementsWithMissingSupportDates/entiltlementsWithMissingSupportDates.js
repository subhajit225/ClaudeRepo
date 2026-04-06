import { LightningElement,api, wire, track } from 'lwc';
import getEntList from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const columns = [
    {
        label: 'Name', fieldName: 'EntitlementURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'name'
            }
        }
    },
    {
        label: 'Support Start Date', fieldName: 'supportStartDate', type: 'date',
        typeAttributes: {
            day: "numeric",
            month: "numeric",
            year: "numeric"
        }
    },
    {
        label: 'Support End Date', fieldName: 'supportEndDate', type: 'date',
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
        label: 'Order Name', fieldName: 'order', type: 'text'
       /* typeAttributes: {
            label: {
                fieldName: 'order'
            }
        }*/
    },
    {
        label: 'Notes', fieldName: 'Notes__c', type: 'text'
    },
    {
        label: 'Asset', fieldName: 'assetURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'asset'
            }
        }
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
        label: 'Type', fieldName: 'type', type: 'text'
    },
    {
        label: 'Subscription Term', fieldName: 'subscriptionTerm', type: 'text'
    }

];

export default class EntiltlementsWithMissingSupportDates extends LightningElement {
    @track missingEntitlementDataDisplay = [];
    @track missingEntWithssupportDateData = [];
    @track startDate;
    @track endDate;
    @track endDateError = '';
    filterText = '';
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
    @track metadataProfileName;
    /**
     * Lifecycle hook that is invoked when the component is inserted into the DOM.
     * It initializes the component by fetching entitlement records.
     */
    connectedCallback() {
        this.getEntitlementRecords();
    }

    /**
     * Fetches entitlement records with missing support dates and updates the component's state.
     * The function queries the entitlement records where the StartDate or EndDate is null,
     * and the product category is not 'Spare' and type is 'Phone Support'.
     * It processes the result to create a displayable format and updates the component's data properties.
     */
    getEntitlementRecords() {
        var dateFilterQuery = 'SELECT Id,Name,StartDate,EndDate,AccountId, Account.Name, Order_Service_Item__r.OrderId, Order_Number__c, Notes__c, AssetId, Asset.Name,CreatedDate,Type,Subscription_Term__c, Product__r.Product_Type__c,Product__r.Category__c FROM entitlement '
            +' WHERE (StartDate = NULL OR EndDate = NULL) AND (NOT Product__r.Category__c LIKE \'%Spare\') AND Type = \'Phone Support\' AND (NOT Notes__c LIKE \'%reviewed by installed base%\') AND Entitlement_Status__c != \'Terminated\' ';
        getEntList({ theQuery: dateFilterQuery })
            .then(result => {
                this.isLoaded = true;
                result = JSON.parse(JSON.stringify(result));
                console.log('result data : ', JSON.stringify(result));
                result.forEach((ent) => {

                        let tempEnt1 = { Id:'',EntitlementURL: '', name: '', accountURL: '', account: '', orderURL: '', order: '', asset: '', assetURL:'',createdDate:'',type:'',subscriptionTerm:'', supportStartDate: '',supportStartDate:'', Notes__c: ''};
                            tempEnt1.Id = ent.Id;
                            tempEnt1.EntitlementURL = '/' + ent.Id;
                            tempEnt1.name = ent?.Name;
                            tempEnt1.supportStartDate = ent?.StartDate;
                            tempEnt1.supportEndDate = ent?.EndDate;
                            tempEnt1.accountURL = '/' + ent?.AccountId;
                            tempEnt1.account = ent.Account.Name;
                            //tempEnt1.orderURL = '/' + ent.Order_Service_Item__r.Order;
                            tempEnt1.order = ent?.Order_Number__c;
                            tempEnt1.Notes__c = ent?.Notes__c;
                            tempEnt1.assetURL = ent?.AssetId !== undefined ? '/' + ent?.AssetId : '';
                            tempEnt1.asset = ent?.Asset?.Name != null && ent?.Asset?.Name !== undefined ? ent?.Asset?.Name : '';
                            tempEnt1.createdDate = ent?.CreatedDate;
                            tempEnt1.type = ent?.Type;
                            tempEnt1.subscriptionTerm = ent?.Subscription_Term__c;


                            this.missingEntWithssupportDateData = [...this.missingEntWithssupportDateData, tempEnt1];
                })
                this.missingEntitlementDataDisplay = this.missingEntWithssupportDateData;
                this.filteredData = this.missingEntWithssupportDateData;
                if (this.missingEntitlementDataDisplay.length > 0) this.showTable = true;
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
                this.filteredData = this.missingEntWithssupportDateData.filter(eachObj =>{
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
            this.filteredData = [...this.missingEntWithssupportDateData];
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
            this.ShowToast('Error', 'An Error Occured!!', 'error', 'dismissable');
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
    /**
     * Handles changes to the filter input and updates the filtered data based on the input value.
     * Filters the displayed entitlement data by matching the filter text with specific fields.
     *
     * @param {Event} event - The event object containing details about the filter input change.
     * @property {string} event.target.value - The current value of the filter input field.
     *
     * @returns {void} This function does not return a value.
     */
    handleFilterChange(event) {
        this.filterText = event.target.value;
        try {
            this.filteredData = this.missingEntitlementDataDisplay.filter((item) => {


                if ((item.name != undefined && item.name.toLowerCase().includes(this.filterText.toLowerCase())) ||					
                    (item.account && item.account.toLowerCase().includes(this.filterText.toLowerCase())) ||
                    (item.order != undefined && item.order.toLowerCase().includes(this.filterText.toLowerCase())) ||
                    (item.asset != undefined && item.asset.toLowerCase().includes(this.filterText.toLowerCase())) ||
                    (item.type != undefined && item.type.toLowerCase().includes(this.filterText.toLowerCase())) 
                    ) {
                    return item
                }

            });
        } catch (err) {
            console.error(err)
        }

        if (this.filterText == '' || this.filterText == undefined) {
            this.consData = this.missingEntitlementDataDisplay;
        }

    }
}