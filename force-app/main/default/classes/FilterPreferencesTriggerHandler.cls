public class FilterPreferencesTriggerHandler extends TriggerManager.GenericTriggerHandler{
	public List<Filter_Preference__c> newList = (List<Filter_Preference__c>)Trigger.new;
    public List<Filter_Preference__c> oldList = (List<Filter_Preference__c>)Trigger.old;
    public Map<Id, Filter_Preference__c> newMap = (Map<Id, Filter_Preference__c>)Trigger.newMap;
    public Map<Id, Filter_Preference__c> oldMap = (Map<Id, Filter_Preference__c>)Trigger.oldMap;
    
    public override void onBeforeInsert(List<sObject> newRecords){
        String logged_in_user = UserInfo.getUserId();
        Set<Id> keyids = new Set<Id>();
        for(Filter_Preference__c pf: newList){
            keyids.add(pf.Dashboard_Filter__c);
        }
        
        Map<Id, Dashboard_Filter__c> dashboardFilterMap = new Map<Id, Dashboard_Filter__c>([SELECT Id, Dashboard_Name__c, Filter_Name__c, Filter_Developer_Name__c from Dashboard_Filter__c where Id IN: keyids ]);
        for(Filter_Preference__c pf: newList){
            pf.Filter_Identifier__c = dashboardFilterMap.get(pf.Dashboard_Filter__c).Dashboard_Name__c+dashboardFilterMap.get(pf.Dashboard_Filter__c).Filter_Developer_Name__c+logged_in_user;
        }
    }
}