public without sharing class ApprovalRequestWidgetController {
    
    @AuraEnabled(cacheable=true)
    public static List<sbaa__Approval__c> getApprovalRequests(String loggedInUserId){
        List<sbaa__Approval__c> loggedInUserApprovalRequests = new List<sbaa__Approval__c>();
        Set<Id> groupIds = new Set<Id>();
        Map<Id, Id> mapAppIdGroupId = new Map<Id, Id>();
        Map<Id, sbaa__Approval__c> mapIdApprovalRec = new Map<Id, sbaa__Approval__c>();
        List<GroupMember> groupMembers = [SELECT Id, GroupId FROM GroupMember WHERE UserOrGroupId = :loggedInUserId];
        Set<String> strId = new Set<String>();
        if(groupMembers != null && !groupMembers.isEmpty()){
            for(GroupMember grpMbr: groupMembers){   
               /************ Below changes has been done as a part of CPQ22-4753*****/
                String str = String.ValueOf(grpMbr.GroupId);
                if(str.length() == 18){
                    strId.add(str);
                    strId.add(str.substring(0, 15));  
                }
                /********************************************************************/
            }
        }
        List<sbaa__Approval__c> approvalRecords = [SELECT Id, Name, Quote__c, Quote__r.Name, sbaa__Status__c,
        Quote__r.SBQQ__Opportunity2__c, Quote__r.SBQQ__Opportunity2__r.Name, Quote__r.SBQQ__Opportunity2__r.StageName,
        Quote__r.ETM_Area__c,Quote__r.ETM_Region__c, Quote__r.ApprovalStatus__c,Quote__r.SBQQ__NetAmount__c,Quote__r.SBQQ__SubscriptionTerm__c,
        Quote__r.TotalACV__c, CreatedBy.Name	, Deal_Desk_Case__c,Deal_Desk_Case__r.Name,
        Deal_Desk_Case__r.Opportunity__c,Deal_Desk_Case__r.Opportunity__r.Name,
        Deal_Desk_Case__r.Opportunity__r.StageName, Deal_Desk_Case__r.Opportunity__r.ETM_Area__c,
        Deal_Desk_Case__r.Opportunity__r.ETM_Region__c    FROM sbaa__Approval__c 
        WHERE 
        ((Deal_Desk_Case__c != NULL AND Deal_Desk_Case__r.Opportunity__c != NULL AND 
        Deal_Desk_Case__r.Opportunity__r.StageName NOT IN ('6 PO With Channel', '7 Closed Won', '7 Closed Lost', '7 Closed Admin')) OR
        (Quote__c != NULL AND Quote__r.SBQQ__Opportunity2__c != NULL AND Quote__r.SBQQ__Status__c = 'In Review' AND
        Quote__r.SBQQ__Opportunity2__r.StageName NOT IN ('6 PO With Channel', '7 Closed Won', '7 Closed Lost', '7 Closed Admin')))
        AND sbaa__Status__c = 'Requested'
        AND (sbaa__AssignedTo__c =: loggedInUserId OR sbaa__AssignedGroupId__c IN: strId)];
        
        if(approvalRecords != null && !approvalRecords.isEmpty()){
            loggedInUserApprovalRequests.addAll(approvalRecords);
        }
        return loggedInUserApprovalRequests;
    }
}