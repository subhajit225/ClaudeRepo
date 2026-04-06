public class AllianceLeadConvert {
    Map<String, String> mapOfMapping;
    public boolean hasDuplicateResult{get;set;}
    public AllianceLeadConvert(){
        mapOfMapping = new Map<String, String>();
        getMapping();
        
    }
    public Id convertLeadReg(sObject sobj){
        Id i;
        Alliance_Lead__c leadObj = (Alliance_Lead__c) sObj;
        Lead convLead = new Lead();
        //leadObj.isConverted__c=True;
        for(String key: mapOfMapping.keySet()){
            if(mapOfMapping.get(key)!='Campaign'){
                String destinationField = mapOfMapping.get(key);
                system.debug('destinationField=> '+destinationField);
                Object sourceValue = leadObj.get(key);
                system.debug('sourceValue=> '+sourceValue);
                convLead.put(destinationField, sourceValue);	
            }
        }
        Database.SaveResult saveResult = Database.insert(convLead, false);
        system.debug('saveResult '+saveResult);
        
        System.debug('Successfully inserted Lead ID: ' + saveResult.getId());
        List<CampaignMember> campaignMemberList = new List<CampaignMember>();
        for(String k: mapOfMapping.keySet()){
            system.debug('Campaign__c====*****'+k);
            if(k=='Campaign__c'){ // SF-195:Satish- Changed from Campaign field to Campaign__c.
                string source1 = string.valueOf(leadObj.get(k));
                if(!string.isBlank(source1) && saveResult.getId() != null){ // SF-195:Satish- Added null check.
                    CampaignMember cms=new CampaignMember(campaignid=Id.valueof(source1),leadid=saveResult.getId());
                    campaignMemberList.add(cms);
                }
            }
        }
        if(!campaignMemberList.isEmpty()){
            insert campaignMemberList;
        }
        i=saveResult.getId();
        
        return i;
    }
    
    
    public void getMapping(){
        List<AllianceleadLeadMapping__c> leadMappings = AllianceleadLeadMapping__c.getAll().values();
        for(AllianceleadLeadMapping__c mapping : leadMappings) {
            mapOfMapping.put(mapping.Name,mapping.LeadFields__c); 
        }
    }
    
}