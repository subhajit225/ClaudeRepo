/*******************************************************************************************************
* @author Rubrik
* @date 2018
* @description Partner Community - Distributors page components controller.
*******************************************************************************************************/
public without sharing class PC_SalesDistributorsController {

        /*******************************************************************************************************
* @description Returns User record
* @param N/A
* @return the Distributors List
***********************************************************************************************************/
    @AuraEnabled
    public Static List<Contract> getDistributorsList(string accountName, string country){
        
        List<Contract> lstAccounts = new List<Contract>();
        List<String> wheres = new List<String>();
        string accType = 'Distributor';
        string agreementStatus = 'Signed - Active';
        string agreementType = 'Distributor';
        string contractStatus = 'Active';
        
        String query = 'SELECT ID,Territory_Country__c,Agreement_Type__c,Contract_Status__c,Account.Name,Account.BillingCountry FROM Contract WHERE Contract_Status__c =:contractStatus AND Agreement_Type__c =:agreementType AND Account.Partner_Agreement_Status__c=:agreementStatus AND Account.Type=:accType';

        //String query = 'SELECT Id, Name, BillingCountry, BillingCountryCode, Territory__c FROM Account where Partner_Agreement_Status__c=:agreementStatus and Type=:accType';
        
        if(String.isNotBlank(accountName)) {
            wheres.add('Account.Name LIKE \'%' + String.escapeSingleQuotes(accountName.trim()) + '%\'');
        }
        if(String.isNotBlank(country)) {
            wheres.add('Territory_Country__c INCLUDES (\'' + String.escapeSingleQuotes(country.trim())+ '\')');
        }
        /*if(String.isNotBlank(territory)) {
            wheres.add('Territory__c includes( \'' + String.escapeSingleQuotes(territory.trim())+ '\')');
        }*/
        
        if(!wheres.isEmpty()) {
            query += ' AND ( ' + String.join(wheres, ' AND ') + ')';
        }
        
        query += ' Order by Account.BillingCountry';
        system.debug('query*****'+query);
        
        lstAccounts = Database.query(query);
        return lstAccounts;
    }
    
    /*******************************************************************************************************
* @description To get the picklist values
* @param 
* @return the Country options.
***********************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> getCountryOptions() {
        Map<String,String> allOpts = new Map<String,String>();
                                     
       /* Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> fieldMap = gd.get(objectName.toLowerCase()).getDescribe().fields.getMap(); 
        */
        
        Schema.sObjectType objType = Account.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Get the list of picklist values for this field.
        list < Schema.PicklistEntry > values = fieldMap.get('BillingCountryCode').getDescribe().getPickListValues();
        
        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a: values) {
            //allOpts.add(a.getValue());
            allOpts.put(a.getValue(),a.getLabel());
        }
        system.debug('allOpts ---->' + allOpts);
        //allOpts.sort();
        return allOpts;
    }
    
        /*******************************************************************************************************
* @description To get the picklist values
* @param 
* @return the Country options.
***********************************************************************************************************/
    /*@AuraEnabled
    public static Map<String,String> getTerritoryOptions() {
        Map<String,String> allOpts = new Map<String,String>();*/
                                     
       /* Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> fieldMap = gd.get(objectName.toLowerCase()).getDescribe().fields.getMap(); 
        */
        
        /*Schema.sObjectType objType = Account.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Get the list of picklist values for this field.
        list < Schema.PicklistEntry > values = fieldMap.get('Territory__c').getDescribe().getPickListValues();
        
        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a: values) {
            //allOpts.add(a.getValue());
            allOpts.put(a.getValue(),a.getLabel());
        }
        system.debug('allOpts ---->' + allOpts);
        //allOpts.sort();
        return allOpts;
    }*/
}