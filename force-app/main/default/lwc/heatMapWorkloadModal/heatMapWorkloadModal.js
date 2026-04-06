import { LightningElement,api,track,wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import heatMapStyles from '@salesforce/resourceUrl/HeatMapStyles';
import { loadStyle } from 'lightning/platformResourceLoader';
import HEATMAP_OBJECT from '@salesforce/schema/HeatMap_Entry__c';
import MANUAL_WORKLOAD_VALUE from '@salesforce/schema/HeatMap_Entry__c.Manual_Workload_Value__c';
import MANUAL_INCUMBENT_VALUE from '@salesforce/schema/HeatMap_Entry__c.Manual_Incumbent__c';
import upsertHeatMapEntry from '@salesforce/apex/HeatMapController.saveHeatMapAttribute';
import updateAccountInformation from '@salesforce/apex/HeatMapController.updateAccountInformation';

export default class HeatMapWorkloadModal extends LightningElement {
    /*All Variables*/
    heatMapEntry = {sobjectType : 'HeatMap_Entry__c'};
    accountObj = {sobjectType : 'Account'};
    updatedAccountObj = {};
    @api showSelectionModal = false;//selection modal
    @api showWorkloadEntryModal = false;//workload entry modal
    @api showAccountInfoModal = false;//account info modal
    loadingData = false;
    objectName = 'HeatMap_Entry__c';
    fieldName = 'Manual_Workload_Value__c';
    objectInfoData;
    defaultRecordTypeId;
    selectedWorkloadVal = '';
    workloadPicklistVals;
    workloadSelVal;
    incumbentPicklistVals;
    incumbentSelVal;
    manualCount;
    manualCapacity;
    disableModal;
    outsideClick;
    updateWorkload = false;

    /*All Inputs*/
    @api workload = {};
    @api clickType = '';
    @api hasEditAccess;
    @api maxScroll = '';

    disableDataValue = false;

    /*All Life Cycle Hooks*/
    connectedCallback(){
        Promise.all([
            loadStyle(this, heatMapStyles )
        ]).catch(error => {
            console.log('Error loading styles: ' + JSON.stringify(error));
        });
        
        if (this.clickType === 'doubleClick') {
            this.showSelectionModal = false;
            this.showAccountInfoModal = false;
            this.showWorkloadEntryModal = false;
            this.disableModal = false;
            this.disableDataValue = false;

            if (this.workload.columnType === 'Workload' && this.workload.columnFilter !== 'Account Information' && this.workload.columnFilter != 'Product Editions') {
                this.showWorkloadEntryModal = true;
                requestAnimationFrame(() => {
                   this.template.querySelector('lightning-combobox[data-id="worloadValue"]')?.focus();
                });
                if (this.workload.readOnly || this.hasEditAccess != 'true') {
                    this.disableModal = true;
                    if(this.hasEditAccess != 'true'){
                        this.disableDataValue = true;
                    }
                }
            } else if (this.workload.columnType === 'Manual' && !this.workload.readOnly && this.hasEditAccess == 'true') {
                this.showAccountInfoModal = true;
                this.showWorkloadEntryModal = false;
                requestAnimationFrame(() => {
                    this.template.querySelector('textarea')?.focus();
                });
            } else {
                this.disableModal = true;
                if(this.hasEditAccess != 'true'){
                    this.disableDataValue = true;
                }
            }
        } else if (this.clickType === 'rightClick' && this.hasEditAccess == 'true') {
            this.showWorkloadEntryModal = false;
            this.showAccountInfoModal = false;
            this.showSelectionModal = true;
            this.disableModal = false;
            this.disableDataValue = false;

            if (this.workload.columnType === 'Manual' || this.workload.readOnly) {
                this.showSelectionModal = false;
                this.disableModal = true;
                if(this.hasEditAccess != 'true'){
                    this.disableDataValue = true;
                }
            }
        }
        this.heatMapEntry.Account__c = this.workload.accountId;
        this.heatMapEntry.HeatMap_Column__c = this.workload.columnId;
        this.heatMapEntry.AccountId_ColumnId__c = this.workload.accountId + '-' + this.workload.columnId;
        this.workloadSelVal = this.workload.manualWorkloadVal;
        this.incumbentSelVal = this.workload.manualIncumbent;
        this.manualCount = this.workload.manualObjCount;
        this.manualCapacity = this.workload.manualObjCapacity;
        if(this.workload.heatMapEntryId){
            this.heatMapEntry.Id = this.workload.heatMapEntryId;
        }
        this.accountObj.Id = this.workload.accountId;

        document.addEventListener('click', this.outsideClick = this.handleCloseModal.bind(this));
    }
    textAreaHeight = '';
    getTextAreaBoundry(event){
        this.textAreaHeight = event.target.clientHeight;
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.outsideClick);
        this.workloadSelVal = '';
        this.manualCount = '';
        this.manualCapacity = '';
        this.incumbentSelVal = '';
        this.clickType = '';
    }

    /*All Wired Call*/
    @wire(getObjectInfo, { objectApiName: HEATMAP_OBJECT })
    wireObjectInfo({ error, data }){
        if(data){
            this.objectInfoData = data;
            this.defaultRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
             //handle error
        }
    }

    @wire(getPicklistValues, {recordTypeId: '$defaultRecordTypeId',fieldApiName: MANUAL_WORKLOAD_VALUE})
    pickValues({ error, data }) {
        if (data) {
            this.workloadPicklistVals = data.values.map(plValue => {
                return {
                    label: plValue.label,value: plValue.value
                };
            });
            const newEle = {label: 'Blank', value: ''};
            this.workloadPicklistVals.push(newEle);
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getPicklistValues, {recordTypeId: '$defaultRecordTypeId',fieldApiName: MANUAL_INCUMBENT_VALUE})
    pickValuesIncumbent({ error, data }) {
        if (data) {
            this.incumbentPicklistVals = data.values.map(plValue => {
                return {
                    label: plValue.label, value: plValue.value
                };

            });
            this.incumbentPicklistVals.unshift({label: 'Blank', value: ''});
        } else if (error) {
            console.log(error);
        }
    }

    /*All Change Handlers*/
    handleWorkloadDropdownChange(event){
        this.workloadSelVal = event.target.value;
        if (this.workloadSelVal !== this.workload.value) {
            this.heatMapEntry.Manual_Workload_Value__c = this.selectedWorkloadVal === 'Blank' ? '' : this.workloadSelVal;
        }
    }

    handleIncumbentDropdownChange(event){
        this.incumbentSelVal = event.target.value;
        if(this.incumbentSelVal != this.workload.manualIncumbent){
            this.heatMapEntry.Manual_Incumbent__c = this.incumbentSelVal === 'Blank' ? '' : this.incumbentSelVal;
        }
    }

    handleManualCountChange(event){
        this.manualCount = event.target.value;
        if(this.manualCount != this.workload.manualObjCount){
            this.heatMapEntry.Manual_Object_Count__c = this.manualCount;
        }
    }

    handleManualCapacityChange(event){
        this.manualCapacity = event.target.value;
        let objectCapacityField = this.template.querySelector('.objectCapacity');

        const decimalStr = this.manualCapacity.split('.')[1];
        if (decimalStr && decimalStr.length > 2) {
            objectCapacityField.setCustomValidity('Enter a valid value.');
        } else {
            objectCapacityField.setCustomValidity('');
            if (this.manualCapacity !== this.workload.manualObjCapacity) {
                this.heatMapEntry.Manual_Object_Capacity__c = this.manualCapacity;
            }
        }
    }

    handleSaveButtonClick(event){
        if(this.workload.columnFilter == 'Account Information'){
            if(this.textAreaValue.length > 5000 && this.workload.columnName != 'PG Next Step'){
                this.showError = true;
                this.errorMsg = `Exceeds character limit of 5000`;
            }else if(this.workload.columnName == 'PG Next Step' && this.textAreaValue.length >255){
                this.showError = true;
                this.errorMsg = `Exceeds character limit of 255`;
            }else{
                this.showError = false;
                this.handleAccountInfoUpdate();
                this.updateWorkload = true;
                this.closeModal();
            }
            
        }else {
            let objectCountField = this.template.querySelector('.objectInput').checkValidity();
            let objectCapacityField = this.template.querySelector('.objectCapacity').checkValidity();
            if(objectCountField && objectCapacityField){
                this.updateWorkload = true;
                this.closeModal();
                this.handleEntryUpsert();
            }
        }
    }

    handleModalOnClick(event){
        this.selectedWorkloadVal = event.target.getAttribute('data-item');
        if (this.selectedWorkloadVal !== this.workload.value) {
            this.heatMapEntry.Manual_Workload_Value__c = this.selectedWorkloadVal === 'Blank' ? '' : this.selectedWorkloadVal;
            this.handleEntryUpsert();
            this.closeModal();
            this.updateWorkload = true;
        }
    }

    handleCloseIconOnClick(){
        this.closeModal();
    }

    handleCloseModal(event){
        event.stopPropagation();
        let heightcon = this.template.querySelector('.scrollable-textarea') || undefined;
        if(heightcon && this.textAreaHeight){
            this.textAreaHeight = undefined;
            return;
        }else{
            this.closeModal();
        }
    }
    handleKeyDown(event) {
        if(event.code == 'Escape') {
          this.showAccountInfoModal = false;
          this.showWorkloadEntryModal = false;
          event.preventDefault();
          event.stopImmediatePropagation();
        }
      }

    handleInsideClick(event){
        event.stopPropagation();
        return false;
    }
    
    showError = false;
    errorMsg = '';
    textAreaValue = '';
    handleTextArea(event){
        this.textAreaValue = event.target.value;
        if(this.textAreaValue.length > 5000 && this.workload.columnName != 'PG Next Step') {
            this.showError = true;
            this.errorMsg = `Exceeds character limit of 5000`;
        } else if(this.workload.columnName == 'PG Next Step' && this.textAreaValue.length >255){
            this.showError = true;
            this.errorMsg = `Exceeds character limit of 255`;
        }else {
            this.showError = false;
            this.updatedAccountObj.accountId = this.workload.accountId;
            this.updatedAccountObj.columnName = this.workload.columnName;
            this.updatedAccountObj.pgValue = this.textAreaValue;
            if(this.workload.columnName == 'PG Notes'){
                this.accountObj.PG_Notes__c = this.textAreaValue;
                this.updatedAccountObj.columnId = this.workload.columnId;
            }else if(this.workload.columnName == 'PG Next Step'){
                this.updatedAccountObj.columnId = this.workload.columnId;
                this.accountObj.PG_Next_Steps__c =  this.textAreaValue;
            }
        }
        
    }

    /*All Apex Controller Methods*/
    async handleEntryUpsert(){
        this.handleNullValuesForHeatmapEntry();
        await upsertHeatMapEntry({heatMapEntry: this.heatMapEntry})
        .then((result) => {
            //call parent
            this.closeModal();
        })
        .catch((error) => {
            console.log(error);
            this.closeModal();
        });
    }

    async handleAccountInfoUpdate(){
        await updateAccountInformation({accountObjRecord : this.accountObj})
            .then((result) => {
                this.closeModal();
                //call parent
            })
            .catch((error) => {
                console.log(error);
            });
    }

    /*All Helper Methods*/
    closeModal(){
        this.dispatchEvent(new CustomEvent('modalaction',{
            detail: {
                heatMapEntryObj: this.heatMapEntry,
                updatedAccountObj : this.updatedAccountObj,
                updateWorkloadFlag : this.updateWorkload
            }
        }));

        //reset all values
        this.workloadSelVal = '';
        this.manualCount = '';
        this.manualCapacity = '';
        this.incumbentSelVal = '';
        this.clickType = '';
    }

    handleNullValuesForHeatmapEntry(){
        if(this.heatMapEntry.hasOwnProperty("Manual_Workload_Value__c") && (this.heatMapEntry.Manual_Workload_Value__c == null || this.heatMapEntry.Manual_Workload_Value__c == "") ){
            this.heatMapEntry.Manual_Workload_Value__c = '';
        }
        if(this.heatMapEntry.hasOwnProperty("Manual_Incumbent__c") && (this.heatMapEntry.Manual_Incumbent__c == null || this.heatMapEntry.Manual_Incumbent__c == "") ){
            this.heatMapEntry.Manual_Incumbent__c = '';
        }
        if(this.heatMapEntry.hasOwnProperty("Manual_Object_Capacity__c") && (this.heatMapEntry.Manual_Object_Capacity__c == null || this.heatMapEntry.Manual_Object_Capacity__c == "" || this.heatMapEntry.Manual_Object_Capacity__c == 0) ){
            this.heatMapEntry.Manual_Object_Capacity__c = 0;
        }
        if(this.heatMapEntry.hasOwnProperty("Manual_Object_Count__c") && (this.heatMapEntry.Manual_Object_Count__c == null || this.heatMapEntry.Manual_Object_Count__c == "" || this.heatMapEntry.Manual_Object_Count__c == 0)){
            this.heatMapEntry.Manual_Object_Count__c = 0;
        }
    }
}