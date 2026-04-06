public with sharing class HeatMapEntryTriggerHelper {
    //process all before insert data
    public void populateHeatMapEntryData(List<HeatMap_Entry__c> newRecordsList){
        for(HeatMap_Entry__c entry : newRecordsList){
            if(entry.Account__c != null && entry.HeatMap_Column__c != null){
                //Set external Id to be Account Id + '-' + Column Id
                entry.AccountId_ColumnId__c = entry.Account__c+'-'+entry.HeatMap_Column__c;
            }
        }
    }
}