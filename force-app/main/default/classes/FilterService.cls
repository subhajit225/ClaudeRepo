public class FilterService {
    public static final String LOGGED_IN_USER_ID = UserInfo.getUserId();
    @AuraEnabled(cacheable=true)
    public static List<Dashboard_Filter__c> getDashboardFilers(String dashboardName){
        List<Dashboard_Filter__c> listOfDashboardFilter= [SELECT Id, Dashboard_Name__c, Filter_Name__c, Filter_Developer_Name__c, Help_Text__c, Order__c, Type__c,Options__c FROM Dashboard_Filter__c WHERE Dashboard_Name__c =: dashboardName ORDER BY Order__c ASC];
        return listOfDashboardFilter;
    }

    @AuraEnabled
    public static String gerUserPreferences(String dashboardName){

        Map<String,String> mapFilterNameWithValue = new Map<String,String>();
        for(Filter_Preference__c filtPref : [SELECT Id,Dashboard_Filter__r.Filter_Name__c, Preferred_Filter_Value__c FROM Filter_Preference__c WHERE Dashboard_Filter__r.Dashboard_Name__c =: dashboardName AND User__c =: LOGGED_IN_USER_ID]){
            System.debug('filtPref---'+filtPref);
            mapFilterNameWithValue.put(filtPref.Dashboard_Filter__r.Filter_Name__c, filtPref.Preferred_Filter_Value__c);
        }
        return JSON.serialize(mapFilterNameWithValue);
    }

    @AuraEnabled
    public static void upsertFilterPreferences(String dashboardName, String filterValuesMap){
        System.debug('dashboardName--'+dashboardName);
        System.debug('filterValuesMap--'+filterValuesMap);
        Map<String, String> valuesMap = new Map<String, String>();
        if(filterValuesMap != ''){
            for(Object obj : (List<Object>)JSON.deserializeUntyped(filterValuesMap)){
                Map<String, Object> data = (Map<String, Object>)obj;
                valuesMap.put(String.valueOf(data.get('key')),String.valueOf(data.get('value')));
            } 
        }
        FilterService.savePreferences(dashboardName, LOGGED_IN_USER_ID, valuesMap);
    }

    @future
    public static void savePreferences(String dashboardName, Id user_Id, Map<String, String> filterValuesMap){   

        System.debug('dashboardName- 29-'+dashboardName);
        System.debug('filterValuesMap-30-'+filterValuesMap);
        System.debug('user_Id-31-'+user_Id);
        List<String> uniqueKeyList = new List<String>();
        for(String filterName : filterValuesMap.keySet()){
            uniqueKeyList.add(dashboardName+filterName+user_Id);
        }
        System.debug('uniqueKeyList--'+uniqueKeyList);
        List<Filter_Preference__c> filterPrefernceList = new List<Filter_Preference__c>([SELECT Id,Dashboard_Filter__r.Filter_Developer_Name__c, Preferred_Filter_Value__c, User__c FROM Filter_Preference__c WHERE Filter_Identifier__c IN: uniqueKeyList]);

        List<Filter_Preference__c> listTobeUpserted = new List<Filter_Preference__c>();
        if(!filterPrefernceList.isEmpty()){
            for(Filter_Preference__c pf : filterPrefernceList){
                pf.Preferred_Filter_Value__c = filterValuesMap.get(pf.Dashboard_Filter__r.Filter_Developer_Name__c);
                listTobeUpserted.add(pf);
            }
        }else{
            Map<String, Id> filterToDashboardFilterIdMap = new Map<String, Id>();
            for(Dashboard_Filter__c dashfilter : [SELECT Id, Filter_Name__c,Filter_Developer_Name__c FROM Dashboard_Filter__c WHERE Dashboard_Name__c =: dashboardName]){
                filterToDashboardFilterIdMap.put(dashfilter.Filter_Developer_Name__c, dashfilter.Id);
            }
            System.debug('filterToDashboardFilterIdMap---'+filterToDashboardFilterIdMap);
            for(String keyVal : filterValuesMap.keySet()){
                Filter_Preference__c fltPref = new Filter_Preference__c();
                fltPref.Dashboard_Filter__c = filterToDashboardFilterIdMap.get(keyVal);
                fltPref.Preferred_Filter_Value__c = filterValuesMap.get(keyVal);
                fltPref.User__c = user_Id;
                listTobeUpserted.add(fltPref);
            }
        }
        System.debug('listTobeUpserted---'+listTobeUpserted);

        upsert listTobeUpserted;

    }
}