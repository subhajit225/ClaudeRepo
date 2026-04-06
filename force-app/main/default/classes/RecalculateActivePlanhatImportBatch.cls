/**
* @description Batch Job to recalculate and update active accounts for Planhat Import process.
*			   JIRA - CS21-608
*
* @CreatedDate 16th July 2021
* @Created By Veera Gandi
* @Modified by Ashish 20th April 2022
* @Test Class RecalculatePlanhatImportBatchTest
*/
public class RecalculateActivePlanhatImportBatch implements Database.Batchable<sObject>, Schedulable {
    public String query;

    /**
    * @description Constructor to assign initial values for Planhat Account recalculation
    * 			   query fetches accounts with "IsPlanhatImport__c" as false, but after recalculation
    * 			   should be updated to true.
    * @Modification Added as per the Jira ticket CS21-271 on 6th April 2022 and CS21-1082 on 20th April 2022, If either one of the condition comes to true then the IsPlanhatImport__c should be flagged
    */
    public RecalculateActivePlanhatImportBatch(){       
        query = 'SELECT id,IsPlanhatImport__c,IsPaidCustomerActiveMaintenance__c,IsPaidCustomerInactiveMaintenance__c ,IsSignedPartnerResellerDistributor__c,IsActivePOCEvaluationAccount__c,'; 
        query += 'Account_Preference__c From Account WHERE  IsPlanhatImport__c = false AND FedRAMP__c=false';  
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
        Map<Id,Integer> accountWithClosedWonOpportunities=new Map<Id,Integer>();
        Integer shipmentDelayByDays=Integer.valueof(System.Label.Days_for_Opportunity_Close_Date);
		Date sixtyDaysBeforeDate=System.today()-shipmentDelayByDays;
        for(Opportunity eachOpportunity:[Select Id, CloseDate,AccountID from Opportunity WHERE accountID IN :accounts AND stageName='7 Closed Won' AND closeDate>:sixtyDaysBeforeDate]){
            if(accountWithClosedWonOpportunities.containsKey(eachOpportunity.AccountID)){
                integer activeOpportunityCount=accountWithClosedWonOpportunities.get(eachOpportunity.AccountID);
                activeOpportunityCount=activeOpportunityCount+1;
                accountWithClosedWonOpportunities.put(eachOpportunity.AccountID,activeOpportunityCount);
            }else{
                accountWithClosedWonOpportunities.put(eachOpportunity.AccountID,1);
            }  
        }
        
        for (Account eachAccount : accounts) {
            if((eachAccount.IsPaidCustomerActiveMaintenance__c || 
                eachAccount.IsPaidCustomerInactiveMaintenance__c || 
                eachAccount.IsSignedPartnerResellerDistributor__c || 
                eachAccount.IsActivePOCEvaluationAccount__c || 
                (eachAccount.Account_Preference__c!=NULL && eachAccount.Account_Preference__c!='')) 
               || 
               (!accountWithClosedWonOpportunities.isEmpty() && 
                accountWithClosedWonOpportunities.containsKey(eachAccount.id) &&
                accountWithClosedWonOpportunities.get(eachAccount.id)>0)
              ){
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
        if (!test.isRunningTest()) {
            RecalculateInactivePlanhatImportBatch recalculateInActiveAccounts = new RecalculateInactivePlanhatImportBatch();
            Database.executeBatch(recalculateInActiveAccounts, Integer.valueOf(Label.PlanhatImportBatchSize));
        }
    }
    
    /**
    * @description Schedule class execure method
    * @param  SchedulableContext - SchedulableContext
    * @return void
    */
    public void execute(SchedulableContext schedulableContext) {
        
            RecalculateActivePlanhatImportBatch recalculatePlanhatImportAccounts = new RecalculateActivePlanhatImportBatch();
            Database.executeBatch(recalculatePlanhatImportAccounts, Integer.valueOf(Label.PlanhatImportBatchSize));
        
    }
}