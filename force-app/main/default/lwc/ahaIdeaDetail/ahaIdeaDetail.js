import { LightningElement, track, wire, api } from 'lwc';
import getAhaIdeaRecord from '@salesforce/apex/ManageAhaIdeaController.getAhaIdeaRecord';
const columns = [
  { label: 'Idea Number', fieldName: 'Aha_Unique_ID__c', type: 'text' },
  { label: 'Title', fieldName: 'Name', type: 'text' },
  { label: 'Description', fieldName: 'Idea_Description__c', type: 'text' },
];

export default class BaseURL extends LightningElement {
     sfdcBaseURL;
     params;
     @track newAhaIdea;
     @track paramsval
     @track nameval = '';
     @track ideaNumber = '';
     @track businessfieldval = '';
     @track Proposed_Solutionval = '';
     @track EscalationIdeaval = '';
     @track ForWorkspaceval = '';
     @track ProblemStatementval = '';
     @track ProductAreaval = '';
     @track ProductComponentval = '';
     @track StrategicMajorAccountval = '';
     @track IdeaDescriptionval = '';
     @track IdeaCategoryval = '';
     @track IdeaTagsval = '';
     @track AccountPreferenceval = '';

    renderedCallback(){
        const mapData = new Map();
        this.sfdcBaseURL = window.location.href;
        console.log('sfdcBaseURL-->' +  this.sfdcBaseURL);
        var urlParams = new URL(this.sfdcBaseURL).searchParams;
        console.log('urlParams-->' + urlParams);
        var urlval = urlParams.toString();
        console.log('urlval-->' +  urlval);
        var getIdeaId = urlval.replace('c__recordId=%22','');
        console.log('getIdeaId-->' + getIdeaId);
        var ahaUniqueId = getIdeaId.replace('%22','');
        if(ahaUniqueId.length>0){
            getAhaIdeaRecord({ahaId: ahaUniqueId})
            .then(result => {
               console.log('result - ',result);
                this.nameval = result.Name;
                this.ideaNumberval =  result.Aha_Unique_ID__c;
                this.businessfieldval = result.Business_Case_Value__c!= null?result.Business_Case_Value__c:'N/A';
                this.Proposed_Solutionval = result.Creator_Proposed_Solution__c!= null?result.Creator_Proposed_Solution__c:'N/A';
                this.EscalationIdeaval = result.Escalation__c!= null?result.Escalation__c:'N/A';
                this.ForWorkspaceval = result.For_Workspace__c!=null?result.For_Workspace__c:'N/A';
                this.ProblemStatementval = result.Problem_Statement__c!=null?result.Problem_Statement__c:'N/A';
                this.ProductAreaval = result.Product_Area__c!= null?result.Product_Area__c:'N/A';
                this.StrategicMajorAccountval = result.Strategic_Major_Account__c!= null?result.Strategic_Major_Account__c:'N/A';
                this.IdeaDescriptionval = result.Idea_Description__c!= null ?result.Idea_Description__c:'N/A';
                this.IdeaCategoryval = result.Idea_Category__c!= null?result.Idea_Category__c:'N/A';
                this.IdeaTagsval = result.Idea_Tags__c!= null?result.Idea_Tags__c:'N/A';
                this.AccountPreferenceval = result.Account_Preference__c!= null?result.Account_Preference__c:'N/A';
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.newAhaIdea = undefined;
            });
        }
    }


}