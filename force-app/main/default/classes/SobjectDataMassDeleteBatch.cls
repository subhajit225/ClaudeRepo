/**
 * @description Batch process to mass delete records for a single SObject prior to a cutoff date.
 *              Uses a PST/PDT midnight boundary for the provided cutoff Date and deletes all records with
 *              CreatedDate earlier than that boundary. Sends a completion email with summary and, if any failures
 *              occurred, a CSV attachment listing failed deletes.
 *
 * @author Chintan Popat
 * @date 2025-12-08
 */
public with sharing class SobjectDataMassDeleteBatch implements Database.Batchable<SObject> , Database.Stateful{
    
    // Configurable email recipients
    @TestVisible
    private final List<String> emailRecipients;

    // Batch job inputs
    private final String objectApiName; 
    private final Date cutoffDate;

    // Collect failures for reporting
    @TestVisible
    private Map<String, List<String>> failedRecordsCsvMap = new Map<String, List<String>>();
    
    // To track the total successful deletions across all batches
    private Integer successfulCount = 0;
    
    /**
     * @description Custom exception class for invalid parameters.
     */
    public class InvalidParameterException extends Exception {}

    /**
     * @description Constructs the batch with default email recipient of the running user.
     * @param objectToProcess API name of the SObject to delete (e.g., Account, Custom__c).
     * @param dateToDeleteBefore Date boundary; records created strictly before midnight PST/PDT of this date are deleted.
     * @throws InvalidParameterException if inputs are invalid.
     */
    public SobjectDataMassDeleteBatch(String objectToProcess, Date dateToDeleteBefore) {
        this(objectToProcess, dateToDeleteBefore, new List<String>{UserInfo.getUserEmail()});
    }
    
    /**
     * @description Constructs the batch for a single SObject with explicit email recipients.
     * @param objectToProcess API name of the SObject to delete (e.g., Account, Custom__c).
     * @param dateToDeleteBefore Date boundary; records created strictly before midnight PST/PDT of this date are deleted.
     * @param emailRecipients List of email addresses to notify upon completion.
     * @throws InvalidParameterException if inputs are invalid or object API name does not exist.
     */
    public SobjectDataMassDeleteBatch(String objectToProcess, Date dateToDeleteBefore, List<String> emailRecipients) {
        if (String.isBlank(objectToProcess)) { 
            throw new InvalidParameterException('The object API name cannot be empty.');
        }
        if (dateToDeleteBefore == null) {
            throw new InvalidParameterException('The cutoff date cannot be null.');
        }
        if (emailRecipients == null || emailRecipients.isEmpty()) {
            throw new InvalidParameterException('At least one email recipient must be specified.');
        }

        // Validate object API name against describe to prevent SOQL injection
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey(objectToProcess)) {
            throw new InvalidParameterException('Invalid SObject API name: ' + objectToProcess);
        }

        this.objectApiName = objectToProcess;
        this.cutoffDate = dateToDeleteBefore;
        this.emailRecipients = emailRecipients;
    }

    /**
     * @description Returns a query locator for records to delete based on CreatedDate and target SObject.
     * @param bc Batchable context.
     * @return Database.QueryLocator for the target records.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // get PST Cut Off Datetime
        Datetime cutoffDateTime = getPSTCutOffTime();

        String query = 'SELECT Id FROM ' + objectApiName + ' WHERE CreatedDate < :cutoffDateTime';
        System.debug(LoggingLevel.INFO, 'Starting Batch for Object: ' + objectApiName + ' with Query: ' + query);
        return Database.getQueryLocator(query);
    }

    /**
     * @description Performs delete DML for the provided scope. Tallies successes and captures failures for reporting.
     * @param bc Batchable context.
     * @param scope Chunk of SObject records to delete.
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'No records to process in this execute call.');
            return;
        }

        System.debug(LoggingLevel.INFO, 'Processing delete for ' + scope.size() + ' records of ' + objectApiName);
        
        Database.DeleteResult[] results = Database.delete(scope, false); 
        List<String> failedCsvLines = new List<String>();
        for (Integer i = 0; i < results.size(); i++) {
            Database.DeleteResult dr = results[i];
            if (!dr.isSuccess()) {
                Database.Error error = dr.getErrors()[0];
                
               // Format: Record_ID,SObject_API_Name,Status_Code,Error_Message
                String csvLine = dr.getId() + ',' + 
                                 objectApiName + ',' + 
                                 error.getStatusCode() + ',' + 
                                 error.getMessage().replace('\n', ' ').replace('\r', ' '); 

                failedCsvLines.add(csvLine);
                
                System.debug(LoggingLevel.ERROR, 'Deletion Failed for ' + objectApiName + 
                             ' ID: ' + dr.getId() + ' | ' + error.getMessage());
            } else {
                successfulCount++;
            }
        }
        
        // Store failed records in the Stateful map
        if (!failedCsvLines.isEmpty()) {
            if (!failedRecordsCsvMap.containsKey(objectApiName)) {
                failedRecordsCsvMap.put(objectApiName, new List<String>());
            }
            failedRecordsCsvMap.get(objectApiName).addAll(failedCsvLines);
        }
    }

    /**
     * @description Sends completion email including totals and attaches a CSV of failed deletes if any.
     * @param bc Batchable context.
     */
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'Deletion batch completed for ' + objectApiName + '. Sending notification.');
        sendCompletionEmail(bc.getJobId());
    }
    
    /**
     * @description Sends the summary email and optional CSV attachment for failures.
     * @param jobId The AsyncApexJob Id for the batch, used in subject and file naming.
     */
    private void sendCompletionEmail(Id jobId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailRecipients);
        
        String subject = 'Mass Record Deletion Batch Status - Job ID: ' + jobId;
        String body = 'The Mass Record Deletion Batch process has completed for the object: ' + objectApiName + '.\n\n';
        body += 'Processed Records Created Before: ' + cutoffDate.year() + '-' + cutoffDate.month() + '-' +cutoffDate.day() + '\n\n';
        
        // Check the CSV map for failures
        if (failedRecordsCsvMap.isEmpty()) {
            body += 'SUCCESS: All records were deleted successfully (Record Counts: ' + successfulCount + ').\n';
        } else {
            body += 'Total Records Deleted: ' + successfulCount + '\n';
            body += 'Total Records Failed: ' + getFailureCount() + '\n\n';
            body += 'WARNING: Some records failed to delete. The detailed list of failures has been attached as a CSV file.\n';
            
            String csvHeader = 'Record_ID,SObject_API_Name,Status_Code,Error_Message\n';
            String csvBody = '';
            
            // Only iterate over the single object's failures
            if (failedRecordsCsvMap.containsKey(objectApiName)) {
                 csvBody += String.join(failedRecordsCsvMap.get(objectApiName), '\n') + '\n';
            }
            
            String finalCsv = csvHeader + csvBody;
            
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(objectApiName + '_Deletion_Failures_' + jobId + '.csv');
            attachment.setBody(Blob.valueOf(finalCsv));
            attachment.setContentType('text/csv');
            
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        }
        
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug(LoggingLevel.INFO, 'Completion email sent successfully.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to send completion email: ' + e.getMessage());
        }
    }

    /**
     * @description Returns the total number of failed deletes captured for the target SObject.
     * @return Total failure count.
     */
    private Integer getFailureCount() {
        if (failedRecordsCsvMap.containsKey(objectApiName)) {
            return failedRecordsCsvMap.get(objectApiName).size();
        }
        return 0;
    }

    /**
     * @description Calculates the UTC datetime that corresponds to 12:00 AM in America/Los_Angeles
     *              for the provided cutoff date (handles PST/PDT via TimeZone offset).
     * @return The Datetime boundary to use in the SOQL filter.
     */
    private Datetime getPSTCutOffTime(){
        
        // 1. Define the input date/time in the context of the user's timezone 
        // This creates a DateTime object for 12:00 AM UTC on the cutoff day.
        Datetime midnightUTC = Datetime.newInstanceGmt(cutoffDate.year(), cutoffDate.month(), cutoffDate.day(), 0, 0, 0);
        
        // 2. Determine the PST Offset 
        // We create a TimeZone object and ask for the offset for our midnight UTC time.
        TimeZone pstZone = TimeZone.getTimeZone('America/Los_Angeles'); // Standard PST
        
        // getOffset() returns the offset in milliseconds between GMT and the timezone
        // The offset is negative for zones west of Greenwich (like PST/PDT).
        Long offsetMs = pstZone.getOffset(midnightUTC); 
    
        // 3. Calculate the true UTC boundary: 
        // We want the time that is equivalent to 12:00:00 AM PST.
        // midnightUTC - offsetMs gives you the actual UTC time when it is 12:00 AM PST/PDT.
        // return midnightUTC.addSeconds((Integer) (offsetMs / 1000));
        return midnightUTC.addSeconds(-(Integer) (offsetMs / 1000));
    }
}