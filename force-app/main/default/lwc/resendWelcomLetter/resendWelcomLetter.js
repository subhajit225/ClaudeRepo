import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import executeAllQuery from '@salesforce/apex/LCC_JSMQueryResultService.executeAllQuery';
import submitOrderDetails from '@salesforce/apex/LCC_JSMQueryResultService.saveShippedOrder';
import USER_ID from '@salesforce/user/Id';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ORDER_OBJECT from '@salesforce/schema/Order';
import WL_RESENDREASON_FIELD from '@salesforce/schema/Order.WL_ResendReason__c';

export default class ResendWelcomLetter extends LightningElement {
    recordId;
    @track parentOrder = { hasEmails: false };
    isLoading = true;
    isValidUser = false;
    isAspenOrder = false;
    step = 1;
    skipSecond = false;
    isCommentsRequired = false;
    isResendReasonRequired = false;

    @track resendReasonOptions = [];
    @track letterTypeOptions = [];

    // Properties to track specific access conditions
    @track isValidOrderType = true;
    @track isOrderStatusShipped = true;
    @track isUserRBACAuthorized = true;

    @track objWrapper = {
        welcomeletterType: 'hardware',
        selectedResendReasons: [],
        resendComment: '',
        oppConEmail: '',
        primaryOCREmail: ''
    };

    get selectedLetterType() {
        return this.objWrapper.welcomeletterType;
    }

    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: WL_RESENDREASON_FIELD
    })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.resendReasonOptions = data.values;
            console.log('this.resendReasonOptions',JSON.stringify(this.resendReasonOptions));
        } else if (error) {
            console.error('Error fetching picklist values', error);
            this.showToastMessage('Error!', 'Failed to fetch resend reasons.', 'error');
        }
    }

    @wire(CurrentPageReference)
    getPageRef({ state }) {
        if (state && state.recordId) {
            this.recordId = state.recordId;
        }
        if(this.recordId){
            this.isLoading = true;
            this.fetchUserAndOrderDetails();
        }
    }

    async fetchUserAndOrderDetails() {
        this.isLoading = true;

        const userQuery = `SELECT Id, RBAC_Group__c FROM User WHERE Id = '${USER_ID}'`;
        const orderFields = [
            'Id', 'SD_Status__c', 'Order_Status__c', 'Welcome_Letter_Status__c', 'ProcessType__c',
            'Polaris_Contact_Email__c', 'Welcome_Letter_Contact_Email__c',
            'POC_Opportunity__r.Polaris_Portal_Contact__r.Email', 'Opportunity.Polaris_Portal_Contact__r.Email',
            'Type', 'POC_Opportunity__c', 'OpportunityId'
        ].join(', ');
        const orderQuery = `SELECT ${orderFields} FROM Order WHERE Id = '${this.recordId}' LIMIT 1`;

        try {
            const queries = {
                user: userQuery,
                order: orderQuery
            };

            const results = await executeAllQuery({ theQuery: queries });
            
            const userData = results.user?.[0];
            const orderData = results.order?.[0];

            if (userData) {
                const userRBACGroup = userData.RBAC_Group__c;
                const allowedGroups = ['IT Prod Ops Support', 'Order - Management', 'Order - Team'];
                this.isUserRBACAuthorized = userRBACGroup && allowedGroups.some(group => userRBACGroup.includes(group));
            }

            if (this.isUserRBACAuthorized && orderData) {
                const {
                    Welcome_Letter_Contact_Email__c, Polaris_Contact_Email__c, Welcome_Letter_Status__c,
                    Type, Order_Status__c, ProcessType__c, SD_Status__c, POC_Opportunity__c, OpportunityId,
                    POC_Opportunity__r, Opportunity
                } = orderData;

                this.parentOrder = {
                    ...this.parentOrder,
                    Welcome_Letter_Contact_Email__c,
                    Polaris_Contact_Email__c,
                    Welcome_Letter_Status__c
                };

                this.isValidOrderType = (Type === 'Revenue' || Type === 'POC');
                this.isOrderStatusShipped = (Order_Status__c === 'Shipped');
                this.isValidUser = this.isValidOrderType && this.isOrderStatusShipped;

                const emailAddresses = new Set();

                const rscContactEmail = (Type === 'POC')
                    ? POC_Opportunity__r?.Polaris_Portal_Contact__r?.Email
                    : Opportunity?.Polaris_Portal_Contact__r?.Email;

                if (rscContactEmail) {
                    emailAddresses.add(rscContactEmail);
                    this.objWrapper.oppConEmail = rscContactEmail;
                }

                if (ProcessType__c === 'Aspen') {
                    this.isAspenOrder = true;
                    this.letterTypeOptions = [
                        { label: 'Software Welcome Letter ( ASPEN/Non-ASPEN )', value: 'software' }
                    ];
                    this.objWrapper.welcomeletterType = 'software';
                    if (SD_Status__c === 'Success') {
                        this.letterTypeOptions.push({ label: 'Hardware Only ( For ASPEN )', value: 'hardware' });
                    }
                } else {
                    this.letterTypeOptions = [
                        { label: 'Software Welcome Letter ( ASPEN/Non-ASPEN )', value: 'software' },
                        { label: 'Hardware Only ( For Non-ASPEN )', value: 'hardware' }
                    ];
                }

                const ordOpportunityId = (Type === 'POC') ? POC_Opportunity__c : OpportunityId;

                if (ordOpportunityId) {
                    const oppContactRoleQuery = `SELECT Id, Contact.Email FROM OpportunityContactRole WHERE OpportunityId = '${ordOpportunityId}' AND IsPrimary = TRUE LIMIT 1`;
                    const contactRoleResults = await executeAllQuery({ theQuery: { contactRole: oppContactRoleQuery } });
                    const contactRole = contactRoleResults.contactRole?.[0];

                    if (contactRole?.Contact?.Email) {
                        emailAddresses.add(contactRole.Contact.Email);
                        this.objWrapper.primaryOCREmail = contactRole.Contact.Email;
                    }
                }

                this.parentOrder.hasEmails = emailAddresses.size > 0;
            } else {
                this.isValidUser = false;
            }

        } catch (error) {
            console.error('Error fetching data:', error);
            this.showToastMessage('Error!', 'Failed to fetch user or order details.', 'error');
            this.isValidUser = false;
            this.isUserRBACAuthorized = false;
        } finally {
            this.isLoading = false;
        }
    }

    handleInputChange(event) {
        this.objWrapper[event.target.name] = event.target.value;
        this.isFormValid();
    }

    handleSelectOptionList(event) {
        this.objWrapper.selectedResendReasons = event.detail.value;

        this.skipSecond = !(
            this.objWrapper.selectedResendReasons.includes('Wrong Email or Wrong Contact') ||
            this.objWrapper.selectedResendReasons.includes('Bounce Back')
        );

        this.isCommentsRequired = this.objWrapper.selectedResendReasons.includes('Other');
        this.isFormValid();
    }

    handleNext() {
        console.log('this.step'+this.step);
        if (this.step === 1) {
            console.log('this.step inside 1'+this.step);
            if (!this.isFormValid()) {
                return;
            }
            this.step = this.skipSecond ? 3 : 2;
            this.prepareEmailAddresses();
        } else if (this.step === 3) {
            console.log('this.step inside 3'+this.step);
            this.handleSubmit();
        } else {
            console.log('this.step else'+this.step);
            this.step += 1;
        }
    }

    handlePrevious() {
        if (this.step > 1) {
            this.step = (this.step === 3 && this.skipSecond) ? 1 : this.step - 1;
        }
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSubmit() {
        this.isLoading = true;
        const orderToBeUpdated = this.populateFieldsForOrderUpdate();

        try {
            if (this.parentOrder.Welcome_Letter_Status__c != null) {
                await this.clearWelcomeLetterStatus();
            }
            await this.submitOrder(orderToBeUpdated);
        } catch (error) {
            this.isLoading = false;
            this.handleError(error, 'Error submitting order.');
        }
    }

    get isFirst() {
        return this.step === 1;
    }

    get isSecond() {
        return this.step === 2;
    }

    get isThird() {
        return this.step === 3;
    }

    get nextButtonLabel() {
        return this.step === 1 ? 'Next' : this.step === 2 ? 'Confirm' : 'Submit';
    }

    get disableNext() {
        return this.step === 3 ? !this.parentOrder.hasEmails : false ;
    }

    prepareEmailAddresses() {
        const emailAddresses = new Set();
        if (this.skipSecond) {
            emailAddresses.add(this.parentOrder.Welcome_Letter_Contact_Email__c ?? null);
            emailAddresses.add(this.parentOrder.Polaris_Contact_Email__c ?? null);
        } else {
            emailAddresses.add(this.objWrapper.oppConEmail);
            emailAddresses.add(this.objWrapper.primaryOCREmail);
        }

        const filteredEmails = new Set([...emailAddresses].filter(email => email));

        if (filteredEmails.size === 0) {
            this.showToastMessage('Error!', 'No email address found for Welcome E-Mail Letter.', 'error');
            this.step = 1;
        }
        this.parentOrder.emailAddresses = [...filteredEmails];
        this.parentOrder.hasEmails = (filteredEmails.size > 0);
    }

    isFormValid() {
        let isValid = true;
        this.isResendReasonRequired = false;

        if (!this.objWrapper.selectedResendReasons || this.objWrapper.selectedResendReasons.length === 0) {
            this.isResendReasonRequired = true;
            isValid = false;
        }

        const commentInput = this.template.querySelector('lightning-textarea');
        if (this.isCommentsRequired) {
            if (!commentInput || !commentInput.value || commentInput.value.trim() === '') {
                if (commentInput) {
                    commentInput.setCustomValidity('Please enter comments');
                }
                isValid = false;
            } else {
                commentInput.setCustomValidity('');
            }
            commentInput?.reportValidity();
        } else if (commentInput) {
            commentInput.setCustomValidity('');
            commentInput?.reportValidity();
        }

        return isValid;
    }

    populateFieldsForOrderUpdate() {
        const body = {
            Id: this.recordId,
            Has_WelcomeLetter_Contact__c: true,
            Welcome_letter_sent_for_the_first_time__c: false,
            Welcome_Letter_Status__c: this.objWrapper.welcomeletterType === 'software'
                ? 'Send S/W welcome letter'
                : 'Send H/W welcome letter',
            WL_ResendReason__c: this.objWrapper.selectedResendReasons.join(';'),
            WL_ResendComments__c: this.objWrapper.resendComment
        };

        if(this.objWrapper.welcomeletterType === 'software'){
            body.WelcomeEmailSentforSoftwareProducts__c = false;
        }

        if (!this.skipSecond) {
            body.Welcome_Letter_Contact_Email__c = this.objWrapper.oppConEmail;
            body.Polaris_Contact_Email__c = this.objWrapper.primaryOCREmail;
        }

        return body;
    }

    async clearWelcomeLetterStatus() {
        const clearBody = { Id: this.recordId, Welcome_Letter_Status__c: null };
        return await submitOrderDetails({ rec: clearBody });
    }

    async submitOrder(body) {
        try {
            const result = await submitOrderDetails({ rec: body });
            if (result) {
                this.showToastMessage('Error!', result, 'error');
            } else {
                this.handleClose();
                this.showToastMessage('Success!', 'Order updated successfully', 'success');
            }
        } catch (error) {
            throw error;
        } finally {
            this.isLoading = false;
        }
    }

    handleError(error, defaultMessage) {
        let errorMessage = defaultMessage || 'An unknown error occurred.';
        if (error?.body?.message) {
            errorMessage = error.body.message;
        } else if (error?.message) {
            errorMessage = error.message;
        }
        this.showToastMessage('Error!', errorMessage, 'error');
    }

    showToastMessage(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}