/*****************************************************************************
@description   : Custom History Tracker
Holds logic for tracking history of fields of an object which is added in the fieldset.

Field set API should be -> Fields_To_Be_Tracked

******************************************************************************/


public without sharing class CustomHistoryTracker {  

    /** Global variables  **/

    public static Set<String> recurssionHandlerSobjectSet = new Set<String>();
        public static Boolean richTextIdentified = false;
    
    /************************************************* 
    * @description : Method called in after update | newSobjectRecords -> sobject new values |  oldSobjectRecords -> old values | parentFieldApi is lookup field API in History Tracking object.
    * @param newSobjectRecords
    * @param oldSobjectRecords
    * @param parentFieldApi
    ******************************************************/
    public static void trackFieldsHistory(List<sObject> newSobjectRecords, Map<Id,sObject> oldSobjectRecords, String parentFieldApi) {
        
        if(newSobjectRecords == null || newSobjectRecords.isEmpty() || oldSobjectRecords ==  null || oldSobjectRecords.isEmpty() || parentFieldApi == null) return;
        
        String sobjectName = String.valueOf(newSobjectRecords[0].Id.getsobjecttype());
        String fieldSetName = 'Fields_To_Be_Tracked';

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
    	Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(sobjectName);
    	Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        List<Schema.FieldSetMember> fieldsOfFieldset = DescribeSObjectResultObj.fieldSets.getMap().get(fieldSetName).getFields();
        
        if(fieldsOfFieldset == Null || fieldsOfFieldset.isEmpty()) return;

        Map<String,List<String>> mapFieldAPILstFieldInfo = new Map<String,List<String>>();
        List<History_Tracking__c> historyTrackingRecordsInsert = new List<History_Tracking__c>();

        
        for (Schema.FieldSetMember f : fieldsOfFieldset) {
        
            Schema.DescribeFieldResult describeResult = f.getSObjectField().getDescribe();
            //choose which fields to track depending on the field type
            if (describeResult.getType() == Schema.DisplayType.Boolean ||
                describeResult.getType() == Schema.DisplayType.Combobox ||
                describeResult.getType() == Schema.DisplayType.Currency ||
                describeResult.getType() == Schema.DisplayType.Date ||
                describeResult.getType() == Schema.DisplayType.Double ||
                describeResult.getType() == Schema.DisplayType.Email ||
                describeResult.getType() == Schema.DisplayType.Integer ||
                describeResult.getType() == Schema.DisplayType.MultiPicklist ||
                describeResult.getType() == Schema.DisplayType.Percent ||
                describeResult.getType() == Schema.DisplayType.Phone ||
                describeResult.getType() == Schema.DisplayType.Picklist ||
                describeResult.getType() == Schema.DisplayType.String ||
                describeResult.getType() == Schema.DisplayType.TextArea ||
                describeResult.getType() == Schema.DisplayType.Time ||
                describeResult.getType() == Schema.DisplayType.URL  ||
               	describeResult.getType() == Schema.DisplayType.DateTime ||
                describeResult.getType() == Schema.DisplayType.REFERENCE 
               ) 
            {
                //don't add standard fields that are not necessary
                if (describeResult.getName() != 'CreatedDate' &&
                    describeResult.getName() != 'LastModifiedDate' &&
                    describeResult.getName() != 'SystemModstamp' &&
                    //do not add formula fields
                    !describeResult.isCalculated()
                    )
                {
                    List<String> localStr = new List<String>();
                    localStr.add(String.valueOf(describeResult.getLabel()));
                    localStr.add(String.valueOf(describeResult.getType()));
                    mapFieldAPILstFieldInfo.put(describeResult.getName(),localStr);
                }
            }
        }

        if(mapFieldAPILstFieldInfo.isEmpty()) return;

        for(sObject newRecord: newSobjectRecords){
            sObject oldRecord = oldSobjectRecords.get(newRecord.Id);
            for (String fieldAPI : mapFieldAPILstFieldInfo.keySet()) {
                if(newRecord.get(fieldAPI) != oldRecord.get(fieldAPI) && mapFieldAPILstFieldInfo.containsKey(fieldAPI)){ 
                    History_Tracking__c HT = new History_Tracking__c();
                    HT.put(parentFieldApi,newRecord.Id);
                    HT.Field_Name__c = mapFieldAPILstFieldInfo.get(fieldAPI)[0];
                    if(mapFieldAPILstFieldInfo.get(fieldAPI)[1] == 'TEXTAREA' && richTextIdentified){
                        HT.New_Value__c = '';
                        HT.Old_Value__c = '';
                    }else if(mapFieldAPILstFieldInfo.get(fieldAPI)[1] == 'DATETIME'){
                        DateTime newDT = newRecord.get(fieldAPI) != null ? Datetime.valueOf(newRecord.get(fieldAPI)) : null;
                        DateTime oldDT = oldRecord.get(fieldAPI) != null ? Datetime.valueOf(oldRecord.get(fieldAPI)) : null;
                        HT.New_Value__c = newDT?.format('MM/dd/yyyy hh:mm a'); 
                        HT.Old_Value__c = oldDT?.format('MM/dd/yyyy hh:mm a');
                    }else if(mapFieldAPILstFieldInfo.get(fieldAPI)[1] == 'DATE'){
                        DateTime newDate = newRecord.get(fieldAPI) != null ? Datetime.valueOf(String.valueOf(newRecord.get(fieldAPI))) : null;
                        DateTime oldDate = oldRecord.get(fieldAPI) != null ? Datetime.valueOf(String.valueOf(oldRecord.get(fieldAPI))) : null;
                        HT.New_Value__c = newDate?.format('MM/dd/yyyy');
                        HT.Old_Value__c = oldDate?.format('MM/dd/yyyy');
                    }else{
                        HT.New_Value__c = newRecord.get(fieldAPI) != null ? String.valueOf(newRecord.get(fieldAPI)) : null;
                        HT.Old_Value__c = oldRecord.get(fieldAPI) != null ? String.valueOf(oldRecord.get(fieldAPI)) : null;
                    } 
                    historyTrackingRecordsInsert.add(HT);
                }
            }
        }
        if(!historyTrackingRecordsInsert.isEmpty()){
            CustomHistoryTracker.recurssionHandlerSobjectSet.add(String.valueOf(DescribeSObjectResultObj));
                insert historyTrackingRecordsInsert;      
        }
    }
    
}