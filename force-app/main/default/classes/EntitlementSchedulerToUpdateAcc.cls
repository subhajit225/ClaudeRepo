/*
 * This Schedular class is used to schedule EntitlementBatchToUpdateAcc Batch 
 */
public class EntitlementSchedulerToUpdateAcc implements Schedulable {
	private Boolean isDisabledBatchApex = false;
    Integer batchSize ;
    public EntitlementSchedulerToUpdateAcc(Integer batchSize){
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabledBatchApex = disabled.Disable_Batch_Apex__c;
        this.batchSize = batchSize;
    }
    public void execute(SchedulableContext sc) {
        if (!isDisabledBatchApex) {
            EntitlementBatchToUpdateAcc batchToUpdateAcc = new EntitlementBatchToUpdateAcc();
            if(this.batchSize == null){
                Database.executeBatch(batchToUpdateAcc);
            }
            else{
               Database.executeBatch(batchToUpdateAcc, batchSize); 
            }
        }
    }
}