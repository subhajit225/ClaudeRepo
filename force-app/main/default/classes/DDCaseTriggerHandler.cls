/**
* Date :17-July-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
* TestClass : DDCaseTriggerHandler_Test
**/
public class DDCaseTriggerHandler {
    
    public static final set<String> openStatusSet = new Set<String>{'Draft','On Hold','Requested','Modification Requested','Recalled','Closed'};
    public static final set<String> closedOppStages = new Set<String>{'6 PO With Channel','7 Closed Won','7 Closed Lost','7 Closed Admin'};
    /**
     * @description on Before Delete
     * @param oldList
     * this will executes onBeforeDelete
     */ 
    public static void onBeforeDelete(List<Deal_Desk_Case__c> oldList){
        PreventDeletion(oldList);
    }
    /**
     * @description on Before Insert
     * @param newList
     *  this will executes onBeforeInsert
     */ 
    public static void onBeforeInsert(List<Deal_Desk_Case__c> newList){
         /**
        * @author Ajay Kumar Khatri
        * @date 16-07-2025
        * @description checking email masking
        */
        setDefaultValues(newList);
        //preventDuplicate(newList,null);
        setCaseOwner(newList,null);  
        updateQuestionare(newList,null);
    }
    /**
     * @description on After Insert
     * @param newList
     * @param newMap
     *  this will executes onAfterInsert
     */ 
    public static void onAfterInsert(List<Deal_Desk_Case__c> newList, Map<Id,Deal_Desk_Case__c> newMap){
        
        //autoSubmitCase(newList);//DD25-3 SAL26-481
        updateCountOnOpp(newList,null);
        sendEmailNotification(newList,null);
    }
    /**
     * @description on Before Update
     * @param newList
     * @param oldMap
     *  this will executes onBeforeUpdate
     */
    public static void onBeforeUpdate(List<Deal_Desk_Case__c> newList, Map<Id,Deal_Desk_Case__c> oldMap){
        //preventDuplicate(newList,oldMap);
         /**
        * @author Ajay Kumar Khatri
        * @date 16-07-2025
        * @description checking email masking
        */
        //PlatformUtility.validateEmails(newList);
        updateCaseStatus(newList,oldMap);
        updateQuestionare(newList,oldMap);
        setCaseOwner(newList,oldMap);
    }
    /**
     * @description on After Update
     * this will executes onAfterUpdate
     * @param newList
     * @param oldMap
     */
    public static void onAfterUpdate(List<Deal_Desk_Case__c> newList, Map<Id,Deal_Desk_Case__c> oldMap){
        updateCountOnOpp(newList,oldMap);
        recallApprovals(newList,oldMap);
        sendEmailNotification(newList,oldMap);
       // conditionalApprovalFlow(newList,oldMap);
        postOnChatter(newList,oldMap);
    }
     /**
     * @description auto Submit Case
     * @param ddCaseNewList
     *  this will executes autoSubmitCase
     */
    // Method to auto-submit the case on creation : DD25-3
    public static void autoSubmitCase(List<Deal_Desk_Case__c> ddCaseNewList){
        Deal_Desk_Case__c ddRec = ddCaseNewList[0];
        if(ddRec!=null && !ddRec.Case_Auto_Created__c){
            DDCaseExtController con = new DDCaseExtController(new ApexPages.StandardController(ddRec));
            if(!test.isRunningtest()){
            con.onSubmit();
            }
        } 
    }
    /**
     * @description set Default Values
     * @param ddCaseNewList
     *  this will executes setDefaultValues
     */
   public static void setDefaultValues(List<Deal_Desk_Case__c> ddCaseNewList){
        Set<Id> OppIds = new Set<Id>(); //DD25-5
        for(Deal_Desk_Case__c dd : ddCaseNewList){
            if(dd.Requestor__c == null){
                dd.Requestor__c = UserInfo.getUserId();
            }
            dd.Request_Status__c = 'Draft';
            dd.Case_Status__c ='Requested';
            OppIds.add(dd.Opportunity__c); //DD25-5
        }
        //DD25-5 start
        if(OppIds!=null && !OppIds.isEmpty()){
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, RecordType.name, StageName, CloseDate,AccountId, OwnerId, ACV_Amount__c,Amount, ETM_Theatre__c, ETM_Area__c,ETM_Region__c,
                                                                  Deal_Structuring_Oppty_Notes__c, In_Forecast_Theatre__c,Primary_Quote_Approval_Status__c,SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.SBQQ__Status__c 
                                                                  FROM Opportunity where Id IN:OppIds]); //DD25-13
            
            for(Deal_Desk_Case__c dd : ddCaseNewList){
                dd.Opportunity_Owner__c = oppMap.get(dd.Opportunity__c).OwnerId;
                dd.Opportunity_Stage__c = oppMap.get(dd.Opportunity__c).StageName;
                dd.Close_Date__c = oppMap.get(dd.Opportunity__c).CloseDate;
                dd.Account_Name__c = oppMap.get(dd.Opportunity__c).AccountId;
                dd.Amount_ACV__c = oppMap.get(dd.Opportunity__c).ACV_Amount__c;
                dd.Amount_TCV__c = oppMap.get(dd.Opportunity__c).Amount;
                dd.ETM_Theatre__c = oppMap.get(dd.Opportunity__c).ETM_Theatre__c;
                dd.ETM_Area__c = oppMap.get(dd.Opportunity__c).ETM_Area__c;
                dd.ETM_Region__c = oppMap.get(dd.Opportunity__c).ETM_Region__c;
                dd.Deal_Structuring_Notes__c = oppMap.get(dd.Opportunity__c).Deal_Structuring_Oppty_Notes__c;
                dd.In_Forecast_GVP__c = oppMap.get(dd.Opportunity__c).In_Forecast_Theatre__c;
                dd.Primary_Quote__c = oppMap.get(dd.Opportunity__c).SBQQ__PrimaryQuote__c;
                dd.Opportunity_Record_Type__c = oppMap.get(dd.Opportunity__c).RecordType.name; //DD25-7
            }
        }
        //DD25-5 end
    }
	/**
     * @description set Case Owner
     * @param ddCaseNewList
     * @param oldMap
     *  this will executes setCaseOwner
     */
    //method to set case Owner based on Deal Desk Team and ETM Region on DD Case
    public static void setCaseOwner(List<Deal_Desk_Case__c> ddCaseNewList,Map<Id,Deal_Desk_Case__c> oldMap){
        list<string> etmRegionList = new list<string>();
        String regions = '';//DD25-55
        Map<String, String> userVsRegions = new Map<String, String>();
        List<Deal_Desk_Assignees__c> ddAsgnMapping = [Select Assignee__c,Assignee__r.Name,ETM_Region__c, Deal_Desk_Team__c from Deal_Desk_Assignees__c limit 1000];

// DD25-55 starts

for (Deal_Desk_Assignees__c dda : ddAsgnMapping) {
    if (dda.Assignee__c != Null) {
        userVsRegions.put(dda.Assignee__c, dda.ETM_Region__c);
    }
}
for (UserVsRegionsDDC__mdt userMetaData : [SELECT IsBypassed__c, UserId__c from UserVsRegionsDDC__mdt where Type_of_Metadata__c = 'Users to Bypass']) {
    if (userMetaData.IsBypassed__c == TRUE) {
        regions += userVsRegions.get(userMetaData.UserId__c);
    }
}
       // DD25-55 ends 
        //dd25-7
        for(Deal_Desk_Case__c dd : ddCaseNewList){
            if(oldMap == null && dd.Opportunity_Record_Type__c == 'Renewal Opportunity' && dd.Deal_Desk_Team__c == 'Deal Operations'){
                    if((dd.ETM_Theatre__c.contains('APAC'))||dd.ETM_Theatre__c.contains('EMEA')){
                dd.OwnerId = System.label.APAC_EMEA_DealDesk_Queue; //International Queue
                }
                else {
                    dd.OwnerId = System.label.Amer_DeakDesk_Queue; //Amer Queue
                }
            } 
            else if(((oldMap == null && dd.Deal_Desk_Team__c!=null ) || (oldMap!=null && dd.Deal_Desk_Team__c!=null && dd.Deal_Desk_Team__c != oldMap.get(dd.Id).Deal_Desk_Team__c))
               && (dd.ETM_Region__c!=null)&& (((dd.Deal_Desk_Team__c == 'Deal Structuring'))||((dd.Deal_Desk_Team__c == 'Deal Operations')&&(regions.contains(dd.ETM_Region__c))))
 ){
                   dd.OwnerId = System.label.Cyrus_Sharif_UserId;
                   for(Deal_Desk_Assignees__c ddasgn  : ddAsgnMapping){
                       if(dd.Deal_Desk_Team__c == ddasgn.Deal_Desk_Team__c){
                           etmRegionList.clear();
                           if(ddasgn.ETM_Region__c!=null){
                               String str = ddasgn.ETM_Region__c.deleteWhitespace();
                               etmRegionList = str.split(',');
                           }
                           
                           if(etmRegionList!=null && !etmRegionList.isEmpty()){
                               if(etmRegionList.contains(dd.ETM_Region__c)){
                                   dd.OwnerId = ddasgn.Assignee__c;
                               }
                           }
                       }
                   }
               }
            //DD25-55 starts
            else if(((oldMap == null && dd.Deal_Desk_Team__c!=null ) || (oldMap!=null && dd.Deal_Desk_Team__c!=null && dd.Deal_Desk_Team__c != oldMap.get(dd.Id).Deal_Desk_Team__c))
             && (dd.ETM_Region__c!=null) && ((dd.Deal_Desk_Team__c == 'Deal Operations'))&&(!(regions.contains(dd.ETM_Region__c)))){
                dd.OwnerId = System.label.Cyrus_Sharif_UserId;
                if(String.isNotBlank(dd.ETM_Theatre__c)){ 
                    if((dd.ETM_Theatre__c.contains('APAC'))||dd.ETM_Theatre__c.contains('EMEA')){
                    dd.OwnerId = System.label.APAC_EMEA_DealDesk_Queue;

                    }else{
                       dd.OwnerId = System.label.Amer_DeakDesk_Queue;
                    }  
                }
               }
                           //DD25-55 ends
            else if(((oldMap == null && dd.Deal_Desk_Team__c!=null ) || 
                     (oldMap!=null && dd.Deal_Desk_Team__c!=null && dd.Deal_Desk_Team__c != oldMap.get(dd.Id).Deal_Desk_Team__c))
                    && (dd.ETM_Region__c==null)){
                        dd.OwnerId = System.label.Cyrus_Sharif_UserId;
                    }
        }       
    }
    /** 
     * @description recall Approvals
     * @param ddCaseNewList
     * @param oldMap
     *  this will executes recallApprovals
     */
    //method to update the Deal Desk Case status corresponding to the Approval Status
    public static void recallApprovals(List<Deal_Desk_Case__c> ddCaseNewList, Map<Id,Deal_Desk_Case__c> oldMap){
        try{
            system.debug(LoggingLevel.DEBUG, 'DDCaseTriggerHandler.recallApprovals started');
            Set<Id> closedIncompleteDDC= new Set<Id>(); 
            for(Deal_Desk_Case__c eachDdCase : ddCaseNewList){
                if(eachDdCase.Request_Status__c=='Closed - Incomplete' && oldMap.get(eachDdCase.Id).Request_Status__c!= eachDdCase.Request_Status__c){
                    closedIncompleteDDC.add(eachDdCase.Id);                     
                }
            }
            if(!closedIncompleteDDC.isEmpty()){
                List<sbaa__approval__c> approvals= new List<sbaa__approval__c>() ;
                for(sbaa__approval__c eachApproval : [Select Id from sbaa__approval__c where Deal_Desk_Case__c in :closedIncompleteDDC And sbaa__Status__c not in ('Approved','Rejected','Recalled', 'Revoked','Conditionally Approved')]){
                    approvals.add(new sbaa__approval__c(Id=eachApproval.Id,sbaa__Status__c='Closed - Incomplete'));
                }
                if(!approvals.isEmpty()){
                    update approvals;
                }
                //recallApprovalsAsync(closedIncompleteDDC);
            }
        }
        catch(exception ex){
            system.debug(LoggingLevel.DEBUG, 'DDCaseTriggerHandler.recallApprovals ==> '+ex.getMessage());
        }
    }
    /**
     * @description recall Approvals Async
     * @param dDCIdSet
     *  this will executes recallApprovalsAsync
     */
    //since AA package's recall method does not work in bulk calling it in future to avoid hitting governor limit
    @future
    public static void recallApprovalsAsync(Set<Id> dDCIdSet){
        for(Id recordId:dDCIdSet){
            SBAA.ApprovalAPI.recall(recordId, SBAA__Approval__c.Deal_Desk_Case__c);
        }
    }
	 /**
     * @description update Case Status
     * @param newList
     * @param oldMap
     *  this will executes updateCaseStatus
     */    
    //method to update the Deal Desk Case status corresponding to the Approval Status
    public static void updateCaseStatus(List<Deal_Desk_Case__c> newList, Map<Id,Deal_Desk_Case__c> oldMap){
        try{
            for(Deal_Desk_Case__c dd : newList){
                if(dd.ApprovalStatus__c == 'Pending' && oldMap.get(dd.Id).ApprovalStatus__c!='Pending'){
                    dd.Request_Status__c = 'Requested';
                    //dd.Case_Status__c = 'Requested'; //dd25-4 //SAL26-481 make it commented.
                } 
                //adding 3rd condition if the case is marked as closed- incomplete then automation will recall the approval records,
                // in order to avoid updating the case status again to recalled
                if(dd.ApprovalStatus__c == 'Recalled' && oldMap.get(dd.Id).ApprovalStatus__c!='Recalled' && dd.Request_Status__c!='Closed - Incomplete'){
                    dd.Adhoc_Approval_Requested__c=FALSE;
                    dd.Request_Status__c = 'Recalled';
                }
                if(dd.ApprovalStatus__c == 'Approved' && oldMap.get(dd.Id).ApprovalStatus__c!='Approved'){
                    dd.Adhoc_Approval_Requested__c=FALSE;
                    if(dd.Amount_Conditional__c!=null || dd.Amount_Conditional__c>0 || dd.Primary_Quote_Conditional__c!=null || dd.Close_Date_Conditional__c!=null ){
                        dd.Request_Status__c = 'Conditionally Approved';
                    }else{
                        dd.Request_Status__c = 'Approved';
                        dd.Case_Status__c = 'Closed'; //dd25-4
                    }
                }
                if(dd.ApprovalStatus__c == 'Rejected' && oldMap.get(dd.Id).ApprovalStatus__c!='Rejected'){
                    dd.Adhoc_Approval_Requested__c=FALSE;
                    dd.Request_Status__c = 'Rejected';
                    dd.Case_Status__c = 'Closed'; //dd25-4
                }
             }
            
        }
        catch(exception ex){
            system.debug(LoggingLevel.DEBUG, 'DDCaseTriggerHandler.updateCaseStatus ==> '+ex.getMessage());
        }
    }
	/**
     * @description update Count On Opp
     * @param newList
     * @param oldMap
     *  this will executes updateCountOnOpp
     * The below method updated as part of SAL26-481 where we are calculating the open Case count at Opportunity level based on case Status [We have replaced the Request_Status__c with Case_Status__c]
     * Also Previously Request Status's are hard coded but now we are fetching from schema class.
     */	
    //Method to update count of Open Deal Desk cases on related Opportunity
    public static void updateCountOnOpp(List<Deal_Desk_Case__c> newList, Map<Id,Deal_Desk_Case__c> oldMap){
        Set<Id> oppIds = new Set<Id>();
        list<Opportunity> oppLi = new List<Opportunity>();
        try{
            if(oldMap == null){
                for(Deal_Desk_Case__c ddLi : newList){
                    if(ddLi.Case_Status__c !='Closed'){
                        oppIds.add(ddli.Opportunity__c);
                    }
                }
            }
            else if(oldMap != null){
                for(Deal_Desk_Case__c ddLi : newList){
                    /*if((ddLi.Case_Status__c != oldMap.get(ddLi.Id).Case_Status__c) &&
                         ((openStatusSet.contains(ddLi.Case_Status__c) && !openStatusSet.contains(oldMap.get(ddLi.Id).Case_Status__c)) ||
                          (!openStatusSet.contains(ddLi.Case_Status__c) && openStatusSet.contains(oldMap.get(ddLi.Id).Case_Status__c)))){
                            oppIds.add(ddli.Opportunity__c);
                }*/
                    if((ddLi.Case_Status__c != oldMap.get(ddLi.Id).Case_Status__c)) {
                         oppIds.add(ddli.Opportunity__c);
                    }
            	}
            }
            if(oppIds!=null && !oppIds.isEmpty()){
                for(Opportunity opp : [Select id , (Select id , Case_Status__c from Deal_Desk_Cases__r where Case_Status__c !='Closed') from Opportunity where id in: oppIds]){
                    if(opp.Deal_Desk_Cases__r !=null){ //DD25-5
                    Opportunity opObj = new Opportunity();
                    opObj.Id = opp.Id;
                    opObj.Deal_Desk_Open_Cases__c = opp.Deal_Desk_Cases__r.size();
                    oppLi.add(opObj);
                    }
                }
            }
            if(oppLi!=null && !oppLi.isEmpty()){
                update oppLi;
            }
        }
        catch(exception ex){
            system.debug(LoggingLevel.DEBUG,'DDCaseTriggerHandler.updateCountOnOpp ==> '+ex.getMessage());
        }  
    }
    /**
     * @description send Email Notification
     * @param newList
     * @param oldMap
     *  this will executes sendEmailNotification
     */
    //Send Email notification on DD Case creation and re-assignment
    public static void sendEmailNotification(List<Deal_Desk_Case__c> newList, Map<Id,Deal_Desk_Case__c> oldMap){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<FeedItem> FeedItemList = New List<FeedItem>(); //DD25-6
        map<string,id> emailTemptoIdMap = new map<string,id>();
        List<EmailTemplate> emTemp = [SELECT Id, DeveloperName FROM EmailTemplate where DeveloperName in ('Deal_Desk_Case_Creation_Notification','Deal_Desk_Case_Reassignment','DDC_Status_Change_Email_Notification','Deal_Desk_Case_Urgent_Notification')];
        for(EmailTemplate et : emTemp){
            emailTemptoIdMap.put(et.DeveloperName,et.Id);
        }
        List<OrgWideEmailAddress> owEmail = [SELECT id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName ='No Reply' LIMIT 1];
        try{
            if(oldMap == null){
                for(Deal_Desk_Case__c ddc : newList){
                    List<ID> listofOwners = new List<ID>();
                    if(ddc.Tertiary_Owner__c != null && ddc.Secondary_owner__c != null){
                        listofOwners.add(ddc.Secondary_owner__c);
                        listofOwners.add(ddc.Tertiary_Owner__c);
                    }
                    // to send email notification to requestor when case is created
                    Set<String> userIds = new Set<String>();
                    if(ddc.Account_Executive_ID__c!=null){
                        userIds.add(ddc.Account_Executive_ID__c);
                    }
                    //userIds.add(System.label.Cyrus_Sharif_UserId);
                    Messaging.SingleEmailMessage email = EmailHelper.getSingleEmailMessageObj(userIds, null, null, ddc.Requestor__c, ddc.Id, emailTemptoIdMap.get('Deal_Desk_Case_Creation_Notification'));
                    email.setOrgWideEmailAddressId(owEmail[0].Id);
                    mails.add(email);

                    //to send email notification to case owner when case is marked as urgent //DD25-6
                    if(ddc.Urgent__c){
                        Messaging.SingleEmailMessage email1 = EmailHelper.sendEmail(emailTemptoIdMap.get('Deal_Desk_Case_Urgent_Notification'), ddc.OwnerId, ddc.Id);
                            email1.setOrgWideEmailAddressId(owEmail[0].Id);
                                email1.setCcAddresses(listofOwners);
                            mails.add(email1); 
                            FeedItem post = new FeedItem();
                            post.ParentId = ddc.OwnerId;
                            post.Body = 'You have an Urgent Deal Desk Case. Please review by clicking this notification';
                            post.Title = ddc.Name;
                            post.LinkUrl = '/lightning/r/Deal_Desk_Case__c/' + ddc.ID + '/view';
                            FeedItemList.add(post);
                    }
                }
            }
            else if(oldMap !=null){
                for(Deal_Desk_Case__c ddc : newList){
                    // to send email notification to new owner when case is reassigned
                    if(ddc.OwnerId!=oldMap.get(ddc.Id).OwnerId && ddc.OwnerId!=null){
                        Messaging.SingleEmailMessage email = EmailHelper.sendEmail(emailTemptoIdMap.get('Deal_Desk_Case_Reassignment'), ddc.OwnerId, ddc.Id);
                        email.setOrgWideEmailAddressId(owEmail[0].Id);
                        mails.add(email); 
                    }
                    // to send email notification to new Secondry owner
                    if(ddc.Secondary_owner__c!=oldMap.get(ddc.Id).Secondary_owner__c && ddc.Secondary_owner__c!=null){
                    Messaging.SingleEmailMessage email = EmailHelper.sendEmail(emailTemptoIdMap.get('Deal_Desk_Case_Reassignment'), ddc.Secondary_owner__c, ddc.Id);
                        email.setOrgWideEmailAddressId(owEmail[0].Id);
                        mails.add(email);
                    }
                    // to send email notification to Tertiary Owner
                        if(ddc.Tertiary_Owner__c!=oldMap.get(ddc.Id).Tertiary_Owner__c && ddc.Tertiary_Owner__c!=null){
                    Messaging.SingleEmailMessage email = EmailHelper.sendEmail(emailTemptoIdMap.get('Deal_Desk_Case_Reassignment'), ddc.Tertiary_Owner__c, ddc.Id);
                        email.setOrgWideEmailAddressId(owEmail[0].Id);
                        mails.add(email);
                    }
                    // to send email notification to requestor when case status is changed SAL26-481 Replaced Request Status to Case Status
                        if(ddc.Case_Status__c!=oldMap.get(ddc.Id).Case_Status__c){
                        Set<String> userIds = new Set<String>();
                        if(ddc.Account_Executive_ID__c!=null){
                        userIds.add(ddc.Account_Executive_ID__c);
                        }
                        //userIds.add(System.label.Cyrus_Sharif_UserId);
                        Messaging.SingleEmailMessage email = EmailHelper.getSingleEmailMessageObj(userIds, null, null, ddc.Requestor__c, ddc.Id, emailTemptoIdMap.get('DDC_Status_Change_Email_Notification'));
                        email.setOrgWideEmailAddressId(owEmail[0].Id);
                        String emailhtmlBody = email.getHtmlBody();
                        emailhtmlBody = emailhtmlBody.replace('original_status',oldMap.get(ddc.Id).Case_Status__c);
                        email.setHtmlBody(emailhtmlBody);
                        mails.add(email); 
                }
                //to send email notification to case owner when case is marked as urgent DD25-6
                if(ddc.Urgent__c && !oldMap.get(ddc.Id).Urgent__c){
                    Messaging.SingleEmailMessage email = EmailHelper.sendEmail(emailTemptoIdMap.get('Deal_Desk_Case_Urgent_Notification'), ddc.OwnerId, ddc.Id);
                        email.setOrgWideEmailAddressId(owEmail[0].Id);
                        mails.add(email); 
                        FeedItem post = new FeedItem();
                        post.ParentId = ddc.OwnerId;
                        post.Body = 'You have an Urgent Deal Desk Case. Please review by clicking this notification';
                        post.Title = ddc.Name;
                        post.LinkUrl = '/lightning/r/Deal_Desk_Case__c/' + ddc.ID + '/view';
                        FeedItemList.add(post);
                }
                }
            }
            if(!mails.isEmpty() && !test.isRunningTest()){
                Messaging.sendEmail(mails);
            }
             //DD25-6
             if (FeedItemList.size()>0) {         
                insert FeedItemList;                
            }
        }
        catch(Exception ex){
            system.debug(LoggingLevel.DEBUG, 'exception occured: '+ex.getMessage());
        }
    }
    
    /**
     * @description update Questionare
     * @param newList
     * @param oldMap
     *  this will executes updateQuestionare
     */
    //Add questionnare based on Request Sub-Types
     public static void updateQuestionare(List<Deal_Desk_Case__c> newList, Map<Id,Deal_Desk_Case__c> oldMap){
        set<Id> ddcIds = new Set<Id>();
        Map<Id,List<String>> ddcIdtoReqType = new Map<Id,List<String>>();
        List<Deal_Desk_Template_Questions__mdt> quesMdt = [select Request_Type__c, Template_Question__c from Deal_Desk_Template_Questions__mdt];
        Map<String,String> valToQuesMap = new Map<String,String>();
        for(Deal_Desk_Template_Questions__mdt mdt : quesMdt){
            valToQuesMap.put(mdt.Request_Type__c,mdt.Template_Question__c);
        }
        if(oldMap == null){
            for(Deal_Desk_Case__c ddc : newList){
                ddcIds.add(ddc.Id);
                ddcIdtoReqType.put(ddc.Id,ddc.Request_Type__c.split(';'));
            }
        }
        if(oldmap!=null){
            for(Deal_Desk_Case__c ddc : newList){
                if(ddc.Deal_Desk_Team__c != oldMap.get(ddc.Id).Deal_Desk_Team__c || ddc.Request_Type__c!=oldMap.get(ddc.Id).Request_Type__c){
                    ddcIds.add(ddc.Id);
                    ddcIdtoReqType.put(ddc.Id,ddc.Request_Type__c.split(';'));
                }
            }
         }
        if(!ddcIds.isEmpty() && ddcIds.size()>0){
            for(Deal_Desk_Case__c ddc : newList){
                String ques = '-> Provide Quote Number!';
                if(ddcIdtoReqType.containsKey(ddc.Id)){
                    for(String st : ddcIdtoReqType.get(ddc.Id)){
                        if(valToQuesMap.containsKey(st)){
                            if(st!='General Inquiry'){
                                ques = ques +'\n'+'-> ' +valToQuesMap.get(st);
                            }
                            else if(st=='General Inquiry'){
                                if(ddc.Deal_Desk_Team__c == 'Deal Operations'){
                                    ques = ques+ '\n' + '->What are you trying to quote?'+
                                        '\n' + 'Attach a screenshot of the error in Attachments.'+
                                        '\n' + 'Please refer to our cannon page for much of our Quoting Processes and Guidance.';
                                }
                                else if(ddc.Deal_Desk_Team__c == 'Deal Structuring'){
                                    ques = ques+ '\n' + '->How can we help you?'+
                                        '\n' + 'Please explain your issue in detail.'+
                                        '\n' + 'Please refer to our cannon page for much of our Deal Structuring Guidance.';
                                }
                            }
                        }
                    }
                }
                ddc.Business_Justification_Questions__c = ques;
            }
        }
    } 
    
    //Method to reOpen Conditionally Approved cases based on Conditionally Approved conditions and sending out emails to AE and DD team
   /* public static void conditionalApprovalFlow(List<Deal_Desk_Case__c> newList, Map<Id,Deal_Desk_Case__c> oldMap){
        Set<Id> ddUpdateIds = new Set<Id>();
        Set<Id> ddIdsforClosedOpp = new Set<Id>();
        List<Deal_Desk_Case__c> ddcUpdateLi = new List<Deal_Desk_Case__c>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        map<string,id> emailTemptoIdMap = new map<string,id>();
        List<EmailTemplate> emTemp = [SELECT Id, DeveloperName FROM EmailTemplate where DeveloperName in ('DDC_Conditional_Approval_Oppty_Closed')];
        for(EmailTemplate et : emTemp){
            emailTemptoIdMap.put(et.DeveloperName,et.Id);
        }
        List<OrgWideEmailAddress> owEmail = [SELECT id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName ='No Reply' LIMIT 1];
        try{
            //to update status and send email when Oppty is below stage 6
            for(Deal_Desk_Case__c dd : newList){
                if(dd.Request_Status__c == 'Conditionally Approved' && !closedOppStages.contains(dd.Opportunity_Stage__c) && 
                   (dd.Amount_TCV__c != oldMap.get(dd.Id).Amount_TCV__c || dd.Close_Date__c != oldMap.get(dd.Id).Close_Date__c || dd.Primary_Quote__c != oldMap.get(dd.Id).Primary_Quote__c )){
                       if(dd.Amount_Conditional__c!=null && dd.Amount_TCV__c < dd.Amount_Conditional__c){
                           ddUpdateIds.add(dd.Id);
                       }
                       if(dd.Close_Date_Conditional__c!=null && dd.Close_Date__c > dd.Close_Date_Conditional__c){
                           ddUpdateIds.add(dd.Id);
                       }
                       if(dd.Primary_Quote_Conditional__c!=null && dd.Primary_Quote__c != dd.Primary_Quote_Conditional__c){
                           ddUpdateIds.add(dd.Id);
                       }
                   }
            }
            if(!ddUpdateIds.isEmpty() && ddUpdateIds.size()>0){
                for(Deal_Desk_Case__c ddc : newList){
                    if(ddUpdateIds.contains(ddc.Id)){
                        Deal_Desk_Case__c ddupdate = new Deal_Desk_Case__c();
                        ddupdate.Id = ddc.Id;
                        ddupdate.Request_Status__c = 'Draft';
                        ddupdate.ApprovalStatus__c = null;
                        ddcUpdateLi.add(ddupdate);
                    }
                }
            }
            if(!ddcUpdateLi.isEmpty() && ddcUpdateLi.size()>0){
                update ddcUpdateLi;
            }
            //to send email when conditions are not met and oppty is getting closed
            for(Deal_Desk_Case__c ddcase : newList){
                if(ddcase.Opportunity_Stage__c!=oldMap.get(ddcase.Id).Opportunity_Stage__c && ddcase.Request_Status__c == 'Conditionally Approved' && closedOppStages.contains(ddcase.Opportunity_Stage__c)){
                    if(ddcase.Amount_Conditional__c!=null && ddcase.Amount_TCV__c < ddcase.Amount_Conditional__c){
                        ddIdsforClosedOpp.add(ddcase.Id);
                    }
                    if(ddcase.Close_Date_Conditional__c!=null && ddcase.Close_Date__c > ddcase.Close_Date_Conditional__c){
                        ddIdsforClosedOpp.add(ddcase.Id);
                    }
                    if(ddcase.Primary_Quote_Conditional__c!=null && ddcase.Primary_Quote__c != ddcase.Primary_Quote_Conditional__c){
                        ddIdsforClosedOpp.add(ddcase.Id);
                    }
                }
            }
            if(!ddIdsforClosedOpp.isEmpty() && ddIdsforClosedOpp.size()>0){
                for(Deal_Desk_Case__c ddcase : newList){
                    if(ddIdsforClosedOpp.contains(ddcase.Id)){
                        Set<String> userIds = new Set<String>();
                        if(ddcase.Account_Executive_ID__c!=null){
                            userIds.add(ddcase.Account_Executive_ID__c);
                        }
                         if(ddcase.Requestor__c!=null){
                            userIds.add(ddcase.Requestor__c);
                        }
                        //userIds.add(System.label.Cyrus_Sharif_UserId);
                        Messaging.SingleEmailMessage email = EmailHelper.getSingleEmailMessageObj(userIds, null, null, ddcase.OwnerId, ddcase.Id, emailTemptoIdMap.get('DDC_Conditional_Approval_Oppty_Closed'));
                        email.setOrgWideEmailAddressId(owEmail[0].Id);
                        mails.add(email);
                    }          
                }
            }
            if(!mails.isEmpty() && !test.isRunningTest()){
                Messaging.sendEmail(mails);
            }
        }
        catch(Exception ex){
            system.debug('exception occured: '+ex.getMessage());
        }
    }
    */
    //Method to post on chatter if Request Type, Request Sub-Type or Business Justification changes.
    /**
     * @description post On Chatter
     * @param newList
     * @param oldMap
     *  this will executes postOnChatter
     */
    public static void postOnChatter(List<Deal_Desk_Case__c> newList, Map<Id,Deal_Desk_Case__c> oldMap){
        list<FeedItem> listFI = new list<FeedItem>();
        for(Deal_Desk_Case__c ddc : newList){
            if(ddc.Request_Type__c != oldMap.get(ddc.Id).Request_Type__c){
                listFI.add(ChatterUtil.postOnFeed(ddc.Id,'Request Type'+'\n'+oldMap.get(ddc.Id).Request_Type__c +' to '+ddc.Request_Type__c));
            }
            //if(ddc.Request_Sub_Type__c != oldMap.get(ddc.Id).Request_Sub_Type__c && oldMap.get(ddc.Id).Request_Sub_Type__c!=null && ddc.Request_Sub_Type__c!=null){
                //listFI.add(ChatterUtil.postOnFeed(ddc.Id,'Request Sub-Type'+'\n'+oldMap.get(ddc.Id).Request_Sub_Type__c +' to '+ddc.Request_Sub_Type__c));
            //}
            //else if(ddc.Request_Sub_Type__c != oldMap.get(ddc.Id).Request_Sub_Type__c && oldMap.get(ddc.Id).Request_Sub_Type__c==null){
                //listFI.add(ChatterUtil.postOnFeed(ddc.Id,'Request Sub-Type'+'\n'+'Blank to '+ddc.Request_Sub_Type__c));
           // }
            //else if(ddc.Request_Sub_Type__c != oldMap.get(ddc.Id).Request_Sub_Type__c && ddc.Request_Sub_Type__c==null){
                //listFI.add(ChatterUtil.postOnFeed(ddc.Id,'Request Sub-Type'+'\n'+oldMap.get(ddc.Id).Request_Sub_Type__c +' to Blank'));
            //}
            
            if(ddc.Business_Justification__c != oldMap.get(ddc.Id).Business_Justification__c){
                listFI.add(ChatterUtil.postOnFeed(ddc.Id,'Business Justification'+'\n'+oldMap.get(ddc.Id).Business_Justification__c +' to '+ddc.Business_Justification__c));
            }
        }
        if(listFI.size()>0 && !listFI.isEmpty()){
            insert listFI;
        }
    }
    /**
     * @description update D D Case Status
     * @param oppLi
     *  this will executes updateDDCaseStatus
     This Method has been updated with case status as part of SAL26-481.
     */
 //this method is call'd from Opportunity trigger handler, it closes the open cases if their related Opp is closed
    public static void updateDDCaseStatus(List<Opportunity> oppLi){
         list<Deal_Desk_Case__c> ddUpdateList = new List<Deal_Desk_Case__c>();
        
        /*list<Deal_Desk_Case__c> ddUpdateList = new List<Deal_Desk_Case__c>();
        if(oppLi!=null && oppLi.size()>0){
            //Replaced below loop with Case status as part of SAL26-481.
            for(Deal_Desk_Case__c ddLi : [Select Id,Case_Status__c,Summary_of_Approval__c,Deal_Desk_Tagging__c from  Deal_Desk_Case__c where Opportunity__c in: oppLi]){
                if(ddLi.Case_Status__c != 'Closed'){
                    ddli.Case_Status__c = 'Closed';
                }
                if(ddLi.Deal_Desk_Tagging__c == null){
                    ddLi.Deal_Desk_Tagging__c ='Other';
                }
                if(ddLi.Summary_of_Approval__c == null || ddLi.Summary_of_Approval__c =='') {
                    ddLi.Summary_of_Approval__c = ' ';
                }
                ddUpdateList.add(ddLi);
            }
           // for(Deal_Desk_Case__c ddLi : [Select Id,Request_Status__c from  Deal_Desk_Case__c where Opportunity__c in: oppLi]){
             //   if(ddLi.Request_Status__c == 'Draft' || ddLi.Request_Status__c == 'On Hold' || ddLi.Request_Status__c == 'Requested' ||
               //    ddLi.Request_Status__c == 'Modification Requested' || ddLi.Request_Status__c == 'Recalled'){
                    //   
                  //     ddli.Request_Status__c = 'Closed - Incomplete';
                //       ddUpdateList.add(ddLi);
              //     }
            //}
        }
        if(ddUpdateList!=null && ddUpdateList.size()>0){
            update ddUpdateList;
        }*/
    }
    /**
     * @description re Open Case
     * @param ddcIds
     *  this will executes reOpenCase
     */
    //DD25-13
    public static void reOpenCase(Set<Id> ddcIds){
        List<Deal_Desk_Case__c> ddListUpdate = new List<Deal_Desk_Case__c>();
        if(ddcIds != null){
            for(Deal_Desk_Case__c ddList : [Select Id, Case_Status__c from Deal_Desk_Case__c where Id in: ddcIds]){
                if(ddList.Case_Status__c == 'Closed'){
                    Deal_Desk_Case__c ddcObj = new Deal_Desk_Case__c();
                    ddcObj.Id = ddList.Id;
                    ddcObj.Case_Status__c = 'Requested';
                    ddcObj.ApprovalStatus__c = '';
                    ddcObj.Case_Auto_Created__c = False;
                    ddListUpdate.add(ddcObj);
                }
            }
        }
        
        if(ddListUpdate!=null && !ddListUpdate.isEmpty()){
            update ddListUpdate;
            //autoSubmitCase(ddListUpdate);
        }
    }
    /**
     * @description prevent Deletion
     * @param DDClist
     *  this will executes PreventDeletion
     */
       // DD25-77 Method to prevent deletion of DD case record
       public static void preventDeletion(List<Deal_Desk_Case__c> DDClist){
        SOX_Objects_Delete_Access__c userPermission = SOX_Objects_Delete_Access__c.getInstance(UserInfo.getUserId());
            for (Deal_Desk_Case__c ddc : DDClist) {
           if (!userPermission.Allow_DDcase_delete__c) {
                ddc.addError('You are not authorized to delete this record.');
            }
        }
    }
           // DD25-88 Method to prevent duplicate
    /*public static void preventDuplicate(List<Deal_Desk_Case__c> DDclist , Map<Id,Deal_Desk_Case__c> oldMap){
        Set<Id> parentPrQtIds = new Set<Id>();
        for (Deal_Desk_Case__c ddc : DDclist) {
            System.debug(ddc.Primary_Quote__c);
            if ((oldMap == null && ddc.Primary_Quote__c != null ) || (oldMap != null && ddc.Primary_Quote__c != null && ddc.Primary_Quote__c != oldMap.get(ddc.Id).Primary_Quote__c))
             {
                parentPrQtIds.add(ddc.Primary_Quote__c);
            }
        }
         Map<Id, List<Deal_Desk_Case__c>> prQtsToCases = new Map<Id, List<Deal_Desk_Case__c>>();
        if (!parentPrQtIds.isEmpty() && parentPrQtIds != null) {
        List<Deal_Desk_Case__c> existingCases = [
            SELECT Id, Primary_Quote__c,Name
            FROM Deal_Desk_Case__c
            WHERE Primary_Quote__c IN :parentPrQtIds
        ];
        for (Deal_Desk_Case__c ddc : existingCases) {
            if (!prQtsToCases.containsKey(ddc.Primary_Quote__c)) {
                prQtsToCases.put(ddc.Primary_Quote__c, new List<Deal_Desk_Case__c>());
            }
            prQtsToCases.get(ddc.Primary_Quote__c).add(ddc);
        }
        }

        for (Deal_Desk_Case__c ddc : DDclist) {
            if (ddc.Primary_Quote__c != null && prQtsToCases.containskey(ddc.Primary_Quote__c)) {
            if ((oldMap == null && ddc.Primary_Quote__c != null ) || (oldMap != null && ddc.Primary_Quote__c != null && ddc.Primary_Quote__c != oldMap.get(ddc.Id).Primary_Quote__c))
                {
                ddc.addError('A case '+ prQtsToCases.get(ddc.Primary_Quote__c)[0].Name +' already exists for this parent Opportunity.');
                }
            }
        }
        
        } */
        // DD25-88 ends
}