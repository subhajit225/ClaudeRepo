import { LightningElement,api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport'
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';

import getFHRecs from '@salesforce/apex/MIPFetchFormReviewDetails.getFHRecs';
import getRMRecs from '@salesforce/apex/MIPFetchFormReviewDetails.getRMRecs';
import getPSNLRecs from '@salesforce/apex/MIPFetchFormReviewDetails.getPSNLRecs';
import getTotalRecs from '@salesforce/apex/MIPFetchFormReviewDetails.getTotalRecs';
import getEnrollRecs from '@salesforce/apex/MIPFetchFormReviewDetails.getEnrollRecs';
import getMilestoneRecs from '@salesforce/apex/MIPFetchFormReviewDetails.getMilestoneRecs';

//MIP Contract
import mipContract_Obj from '@salesforce/schema/MIP_Contract__c';
import name_Field from '@salesforce/schema/MIP_Contract__c.Name';
import startdate_Field from '@salesforce/schema/MIP_Contract__c.Start_Date__c';
import enddate_Field from '@salesforce/schema/MIP_Contract__c.End_Date__c';
import partnerContSignature_Field from '@salesforce/schema/MIP_Contract__c.Partner_Contact_of_Signature__c';

//MIP Milestone
import milestoneType_field from '@salesforce/schema/MIP_Milestone__c.Milestone_Type__c';
import status_field from '@salesforce/schema/MIP_Milestone__c.Status__c';
import contact_field from '@salesforce/schema/MIP_Milestone__c.Contact__c';
import role_field from '@salesforce/schema/MIP_Milestone__c.Role__c'
import activityDesc_field from '@salesforce/schema/MIP_Milestone__c.Activity_Description__c';
import qty_field from '@salesforce/schema/MIP_Milestone__c.Quantity__c';
import targetCompletionDate_field from '@salesforce/schema/MIP_Milestone__c.Target_Completion_Date__c';
import proof_field from '@salesforce/schema/MIP_Milestone__c.Proof_of_Performance_Requirement__c';


const mipElementFHColumns = [
    { label: 'Name', fieldName: "Name", type: 'text', hideDefaultActions: true, initialWidth:80},
    { label: 'Payout Type', fieldName: "Payout_Type__c", type: 'text', editable: true, hideDefaultActions: true, initialWidth:98,wrapText: true },
    { label: 'Account', fieldName: "Partner_Account__c", type: 'text', editable: false, hideDefaultActions: true, wrapText: true, initialWidth:82},
    { label: 'Roles', fieldName: "Roles__c", type: 'text', editable: true, hideDefaultActions: true, initialWidth:80 },
    { label: 'Max Funded Head Payout', fieldName: "Max_Funded_Head_Payout__c", type: 'currency', editable: true, hideDefaultActions: true, initialWidth:180, cellAttributes :{ alignment: 'left' } },
    { label: 'Head Count', fieldName: "Head_Count__c", type: 'number', editable: true, hideDefaultActions: true },
    { label: 'Milestones', type: 'button', typeAttributes: {title: 'View', label:'View', name: 'View', variant:'brand'},initialWidth:93},
    { label: '', type: 'button-icon', typeAttributes: {title: 'Add', iconName:'utility:add'},initialWidth:20}
    ];

const mipElementRMColumns = [
    { label: 'Name', fieldName: "Name", type: 'text', hideDefaultActions: true, initialWidth:80},
    { label: 'Payout Type', fieldName: "Payout_Type__c", type: 'text', hideDefaultActions: true, initialWidth:198,wrapText: true },
    { label: 'Max Milestone Payout', fieldName: "Max_Milestone_Payout__c", type: 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
    { label: 'Milestones', type: 'button', typeAttributes: {title: 'View', label:'View', name: 'View', variant:'brand'},initialWidth:93},
    { label: '', type: 'button-icon', typeAttributes: {title: 'Add', iconName:'utility:add'},initialWidth:20}
    ];

const mipElementPSNLTotalColumns = [
    { label: 'Name', fieldName: "Name", type: 'text', hideDefaultActions: true, initialWidth:80},
    { label: 'Prior Year Bookings (ACV)', fieldName: "Prior_Year_Bookings_ACV__c", type: 'currency', editable: true, hideDefaultActions: true, initialWidth:132, cellAttributes :{ alignment: 'left' } },
    /*{ label: 'Baseline', fieldName: "Baseline_Bookings_Expected_Growth__c", type: 'percentage', editable: true, hideDefaultActions: true, initialWidth:85 },*/
    { label: 'Tier 1', fieldName: "Tier_1_Bookings_Expected_Growth__c", type: 'percentage', editable: true, hideDefaultActions: true, initialWidth:70 },
    { label: 'Tier 2', fieldName: "Tier_2_Bookings_Expected_Growth__c", type: 'percentage', editable: true, hideDefaultActions: true, initialWidth:70 },
    { label: 'Tier 3', fieldName: "Tier_3_Bookings_Expected_Growth__c", type: 'percentage', editable: true, hideDefaultActions: true, initialWidth:70 },
    /*{ label: 'Base Dist.', fieldName: "Baseline_Bookings_Expected_Growth__c", type: 'percentage', editable: true, hideDefaultActions: true, initialWidth:80 },*/
    { label: 'T1 Dist.', fieldName: "Tier_1_Bookings_Rebate_Distribution__c", type: 'percentage', editable: true, hideDefaultActions: true, initialWidth:70 },
    { label: 'T2 Dist.', fieldName: "Tier_2_Bookings_Rebate_Distribution__c", type: 'percentage', editable: true, hideDefaultActions: true, initialWidth:70 },
    { label: 'T3 Dist.', fieldName: "Tier_3_Bookings_Rebate_Distribution__c", type: 'percentage', editable: true, hideDefaultActions: true, initialWidth:70 },
    ];

const mipElementEnrollColumns = [
    { label: 'Name', fieldName: "Name", type: 'text', hideDefaultActions: true, initialWidth:80},
    { label: 'Element Type', fieldName: "Element_Type__c", type: 'text', hideDefaultActions: true, initialWidth:100},
    { label: 'Enrollment Payout Rate', fieldName: "Enrollment_Payout_Rate__c", type: 'percentage', hideDefaultActions: true, initialWidth:170, editable: true },
    { label: 'Max Enrollment Payout', fieldName: "Max_Enrollment_Payout__c", type: 'currency', hideDefaultActions: true, editable: true, initialWidth:190, cellAttributes: { alignment: 'left' } }
    ];

const mipMilestoneColumns = [
    { label: 'Name', fieldName: "Name", type: 'text', hideDefaultActions: true},
    { label: 'Milestone Element Type', fieldName: "Milestone_Element_Type__c", type: 'text', editable: false, hideDefaultActions: true},
    { label: 'Milestone Type', fieldName: "Milestone_Type__c", type: 'text', editable: true, hideDefaultActions: true },
    { label: 'Status', fieldName: "Status__c", type: 'text', editable: true, hideDefaultActions: true },
    { label: 'Role', fieldName: "Role__c", type: 'text', editable: true, hideDefaultActions: true },
    { label: 'Quantity', fieldName: "Quantity__c", type: 'number', editable: true, hideDefaultActions: true },
    { label: 'Target Completion Date', fieldName: "Target_Completion_Date__c", type: 'date',typeAttributes:{year: "numeric",month: "short", day: "2-digit"}, editable: true, hideDefaultActions: true }
    ];


export default class mipContractreview extends LightningElement {
    @api mipcontractRecId = 'a5I8J0000000yoqUAA';
    @api recId = 'a5I8J0000000yoqUAA' ; //this.mipcontractRecId ; 'a5I8J0000000yoqUAA';

    mipElementFHRecs;
    mipElementRMRecs;
    mipElementPSNLRecs;
    mipElementTotalRecs;
    mipElementEnrollRecs;
    mipMilestoneRecs;

    mipElementRebate= false;
    modalContainer = false;
    accordianFH = false;
    accordianRM = false;
    accordianPSNL = false;
    accordianTotal = false;
    accordianEnroll = false;

    saveDraftValues = [];
    milestoneLoading;
    mipEleId;

    mipContractObj  = mipContract_Obj;
    mipElementFHColumns = mipElementFHColumns;
    mipElementRMColumns = mipElementRMColumns;
    mipElementPSNLTotalColumns = mipElementPSNLTotalColumns;
    mipElementEnrollColumns = mipElementEnrollColumns;
    mipMilestoneColumns = mipMilestoneColumns;

    
    mipContractFields = [name_Field, partnerContSignature_Field, startdate_Field, enddate_Field];
    mipMilestoneFields = [milestoneType_field, status_field, contact_field, role_field, qty_field, targetCompletionDate_field, activityDesc_field, proof_field];

    @wire(getFHRecs, {mipcontractId : '$recId'})
    wiredFHRecs(result) {
        if (Array.isArray(result.data) && result.data.length) {

            //following logic is required for getting lookup account name
            //Also as "result " is readonly, the below logic is workaround
            let tempResult = [];
            for (var i = 0; i < result.data.length; i++) {
                tempResult.push({
                    Id : result.data[i].Id,
                    Name : result.data[i].Name,
                    Element_Type__c : result.data[i].Element_Type__c,
                    Payout_Type__c : result.data[i].Payout_Type__c,
                    Partner_Account__c : result.data[i].Partner_Account__r.Name,
                    Roles__c : result.data[i].Roles__c,
                    Max_Funded_Head_Payout__c : result.data[i].Max_Funded_Head_Payout__c,
                    Head_Count__c : result.data[i].Head_Count__c
                })
            }
            let finalResult = {};
            finalResult.data = [];
            finalResult.data = tempResult;
            this.mipElementFHRecs=finalResult;

            //Used to refresh the table when record updated
            this.mipElementFHRecsRefresh = result;
            this.accordianFH = true;
        }
    }

   @wire(getRMRecs, {mipcontractId : '$recId'})
    wiredRMRecs (result) {
        if (Array.isArray(result.data) && result.data.length) {
            this.mipElementRMRecs=result;
            this.accordianRM = true;
            this.mipElementRebate= true;
        }
    }
    @wire(getPSNLRecs, {mipcontractId : '$recId'})
    wiredPSNLRecs (result) {
        if (Array.isArray(result.data) && result.data.length) {
            this.mipElementPSNLRecs=result;
            this.accordianPSNL = true;
            this.mipElementRebate= true;
        }
    }
    @wire(getTotalRecs, {mipcontractId : '$recId'}) 
    wiredTotalRecs (result) {
        if (Array.isArray(result.data) && result.data.length) {
            this.mipElementTotalRecs=result;
            this.accordianTotal = true;
            this.mipElementRebate= true;
        }
    }
    @wire(getEnrollRecs, {mipcontractId : '$recId'}) 
    wiredEnrollRecs (result) {
        if (Array.isArray(result.data) && result.data.length) {
            this.mipElementEnrollRecs=result;
            this.accordianEnroll = true;
            //this.mipElementRebate= true;
        }
    }

    handleSaveContract(){
        this.showToast('Success', 'MIP Contract Updated Successfully!', 'success', 'dismissable');   
    }

    handleSaveFH(event){
        this.handleSave(event);
    }

    handleSaveRM(event){
        this.handleSave(event);
    }

    handleSavePSNL(event){
        this.handleSave(event);
    }

    handleSaveTotal(event){
        this.handleSave(event);
    }

    handleSaveEnroll(event){
        this.handleSave(event);
    }

    handleSaveMilestone(event){
        this.handleSave(event);
    }


    handleSave(event) {
        console.log(event.target.dataset.id);
        this.saveDraftValues = event.detail.draftValues;
        let clickedFrom = event.target.dataset.id;
        const recordInputs = this.saveDraftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });
 
        // Updating the records using the UiRecordAPi
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(res => {
            this.showToast('Success', 'Records Updated Successfully!', 'success', 'dismissable');
            this.saveDraftValues = [];
            return this.refresh(clickedFrom);
        }).catch(error => {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showToast('Error', message, 'error', 'dismissable');
        }).finally(() => {
            this.saveDraftValues = [];
        });
    }
 
    showToast(title, message, variant, mode){
        const evt = new ShowToastEvent({
                title: title,
                message:message,
                variant: variant,
                mode: mode
            });
            this.dispatchEvent(evt);
    }
 
    // This function is used to refresh the table once data updated
    // Update the table based on save button
    refresh(clickEvt) {
        if(clickEvt === 'Funded Head'){
            refreshApex(this.mipElementFHRecsRefresh);
        }else if(clickEvt === 'Rebate Milestone'){
            refreshApex(this.mipElementRMRecs);
        }else if(clickEvt === 'PSNL Bookings'){
            refreshApex(this.mipElementPSNLRecs);
        }else if(clickEvt === 'Total Bookings'){
            refreshApex(this.mipElementTotalRecs);
        }else if(clickEvt === 'Enrollment'){
            refreshApex(this.mipElementEnrollRecs);
        }else{
            this.showMilestones();
        }
    }

    showMilestones(event){
        this.resetFlags();
        if(event && event.detail && event.detail.action.title === 'Add'){
            this.showCreateMilestone = true;
            this.milestoneId = event.detail.row.Id;
        }else{
            this.milestoneLoading = true;
            if(event){
                this.mipEleId = event.detail.row.Id;
            }
            //Adding parameter of current time, as imperative apex does not refresh unless provided parameter values are changed
            var d = new Date();
            getMilestoneRecs({ mipElementId: this.mipEleId, currentTime : d})
            .then((result) => {
                    if(result.length){
                        this.mipMilestoneRecs = result;
                    }else{
                        this.noMilestones = true;
                    }
                    this.milestoneLoading = false;
                    this.error = undefined;
                })
            .catch((error) => {
                this.error = error;
                this.milestoneLoading = false;
                this.mipMilestoneRecs = undefined;
            });
        }
    }

    resetFlags(){
        this.mipMilestoneRecs = null;
        this.noMilestones = false;
        this.modalContainer = true;
        this.showCreateMilestone = false;
    }

    createMilestone(event) {
        event.preventDefault(); // stop the form from submitting
        const fields = event.detail.fields;
        fields.MIP_Element__c = this.milestoneId; // modify a field
        this.template.querySelector('.milestone-rec-form').submit(fields);
    }

    submit(){
        this.showToast('Success', 'Submitted Successfully', 'success', 'dismissable');

        const endFlow = new FlowNavigationFinishEvent ();
        this.dispatchEvent(endFlow);
    }

    closeModalAction(){
        this.modalContainer = false;
    }

    connectedCallback() {
        console.log('mipcontractRecId : ' +this.mipcontractRecId);
        this.recId = this.mipcontractRecId;
    }
}