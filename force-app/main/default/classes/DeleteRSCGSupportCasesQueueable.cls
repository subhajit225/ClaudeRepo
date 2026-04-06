/**
 * @description Queueable class to delete Support Cases when Account has RSC-G support
 * @date 2025-12-03
 */
public class DeleteRSCGSupportCasesQueueable implements Queueable {
    
    private List<Case> caseList;
    
    /**
     * @description Constructor to initialize the queueable with case IDs to process
     * @param caseList List of Case record for deletion
     */
    public DeleteRSCGSupportCasesQueueable(List<Case> caseList) {
        this.caseList = caseList;
    }
    
    /**
     * @description Execute method for the queueable job
     * @param context QueueableContext provided by the system
     */
    public void execute(QueueableContext context) {
        try {
            // Delete cases
            if (!caseList.isEmpty()) {
                delete caseList;
            }
        } catch (Exception e) {
            // Log error for monitoring
            System.debug(LoggingLevel.ERROR, 'DeleteRSCGSupportCasesQueueable Error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
    }
}