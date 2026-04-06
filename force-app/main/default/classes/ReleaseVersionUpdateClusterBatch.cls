/**
 * @description :
 * @Author      : Vijay Kumar K R
 * @CreatedDate : Jan 8, 2025 
 * @TstClass    : ReleaseVersionTriggerHandlerTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-3039        Vijay Kumar K R          Jan 8, 2025      Batch to update Cluster records from ReleaseVersionTriggerHandler
 * -------------------------------------------------------------------------
 */
public with sharing class ReleaseVersionUpdateClusterBatch implements Database.Batchable<SObject> {
    
    private Map<String, Date> eodByVersionMap;
    
    /**
     * @description 
     * @param eodByVersionMap
     */
    public ReleaseVersionUpdateClusterBatch(Map<String, Date> eodByVersionMap) {
        this.eodByVersionMap = eodByVersionMap;
    }
    
    /**
     * @description 
     * @param BC
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, software_version__c, Release_Version_End_Of_Support_Date__c
                                            FROM Cluster__c
                                            WHERE software_version__c IN: eodByVersionMap.keySet()]);
    }
    
    /**
     * @description 
     * @param BC
     * @param scope
     */
    public void execute(Database.BatchableContext BC, List<Cluster__c> scope) {
        Map<Id, Cluster__c> updateClusterMap = new Map<Id, Cluster__c>();
        for (Cluster__c objCluster : scope) {
            if(objCluster.software_version__c != null
                && eodByVersionMap.containsKey(objCluster.software_version__c)){
                    // get EOD date val
                    Date newEod = eodByVersionMap.get(objCluster.software_version__c);
                    // Only update if there is a change in Cluster Release_Version_End_Of_Support_Date__c val
                    if (objCluster.Release_Version_End_Of_Support_Date__c != newEod) {
                            objCluster.Release_Version_End_Of_Support_Date__c = newEod;
                            updateClusterMap.put(objCluster.Id, objCluster);
                    }
            }else{
                objCluster.Release_Version_End_Of_Support_Date__c = null;
            }
        }
        
        try {
            if(!updateClusterMap.isEmpty()){
                UPDATE updateClusterMap.values();
            }
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR,'DML Exception: ' + e.getMessage());
        }
    }
    
    /**
     * @description 
     * @param BC
     */
    public void finish(Database.BatchableContext BC) {
        System.debug(LoggingLevel.WARN, 'finish block.'); 
    }
}