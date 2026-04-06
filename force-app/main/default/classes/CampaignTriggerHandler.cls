public without sharing class CampaignTriggerHandler {

    public static void createMemberStatus(Map<Id,Campaign> newCampMap){
        try{
			CampaignMemberStatusBatch batch = new CampaignMemberStatusBatch(newCampMap);
            Database.executeBatch(batch,1); //To create Member statuses on Campaign creation
        }catch(Exception e){
            System.debug('@@ Exception occurred '+e.getMessage()+' at line '+e.getLineNumber());
        }
    }
    public static void populateActualCost(List<Campaign> newCampList, Map<Id,Campaign> oldCampMap){
        Map<Id,Campaign> pfrcampMap = new Map<Id,Campaign>();
        for(Campaign cmp : newCampList){
            if(cmp.Partner_Fund_Request__c != null && oldCampMap.get(cmp.Id).Partner_Fund_Request__c != cmp.Partner_Fund_Request__c){
                pfrcampMap.put(cmp.Partner_Fund_Request__c,cmp);
            }   
        }
        if(!pfrcampMap.isEmpty()){
            for(PartnerFundRequest pfr :[select Id,TotalApprovedFcs,status from PartnerFundRequest where Id IN:pfrcampMap.keySet() AND status = 'Approved']){
                pfrcampMap.get(pfr.Id).ActualCost = pfr.TotalApprovedFcs;
            }
        }  
    }
    public static void checkActive(List<Campaign> newCampaigns) {
        for(Campaign newCampaign : newCampaigns){
            newCampaign.isActive = true;
        }
    }
    
    public static void populateCDM(List<Campaign> newCampList, Map<Id,Campaign> oldCampMap){
        Set<Id> accountIds = new Set<Id>();
        for(Campaign cmpObj : newCampList){
            if(cmpObj.Campaign_Partner__c != null && cmpObj.Partner_Fund_Request__c == null){
                accountIds.add(cmpObj.Campaign_Partner__c);
            }
        }
        if(!accountIds.isEmpty()){
            Map<Id, Account> cmpPartnerToOwnerMap = new Map<Id, Account>([SELECT Id, OwnerId, Owner.IsActive FROM Account WHERE Id IN : accountIds]);
            for(Campaign cmp : newCampList){
                if(cmpPartnerToOwnerMap.containsKey(cmp.Campaign_Partner__c) && cmpPartnerToOwnerMap.get(cmp.Campaign_Partner__c).Owner.IsActive &&  (oldCampMap == null || (oldCampMap != null && cmp.Campaign_Partner__c != oldCampMap.get(cmp.Id).Campaign_Partner__c))){
                    cmp.CDM__c = cmpPartnerToOwnerMap.get(cmp.Campaign_Partner__c).OwnerId;
                }else if(cmpPartnerToOwnerMap.containsKey(cmp.Campaign_Partner__c) && !cmpPartnerToOwnerMap.get(cmp.Campaign_Partner__c).Owner.IsActive && oldCampMap != null && cmp.Campaign_Partner__c != oldCampMap.get(cmp.Id).Campaign_Partner__c){
                    cmp.CDM__c = null;
                }
            }
        }
        
    }
}