/**
 * @description Apex handler for CVE_Opportunity_Contact trigger
 * @createdDate 22-July-2025
 */ 
public without sharing class CVEOpportunityContactTriggerHandler extends TriggerManager.GenericTriggerHandler{

    /**
     * @description handle after CVE_Opportunity_Contact insert logic
     * @param newRecordsMap
     */
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap){
        List<CVE_Opportunity_Contact__c> newCveOppContactLst = (List<CVE_Opportunity_Contact__c>)newRecordsMap.values();
        Set<Id> cveEngagementIdsSet = new Set<Id>();
        //Get CVEengagement Ids for inserted CVE_Opp_Contact records
        for(CVE_Opportunity_Contact__c cveOppCon : newCveOppContactLst){
            if(cveOppCon.Contact__c != null || cveOppCon.Opportunity__c !=null){
                cveEngagementIdsSet.add(cveOppCon.CVE_Engagement__c);
            }
        }
        
        if(!cveEngagementIdsSet.isEmpty()){
            //Get all CVE_Opp_Contact records(existing+Newly Inserted) for engagementIds
            List<CVE_Opportunity_Contact__c> cveOppContactLst = [SELECT Id, CVE_Engagement__c, Contact__c, Contact__r.Name, Opportunity__c, Opportunity__r.Name
                                                                 FROM CVE_Opportunity_Contact__c
                                                                 WHERE CVE_Engagement__c IN :cveEngagementIdsSet];
            
            //Validate no of contacts and opportunities linked to one CVE Engagement (Max is 5)
            String error = CVEOpportunityContactTriggerHelper.validateNoOfContactAndOpp(cveOppContactLst, cveEngagementIdsSet);
            if(String.isNotBlank(error) && !newCveOppContactLst.isEmpty()){
                newCveOppContactLst[0].addError(error);
            }
            
            //populate fields Contact__c and Opportunity__c on CVE Engagement record
            if(!newCveOppContactLst.isEmpty()){
                CVEOpportunityContactTriggerHelper.updateContactAndOpportunityFieldsOnCveEng(cveOppContactLst, newCveOppContactLst[0]);
            }
        }
    }   
    
    /**
     * @description handle after CVE_Opportunity_Contact__c record update logic
     * @param oldRecordsMap
     * @param newRecordsMap
     */ 
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        List<CVE_Opportunity_Contact__c> updatedCveOppConLst = (List<CVE_Opportunity_Contact__c>)newRecordsMap.values();
        Map<Id, CVE_Opportunity_Contact__c> oldCveOppConMap = (Map<Id, CVE_Opportunity_Contact__c>)oldRecordsMap;
        Set<Id> cveEngagementIdsSet = new Set<Id>();
        //Get cve engagement Ids for updated CVE_Opp_Contact records 
        for(CVE_Opportunity_Contact__c cveOppCon : updatedCveOppConLst){
            CVE_Opportunity_Contact__c oldCveOppCon = oldCveOppConMap.get(cveOppCon.Id);
            if(cveOppCon.Contact__c != oldCveOppCon.Contact__c || cveOppCon.Opportunity__c != oldCveOppCon.Opportunity__c || cveOppCon.CVE_Engagement__c != oldCveOppCon.CVE_Engagement__c){
				cveEngagementIdsSet.add(cveOppCon.CVE_Engagement__c);
            }
        }
        
        if(!cveEngagementIdsSet.isEmpty()){
            //Get all CVE_Opp_Contact records(existing+updated) for engagementIds
            List<CVE_Opportunity_Contact__c> cveOppContactLst = [SELECT Id, CVE_Engagement__c, Contact__c, Contact__r.Name, Opportunity__c, Opportunity__r.Name
                                                                 FROM CVE_Opportunity_Contact__c
                                                                 WHERE CVE_Engagement__c IN :cveEngagementIdsSet];
            
            //Validate no of contacts and opportunities linked to one CVE Engagement (Max is 5)
            String error = CVEOpportunityContactTriggerHelper.validateNoOfContactAndOpp(cveOppContactLst, cveEngagementIdsSet);
            if(String.isNotBlank(error) && !updatedCveOppConLst.isEmpty()){
                updatedCveOppConLst[0].addError(error);
            }
            
            //populate fields Contact__c and Opportunity__c on CVE Engagement record
            if(!updatedCveOppConLst.isEmpty()){
                CVEOpportunityContactTriggerHelper.updateContactAndOpportunityFieldsOnCveEng(cveOppContactLst, updatedCveOppConLst[0]);
            }
        }
    }

    /**
     * @description handle after CVE_Opportunity_Contact__c record delete logic
     * @param oldRecordsMap
     */ 
    public override void onBeforeDelete(Map<Id, sObject> oldRecordsMap){
        List<CVE_Opportunity_Contact__c> deletedCveOppConLst = (List<CVE_Opportunity_Contact__c>)oldRecordsMap.values();
        Set<Id> cveEngagementIdsSet = new Set<Id>();
        //Get cve engagement Ids for deleted CVE_Opp_Contact records 
        for(CVE_Opportunity_Contact__c cveOppCon : deletedCveOppConLst){
            if(cveOppCon.Contact__c != null || cveOppCon.Opportunity__c != null){
				cveEngagementIdsSet.add(cveOppCon.CVE_Engagement__c);
            }
        }
        
        if(!cveEngagementIdsSet.isEmpty()){
            //Get all CVE_Opp_Contact records(excluding deleted records) for engagementIds
            List<CVE_Opportunity_Contact__c> cveOppContactLst = [SELECT Id, CVE_Engagement__c, Contact__c, Contact__r.Name, Opportunity__c, Opportunity__r.Name
                                                                 FROM CVE_Opportunity_Contact__c
                                                                 WHERE CVE_Engagement__c IN :cveEngagementIdsSet 
                                                                 AND Id NOT IN :deletedCveOppConLst];
                        
            //populate fields Contact__c and Opportunity__c on CVE Engagement record
            if(cveOppContactLst.isEmpty()){
                List<CVE_Engagement__c> cveEngagementLst = [SELECT Id, Contact__c, Opportunity__c FROM CVE_Engagement__c WHERE Id IN :cveEngagementIdsSet];
                for(CVE_Engagement__c cve : cveEngagementLst){
                    cve.Contact__c = '';
                    cve.Opportunity__c = '';
                }
                if(!cveEngagementLst.isEmpty()){
                    UPDATE cveEngagementLst;
                }
            } else if(!cveOppContactLst.isEmpty() && !deletedCveOppConLst.isEmpty()){
                CVEOpportunityContactTriggerHelper.updateContactAndOpportunityFieldsOnCveEng(cveOppContactLst, deletedCveOppConLst[0]);
            }
        }
    }       
}