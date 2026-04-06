public class MeetingCategorizationController{
    public static final String DASHBOARD = 'Categorization';
    public static final String PERMISSIONSETNAME = 'Meeting_Console';
    public static final String LOGGED_IN_USER_ID = UserInfo.getUserId();
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Console_Column_Picker__mdt> getCustomMetadataRecords() {
        return EventConsoleService.getColumnPreferencesForTheDashborad(DASHBOARD);
    }
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Console_Filter_Picker__mdt> getFilterCustomMetadataRecords() {
       return EventConsoleService.getFilterPreferencesForTheDashborad(DASHBOARD);
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getMeetingCategoryPicklistValues() {
       return EventConsoleService.getMeetingCategoryPicklistValues();
    }
    @AuraEnabled(cacheable=true)
    public static Boolean getUserAccessToThePage() {
        List<String> perSetGrpNameList = new List<String>();
        for(PermissionSetGroupComponent prmSetGrpComp : [SELECT Id, PermissionSet.Name, PermissionSetGroup.DeveloperName FROM PermissionSetGroupComponent WHERE PermissionSet.Name =: PERMISSIONSETNAME]){
            perSetGrpNameList.add(prmSetGrpComp.PermissionSetGroup.DeveloperName);
        }
       List<PermissionSetAssignment> listpermissionSet = [SELECT Id, AssigneeId, Assignee.Name, PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE AssigneeId =: LOGGED_IN_USER_ID AND (PermissionSetGroup.DeveloperName IN : perSetGrpNameList OR PermissionSet.Name =: PERMISSIONSETNAME)  LIMIT 1];
       return !listpermissionSet.isEmpty();
    }
    @AuraEnabled
    public static List<EventConsoleService.EventDataWrapper> getEventRecords(String filterMapValues, String eventData){
        try {
            Map<String, String> eventsMap = new Map<String, String>();
        if(eventData != ''){
            for(Object obj : (List<Object>)JSON.deserializeUntyped(eventData)){
                Map<String, Object> data = (Map<String, Object>)obj;
                if(data.keySet().size() > 2 && !eventsMap.containsKey(String.valueOf(data.get('meetingLink')))){
                    eventsMap.put(String.valueOf(data.get('meetingLink')),String.valueOf(data.get('outcome')));
                }else{
                    eventsMap.put(String.valueOf(data.get('failedRecordLink')),String.valueOf(data.get('failedEventReason')));
                }
                
            }
        }
            Map<String, String> valuesMap = EventConsoleService.getValuesMap(filterMapValues);
            List<Event> evntLists = EventConsoleService.getEventQuery(DASHBOARD, valuesMap);
            Map<Id,Id> eveConMap = new Map<Id,Id>();
            Map<Id,Id> eveLdMap = new Map<Id,Id>();
            List<Id> listOfEventIds = new List<Id>();
            Integer count = 0;
            for(Event evt : evntLists){
                if(evt.WhoId != null){
                    if(evt.WhoId.getSObjectType() == Contact.sobjectType){
                        eveConMap.put(evt.Id,evt.WhoId);
                    }
                    if(evt.WhoId.getSObjectType() == Lead.sobjectType){
                        eveLdMap.put(evt.Id,evt.WhoId);
                    }
                }
            }
            List<Contact> conList = new List<Contact>();
            List<Lead> ldList = new List<Lead>();
            List<Id> ldEventIds = eveLdMap.values();
            List<Id> conEventIds = eveConMap.values();
            String conBaseQuery = 'SELECT Id,Name,Title,Account.Name,AccountId,L2A_Parent_Account_Tier__c from Contact where Id IN : conEventIds';
            String leadBaseQuery = 'SELECT Id,Name,Title,PartnerAccount.Name,PartnerAccountId,Winning_L2A_Account__c,Winning_L2A_Account__r.Name,L2A_Parent_Account_Tier__c from Lead where Id IN : ldEventIds';
            /*
            if(selectedAccountId != null){
                String recId = selectedAccountId.replaceAll('"', '').trim();
                conBaseQuery += ' AND AccountId =: recId';
                leadBaseQuery += ' AND Winning_L2A_Account__c =: recId' ;
            }*/
            conList = Database.query(conBaseQuery);
            ldList = Database.query(leadBaseQuery);
            Map<Id, Contact> contactMap = new Map<Id, Contact>(conList);
            Map<Id, Lead> leadMap = new Map<Id, Lead>(ldList);
            List<Event> processedEventList = new List<Event>();
            for(Event evt : evntLists){
                if(contactMap.containsKey(evt.WhoId) || leadMap.containsKey(evt.WhoId)){
                    processedEventList.add(evt);
                    count++;
                    if(count<=200){
                        listOfEventIds.add(evt.Id);
                    }
                }
            }
            Map<Id, UserRecordAccess> mapOfEventIdWithRecordAccess = new Map<Id, UserRecordAccess>([SELECT RecordId FROM UserRecordAccess WHERE RecordId IN :listOfEventIds AND UserId =: LOGGED_IN_USER_ID AND HasEditAccess = true LIMIT 200]);
            return EventConsoleService.setEventDataInWrapper(DASHBOARD, processedEventList, contactMap, leadMap, eveConMap, eveLdMap, eventsMap, mapOfEventIdWithRecordAccess);  
        } catch (Exception e) {
            System.debug('Error: '+e.getMessage());
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    /* Method is used to prevent relatedTo feature for events associated with Leads*/
    @AuraEnabled
    public static String getWhoIdDetails(List<String> selectedEventIds) {
        try {
            String allLeadNames='';
            for(Event evt  : [SELECT Id, WhoId, Who.Name FROM Event WHERE Id IN : selectedEventIds]){
                if(evt.WhoId.getSObjectType() == Lead.sobjectType){
                    allLeadNames += evt.Who.Name + ', ';
                }
            }
            if(allLeadNames != ''){
                return allLeadNames.removeEnd(', ').trim();
            }else {
                return allLeadNames;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<EventConsoleService.EventDataWrapper> updateSelectedRecords(List<String> selectedEventIds, String varMeetingCategory){
        try {
            List<EventConsoleService.EventDataWrapper> wrapperObjList = new List<EventConsoleService.EventDataWrapper>();
            List<Event> eventList = new List<Event>();
            List<Event> alredayQuickTagged = new List<Event>();

            for(Event evt  : [SELECT Id, Meeting_Category__c FROM Event WHERE Id IN : selectedEventIds]){
                if(varMeetingCategory != 'None'){
                    evt.Meeting_Category__c = varMeetingCategory;
                }else{
                    evt.Meeting_Category__c = null;
                }
                eventList.add(evt);
            }

            if(!eventList.isEmpty()){
                wrapperObjList = updateTheMeetings(eventList);
            }

            return wrapperObjList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /* Method is used to updated relatedTo for selected events*/
    @AuraEnabled
    public static List<EventConsoleService.EventDataWrapper> updateRelatedToRecords(List<String> selectedEventIds, Id relatedToOpportunity, Boolean selectedLeaveBlank){
        try {
            List<EventConsoleService.EventDataWrapper> wrapperObjList = new List<EventConsoleService.EventDataWrapper>();
            List<Event> eventList = new List<Event>();
            for(Event evt  : [SELECT Id, WhatId FROM Event WHERE Id IN : selectedEventIds]){
                if(!selectedLeaveBlank){
                    evt.WhatId = relatedToOpportunity;
                }else{
                    evt.WhatId = null;
                }
                eventList.add(evt);
            }
            if(!eventList.isEmpty()){
                wrapperObjList = updateTheMeetings(eventList);
            }
            return wrapperObjList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /* Method is used to perform dml to update selected events*/
    public static List<EventConsoleService.EventDataWrapper> updateTheMeetings(List<Event> eventList){
        List<EventConsoleService.EventDataWrapper> wrpList = new List<EventConsoleService.EventDataWrapper>();
        if(!eventList.isEmpty()){
            Database.SaveResult[] updatedList = Database.update(eventList, false);
            Integer i =0;
            for(Database.SaveResult sr : updatedList){
                i++;
                if (!sr.isSuccess()){
                    for(Database.Error err : sr.getErrors()){
                        EventConsoleService.EventDataWrapper wrpInst = new EventConsoleService.EventDataWrapper();
                        wrpInst.failedRecordLink = '/'+eventList.get(i-1).Id;
                        wrpInst.failedEventReason = err.getMessage()+' '+ err.getStatusCode();
                        wrpList.add(wrpInst);
                    }     
                }
                //return wrpList;
            }
        }
        return wrpList;
    }

    @AuraEnabled(cacheable=true)
    public static list<sObject> fetchLookupData(string searchKey , string sObjectApiName, List<String> accountIdsList) { 
        List < sObject > returnList = new List < sObject > ();
        String sWildCardText = String.isNotBlank(searchKey) ? '%' + searchKey + '%' : '';
        // string sWildCardText = '%' + searchKey + '%';
        string sQuery;
        if(sObjectApiName == 'Account'){
            sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText AND Id IN : accountIdsList order by createdDate DESC LIMIT 5';

        }else if(sObjectApiName == 'Opportunity'){
            if(String.isNotBlank(sWildCardText)){
                sQuery = 'SELECT Id,Name FROM ' + sObjectApiName + ' WHERE Name LIKE : sWildCardText ORDER BY CreatedDate DESC LIMIT 5';
            }else{
                sQuery = 'SELECT Id,Name FROM ' + sObjectApiName + ' ORDER BY CreatedDate DESC LIMIT 5';
            }
        }
        for (sObject obj: database.query(sQuery)) {
            returnList.add(obj);
        }
        return returnList;
    }
    @AuraEnabled
    public static List<EventConsoleService.EventDataWrapper> getEditAccessForRemainingChunks(List<String> meetingIds, String eventWrapperStringified){
        try {
            List<EventConsoleService.EventDataWrapper> wrapObj = new List<EventConsoleService.EventDataWrapper>();
            if(!meetingIds.isEmpty()){            
                if(String.isNotBlank(eventWrapperStringified)){
                    wrapObj = (List<EventConsoleService.EventDataWrapper>) JSON.deserialize(eventWrapperStringified, List<EventConsoleService.EventDataWrapper>.class);
                }
                Map<Id, UserRecordAccess> mapOfEventIdWithRecordAccess = new Map<Id, UserRecordAccess>([SELECT RecordId FROM UserRecordAccess WHERE RecordId IN :meetingIds AND UserId =: LOGGED_IN_USER_ID AND HasEditAccess = true LIMIT 200]);
                if(!wrapObj.isEmpty()){
                    for(EventConsoleService.EventDataWrapper wrapInstance: wrapObj){
                        if(!mapOfEventIdWithRecordAccess.isEmpty()){
                            String eventId = wrapInstance.meetingLink.replace('/', '').trim();
                            wrapInstance.hasAccessToEditTheMeeting = mapOfEventIdWithRecordAccess.containsKey(eventId);
                        }
                    }
                }
            }
            return wrapObj;
        } catch (Exception e) {
            // System.debug('Error: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<EventConsoleService.EventDataWrapper> updateLeaderAttended(List<String> selectedEventIds, String varLeaderAttended){
        try {
            List<EventConsoleService.EventDataWrapper> wrapperObjList = new List<EventConsoleService.EventDataWrapper>();
            List<Event> eventList = new List<Event>();
            for(Event evt  : [SELECT Id, Leader_Attended__c FROM Event WHERE Id IN : selectedEventIds]){
                if(evt.Leader_Attended__c != varLeaderAttended && varLeaderAttended != 'none'){
                    evt.Leader_Attended__c = varLeaderAttended;
                }else if(varLeaderAttended == 'none'){
                    evt.Leader_Attended__c = '';
                }
                eventList.add(evt);
            }
            if(!eventList.isEmpty()){
                wrapperObjList = updateTheMeetings(eventList);
            }
            return wrapperObjList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

    }
}