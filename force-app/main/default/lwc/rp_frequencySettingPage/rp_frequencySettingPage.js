import { LightningElement, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getLatestSetting from '@salesforce/apex/CS_AutomaticRiskProfileCreation.getRPFrequencySettingRecord';
import ALLOWED_USERS from '@salesforce/label/c.RP_Frequency_Users_Access';
import USER_ID from '@salesforce/user/Id';
import ProfileId from '@salesforce/schema/User.ProfileId';

// Schema Imports
import CUSTOM_CONFIG_OBJECT from '@salesforce/schema/Custom_Configuration_Change__c';
import DEFAULT_CONFIG_FIELD from '@salesforce/schema/Custom_Configuration_Change__c.Config_Disabled__c';
import CONFIG_FIELD from '@salesforce/schema/Custom_Configuration_Change__c.Config_Type__c';
import NEXT_RUN_FIELD from '@salesforce/schema/Custom_Configuration_Change__c.Next_Run__c';
import CONFIG_FOR_FIELD from '@salesforce/schema/Custom_Configuration_Change__c.Config_For__c';
import RECORDTYPEID__FIELD from '@salesforce/schema/Custom_Configuration_Change__c.RecordTypeId';

export default class rp_frequencySettingPage extends LightningElement {
    currentFrequency;
    lastRun = null;
    currentFrequencyFor;
    newFrequency = 'Daily';
    newStartDate;
    frequencyFor = 'CX Sync';
    minStartDate;
    lastModifiedBy;
    hasAccess = false;
    recordTypeId = '';
    recordTypeName = 'RP Frequency Config';
    disabledFieldValue= false;
    isDisabled = false;
    emptyObjectData = false;
    isLoading = false;

    frequencyOptions = [
        { label: 'Daily', value: 'Daily' },
        { label: 'Weekly', value: 'Weekly' },
        { label: 'Biweekly', value: 'Biweekly' },
        { label: 'Monthly', value: 'Monthly' },
        { label: 'Snooze with a Date picker', value: 'Snooze with a Date picker' }
    ];

    frequencyForOptions = [
        { label: 'CX Sync', value: 'CX Sync' },
        { label: 'ML Sync', value: 'ML Sync' },
        { label: 'CX & ML Both', value: 'CX & ML Both' }
    ];

    connectedCallback() {
        this.isLoading = true;
    }

    @wire(getRecord, { recordId: USER_ID, fields: [ ProfileId] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            if (data.fields.ProfileId.value != null) {
                const allowedUsers = ALLOWED_USERS.split(';').map(id => id.trim());
                this.hasAccess = allowedUsers.includes(USER_ID) || allowedUsers.includes(data.fields.ProfileId.value);
                this.isLoading = false;
                if(this.hasAccess){
                    const tomorrow = new Date();
                    tomorrow.setDate(tomorrow.getDate() + 1);
                    const formattedDate = this.formatDate(tomorrow);
                    this.newStartDate = formattedDate;
                    this.minStartDate = formattedDate;
                }
            }
        }
    }

    formatDate(date) {
        return date.toISOString().split('T')[0]; // yyyy-mm-dd
    }

    @wire(getObjectInfo, { objectApiName: CUSTOM_CONFIG_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            const rtInfos = data.recordTypeInfos;
            for (const rtId in rtInfos) {
                if (rtInfos[rtId].name === this.recordTypeName) {
                    this.recordTypeId = rtId;
                    break;
                }
            }
        } else if (error) {
            this.showToast('Error fetching object info', error, 'error');
        }
    }

    @wire(getLatestSetting)
    wiredSetting({ data, error }) {
        if (data) {
            this.disabledFieldValue = data.Config_Disabled__c;
            this.isDisabled = this.disabledFieldValue;
            this.lastRun = data.Last_Run__c;
            this.currentFrequencyFor = data.Config_For__c;
            this.currentFrequency = data.Config_Type__c;
            this.lastModifiedBy = data.LastModifiedBy.Name;
            this.recordTypeId = data.RecordTypeId;
            this.emptyObjectData = false;
        } else if (error) {
            this.showToast('Error loading data', error.body?.message || 'Unknown error', 'error');
        }
        else if (data === null) {
            this.showToast('Info','No records exist for Batch Frequency Setting, please insert a new record.','info');
            this.emptyObjectData = true;
        }
    }

    // Handlers
    handleFrequencyChange(event) {
        this.newFrequency = event.detail.value;
    }

    handleFrequencyForChange(event) {
        this.frequencyFor = event.detail.value;
    }

    handleDateChange(event) {
        this.newStartDate = event.detail.value;
    }

    handleSave() {
        if (this.isDisabled && this.disabledFieldValue) {
            this.showToast('Error', 'RP Frequency Configuration is currently disabled. Please enable it to set the frequency.', 'error');
            return;
        }

        const isDisabledMode = this.disabledFieldValue !== false;

        if (isDisabledMode) {
            this.createFrequencyRecord({
                [DEFAULT_CONFIG_FIELD.fieldApiName]: this.disabledFieldValue
            });
            return;
        }

        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        const allValid = [...inputs].every(input => input.reportValidity());

        if (!allValid) {
            this.showToast('Error', 'Please review errors before inserting the record.', 'error');
            return;
        }

        this.createFrequencyRecord({
            [CONFIG_FIELD.fieldApiName]: this.newFrequency,
            [NEXT_RUN_FIELD.fieldApiName]: this.newStartDate,
            [CONFIG_FOR_FIELD.fieldApiName]: this.frequencyFor,
            [RECORDTYPEID__FIELD.fieldApiName]: this.recordTypeId
        });
    }

    createFrequencyRecord(fields) {
        this.isLoading = true;
        createRecord({ apiName: CUSTOM_CONFIG_OBJECT.objectApiName, fields })
            .then(() => {
                this.isLoading = false;
                this.showToast('Success', 'New frequency record inserted', 'success');
                window.location.reload();
            })
            .catch(error => {
                this.isLoading = false;
                console.log('Error ==== ',error);
                this.showToast('Error', error.body?.message || 'Error inserting record', 'error');
            });
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleCheckboxChange(event) {
        this.disabledFieldValue = event.target.checked;
    }
}