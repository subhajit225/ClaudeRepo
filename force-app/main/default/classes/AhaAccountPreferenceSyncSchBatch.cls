/**
 * @description Batch class to sync Account Preference field values from Salesforce to AHA ideas.
 *              This batch job runs every 72 hours to update AHA ideas with the latest Account Preference values
 *              from associated Accounts through Opportunity or Case relationships.
 * @author Vijay K R
 * @since 28/11/2024
 * @see AhaAccountPreferenceSyncSchBatchTest
 */
public class AhaAccountPreferenceSyncSchBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {

    /**
     * @description Batch size limit to avoid governor limits during processing
     */
    private static final Integer BATCH_SIZE = 50;

    /**
     * @description Static list of Account Preference values to filter for in the batch query.
     *              Only accounts with these preference values will be processed for AHA synchronization.
     */
    private static final List<String> TARGET_ACCOUNT_PREFERENCES = new List<String>{
        'Strategic Account',
        'Top Accounts',
        'Premium Account',
        'Premium - CES'
    };

    /**
     * @description automatically invoked when the scheduled job runs.
     * @param sc SchedulableContext 
     */
    public void execute(SchedulableContext sc) {
        try {
            Database.executeBatch(new AhaAccountPreferenceSyncSchBatch(), BATCH_SIZE);
        } catch (Exception e) {
            logError('Scheduler Error', e);
        }
    }

    /**
     * @description Static method to schedule the job to run every 48 hours
     * Usage: AhaAccountPreferenceSyncScheduler.scheduleJob();
     * @return String The scheduled job ID
     */
    public static String scheduleJob() {
        return scheduleJob('AHA Account Preference Sync');
    }

    /**
     * @description Static method to schedule the job with custom name
     * @param jobName The custom name for the scheduled job
     * @return String The scheduled job ID
     */
    public static String scheduleJob(String jobName) {
        // Cron expression for every 72 hours (every 3 days at 2 AM)
        // Format: Seconds Minutes Hours Day_of_month Month Day_of_week Year
        String cronExpression = '0 0 2 */2 * ?';
        return System.schedule(jobName, cronExpression, new AhaAccountPreferenceSyncSchBatch());
    }

     /**
     * @description execute Batc Now
     * @param jobName The custom name for the scheduled job
     * @return String The scheduled job ID
     */
    public static Id executeBatchNow() {
        return Database.executeBatch(new AhaAccountPreferenceSyncSchBatch(), BATCH_SIZE);
    }

    /**
     * @description Start method of the batch job that queries Aha_Idea_Link__c records
     *              with Account Preference changes in the last 3 days.
     * @param bc Database.BatchableContext - The batchable context provided by the platform
     * @return Database.QueryLocator - Query locator containing the records to be processed
     * @see Database.Batchable
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        String includesClause = '(\'' + String.join(TARGET_ACCOUNT_PREFERENCES, '\',\'') + '\')';

        String query = 'SELECT Id, Name, LastModifiedBy.Name, LastModifiedDate, ' +
                      'Opportunity_Name__r.Account.Account_Preference__c, ' +
                      'Case_Number__r.Account.Account_Preference__c, ' +
                      'Aha_Ideas__c, Aha_Ideas__r.Aha_Unique_ID__c, ' +
                      'Aha_Ideas__r.Name, Aha_Ideas__r.Impacted_Customers__c, ' +
                      'Aha_Ideas__r.Strategic_Major_Account__c ' +
                      'FROM Aha_Idea_Link__c ' +
                      'WHERE ((Opportunity_Name__r.Account.Account_Preference__c != null ' +
                      'AND (Opportunity_Name__r.Account.Account_Preference__c INCLUDES ' + includesClause + ')) ' +
                      'OR (Case_Number__r.Account.Account_Preference__c != null ' +
                      'AND (Case_Number__r.Account.Account_Preference__c INCLUDES ' + includesClause + '))) ' +
                      'AND (Opportunity_Name__r.Account.LastModifiedDate = LAST_N_DAYS:3 ' +
                      'OR Case_Number__r.Account.LastModifiedDate = LAST_N_DAYS:3) ' +
                      'ORDER BY LastModifiedDate DESC';

        return Database.getQueryLocator(query);
    }

    /**
     * @description Execute method that processes each batch of Aha_Idea_Link__c records.
     *              Groups records by AHA Unique ID to avoid duplicate callouts and processes
     *              Account Preference updates for each unique AHA idea.
     * @param bc Database.BatchableContext - The batchable context provided by the platform
     * @param scope List<Aha_Idea_Link__c> - The list of records to process in this batch
     * @see Database.Batchable
     */
    public void execute(Database.BatchableContext bc, List<Aha_Idea_Link__c> scope) {

        try {

            Map<String, AhaIdeaUpdateWrapper> ahaIdeaUpdates = new Map<String, AhaIdeaUpdateWrapper>();
            Map<String, Set<String>> ahaPreferenceMap = new Map<String, Set<String>>();

            for (Aha_Idea_Link__c ideaLink : scope) {

                if (ideaLink.Aha_Ideas__r.Aha_Unique_ID__c == null) continue;

                String ahaUniqueId = ideaLink.Aha_Ideas__r.Aha_Unique_ID__c;

                if (!ahaPreferenceMap.containsKey(ahaUniqueId))
                    ahaPreferenceMap.put(ahaUniqueId, new Set<String>());

                String accountPreference = '';

                if (ideaLink.Case_Number__r?.Account?.Account_Preference__c != null)
                    accountPreference = ideaLink.Case_Number__r.Account.Account_Preference__c;
                else if (ideaLink.Opportunity_Name__r?.Account?.Account_Preference__c != null)
                    accountPreference = ideaLink.Opportunity_Name__r.Account.Account_Preference__c;

                if (String.isBlank(accountPreference)) continue;

                for (String pref : accountPreference.split(';')) {
                    if (String.isNotBlank(pref))
                        ahaPreferenceMap.get(ahaUniqueId).add(pref.trim());
                }

                if (!ahaIdeaUpdates.containsKey(ahaUniqueId)) {
                    AhaIdeaUpdateWrapper wrapper = new AhaIdeaUpdateWrapper();
                    wrapper.ahaUniqueId = ahaUniqueId;
                    wrapper.ideaName = ideaLink.Aha_Ideas__r.Name;
                    wrapper.impactedCustomers = ideaLink.Aha_Ideas__r.Impacted_Customers__c;
                    wrapper.strategicAccount = Integer.valueOf(
                        ideaLink.Aha_Ideas__r.Strategic_Major_Account__c != null ?
                        ideaLink.Aha_Ideas__r.Strategic_Major_Account__c : 0
                    );
                    wrapper.accountPreferences = new Set<String>();
                    ahaIdeaUpdates.put(ahaUniqueId, wrapper);
                }
            }

            for (String idKey : ahaPreferenceMap.keySet())
                if (ahaIdeaUpdates.containsKey(idKey))
                    ahaIdeaUpdates.get(idKey).accountPreferences = ahaPreferenceMap.get(idKey);

            if (!ahaIdeaUpdates.isEmpty())
                processAhaUpdates(ahaIdeaUpdates.values());

        } catch (Exception e) {
            logError('Batch Execute', e);
        }
    }

    /**
     * @description Finish method called after all batches are processed.
     *              Retrieves batch job details for monitoring and logging purposes.
     * @param bc Database.BatchableContext - The batchable context provided by the platform
     */
    public void finish(Database.BatchableContext bc) {
        // optional logging
    }

    /**
     * @description Processes AHA idea updates while respecting callout governor limits.
     *              Limits the number of callouts to avoid hitting the 100 callout limit per transaction.
     * @param ideaUpdates List<AhaIdeaUpdateWrapper> - List of AHA idea update wrappers to process
     */
    private void processAhaUpdates(List<AhaIdeaUpdateWrapper> updates) {

        Integer callouts = 0;

        for (AhaIdeaUpdateWrapper w : updates) {
            if (callouts >= 90) break;

            try {
                updateAhaIdeaAccountPreference(w);
                callouts++;
            } catch (Exception e) {
                logError('Callout ' + w.ahaUniqueId, e);
            }
        }
    }

    /**
     * @description Updates an AHA idea with Account Preference values via HTTP callout.
     *              This is a simplified version of ManageAhaIdeaHelper.updateIdeaRecordInAha
     *              that only updates the account_preference custom field.
     * @param wrapper AhaIdeaUpdateWrapper - Wrapper containing AHA idea details and account preferences
     * @throws CalloutException When AHA API returns non-200 status code
     * @see ManageAhaIdeaHelper.updateIdeaRecordInAha
     */
    private void updateAhaIdeaAccountPreference(AhaIdeaUpdateWrapper wrapper) {

        Rubrik_Aha_Credencial__mdt cred = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');

        String value = String.join(new List<String>(wrapper.accountPreferences), ',');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(cred.AHA_BASE_URL__c + '/ideas/' + wrapper.ahaUniqueId);
        req.setMethod('PUT');
        req.setHeader('Authorization', 'Bearer ' + cred.AHA_API_KEY__c);
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setBody('{"idea":{"custom_fields":{"account_preference":"' + value + '"}}}');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200)
            throw new CalloutException(res.getBody());
    }

    /**
     * @description Inserts an error log record for tracking batch processing issues.
     *              Creates an Idea_Exception__c record with error details for monitoring and debugging.
     * @param operation String - The operation where the error occurred (e.g., 'Execute', 'Callout')
     * @param errorMessage String - The error message to log
     * @param stackTrace String - The stack trace of the exception
     */
    private static void logError(String type, Exception e) {
        try {
            insert new Idea_Exception__c(
                Type__c = type,
                Error_Message__c = e.getMessage() + '\n' + e.getStackTraceString()
            );
        } catch (Exception ignore) {}
    }

    /**
     * @description Wrapper class to hold AHA idea update information.
     *              Contains all necessary data for updating an AHA idea's account preferences.
     */
    public class AhaIdeaUpdateWrapper {
        /**
         * @description The unique identifier for the AHA idea
         */
        public String ahaUniqueId;

        /**
         * @description The name/title of the AHA idea
         */
        public String ideaName;

        /**
         * @description The impacted customers field value from the AHA idea
         */
        public String impactedCustomers;

        /**
         * @description The strategic account count/flag for the AHA idea
         */
        public Integer strategicAccount;

        /**
         * @description Set of account preference values to be synchronized to AHA
         */
        public Set<String> accountPreferences;
    }
}