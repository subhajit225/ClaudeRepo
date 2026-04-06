/**
 * @name - Batch_ContactReComputeDataUsePermitted
 * @description - Batch class to update Re_compute_Data_Use_Permitted__c to True for specific Contact records based on the Filter Criteria.
 */
public class Batch_ContactReComputeDataUsePermitted implements Database.Batchable<sObject>, Database.Stateful {
    
    private List<String> leadSources; // private variable to store the list of LeadSource to filter the Contact records
    private List<String> countryCodes; // private variable to store the list of CountryCode to filter the Contact records
    
    /**
     * @description - Constructor to bring the list of LeadSource and list of CountryCode from the User
     * @param leadSources - contains the list of LeadSource provided by the User
     * @param countryCodes - contains the list of CountryCode provided by the User
     */
    public Batch_ContactReComputeDataUsePermitted(List<String> leadSources, List<String> countryCodes) {
        this.leadSources = (leadSources == null) ? new List<String>() : leadSources;
        this.countryCodes = (countryCodes == null) ? new List<String>() : countryCodes;
    }
    
    /**
     * @description - Start method to retrieve all specified Contacts which are from the provided Lead Sources or in the listed Country Codes.
     * @param bc Database.BatchableContext - the batch context
     * @return Database.QueryLocator - query locator for Lead records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String baseQuery = 'SELECT Id, Re_compute_Data_Use_Permitted__c, LeadSource, MailingCountryCode FROM Contact';
        
        List<String> conditions = new List<String>();
        Boolean hasLeadSources = leadSources != null && !leadSources.isEmpty();
        Boolean hasMailingCountryCodes = countryCodes != null && !countryCodes.isEmpty();
        
        // when both the parameters are provided
        if (hasLeadSources && hasMailingCountryCodes) {
            conditions.add('LeadSource IN :leadSources');
            conditions.add('MailingCountryCode IN :countryCodes');
        }
        // only LeadSource is provided
        else if (hasLeadSources) {
            conditions.add('LeadSource IN :leadSources');
        }
        // only MailingCountryCode is provided
        else if (hasMailingCountryCodes) {
            conditions.add('MailingCountryCode IN :countryCodes');
        }
        
        if (!conditions.isEmpty()) {
            baseQuery += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        return Database.getQueryLocator(baseQuery);
    }
    
    /**
     * @description - Execute method to update Re_compute_Data_Use_Permitted__c to true for re computing the Data Use Permitted.
     * @param bc Database.BatchableContext - the batch context
     * @param scope List<Contact> - scope of Contact records for this execution
     */
    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact l : scope) {
            l.Re_compute_Data_Use_Permitted__c = true;
            contactsToUpdate.add(l);
        }
        if (!contactsToUpdate.isEmpty()) {
            Database.update(contactsToUpdate, false);
        }
    }
    
    /**
     * @description - Finish method for post-processing
     * @param bc Database.BatchableContext - the batch context
     */
    public void finish(Database.BatchableContext bc) {
        //no post processing required for this batch operation.
    }

}