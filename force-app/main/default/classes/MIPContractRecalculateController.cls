public class MIPContractRecalculateController {
    @AuraEnabled
    public static void initiateMIPSyncBatch(Id recordId){
        system.debug('recordId-4>'+recordId);
        Database.executeBatch(new MIPSyncBatch(recordId), 1);
    }
}