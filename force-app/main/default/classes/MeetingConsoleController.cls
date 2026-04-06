public class MeetingConsoleController {
    @testvisible
    private static Boolean isEventUpdateFailedInTest = Test.isRunningTest();
    public static final String DASHBOARD = 'Disposition';
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Console_Column_Picker__mdt> getCustomMetadataRecords() {
        return EventConsoleService.getColumnPreferencesForTheDashborad(DASHBOARD);
    }
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Console_Filter_Picker__mdt> getFilterCustomMetadataRecords() {
        return EventConsoleService.getFilterPreferencesForTheDashborad(DASHBOARD);
    }

    @AuraEnabled
    public static List<EventConsoleService.EventDataWrapper> getEventRecords(String filterMapValues, String eventData){
        System.debug('eventData--'+eventData);
        Map<String, String> eventsMap = new Map<String, String>();
        if(eventData != ''){
            for(Object obj : (List<Object>)JSON.deserializeUntyped(eventData)){
                Map<String, Object> data = (Map<String, Object>)obj;
                System.debug('valuesMap--'+data);
                if(data.keySet().size() > 2 && !eventsMap.containsKey(String.valueOf(data.get('meetingLink')))){
                    eventsMap.put(String.valueOf(data.get('meetingLink')),String.valueOf(data.get('outcome')));
                }else{
                    eventsMap.put(String.valueOf(data.get('failedRecordLink')),String.valueOf(data.get('failedEventReason')));
                }
                
            }
            System.debug('eventsMap--'+eventsMap);
        }
        Map<String, String> valuesMap = new Map<String, String>();
        for(Object obj : (List<Object>)JSON.deserializeUntyped(filterMapValues)){
            Map<String, Object> data = (Map<String, Object>)obj;
            valuesMap.put(String.valueOf(data.get('key')),String.valueOf(data.get('value')));
        }
       
        List<Event> evntLists = new List<Event>();
            String baseQuery = 'SELECT Id, WhoId, ActivityDate, ActivityDateTime, Subject, CreatedDate, CreatedBy.Name, Activity_Type__C, Completed_Date__c,'+
                'Post_Meeting_Status__c FROM Event '+
                'WHERE WhoId != null';
            String currentUserId = '\'' + String.escapeSingleQuotes(UserInfo.getUserId()) + '\'';
            baseQuery += ' AND OwnerId = '+ currentUserId;
            Date todaysDate = Date.today();
            if(valuesMap.get('Week_of_Fiscal_Quarter') == ''){
                //Meeting Fiscal Quarter
                if(valuesMap.get('Meeting_FQ') == 'Current Quarter'){
                    baseQuery += ' AND ActivityDateTime = THIS_FISCAL_QUARTER';
                }else if(valuesMap.get('Meeting_FQ') == 'Previous Quarter'){
                    baseQuery += ' AND ActivityDateTime = LAST_FISCAL_QUARTER';
                }else if(valuesMap.get('Meeting_FQ') == 'Next Quarter'){
                    baseQuery += ' AND ActivityDateTime = NEXT_FISCAL_QUARTER';
                }
            }else{
                //Week of Fiscal Quarter
                Map<String,List<Date>> weekNumber = getWeeksOfFQ(valuesMap.get('Meeting_FQ'));
                String weekOfFiscalQuarter = valuesMap.get('Week_of_Fiscal_Quarter');
                Date firstDate;
                Date lastDate;
                if(weekOfFiscalQuarter == 'All Weeks'){
                    List<List<Date>> allWeeks = weekNumber.values();
                    firstDate = allWeeks[0][0];
                    lastDate = allWeeks[allWeeks.size()-1][1];
                } else {
                    firstDate = weekNumber.get(weekOfFiscalQuarter)[0];
                    lastDate = weekNumber.get(weekOfFiscalQuarter)[1];
                }
                baseQuery += ' AND ActivityDate >=: firstDate AND ActivityDate <=: lastDate';
            }
            
           // Meeting Timing
           if(valuesMap.get('Meeting_Timing') == 'Past Meeting'){
            baseQuery += ' AND ActivityDate <: todaysDate';
            }else if(valuesMap.get('Meeting_Timing') == 'Upcoming Meeting'){
                baseQuery += ' AND ActivityDate >=: todaysDate';
            }
           //Meeting outcome
           if(valuesMap.get('Disposition_Status') == 'Opportunity Sourced'){
               baseQuery += ' AND Post_Meeting_Status__c =\'Opportunity Sourced\'';
           }else if(valuesMap.get('Disposition_Status') == 'No Opportunity Sourced'){
              baseQuery += ' AND Post_Meeting_Status__c =\'No Opportunity Sourced\'';
            }else if(valuesMap.get('Disposition_Status') == 'Meeting Cancelled'){
                baseQuery += ' AND Post_Meeting_Status__c =\'Meeting Cancelled\'';
            }else if(valuesMap.get('Disposition_Status') == null){
                baseQuery += ' AND Post_Meeting_Status__c = \'\''; 
            }
           
            //meeting type
            String meetingType = valuesMap.get('Meeting_Type');
            if(String.isNotBlank(meetingType)){
                baseQuery += ' AND Type = \''+ meetingType + '\'';
            }

            baseQuery += ' ORDER BY CreatedDate ASC NULLS LAST';
            baseQuery += ' LIMIT 2500';
            system.debug('baseQuery--'+baseQuery);
            evntLists = Database.query(baseQuery);
            
            Map<Id,Id> eveConMap = new Map<Id,Id>();
            Map<Id,Id> eveLdMap = new Map<Id,Id>();
            for(Event evt : evntLists){
                if(evt.WhoId.getSObjectType() == Contact.sobjectType){
                    eveConMap.put(evt.Id,evt.WhoId);
                }
                if(evt.WhoId.getSObjectType() == Lead.sobjectType){
                    eveLdMap.put(evt.Id,evt.WhoId);
                }
            }
            List<Contact> conList = new List<Contact>();
            List<Lead> ldList = new List<Lead>();
            List<Id> ldEventIds = eveLdMap.values();
            List<Id> conEventIds = eveConMap.values();
            String conBaseQuery = 'SELECT Id,Name,Title,Account.Name,AccountId,L2A_Parent_Account_Tier__c from Contact where Id IN : conEventIds';
            String leadBaseQuery = 'SELECT Id,Name,Title,PartnerAccount.Name,PartnerAccountId,Winning_L2A_Account__c,Winning_L2A_Account__r.Name,L2A_Parent_Account_Tier__c from Lead where Id IN : ldEventIds';
           
            //Parent Account Tier
            if(valuesMap.get('Parent_Account_Tier') != ''){
                String Tier = valuesMap.get('Parent_Account_Tier');
                conBaseQuery += ' AND L2A_Parent_Account_Tier__c =: Tier';
                leadBaseQuery += ' AND L2A_Parent_Account_Tier__c =: Tier';
            }
           
            conList = Database.query(conBaseQuery);
            ldList = Database.query(leadBaseQuery);
            
            Map<Id, Contact> contactMap = new Map<Id, Contact>(conList);
            Map<Id, Lead> leadMap = new Map<Id, Lead>(ldList);
           
            List<Event> processedEventList = new List<Event>();
            for(Event evt : evntLists){
                if(contactMap.containsKey(evt.WhoId) || leadMap.containsKey(evt.WhoId)){
                    processedEventList.add(evt);
                }
            }
            List<EventConsoleService.EventDataWrapper> wrapperClsObj = new List<EventConsoleService.EventDataWrapper>();
            for(Event evt : processedEventList){
                String setDate = evt.CreatedDate.format();
                
                EventConsoleService.EventDataWrapper wrapObj = new EventConsoleService.EventDataWrapper();
                wrapObj.subject = evt.Subject;
                
                wrapObj.createdDate = evt.CreatedDate;
                wrapObj.createdDateString = setDate;

                wrapObj.meetingLink = '/'+evt.Id;
                wrapObj.leadContactLink = '/'+evt.WhoId;

                wrapObj.activityDate = evt.ActivityDateTime;
                wrapObj.activityDateString = evt.ActivityDateTime.format();

                wrapObj.activityDateClr = evt.ActivityDate;
                wrapObj.fullName = evt.CreatedBy.Name;
                wrapObj.activityType = evt.Activity_Type__C;

                if(evt.Completed_Date__c != null){
                    wrapObj.completedDateString = evt.Completed_Date__c.format();
                    wrapObj.completedDate = evt.Completed_Date__c;
                }
                
                if(eventsMap.containsKey('/'+evt.Id)){
                    String dispositionOutCome = eventsMap.get('/'+evt.Id);
                    if(evt.Post_Meeting_Status__c == null){
                        wrapObj.outcome = dispositionOutCome;
                    }else{
                        if(dispositionOutCome == 'Opportunity Sourced (Already Dispositioned)' || dispositionOutCome == 'Meeting Cancelled (Already Dispositioned)' || dispositionOutCome == 'No Opportunity Sourced (Already Dispositioned)'){
                            wrapObj.outcome = dispositionOutCome;
                        }else if(dispositionOutCome == 'Already Dispositioned'){
                                wrapObj.outcome =  evt.Post_Meeting_Status__c + ' (' + dispositionOutCome + ')';
                            }else{
                                wrapObj.outcome =  evt.Post_Meeting_Status__c;
                            }     
                        }
                }else{
                    wrapObj.outcome = evt.Post_Meeting_Status__c;
                }
                
                if(evt.WhoId.getSObjectType() == Contact.sobjectType){
                    wrapObj.accountName = contactMap.get(eveConMap.get(evt.Id)).Account.Name;
                    wrapObj.leadContactName =  contactMap.get(eveConMap.get(evt.Id)).Name;
                    wrapObj.accountLink = '/'+contactMap.get(eveConMap.get(evt.Id)).AccountId;
                    wrapObj.title = contactMap.get(eveConMap.get(evt.Id)).Title;
                }
                else if(evt.WhoId.getSObjectType() == Lead.sobjectType){
                    if(leadMap.get(eveLdMap.get(evt.Id)).Winning_L2A_Account__c != null){
                        wrapObj.accountName = leadMap.get(eveLdMap.get(evt.Id)).Winning_L2A_Account__r.Name;
                        wrapObj.accountLink = '/'+leadMap.get(eveLdMap.get(evt.Id)).Winning_L2A_Account__c;
                    }else{
                        wrapObj.accountName = leadMap.get(eveLdMap.get(evt.Id)).Name;
                        wrapObj.accountLink = '/'+leadMap.get(eveLdMap.get(evt.Id)).Id;
                    } 
                    wrapObj.leadContactName = leadMap.get(eveLdMap.get(evt.Id)).Name;
                    wrapObj.title = leadMap.get(eveLdMap.get(evt.Id)).Title;
                }
                
                wrapperClsObj.add(wrapObj);
            }
        return wrapperClsObj;
    }

    public static Map<String,List<Date>> getWeeksOfFQ(String quarter){
        Map<String,List<Date>> weeksNoToFirstDay = new Map<String,List<Date>>();
        Date today = Date.today();
        Integer month = quarter == 'Next Quarter'?today.month()+3: quarter == 'Previous Quarter'?today.month() - 3: today.month();
        
        Integer firstMonthOfTheQuarter = month >= 2 && month <= 4 ? 2 : (month >= 5 && month <= 7 ? 5 : (month >= 8 && month <= 10 ? 8 : 11));
        Date firstDayOfQuarter =  Date.newInstance(month==1?today.year()-1:today.year(), firstMonthOfTheQuarter, 1);
        Date lastDayofQuarter = firstDayOfQuarter.addMonths(3).addDays(-1);

        Date firstDayOfWeek = firstDayOfQuarter;
        for(Integer i=1; i<14; i++){
            Date lastDayfWeek = firstDayOfWeek.addDays(6)<lastDayofQuarter ? firstDayOfWeek.addDays(6):lastDayofQuarter;
            lastDayfWeek = ((lastDayfWeek.daysBetween(lastDayofQuarter) == 9 && i == 12) || (lastDayfWeek.daysBetween(lastDayofQuarter) == 1 && i == 13)) ? lastDayfWeek.addDays(1) : lastDayfWeek;
            weeksNoToFirstDay.put('Week '+i, new List<Date>{firstDayOfWeek, lastDayfWeek});
            firstDayOfWeek = firstDayOfWeek+7;
        }
        return weeksNoToFirstDay;
    }

    @AuraEnabled
    public static List<EventConsoleService.EventDataWrapper> getSelectedRecords(List<String> selectedEventIds, String outcome, String reason, String othrReason){
        System.debug('selectedEventIds--'+selectedEventIds);
        List<EventConsoleService.EventDataWrapper> wrapperObj = new List<EventConsoleService.EventDataWrapper>();
        List<Event> eventList = new List<Event>();
        List<Event> alredayDisposEventList = new List<Event>();
        for(Event evt : [SELECT Id, Post_Meeting_Status__c, Disqualified_Reason__c,Subject, Cancellation_reason__c, Other__c FROM Event WHERE Id IN: selectedEventIds]){
            if(evt.Post_Meeting_Status__c == null){
                evt.Post_Meeting_Status__c = outcome;
                if(outcome == 'No Opportunity Sourced'){
                    evt.Disqualified_Reason__c = reason;
                    if(reason == 'Other'){
                        evt.Other__c = othrReason;
                    }
                }else if(outcome == 'Meeting Cancelled'){
                    evt.Cancellation_reason__c = reason;
                }
                eventList.add(evt);
            }else{
                alredayDisposEventList.add(evt);
            }
        }
        if(!alredayDisposEventList.isEmpty()){
            for(Event evt : alredayDisposEventList){
                EventConsoleService.EventDataWrapper wrpInst = new EventConsoleService.EventDataWrapper();
                wrpInst.failedRecordLink = '/'+evt.Id;
                wrpInst.failedEventReason = 'Already Dispositioned';
                wrapperObj.add(wrpInst);
            }
        }
        if(!eventList.isEmpty()){
            Database.SaveResult[] updatedList = Database.update(eventList, false);
            Integer i =0;
            for(Database.SaveResult sr : updatedList){
                i++;
                if (!sr.isSuccess() || isEventUpdateFailedInTest){
                    for(Database.Error err : sr.getErrors()){
                        EventConsoleService.EventDataWrapper wrpInst = new EventConsoleService.EventDataWrapper();
                        wrpInst.failedRecordLink = '/'+eventList.get(i-1).Id;
                        wrpInst.failedEventReason = err?.getMessage()+' '+ err?.getStatusCode();
                        wrapperObj.add(wrpInst);
                    }     
                }
            }
        }
        return wrapperObj;
    }
}