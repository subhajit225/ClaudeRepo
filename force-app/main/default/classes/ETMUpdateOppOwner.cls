/**
* @description To Update Owner and TART values based on opportunity based on territory model or account Object 
Split opp : Update TART ,sales Engg Based on opp owner and its ref in territory model
Revenue/Renewal opp : Based on account territory update TART,sales Engg
* @Developer    Chaitra
* @Date         11/2019
*/

public class ETMUpdateOppOwner implements Database.Batchable<sObject>,Database.Stateful {
    
    public string CLASS_NAME = 'ETMUpdateOppOwner';
    public string ERROR_FUNCTIONALITY = 'ETM';
    public List<string> SERoles; // sales engineer role
    public Map<string,Custom_Error_Log__c> errorLogs = new Map<string,Custom_Error_Log__c>(); //SAL26-717
    private set<Id> failedAccIds = new set<id>();
    private boolean enableLogging,disable_ContactOwnerUpdate,disable_OppOwnerUpdate ;
    private string OwnerAssociation_SourceType = 'UserUpdate';
    private integer totalNumExec;
    public set<string> SEAdaptiveIds = new set<string>();
    public set<string> coOwnerAdaptiveIds = new set<string>();
    //SAL24-798
    public static ID oppRecTypeIdRenewOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
    public static ID oppRecTypeIdSalesOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
    //SF-7721 (ETM-181): Renewal Opp Owner changes
    public List<string> plsAERoles; // PLS AE roles //SAL24-735
    public List<string> plsSERoles; // PLS SE roles //SAL25-48
    public List<String> coOwnerRoles = new List<String>(); //PL26-38
    public Map<String, List<String>> roleToAccETMFieldListMap = new Map<String, List<String>>{
        'Cloud AE' => new List<String>{'PLS_NAS_ETM_Territory__c', 'PLS_NAS_ETM_Region__c', 'PLS_NAS_ETM_Area__c', 'PLS_NAS_Theatre__c'},
        'SaaS AE' => new List<String>{'PLS_SaaS_ETM_Territory__c', 'PLS_SaaS_ETM_Region__c', 'PLS_SaaS_ETM_Area__c', 'PLS_SaaS_Theatre__c'},
        'NCD AE' => new List<String>{'PLS_NCD_ETM_Territory__c', 'PLS_NCD_ETM_Region__c', 'PLS_NCD_ETM_Area__c', 'PLS_NCD_Theatre__c'}
    }; //PL26-38, PL26-19 //SAL26-138: NAS to Cloud
    public List<UserTerritory2Association> UTAList = new List<UserTerritory2Association>();
    /**
    * @description Constructor
    * @param failedAccIds
    * @param enableLogging
    * @param totalNumExec
    * @param disable_OppOwnerUpdate
    */ 
    
     public ETMUpdateOppOwner(set<Id> failedAccIds,boolean enableLogging,integer totalNumExec,boolean disable_OppOwnerUpdate){
        this.failedAccIds = failedAccIds;
        this.enableLogging = enableLogging; 
        this.totalNumExec = totalNumExec; 
        this.disable_OppOwnerUpdate=disable_OppOwnerUpdate;   
    }
    
    /**
    * @description Queries the elligible Opportunitied for TART and Sales Engg Update
    * @param BC
    * @return Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        string query;
        try{
            if(disable_OppOwnerUpdate){
                query ='select id from opportunity limit 0'; 
            }
            else{
                for(Territory_Owner_Assignment__c SETerr : [select id,AdaptiveId__c from Territory_Owner_Assignment__c where Functionality__c='Sales Engineer Assignment' limit 50000]){
                    SEAdaptiveIds.add(SETerr.AdaptiveId__c);
                } 
                
                for(Territory_Owner_Assignment__c coownerTerr : [select id,AdaptiveId__c from Territory_Owner_Assignment__c where Functionality__c='Opp Co-Owner Assignment' limit 50000]){
                    coOwnerAdaptiveIds.add(coownerTerr.AdaptiveId__c);
                } //PL26-19,PL26-38
                                
                String nonCoreAdaptiveIdCondition = '';
                boolean hasNonCoreAdaptiveIdCondition = false;
                if(!coOwnerAdaptiveIds.isEmpty()) {
                    // Remove duplicates by converting to Set (already a Set, but ensure uniqueness)
                    Set<String> uniqueAdaptiveIds = new Set<String>(coOwnerAdaptiveIds);
                    List<String> orConditions = new List<String>();
                    for(String adaptiveId : uniqueAdaptiveIds) {
                        if(String.isNotBlank(adaptiveId)) {
                            orConditions.add('Non_Core_Adaptive_Id__c LIKE \'%' + String.escapeSingleQuotes(adaptiveId) + '%\'');
                        }
                    }
                    if(!orConditions.isEmpty()) {
                        nonCoreAdaptiveIdCondition = '(' + String.join(orConditions, ' OR ') + ')';
                        hasNonCoreAdaptiveIdCondition = true;
                    }
                }
                //SF-7721 (ETM-181): Renewal Opp Owner changes
                //ETM-178: OVerride ETM Ownership
                //ETM-179: MSP Opportunity ETM Owner and TART enhancement
                /* Added below fields in Query as part of SAL26-105
                    AWS_GCP_Cloud_Alliance_BDM_Id__c, MSFT_OCI_Cloud_Alliance_BDM_Id__c ,AWS_GCP_Cloud_Alliance_BDM__c, MSFT_OCI_Cloud_Alliance_BDM__c
                    account.AWS_GCP_Cloud_Alliance_BDM__c, account.AWS_GCP_Cloud_Alliance_BDM__r.Name, MSP_End_User_Lookup__r.AWS_GCP_Cloud_Alliance_BDM__c, MSP_End_User_Lookup__r.AWS_GCP_Cloud_Alliance_BDM__r.Name,account.MSFT_OCI_Cloud_Alliance_BDM__c, account.MSFT_OCI_Cloud_Alliance_BDM__r.Name, MSP_End_User_Lookup__r.MSFT_OCI_Cloud_Alliance_BDM__c, MSP_End_User_Lookup__r.MSFT_OCI_Cloud_Alliance_BDM__r.Name
                //Removed Below fields as part of SAL26-101
                    Account_Alliance_BDM_Id__c,Opportunity_Alliance_BDM__c,account.Account_Alliance_BDM_Lookup__c, account.Account_Alliance_BDM_Lookup__r.Name, MSP_End_User_Lookup__r.Account_Alliance_BDM_Lookup__c, MSP_End_User_Lookup__r.Account_Alliance_BDM_Lookup__r.Name, 
                */
                String whereClause = ' FROM Opportunity WHERE AccountId NOT IN :failedAccIds AND IsClosed = false AND (';
                if(hasNonCoreAdaptiveIdCondition) {
                    whereClause += '((' + nonCoreAdaptiveIdCondition + ' OR In_Sync_With_Territory_PLS__c = false)) OR ';
                }
                whereClause += 'Override_ETM_Ownership__c = true OR In_Sync_With_Territory__c =false OR Opportunity_Split_ParentID__c!=null OR account.Adaptive_Territory_Id__c IN: SEAdaptiveIds OR MSP_End_User_Lookup__r.Adaptive_Territory_Id__c IN: SEAdaptiveIds OR ((Opportunity_Sub_Type__c like \'%MSP%\' OR Opportunity_Sub_Type__c = \'GC Offer\') AND MSP_End_User_Lookup__c != null AND RecordType.Name !=\'Renewal Opportunity\')) order by AccountId'; //SAL23-720 //SAL24-245 //SAL24-548 //SAL24-798 //SAL24-735

                query = 'SELECT Id,OwnerId, Territory2Id,Territory2Id__c,Account.OwnerId,IsClosed,account.Adaptive_Territory_Id__c,Disable_Auto_OwnerAssignment__c,Rubrik_Sales_Engineer__c,SE_Misaligned__c,account.ETM_Theatre__c,account.ETM_Area__c,account.ETM_Region__c,account.ETM_Territory__c,account.CDM_Area__c,account.CDM_Region__c,account.CDM_Territory__c,account.CDM_Theatre__c,Opportunity_Split_ParentID__c,account.RecordType.Name, account.RecordTypeId, MSP_End_User_Lookup__r.RecordTypeId, Override_ETM_Ownership__c, Opportunity_Sub_Type__c, RenewalOwner__c, account.Renewal_Owner__c, MSP_End_User_Lookup__r.Renewal_Owner__c,Opportunity_Override_Flags__c, ' + //SAL22-285 //SAL24-798//SAL26-1085:addOpportunity_Override_Flags__c
                        ' ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,CDM_Theatre__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c, Partner_Lookup__r.ETM_Theatre__c,Partner_Lookup__r.ETM_Area__c,Partner_Lookup__r.ETM_Region__c,Partner_Lookup__r.ETM_Territory__c,Override_ETM_Alliance_BDM__c, AWS_GCP_Cloud_Alliance_BDM_Id__c, MSFT_OCI_Cloud_Alliance_BDM_Id__c ,AWS_GCP_Cloud_Alliance_BDM__c, MSFT_OCI_Cloud_Alliance_BDM__c,' + //SF-18918/SAL22-517 //SAL23-391 //SAL23-443 //SAl24-28 //SAL24-472 //SAL25-99 //SAL25-583
                        ' Deal_Registration_Type__c, Sourcing_Partner__r.ETM_Theatre__c,Sourcing_Partner__r.ETM_Area__c,Sourcing_Partner__r.ETM_Region__c,Sourcing_Partner__r.ETM_Territory__c, Teaming_Partner__r.ETM_Theatre__c,Teaming_Partner__r.ETM_Area__c,Teaming_Partner__r.ETM_Region__c,Teaming_Partner__r.ETM_Territory__c, Update_CDM_TART__c, RecordTypeId, Owner.ManagerId, PLS_AE_ETM_Role_Name__c, Is_PLS_AE_Manager_Assigned__c, ' + //SAL24-528 //SAL24-798 //SAL24-735
                    'account.AWS_GCP_Cloud_Alliance_BDM__c, account.AWS_GCP_Cloud_Alliance_BDM__r.Name, MSP_End_User_Lookup__r.AWS_GCP_Cloud_Alliance_BDM__c, MSP_End_User_Lookup__r.AWS_GCP_Cloud_Alliance_BDM__r.Name,account.MSFT_OCI_Cloud_Alliance_BDM__c, account.MSFT_OCI_Cloud_Alliance_BDM__r.Name, MSP_End_User_Lookup__r.MSFT_OCI_Cloud_Alliance_BDM__c, MSP_End_User_Lookup__r.MSFT_OCI_Cloud_Alliance_BDM__r.Name, '+
                    ' MSP_End_User_Lookup__r.OwnerId, MSP_End_User_Lookup__r.Adaptive_Territory_Id__c, MSP_End_User_Lookup__r.ETM_Theatre__c, MSP_End_User_Lookup__r.ETM_Area__c, MSP_End_User_Lookup__r.ETM_Region__c, MSP_End_User_Lookup__r.ETM_Territory__c, MSP_End_User_Lookup__r.CDM_Theatre__c, MSP_End_User_Lookup__r.CDM_Area__c, MSP_End_User_Lookup__r.CDM_Region__c, MSP_End_User_Lookup__r.CDM_Territory__c, MSP_End_User_Lookup__r.Rubrik_Sales_Engineer__c, account.Rubrik_Sales_Engineer__c, MSP_End_User_Lookup__r.Is_SE_Existing_In_Territory__c, account.Is_SE_Existing_In_Territory__c, ' + //SF-8995 //SAL22-338
                    ' Account.Non_Core_Type_and_Adaptive_Id__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Theatre__c, Co_Owner__c, account.PLS_NAS_ETM_Territory__c,account.PLS_NAS_ETM_Region__c,account.PLS_NAS_ETM_Area__c,account.PLS_NAS_Theatre__c,account.PLS_SaaS_ETM_Territory__c,account.PLS_SaaS_ETM_Region__c,account.PLS_SaaS_ETM_Area__c,account.PLS_SaaS_Theatre__c,Non_Core_Adaptive_Id__c,Account.Non_Core_Adaptive_Territory_Ids__c,PLS_ETM_Overrides__c,Opportunity_Split_Parent__r.ETM_Theatre__c,Opportunity_Split_Parent__r.PLS_AE_ETM_Role_Name__c,Opportunity_Split_Parent__r.Co_Owner__c, Opportunity_Split_Parent__r.PLS_ETM_Overrides__c, Opportunity_Type__c, RenewalOwnerApproved__c, '+
                    ' Opp_PLS_NCD_ETM_Territory__c, Opp_PLS_NCD_ETM_Region__c, Opp_PLS_NCD_ETM_Area__c, Opp_PLS_NCD_ETM_Theatre__c, NCD_Co_Owner__c, Opp_PLS_SaaS_ETM_Territory__c, Opp_PLS_SaaS_ETM_Region__c, Opp_PLS_SaaS_ETM_Area__c, Opp_PLS_SaaS_ETM_Theatre__c, SaaS_Co_Owner__c, account.PLS_NCD_ETM_Territory__c, account.PLS_NCD_ETM_Region__c, account.PLS_NCD_ETM_Area__c, account.PLS_NCD_Theatre__c ' + //SAL26-1292
                    whereClause; 
                //SAL26-86: optimization
                List<Territory_Management_Setup__mdt> terrManagementSetMDTLst = [SELECT Id, Field_Value__c,Field_Type__c,Operator__c, DeveloperName 
                                                                                FROM Territory_Management_Setup__mdt 
                                                                                WHERE DeveloperName IN ('Opp_Co_Owner_Roles', 'Role_of_Sales_Engineer', 'Role_of_PLS_AE', 'Role_of_PLS_SE')];
                                
                for(Territory_Management_Setup__mdt terrMDT : terrManagementSetMDTLst) {
                    if(terrMDT.DeveloperName == 'Opp_Co_Owner_Roles') {
                        if(terrMDT.Field_Value__c != null) {
                            coOwnerRoles = terrMDT.Field_Value__c.contains(',') ? terrMDT.Field_Value__c.split(',') : new List<String>{terrMDT.Field_Value__c};
                        } else {
                            errorLogs.put('Co-Owner miss', new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = 'Missing Co-Owner user role data in Territory_Management_Setup__mdt.Opp_Co_Owner_Roles',Class__c = CLASS_NAME));
                }  
                    } else if(terrMDT.DeveloperName == 'Role_of_Sales_Engineer') {
                        if(terrMDT.Field_Value__c != null) {
                            SERoles = terrMDT.Field_Value__c.contains(',') ? terrMDT.Field_Value__c.split(',') : new List<String>{terrMDT.Field_Value__c};
                        } else {
                            errorLogs.put('SE miss', new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = 'Missing sales engineer user role data in Territory_Management_Setup__mdt.Role_of_Sales_Engineer',Class__c = CLASS_NAME));
                }
                    } else if(terrMDT.DeveloperName == 'Role_of_PLS_AE') {
                        if(terrMDT.Field_Value__c != null) {
                            plsAERoles = terrMDT.Field_Value__c.contains(',') ? terrMDT.Field_Value__c.split(',') : new List<String>{terrMDT.Field_Value__c};
                        } else {
                    errorLogs.put('PLS AE miss',new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = 'Missing PLS AE user role data in Territory_Management_Setup__mdt.Role_of_PLS_AE',Class__c = CLASS_NAME));
                }
                    } else if(terrMDT.DeveloperName == 'Role_of_PLS_SE') {
                        if(terrMDT.Field_Value__c != null) {
                            plsSERoles = terrMDT.Field_Value__c.contains(',') ? terrMDT.Field_Value__c.split(',') : new List<String>{terrMDT.Field_Value__c};
                        } else {
                    errorLogs.put('PLS SE miss',new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = 'Missing PLS SE user role data in Territory_Management_Setup__mdt.Role_of_PLS_SE',Class__c = CLASS_NAME));
                        }
                }
                }
                UTAList = [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2, Territory2.Territory2Type.DeveloperName, //SF-7721 (ETM-181): Renewal Opp Owner changes
                                                territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,  
                                                territory2.Channel_Territory__c,territory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c  
                                                , Territory2.ParentTerritory2.Adaptive_Territory_Id__c 
                                                from UserTerritory2Association 
                                                 where Territory2.Territory2Model.state='Active' 
                                                 AND User.IsActive=true 
                                                 AND  ( (Territory2.Adaptive_Territory_Id__c IN : SEAdaptiveIds ) 
                                                         OR (Territory2.Adaptive_Territory_Id__c IN :coOwnerAdaptiveIds AND RoleInTerritory2 IN :coOwnerRoles)) order by lastmodifieddate ];  
                
                //SF-7721 (ETM-181): Renewal Opp Owner changes
                //SAL24-798 - Remove existing logic
                /*List<Territory_Management_Setup__mdt> fielSalesMdtRAM = [select Field_Value__c,Field_Type__c,Operator__c from Territory_Management_Setup__mdt where DeveloperName='Role_of_Renewal_Account_Manager'];
                if(!fielSalesMdtRAM.isEmpty() && fielSalesMdtRAM[0].Field_Value__c!=null){
                    RAMRoles = fielSalesMdtRAM[0].Field_Value__c.split(';');
                }
                else{
                    errorLogs.put('RAM miss',new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = 'Missing Renewals Representative user role data in Territory_Management_Setup__mdt.Role_of_Renewal_Account_Manager',Class__c = CLASS_NAME));
                }*/
            }   
        }catch(exception e){
            insert LogError.CreateGenericErrorLog(CLASS_NAME,e,ERROR_FUNCTIONALITY);
        }              
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description Logic to update TART and Sales Engg for split,revenue and renewal opp
    * @param BC
    * @param OppList
    */
    public void execute(Database.BatchableContext BC,List<Opportunity> OppList){
        OpportunityObjectTriggerHandler.skipExecutionHandler = true;
        Integer i= 0; 
        set<string> allAdaptiveId = new set<string>();
        Map<Id,List<Id>> OppOwner_Ids = new Map<Id,List<Id>>();
        Map<Id,string> splitoppId_TART = new Map<Id,string>();
        set<string> SplitOppAdaptiveId = new set<string>();
        map<string,Id> AdaptiveSE = new map<string,Id>();
        list<string> TART = new list<string>();
        Map<string,Id> adaptiveId_TerrId  = new map<string,Id>();

        //SF-8995
        Map<String,String> terrToRegionSEAdaptiveMap = new Map<String,String>();

        //SF-12712
        Set<Id> ownerChangeOppIds = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Map<Id, OpportunityTeamMember> deleteOTMMap = new Map<Id, OpportunityTeamMember>();//SAL26-86:changed list to map 
        List<OpportunityTeamMember> insertOTM = new List<OpportunityTeamMember>();
        //SF-18918/SAL22-517
        List<Opportunity> updateOppList = new List<Opportunity>(); //Opportunities to be updated
        Map<Id, Opportunity> oppListMap = new Map<Id, Opportunity>(OppList); //SPH-2713
        /*Removed Account_Alliance_BDM_Id__c,Opportunity_Alliance_BDM__c from below query as part of SAL26-101
        And added AWS_GCP_Cloud_Alliance_BDM_Id__c,MSFT_OCI_Cloud_Alliance_BDM_Id__c, AWS_GCP_Cloud_Alliance_BDM__c, MSFT_OCI_Cloud_Alliance_BDM__c new fields in below query*/ 
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>([select Id,ownerId,RenewalOwner__c,Rubrik_Sales_Engineer__c,Territory2Id,AWS_GCP_Cloud_Alliance_BDM_Id__c,MSFT_OCI_Cloud_Alliance_BDM_Id__c, AWS_GCP_Cloud_Alliance_BDM__c, MSFT_OCI_Cloud_Alliance_BDM__c,  //SAL23-443 //SAL24-28 //SAL24-472 
                                                                   ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,PLS_ETM_Overrides__c,
                                                                   CDM_Theatre__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c, Update_CDM_TART__c, Is_PLS_AE_Manager_Assigned__c, //SAL24-528 //SAL24-735
                                                                   Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Theatre__c, Co_Owner__c, Non_Core_Adaptive_Id__c,//PL26-123
                                                                   NCD_Co_Owner__c, Opp_PLS_NCD_ETM_Theatre__c, Opp_PLS_NCD_ETM_Area__c, Opp_PLS_NCD_ETM_Region__c, Opp_PLS_NCD_ETM_Territory__c, //SAL26-1292
                                                                   SaaS_Co_Owner__c, Opp_PLS_SaaS_ETM_Theatre__c, Opp_PLS_SaaS_ETM_Area__c, Opp_PLS_SaaS_ETM_Region__c, Opp_PLS_SaaS_ETM_Territory__c //SAL26-1292
                                                                   from Opportunity where Id IN :oppListMap.keySet() ]); //Store OppList with old values
        //SAL23-720 //SAL24-798n799
        String unassignedRenewalOwnerId = [select DeveloperName,Field_Value__c from Territory_Management_Setup__mdt where DeveloperName = 'Unassigned_Renewal_OwnerId' limit 1]?.Field_Value__c;
        Set<Id> accRenewalOwnerIds = new Set<Id>(); 
        Map<ID, User> userMap = new Map<ID, User>();
        //SAL24-735
        Map<String,Id> adaptiveIdRolePLSAEMap = new Map<String,Id>();
        Set<Id> plsAEOwnerMgrIds = new Set<Id>();
        Id errOppId;
        Map<String,Id> adaptiveIdRolePLSSEMap = new Map<String,Id>(); //SAL25-48
            
        try{
            //if opp does not have non core id,get them from account to get UTA
            for(Opportunity opp : OppList){
                if(opp.RecordTypeId == oppRecTypeIdSalesOpp && String.isNotBlank(opp.PLS_AE_ETM_Role_Name__c)){
                    Set<String> accNonCoreAdaptiveIdSet = new Set<String>(String.isNotBlank(opp.Account.Non_Core_Adaptive_Territory_Ids__c) && opp.Account.Non_Core_Adaptive_Territory_Ids__c.contains(',') ?
                                                                          opp.Account.Non_Core_Adaptive_Territory_Ids__c.split(',') : new List<String>{opp.Account.Non_Core_Adaptive_Territory_Ids__c});
                    
                    coOwnerAdaptiveIds.addAll(accNonCoreAdaptiveIdSet);
                }
            }            
            
            for(Opportunity Opp : OppList) {
                errOppId = Opp.Id; //SAL24-798 - Optimize
                //ETM-179: MSP Opportunity ETM Owner and TART enhancement
                Account OppAccountRec = (Opp.Opportunity_Sub_Type__c != null && Opp.RecordTypeId != oppRecTypeIdRenewOpp && (Opp.Opportunity_Sub_Type__c.contains('MSP') || Opp.Opportunity_Sub_Type__c == 'GC Offer') && Opp.MSP_End_User_Lookup__c != null) ? Opp.MSP_End_User_Lookup__r : Opp.Account; //SAL24-548 //SAL24-798
                if(Opp.Opportunity_Split_ParentID__c == null && !Opp.Override_ETM_Ownership__c){
                    Id oppOwnerId = OppAccountRec.OwnerId;
                    if(Opp.OwnerId != oppOwnerId && Opp.Disable_Auto_OwnerAssignment__c==false && Opp.Override_ETM_Ownership__c==false && Opp.RecordTypeId != oppRecTypeIdRenewOpp){ //SF-7721 (ETM-181): Renewal Opp Owner changes //SAL23-720 //SAL24-798
                        Opp.OwnerId = oppOwnerId; //SAL23-720
                        //SF-12712
                        ownerChangeOppIds.add(Opp.Id);
                    }
                    //SF-10655
                    if(!Opp.Override_ETM_Ownership__c){
                        //ETM-179: MSP Opportunity ETM Owner and TART enhancement
                        Opp.ETM_Theatre__c = OppAccountRec.ETM_Theatre__c;
                        Opp.ETM_Area__c = OppAccountRec.ETM_Area__c;
                        Opp.ETM_Region__c = OppAccountRec.ETM_Region__c;
                        Opp.ETM_Territory__c = OppAccountRec.ETM_Territory__c;
                        //SAL23-391 //SAL24-528 
                    } //End SF-10655
                }  
                else if(opp.Opportunity_Split_ParentID__c != null || opp.Override_ETM_Ownership__c){  // Split opportunity //SAL24-735
                    if(OppOwner_Ids.containskey(Opp.OwnerId))
                        OppOwner_Ids.get(Opp.OwnerId).add(Opp.Id);
                    else    
                        OppOwner_Ids.put(Opp.OwnerId,new List<Id>{Opp.Id}); 
                    //SAL24-245
                }
                //SAL24-472 //SAL25-99
                if(!Opp.Override_ETM_Alliance_BDM__c){
                    // Start SAL26-105
                    Opp.AWS_GCP_Cloud_Alliance_BDM__c = OppAccountRec?.AWS_GCP_Cloud_Alliance_BDM__r?.Name; 
                    Opp.MSFT_OCI_Cloud_Alliance_BDM__c = OppAccountRec?.MSFT_OCI_Cloud_Alliance_BDM__r?.Name; 
                    Opp.AWS_GCP_Cloud_Alliance_BDM_Id__c = OppAccountRec?.AWS_GCP_Cloud_Alliance_BDM__c; 
                    Opp.MSFT_OCI_Cloud_Alliance_BDM_Id__c = OppAccountRec?.MSFT_OCI_Cloud_Alliance_BDM__c; 
                    // End SAL26-105
                }
                //SAL26-1272 : set RenewalOwner__c on opportunity same as Account Owner
                //exclude opps where Renewal Owner is set manually by user or RenewalOwnerApproved__c is true or split and Debooking opportunity
                if(!opp.Override_ETM_Ownership__c && !opp.RenewalOwnerApproved__c && opp.Opportunity_Type__c != 'Debooking' && opp.Opportunity_Split_ParentID__c == null && opp.RenewalOwner__c != oppAccountRec.OwnerId){
                    opp.RenewalOwner__c = oppAccountRec.OwnerId;
                }
                
                //ETM-179: MSP Opportunity ETM Owner and TART enhancement
                allAdaptiveId.add(OppAccountRec.Adaptive_Territory_Id__c);   
                //SAL24-798 //SAL24-799
                if(Opp.RecordTypeId == oppRecTypeIdRenewOpp && Opp.Opportunity_Sub_Type__c != null && Opp.Opportunity_Sub_Type__c.contains('Renewal')){ accRenewalOwnerIds.add(OppAccountRec.Renewal_Owner__c);}
            }
            //SF-7721 (ETM-181): Renewal Opp Owner changes
            for(Territory2 Terr:[Select id,Adaptive_Territory_Id__c, ParentTerritory2Id, ParentTerritory2.ParentTerritory2Id, ParentTerritory2.ParentTerritory2.ParentTerritory2Id from territory2 
                                 where Adaptive_Territory_Id__c IN: allAdaptiveId and Territory2Model.state='Active'])
            {
                adaptiveId_TerrId.put(Terr.Adaptive_Territory_Id__c,Terr.Id);
            }
            Map<String, UserTerritory2Association> adaptiveIdToUserTerrMap = new Map<String, UserTerritory2Association>(); //PL26-38/SAL26-86 - Optimization moved to existing SOQL
			List<UserTerritory2Association> innerUTAList = new List<UserTerritory2Association>();
            innerUTAList = [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2, Territory2.Territory2Type.DeveloperName, //SF-7721 (ETM-181): Renewal Opp Owner changes
                                                territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,  
                                                territory2.Channel_Territory__c,territory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c  
                                                , Territory2.ParentTerritory2.Adaptive_Territory_Id__c //SF-8995
                                                from UserTerritory2Association 
                                                 where Territory2.Territory2Model.state='Active' 
                                                 AND User.IsActive=true 
                                                 AND  ((Territory2.Adaptive_Territory_Id__c IN: allAdaptiveId AND (RoleInTerritory2 IN : SERoles OR RoleInTerritory2 IN : plsAERoles OR RoleInTerritory2 IN : plsSERoles)) //sales engg //SAL24-735 //SAL25-48
                                                       OR ( UserId IN : OppOwner_Ids.keyset() AND RoleInTerritory2 ='Account Executive') 
                                                       OR (Territory2.Adaptive_Territory_Id__c IN : SEAdaptiveIds ) // Split opp //SAL24-798
                                                       OR (Territory2.Adaptive_Territory_Id__c IN :coOwnerAdaptiveIds AND RoleInTerritory2 IN :coOwnerRoles)) //SAL26-86:optimization
                                                       //SAL24-798 - Remove existing logic
                                                       //OR (Territory2.Id IN :RAMParentTerrIds AND RoleInTerritory2 IN : RAMRoles)) //SF-7721 (ETM-181): Renewal Opp Owner changes
                                                 order by lastmodifieddate
                                                ];
            innerUTAList.addAll(UTAList);
            for(UserTerritory2Association UTA : innerUTAList){  // UTA assigned to T4(territory) level   
                                                    //SF-7721 (ETM-181): Renewal Opp Owner changes
                                                    if(UTA.Territory2.Territory2Type.DeveloperName == 'Territory'){
                                                        if(coOwnerRoles.contains(UTA.RoleInTerritory2) && coOwnerAdaptiveIds.contains(UTA.Territory2.Adaptive_Territory_Id__c)){
                                                            adaptiveIdToUserTerrMap.put(UTA.Territory2.Adaptive_Territory_Id__c, UTA);
                                                        } //SAL26-86:optimization
                                                        //SF-8995
                                                        if(OppOwner_Ids.containsKey(UTA.UserId) && UTA.RoleInTerritory2=='Account Executive'){  // Collect TART of split opp
                                                            for(Id oppId : OppOwner_Ids.get(UTA.UserId)){ 
                                                                splitoppId_TART.put(oppId ,UTA.Territory2.Adaptive_Territory_Id__c+'_'+UTA.territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                                                                    +UTA.territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                                                                    +UTA.territory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                                                                    +UTA.Territory2.Internal_Territory_Name__c+'_' 
                                                                                    +UTA.territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c+'_'
                                                                                    +UTA.territory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c+'_'
                                                                                    +UTA.territory2.ParentTerritory2.Channel_Territory__c+'_'
                                                                                    +UTA.Territory2.Channel_Territory__c
                                               );

                                                                adaptiveId_TerrId.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.Territory2Id);
                                                                SplitOppAdaptiveId.add(UTA.Territory2.Adaptive_Territory_Id__c);     
                                                                //SF-8995
                                                                SplitOppAdaptiveId.add(UTA.Territory2.ParentTerritory2.Adaptive_Territory_Id__c);
                                                                terrToRegionSEAdaptiveMap.put(UTA.Territory2.Adaptive_Territory_Id__c, UTA.Territory2.ParentTerritory2.Adaptive_Territory_Id__c);  
                                                            }
                                                        }
                                                        //SAL24-735
                                                        if(plsAERoles.contains(UTA.RoleInTerritory2)){
                                                            //Key:AdaptiveIdRole Value: UserId
                                                            adaptiveIdRolePLSAEMap.put(UTA.Territory2.Adaptive_Territory_Id__c+UTA.RoleInTerritory2,UTA.UserId);
                                                        }
                                                        //SAL25-48
                                                        if(plsSERoles.contains(UTA.RoleInTerritory2)){
                                                            //Key:AdaptiveIdRole Value: UserId
                                                            adaptiveIdRolePLSSEMap.put(UTA.Territory2.Adaptive_Territory_Id__c+UTA.RoleInTerritory2,UTA.UserId);
                                                        }
                                                    }
                                                }
            // Query for Split opp 
            for(UserTerritory2Association UTA : [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c  from UserTerritory2Association 
                                                 where Territory2.Territory2Model.state='Active' 
                                                 AND User.IsActive=true 
                                                 AND Territory2.Adaptive_Territory_Id__c IN: SplitOppAdaptiveId 
                                                 AND RoleInTerritory2 IN : SERoles
                                                 AND Territory2.Adaptive_Territory_Id__c NOT IN :AdaptiveSE.keySet()
                                                 order by lastmodifieddate
                                                ]){  // UTA assigned to T4(territory) level   
                                                    if(SERoles.contains(UTA.RoleInTerritory2) && AdaptiveSE.containskey(UTA.Territory2.Adaptive_Territory_Id__c)==false){
                                                        AdaptiveSE.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.UserId);
                                                    }
                                                } 
            SplitOppAdaptiveId.clear();   
            //SAL24-798n799 //SAL24-735
            if(!accRenewalOwnerIds.isEmpty() || !plsAEOwnerMgrIds.isEmpty()){
                userMap = new Map<ID, User>([Select Id,isActive from User where ID IN:accRenewalOwnerIds or ID IN:plsAEOwnerMgrIds]);
            }
            for(Opportunity Opp : OppList){
                Opportunity oldOpp = oldOppMap.get(opp.Id); //SAL35-137
                
                // PL26-19,PL26-38
               if(String.isNotBlank(Opp.Account.Non_Core_Type_and_Adaptive_Id__c) && ( Test.isRunningTest() || (!coOwnerAdaptiveIds.isEmpty() && Opp.RecordTypeId == oppRecTypeIdSalesOpp))){
                   
                   if(Opp.Opportunity_Split_ParentID__c == null) {
                        updateCoOwnerAndTartFields(adaptiveIdToUserTerrMap, Opp);
                   } else if(Opp.Opportunity_Split_Parent__c != null){
                       if(opp.ETM_Theatre__c != Opp.Opportunity_Split_Parent__r.ETM_Theatre__c){
                           if(opp.PLS_ETM_Overrides__c == null){
                               opp.Co_Owner__c = opp.SaaS_Co_Owner__c = opp.NCD_Co_Owner__c = null;
                           }else{
                               if(!opp.PLS_ETM_Overrides__c.contains('Cloud ETM Override')) opp.Co_Owner__c = null;
                               if(!opp.PLS_ETM_Overrides__c.contains('SaaS ETM Override')) opp.SaaS_Co_Owner__c = null;
                               if(!opp.PLS_ETM_Overrides__c.contains('NCD ETM Override')) opp.NCD_Co_Owner__c = null;    
                           } 
                       } else if(Opp.ETM_Theatre__c == Opp.Opportunity_Split_Parent__r.ETM_Theatre__c) {
                           updateCoOwnerAndTartFields(adaptiveIdToUserTerrMap, Opp);
                       }
                   }                   
               }
                
                //ETM-179: MSP Opportunity ETM Owner and TART enhancement
                Account OppAccountRec = (Opp.Opportunity_Sub_Type__c != null && Opp.RecordTypeId != oppRecTypeIdRenewOpp && (Opp.Opportunity_Sub_Type__c.contains('MSP') || Opp.Opportunity_Sub_Type__c == 'GC Offer') && Opp.MSP_End_User_Lookup__c != null) ? Opp.MSP_End_User_Lookup__r : Opp.Account; //SAL24-548 //SAL24-798
                TART.clear();
                if(opp.Opportunity_Split_ParentID__c == null && (!opp.Override_ETM_Ownership__c)){ //SAL24-245 //SAL24-735 //SAL25-166
 if(!Opp.Override_ETM_Ownership__c){ //SAL25-166
                        if(OppAccountRec!=null && OppAccountRec.Adaptive_Territory_Id__c!=null && adaptiveId_TerrId.containskey(OppAccountRec.Adaptive_Territory_Id__c)){
                            opp.Territory2Id = opp.Territory2Id__c = adaptiveId_TerrId.get(OppAccountRec.Adaptive_Territory_Id__c);
                        }
                        else{
                            opp.Territory2Id = opp.Territory2Id__c = null ;
                        }
                    }//End SF-10655
                    if(opp.SE_Misaligned__c==false){
                        opp.Rubrik_Sales_Engineer__c = !Opp.Override_ETM_Ownership__c  ? OppAccountRec.Rubrik_Sales_Engineer__c : !Label.Account_RecordType_Partner_Distributor.contains(OppAccountRec.RecordTypeId) ? OppAccountRec.Rubrik_Sales_Engineer__c : opp.Rubrik_Sales_Engineer__c; //SAL24-735
                    }
                    //SAL24-798 //SAL24-799
                    if(Opp.RecordTypeId == oppRecTypeIdRenewOpp && Opp.Opportunity_Sub_Type__c != null && Opp.Opportunity_Sub_Type__c.contains('Renewal')){
                        Id acctRenewalOwnerId = (OppAccountRec!=null && OppAccountRec.Renewal_Owner__c !=null) ? OppAccountRec.Renewal_Owner__c : null;
                        Boolean isAcctRenewalOwnerValid = acctRenewalOwnerId != null && userMap!=null && userMap.containsKey(acctRenewalOwnerId) && userMap.get(acctRenewalOwnerId).IsActive ? true : false;
                        Id RenewalOppOwnerId = isAcctRenewalOwnerValid ? acctRenewalOwnerId : unassignedRenewalOwnerId;
                        if(Opp.OwnerId != RenewalOppOwnerId && !Opp.Disable_Auto_OwnerAssignment__c && !Opp.Override_ETM_Ownership__c){
                            Opp.OwnerId = RenewalOppOwnerId;
                            ownerChangeOppIds.add(Opp.Id);
                        }
                    }
                        string accAdaptiveId = OppAccountRec.Adaptive_Territory_Id__c;
                        }
                else if(opp.Opportunity_Split_ParentID__c != null){
                    if(Opp.RecordTypeId != oppRecTypeIdRenewOpp){
                        if(splitoppId_TART.containsKey(Opp.id)){
                            TART = splitoppId_TART.get(Opp.id).replaceall('null',' ').split('_');
                            if(TART[0]!=null && adaptiveId_TerrId.containskey(TART[0])
                            && (opp.Territory2Id__c !=adaptiveId_TerrId.get(TART[0]) 
                                || opp.Territory2Id !=adaptiveId_TerrId.get(TART[0]))
                            ){
                                Opp.Territory2Id = opp.Territory2Id__c = adaptiveId_TerrId.get(TART[0]) ;
                            }
                            Opp.ETM_Theatre__c = TART[1] ;
                            Opp.ETM_Area__c = TART[2] ;
                            Opp.ETM_Region__c = TART[3] ;
                            Opp.ETM_Territory__c = TART[4] ;
                            if(opp.SE_Misaligned__c==false){
                                String parentSEAdaptiveId = terrToRegionSEAdaptiveMap.get(TART[0]);
                                opp.Rubrik_Sales_Engineer__c = TART[0]!=null && AdaptiveSE.get(TART[0]) != null ? 
                                                                    AdaptiveSE.get(TART[0]) : 
                                                                    TART[0]!=null && parentSEAdaptiveId != null && AdaptiveSE.get(parentSEAdaptiveId) != null ? AdaptiveSE.get(parentSEAdaptiveId) : null ;
                            }
                        }
                        else{
                            opp.Rubrik_Sales_Engineer__c =Opp.Territory2Id =opp.Territory2Id__c = Opp.ETM_Theatre__c = Opp.ETM_Area__c = Opp.ETM_Region__c = Opp.ETM_Territory__c = null; // split opp owner doesnt belong to any territory
                        }
                    }
                }
                
                //SAL26-1085
                Boolean cdmETMOverride = false;
                if(String.isNotBlank(Opp.Opportunity_Override_Flags__c)){
					List<String> selectedFlags = Opp.Opportunity_Override_Flags__c.split(';');
                    if(selectedFlags.contains('CDM ETM Override')){
                        cdmETMOverride = true;
                    }
                }

                if(!cdmETMOverride){ //SAL26-1085
                    //SAL24-528
                    String cdmTARTFrom = Opp.Deal_Registration_Type__c != 'Rubrik Sourced' && Opp.Sourcing_Partner__c != null ? 
                        'Sourcing_Partner' : 
                    Opp.Deal_Registration_Type__c == 'Rubrik Sourced' && Opp.Teaming_Partner__c != null ?
                        'Teaming_Partner' : 
                    Opp.Partner_Lookup__c != null ? 'Partner_Lookup' : 'Partner_Lookup';
                    Opp.CDM_Theatre__c = cdmTARTFrom == 'Sourcing_Partner' ? Opp.Sourcing_Partner__r?.ETM_Theatre__c : cdmTARTFrom == 'Teaming_Partner' ?  Opp.Teaming_Partner__r?.ETM_Theatre__c : Opp.Partner_Lookup__r?.ETM_Theatre__c;
                    Opp.CDM_Area__c = cdmTARTFrom == 'Sourcing_Partner' ? Opp.Sourcing_Partner__r?.ETM_Area__c : cdmTARTFrom == 'Teaming_Partner' ?  Opp.Teaming_Partner__r?.ETM_Area__c : Opp.Partner_Lookup__r?.ETM_Area__c;
                    Opp.CDM_Region__c = cdmTARTFrom == 'Sourcing_Partner' ? Opp.Sourcing_Partner__r?.ETM_Region__c : cdmTARTFrom == 'Teaming_Partner' ?  Opp.Teaming_Partner__r?.ETM_Region__c : Opp.Partner_Lookup__r?.ETM_Region__c;
                    Opp.CDM_Territory__c = cdmTARTFrom == 'Sourcing_Partner' ? Opp.Sourcing_Partner__r?.ETM_Territory__c : cdmTARTFrom == 'Teaming_Partner' ?  Opp.Teaming_Partner__r?.ETM_Territory__c : Opp.Partner_Lookup__r?.ETM_Territory__c;
                    Opp.Update_CDM_TART__c = false;
                }

                if(Test.isRunningTest() || opp.ownerId != oldOpp.ownerId || opp.RenewalOwner__c != oldOpp.RenewalOwner__c || opp.Rubrik_Sales_Engineer__c != oldOpp.Rubrik_Sales_Engineer__c || opp.Territory2Id != oldOpp.Territory2Id ||
                    opp.ETM_Theatre__c != oldOpp.ETM_Theatre__c || opp.ETM_Area__c != oldOpp.ETM_Area__c || opp.ETM_Region__c != oldOpp.ETM_Region__c || opp.ETM_Territory__c != oldOpp.ETM_Territory__c ||
                    opp.CDM_Theatre__c != oldOpp.CDM_Theatre__c || opp.CDM_Area__c != oldOpp.CDM_Area__c || opp.CDM_Region__c != oldOpp.CDM_Region__c || opp.CDM_Territory__c != oldOpp.CDM_Territory__c || 
                    opp.Update_CDM_TART__c != oldOpp.Update_CDM_TART__c ||opp.Is_PLS_AE_Manager_Assigned__c != oldOpp.Is_PLS_AE_Manager_Assigned__c ||
                    opp.Opp_PLS_ETM_Territory__c != oldOpp.Opp_PLS_ETM_Territory__c || opp.Opp_PLS_ETM_Region__c != oldOpp.Opp_PLS_ETM_Region__c || opp.Opp_PLS_ETM_Area__c != oldOpp.Opp_PLS_ETM_Area__c || opp.Opp_PLS_ETM_Theatre__c != oldOpp.Opp_PLS_ETM_Theatre__c || opp.Co_Owner__c != oldOpp.Co_Owner__c || opp.Non_Core_Adaptive_Id__c != oldOpp.Non_Core_Adaptive_Id__c || //PL26-123
                    opp.Opp_PLS_SaaS_ETM_Territory__c != oldOpp.Opp_PLS_SaaS_ETM_Territory__c || opp.Opp_PLS_SaaS_ETM_Region__c != oldOpp.Opp_PLS_SaaS_ETM_Region__c || opp.Opp_PLS_SaaS_ETM_Area__c != oldOpp.Opp_PLS_SaaS_ETM_Area__c || opp.Opp_PLS_SaaS_ETM_Theatre__c != oldOpp.Opp_PLS_SaaS_ETM_Theatre__c || opp.SaaS_Co_Owner__c != oldOpp.SaaS_Co_Owner__c || //SAL26-1292
                    opp.Opp_PLS_NCD_ETM_Territory__c != oldOpp.Opp_PLS_NCD_ETM_Territory__c || opp.Opp_PLS_NCD_ETM_Region__c != oldOpp.Opp_PLS_NCD_ETM_Region__c || opp.Opp_PLS_NCD_ETM_Area__c != oldOpp.Opp_PLS_NCD_ETM_Area__c || opp.Opp_PLS_NCD_ETM_Theatre__c != oldOpp.Opp_PLS_NCD_ETM_Theatre__c || opp.NCD_Co_Owner__c != oldOpp.NCD_Co_Owner__c || //SAL26-1292
                    opp.AWS_GCP_Cloud_Alliance_BDM_Id__c != oldOpp.AWS_GCP_Cloud_Alliance_BDM_Id__c || opp.AWS_GCP_Cloud_Alliance_BDM__c != oldOpp.AWS_GCP_Cloud_Alliance_BDM__c ||
                    opp.MSFT_OCI_Cloud_Alliance_BDM_Id__c != oldOpp.MSFT_OCI_Cloud_Alliance_BDM_Id__c || opp.MSFT_OCI_Cloud_Alliance_BDM__c != oldOpp.MSFT_OCI_Cloud_Alliance_BDM__c
                    ){ //SAL23-443 //SAL24-28 //SAL24-472 //SAL24-528 //SAL24-735
                        updateOppList.add(opp);
                } //End
            }
            //SF-12712
            if(!ownerChangeOppIds.isEmpty()){
                oppMap = new Map<Id, Opportunity>([select Id, (Select Id, OpportunityId, UserId, OpportunityAccessLevel, TeamMemberRole from OpportunityTeamMembers) from Opportunity where Id IN :ownerChangeOppIds ]);
                for(Opportunity opp :oppMap.values()){
                    deleteOTMMap.putAll(opp.OpportunityTeamMembers);
                }
            } //End

            //SF-18918/SAL22-517
            if(!updateOppList.isEmpty()) { 
                for (Database.SaveResult sr : database.update(updateOppList, false)) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            if(SEAdaptiveIds.contains(updateOppList[i].account.Adaptive_Territory_Id__c)){
                                SEAdaptiveIds.remove(updateOppList[i].account.Adaptive_Territory_Id__c);
                            }
                            if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage())){ 
                                if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                                    errorLogs.get(err.getMessage()).FailedRecords__c += ','+updateOppList[i].Id;              
                            }
                            else{
                                errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = (err.getMessage()+':'+err.getFields()),Class__c = CLASS_NAME,FailedRecords__c=updateOppList[i].Id));
                            }
                        }
                        //SF-12712
                        if(oppMap.containsKey(updateOppList[i].Id)) { insertOTM.addAll(oppMap.get(updateOppList[i].Id).OpportunityTeamMembers);}
                    } 
                    i++;
                }
                //SF-12712
                for(OpportunityTeamMember otm :insertOTM){
                    otm.Id = null;
                }
                if(!insertOTM.isEmpty()){ database.insert(insertOTM,false); } //End
            }
            //SAL25-137
            Map<Id, Opportunity> plsOppMap = new Map<Id, Opportunity>();
            if(!deleteOTMMap.isEmpty()){//sAL26-86
                List<Database.DeleteResult> drList = Database.delete(deleteOTMMap.values(),false);
                LogError.deleteDMLErrorLog((List<SObject>)deleteOTMMap.values(), drList, CLASS_NAME,'ETM - Delete PLS OpportunityTeamMember');
            }
        }catch(exception err){
            if(errorLogs.isEmpty() || !errorLogs.containskey(err.getMessage())){
                errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = err.getMessage(),Class__c = CLASS_NAME,FailedRecords__c=errOppId, ErrorTrace__c= String.format('{0}\n{1}\n\n\n\n',new List<String>{'Exception type :'+err.getTypeName(),'Trace : '+err.getStackTraceString()})));
            }
        }
    }
    
    /**
    * @description creates error logs    
                   Deletes processed terrId from reprocessing Territory table
                   Triggers Owner assignment batch if found any unprocessed records in reprocessing Territory table 
    * @param BC
    */
    public void finish(Database.BatchableContext BC) {
        set<id> unprocessedLeafIds = new set<Id>() ;  //Stores leaf terrr Id that doesnt have accounts and are part of active territory model
        //Insert error logs  
        if(!errorLogs.values().isEmpty() && enableLogging){
            database.insert(errorLogs.values(),false);
        }
        for(Territory_Owner_Assignment__c TOW :[select id,LeafTerritoryId__c from Territory_Owner_Assignment__c where Functionality__c IN ('Owner Assignment') limit 50000]){  //where Functionality__c='Owner Assignment' //SAL23-443 //SAL24-28 //SAL24-14
            unprocessedLeafIds.add(TOW.LeafTerritoryId__c);  
        }
    
        for(Territory2 leaftrr: [select id,Territory2Model.State,(select id from ObjectTerritory2Associations limit 1) from Territory2 where Id IN: unprocessedLeafIds] ){
            if(leaftrr.ObjectTerritory2Associations.isEmpty() || leaftrr.Territory2Model.State !='Active'){
                unprocessedLeafIds.remove(leaftrr.id);
            } 
        }
        delete [select id from Territory_Owner_Assignment__c where (LeafTerritoryId__c NOT IN : unprocessedLeafIds and Functionality__c IN ('Owner Assignment', 'Opp Co-Owner Assignment')) ]; //SAL23-443 //SAL24-28 //SAL24-14 //SAL24-472//PL26-38
        
        if(unprocessedLeafIds.size()>0 && totalNumExec<3 && !boolean.valueof(System.Label.ETM_Owner_Assignment)){
            //SAL24-735
            Integer accBatchSize = 50;
            List<Territory_Management_Setup__mdt> fielSalesMdtBatchSize = [select Field_Value__c,Field_Type__c,Operator__c from Territory_Management_Setup__mdt where DeveloperName='ETM_Account_Batch_Size'];
            if(!fielSalesMdtBatchSize.isEmpty() && fielSalesMdtBatchSize[0].Field_Value__c!=null){
                accBatchSize = Integer.valueOf(fielSalesMdtBatchSize[0].Field_Value__c);
            }
            Database.executeBatch(new ETMTerritoryOwnerAssociationBatch(OwnerAssociation_SourceType,unprocessedLeafIds,totalNumExec),accBatchSize); //SAL24-735
        }
    }
   
    //SAL26-1292 AND SAL26-1340 - START

    /* ============================================================
     * ROLE CONFIG
     * ============================================================ */
    private static final Map<String, Map<String, Object>> ROLE_CONFIG =
        new Map<String, Map<String, Object>>{
            'Cloud AE' => new Map<String, Object>{
                'coOwnerField' => 'Co_Owner__c',
                'typePrefix'   => 'PLS Cloud',
                'overrideKey'  => 'CLOUD ETM Override',
                'tartFields'   => new List<String>{'Opp_PLS_ETM_Territory__c', 'Opp_PLS_ETM_Region__c', 'Opp_PLS_ETM_Area__c', 'Opp_PLS_ETM_Theatre__c'
                }
            },
            'NCD AE' => new Map<String, Object>{
                'coOwnerField' => 'NCD_Co_Owner__c',
                'typePrefix'   => 'PLS NCD',
                'overrideKey'  => 'NCD ETM Override',
                'tartFields'   => new List<String>{'Opp_PLS_NCD_ETM_Territory__c', 'Opp_PLS_NCD_ETM_Region__c', 'Opp_PLS_NCD_ETM_Area__c', 'Opp_PLS_NCD_ETM_Theatre__c'
                }
            },
            'SaaS AE' => new Map<String, Object>{
                'coOwnerField' => 'SaaS_Co_Owner__c',
                'typePrefix'   => 'PLS SaaS',
                'overrideKey'  => 'SaaS ETM Override',
                'tartFields'   => new List<String>{'Opp_PLS_SaaS_ETM_Territory__c', 'Opp_PLS_SaaS_ETM_Region__c', 'Opp_PLS_SaaS_ETM_Area__c', 'Opp_PLS_SaaS_ETM_Theatre__c'
                }
            }
        };
    /* ------------------------------------------------------------
     * ROLE → AccountField → OpportunityField
     * ------------------------------------------------------------ */
    private static final Map<String, Map<String, String>> ROLE_FIELD_MAPPING =
        new Map<String, Map<String, String>>{
            'Cloud AE' => new Map<String, String>{
                'PLS_NAS_ETM_Territory__c' => 'Opp_PLS_ETM_Territory__c',
                'PLS_NAS_ETM_Region__c'    => 'Opp_PLS_ETM_Region__c',
                'PLS_NAS_ETM_Area__c'      => 'Opp_PLS_ETM_Area__c',
                'PLS_NAS_Theatre__c'       => 'Opp_PLS_ETM_Theatre__c'
            },

            'NCD AE' => new Map<String, String>{
                'PLS_NCD_ETM_Territory__c' => 'Opp_PLS_NCD_ETM_Territory__c',
                'PLS_NCD_ETM_Region__c'    => 'Opp_PLS_NCD_ETM_Region__c',
                'PLS_NCD_ETM_Area__c'      => 'Opp_PLS_NCD_ETM_Area__c',
                'PLS_NCD_Theatre__c'       => 'Opp_PLS_NCD_ETM_Theatre__c'
            },

            'SaaS AE' => new Map<String, String>{
                'PLS_SaaS_ETM_Territory__c' => 'Opp_PLS_SaaS_ETM_Territory__c',
                'PLS_SaaS_ETM_Region__c'    => 'Opp_PLS_SaaS_ETM_Region__c',
                'PLS_SaaS_ETM_Area__c'      => 'Opp_PLS_SaaS_ETM_Area__c',
                'PLS_SaaS_Theatre__c'       => 'Opp_PLS_SaaS_ETM_Theatre__c'
            }
        };

    public void updateCoOwnerAndTartFields(Map<String, UserTerritory2Association> adaptiveIdToUserTerrMap, Opportunity opp){
        Boolean hasAnyOverride = hasAnyETMOverride(opp);
        if (String.isBlank(opp.PLS_AE_ETM_Role_Name__c)) {
            if (!hasAnyOverride) clearAllCoOwnersAndTART(opp);
            return;
        }
        
        Account acc = opp.Account;
        Map<String, String> typeToAdaptiveIdMap = parseTypeToAdaptiveId(acc);
        String roleValue = (opp.Opportunity_Split_Parent__c != null && String.isNotBlank(opp.Opportunity_Split_Parent__r.PLS_AE_ETM_Role_Name__c)) ? 
            				opp.Opportunity_Split_Parent__r.PLS_AE_ETM_Role_Name__c : opp.PLS_AE_ETM_Role_Name__c;
        List<String> roles = new List<String>();
        roles = (String.isNotBlank(roleValue) && roleValue.contains(',')) ? roleValue.split(',') : new List<String>{ roleValue };
        
        Set<String> finalAdaptiveIds = new Set<String>();
        Boolean anyRoleApplied = false;

        for (String role : roles) {
            role = role.trim();
            if (!ROLE_CONFIG.containsKey(role)) continue;

            Map<String, Object> cfg = ROLE_CONFIG.get(role);
            String coOwnerField = (String)cfg.get('coOwnerField');
            String typePrefix   = (String)cfg.get('typePrefix');
            String overrideKey  = (String)cfg.get('overrideKey');
            List<String> tartFields = (List<String>)cfg.get('tartFields');

            /* OVERRIDE NOT PRESENT → CLEAR ONLY THIS ROLE */
            if (isOverridePresent(opp, overrideKey)) {
                continue;
                }

            /* -------- Override PRESENT → Populate -------- */
            String adaptiveId = typeToAdaptiveIdMap.get(typePrefix);
            if (String.isBlank(adaptiveId)) {
                opp.put(coOwnerField, null);
                updateOppTARTFieldsToBlank(opp, tartFields);
                continue;
            }

            anyRoleApplied = true;
            finalAdaptiveIds.add(adaptiveId);

            if (adaptiveIdToUserTerrMap != null &&
                adaptiveIdToUserTerrMap.containsKey(adaptiveId)) {

                UserTerritory2Association uta = adaptiveIdToUserTerrMap.get(adaptiveId);

                if (uta != null && uta.RoleInTerritory2 == role) {
                    if ((Id) opp.get(coOwnerField) != uta.UserId) {
                        opp.put(coOwnerField, uta.UserId);
                }
                    updateOppTARTFieldsFROMAccount(opp, acc, role);
                }
            } else {
                opp.put(coOwnerField, null);
                updateOppTARTFieldsToBlank(opp, tartFields);
        }
    }

        /* -------- Adaptive ID Sync -------- */
        opp.Non_Core_Adaptive_Id__c = finalAdaptiveIds.isEmpty() ? null : String.join(new List<String>(finalAdaptiveIds), ',');

        if (!anyRoleApplied && !hasAnyOverride) {
            clearAllCoOwnersAndTART(opp);
        }
    }

    private static Boolean hasAnyETMOverride(Opportunity opp) {
        return String.isNotBlank(opp.PLS_ETM_Overrides__c);
        }

    private static Boolean isOverridePresent(Opportunity opp, String overrideKey) {
        return ((opp.Opportunity_Split_Parent__c != null && String.isNotBlank(opp.Opportunity_Split_Parent__r.PLS_ETM_Overrides__c) && opp.Opportunity_Split_Parent__r.PLS_ETM_Overrides__c.contains(overrideKey)) ||
                (String.isNotBlank(opp.PLS_ETM_Overrides__c) && opp.PLS_ETM_Overrides__c.contains(overrideKey)));
        }

    private static Map<String, String> parseTypeToAdaptiveId(Account acc) {
        Map<String, String> result = new Map<String, String>();
        if (acc == null || String.isBlank(acc.Non_Core_Type_and_Adaptive_Id__c))
            return result;

        for (String pair : acc.Non_Core_Type_and_Adaptive_Id__c.split(';')) {
            if (pair.contains(':')) {
                List<String> parts = pair.split(':');
                result.put(parts[0].trim(), parts[1].trim());
        }        
    }
        return result;
    }

    private static void clearAllCoOwnersAndTART(Opportunity opp) {
        opp.Co_Owner__c = opp.NCD_Co_Owner__c = opp.SaaS_Co_Owner__c = opp.Non_Core_Adaptive_Id__c = null;
        for (Map<String, Object> cfg : ROLE_CONFIG.values()) {
            updateOppTARTFieldsToBlank(opp, (List<String>) cfg.get('tartFields'));
        }
    }

    private static void updateOppTARTFieldsToBlank(Opportunity opp, List<String> fields){
        for (String fld : fields) {
            if (String.isNotBlank((String) opp.get(fld))) {
                opp.put(fld, '');
            }
        }
    }

    private static void updateOppTARTFieldsFROMAccount(Opportunity opp, Account acc, String role){
        Map<String, String> fieldMap = ROLE_FIELD_MAPPING.get(role);
        for (String accField : fieldMap.keySet()) {
            String oppField = fieldMap.get(accField);
            if (acc.get(accField) != null && acc.get(accField) != opp.get(oppField)) {
                opp.put(oppField, acc.get(accField));
        }        
    }
    }

    //SAL26-1292 AND SAL26-1340 - END
}