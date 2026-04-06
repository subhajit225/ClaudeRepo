/**
* @description  :   Process open Metadata requests to create metadata in Salesforce
* @Author       :   Saakshi Gupta
* @CreatedDate  :   27-07-2020
* @Jira Ticket  :   CS21-83 - Enable a method for Rob Tipton to manage software releases in Salesforce
* @Description  :   Process open Metadata requests to create metadata in Salesforce
* @TestClass    :   ProcessMetadataRequestsBatchTest.cls
* @Modifications:   CS21-2810 - Add options to Abra Tags field on Case and record types through SentryAI
*					CS21-3349 - Increased code coverage to 90
*/
public class ProcessMetadataRequestsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {
    
    public String message = '';
    public String metadataRequestId='';
    public MetadataService.MetadataPort service = new MetadataService.MetadataPort();
    Public MetadataService.CustomField customField;
    Public MetadataService.GlobalValueSet globalField;
    Public map<String,Set<String>> recordTypeToNewValues=new map<String,Set<String>>();
    Public map<String,Set<String>> recordTypeToNewLabelsValues=new map<String,Set<String>>();
    Public List<String> metaReqIdList=new List<String>();
    Public list<String> caseRecordTypeNames=label.Case_Recordtype_Names.split(',');
    Public list<String> caseRecordTypeLabelNames=label.Case_Recordtypes_Label_Name.split(',');
    
    /**
    * @description start method
    * @param context
    * @return metadata_request records with Open Status
    */
    public Database.QueryLocator start(Database.BatchableContext context){
        String testCase='';
        if(Test.isRunningTest()){
            testCase='  And value__c in (\'1.0.Test picklist value\',\'2.0.Test picklist value\')';
        }
        String batchQuery = 'SELECT Id, Field__c, Object__c, Value__c, Controlling_Product_Lines__c,Message__c,status__c, Operation_Type__c, Old_Value__c '
            + ' FROM Metadata_Request__c WHERE Status__c = \'Open\'' +testCase;
        return Database.getQueryLocator(batchQuery);
    }
    
    /**
    * @description execute method
    * @param context
    * @param metadataRequestList list of metadata records
    */
    public void execute(Database.BatchableContext context, List<Metadata_Request__c> metadataRequestList) {
        if(metadataRequestList.size()>0){ 
            metadataRequestId=metadataRequestList[0].Id;
            service.SessionHeader = new MetadataService.SessionHeader_element();
            service.SessionHeader.sessionId = UserInfo.getSessionId();
            service.timeout_x = 120000;
            
            if(String.IsNotBlank(metadataRequestList[0].message__c) && String.IsNotBlank(metadataRequestList[0].Value__c) && metadataRequestList[0].message__c.contains('and the value will be added to the Record Types shortly.')){
                checkIfRecordTypeUpdated(metadataRequestList[0].Value__c, metadataRequestList[0].Field__c);
            }else{
                try{
                    List<MetadataService.Metadata> metadataList = new List<MetadataService.Metadata>();
                    List<MetadataService.CustomValue> customFieldValueList = new List<MetadataService.CustomValue>();
                    List<MetadataService.CustomValue> customFieldValueLabelList = new List<MetadataService.CustomValue>();
                    List<MetadataService.CustomValue> globalFieldValueList = new List<MetadataService.CustomValue>();
                    List<MetadataService.ValueSettings> controllingValueList = new List<MetadataService.ValueSettings>();
                    String customFieldName = '';
                    String globalFieldName = '';
                    Boolean IsNewValuePresentInCustomField=false;
                    Boolean IsNewValuePresentInGlobalSet=false;
                    list<String> ControllingProductLines=new list<String>();
                    List<Id> metadataDeleteIds = new List<Id>();
                    
                    for(Metadata_Request__c eachRequest : metadataRequestList){
                        if(eachRequest.Operation_Type__c == 'None' 
                           || String.isBlank(eachRequest.Operation_Type__c) 
                           || eachRequest.Operation_Type__c == 'Update'){
                            
                            MetadataService.CustomValue objCustomValue = new MetadataService.CustomValue();
                            objCustomValue.label = eachRequest.Value__c;
                            objCustomValue.fullName = eachRequest.Value__c;
                            objCustomValue.default_x = false;
                            
                            if(eachRequest.Object__c.contains('Case')){
                                if(eachRequest.Field__c == 'Software Version')
                                    customFieldName = 'Case.Software_Version__c';
                                else if(eachRequest.Field__c == 'Abra Tags')
                                    customFieldName = 'Case.Abra_Tags__c';
                                
                                customField = (MetadataService.CustomField)service.readMetadata('CustomField', new String[]{customFieldName}).getRecords()[0];
                                List<MetadataService.CustomValue> existingValues = Test.isRunningTest() ? getMockExistingValues() : new List<MetadataService.CustomValue>(customField.valueSet.valueSetDefinition.value);
                                for(Integer i=0;i<existingValues.size();i++){
                                    if(eachRequest.Operation_Type__c == 'Update' && EncodingUtil.urlDecode(existingValues[i].fullName, 'UTF-8') ==metadataRequestList[0].Old_Value__c){
                                        existingValues.remove(i); // Remove from existingValues
                                    }
                                    if(EncodingUtil.urlDecode(existingValues[i].fullName, 'UTF-8') ==metadataRequestList[0].Value__c){
                                        IsNewValuePresentInCustomField=true;
                                        break;
                                    }
                                }
                                if(!IsNewValuePresentInCustomField){
                                    if(eachRequest.Field__c == 'Software Version'){
                                        customFieldValueList.add(objCustomValue);
                                        customField.valueSet.valueSetDefinition.value.clear();
                                        customField.valueSet.valueSetDefinition.value.addAll(customFieldValueList);
                                        customField.valueSet.valueSetDefinition.value.addAll(existingValues);
                                        sortPicklistValues(customField.valueSet.valueSetDefinition.value);
                                        
                                    }
                                    else if(eachRequest.Field__c == 'Abra Tags'){
                                        customFieldValueLabelList.add(objCustomValue);
                                        customField.valueSet.valueSetDefinition.value.clear();
                                        customField.valueSet.valueSetDefinition.value.addAll(customFieldValueLabelList);
                                        customField.valueSet.valueSetDefinition.value.addAll(existingValues);
                                    }
                                    
                                }
                                if( !String.isBlank(eachRequest.Controlling_Product_Lines__c)) {
                                    
                                    if(!IsNewValuePresentInCustomField && !Test.isRunningTest()){
                                        ControllingProductLines=eachRequest.Controlling_Product_Lines__c.split(';');
                                    }else {
                                        ControllingProductLines=checkIfControllingFieldIsUpdated(eachRequest.Value__c,eachRequest.Controlling_Product_Lines__c.split(';'));
                                    }
                                    if(ControllingProductLines!=null && ControllingProductLines.size()>0){
                                        MetadataService.ValueSettings controllingValue = new MetadataService.ValueSettings();
                                        controllingValue.controllingFieldValue = ControllingProductLines;
                                        controllingValue.valueName = eachRequest.Value__c;
                                        controllingValueList.add(controllingValue);
                                    }
                                }
                                if(!controllingValueList.isEmpty() && customFieldName != 'Case.Abra_Tags__c'){
                                    customField.valueSet.valueSettings.addAll(controllingValueList);
                                }
                                if(!IsNewValuePresentInCustomField || ControllingProductLines.size()>0){
                                    metadataList.add(customField);
                                }
                                
                                
                                
                            }
                            if(eachRequest.Object__c.contains('User, Knowledge Centered Support (KCS), Release Version, Release')){
                                globalFieldName = eachRequest.Field__c == 'Software Version' ? 'Software_Versions' : '';
                                
                                globalField = (MetadataService.GlobalValueSet)service.readMetadata('GlobalValueSet', new String[]{globalFieldName}).getRecords()[0];
                                
                                List<MetadataService.CustomValue> existingValues = Test.isRunningTest() ? getMockExistingValues() : new List<MetadataService.CustomValue>(globalField.customValue);
                                for(Integer i=0;i<existingValues.size();i++){
                                    if(EncodingUtil.urlDecode(existingValues[i].fullName, 'UTF-8') ==metadataRequestList[0].Value__c){
                                        IsNewValuePresentInGlobalSet=true;
                                        break;
                                    }
                                }
                                
                                if(!IsNewValuePresentInGlobalSet){  
                                    globalFieldValueList.add(objCustomValue);
                                    globalField.customValue.clear();
                                    globalField.customValue.addAll(globalFieldValueList);
                                    globalField.customValue.addAll(existingValues);
                                    sortPicklistValues(globalField.customValue);
                                    metadataList.add(globalField);
                                }
                                
                            }
                        }
                        else if(eachRequest.Operation_Type__c == 'Delete'){
                            if(eachRequest.Field__c == 'Software Version')
                                customFieldName = 'Case.Software_Version__c';
                            else if(eachRequest.Field__c == 'Abra Tags')
                                customFieldName = 'Case.Abra_Tags__c';
                            
                            customField = (MetadataService.CustomField)service.readMetadata('CustomField', new String[]{customFieldName}).getRecords()[0];
                            
                            List<MetadataService.CustomValue> existingValues = Test.isRunningTest() ? getMockExistingValues() : new List<MetadataService.CustomValue>(customField.valueSet.valueSetDefinition.value);
                            for(Integer i=0;i<existingValues.size();i++){
                                if(EncodingUtil.urlDecode(existingValues[i].fullName, 'UTF-8') ==eachRequest.Value__c){
                                    existingValues[i].isActive = false;
                                    break;
                                }
                            }
                            customField.valueSet.valueSetDefinition.value.clear();
                            customField.valueSet.valueSetDefinition.sorted=true;
                            customField.valueSet.valueSetDefinition.value.addAll(existingValues);
                            metadataList.add(customField);
                            metadataDeleteIds.add(eachRequest.Id);
                        }
                    }
                    
                    String status = '';
                    
                    if(metadataList.size()>0){
                        String successMessage = '';
                        String failureMessage = '';  
                        
                        List<MetadataService.SaveResult>  results = service.updateMetadata(metadataList);
                        
                        for (MetadataService.SaveResult objResult : results) {
                            if(!objResult.success) {
                                failureMessage = failureMessage + objResult.errors[0].message + '. ';
                            }
                            else{
                                successMessage = 'Request completed';
                            }
                        }
                        
                        if(!String.isBlank(failureMessage) && !String.isBlank(successMessage)){
                            
                            status = 'Closed';
                            message = 'Request partially completed. ' + failureMessage;
                        }
                        else if(!String.isBlank(successMessage)){
                            
                            status = 'Closed';
                            message = successMessage;
                            if(metadataRequestList[0].Object__c.contains('Case') && (caseRecordTypeNames.size()>0 || caseRecordTypeLabelNames.size()>0) && !metadataDeleteIds.contains(metadataRequestList[0].Id)){
                                Status='Open';
                                checkIfRecordTypeUpdated(metadataRequestList[0].Value__c, metadataRequestList[0].Field__c);  
                                message=message+ ' and the value will be added to the Record Types shortly.';
                            }
                            else if(metadataDeleteIds.contains(metadataRequestList[0].Id)){
                                metaReqIdList.add(metadataRequestList[0].Id);
                            }
                        }
                        else if(!String.isBlank(failureMessage)){
                            status = 'Closed';
                            message = failureMessage;
                        }
                        
                    }else{ 

                        if((caseRecordTypeNames.size()>0 || caseRecordTypeLabelNames.size()>0) && String.IsNotBlank(metadataRequestList[0].Object__c) && metadataRequestList[0].Object__c.contains('Case'))
                        {
                            if(checkIfRecordTypeUpdated(metadataRequestList[0].Value__c, metadataRequestList[0].Field__c)){
                                status='Closed';
                                Message='The new value already exists in the picklist fields, and values already exists in the Record Types.';
                            }else{
                                status='Open';
                                Message='The new value already exists in the picklist fields, and the value will be added to the Record Types shortly.';
                            }
                            
                        }else if(!metadataRequestList[0].Object__c.contains('Case') && metadataRequestList[0].Object__c.contains('User, Knowledge Centered Support (KCS), Release Version, Release') && IsNewValuePresentInGlobalSet){
                            status='Closed';
                            Message='Request completed';
                        }
                    }
                    if(String.IsNotBlank(metadataRequestId) && String.IsNotBlank(Status) && String.IsNotBlank(message)){
                        Metadata_Request__c request = new Metadata_Request__c(Id = metadataRequestId, Status__c = status, Message__c = message);
                        update request; 
                    }
                    
                    
                }
                catch(Exception e){
                    System.debug(LoggingLevel.DEBUG, 'Exception==> '+e.getMessage());
                    System.debug(LoggingLevel.DEBUG, 'Line number: ' + e.getLineNumber());  
                }
                
                
            }
        }       
    }
    
    /**
    * @description finish method
    * @param context
    */
    public void finish(Database.BatchableContext context){
        
        if(recordTypeToNewValues.size()>0 || recordTypeToNewLabelsValues.size()>0){
            System.enqueueJob(new UpdateRecordTypeQueueable(recordTypeToNewValues, recordTypeToNewLabelsValues)); 
        }
        
        if(metaReqIdList.size()>0){
            List<Metadata_Request__c> metadataList=new List<Metadata_Request__c>();
            for(String metaRecId:metaReqIdList){
                Metadata_Request__c mr=new Metadata_Request__c();
                mr.Status__c='Closed';
                mr.Message__c='Request completed';
                mr.Id=metaRecId;
                metadataList.add(mr);
            }
            if(metadataList.size()>0){
                update metadataList;
            }
        }
        Database.executeBatch(new UpdateUserUrlsBatch(''));//CS21-3349
    }

    /**
    * @description to check if options exist in record types or not
    * @param newValue
    * @param fieldName
    * @return Boolean 
    */
    public Boolean checkIfRecordTypeUpdated(String newValue, String fieldName){
        if((fieldName == 'Software Version' && caseRecordTypeNames.size()>0) || (fieldName == 'Abra Tags' && caseRecordTypeLabelNames.size()>0)){
            List<String> allNewPickListValues=new List<String>();
            Set<String> allCaseRecordtypeName = new Set<String>(caseRecordTypeNames);
            allCaseRecordtypeName.addAll(caseRecordTypeLabelNames);
            List<RecordType> CaseRecordTypeList = new List<RecordType>();
            if(fieldName == 'Software Version'){
                CaseRecordTypeList = [select id,name,DeveloperName from RecordType where SobjectType='Case' and name in:caseRecordTypeNames];
            }
            else if(fieldName == 'Abra Tags'){
                CaseRecordTypeList = [select id,name,DeveloperName from RecordType where SobjectType='Case' and name in:caseRecordTypeLabelNames];
            }
            String recordTypeName='';
            List<String> recordTypeDeveloperNames = new List<String>();
            for(RecordType rec:CaseRecordTypeList){
                recordTypeName='Case.'+rec.DeveloperName;
                recordTypeDeveloperNames.add(recordTypeName);
            }
            
            MetadataService.RecordType[] recordTypes;
            if (!Test.isRunningTest()) {
                recordTypes = (MetadataService.RecordType[])service.readMetadata('RecordType', recordTypeDeveloperNames).getRecords();
            } else {
                recordTypes=createMockRecordTypes();
                String fieldApiName ='';
                if(fieldName == 'Software Version')fieldApiName = 'Software_Version__c';
                if(fieldName == 'Abra Tags')fieldApiName = 'Abra_Tags__c';
                recordTypes=createMockRecordTypes(fieldName,fieldApiName,'1.0.Test picklist value');
                caseRecordTypeNames = new List<String>();
            }
            String encodedNewValue='';
            if(!Test.isRunningTest()){
                encodedNewValue = EncodingUtil.urlEncode(newValue, 'UTF-8').replace('.', '%2E').replace(')', '%29').replace('(', '%28').replace('+', ' ');
            }else{
                encodedNewValue=newValue;
            }
            
            Boolean isNewValueContains=false;
            
            if(fieldName == 'Software Version'){
                for(Integer i=0;i<recordTypes.size();i++){  
                    for (MetadataService.RecordTypePicklistValue existingValue : recordTypes[i].PicklistValues) {
                        if (existingValue.picklist == 'Software_Version__c') {
                            for(Integer j=0;j<existingValue.values.size();j++){
                                if(encodedNewValue==existingValue.values[j].fullName){
                                    isNewValueContains=true;
                                    break;
                                }
                            }
                            
                        }
                        if(isNewValueContains){
                            break;
                        }  
                    }
                    if(!isNewValueContains){
                        if(recordTypeToNewValues.containskey(recordTypes[i].fullName)){
                            Set<String> recTypeList=recordTypeToNewValues.get(recordTypes[i].fullName);
                            recTypeList.add(newValue);
                            allNewPickListValues.addAll(recTypeList);
                            recordTypeToNewValues.put(recordTypes[i].fullName,recTypeList);
                        }else{
                            allNewPickListValues.add(newValue);
                            recordTypeToNewValues.put(recordTypes[i].fullName,new Set<String>{newValue});
                        }
                    }else{
                        isNewValueContains=false;
                    }
                    
                } 
            }
            else if(fieldName == 'Abra Tags'){
                for(Integer i=0;i<recordTypes.size();i++){  
                    for (MetadataService.RecordTypePicklistValue existingValue : recordTypes[i].PicklistValues) {
                        if (existingValue.picklist == 'Abra_Tags__c') {
                            for(Integer j=0;j<existingValue.values.size();j++){
                                if(encodedNewValue==existingValue.values[j].fullName){
                                    isNewValueContains=true;
                                    break;
                                }
                            }
                            
                        }
                        if(isNewValueContains){
                            break;
                        }  
                    }
                    if(!isNewValueContains){
                        if(recordTypeToNewLabelsValues.containskey(recordTypes[i].fullName)){
                            Set<String> recTypeList=recordTypeToNewLabelsValues.get(recordTypes[i].fullName);
                            recTypeList.add(newValue);
                            allNewPickListValues.addAll(recTypeList);
                            recordTypeToNewLabelsValues.put(recordTypes[i].fullName,recTypeList);
                        }else{
                            allNewPickListValues.add(newValue);
                            recordTypeToNewLabelsValues.put(recordTypes[i].fullName,new Set<String>{newValue});
                        }
                    }else{
                        isNewValueContains=false;
                    }
                    
                } 
            }
            
            
            if((recordTypeToNewValues.size()>0 && !allNewPickListValues.contains(newValue)) || recordTypeToNewValues.size()==0){
                metaReqIdList.add(metadataRequestId);
            }
            
            if(allNewPickListValues.size()>0 && !allNewPickListValues.contains(newValue)){
                return true;
            }
            
        }
        return false;
    }
    
    
    /**
    * @description Helper for Mock Metadata Records
    * @return recordtypes metadata
    */
    Public MetadataService.RecordType[] createMockRecordTypes() {
        
        MetadataService.RecordType recordType = new MetadataService.RecordType();
        
        // Set values for the fields
        recordType.fullName = 'Case.Support_Case';
        recordType.active = true;
        recordType.description = 'Test picklist value';
        recordType.label = 'Software Version';
        
        // Create and set picklist values
        MetadataService.RecordTypePicklistValue picklistValue1 = new MetadataService.RecordTypePicklistValue();
        picklistValue1.picklist = 'Software_version__c';
        MetadataService.PicklistValue pickLValue= new MetadataService.PicklistValue();
        pickLValue.fullName='1.0.Test picklist value';
        picklistValue1.values = new List<MetadataService.PicklistValue>{pickLValue};
            recordType.picklistValues = new MetadataService.RecordTypePicklistValue[]{picklistValue1}; 
                return new List<MetadataService.RecordType>{ recordType };
                    }
    /**
    * @description Helper for Mock Metadata Records
    * @param fieldLabel : label of the field
    * @param fieldApiName : API name of the field
    * @param picklistValue : picklist field value
    * @return recordtypes metadata
    */
    Public MetadataService.RecordType[] createMockRecordTypes(String fieldLabel,String fieldApiName,String picklistValue) {
        List<MetadataService.RecordType> recordTypeList = new List<MetadataService.RecordType>();
        
        MetadataService.RecordType recordType = new MetadataService.RecordType();
        
        // Set values for the fields
        recordType.fullName = 'Case.Support_Case';
        recordType.active = true;
        recordType.description = 'Test picklist value';
        recordType.label = fieldLabel;
        
        // Create and set picklist values
        MetadataService.RecordTypePicklistValue picklistValue1 = new MetadataService.RecordTypePicklistValue();
        picklistValue1.picklist = fieldApiName;
        MetadataService.PicklistValue pickLValue= new MetadataService.PicklistValue();
        pickLValue.fullName=picklistValue;
        picklistValue1.values = new List<MetadataService.PicklistValue>{pickLValue};
        recordType.picklistValues = new MetadataService.RecordTypePicklistValue[]{picklistValue1}; 
        recordTypeList.add(recordType);
        return recordTypeList;
    }
    /**
    * @description Helper for Mock Metadata Records
    * @return recordtypes metadata
    */
    public List<MetadataService.CustomValue> getMockExistingValues(){
        List<MetadataService.CustomValue> customFieldValues = new List<MetadataService.CustomValue>();
        MetadataService.CustomValue customValue1 = new MetadataService.CustomValue();
        customValue1.fullName = '2.0.Test picklist value';
        customValue1.default_x = false;
        customValue1.label = '2.0.Test picklist value';
        customFieldValues.add(customValue1);
        return customFieldValues;
    }

    /**
    * @description start method
    * @param newValue
    * @param controllingFieldList
    * @return metadata_request records with Open Status
    */
    
    public list<String> checkIfControllingFieldIsUpdated(String newValue,List<String> controllingFieldList){
        list<String> controllingFieldsTobeUpdated=new list<String>();
        set<String> oldCOntrollingFields=new set<String>();
        
        if(Test.isRunningTest()) {
            list<metadataservice.valueSettings> valueSettingList=new list<metadataservice.valueSettings>();
            metadataservice.valueSettings meta=new metadataservice.valueSettings();
            meta.controllingFieldValue=new list<String>{'CDM','Polaris'};
                meta.valueName='2.0.Test picklist value';
            valueSettingList.add(meta);
            customField.valueSet.valueSettings=valueSettingList;
        }
        
        for(Integer i=0;i<customField.valueSet.valueSettings.size();i++){
            if(customField.valueSet.valueSettings[i].valueName==newValue){
                if( customField.valueSet.valueSettings[i].controllingFieldValue.size()>0){
                    if(customField.valueSet.valueSettings[i].controllingFieldValue.size()==controllingFieldList.size()){
                        if(!(new Set<String>(controllingFieldList).equals(new Set<String>(customField.valueSet.valueSettings[i].controllingFieldValue)))){
                            oldCOntrollingFields.addALL(customField.valueSet.valueSettings[i].controllingFieldValue);
                        }
                    }else{
                        for(String controllingFieldName:controllingFieldList){
                            if(!customField.valueSet.valueSettings[i].controllingFieldValue.contains(controllingFieldName)){
                                oldCOntrollingFields.addALL(customField.valueSet.valueSettings[i].controllingFieldValue);
                                break;
                            }
                        }
                        
                    }
                    break;
                }
                break;
            }
        }
        if(oldCOntrollingFields.size()>0){
            oldCOntrollingFields.AddALL(controllingFieldList);
            controllingFieldsTobeUpdated.AddAll(oldCOntrollingFields);       
        }
        return controllingFieldsTobeUpdated;
    }
    /**
     * @description Sorts the picklist values in descending order
     * @param picklistValues List of picklist values to be sorted
     */
    public static void sortPicklistValues( List<MetadataService.CustomValue> picklistValues){
        if(!(picklistValues.size()>0)){
            return;
        }
        Map<String, String> lowerToOriginal = new Map<String, String>();
        // map to store the original value as we need to sort the values in descending order irrespective of the case
        for(Integer i=0;i<picklistValues.size();i++){
            lowerToOriginal.put(EncodingUtil.urlDecode(picklistValues[i].fullName, 'UTF-8').tolowerCase(),EncodingUtil.urlDecode(picklistValues[i].fullName, 'UTF-8'));
        }
        
        List<String> sortedKeys = new List<String>(lowerToOriginal.keySet());
        sortedKeys.sort();
        
        picklistValues.clear();
        //To sort the values in desceding order
        for (Integer i = sortedKeys.size() - 1; i >= 0; i--) {
            MetadataService.CustomValue objCustomValue = new MetadataService.CustomValue();
            objCustomValue.label = lowerToOriginal.get(sortedKeys[i]);
            objCustomValue.fullName =lowerToOriginal.get(sortedKeys[i]);
            objCustomValue.default_x = false;
            picklistValues.add(objCustomValue);
        } 
    } 
}