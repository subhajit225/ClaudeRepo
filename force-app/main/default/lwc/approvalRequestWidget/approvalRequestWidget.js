import { LightningElement, wire, track } from 'lwc';
import Id from '@salesforce/user/Id';
import getApprovalRequests from '@salesforce/apex/ApprovalRequestWidgetController.getApprovalRequests';
import { NavigationMixin } from 'lightning/navigation';

export default class ApprovalRequestWidget extends NavigationMixin(LightningElement) {
    @track approvalRequests = [];
    @track pagedApprovalRequests = [];
    currentPage = 1;
    pageSize = 10;

    columns = [
        {
            label: 'Approval Name',
            fieldName: 'url',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },        
        {
            label: 'Status',
            fieldName: 'Status',
            type: 'text'
        },
        {
            label: 'Opportunity Name',
            fieldName: 'oppNumber',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'OpportunityName' },
                target: '_blank'
            }

        },
        {
            label: 'Opportunity Stage',
            fieldName: 'Stage',
            type: 'text'
        },
        {
            label: 'Quote: ETM Area',
            fieldName: 'ETMArea',
            type: 'text'
        },
        {
            label: 'Quote: ETM Region',
            fieldName: 'ETMRegion',
            type: 'text'
        },
        {
            label: 'Quote Number',
            fieldName: 'QuoteNumber',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'QuoteName' },
                target: '_blank'
            }
        },
        {
            label: 'Quote: ApprovalStatus',
            fieldName: 'QuoteAppStatus',
            type: 'text'
        },
        {
            label: 'Quote: Net Amount',
            fieldName: 'QuoteNetAmount',
            type: 'text'
        },
        {
            label: 'ACV Estimate',
            fieldName: 'ACVEstimate',
            type: 'double'
        },
        {
            label: 'Approval: Created By',
            fieldName: 'AppCreateBy',
            type: 'text'
        },
        {
            label: 'Deal Desk Case',
            fieldName: 'DDCaseNumber',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'DDCaseName' },
                target: '_blank'
            }
        }
    ];

    @wire(getApprovalRequests, { loggedInUserId: Id })
    userDetails({ error, data }) {
        if (error) {
            console.error('Error:', error);
            this.approvalRequests = [];
        } else if (data) {
            this.approvalRequests = data.map(record => ({
                ...record,
                url: `/${record.Id}`,
                QuoteNumber: record.Deal_Desk_Case__c != null ? '' : (record.Quote__c ? `/${record.Quote__c}` : ''),
                QuoteName: record.Quote__r ? record.Quote__r.Name : '',
                Status: record.sbaa__Status__c,
                oppNumber: record.Deal_Desk_Case__c != null ? `/${record.Deal_Desk_Case__r.Opportunity__c}` : `/${record.Quote__r.SBQQ__Opportunity2__c}`,
                OpportunityName: record.Deal_Desk_Case__c != null ? record.Deal_Desk_Case__r.Opportunity__r.Name : (record.Quote__c ? record.Quote__r.SBQQ__Opportunity2__r.Name: ''),
                Stage: record.Deal_Desk_Case__c != null ? record.Deal_Desk_Case__r.Opportunity__r.StageName : (record.Quote__c ? record.Quote__r.SBQQ__Opportunity2__r.StageName : ''),
                ETMArea: record.Deal_Desk_Case__c != null ? record.Deal_Desk_Case__r.Opportunity__r.ETM_Area__c : (record.Quote__c ? record.Quote__r.ETM_Area__c : ''),
                ETMRegion: record.Deal_Desk_Case__c != null ? record.Deal_Desk_Case__r.Opportunity__r.ETM_Region__c : (record.Quote__c ? record.Quote__r.ETM_Region__c : ''),
                QuoteAppStatus: record.Deal_Desk_Case__c != null ? '' : (record.Quote__c ? record.Quote__r.ApprovalStatus__c: ''),
                QuoteNetAmount: record.Deal_Desk_Case__c != null ? '' : (record.Quote__c ? record.Quote__r.SBQQ__NetAmount__c: ''),
                ACVEstimate: (record.Quote__c != null && record.Quote__r.SBQQ__NetAmount__c != null && record.Quote__r.SBQQ__SubscriptionTerm__c != null) ? Math.round(((record.Quote__r.SBQQ__NetAmount__c/record.Quote__r.SBQQ__SubscriptionTerm__c) * 12) * 100) / 100 : '',
                AppCreateBy: record.CreatedBy.Name,
                DDCaseNumber: record.Deal_Desk_Case__c != null ? `/${record.Deal_Desk_Case__c}` : '',
                DDCaseName: record.Deal_Desk_Case__c != null ? record.Deal_Desk_Case__r.Name : ''
            }));
            this.updatePagedApprovalRequests();
        }
    }

    updatePagedApprovalRequests() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.pagedApprovalRequests = this.approvalRequests.slice(start, end);
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updatePagedApprovalRequests();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.updatePagedApprovalRequests();
        }
    }

    get isPreviousDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }

    get totalPages() {
        return Math.ceil(this.approvalRequests.length / this.pageSize);
    }
}