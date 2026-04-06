//18-Oct-2024 - Changes from release team to rollback US-0005105
public class EventTriggerHandler extends TriggerManager.GenericTriggerHandler{
    EventTriggerHelper helper;

    public List<Event> newList = (List<Event>)Trigger.new;
    public List<Event> oldList = (List<Event>)Trigger.old;
    public Map<Id, Event> newMap = (Map<Id, Event>)Trigger.newMap;
    public Map<Id, Event> oldMap = (Map<Id, Event>)Trigger.oldMap;

    public EventTriggerHandler() {
        helper = new EventTriggerHelper();
    }

    public override void onBeforeInsert(List<sObject> newRecords){
        helper.setDefaultEventType(newList);
        helper.copyActivityTypeToType(newList);
        //helper.populateETMFields(newList); 
        helper.updateEventFromLeadContactBeforeInsert(newList);
        helper.checkNBM(newList);
        helper.updateCreatedByManager(newList);
        helper.setMeetingTypeForISLBookedMeetings(newList); 
    }

    public override void onAfterInsert(Map<ID, sObject> newRecordsMap){
        helper.updateLeadAndContactsAfterInsert(newList);
        helper.removeChildEvent(newList);
    }

    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        helper.setMeetingStatus(newList, oldMap);
        helper.updateCompletionAttributes(newList, oldMap);  
        //helper.updateInsideSalesPoints(newList, oldMap);  
        helper.stampOpportunityDate(newList, oldMap);   
        helper.setMeetingTypeForISLCompletedMeetings(newList, oldMap); 
        helper.updateOwnerEmail(newList, oldMap);
    }

    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        helper.updateLeadAndContactsAfterUpdate(newList, oldMap);
    }

    public override void onBeforeDelete(Map<ID, sObject> oldRecordsMap){
        helper.removeEventInfo(oldList);
    }
}