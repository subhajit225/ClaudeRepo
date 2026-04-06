public class HoldCodeTrackingHelper{
    public static void manageTrackingRecords(Map<String, List<String>> mapRecordswithNewHoldCodes, Map<String, List<String>> mapRecordswithOldHoldCodes, String recordType) {
        List<Hold_Off_Tracking__c> createNewTrackingRecords = new List<Hold_Off_Tracking__c>();
        List<Hold_Off_Tracking__c> updateExistingTrackingRecords = new List<Hold_Off_Tracking__c>();
        Map<String, List<String>> mapParentwithAllTrackingRecords = new Map<String, List<String>>();
        Map<String, String> mapParentwithUniqueTrackinngId = new Map<String, String>();
        Map<String, String> mapOpptywithOrder = new Map<String, String>();
        //Map<String, String> mapOrderwithOpptyID = new Map<String, String>();
        Map<String, Hold_Off_Tracking__c> mapIdwithTrackingRecord = new Map<String, Hold_Off_Tracking__c>();
        if(recordType =='Opportunity'){
            if(!mapRecordswithNewHoldCodes.isEmpty() || !mapRecordswithOldHoldCodes.isEmpty()){
                for(Order order : [select Id, OpportunityId from Order where (OpportunityId IN : mapRecordswithNewHoldCodes.keySet() OR OpportunityId IN: mapRecordswithOldHoldCodes.keySet())]){
                    mapOpptywithOrder.put(order.OpportunityId, order.Id);
                    //mapOrderwithOpptyID.put(order.Id, Order.OpportunityId);
                }
            }
        }
        List<String> holdCodesList;
        if(recordType =='Opportunity') {
            
            for(Opportunity oppRecord : [select id, Hold_Code__c, (Select id, Hold_Code__c  , Is_Released__c, Release_Date_Time__c, Related_Opportunity__c,Related_Order__c from Hold_Off_Tracking__r where Is_Released__c = false) from Opportunity where (Id IN : mapRecordswithNewHoldCodes.keySet() OR Id IN: mapRecordswithOldHoldCodes.keySet())]) {
                
                holdCodesList = new List<String>();
                for(Hold_Off_Tracking__c holdTrackingRecord : oppRecord.Hold_Off_Tracking__r){
                    holdCodesList.add(holdTrackingRecord.Hold_Code__c);
                    mapIdwithTrackingRecord.put(holdTrackingRecord.Id, holdTrackingRecord);
                    mapParentwithUniqueTrackinngId.put(holdTrackingRecord.Related_Opportunity__c+holdTrackingRecord.Hold_Code__c, holdTrackingRecord.Id);
                }
                mapParentwithAllTrackingRecords.put(oppRecord.Id , holdCodesList);
            }
        }
        
        // System.debug('mapParentwithAllTrackingRecords==== '+mapParentwithAllTrackingRecords);
        // System.debug('mapParentwithUniqueTrackinngId==== '+mapParentwithUniqueTrackinngId);
        for(String recordId : mapRecordswithNewHoldCodes.KeySet()) {
            for(String holdcode : mapRecordswithNewHoldCodes.get(recordId)) {
                System.debug('holdCode==== '+holdcode);
                if(!mapParentwithAllTrackingRecords.isEmpty() && !mapParentwithAllTrackingRecords.get(recordId).contains(holdcode)) {
                    if(recordType =='Opportunity')
                        createNewTrackingRecords.add(createTrackingRecord(recordId, NULL,  holdcode, mapOpptywithOrder, recordType));
                }
            }
            System.debug('createNewTrackingRecords==== '+createNewTrackingRecords);
        }

        for(String recordId : mapRecordswithOldHoldCodes.KeySet()) {
            // System.debug('mapRecordswithNewHoldCodes==== '+mapRecordswithNewHoldCodes);
            // System.debug('mapRecordswithNewHoldCodes.isEmpty==== '+mapRecordswithNewHoldCodes.isEmpty());
            if(!mapRecordswithNewHoldCodes.isEmpty())  {
                for(String diffString : findDifference(mapRecordswithNewHoldCodes.get(recordId), mapRecordswithOldHoldCodes.get(recordId))){
                    system.debug('diffset--'+diffString);
                    if(mapParentwithUniqueTrackinngId.containsKey(recordId+diffString) && !mapRecordswithNewHoldCodes.get(recordId).contains(diffString)){
                        updateExistingTrackingRecords.add(mapIdwithTrackingRecord.get(mapParentwithUniqueTrackinngId.get(recordId+diffString)));
                    }
                }
            }else{
                for(String diffString : mapRecordswithOldHoldCodes.get(recordId)){
                    if(mapParentwithUniqueTrackinngId.containsKey(recordId+diffString)){
                        updateExistingTrackingRecords.add(mapIdwithTrackingRecord.get(mapParentwithUniqueTrackinngId.get(recordId+diffString)));
                    }
                }
            }
        }
        system.debug('updateExistingTrackingRecords==='+updateExistingTrackingRecords);
        releaseTrackingRecord(updateExistingTrackingRecords);
        system.debug('updateExistingTrackingRecords after==='+updateExistingTrackingRecords);

        if(!createNewTrackingRecords.isEmpty()){
            database.insert(createNewTrackingRecords,false);
        }

        if(!updateExistingTrackingRecords.isEmpty()){
            database.update(updateExistingTrackingRecords,false);
        }
        
    }

    public static Hold_Off_Tracking__c createTrackingRecord(String parentId, String opptyId,  String holdCode, Map<String, String> mapOpptywithOrder, String recordType) {
        Hold_Off_Tracking__c newTrackingRecord = new Hold_Off_Tracking__c ();
        newTrackingRecord.Hold_Off_Time_Stamp__c = System.Now();
        newTrackingRecord.Hold_Code__c = holdCode;
        system.debug('parentId=='+parentId);
        system.debug('opptyId=='+opptyId);
        if(recordType == 'Opportunity'){
            newTrackingRecord.Related_Opportunity__c = parentId;
            if(mapOpptywithOrder.containsKey(parentId) && mapOpptywithOrder.get(parentId) != NULL)
                newTrackingRecord.Related_Order__c = mapOpptywithOrder.get(parentId);
        }
        system.debug('newTrackingRecord=='+newTrackingRecord);
        return newTrackingRecord;
    }

    public static void releaseTrackingRecord(List<Hold_Off_Tracking__c> updateExistingTrackingRecords) {
        for(Hold_Off_Tracking__c holdoff : updateExistingTrackingRecords){
            holdoff.Is_Released__c = true;
            holdoff.Release_Date_Time__c = system.Now();
        }
    }

    public static Set<String> findDifference(List<String> newList, List<String> oldList){
        Set<String> differences = new Set<String>();
        differences.addAll(newList);
        for(String item : oldList){ 
            //This assumes oldlist doesn't not contain dupes, if it might then first convert it to a set
            //if add returns false it means the set did NOT change, which means is already contains the item
            //if the item was already there then remove it, it's not different..
            if( !differences.add(item) ) {
                differences.remove(item); 
            }
        }
        return differences;
    }
}