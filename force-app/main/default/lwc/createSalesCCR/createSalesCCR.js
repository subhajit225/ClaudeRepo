import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from "lightning/uiRecordApi";
import saveCCR from '@salesforce/apex/SalesCCRLWCController.saveCCR';

const FIELDS = ["CCR__c.Does_CCR_affect_People_or_Territory__c", "CCR__c.Name"];
export default class CreateSalesCCR extends NavigationMixin(LightningElement) {

    @track showModal = false;
    @track showSpinner = true;
    recordTypeId;
    selectedAffects;
    @track errormsg = '';	
    @track ccrObj = {};
    @api
    recordId;
    @api parentId;

    recordName;

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    wiredData({ error, data }) {
      if (data) {
        this.selectedAffects = data.fields.Does_CCR_affect_People_or_Territory__c.value;
        this.recordName = data.fields.Name.value;
      } else if (error) {
         this.errormsg =  error;
         this.showToast('Error', this.errormsg, 'error', 'sticky');
      }
    }

    @wire(getObjectInfo, { objectApiName: 'CCR__c' })
    objectInfo({ error, data }) {
        if (data) {
            const recordTypes = data.recordTypeInfos;
            const recordTypeInfo = Object.values(recordTypes).find(rt => rt.name === 'Sales CCR');
            if (recordTypeInfo) {
                this.recordTypeId = recordTypeInfo.recordTypeId;
            }
        } else if (error) {
             this.errormsg = 'Error fetching object info:';
             this.showToast('Error', this.errormsg, 'error', 'sticky');
        }
        this.showSpinner = false;
    }

    get editHeader() {
        return `Edit ${this.recordName}`;
    }

    handleAffectsChange(event) {
        this.selectedAffects = event.detail.value;
    }

    get showPeople() {
        return this.selectedAffects === 'People';
    }

    get showTerritory() {
        return this.selectedAffects === 'Territory';
    }

    get affectedFields() {
        if (this.showPeople) return this.affectedPersonFields;
        if (this.showTerritory) return this.affectedTerritoryFields;
        return
    }

    affectedPersonFields = [
        { label: 'Affective_Person__c', required: true },
        { label: 'Affected_Person_2__c', required: false },
        { label: 'Affected_Person_3__c', required: false },
        { label: 'Affected_Person_4__c', required: false },
        { label: 'Affected_Person_5__c', required: false },
        { label: 'Affected_Person_6__c', required: false }
    ];

    affectedTerritoryFields = [
        { label: 'Affected_Territory__c', required: true },
        { label: 'Affected_Territory_2__c', required: false },
        { label: 'Affected_Territory_3__c', required: false },
        { label: 'Affected_Territory_4__c', required: false },
        { label: 'Affected_Territory_5__c', required: false },
        { label: 'Affected_Territory_6__c', required: false }
    ];

    handleCancel() {
        // Check if running in Visualforce context
            // Close the window or go back in Visualforce context
            window.close();
            // If window.close() doesn't work (popup blockers), try going back
            if (!window.closed) {
                window.history.back();
            }
          

        // Standard Lightning navigation
        if (this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'CCR__c',
                    actionName: 'view'
                }
            });
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'CCR__c',
                actionName: 'list'
            }
        });
    }
    handleSuccess(event) {
        this.showSpinner = false;
        const recordId = event.detail.id;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: this.recordId ? 'CCR record updated successfully.' : 'CCR record created successfully.',
                variant: 'success'
            })
        );

        // Always use window.location for navigation when in Aura/VF context
        setTimeout(() => {
            window.location.href = '/' + recordId;
        }, 1500);
    }

    handleSave() {
        this.errormsg = '';
        
        const isValid = [...this.template.querySelectorAll('lightning-input-field')].reduce((prev, curr) => {
            return curr.reportValidity() && prev;
        }, true);
        if (!isValid) return;
        var finalSaveStr = '';
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
                finalSaveStr = finalSaveStr+element.fieldName +':'+ element.value+',';
                this.ccrObj[element.fieldName] = element.value;

        });
        
       // Add record Id for edit mode
		if(this.recordId) {
            this.ccrObj['Id'] = this.recordId;
        }        
        this.showSpinner = true;
        saveCCR({
            'finalSaveString' : JSON.stringify(this.ccrObj)
        }).then(response => {
            if (response.Success) {
                this.showSpinner = false;

                // Show success toast
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: response.Message || 'CCR record created/updated successfully.',
                        variant: 'success'
                    })
                );

                 // Navigate to the record
                const recordId = response.Data ? response.Data.Id : this.recordId;

                if(recordId) {
                    setTimeout(() => {
                        window.location.href = '/' + recordId;
                    }, 1500);
                }

            }else{
                this.showSpinner = false;
                this.errormsg = response.Message || 'An error occurred. Please try again.';
                this.showToast('Error', this.errormsg, 'error', 'sticky');
            }  
        }).catch(error => {
            this.showSpinner = false;
            if(error != undefined && error.body != undefined){
                if (Array.isArray(error.body)) {
                    this.errormsg = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    this.errormsg = error.body.message;
                } else {
                    // error.body exists but no recognizable message format
                    this.errormsg = 'Something went wrong. Please contact your administrator.';
                }
            } else {
                // No error.body
                this.errormsg = 'Something went wrong. Please contact your administrator.';
            }

            // Always show toast for any error
            this.showToast('Error', this.errormsg, 'error', 'sticky');            }); 
        
    }

    handleError(event) {
        this.showSpinner = false;
        this.errormsg = JSON.stringify(event.detail.detail);
        const event2 = new ShowToastEvent({
            title: 'Error',
            message: JSON.stringify(event.detail.message),
            variant: 'error'
        });
        this.dispatchEvent(event2);
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

}