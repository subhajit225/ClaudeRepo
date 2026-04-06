public with sharing class MQLRoutingService {
    Set<Id> recordIds;
    String objectName;
    Map<String, String> metadataToObjectFields;
    List<Lead_Routing_Rule__mdt> allRules ;

    public MQLRoutingService(Set<Id> recordIds, String objectName) {
        this.recordIds = recordIds;
        this.objectName = objectName;
        this.metadataToObjectFields = new Map<String, String>();
        String labelName = 'MQL Routing Rules-'+objectName;
        for(Key_Value__mdt keyValuePair: [SELECT Key__c, Value__c FROM Key_Value__mdt WHERE MasterLabel = :labelName]){
            metadataToObjectFields.put(keyValuePair.Key__c, keyValuePair.Value__c); //key --> api name of the field on custom metadata, value --> api name on the object
        }
    }
    public List<Lead_Routing_Rule__mdt> getAllRules() {
        return getRoutingRules(this.objectName);
    }

    public Map<Id, Lead_Routing_Rule__mdt> stampRulesOnRecords(List<Lead_Routing_Rule__mdt> ruleSet){
        /*List<Lead_Routing_Rule__mdt> routingRules = this.getRoutingRules(this.objectName);
        String sObjectQuery = this.buildQuery();
        List<SObject> recordsToAssign = getQueryResults(sObjectQuery);*/
        
        Map<Id, Lead_Routing_Rule__mdt> recordsWithRules = applyRoutingRules(ruleSet);
        return recordsWithRules;  
    }
    
    //returns all the rules applicable for the object in the order of priority
    private List<Lead_Routing_Rule__mdt> getRoutingRules(String objectName){
        /*String query = 'SELECT MasterLabel, Priority__c,DeveloperName,ObjectName__c,Routing_Source__c,User_Role_Field_Value__c,Fallback_Source__c,Fallback__c,';
        List<String> lstStrings = new List<String>();
        for(String fieldName : metadataToObjectFields.keySet()){
            lstStrings.add( fieldName );
        }
        query = query + String.join(lstStrings,',') + ' FROM Lead_Routing_Rule__mdt WHERE ObjectName__c = :objectName OR ObjectName__c = \'Both\' ORDER BY Priority__c ASC';*/
        String query = getRoutingRulesQuery(objectName);
        query += ' ORDER BY Priority__c ASC';
        List<Lead_Routing_Rule__mdt> queryAllMQLRoutingRules = Database.query(query);
        this.allRules = queryAllMQLRoutingRules;
        return queryAllMQLRoutingRules;
    }
    public String getRoutingRulesQuery(String objectName){
        String query = 'SELECT MasterLabel, Priority__c,DeveloperName,ObjectName__c,Routing_Source__c,User_Role_Field_Value__c,Fallback_Source__c,Fallback__c,';
        List<String> lstStrings = new List<String>();
        for(String fieldName : metadataToObjectFields.keySet()){
            lstStrings.add( fieldName );
        }
        query = query + String.join(lstStrings,',') + ' FROM Lead_Routing_Rule__mdt WHERE (ObjectName__c = :objectName OR ObjectName__c = \'Both\')';
        return query;
    }

    //Builds the query to retrieve all the fields from Sobject
    private String buildQuery(){
        String query = 'SELECT Id';
        if( objectName == 'contact' ) {
            query = query + ',accountid';
        } else {
            query = query + ',winning_l2a_account__c';
        }
        for(String objectField : metadataToObjectFields.values()){
            query = query+','+objectField;
        }
        query+= (' FROM '+ objectName +' WHERE Id IN :recordIds FOR UPDATE');

        return query;
    }

    //TODO: Princy- implement
    private List<SObject> getQueryResults(String query){
        return Database.query(query);
    }

    public Map<Id, Lead_Routing_Rule__mdt>  applyRoutingRules(List<Lead_Routing_Rule__mdt> ruleSet){
        
        /*List<Lead_Routing_Rule__mdt> lstRules = getRoutingRules(this.objectName);
        this.allRules = lstRules;*/
        List<sObject> records = getQueryResults( buildQuery() );
        List<Lead> lstLeadsToUpdate = new List<Lead>();
        system.debug('records ::: ' + records);
        Map<Id, Lead_Routing_Rule__mdt> mapLeadIdToMDt = new Map<Id, Lead_Routing_Rule__mdt>();
        for( sObject sObj : records ) {
            for( Lead_Routing_Rule__mdt objRule : ruleSet ) {
                if( objRule.ObjectName__c == this.objectName || objRule.ObjectName__c == 'Both' ) {
                    system.debug('Current Rule-----------------------' + objRule.DeveloperName);
                    Boolean isRuleMatch = true;
                    for( String key : metadataToObjectFields.keySet()) {
                        if( objRule.get(key) != null) {
                            system.debug('Rule key::::' + key);
                            system.debug('Target Value::::' + metadataToObjectFields.get( key ));
                            isRuleMatch = objRule.get(key) ==  sObj.get(metadataToObjectFields.get( key ));//validateFieldMatch( key, metadataToObjectFields.get( key ), sObj, objRule );
                            system.debug('Rule Result::::' + isRuleMatch);
                            if( !isRuleMatch ) {
                                break;
                            }
                        }
                    }
                    if( isRuleMatch ) {
                        //system.debug('Rule Matched:::::' + objRule);
                        //if(String.valueOf(sObj.get('Valid_Routing_Method__c')) != 'Next Rule' ) {
                            mapLeadIdToMDt.put( sObj.Id, objRule );
                            break;
                        //}
                    }
                }
            }
        }
        return mapLeadIdToMDt;
    }

    private void assignOwners(Map<Id, Lead_Routing_Rule__mdt> recordIdToRule){

    }

}