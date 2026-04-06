/******************************************************************************************************
Description : UserTerritory2Association Helper 
Developer : Chaitra
Date      : 1/2020
**********************************************************************************************************/

public class UserTerritory2AssociationTriggerHelper {
    
    //Constant
    public static final string THEATRE = 'Theatre';
    public static final string AREA = 'Area';
    public static final string REGION = 'Region';
    public static final string OwnerAssociation_SourceType = 'UserUpdate';
    public static final string TERRITORY = 'Territory';
    public static final string UNASSIGNED_TERRITORY='Unassigned';
    public static string runningContext ='' ; // Check to controll processing of leaf territoryId's in Batch class as future cannot be called from batch class
    public static map<string,string> TerrType_OwnerRole = new Map<string,string>();
    public static map<string,string> CDMTerrType_OwnerRole = new Map<string,string>();
    public static Map<Id,User> finalusrUpdateMap = new Map<Id,User>();//SAL25-617
    
    public static void ownerAssignment(List<UserTerritory2Association> newUTAList,Map<Id,UserTerritory2Association> oldMapUTA){
        List<string> oppCoownerRoles = new List<string>(); //PL26-38, PL26-19
        set<id> oppCoownerTerrIds = new set<Id>(); //PL26-38, PL26-19
        Set<String> oppCoOwnerAdaptiveIds = new Set<String>(); //PL26-38, PL26-19
        Set<Id>leafTerritoryIds = new set<Id>();
        set<Id>parentTerritoryId = new set<id>();
        set<Id> updatedUTA = new set<Id>();
        List<string>SERoles = new List<string>();
        set<string>SEAdaptiveIds = new set<string>(); // Sales engineer present in Territory Ids
        set<id>SETerrIds = new set<Id>();
        //SAL23-443 - Alliance Rep //SAL24-28 //SAL24-472
        List<string> allianceRepRoles = new List<string>();
        set<id> allianceRepTerrIds = new set<Id>();
        //SAL24-14 - Contact Routing
        List<string> sdrRoles = new List<string>();
        set<id> sdrTerrIds = new set<Id>();
        system.debug('newUTAList'+newUTAList);
        for(Territory_Management_Setup__mdt setupMdt : [select Field_Value__c,DeveloperName from Territory_Management_Setup__mdt where DeveloperName IN('Role_of_Alliance_Rep','Role_of_SDR','Role_of_Sales_Engineer','Con_UTA_RoleInTerritory2','Con_UTA_CDM_RoleInTerritory2','Opp_Co_Owner_Roles')]){ //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472
            if(setupMdt.DeveloperName!=null && setupMdt.Field_Value__c!=null){
                
                //PL26-38, PL26-19 - opp Co-owner Roles
                if(setupMdt.DeveloperName.equalsIgnoreCase('Opp_Co_Owner_Roles')){
                    oppCoownerRoles = setupMdt.Field_Value__c.contains(',') ? setupMdt.Field_Value__c.split(',') : new List<String>{setupMdt.Field_Value__c};
                }
                
                //SAL23-443 - Alliance Rep //SAL24-28 //SAL24-472
                if(setupMdt.DeveloperName.equalsIgnoreCase('Role_of_Alliance_Rep')){
                    allianceRepRoles = setupMdt.Field_Value__c.split(';');
                }
                //SAL24-14 - Contact Routing
                if(setupMdt.DeveloperName.equalsIgnoreCase('Role_of_SDR')){
                    sdrRoles = setupMdt.Field_Value__c.split(';');
                }
                else if(setupMdt.DeveloperName.equalsIgnoreCase('Role_of_Sales_Engineer')){
                    SERoles = setupMdt.Field_Value__c.split(';');
                }
                else if(setupMdt.DeveloperName.equalsIgnoreCase('Con_UTA_RoleInTerritory2')){ 
                    for(string UserRole: setupMdt.Field_Value__c.split(';')){
                        TerrType_OwnerRole.put(UserRole.split(':')[0].trim(),UserRole.split(':')[1].trim());
                    }
                } 
                else if(setupMdt.DeveloperName.equalsIgnoreCase('Con_UTA_CDM_RoleInTerritory2')){ 
                    for(string UserRole: setupMdt.Field_Value__c.split(';')){
                        CDMTerrType_OwnerRole.put(UserRole.split(':')[0].trim(),UserRole.split(':')[1].trim());
                    }
                }         
            }
        }      
        system.debug('CDMTerrType_OwnerRole'+CDMTerrType_OwnerRole);
        system.debug('TerrType_OwnerRole'+TerrType_OwnerRole);
        for(UserTerritory2Association UTA : newUTAList){
            system.debug('CP UTA'+UTA.RoleInTerritory2);
            
            //PL26-38,PL26-19 
            if(!oppCoownerRoles.isEmpty() && 
                (oppCoownerRoles.contains(UTA.RoleInTerritory2) || (oldMapUTA != null && oppCoownerRoles.contains(oldMapUTA.get(UTA.id).RoleInTerritory2)))){
                if(Trigger.isDelete)
                    oppCoownerTerrIds.add(UTA.Territory2Id); // delete 
                else if(Trigger.isInsert || UTA.RoleInTerritory2 != oldMapUTA.get(UTA.id).RoleInTerritory2)
                    oppCoownerTerrIds.add(UTA.Territory2Id);
                
                continue;
            } //End
            
            //SAL23-443 - Alliance Rep //SAL24-28 //SAL24-472
            if(!allianceRepRoles.isEmpty() && 
                (allianceRepRoles.contains(UTA.RoleInTerritory2) || (oldMapUTA != null && allianceRepRoles.contains(oldMapUTA.get(UTA.id).RoleInTerritory2)))){
                if(Trigger.isDelete)
                    allianceRepTerrIds.add(UTA.Territory2Id); // delete 
                else if(Trigger.isInsert || UTA.RoleInTerritory2 != oldMapUTA.get(UTA.id).RoleInTerritory2)
                    allianceRepTerrIds.add(UTA.Territory2Id);
                
                continue;
            } //End 
            //SAL24-14 Contact Routing
            if(!sdrRoles.isEmpty() && 
                (sdrRoles.contains(UTA.RoleInTerritory2) || (oldMapUTA != null && sdrRoles.contains(oldMapUTA.get(UTA.id).RoleInTerritory2)))){
                if(Trigger.isDelete)
                    sdrTerrIds.add(UTA.Territory2Id); // delete 
                else if(Trigger.isInsert || UTA.RoleInTerritory2 != oldMapUTA.get(UTA.id).RoleInTerritory2)
                    sdrTerrIds.add(UTA.Territory2Id);
                
                continue;
            } //End

            if(!SERoles.isEmpty() 
            && (SERoles.contains(UTA.RoleInTerritory2)
                 || (oldMapUTA != null && SERoles.contains(oldMapUTA.get(UTA.id).RoleInTerritory2)))){
               if(Trigger.isDelete){
                SETerrIds.add(UTA.Territory2Id); // delete 
               }
               else{
               if(Trigger.isinsert || UTA.RoleInTerritory2 != oldMapUTA.get(UTA.id).RoleInTerritory2)
                //SF-8995
                //updatedUTA.add(UTA.Id); // for insert or update UTA
                SETerrIds.add(UTA.Territory2Id);
               }
               continue;
            }
            
            if(TerrType_OwnerRole.values().contains(UTA.RoleInTerritory2) || 
               CDMTerrType_OwnerRole.values().contains(UTA.RoleInTerritory2) || 
                (oldMapUTA != null && (TerrType_OwnerRole.values().contains(oldMapUTA.get(UTA.id).RoleInTerritory2) || CDMTerrType_OwnerRole.values().contains(oldMapUTA.get(UTA.id).RoleInTerritory2)))){ //Role change or user movment from one territory to other
                if(Trigger.isDelete){
                system.debug('UTA.Territory2Id in delete'+UTA.Territory2Id);
                parentTerritoryId.add(UTA.Territory2Id); 
                }
                else{
                if(Trigger.isInsert || UTA.RoleInTerritory2 != oldMapUTA.get(UTA.id).RoleInTerritory2)
                updatedUTA.add(UTA.Id);
                }
            }
            system.debug('parentTerritoryId Adding sec=>'+parentTerritoryId);
        }
         system.debug('SETerrIds'+ SETerrIds);
        for(UserTerritory2Association UTA:[select id,Territory2.SubType__c,Territory2.Adaptive_Territory_Id__c,Territory2.DeveloperName,Territory2Id,Territory2.Territory2Type.DeveloperName,RoleInTerritory2 from UserTerritory2Association where id IN:updatedUTA and User.IsActive=true and Territory2.Territory2Model.State IN('Active','Planning')]){  
            //SF-8995
            /*if(!SERoles.isEmpty() && (SERoles.contains(UTA.RoleInTerritory2) || (oldMapUTA != null && SERoles.contains(oldMapUTA.get(UTA.id).RoleInTerritory2)))){
             SEAdaptiveIds.add(UTA.Territory2.Adaptive_Territory_Id__c);
             continue;
            }*/
            if(UTA.Territory2.SubType__c!=null && UTA.Territory2.SubType__c.equalsIgnoreCase('Channel')){  // CDM UTA update
            if(CDMTerrType_OwnerRole.get(UTA.Territory2.Territory2Type.DeveloperName).equalsIgnoreCase(UTA.RoleInTerritory2)   // On UTA Insert
                  || (oldMapUTA!=null && CDMTerrType_OwnerRole.get(UTA.Territory2.Territory2Type.DeveloperName).equalsIgnoreCase(oldMapUTA.get(UTA.Id).RoleInTerritory2))){ // on UTA update

                if(UTA.Territory2.Territory2Type.DeveloperName.equalsIgnoreCase('Territory')){
                  leafTerritoryIds.add(UTA.Territory2Id); 
                }
                else {
                 parentTerritoryId.add(UTA.Territory2Id);
            }
                
            }
           }
           else{ // AE UTA update
              if(TerrType_OwnerRole.get(UTA.Territory2.Territory2Type.DeveloperName).equalsIgnoreCase(UTA.RoleInTerritory2)   // On UTA Insert
                  || (oldMapUTA!=null && TerrType_OwnerRole.get(UTA.Territory2.Territory2Type.DeveloperName).equalsIgnoreCase(oldMapUTA.get(UTA.Id).RoleInTerritory2)) // on UTA update
                  || UTA.Territory2.DeveloperName.equalsIgnoreCase(UNASSIGNED_TERRITORY) ){

                if(UTA.Territory2.Territory2Type.DeveloperName.equalsIgnoreCase('Territory')  
                    || (UTA.Territory2.DeveloperName.equalsIgnoreCase(UNASSIGNED_TERRITORY) 
                         && (TerrType_OwnerRole.get(UNASSIGNED_TERRITORY).equalsIgnoreCase(UTA.RoleInTerritory2)
                             ||(oldMapUTA!=null && TerrType_OwnerRole.get(UNASSIGNED_TERRITORY).equalsIgnoreCase(oldMapUTA.get(UTA.Id).RoleInTerritory2)))))  {
                  leafTerritoryIds.add(UTA.Territory2Id); 
                }
                else {
                 parentTerritoryId.add(UTA.Territory2Id);
            }
                
            }
           
           } 
        }
        
        system.debug('parentTerritoryId'+parentTerritoryId);
        //SF-8995
        //if(parentTerritoryId.size()>0){
        if(!parentTerritoryId.isEmpty() || !SETerrIds.isEmpty() || !oppCoownerTerrIds.isEmpty()){
             for( Territory2 Terr : [Select id, Adaptive_Territory_Id__c, ParentTerritory2.id, ParentTerritory2.ParentTerritory2.id,
                                        ParentTerritory2.ParentTerritory2.ParentTerritory2.id, ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.id
                                          from Territory2 where Territory2Type.DeveloperName ='territory'
                                           AND Territory2Model.State IN('Active','Planning')
                                           AND
                                          (ID IN: parentTerritoryId or Id IN: SETerrIds or Id IN :oppCoownerTerrIds //SF-8995 //PL26-38:oppCoownerTerrIds
                                          or  ParentTerritory2.Id IN: parentTerritoryId or ParentTerritory2.Id IN: SETerrIds //SF-8995
                                          or  ParentTerritory2.ParentTerritory2.Id IN: parentTerritoryId
                                          or  ParentTerritory2.ParentTerritory2.ParentTerritory2.Id IN: parentTerritoryId
                                          or  ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Id IN: parentTerritoryId)
                                          ]){
        //SF-8995
        if(parentTerritoryId.contains(Terr.id) || parentTerritoryId.contains(Terr.ParentTerritory2.id) || 
                parentTerritoryId.contains(Terr.ParentTerritory2.ParentTerritory2.id) || 
                parentTerritoryId.contains(Terr.ParentTerritory2.ParentTerritory2.ParentTerritory2.id) || 
                parentTerritoryId.contains(Terr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.id))
            leafTerritoryIds.add(Terr.id);
        if(SETerrIds.contains(Terr.Id) || SETerrIds.contains(Terr.ParentTerritory2.Id))
            SEAdaptiveIds.add(Terr.Adaptive_Territory_Id__c);
        if(oppCoownerTerrIds.contains(Terr.Id)){ //PL26-38:oppCoownerTerrIds
            oppCoOwnerAdaptiveIds.add(Terr.Adaptive_Territory_Id__c);                                      
        }
       }
        } 
         
        system.debug('Leaf territory Id'+leafTerritoryIds+'SEAdaptiveIds'+SEAdaptiveIds+'SETerrIds'+SETerrIds+'oppCoOwnerAdaptiveIds: '+oppCoOwnerAdaptiveIds+'oppCoownerTerrIds:'+oppCoownerTerrIds); 
        if(!(leafTerritoryIds.isEmpty() && SEAdaptiveIds.isEmpty() && sdrTerrIds.isEmpty() && allianceRepTerrIds.isEmpty() && oppCoOwnerAdaptiveIds.isEmpty())){ //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472//PL26-38:oppCoOwnerAdaptiveIds
            system.debug('runningContext'+runningContext);
            if(runningContext.equalsIgnoreCase('ETM_UTABatch')){
                for(territory2 Terr : [select id,Adaptive_Territory_Id__c,(select id from ObjectTerritory2Associations limit 1)from territory2 where id IN: leafTerritoryIds]){ //SF-8995
                    //SF-8995
                    /*if(SETerrIds.contains(Terr.id)){
                        ETMCreateUserTerritoryAssociationBatch.reprocessTerr.add(new Territory_Owner_Assignment__c(AdaptiveId__c = Terr.Adaptive_Territory_Id__c, Functionality__c='Sales Engineer Assignment'));
                    }
                    else*/ if(Terr.ObjectTerritory2Associations.size()>0){
                        ETMCreateUserTerritoryAssociationBatch.reprocessTerr.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c=Terr.id, Functionality__c='Owner Assignment'));
                    }
                    } 
                for(string AId : SEAdaptiveIds){
                    ETMCreateUserTerritoryAssociationBatch.reprocessTerr.add(new Territory_Owner_Assignment__c(AdaptiveId__c = AId, Functionality__c='Sales Engineer Assignment'));

                }   
                //SAL23-443 - Alliance Rep //SAL24-28 //SAL24-472
                for(Id arTerrId : allianceRepTerrIds){
                    ETMCreateUserTerritoryAssociationBatch.reprocessTerr.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c = arTerrId, Functionality__c='Alliance Rep Assignment'));
                }
                //SAL24-14 Contact Routing
                for(Id arTerrId : sdrTerrIds){
                    ETMCreateUserTerritoryAssociationBatch.reprocessTerr.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c = arTerrId, Functionality__c='SDR Assignment'));
                }
                //PL26-38,PL26-19
                for(String adaptiveId : oppCoOwnerAdaptiveIds){
                    ETMCreateUserTerritoryAssociationBatch.reprocessTerr.add(new Territory_Owner_Assignment__c(AdaptiveId__c = adaptiveId, Functionality__c='Opp Co-Owner Assignment'));
                }
            }
            else{
                AddReprocessId(oppCoOwnerAdaptiveIds, leafTerritoryIds,SEAdaptiveIds,sdrTerrIds,allianceRepTerrIds); //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472
            }    
        } 
  }  
  @future
    public static void AddReprocessId(Set<String> oppCoOwnerAdaptiveIds, Set<Id> LeafTerrIds,set<string> SEAdaptiveIds,set<Id> sdrTerrIds, set<Id> allianceRepTerrIds) { //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472
        List<Territory_Owner_Assignment__c> toBeProcessedTerr_OwnerAssignment = new List<Territory_Owner_Assignment__c>();
        for(territory2 Terr : [select id,Adaptive_Territory_Id__c,(select id from ObjectTerritory2Associations limit 1)from territory2 where id IN: LeafTerrIds]){ //SF-8995
            //SF-8995
            /*if(SETerrIds.contains(Terr.id)){
                    toBeProcessedTerr_OwnerAssignment.add(new Territory_Owner_Assignment__c(AdaptiveId__c = Terr.Adaptive_Territory_Id__c, Functionality__c='Sales Engineer Assignment'));
            }
            else*/ if(Terr.ObjectTerritory2Associations.size()>0)
            toBeProcessedTerr_OwnerAssignment.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c=Terr.id, Functionality__c='Owner Assignment'));
            } 
        for(string AId : SEAdaptiveIds){
            toBeProcessedTerr_OwnerAssignment.add(new Territory_Owner_Assignment__c(AdaptiveId__c = AId, Functionality__c='Sales Engineer Assignment'));

        }   
        //SAL23-443 - Alliance Rep //SAL24-28 //SAL24-472
        for(Id arTerrId : allianceRepTerrIds){
            toBeProcessedTerr_OwnerAssignment.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c = arTerrId, Functionality__c='Alliance Rep Assignment'));
        }
        //SAL24-14 Contact Routing
        for(Id arTerrId : sdrTerrIds){
            toBeProcessedTerr_OwnerAssignment.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c = arTerrId, Functionality__c='SDR Assignment'));
        }
        //PL26-38,PL26-19
        for(String adaptiveId  : oppCoOwnerAdaptiveIds){
            toBeProcessedTerr_OwnerAssignment.add(new Territory_Owner_Assignment__c(AdaptiveId__c = adaptiveId, Functionality__c='Opp Co-Owner Assignment'));
        }
        system.debug('toBeProcessedTerr_OwnerAssignment'+toBeProcessedTerr_OwnerAssignment); 
        Database.insert(toBeProcessedTerr_OwnerAssignment,false) ;  
    }
    
    /** ETM:137
        @Description : Create UTA History record when UTA record is created
    */
    public static void createUTAHistory(Map<Id, UserTerritory2Association> newUTAMap) {
        System.enqueueJob(new UserTerritoryAssociationHistoryHelper(newUTAMap.keySet(), null, 'TRIGGER-INSERT'));
    }

    /** ETM:137
        @Description : Create UTA History record when UTA record is deleted
    */
    public static void updateUTAHistory(Map<Id, UserTerritory2Association> oldUTAMap) {
        System.enqueueJob(new UserTerritoryAssociationHistoryHelper(null, oldUTAMap.keySet(), 'TRIGGER-DELETE'));
    }

    //SAL21-320
    public static void validateAllowedUTAChanges(List<UserTerritory2Association> newUTAList){
        ShGl_DisableFunctionalityLogic__c disableFuncLogic = ShGl_DisableFunctionalityLogic__c.getInstance();
        Boolean isAllowed = disableFuncLogic.Allow_Changes_UserTerritoryAssociation__c;
        for(UserTerritory2Association UTA : newUTAList){
            if(!Test.isRunningTest() && !isAllowed) UTA.addError(Label.ETM_UserTerritoryAssociation_Failed_Msg);
        }
    }
    
     //SAL23-374
    public static void addNewRole(List<UserTerritory2Association> newUTAList){
        Set<Id> territory2IdSet = new Set<Id>();
        List<UserTerritory2Association> finalUTAList = new List<UserTerritory2Association>();
        for(UserTerritory2Association uta : newUTAList){
            if(uta.IsActive){
            	if(uta.RoleInTerritory2 == 'Account Executive' || uta.RoleInTerritory2 == 'Sales Engineer'|| uta.RoleInTerritory2 == 'SEM' ||  uta.RoleInTerritory2 == 'SED'){ //SAL25-617
            		territory2IdSet.add(uta.Territory2Id);
                }
            }
        }
        if(!territory2IdSet.isEmpty()){
            for(UserTerritory2Association uta : [select Id, UserId,IsActive,Territory2Id,RoleInTerritory2 ,Territory2.Territory2Type.DeveloperName, Territory2.ParentTerritory2Id,Territory2.ParentTerritory2.ParentTerritory2Id ,Territory2.Territory2Model.State from UserTerritory2Association where (Territory2Id IN:territory2IdSet OR Territory2.ParentTerritory2Id IN:territory2IdSet OR Territory2.ParentTerritory2.ParentTerritory2Id IN:territory2IdSet) AND Territory2.Territory2Model.State = 'Active' and RoleInTerritory2 IN ('Account Executive','Sales Engineer')]){
            	finalUTAList.add(uta);
            }
        }
        if(!finalUTAList.isEmpty()){
            UserTerritory2AssociationTriggerHelper.setPOCApprover(finalUTAList,null);
        }
    }
   
    //SAL23-374
    public static void removeRTSEMorSED(List<UserTerritory2Association> newUTAList, Map<Id,UserTerritory2Association> oldMapUTA){
    	Set<Id> territoryIdSet = new Set<Id>();
        Set<Id> AEuserIdSet = new Set<Id>();
        Map<Id,UserTerritory2Association> allManagerUTAMap = new Map<Id,UserTerritory2Association>();
        List<UserTerritory2Association> finalUTAList = new List<UserTerritory2Association>();
        
        for(UserTerritory2Association uta : newUTAList){
            if(Trigger.isDelete && uta.RoleInTerritory2 == 'Account Executive'){ //SAL25-617
                AEuserIdSet.add(uta.UserId);
            }
            if(Trigger.isDelete && (uta.RoleInTerritory2 == 'SEM' ||  uta.RoleInTerritory2 == 'SED')){ 
            	territoryIdSet.add(uta.Territory2Id); //SAL25-617
            }
        }
        //SAL25-617
        if(!AEuserIdSet.isEmpty()){
            for(User usr: [Select Id,POC_Approver__c from User where POC_Approver__c IN:AEuserIdSet]){
                usr.POC_Approver__c = null;
                if(finalusrUpdateMap == null || (finalusrUpdateMap != null && !finalusrUpdateMap.containskey(usr.Id))){
                    finalusrUpdateMap.put(usr.Id,usr);
                }
            }
        }
        if(!territoryIdSet.isEmpty()){
            for(UserTerritory2Association uta : [select Id, UserId,IsActive,Territory2Id,RoleInTerritory2 ,Territory2.Territory2Type.DeveloperName, Territory2.ParentTerritory2Id,Territory2.ParentTerritory2.ParentTerritory2Id ,Territory2.Territory2Model.State from UserTerritory2Association where (Territory2.ParentTerritory2Id IN:territoryIdSet OR Territory2.ParentTerritory2.ParentTerritory2Id IN:territoryIdSet) AND Territory2.Territory2Model.State = 'Active' and RoleInTerritory2 IN ('Account Executive','Sales Engineer')]){ //SAL25-617
                finalUTAList.add(uta);
            }
        }
        if(!finalUTAList.isEmpty()){
            UserTerritory2AssociationTriggerHelper.setPOCApprover(finalUTAList,null);
        }
    }
     
    //SAL23-374
    public static void addORRemoveRole(List<UserTerritory2Association> newUTAList, Map<Id,UserTerritory2Association> oldMapUTA){
        List<UserTerritory2Association> updatedUTAList = new List<UserTerritory2Association>();
        List<UserTerritory2Association> finalUTAList = new List<UserTerritory2Association>();
        Set<Id> removedAESEIdSet = new Set<Id>();
        
        for(UserTerritory2Association uta : newUTAList){
            if(oldMapUTA != null && oldMapUTA.get(uta.Id).RoleInTerritory2 != uta.RoleInTerritory2 && uta.IsActive){
                if(uta.RoleInTerritory2 == 'Account Executive' || uta.RoleInTerritory2 == 'Sales Engineer' || uta.RoleInTerritory2 == 'SEM' ||  uta.RoleInTerritory2 == 'SED' || oldMapUTA.get(uta.Id).RoleInTerritory2 == 'SEM' || oldMapUTA.get(uta.Id).RoleInTerritory2 == 'SED'){
                    updatedUTAList.add(uta);
                }
            }
        }
        if(!updatedUTAList.isEmpty()){
            for(UserTerritory2Association uta : [select Id, UserId,IsActive,Territory2Id,RoleInTerritory2 ,Territory2.Territory2Type.DeveloperName, Territory2.ParentTerritory2Id,Territory2.ParentTerritory2.ParentTerritory2Id,Territory2.Territory2Model.State from UserTerritory2Association where Territory2.Territory2Model.State = 'Active' and RoleInTerritory2 IN ('Account Executive','Sales Engineer')]){
                for(UserTerritory2Association upduta : updatedUTAList){
                    if(uta.Territory2Id == upduta.Territory2Id || uta.Territory2.ParentTerritory2Id == upduta.Territory2Id || (uta.Territory2.ParentTerritory2.ParentTerritory2Id != null && uta.Territory2.ParentTerritory2.ParentTerritory2Id == upduta.Territory2Id)){
                        finalUTAList.add(uta);
                    }
                }
            }
        }
        if(!finalUTAList.isEmpty()){
            UserTerritory2AssociationTriggerHelper.setPOCApprover(finalUTAList,null);
        }
    }
    //SAL23-374
    public static void setPOCApprover(List<UserTerritory2Association> newUTAList, Map<Id,Id> userPrevPOCIdMap){
        Set<Id> SEUserIdSet = new Set<Id>();
        Set<Id> AEUserIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        Map<Id,Id> tuserToRegionMap = new Map<Id,Id>();
        Map<Id,Id> tuserToAreaMap = new Map<Id,Id>();
        Map<Id,Id> SEMMap = new Map<Id,Id>();
        Map<Id,Id> SEDMap = new Map<Id,Id>();
        Map<Id,Id> UTAManagerIdMap = new Map<Id,Id>();
        Set<Id> parentUTAIdSet = new Set<Id>();
        
        for(UserTerritory2Association uta : newUTAList){
             if(uta.IsActive && (uta.RoleInTerritory2 == 'Sales Engineer' || uta.RoleInTerritory2 == 'Account Executive')){
                if(uta.RoleInTerritory2 == 'Sales Engineer'){
                    SEUserIdSet.add(uta.UserId);
                    parentUTAIdSet.add(uta.Territory2Id);
                    parentUTAIdSet.add(uta.Territory2.ParentTerritory2Id);
                    tuserToRegionMap.put(uta.UserId,uta.Territory2Id); 
                    tuserToAreaMap.put(uta.UserId,uta.Territory2.ParentTerritory2Id); 
                 }else{
                     AEUserIdSet.add(uta.UserId);
                }
                    userIdSet.add(uta.UserId);
                 tuserToRegionMap.put(uta.UserId,uta.Territory2.ParentTerritory2Id);
                 parentUTAIdSet.add(uta.Territory2.ParentTerritory2Id);
                 tuserToAreaMap.put(uta.UserId,uta.Territory2.ParentTerritory2.ParentTerritory2Id);
                 parentUTAIdSet.add(uta.Territory2.ParentTerritory2.ParentTerritory2Id);
                }
        }
        if(!parentUTAIdSet.isEmpty()){
            for(UserTerritory2Association parentUTA : [Select Id,RoleInTerritory2,UserId,Territory2Id,Territory2.ParentTerritory2Id,Territory2.Territory2Type.DeveloperName from UserTerritory2Association where Territory2Id IN: parentUTAIdSet AND Territory2.Territory2Model.State = 'Active' AND RoleInTerritory2 IN ('SEM','SED') AND IsActive = true]){
                if(parentUTA.RoleInTerritory2 == 'SEM')
                    SEMMap.put(parentUTA.Territory2Id,parentUTA.UserId);
                else
                    SEDMap.put(parentUTA.Territory2Id,parentUTA.UserId);
            }
        }
        for(UserTerritory2Association uta : newUTAList){
            if(!tuserToRegionMap.isEmpty() && tuserToRegionMap.containskey(uta.UserId) && !SEMMap.isEmpty() && SEMMap.containskey(tuserToRegionMap.get(uta.UserId))){
                if(userPrevPOCIdMap == null || !userPrevPOCIdMap.containsKey(uta.UserId) || (userPrevPOCIdMap.containsKey(uta.UserId) && userPrevPOCIdMap.get(uta.UserId) != SEMMap.get(tuserToRegionMap.get(uta.UserId)))){
                    UTAManagerIdMap.put(uta.UserId,SEMMap.get(tuserToRegionMap.get(uta.UserId)));
                }
            }
            if(UTAManagerIdMap.isEmpty() || !UTAManagerIdMap.containskey(uta.UserId)){
                if(!tuserToAreaMap.isEmpty() && tuserToAreaMap.containskey(uta.UserId) && !SEDMap.isEmpty() && SEDMap.containskey(tuserToAreaMap.get(uta.UserId))){
                    if(userPrevPOCIdMap == null || !userPrevPOCIdMap.containsKey(uta.UserId) || (userPrevPOCIdMap.containsKey(uta.UserId) && userPrevPOCIdMap.get(uta.UserId) != SEDMap.get(tuserToAreaMap.get(uta.UserId))))
                        UTAManagerIdMap.put(uta.UserId,SEDMap.get(tuserToAreaMap.get(uta.UserId)));
                }
            }
        } 
        for(User u : [select Id,ManagerId,Manager.isActive,Manager.ManagerId,Manager.Manager.isActive,POC_Approver__c from User where Id IN: userIdSet]){
            if(!AEUserIdSet.isEmpty() && AEUserIdSet.contains(u.Id)){
                if(!UTAManagerIdMap.isEmpty() && UTAManagerIdMap.containskey(u.Id)){
                    if(UTAManagerIdMap.get(u.Id) != u.POC_Approver__c){
                        u.POC_Approver__c = UTAManagerIdMap.get(u.Id);
                        finalusrUpdateMap.put(u.Id,u);
                    }
                }else if((UTAManagerIdMap.isEmpty() || !UTAManagerIdMap.containsKey(u.Id)) && u.POC_Approver__c != null){
                        u.POC_Approver__c = null;
                        finalusrUpdateMap.put(u.Id,u);
                    }
                }
            if(!SEUserIdSet.isEmpty() && SEUserIdSet.contains(u.Id)){
                if(u.ManagerId != null && u.Manager.isActive && (userPrevPOCIdMap == null || !userPrevPOCIdMap.containsKey(u.Id) || (userPrevPOCIdMap.containsKey(u.Id) && userPrevPOCIdMap.get(u.Id) != u.ManagerId))){
                    if(u.ManagerId != u.POC_Approver__c){
                        u.POC_Approver__c = u.ManagerId;
                        finalusrUpdateMap.put(u.Id,u);
                    }
                }else if(u.Manager.ManagerId != null && u.Manager.Manager.isActive && (userPrevPOCIdMap == null || !userPrevPOCIdMap.containsKey(u.Id) || (userPrevPOCIdMap.containsKey(u.Id) && userPrevPOCIdMap.get(u.Id) != u.Manager.ManagerId))){
                    if(u.Manager.ManagerId != u.POC_Approver__c){
                        u.POC_Approver__c = u.Manager.ManagerId;
                        finalusrUpdateMap.put(u.Id,u);
                    }
                }else if(!UTAManagerIdMap.isEmpty() && UTAManagerIdMap.containskey(u.Id)){
                    if(UTAManagerIdMap.get(u.Id) != u.POC_Approver__c){
                        u.POC_Approver__c = UTAManagerIdMap.get(u.Id);
                        finalusrUpdateMap.put(u.Id,u);
                    }
                }else if(u.POC_Approver__c != null){
                    u.POC_Approver__c = null;
                    finalusrUpdateMap.put(u.Id,u);
                }
            }
        }
        if(!finalusrUpdateMap.isEmpty()){
            flowControll.UserTriggerHandler = false;
            update finalusrUpdateMap.values();
            flowControll.UserTriggerHandler = true; //SAL25-617
        }
    }
}