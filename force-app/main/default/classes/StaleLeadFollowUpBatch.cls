/**
 * @description Batch job that finds open Leads older than 60 days and creates
 *              a follow-up Task assigned to the Lead owner with a 2-day due date.
 *              Implements Database.Stateless since no cross-chunk state is required.
 */
public with sharing class StaleLeadFollowUpBatch implements Database.Batchable<SObject> {

    private static final String TASK_SUBJECT = 'Close the Lead or mark it Bogus';
    private static final Integer DAYS_THRESHOLD = 60;
    private static final Integer DUE_DATE_OFFSET = 2;

    /**
     * @description Returns a QueryLocator for all open, unconverted Leads
     *              created more than 60 days ago.
     * @param bc The batch context
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoffDate = Date.today().addDays(-DAYS_THRESHOLD);
        return Database.getQueryLocator([
            SELECT Id, OwnerId
            FROM Lead
            WHERE IsConverted = false
            AND CreatedDate <= :cutoffDate
            WITH USER_MODE
        ]);
    }

    /**
     * @description Creates a follow-up Task for each Lead in the current batch chunk.
     * @param bc    The batch context
     * @param scope List of Lead records to process
     */
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        Date dueDate = Date.today().addDays(DUE_DATE_OFFSET);
        List<Task> tasksToInsert = new List<Task>();

        for (Lead lead : scope) {
            tasksToInsert.add(new Task(
                Subject      = TASK_SUBJECT,
                WhoId        = lead.Id,
                OwnerId      = lead.OwnerId,
                ActivityDate = dueDate,
                Status       = 'Not Started',
                Priority     = 'Normal'
            ));
        }

        if (!tasksToInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(tasksToInsert, false, AccessLevel.USER_MODE);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        // Errors are logged via platform; partial success is intentional
                        System.debug(LoggingLevel.ERROR, 'Task insert error: ' + err.getMessage());
                    }
                }
            }
        }
    }

    /**
     * @description Finish method — no post-processing required.
     * @param bc The batch context
     */
    public void finish(Database.BatchableContext bc) { }
}