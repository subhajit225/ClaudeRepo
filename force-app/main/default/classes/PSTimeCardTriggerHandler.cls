/**
* @Author      : Sai Kishore
*/
public class PSTimeCardTriggerHandler extends TriggerManager.GenericTriggerHandler{
    PSTimeCardTriggerHelper helper;
    
    public List<PS_Time_Card__c> newList = (List<PS_Time_Card__c>)Trigger.new;
    public Map<Id, PS_Time_Card__c> oldMap = (Map<Id, PS_Time_Card__c>)Trigger.oldMap;
    
    public PSTimeCardTriggerHandler() {
        helper = new PSTimeCardTriggerHelper();
    }
    
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        helper.BeforeUpdateHelper(newList, oldMap);
    }
}