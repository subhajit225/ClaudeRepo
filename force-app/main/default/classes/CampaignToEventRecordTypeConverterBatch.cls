/**
 * @description Batch class to convert Campaign records with a record type
 * not equal to 'Event' to the 'Event' record type.
 * This class handles the querying, processing, and updating
 * of Campaign records in batches to avoid governor limits.
 */
public class CampaignToEventRecordTypeConverterBatch implements Database.Batchable<SObject>, Database.Stateful {
    // Member variable to store the ID of the 'Event' Record Type for the Campaign object.
    private Id eventRecordTypeId;

    /**
     * @description Constructor for the batch class.
     * It fetches the ID of the 'Event' Record Type upon initialization.
     */
    public CampaignToEventRecordTypeConverterBatch() {
        // Query for the 'Event' Record Type ID for the Campaign object.
        List<RecordType> campaignEventRTs = [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'Campaign' AND DeveloperName = 'Event'
            LIMIT 1
        ];

        if (!campaignEventRTs.isEmpty()) {
            this.eventRecordTypeId = campaignEventRTs[0].Id;
            System.debug(System.LoggingLevel.debug, 'Found Event Record Type ID: ' + this.eventRecordTypeId);
        } else {
            System.debug(System.LoggingLevel.ERROR, 'Error: Campaign Record Type with DeveloperName \'Event\' not found. Please ensure it exists.');
        }
    }

    /**
     * @description The start method collects the records or objects to be passed to the execute method.
     * @param bc The Database.BatchableContext object.
     * @return Database.QueryLocator An object that returns the records to be processed.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (this.eventRecordTypeId == null) {
            System.debug(System.LoggingLevel.ERROR, 'Batch will not run as Event Record Type ID was not found.');
            // Return an empty query locator if the record type ID is not found.
            return Database.getQueryLocator('SELECT Id FROM Campaign WHERE Id = NULL'); // No records will be processed.
        }

        // Query all Campaign records whose RecordTypeId is not equal to the 'Event' Record Type.
        // This ensures only relevant records are processed.
        String query = 'SELECT Id, RecordTypeId FROM Campaign WHERE RecordTypeId != :eventRecordTypeId AND IsActive = TRUE';
        System.debug(System.LoggingLevel.debug,'Start method query: ' + query);
        return Database.getQueryLocator(query);
    }

    /**
     * @description The execute method is called for each batch of records returned by the start method.
     * @param bc The Database.BatchableContext object.
     * @param scope A list of SObject records to process in this batch.
     */
    public void execute(Database.BatchableContext bc, List<Campaign> scope) {
        List<Campaign> campaignsToUpdate = new List<Campaign>();
        System.debug(System.LoggingLevel.debug, 'Executing batch for ' + scope.size() + ' Campaign records.');
        for (Campaign camp : scope) {
            // Check if the current record's record type is already the target 'Event' record type.
            // This avoids unnecessary updates and potential issues if a record gets processed twice.
            if (camp.RecordTypeId != this.eventRecordTypeId) {
                camp.RecordTypeId = this.eventRecordTypeId; // Set the record type to 'Event'.
                campaignsToUpdate.add(camp);
            }
        }

        if (!campaignsToUpdate.isEmpty()) {
            //try {
                Database.update(campaignsToUpdate, FALSE); // Perform the DML operation to update the records.
            /*    System.debug(System.LoggingLevel.debug,'Successfully updated ' + campaignsToUpdate.size() + ' Campaign records to Event Record Type.');
            } catch (DMLException e) {
                System.debug(System.LoggingLevel.Error, 'Error updating Campaign records: ' + e.getMessage());
                // Consider logging errors or handling specific types of errors.
            }*/
        } else {
            System.debug(System.LoggingLevel.debug, 'No Campaign records to update in this batch.');
        }
    }

    /**
     * @description The finish method is called once all batches are processed.
     * It can be used to send an email notification, perform cleanup, etc.
     * @param bc The Database.BatchableContext object.
     */
    public void finish(Database.BatchableContext bc) {
        System.debug(System.LoggingLevel.debug, 'Campaign Record Type Conversion Batch Finished.');
    }
}