import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getEditFieldNames from '@salesforce/apex/CS_CustomFieldController.getFieldNames';
import hasPermission from "@salesforce/customPermission/Case_Special_Handling_Object_Edit_Permission";
import { IsConsoleNavigation, getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';

export default class CS_NewCaseSpecialHandlingLWC extends NavigationMixin(LightningElement) {
   @track isSubmitting = false;
   @track newmode;
   @track editmode;
   @api recordId;
   @api parentId;
   @track parentIdNew;
   @api objectApiName = 'Case_Special_Handling__c';
   @track operation;
   @track fields = [];
   @api redirectedFromDetails;
   @track previousURL = '/lightning/';
   @track lightningMode;
   @track error;
   @track success;

   @wire(IsConsoleNavigation) isConsoleNavigation;

   get hasEditCustomPermission() {
      return hasPermission;
   }

   handleSubmit(event) {
      this.isSubmitting = true;
      setTimeout(() => {
         this.isSubmitting = false;
      }, 2000);
   }

   async handleSuccess(event) {
      if (this.lightningMode) {
         const toastEvent = new ShowToastEvent({
            title: 'Success!',
            message: 'Record saved successfully.',
            variant: 'success',
         });
         this.dispatchEvent(toastEvent);
         if (this.newmode) {
            const newRecordId = event.detail.id;
            if (this.isConsoleNavigation) {
               const { tabId } = await getFocusedTabInfo();
               await closeTab(tabId);
            }
            window.open('/lightning/r/Case_Special_Handling__c/' + newRecordId + '/view', '_self');
         } else {
            if (this.isConsoleNavigation) {
               const { tabId } = await getFocusedTabInfo();
               await closeTab(tabId);
            } else {
               window.open(this.previousURL, '_self');
            }
         }
      } else {
         const currentUrl = window.location.href;
         const urlParts = currentUrl.split('/');
         const newRecordId = event.detail.id;
         if (this.newmode) {
            this.operation = 'Edit';
            const url = urlParts[0] + "/" + newRecordId;
            window.open(url, '_self');
         } else {
            const url = urlParts[0] + "/" + this.parentIdNew;
            window.open(url, '_self');
         }
         this.success = true;
         this.newmode = false;
         this.editmode = false;
         setTimeout(() => {
            this.success = false;
         }, 1000);
      }

   }

   @wire(getEditFieldNames, {
      objectApiName: '$objectApiName',
      operation: '$operation'
   })
   wiredFieldNames({
      error,
      data
   }) {
      if (data) {
         this.fields = data;
         this.fields = data.map(field => ({
            apiName: field,
            isDisabled: this.isFieldEnabled(field),
            required: this.isFieldRequired(field),
            value: this.fieldValue(field),
            unchange: this.isUnchanged(field),
         }));
      } else if (error) {
         console.error('Error fetching field names:', error);
      }
   }
   isFieldEnabled(fieldName) {
      const disabledFields = ['Account_Id__c','Manual_Review_Requested_On__c'];
      //const disabledFields = ['Message__c','Icon__c','Show_Banner__c','Category__c','Case__c','Auto_Archive__c','Is_Archived__c', 'Valid_Until__c'];
      return disabledFields.includes(fieldName);
   }
   isFieldRequired(fieldName) {
      const disabledFields = ['Message__c', 'Account_Id__c'];
      return disabledFields.includes(fieldName);
   }
   fieldValue(fieldName) {
      if (fieldName == 'Account_Id__c') {
         return this.parentIdNew;
      }

   }

   isUnchanged(fieldName) {
      if (this.parentIdNew) {
         const disabledFields = ['Account_Id__c'];
         return disabledFields.includes(fieldName);
      } else {
         return false;
      }

   }

   async handleCancel() {
      this.editmode = false;
      this.newmode = false;
      if (this.lightningMode) {
         if (this.isConsoleNavigation) {
            const { tabId } = await getFocusedTabInfo();
            await closeTab(tabId);
         }
         else {
            window.open(this.previousURL, '_self');
         }
      } else {
         window.history.back();
      }
   }

   handleToastCancel() {
      this.success = false;
   }

   async connectedCallback() {

      const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
      await delay(1);
      const currentUrl = window.location.href;
      if (currentUrl.includes('lightning')) {
         this.lightningMode = true;
      } else {
         this.lightningMode = false;
      }

      if (this.lightningMode) {
         this.parentIdNew = this.parentId;
         if (currentUrl.includes('new')) {
            this.editmode = false;
            this.newmode = true;
            this.operation = 'New';
         } else {
            this.newmode = false;
            this.editmode = true;
            this.operation = 'Edit';
            const currentUrl = window.location.href;
            const urlParts = currentUrl.split('/');
            this.recordId = urlParts[urlParts.length - 2]

         }
         var previousDetails = JSON.parse(this.redirectedFromDetails);
         if (previousDetails.type == 'standard__recordPage') {
            this.parentIdNew = previousDetails.attributes.recordId;
            this.previousURL = this.previousURL + 'r/' + previousDetails.attributes.objectApiName + '/' + previousDetails.attributes.recordId + '/' + previousDetails.attributes.actionName;

         } else if (previousDetails.type == 'standard__recordRelationshipPage') {
            this.parentIdNew = previousDetails.attributes.recordId;
            this.previousURL = this.previousURL + 'r/' + previousDetails.attributes.objectApiName + '/' + previousDetails.attributes.recordId + '/related/Case_Special_Handling__r/view';

         } else {
            if (previousDetails.state.filterName != undefined) {
               this.previousURL = this.previousURL + 'o/' + previousDetails.attributes.objectApiName + '/' + previousDetails.attributes.actionName + '?filterName=' + previousDetails.state.filterName;
            } else {
               this.previousURL = this.previousURL + 'o/' + previousDetails.attributes.objectApiName + '/' + previousDetails.attributes.actionName;
            }
         }

      } else {
         this.parentIdNew = this.parentId.replace('/', '');
         if (this.recordId) {
            this.editmode = true;
            this.operation = 'Edit';
            this.isDisabled = true;
         } else {
            this.newmode = true;
            this.operation = 'New';
            this.isDisabled = false;
         }
      }

   }
}