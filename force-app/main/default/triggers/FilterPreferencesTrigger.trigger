trigger FilterPreferencesTrigger on Filter_Preference__c (Before insert) {
    if(UserInfo.getUserId() == Label.DisableTriggerUser) return;
	TriggerManager.invokeHandler(new FilterPreferencesTriggerHandler());
}