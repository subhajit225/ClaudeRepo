import { LightningElement, wire } from 'lwc';
// hide standard lighting app page header
import HideLightningHeader from '@salesforce/resourceUrl/NoHeader';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
//standard methods
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ESCALATION from '@salesforce/schema/Escalation__c';
import { deleteRecord } from 'lightning/uiRecordApi';
import LightningConfirm from "lightning/confirm";

// Draft
import getDraftEscalation from '@salesforce/apex/EscalationManagementTeamController.getDraftEscalation';

export default class EscalationManagementTeam extends LightningElement {

    showSpinner = false
    ransomwareRtId
    supportRtId
    isWelcomeNote = true
    // draft
    isDraft = false

    @wire(getObjectInfo, { objectApiName: ESCALATION })
    fetchRecordTypeId({error, data}){
        if(data){
            const rtis = data.recordTypeInfos;
            this.ransomwareRtId = Object.keys(rtis).find(rti => rtis[rti].name === 'Escalation Ransomware');
            this.supportRtId = Object.keys(rtis).find(rti => rtis[rti].name === 'Escalation Support');
        }else{
            console.log('accountObject error: ', error);
        }
    }

    get options() {
        return [
            { label: 'Ransomware', value: 'Ransomware' },
            { label: 'Escalation Support', value: 'Escalation' },
        ];
    }
    value = 'Ransomware'

    ransomewareTemplateFields = ['Case__c', 
                                    'Customer_Geo__c',
                                    'Account__c', 
                                    'Market_Segment__c',
                                    'Slack_channel__c',
                                    'JIRA_Reference__c',
                                    'Case_Priority__c',
                                    'AHA_reference__c',
                                    'Customer_Preparedness__c',
                                    'Idea_Reference__c',
                                    'License_Type__c',
                                    'Initial_engagement_date__c',
                                    'Status__c',
                                    'Current_Rubrik_CDM_version__c',
                                    'Business_impact_media_attention__c',
                                    'CDM_version_time_of_attack__c',
                                    'Rubrik_Compromised__c',
                                    'Attacker_RSC_Logon_Attempted__c',
                                    'Ransomware_entry_point__c',
                                    'Attack_vector__c',
                                    'Customer_impact_and_current_status__c', 
                                    'Polaris_Active__c',
                                    'Radar_Alerted__c',
                                    'Cluster_UUID__c',
                                    'Radar_alert_summary__c',
                                    'Cluster_Stats_SentryAI_URL__c',
                                    'Radar_Enabled__c',
                                    'Customer_preferred_time_zone_of_contact__c',
                                    'Data_Loss__c',
                                    'Ransom_paid__c',
                                    'Grafana_Link__c',
                                    'Threat_hunter_enabled__c',
                                    'Heads_up_to_support_team__c',
                                    'Threat_hunter_IOC__c',
                                    'Escalation_Manager_Owner__c',
                                    'is_there_a_relevant_insight_in_SentryAI__c',
                                    'Retention_Lock__c',
                                    'Insight_Id__c',
                                    'Tagged_KB_article__c',
                                    'Affected_Node__c',
                                    'TOTP_in_use__c',
                                    'Recommendation_Next_Steps_Provided__c'];
    escalationTemplateFields = ['Case__c', 
                                'Case_Priority__c',
                                'Account__c', 
                                'Status__c',
                                'Slack_channel__c',
                                'Escalation_Manager_Owner__c',
                                'Customer_Geo__c', 
                                'Cluster_UUID__c',
                                'Grafana_Link__c', 
                                'Customer_preferred_time_zone_of_contact__c',
                                'Cluster_Stats_SentryAI_URL__c', 
                                'Business_impact_media_attention__c', 
                                'JIRA_Reference__c',
                                'Customer_impact_and_current_status__c', 
                                'AHA_reference__c',
                                'Escalation_contributing_factors__c', 
                                'Idea_Reference__c',
                                'Recommendation_Next_Steps_Provided__c',
                                'Situation_Type__c',  
                                'Tagged_KB_article__c',
                                'Data_Loss__c',
                                'Affected_Node__c',  
                                'is_there_a_relevant_insight_in_SentryAI__c',  
                                'Customer_temperature__c',
                                'Insight_Id__c',
                                'Heads_up_to_support_team__c'
                                ];
                                
    templateInfo = {'type':'Ransomware',
                    'section':'Ransomware Attack/Recovery Information',
                    'fields':this.ransomewareTemplateFields, 
                    'recordtypeId':this.ransomwareRtId,
                    'er_recordId':'', 
                    'er_isEdit':true,
                    'es_recordId':'', 
                    'es_isEdit':true,
                    'er_draft':{},
                    'es_draft':{}}

    connectedCallback() {
        loadStyle(this, HideLightningHeader)
    }

    savedRecord = {
        'er_recordId':'',
                            'er_isEdit':true,
                            'es_recordId':'',
                            'es_isEdit':true,
        'er_draft':{'Id':'', 'CaseId':'', 'lastmodifieddate':''},
        'es_draft':{'Id':'', 'CaseId':'', 'lastmodifieddate':''}
    }

    async handleTypeChange(event) {
        
        console.log('handleTypeChange savedRecord: ', JSON.parse(JSON.stringify(this.savedRecord)));
        this.value = event.detail.value;
        const accordion = this.template.querySelector('.example-accordion');
        let sectionTitle = this.value == 'Ransomware' ? 'Ransomware Attack/Recovery Information' : 'New Support Escalation';
        accordion.activeSectionName = sectionTitle;
        let templateFields = this.value == 'Ransomware' ? this.ransomewareTemplateFields : this.escalationTemplateFields;
        let recordTypeId = this.value == 'Ransomware' ? this.ransomwareRtId : this.supportRtId;

        this.templateInfo = {'type':this.value, 
                                'section':sectionTitle, 
                                'fields':templateFields, 
                                'recordtypeId':recordTypeId};
                                
        console.log('handleTypeChange section : ', this.templateInfo);

        // Draft ER Id
        if(this.savedRecord.er_draft){
            this.templateInfo.er_draft = this.savedRecord.er_draft;
        }
        // Draft ES Id
        if(this.savedRecord.es_draft){
            this.templateInfo.es_draft = this.savedRecord.es_draft;
        }

        if(this.savedRecord.er_recordId){
            this.templateInfo.er_recordId = this.savedRecord.er_recordId;
            this.templateInfo.er_isEdit = false;
        }else{
            this.templateInfo.er_recordId = '';
            this.templateInfo.er_isEdit = true;
        }
        if(this.savedRecord.es_recordId){
            this.templateInfo.es_recordId = this.savedRecord.es_recordId;
            this.templateInfo.es_isEdit = false;
        }else{
            this.templateInfo.es_recordId = '';
            this.templateInfo.es_isEdit = true;
        }

        //  Changing tab to Escalation When draft record saved as Ransomware
        if(this.savedRecord && this.value != 'Ransomware'
            && this.savedRecord.er_draft
            && this.savedRecord.er_draft.Id){
                const result = await LightningConfirm.open({
                    message: "are you sure you want to delete draft Ransomware Escalation and create new Support Escalation?",
                    variant: "default", // headerless
                    label: "Delete a record"
                });
                console.log('result::: ', JSON.stringify(result));
                //result is true if OK was clicked
                if (result) {
                    deleteRecord(this.savedRecord.er_draft.Id)
                    this.savedRecord.er_draft.Id = '';
                    this.templateInfo.er_draft = this.savedRecord.er_draft;
                    this.value = 'Escalation';
                    // remove DRAFT button after record delete
                    this.isDraft = false;
                }else{
                    this.value = 'Ransomware';
                }
                // this.template.querySelector('c-escalation-template').handleSectionChange(this.templateInfo);
                this.templateInfo.type = this.value;
        }
        //  Changing tab to Ransomware When draft record saved as Escalation
        else if(this.savedRecord && this.value == 'Ransomware'
                && this.savedRecord.es_draft
                && this.savedRecord.es_draft.Id){
                    const result = await LightningConfirm.open({
                        message: "are you sure you want to delete draft Support Escalation and create new Ransomware Escalation?",
                        variant: "default", // headerless
                        label: "Delete a record"
                    });
                    //result is true if OK was clicked
                    if (result) {
                        deleteRecord(this.savedRecord.es_draft.Id);
                        this.savedRecord.es_draft.Id = '';
                        this.templateInfo.es_draft = this.savedRecord.es_draft;
                        this.value = 'Ransomware';
                        // remove DRAFT button after record delete
                        this.isDraft = false;
                    }else{
                        this.value = 'Escalation';
                    }
                    // this.template.querySelector('c-escalation-template').handleSectionChange(this.templateInfo);
                    this.templateInfo.type = this.value;
        }
        // If No Draft Record saved
        console.log('handleTypeChange finalll : ', this.templateInfo);
        this.template.querySelector('c-escalation-template').handleSectionChange(this.templateInfo);
    }
    
    hanldeescalationchange(event){
        this.savedRecord = event.detail;
    }

    handleProceed(){
        this.isWelcomeNote = false;
        this.fetchDraftEscalations();
        // Onclick of cancel after draft record created, displaying Draft button
        console.log('handleProceed '+ JSON.stringify(this.savedRecord));

        if(this.savedRecord
            && ((this.savedRecord.er_draft
                    && this.savedRecord.er_draft.Id)
                || (this.savedRecord.es_draft
                    && this.savedRecord.es_draft.Id))){
                        this.isDraft = true;
        }
    }

    // fetch Draft Escalations
    async fetchDraftEscalations(){
        this.showSpinner = true;
        this.isDraft = false;
        await getDraftEscalation({})
        .then((result) => {
            console.log('ransomwareEsc '+ JSON.stringify(result));
            // console.log('templateInfo BB '+ JSON.stringify(this.templateInfo));
            if(result){
                if(result.ransomwareEsc){
                    // draft er id
                    this.savedRecord.er_draft.Id = result.ransomwareEsc.Id;
                    this.savedRecord.er_draft.CaseId = result.ransomwareEsc.Case__c;
                    this.savedRecord.er_draft.lastmodifieddate = result.ransomwareEsc.LastModifiedDate;
                    this.isDraft = true;
                    this.value = 'Ransomware';
                }
                if(result.supportEsc){
                    // draft es id
                    this.savedRecord.es_draft.Id = result.supportEsc.Id;
                    this.savedRecord.es_draft.CaseId = result.supportEsc.Case__c;
                    this.savedRecord.es_draft.lastmodifieddate = result.supportEsc.LastModifiedDate;
                    this.isDraft = true
                    this.value = 'Escalation';
                }
                this.templateInfo.type = this.value;
            }
            console.log('value '+ this.value);
            console.log('savedRecord '+ JSON.stringify(this.savedRecord));
        })
        .catch((error) => {
            console.log('fetchDraftEscalations ERROR: '+ JSON.stringify(error));
        })
        .finally(() =>{
            this.showSpinner = false;
        })
    }

    handleLoadMainPage(){
        this.isWelcomeNote = true;
    }

    // draft options change
    async handleDraftOptions(event) {
        let optionVal = event.detail.value;
        let recordType = this.value == 'Ransomware' ? 'Ransomware Escalation' : 'Support Escalation';

        // Onlick of edit/delete from draft options, Displaying eslaction template fields
        this.isDraft = false;

        // assign draft record value: Default for edit option
        if(this.value == 'Ransomware'){
            this.templateInfo.er_draft = this.savedRecord.er_draft;
        }else{
            this.templateInfo.es_draft = this.savedRecord.es_draft;
        }
        
        // delete draft escalation record 
        if(optionVal == 'delete'){
            const result = await LightningConfirm.open({
                message: "are you sure, you want to delete this draft "+recordType+" record?",
                variant: "default", // headerless
                label: "Delete a record"
            });
            if (result) {
                let recordId = this.value == 'Ransomware' ? this.savedRecord.er_draft.Id : this.savedRecord.es_draft.Id;
                await deleteRecord(recordId)
                if(this.value == 'Ransomware'){
                    this.templateInfo.er_draft.Id = '';
                    this.templateInfo.er_draft = this.savedRecord.er_draft;
                }else{
                    this.templateInfo.es_draft.Id = '';
                    this.templateInfo.es_draft = this.savedRecord.es_draft;
                }
            }
        }
        console.log('handleDraftOptions final:: ', JSON.stringify(this.templateInfo));
        this.template.querySelector('c-escalation-template').handleSectionChange(this.templateInfo);
    }
}