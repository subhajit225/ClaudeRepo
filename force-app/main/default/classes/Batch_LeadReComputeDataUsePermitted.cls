/**
 * @name - Batch_LeadReComputeDataUsePermitted
 * @description - Batch class to update Re_compute_Data_Use_Permitted__c to True for specific Lead records based on the Filter Criteria.
 */
public class Batch_LeadReComputeDataUsePermitted implements Database.Batchable<sObject>, Database.Stateful {
    
    private List<String> leadSources; // private variable to store the list of LeadSource to filter the Lead records
    private List<String> countryCodes; // private variable to store the list of CountryCode to filter the Lead records
    
    /**
     * @description - Constructor to bring the list of LeadSource and list of CountryCode from the User
     * @param leadSources - contains the list of LeadSource provided by the User
     * @param countryCodes - contains the list of CountryCode provided by the User
     */
    public Batch_LeadReComputeDataUsePermitted(List<String> leadSources, List<String> countryCodes) {
        this.leadSources = (leadSources == null) ? new List<String>() : leadSources;
        this.countryCodes = (countryCodes == null) ? new List<String>() : countryCodes;
    }

    
    /**
     * @description - Start method to retrieve all specified Leads which are from the provided Lead Sources or in the listed Country Codes.
     * @param bc Database.BatchableContext - the batch context
     * @return Database.QueryLocator - query locator for Lead records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String baseQuery = 'SELECT Id, Re_compute_Data_Use_Permitted__c, LeadSource, CountryCode FROM Lead';
        
        List<String> conditions = new List<String>();
        Boolean hasLeadSources = leadSources != null && !leadSources.isEmpty();
        Boolean hasCountryCodes = countryCodes != null && !countryCodes.isEmpty();
        
        // when both the parameters are provided
        if (hasLeadSources && hasCountryCodes) {
            conditions.add('LeadSource IN :leadSources');
            conditions.add('CountryCode IN :countryCodes');
        }
        // only LeadSource is provided
        else if (hasLeadSources) {
            conditions.add('LeadSource IN :leadSources');
        }
        // only CountryCode is provided
        else if (hasCountryCodes) {
            conditions.add('CountryCode IN :countryCodes');
        }
        
        if (!conditions.isEmpty()) {
            baseQuery += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        return Database.getQueryLocator(baseQuery);
    }

    
    /**
     * @description - Execute method to update Re_compute_Data_Use_Permitted__c to true for re computing the Data Use Permitted.
     * @param bc Database.BatchableContext - the batch context
     * @param scope List<Lead> - scope of Lead records for this execution
     */
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead l : scope) {
            l.Re_compute_Data_Use_Permitted__c = true;
            leadsToUpdate.add(l);
        }
        if (!leadsToUpdate.isEmpty()) {
            Database.update(leadsToUpdate, false);
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