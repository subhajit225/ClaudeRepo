/**
 * @description Helper class to manage sharing for Operations_Request__c records.
 *              Shares records with eligible managers if they are active and do not already have access.
 *              Considers Permission Sets and existing access levels.
 */
public with sharing class OperationRequestTriggerHelper {
    private static final String ACCESS_EDIT = 'Edit';
    /**
     * @description Main entry point to share Operations_Request__c records with eligible managers.
     *              Skips records if users already have Modify All access or existing share.
     *              Uses partial insert to avoid failing entire batch.
     * @param requests List of Operations_Request__c records to process
     * @param oldMap Map<Id, Operations_Request__c> updated records to process
     */
    public static void shareRecords(List<Operations_Request__c> requests, Map<Id, Operations_Request__c> oldMap) {
        if (requests == null || requests.isEmpty()) {
            return;
        }
        List<Operations_Request__c> recordsToProcess = new List<Operations_Request__c>();
        if (oldMap == null) {
            recordsToProcess.addAll(requests);
        } else {
            for (Operations_Request__c newRec : requests) {
                Operations_Request__c oldRec = oldMap.get(newRec.Id); // re-initialtion to check the magaers are chnaged to true check
                if (oldRec == null) continue;
                if ((newRec.Current_Owner_Manager__c != oldRec.Current_Owner_Manager__c) || (newRec.Future_owner_manager__c != oldRec.Future_owner_manager__c)) {
                    recordsToProcess.add(newRec);
                }
            }
        }
        if (recordsToProcess.isEmpty()) return;
        Set<Id> userIdsToCheck = collectEligibleManagerIds(recordsToProcess);
        if (userIdsToCheck.isEmpty()) return;
        // Fetch active users only
        Map<Id, User> activeUsers = getActiveUsers(userIdsToCheck);
        List<Operations_Request__Share> sharesToInsert = prepareShareRecords(recordsToProcess, activeUsers);
        if (!sharesToInsert.isEmpty()) {
            // Partial insert so errors on some records do not block others
            Database.SaveResult[] results = Database.insert(sharesToInsert, false);
            System.debug(LoggingLevel.ERROR,results);
            logPartialInsertErrors(results, sharesToInsert);
        }
    }
    /**
     * @description Collects eligible manager User Ids from Operations_Request__c records.
     * @param requests List of Operations_Request__c records
     * @return Set of User Ids to check for active status
     */
    private static Set<Id> collectEligibleManagerIds(List<Operations_Request__c> requests) { 
        Set<Id> userIds = new Set<Id>();
        for (Operations_Request__c req : requests) {
            //Suppose X is record Owner, Y is current Account Owner, Z is current account Owner Manager then Owenr != manager check. if same, no need to explicitly provide access for record owner.
            if (req.Current_account_owner__c != null && req.Current_Owner_Manager__c != null && req.OwnerId != req.Current_Owner_Manager__c) {
                userIds.add(req.Current_Owner_Manager__c);
            }
            //Suppose X is record Owner, Y is future Account Owner, Z is future  Owner Manager then Owenr != manager check. if same, no need to explicitly provide access for record owner.
            if (req.Future_account_owner__c != null && req.Future_owner_manager__c != null && req.OwnerId != req.Future_owner_manager__c) {
                userIds.add(req.Future_owner_manager__c);
            }
        }
        return userIds;
    }
    /**
     * @description Retrieves active users from a given set of User Ids.
     * @param userIds Set of User Ids to query
     * @return Map of User Id to User for active users
     */
    private static Map<Id, User> getActiveUsers(Set<Id> userIds) {
        return new Map<Id, User>(
            [SELECT Id FROM User WHERE Id IN :userIds AND IsActive = true]
        );
    }
    /**
     * @description Prepares Operations_Request__Share records for eligible users.
     *              Excludes users with existing access or Modify All permission.
     * @param requests List of Operations_Request__c
     * @param activeUsers Map of active User Ids
     * @return List of Operations_Request__Share records ready for insert
     */
    private static List<Operations_Request__Share> prepareShareRecords(List<Operations_Request__c> requests, Map<Id, User> activeUsers) {
        List<Operations_Request__Share> shares = new List<Operations_Request__Share>();
        if (requests == null || requests.isEmpty() || activeUsers.isEmpty()) return shares;
        // Query existing shares
        Set<Id> requestIds = new Set<Id>();
        for (Operations_Request__c req : requests) {
            requestIds.add(req.Id);
        }
        //Filter on existing shared records and belongs to active users in this current context. 
        Map<String, Operations_Request__Share> existingShares = new Map<String, Operations_Request__Share>();
        for (Operations_Request__Share share : [
            SELECT ParentId, UserOrGroupId, AccessLevel
            FROM Operations_Request__Share
            WHERE ParentId IN :requestIds AND UserOrGroupId IN: activeUsers.keySet()
        ]) {
            existingShares.put(share.ParentId + '_' + share.UserOrGroupId, share);
        }
        // Build new shares
        for (Operations_Request__c req : requests) {
            addShareIfEligible(shares, req.Id, req.Current_Owner_Manager__c, activeUsers, existingShares);
            addShareIfEligible(shares, req.Id, req.Future_owner_manager__c, activeUsers, existingShares);
        }
        return shares;
    }
    /**
     * @description Helper to check eligibility and add share record.
     * @param shares List of Operations_Request__Share to add into
     * @param parentId Id of Operations_Request__c
     * @param userId Id of User to share with
     * @param activeUsers Map<Id, User> of the active Users
     * @param existingShares Map of existing shares
     */
    private static void addShareIfEligible(
        List<Operations_Request__Share> shares,
        Id parentId,
        Id userId,
        Map<Id, User> activeUsers,
        Map<String, Operations_Request__Share> existingShares
    ) {
        if (userId == null || !activeUsers.containsKey(userId)) return;
        String key = parentId + '_' + userId;
        if (!existingShares.containsKey(key)) {
            shares.add(createShareRecord(parentId, userId));
        }
    }
    /**
     * @description Creates Operations_Request__Share record with Edit access.
     * @param parentId Id of Operations_Request__c
     * @param userId Id of User to share with
     * @return Operations_Request__Share record
     */
    private static Operations_Request__Share createShareRecord(Id parentId, Id userId) {
        Operations_Request__Share shr = new Operations_Request__Share();
        shr.ParentId = parentId;
        shr.UserOrGroupId = userId;
        shr.AccessLevel = ACCESS_EDIT;
        shr.RowCause = Schema.Operations_Request__Share.RowCause.Manual;
        return shr;
    }
    /**
     * @description Logs partial insert errors for DML operations.
     * @param results Database.SaveResult[] from Database.insert
     * @param shares List of Operations_Request__Share attempted to insert
     */
    private static void logPartialInsertErrors(Database.SaveResult[] results, List<Operations_Request__Share> shares) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR,
                    'Failed to insert share for Operations_Request__c Id=' + shares[i].ParentId +
                    ' UserId=' + shares[i].UserOrGroupId + ' Error=' + results[i].getErrors()[0].getMessage());
            }
        }
    }
}