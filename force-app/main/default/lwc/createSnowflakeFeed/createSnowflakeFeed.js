import { LightningElement, track, api, wire } from 'lwc';   
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import GLOBAL_COMMITID from '@salesforce/schema/Scale_Utility_Overage__c.Global_Commit_ID__c';
import ACCOUNT_ID from '@salesforce/schema/Scale_Utility_Overage__c.Account_ID__c';
import ORIGINAL_ORDER from '@salesforce/schema/Scale_Utility_Overage__c.Original_Order__c';
import BUNDLE_TYPE from '@salesforce/schema/Scale_Utility_Overage__c.Bundle_Type__c';


import createSnowflakeFeed from '@salesforce/apex/CreateUCLSnowflakeFeedsHelper.createSnowFlakeFeed';

const fields = [GLOBAL_COMMITID, ACCOUNT_ID, ORIGINAL_ORDER,BUNDLE_TYPE];

export default class CreateSnowflakeFeed extends NavigationMixin(LightningElement) {
  @track showLoading = false;
  @api recordId;
  @api scaleUtiltityOverageRec;
  message;

  @wire(getRecord, { recordId: '$recordId', fields })
  scaleUtiltityOverageRecord;

  get globalcommitId() {
    this.scaleUtiltityOverageRec = this.scaleUtiltityOverageRecord.data;
    return getFieldValue(this.scaleUtiltityOverageRecord.data, GLOBAL_COMMITID);
  }

  handleCreate() {
    var clusterUUID = this.template.querySelector("[data-field='ClusterUUID']").value;
    var clusterUsage = this.template.querySelector("[data-field='ClusterUsage']").value;
    console.log('values are ##### ' + JSON.stringify(this.scaleUtiltityOverageRec.fields));
    var scaleUtitlityObj = new Object();
    scaleUtitlityObj['Global_Commit_ID__c'] = this.scaleUtiltityOverageRec.fields.Global_Commit_ID__c.value;
    scaleUtitlityObj['ClusterUUID'] = clusterUUID;
    scaleUtitlityObj['ClusterUsage'] = clusterUsage;
    scaleUtitlityObj['Account_ID__c'] = this.scaleUtiltityOverageRec.fields.Account_ID__c.value;
    scaleUtitlityObj['Original_Order__c'] = this.scaleUtiltityOverageRec.fields.Original_Order__c.value;
    scaleUtitlityObj['BundleType'] = this.scaleUtiltityOverageRec.fields.Bundle_Type__c.value;
    scaleUtitlityObj['recordId'] = this.recordId;

    createSnowflakeFeed({ scaleUtilityOverageRec: scaleUtitlityObj })
      .then(result => {
        console.log(result);
        this.showToast('Success!!', 'SnowFlake Feed Record created successfully!!', 'success', 'dismissable');
        // Display fresh data in the form
        this.openSnowRecordHandler(result);
      })
      .catch(error => {
        console.log(error.body.message);
        // String errorMessage = error.body.message;
        this.showToast('Failure!!', 'SnowFlake Feed Record failed to create!!' + errorMessage, 'Error', 'dismissable');
      });
  }
  
  showToast(title, message, variant, mode) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      mode: mode,
    });
    this.dispatchEvent(evt);
  }

  openSnowRecordHandler(result) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        objectApiName: 'Snowflake_Feed__c',
        actionName: 'view',
        recordId: result,
      },
    });
  }

  handleDismiss() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}