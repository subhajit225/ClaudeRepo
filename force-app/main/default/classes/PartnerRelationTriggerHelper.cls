public without sharing class PartnerRelationTriggerHelper {
    public static Set<String> dupInvolvementTypes = new Set<String>{'Transacting Partner','Sourcing Partner','Distributor','Incumbent Partner'};
        public static Set<String> dupPartnerTypes = new Set<String>{'Teaming Partner','TAP Alliance','Influence Partner'};
            /**
* Updates the Partner Relation fields based on changes in the Partner Account.
*/
    /*public static void updatePartnerRelationFields(Map<ID, Partner_Relation__c> oldRecordsMap, List<Partner_Relation__c> newRecords) {         
        Set<Id> accountIds = new Set<Id>();
        List<Partner_Relation__c> prRecords = new List<Partner_Relation__c>();
        for(Partner_Relation__c pr: newRecords) {
            // Check if this is an insert operation and the Partner Account is not null
            if(oldRecordsMap == null && pr.Partner_Account__c != null){
                accountIds.add(pr.Partner_Account__c);
                prRecords.add(pr);
            }
            // Check if this is an update operation and the Partner Account has changed
            else if(oldRecordsMap != null && pr.Partner_Account__c != null && oldRecordsMap.get(pr.Id).Partner_Account__c != pr.Partner_Account__c){
                accountIds.add(pr.Partner_Account__c);
                prRecords.add(pr);
            } 
        }
        if(accountIds.isEmpty()){
            return;
        }
        Map<Id, Account> accountPRMap = new Map<Id, Account>([SELECT National_Partner__c, Focused_Partner__c, MSP_Sub_Type__c FROM Account WHERE Id IN :accountIds]);
        // Iterate through the Partner Relation records to update the fields
        for (Partner_Relation__c pr : prRecords) {
            if (accountPRMap != null && accountPRMap.containsKey(pr.Partner_Account__c)) {
                Account prAccount = accountPRMap.get(pr.Partner_Account__c);
                pr.National_Flag__c = prAccount.National_Partner__c;
                pr.Focus_Flag__c = prAccount.Focused_Partner__c;
                pr.SDP_Sub_Type__c = prAccount?.MSP_Sub_Type__c;
            }
        }
    }*/
    /**
* Check duplicates of Involvement Type with same Opportunity -> PRIT25-751
* Check duplicates of Involvement Type with SDP ub Type with same Partner Account -> PRIT25-752
* Also checks if the Relation record fields are getting updates when its related Opportunity is Stage 6 or Stage 7 -> PRIT25-753
*/
    public static void checkDuplicates(Map<ID, Partner_Relation__c> oldRecordsMap, List<Partner_Relation__c> newRecords)
    {
        Set<Id> prIds = new Set<Id>();
        Map<Id, Set<String>> oppWithPIIType = new Map<Id, Set<String>>();
        Map<Id, Set<String>> oppToPRTypes = new Map<Id, Set<String>>();
        Map<Id, String> oppIdToStageMap = new Map<Id, String>(); 
        
        for( Partner_Relation__c pr : newRecords)
        {
            oppIdToStageMap.put(pr.Opportunity__c, pr.Opportunity_StageName__c);//PRIT25-751
        }
        
        for(Partner_Relation__c pr : [SELECT Id, Involvement_Type__c, Influence_Sub_Type__c, Partner_Account__c, Opportunity__c, Opportunity__r.StageName FROM Partner_Relation__c WHERE Opportunity__c IN : oppIdToStageMap.keySet()])
        {
            
            //PRIT25-753 
            if(oldRecordsMap != null && oldRecordsMap.containsKey(pr.Id) && oppIdToStageMap.containsKey(pr.Opportunity__c))
            {
                if(pr.Opportunity__r.StageName.contains('7 Closed') || pr.Opportunity__r.StageName.contains('6 PO'))
                    prIds.add(pr.Id);
            }
            
            //PRIT25-751
            if(!oppToPRTypes.isEmpty() && oppToPRTypes.containsKey(pr.Opportunity__c) && dupInvolvementTypes.contains(pr.Involvement_Type__c)){
                Set<String> involvementTypes = oppToPRTypes.get(pr.Opportunity__c);
                involvementTypes.add(pr.Involvement_Type__c);
                oppToPRTypes.put(pr.Opportunity__c, involvementTypes);
            }else if(dupInvolvementTypes.contains(pr.Involvement_Type__c)){
                oppToPRTypes.put(pr.Opportunity__c, new Set<String>{pr.Involvement_Type__c});
            }
            
            //PRIT25-752
            if(dupPartnerTypes.contains(pr.Involvement_Type__c) && !oppWithPIIType.isEmpty() && oppWithPIIType.containsKey(pr.Opportunity__c))
            {
                String value = pr.Partner_Account__c + pr.Involvement_Type__c + pr.Influence_Sub_Type__c;
                Set<String> values = oppWithPIIType.get(pr.Opportunity__c);
                values.add(value);
                oppWithPIIType.put(pr.Opportunity__c,values);
					                
            }else if(dupPartnerTypes.contains(pr.Involvement_Type__c))
            {
                oppWithPIIType.put(pr.Opportunity__c, new Set<String>{pr.Partner_Account__c + pr.Involvement_Type__c + pr.Influence_Sub_Type__c});
            }
        }
        
        for( Partner_Relation__c pr : newRecords ){
            
            if(oldRecordsMap == null)
            {
                    //PRIT25-753 //SAL26-215
                if(pr.Opportunity__c != null && oppIdToStageMap.containsKey(pr.Opportunity__c) 
                   && pr.Opportunity_Type__c != 'Debooking' && !System.Label.PR_Bypass_User_Ids.contains(UserInfo.getUserId()) 
				   && (oppIdToStageMap.get(pr.Opportunity__c).contains('7 Closed') ||  (!pr.Opportunity_Is_child_Renewal_split__c && oppIdToStageMap.get(pr.Opportunity__c).contains('6 PO')))  
                  )
                {
                    pr.addError('Opportunity is in Stage 6 or Stage 7, Partner Relations record creation is not allowed');
                }
                
                //PRIT25-751
                if(!oppToPRTypes.isEmpty() && oppToPRTypes.containsKey(pr.Opportunity__c) && oppToPRTypes.get(pr.Opportunity__c).contains(pr.Involvement_Type__c) && dupInvolvementTypes.contains(pr.Involvement_Type__c)){
                    pr.addError('Duplicate Involvement Type : '+  pr.Involvement_Type__c +' for Opportunity - Please check existing records.' );
                }else{
                    //add new type to the map for if next element is of same type on the same opp to throw error
                    Set<String> involvementTypes = oppToPRTypes.get(pr.Opportunity__c) != null ? oppToPRTypes.get(pr.Opportunity__c) : new Set<String>();
                    involvementTypes.add(pr.Involvement_Type__c);
                    oppToPRTypes.put(pr.Opportunity__c, involvementTypes);
                }
                
                //PRIT25-752
                if(!oppWithPIIType.isEmpty() && oppWithPIIType.containsKey(pr.Opportunity__c) 
                   && oppWithPIIType.get(pr.Opportunity__c).contains(pr.Partner_Account__c + pr.Involvement_Type__c + pr.Influence_Sub_Type__c)
                   && dupPartnerTypes.contains(pr.Involvement_Type__c))
                {
                    pr.addError('Duplicate Involvement Type : '+pr.Involvement_Type__c+ ' for Partner Account on this Opportunity - Please check existing records.');
                }else{
                    Set<String> values = oppWithPIIType.get(pr.Opportunity__c) != null ? oppWithPIIType.get(pr.Opportunity__c) : new Set<String>();
                    values.add(pr.Partner_Account__c + pr.Involvement_Type__c + pr.Influence_Sub_Type__c);
                    oppWithPIIType.put(pr.Opportunity__c,values);
                }
                
            }
            else if(oldRecordsMap != null)
            {
                //PRIT25-753
                if( (oldRecordsMap.get(pr.Id).Involvement_Type__c != pr.Involvement_Type__c
                  	|| oldRecordsMap.get(pr.Id).Influence_Sub_Type__c != pr.Influence_Sub_Type__c 
                  	|| oldRecordsMap.get(pr.Id).Partner_Account__c != pr.Partner_Account__c)
                  	&& prIds.contains(pr.Id) )
                {
                    pr.addError('Opportunity is in Stage 6 or Stage 7, Modification to these fields: National Flag, Focus Flag, SDP Sub Type, Involvement Type, Partner Sub Type, Partner Account are not allowed.');
                }
                
                //PRIT25-751
                if( (oldRecordsMap.get(pr.Id).Involvement_Type__c != pr.Involvement_Type__c
                    || oldRecordsMap.get(pr.Id).Opportunity__c != pr.Opportunity__c) 
                   && dupInvolvementTypes.contains(pr.Involvement_Type__c))
                {
                    if(!oppToPRTypes.isEmpty() && oppToPRTypes.containsKey(pr.Opportunity__c) && oppToPRTypes.get(pr.Opportunity__c).contains(pr.Involvement_Type__c)){
                        pr.addError('Duplicate Involvement Type : '+  pr.Involvement_Type__c +' for Opportunity - Please check existing records.' );
                    }else{
                        //add new type to the map for if next element is of same type on the same opp to throw error
                        Set<String> involvementTypes = oppToPRTypes.get(pr.Opportunity__c) != null ? oppToPRTypes.get(pr.Opportunity__c) : new Set<String>();
                        involvementTypes.add(pr.Involvement_Type__c);
                        oppToPRTypes.put(pr.Opportunity__c, involvementTypes);
                    }
                }
                
                //PRIT25-752
                if((pr.Involvement_Type__c != oldRecordsMap.get(pr.Id).Involvement_Type__c 
                    || pr.Influence_Sub_Type__c != oldRecordsMap.get(pr.Id).Influence_Sub_Type__c
                    || pr.Partner_Account__c != oldRecordsMap.get(pr.Id).Partner_Account__c
                    || pr.Opportunity__c != oldRecordsMap.get(pr.Id).Opportunity__c)
                    && dupPartnerTypes.contains(pr.Involvement_Type__c)
                  ){
                      if(!oppWithPIIType.isEmpty() && oppWithPIIType.containsKey(pr.Opportunity__c) 
                         && oppWithPIIType.get(pr.Opportunity__c).contains(pr.Partner_Account__c + pr.Involvement_Type__c + pr.Influence_Sub_Type__c)){
                          pr.addError('Duplicate Involvement Type : '+pr.Involvement_Type__c+ ' for Partner Account on this Opportunity - Please check existing records.');
                      }else{
                          Set<String> values = oppWithPIIType.get(pr.Opportunity__c) != null ? oppWithPIIType.get(pr.Opportunity__c) : new Set<String>();
                          values.add(pr.Partner_Account__c + pr.Involvement_Type__c + pr.Influence_Sub_Type__c);
                          oppWithPIIType.put(pr.Opportunity__c,values);
                      }
                  }
            }
        }
    }
      
    /** PRIT26-22
    * Maps GSI-related fields on Opportunities based on associated Partner Relations.
    * It identifies relevant partner accounts and updates Secondary AE and SE fields accordingly.
    */
    public static void opportunitySDPFieldsGSIMapping(Map<ID, Partner_Relation__c> oldRecordsMap, List<Partner_Relation__c> newPartnerRelations) {
        
        Set<String> involvementTypes = new Set<String>{'Sourcing Partner','Transacting Partner','Influence Partner'};
        Map<Id, List<Partner_Relation__c>> oppToPartnerRelationsMap = new Map<Id, List<Partner_Relation__c>>();
        Set<Id> userIdSet = new Set<Id>();

        // Build Opportunity-Partner Relation Mapping
        for (Partner_Relation__c pr : newPartnerRelations) {
            if(involvementTypes.contains(pr.Involvement_Type__c) && pr.Partner_Account__c != null &&
               (oldRecordsMap == null  || 
               (oldRecordsMap != null && oldRecordsMap.get(pr.Id).Partner_Account__c != pr.Partner_Account__c))){
                   if (!oppToPartnerRelationsMap.containsKey(pr.Opportunity__c)) {
                       oppToPartnerRelationsMap.put(pr.Opportunity__c, new List<Partner_Relation__c>());
                   }
                   oppToPartnerRelationsMap.get(pr.Opportunity__c).add(pr); 
               }
        }
        
        if (oppToPartnerRelationsMap.isEmpty()) return;
        
        // Query existing Partner Relations
        Map<Id, List<Partner_Relation__c>> existingPartnerRelationsMap = new Map<Id, List<Partner_Relation__c>>();
        for (Partner_Relation__c pr : [SELECT Id, Opportunity__c, Partner_Account__c, Partner_Account__r.ParentId, 
                                       Involvement_Type__c, CreatedDate, Opportunity_ETM_Theatre__c, Opportunity_Country__c FROM Partner_Relation__c 
                                       WHERE Opportunity__c IN :oppToPartnerRelationsMap.keySet() AND Partner_Account__r.MSP_Sub_Type__c IN ('GSI', 'GSP') AND 
                                       Involvement_Type__c IN: involvementTypes ORDER BY CreatedDate ASC]) 
        {
            if (!existingPartnerRelationsMap.containsKey(pr.Opportunity__c)) {
                existingPartnerRelationsMap.put(pr.Opportunity__c, new List<Partner_Relation__c>());
            }
            existingPartnerRelationsMap.get(pr.Opportunity__c).add(pr);
        }
        
        // Determine the relevant partner IDs before querying the custom setting
        Map<Id,String> opportunityPartnerMap = new Map<Id,String>();
        Map<Id,String> opportunityPartnerMapWithCountry = new Map<Id,String>();
        
        for (Id oppId : oppToPartnerRelationsMap.keySet()) {
            List<Partner_Relation__c> partnerRelationsList = existingPartnerRelationsMap.get(oppId);
            Partner_Relation__c prRecord = findPartner('Sourcing Partner', partnerRelationsList) ??
                findPartner('Transacting Partner', partnerRelationsList) ??
                findPartner('Influence Partner', partnerRelationsList);
            if (prRecord != null) {
                String partnerId = prRecord.Partner_Account__r.ParentId != null ? prRecord.Partner_Account__r.ParentId : prRecord.Partner_Account__c;
                opportunityPartnerMapWithCountry.put(oppId,partnerId + prRecord.Opportunity_ETM_Theatre__c + prRecord?.Opportunity_Country__c?.toLowerCase());
                opportunityPartnerMap.put(oppId,partnerId + prRecord.Opportunity_ETM_Theatre__c);
            }
        }
        
        // Query GSI BDM GAM Mapping 
        Map<String, GSI_BDM_GAM_Mapping__c> gamMappingRecords = new Map<String, GSI_BDM_GAM_Mapping__c>();
        Map<String, GSI_BDM_GAM_Mapping__c> gamMappingRecordsWithCountry = new Map<String, GSI_BDM_GAM_Mapping__c>();
        for (GSI_BDM_GAM_Mapping__c mapping : GSI_BDM_GAM_Mapping__c.getAll().values()) {
            if (!mapping.Active__c) continue;
            String partnerETM = mapping.Account_ID__c + mapping.Theatre__c;
            String partnerETMWithCountry = partnerETM + mapping?.Country__c?.toLowerCase();
            if (mapping.Country__c != null && opportunityPartnerMapWithCountry.values().contains(partnerETMWithCountry)) {
                gamMappingRecordsWithCountry.put(partnerETMWithCountry, mapping);
            } 
            if (mapping.Country__c == null && opportunityPartnerMap.values().contains(partnerETM)) {
                gamMappingRecords.put(partnerETM, mapping);
            }
            userIdSet.add(mapping.GAM_Id__c);
            userIdSet.add(mapping.BDM_Id__c);
        }
        Map<Id, String> gamTerritoriesMap = new Map<Id, String>();
        Map<Id, String> bdmTerritoriesMap = new Map<Id, String>();
        for (UserTerritory2Association userTerritory : [SELECT UserId, Territory2.Internal_Territory_Name__c FROM UserTerritory2Association WHERE UserId IN: userIdSet AND Territory2.Internal_Territory_Name__c LIKE '%GSI%' AND Territory2.Territory2Type.DeveloperName = 'Territory']) {
            if (userTerritory.Territory2.Internal_Territory_Name__c.contains('GAM')) {
                gamTerritoriesMap.put(userTerritory.UserId, userTerritory.Territory2.Internal_Territory_Name__c);
            } else if (userTerritory.Territory2.Internal_Territory_Name__c.contains('BDM')) {
                bdmTerritoriesMap.put(userTerritory.UserId, userTerritory.Territory2.Internal_Territory_Name__c);
            }
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        // Process each opportunity
        for (Id oppId : opportunityPartnerMap.keySet()) {
            Opportunity opp = new Opportunity();
            opp.Id = oppId;
            GSI_BDM_GAM_Mapping__c mapping = gamMappingRecordsWithCountry.get(opportunityPartnerMapWithCountry.get(oppId)) 
                                    		 ?? gamMappingRecords.get(opportunityPartnerMap.get(oppId));
            
            if (mapping != null) {
                opp.New_Secondary_AE__c = gamTerritoriesMap.get(mapping.GAM_Id__c);
                opp.New_Secondary_SE__c = bdmTerritoriesMap.get(mapping.BDM_Id__c);
                oppsToUpdate.add(opp);
            }
        }
        
        // Update opportunities
        if (!oppsToUpdate.isEmpty()) {
            FlowControll.opportunityTriggerHandler = false;
            Database.update(oppsToUpdate, false);
            FlowControll.opportunityTriggerHandler = true;
        }
    }
    
    private static Partner_Relation__c findPartner(String involvementType, List<Partner_Relation__c> partnerRelationsList) {
        return getActualPartner(involvementType, partnerRelationsList);
    }
    
    private static Partner_Relation__c getActualPartner(String involvementType, List<Partner_Relation__c> prRecords) {
        if (prRecords == null) return null;
        
        for (Partner_Relation__c pr : prRecords) {
            if (pr.Involvement_Type__c == involvementType) {
                return pr;
            }
        }
        return null;
    }
     /**
* Insert OpportunityTeamMember  -> SAL26-73
* Share Opportunity to the Partner relation using OpportunityTeamMember
* Delete existing sharing if partner account on partner relation changes
*/
public static void opportunitySharingToPartnerAccount(Map<ID, Partner_Relation__c> oldRecordsMap, List<Partner_Relation__c> newPartnerRelations) {
    List<OpportunityTeamMember> opportunityTeamMemberRecords = new List<OpportunityTeamMember> ();
    Map<String, String> opportunityPartnerMap = new Map<String, String> ();
    Map<String, String> oldPartnerMap = new Map<String, String> ();
    Map<String, OpportunityTeamMember> existingOpportunityMemberMap = new Map<String, OpportunityTeamMember> ();
    List<OpportunityTeamMember> otmToBeDeleted = new List<OpportunityTeamMember> ();
    Map<String, String> partnerOwnerIdMap = new Map<String, String> ();
    Set<String> involvementTypes = new Set<String>{'TAP Alliance', 'Influence Partner'};
    Map<String, List<Partner_Relation__c>> oppToPartnerRelationsMap = new Map<String, List<Partner_Relation__c>>();
    Map<String, String> oldPartnerAccountMap = new Map<String, String> ();
        Map<String, List<Partner_Relation__c>> existingPartnerRelationsMap = new Map<String, List<Partner_Relation__c>>();
        
    // Build Opportunity-Partner Relation Mapping
    for (Partner_Relation__c pr : newPartnerRelations) {
        if(involvementTypes.contains(pr.Involvement_Type__c) &&
           ((oldRecordsMap == null && pr.Partner_Account__c != null) ||
            (oldRecordsMap != null && trigger.isUpdate && pr.Partner_Account__c != null && oldRecordsMap.get(pr.Id).Partner_Account__c != pr.Partner_Account__c))) {
                if (!oppToPartnerRelationsMap.containsKey(pr.Opportunity__c)) {
                    oppToPartnerRelationsMap.put(pr.Opportunity__c, new List<Partner_Relation__c>());
                }
                oppToPartnerRelationsMap.get(pr.Opportunity__c).add(pr);
            }
    }
    if (oppToPartnerRelationsMap.isEmpty()) return;
    for(OpportunityTeamMember teamMemberRecord: [SELECT Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel, Partner_Relation__c FROM OpportunityTeamMember WHERE (OpportunityId IN: oppToPartnerRelationsMap.keySet() AND TeamMemberRole = 'Partner Relation')]) {
        String compositeKey = teamMemberRecord.OpportunityId+''+teamMemberRecord.UserId;
        existingOpportunityMemberMap.put(compositeKey, teamMemberRecord);
    }
    if(existingOpportunityMemberMap!=null) {
        delete existingOpportunityMemberMap.values();
    }
    for (Partner_Relation__c pr : [SELECT Id, Opportunity__c, Partner_Account__c, Partner_Account__r.OwnerId, Involvement_Type__c FROM Partner_Relation__c 
                                   WHERE (Opportunity__c IN :oppToPartnerRelationsMap.keySet() AND
                                          Involvement_Type__c IN: involvementTypes) ORDER BY CreatedDate ASC]) 
    {                
        opportunityPartnerMap.put(pr.Partner_Account__c, pr.Partner_Account__r.OwnerId);
        if (!existingPartnerRelationsMap.containsKey(pr.Opportunity__c)) {
            existingPartnerRelationsMap.put(pr.Opportunity__c, new List<Partner_Relation__c>());
        }
        existingPartnerRelationsMap.get(pr.Opportunity__c).add(pr);
    }
    if(!opportunityPartnerMap.isEmpty()) {
        for(String outerKey: existingPartnerRelationsMap.keySet()) {
            for(Partner_Relation__c innerKey: existingPartnerRelationsMap.get(outerKey)) {
                OpportunityTeamMember member = new OpportunityTeamMember ();
                    member.OpportunityAccessLevel = 'Read';
                    member.OpportunityId = outerKey;
                    member.TeamMemberRole = 'Partner Relation';
                    member.UserId = opportunityPartnerMap.get(innerKey.Partner_Account__c);
                    member.Partner_Relation__c = innerKey.Id;
                    opportunityTeamMemberRecords.add(member);
            }
        }
    }
    try {
        if(!opportunityTeamMemberRecords.isEmpty()) {
            Database.upsert(opportunityTeamMemberRecords, false);
        }
    } catch (Exception ex) {
        system.debug('Exception occured  opportunitySharingToPartnerAccount'+ex.getMessage()+'at Line=>'+ex.getLineNumber());
    }
    }
/**
* Update child opportunity split with partner relation-> SAL26-72
* Fetch TAP Alliance and Influence Partner relation
* copy partner relation to child opportunity
*/
    public static void updateChildSplitPartnerReation(Map<ID, Partner_Relation__c> oldRecordsMap, List<Partner_Relation__c> newPartnerRelations) {
        Set<String> involvementTypes = new Set<String>{'TAP Alliance', 'Influence Partner'};
            Map<Id, Partner_Relation__c> partnerRelationToBeUpdated = new Map<Id, Partner_Relation__c> ();
        Set<String> opportunityIds = new Set<String> ();
        Map<String, Partner_Relation__c> partnerRelationMap = new Map<String, Partner_Relation__c> ();
        Map<String, List<Partner_Relation__c>> existingPartnerRelationsMap = new Map<String, List<Partner_Relation__c>>();

        // Build Opportunity-Partner Relation Mapping
        for (Partner_Relation__c pr : newPartnerRelations) {
            if(involvementTypes.contains(pr.Involvement_Type__c) &&
            ((oldRecordsMap != null && trigger.isUpdate && pr.Partner_Account__c != null && (oldRecordsMap.get(pr.Id).Partner_Account__c != pr.Partner_Account__c || (pr.Influence_Sub_Type__c!=null && oldRecordsMap.get(pr.Id).Influence_Sub_Type__c != pr.Influence_Sub_Type__c))))) {
                opportunityIds.add(pr.Opportunity__c);
                partnerRelationMap.put(pr.Id, pr);
            }
        }
        if (opportunityIds.isEmpty()) return;
        if(!opportunityIds.isEmpty()) {
            for (Partner_Relation__c pr : [SELECT Id, Opportunity__c, Partner_Account__c, Partner_Account__r.OwnerId, Parent_Partner_Relation__r.Opportunity__c, Involvement_Type__c, Influence_Sub_Type__c FROM Partner_Relation__c 
                                        WHERE (Involvement_Type__c IN: involvementTypes AND Parent_Partner_Relation__c IN: partnerRelationMap.keySet()) ORDER BY CreatedDate ASC]) 
            {
                if (!existingPartnerRelationsMap.containsKey(pr.Parent_Partner_Relation__c)) {
                    existingPartnerRelationsMap.put(pr.Parent_Partner_Relation__c, new List<Partner_Relation__c>());
                }
                existingPartnerRelationsMap.get(pr.Parent_Partner_Relation__c).add(pr);
            }
            if(!existingPartnerRelationsMap.isEmpty()) {
                for (String partnerId : partnerRelationMap.keySet()) {
                    Partner_Relation__c partnerObj = partnerRelationMap.get(partnerId);
                    for(Partner_Relation__c partnerRecord: existingPartnerRelationsMap.get(partnerId)) {
                        partnerRecord.Partner_Account__c = partnerObj.Partner_Account__c;
                        partnerRecord.Influence_Sub_Type__c = partnerObj.Influence_Sub_Type__c;//SAL26-250
                        partnerRelationToBeUpdated.put(partnerRecord.Id, partnerRecord);
                    }
                }
            }
        }
        try {
            if(!partnerRelationToBeUpdated.isEmpty()) {
                update partnerRelationToBeUpdated.values();
            }
        } catch (Exception ex) {
            system.debug(LoggingLevel.DEBUG,'Exception occured  partnerRelationToBeUpdated '+ex.getMessage()+'at Line=>'+ex.getLineNumber());
        }
        
    }
    
    /**
    * Updates the Partner Relation fields based on changes in the Partner Account.
    */
    // PRIT26-107
    public static void updatePRFieldsOnClosedStage(Set<Id> oppIds) {
        Set<Id> accountIds = new Set<Id>();
        List<Partner_Relation__c> updatedPRList = new List<Partner_Relation__c>();
        List<Partner_Relation__c> prRecords = [SELECT Id,National_Flag__c, SDP_Sub_Type__c, Focus_Flag__c,
                                               Opportunity__c, Partner_Account__c, Partner_Account__r.MSP_Sub_Type__c, 
                                               Partner_Account__r.National_Partner__c, Partner_Account__r.Focused_Partner__c
                                               FROM Partner_Relation__c WHERE Opportunity__c IN: oppIds];
        
        // Iterate through the Partner Relation records to update the fields
        for (Partner_Relation__c pr : prRecords) {
            pr.National_Flag__c = pr.Partner_Account__r.National_Partner__c;
            pr.Focus_Flag__c = pr.Partner_Account__r.Focused_Partner__c;
            pr.SDP_Sub_Type__c = pr.Partner_Account__r.MSP_Sub_Type__c;
            updatedPRList.add(pr);
        }
        
        if(!updatedPRList.isEmpty()){
            Database.update(updatedPRList,false);
        }
    }
}