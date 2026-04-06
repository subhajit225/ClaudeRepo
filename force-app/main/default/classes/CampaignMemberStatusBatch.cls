/**
 * @description Batch class to create Campaign Member Status records based on Campaign Types.
 * This class implements the Database.Batchable and Database.Stateful interfaces to handle large volumes of Campaigns.
 */
public class CampaignMemberStatusBatch implements Database.Batchable<SObject>, Database.Stateful {
    Map<Id, Campaign> idCampaignMap = new Map<Id, Campaign>();
    private Map<String, List<CamapignMemberStatus__mdt>> campaignMemberTypeToStatusesMap;

    // Removed camprecordTypeMap as it's no longer needed for record type mapping
    // Map<string, string> camprecordTypeMap = new Map<string, string>(); 
    Map<String, List<CamapignMemberStatus__mdt>> memstatusTypeMap = new Map<String, List<CamapignMemberStatus__mdt>>(); // Renamed for clarity

    /**
     * @description Constructor to initialize the batch class with a map of Campaign Ids to Campaign records.
     * @param idCampaignMapBatch Map of Campaign Ids to Campaign records.
     * This map is used to filter the Campaigns that will be processed in the batch.
     * It also initializes the mapping of Campaign Types to their corresponding Campaign Member Statuses from the custom metadata type.
     */
    public CampaignMemberStatusBatch(Map<Id, Campaign> idCampaignMapBatch) {
        idCampaignMap = idCampaignMapBatch;

        campaignMemberTypeToStatusesMap = new Map<String, List<CamapignMemberStatus__mdt>>();
        for (CamapignMemberStatus__mdt mapping : [SELECT Type__c, MasterLabel, Is_Default__c, HasResponded__c FROM CamapignMemberStatus__mdt WHERE Type__c != null]) {
            if (!campaignMemberTypeToStatusesMap.containsKey(mapping.Type__c)) {
                campaignMemberTypeToStatusesMap.put(mapping.Type__c, new List<CamapignMemberStatus__mdt>());
            }
            campaignMemberTypeToStatusesMap.get(mapping.Type__c).add(mapping);
        }
    }

    /**
     * @description Method to start the batch process.
     * This method queries all Campaigns that might need status updates, excluding those with RecordType 'Event'.
     * @param BC The Database.BatchableContext provided by the batch framework.
     * @return A QueryLocator for the Campaigns to be processed.
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
         // Query all Campaigns that might need status updates
        // Consider adding a WHERE clause if you only need to process specific types of campaigns
        return Database.getQueryLocator([
            SELECT Id, Name, Type // Assuming 'Type' field on Campaign stores CampaignMemberType
            FROM Campaign
            WHERE Id IN :idCampaignMap.keyset() // Exclude Event record type
            AND Type != null // Ensure we only process campaigns with a defined type
        ]);
    }

    /**
     * @description Method to execute the batch process.
     * This method processes a batch of Campaigns, checking their types against the Custom Metadata Type mappings,
     * and creates new Campaign Member Status records as needed.
     * @param BC The Database.BatchableContext provided by the batch framework.
     * @param scope The list of Campaign records to be processed in this batch.
     */
    public void execute(Database.BatchableContext BC, List<Campaign> scope) {
        List<CampaignMemberStatus> newCampaignMemberStatuses = new List<CampaignMemberStatus>();
        Set<Id> campaignIdsInScope = new Set<Id>();
        for (Campaign camp : scope) {
            campaignIdsInScope.add(camp.Id);
        }

        // Get existing CampaignMemberStatuses for the Campaigns in the current batch
        // Use a Map for efficient lookup: CampaignId -> Set of existing Status Names
        Map<Id, Set<String>> existingStatusesByCampaignId = new Map<Id, Set<String>>();
        for (CampaignMemberStatus cms : [SELECT CampaignId, Label FROM CampaignMemberStatus WHERE CampaignId IN :campaignIdsInScope]) {
            if (!existingStatusesByCampaignId.containsKey(cms.CampaignId)) {
                existingStatusesByCampaignId.put(cms.CampaignId, new Set<String>());
            }
            existingStatusesByCampaignId.get(cms.CampaignId).add(cms.Label);
        }

        for (Campaign camp : scope) {
            String campaignMemberType = camp.Type; // Adjust field name if different

            if (campaignMemberType != null && campaignMemberTypeToStatusesMap.containsKey(campaignMemberType)) {
                List<CamapignMemberStatus__mdt> requiredStatuses = campaignMemberTypeToStatusesMap.get(campaignMemberType);
                Set<String> currentCampaignStatuses = existingStatusesByCampaignId.containsKey(camp.Id)?existingStatusesByCampaignId.get(camp.Id):new Set<String>();

                // Check if the required statuses already exist for the campaign
                // If not, prepare to insert them
                for (CamapignMemberStatus__mdt requiredStatus : requiredStatuses) {
                    // Only add if the status does not already exist for this campaign
                    // and if it is not already in the currentCampaignStatuses set
                    if (!currentCampaignStatuses.contains(requiredStatus.MasterLabel)) {
                        newCampaignMemberStatuses.add(new CampaignMemberStatus(
                            CampaignId = camp.Id,
                            Label = requiredStatus.MasterLabel,
                            IsDefault = requiredStatus.Is_Default__c,
                            HasResponded = requiredStatus.HasResponded__c
                        ));
                    }
                }
            }
        }

        // Insert new Campaign Member Statuses
        if (!newCampaignMemberStatuses.isEmpty()) {
                insert newCampaignMemberStatuses;
        }
    }
    /**
     * @description Method to finish the batch process.
     * This method is called after all batches have been processed.
     * It can be used for any final cleanup or logging.
     * @param BC The Database.BatchableContext provided by the batch framework.
     */
    public void finish(Database.BatchableContext BC) {
        System.debug(System.LoggingLevel.INFO, 'Campaign Member Status Batch Process Completed');
    }
}