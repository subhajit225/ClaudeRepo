import { LightningElement , api, wire} from 'lwc';
import ISSUE_CATEGORY from '@salesforce/schema/Assist_Request__c.Issue_Understanding_Category__c';
import ISSUE_REASON from '@salesforce/schema/Assist_Request__c.Issue_Understanding_Reason__c';
import ISSUE_COMMENT from '@salesforce/schema/Assist_Request__c.Issue_Understanding_Comment__c';
import RESEARCH_SKILLS_REASON from '@salesforce/schema/Assist_Request__c.Research_Skills_Reason__c';
import RESEARCH_SKILLS_CATEGORY from '@salesforce/schema/Assist_Request__c.Research_Skills_Category__c';
import RESEARCH_SKILLS_COMMENT from '@salesforce/schema/Assist_Request__c.Research_Skills_Comment__c';
import TROUBLESHOOTING_SKILLS_REASON from '@salesforce/schema/Assist_Request__c.Troubleshooting_Skills_Reason__c';
import TROUBLESHOOTING_SKILLS_CATEGORY from '@salesforce/schema/Assist_Request__c.Troubleshooting_Skills_Category__c';
import TROUBLESHOOTING_SKILLS_COMMENT from '@salesforce/schema/Assist_Request__c.Troubleshooting_Skills_Comment__c';
import RESOLUTION_SKILL_REASON from '@salesforce/schema/Assist_Request__c.Resolution_Skill_Reason__c';
import RESOLUTION_SKILL_CATEGORY from '@salesforce/schema/Assist_Request__c.Resolution_Skill_Category__c';
import RESOLUTION_SKILL_COMMENT from '@salesforce/schema/Assist_Request__c.Resolution_Skill_Comment__c';
import CASE_COMMUNICATION_REASON from '@salesforce/schema/Assist_Request__c.Case_Communication_Reason__c';
import CASE_COMMUNICATION_CATEGORY from '@salesforce/schema/Assist_Request__c.Case_Communication_Category__c';
import CASE_COMMUNICATION_COMMENT from '@salesforce/schema/Assist_Request__c.Case_Communication_Comment__c';
import { getRecord } from 'lightning/uiRecordApi';

import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
const FIELDS = [
    'Assist_Request__c.Status__c',
    'Assist_Request__c.Issue_Understanding_Category__c',
    'Assist_Request__c.Research_Skills_Category__c',
    'Assist_Request__c.Troubleshooting_Skills_Category__c',
    'Assist_Request__c.Resolution_Skill_Category__c',
    'Assist_Request__c.Case_Communication_Category__c'
    
];

export default class Cs_ar_feedback_cmp extends LightningElement {
    issueReason = ISSUE_REASON;
    issueCategory = ISSUE_CATEGORY;
    issueComment = ISSUE_COMMENT;
    researchSkillsReasonField = RESEARCH_SKILLS_REASON;
    researchSkillsCategoryField = RESEARCH_SKILLS_CATEGORY;
    reaseachSkillsComment = RESEARCH_SKILLS_COMMENT;
    troubleshootingSkillsReasonField = TROUBLESHOOTING_SKILLS_REASON;
    troubleshootingSkillsCategoryField = TROUBLESHOOTING_SKILLS_CATEGORY;
    troubleshootingSkillsComment = TROUBLESHOOTING_SKILLS_COMMENT;
    resolutionSkillReasonField = RESOLUTION_SKILL_REASON;
    resolutionSkillCategoryField = RESOLUTION_SKILL_CATEGORY;
    resolutionSkillComment = RESOLUTION_SKILL_COMMENT;
    caseCommunicationReasonField = CASE_COMMUNICATION_REASON;
    caseCommunicationCategoryField = CASE_COMMUNICATION_CATEGORY;
    caseCommunicationComment = CASE_COMMUNICATION_COMMENT;
    issueCategoryVal;
    researchSkillsCategoryFieldVal;
    troubleshootingSkillsReasonFieldVal;
    resolutionSkillReasonFieldVal;
    caseCommunicationReasonVal;
    @api recordId;
    @api objectApiName;
    stepCount = '1';
    showIssueBlock = 'visible';
    showResearchBlock = 'hidden';
    showTroubleshootingBlock = 'hidden';
    showResolutionBlock = 'hidden';
    showCommunicationBlock = 'hidden';
    saveRecord = false;
    hasNext = true;
    hasBack = false;
    totalAnswered = 5;
    answered = 0;
    disableNext = true;
    percentage;
    value = '';
    assistrequest;
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredassistrequests({ error, data }) {
        if (data) {
            this.assistrequest = data;  
            this.issueCategoryVal = data.fields.Issue_Understanding_Category__c.value;
            if(!!this.issueCategoryVal){
                this.disableNext = false;
            }
            if(!!this.issueCategoryVal && this.issueCategoryVal == 'No'){
                this.saveRecord = true;
                this.hasNext = false;
            }
            this.researchSkillsCategoryFieldVal = data.fields.Research_Skills_Category__c.value;
            this.troubleshootingSkillsReasonFieldVal = data.fields.Troubleshooting_Skills_Category__c.value;
            this.resolutionSkillReasonFieldVal = data.fields.Resolution_Skill_Category__c.value;
            this.caseCommunicationReasonVal = data.fields.Case_Communication_Category__c.value;
        } else if (error) {
        }
    }

    handleButtonChange(event){
        if(this.stepCount == '1'){
            this.issueCategoryVal = event.detail.value;
        }else if(this.stepCount == '2'){
            this.researchSkillsCategoryFieldVal = event.detail.value;
        }
        else if(this.stepCount == '3'){
            this.troubleshootingSkillsReasonFieldVal = event.detail.value;
        }
        else if(this.stepCount == '4'){
            this.resolutionSkillReasonFieldVal = event.detail.value;
        }
        if(event.detail.value == 'Yes'){
            if(this.stepCount == '5'){
                this.saveRecord = true;
                this.hasNext = false;
            }else{
                 
                this.saveRecord = false;
                this.hasNext = true;
            }
            this.disableNext = false;

        }else if(event.detail.value == 'No'){
            this.saveRecord = true;
            this.hasNext = false;
            this.disableNext = false;
        }else{
            this.saveRecord = false;
            this.hasNext = true;
             this.disableNext = true;
        }
    }
    handleBack(){
        if(this.stepCount == '5'){
            this.showCommunicationBlock = 'hidden';
            this.showResolutionBlock = 'visible';
            this.stepCount = '4';
        }else if(this.stepCount == '4'){
            this.showResolutionBlock = 'hidden';
            this.showTroubleshootingBlock = 'visible';
            this.stepCount = '3';
        }else if(this.stepCount == '3'){
            this.stepCount = '2';
            this.showResearchBlock = 'visible';
            this.showTroubleshootingBlock = 'hidden';
        }else if(this.stepCount == '2'){
            this.showResearchBlock = 'hidden';
            this.showIssueBlock = 'visible';
            this.hasBack = false;
            this.stepCount = '1';
        }
        this.saveRecord = false;
        this.hasNext = true;
        this.disableNext = false;
        this.percentage = (((this.stepCount-1) / this.totalAnswered)*100).toFixed(0);
        this.percentage =  isNaN(this.percentage) ? 0 : this.percentage;
    }
    handleNext(){
        this.disableNext = true;
        if(this.stepCount == '1' && !!this.issueCategoryVal){
            this.disableNext = false;
            if(!this.researchSkillsCategoryFieldVal){
                this.disableNext = true;
            }
            this.showIssueBlock = 'hidden';
            this.showResearchBlock = 'visible';
            this.stepCount = '2';
            this.hasBack = true;
            if(!!this.researchSkillsCategoryFieldVal && this.researchSkillsCategoryFieldVal == 'No'){
                this.saveRecord = true;
                this.hasNext = false;
            }
        }else if(this.stepCount == '2'  && !!this.researchSkillsCategoryFieldVal){
            this.disableNext = false;
            if(!this.troubleshootingSkillsReasonFieldVal){
                this.disableNext = true;
            }
            this.showResearchBlock = 'hidden';
            this.showTroubleshootingBlock = 'visible';
            this.stepCount = '3';
            if(!!this.troubleshootingSkillsReasonFieldVal && this.troubleshootingSkillsReasonFieldVal == 'No'){
                this.saveRecord = true;
                this.hasNext = false;
            }
        }else if(this.stepCount == '3'  && !!this.troubleshootingSkillsReasonFieldVal){
            this.disableNext = false;
            if(!this.resolutionSkillReasonFieldVal){
                this.disableNext = true;
            }
            this.stepCount = '4';
            this.showResolutionBlock = 'visible';
            this.showTroubleshootingBlock = 'hidden';
            if(!!this.resolutionSkillReasonFieldVal && this.resolutionSkillReasonFieldVal == 'No'){
                this.saveRecord = true;
                this.hasNext = false;
            }
        }else if(this.stepCount == '4'  && !!this.resolutionSkillReasonFieldVal){
            this.disableNext = false;
            if(!this.caseCommunicationReasonVal){
                this.disableNext = true;
            }
            this.showResolutionBlock = 'hidden';
            this.showCommunicationBlock = 'visible';
            this.saveRecord = true;
            this.hasNext = false;
            this.stepCount = '5';
        }
        this.percentage = (((this.stepCount-1) / this.totalAnswered)*100).toFixed(0);
        this.percentage =  isNaN(this.percentage) ? 0 : this.percentage;
    }
    handleSuccess(){
        this.dispatchEvent(new RefreshEvent());

        this.dispatchEvent(new CloseActionScreenEvent());

    }
    handleEmpty(fieldLabel,fieldValue){
        if(fieldValue == ''){

        }
    }

    handleSubmit(event){
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        if(this.stepCount == '1'){
            fields.Research_Skills_Category__c = '';
            fields.Research_Skills_Reason__c = '';
            fields.Troubleshooting_Skills_Category__c = '';
            fields.Troubleshooting_Skills_Reason__c = '';
            fields.Resolution_Skill_Category__c = '';
            fields.Resolution_Skill_Reason__c = '';
            fields.Case_Communication_Category__c = '';
            fields.Case_Communication_Reason__c = '';
        }
        if(this.stepCount == '2'){
            fields.Troubleshooting_Skills_Category__c = '';
            fields.Troubleshooting_Skills_Reason__c = '';
            fields.Resolution_Skill_Category__c = '';
            fields.Resolution_Skill_Reason__c = '';
            fields.Case_Communication_Category__c = '';
            fields.Case_Communication_Reason__c = '';
        }
        if(this.stepCount == '3'){
            fields.Resolution_Skill_Category__c = '';
            fields.Resolution_Skill_Reason__c = '';
            fields.Case_Communication_Category__c = '';
            fields.Case_Communication_Reason__c = '';
        }
        if(this.stepCount == '4'){
            fields.Case_Communication_Category__c = '';
            fields.Case_Communication_Reason__c = '';
        }
        let statusVal = this.assistrequest ? this.assistrequest.fields.Status__c.value : '';
        fields.Status__c = statusVal != 'Closed' ? 'Resolved' : statusVal;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
}