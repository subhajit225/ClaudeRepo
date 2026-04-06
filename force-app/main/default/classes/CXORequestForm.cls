/**
 * @description Apex controller for cxoRequestForm Lightning Web Component 
 * @createdDate July 2025
 */
public without sharing class CXORequestForm {

    /**
     * @description Get form data
     * @return Response DTO with data/error
     */
    @AuraEnabled
    public static Response getFormData() {
        try {
            FormDTO formDTO = new FormDTO();
            formDTO.fieldToOptionWrapperLstMap = getPicklistValues();
            return new Response(true, 'Success!', formDTO);
        } catch(Exception ex) {
            return new Response(false, 'Something went wrong, please contact your administrator.'+ex.getMessage(), ex);
        }
    }
        
    /**
	 * @description Create a cve Engagement record on application submit
     * @param cveEngagementJsonStr - JSON string with Cve Engagement details
     * @param selectedOppsStr
     * @param valueEconomicsScopeVal
     * @return Response DTO with data/error
	 */
    @AuraEnabled
    public static Response createCveEngagementRecord(String cveEngagementJsonStr, String selectedOppsStr, List<String> valueEconomicsScopeVal) {
        if(String.isBlank(cveEngagementJsonStr)) {
            return new Response(false, 'Unexpected null argument: cveEngagementJsonStr', null);
        }
        try {          
            
            //Deserialize selected opp string to Id and Name object
            List<RecordData> oppDataLst = new List<RecordData>();
            if(String.isNotBlank(selectedOppsStr)){
                oppDataLst = (List<RecordData>)JSON.deserialize(selectedOppsStr, List<RecordData>.class);
            }
            //Deserialize CVE Engagement data string to CVE_Engagement object
            CVE_Engagement__c cveEngagement = (CVE_Engagement__c)JSON.deserialize(cveEngagementJsonStr, CVE_Engagement__c.class);
            //Assign multi-select picklist selected values
            cveEngagement.Value_Economics_Scope__c = valueEconomicsScopeVal != null && !valueEconomicsScopeVal.isEmpty() ? String.join(valueEconomicsScopeVal, ';') : null;
            INSERT cveEngagement;
 
            List<CVE_Opportunity_Contact__c> cveOppsLst = new List<CVE_Opportunity_Contact__c>();
            String urls;
            
            //Create CVE_Opportunity_Contact records based on selectedOppsStr/oppDataLst
            for(RecordData opp : oppDataLst){
                cveOppsLst.add(new CVE_Opportunity_Contact__c(CVE_Engagement__c = cveEngagement.Id, Opportunity__c = opp.Id));
                //Prepare url for each (oppId) Opp record to store as Rich text on CVE_Engagement record
                String url = getSFBaseURL()+'/'+opp.Id;
                if(String.isBlank(urls)){
                    urls = '<a href="' + url + '">' + opp.Name + '</a>';
                } else {
                    urls = urls +','+ '<a href="' + url + '">' + opp.Name + '</a>';
                }
            }
            
            if(!cveOppsLst.isEmpty()){
                INSERT cveOppsLst;
            }
            
            if(String.isNotBlank(urls)){
                cveEngagement.Opportunity__c = urls;
                UPDATE cveEngagement;
            }
            
            return new Response(true, 'Application Submitted Successfully!', cveEngagement);
        } catch(Exception ex) {
            return new Response(false, 'Something went wrong please contact your administrator.'+ex.getMessage(), ex);
        }
    }
    
   /**
    * @description get records based on search keyword
    * @param ObjectName
    * @param fieldName
    * @param value
    * @param selectedRecId
    * @param currentRecordId
    * @return List<sObject>
    */ 
    @AuraEnabled(cacheable=true)
    public static Response retriveSearchData(String ObjectName, String fieldName, String value, List<String> selectedRecId, String currentRecordId) {
        
        if(String.isBlank(ObjectName) || String.isBlank(fieldName)){
            return new Response(false, 'Opps, Object Name or Field Name is missing!', null);
        }
        
        List<sObject> sObjectResultList = new List<sObject>();
        if(selectedRecId == null)
            selectedRecId = new List<String>();
        
        try {
            if(String.isNotEmpty(value)) {
                String salesRT = OpportunityUtil.oppRecTypeIdSalesOpp;
                String query = 'SELECT '+String.escapeSingleQuotes(fieldName.trim())+' FROM '+String.escapeSingleQuotes(ObjectName.trim())+' WHERE Name LIKE \'%' + String.escapeSingleQuotes(value.trim()) + '%\' AND IsClosed = false AND ID NOT IN: selectedRecId'+
                    ' AND AccountId =:currentRecordId AND RecordTypeId = :salesRT AND Opportunity_Type__c != \'Debooking\' AND Opportunity_Split_Parent__c = null'+
                    ' ORDER BY createdDate DESC LIMIT 5';
                for(sObject so : Database.Query(query)) {
                    sObjectResultList.add(so);
                }
            }
            
        } catch(Exception ex){
            return new Response(false, 'Something went wrong please contact your administrator.'+ex.getMessage(), ex);
        }
        
        return new Response(true, 'Success!', sObjectResultList);
    }
    
    /**
     * @description get picklist values for field provided
     * @return Map<String, List<OptionsWrapper>>
     */ 
    private static Map<String, List<OptionsWrapper>> getPicklistValues() {
        Map<String, List<OptionsWrapper>> fieldToOptionWrapperLstMap = new Map<String, List<OptionsWrapper>>();
        Set<String> fieldAPINames = new Set<String>{'Value_Economics_Scope__c',
            'Will_the_EB_sponsor_this__c', 'X3_Why_s_Presented__c', 'Architectural_Workshop_Executed__c', 'Org_Chart_or_Account_Planning_Document__c'};
        Map<String, Schema.SobjectField> fieldMap = Schema.getGlobalDescribe().get('CVE_Engagement__c').getDescribe().fields.getMap();
        List<OptionsWrapper> OptionsWrapperLst = new List<OptionsWrapper>();
        
        for(String fieldAPIName : fieldAPINames) {
            OptionsWrapperLst = new List<OptionsWrapper>();
            for(Schema.PicklistEntry picklistEntry : getPicklistValues('CVE_Engagement__c', fieldAPIName)) {
                if(picklistEntry.isActive()) {
                    OptionsWrapperLst.add(new OptionsWrapper(picklistEntry.getLabel(), picklistEntry.getValue()));
                }
            }
            fieldToOptionWrapperLstMap.put(fieldAPIName, OptionsWrapperLst);
        }            
        return fieldToOptionWrapperLstMap;
    }
    
     /**
	 * @description Get picklist field entries
	 * @param objName
	 * @param fieldName
     * @return List<Schema.PicklistEntry>
	 */
    private static List<Schema.PicklistEntry> getPicklistValues(String objName, String fieldName) {
        List<String> labels = new List<String>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        return ple;
    }
    
    /**
     * @description get Salesforce base URL
     * @return String
     */ 
    public static String getSFBaseURL(){
         return URL.getOrgDomainURL().toExternalForm();
    }   
    
    /**
     * @description RecordData wrapper with Id and Name properties
     */ 
    private class RecordData {
        String Id;
        String Name;
    }
    
    /**
     * @description Form DTO with Field Name and picklist options
     */ 
    private class FormDTO {
        @AuraEnabled public Map<String, List<OptionsWrapper>> fieldToOptionWrapperLstMap;
    }

    /**
     * @description Picklist Option Wrapper
     */ 
     private class OptionsWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        /**
         * @description wrapper constructor
         * @param label
         * @param value
         */
        public OptionsWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
     /**
      * @description Response DTO with success/error message and data
      */ 
     public class Response{
        @AuraEnabled public Boolean Success;
        @AuraEnabled public String Message;
        @AuraEnabled public Object Data;
        /**
         * @description wrapper constructor
         * @param Success
         * @param Message
         * @param Data
         */
        public Response(Boolean Success, String Message, Object Data){
            this.Success = Success;
            this.Message = Message;
            this.Data = Data;
        }
    }        
}