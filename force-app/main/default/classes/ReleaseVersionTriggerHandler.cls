/**
 * @description :
 * @Author      : Vijay Kumar K R
 * @CreatedDate : Jan 8, 2025 
 * @TstClass    : ReleaseVersionTriggerHandlerTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-3039        Vijay Kumar K R          Jan 8, 2025      CS21-2619: Change in EOD on release version should update CDM Software version on Case
 * -------------------------------------------------------------------------
 */
public without sharing class ReleaseVersionTriggerHandler extends TriggerHandler {

    public override void afterUpdate() {

        Set<Id> rvIdSet = new Set<Id>();
        for (Release_Version__c objRv : (List<Release_Version__c>) Trigger.new) {
            // only when End_Of_Support_Date__c is changed
            if (isChanged('End_Of_Support_Date__c', objRv)) {  
                rvIdSet.add(objRv.Id);
            }
        }
        
        Map<String, Date> eodByVersionMap = new Map<String, Date>();
        if(!rvIdSet.isEmpty() && Schema.sObjectType.Releases__c.isAccessible()){
            for(Releases__c objRl : [SELECT Id, Version__c, Release_Version__r.End_Of_Support_Date__c 
                                    FROM Releases__c
                                    WHERE Release_Version__c IN: rvIdSet ]){
                if(objRl.Version__c != null){
                    eodByVersionMap.put(objRl.Version__c, objRl.Release_Version__r.End_Of_Support_Date__c);  
                }                          
            }
        }
        
        if(!eodByVersionMap.isEmpty()){
            ReleaseVersionUpdateClusterBatch batch = new ReleaseVersionUpdateClusterBatch(eodByVersionMap);
            Database.executeBatch(batch, 2000);  
        }
    }
    
}