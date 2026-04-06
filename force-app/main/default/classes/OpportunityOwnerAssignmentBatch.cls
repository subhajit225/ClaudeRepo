/**
 * @name OpportunityOwnerAssignmentBatch
 * @description Batch class to sync Opportunity Team Members (OTMs) with Partner_Relation__c account owners.
 *
 * Rules:
 * - Identify Opportunities impacted by Account Owner changes.
 * - For each impacted Opportunity, collect ALL Partner_Relation__c records.
 * - Create OTMs for all unique Account Owners.
 * - Do not delete OTMs if the user still owns at least one Account linked via PR.
 * - Only delete OTMs if the user owns zero PR-linked Accounts for that Opportunity.
 *
 * Bulkified and PMD compliant.
 */
public class OpportunityOwnerAssignmentBatch implements Database.Batchable<sObject>, Database.Stateful {
	/**
     * @description Holds error logs for failed records during batch execution
     */
    @TestVisible
    private List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();
    private static final Date FILTER_START_DATE = getFilterStartDate(); //MKT26-842 changes

    /**
     * @description Start method to retrieve Account History of OwnerId field
     * @param bc Database.BatchableContext - the batch context
     * @return Database.QueryLocator - query locator for AccountHistory records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT AccountId, NewValue, OldValue, CreatedDate FROM AccountHistory ' +
                       'WHERE CreatedDate = LAST_N_DAYS:1 AND Field = \'Owner\'';
        return Database.getQueryLocator(query);
    }

    /**
     * @description Execute method to insert or delete Opportunity Team Members based on Account Owner changes
     * @param bc Database.BatchableContext - the batch context
     * @param scope List<AccountHistory> - scope of AccountHistory records for this execution
     */
    public void execute(Database.BatchableContext bc, List<AccountHistory> scope) {
        if (scope.isEmpty()) {
            return;
        }

        // Step 1: Collect changed AccountIds
        Set<Id> changedAccountIds = new Set<Id>();
        for (AccountHistory ah : scope) {
            changedAccountIds.add(ah.AccountId);
        }

        if (changedAccountIds.isEmpty()) {
            return;
        }

        //MKT26-842 changes
        Map<Id, Id> accountToOwnerMap = new Map<Id, Id>();
        for (Account acc : [SELECT Id, OwnerId FROM Account WHERE Id IN :changedAccountIds]) {
            accountToOwnerMap.put(acc.Id, acc.OwnerId);
        }

        String campaignQuery = 'SELECT Id, StartDate, Campaign_Partner__c, Campaign_Partner__r.OwnerId, CDM__c ' +
                               'FROM Campaign WHERE Campaign_Partner__c IN :changedAccountIds';
        if (FILTER_START_DATE != null) {
            campaignQuery += ' AND StartDate >= :FILTER_START_DATE';
        }
        List<Campaign> campaignsList = Database.query(campaignQuery);
        List<Campaign> campaignsToUpdate = new List<Campaign>();
        for(Campaign c: campaignsList){
            Id newOwner = accountToOwnerMap.get(c.Campaign_Partner__c);
            if(newOwner != null && c.CDM__c != newOwner){
                c.CDM__c = newOwner;
                campaignsToUpdate.add(c);
            }
        }

        if(!campaignsToUpdate.isEmpty()){
            flowControll.campaignTrigger = false;
            update campaignsToUpdate;
            flowControll.campaignTrigger = true;
        }

        String leadQuery = 'SELECT Id, MQL_Channel_Partner__c, MQL_Channel_Partner__r.OwnerId, Last_MQL_Date__c, MQL_Channel_CDM__c ' +
                           'FROM Lead WHERE MQL_Channel_Partner__c IN :changedAccountIds';
        if (FILTER_START_DATE != null) {
            leadQuery += ' AND Last_MQL_Date__c > :FILTER_START_DATE';
        }
        List<Lead> leadsList = Database.query(leadQuery);
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead l : leadsList) {
            Id newOwner = accountToOwnerMap.get(l.MQL_Channel_Partner__c);
            if (newOwner != null && l.MQL_Channel_CDM__c != newOwner) {
                l.MQL_Channel_CDM__c = newOwner;
                leadsToUpdate.add(l);
            }
        }

        if (!leadsToUpdate.isEmpty()) {
            flowControll.leadTriggerHandler = false;
            update leadsToUpdate;
            flowControll.leadTriggerHandler = true;
        }

        String contactQuery = 'SELECT Id, MQL_Channel_Partner__c, MQL_Channel_Partner__r.OwnerId, Last_MQL_Date__c, MQL_Channel_CDM__c ' +
                              'FROM Contact WHERE MQL_Channel_Partner__c IN :changedAccountIds';
        if (FILTER_START_DATE != null) {
            contactQuery += ' AND Last_MQL_Date__c > :FILTER_START_DATE';
        }
        List<Contact> contactsList = Database.query(contactQuery);
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c : contactsList) {
            Id newOwner = accountToOwnerMap.get(c.MQL_Channel_Partner__c);
            if (newOwner != null && c.MQL_Channel_CDM__c != newOwner) {
                c.MQL_Channel_CDM__c = newOwner;
                contactsToUpdate.add(c);
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            flowControll.contactTrigger = false;
            update contactsToUpdate;
            flowControll.contactTrigger = true;
        }

        Set<String> involvementTypes = new Set<String>{'TAP Alliance','Influence Partner'};
        Set<String> stageExclusions = new Set<String>{'7 Closed Won','7 Closed Lost','7 Closed Admin'};

        // Step 2: Find Opportunities impacted (through PRs of changed accounts)
        Set<Id> impactedOppIds = new Set<Id>();
        for (Partner_Relation__c pr : [
            SELECT Opportunity__c
            FROM Partner_Relation__c
            WHERE Partner_Account__c IN :changedAccountIds
              AND Involvement_Type__c IN :involvementTypes
              AND Opportunity__r.Opportunity_Type__c != 'Debooking'
              AND Opportunity__r.StageName NOT IN :stageExclusions
        ]) {
            impactedOppIds.add(pr.Opportunity__c);
        }

        if (impactedOppIds.isEmpty()) {
            return;
        }

        // Step 3: Get ALL PRs for impacted Opportunities
        List<Partner_Relation__c> allPrs = [
            SELECT Id, Opportunity__c, Partner_Account__c, Partner_Account__r.OwnerId
            FROM Partner_Relation__c
            WHERE Opportunity__c IN :impactedOppIds
              AND Involvement_Type__c IN :involvementTypes
              AND Opportunity__r.Opportunity_Type__c != 'Debooking'
              AND Opportunity__r.StageName NOT IN :stageExclusions
        ];

        // Step 4: Build maps: Opp -> Owners and Opp -> Accounts
        Map<Id, Set<Id>> oppToOwners = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> oppToAccounts = new Map<Id, Set<Id>>();
        for (Partner_Relation__c pr : allPrs) {
            if (!oppToOwners.containsKey(pr.Opportunity__c)) {
                oppToOwners.put(pr.Opportunity__c, new Set<Id>());
                oppToAccounts.put(pr.Opportunity__c, new Set<Id>());
            }
            oppToOwners.get(pr.Opportunity__c).add(pr.Partner_Account__r.OwnerId);
            oppToAccounts.get(pr.Opportunity__c).add(pr.Partner_Account__c);
        }

        // Step 5: Query all Accounts to confirm owners
        Set<Id> allAccIds = new Set<Id>();
        for (Set<Id> ids : oppToAccounts.values()) {
            allAccIds.addAll(ids);
        }

        Map<Id, Account> accountsById = new Map<Id, Account>();
        if (!allAccIds.isEmpty()) {
            for (Account acc : [SELECT Id, OwnerId FROM Account WHERE Id IN :allAccIds]) {
                accountsById.put(acc.Id, acc);
            }
        }

        // Step 6: Query existing OTMs
        Map<String, OpportunityTeamMember> existingOtmMap = new Map<String, OpportunityTeamMember>();
        for (OpportunityTeamMember otm : [
            SELECT Id, OpportunityId, UserId, TeamMemberRole
            FROM OpportunityTeamMember
            WHERE OpportunityId IN :impactedOppIds
              AND TeamMemberRole = 'Partner Relation'
        ]) {
            existingOtmMap.put(otm.OpportunityId + '' + otm.UserId, otm);
        }

        // Step 7: Insert new OTMs for missing owners
        List<OpportunityTeamMember> toInsert = new List<OpportunityTeamMember>();
        for (Id oppId : oppToOwners.keySet()) {
            for (Id ownerId : oppToOwners.get(oppId)) {
                String key = oppId + '' + ownerId;
                if (!existingOtmMap.containsKey(key)) {
                    toInsert.add(new OpportunityTeamMember(
                        OpportunityId = oppId,
                        UserId = ownerId,
                        TeamMemberRole = 'Partner Relation',
                        OpportunityAccessLevel = 'Read'
                    ));
                }
            }
        }

        if (!toInsert.isEmpty()) {
            List<Database.SaveResult> srList = Database.insert(toInsert, false);
            errorLogList = LogError.createDMLErrorLogWithRetrunType(
                (List<SObject>) toInsert,
                srList,
                'OpportunityOwnerAssignmentBatch',
                'Insert OTM failed'
            );
        }

        // Step 8: Delete OTMs only if user no longer owns ANY Account on ANY PR of the Opp
        Map<String, OpportunityTeamMember> toDelete = new Map<String, OpportunityTeamMember>();
        for (OpportunityTeamMember otm : existingOtmMap.values()) {
            Id oppId = otm.OpportunityId;
            Id userId = otm.UserId;

            Boolean stillValidOwner = false;
            if (oppToAccounts.containsKey(oppId)) {
                for (Id accId : oppToAccounts.get(oppId)) {
                    if (accountsById.containsKey(accId) && accountsById.get(accId).OwnerId == userId) {
                        stillValidOwner = true;
                        break;
                    }
                }
            }

            if (!stillValidOwner) {
                toDelete.put(oppId + '' + userId, otm);
            }
        }

        if (!toDelete.isEmpty()) {
            Database.delete(toDelete.values(), false);
        }
    }

    /**
     * @description Finish method for post-processing (error logging and notification email)
     * @param bc Database.BatchableContext - the batch context
     */
    public void finish(Database.BatchableContext bc) {
        if (!errorLogList.isEmpty()) {
            String emailDetail = EmailHelper.prepareEmailBodyForCustomErrorLog(errorLogList);
            EmailHelper.sendBatchErrorsEmail(
                new List<String>{System.Label.SalesApps_Support_Email},
                'OpportunityOwnerAssignmentBatch - ' + Date.today().format(),
                emailDetail
            );
        }
    }

    @TestVisible
    private static Date getFilterStartDate() {
        try {
            String labelValue = System.Label.Campaign_Filter_Start_Date;
            if (String.isNotBlank(labelValue)) {
                return Date.valueOf(labelValue); // expects format yyyy-MM-dd
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG,'Could not parse Campaign_Filter_Start_Date label: ' + e.getMessage());
        }
        return null;
    }
}