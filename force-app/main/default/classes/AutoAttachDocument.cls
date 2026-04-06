/**************************************************************
* Story : CPQ22-4425
* Created : 21/08/2024
* Purpose : Auto attach quote document on Opportunity on Stage 7
* ***********************************************************/
public class AutoAttachDocument implements Queueable {
    
    public List<SBQQ__Quote__c> quotes;
    
    public AutoAttachDocument(List<SBQQ__Quote__c> qoutesAttachDoc){
        this.quotes = qoutesAttachDoc;
    }
    
    public void execute(QueueableContext context) {
        
        try{
            List<SBQQ__QuoteDocument__c> docsUpdate = new List<SBQQ__QuoteDocument__c>(); 
            
            for (SBQQ__Quote__c quote : quotes){
                if (quote.SBQQ__R00N70000001lX7YEAU__r!=null && quote.SBQQ__R00N70000001lX7YEAU__r.size() > 0){
                    SBQQ__QuoteDocument__c doc = quote.SBQQ__R00N70000001lX7YEAU__r[0];
                    doc.SBQQ__Opportunity__c = quote.SBQQ__Opportunity2__c;
                    docsUpdate.add(doc);
                }
            }
            
            if(docsUpdate.size() > 0) {
                update docsUpdate;
            }
        }
        catch(Exception e){
            insert new Batch_Error_Log__c(Class_Name__c='AutoAttachDocument', Failure_Job_ID__c=context.getJobId(), Failure_Message__c=e.getMessage()+' @ '+e.getStackTraceString(), Scenario__c='CPQ22-4425 Auto Attach Doc', Failure_Date__c=Date.today());
        }
        
    }
}