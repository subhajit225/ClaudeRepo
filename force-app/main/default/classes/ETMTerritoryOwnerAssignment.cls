/*****************************************************************************************
Description : To Update Owner and TART values based on territory model on account Object
Developer : Chaitra
Date : 11/2019 
*******************************************************************************************/
public class ETMTerritoryOwnerAssignment {

// Variable declaration and initialization

    private static final string START_ROLELEVEL_OWNERASSIGNMENT  = 'Territory';
    private static final string NO_TERRITORY_OWNER ='No owner to assign to adaptiveId';
    private string CLASS_NAME = 'ETMTerritoryOwnerAssignment';
    private static final Integer MAX_TERRITORY_HIERARCHY_DEPTH = 6; //TART and global
    private static final string ERROR_FUNCTIONALITY = 'ETM';
    private static final string UNASSIGNED_TERRITORY='Unassigned';
    private static Map<Id,ObjectTerritory2Association> terr_ATA = new Map<Id,ObjectTerritory2Association>();
    private static Map<string,string>Adaptive_Owner = new Map<string,string>(); // adaptiveId and AccountOwnerId
    public set<Id> ProcessedLeafterritoryId; //Processesd Leaf territoryId
    private static Map<string,Id> Adaptive_leafterr = new map<string,id>();
    private string UTA_WHERECLAUSE,OTA_WHERECLAUSE;
    private Map<string,string>TerrType_OwnerRole = new Map<string,string>();
    private Map<string,string>CDMTerrType_OwnerRole = new Map<string,string>();
    private Map<Id,Id>TerrId_Owner = new Map<Id,Id>();  
    public boolean disable_AccountOwnerUpdate,disable_ContactOwnerUpdate,disable_OppOwnerUpdate,disable_ActivityOwnerUpdate = false ; //Enabling owner assignment by default
    private map<string,Custom_Error_Log__c> errorLogs = new map<string,Custom_Error_Log__c>();
    public boolean enableLogging = true; // by default enable error log creation 
    //public set<Id> finalUpdateAccounts = new set<Id>();
    public set<Id> failedAccIds = new set<Id>();

    //SF-8545: Update Rubrik Sales Engineer Field On Accounts
    public List<String> SERoles = new List<String>(); // sales engineer role
    public Map<String,Id> adaptiveSEMap = new map<String,Id>();
    //SF-8995
    public Map<String,String> terrToRegionSEAdaptiveMap = new Map<String,String>();
    //SAL23-443 - Alliance Rep //SAL24-28 //SAL24-472
    private List<String> allianceRepRoles = new List<String>(); // Alliance rep role
    private Map<String,Map<string,Id>> adaptiveIdAllianceRepMap = new map<String,Map<string,Id>>(); // Changed is as part of SAL26-104
    //SAL24-14
    private List<String> sdrRoles = new List<String>(); // SDR Role
    private Map<String,Id> adaptiveIdSdrMap = new map<String,Id>();
    //SAL24-244
    private Map<String,Set<Id>> adaptiveIdSESetMap = new map<String,Set<Id>>();
    private Set<String> seAdaptiveIdSet = new Set<String>();
    private List<Account> updateATMAccounts = new List<Account>();
    public set<String> failedAdaptiveIds = new set<String>(); //SAL24-334 //failed SE Adaptive Id
    public boolean disableCaseTeamMemberLogic = false; //SAL24-735 - ETM H1FY25
      public Map<String,Set<Id>> regionToPooledSEMap = new Map<String,Set<Id>>(); //Pooled SE
    
/*************************************************************************
Description : constructor 
parameters :
1.reqSource : AccountUpdate(Batch class) or UserUpdate(User2TerritoryAssociation)
AccountUpdate : Considers all accounts that needs revaluation or assignment for account owner
UserUpdate: Used when Users assigned to territory are modified 
**********************************************************************************************/
    public string getUserToTerritories(string reqSource){
        string OTAquery;
        // salesEnggRole ='';
        //SAL25-56
        List<ETM_Territory_Controller__c> etmCSList = [select Id,Name,Field_API_Name__c,Field_Value__c,Operator__c,Field_Type__c from ETM_Territory_Controller__c where Name = 'Con_OTA_LMDT' limit 1];
        ETM_Territory_Controller__c etmCS = etmCSList[0];
        if(reqSource.equalsIgnoreCase('UserUpdate')) OTA_WHERECLAUSE= 'Where (' + 'Territory2Id IN : TerrId'; 
        else if(etmCS != null && etmCS.Name != null && etmCS.Field_API_Name__c!= null && etmCS.Field_Value__c != null && etmCS.Operator__c != null) {
            OTA_WHERECLAUSE= 'Where (' + etmCS.Field_API_Name__c +''+etmCS.Operator__c;
            if(etmCS.Field_Type__c.equalsIgnoreCase('Boolean') || etmCS.Field_Type__c.equalsIgnoreCase('DateTime'))   OTA_WHERECLAUSE+= etmCS.Field_Value__c ; 
            else    OTA_WHERECLAUSE+= '\''+String.escapeSingleQuotes(etmCS.Field_Value__c)+'\'' ;
        }
        //End
        List<Territory_Management_Setup__mdt> filterRec = [select DeveloperName,Field_API_Name__c,Field_Value__c,Field_Type__c,Operator__c from Territory_Management_Setup__mdt];
        for(Territory_Management_Setup__mdt fRec : filterRec){  
               if(fRec.DeveloperName.startsWith('Con_OTA')){
                   if(String.isNotBlank(fRec.Field_Value__c)){
                   if(String.isBlank(OTA_WHERECLAUSE)){
                    OTA_WHERECLAUSE = 'Where ('; //SF-8545
                   }
                   else
                   OTA_WHERECLAUSE+=' AND ';
                   OTA_WHERECLAUSE+= fRec.Field_API_Name__c +'' +fRec.Operator__c;
                   
                   if(fRec.Field_Type__c.equalsIgnoreCase('Boolean') || fRec.Field_Type__c.equalsIgnoreCase('DateTime'))
                     OTA_WHERECLAUSE+= fRec.Field_Value__c ; 
                   else
                   OTA_WHERECLAUSE+= '\''+String.escapeSingleQuotes(fRec.Field_Value__c)+'\'' ;
                  } 
              } 
              else if(fRec.DeveloperName.startsWith('Con_UTA') && String.isNotBlank(fRec.Field_Value__c)){
                   
                   if(fRec.Field_API_Name__c.equalsIgnoreCase('RoleInTerritory2')){ 
                      for(string UserRole: fRec.Field_Value__c.split(';')){
                          TerrType_OwnerRole.put(UserRole.split(':')[0].trim(),UserRole.split(':')[1].trim());
                       }
                      continue;
                   } 
                   else if(fRec.Field_API_Name__c.equalsIgnoreCase('CDM_RoleInTerritory2')){ 
                      for(string UserRole: fRec.Field_Value__c.split(';')){
                          CDMTerrType_OwnerRole.put(UserRole.split(':')[0].trim(),UserRole.split(':')[1].trim());
                       }
                      continue;
                   } 
                   if(String.isBlank(UTA_WHERECLAUSE)){
                     UTA_WHERECLAUSE = fRec.Field_API_Name__c +'' +fRec.Operator__c ; 
                   }
                   else
                   UTA_WHERECLAUSE+=' AND '+fRec.Field_API_Name__c +'' +fRec.Operator__c ; 
                   if(fRec.Field_Type__c.equalsIgnoreCase('Boolean')|| fRec.Field_Type__c.equalsIgnoreCase('DateTime'))
                     UTA_WHERECLAUSE+= fRec.Field_Value__c ;
                   else
                   UTA_WHERECLAUSE+= '\''+String.escapeSingleQuotes(fRec.Field_Value__c)+'\'' ;
              } 
             else if(fRec.DeveloperName.equalsIgnoreCase('Generate_logs')&& fRec.Field_Value__c != null){
              enableLogging = boolean.valueof(fRec.Field_Value__c) ;
             } 
              else if(fRec.DeveloperName.equalsIgnoreCase('Disable_AccountOwner_Assignment') && fRec.Field_Value__c != null){
              disable_AccountOwnerUpdate = boolean.valueof(fRec.Field_Value__c) ;
             }     
              else if(fRec.DeveloperName.equalsIgnoreCase('Disable_ContactOwner_Assignment') && fRec.Field_Value__c != null){
              disable_ContactOwnerUpdate = boolean.valueof(fRec.Field_Value__c) ;
             }     
              else if(fRec.DeveloperName.equalsIgnoreCase('Disable_ActivityOwner_Assignment') && fRec.Field_Value__c != null){
              disable_ActivityOwnerUpdate = boolean.valueof(fRec.Field_Value__c) ;
             } 
             else if(fRec.DeveloperName.equalsIgnoreCase('Disable_OpportunityOwner_Assignment') && fRec.Field_Value__c != null){
              disable_OppOwnerUpdate = boolean.valueof(fRec.Field_Value__c) ;
             } 
             //SF-8545: Update Rubrik Sales Engineer Field On Accounts
             else if(fRec.DeveloperName.equalsIgnoreCase('Role_of_Sales_Engineer') && fRec.Field_Value__c != null){ 
                for(string UserRole: fRec.Field_Value__c.split(';')){
                    SERoles.add(UserRole.trim());
                }
            }
            //SAL23-443 - Alliance Rep //SAL24-28 //SAL24-472
            else if(fRec.DeveloperName.equalsIgnoreCase('Role_of_Alliance_Rep') && fRec.Field_Value__c != null){ 
                for(string UserRole: fRec.Field_Value__c.split(';')){
                    allianceRepRoles.add(UserRole.trim());
                }
            }
            //SAL24-14
            else if(fRec.DeveloperName.equalsIgnoreCase('Role_of_SDR') && fRec.Field_Value__c != null){ 
                for(string UserRole: fRec.Field_Value__c.split(';')){
                    sdrRoles.add(UserRole.trim());
                }
            }
            //SAL24-735 - ETM H1FY25
            else if(fRec.DeveloperName.equalsIgnoreCase('Disable_CaseTeamMember_Logic') && fRec.Field_Value__c != null){
                disableCaseTeamMemberLogic = boolean.valueof(fRec.Field_Value__c) ;
            }
        }
       
        OTAquery = 'select id,ObjectId, SobjectType,lastmodifieddate,Territory2.Adaptive_Territory_Id__c,Territory2Id,'+
                    'Territory2.ParentTerritory2Id,Territory2.ParentTerritory2.ParentTerritory2Id,Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,'+
                    'Territory2.DeveloperName,Territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,'+
                    'Territory2.Channel_Territory__c,territory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c, '+
                    'Territory2.Territory_Structure_Type__c '+ //PL26-18
                    'FROM ObjectTerritory2Association ' ; 
        if(String.isNotBlank(OTA_WHERECLAUSE)){
            //SF-8545: Update Rubrik Sales Engineer Field On Accounts
            //OTAquery+= OTA_WHERECLAUSE +' Order by lastmodifieddate' ;
            OTAquery+= OTA_WHERECLAUSE +') OR ((Territory2Id IN :allianceRepTerrIds OR Territory2Id IN :sdrTerrIds OR Territory2.Adaptive_Territory_Id__c IN :SEAdaptiveIds) AND Territory2.Territory2Model.State = \'Active\') Order by lastmodifieddate' ; //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472
        }
       return OTAquery ;
    }    
/*************************************************************************
Description : called from batch 
**************************************************************************/
    
    public list<Custom_Error_Log__c> processOwnerAssignment(List<ObjectTerritory2Association>acctTerritoryAssociationList) {
        string queryUTA ='';
        ProcessedLeafterritoryId = new set<Id>();
        AccountTriggerHelper.bypassOppOwnerAssignment = true;
        set<Id>AccountIds = new set<Id>();
        Map<Id, Id> acctTerritoryId = new Map<Id, Id>();  
        Map<string,string> terrIdTART = new Map<string,string>(); 
        for(ObjectTerritory2Association OTA : acctTerritoryAssociationList) { 
            if(!terr_ATA.containsKey(OTA.Territory2Id)){ 
                if(OTA.Territory2.DeveloperName.equalsIgnoreCase(UNASSIGNED_TERRITORY) ) {  
                if(TerrId_Owner.containsKey(OTA.Territory2Id))
                 Adaptive_Owner.put(UNASSIGNED_TERRITORY,TerrId_Owner.get(OTA.Territory2Id));
                else if(TerrId_Owner.containsKey(OTA.Territory2.ParentTerritory2Id)) 
                  Adaptive_Owner.put(UNASSIGNED_TERRITORY,TerrId_Owner.get(OTA.Territory2.ParentTerritory2Id));
                }
                else
                terr_ATA.put(OTA.Territory2Id,OTA);
                Adaptive_leafterr.put(OTA.Territory2.Adaptive_Territory_Id__c,OTA.Territory2Id);
                if(OTA.Territory2.Adaptive_Territory_Id__c!=null) // For Global territories where adaptive Id is null
                Adaptive_Owner.put(OTA.Territory2.Adaptive_Territory_Id__c, NO_TERRITORY_OWNER);
            }
            if(!OTA.Territory2.DeveloperName.equalsIgnoreCase(UNASSIGNED_TERRITORY) && !terrIdTART.containskey(OTA.Territory2.Adaptive_Territory_Id__c)){
            terrIdTART.put(OTA.Territory2.Adaptive_Territory_Id__c,OTA.territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                                                   +OTA.territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                                                   +OTA.territory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                                                   +OTA.Territory2.Internal_Territory_Name__c+'_'
                                                                    +OTA.territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c+'_'
                                                                    +OTA.territory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c+'_'
                                                                    +OTA.territory2.ParentTerritory2.Channel_Territory__c+'_'
                                                                    +OTA.Territory2.Channel_Territory__c+'_'  // Theater_Area_Region_Terrritory (AETART_CDMTART)
                                                                    +OTA.Territory2.Territory_Structure_Type__c); //PL26-18:added structure type field
            }                 
            AccountIds.add(OTA.ObjectId); // One account will be part of one territory
            ProcessedLeafterritoryId.add(OTA.Territory2Id);
        }
        getTerritoryOwner_LevelBased(terr_ATA.keyset(),null,0);
        ownerAssignment(AccountIds,terrIdTART);
        return errorLogs.values();
    } 

/***************************************************************************
Description : Fetch owner against each territory
**************************************************************************/
 public void getTerritoryOwner_TerrBased(){
 set<string> possibleOwnerRoles = new set<string>(TerrType_OwnerRole.values());
 possibleOwnerRoles.addall(CDMTerrType_OwnerRole.values());
 //SF-8545: Update Rubrik Sales Engineer Field on Accounts
 //string queryUTA ='Select Id,UserId,Territory2Id,Territory2.DeveloperName,Territory2.SubType__c,RoleInTerritory2,Territory2.Territory2Type.DeveloperName,Territory2.Adaptive_Territory_Id__c from UserTerritory2Association where RoleInTerritory2 IN : possibleOwnerRoles ';
 string queryUTA ='Select Id,UserId,User.Name,Territory2Id,Territory2.DeveloperName,Territory2.SubType__c,RoleInTerritory2,Territory2.Territory2Type.DeveloperName,Territory2.Adaptive_Territory_Id__c,Territory2.SE_Pooling__c from UserTerritory2Association where (RoleInTerritory2 IN : possibleOwnerRoles OR RoleInTerritory2 IN :SERoles OR RoleInTerritory2 IN :sdrRoles OR RoleInTerritory2 IN :allianceRepRoles)'; //Pooled SE //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472
 if(string.isNotBlank(UTA_WHERECLAUSE))
    queryUTA+= ' AND '+UTA_WHERECLAUSE;
 for(UserTerritory2Association UTA : database.query(queryUTA)){ 
        if(UTA.Territory2.SubType__c!=null && UTA.Territory2.SubType__c.equalsIgnoreCase('Channel')){
        if(UTA.RoleInTerritory2.equalsIgnoreCase(CDMTerrType_OwnerRole.get(UTA.Territory2.Territory2Type.DeveloperName))){
        TerrId_Owner.put(UTA.Territory2Id,UTA.UserId);
        }
       }
        else{
        if(UTA.RoleInTerritory2.equalsIgnoreCase(TerrType_OwnerRole.get(UTA.Territory2.Territory2Type.DeveloperName))){
            TerrId_Owner.put(UTA.Territory2Id,UTA.UserId);
        }
        else if(UTA.Territory2.DeveloperName.equalsIgnoreCase(UNASSIGNED_TERRITORY) && UTA.RoleInTerritory2 == TerrType_OwnerRole.get(UNASSIGNED_TERRITORY)){
           TerrId_Owner.put(UTA.Territory2Id,UTA.UserId);
       }
       }

        //SF-8545: Update Rubrik Sales Engineer Field On Accounts
        //SF-8995
        if((UTA.Territory2.Territory2Type.DeveloperName == 'Territory' || UTA.Territory2.Territory2Type.DeveloperName == 'Region') && SERoles.contains(UTA.RoleInTerritory2) && !AdaptiveSEMap.containskey(UTA.Territory2.Adaptive_Territory_Id__c)){
            AdaptiveSEMap.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.UserId);
        }

        //Pooled SE start
        if(UTA.Territory2.Territory2Type.DeveloperName == 'Region' && UTA.Territory2.SE_Pooling__c){
            if(regionToPooledSEMap.isEmpty() || !regionToPooledSEMap.containskey(UTA.Territory2.Adaptive_Territory_Id__c)){
                regionToPooledSEMap.put(UTA.Territory2.Adaptive_Territory_Id__c,new Set<Id>());
            }
            regionToPooledSEMap.get(UTA.Territory2.Adaptive_Territory_Id__c).add(UTA.UserId);   
        }
        //Pooled SE end
        //SAL23-443 - Alliance Rep //SAL24-28 //SAL24-472
        //Updated below if condition as part of SAL26-104 START
        if(UTA.Territory2.Territory2Type.DeveloperName == 'Territory' && allianceRepRoles.contains(UTA.RoleInTerritory2)){   
            if(!adaptiveIdAllianceRepMap.containskey(UTA.Territory2.Adaptive_Territory_Id__c)){
                adaptiveIdAllianceRepMap.put(UTA.Territory2.Adaptive_Territory_Id__c,new Map<string,Id>{UTA.RoleInTerritory2 => UTA.UserId});
            }else{
                Map<string, Id> tempMap = adaptiveIdAllianceRepMap.get(UTA.Territory2.Adaptive_Territory_Id__c);
                if(!tempMap.Containskey(UTA.RoleInTerritory2)){
                    tempMap.put(UTA.RoleInTerritory2, UTA.UserId);
                    adaptiveIdAllianceRepMap.put(UTA.Territory2.Adaptive_Territory_Id__c,tempMap);
                }
            }
        }
        //END SAL26-104
        //SAL24-14
        if(UTA.Territory2.Territory2Type.DeveloperName == 'Territory' && sdrRoles.contains(UTA.RoleInTerritory2) && !adaptiveIdSdrMap.containskey(UTA.Territory2Id)){
            adaptiveIdSdrMap.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.UserId);
        }
        //SAL24-244 - Get list of SE for each territory and add to set and map with adaptive Id
        if(UTA.Territory2.Territory2Type.DeveloperName == 'Territory' && SERoles.contains(UTA.RoleInTerritory2)){
            Set<Id> seIdSet = new Set<Id>();
            if(adaptiveIdSESetMap.containsKey(UTA.Territory2.Adaptive_Territory_Id__c)) seIdSet = adaptiveIdSESetMap.get(UTA.Territory2.Adaptive_Territory_Id__c);
            seIdSet.add(UTA.UserId);
            adaptiveIdSESetMap.put(UTA.Territory2.Adaptive_Territory_Id__c,seIdSet);
        }
    }
    
    //SF-8995
    for(Territory2 Terr:[Select id, Adaptive_Territory_Id__c, ParentTerritory2.Adaptive_Territory_Id__c from territory2 where Territory2Model.state='Active' and Territory2Type.DeveloperName = 'Territory']){
        terrToRegionSEAdaptiveMap.put(Terr.Adaptive_Territory_Id__c,Terr.ParentTerritory2.Adaptive_Territory_Id__c);
    }
}
    
/***************************************************************************
Description : ownerassignment 
parameters :
1. updateState : all - all the accounts of territory
partial - specified accounts in param of territory
**************************************************************************/
    private void getTerritoryOwner_LevelBased(set<Id>TerrId,map<Id,List<string>> pre_Terr_leafAdaptiveId ,Integer level){
        string queryUTA ='';
        string errRecId,errMsg ='';
        map<Id,List<string>> Terr_leafAdaptiveId = new map<Id,List<string>>(); 
        set<id>ProcessedTerritoryId = new set<id>();
         for(Id TId:TerrId){
         if(TerrId_Owner.containsKey(TId)){
         if(level==0) { //Territory level
                 if(terr_ATA.containsKey(TId))
                 Adaptive_Owner.put(terr_ATA.get(TId).Territory2.Adaptive_Territory_Id__c,TerrId_Owner.get(TId)); 
          }      
                
            else{
                if(pre_Terr_leafAdaptiveId.containskey(TId)){
                    for(string adaptiveId :pre_Terr_leafAdaptiveId.get(TId))
                        Adaptive_Owner.put(adaptiveId,TerrId_Owner.get(TId));
                }
            }
             ProcessedTerritoryId.add(TId);
           }     
         
         }
         TerrId.removeall(ProcessedTerritoryId);
        for(Id TId:TerrId){
            switch on level {
                when 0 {
                    if(!Terr_leafAdaptiveId.containskey(terr_ATA.get(TId).Territory2.ParentTerritory2Id))
                        Terr_leafAdaptiveId.put(terr_ATA.get(TId).Territory2.ParentTerritory2Id,new List<string>{terr_ATA.get(TId).Territory2.Adaptive_Territory_Id__c}); // Region
                    else
                        Terr_leafAdaptiveId.get(terr_ATA.get(TId).Territory2.ParentTerritory2Id).add(terr_ATA.get(TId).Territory2.Adaptive_Territory_Id__c); // Region              
                }
                when 1 {
                    if(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2Id!=null){
                        if(!Terr_leafAdaptiveId.containskey(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2Id))
                            Terr_leafAdaptiveId.put(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2Id,new List<string>(pre_Terr_leafAdaptiveId.get(TId))); //Area 
                        else
                            Terr_leafAdaptiveId.get(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2Id).addall(pre_Terr_leafAdaptiveId.get(TId)); //Area 
                    }
                    else{
                         if(errorLogs.containskey(NO_TERRITORY_OWNER)){
                            errorLogs.get(NO_TERRITORY_OWNER).FailedRecords__c += ','+pre_Terr_leafAdaptiveId.get(TId);
                        }
                        else{
                        errRecId = String.join(pre_Terr_leafAdaptiveId.get(TId), ',').length()>255?(String.join(pre_Terr_leafAdaptiveId.get(TId), ',')).substring(0,255):String.join(pre_Terr_leafAdaptiveId.get(TId), ',');
                        errorLogs.put(NO_TERRITORY_OWNER,new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, FailedRecords__c = errRecId, Exception_Message__c = NO_TERRITORY_OWNER , Class__c =CLASS_NAME));
                        }
                  }
                }
                
                when 2 {
                    if(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id!=null){
                        if(!Terr_leafAdaptiveId.containskey(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id))
                            Terr_leafAdaptiveId.put(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,new List<string>(pre_Terr_leafAdaptiveId.get(TId))); //Theatre 
                        else
                            Terr_leafAdaptiveId.get(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id).addall(pre_Terr_leafAdaptiveId.get(TId)); //Theatre 
                    }
                    else{
                        if(errorLogs.containskey(NO_TERRITORY_OWNER)){
                            errorLogs.get(NO_TERRITORY_OWNER).FailedRecords__c += ','+pre_Terr_leafAdaptiveId.get(TId);
                        }
                        else{
                         errRecId = String.join(pre_Terr_leafAdaptiveId.get(TId), ',').length()>255?(String.join(pre_Terr_leafAdaptiveId.get(TId), ',')).substring(0,255):String.join(pre_Terr_leafAdaptiveId.get(TId), ',');
                        errorLogs.put(NO_TERRITORY_OWNER,new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, FailedRecords__c = errRecId, Exception_Message__c = NO_TERRITORY_OWNER,Class__c = CLASS_NAME));
                     }
                     }            
                }
                when 3 {
                    if(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id!=null){
                        if(!Terr_leafAdaptiveId.containskey(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id))
                            Terr_leafAdaptiveId.put(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id,new List<string>(pre_Terr_leafAdaptiveId.get(TId))); //Global 
                        else
                            Terr_leafAdaptiveId.get(terr_ATA.get(Adaptive_leafterr.get(pre_Terr_leafAdaptiveId.get(TId)[0])).Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2Id).addall(pre_Terr_leafAdaptiveId.get(TId)); //Global 
                    }
                    else{
                        if(errorLogs.containskey(NO_TERRITORY_OWNER)){
                            errorLogs.get(NO_TERRITORY_OWNER).FailedRecords__c += ','+pre_Terr_leafAdaptiveId.get(TId);
                        }
                        else{
                         errRecId = String.join(pre_Terr_leafAdaptiveId.get(TId), ',').length()>255?(String.join(pre_Terr_leafAdaptiveId.get(TId), ',')).substring(0,255):String.join(pre_Terr_leafAdaptiveId.get(TId), ',');
                        errorLogs.put(NO_TERRITORY_OWNER,new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, FailedRecords__c = errRecId, Exception_Message__c = NO_TERRITORY_OWNER,Class__c = CLASS_NAME));
                     }
                     }            
                }
                when else {
                    System.debug('Exceeds the level used for owner assignment');
                }    
            }       
        }  
        if(TerrId.size()>0 && level+1 < MAX_TERRITORY_HIERARCHY_DEPTH ){
            getTerritoryOwner_LevelBased(Terr_leafAdaptiveId.keyset(),Terr_leafAdaptiveId,level+1);
        }
        else{
            System.debug('No owner for this territory'+TerrId);
        } 
    }
    
/**************************************************************************
Description : ownerassignment 
parameters :
1.updateState : all - all the accounts of territory
partial - specified accounts in param of territory
**************************************************************************/
    
    private void ownerAssignment(set<Id>updateAccIds , map<string,string>terrIdTART){
        //1.Update Account Owner
        List<Account> accOwnerUpdateList = new List<account>();
        string errRecId='';
        Integer i =0;
        set<string> AETerr= new set<string>();
        Map<string,string> AE_CDM_Mapping = new Map<string,string>();
        Map<string,string> CDM_CDMTART = new Map<string,string>();
        updateATMAccounts = new List<Account>(); //SAL24-334/SF-37097 - DML issue fix
        //SF-8545: Update Rubrik Sales Engineer Field On Accounts
        //SAL23-384 - Update Account only if any changes 
        //accOwnerUpdateList =  [SELECT Id, OwnerId, Disable_Auto_OwnerAssignment__c ,Adaptive_Territory_Id__c, Rubrik_Sales_Engineer__c, RecordTypeId FROM Account WHERE Id IN :updateAccIds]; //SAL22-338
        Map<Id, Account> oldAccMap = new Map<Id, Account>([SELECT Id, OwnerId,Pooled_SE_Override__c,Rubrik_Sales_Engineer_Id__c, Disable_Auto_OwnerAssignment__c ,Adaptive_Territory_Id__c, Rubrik_Sales_Engineer__c, RecordTypeId, Is_RSE_Added_Manually__c, //SAL23-417
                                                            CDM_Theatre__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c,ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,ETM_SDR__c,AWS_GCP_Cloud_Alliance_BDM__c,MSFT_OCI_Cloud_Alliance_BDM__c FROM Account WHERE Id IN :updateAccIds]); //SAL22-338 //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472 //Removed Account_Alliance_BDM_Lookup__c as part of SAL26-101 and Added AWS_GCP_Cloud_Alliance_BDM__c,MSFT_OCI_Cloud_Alliance_BDM__c fields as part of SAL26-105
        List<Account> updAccList = [SELECT Id, OwnerId,Pooled_SE_Override__c,Rubrik_Sales_Engineer_Id__c, Disable_Auto_OwnerAssignment__c ,Adaptive_Territory_Id__c, Rubrik_Sales_Engineer__c, RecordTypeId, Is_RSE_Added_Manually__c, //SAL23-417
                                    CDM_Theatre__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c,ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,ETM_SDR__c, 
                                    Non_Core_Adaptive_Territory_Ids__c, PLS_SaaS_Theatre__c,PLS_SaaS_ETM_Area__c,PLS_SaaS_ETM_Region__c,PLS_SaaS_ETM_Territory__c,PLS_NAS_Theatre__c,PLS_NAS_ETM_Area__c,PLS_NAS_ETM_Region__c,PLS_NAS_ETM_Territory__c,//PL26-18: added new fields
                                    PLS_NCD_ETM_Area__c,PLS_NCD_ETM_Region__c,PLS_NCD_ETM_Territory__c,PLS_NCD_Theatre__c,AWS_GCP_Cloud_Alliance_BDM__c,MSFT_OCI_Cloud_Alliance_BDM__c FROM Account WHERE Id IN :updateAccIds]; //SAL22-338 //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472 //Pooled SE //Removed Account_Alliance_BDM_Lookup__c as part of SAL26-101 and Added AWS_GCP_Cloud_Alliance_BDM__c,MSFT_OCI_Cloud_Alliance_BDM__c fields as part of SAL26-105
        //SAL24-244 - Get list of territory adaptive Id that are added/removed SE - stored in Territory_Owner_Assignment__c
        for(Territory_Owner_Assignment__c SETerr : [select id,AdaptiveId__c,LeafTerritoryId__c,Functionality__c from Territory_Owner_Assignment__c where Functionality__c='Sales Engineer Assignment' AND Functionality__c NOT IN ('Owner Assignment','Opp Co-Owner Assignment') limit 50000]){ //PL26-38 added Functionality__c filter
            seAdaptiveIdSet.add(SETerr.AdaptiveId__c);
        }
        for(Account acct : updAccList) {
                
            /*** PL26-18 ***/
            Boolean isAnyETMFieldChanged = assignAccountETMFields(acct, terrIdTART); // created to populate non core ETM field
            if(String.isBlank(acct.Adaptive_Territory_Id__c)) {
                if(isAnyETMFieldChanged){
                    accOwnerUpdateList.add(acct);
            }
                continue;
            }
            
            assignAccountOwner(acct, Adaptive_Owner); //move logic to separate method
            /** PL26-18 End**/
           
            //SF-8545: Update Rubrik Sales Engineer Field On Accounts
            //SF-8995
            //acct.Rubrik_Sales_Engineer__c = acct.Adaptive_Territory_Id__c!=null && AdaptiveSEMap.get(acct.Adaptive_Territory_Id__c) != acct.Rubrik_Sales_Engineer__c ? AdaptiveSEMap.get(acct.Adaptive_Territory_Id__c) : null;
            String parentSEAdaptiveId = terrToRegionSEAdaptiveMap.get(acct.Adaptive_Territory_Id__c);
            //SAL22-338
            Id territoryRSE = acct.Adaptive_Territory_Id__c!=null && AdaptiveSEMap.get(acct.Adaptive_Territory_Id__c) != null ? 
                                AdaptiveSEMap.get(acct.Adaptive_Territory_Id__c) : 
                                acct.Adaptive_Territory_Id__c!=null && parentSEAdaptiveId != null && AdaptiveSEMap.get(parentSEAdaptiveId) != null ? AdaptiveSEMap.get(parentSEAdaptiveId) : null ;
            if(!acct.Disable_Auto_OwnerAssignment__c && !acct.Pooled_SE_Override__c){ //Pooled SE
                //SAL23-417
                //acct.Rubrik_Sales_Engineer__c = territoryRSE != null ? territoryRSE : Label.Account_RecordType_Partner_Distributor.contains(acct.RecordTypeId) ? territoryRSE : acct.Rubrik_Sales_Engineer__c;
                acct.Rubrik_Sales_Engineer__c = territoryRSE != null ? territoryRSE : Label.Account_RecordType_Partner_Distributor.contains(acct.RecordTypeId) || !acct.Is_RSE_Added_Manually__c ? territoryRSE : acct.Rubrik_Sales_Engineer__c;
            }
            acct.Rubrik_Sales_Engineer_Id__c = territoryRSE != null ? (String)territoryRSE : ''; //always contains SE of ETM - Pooled SE
            if(acct.Pooled_SE_Override__c){ //Pooled SE
                Set<Id> regionSEUserIds = new Set<Id>();
                
                if(regionToPooledSEMap.containskey(parentSEAdaptiveId) && regionToPooledSEMap.get(parentSEAdaptiveId) != null)
                    regionSEUserIds = regionToPooledSEMap.get(parentSEAdaptiveId);
                if(regionSEUserIds.isEmpty() || !regionSEUserIds.contains(acct.Rubrik_Sales_Engineer__c)){
                    acct.Pooled_SE_Override__c = false;
                    acct.Rubrik_Sales_Engineer__c = acct.Rubrik_Sales_Engineer_Id__c;
                }
            } //Pooled SE 
            //acct.Is_SE_Existing_In_Territory__c = territoryRSE != null ? TRUE: FALSE; //SAL23-417
            //SAL22-338 - End

            //SAL23-443 - Alliance Rep
            //acct.Account_Alliance_BDM__c = adaptiveIdAllianceRepMap?.get(acct.Adaptive_Territory_Id__c); //SAL24-28
            //Commented below line as part of SAL26-101
            //acct.Account_Alliance_BDM_Lookup__c = adaptiveIdAllianceRepMap?.get(acct.Adaptive_Territory_Id__c); //SAL24-472
            //Added below if condition as part of SAL26-104
            If(adaptiveIdAllianceRepMap.containskey(acct.Adaptive_Territory_Id__c)){
                Map<string, Id> terrUserMap = adaptiveIdAllianceRepMap.get(acct.Adaptive_Territory_Id__c);
                if(terrUserMap.containskey('AWS/GCP Alliance Rep')){
                    acct.AWS_GCP_Cloud_Alliance_BDM__c = terrUserMap.get('AWS/GCP Alliance Rep');
                }else{
                    acct.AWS_GCP_Cloud_Alliance_BDM__c = null;
                }
                if(terrUserMap.containskey('MSFT/OCL Alliance Rep')){
                    acct.MSFT_OCI_Cloud_Alliance_BDM__c = terrUserMap.get('MSFT/OCL Alliance Rep');
                }else{
                    acct.MSFT_OCI_Cloud_Alliance_BDM__c = null;
                }
            }else {
                acct.AWS_GCP_Cloud_Alliance_BDM__c = null;
                acct.MSFT_OCI_Cloud_Alliance_BDM__c = null;
            }            
            acct.ETM_SDR__c = adaptiveIdSdrMap?.get(acct.Adaptive_Territory_Id__c); //SAL24-14

            //SAL23-384 - Update account only if any changes
            Account oldAcc = oldAccMap.get(acct.Id);
            acct.Is_RSE_Added_Manually__c = acct.Rubrik_Sales_Engineer__c != oldAcc.Rubrik_Sales_Engineer__c ? false : acct.Is_RSE_Added_Manually__c;//SAL23-417
            //Removed || acct.Account_Alliance_BDM_Lookup__c != oldAcc.Account_Alliance_BDM_Lookup__c condition as part of SAL26-101
            if(Test.isRunningTest() || acct.ownerId != oldAcc.ownerId || acct.Rubrik_Sales_Engineer__c != oldAcc.Rubrik_Sales_Engineer__c || acct.Is_RSE_Added_Manually__c != oldAcc.Is_RSE_Added_Manually__c || //SAL23-417
              acct.ETM_SDR__c != oldAcc.ETM_SDR__c || isAnyETMFieldChanged || acct.Pooled_SE_Override__c  != oldAcc.Pooled_SE_Override__c || acct.Rubrik_Sales_Engineer_Id__c  != oldAcc.Rubrik_Sales_Engineer_Id__c ||
              acct.AWS_GCP_Cloud_Alliance_BDM__c != oldAcc.AWS_GCP_Cloud_Alliance_BDM__c || acct.MSFT_OCI_Cloud_Alliance_BDM__c != oldAcc.MSFT_OCI_Cloud_Alliance_BDM__c){ //Pooled SE  //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472 // Added this line condition as part of SAL26-105
                     accOwnerUpdateList.add(acct);
            } //End
            
            //SAL24-244 - //Add/Remove ATM on accounts that are moved to another territory or associated to a territory that are added/removed SE from it
            if(Test.isRunningTest() || acct.ownerId != oldAcc.ownerId || acct.Rubrik_Sales_Engineer__c != oldAcc.Rubrik_Sales_Engineer__c || acct.ETM_Territory__c != oldAcc.ETM_Territory__c || seAdaptiveIdSet.contains(acct.Adaptive_Territory_Id__c)){ //SAL24-373
                updateATMAccounts.add(acct);
            } //End
        }
        if(!accOwnerUpdateList.isEmpty()) {
            AccountTriggersHandler.disableCaseTeamMemberUpdate = disableCaseTeamMemberLogic; //SAL24-735 - ETM H1FY25 
            for (Database.SaveResult sr : database.update(accOwnerUpdateList, false)) {
                if (!sr.isSuccess()) {
                    failedAccIds.add(accOwnerUpdateList[i].id);
                    updateAccIds.remove(accOwnerUpdateList[i].id);
                    //finalUpdateAccounts.remove(accOwnerUpdateList[i].id);
                    for(Database.Error err : sr.getErrors()) {
                          if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage())){ 
                                if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                                    errorLogs.get(err.getMessage()).FailedRecords__c += ','+accOwnerUpdateList[i].Id;              
                            }
                            else{
                                  errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c =  (err.getMessage()+':'+err.getFields()),Class__c = CLASS_NAME,FailedRecords__c=accOwnerUpdateList[i].Id));
                            }
                        failedAdaptiveIds.add(accOwnerUpdateList[i].Adaptive_Territory_Id__c); //SAL24-334
                    }
                }
                i++;
            }
        }

        //SAL24-244
        if(!updateATMAccounts.isEmpty()){
            updateAccountTeams();
        }
        
         /********* MOVED THE LOGIC TO DIFFERENT BATCH **************************************************************** 
                     
          Update Contact and opportunity
       
        /********* END MOVED THE LOGIC TO DIFFERENT BATCH ****************************************************************/ 
       
        //3.update Open Task Owner related to account
        
        if(disable_ActivityOwnerUpdate == false || Test.isRunningTest()){
        List<Task> openTaskList = [SELECT Id,Account.OwnerId FROM TASK 
                                   WHERE AccountId IN :updateAccIds AND Isclosed = false AND Account.Disable_Auto_OwnerAssignment__c=false AND account.RecordType.name='Customer/Prospect'];
        set<Id>ActivityId = new set<Id>();
        for(Task t : openTaskList) {
            t.ownerId = t.Account.OwnerId;
            ActivityId.add(t.id);
        }
        
        if(!openTaskList.isEmpty()) {
            for (Database.SaveResult sr : database.update(openTaskList, false)) {
                i=0;
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage())){ 
                                if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                                    errorLogs.get(err.getMessage()).FailedRecords__c += ','+openTaskList[i].Id;              
                            }
                            else{
                                  errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = (err.getMessage()+':'+err.getFields()),Class__c = CLASS_NAME,FailedRecords__c=openTaskList[i].Id));
                            }     
                    }
                }
                i++;
            }
        
        }
        
        //4.update Open Event Owner related to account
        
        List<Event> openEventList = [SELECT Id,Account.OwnerId FROM Event 
                                     WHERE AccountId IN :updateAccIds AND ActivityDate >= TODAY AND Account.Disable_Auto_OwnerAssignment__c=false AND account.RecordType.name='Customer/Prospect'];
        for(Event e : openEventList) {
            e.ownerId = e.Account.OwnerId;
            ActivityId.add(e.id);
        }
        
        if(!openEventList.isEmpty()) {
            for (Database.SaveResult sr : database.update(openEventList, false)) {
                i =0;
                if (!sr.isSuccess()) { 
                    for(Database.Error err : sr.getErrors()) {
                         if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage())){ 
                                if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                                    errorLogs.get(err.getMessage()).FailedRecords__c += ','+openEventList[i].Id;              
                            }
                            else{
                                  errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = err.getMessage(),Class__c = CLASS_NAME,FailedRecords__c=openEventList[i].Id));
                            }          
                    }
                }
                i++;
            }
        
        } 
        
        }
    }  
  
    //SAL24-244
    private void updateAccountTeams(){
        List<AccountTeamMember> insertAccountTeamList = new List<AccountTeamMember>();
        List<AccountTeamMember> deleteAccountTeamList = new List<AccountTeamMember>();
        //fetch existing account team records to be deleted
        for(AccountTeamMember aTM : [SELECT Id, AccountId, UserId, TeamMemberRole 
                                FROM AccountTeamMember 
                                WHERE AccountId IN :updateATMAccounts AND TeamMemberRole = 'Sales Engineer ETM']){
            deleteAccountTeamList.add(aTM);
        }
        for(Account acc :updateATMAccounts){
            if(adaptiveIdSESetMap != null && adaptiveIdSESetMap.containsKey(acc.Adaptive_Territory_Id__c)) //SAL24-373
                for(Id userId :adaptiveIdSESetMap.get(acc.Adaptive_Territory_Id__c)){
                    insertAccountTeamList.add(new AccountTeamMember(
                                                        AccountId = acc.Id, 
                                                        UserId = userId, 
                                                        TeamMemberRole = 'Sales Engineer ETM',
                                                        AccountAccessLevel = 'Edit', 
                                                        OpportunityAccessLevel = 'Edit',
                                                        CaseAccessLevel = 'Edit'
                                                    ));
                }
        }

        //delete old account team records for SE
        if(!deleteAccountTeamList.isEmpty()){
            List<Database.DeleteResult> drList = Database.delete(deleteAccountTeamList, false);
            LogError.deleteDMLErrorLog((List<SObject>)deleteAccountTeamList, drList, CLASS_NAME,'ETM - Delete AccountTeam'); //SAL24-334
        }

        //insert new account team records for SE
        if(!insertAccountTeamList.isEmpty()){
            List<Database.SaveResult> srList = Database.insert(insertAccountTeamList, false);
            LogError.createDMLErrorLog((List<SObject>)insertAccountTeamList, srList, CLASS_NAME,'ETM - Insert AccountTeam'); //SAL24-334
        }
    } //End      

    public static void assignAccountOwner(Account acct, Map<string,string> Adaptive_Owner) {
        if(acct.Adaptive_Territory_Id__c!=null && acct.Disable_Auto_OwnerAssignment__c==false && Adaptive_Owner.containskey(acct.Adaptive_Territory_Id__c)&& Adaptive_Owner.get(acct.Adaptive_Territory_Id__c)!= NO_TERRITORY_OWNER 
           && Adaptive_Owner.get(acct.Adaptive_Territory_Id__c)!= acct.ownerId
          ){
              acct.ownerId = Adaptive_Owner.get(acct.Adaptive_Territory_Id__c);
          }
        else{
            // Assign accounts to unassigned account territory 
        }
    }
    
    /*** PL26-18: populate ETM fields on account, based on territory type **/
    private Boolean assignAccountETMFields(Account acct, Map<String, String> terrIdTART){
        List<string> TART = new List<string>();
        Boolean isChanged = false;
        List<String> adaptiveIdsList = String.isNotBlank(acct.Non_Core_Adaptive_Territory_Ids__c) ?
            acct.Non_Core_Adaptive_Territory_Ids__c.contains(',') ? acct.Non_Core_Adaptive_Territory_Ids__c.split(',') : 
            new List<String>{acct.Non_Core_Adaptive_Territory_Ids__c} :
            new List<String>();
        
        if(acct.Adaptive_Territory_Id__c != null){
            adaptiveIdsList.add(acct.Adaptive_Territory_Id__c);
        }
        for(String adaptiveId : adaptiveIdsList){
            TART = new List<String>();
            
            if(terrIdTART.containsKey(adaptiveId)){
                TART = terrIdTART.get(adaptiveId).split('_');                
                String terType =  TART[8] != null && String.isNotBlank(TART[8]) && TART[8] != 'null' ? TART[8] : 'Core';                
                
                if(terType == 'Core' && (acct.ETM_Theatre__c != TART[0] || acct.ETM_Area__c != TART[1] || acct.ETM_Region__c != TART[2] || acct.ETM_Territory__c != TART[3]
                                         || acct.CDM_Theatre__c != TART[4] || acct.CDM_Area__c != TART[5] || acct.CDM_Region__c != TART[6] || acct.CDM_Territory__c != TART[7])){
                                             acct.ETM_Theatre__c = TART[0];
                                             acct.ETM_Area__c = TART[1]; 
                                             acct.ETM_Region__c = TART[2];
                                             acct.ETM_Territory__c = TART[3];
                                             acct.CDM_Theatre__c = TART[4];
                                             acct.CDM_Area__c = TART[5];
                                             acct.CDM_Region__c = TART[6];
                                             acct.CDM_Territory__c = TART[7];
                                             isChanged = true;
                                         } else if(terType == 'PLS SaaS' && (acct.PLS_SaaS_Theatre__c != TART[0] || acct.PLS_SaaS_ETM_Area__c != TART[1] ||
                                                                             acct.PLS_SaaS_ETM_Region__c != TART[2] || acct.PLS_SaaS_ETM_Territory__c != TART[3])) {
                                                                                 acct.PLS_SaaS_Theatre__c = TART[0];
                                                                                 acct.PLS_SaaS_ETM_Area__c = TART[1]; 
                                                                                 acct.PLS_SaaS_ETM_Region__c = TART[2];
                                                                                 acct.PLS_SaaS_ETM_Territory__c = TART[3];
                                                                                 isChanged = true;
                                                                             } else if(terType == 'PLS Cloud' && (acct.PLS_NAS_Theatre__c != TART[0] || acct.PLS_NAS_ETM_Area__c != TART[1] ||
                                                                                                                acct.PLS_NAS_ETM_Region__c != TART[2] || acct.PLS_NAS_ETM_Territory__c != TART[3])) {
                                                                                                                    acct.PLS_NAS_Theatre__c = TART[0];
                                                                                                                    acct.PLS_NAS_ETM_Area__c = TART[1]; 
                                                                                                                    acct.PLS_NAS_ETM_Region__c = TART[2];
                                                                                                                    acct.PLS_NAS_ETM_Territory__c = TART[3];//SAL26-138:NAS to Cloud
                                                                                                                    isChanged = true;
                                                                                                                } else if(terType == 'PLS NCD' && (acct.PLS_NCD_Theatre__c != TART[0] || acct.PLS_NCD_ETM_Area__c != TART[1] ||
                                                                                                                                                   acct.PLS_NCD_ETM_Region__c != TART[2] || acct.PLS_NCD_ETM_Territory__c != TART[3])){
                                                                                                                                                       acct.PLS_NCD_Theatre__c = TART[0];
                                                                                                                                                       acct.PLS_NCD_ETM_Area__c = TART[1]; 
                                                                                                                                                       acct.PLS_NCD_ETM_Region__c = TART[2];
                                                                                                                                                       acct.PLS_NCD_ETM_Territory__c = TART[3];
                                                                                                                                                       isChanged = true;
                                                                                                                                                   }
            }
        }
        return isChanged;
    }
}