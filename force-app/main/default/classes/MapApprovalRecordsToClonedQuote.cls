/**
 * @description Utility class to clone approved approval records from a source quote
 *              to a target (cloned) quote. Also replicates associated snapshots and updates quote flags.
 * @author      Siddharth Ahluwalia
 * @created     2025-3-27
 * @version     1.0
 */
public class MapApprovalRecordsToClonedQuote {

    /**
     * @description Clones approval records and their associated snapshots from a source quote to the current quote.
     *              Sets a flag on the quote to prevent duplicate processing.
     * @param quoteId The ID of the quote (target) to which approval records should be copied.
     * @return Boolean True if operation is successful, False if an exception occurs.
     */
    public static Boolean createApprovalRecords(String quoteId) {
        try {
            // Initialize required collections and variables
            List<sbaa__Approval__c> approvalList = new List<sbaa__Approval__c>(); 
            Set<SBQQ__Quote__c> qtList = new Set<SBQQ__Quote__c>(); 
            List<SBQQ__Quote__c> qtListtoUpdate = new List<SBQQ__Quote__c>(); 
            List<sbaa__ApprovalSnapshot__c> clonedSnapshots = new List<sbaa__ApprovalSnapshot__c>();
            List<ID> sourceList = new List<ID>(); 
            SBQQ__Quote__c quote;
            Map<String, sbaa__Approval__c> ruleVSApprovalMap = new Map<String, sbaa__Approval__c>();
            Map<String, List<sbaa__ApprovalSnapshot__c>> approvalvsSnapshotMap = new Map<String, List<sbaa__ApprovalSnapshot__c>>();

            // Retrieve source quote ID from the current quote
            if (quoteId != null) {
                quote = [
                    SELECT Id, SBQQ__Source__c, Approvals_Created_from_Source__c 
                    FROM SBQQ__Quote__c 
                    WHERE Id = :quoteId 
                    LIMIT 1
                ]; 

                if (quote.SBQQ__Source__c != null) {
                    sourceList.add(quote.SBQQ__Source__c); 
                }
            }

            // Only proceed if approval records have not already been created
            if (!quote.Approvals_Created_from_Source__c) {

                // Query approval records from the source quote that are approved
                sbaa__Approval__c[] approvals = [
                    SELECT Id, sbaa__Status__c, Quote__c, sbaa__CommentsLong__c, sbaa__Rule__c
                         , sbaa__Approver__c, sbaa__ApprovalStep__c, sbaa__AssignedTo__c, sbaa__ApprovalChain__c
                         , sbaa__ApprovedBy__c, Approval_Date__c,
                          (SELECT Id, sbaa__ApprovalCondition__c, sbaa__ApprovedValueNumeric__c, sbaa__ApprovedValueText__c 
                            FROM sbaa__ApprovalSnapshot__r 
                            ORDER BY CreatedDate DESC)
                    FROM sbaa__Approval__c 
                    WHERE Quote__c IN :sourceList 
                    AND sbaa__Status__c = :Constants.STATUS_APPROVED 
                      AND sbaa__Rule__c IN (
                            SELECT sbaa__ApprovalRule__c 
                             FROM sbaa__ApprovalCondition__c 
                            WHERE Custom_Smart_Approval__c = true 
                                OR sbaa__EnableSmartApproval__c =true)
                    ORDER BY sbaa__Rule__c, Approval_Date__c, LastModifiedDate DESC 
                    LIMIT 200
                ];
                // Deduplicate by rule and capture snapshots
                for (sbaa__Approval__c ap : approvals) {
                    if (!approvalvsSnapshotMap.containsKey(ap.Id) &&
                        ap.sbaa__ApprovalSnapshot__r != null &&
                        !ap.sbaa__ApprovalSnapshot__r.isEmpty()) {
                        approvalvsSnapshotMap.put(ap.Id, ap.sbaa__ApprovalSnapshot__r);
                    }

                    if (!ruleVSApprovalMap.containsKey(ap.sbaa__Rule__c)) {
                        ruleVSApprovalMap.put(ap.sbaa__Rule__c, ap);
                    }
                }

                // Create cloned approval records for the new quote
                for (sbaa__Approval__c app : ruleVSApprovalMap.values()) {
                    sbaa__Approval__c appRecord = new sbaa__Approval__c(
                        Quote__c = quoteId,
                        sbaa__Approver__c = app.sbaa__Approver__c,
                        sbaa__CommentsLong__c = app.sbaa__CommentsLong__c,
                        sbaa__Status__c = app.sbaa__Status__c,
                        sbaa__ApprovalStep__c = app.sbaa__ApprovalStep__c,
                        sbaa__RecordField__c = 'Quote__c',
                        sbaa__AssignedTo__c = app.sbaa__AssignedTo__c,
                        sbaa__ApprovalChain__c = app.sbaa__ApprovalChain__c,
                        sbaa__Rule__c = app.sbaa__Rule__c,
                        Approvals_from_Source_Quote__c = true,
                        Approval_Date__c = app.Approval_Date__c
                    );
                    if(!test.isrunningtest()){
                        appRecord.sbaa__ApprovedBy__c = System.Label.Smart_Approved;
                        }
                    approvalList.add(appRecord);
                }

                // Insert the cloned approval records
                insert approvalList;

                // Map newly inserted approval records back to rule for snapshot cloning
                for (sbaa__Approval__c appr : [
                    SELECT Id, sbaa__Rule__c FROM sbaa__Approval__c WHERE Id IN :approvalList
                ]) {

                    // Clone approval snapshots
                    if (approvalvsSnapshotMap.containsKey(ruleVSApprovalMap.get(appr.sbaa__Rule__c).ID)) {
                        for (sbaa__ApprovalSnapshot__c snaps : approvalvsSnapshotMap.get(ruleVSApprovalMap.get(appr.sbaa__Rule__c).ID)) {
                            sbaa__ApprovalSnapshot__c snapshot = new sbaa__ApprovalSnapshot__c(
                                sbaa__Approval__c = appr.Id,
                                sbaa__ApprovalCondition__c = snaps.sbaa__ApprovalCondition__c,
                                sbaa__ApprovedValueNumeric__c = snaps.sbaa__ApprovedValueNumeric__c,
                                sbaa__ApprovedValueText__c = snaps.sbaa__ApprovedValueText__c
                            );
                            clonedSnapshots.add(snapshot);
                        }
                    }

                    // Flag the quote to avoid duplicate cloning
                    SBQQ__Quote__c qt = new SBQQ__Quote__c(
                        Id = quoteId,
                        Approvals_Created_from_Source__c = true
                    );
                    qtList.add(qt);
                }

                // Insert cloned snapshots
                qtListtoUpdate.addAll(qtList);
                insert clonedSnapshots;

                // Disable quote trigger during update to avoid recursive logic
                TriggerControls.disableQuoteTrigger = true;
                update qtListtoUpdate;
                TriggerControls.disableQuoteTrigger = false;
            }

            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception occurred in createApprovalRecords: ' + e.getMessage());
            return false;
        }
    }
}