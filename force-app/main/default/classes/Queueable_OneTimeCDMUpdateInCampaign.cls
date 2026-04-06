/**
 * @name - Queueable_OneTimeCDMUpdateInCampaign
 * @description - One time Queueable class to update CDM__c Field in Campaign with Campaign_Partner__r.OwnerId and execute the Lead and Contact Batch Class
 */
public class Queueable_OneTimeCDMUpdateInCampaign implements Queueable {
    
    private static final Date FILTER_START_DATE = Date.newInstance(2025, 2, 1);
    
    /**
     * @description - Execute method to update CDM with Campaign_Partner__r.OwnerId
    * @param context QueueableContext - the queueable context
     */
    public void execute(QueueableContext context) {
        List<Campaign> campaignsList = [SELECT Id, StartDate, Campaign_Partner__c, Campaign_Partner__r.OwnerId, CDM__c FROM Campaign 
                                        WHERE StartDate >= :FILTER_START_DATE AND Campaign_Partner__c != null AND Campaign_Partner__r.RecordType.Name = 'Partner/Distributor'
                                        AND (Type != 'Tradeshow / Conference (3rd Party Hosted)' OR Consent_Proof_Link__c != null)];
        List<Campaign> campaignsToUpdate = new List<Campaign>();
        for(Campaign c: campaignsList){
            Id newOwner = c.Campaign_Partner__r.OwnerId;
            if(newOwner != null && c.CDM__c != newOwner){
                c.CDM__c = newOwner;
                campaignsToUpdate.add(c);
            }
        }
        if(!campaignsToUpdate.isEmpty()){
            flowControll.campaignTrigger = false;
            Database.update(campaignsToUpdate, false);
            flowControll.campaignTrigger = true;
        }
        
        Database.executeBatch(new Batch_OneTimeCDMUpdateInLead(), 2000);
    }

}