/**
 * @author Sushant Arora
 * @date 2024-01-31
 * @description Class to fetch the fields from the fieldsets
 * @TestClass - CS_CustomFieldControllerTest
 */

/**
 * @description Retrieves the name of the field set based on the provided operation and object API name.
 * @param operation The operation (e.g., "New", "Edit") for which the field set name is retrieved.
 * @param obj The API name of the object for which the field set name is retrieved.
 * @return String The name of the field set for the specified operation and object API name.
 */
public with sharing class CS_CustomFieldController {
    private static string getFieldSetName(String operation,String obj) {
        
        List<Fieldset_Retrieval__mdt> csh = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, SystemModstamp, FieldSet_Name__c, Object__c
                       FROM Fieldset_Retrieval__mdt WHERE Object__c = :obj WITH SECURITY_ENFORCED];
        String mdt = '';
        switch on operation {
            when 'New' {
                mdt = 'New';
            }
            when 'Edit' {
                mdt = 'Edit';
            }
            when else {
                mdt = operation;
            }
        }
        for (Fieldset_Retrieval__mdt record : csh) {
            if (record.DeveloperName == mdt) {
                return record.FieldSet_Name__c;
            }
        }
        return '';
    
      // return csh.containsKey(mdt) ? csh.get(mdt).FieldSet_Name__c : '';
    }
 /**
 * @description Retrieves the field names of a specified object based on the provided operation and object API name.
 * @param objectApiName The API name of the object for which field names are retrieved.
 * @param operation The operation (e.g., "create", "edit") for which field names are retrieved.
 * @return List<String> A list of field names for the specified object and operation.
 * @AuraEnabled(cacheable=true) Enables client-side caching for improved performance.
 * @throws AuraHandledException if the object or field set is not found, or if an error occurs during processing.
 */
    @AuraEnabled(cacheable = true)
    public static List<String> getFieldNames(String objectApiName, String operation) {
        List<String> fieldNames = new List<String> ();
        String fieldSetName = getFieldSetName(operation,objectApiName);
        try {
            // Retrieve the describe information for the specified object
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();

            // Retrieve the field set based on the provided field set name
            Schema.FieldSet fieldSet = objectDescribe.FieldSets.getMap().get(fieldSetName);

            // If the field set is not null, iterate over its fields and add their names to the list
            if (fieldSet != null) {
                for (Schema.FieldSetMember field: fieldSet.getFields()) {
                    fieldNames.add(field.getFieldPath());
                }
            } else {
                // If the field set is null, throw an exception indicating that the field set was not found
                throw new AuraHandledException('Script-thrown exception');
            }
        } catch (NullPointerException e) {
            // Catch NullPointerException if the object or field set is not found
            throw new AuraHandledException('Object ' + objectApiName + ' or Field Set ' + fieldSetName + ' not found.');
        } catch (Exception e) {
            // Catch any other exceptions and log the error message
            throw new AuraHandledException('Error fetching field names: ' + e.getMessage());
        }
        return fieldNames;
    }
}