/**
 * @description Helper class for CVEOpportunityContactTrigger
 * @createdDate 11-August-2025
 */ 
public class CVEOpportunityContactTriggerHelper {

    public static Integer MAX_COUNT = Integer.valueOf(System.Label.CXO_Max_Contact_Opportunity_Count);//Maximum contacts or opportunities allowed on one CVE Engagement record

    /**
     * @description update Contact and Opportunity fields on CVE Engagement records, based on CVE_Opportunity_Contact records
     * @param cveOppContactLst
     * @param newOrUpdatedRecord
     */ 
    public static void updateContactAndOpportunityFieldsOnCveEng(List<CVE_Opportunity_Contact__c> cveOppContactLst, CVE_Opportunity_Contact__c newOrUpdatedRecord){        
        Map<Id, List<CVE_Opportunity_Contact__c>> cveEngIdToCveOppConLstMap = new Map<Id, List<CVE_Opportunity_Contact__c>>();
        //Prepare a map of CVE_EngagementId to List of CVE_Opp_Contact records
        for(CVE_Opportunity_Contact__c cveOppCon : cveOppContactLst){
            if(!cveEngIdToCveOppConLstMap.containsKey(cveOppCon.CVE_Engagement__c)){
                cveEngIdToCveOppConLstMap.put(cveOppCon.CVE_Engagement__c, new List<CVE_Opportunity_Contact__c>());
            }
            cveEngIdToCveOppConLstMap.get(cveOppCon.CVE_Engagement__c).add(cveOppCon);
        }
        
        //Get CVE_Engagement records 
        List<CVE_Engagement__c> cveEngagementLst = [SELECT Id, Contact__c, Opportunity__c
                                                    FROM CVE_Engagement__c 
                                                    WHERE Id IN :cveEngIdToCveOppConLstMap.keySet()];
        
        Set<Id> contactIdsSet = new Set<Id>();
        Set<Id> oppIdsSet = new Set<Id>();
        for(CVE_Engagement__c cve : cveEngagementLst){
            cve.Contact__c = '';
            cve.Opportunity__c = '';
            contactIdsSet = new Set<Id>();
            oppIdsSet = new Set<Id>();
            for(CVE_Opportunity_Contact__c cveOppCon : cveEngIdToCveOppConLstMap.get(cve.Id)){
                //Avoid duplicate contact
                if(contactIdsSet.contains(cveOppCon.Contact__c)){
                    newOrUpdatedRecord.addError('Please select another contact, contact already present.');
                }
                //Populate Contact__c field - url to contact records 
                if(cveOppCon.Contact__c != null && !contactIdsSet.contains(cveOppCon.Contact__c)){                   
                    if(String.isBlank(cve.Contact__c)){
                        cve.Contact__c = '<a href="' + CXORequestForm.getSFBaseURL()+'/'+cveOppCon.Contact__c + '">' + cveOppCon.Contact__r.Name + '</a>';
                    } else {
                        cve.Contact__c = cve.Contact__c +','+ '<a href="' + CXORequestForm.getSFBaseURL()+'/'+cveOppCon.Contact__c + '">' + cveOppCon.Contact__r.Name + '</a>';
                    }
                    contactIdsSet.add(cveOppCon.Contact__c);
                }
                //Avoid duplicate opportunity
                if(oppIdsSet.contains(cveOppCon.Opportunity__c)){
                    newOrUpdatedRecord.addError('Please select another opportunity, opportunity already present.');
                }
                //Populate Opportunity__c field  - url to opportunity records 
                if(cveOppCon.Opportunity__c != null && !oppIdsSet.contains(cveOppCon.Opportunity__c)){                   
                    if(String.isBlank(cve.Opportunity__c)){
                        cve.Opportunity__c = '<a href="' + CXORequestForm.getSFBaseURL()+'/'+cveOppCon.Opportunity__c + '">' + cveOppCon.Opportunity__r.Name + '</a>';
                    } else {
                        cve.Opportunity__c = cve.Opportunity__c +','+ '<a href="' + CXORequestForm.getSFBaseURL()+'/'+cveOppCon.Opportunity__c + '">' + cveOppCon.Opportunity__r.Name + '</a>';
                    }
                    oppIdsSet.add(cveOppCon.Opportunity__c);
                }
            }
        }
        if(!cveEngagementLst.isEmpty()){
            UPDATE cveEngagementLst;
        }        
    }
    
    /**
     * @description validate number of contacts and opportunities linked to CVE Engagement record, maximum 5 contacts/opportunities are allowed
     * @param cveOppConLst
     * @param cveEngagementIdsSet
     * @return String
     */   
    public static String validateNoOfContactAndOpp(List<CVE_Opportunity_Contact__c> cveOppConLst, Set<Id> cveEngagementIdsSet){
        Map<Id, Set<Id>> cveToContactIdsSetMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> cveToOppIdsSetMap = new Map<Id, Set<Id>>();
        
        for(CVE_Opportunity_Contact__c cveOppCon : cveOppConLst){
            //CVE_EngagementId to set of contactIds linked to it
            if(cveOppCon.Contact__c != null){
                if(!cveToContactIdsSetMap.containsKey(cveOppCon.CVE_Engagement__c)){
                    cveToContactIdsSetMap.put(cveOppCon.CVE_Engagement__c, new Set<Id>());
                }
                cveToContactIdsSetMap.get(cveOppCon.CVE_Engagement__c).add(cveOppCon.Contact__c);
            }
            //CVE_EngagementId to set of opportunityIds linked to it
            if(cveOppCon.Opportunity__c != null){
                if(!cveToOppIdsSetMap.containsKey(cveOppCon.CVE_Engagement__c)){
                    cveToOppIdsSetMap.put(cveOppCon.CVE_Engagement__c, new Set<Id>());
                }
                cveToOppIdsSetMap.get(cveOppCon.CVE_Engagement__c).add(cveOppCon.Opportunity__c);
            }
        }
        
        for(Id cveEngId : cveEngagementIdsSet){
            //check if max contact count is exceed or not
            if(cveToContactIdsSetMap.containsKey(cveEngId) && cveToContactIdsSetMap.get(cveEngId).size() > MAX_COUNT){
                return System.Label.CXO_Maximum_Contact_Exceeded;
            }
            //check if max opportunity count is exceed or not
            if(cveToOppIdsSetMap.containsKey(cveEngId) && cveToOppIdsSetMap.get(cveEngId).size() > MAX_COUNT){
                return System.Label.CXO_Maximum_Opportunity_Exceeded;
            }
        }
        return null;
    }        
}