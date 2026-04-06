public with sharing class EventConsoleService {

    public static List<Meeting_Console_Column_Picker__mdt> getColumnPreferencesForTheDashborad(String dashboard) {
        String getColumns = '%'+dashboard+'%';
        List<Meeting_Console_Column_Picker__mdt> listcolumnPicker = [SELECT Id,MasterLabel,FieldName__c,Hyperlink__c,Order__c,Sortable__c,Type__c from Meeting_Console_Column_Picker__mdt WHERE (FieldName__c != 'actualcompletedDate' AND FieldName__c != 'actualActivityDate' AND FieldName__c != 'actualCreatedDate') AND (Tabset__c LIKE :getColumns)  ORDER BY Order__c ASC];
        return listcolumnPicker;
    }

    public static List<Meeting_Console_Filter_Picker__mdt> getFilterPreferencesForTheDashborad(String dashboard) {
        String getFilters = '%'+dashboard+'%';
        List<Meeting_Console_Filter_Picker__mdt> listFiterPicker = [SELECT Id,MasterLabel,DeveloperName,Options__c,Order__c,Help_Text__c, Tabset__c FROM Meeting_Console_Filter_Picker__mdt WHERE (Tabset__c LIKE :getFilters) ORDER BY Order__c ASC];
        return listFiterPicker;
    }
    public static List<String> getMeetingCategoryPicklistValues() {
        List<String> meetingcategoryPicklistvalues = new List<String>();
        
        List<Meeting_Console_Filter_Picker__mdt> listFiterPicker = [SELECT Id,Options__c FROM Meeting_Console_Filter_Picker__mdt WHERE DeveloperName = 'Meeting_Category' LIMIT 1];
        for(String str : listFiterPicker[0].Options__c.split(';')){
            meetingcategoryPicklistvalues.add(str);
        }
        return meetingcategoryPicklistvalues;
    }

    public static Map<String, String> getValuesMap(String filterMapValues){
        Map<String, String> valuesMap = new Map<String, String>();
        if(filterMapValues != ''){
            for(Object obj : (List<Object>)JSON.deserializeUntyped(filterMapValues)){
                Map<String, Object> data = (Map<String, Object>)obj;
                valuesMap.put(String.valueOf(data.get('key')),String.valueOf(data.get('value')));
            } 
        }
        return valuesMap;
    }

    public static List<Event> getEventQuery(String dashboard, Map<String, String> valuesMap){        
        String baseQuery  = 'SELECT Id, WhoId, ActivityDate, ActivityDateTime, Subject, CreatedDate, Leader_Attended__c,CreatedBy.Name, Activity_Type__C, Completed_Date__c,'+
                            'Post_Meeting_Status__c, OwnerId, Owner.Name, Meeting_Category__c, WhatId, What.Name FROM Event';
        String currentUserId = '\'' + String.escapeSingleQuotes(UserInfo.getUserId()) + '\'';
        //String curentUsersEmailAddress = '%' + UserInfo.getUserEmail() + '%' ;
        //String trimmedEmailAddress = '%' + UserInfo.getUserEmail().split('@rubrik')[0] + '%';
        
        if('Categorization' == dashboard){
            baseQuery += ' WHERE WhoId != null';
            baseQuery += ' AND (OwnerId = ' + currentUserId + ' OR SOPS_SelectedOwner__c ='+ currentUserId +')';
            baseQuery += ' AND (Event_Status__c = \'Not Started\' OR Event_Status__c = \'Completed\')';
            Date todaysDate = Date.today();
            if(!(valuesMap.keySet()).isEmpty()){
                if(valuesMap.get('Month_of_the_Fiscal_Quarter') != 'Entire Quarter'){
                    String fiscalYearAndQuarter = GeneralUtility.determineFinancialYearAndQuarter(System.today());
                    Integer fiscalQuarter = Integer.valueOf(fiscalYearAndQuarter.split('Q')[1]);
                    fiscalQuarter = valuesMap.get('Meeting_FQ') == 'Previous Quarter' ? (fiscalQuarter - 1 == 0 ? 4 : fiscalQuarter - 1) : valuesMap.get('Meeting_FQ') == 'Next Quarter' ? (fiscalQuarter + 1 > 4 ? 1 : fiscalQuarter + 1) : fiscalQuarter;
                    Integer filterMonthValue = Integer.valueOf(valuesMap.get('Month_of_the_Fiscal_Quarter').remove('Month').trim());
                    Integer getMonthForQuery = (fiscalQuarter * 3) - 2 + filterMonthValue > 12 ? (fiscalQuarter * 3) - 2 + filterMonthValue - 12 : (fiscalQuarter * 3) - 2 + filterMonthValue;
                    baseQuery += ' AND CALENDAR_MONTH(ActivityDateTime) =: getMonthForQuery';
                }
                if(valuesMap.get('Week_of_Fiscal_Quarter') == 'All Weeks'){
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
                    Date firstDate = weekNumber.get(valuesMap.get('Week_of_Fiscal_Quarter'))[0];
                    Date lastDate = weekNumber.get(valuesMap.get('Week_of_Fiscal_Quarter'))[1];
                    baseQuery += ' AND ActivityDate >=: firstDate AND ActivityDate <=: lastDate';
                }
                // Meeting Timing
                if(valuesMap.get('Meeting_Timing') == 'Past Meeting'){
                    baseQuery += ' AND ActivityDate <: todaysDate';
                }else if(valuesMap.get('Meeting_Timing') == 'Upcoming Meeting'){
                    baseQuery += ' AND ActivityDate >=: todaysDate';
                }
                //Meeting Category
                if(valuesMap.containsKey('Meeting_Category')){
                    String selectedCategories = valuesMap.get('Meeting_Category');
                    String selectedCategoriesForQuery;
                    String noneMeetingCategory = '';
                    if(selectedCategories != ''){
                        selectedCategoriesForQuery = selectedCategories.removeStart('(').removeEnd(')');
                    }
                    List<String> allCategoriesForQuery = new List<String>();
                    if(selectedCategoriesForQuery != ''){
                        for(String str: selectedCategoriesForQuery.split(',')){
                            if(str.normalizeSpace() != 'None'){
                                allCategoriesForQuery.add(str.normalizeSpace());
                            }else {
                                noneMeetingCategory = 'None';
                            }
                    	}
                    }
                    
                    if(!allCategoriesForQuery.isEmpty() && noneMeetingCategory == 'None'){
                        baseQuery += ' AND (Meeting_Category__c IN: allCategoriesForQuery OR Meeting_Category__c = null)';
                    }else if (allCategoriesForQuery.isEmpty() && noneMeetingCategory == 'None') {
                        baseQuery += ' AND Meeting_Category__c = null';
                    }else if(!allCategoriesForQuery.isEmpty() && noneMeetingCategory == ''){
                        baseQuery += ' AND Meeting_Category__c IN: allCategoriesForQuery';
                    }
                }

                //meeting type
                String meetingType = valuesMap.get('Meeting_Type');
                if(String.isNotBlank(meetingType)){
                    baseQuery += ' AND Type = \''+ meetingType + '\'';
                }
            }
            baseQuery += ' ORDER BY Meeting_Category__c NULLS FIRST, CreatedDate ASC';
            baseQuery += ' LIMIT 2500';
        }
                return Database.query(baseQuery);
    }
    public static Map<String,List<Date>> getWeeksOfFQ(String quarter){
        Map<String,List<Date>> weeksNoToFirstDay = new Map<String,List<Date>>();
        Date today = Date.today();
        Integer monthOfQuarter = quarter == 'Next Quarter'?today.month()+3: quarter == 'Previous Quarter'?today.month() - 3: today.month();
        Integer month = (monthOfQuarter > 12) ? monthOfQuarter-12 : (monthOfQuarter < 0) ? monthOfQuarter+12 : monthOfQuarter;
        Integer firstMonthOfTheQuarter = month >= 2 && month <= 4 ? 2 : (month >= 5 && month <= 7 ? 5 : (month >= 8 && month <= 10 ? 8 : 11));
		Date firstDayOfQuarter = (monthOfQuarter >=13) ? Date.newInstance((monthOfQuarter!=13?(today.year() +1): today.year()), firstMonthOfTheQuarter, 1) : (monthOfQuarter <=0) ? Date.newInstance(today.year()-1, firstMonthOfTheQuarter, 1): Date.newInstance(month==1?today.year()-1:today.year(), firstMonthOfTheQuarter, 1);
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
    public static List<EventDataWrapper> setEventDataInWrapper(String dashboard, List<Event> processedEventList, Map<Id, Contact> contactMap, Map<Id, Lead> leadMap, Map<Id,Id> eveConMap, Map<Id,Id> eveLdMap, Map<String, String> eventsMap, Map<Id, UserRecordAccess> mapOfEventIdWithRecordAccess){
        List<String> taggedOutcomeList = getMeetingCategoryPicklistValues();
        List<EventDataWrapper> wrapperClsObj = new List<EventDataWrapper>(); 
        if(!processedEventList.isEmpty()){
            for(Event evt: processedEventList){
                String setDate = evt.CreatedDate.format();
                EventDataWrapper wrapObj = new EventDataWrapper();
                wrapObj.subject = evt.Subject;
                wrapObj.ownerId = evt.Owner.Name;
                wrapObj.userLink = '/'+evt.OwnerId;
                
                if(evt.WhatId!=null){
                    wrapObj.relatedTo = evt.What.Name;
                    wrapObj.whatIdLink = '/'+evt.WhatId;
                }
                wrapObj.createdDate = evt.CreatedDate;
                wrapObj.createdDateString = setDate;
                wrapObj.leaderAttended = evt.Leader_Attended__c;

                wrapObj.meetingLink = '/'+evt.Id;
                wrapObj.leadContactLink = '/'+evt.WhoId;
                wrapObj.hasAccessToEditTheMeeting = mapOfEventIdWithRecordAccess.containsKey(evt.Id);

                wrapObj.activityDate = evt.ActivityDateTime;
                if(evt.ActivityDateTime != null){
                    wrapObj.activityDateString = evt.ActivityDateTime.format();
                }
                wrapObj.activityDateClr = evt.ActivityDate;
                
                if(eventsMap.containsKey('/'+evt.Id)){
                    //List<String> taggedOutcomeList = new List<String>{'Marketing / SDR Intro Meeting','Discovery Meeting','New Business Meeting','Deal Progression Meeting','EB Go / No Go','Champ Go / No Go','Partner Meeting','Other Meetings','Cancelled'};
                    String taggedOutCome = eventsMap.get('/'+evt.Id);
                    if(!taggedOutcomeList.contains(taggedOutCome)){
                        wrapObj.meetingCategory = taggedOutCome;
                    }else{
                        wrapObj.meetingCategory = evt.Meeting_Category__c;
                    }
                }else{
                    wrapObj.meetingCategory = evt.Meeting_Category__c;
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
                    wrapObj.leadIcon = 'standard:lead';
                }
                wrapperClsObj.add(wrapObj);
            }
        }
        return wrapperClsObj;
    }

    public class EventDataWrapper{
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public string createdDateString;
        @AuraEnabled
        public DateTime createdDate;
        @AuraEnabled
        public String accountName;
        @AuraEnabled
        public String leadContactName;
        @AuraEnabled
        public String meetingLink;
        @AuraEnabled
        public String accountLink;
        @AuraEnabled
        public String leadContactLink;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public DateTime activityDate;
        @AuraEnabled
        public String activityDateString;
        @AuraEnabled
        public DateTime activityDateClr;
        @AuraEnabled
        public String fullName;
        @AuraEnabled
        public String activityType;
        @AuraEnabled
        public Date completedDate;
        @AuraEnabled
        public string completedDateString;
        @AuraEnabled
        public String outcome;
        @AuraEnabled
        public string ownerId;
        @AuraEnabled
        public String meetingCategory;
        @AuraEnabled
        public String userLink;
        @AuraEnabled
        public String relatedTo;
        @AuraEnabled
        public String whatIdLink;
        @AuraEnabled
        public Boolean hasAccessToEditTheMeeting;
        @AuraEnabled
        public String leadIcon;
        @AuraEnabled
        public string failedRecordLink;
        @AuraEnabled
        public string failedEventReason;
        @AuraEnabled
        public String leaderAttended;
    }
}