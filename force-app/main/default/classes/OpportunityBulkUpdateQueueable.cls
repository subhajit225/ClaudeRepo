/**************************************************************************************************
 * @description       : OpportunityBulkUpdateQueueable
 * @author            : Shrutika 
 * @last modified on  : 27-11-2025
 * Modifications Log
 * Ver   Date          Author        Modification
 ******************************************************************************/
public class OpportunityBulkUpdateQueueable implements Queueable {
    //Static variable as requested
    public static Boolean isbulkDeal = false;
    private List<Opportunity> oppList;
	/**
	 * @description constructor
	 * @param opportunities
	 * */
     public OpportunityBulkUpdateQueueable(List<Opportunity> opportunities) {
     	this.oppList = opportunities;
     }
    
	/**
	 * @description execute method in Queable 
	 * @param context
	 **/    
    public void execute(QueueableContext context) {
        if (oppList.isEmpty())
        	return; 
        
        isBulkDeal = true;
        Opportunity oppToProcess = oppList[0];
        update oppToProcess;
        oppList.remove(0);
        if (!OrderItemTriggerHelper.oiUpdateMap.isEmpty() && !Test.isRunningTest()){
           System.enqueueJob(new UpdateSupportOrderLinesDatesForCSUClass(OrderItemTriggerHelper.oiUpdateMap.values()));
        }else if (!oppList.isEmpty()) {
            try{
            	System.enqueueJob(new OpportunityBulkUpdateQueueable(oppList));
            }catch(exception ex){
                system.debug(LoggingLevel.DEBUG,'::ex::'+ex);
            }
        }
 
    }
}