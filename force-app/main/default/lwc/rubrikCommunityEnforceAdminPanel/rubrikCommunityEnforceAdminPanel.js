import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAccountDetails from '@salesforce/apex/RubrikEnforceAdminPanelController.getAccountDetails';
import updateAccount from '@salesforce/apex/RubrikEnforceAdminPanelController.updateEnforceAdminUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class RubrikCommunityEnforceAdminPanel extends LightningElement {
    @api recordId;
    accounts;
    accountId;
    enforceAdminPanel;
    error;
    isAuditAvailable = false;
    audits;
    auditUserName;
    auditUserEmail;
    auditDate;
    auditValue;
    disableToggle = false;
    showSpinner = false;


    @wire(getAccountDetails, { AccountId: '$recordId'})
    wiredAccount(value) {
        this.accounts = value;
        const { data, error } = value;

        if (error) {
            this.handleError(error);
        } else if (data) {
            this.accountId = data[0].Id;
            this.enforceAdminPanel = data[0].Enforce_Admin_User__c;
            this.audits = data[0].Account_Audit_Logs__r;

             if (this.audits) {
                this.isAuditAvailable = true;
                this.auditUserName = this.audits[0].UserFullName__c;
                this.auditUserEmail = this.audits[0].Email__c;
                this.auditDate = this.audits[0].CreatedDate;
                this.auditValue = this.audits[0].NewValue__c ? 'disabled' : 'enabled';
            }
        }

        this.showSpinner = false; // added for refresh
        this.disableToggle = false; // added for refresh
    }

    handleToggleChange(event) {
        this.disableToggle = true;
        this.showSpinner = true;
        this.isAuditAvailable = false;
        this.handleUpdateAccount(event.target.checked);
    }

    handleUpdateAccount(enforceAdminUser) {
        updateAccount({ accountId: this.accountId,  enforceAdminUser: enforceAdminUser})
            .then((result) => {
                refreshApex(this.accounts);
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    handleError(error) {
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error getting enforce admin panel value',
                message,
                variant: 'error',
            }),
        );
    }

}