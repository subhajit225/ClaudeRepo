/**
 * @author Sushant Arora
 * @date 2024-11-19
 * @description  A utility class for cross-object field synchronization using custom metadata mappings.
 * This class supports both synchronous and asynchronous execution of field synchronization.
 * @TestClass - CS_CrossObjectFieldSyncMappingTest
 */
public class CS_CrossObjectFieldSyncMapping {

    public String syncName;
    public Set<Id> sourceRecordIds;
    @TestVisible private static List<Cross_Object_Fields_Sync_Mapping__mdt> testMockFieldMappings = new List<Cross_Object_Fields_Sync_Mapping__mdt>();
    private List<Cross_Object_Fields_Sync_Mapping__mdt> fieldMappings;
    private List<SObject> sourceRecords;
    private List<SObject> targetRecordsToUpdate;
    private Map<String, String> sourceToTargetFieldMapping = new Map<String, String>();
    private List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();
    /**
     * @description Constructor to initialize the sync process with a sync name.
     * @param syncName Name of the synchronization process.
     */
    public CS_CrossObjectFieldSyncMapping(String syncName) {
        this.syncName = syncName;
    }

    /**
     * @description Sets the IDs of source records to be processed.
     * @param sourceRecordIds Set of source record IDs.
     * @return CS_CrossObjectFieldSyncMapping The current instance for method chaining.
     */
    public CS_CrossObjectFieldSyncMapping setSourceRecordIds(Set<Id> sourceRecordIds) {
        this.sourceRecordIds = sourceRecordIds;
        return this;
    }

    /**
     * @description Executes the synchronization process with optional additional filters.
     * @param additionalFilters Map of additional filters for the source query.
     * @return String The status of the synchronization process.
     */
    public String executeSync(Map<String, String> additionalFilters) {
        return this
            .validateInput()
            .fetchFieldMappings()
            .fetchSourceRecords(additionalFilters)
            .mapFieldsToTargetRecords()
            .updateTargetRecords();
    }

    /**
     * @description Validates input parameters such as sync name and source record IDs.
     * @return CS_CrossObjectFieldSyncMapping The current instance for method chaining.
     */
    private CS_CrossObjectFieldSyncMapping validateInput() {
        if (String.isBlank(syncName) || sourceRecordIds == null || sourceRecordIds.isEmpty()) {
            errorLogs.add(getErrorLog('Invalid input parameters ' + syncName, 'validateInput'));
        }
        return this;
    }

    /**
     * @description Fetches field mappings from custom metadata based on the sync name and source object type.
     * @return CS_CrossObjectFieldSyncMapping The current instance for method chaining.
     */
    private CS_CrossObjectFieldSyncMapping fetchFieldMappings() {
        String sourceObjectName = sourceRecordIds.iterator().next().getSObjectType().getDescribe().getName();
        fieldMappings = [
            SELECT Destination_FieldAPIName__c, Destination_Object__c, Source_FieldAPIName__c, 
            Source_Object__c, Destination_Object_Id_Field__c 
            FROM Cross_Object_Fields_Sync_Mapping__mdt 
            WHERE Sync_Name__c = :syncName AND Source_Object__c = :sourceObjectName
        ];
        if(Test.isRunningTest()){
            fieldMappings = testMockFieldMappings;
        }
        
        if (fieldMappings.isEmpty()) {
            errorLogs.add(getErrorLog('No field mappings found', 'fetchFieldMappings'));
        }
        return this;
    }

    /**
     * @description Constructs a SOQL query to fetch source records with additional filters.
     * @param additionalFilters Map of additional filters for the query.
     * @return String The constructed SOQL query.
     */
    private String buildSourceQuery(Map<String, String> additionalFilters) {
        if(!errorLogs.isEmpty()){
            return '';
        }
        String sourceObjectName = fieldMappings[0].Source_Object__c;
        String parentFieldAPI = fieldMappings[0].Destination_Object_Id_Field__c;
        String parentRelationshipAPI = parentFieldAPI.endsWith('__c') ? parentFieldAPI.replace('__c', '__r') : parentFieldAPI;
        Set<String> fieldsToQuery = new Set<String>();
        fieldsToQuery.add('Id');
        fieldsToQuery.add(parentFieldAPI);
        for (Cross_Object_Fields_Sync_Mapping__mdt mapping : fieldMappings) {
            fieldsToQuery.add(mapping.Source_FieldAPIName__c);
            fieldsToQuery.add(parentRelationshipAPI + '.' + mapping.Destination_FieldAPIName__c);
            sourceToTargetFieldMapping.put(mapping.Source_FieldAPIName__c, mapping.Destination_FieldAPIName__c);
        }
        String fieldsQueryPart = String.join(new List<String>(fieldsToQuery), ', ');
        String sourceQuery = 'SELECT ' + fieldsQueryPart + ' FROM ' + sourceObjectName + ' WHERE Id IN :sourceRecordIds';
        if (additionalFilters != null && !additionalFilters.isEmpty()) {
            for (String field : additionalFilters.keySet()) {
                String value = additionalFilters.get(field);
                sourceQuery += ' AND ' + field + ' = \'' + String.escapeSingleQuotes(value) + '\'';
            }
        }
        
        return sourceQuery;
    }

    /**
     * @description Fetches source records based on the constructed query.
     * @param additionalFilters Map of additional filters for the query.
     * @return CS_CrossObjectFieldSyncMapping The current instance for method chaining.
     */
    private CS_CrossObjectFieldSyncMapping fetchSourceRecords(Map<String, String> additionalFilters) {
        if(!errorLogs.isEmpty()){
            return this;
        }
        String sourceQuery = buildSourceQuery(additionalFilters);
        sourceRecords = Database.query(sourceQuery);
        if (sourceRecords.isEmpty()) {
            errorLogs.add(getErrorLog('No source records found', 'fetchSourceRecords'));
        }
        return this;
    }

    /**
     * @description Maps fields from source records to target records and identifies changes.
     * @return CS_CrossObjectFieldSyncMapping The current instance for method chaining.
     */
    private CS_CrossObjectFieldSyncMapping mapFieldsToTargetRecords() {
        if(!errorLogs.isEmpty()){
            return this;
        }
        targetRecordsToUpdate = new List<SObject>();
        String targetObjectName = fieldMappings[0].Destination_Object__c;
        for (SObject sourceRecord : sourceRecords) {
                String parentFieldAPI = fieldMappings[0].Destination_Object_Id_Field__c;
                String parentRelationshipAPI = parentFieldAPI.endsWith('__c') ? parentFieldAPI.replace('__c', '__r') : parentFieldAPI;
            
            SObject targetRecord = (SObject)sourceRecord.getSObject(parentRelationshipAPI);
            if (targetRecord == null) {
                continue;
            }
            
            Boolean changeInFields = false;
            for (Cross_Object_Fields_Sync_Mapping__mdt mapping : fieldMappings) {
                String sourceFieldAPIName = mapping.Source_FieldAPIName__c;
                String destinationFieldAPIName = mapping.Destination_FieldAPIName__c;                
        
                if(sourceRecord.get(sourceFieldAPIName) != targetRecord.get(destinationFieldAPIName)){
                    changeInFields = true;
                    targetRecord.put(destinationFieldAPIName, sourceRecord.get(sourceFieldAPIName));
                }
            }
            if(changeInFields){
                targetRecordsToUpdate.add(targetRecord);
            }            
        }
        return this;
    }

    /**
     * @description Updates the target records and returns the status of the operation.
     * @return String Status of the update operation.
     */
    private String updateTargetRecords() {
        if(!errorLogs.isEmpty()){
            //insert errorLogs;
            return 'Nothing to update';
        }
        if (!targetRecordsToUpdate.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(targetRecordsToUpdate, false);
            List<String> errorMessages = new List<String>();
            for (Database.SaveResult result : saveResults) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        errorMessages.add('Error updating record ID ' + result.getId() + ': ' + error.getMessage());
                    }
                }
            }
            if (!errorMessages.isEmpty()) {
                return 'Failed to update some records. Errors: ' + String.join(errorMessages, '; ');
            }
            return 'Success';
        }
        return 'Nothing to update';
    }

    /**
     * @description Executes the synchronization process either synchronously or asynchronously.
     * @param mappingInstance The mapping instance for execution.
     * @param additionalFilters Additional filters for the source query.
     */
    public static void execute(CS_CrossObjectFieldSyncMapping mappingInstance, Map<String, String> additionalFilters) {
        if (System.isFuture()) {
            mappingInstance.executeSync(additionalFilters);
        } else {
            executeAsync(mappingInstance.syncName, mappingInstance.sourceRecordIds, additionalFilters);
        }
    }

    /**
     * @description Asynchronous execution of the synchronization process.
     * @param syncName The name of the synchronization process.
     * @param sourceRecordIds Set of source record IDs.
     * @param additionalFilters Additional filters for the source query.
     */
    @future
    private static void executeAsync(String syncName, Set<Id> sourceRecordIds, Map<String, String> additionalFilters) {
        CS_CrossObjectFieldSyncMapping mappingInstance = new CS_CrossObjectFieldSyncMapping(syncName)
            .setSourceRecordIds(sourceRecordIds);
        mappingInstance.executeSync(additionalFilters);
    }

    /**
     * @description Generate error log object
     * @param message Error message
     * @param method Method that triggered the Error
     * @return Error_Logs__c Error Log object
     */
    private Error_Logs__c getErrorLog(String message, String method){
        return new Error_Logs__c(Object__c = 'Cross_Object_Fields_Sync_Mapping__mdt',
                                Error_Message__c = message,
                                Class__c = 'CS_CrossObjectFieldSyncMapping',
                                Method__c = method,
                                Type__c = 'SFDC',
                                Success__c = false);
    }
}