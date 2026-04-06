import { LightningElement, api, wire, track } from 'lwc';
import saveRecord from '@salesforce/apex/LCC_JSMQueryResultService.triggerOrderCreation';
import executeAllQuery from '@salesforce/apex/LCC_JSMQueryResultService.executeAllQuery';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import USER_ID from '@salesforce/user/Id';

const ALLOWED_RBAC_GROUPS = [
    'Order - Management',
    'Order - Team',
    'IT Prod Ops Support'
];

export default class OpptyManualOrderCreation extends LightningElement {
    @api recordId;
    
    @track isLoading = true;
    @track errorMessage;
    @track showConfirmModal = false;
    @track opportunityOrdered = false;
    userPicklistValues;
    opptyLineCount = 0;

    // Load logged-in user
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
        const opptyQuery = `SELECT Id, SBQQ__Ordered__c, (SELECT Id FROM OpportunityLineItems LIMIT 201) FROM Opportunity WHERE Id = '${this.recordId}' LIMIT 1`;

        try {
            const queries = {
                user: userQuery,
                opportunity: opptyQuery
            };

            const results = await executeAllQuery({ theQuery: queries });
            
            const userData = results.user?.[0];
            const oppData = results.opportunity?.[0];

            this.opptyLineCount = oppData?.OpportunityLineItems?.length || 0;
            this.opportunityOrdered = oppData?.SBQQ__Ordered__c;

            if (!userData) {
                throw new Error('User details not found');
            }

            this.userPicklistValues = userData.RBAC_Group__c;

            this.evaluateAccess();

        } catch (error) {
            this.isLoading = false;
            this.errorMessage = 'Failed to fetch details: ' + error;
        }
    }

    evaluateAccess() {
        const userValues = this.userPicklistValues
            ? this.userPicklistValues.split(';')
            : [];

        const hasAccess = ALLOWED_RBAC_GROUPS.some(group =>
            userValues.includes(group)
        );

        if (!hasAccess) {
            this.isLoading = false;
            this.errorMessage = 'You are not authorized to create orders manually, hence please create support ticket with ProdOps Support or email "ProdOpsapps@rubrik.com" with details.';
            return;
        }

        if (this.opportunityOrdered) {
            this.isLoading = false;
            this.errorMessage = 'This Opportunity is already ordered.Manual order creation is not allowed.';
            return;
        }

        this.isLoading = false;
        this.showConfirmModal = true;
    }

    handleCancel() {
        this.showConfirmModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }


    handleOrderCreation() {

        this.showConfirmModal = false;
        this.isLoading = true;
        this.errorMessage = null;

        // Proceed with Apex
        const opportunity = {
            sobjectType: 'Opportunity',
            Id: this.recordId,
            SBQQ__Ordered__c: true
        };

        saveRecord({ rec: opportunity, lineCount: this.opptyLineCount })
        .then(result => {
            this.isLoading = false;

            if (!result) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Opportunity has been updated successfully',
                        variant: 'success'
                    })
                );

                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                this.errorMessage = result;
            }
        })
        .catch(error => {
            this.isLoading = false;
            this.errorMessage = (error.body?.message || 'Unexpected error occurred');
        });
    }
}