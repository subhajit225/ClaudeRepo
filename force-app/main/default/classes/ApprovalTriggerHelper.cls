/**
 * @description Helper class for handling approval-related logic for CPQ and Deal Desk objects.
 * Provides validation, duplication checks, record type assignment, status sync, and notification handling.
 */
public without sharing class ApprovalTriggerHelper {

    static final String SYSTEM_ADMINISTRATOR_PROFILE = 'System Administrator';
    static final String SALES_OPERATIONS_PROFILE = 'Sales Operations';
    
    static final String DEAL_DESK_GROUP = 'Deal_Desk';
    static final String STATUS_APPROVED = 'Approved';
    static final String DEAL_DESK= 'Deal_Desk_Case__c';
    static final String CPQ_QUOTE= 'Quote__c';
    
    /**
     * @description Determines approval type (Quote or Deal Desk) and routes to respective duplicate check methods.
     * @param listApproval List of Approval records to evaluate.
     */
    public static void duplicateCheck(List<sbaa__Approval__c> listApproval) {
        List<sbaa__Approval__c> quoteApprovalList= new List<sbaa__Approval__c> ();
        List<sbaa__Approval__c> DDcApprovalList= new List<sbaa__Approval__c> ();
        for(sbaa__Approval__c eachApproval: listApproval){
            if(eachApproval.sbaa__RecordField__c ==DEAL_DESK){
                DDcApprovalList.add(eachApproval);
            }else if(eachApproval.sbaa__RecordField__c==CPQ_QUOTE){
                quoteApprovalList.add(eachApproval);
            }
        }
        
        if(!quoteApprovalList.isEmpty()){
            duplicateCheckForQuoteApprovals(quoteApprovalList);
        }
        if(!DDcApprovalList.isEmpty()){
            duplicateCheckForDDCApprovals(DDcApprovalList);
        }
    }
    /**
     * @description Validates duplicate quote approvals based on Quote ID and Rule.
     * @param quoteApprovalList List of quote approval records to check.
     */
    public static void duplicateCheckForQuoteApprovals(List<sbaa__Approval__c> quoteApprovalList){
         Set <Id> setQuoteId = new Set<Id>(); 
         Set <Id> setRuleId = new Set<Id>();  
              
        for (sbaa__Approval__c approvalRec : quoteApprovalList) {
   
           setQuoteId.add(approvalRec.Quote__c);
           setRuleId.add(approvalRec.sbaa__Rule__c);
        }
         
        if (!(setQuoteId.isEmpty())) {
        List<sbaa__Approval__c> previousApprovals = [ 
            SELECT
                Id,
                Quote__c,
                sbaa__Rule__c,
                sbaa__Status__c
            FROM 
                sbaa__Approval__c 
            WHERE 
                sbaa__Status__c in  ('Requested','In Queue')
            AND 
                Quote__c in : setQuoteId
            AND
                sbaa__Rule__c in : setRuleId
            ];
          if (!previousApprovals.isEmpty()) {
             for (sbaa__Approval__c approvalRec : quoteApprovalList) {
               approvalRec.addError('Approval Record is already Existing, please Return to Quote.');
             }
          }
         
        }
    }
    
    /**
     * @description Validates whether the current user can modify the Assigned To field in approvals.
     * @param listApproval List of approval records being updated.
     * @param mapNewApproval Map of approval IDs to their new versions.
     */
    public static void validateUser(
            List<sbaa__Approval__c> listApproval,
            Map<Id, sbaa__Approval__c> mapNewApproval
    ) {
        //CPQ22-4021 Starts - added check for Custom Label. The Users in this label can only bypass this validation
        Boolean check = false;
        List<String> lstofUsers = System.Label.IT_Users_special_Access.split(',');
        if (lstofUsers != null && !lstofUsers.isEmpty()) {
            for (String str : lstofUsers) {
                str = str.trim();
                String userLoggedIn = userinfo.getUserId().toString();
                if (userLoggedIn == str) {
                    check = true;
                }
            }
        }
        //CPQ22-4021 Commented below profile check since we should not be bypassing for the Profiles.
        /*List<Profile> listProfile = new List<Profile>();
        listProfile = [SELECT Name
                       FROM Profile
                       WHERE ID = :userinfo.getProfileId()
                       AND Name != :SYSTEM_ADMINISTRATOR_PROFILE
                       //AND Name != :SALES_OPERATIONS_PROFILE
                       LIMIT 1
                      ];

        if (!listProfile.isEmpty()) {
            //CPQ22-4021 Ends
            */
            List<sbaa__Approval__c> listApprovals = new List<sbaa__Approval__c>();
            Set<Id> setApprovalGroupId = new Set<Id>();
            Set<Id> setDelegatedApprovals = new Set<Id>();
            Set<Id> setGroupId = new Set<Id>();
            Map<Id, sbaa__Approver__c> mapApprover = new Map<Id, sbaa__Approver__c>();
            
            for (sbaa__Approval__c objApproval : listApproval) {
                if (objApproval.sbaa__AssignedTo__c != null && objApproval.sbaa__AssignedTo__c == userinfo.getUserId()) {
                    break;
                } else if (objApproval.sbaa__AssignedGroupId__c != null) {
                    setApprovalGroupId.add(objApproval.sbaa__AssignedGroupId__c);
                }
                
                if (objApproval.sbaa__DelegatedApprover__c != null) {
                    setDelegatedApprovals.add(objApproval.sbaa__DelegatedApprover__c);
                }
                
                listApprovals.add(objApproval);
            }
            
            if (!setDelegatedApprovals.isEmpty()) {
                mapApprover = new Map<Id, sbaa__Approver__c>(
                                [SELECT Id
                                       , Name
                                       , sbaa__User__c
                                       , sbaa__GroupId__c
                                 FROM sbaa__Approver__c
                                 WHERE Id IN: setDelegatedApprovals
                                ]);
                
                for (sbaa__Approver__c objApprover : mapApprover.values()) {
                    if (objApprover.sbaa__GroupId__c != null) {
                        setApprovalGroupId.add(objApprover.sbaa__GroupId__c);
                    }
                }
            }
            
            if (!setApprovalGroupId.isEmpty()) {
                //CPQ22-4021 - Removed check for Deal Desk group so that the validation is not bypassed for them too - "OR Group.Name = :DEAL_DESK_GROUP "
                for (
                        GroupMember objGroupMember :
                            [SELECT GroupId
                             FROM GroupMember
                             WHERE UserOrGroupId = :UserInfo.getUserId()
                             AND ( GroupId IN :setApprovalGroupId
                                )
                            ]
                ) {
                    setGroupId.add(objGroupMember.GroupId);
                }
            }
            
            
            
            for (sbaa__Approval__c objApproval : listApprovals) {
                if (
                        (objApproval.sbaa__AssignedTo__c != null
                            && objApproval.sbaa__AssignedTo__c == userinfo.getUserId())
                        || (objApproval.sbaa__AssignedGroupId__c != null
                            && !setGroupId.isEmpty() && setGroupId.contains(objApproval.sbaa__AssignedGroupId__c))
                        || (objApproval.sbaa__DelegatedApprover__c != null
                            && mapApprover.containsKey(objApproval.sbaa__DelegatedApprover__c)
                            && ((mapApprover.get(objApproval.sbaa__DelegatedApprover__c).sbaa__User__c != null
                                    && mapApprover.get(objApproval.sbaa__DelegatedApprover__c).sbaa__User__c == userinfo.getUserId())
                                || (mapApprover.get(objApproval.sbaa__DelegatedApprover__c).sbaa__GroupId__c != null
                                    && !setGroupId.isEmpty()
                                    && setGroupId.contains(mapApprover.get(objApproval.sbaa__DelegatedApprover__c).sbaa__GroupId__c))))
                ) {
                    continue;
                }
            
                //CPQ22-4021 added if condition
                if (!check) {
                    mapNewApproval.get(objApproval.Id).addError(
                    System.Label.Reassign_Error_Message
                );
                }
            //}
        }
    }
    
    /**
     * @description Automatically marks approvals as approved when applicable.
     * @param listApproval List of approval records to process.
     */
    public static void autoApprovalList(List<sbaa__Approval__c> listApproval) { 
        Set<Id> lstApprovals = new Set<Id>();
        
        if (!listApproval.isEmpty()) {
            for (sbaa__Approval__c appRec : listApproval) {
                if (appRec.sbaa__Status__c == 'Approved' && appRec.Approvals_from_Source_Quote__c == false) { //AG- CPQ22-5275 Added check of approvals from source quote for POC
                    appRec.Auto_Approved__c = true;
                    appRec.sbaa__ApprovedBy__c = System.Label.Smart_Approved;
                    //FY26WL-542 no comments
                    appRec.sbaa__CommentsLong__c = null;
                }
            }
        }
    }//CPQ22-726 ends

    /**
     * @description Assigns Deal Desk record type to relevant approval requests.
     * @param listApproval List of approvals to update.
     */
    public static void assignDDCRecordType(List<sbaa__Approval__c> listApproval){
        Set<Id> approvesrslist = new Set<Id>();
        for(sbaa__Approval__c eachApproval:listApproval){
            if(eachApproval.sbaa__RecordField__c==DEAL_DESK || eachApproval.RecordTypeId==Schema.SObjectType.sbaa__Approval__c.getRecordTypeInfosByName().get('Deal Desk Approvals').getRecordTypeId()){               
                eachApproval.RecordTypeId=Schema.SObjectType.sbaa__Approval__c.getRecordTypeInfosByName().get('Deal Desk Approvals').getRecordTypeId();
                eachApproval.sbaa__RecordField__c=DEAL_DESK;
                if(eachApproval.sbaa__AssignedTo__c==null || String.isblank(eachApproval.sbaa__AssignedTo__c)){
                    approvesrslist.add(eachApproval.sbaa__Approver__c );
                }
            }
        }
        if(!approvesrslist.isEmpty()){
            Map<Id,sbaa__Approver__c> approversData= new Map<Id,sbaa__Approver__c>([Select id,sbaa__User__c from sbaa__Approver__c where id in :approvesrslist and sbaa__User__c!=null]);
            if(approversData!=null && !approversData.isEmpty()){
                for(sbaa__Approval__c eachApproval:listApproval){
                    if(eachApproval.sbaa__RecordField__c==DEAL_DESK && approversData.containsKey(eachApproval.sbaa__Approver__c)){
                        eachApproval.sbaa__AssignedTo__c=approversData.get(eachApproval.sbaa__Approver__c).sbaa__User__c;
                    }
                }
            }  
        }
    }
    
 /**
     * @description Validates duplicate Deal Desk approvals and flags adhoc approval requests.
     * @param DDcApprovalList List of Deal Desk approval records to check.
     */
    public static void duplicateCheckForDDCApprovals(List<sbaa__Approval__c> DDcApprovalList){
        Set <Id> setDDcId = new Set<Id>(); 
        Set <Id> setRuleId = new Set<Id>();  
        Set <Id> setDDcIdForAdhocApprovals = new Set<Id>(); 
        String approvalRule = System.Label.approvalRule;
        for (sbaa__Approval__c approvalRec : DDcApprovalList) {
            if(approvalRec.sbaa__Rule__c!= approvalRule){
                setDDcId.add(approvalRec.Deal_Desk_Case__c);
                setRuleId.add(approvalRec.sbaa__Rule__c);
            }else{
                setDDcIdForAdhocApprovals.add(approvalRec.Deal_Desk_Case__c);
            }
        }
        
        if (!(setDDcId.isEmpty())) {
            List<sbaa__Approval__c> previousApprovals = [ 
                SELECT
                Id,
                Deal_Desk_Case__c,
                sbaa__Rule__c,
                sbaa__Status__c
                FROM 
                sbaa__Approval__c 
                WHERE 
                sbaa__Status__c in  ('Requested','In Queue')
                AND 
                Deal_Desk_Case__c in : setDDcId
                AND
                sbaa__Rule__c in : setRuleId
            ];
            if (!previousApprovals.isEmpty()) {
             for (sbaa__Approval__c approvalRec : DDcApprovalList) {
               approvalRec.addError('Approval Record is already Existing, please Return to Case.');
             }
          }
         
        }
        
        //updating flag on deal desk case to avoid deletion of adhoc approval requests
        if(!setDDcIdForAdhocApprovals.isEmpty()){
            List<Deal_Desk_Case__c> ddList= new List<Deal_Desk_Case__c>();
            for(Id eachDDcId:setDDcIdForAdhocApprovals){
                ddList.add(new Deal_Desk_Case__c(Id=eachDDcId,Adhoc_Approval_Requested__c=true));
            }
            if(!ddList.isEmpty()){
                update ddList;
            }
        }
    }
  
    /**
     * @description Performs validation on Deal Desk approval record updates.
     * @param dDCApprovalOldMap Map of old approval records.
     * @param DDcApprovalList List of updated approval records.
     */
    public static void checkForDDCValidations(Map<Id,sbaa__Approval__c> dDCApprovalOldMap,List<sbaa__Approval__c> DDcApprovalList){
        for(sbaa__Approval__c eachApproval: DDcApprovalList){
            /*if(eachApproval.sbaa__RecordField__c==DEAL_DESK &&eachApproval.sbaa__Status__c != null && eachApproval.sbaa__Status__c!=dDCApprovalOldMap.get(eachApproval.Id).sbaa__Status__c
               && (eachApproval.sbaa__Status__c== STATUS_APPROVED || eachApproval.sbaa__Status__c=='Rejected')){
                if(eachApproval.sbaa__CommentsLong__c ==null){
                    eachApproval.addError('Comments are mandatory to Approve/Reject the approval request.');       
                }
            }*/
            if(eachApproval.sbaa__Status__c!=dDCApprovalOldMap.get(eachApproval.Id).sbaa__Status__c){
                //if(dDCApprovalOldMap.get(eachApproval.Id).sbaa__Status__c!='Waiting On Others'){
                    eachApproval.Previous_Status__c =dDCApprovalOldMap.get(eachApproval.Id).sbaa__Status__c;
                //}
                //else{
                  //  eachApproval.Previous_Status__c =dDCApprovalOldMap.get(eachApproval.Id).Previous_Status__c;
                //}
            }
        }   
    }
    /**
     * @description Posts chatter comments and syncs case status based on approval updates.
     * @param dDCApprovalOldMap Map of old approval records.
     * @param DDcApprovalList List of updated approval records.
     */
    public static void syncDDCStatus(Map<Id,sbaa__Approval__c> dDCApprovalOldMap,List<sbaa__Approval__c> DDcApprovalList){
        list<Deal_Desk_Case__c> ddclist = new list<Deal_Desk_Case__c>();
        list<FeedItem> listFI = new list<FeedItem>();
        
        for(sbaa__Approval__c eachApproval: DDcApprovalList){
            if(eachApproval.sbaa__RecordField__c==DEAL_DESK){
                if(eachApproval.sbaa__Status__c != null && eachApproval.sbaa__Status__c!=dDCApprovalOldMap.get(eachApproval.Id).sbaa__Status__c){
                    /*if(eachApproval.sbaa__Status__c=='On Hold'){
                        ddclist.add(new Deal_Desk_Case__c(Id=eachApproval.Deal_Desk_Case__c, Request_Status__c='On Hold'));
                    }
                    else if(dDCApprovalOldMap.get(eachApproval.Id).sbaa__Status__c=='On Hold' && eachApproval.sbaa__Status__c=='Requested'){
                        ddclist.add(new Deal_Desk_Case__c(Id=eachApproval.Deal_Desk_Case__c, Request_Status__c='Requested'));
                    }
                    else */if(eachApproval.sbaa__Status__c=='Approved' || eachApproval.sbaa__Status__c=='Rejected' || eachApproval.sbaa__Status__c=='Conditionally Approved' ){
                        if(eachApproval.sbaa__CommentsLong__c !=null){
                           String comments= 'Request '+eachApproval.Name +' has been '+eachApproval.sbaa__Status__c+' with follwing comments : \n'+eachApproval.sbaa__CommentsLong__c;
                           listFI.add(ChatterUtil.postOnFeed(eachApproval.Deal_Desk_Case__c, comments));
                       }
                    }
                }
                /*if( dDCApprovalOldMap.get(eachApproval.Id).Additional_Comments__c  !=  eachApproval.Additional_Comments__c ) {
                    listFI.add(ChatterUtil.postOnFeed(eachApproval.Deal_Desk_Case__c,'User comments have been updated on the approval record '+eachApproval.Name+' :\n'+eachApproval.Request_To_Information_Comment__c));
                }*/
            
            }
        }
        if(!ddclist.isEmpty()){
            update ddclist;
        }
        if(!listFI.isEmpty()){
            insert listFI;
        }   
    }

    /**
     * @description Sends email notification for conditionally approved Deal Desk approvals.
     * @param approvalList List of updated approval records.
     * @param oldApprovalMap Map of old approval records.
     */
    public static void sendConditionalApprovalEmail(List<sbaa__Approval__c> approvalList, Map<Id,sbaa__Approval__c> oldApprovalMap)
    {
        Set<id> conditionallyapproved= new Set<Id>();
        for(sbaa__Approval__c eachApproval:approvalList){
            if(eachApproval.sbaa__Status__c!=oldApprovalMap.get(eachApproval.Id).sbaa__Status__c &&  eachApproval.sbaa__status__c == 'Conditionally Approved'){
                conditionallyapproved.add(eachApproval.Id);
            }
        }
        if(!conditionallyapproved.isEmpty()){
            EmailTemplate et = [SELECT Id,Subject, Body FROM EmailTemplate WHERE Name ='DDC Conditionally Approved'];
            List<OrgWideEmailAddress> owEmail = [SELECT id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName ='No Reply' LIMIT 1];
            Map<Id,sbaa__Approval__c> approvalMap=new Map<Id,sbaa__Approval__c>([Select Id, OwnerId,Owner.Email,Deal_Desk_Case__r.Owner.Email from sbaa__Approval__c where id in :conditionallyapproved]);
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            for(Id approvalId :approvalMap.keySet()){
                List<String> toaddresses= new List<String>();
                toaddresses.add(approvalMap.get(approvalId).Owner.Email);
                toaddresses.add(approvalMap.get(approvalId).Deal_Desk_Case__r.Owner.Email);
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, approvalMap.get(approvalId).OwnerId, approvalId);
                String emailSubject = email.getSubject();
                String emailTextBody = email.getPlainTextBody();
                email.setToAddresses(toaddresses);
                email.setTargetObjectId(approvalMap.get(approvalId).OwnerId);
                email.setSubject(emailSubject);
                email.setPlainTextBody(emailTextBody);
                email.saveAsActivity = false;
                email.setOrgWideEmailAddressId(owEmail[0].Id);
                allmsg.add(email); 
                
                
            }
            if(!allmsg.isEmpty()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(allmsg);
                if (results[0].isSuccess()) {
                    System.debug(LoggingLevel.DEBUG,'Email sent successfully.');
                } else {
                    System.debug(LoggingLevel.DEBUG,'Email failed to send. Error: ' + results[0].getErrors()[0].getMessage());
                }
            }
        }
    } 
    
    /**
     * @description Prevents deletion of approval records by non-admin users.
     * @param approvalList List of approvals marked for deletion.
     * @param oldApprovalMap Map of original approval records before deletion.
     */
     public static void preventApprovalDeletion(List<sbaa__Approval__c> approvalList, Map<Id,sbaa__Approval__c> oldApprovalMap)
    {
         List<Profile> listProfile = new List<Profile>();
        listProfile = [SELECT Name
                       FROM Profile
                       WHERE ID = :userinfo.getProfileId()
                       AND Name Like '%Admin%'];

        if(listProfile.isEmpty()){
            for(sbaa__Approval__c eachRec: approvalList){
                eachRec.addError('You do not have permissions to delete approval records. Kindly reach out to your Administrators for help!');
            }
        }
    } 
}