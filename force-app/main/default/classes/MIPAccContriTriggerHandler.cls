public without sharing class MIPAccContriTriggerHandler extends TriggerManager.GenericTriggerHandler{
    MIPAccContriTriggerHelper mipAccContriHelper;

    private List<MIP_Account_Contribution__c > newList = (List<MIP_Account_Contribution__c >)Trigger.new;
    private List<MIP_Account_Contribution__c > oldList = (List<MIP_Account_Contribution__c >)Trigger.old;
    private Map<Id, MIP_Account_Contribution__c > newMap = (Map<Id, MIP_Account_Contribution__c >)Trigger.newMap;
    private Map<Id, MIP_Account_Contribution__c > oldMap = (Map<Id, MIP_Account_Contribution__c >)Trigger.oldMap;

    public MIPAccContriTriggerHandler() {
        mipAccContriHelper = new MIPAccContriTriggerHelper();
    }

    public override void onAfterDelete(Map<ID, sObject> oldRecordsMap){
        mipAccContriHelper.participatingAccOnContract(oldMap);
    }
    
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap){
        mipAccContriHelper.participatingAccOnContract(newMap);
    }
    
}