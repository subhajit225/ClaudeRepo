/*****************************************************************************


* @Author      : Sushant Arora
* @description : Custom History Tracker - Holds logic for tracking history of fields of an object which is added in the fieldset. 
Field set API should be -> Fields_To_Be_Tracked
* @TestClass   : CS_FieldHistoryTrackingTest

******************************************************************************/


public with sharing class CS_FieldHistoryTracking {  
    
    public static void trackFieldsHistory(List<sObject> newSobjectRecords, Map<Id, sObject> oldSobjectRecords) {
        
        if (newSobjectRecords == null || newSobjectRecords.isEmpty() || oldSobjectRecords ==  null || oldSobjectRecords.isEmpty()) return;
        
        String sobjectName = String.valueOf(newSobjectRecords[0].Id.getSObjectType().getDescribe().getName());
        String fieldSetName = 'Fields_To_Be_Tracked';
        Map<Integer, String> coinIncreaseToReasonMap = new Map<Integer, String>();
        
        
        List<History_Tracking_Config__mdt> objHT = new List<History_Tracking_Config__mdt>(
            [SELECT Lookup_API__c, Object_API_Name__c, Field_Name_API__c, New_Value_API__c, Old_Value_API__c 
             FROM History_Tracking_Config__mdt 
             WHERE DeveloperName =: sobjectName
             AND Is_Active__c = TRUE
             AND Lookup_API__c != NULL 
             AND Object_API_Name__c != NULL
             AND Field_Name_API__c != NULL
             AND New_Value_API__c != NULL 
             AND Old_Value_API__c != NULL
             LIMIT 1]
        );
        
        if(objHT.size() == 0 || objHT.isEmpty()) return;
        
        
        List<SObject> historyTrackingRecordsInsert = (List<SObject>)Type.forName( 'List<' + objHT[0].Object_API_Name__c + '>' ).newInstance();
        
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(sobjectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        List<Schema.FieldSetMember> fieldsOfFieldset = describeSObjectResultObj.fieldSets.getMap().get(fieldSetName).getFields();
        
        if (fieldsOfFieldset == null || fieldsOfFieldset.isEmpty()) return;
        
        Map<String, List<String>> mapFieldAPILstFieldInfo = new Map<String, List<String>>();
        
        for (Schema.FieldSetMember f : fieldsOfFieldset) {
            Schema.DescribeFieldResult describeResult = f.getSObjectField().getDescribe();
            // choose which fields to track depending on the field type
            if (describeResult.getType() == Schema.DisplayType.Boolean ||
                describeResult.getType() == Schema.DisplayType.Combobox ||
                describeResult.getType() == Schema.DisplayType.Currency ||
                describeResult.getType() == Schema.DisplayType.Date ||
                describeResult.getType() == Schema.DisplayType.DateTime ||
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
                describeResult.getType() == Schema.DisplayType.URL) 
            {
                // don't add standard fields that are not necessary
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
        if (mapFieldAPILstFieldInfo.isEmpty()) return;
        
        if(sobjectName == 'User'){
            for(User_Coins_Update_Reason_Mapping__mdt eachMapping : [SELECT Increase_in_coins__c, Reason__c FROM User_Coins_Update_Reason_Mapping__mdt WHERE Active__c = true]){
                coinIncreaseToReasonMap.put(Integer.valueOf(eachMapping.Increase_in_coins__c), eachMapping.Reason__c);
            } 
        }
        for (sObject newRecord : newSobjectRecords) {
            sObject oldRecord = oldSobjectRecords.get(newRecord.Id);
            for (String fieldAPI : mapFieldAPILstFieldInfo.keySet()) {
                if(newRecord.get(fieldAPI) != oldRecord.get(fieldAPI)){ 
                    sObject sObj = Schema.getGlobalDescribe().get(objHT[0].Object_API_Name__c).newSObject() ;
                    if(sobjectName =='User'){
                        if(mapFieldAPILstFieldInfo.get(fieldAPI)[0] == 'Coins'){
                            Integer coinDifference = Integer.valueOf(newRecord.get(fieldAPI) == null ? 0 : newRecord.get(fieldAPI)) - Integer.valueOf(oldRecord.get(fieldAPI) == null ? 0 : oldRecord.get(fieldAPI));
                            if(coinIncreaseToReasonMap.containsKey(coinDifference) && UserInfo.getName().equalsIgnoreCase('Automated Process')){
                                sObj.put('Reason__c',  coinIncreaseToReasonMap.get(coinDifference));
                            }
                            else{
                                sObj.put('Reason__c',  'Manual');
                            }
                        }
                        sObj.put('Modified_Date_Time__c',  System.now());
                        sObj.put('Modified_By__c', UserInfo.getUserId());
                    }
                    sObj.put(objHT[0].Lookup_API__c,newRecord.Id);
                    sObj.put(objHT[0].Field_Name_API__c,mapFieldAPILstFieldInfo.get(fieldAPI)[0]);
                    if(mapFieldAPILstFieldInfo.get(fieldAPI)[1] == 'DATETIME'){
                        DateTime newDT = newRecord.get(fieldAPI) != null ? Datetime.valueOf(newRecord.get(fieldAPI)) : null;
                        DateTime oldDT = oldRecord.get(fieldAPI) != null ? Datetime.valueOf(oldRecord.get(fieldAPI)) : null;
                        sObj.put(objHT[0].New_Value_API__c,newDT?.format('MM/dd/yyyy hh:mm a')); 
                        sObj.put(objHT[0].Old_Value_API__c,oldDT?.format('MM/dd/yyyy hh:mm a')); 
                    }else if(mapFieldAPILstFieldInfo.get(fieldAPI)[1] == 'DATE'){
                        DateTime newDate = newRecord.get(fieldAPI) != null ? Datetime.valueOf(String.valueOf(newRecord.get(fieldAPI))) : null;
                        DateTime oldDate = oldRecord.get(fieldAPI) != null ? Datetime.valueOf(String.valueOf(oldRecord.get(fieldAPI))) : null;
                        sObj.put(objHT[0].New_Value_API__c,newDate?.format('MM/dd/yyyy')); 
                        sObj.put(objHT[0].Old_Value_API__c,oldDate?.format('MM/dd/yyyy')); 
                    }else{
                        sObj.put(objHT[0].New_Value_API__c,newRecord.get(fieldAPI) != null ? String.valueOf(newRecord.get(fieldAPI)) : null);
                        sObj.put(objHT[0].Old_Value_API__c,oldRecord.get(fieldAPI) != null ? String.valueOf(oldRecord.get(fieldAPI)) : null);
                    } 
                    
                    historyTrackingRecordsInsert.add(sObj);
                    
                }
            }
        }
        if (!historyTrackingRecordsInsert.isEmpty()) {
            ID jobID = System.enqueueJob(new insertHistoryRecords(historyTrackingRecordsInsert));
        }
    }
    
    public class insertHistoryRecords implements Queueable {
        public List<sObject> records;
        public insertHistoryRecords(List<sObject> records){
           this.records = records;
        }
            public void execute(QueueableContext context) {
                insert records;
            }
    }
    
    
}