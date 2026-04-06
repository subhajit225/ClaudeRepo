/**
 * @description : Handler class for Partner_Registration_Request__c object
 */
public class PC_PartnerRegistrationRequestHandler extends TriggerManager.GenericTriggerHandler{
    PC_PartnerRegistrationRequestHelper helper;
 
    private List<Partner_Registration_Request__c> newList = (List<Partner_Registration_Request__c>)Trigger.new;
    private List<Partner_Registration_Request__c> oldList = (List<Partner_Registration_Request__c>)Trigger.old;
    private Map<Id, Partner_Registration_Request__c> newMap = (Map<Id, Partner_Registration_Request__c>)Trigger.newMap;
    private Map<Id, Partner_Registration_Request__c> oldMap = (Map<Id, Partner_Registration_Request__c>)Trigger.oldMap;
	
    /**
     * @description : Contructor
     * @return : none
     */
    public PC_PartnerRegistrationRequestHandler() {
        helper = new PC_PartnerRegistrationRequestHelper();
    }
	
    /**
     * @description : Method to fire on after insert event
     * @return : void
     */
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap){
        helper.processAutoApprovedRequests(newList);
    }
	
    /**
     * @description : Method to fire on before update event
     * @return : void
     */
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        helper.updateRelatedContactsByEmail(newList, oldMap);
        helper.checkPartnerAccount(newList, oldMap);
    }
	
    /**
     * @description : Method to fire on after update event
     * @return : void
     */
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        helper.checkAccountType(newList, oldMap);
    }
}