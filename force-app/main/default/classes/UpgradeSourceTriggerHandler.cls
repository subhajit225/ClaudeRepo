public class UpgradeSourceTriggerHandler implements ITrigger{

    public void bulkAfter(){
        if (Trigger.isUpdate){
            UpgradeSourceHelper.AfterUpgradeSourceUpdate((Map<ID, Custom_Upgrade_Source__c>)Trigger.oldMap, (Map<ID, Custom_Upgrade_Source__c>)Trigger.newMap);
        }
        if (Trigger.isinsert){
             UpgradeSourceHelper.AfterUpgradeSourceinsert((Map<ID, Custom_Upgrade_Source__c>)Trigger.newMap);
        }
        if (Trigger.isDelete){
             UpgradeSourceHelper.AfterUpgradeSourceDelete((Map<ID, Custom_Upgrade_Source__c>)Trigger.oldMap);
        }
    }
    
    public void bulkbefore(){}
    public void beforeInsert(SObject so){}
    public void beforeUpdate(SObject oldSo, SObject so){}
    public void beforeDelete(SObject so){}
    public void afterInsert(SObject so){}
    public void afterUpdate(SObject oldSo, SObject so){}
    public void afterDelete(SObject so){}
    public void andFinally(){}

}