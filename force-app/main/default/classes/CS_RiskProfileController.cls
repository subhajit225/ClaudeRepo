/**
 * @author Sushant Arora
 * @date 2024-11-19
 * @description 
 * This controller class provides methods to handle CRUD operations and 
 * manage Risk Profile records and related objects. It is designed for 
 * use with Lightning Aura or LWC components to handle client-side actions.
 * RRR-110 - Updated code to replace PDM feature with Bundle Component Allocation
 * @TestClass - CS_RiskProfileControllerTest
 */
public class CS_RiskProfileController {
	public class CS_RiskProfileController_Exception extends Exception {}

    /**
     * @description Fetches the Product Pillar information for a list of Component Feature IDs.
     * @param entitlementIds A list of entitlement Ids to get the Pillar info from Product level if it is a standalone Product by checking Bundle_Features__c
     * @param componentIds A list of Component Feature record IDs.
     * @return prodPillarList A list of Bundle Component Allocation records with pillar details.
     * @throws AuraHandledException If any error occurs during SOQL execution.
     */
    @AuraEnabled(cacheable=true)
    public static PillarInfoWrapper getProductPillarInformation(String[] entitlementIds, String[] componentIds){
        PillarInfoWrapper pillarInfoResult = new PillarInfoWrapper();
        pillarInfoResult.pillarInfoList = new List<ProductPillarWrapper>();
        pillarInfoResult.hasComponent = false;
        List<ProductPillarWrapper> prodPillarList= new List<ProductPillarWrapper>();    
        try {
            List<sObject> compAndEntList = new List<sObject>();
            List<AggregateResult> agrResult = [SELECT Count(Id) FROM Bundle_Components_Allocation__c WHERE Product_Name__c IN (SELECT Product__c FROM Entitlement WHERE Id=:entitlementIds) AND Component_Status__c = 'Current'];
            if(agrResult!=null && (Integer)agrResult[0].get('expr0') > 0) pillarInfoResult.hasComponent = true;
            List<sObject> compList = [SELECT Product_Pillar_1_Component__c, Product_Pillar_2_Component__c, Product_Name__c,Product_Name__r.Product_Pillar_1_Component__c,
                                                                 Product_Name__r.Product_Pillar_2_Component__c,Product_Name__r.Bundle_Features__c FROM Bundle_Components_Allocation__c  
                                                                 WHERE Id IN :componentIds AND Product_Name__r.Bundle_Features__c!='' WITH USER_MODE];
            if(!compList.isEmpty()) compAndEntList.addAll(compList);
            List<sObject> entList = [SELECT Id,Product__c,Product__r.Product_Pillar_1_Component__c,Product__r.Product_Pillar_2_Component__c,Product__r.Bundle_Features__c FROM Entitlement 
                                    WHERE Product__r.Bundle_Features__c='' AND Id IN:entitlementIds WITH USER_MODE];
            if(!entList.isEmpty()) compAndEntList.addAll(entList);
            if(compAndEntList.isEmpty()) return pillarInfoResult;

            for(sObject sobj : compAndEntList){
                String objectName = String.valueOf(sobj.getSObjectType().getDescribe().getName());
                ProductPillarWrapper prodPillarInfo = new ProductPillarWrapper();
                sObject currentObj = objectName == 'Entitlement' ? sobj.getSObject('Product__r') : sobj;
                prodPillarInfo.pillar1 = currentObj!=null ? String.valueOf(currentObj.get('Product_Pillar_1_Component__c')) : '';
                prodPillarInfo.pillar2 = currentObj!=null ? String.valueOf(currentObj.get('Product_Pillar_2_Component__c')) : '';
                prodPillarList.add(prodPillarInfo);
            }
            pillarInfoResult.pillarInfoList = prodPillarList;

            return pillarInfoResult;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Updates Risk Profile records dynamically based on provided data.
     * @param objects List of maps containing field-value pairs and object metadata.
     * @return Response Object containing the IDs of successfully updated records or an error message.
     * @throws DMLException If any DML operation fails.
     * @throws Exception For general exceptions.
     */
	@AuraEnabled
    public static Response updateRiskProfile(List<Map<String, Object>> objects){
        Response response = new Response();
        
        try {
            List<Id> succcesfullRecords = crud(objects);
            response.data = succcesfullRecords;
        }
        catch(DMLException dmlEx){
            response.error = dmlEx.getDmlMessage(0);
        }
        catch (Exception e) {
             response.error = e.getMessage();
        }
        return response;

    }

    /**
     * @description Creates a new Risk Profile record and its related objects.
     * @param objects List of maps containing field-value pairs for Risk Profile and related objects.
     * @return Response Object containing the newly created Risk Profile record or an error message.
     * @throws DMLException If any DML operation fails.
     * @throws Exception For general exceptions.
     */
    @AuraEnabled
    public static Response createRiskProfile(List<Map<String, Object>> objects){
        Response response = new Response();
        try {
            List<Map<String, Object>> riskProfiles = new List<Map<String, Object>>();
            List<Map<String, Object>> pdmFeatures = new List<Map<String, Object>>();
            List<Map<String, Object>> riskProfileWatcher = new List<Map<String, Object>>();

            for(Map<String, Object> mObject : (List<Map<String, Object>>) objects){
                if(mObject.get('objectApiName') == 'Risk_Profile__c') {
                    riskProfiles.add(mObject);
                }
            }

            List<Id> riskProfileIds = crud(riskProfiles);
            for(Map<String, Object> mObject : (List<Map<String, Object>>) objects){
                String objectApiName = String.valueOf(mObject.get('objectApiName'));
                if(objectApiName == 'Risk_Profile_Entitlement__c' || objectApiName == 'Risk_Profile_Component__c' || objectApiName == 'Risk_Profile_Watcher__c') {
                    mObject.put('Risk_Profile__c',riskProfileIds[0]);
                    pdmFeatures.add(mObject);
                }
            }
            Risk_Profile__c riskProfile = [SELECT Id,Name FROM Risk_Profile__c WHERE Id = :riskProfileIds[0]];
            crud(pdmFeatures);
            
            response.data = riskProfile;
        } 
        catch(DMLException dmlEx){
            response.error = dmlEx.getDmlMessage(0);
        }
        catch (Exception e) {
             response.error = e.getMessage();
        }        
        return response;
    }

    /**
     * @description Handles generic CRUD operations for Salesforce objects.
     * @param fieldValueMapList List of maps containing object metadata and field-value pairs.
     * @return List<Id> A list of IDs of successfully processed records.
     * @throws CS_RiskProfileController_Exception If an invalid object or field API name is provided.
     * @throws DMLException If any DML operation fails.
     * @throws Exception For general exceptions.
     */
	public static List<Id> crud(List<Map<String, Object>> fieldValueMapList) {
        List<SObject> recordsToInsert = new List<SObject>();
        List<SObject> recordsToUpdate = new List<SObject>();
        List<SObject> recordsToDelete = new List<SObject>();
        List<Id> successfullRecordIds = new List<Id>();

        try {           

            for (Map<String, Object> fieldValueMap : fieldValueMapList) {
                String objectApiName = (String)fieldValueMap.get('objectApiName');
                fieldValueMap.remove('objectApiName');
                String operation =  (String)fieldValueMap.get('Operation');fieldValueMap.remove('Operation'); 
                Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);

                if (sObjectType == null) {
                    throw new CS_RiskProfileController_Exception('Invalid Object API Name: ' + objectApiName);
                }

                SObject record = sObjectType.newSObject(null, false);

                for (String fieldName : fieldValueMap.keySet()) {
                    if (sObjectType.getDescribe().fields.getMap().containsKey(fieldName)) {
                        Schema.DisplayType type = sObjectType
                                                    .getDescribe()
                                                    .fields
                                                    .getMap()
                                                    .get(fieldName)
                                                    .getDescribe()
                                                    .getType();
                        record.put(fieldName, parseValue(fieldValueMap.get(fieldName), type));
                    } else {
                        
                        throw new CS_RiskProfileController_Exception('Invalid Field API Name: ' + fieldName + ' for Object: ' + objectApiName);
                    }
                }

                switch on operation {
                    when 'Create' {
                        recordsToInsert.add(record);
                    }
                    when 'Update'{
                        recordsToUpdate.add(record);
                        
                    }
                    when 'Delete'{
                        recordsToDelete.add(record);
                    }
                }

                
            }
            if (!recordsToInsert.isEmpty()) {
                insert as system recordsToInsert;
                successfullRecordIds.addAll((new Map<Id,Sobject>(recordsToInsert)).Keyset());
            }
            if (!recordsToUpdate.isEmpty()) {
                update as system recordsToUpdate;
                successfullRecordIds.addAll((new Map<Id,Sobject>(recordsToUpdate)).Keyset());
				
            }
            if (!recordsToDelete.isEmpty()) {
                delete as system recordsToDelete;
                successfullRecordIds.addAll((new Map<Id,Sobject>(recordsToDelete)).Keyset());
				
            }
        }
        /*
        catch(DMLException dmlEx){
            throw dmlEx;
        }*/
        catch (DmlException dmlEx) {
            for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
                System.debug(LoggingLevel.DEBUG,'❌ DML Error on record: ' + dmlEx.getDmlId(i));
                System.debug(LoggingLevel.DEBUG,'👉 Operation: ' + dmlEx.getDmlType(i));
                System.debug(LoggingLevel.DEBUG,'⚠️ Error Message: ' + dmlEx.getDmlMessage(i));
                System.debug(LoggingLevel.DEBUG,'🔎 Fields: ' + dmlEx.getDmlFields(i));
            }
            throw dmlEx; // still rethrow if you want caller to handle
        }

        catch (Exception e) {            
            throw e;
        }

        return successfullRecordIds;
    }

    /**
     * @description Inner class to standardize the response structure for Aura/LWC actions.
     */
	public class Response {
        /**
        * @description Response data
        */
       @AuraEnabled public Object data{get;set;}
       /**
        * @description Error if any
        */
       @AuraEnabled public String error{get;set;} 
    }

    /**
     * @description Parses a field value based on its Salesforce field type.
     * @param objValue The value to be parsed.
     * @param displayType The Salesforce field type (Schema.DisplayType).
     * @return Object Parsed value compatible with the field type.
     */
    public static Object parseValue(Object objValue, Schema.DisplayType displayType) {
        if(objValue == null){
            return null;
        }
        String stringValue = String.valueOf(objValue).trim();
        switch on displayType {
            when Integer {
                return Integer.valueOf(stringValue);
            }
            when Double {
                return Double.valueOf(stringValue);
            }
            when Boolean {
                return Boolean.valueOf(stringValue);
            }
            when Date {
                return Date.valueOf(stringValue);
            }
            when DateTime {
                return DateTime.valueOf(stringValue);
            }
            when Currency {
                return Decimal.valueOf(String.valueOf(stringValue));
            }
            when Percent {
                return Decimal.valueOf(String.valueOf(stringValue)); 
            }            	
            when REFERENCE,String,TextArea,Url,Phone,Id,Email,Picklist,Location,MultiPicklist {
                return stringValue;
            }
            when else {
                return stringValue;
            }

        }
    }
    /**
     * @description Inner class to get the Pillar info from Product if Component is standalone.
     */
    public class ProductPillarWrapper{
        /**
        * @description Pillar 1 information from Bundle Component
        */
        @AuraEnabled public String pillar1 {get;set;}
        /**
        * @description Pillar 2 information from Bundle Component
        */
        @AuraEnabled public String pillar2 {get;set;}
    }

    /**
    * @description Pillar Info and check for component availability
    */
    public class PillarInfoWrapper{
        /**
        * @description Product Pillar List
        */
        @AuraEnabled public List<ProductPillarWrapper> pillarInfoList {get;set;}
        /**
        * @description check for component existance with selected Entitlement
        */
        @AuraEnabled public Boolean hasComponent {get;set;}
    }
}