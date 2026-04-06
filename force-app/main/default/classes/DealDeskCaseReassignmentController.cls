public with sharing class DealDeskCaseReassignmentController {

    @AuraEnabled
    public static list<Deal_Desk_Case__c> fetchFilteredRecords(list<Id> assigneeIds, String team, List<String> statusList){
        list<Deal_Desk_Case__c> ddCases = new List<Deal_Desk_Case__c>();
        String queryStr = '';
        String filterConditions = '';
        try {
            if(team!='' && team!=null){
                filterConditions = filterConditions + 'Deal_Desk_Team__c LIKE ' +'\''+team+'\'';
            }
            else {
                filterConditions = filterConditions + 'Deal_Desk_Team__c LIKE \'%\'';
            }
            if(assigneeIds.size()>0 && assigneeIds!=null){
                filterConditions = filterConditions + ' AND OwnerId IN :assigneeIds';
            }
            if(statusList.size()>0 && statusList!=null){
                filterConditions = filterConditions + ' AND Request_Status__c IN:statusList';
            }
            queryStr = 'Select ID, Name,OwnerId,Owner.Name, Deal_Desk_Team__c,Opportunity__c, Opportunity__r.Name, ';
            queryStr += 'Request_Status__c, Request_Type__c, Request_Sub_Type__c,SubmittedDate__c,ETM_Area__c,ETM_Theatre__c ';
            queryStr += 'FROM Deal_Desk_Case__c WHERE ';
            queryStr +=  filterConditions + ' AND OwnerId != NULL AND Opportunity__c != NULL  ORDER BY Name ASC LIMIT 49999';
            ddCases = database.query(queryStr);
            return ddCases;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<sObject> fetchReassignUser(String searchTerm){
       
    List<sObject> sObjectResultList = new List<sObject>();
        if(String.isNotEmpty(searchTerm)) {
            String query = 'Select Id, Name, Title from User Where Name LIKE \'' + searchTerm.trim() + '%\' and UserType =\'Standard\' order by createdDate DESC LIMIT 10';
            for(sObject so : Database.Query(query)) {
                sObjectResultList.add(so);
            }
        }
        return sObjectResultList;
    }

    @AuraEnabled
    public static List<Deal_Desk_Case__c> reAssignCase(List<Id> caseIds, Id assignToId, List<Id> filteredIds){
        list<Deal_Desk_Case__c> ddCases = new List<Deal_Desk_Case__c>();
        List<Deal_Desk_Case__c> ddcUpdateList = new List<Deal_Desk_Case__c>();
        try{
        if(caseIds.size() > 0 && caseIds != null && assignToId != null){
            for(Id cId : caseIds){
                Deal_Desk_Case__c ddc = new Deal_Desk_Case__c();
                ddc.Id = cId;
                ddc.OwnerId = assignToId;
                ddcUpdateList.add(ddc);
            }
        }
            if(ddcUpdateList.size()>0 && ddcUpdateList!=null){
                update ddcUpdateList;
            }
            if(filteredIds.size()>0 && !filteredIds.isEmpty()){
                ddCases = [Select ID, Name, OwnerId, Owner.Name, Deal_Desk_Team__c,Opportunity__c, Opportunity__r.Name,
                Request_Status__c, Request_Type__c, Request_Sub_Type__c,SubmittedDate__c,ETM_Area__c,ETM_Theatre__c 
                FROM Deal_Desk_Case__c
                WHERE Id IN :filteredIds AND OwnerId != NULL AND Opportunity__c != NULL
                ORDER BY Name ASC LIMIT 49999];
            }
            return ddCases;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}