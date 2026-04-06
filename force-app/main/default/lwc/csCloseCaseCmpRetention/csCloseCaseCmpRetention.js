import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getCaseRecord from '@salesforce/apex/CS_CaseRetentionController.getRetentionCaseRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import CASE_ID_FIELD from '@salesforce/schema/Case.Id';
import RESOLUTION_DETAILS_FIELD from '@salesforce/schema/Case.Resolution_Details__c';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';

import { getObjectInfo,getPicklistValues } from "lightning/uiObjectInfoApi";
import CASE_OBJECT from "@salesforce/schema/Case";
import FIELD_CASE_RISK_STATUS from "@salesforce/schema/Case.Risk_Status__c";

const CLOSED_CASE_STATUS = ['New', 'In Progress'];
export default class CloseCaseCmpRetention extends NavigationMixin(
    LightningElement
) {
    @api recordId;
    @track resolutionDetails = '';
    @track caseRecord;

    allPdmFeatures = []
    pdmFeatures;
    allEntitlements = []
    entitlements;
    isLoading = true;

    //Pagination variables
    pageSize = 5;
    currentPage = 1;
    currentPageEntitlement = 1;
    totalPages = 0;
    totalPagesEntitlements = 0;

    columns = [
        { label: 'Id', fieldName: 'Id', type: 'text' },
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Feature', fieldName: 'Feature__c', type: 'text' }
    ];
    columnsEntitlement = [
        { label: 'Id', fieldName: 'Id', type: 'text' },
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'ACV', fieldName: 'AnnualContractValue__c', type: 'text' },
        { label: 'Expiry Date', fieldName: 'EndDate', type: 'text' }
    ];

    @wire(IsConsoleNavigation) isConsoleNavigation;

    get activeSections(){
        return ['caseInfo','caseDescription','resolutionInfo','riskGovernance'];
    }

    get vfPageUrl() {
        return `/apex/CloseCaseRetention?recordId=${this.recordId}`;
    }

    get disablePrevious() {
        return this.currentPage <= 1;
    }
    get disablePreviousEntitlement() {
        return this.currentPageEntitlement <= 1;
    }

    get disableNext() {
        return this.currentPage >= this.totalPages;
    }

    get disableNextEntitlement() {
        return this.currentPageEntitlement >= this.totalPagesEntitlements;
    }

    get ownerName() {
        return this.caseRecord?.Owner?.Name || '';
    }

    get caseNumber() {
        return this.caseRecord?.CaseNumber || '';
    }

    get subject() {
        return this.caseRecord?.Subject || '';
    }

    get description() {
        return this.caseRecord?.Description || '';
    }

    get accountName() {
        return this.caseRecord?.Account?.Name || '';
    }

    get createdDate() {
        return this.caseRecord?.CreatedDate || '';
    }

    get contactName() {
        return this.caseRecord?.Contact?.Name || '';
    }

    get workaroundProvided() {
        return this.caseRecord?.Workaround_Provided__c || '';
    }
    riskStatus;

    get riskGovernanceOwner() {
        return this.caseRecord?.Risk_Profile__r?.Owner.Name || '';
    }

    get phase() {
        return this.caseRecord?.Phase__c || '';
    }

    get currentStatusAndNextSteps(){
        return this.caseRecord?.Current_Status_Next_Steps__c || '';
    }

    get subPhase() {
        return this.caseRecord?.Sub_Phase__c || '';
    }

    get riskProfileRecordNumber() {
        return this.caseRecord?.Risk_Profile__r?.Name || '';
    }

    get riskType() {
        return this.caseRecord?.Risk_Profile__r?.Risk_Type__c || '';
    }

    get entitlementName() {
        return this.caseRecord?.Risk_Profile__r?.Entitlement__r?.Name || '';
    }

    get entitlementACV() {
        let entitlementACV = this.caseRecord?.Risk_Profile__r?.Entitlement_ACV__c?.toString();
        return entitlementACV ? '$'+ entitlementACV : '';
    }

    get entitlementExpiryDate() {
        return this.caseRecord?.Risk_Profile__r?.Entitlement_Expiry_Date__c || '';
    }

    get acvAtRisk(){
        let acvAtrisk = this.caseRecord?.ACV_At_Risk__c?.toString();
        return acvAtrisk ? '$'+ acvAtrisk : '';
    }

    get acvMitigated(){
        let acvMitigated = this.caseRecord?.ACV_mitigated__c?.toString();
        return acvMitigated ? '$'+ acvMitigated : '';
    }

    get riskResource(){
        return this.caseRecord?.Resolution__c || ''
    }

    get riskOpportunity(){
        return this.caseRecord?.Risk_Opportunity__r?.Name || ''
    }

    @track objectInfo;
    get options() {
        return this.picklistResults.data?.values;
    }

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    get retentionCaseRecordTypeId() {                
        if(this.objectInfo.data == null) {
            return '';
        }
        
        const rtis = this.objectInfo.data.recordTypeInfos;
        return Object.keys(rtis).find((rti) => rtis[rti].name === "Retention Case");
    }

    @wire(getPicklistValues, { recordTypeId: "$retentionCaseRecordTypeId", fieldApiName: FIELD_CASE_RISK_STATUS })
    picklistResults

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {        
        if (currentPageReference) {
            this.recordId = currentPageReference?.state?.c__recordId;
            if (this.recordId) {
                this.fetchCaseRecord();
            }
        }
    }
    get isCaseClosed(){
        return this.caseRecord?.Mitigation_Case_Closed__c;
    }
    connectedCallback() {
        this.fetchCaseRecord();
    }
    fetchCaseRecord() {
        this.isLoading = true;
        getCaseRecord({ caseId: this.recordId })
            .then(result => {                
                this.caseRecord = result?.caseRecord;
                this.pdmFeature = result?.pdmFeatureRecord;
                this.riskStatus = this.caseRecord.Risk_Status__c;
                if (result?.pdmFeatureRecord) {
                    this.allPdmFeatures = result?.pdmFeatureRecord;
                    this.totalPages = Math.ceil(result?.pdmFeatureRecord?.length / this.pageSize);
                    this.setPage(1);
                } else {
                    this.allPdmFeatures = [];
                }
                if (result?.riskProfileEntitlements) {
                    this.allEntitlements = result?.riskProfileEntitlements
                    .filter(item => item.Entitlement__r)
                    .map(item => item.Entitlement__r);
                    this.totalPagesEntitlements = Math.ceil(result?.riskProfileEntitlements?.length / this.pageSize);
                    this.setPageEntitlements(1);
                } else {
                    this.allEntitlements = [];
                }
                this.resolutionDetails = this.caseRecord?.Resolution_Details__c;
                this.isLoading = false;
            })
            .catch(error => {
                this.errorToast('Error loading case', error);
                this.isLoading = false;
            });
    }

    setPage(pageNumber) {
        this.currentPage = pageNumber;
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = this.currentPage * this.pageSize;
        this.pdmFeatures = this.allPdmFeatures.slice(startIndex, endIndex);
    }
    setPageEntitlements(pageNumber) {
        this.currentPageEntitlement = pageNumber;
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = this.currentPage * this.pageSize;
        this.entitlements = this.allEntitlements.slice(startIndex, endIndex);
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.setPage(this.currentPage - 1);
        }
    }
    previousPageEntitlement() {
        if (this.currentPageEntitlement > 1) {
            this.setPageEntitlements(this.currentPageEntitlement - 1);
        }
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.setPage(this.currentPage + 1);
        }
    }

    nextPageEntitlement() {
        if (this.currentPageEntitlement < this.totalPagesEntitlements) {
            this.setPageEntitlements(this.currentPageEntitlement + 1);
        }
    }

    handleCancel() {
        this.closeTab();
        this.closeAndNavigateToCase();
    }

    handleResolutionChange(event) {
        this.resolutionDetails = event.target.value;  
    }
    handleRiskStatusChange(event) {
        this.riskStatus = event.detail.value;
    }
    handleLoad(event){
        const style = document.createElement('style');
        style.innerText = `c-cs-close-case-cmp-retention lightning-helptext,c-cs-close-case-cmp-retention .slds-form-element__label {
            display: none;
            }`;
        this.template.querySelector('.no-help-text')?.appendChild(style);
    }
    handleSave(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.isLoading = true;   
    }
    handleFormSuccess(event) {
        this.isLoading = false;
        this.closeTab();
        this.closeAndNavigateToCase();
    }
    count = 0;
    handleFormError(event) {
        this.isLoading = false;    
    }

    successToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'success'
            })
        );
    }

    errorToast(title, error) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: error,
                variant: 'error',
            })
        );
    }
    closeAndNavigateToCase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }

    async closeTab() {
        if (!this.isConsoleNavigation) {
            return this.fetchCaseRecord();
        }
        const { tabId } = await getFocusedTabInfo();
        await closeTab(tabId);
    }

}