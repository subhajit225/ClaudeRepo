/**
 * @author Shubham
 * @created 12 July 2022
 * @description Controller AssistRequestFormControllerLWC for the LWC AssistRequestForm.
 *              Added support for CS21-100 32k.
 */
public with sharing class AssistRequestFormControllerLWC {

    /**
     * @description Method to prepopulate the fields of AssistRequestForm LWC and constructing message for existing open Assist Request
     * @param caseId
     * @return AssistRequestWithMessageWrapper
     */
    @AuraEnabled
    public static AssistRequestWithMessageWrapper getAssistRequestObj(Id caseId) {
        String assistRequestMessage;
        String prevARId;
        Case thisCase = [Select Id, Priority, CustomerImpactUrgencyAndExpectations__c,Customer_impact__c,KB_Tagged__c,Slack_channel__c, AccountId,Account.Name, Account.Heads_Up_to_Support_Team__c,OwnerId,CaseNumber,Software_Version__c,Cluster__r.Name,Support_Tunnel__c,SentryAI_URL__c,Grafana_Link__c,Jira_Reference_urls__c, Problem_Type__c,RecordType.DeveloperName,Product_Name__c,Account_Preference__c from Case where Id = :caseId WITH SECURITY_ENFORCED];
        List<Assist_Request__c> assistRequestList = [select id,Name,CreatedBy.Name,CreatedDate from Assist_Request__c where Case__c=: thisCase.Id  AND Status__c != 'Closed' WITH SECURITY_ENFORCED]; 
        if(!assistRequestList.isEmpty()){
            assistRequestMessage = 'There is already an existing Assist Request open <a  style="color:blue;" href="/'+assistRequestList[0].id+'">'+assistRequestList[0].Name+'</a>'+
                ', requested by '+assistRequestList[0].CreatedBy.Name+', Requested Date '+assistRequestList[0].CreatedDate+'.<br> Do you want to create a new Assist Request task';
                //'<br><button onclick="hideMessage();return null;" id="buttonSec" style="color:blue;" class="slds-button slds-button_reset">Yes</button> <a  style="color:blue;" class="slds-button slds-button_reset" href="/'+assistRequestList[0].id+'">No</a>';
            prevARId = assistRequestList[0].id;
        }
        Assist_Request__c assistRequest = new Assist_Request__c();
        assistRequest.Case__c = thisCase.Id;
        assistRequest.Component__c = thisCase.Problem_Type__c;
        assistRequest.Jira_Reference__c = thisCase.Jira_Reference_urls__c;
        assistRequest.InsightId__c = '';
        String ask = 'Cluster UUID:\nSupport analysis:\nWhat is being requested of GET:';
        ask = ask.replace('null', 'Not Available').replace(':',': ');
        if(thisCase.recordtype.developername == 'Customer_Success'){
            assistRequest.What_is_the_Ask__c = '';
        }
        else{
        assistRequest.What_is_the_Ask__c = ask;
        }
        assistRequest.Heads_up_to_support_team__c = thisCase.Account.Heads_Up_to_Support_Team__c;
        assistRequest.Account__c = thisCase.AccountId;
        assistRequest.Affected_node__c = thisCase.Customer_impact__c;
        assistRequest.Customer_impact_and_current_status__c = thisCase.CustomerImpactUrgencyAndExpectations__c;
        assistRequest.Support_tunnel__c = thisCase.Support_Tunnel__c;
        assistRequest.Product_Name__c = thisCase.Product_Name__c;
        String likeTerm = thisCase.recordtype.developername == 'Customer_Success' ? 'Customer' : 'Support';
        String likePattern = '%' + likeTerm + '%';
        RecordType arRecord = [SELECT Id FROM RecordType WHERE SObjectType = 'Assist_Request__c' AND DeveloperName LIKE :likePattern WITH SECURITY_ENFORCED LIMIT 1];
        assistRequest.RecordTypeId = arRecord.Id;
        if(String.ValueOf(thisCase.OwnerId).StartsWith('005')){
            assistRequest.Case_Owner__c = thisCase.OwnerId;
            assistRequest.Case_Owner_Manager__c = [SELECT ManagerId FROM User WHERE id=: thisCase.OwnerId LIMIT 1].ManagerId;
        }
        AssistRequestWithMessageWrapper AssistRequestWithMessageWrapperObj = new AssistRequestWithMessageWrapper();
        AssistRequestWithMessageWrapperObj.assistRequestRec = assistRequest;
        AssistRequestWithMessageWrapperObj.message = assistRequestMessage;
        AssistRequestWithMessageWrapperObj.casePriority = thisCase.Priority;
        AssistRequestWithMessageWrapperObj.themeType = userInfo.getUIThemeDisplayed();
        AssistRequestWithMessageWrapperObj.prevAssistReqId = prevARId;
        AssistRequestWithMessageWrapperObj.caseRecordTypeDeveloperName = thisCase.RecordType.DeveloperName;
        AssistRequestWithMessageWrapperObj.accountPreference = thisCase.Account_Preference__c;
        return AssistRequestWithMessageWrapperObj;
    }
    /**
     * @description Method to assign owner, save Assist Request and its related objects
     * @param assistRequest
     * @return String
    */
    @AuraEnabled
    public static String saveAR(Assist_Request__c assistRequest){
        User thisUser = [ select UserRoleId,UserRole.Name FROM User where Id =:UserInfo.getUserId()];
        /* ---- CS21-2742: All ARs to route to Assist Queue -----
         * 
        if(thisUser.UserRole.Name == 'APAC Support Engineer'){
            String dtIST = System.now().format('yyyy:MM:dd:HH:mm:ss', 'IST');
            String[] strTimeSplit = dtIST.split(':');
            Datetime createdTime = Datetime.newInstance( Integer.valueOf(strTimeSplit[0]) //hour
                                                        ,Integer.valueOf(strTimeSplit[1]) //min
                                                        ,Integer.valueOf(strTimeSplit[2])                                //sec
                                                        ,Integer.valueOf(strTimeSplit[3])-7,
                                                        Integer.valueOf(strTimeSplit[4]),0);
            Datetime time_05 = Datetime.newInstance( Integer.valueOf(strTimeSplit[0]) //hour
                                                    ,Integer.valueOf(strTimeSplit[1]) //min
                                                    ,Integer.valueOf(strTimeSplit[2]), 5-7,  0, 0 );
            Datetime time_01 = Datetime.newInstance(  Integer.valueOf(strTimeSplit[0]) //hour
                                                    ,Integer.valueOf(strTimeSplit[1]) //min
                                                    ,Integer.valueOf(strTimeSplit[2])+1, 1-7,  0, 0  );
            String dayOfWeek =  System.now().format('E','IST');
            if(createdTime > time_05 && createdTime < time_01 && (dayOfWeek == 'Mon' || dayOfWeek == 'Tue' || dayOfWeek == 'Wed' || dayOfWeek == 'Thu' || dayOfWeek == 'Fri')){
                QueueSObject que = [SELECT Id,queue.Name, QueueId FROM QueueSobject where queue.name = 'Case Acceleration'];
                assistRequest.OwnerId = que.QueueId;
                assistRequest.is_Case_Acceleration__c = true;
            }else{
                QueueSObject que = [SELECT Id,queue.Name, QueueId FROM QueueSobject where queue.name = 'Assist Queue'];
                assistRequest.OwnerId = que.QueueId;
                assistRequest.is_Case_Acceleration__c = false;
            }
        }else{*/
            RecordType arRecord = [SELECT Id,developername FROM RecordType WHERE SObjectType = 'Assist_Request__c' AND Id =:assistRequest.recordtypeId WITH SECURITY_ENFORCED LIMIT 1];
            String likeTerm = arRecord.developername == 'Customer_Success' ? 'Assist Request CSM Queue' : 'Assist Queue';
             QueueSObject que = [SELECT Id,queue.Name, QueueId FROM QueueSobject where queue.name =: likeTerm WITH SECURITY_ENFORCED LIMIT 1];
             assistRequest.OwnerId = que.QueueId;
             assistRequest.is_Case_Acceleration__c = false;
        //}
        // --------- Ashish CS21-2590: Further AR notifications based on Functional area / Component --------
        String functionArea = [Select Product_Area__c  from Case where Id =: assistRequest.Case__c].Product_Area__c;
        for(AR_Case_escalated__mdt ARemail : [SELECT Id,functional_area__c, Component__c,  Email__c from AR_Case_escalated__mdt where label = 'Focus team AR notification']){
            if(ARemail.Component__c != null && ARemail.Component__c == assistRequest.Component__c && ARemail.functional_area__c == functionArea){
                assistRequest.Slack_Email__c = ARemail.Email__c;
            } 
            else if(ARemail.Component__c == null && ARemail.functional_area__c == functionArea){
                assistRequest.Slack_Email__c = ARemail.Email__c;
            }
        }
        if(assistRequest.Component__c != null){
            Map<String,String> slackMap = new Map<String,String>();
            for(String each: System.label.AssistRequest_Emails.split(';')){
                List<String> keyValue = each.split(':');
                slackMap.put(keyValue[0],keyValue[1]);
            }
            for(String key : slackMap.keyset()){
                if(assistRequest.Component__c.containsIgnoreCase(key) || assistRequest.Component__c.equalsIgnoreCase(key)){
                    assistRequest.Slack_Email__c = slackMap.get(key);
                    break;
                }
            }
        }
       
        insert assistRequest;
        String comment = 'Assist Request Comments('+assistRequest.Name+'): '+assistRequest.What_is_the_Ask__c;
        insert new Note(ParentId = assistRequest.Id,Body  = comment,title='Recommendation/Next Steps Provide');
        if(comment.length() > 4000){
            comment = comment.substring(0, 3900)+' [Comment truncated - Please open Assist Request to view full message]';
        }
        CaseComment cc =new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = comment);
        insert cc;
        if(!test.isRunningTest())
        	CaseApexController.setComment(cc.Id,'Assist Request Comments('+assistRequest.Name+'): '+assistRequest.What_is_the_Ask__c);
        update new Case(id = assistRequest.Case__c,Open_Assist_request__c = [select id from Assist_Request__c where status__c != 'Closed' AND Case__c =: assistRequest.Case__c].size());
        return assistRequest.Id;
    }

     /**
     * @description Method which return list of cases based on filter condition for the bottons on AssistRequestForm LWC
     * @param caseId - Case Id
     * @param filterCondition - Filter Condition
     * @return List<Case>
     */
    @AuraEnabled
    public static List<Case> recentCaseListAction(Id caseId, String filterCondition){
        Case cs = [SELECT Id, AccountId,Subject,RecordType__c from case where Id =: caseId];
        If(cs.AccountId != Null){
            if(filterCondition == 'RecentCases')
                return [SELECT Id,CreatedDate,ClosedDate,Account.Name,Jira_Reference_urls__c,CaseNumber,Owner.Name,Subject,Status,Priority,Type,AccountId FROM Case where AccountId =: cs.AccountId and Account.Name != 'Rubrik' AND RecordType__c =:cs.RecordType__c  Limit 900];
            else if(filterCondition == 'OpenCases')
                return [SELECT Id,CreatedDate,ClosedDate,Account.Name,Jira_Reference_urls__c,CaseNumber,Owner.Name,Subject,Status,Priority,Type,AccountId FROM Case where AccountId =: cs.AccountId and Account.Name != 'Rubrik' and Status != 'Closed' AND RecordType__c =:cs.RecordType__c Limit 900];
            else if(filterCondition == 'ClosedCases')
                return [SELECT Id,CreatedDate,ClosedDate,Account.Name,Jira_Reference_urls__c,CaseNumber,Owner.Name,Subject,Status,Priority,Type,AccountId FROM Case where AccountId =: cs.AccountId and Account.Name != 'Rubrik' and Status =: 'Closed' AND RecordType__c =:cs.RecordType__c Limit 900];
            else if(filterCondition == 'RelatedCases')
                return [SELECT Id,CreatedDate,ClosedDate,Account.Name,Jira_Reference_urls__c,CaseNumber,Owner.Name,Subject,Status,Priority,Type,AccountId FROM Case where AccountId =: cs.AccountId and Account.Name != 'Rubrik' and Subject like :'%'+cs.Subject+'%' AND RecordType__c =:cs.RecordType__c Limit 900];
        }
        return Null;
    }

    // wrapper class with @AuraEnabled and {get;set;} properties 
    public class AssistRequestWithMessageWrapper{
        @AuraEnabled
        public Assist_Request__c assistRequestRec{get;set;}
        @AuraEnabled
        public String message{get;set;}
        @AuraEnabled
        public String casePriority{get;set;}
        @AuraEnabled
        public String themeType {get;set;}
        @AuraEnabled
        public String prevAssistReqId {get;set;}
        /**
        * @description Sets the record type developer name of the case
        * @return String
        */
        @AuraEnabled
        public String caseRecordTypeDeveloperName{get;set;}
        /*
        @description: Account Preference from Case
        */
        @AuraEnabled
        public String accountPreference{get;set;}
    }
}