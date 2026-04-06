/**
* @Author       :   Raveeesh Layal
* @CreatedDate  :   12-11-2024
* @Jira Ticket  :   CS21-2646 - Metadata request MR-000361 was not processed properly
* @description  :   Adds the picklist values to the respective record types
* @TestClass    :   ProcessMetadataRequestsBatchTest.cls
*/
public class UpdateRecordTypeQueueable implements Queueable, Database.AllowsCallouts {
    
    Public map<String,Set<String>> recordTypeToNewValues=new map<String,Set<String>>();
    Public map<String,Set<String>> recordTypeToNewLabelValues=new map<String,Set<String>>();
    
    /**
    * @description constructor
    * @param recordTypeToNewValues map to update record types for Software version field
    * @param recordTypeToNewLabelValues map to update record types for Abra Tags field
    */
    public UpdateRecordTypeQueueable(map<String,Set<String>> recordTypeToNewValues, map<String,Set<String>> recordTypeToNewLabelValues) {
        this.recordTypeToNewValues=recordTypeToNewValues;
        this.recordTypeToNewLabelValues = recordTypeToNewLabelValues;
    }
    
    /**
    * @description execute method
    * @param context
    */
    public void execute(QueueableContext context) {
        List<String> caseRecordTypeList=new list<String>();
        List<String> caseRecordTypeLabelList=new list<String>();
        if(recordTypeToNewValues.size()>0){
            try{
                caseRecordTypeList.addAll(recordTypeToNewValues.keyset());
                
                MetadataService.MetadataPort service = new MetadataService.MetadataPort();
                service.SessionHeader = new MetadataService.SessionHeader_element();
                service.SessionHeader.sessionId = UserInfo.getSessionId();
                service.timeout_x = 120000;
                
                MetadataService.RecordType[] recordTypes;
                if (!Test.isRunningTest()) {
                    recordTypes = (MetadataService.RecordType[])service.readMetadata('RecordType',new List<String>{caseRecordTypeList[0]}).getRecords();
                } else {
                   ProcessMetadataRequestsBatch P=new ProcessMetadataRequestsBatch();
                   recordTypes= p.createMockRecordTypes();
                }
                
                if(recordTypes.size()>0){
                    MetadataService.RecordTypePicklistValue fieldRelatedPicklistValues = new MetadataService.RecordTypePicklistValue();
                    fieldRelatedPicklistValues.picklist = 'Software_Version__c';
                    
                    List<MetadataService.RecordTypePicklistValue> listFieldRelatedPicklistValues = new List<MetadataService.RecordTypePicklistValue>();
                    List<MetadataService.PicklistValue> picklistValues = new List<MetadataService.PicklistValue>();
                    
                    // Retrieve existing picklist values
                    List<MetadataService.PicklistValue> existingPicklistValues = new List<MetadataService.PicklistValue>();
                    if (!Test.isRunningTest() && recordTypes.size() > 0 && recordTypes[0].PicklistValues != null && recordTypes[0].PicklistValues.size() > 0) {
                        for (MetadataService.RecordTypePicklistValue existingValue : recordTypes[0].PicklistValues) {
                            if (existingValue.picklist == 'Software_Version__c') {
                                existingPicklistValues.addAll(existingValue.values);
                                break;
                            }
                        }
                    }
                    
                    
                    for(String newValue:recordTypeToNewValues.get(recordTypes[0].FullName)){
                        MetadataService.PicklistValue pk = new MetadataService.PicklistValue();
                        pk.fullName =newValue ;
                        pk.isActive = true;
                        pk.default_x = false;
                        picklistValues.add(pk);
                    }
                    existingPicklistValues.addAll(picklistValues);
                    fieldRelatedPicklistValues.values = existingPicklistValues;
                    listFieldRelatedPicklistValues.add(fieldRelatedPicklistValues);
                    recordTypes[0].PicklistValues = listFieldRelatedPicklistValues;
                   
                    
                    MetadataService.Metadata[] listMetadata = new List<MetadataService.Metadata>();
                    listMetadata.addAll(recordTypes);
                    if(listMetadata.size()>0){
                        List<MetadataService.SaveResult> results = service.updateMetadata(listMetadata);   
                    }
                }
            }
            catch(Exception e){
                System.debug(LoggingLevel.DEBUG, 'Exception==> '+e.getMessage());
            }
            if(recordTypeToNewValues.size()>0){
                recordTypeToNewValues.remove(caseRecordTypeList[0]);
            }
        }
        // ----- CS21-2810: Add Abra Tags options to the record types -----
        if(recordTypeToNewLabelValues.size()>0){
            try{
                caseRecordTypeLabelList.addAll(recordTypeToNewLabelValues.keyset());
                
                MetadataService.MetadataPort service = new MetadataService.MetadataPort();
                service.SessionHeader = new MetadataService.SessionHeader_element();
                service.SessionHeader.sessionId = UserInfo.getSessionId();
                service.timeout_x = 120000;
                
                MetadataService.RecordType[] recordTypes;
                if (!Test.isRunningTest()) {
                    recordTypes = (MetadataService.RecordType[])service.readMetadata('RecordType',new List<String>{caseRecordTypeLabelList[0]}).getRecords();
                } else {
                   ProcessMetadataRequestsBatch P=new ProcessMetadataRequestsBatch();
                   recordTypes= p.createMockRecordTypes();
                }
                
                if(recordTypes.size()>0){
                    MetadataService.RecordTypePicklistValue fieldRelatedPicklistValues = new MetadataService.RecordTypePicklistValue();
                    fieldRelatedPicklistValues.picklist = 'Abra_Tags__c';
                    system.debug(LoggingLevel.DEBUG, 'fieldRelatedPicklistValues -> '+fieldRelatedPicklistValues);
                    List<MetadataService.RecordTypePicklistValue> listFieldRelatedPicklistValues = new List<MetadataService.RecordTypePicklistValue>();
                    List<MetadataService.PicklistValue> picklistValues = new List<MetadataService.PicklistValue>();
                    
                    // Retrieve existing picklist values
                    List<MetadataService.PicklistValue> existingPicklistValues = new List<MetadataService.PicklistValue>();
                    if (!Test.isRunningTest() && recordTypes.size() > 0 && recordTypes[0].PicklistValues != null && recordTypes[0].PicklistValues.size() > 0) {
                        for (MetadataService.RecordTypePicklistValue existingValue : recordTypes[0].PicklistValues) {
                            if (existingValue.picklist == 'Abra_Tags__c') {
                                existingPicklistValues.addAll(existingValue.values);
                                break;
                            }
                        }
                    }
                    
                    
                    for(String newValue:recordTypeToNewLabelValues.get(recordTypes[0].FullName)){
                        MetadataService.PicklistValue pk = new MetadataService.PicklistValue();
                        pk.fullName =newValue ;
                        pk.isActive = true;
                        pk.default_x = false;
                        picklistValues.add(pk);
                    }
                    existingPicklistValues.addAll(picklistValues);
                    fieldRelatedPicklistValues.values = existingPicklistValues;
                    listFieldRelatedPicklistValues.add(fieldRelatedPicklistValues);
                    recordTypes[0].PicklistValues = listFieldRelatedPicklistValues;
                   
                    
                    MetadataService.Metadata[] listMetadata = new List<MetadataService.Metadata>();
                    listMetadata.addAll(recordTypes);
                    system.debug(LoggingLevel.DEBUG, 'listMetadata -> '+listMetadata);
                    if(listMetadata.size()>0){
                        List<MetadataService.SaveResult> results = service.updateMetadata(listMetadata);   
                    }
                    if(recordTypeToNewLabelValues.size()>0){
                        recordTypeToNewLabelValues.remove(caseRecordTypeLabelList[0]);
                    }
                }
            }
            catch(Exception e){
                System.debug(LoggingLevel.DEBUG, 'Exception==> '+e.getMessage());
            }
        }
        // ----- CS21-2810: Add Abra Tags options to the record types -----
        if(recordTypeToNewValues.size()>0 || recordTypeToNewLabelValues.size()>0){
            System.enqueueJob(new UpdateRecordTypeQueueable(recordTypeToNewValues, recordTypeToNewLabelValues)); 
        }
    }
}