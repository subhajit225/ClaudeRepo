import { LightningElement,api,wire,track } from 'lwc';
import Id from '@salesforce/user/Id';
import TIME_ZONE  from '@salesforce/i18n/timeZone';
import { getRecord } from 'lightning/uiRecordApi';
import getAssistRequestObj from '@salesforce/apex/AssistRequestFormControllerLWC.getAssistRequestObj';
import recentCaseListAction from '@salesforce/apex/AssistRequestFormControllerLWC.recentCaseListAction';
import saveAR from '@salesforce/apex/AssistRequestFormControllerLWC.saveAR';
import UserNameFld from '@salesforce/schema/User.Name';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Critical_Situation_AR from '@salesforce/label/c.Critical_Situation_AR';

const columns = [
    { label: 'Case Number', fieldName: 'CaseURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'CaseNumber'
            }, 
            target: '_new'
        } 
    },
    { label: 'Name', fieldName: 'OwnerName' },
    { label: 'Status', fieldName: 'Status'},
    { label: 'Priority', fieldName: 'Priority' },
    { label: 'Subject', fieldName: 'Subject' },
    { label: 'JIRA Reference', fieldName: 'Jira_Reference_urls__c' },
    { label: 'Date/Time Opened', fieldName: 'CreatedDate',type: 'date', 
        typeAttributes:{
            month: "2-digit",
            day: "2-digit",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit",
            hour12: true ,
            timeZone: TIME_ZONE 
        } 
    },
    { label: 'Date/Time Closed', fieldName: 'ClosedDate',type: 'date', 
        typeAttributes:{
            month: "2-digit",
            day: "2-digit",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit",
            hour12: true ,
            timeZone: TIME_ZONE 
        } 
     },
];

export default class AssistRequestForm extends LightningElement {

    @api recordId;
    selectedValue;
    userId = Id;
    currentUserName;
    error;
    @track assistRequestObj;
    @track cPriority;
    assistRequestId;
    disableAllBtn = false;
    caseList;
    columns = columns;
    hideRecentCases = false;
    hyperLinkLabel = 'Hide Recent Cases';
    showSpinner = false;
    themeType ;
    message ;
    prevAssistReqId ;
    showInsightIdField = false;
    recordTypeId;
    isSupportCase = false;
    accountPreference;

    @wire(getRecord, { recordId: Id, fields: [UserNameFld]}) 
    userDetails({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
            this.error = undefined;
        } else if (error) {
            this.error = error ;
        }
    }
    
    connectedCallback(){
        this.showSpinner = true;
        getAssistRequestObj({ caseId: this.recordId})
        .then((result) => {
            this.assistRequestObj = result;
            this.cPriority = this.assistRequestObj.casePriority;
            this.themeType = this.assistRequestObj.themeType;
            this.message = this.assistRequestObj.message;
            this.prevAssistReqId = this.assistRequestObj.prevAssistReqId;
            this.error = undefined;
            this.isSupportCase =this.assistRequestObj.caseRecordTypeDeveloperName == 'Support_Case' ? true:false;
            this.recordTypeId = this.assistRequestObj.assistRequestRec.RecordTypeId;
            this.accountPreference = this.assistRequestObj.accountPreference;
        })
        .catch((error) => {
            this.error = error;
            this.assistRequestObj = undefined;
            this.showSpinner = false;
        });

        recentCaseListAction({ caseId: this.recordId , filterCondition : 'RecentCases'})
        .then((result) => {
            if(result){
                this.caseList = result.map(row=>{
                    return{...row, CaseURL : '/' + row.Id, OwnerName : row.Owner.Name}
                })
            }
            this.error = undefined;
        })
        .catch((error) => {
            this.error = error;
            this.caseList = undefined;
            this.showSpinner = false;
        });
    }

    renderedCallback() {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields && this.assistRequestObj && this.assistRequestObj.assistRequestRec) {
            inputFields.forEach(field => {
                if(field.fieldName == 'What_is_the_Ask__c' && this.isSupportCase == true){
                  field.value = this.assistRequestObj.assistRequestRec.What_is_the_Ask__c;
                 }
                else if(field.fieldName == 'RecordTypeId'){
                    field.value = this.assistRequestObj.assistRequestRec.RecordTypeId;
                }      
                else if(field.fieldName == 'Account__c')
                    field.value = this.assistRequestObj.assistRequestRec.Account__c;
                else if(field.fieldName == 'Status__c')
                    field.value = this.assistRequestObj.assistRequestRec.Status__c;
                else if(field.fieldName == 'Type__c')
                    field.value = this.assistRequestObj.assistRequestRec.Type__c;
                else if(field.fieldName == 'Jira_Reference__c')
                    field.value = this.assistRequestObj.assistRequestRec.Jira_Reference__c;
                else if(field.fieldName == 'Heads_up_to_support_team__c')
                    field.value = this.assistRequestObj.assistRequestRec.Heads_up_to_support_team__c;
                else if(field.fieldName == 'Affected_node__c')
                    field.value = this.assistRequestObj.assistRequestRec.Affected_node__c;
                else if(field.fieldName == 'Component__c')
                    field.value = this.assistRequestObj.assistRequestRec.Component__c;
                else if(field.fieldName == 'Customer_impact_and_current_status__c')
                    field.value = this.assistRequestObj.assistRequestRec.Customer_impact_and_current_status__c;
                else if(field.fieldName == 'Support_tunnel__c')
                    field.value = this.assistRequestObj.assistRequestRec.Support_tunnel__c;
                else if(field.fieldName == 'Case_Owner__c')
                    field.value = this.assistRequestObj.assistRequestRec.Case_Owner__c;
                else if(field.fieldName == 'Critical_Situation_Reason__c')
                    field.value = this.assistRequestObj.assistRequestRec.Critical_Situation_Reason__c;
                else if(field.fieldName == 'Product_Name__c')
                    field.value = this.assistRequestObj.assistRequestRec.Product_Name__c;
                else if(field.fieldName == 'OwnerId'){
                    field.value = this.assistRequestObj.assistRequestRec.OwnerId;
                }                   
            });
        }
    }

    handleChange(event){
        if(event.target.name == 'Status__c'){
            this.assistRequestObj.assistRequestRec['Status__c'] = event.target.value; 
        } else if(event.target.name == 'Type__c'){
            this.assistRequestObj.assistRequestRec['Type__c'] = event.target.value;
        } else if(event.target.name == 'Case__c'){
            this.assistRequestObj.assistRequestRec['Case__c'] = event.target.value;
        } else if(event.target.name == 'Account__c'){
            this.assistRequestObj.assistRequestRec['Account__c'] = event.target.value;
        } else if(event.target.name == 'What_is_the_Ask__c'){
            this.assistRequestObj.assistRequestRec['What_is_the_Ask__c'] = event.target.value;
        } else if(event.target.name == 'Affected_node__c'){
            this.assistRequestObj.assistRequestRec['Affected_node__c'] = event.target.value;
        } else if(event.target.name == 'Cluster_Stats_Sentry_AI_URL__c'){
            this.assistRequestObj.assistRequestRec['Cluster_Stats_Sentry_AI_URL__c'] = event.target.value;
        } else if(event.target.name == 'Cluster_UUID__c'){
            this.assistRequestObj.assistRequestRec['Cluster_UUID__c'] = event.target.value;
        } else if(event.target.name == 'Customer_impact_and_current_status__c'){
            this.assistRequestObj.assistRequestRec['Customer_impact_and_current_status__c'] = event.target.value;
        } else if(event.target.name == 'Customer_preferred_time_zone_of_contact__c'){
            this.assistRequestObj.assistRequestRec['Customer_preferred_time_zone_of_contact__c'] = event.target.value;
        } else if(event.target.name == 'Grafana_Link__c'){
            this.assistRequestObj.assistRequestRec['Grafana_Link__c'] = event.target.value;
        } else if(event.target.name == 'InsightId__c'){
            this.assistRequestObj.assistRequestRec['InsightId__c'] = event.target.value;
        } else if(event.target.name == 'Issue_Summary__c'){
            this.assistRequestObj.assistRequestRec['Issue_Summary__c'] = event.target.value;
        } else if(event.target.name == 'Rubrik_version__c'){
            this.assistRequestObj.assistRequestRec['Rubrik_version__c'] = event.target.value;
        } else if(event.target.name == 'Support_tunnel__c'){
            this.assistRequestObj.assistRequestRec['Support_tunnel__c'] = event.target.value;
        } else if(event.target.name == 'Tagged_KB_article__c'){
            this.assistRequestObj.assistRequestRec['Tagged_KB_article__c'] = event.target.value;
        } else if(event.target.name == 'What_is_the_Ask__c'){
            this.assistRequestObj.assistRequestRec['What_is_the_Ask__c'] = event.target.value;
        } else if(event.target.name == 'InsightId__c'){
            this.assistRequestObj.assistRequestRec['InsightId__c'] = event.target.value;
        } else if(event.target.name == 'Component__c'){
            this.assistRequestObj.assistRequestRec['Component__c'] = event.target.value;
        } else if(event.target.name == 'Product_Name__c'){
            this.assistRequestObj.assistRequestRec['Product_Name__c'] = event.target.value;
        } else if(event.target.name == 'insight_checkbox'){
            if(event.target.checked){
                this.showInsightIdField = true;
            } else {
                this.showInsightIdField = false;
                //this.template.querySelector('lightning-input-field[data-name="InsightId"]').value = null;
                this.assistRequestObj.assistRequestRec['InsightId__c'] = null;
            }
        } else if(event.target.name == 'Critical_Situation_Reason__c'){
            this.assistRequestObj.assistRequestRec['Critical_Situation_Reason__c'] = event.target.value;
        }
    } 

    handleSubmit(event) {
        // ---- CS21-2156 start-------
        if(this.assistRequestObj.assistRequestRec['Type__c'] == 'Critical Situation' && this.cPriority != 'P1'){
            event.preventDefault();
            if(window.location.href.includes('/lightning/')){
                const evt = new ShowToastEvent({
                title: 'Case Priority Must Be P1 for Critical Situation AR',
                message: Critical_Situation_AR,
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);  
            } else {
                alert(Critical_Situation_AR);
            }
            
                      
        }// ---- CS21-2156 end -------
        else{
            this.disableAllBtn = true;
            this.showSpinner = true;
            event.preventDefault();     
            const fields = event.detail.fields;
            saveAR({ assistRequest: this.assistRequestObj.assistRequestRec })
            .then((result) => {
                this.assistRequestId = result;
                this.error = undefined;
                if(this.themeType == 'Theme4d' || this.themeType == 'Theme4t' || this.themeType == 'Theme4u'){
                    this.openAssistReqRecord();
                } else {
                    window.location.href = '/' + this.assistRequestId;
                }
            })
            .catch((error) => {
                this.error = error;
                this.assistRequestId = undefined;
                this.showSpinner = false;
            });
        }
    }

    handleSuccess(event) {
        //this.assistRequestId = event.detail.id;
    }

    handleLoad(event){
        this.showSpinner = false;
    }

    handleCancel(event){
        if(this.themeType == 'Theme4d' || this.themeType == 'Theme4t' || this.themeType == 'Theme4u'){
            this.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
              if (isConsole) {
                this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
                  this.invokeWorkspaceAPI('openSubtab', {
                    parentTabId: focusedTab.tabId,
                    recordId: this.recordId,
                    focus: true
                  }).then(tabId => {
                  });
                });
              }
            });
         } else {
            window.history.back();
         }
    }

    handleclick(event){
        event.preventDefault();
        if(this.hideRecentCases){
            this.hideRecentCases = false;
            this.hyperLinkLabel= 'Hide Recent Cases';
        } else {
            this.hideRecentCases = true;
            this.hyperLinkLabel= 'Show Recent Cases';
        }
    }

    handleOpenCases(event){
        this.showSpinner = true;
        recentCaseListAction({ caseId: this.recordId , filterCondition : 'OpenCases'})
        .then((result) => {
            if(result){
                this.caseList = result.map(row=>{
                    return{...row, CaseURL : '/' + row.Id, OwnerName : row.Owner.Name}
                })
            }
            this.error = undefined;
        })
        .catch((error) => {
            this.error = error;
            this.caseList = undefined;
        });
        this.showSpinner = false;
    }

    handleClosedCases(event){
        this.showSpinner = true;
        recentCaseListAction({ caseId: this.recordId , filterCondition : 'ClosedCases'})
        .then((result) => {
            if(result){
                this.caseList = result.map(row=>{
                    return{...row, CaseURL : '/' + row.Id, OwnerName : row.Owner.Name}
                })
            }
            this.error = undefined;
        })
        .catch((error) => {
            this.error = error;
            this.caseList = undefined;
        });
        this.showSpinner = false;
    }

    handleRelatedCases(event){
        this.showSpinner = true;
        recentCaseListAction({ caseId: this.recordId , filterCondition : 'RelatedCases'})
        .then((result) => {
            if(result){
                this.caseList = result.map(row=>{
                    return{...row, CaseURL : '/' + row.Id, OwnerName : row.Owner.Name}
                })
            }
            this.error = undefined;
        })
        .catch((error) => {
            this.error = error;
            this.caseList = undefined;
        });
        this.showSpinner = false;
    }

    openAssistReqRecord() {
        this.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
          if (isConsole) {
            this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
              this.invokeWorkspaceAPI('openSubtab', {
                parentTabId: focusedTab.tabId,
                recordId: this.assistRequestId,
                focus: true
              }).then(tabId => {
              });
            });
          }
        });
    }
     
    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
          const apiEvent = new CustomEvent("internalapievent", {
            bubbles: true,
            composed: true,
            cancelable: false,
            detail: {
              category: "workspaceAPI",
              methodName: methodName,
              methodArgs: methodArgs,
              callback: (err, response) => {
                if (err) {
                    return reject(err);
                } else {
                    return resolve(response);
                }
              }
            }
          });
     
          window.dispatchEvent(apiEvent);
        });
    }

    hideMessage(event){
        event.preventDefault();
        this.message = undefined;
    }

    handleNoBtn(event){
        event.preventDefault();
        if(this.themeType == 'Theme4d' || this.themeType == 'Theme4t' || this.themeType == 'Theme4u'){
            this.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
              if (isConsole) {
                this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
                  this.invokeWorkspaceAPI('openSubtab', {
                    parentTabId: focusedTab.tabId,
                    recordId: this.prevAssistReqId,
                    focus: true
                  }).then(tabId => {
                  });
                });
              }
            });
        } else {
            window.location.href = '/' + this.prevAssistReqId;
        }
    }
}