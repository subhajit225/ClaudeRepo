global class UpdateClusterIssueOnCapacityChangeBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext context){
        String batchQuery = 'SELECT Id, Mute_Notifications__c, Priority__c, Cluster__r.Capacity_Days_Until_100__c, Account__r.OwnerId,'
                    + ' Account_Owner__c, Owner__c, Account__c FROM Cluster_Issue__c WHERE Cluster__r.Capacity_Days_Until_100__c != NULL AND Status__c != \'Closed\'';
        return Database.getQueryLocator(batchQuery);
    }

    global void execute(Database.BatchableContext context, List<Cluster_Issue__c> clusterIssueList) {
        List<Cluster_Issue__c> clusterIssueListToUpdate = new List<Cluster_Issue__c>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Id> accountIdEngineerIdMap = new Map<Id, Id>();
        Boolean recordModified = false;
        Integer onsetP1 = Integer.valueOf(System.Label.Onset_Days_P1);
        Integer onsetP2 = Integer.valueOf(System.Label.Onset_Days_P2);

        for(Cluster_Issue__c eachClusterIssue : clusterIssueList){
            accountIdSet.add(eachClusterIssue.Account__c);
        }

        Map<Id, Territory2> territoryMap = new Map<Id, Territory2>([SELECT Id,
                                                                        (SELECT Id, UserId
                                                                        FROM UserTerritory2Associations
                                                                        WHERE IsActive = true
                                                                        AND RoleInTerritory2 = 'Sales Engineer'),
                                                                        (SELECT Territory2Id, ObjectId
                                                                        FROM ObjectTerritory2Associations
                                                                        WHERE ObjectId =: accountIdSet)
                                                                    FROM Territory2
                                                                    WHERE Id in (SELECT Territory2Id
                                                                                FROM ObjectTerritory2Association
                                                                                WHERE ObjectId =: accountIdSet
                                                                                AND Territory2.Territory2Model.State = 'Active')]);

        for(Territory2 eachTerritory : territoryMap.values()){
            if(!eachTerritory.UserTerritory2Associations.isEmpty()){
                Id userId = eachTerritory.UserTerritory2Associations[0].UserId;
                for(ObjectTerritory2Association eachObjectAssociation : eachTerritory.ObjectTerritory2Associations){
                    accountIdEngineerIdMap.put(eachObjectAssociation.ObjectId, userId);
                }
            }
        }

        for(Cluster_Issue__c eachClusterIssue : clusterIssueList){
            recordModified = false;
            if(eachClusterIssue.Cluster__r.Capacity_Days_Until_100__c > onsetP1 && eachClusterIssue.Cluster__r.Capacity_Days_Until_100__c <= onsetP2 && eachClusterIssue.Priority__c == 'P3') {
                eachClusterIssue.Priority__c = 'P2';
                eachClusterIssue.Mute_Notifications__c = false;
                recordModified = true;
            }
            else if(eachClusterIssue.Cluster__r.Capacity_Days_Until_100__c <= onsetP1 && eachClusterIssue.Priority__c != 'P1') {
                eachClusterIssue.Priority__c = 'P1';
                eachClusterIssue.Mute_Notifications__c = false;
                recordModified = true;
            }

            if(eachClusterIssue.Account_Owner__c != eachClusterIssue.Account__r.OwnerId) {
                eachClusterIssue.Account_Owner__c = eachClusterIssue.Account__r.OwnerId;
                recordModified = true;
            }

            if((accountIdEngineerIdMap.containsKey(eachClusterIssue.Account__c) && eachClusterIssue.Owner__c != accountIdEngineerIdMap.get(eachClusterIssue.Account__c))
                || (!accountIdEngineerIdMap.containsKey(eachClusterIssue.Account__c) && eachClusterIssue.Owner__c != eachClusterIssue.Account__r.OwnerId)) {
                eachClusterIssue.Owner__c = accountIdEngineerIdMap.containsKey(eachClusterIssue.Account__c) ?
                                            accountIdEngineerIdMap.get(eachClusterIssue.Account__c) :
                                            eachClusterIssue.Account__r.OwnerId;
                recordModified = true;
            }

            if(recordModified) {
                clusterIssueListToUpdate.add(eachClusterIssue);
            }
        }

        Database.SaveResult[] saveResults = Database.update(clusterIssueListToUpdate, false);
        List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();

        for(Database.SaveResult eachSaveResult : saveResults) {
            for(Database.Error eachError : eachSaveResult.getErrors()) {
                errorLogList.add(LogError.CreateDMLErrorLog('UpdateClusterIssueOnCapacityChangeBatch', null, eachError.getMessage(), 'Cluster Issue update error'));
            }
        }

        Database.SaveResult[] errorLogSaveResults = Database.insert(errorLogList, false);
    }

    global void finish(Database.BatchableContext context){
        if(!Test.isRunningTest()) {
            System.scheduleBatch(new UpdateClusterIssueOnCapacityChangeBatch(), 'Customer Proactive Response Updation - Class : UpdateClusterIssueOnCapacityChangeBatch', 15, 200);
        }
    }
}