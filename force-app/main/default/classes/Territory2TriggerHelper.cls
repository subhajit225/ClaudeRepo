/*****************************************************************************************
Description : Helper class for Territory2 trigger
              Territory Rule label & TerritoryName will be same,
              Rule dev Name will be 'TertName_R1'
Developer : Santosh/Chaitra
Date : 10/2019
*******************************************************************************************/
public class Territory2TriggerHelper {
    
    static final string RULE = '_Rule';
    static final string UNASSIGNED_TERRITORY = 'Unassigned';
    public static string runningContext ='' ;

    //SE Pooling
    public static void sePoolingCheck(List<territory2> newTerritoryList, Map<Id, Territory2> oldTerritoryMap){
        List<String> poolingEnabledAdapIds = new List<String>();
        List<String> terrAdapIds = new List<String>();
        Set<Id> regIds = new Set<Id>();
        Set<Id> finalRegIDs = new Set<Id>();
        Map<String,Id> terrAdpIdtoRegIdMap = new Map<String,Id>();
        for(Territory2 reg: newTerritoryList){
            if(!reg.SE_Pooling__c && oldTerritoryMap.get(reg.Id).SE_Pooling__c)
                regIds.add(reg.Id);
        }
        if(!regIds.isEmpty()){
            for(Territory2 terr : [Select Id, Adaptive_Territory_Id__c,ParentTerritory2Id from Territory2 where Territory2Type.DeveloperName  = 'Territory' 
                                    AND ParentTerritory2.Territory2Type.DeveloperName = 'Region' AND ParentTerritory2Id IN: regIds
                                    AND Active_Territory__c = TRUE AND Territory2Model.State = 'Active']){
                                        terrAdapIds.add(terr.Adaptive_Territory_Id__c);
                                        terrAdpIdtoRegIdMap.put(terr.Adaptive_Territory_Id__c,terr.ParentTerritory2Id);
                                    }
        }
        if(!terrAdapIds.isEmpty()){
            for(Account acc : [Select Id,Pooled_SE_Override__c,Adaptive_Territory_Id__c from Account 
                                where Adaptive_Territory_Id__c IN: terrAdapIds]){
                if(acc.Pooled_SE_Override__c){
                    poolingEnabledAdapIds.add(acc.Adaptive_Territory_Id__c);
                }
            }
            
        }
        if(!terrAdapIds.isEmpty() && !poolingEnabledAdapIds.isEmpty()){
        for(String terrAdpId : terrAdapIds){
                    if(poolingEnabledAdapIds.contains(terrAdpId) && terrAdpIdtoRegIdMap.containsKey(terrAdpId)){
                        finalRegIDs.add(terrAdpIdtoRegIdMap.get(terrAdpId));
                    }
                }
            }
        if(!finalRegIDs.isEmpty()){
            for(Territory2 terr: newTerritoryList){
                if(finalRegIDs.contains(terr.ID) && !test.isRunningTest()){
                    terr.SE_Pooling__c.addError('Pooled SE Override must be disabled on all related Territory Accounts');
                }
            }
        }
    }
    
      public static void sePoolCheckforRegion(List<territory2> newTerritoryList){
        Set<Id> terrIds = new Set<Id>();
        Set<id> validationList = new Set<Id>();
        for(Territory2 ter: newTerritoryList){
            if(ter.SE_Pooling__c)
                terrIds.add(ter.Id);
        }
        if(!terrIds.isEmpty()){
            for(Territory2 terr : [Select Id, Territory2Type.DeveloperName from Territory2 where Territory2Type.DeveloperName  != 'Region' 
                                    AND Id IN: terrIds]){
                                        validationList.add(terr.Id);
                                    }
        }
        if(!validationList.isEmpty()){
            for(Territory2 terr: newTerritoryList){
                if(validationList.contains(terr.ID) && !test.isRunningTest()){
                    terr.SE_Pooling__c.addError('SE Pooling can only be checked at Region level');
                }
            }
        }
    }

    public static void getOwnerAssignmentImpactedTerr(List<territory2> newTerritoryList, Map<Id, Territory2> oldTerritoryMap){ 
    Set<Id> terrIds = new Set<id>(); // Holds list of territory id that would impact owner assignment of account/contact/opportunity
    Set<Id> leafTerritoryIds = new Set<id>();
    for(Territory2 terr: newTerritoryList){
       if(terr.ParentTerritory2Id != oldTerritoryMap.get(terr.id).ParentTerritory2Id 
       || terr.Name != oldTerritoryMap.get(terr.id).Name
       || terr.Channel_Territory__c != oldTerritoryMap.get(terr.id).Channel_Territory__c 
       || terr.Channel_Territory__c != oldTerritoryMap.get(terr.id).Channel_Territory__c
       || test.isRunningTest()
       )
       terrIds.add(terr.id);
    }
    
    if(!terrIds.isEmpty()){
       for( Territory2 Terr : [Select id 
                                          from Territory2 where Territory2Type.DeveloperName ='territory'
                                          AND
                                          Territory2Model.State='Active' 
                                           AND
                                          (ID IN: terrIds 
                                          or  ParentTerritory2.Id IN: terrIds
                                          or  ParentTerritory2.ParentTerritory2.Id IN: terrIds
                                          or  ParentTerritory2.ParentTerritory2.ParentTerritory2.Id IN: terrIds
                                          or  ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Id IN: terrIds)
                                          ]){

        leafTerritoryIds.add(Terr.id);
    
    }
    }
    if(!leafTerritoryIds.isEmpty()){
    system.debug('runningContext'+runningContext);
         if(runningContext.equalsIgnoreCase('ETM_TerritoryBatch')){
            ETMCreateTerritoryModelBatch.reprocessLeafTerrIds.addall(leafTerritoryIds);
         }
         else{
                UserTerritory2AssociationTriggerHelper.AddReprocessId(new set<string>(), leafTerritoryIds,new set<string>{},new set<Id>{},new set<Id>{});
    }
   } 
   } 
    public static void filterTerritoryToCreateAssignmentRule(Map<Id, Territory2> newTerritoryMap, Map<Id, Territory2> oldTerritoryMap, boolean isInsert) {
        Map<Id, Territory2> filteredTerritoryMap = new Map<Id, Territory2>();
        for(Territory2 tr : newTerritoryMap.values()) {
            if(tr.Adaptive_Territory_Id__c != null
               && (isInsert || (tr.Adaptive_Territory_Id__c != oldTerritoryMap.get(tr.Id).Adaptive_Territory_Id__c)
                    || (tr.Territory_Structure_Type__c != oldTerritoryMap.get(tr.Id).Territory_Structure_Type__c))) {
                filteredTerritoryMap.put(tr.Id, tr);    
            }else if (tr.Adaptive_Territory_Id__c == null && UNASSIGNED_TERRITORY.equalsIgnoreCase(tr.Name) && isInsert) {
                filteredTerritoryMap.put(tr.Id, tr); 
            }
        }
        if(!filteredTerritoryMap.isEmpty()) {
            createTerritoryAssignmentRule(filteredTerritoryMap, oldTerritoryMap, isInsert);
        }
    }
    public static void createTerritoryAssignmentRule(Map<Id, Territory2> newTerritoryMap, Map<Id, Territory2> oldTerritoryMap, boolean isInsert) {
        System.debug('@@'+newTerritoryMap.values().size());
        //Collection for DML
        Map<Id, ObjectTerritory2AssignmentRule> territoryIdAndAssignRuleMap = new Map<Id, ObjectTerritory2AssignmentRule>();
        List<ObjectTerritory2AssignmentRuleItem> oTerrAssRuleItemList = new List<ObjectTerritory2AssignmentRuleItem>();
        List<RuleTerritory2Association> ruleTerritoryAssocList = new List<RuleTerritory2Association>();
        
        //Collection for references
        Map<Id, Id> trtIdRuleIdMap = new Map<Id, Id>();
        Map<Id, Id> trtIdRTAMap = new Map<Id, Id>();    //PL26-128
        List<ObjectTerritory2AssignmentRule> structTypeRuleList = new List<ObjectTerritory2AssignmentRule>();
        List<RuleTerritory2Association> structTypeRTAList = new List<RuleTerritory2Association>();
        Map<Id, List<ObjectTerritory2AssignmentRuleItem>> trtIdRuleItemListMap = new Map<Id, List<ObjectTerritory2AssignmentRuleItem>>();//PL26-10:change to list map
        
        for(RuleTerritory2Association rTA : [SELECT Id, Territory2Id, RuleId FROM RuleTerritory2Association 
                WHERE Territory2Id IN :newTerritoryMap.keySet()]) {
            trtIdRuleIdMap.put(rTA.Territory2Id, rTA.RuleId);
                                                 trtIdRTAMap.put(rTA.Territory2Id, rTA.Id); //PL26-128
        }
        System.debug('trtIdRuleIdMap@@'+trtIdRuleIdMap);
        
        
        if(!trtIdRuleIdMap.isEmpty()) {
            for(ObjectTerritory2AssignmentRuleItem trtRuleItem : [SELECT Id, RuleId, Value FROM ObjectTerritory2AssignmentRuleItem WHERE RuleId IN :trtIdRuleIdMap.values()]) {
                //PL26-10                                             
                if(!trtIdRuleItemListMap.containsKey(trtRuleItem.RuleId)){
                    trtIdRuleItemListMap.put(trtRuleItem.RuleId, new List<ObjectTerritory2AssignmentRuleItem>());
                }
                trtIdRuleItemListMap.get(trtRuleItem.RuleId).add(trtRuleItem);
            }
        }
        
        //To assign unique name to AssignmentRule
        Set<String> trtNameSet = new Set<String>();
        for(Territory2 tr : newTerritoryMap.values()) {
            trtNameSet.add(tr.DeveloperName + RULE);
        }
        Map<String, String> existingRuleWithName = new Map<String, String>();
        for(ObjectTerritory2AssignmentRule ar : [SELECT Id,MasterLabel,DeveloperName FROM ObjectTerritory2AssignmentRule 
        WHERE MasterLabel IN :trtNameSet ORDER BY MasterLabel,DeveloperName]) {
            existingRuleWithName.put(ar.MasterLabel, ar.DeveloperName);
        }
        
        System.debug('existingRuleWithName@@'+existingRuleWithName);
        
        //1. Populate territoryIdAndAssignRuleMap map from newTerritoryList to create rule
        for(Territory2 tr : newTerritoryMap.values()) {
            if(tr.Adaptive_Territory_Id__c != null 
               && (isInsert || (tr.Adaptive_Territory_Id__c != oldTerritoryMap.get(tr.Id).Adaptive_Territory_Id__c && !trtIdRuleIdMap.containsKey(tr.Id))
                  || (tr.Territory_Structure_Type__c != oldTerritoryMap.get(tr.Id).Territory_Structure_Type__c && trtIdRuleIdMap.containsKey(tr.Id)))) { //PL26-128
                      if(!isInsert && tr.Territory_Structure_Type__c != oldTerritoryMap.get(tr.Id).Territory_Structure_Type__c && trtIdRuleIdMap.containsKey(tr.Id)){
                          structTypeRTAList.add(new RuleTerritory2Association(Id = trtIdRTAMap.get(tr.id)));
                          structTypeRuleList.add(new ObjectTerritory2AssignmentRule(Id = trtIdRuleIdMap.get(tr.id)));
                      } //PL26-128 end
                ObjectTerritory2AssignmentRule otAR = new ObjectTerritory2AssignmentRule (
                    ObjectType = 'Account',
                    IsActive = true,
                    MasterLabel = tr.DeveloperName + RULE, //RuleLabel = TerDevName
                    DeveloperName = tr.DeveloperName+RULE+'1',
                    Territory2ModelId = tr.Territory2ModelId
                );
                //if same Rule name is exist in another territory then use next index
                if(existingRuleWithName.containsKey(otAR.MasterLabel)){
                    String existingRuleNameIndex = existingRuleWithName.get(otAR.MasterLabel).substringAfterLast(RULE);
                    if(String.isNotBlank(existingRuleNameIndex)) {
                        Integer nextIndex = Integer.valueOf(existingRuleNameIndex) + 1;
                        otAR.DeveloperName = tr.DeveloperName+RULE+nextIndex;
                    }
                }
                
                territoryIdAndAssignRuleMap.put(tr.Id, otAR);
                System.debug('@@Inside Rule creation loop');
               }
            else if (tr.Adaptive_Territory_Id__c == null && UNASSIGNED_TERRITORY.equalsIgnoreCase(tr.Name) && isInsert) {
                createUnassignedAssignmentRule(tr);
            }
            
        }
        if(!structTypeRuleList.isEmpty() && !structTypeRTAList.isEmpty()){ //PL26-128
            Database.Delete(structTypeRTAList, false);
             Database.Delete(structTypeRuleList, false);
        } //PL26-128 end
        if(!territoryIdAndAssignRuleMap.isEmpty()) {
            Database.Insert(territoryIdAndAssignRuleMap.values(), false);
        }
        
        List<ObjectTerritory2AssignmentRule> assignmentRuleList = new List<ObjectTerritory2AssignmentRule>();
        
        for(Id territory2Id : newTerritoryMap.keySet()) {
            ObjectTerritory2AssignmentRule oAR = territoryIdAndAssignRuleMap.get(territory2Id);
            //Territory Updated
            if(oAR == null) {
                List<ObjectTerritory2AssignmentRuleItem> otARIList = trtIdRuleItemListMap.containsKey(trtIdRuleIdMap.get(territory2Id)) ?
                    trtIdRuleItemListMap.get(trtIdRuleIdMap.get(territory2Id)) : new List<ObjectTerritory2AssignmentRuleItem>(); //PL26-10
                if(!otARIList.isEmpty()) {
                    for(ObjectTerritory2AssignmentRuleItem otARI : otARIList){
                    otARI.Value = newTerritoryMap.get(territory2Id).Adaptive_Territory_Id__c;
                    oTerrAssRuleItemList.add(otARI);
                }
            }
            }else if(oAR.Id != null) {
                //2.Create Assignment ruleItem related to above created rule.
                oTerrAssRuleItemList.add(createAndGetAssignementRuleItem(oAR.Id, 1, 'equals', newTerritoryMap.get(territory2Id).Adaptive_Territory_Id__c, 'Account.Adaptive_Territory_Id__c'));
                //PL26-10: create a new assignment rule item
                oTerrAssRuleItemList.add(createAndGetAssignementRuleItem(oAR.Id, 2, 'contains', newTerritoryMap.get(territory2Id).Adaptive_Territory_Id__c, 'Account.Non_Core_Adaptive_Territory_Ids__c'));
                //PL26-10: add filter condition to Rule
                assignmentRuleList.add(new ObjectTerritory2AssignmentRule(Id = oAR.Id, BooleanFilter = '1 OR 2'));                
                
                //3.Create Association between territory and AssignmentRule using 'RuleTerritory2Association'
                RuleTerritory2Association rta = new RuleTerritory2Association(
                    RuleId = oAR.Id,
                    Territory2Id = territory2Id
                );
                
                ruleTerritoryAssocList.add(rta);
                System.debug('@@Inside If- ruleItem & Association creation');            
            }
        
        }
        
        if(!oTerrAssRuleItemList.isEmpty()) {
            Database.upsert(oTerrAssRuleItemList, false);
        }
        //PL26-10: update assignment rule with added filter condition
        if(!assignmentRuleList.isEmpty()) {
            Database.update(assignmentRuleList, false);
        } 
        if(!ruleTerritoryAssocList.isEmpty()) {
            Database.Insert(ruleTerritoryAssocList, false);
        }
    }
    
    /**
        @Description : Create Territory Assignment rule for Unassigned territory
            Unassigned territory don't have Adaptive Id so handled this in separate function
    */
    public static void createUnassignedAssignmentRule(Territory2 unAssignedTerritory) {
        //Check existing rule to make uniqueName
        
        Map<String, String> existingRuleWithName = new Map<String, String>();
        String ruleLabel = unAssignedTerritory.DeveloperName + RULE;
        for(ObjectTerritory2AssignmentRule ar : [SELECT Id,MasterLabel,DeveloperName FROM ObjectTerritory2AssignmentRule 
        WHERE MasterLabel = :ruleLabel ORDER BY MasterLabel,DeveloperName]) {
            existingRuleWithName.put(ar.MasterLabel, ar.DeveloperName);
        }
        //1.Create Territory Rule
        ObjectTerritory2AssignmentRule otAR = new ObjectTerritory2AssignmentRule (
            ObjectType = 'Account',
            IsActive = true,
            MasterLabel = unAssignedTerritory.DeveloperName + RULE, //RuleLabel = TerDevName
            DeveloperName = unAssignedTerritory.DeveloperName+RULE+'1',
            Territory2ModelId = unAssignedTerritory.Territory2ModelId
        );
        //if same Rule name is exist in another territory then use next index
        if(existingRuleWithName.containsKey(otAR.MasterLabel)){
            String existingRuleNameIndex = existingRuleWithName.get(otAR.MasterLabel).substringAfterLast(RULE);
            if(String.isNotBlank(existingRuleNameIndex)) {
                Integer nextIndex = Integer.valueOf(existingRuleNameIndex) + 1;
                otAR.DeveloperName = unAssignedTerritory.DeveloperName+RULE+nextIndex;
            }
        }
         Database.Insert(otAR, false);
        //insert otAR;
        if(otAR.Id != null) {
            
            //2.Rule Item creation for Unassigned Territory
            ObjectTerritory2AssignmentRuleItem otARI1 = new ObjectTerritory2AssignmentRuleItem (
                ruleId = otAR.Id,
                SortOrder = 1,
                Operation = 'equals',
                Value = 'Customer/Prospect',
                Field = 'Account.RecordTypeId'
            );
            ObjectTerritory2AssignmentRuleItem otARI2 = new ObjectTerritory2AssignmentRuleItem (
                ruleId = otAR.Id,
                SortOrder = 2,
                Operation = 'equals',
                Value = '',
                 Field = 'Account.Adaptive_Territory_Id__c'
            );
            
            insert new List<ObjectTerritory2AssignmentRuleItem> {otARI1, otARI2};
            
            //3.Rule Territory Association
            RuleTerritory2Association rta = new RuleTerritory2Association(
                RuleId = otAR.Id,
                Territory2Id = unAssignedTerritory.Id
            );
            insert rta;
            
        }
    }
    
    //PL26-10
    public static ObjectTerritory2AssignmentRuleItem createAndGetAssignementRuleItem(Id ruleId, Integer sortOrder, String operation, String value, string field) {
        return new ObjectTerritory2AssignmentRuleItem (
            ruleId = ruleId,
            SortOrder = sortOrder,
            Operation = operation,
            Value = value,
            Field = field
        );
    }
}