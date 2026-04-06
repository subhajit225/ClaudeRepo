trigger EntitlementUpdateEvent on EntitlementUpdate__e (after insert) {
    Map<Id,Entitlement> mapOfEntToUpdate = new Map<Id,Entitlement>();
    Set<Id> EntId = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();
    for(EntitlementUpdate__e event : Trigger.new){
        system.debug('event is ' + event);
        String recordId = event.RecordId__c; 
        if(String.isNotBlank(event.RecordId__c) && recordId.startsWith('550') &&  String.isNotBlank(event.RSC_Status__c)){
            mapOfEntToUpdate.put(event.RecordId__c,new Entitlement(id = event.RecordId__c, RSC_Status__c = event.RSC_Status__c));
            if(event.RSC_Status__c == 'Success')
            EntId.add(event.RecordId__c);
        }
        else if(String.isNotBlank(recordId) && recordId.startsWith('001')){
        	accountIds.add(recordId);    
        }
    }
    system.debug('EntId ' + EntId);
    if(!EntId.isEmpty()){
        for(RSC_Process__c rsc : [Select Id,Entitlement__c,Entitlement__r.enddate from RSC_Process__c where Free_trail__c = 'Free Trial' AND Entitlement__c IN : EntId]){
            if(mapOfEntToUpdate.containskey(rsc.Entitlement__c)){
                mapOfEntToUpdate.get(rsc.Entitlement__c).enddate = system.today().addDays(45);
            }else{
                mapOfEntToUpdate.put(rsc.Entitlement__c,new Entitlement(id = rsc.Entitlement__c, enddate = system.today().addDays(45)));
            }
        }
    }
    system.debug('mapOfEntToUpdate ' + mapOfEntToUpdate);
    updateEntRecs(mapOfEntToUpdate.values());
    System.debug('accountIds::'+accountIds);
    if(!accountIds.isEmpty()){
        for(Id accId : accountIds){
        	LCC_ButtonsController.createFreeEntitlementRecord(accId);    
        }    
    }
    public void updateEntRecs(List<Entitlement> lstOfEntToUpdate){
        List<Custom_Error_Log__c> lstError = new List<Custom_Error_Log__c>();
        if(!lstOfEntToUpdate.isEmpty()){
            for (Database.SaveResult sr : database.Update(lstOfEntToUpdate, false)){
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        lstError.add(LogError.CreateDMLErrorLog('EntitlementUpdateEvent', sr.getId(), err.getMessage(),null));
                    }
                }
            }
            
        }
        if(!lstError.isEmpty()){
            insert lstError;
        }
    }
    
}