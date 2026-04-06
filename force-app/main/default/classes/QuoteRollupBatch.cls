/**
 * @description : This Class is a batch used to update Quote's CompUpliftACV__c and Sum_of_RAMP_EXIT_ACV__c as a roll up by Quote line.
 * Class Name:- QuoteRollupBatch
 * Author: Shubham Bansal
 * CreatedDate: 08/01/2026
**/
public class QuoteRollupBatch
implements Database.Batchable<SObject> {
    
    private Set<Id> quoteIds;
    
    /**
     * @description Constructor for chaining that accepts a list of Quote Ids to roll up.
     * @param quoteIds List of SBQQ__Quote__c record Ids whose rollup fields will be recalculated.
     */
    public QuoteRollupBatch(List<Id> quoteIds) {
        this.quoteIds = new Set<Id>(quoteIds);
    }
    
    /**
     * @description Starts the batch process by querying Quotes based on provided quoteIds.
     * @param bc The batchable context.
     * @return A QueryLocator for Quotes meeting the criteria.
     **/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ]);
    }
    
    /**
     * @description execute the batch process post querying Quotes based on provided quoteIds.
     * @param bc The batchable context.
     * @param  scope The list of Quotes to process in this batch chunk.
     **/
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        
        List<SBQQ__Quote__c> quotes =
            (List<SBQQ__Quote__c>) scope;
        
        List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
        
        Set<Id> scopeQuoteIds = new Set<Id>();
        for (SBQQ__Quote__c q : quotes) {
            scopeQuoteIds.add(q.Id);
        }
        
        // Aggregate quote line values
        Map<Id, AggregateResult> aggMap = new Map<Id, AggregateResult>();
        
        for (AggregateResult ar : [
            SELECT
            SBQQ__Quote__c quoteId,
            SUM(RBOBACV__c) rbobAcvSum,
            SUM(RAMP_EXIT_ACV__c) rampExitSum,
            SUM(CompUpliftACV__c) compUpliftSum
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :scopeQuoteIds
            AND (RAMP_EXIT_ACV__c != NULL
                 OR CompUpliftACV__c != NULL)
            GROUP BY SBQQ__Quote__c
        ]) {
            aggMap.put((Id) ar.get('quoteId'), ar);
        }
        
        List<SBQQ__Quote__c> toUpdate = new List<SBQQ__Quote__c>();
        
        for (SBQQ__Quote__c q : quotes) {
            
            Decimal rbobAcvSum = 0;
            Decimal rampExit = 0;
            Decimal compUplift = 0;
            
            if (aggMap.containsKey(q.Id)) {
                AggregateResult ar = aggMap.get(q.Id);
                rbobAcvSum = (Decimal) ar.get('rbobAcvSum');
                rampExit = (Decimal) ar.get('rampExitSum');
                compUplift = (Decimal) ar.get('compUpliftSum');
            }
            
            q.Sum_of_RAMP_EXIT_ACV__c = rampExit;
            q.CompUpliftACV__c = compUplift;
            q.RBOBACV__c = rbobAcvSum;
            
            toUpdate.add(q);
        }
        
        if (!toUpdate.isEmpty()) {
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            LockQuoteValidationByPass.byPassValidation = true;

            Database.SaveResult[] results = Database.update(toUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    batchErrLogList.add(new Batch_Error_Log__c(Status__c='Completed',Class_Name__c='QuoteRollupBatch',Failure_Message__c='Updated Successfully',Object_ID__c = toUpdate[i].Id, Failure_Job_ID__c = bc.getJobID()));
                } else {
                    for (Database.Error e : results[i].getErrors()) {
                        batchErrLogList.add(new Batch_Error_Log__c(Status__c='Error',Class_Name__c='QuoteRollupBatch',Failure_Message__c=e.getMessage(),Object_ID__c = toUpdate[i].Id, Failure_Date__c = Date.today(), Failure_Job_ID__c = bc.getJobID()));
                    }
                }
            }
            if (!batchErrLogList.isEmpty()) insert batchErrLogList;
        }
    }
    
    /**
     * @description finish the batch process.
     * @param bc The batchable context.
     **/
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'QuoteRollupBatch completed successfully.');
    }
}