/**
 * @name RiskProfileSchedulerQueue
 * @description A Queueable class that checks for existing scheduled batches of RiskProfileCreationBatch,
 *              and if none are found, schedules a new instance to run 20 minutes from now.
 *              This avoids duplicate batch executions.
 * 
 * @author Sushant Arora
 * @date 2025-08-14
 * @TestClass - RiskProfileSchedulerQueueTest
 */
public class RiskProfileSchedulerQueue implements Queueable {

    /**
     * @name execute
     * @description Executes the queueable job. It checks for an existing scheduled batch job
     *              named 'RiskProfileCreationBatch'. If none exists, it schedules the batch
     *              to run in 20 minutes using a cron expression.
     * 
     * @param context The queueable context passed by the system during job execution.
     * 
     * @see System.schedule
     * @see CronTrigger
     * @see RiskProfileCreationBatch
     */
    public void execute(QueueableContext context) {
        // Check if a job with a similar name is already scheduled
        Integer existingJobs = [
            SELECT COUNT() 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'RiskProfileCreationBatch%'
        ];

        if (existingJobs == 0) {
            // Schedule the job 20 minutes in the future
            System.scheduleBatch(new RiskProfileCreationBatch(), 'RiskProfileCreationBatch_20Mins', 20, 200); 
        } 
    }
}