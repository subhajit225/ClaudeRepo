/**
* @Author : Ashwini Gnanamurthy
* @Created Date : 12th Nov 2019
* @Description : Controller AssistRequestFormController for the VF page AssistRequestForm 
*                
*                
**/

public class AssistRequestFormController {
    
    public Assist_Request__c assistRequest {get; set;}
    public Case thisCase {get; set;}
    public Boolean hasAssistRequest{get; set;}
    public Boolean showSection{get; set;}
    public Boolean showInsight{get; set;}
    public Boolean disableSave{get; set;}
    public String assistRequestMessage{get; set;}
    
    public AssistRequestFormController(ApexPages.StandardController controller) {
        showSection = false;  
        disableSave = false;
        showInsight = false;
        if(!Test.isRunningTest())
            controller.addFields(new List<String>{'CustomerImpactUrgencyAndExpectations__c','Case_Time_Zone__c','Customer_impact__c','KB_Tagged__c','Priority','Account.Name', 'AccountId', 'Account.Heads_Up_to_Support_Team__c','OwnerId','CaseNumber','Software_Version__c','Cluster__r.Name','Support_Tunnel__c','SentryAI_URL__c','Grafana_Link__c','Jira_Reference_urls__c','Slack_channel__c'});
        thisCase = (Case)controller.getRecord();
        if(Test.isRunningTest())
            thisCase = [Select Id, Priority,CustomerImpactUrgencyAndExpectations__c,Customer_impact__c, AccountId, Account.Heads_Up_to_Support_Team__c,OwnerId,CaseNumber,Software_Version__c,Cluster__r.Name,KB_Tagged__c,Support_Tunnel__c,SentryAI_URL__c,Grafana_Link__c,Jira_Reference_urls__c,Slack_channel__c from Case where Id = :thisCase.Id];
        List<Assist_Request__c> assistRequestList = [select id,Name,CreatedBy.Name,CreatedDate from Assist_Request__c where Case__c=: thisCase.Id  AND Status__c != 'Closed']; 
        if(!assistRequestList.isEmpty()){
            hasAssistRequest = true;
            assistRequestMessage = 'There is already an existing Assist Request open <a  style="color:blue;" href="/'+assistRequestList[0].id+'">'+assistRequestList[0].Name+'</a>'+
                ', requested by '+assistRequestList[0].CreatedBy.Name+', Requested Date '+assistRequestList[0].CreatedDate+'.<br> Do you want to create a new Assist Request task'+
                '<br><button onclick="hideMessage();return null;" id="buttonSec" style="color:blue;" class="slds-button slds-button_reset">Yes</button> <a  style="color:blue;" class="slds-button slds-button_reset" href="/'+assistRequestList[0].id+'">No</a>';
        }else{
            hasAssistRequest = false;
        }
        assistRequest = new Assist_Request__c();
        assistRequest.Case__c = thisCase.Id;
        assistRequest.Jira_Reference__c = thisCase.Jira_Reference_urls__c;
        assistRequest.InsightId__c = '';
        String ask = 'Cluster UUID:\nSupport analysis:\nWhat is being requested of GET:';       
        ask = ask.replace('null', 'Not Available').replace(':',': ');
        assistRequest.What_is_the_Ask__c = ask;
        assistRequest.Affected_node__c = thisCase.Customer_impact__c;
        assistRequest.Heads_up_to_support_team__c = thisCase.Account.Heads_Up_to_Support_Team__c;
        //
        assistRequest.Customer_impact_and_current_status__c = thisCase.CustomerImpactUrgencyAndExpectations__c;
        assistRequest.Support_tunnel__c = thisCase.Support_Tunnel__c;
        
        
        assistRequest.Account__c = thisCase.AccountId;
        if(String.ValueOf(thisCase.OwnerId).StartsWith('005'))
            assistRequest.Case_Owner__c = thisCase.OwnerId;
        
    }
    
    public void enableCheck(){
        showInsight = !showInsight;
    }
    
    public PageReference save(){
        //insert new CaseComment(ParentId = thisCase.Id, isPublished = false, commentBody = assistRequest.Findings_and_Steps_Taken__c);
        //assistRequest.Findings_and_Steps_Taken__c = '';
        //Convert it into Indian Standard Time(dtIST).
        disableSave = true;
        User thisUser = [ select UserRoleId,UserRole.Name FROM User where Id =:UserInfo.getUserId()];
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
        }else{
             QueueSObject que = [SELECT Id,queue.Name, QueueId FROM QueueSobject where queue.name = 'Assist Queue'];
             assistRequest.OwnerId = que.QueueId;
             assistRequest.is_Case_Acceleration__c = false;
        }
        insert assistRequest;
        assistRequest = [Select id,Case__c,Name,What_is_the_Ask__c from Assist_Request__c where id = :assistRequest.Id];
        assistRequest.What_is_the_Ask__c = 'Assist Request Comments('+assistRequest.Name+'): '+assistRequest.What_is_the_Ask__c;
        insert new Note(ParentId = assistRequest.Id,Body  = assistRequest.What_is_the_Ask__c,title='Recommendation/Next Steps Provide');
        String comment = assistRequest.What_is_the_Ask__c;
        if(comment.length() > 4000){
            comment = comment.substring(0, 3900)+'[Comment truncated - Please open Assist Request to view full message]';
        }
        insert new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = comment);
        update new Case(id = assistRequest.Case__c,Open_Assist_request__c = [select id from Assist_Request__c where status__c != 'Closed' AND Case__c =: assistRequest.Case__c].size());
        PageReference assistReqDetail = new PageReference('/'+assistRequest.Id);
        return assistReqDetail;
    }
    public void toogleSection(){
        showSection = showSection ? false : true;
    }
    
    public PageReference cancel(){
        PageReference assistReqDetail = new PageReference('/'+thisCase.Id);
        return assistReqDetail;
    }
    
}