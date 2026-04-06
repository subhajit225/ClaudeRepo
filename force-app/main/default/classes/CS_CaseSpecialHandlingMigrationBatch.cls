/**
 * @author Sushant Arora
 * @date 2024-01-31
 * @description Controller For Migration Batch
 * @TestClass - CS_CaseSpecialHandlingMigrationBatchTest
 */
public class CS_CaseSpecialHandlingMigrationBatch implements Database.Batchable<sObject> {
    /**
     * @description standard interface function
     */
    private string query;
    
    /**
     * @description CS21-1971
     * 
     * @param query external query to retrieve accounts
     */
    public CS_CaseSpecialHandlingMigrationBatch(String query){
        this.query = query;
    }
    /**
     * @description default constructor
     * 
     */
    public CS_CaseSpecialHandlingMigrationBatch(){
        this.query = null;
    }
    
    /**
     * @description Generates the query to be executed in the batch job and returns a QueryLocator object.
     * @param bc The batch context.
     * @return Database.QueryLocator The query locator for the batch process.
     */	
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String localQuery = String.isBlank(this.query)
            ? 'SELECT Id, Heads_Up_to_Support_Team__c FROM Account WHERE Id NOT IN (SELECT Account_Id__c FROM Case_Special_Handling__c)'
            : this.query;
        return Database.getQueryLocator(localQuery);
    }
    
   /**
 * @description Executes the batch process on the list of Account records provided in the scope.
 * @param bc The batch context.
 * @param scope The list of Account records to process.
 */
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Case_Special_Handling__c> records = new List<Case_Special_Handling__c>();
        
        for(Account a : scope) {
            if(a.Heads_Up_to_Support_Team__c == null){
                continue;
            }
            records.add(
                new Case_Special_Handling__c(
                    Account_Id__c = a.Id,
                    Category__c = 'Migrated Case Special Handling',
                    Message__c = a.Heads_Up_to_Support_Team__c,
                    Show_Banner__c = false,
                    Icon__c = null,
                    Valid_Until__c = Date.today().addYears(1),
                    Manual_Review_Requested_On__c = null,
                    Is_Archived__c = false
                ));
        }
        
        if(!records.isEmpty()) {
            insert records;
        }
    }
    
/**
 * @description Completes the batch process.
 * @param bc The batch context.
 */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext bc) {
        // This empty statement block is a mandatory implementation for the Batchable interface.
    // No additional actions are required in the finish method for this batch job.
    }
}