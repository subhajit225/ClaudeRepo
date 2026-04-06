/**
    @Created By   : Santosh
    @Class Name   : CCRAndPOCPendingApprovalController
    @Description  : SAL-1275 Identify Current Pending Approver on CCR and POC Request
*/
public without sharing class CCRAndPOCPendingApprovalController {
    
    //Constants
    private static final Set<String> allPendingApprovalSet = new Set<String>{'POC__c', 'CCR__c'};
    
    /**
       @Name   : getCCRAndPOCPendingApprovalList
       @param  : objectName
       @Return : get list pf all pending approval
    */
    @AuraEnabled
    public static List<pendingApprovalWrapper> getCCRAndPOCPendingApprovalList(String selectedObj) {
       
        System.debug('selectedObj@@' + selectedObj);
        System.debug('allPendingApprovalSet@@' + allPendingApprovalSet);
        
        Set<String> setAllObj = new Set<String>();
        if(String.isNotBlank(selectedObj)) {
           if(selectedObj.equalsIgnoreCase('All')) {
                setAllObj.addAll(allPendingApprovalSet);
           } else {
                setAllObj.add(selectedObj);
           }
        }
        
        System.debug('setAllObj@@' + setAllObj);
        Set<Id> actorIds = new Set<Id>();
        
        if(!Test.isRunningTest()) {
            actorIds = getAllActorId(new Set<Id>{Userinfo.getUserId()});
        }
        
        //Soql query to get pending approval
        String childQuery = 'SELECT Id, ActorId, Actor.Name, OriginalActorId, OriginalActor.Name, StepStatus, Comments, ProcessNode.Name, CreatedDate'+
                ' FROM StepsAndWorkitems WHERE StepStatus = \'Pending\' ';
        if(!actorIds.isEmpty()) {
            childQuery += ' AND ActorId IN :actorIds ';
        }
        Integer rowLimit = Limits.getLimitQueryRows() - Limits.getQueryRows();
        String strMainQuery = 'SELECT Id, Status, TargetObjectId, TargetObject.Name, '
                             +' ( '+childQuery + ' )'
                             + ' FROM ProcessInstance WHERE Status = \'Pending\' '
                             + ' AND ProcessDefinition.TableEnumOrId IN :setAllObj '
                             + ' ORDER BY TargetObjectId LIMIT :rowLimit ';
        
        System.debug('strMainQuery@@@'+strMainQuery);        
        List<pendingApprovalWrapper> pendingApprovalRecList = new List<pendingApprovalWrapper>();
        for (ProcessInstance pi: Database.query(strMainQuery) ) {
                //TargetObjectId will be selected from set
               if(pi.StepsAndWorkItems.size() > 1) {
                   System.debug(pi.TargetObjectId+'@@');
               }
               for (ProcessInstanceHistory pih : pi.StepsAndWorkItems) {
                   pendingApprovalWrapper pendingApprovalRec = new pendingApprovalWrapper();
                   pendingApprovalRec.Status = pih.StepStatus;
                   pendingApprovalRec.RecordName = String.valueOf(pi.TargetObject.Name);
                   pendingApprovalRec.RecordId = String.valueOf(pi.TargetObjectId);
                   pendingApprovalRec.RecordLink = '/'+String.valueOf(pi.TargetObjectId);
                   pendingApprovalRec.RecordObject = String.valueOf(pi.TargetObjectId.getSObjectType()).split('__')[0];
                   //pendingApprovalRec.AssignedToName = String.valueOf(pih.OriginalActor.Name);
                   pendingApprovalRec.ApproverName = pih.Actor.Name;
                   pendingApprovalRec.CreatedDate = String.valueOf(pih.CreatedDate);
                   pendingApprovalRec.approveRejectLink ='/p/process/ProcessInstanceWorkitemWizardStageManager?id='+pih.id;
                   //pendingApprovalRec.actionLabel = 'Approve / Reject';
                   pendingApprovalRec.reassignLink = '/'+pih.id+'/e?et=REASSIGN';
                   //pendingApprovalRec.reassignLabel = 'Reassign';
                   pendingApprovalRecList.add(pendingApprovalRec);
                }          
        }
         System.debug('@@'+pendingApprovalRecList.size());
        return pendingApprovalRecList;
    }
    
    /**
       @Name   : getAllActorId
       @param  : currentUserIds
       @Return : set<Id> of user's associated queue
    */
    @TestVisible
    private static set<Id> getAllActorId(Set<Id> currentUserIds) {
        
        set<Id> allActorId = new set<Id>(currentUserIds);
        Set<Id> ccrPocQueueId = new Set<Id>();
        Map<Id,Id> queuePublicGroupId = new Map<Id,Id>();
        for(QueueSobject queueSobj : [SELECT id,SobjectType,QueueId,Queue.Name 
                FROM QueueSobject 
                    WHERE SobjectType IN ('CCR__c','POC__c')]) {
            ccrPocQueueId.add(queueSobj.QueueId);
        }
       
        Set<Id> memberGroupIds =  new Set<Id>();
        for(GroupMember gm : [SELECT GroupId,UserOrGroupId,group.DeveloperName FROM GroupMember WHERE UserOrGroupId IN :currentUserIds]) {
            memberGroupIds.add(gm.GroupId);
        }

        //can add addtional conddition - AND UserOrGroupId IN currentUserIds+memberGroupIds
        for(GroupMember gmq : [SELECT GroupId,UserOrGroupId , group.DeveloperName FROM GroupMember WHERE GroupId IN :ccrPocQueueId]) {
            if(currentUserIds.contains(gmq.UserOrGroupId) || memberGroupIds.contains(gmq.UserOrGroupId)) {
                allActorId.add(gmq.GroupId);
            }
        }
        return allActorId;
    }
    
    // Wrapper Class to display data on Page
    public class pendingApprovalWrapper{
        @AuraEnabled
        public String Status {get; set;}
        @AuraEnabled
        public String RecordName {get; set;}
        @AuraEnabled
        public String RecordId {get; set;}
        @AuraEnabled
        public String RecordLink {get; set;}
        @AuraEnabled
        public String RecordObject {get; set;}
        @AuraEnabled
        public String AssignedToName {get; set;}
        @AuraEnabled
        public String ApproverName {get; set;}
        @AuraEnabled
        public String CreatedDate {get; set;}
        @AuraEnabled
        public String approveRejectLink {get; set;}
        @AuraEnabled
        public String actionLabel {get; set;}
        @AuraEnabled
        public String reassignLink {get; set;}
        @AuraEnabled
        public String reassignLabel {get; set;}
        
        public pendingApprovalWrapper() {
            reassignLabel = 'Reassign';
            actionLabel = 'Approve / Reject';
            Status = '';
            RecordObject = '';
            RecordLink = '';
            RecordId = '';
            approveRejectLink = '';
        }        
    }
}