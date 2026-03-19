/**
 * @description Schedulable wrapper to run StaleLeadFollowUpBatch on a recurring schedule.
 *              Example — schedule daily at 2 AM:
 *              System.schedule('Stale Lead Follow-Up Daily', '0 0 2 * * ?', new StaleLeadFollowUpScheduler());
 */
public with sharing class StaleLeadFollowUpScheduler implements Schedulable {

    /**
     * @description Executes the batch job when triggered by the scheduler.
     * @param sc The schedulable context
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new StaleLeadFollowUpBatch(), 200);
    }
}