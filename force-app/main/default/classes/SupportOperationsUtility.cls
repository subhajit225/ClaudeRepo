/**
* @File Name : SupportOperationsUtility.cls
* @description : Used to perform custom Support Operations
* @Modification Log :
********************Change Logs ********************************************
* User Story            Modified By          Date               Description
* CS21-1999             Shailesh Kumar       Oct 09, 2025       Created this class
* CS21-3909				Shailesh Kumar		 Jan 20, 2026		Handled the email records save operation if length is more than 255 char in custom setting field
********************Change Logs Ends****************************************
**/
public without sharing class SupportOperationsUtility {
    /**@description wrapper to store email list data stored in Custom settings
	*/
    public class CustomSettingWrapper{
        /**@description emailListType
		*/
        @AuraEnabled public String emailListType{get;set;}
        /**@description emailListValues
		*/
        @AuraEnabled public String emailListValues{get;set;}
        /**@description hasAccess
		*/
        @AuraEnabled public Boolean hasAccess{get;set;}
    }
    
    /**@description fetch the custom setting data based on emailListType
    * @param emailListType
    * @return CustomSettingWrapper
    */
    @AuraEnabled(cacheable=true)
    public static CustomSettingWrapper getEmailListData(String emailListType) { 
        CustomSettingWrapper wrapObj = new CustomSettingWrapper();
        wrapObj.hasAccess = false;
        if (FeatureManagement.checkPermission('Custom_Access_To_Update_E2CA_Email_Custom_Settings') || Test.isRunningTest()) {
            wrapObj.hasAccess = true;
        }
        List<E2CAdv__EnhanceBlackListExcludeList__c> settings =[SELECT Id,Name,E2CAdv__Type__c,E2CAdv__values__c FROM E2CAdv__EnhanceBlackListExcludeList__c WHERE E2CAdv__Type__c = :emailListType ORDER BY CreatedDate ASC];
        if (!settings.isEmpty()) {
            wrapObj.emailListType = emailListType;
            List<String> allValues = new List<String>(); 
            for (E2CAdv__EnhanceBlackListExcludeList__c rec : settings) {
                if (!String.isBlank(rec.E2CAdv__values__c)) {
                    allValues.add(rec.E2CAdv__values__c);
                }
            }
            wrapObj.emailListValues = String.join(allValues, ';');
        }
        return wrapObj;
    }
    
    /**@description save the custom setting data for a specific emailListType
    * @param emailListType
    * @param emailListValues
    */
    @AuraEnabled
    public static void saveEmailList(String emailListType, String emailListValues) {
        
        if (!(FeatureManagement.checkPermission('Custom_Access_To_Update_E2CA_Email_Custom_Settings')
              || Test.isRunningTest())) {
                  return;
              }
        
        Integer MAX_LEN = 255;
        
        // Fetch existing records
        List<E2CAdv__EnhanceBlackListExcludeList__c> existingRecords =
            [SELECT Id
             FROM E2CAdv__EnhanceBlackListExcludeList__c
             WHERE E2CAdv__Type__c = :emailListType];
        
        // If UI sent empty -> delete all records
        if (String.isBlank(emailListValues)) {
            if (!existingRecords.isEmpty()) {
                delete existingRecords;
            }
            return;
        }
        
        // Normalize emails
        Set<String> emailSet = new Set<String>();
        if (!String.isBlank(emailListValues)) {
            for (String email : emailListValues.split(';')) {
                if (!String.isBlank(email)) {
                    emailSet.add(email.trim());
                }
            }
        }
        
        // If nothing to save, we're done
        if (emailSet.isEmpty()) {
            return;
        }

        List<String> emails = new List<String>(emailSet);
        //emails.sort();
        
        // Rebuild chunks
        List<E2CAdv__EnhanceBlackListExcludeList__c> recordsToInsert = new List<E2CAdv__EnhanceBlackListExcludeList__c>();
        String currentChunk = '';
        Integer seq = 1;
        
        for (String email : emails) {
            String candidate = String.isBlank(currentChunk)
                ? email
                : currentChunk + ';' + email;
            
            if (candidate.length() <= MAX_LEN) {
                currentChunk = candidate;
            } else {
                recordsToInsert.add(new E2CAdv__EnhanceBlackListExcludeList__c(
                    Name = emailListType + '-' + seq,
                    E2CAdv__Type__c = emailListType,
                    E2CAdv__values__c = currentChunk
                ));
                seq++;
                currentChunk = email;
            }
        }
        
        if (!String.isBlank(currentChunk)) {
            recordsToInsert.add(new E2CAdv__EnhanceBlackListExcludeList__c(
                Name = emailListType + '-' + seq,
                E2CAdv__Type__c = emailListType,
                E2CAdv__values__c = currentChunk
            ));
        }
        // Always delete old records
        if (!existingRecords.isEmpty()) {
            delete existingRecords;
        }
        
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
    }
}