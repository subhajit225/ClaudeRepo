/**
 * @description Generic service class for object-to-object field mapping using custom metadata
 * Handles metadata access, field transformations, and dynamic query building
 * Uses Object_Mapping_Configuration__mdt and Object_Field_Mapping__mdt
 * @author Salesforce
 * @date 2026-01-26
 */
public with sharing class ObjectMappingService {
    
    /**
     * @description Cache for mapping configurations to avoid repeated SOQL queries
     */
    private static Map<String, Object_Mapping_Configuration__mdt> configCache = new Map<String, Object_Mapping_Configuration__mdt>();

    /**
     * @description Cache for field mappings to avoid repeated SOQL queries
     */
    private static Map<String, List<Object_Field_Mapping__mdt>> fieldMappingCache = new Map<String, List<Object_Field_Mapping__mdt>>();
    
    /**
     * @description Maps source records to target records using generic metadata configuration
     * @param configName DeveloperName of Object_Mapping_Configuration__mdt record
     * @param sourceRecords List of source SObject records
     * @return List<SObject> List of mapped target records (not inserted)
     */
    public static List<SObject> mapRecords(String configName, List<SObject> sourceRecords) {
        List<SObject> targetRecords = new List<SObject>();
        
        if (sourceRecords == null || sourceRecords.isEmpty()) {
            return targetRecords;
        }
        
        Object_Mapping_Configuration__mdt config = getConfiguration(configName);
        if (config == null || !config.Active__c) {
            throw new MappingException('Mapping configuration "' + configName + '" not found or inactive');
        }
        
        List<Object_Field_Mapping__mdt> fieldMappings = getFieldMappings(configName);
        
        for (SObject sourceRecord : sourceRecords) {
            SObject targetRecord = mapSingleRecord(sourceRecord, config, fieldMappings);
            targetRecords.add(targetRecord);
        }
        
        return targetRecords;
    }
    
    /**
     * @description Maps a single source record to target record
     * @param sourceRecord Source SObject record
     * @param config Mapping configuration
     * @param fieldMappings List of field mappings
     * @return SObject Mapped target record
     */
    private static SObject mapSingleRecord(SObject sourceRecord, Object_Mapping_Configuration__mdt config, 
                                           List<Object_Field_Mapping__mdt> fieldMappings) {
        // Create target record
        SObject targetRecord = createTargetRecord(config.Target_Object_API_Name__c);
        
        // Set default values (e.g., IsActive for Campaign)
        setDefaultValues(targetRecord, config);
        
        // Apply field mappings
        applyFieldMappings(sourceRecord, targetRecord, fieldMappings, config);
        
        // Apply custom business logic
        applyCustomLogic(sourceRecord, targetRecord, config);
        
        return targetRecord;
    }
    
    /**
     * @description Builds dynamic SOQL query with only required fields
     * @param configName DeveloperName of Object_Mapping_Configuration__mdt record
     * @param recordIds Set of source record IDs
     * @return String SOQL query string
     */
    public static String buildDynamicQuery(String configName, Set<Id> recordIds) {
        Object_Mapping_Configuration__mdt config = getConfiguration(configName);
        Set<String> fields = getRequiredSourceFields(configName);
        
        return 'SELECT ' + String.join(new List<String>(fields), ', ') + 
               ' FROM ' + config.Source_Object_API_Name__c + 
               ' WHERE Id IN :recordIds';
    }
    
    /**
     * @description Gets required source fields for a mapping configuration
     * Includes fields from direct mappings and formula expressions
     * @param configName DeveloperName of Object_Mapping_Configuration__mdt record
     * @return Set<String> Set of source field API names
     */
    public static Set<String> getRequiredSourceFields(String configName) {
        Set<String> fields = new Set<String>{'Id'};

        List<Object_Field_Mapping__mdt> fieldMappings = getFieldMappings(configName);
        for (Object_Field_Mapping__mdt mapping : fieldMappings) {
            if (!mapping.Active__c) {
                continue;
            }

            // Add direct source field
            if (String.isNotBlank(mapping.Source_Field__c)) {
                fields.add(mapping.Source_Field__c);
            }

            // Extract fields from formula expressions
            if (mapping.Transformation_Type__c == 'FORMULA' && String.isNotBlank(mapping.Formula_Expression__c)) {
                fields.addAll(extractFieldsFromFormula(mapping.Formula_Expression__c));
            }
        }

        return fields;
    }

    /**
     * @description Extracts field references from a formula expression
     * @param formula Formula expression containing {!FieldName} references
     * @return Set<String> Set of field API names referenced in the formula
     */
    private static Set<String> extractFieldsFromFormula(String formula) {
        Set<String> fields = new Set<String>();
        Pattern fieldPattern = Pattern.compile('\\{!([a-zA-Z0-9_]+)\\}');
        Matcher fieldMatcher = fieldPattern.matcher(formula);

        while (fieldMatcher.find()) {
            fields.add(fieldMatcher.group(1));
        }

        return fields;
    }
    
    // ========= PRIVATE HELPER METHODS =========
    
    /**
     * @description Gets mapping configuration from cache or database
     * @param configName DeveloperName of Object_Mapping_Configuration__mdt record
     * @return Object_Mapping_Configuration__mdt Mapping configuration record or null if not found
     */
    private static Object_Mapping_Configuration__mdt getConfiguration(String configName) {
        if (!configCache.containsKey(configName)) {
            List<Object_Mapping_Configuration__mdt> configs = [
                SELECT Id, MasterLabel, DeveloperName, Source_Object_API_Name__c, Target_Object_API_Name__c,
                       Active__c, Description__c, Handler_Class__c, Create_Target_Record__c
                FROM Object_Mapping_Configuration__mdt
                WHERE DeveloperName = :configName
                LIMIT 1
            ];
            configCache.put(configName, configs.isEmpty() ? null : configs[0]);
        }
        return configCache.get(configName);
    }
    
    /**
     * @description Gets field mappings from cache or database
     * @param configName DeveloperName of Object_Mapping_Configuration__mdt record
     * @return List<Object_Field_Mapping__mdt> List of active field mappings ordered by Order__c
     */
    private static List<Object_Field_Mapping__mdt> getFieldMappings(String configName) {
        if (!fieldMappingCache.containsKey(configName)) {
            fieldMappingCache.put(configName, [
                SELECT Id, MasterLabel, DeveloperName, Mapping_Configuration__r.DeveloperName,
                       Source_Field__c, Target_Field__c, Source_Field_Value__c, Target_Field_Value__c,
                       Transformation_Type__c, Formula_Expression__c, Active__c, Order__c
                FROM Object_Field_Mapping__mdt
                WHERE Mapping_Configuration__r.DeveloperName = :configName
                  AND Active__c = true
                ORDER BY Order__c NULLS LAST, DeveloperName
            ]);
        }
        return fieldMappingCache.get(configName);
    }

    /**
     * @description Creates a new target record instance using Schema token
     * @param objectApiName API name of the target SObject
     * @return SObject New instance of the target SObject
     */
    private static SObject createTargetRecord(String objectApiName) {
        Schema.SObjectType sObjectType = Schema.describeSObjects(new List<String>{objectApiName})[0].getSObjectType();
        return sObjectType.newSObject();
    }

    /**
     * @description Sets default values on target record
     * @param targetRecord Target SObject to set default values on
     * @param config Mapping configuration containing target object information
     */
    private static void setDefaultValues(SObject targetRecord, Object_Mapping_Configuration__mdt config) {
        // Set IsActive = true for Campaign objects
        if (config.Target_Object_API_Name__c == 'Campaign') {
            targetRecord.put('IsActive', true);
        }
    }

    /**
     * @description Applies field mappings from source to target record
     * @param sourceRecord Source SObject to read values from
     * @param targetRecord Target SObject to write values to
     * @param fieldMappings List of field mapping configurations
     * @param config Mapping configuration containing object information
     */
    private static void applyFieldMappings(SObject sourceRecord, SObject targetRecord,
                                           List<Object_Field_Mapping__mdt> fieldMappings,
                                           Object_Mapping_Configuration__mdt config) {
        for (Object_Field_Mapping__mdt mapping : fieldMappings) {
            Object valueToSet = null;

            switch on mapping.Transformation_Type__c {
                when 'NONE' {
                    // Direct field copy
                    if (String.isNotBlank(mapping.Source_Field__c)) {
                        valueToSet = sourceRecord.get(mapping.Source_Field__c);
                    }
                }
                when 'CONSTANT' {
                    // Set constant value
                    if (String.isNotBlank(mapping.Target_Field_Value__c)) {
                        Schema.DisplayType fieldType = getFieldType(config.Target_Object_API_Name__c, mapping.Target_Field__c);
                        valueToSet = parseConstantValue(mapping.Target_Field_Value__c, fieldType);
                    }
                }
                when 'PICKLIST' {
                    // Picklist value mapping
                    if (String.isNotBlank(mapping.Source_Field__c) && String.isNotBlank(mapping.Source_Field_Value__c)) {
                        Object sourceValue = sourceRecord.get(mapping.Source_Field__c);
                        if (mapping.Source_Field_Value__c.equals(String.valueOf(sourceValue))) {
                            valueToSet = mapping.Target_Field_Value__c;
                        }
                    }
                }
                when 'FORMULA' {
                    // Evaluate formula expression
                    if (String.isNotBlank(mapping.Formula_Expression__c)) {
                        valueToSet = evaluateFormula(mapping.Formula_Expression__c, sourceRecord);
                    }
                }
            }

            if (valueToSet != null && String.isNotBlank(mapping.Target_Field__c)) {
                targetRecord.put(mapping.Target_Field__c, valueToSet);
            }
        }
    }

    /**
     * @description Applies custom business logic based on source/target objects
     * NOTE: Most custom logic should be moved to FORMULA type mappings in metadata
     * This method is reserved for complex logic that cannot be expressed in formulas
     * @param sourceRecord Source SObject to read values from
     * @param targetRecord Target SObject to write values to
     * @param config Mapping configuration containing object information
     */
    private static void applyCustomLogic(SObject sourceRecord, SObject targetRecord, Object_Mapping_Configuration__mdt config) {
        // Reserved for complex custom logic that cannot be handled by formulas
        // Example: Multi-object lookups, DML operations, external callouts, etc.

        // PFR to Campaign specific logic has been moved to FORMULA mappings in metadata
        // See Object_Field_Mapping__mdt record: PFR_to_Campaign_Routing_Method
        System.debug(logginglevel.DEBUG,'This method is reserved for complex logic that cannot be expressed in formulas');
    }

    /**
     * @description Gets the field type for a specific object field using Schema token
     * @param objectApiName API name of the SObject
     * @param fieldApiName API name of the field
     * @return Schema.DisplayType Field type or null if not found
     */
    private static Schema.DisplayType getFieldType(String objectApiName, String fieldApiName) {
        Schema.SObjectType sObjectType = Schema.describeSObjects(new List<String>{objectApiName})[0].getSObjectType();
        Schema.DescribeFieldResult fieldDescribe = sObjectType.getDescribe()
            ?.fields
            ?.getMap()
            ?.get(fieldApiName)
            ?.getDescribe();
        return fieldDescribe?.getType();
    }

    /**
     * @description Parses a constant value based on field type
     * @param value String value to parse
     * @param fieldType Target field type for parsing
     * @return Object Parsed value in the appropriate type
     */
    private static Object parseConstantValue(String value, Schema.DisplayType fieldType) {
        if (value == null || fieldType == null) {
            return value;
        }

        switch on fieldType {
            when BOOLEAN {
                return value.toLowerCase() == 'true';
            }
            when DATE {
                return Date.valueOf(value);
            }
            when DATETIME {
                return Datetime.valueOf(value);
            }
            when CURRENCY, DOUBLE, PERCENT {
                return Decimal.valueOf(value);
            }
            when INTEGER {
                return Integer.valueOf(value);
            }
            when else {
                return value;
            }
        }
    }

    /**
     * @description Evaluates a formula expression using Salesforce's FormulaEval API
     * Supports standard Salesforce formula syntax with field references
     * @param formulaExpression Formula expression to evaluate (e.g., "IF(ISBLANK({!ETM_Role__c}), {!Routing_Method__c}, 'MQL to ETM')")
     * @param sourceRecord Source record to evaluate formula against
     * @return Object Evaluated result
     */
    private static Object evaluateFormula(String formulaExpression, SObject sourceRecord) {
        if (String.isBlank(formulaExpression)) {
            return null;
        }

        try {
            // Get the SObject type from the source record
            Schema.SObjectType sObjectType = sourceRecord.getSObjectType();

            // Build and evaluate the formula using Salesforce's FormulaEval API
            FormulaEval.FormulaInstance formulaInstance = Formula.builder()
                .withType(sObjectType)
                .withReturnType(FormulaEval.FormulaReturnType.STRING)
                .withFormula(formulaExpression)
                .build();

            // Evaluate the formula with the source record
            Object result = formulaInstance.evaluate(sourceRecord);

            return result;
        } catch (Exception e) {
            throw new MappingException('Formula evaluation failed: ' + e.getMessage() +
                                     '\nFormula: ' + formulaExpression);
        }
    }

    // ========= EXCEPTION CLASS =========

    /**
     * @description Custom exception class for mapping-related errors
     */
    public class MappingException extends Exception {}
}