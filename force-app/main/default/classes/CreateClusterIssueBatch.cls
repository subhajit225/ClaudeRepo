global class CreateClusterIssueBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext context){
        //Fetch the clusters which have less than 180 days left until the capacity reaches 100% only for Accounts which are of Customer,
        //MSP or MSP Reseller type
        String batchQuery = 'SELECT Id, Account__c, Account__r.OwnerId, Account__r.Type, Capacity_Days_Until_100__c, '
                            + '(SELECT Id, CPR_Close_Date__c, Status__c FROM Cluster_Issues__r ORDER BY CreatedDate Desc LIMIT 1), '
                            + '(SELECT Id, Model__c FROM Nodes__r) FROM Cluster__c WHERE Capacity_Days_Until_100__c != NULL '
                            + 'AND Capacity_Days_Until_100__c <= 180 AND Account__r.Type IN (\'Customer\',\'MSP\',\'MSP-Reseller\')';
        return Database.getQueryLocator(batchQuery);
    }

    global void execute(Database.BatchableContext context, List<Cluster__c> clusterList) {
        List<Cluster_Issue__c> clusterIssueListToInsert = new List<Cluster_Issue__c>();
        Cluster_Issue__c clusterIssueObject = new Cluster_Issue__c();
        List<Cluster__c> clusterListToBeProcessed = new List<Cluster__c>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Id> accountIdEngineerIdMap = new Map<Id, Id>();
        Integer clusterIssueLength = 0;
        Boolean isNodeModelEdge = false;
        Integer onsetP1 = Integer.valueOf(System.Label.Onset_Days_P1);
        Integer onsetP2 = Integer.valueOf(System.Label.Onset_Days_P2);
        Integer onsetP3 = Integer.valueOf(System.Label.Onset_Days_P3);

        //Iterate through each Cluster record and exlude the ones from processing which has atleast one Node of
        //Model Type as 'Edge'
        for(Cluster__c eachCluster : clusterList){
            for(Node__c eachNode : eachCluster.Nodes__r){
                if(eachNode.Model__c == 'Edge'){
                    isNodeModelEdge = true;
                }
            }

            if(!isNodeModelEdge) {
            accountIdSet.add(eachCluster.Account__c);
                clusterListToBeProcessed.add(eachCluster);
            }
            isNodeModelEdge = false;
        }

        //Fetch Sales Engineers for the accounts gathered above from their assigned active Territories
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

        //Create a map of Account Id and associated Sales Engineer User Id from the territories fetched above
        for(Territory2 eachTerritory : territoryMap.values()){
            if(!eachTerritory.UserTerritory2Associations.isEmpty()){
                Id userId = eachTerritory.UserTerritory2Associations[0].UserId;
                for(ObjectTerritory2Association eachObjectAssociation : eachTerritory.ObjectTerritory2Associations){
                    accountIdEngineerIdMap.put(eachObjectAssociation.ObjectId, userId);
                }
            }
        }

        Integer daysSinceClosed = 0;

        for(Cluster__c eachCluster : clusterListToBeProcessed){
            clusterIssueLength = eachCluster.Cluster_Issues__r.size();

            //Calculate the number of days since the last CPR was closed, if present
            if(clusterIssueLength > 0 && eachCluster.Cluster_Issues__r[0].Status__c == 'Closed'){
                //daysSinceClosed = System.today().daysBetween(Date.valueOf(eachCluster.Cluster_Issues__r[0].CPR_Close_Date__c));
                daysSinceClosed = Date.valueOf(eachCluster.Cluster_Issues__r[0].CPR_Close_Date__c).daysBetween(System.today());
            }

            //Create CPRs only if there is no existing open CPR or the last CPR was closed more than 90 days ago
            if(clusterIssueLength == 0 || daysSinceClosed >= 90) {
                clusterIssueObject = new Cluster_Issue__c();
                clusterIssueObject.Cluster__c = eachCluster.Id;
                clusterIssueObject.Account__c = eachCluster.Account__c;
                clusterIssueObject.Account_Owner__c = eachCluster.Account__r.OwnerId;

                //Set the priority based on the number of days left for the cluster capacity to reach 100%
                if(eachCluster.Capacity_Days_Until_100__c > onsetP2 && eachCluster.Capacity_Days_Until_100__c <= onsetP3) {
                    clusterIssueObject.Priority__c = 'P3';
                }
                else if(eachCluster.Capacity_Days_Until_100__c > onsetP1 && eachCluster.Capacity_Days_Until_100__c <= onsetP2) {
                    clusterIssueObject.Priority__c = 'P2';
                }
                else if(eachCluster.Capacity_Days_Until_100__c <= onsetP1) {
                    clusterIssueObject.Priority__c = 'P1';
                }

                clusterIssueObject.Owner__c = accountIdEngineerIdMap.containsKey(eachCluster.Account__c) ?
                                            accountIdEngineerIdMap.get(eachCluster.Account__c) :
                                            eachCluster.Account__r.OwnerId;

                clusterIssueListToInsert.add(clusterIssueObject);
            }

            daysSinceClosed = 0;
        }

        Database.SaveResult[] saveResults = Database.insert(clusterIssueListToInsert, false);
        List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();

        for(Database.SaveResult eachSaveResult : saveResults) {
            for(Database.Error eachError : eachSaveResult.getErrors()) {
                errorLogList.add(LogError.CreateDMLErrorLog('CreateClusterIssueBatch', null, eachError.getMessage(), 'Cluster Issue error'));
            }
        }

        Database.SaveResult[] errorLogSaveResults = Database.insert(errorLogList, false);
    }

    global void finish(Database.BatchableContext context){
        if(!Test.isRunningTest()) {
            System.scheduleBatch(new CreateClusterIssueBatch(), 'Customer Proactive Response Creation - Class : CreateClusterIssueBatch', 15, 200);
        }
    }
}