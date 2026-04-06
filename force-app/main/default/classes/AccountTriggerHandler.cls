public without sharing class AccountTriggerHandler implements ITrigger {
    Map<String, List<PatchManager__c>> patchMap;
    
    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore(){
        if(!Trigger.isDelete){
            patchMap=PatchManager.getPatchMap(Trigger.new, PatchManager.ACCOUNT);
        }
    }

    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkAfter(){}

    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public void beforeInsert(SObject so){
        Account lObject = (Account)so;
        if(PatchManager.ROUTE_ON_INSERT_ACCOUNT){
       		PatchManager.assignAccount(patchMap, lObject);
        }     
        
    }

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(SObject oldSo, SObject so){
        Account vAccount = (Account)so;
        if(vAccount.rerun_PatchManager__c==true){
            PatchManager.assignAccount(patchMap, vAccount);
            vAccount.rerun_PatchManager__c=false;
        }
        
    }

    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so){}

    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    public void afterInsert(SObject so){}

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(SObject oldSo, SObject so){}

    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    public void afterDelete(SObject so){}

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally(){}
    
}