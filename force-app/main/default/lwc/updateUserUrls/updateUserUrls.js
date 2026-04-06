import { LightningElement, track, api, wire } from 'lwc';
import saveUserInfoRecords from '@salesforce/apex/UpdateUserUrlsController.saveUserInfoRecords';
import saveQueueRecord from '@salesforce/apex/UpdateUserUrlsController.saveUserFieldData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getRoleData from '@salesforce/apex/UpdateUserUrlsController.isUserManager';
import getExistingUrlData from '@salesforce/apex/UpdateUserUrlsController.getExistingUrl';
import { getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';
import USER_ID from '@salesforce/user/Id';

let nextId = 1;
export default class UpdateUserUrls extends LightningElement {
    objectName = 'User_Info__c';
    objectFieldApiName = 'User__c';
    updateUserUrl = false;
    updateQueue = false;
    showMainButtons = true;
    showBackButton = false;
    @track showSpinner = false;
    @track userQueueRecord = {};
    isManager = false;
    @api isTab = false;
    currentUserId = USER_ID;
    @track rows = [
        { id: nextId++, userId: '', url: '', removable: false }
    ];

    addRow() {
        this.rows = [
            ...this.rows,
            { id: nextId++, userId: '', url: '', removable: true }
        ];
    }

    @wire(getRoleData)
    roleData({ data, error }) {
        if (data && data == true) {
            this.isManager = true;
        }
    }

    removeRow(event) {
        const rowId = parseInt(event.currentTarget.dataset.id, 10);
        this.rows = this.rows.filter(row => row.id !== rowId);
    }

    checkAction(event) {
        this.showSpinner = true;
        const actionName = event.target.dataset.id;
        if (actionName == 'updateUrl') {
            this.updateUserUrl = true;
            this.showBackButton = true;
            this.updateQueue = false;
            this.showMainButtons = false;
            setTimeout(() => {
                this.showSpinner = false;
            }, 1000);
        }
        if (actionName == 'updateQueue') {
            this.updateQueue = true;
            this.showBackButton = true;
            this.updateUserUrl = false;
            this.showMainButtons = false;
            setTimeout(() => {
                this.showSpinner = false;
            }, 1000);
        }
        if (actionName == 'backButton') {
            this.updateUserUrl = false;
            this.showBackButton = false;
            this.updateQueue = false;
            this.showMainButtons = true;
            this.showSpinner = false;
        }
    }

    async handleUserChange(event) {
        const rowId = parseInt(event.currentTarget.dataset.id, 10);
        let selectedUserId = event.detail.userId;
        let existingBookingUrl = '';
        if (Array.isArray(selectedUserId)) {
            selectedUserId = selectedUserId.length > 0 ? selectedUserId[0] : null;
        }
        if (selectedUserId) {
            try {
                //calling apex method to get URL
                let result = await getExistingUrlData({ userId: selectedUserId });
                existingBookingUrl = result != 'No User Id provided' ? result : '';
            } catch (error) {
                this.showToast('Error', error.body.message, 'error');
            }
        }
        for (let i = 0; i < this.rows.length; i++) {
            if (this.rows[i].id === rowId) {
                this.rows[i].userId = selectedUserId;
                if (existingBookingUrl) {
                    this.rows[i].url = existingBookingUrl;//setting existing value of URL
                }
                break; // Found and updated, so stop the loop
            }
        }
    }

    handleUrlChange(event) {
        const rowId = parseInt(event.currentTarget.dataset.id, 10);
        const selectedUrl = event.target.value;

        for (let i = 0; i < this.rows.length; i++) {
            if (this.rows[i].id === rowId) {
                this.rows[i].url = selectedUrl;
                break; // Found and updated, so stop the loop
            }
        }
    }
    /**User Queue Record Change Handler */
    handleFieldChange(event) {
        const field = event.target.dataset.fieldName;
        const value = event.detail.value;
        if (value != '' && value != null) {
            this.userQueueRecord[field] = value;
        }
        console.log('Submitting: ', JSON.stringify(this.userQueueRecord));
    }
    /**Handle Save***/
    handleSave() {
        this.showSpinner = true;
        if (this.updateUserUrl) {
            const valid = this.rows.every(row => row.userId && row.url);
            if (!valid) {
                this.showToast('Error', 'Please fill all fields.', 'error');
                return;
            }

            saveUserInfoRecords({ userInfoList: JSON.stringify(this.rows) })
                .then(() => {
                    //this.dispatchEvent(new CloseActionScreenEvent());
                    this.showToast('Success', 'Records saved successfully. Allow at least 1 hour before using the link.', 'success');
                    if (this.isTab) {
                        this.showMainScreen();
                    } else {
                        this.handleClose();
                    }
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.log('error=>' + error.body.message);
                    this.showToast('Error', error.body.message, 'error');
                });
        }
        if (this.updateQueue) {
            if (this.isInputValid()) {
                // Proceed to call Apex
                saveQueueRecord({ fieldMap: this.userQueueRecord })
                    .then(result => {
                        this.showToast('Success', 'Records saved successfully. Allow at least 1 hour before using the link.', 'success');
                        if (this.isTab) {
                            this.showMainScreen();
                        } else {
                            this.handleClose();
                        }
                    })
                    .catch(error => {
                        this.showSpinner = false;
                        console.log('error=>' + error.body.message);
                        this.showToast('Error', error.body.message, 'error');
                    });
            } else {
                this.showSpinner = false;
                // show error
                console.error('Validation failed.');
            }

        }
    }
    showMainScreen() {
        this.showMainButtons = true;
        this.updateQueue = false;
        this.showBackButton = false;
        this.updateUserUrl = false;
        this.rows = [{ id: nextId++, userId: '', url: '', removable: false }];
        this.showSpinner = false;
    }

    isInputValid() {
        let isValid = false;
        const automatedFieldInput = this.template.querySelector('[data-field-name="Automated_time_off_case_routing__c"]');
        const destinationQueueFieldInput = this.template.querySelector('[data-field-name="Destination_queue_for_automated_time_off__c"]');
        if (automatedFieldInput.value =='' || automatedFieldInput.value == null) {
            this.showToast('Error', 'Please select a Automated time-off case routing value', 'error');
            isValid = false;
        }
        else if(automatedFieldInput.value == 'Queue' && (destinationQueueFieldInput.value == '' || destinationQueueFieldInput.value == null)){
            this.showToast('Error', 'Please select a destination queue.', 'error');
            isValid = false;
        }
        else{
            isValid = true;
        }
        return isValid;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    async handleClose() {
        this.showSpinner = false;
        this.dispatchEvent(new CloseActionScreenEvent());
        if (this.isTab) {
            const focusedTab = await getFocusedTabInfo();

            if (focusedTab && focusedTab.tabId) {
                // Close the current tab
                await closeTab(focusedTab.tabId);
            }
        }
    }
    /**Record Edit Form Onload**/
    handleOnLoad(event) {
        this.showSpinner = true;
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        console.log('user id' + this.userId);
        if (inputFields) {
            inputFields.forEach(field => {
                const fieldName = field.fieldName;
                const fieldValue = field.value;

                if (fieldName && fieldValue != '' && fieldValue != null) {
                    this.userQueueRecord[fieldName] = fieldValue;
                }
            });
            this.showSpinner = false;
        } else {
            this.showSpinner = false;
        }
    }
}