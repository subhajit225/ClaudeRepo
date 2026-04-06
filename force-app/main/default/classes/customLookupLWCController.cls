public without sharing class customLookupLWCController {
    @AuraEnabled
    public static List<Object> getRecordsByName(String objectName, String searchFor, String recordTypeName, String emailDomain, String accId, Boolean mspRestrictedFlag, String accIdNotIn, List<String> accTypes) {
        String whiteSpaceUserId = System.Label.whiteSpaceAccountUserId;
        String queryString;
        String tbhUser1 = 'TBH%';
        String tbhUser2 = '%TBH';
        String dnaUser = 'Do Not Assign Placeholder';
        if(objectName.equalsIgnoreCase('Contact')){
            queryString = 'SELECT Id, Name, Title, Email, AccountId, Phone FROM ';
        }else if(objectName.equalsIgnoreCase('Account') || objectName.equalsIgnoreCase('User')){
            queryString = 'SELECT Id, Name FROM ';
        }
        
        queryString += String.escapeSingleQuotes(objectName) + ' WHERE Name Like \'%' + String.escapeSingleQuotes(searchFor) + '%\'';
        if(objectName.equalsIgnoreCase('Account')){
            queryString = queryString+' AND OwnerId != :whiteSpaceUserId';
        }
        //prit26-5-start
        if(objectName.equalsIgnoreCase('Account') && mspRestrictedFlag != null){
            queryString = queryString+' AND MSP_Restricted__c = :mspRestrictedFlag';
        }
        if(objectName.equalsIgnoreCase('Account') && accIdNotIn != null){
            queryString = queryString+' AND Id != :accIdNotIn';
        }
        if(objectName.equalsIgnoreCase('Account') && !accTypes.isEmpty() ){
            queryString = queryString+' AND Type IN :accTypes';
        }
        //prit26-5-end
        if(objectName.equalsIgnoreCase('Account') && recordTypeName != null && recordTypeName.equalsIgnoreCase('Partner/Distributor')) {
            queryString = queryString+' AND RecordType.Name = :recordTypeName';
            //PRIT24-435-start
            if(emailDomain != null && emailDomain != ''){
                if(emailDomain.countMatches('.') >= 2){
                    emailDomain = emailDomain.substring(0, emailDomain.lastIndexOfIgnoreCase('.'));
                } 
                queryString = queryString+' AND Website Like \'%' + String.escapeSingleQuotes(emailDomain) + '%\'';
            }
            //PRIT24-435-end
        }
        if(objectName.equalsIgnoreCase('Account') && recordTypeName != null && recordTypeName.equalsIgnoreCase('Customer/Prospect')) {
            queryString = queryString+' AND RecordType.Name = :recordTypeName AND Account.Owner.IsActive = TRUE AND ETM_Territory__c!= null AND (NOT Owner.Name LIKE :tbhUser1) AND (NOT Owner.Name LIKE :tbhUser2) AND Owner.Name != :dnaUser LIMIT 100';
        }
        if(objectName.equalsIgnoreCase('User')){
         	queryString = queryString+' AND ContactId = null';
        }
        if(objectName.equalsIgnoreCase('Contact') && accId != null && accId != ''){
            queryString = queryString+' AND AccountId =: accId';
        }
        return Database.query(queryString);
    }
    @AuraEnabled
    public static sObject fetchDefaultRecord(string recordId , string objectName) {
        string sRecId = recordId;    
        string sQuery = 'Select Id,Name From ' + objectName + ' Where Id = : sRecId LIMIT 1';
        for (sObject obj: database.query(sQuery)) {
            return obj;
        } 
        return null;
    }
    @AuraEnabled
    public static List<sObject> fetchDetailedRecords(String recordId, String searchTxt, String country, String objectName, String recordTypeName, String fields) {
        String whiteSpaceUserId = System.Label.whiteSpaceAccountUserId;
        String tbhUser1 = 'TBH%';
        String tbhUser2 = '%TBH';
        String dnaUser = 'Do Not Assign Placeholder';
        String sQuery = 'Select {0} FROM {1} WHERE Account.Owner.IsActive = TRUE AND RecordType.Name = :recordTypeName AND OwnerId != :whiteSpaceUserId AND ETM_Territory__c!= null AND (NOT Owner.Name LIKE :tbhUser1) AND (NOT Owner.Name LIKE :tbhUser2) AND Owner.Name != :dnaUser';
        if(!String.isEmpty(searchTxt)){
            sQuery = sQuery + ' AND Name Like \'%' + String.escapeSingleQuotes(searchTxt) + '%\'';
        }
        if(!String.isEmpty(country)){
            sQuery = sQuery + ' AND BillingCountry =: country';
        }
        if(!String.isEmpty(recordId)){
            sQuery = sQuery + ' AND Id =:recordId';
        }
        sQuery = String.format(sQuery, new List<String>{fields,objectName});
        system.debug(sQuery);
        return Database.query(sQuery);
    }
}