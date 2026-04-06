import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEmailData from '@salesforce/apex/SupportOperationsUtility.getEmailListData';
import saveEmailListData from '@salesforce/apex/SupportOperationsUtility.saveEmailList';
import { refreshApex } from '@salesforce/apex';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';
export default class SupportOperationsUtility extends LightningElement {
    @track newEmail = '';
    @track allEmails = [];
    @track error;
    hasEmail = false;
    emailListType = 'Exclude Email';
    isLoading = true; // Start in loading state
    tempallEmails = [];
    hasAccess = false;

    wiredEmailListResult;

    @wire(IsConsoleNavigation) isConsoleNavigation;

    @wire(getEmailData, { emailListType: '$emailListType' })
    wiredResult(result) {
        this.wiredEmailListResult = result;
        const data = result && result.data;
        const error = result && result.error;
        if (data) {
            this.isLoading = false;
            if (data.hasAccess) {
                this.hasAccess = true;
                let emailListResult = data.emailListValues ? data.emailListValues.split(';') : [];
                if(emailListResult.length == 0){
                    this.hasEmail = false;
                    this.allEmails = [...emailListResult];
                    this.tempallEmails = [...emailListResult];
                }else {
                    emailListResult.length > 0
                    this.hasEmail = true;
                    this.allEmails = [...emailListResult];
                    this.tempallEmails = [...emailListResult];
                }
                this.error = undefined;
            } else {
                this.hasAccess = false;
                this.showPermissionAlert();
            }
        } else if (error) {
            this.isLoading = false;
            this.error = error;
            this.allEmails = [];
            this.tempallEmails = [];
            this.hasEmail = false;
            this.toast('Error loading email list', this.errMsg(error), 'error', 'sticky');
        }
    }

    get emailListTypeOptions() {
        return [
            { label: 'Exclude Email', value: 'Exclude Email' },
            { label: 'Blacklist Email', value: 'Blacklist Email' },
        ];
    }

    handleEmailListTypeChange(event) {
        this.emailListType = event.target.value;
        this.isLoading = true;
    }

    handlePillRemove(event) {
        const emailToRemove = event.currentTarget.dataset.email;
        this.allEmails = this.allEmails.filter(email => email !== emailToRemove);
        this.hasEmail = this.allEmails.length > 0;
    }

    addEmail(event) {
        const email = this.newEmail.trim().toLowerCase();
        if (!email || !this.isEmail(email)) {
            this.toast('Invalid email', 'Please enter a valid email.', 'error', 'dismissable');
            return;
        }
        if (this.allEmails.map(d => d.toLowerCase()).includes(email)) {
            this.toast('Duplicate email!', 'Email already exists.', 'warning', 'dismissable');
            return;
        }
        this.allEmails = [...this.allEmails, email];
        this.hasEmail = this.allEmails.length > 0;
        this.newEmail = '';
    }

    handleSaveEmailList() {
        let hasNewEmails =
            this.allEmails.some(email => !this.tempallEmails.includes(email)) ||
            this.tempallEmails.some(email => !this.allEmails.includes(email));
        
        if (hasNewEmails) {
            this.isLoading = true;
            const emailListString = this.allEmails.join(';');
            saveEmailListData({ emailListType: this.emailListType, emailListValues: emailListString })
                .then(() => {
                    this.toast('Success', 'Email list updated successfully!', 'success');
                    return refreshApex(this.wiredEmailListResult);
                })
                .catch(error => {
                    this.toast('Error', this.errMsg(error), 'error', 'dismissable');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            this.toast('Nothing to update!', 'No new email added to list.', 'info', 'dismissable');
            return;
        }
    }

    handleInputChange(event) {
        this.newEmail = event.target.value;
    }

    toast(title, message, variant = 'info', mode = 'dismissable') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
    }

    errMsg(e) {
        return e?.body?.message || e?.message || 'Unknown error';
    }

    // Lightweight RFC5322-ish email check (good enough for admin UI)
    isEmail(s) {
        // no unicode punycode here; adjust if needed
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s);
    }

    async showPermissionAlert() {
        // Show native browser alert
        alert('You do not have permission to perform actions on this page.');

        // On OK, close the current console tab (or go back if not console)
        if (!this.isConsoleNavigation) {
            window.history.back();
        } else {
            const { tabId } = await getFocusedTabInfo();
            await closeTab(tabId);
        }
    }
}