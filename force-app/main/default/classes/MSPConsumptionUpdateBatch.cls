/*
    every 4h
    String CRON_EXP = '0 0 0/4 1/1 * ?';
    MSPConsumptionUpdateBatch sch = new MSPConsumptionUpdateBatch();
    System.schedule('Every 4h Batch Review MSPConsumption job', CRON_EXP, sch);
*/

global class MSPConsumptionUpdateBatch implements Database.Batchable<sObject>, Schedulable {

    String query;
    private static final String PRODUCT_SUB_TYPE_START_UP = 'Start Up';

    global MSPConsumptionUpdateBatch() {
        this.query = 'SELECT Id, '+
            'MSP_Consumption__c, (SELECT Id, Asset__r.Product2.Product_Subtype__c, Asset__r.Third_Party_MSP__c FROM Nodes__r) '+
            'FROM Cluster__c';
    }

    global void execute(SchedulableContext sc) {
        MSPConsumptionUpdateBatch b = new MSPConsumptionUpdateBatch();
        Database.executeBatch(b, 100);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Cluster__c> clusters = (List<Cluster__c>)scope;
        reviewMSPConsumption(clusters);
    }

    global void finish(Database.BatchableContext BC) {

    }

    static global void Schedulingmethod(){
        String SchdlTime = '0 0 2 ? * *';
        System.schedule('MSPConsumptionUpdateBatch',SchdlTime, new MSPConsumptionUpdateBatch());
    }


    private void reviewMSPConsumption(List<Cluster__c> clusters) {
        List<Cluster__c> toUpdate = new List<Cluster__c>();

        for(Cluster__c cluster : clusters) {
            Set<String> clusterProductSubTypes = new Set<String>();
            Boolean thirdPartyMSP = false;
            for(Node__c node : cluster.Nodes__r) {
                clusterProductSubTypes.add(node.Asset__r.Product2.Product_Subtype__c);

                if(node.Asset__r.Third_Party_MSP__c){
                    thirdPartyMSP = true;
                }
            }

            Boolean expectedMspConsumptionValue = thirdPartyMSP || clusterProductSubTypes.contains(PRODUCT_SUB_TYPE_START_UP);
            
            if(!cluster.MSP_Consumption__c && cluster.MSP_Consumption__c != expectedMspConsumptionValue){
                toUpdate.add(
                    new Cluster__c(Id = cluster.Id, MSP_Consumption__c = expectedMspConsumptionValue)
                );
            }
        }

        if(!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }

}