/**
* @description Batch Job to recalculate and Update Inactive accounts for Planhat Import process.
*			   JIRA - CS21-608
*
* @CreatedDate 16th July 2021
* @Created By Veera Gandi
* 
* @Test Class RecalculatePlanhatImportBatchTest
*/
public class RecalculateInactivePlanhatImportBatch implements Database.Batchable<sObject> {
    public String query;
    
    /**
    * @description Constructor to assign initial values for Planhat Account recalculation
    * 			   query fetches accounts with "IsPlanhatImport__c" as true, but after recalculation
    * 			   should be updated to false
    */
    public RecalculateInactivePlanhatImportBatch(){        
        
        query = 'SELECT id,FedRAMP__c,IsPlanhatImport__c,IsPaidCustomerActiveMaintenance__c,IsPaidCustomerInactiveMaintenance__c ,IsSignedPartnerResellerDistributor__c,IsActivePOCEvaluationAccount__c,'; 
        query += 'Account_Preference__c From Account WHERE  IsPlanhatImport__c = true'; 
    }
    
    /**
    * @description start method runs at the beginning of a batch Apex job which collects the records or objects to pass to the execute method. 
    * @param  BatchableContext - Database.BatchableContext
    * @return Database.QueryLocator - List of Accounts
    */
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description execute method is called for each batch of records that you pass to it
    * @param  BatchableContext - Database.BatchableContext
    * @param  accounts - List of Accounts
    * @return void
    */
    public void execute(Database.BatchableContext batchableContext, List<Account> accounts){
        
        List<Account> activeAccounts = new List<Account>();
        set<ID> accountWithClosedWonOpportunities=new  set<ID>();
        Integer shipmentDelayByDays=Integer.valueof(System.Label.Days_for_Opportunity_Close_Date);
        Date sixtyDaysBeforeDate=System.today()-shipmentDelayByDays;
        
        for(Opportunity eachOpportunity:[Select Id, CloseDate,AccountID from Opportunity WHERE accountID IN :accounts AND stageName='7 Closed Won' AND closeDate>:sixtyDaysBeforeDate]){
            
            accountWithClosedWonOpportunities.add(eachOpportunity.AccountID);
            
        }
        
        for (Account eachAccount : accounts) {
            if(!accountWithClosedWonOpportunities.contains(eachAccount.id) && !eachAccount.IsPaidCustomerActiveMaintenance__c && !eachAccount.IsPaidCustomerInactiveMaintenance__c && !eachAccount.IsSignedPartnerResellerDistributor__c && !eachAccount.IsActivePOCEvaluationAccount__c && (eachAccount.Account_Preference__c==NULL || eachAccount.Account_Preference__c=='')){
                activeAccounts.add(new Account(id=eachAccount.id,IsPlanhatImport__c = !eachAccount.IsPlanhatImport__c));
            }else if((accountWithClosedWonOpportunities.contains(eachAccount.id) || eachAccount.IsPaidCustomerActiveMaintenance__c || eachAccount.IsPaidCustomerInactiveMaintenance__c || eachAccount.IsSignedPartnerResellerDistributor__c || eachAccount.IsActivePOCEvaluationAccount__c || eachAccount.Account_Preference__c!=NULL || eachAccount.Account_Preference__c!='') && eachAccount.FedRAMP__c){
                activeAccounts.add(new Account(id=eachAccount.id,IsPlanhatImport__c = !eachAccount.IsPlanhatImport__c)); 
            }
        }
        
        
        if (!activeAccounts.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.update(activeAccounts, false);
            
            //log errors
            for (Database.SaveResult result : saveResults) {
                if (!result.isSuccess()) {
                    System.debug('Error Occured ::' + JSON.serialize(result.getErrors()));
                }
            }
        }
    }
    
    /**
    * @description finish is to execute post-processing operations
    * @param  batchableContext - Database.BatchableContext
    * @return void
    */
    public void finish(Database.BatchableContext batchableContext){
		System.debug(LoggingLevel.DEBUG, 'Planhat Account Recalculation Jobs Completed Sucessfully!');
    }
}