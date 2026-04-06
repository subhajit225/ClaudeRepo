/**
 * @description CaseTransferApprovalRequest as controller class for Case Transfer LwC Components[CS21-482]
 *
 * @CreatedDate 10th June 2021
 * @Created By Veera Gandi
 * 
 * @test: CaseTransferApprovalRequestTest
 */
public without sharing class CaseTransferApprovalRequest {
    /**
	* @description suggestedQueueandOwnerIds map
	*/
    public static Map<String, string> suggestedQueueandOwnerIds;
    
    /**
    * @description method to programatically submit case record for approval
    * @param  caseId case Submitted for approval
    * @param  caseComment Case Comment to be updated in approval submission Comment
    */
    @AuraEnabled
    public static void submitCaseForTransferRequestApproval(Id caseId, Integer caseComment) {
        try {
            string setComment = 'Submitted Case for Case Transfer Approval Request.';
            
            if (caseComment != null) {
                setComment += ' Monitor Inbounds. Please Review Case Comment# ' + caseComment;
            }
            List<Case> caseList = [SELECT id, Is_TA_Case__c, Account.US_Federal_Account__c, Account.ASE_Account__c, CaseTA_Transfer_Notification_Slack_Email__c FROM Case WHERE id=: caseId];
            if(!caseList.isEmpty()){
                Case caseRecord = caseList[0];
                if(caseRecord.Is_TA_Case__c && !caseRecord.Account.US_Federal_Account__c && !caseRecord.Account.ASE_Account__c){
                    caseRecord.CaseTA_Transfer_Notification_Slack_Email__c = System.Label.ta_case_transfer_SlackEmail;
                    update caseRecord;
                }
            }
            
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments(setComment);
            approvalRequest.setObjectId(caseId);
            Approval.ProcessResult result = Approval.process(approvalRequest);
            
            //when submitted for approval the record is locked
            //unlock the record
            List<Approval.UnlockResult> unlockCase = Approval.unlock(new List<Case>{new Case(Id=caseId)}, false);
        } catch (Exception ex) {
            throw new AuraHandledException('Error : '+ ex.getMessage());    
        }
    }
    
    /**
    * @description method to programatically approve Case record.
    * @param  caseId case Submitted for approval
    * @param  action 
    * @param  message
    */
    @AuraEnabled
    public static void approveCaseTransferRequest(Id caseId, String action, String message) {
        try {
            List<ProcessInstance> processInstances = [SELECT Id, Status, TargetObjectId 
                                                      FROM ProcessInstance 
                                                      WHERE Status='Pending' 
                                                      AND TargetObjectId = :caseId
                                                      LIMIT 1];
            
            if (!processInstances.isEmpty()) {
                List<ProcessInstanceWorkitem> processWorkItems = [SELECT Id, ProcessInstanceId 
                                                                  FROM ProcessInstanceWorkitem 
                                                                  WHERE ProcessInstanceId = :processInstances[0].Id
                                                                  LIMIT 1];
                
                if (!processWorkItems.isEmpty()) {
                    Approval.ProcessWorkitemRequest approvalRequest = new Approval.ProcessWorkitemRequest();
                    approvalRequest.setNextApproverIds(new Id[] {UserInfo.getUserId()});
                    approvalRequest.setWorkitemId(processWorkItems[0].Id);
                    approvalRequest.setComments(message);
                    approvalRequest.setAction(action);
                    Approval.ProcessResult result = Approval.process(approvalRequest);
                }
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error : '+ ex.getMessage()); 
        }
    }
    
    
    /**
    * @description method to check if the current user is support manager
    * @param isSubmitted
    * @return boolean 
    */
    @AuraEnabled(cacheable=true)
    public static boolean isSupportManager(Boolean isSubmitted) {
        Boolean isSupportManager = false;
        
        if (isSubmitted) {
            List<String> managerProfiles = Label.CaseTransferManagerProfiles.trim().split(',');
            
            for (Profile managerProfile : [SELECT Id FROM Profile WHERE Name IN :managerProfiles]) {
                if (UserInfo.getProfileId() == managerProfile.Id) {
                    isSupportManager = true;
                    break;
                }
            }
        }
        
        return isSupportManager;
    }
    
    /**
    * @description update case owner based after transfer request is approved/rejected.
    * @param  newCase trigger context variable
    * @param  oldCase trigger context variable
    */
    public static void updateCaseTransferOwner(List<Case> newCase, Map<Id, Case> oldCase) {
        getSuggestedQueueOwnerIdMapping();
        
        for (Case eachCase : newCase) {
            if (eachCase.CaseTransferStatus__c != oldCase.get(eachCase.Id).CaseTransferStatus__c) {
                
                if(eachCase.CaseTransferStatus__c == 'Approved'
                   && suggestedQueueandOwnerIds.containsKey(eachCase.SuggestedTransferQueue__c)) {
                    //In Progress - to update id's to custom metadata                    
                    eachCase.OwnerId = suggestedQueueandOwnerIds.get(eachCase.SuggestedTransferQueue__c);
                    eachCase.CaseTransferStatus__c = '';
                    CaseTriggerHandler.IS_TRANSFER_QUEUE_APPROVED = true;
                } else if ((eachCase.CaseTransferStatus__c == 'Rejected' || eachCase.CaseTransferStatus__c == 'Recalled')
                           && string.isNotBlank(eachCase.CaseTransferPreviousOwnerId__c))
                {
                    eachCase.OwnerId = eachCase.CaseTransferPreviousOwnerId__c;
                    eachCase.CaseTransferStatus__c = '';
                } 
            }
        }
    }
    
    /**
    * @description construct Queue Name > QueueId map, this map is used to update case owner after transfer request is approved.
    * @return Map<String, string>
    */
    public static Map<String, string> getSuggestedQueueOwnerIdMapping() {

        if (suggestedQueueandOwnerIds == null) {
            suggestedQueueandOwnerIds = new Map<String, string>();
            
            for(Key_Value__mdt  transferQueueMapping : [SELECT Id, Key__c, Value__c FROM Key_Value__mdt
                                                        WHERE MasterLabel  = 'TransferQueues']) {
                suggestedQueueandOwnerIds.put(transferQueueMapping.Key__c, transferQueueMapping.Value__c);
            }
        }
        
        return suggestedQueueandOwnerIds;
    }
    /**
	* @description List of assist requests.
    * @param caseId used to get assist request records
    * @return List of AssistRequest records
	*/
    @AuraEnabled(cacheable=true)
    public static List<Assist_Request__c> getAssistRequests(Id caseId) {
        return [
            SELECT Id, Name, Type__c, Priority__c, Status__c, Owner.Name
            FROM Assist_Request__c
            WHERE Case__c = :caseId
        ];
    }
    /**
	* @description Wrapper Class for selected Case information
	*/
    public class CaseInfoWrapper{
        /**
        * @description isOldCase set to TRUE if case closeddate is greater than 7 days
        */
        @AuraEnabled public Boolean isOldCase {get;set;}
        /**
        * @description errorMessage to show custom error on Case Transfer Request form
        */
        @AuraEnabled public String errorMessage {get;set;}
    }
    /**
	* @description Wrapper Class for selected Case information
    * @param caseId is used to get details of Case
    * @return CaseInfoWrapper which will give details of case and error message if closed case is older than 7 days and will publish a Platform event to create CaseComment record.
	*/
    @AuraEnabled(cacheable=true)
    public static CaseInfoWrapper getCaseDetails(Id caseId){
        CaseInfoWrapper caseWrap = new CaseInfoWrapper();
        caseWrap.isOldCase = false;
        caseWrap.errorMessage = '';
        if(caseId!=null && !FeatureManagement.checkPermission('Bypass_Disallow_Closed_Case_Change_After_7_Days')){
            Set<String> excludedUserTypes = parseCustomLabel(System.Label.Exclude_User_Types, ',');
            Set<String> excludedUserIds = parseCustomLabel(System.Label.Exclude_User_Ids, ',');
            if(excludedUserTypes!=null && !excludedUserTypes.contains(UserInfo.getUserType()) && excludedUserIds!=null && !excludedUserIds.contains(UserInfo.getUserId())){
                Case cs = [SELECT Id, RecordType__c, CaseNumber, ClosedDate, isClosed FROM Case WHERE Id=: caseId];
                if(cs!=null && cs.RecordType__c == 'Support Case' && cs.isClosed && (System.now() > cs.ClosedDate.addDays(7) || Test.isRunningTest())){
                    Case_Change_Event__e closedCaseChanged = new Case_Change_Event__e();
                    closedCaseChanged.Changed_Field_Name__c = 'Case Transfer';
                    closedCaseChanged.Case_Id__c = cs.Id;
                    closedCaseChanged.Case_Number__c = cs.CaseNumber;
                    closedCaseChanged.User_Id__c = UserInfo.getUserId();
                    EventBus.publish(closedCaseChanged);
                    String msg = 'Case ' + cs.CaseNumber + ' has been closed for over 7 days. Please create a new case in Salesforce.';
                    caseWrap.errorMessage = msg;
                    caseWrap.isOldCase = true;
                }
            }
        }
        return caseWrap;
    }
    
    /**
	* @description CS21-3898 Added to extract the values from custom label
	* @param labelValue
	* @param delimiter
	* @return values stored in Custom Label
	*/
    private static Set<String> parseCustomLabel(String labelValue, String delimiter) {
        Set<String> values = new Set<String>();
        if (String.isNotBlank(labelValue)) {
            for (String val : labelValue.split(delimiter)) {
                values.add(val.trim());
            }
        }
        return values;
    }
}