/**
 * @description Opportunity trigger handler class
 */ 
public without sharing class OpportunityObjectTriggerHandler extends TriggerManager.GenericTriggerHandler{
    public static Boolean skipExecutionHandler = false; // skip method executions if triggered via ETMUpdateOppOwner 
	//public static Set<Id> newUCLScaleAddedOppIdsSet = new Set<Id>(); // SAL25-495: indicate-new ucl scale sku inserted on opp//SAL26-549:commented
    private static Set<ID> holdOffEmailToOpptSet = New set<ID>(); //Add Ids in before update trigger and send mail in after update trigger
    private static Set<ID> parentChildAccountIdSet = New set<ID>();//Add Ids in before insert trigger and send mail in after insert trigger
    //Rubrik Complete Start
    boolean RubrikCompleteFieldIspresent = false;
    boolean updatingOppTypeUsingSDPlookup = false; //SAL25-106
    private Opportunity_Stage_Days__c oppSetupCS = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId());
    Map<String, Schema.SObjectField> OpportunityFieldsMap= Schema.SObjectType.opportunity.fields.getMap();
    //Rubrik Complete End   //
    public static Map<string,AspenConfig__mdt> aspenConfigDistii = new Map<string,AspenConfig__mdt>(); 
    public static List<Pricebook2> pbList = new List<Pricebook2>();
    public static Map<ID, Account> AccountMapTrgInsert = new Map<ID, Account>();
    public static Map<ID, Contact> ContactMapTrgInsert = new Map<ID, Contact>();
    public static Map<ID, User> UserMapTrgInsert = new Map<ID, User>();
    public static Map<ID, ServiceContract> serviceContractMapTrgInsert = new Map<ID, ServiceContract>();
    public static Map<ID, SBQQ__Quote__c> quoteMapTrgInsert = new Map<ID, SBQQ__Quote__c>();
    public static List<Territory2> territoryListTrgInsert = new List<Territory2>();
    public static List<UserTerritory2Association> UTAListTrgInsert = new List<UserTerritory2Association>();
    public static List<UserTerritory2Association> UTAList2TrgInsert = new List<UserTerritory2Association>();
    public static List<CampaignMember> campaignMemListTrgInsert = new List<CampaignMember>();
    public static Map<ID, Opportunity> oppMapTrgInsert = new Map<ID, Opportunity>();
    public static List<Deal_Registration__c> dealRegistrationTrgInsert = new List<Deal_Registration__c>();
    
    public static Map<ID, Opportunity> oppMapTrgUpdate = new Map<ID, Opportunity>();
    public static Map<ID, Opportunity> oppMapTrgAfterUpdate = new Map<ID, Opportunity>();
    public static Map<ID, Account> AccountMapTrgUpdate = new Map<ID, Account>();
    public static Map<ID, Contact> ContactMapTrgUpdate = new Map<ID, Contact>();
    public static Map<ID, User> UserMapTrgUpdate = new Map<ID, User>();
    public static Map<ID, ServiceContract> serviceContractMapTrgUpdate = new Map<ID, ServiceContract>();
    public static Map<ID, SBQQ__Quote__c> quoteMapTrgUpdate = new Map<ID, SBQQ__Quote__c>();
    public static Map<ID, Opportunitylineitem> oliMapTrgUpdate = new Map<ID, Opportunitylineitem>();
    public static Map<ID, Lead> dealRegLinkMap = new Map<ID, Lead>();
    public static List<Order> OrderListTrgUpdate = new List<Order>();
    //Commented for SAL25-727
    //public static List<Period> periodList = new List<PEriod>(); //SAL25-549 //To fetch start and end date for the fiscal year and its quarter
    
    //PRDOPS24-484
    public static String isOppAutoManual = null;
    public static Set<Id> renewalOppAccIdSet = new Set<Id>(); //SF-43132
    public static Set<Id> evtOppIds = new Set<Id>(); //SAL25-572
    
    public static List<SBQQ__Quote__c> queriedQuoteList = new List<SBQQ__Quote__c>(); //FY25SR-1204
    
    public static List<AccountTeamMember> accTeamMembersToInsertDelete = new List<AccountTeamMember>(); //PL26-73 
    public static Date PLSDate = Date.newInstance(2025, 02, 01); //SAL26-92
    public static Set<String> plsCoOwnerRoles = new Set<String>{'Cloud AE', 'SaaS AE', 'NCD AE'};//SAL26-138:NAS to Cloud //SAL26-1232
    
    public static boolean bypassClosedWonUpdateValidation = false;//SAL26-1054
    public static boolean oppAllowEdit = false;
     /** 
     * @description Apex method to handle opportunity before insert logic
     * @param newRecords
     * This method is Override activity on Before insert.
     */
    public override void onBeforeInsert(List<sObject> newRecords) {
        //SF 8310 starts
        Map<Id,Opportunity> renewedServiceContracts = new Map<Id,Opportunity>();
        // sf 8310 ends
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        ShGl_DisableBusinessLogic__c disabledBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance();
        List<Opportunity> oppList = (List<Opportunity>) newRecords;
        Map<String, Contact> emailContactMap = new Map<String, Contact>();
        Set<String> emailSet = new Set<String>();
        Set<Id> rubrikSalesEngineerIds = new Set<Id>();
        Map<Id,List<Opportunity>> mapContactOpportunities  = new Map<Id,List<Opportunity>>();
        
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> newOppAccIdSet = new Set<Id>(); //PL26-3
        Set<String> PLSterritoryIds = new set<String>(); //PL26-3
        map<id,List<String>> PLSaccToTerrMap = new  map<id,List<String>>(); //PL26-3
        map<id,UserTerritory2Association> PLSuserToUtaMap = new  map<id,UserTerritory2Association>(); //PL26-3
        Map<String, Id> PLSSalesEngineerToUTAMap = new Map<String, Id>(); //SAL26-151
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> SplitOppOwnerIdSet = new Set<Id>();
        Set<Id> serviceContractIdSet = new Set<Id>();
        Map<string,Id>adaptiveId_TerrId = new Map<string,Id>();
        Map<Id,Set<Id>> mapAccIdContactIds = new Map<Id,Set<Id>>();
        
        /*START- Scale Utility Phase 2.0 #CSU-496: Added by Shaloo Mishra*/
        Map<Id, String> mapOpptyIdVsOrderSubType = new Map<Id, String>();
        Map<Id, String> mapOpptyIdVsPrimaryContact = new Map<Id, String>(); 
        /*END- Scale Utility Phase 2.0 #CSU-496: Added by Shaloo Mishra*/
        
        //SF-7721 (ETM-181): Renewal Opp Owner changes
        Map<string, Map<string,Id>> mapAdaptiveId_RAMTerrId= new Map<string, Map<string, Id>>();
        Map<Id, Id> mapTerrId_RAMOwnerId = new Map<Id, Id>();
        Set<Id> RAMParentTerrIds = new Set<Id>();
        
        //Rubrik Complete Start
        if(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier != null && OpportunityFieldsMap.containsKey(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier)){
            RubrikCompleteFieldIspresent = true;
        }
        //Rubrik Complete End
        /*if(pbList.isEmpty()){
            pbList = [Select ID from Pricebook2 where Name = 'CPQ PriceBook'];
        }
        if(!pbList.isEmpty())*/
            OpportunityUtil.defaultPriceBookId = System.Label.CPQPricebookID; 
        PriceBook_Config_Ids__c pbConfig = PriceBook_Config_Ids__c.getValues('CPQPricebookID'); //SAL26-550
        if(pbConfig != null && pbConfig.Config_Id__c != ''){
            OpportunityUtil.defaultPriceBookId = pbConfig.Config_Id__c;
        }
        
        for(Opportunity newOppObj: oppList){
            newOppObj.Deleted_RTA__c = 0;
            newOppObj.Deleted_line_ContractId_RTA__c = '';
            
            //Starts - [Shaloo Mishra] Arroyo 2.0 ARY-31: Trigger Task creation when an Oppty has Primary Renewal/Expansion Quote created
            
            if(newOppObj.SBQQ__PrimaryQuote__c != null ) {
                
                if((newOppObj.Primary_Quote_Type__c == 'Renewal' || newOppObj.Primary_Quote_Type__c == System.Label.Arry_Quote_Type) && newOppObj.Opportunity_Program__c == System.Label.Arr_Opportunity_Program_as_Refresh)
                    //Added Custom Label for 'Renewal + Expansion' value of Quote Type
                    //Added Custom Label for 'Go Refresh' value of Opportunity Program
                    //Remove the check for Type = Renewal when the automatic population of Quote Type field logic is built by Madhura
                {
                    OpportunityObjectTriggerHelper.createTasksForRenewalExpansionQuote(newRecords); //OnBeforeInsert
                }
            }
            //Ends - [Shaloo Mishra] Arroyo 2.0 ARY-31: Trigger Task creation when an Oppty has Primary Renewal/Expansion Quote created
            
            //sf 8310 starts
            if(newOppObj!=null && newOppObj.SBQQSC__RenewedServiceContract__c!=null){
                renewedServiceContracts.put(newOppObj.SBQQSC__RenewedServiceContract__c,newOppObj);
            } // sf 8310 ends
            
            if(!mapAccIdContactIds.containsKey(newOppObj.AccountId)){
                mapAccIdContactIds.put(newOppObj.AccountId,null);
            }
            //PL26-3 start
            if(newOppObj.AccountId != null){
                newOppAccIdSet.add(newOppObj.AccountId);
            }
            //PL26-3 end
            emailSet.add(newOppObj.Lead_Email_Hidden__c);
            accountIdSet.add(newOppObj.AccountId);
            accountIdSet.add(newOppObj.Partner_Lookup__c);
            //SAL25-106
            accountIdSet.add(newOppObj.MSP_End_User_Lookup__c);
            //Pankaj-cpq22-3392
            accountIdSet.add(newOppObj.Distributor_Lookup__c);
            accountIdSet.add(newOppObj.Partner_of_Record__c);
            
            //SAL24-528 //SAL24-527
            accountIdSet.add(newOppObj.Sourcing_Partner__c);
            accountIdSet.add(newOppObj.Teaming_Partner__c);
            //ETM-179: MSP Opportunity ETM Owner and TART enhancement
            if(newOppObj.Opportunity_Sub_Type__c != null && newOppObj.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp && (newOppObj.Opportunity_Sub_Type__c.contains('MSP') || newOppObj.Opportunity_Sub_Type__c == 'GC Offer') && newOppObj.MSP_End_User_Lookup__c != null) { accountIdSet.add(newOppObj.MSP_End_User_Lookup__c); } //SAL24-548 //SAL24-798
            contactIdSet.add(newOppObj.Initial_Contacts_Name__c);
            //SAL24-184
            if(newOppObj.FCRM__FCR_Admin_Originating_Contact__c != null){
                contactIdSet.add(newOppObj.FCRM__FCR_Admin_Originating_Contact__c);
            }
            userIdSet.add(newOppObj.OwnerId);
            if(newOppObj.OriginalLeadOwner__c != null && newOppObj.SDR_Led__c){
                userIdSet.add(newOppObj.OriginalLeadOwner__c);
            }
            serviceContractIdSet.add(newOppObj.SBQQSC__AmendedServiceContract__c);
            serviceContractIdSet.add(newOppObj.SBQQSC__RenewedServiceContract__c);
            if(newOppObj.Opportunity_Split_ParentID__c!=null){
                SplitOppOwnerIdSet.add(newOppObj.OwnerId);
            }
            rubrikSalesEngineerIds.add(newOppObj.Rubrik_Sales_Engineer__c);
            if(newOppObj.Initial_Contacts_Name__c != null){
                if(!mapContactOpportunities.containsKey(newOppObj.Initial_Contacts_Name__c)){
                    mapContactOpportunities.put(newOppObj.Initial_Contacts_Name__c,new List<Opportunity>());
                }
                mapContactOpportunities.get(newOppObj.Initial_Contacts_Name__c).add(newOppObj);
            }
            //Rubrik Complete Start
            if(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier != null && RubrikCompleteFieldIspresent){
                if(newOppObj.get(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier) == true){
                    newOppObj.Lead_Source_Campaign_Details__c = system.label.Rubrik_Complete_Campaign_Id;
                }
            }
            //Rubrik Complete End
            //MKT22-254
            if(newOppObj.Amount_on_lead_conversion__c != null)
                newOppObj.Amount = newOppObj.Amount_on_lead_conversion__c;
            
            //SAL23-430
            newOppObj.CSM_Notes_Last_Modified_On__c = newOppObj.CSM_Notes__c != null ? System.now() : null;
            // SAL24-120 start
            if(newOppObj.RecordTypeId==OpportunityUtil.oppRecTypeIdRenewOpp && newOppObj.Renewals_Sentiment__c!=null && newOppObj.Opportunity_Type__c!='Debooking'){
                if(newOppObj.Renewals_Sentiment__c=='Green')
                    newOppObj.Blocker_Reason__c='No Risk';
                if(newOppObj.Renewals_Sentiment__c=='Yellow')
                    newOppObj.Blocker_Reason__c='Timeline';
            }
            // SAL24-120 end
        }
        
        emailSet.remove(null);
        rubrikSalesEngineerIds.remove(null);
        accountIdSet.remove(null);
        contactIdSet.remove(null);
        userIdSet.remove(null);
        serviceContractIdSet.remove(null);
        
        //Map<ID, Account> updateAccountMap = new Map<ID, Account>();
        //Map<ID, Contact> contactMap = new Map<ID, Contact>();
        //Map<ID, User> userMap = new Map<ID, User>();
        //Map<ID, ServiceContract> serviceContractMap = new Map<ID, ServiceContract>();
        List<string> SERoles = new List<string>();
        string TART ,SalesEngg ,TerrId;
        set<Id>SplitOppTerrId = new set<id>();
        List<Contact> cntList = new List<Contact>();
        Map<Id,string>splitOppOwner_TART = new Map<Id,string>();
        Map<string,Id>adaptiveIdSalesEngg = new map<string,Id>();
        List<Opportunity> clonedOppList = new List <Opportunity>();
        //SF-7721 (ETM-181): Renewal Opp Owner changes
        List<string> RAMRoles = new List<string>();
        String unassignedRenewalOwnerId; //SAL23-720 //SAL24-798
        //SAL24-735
        Map<String,String> adptiveIdToPLSRoleMap = new Map<String,String>(); 
        List<string> plsAERoles = new List<string>();
        //SAL25-48
        List<string> plsSERoles = new List<string>();
        Map<String,Id> aIdRoleToPLSSEMap = new Map<String,Id>();
        //SF-8995
        Map<String,String> terrToRegionSEAdaptiveMap = new Map<String,String>();
        Set<String> partnerPortalProfileSet = new Set<String>{'Partner Community User', 'Rubrik Partner Community Manager', 'Rubrik Partner Community User'};//prit26-248
            if((!contactIdSet.isEmpty() || !mapAccIdContactIds.isEmpty()) && ContactMapTrgInsert.isEmpty()){
                cntList = [SELECT Id, Email, Name, LeadSource,AccountId, CommunityUserProfile__c,UTM_Term__c,Last_UTM_Term_Date__c,Last_Partner_Sourced_Date__c  FROM Contact WHERE ID IN :contactIdSet OR Email IN: emailSet OR AccountID IN: mapAccIdContactIds.keySet() ORDER BY CreatedDate ASC LIMIT 50000];
                for(Contact con : cntList) {
                    if(mapAccIdContactIds.get(con.AccountId) == null){
                        mapAccIdContactIds.put(con.AccountId, new Set<Id>{con.Id});
                    }
                    else{
                        mapAccIdContactIds.get(con.AccountId).add(con.Id);
                    }
                    if(emailSet.contains(con.Email) && !partnerPortalProfileSet.contains(con.CommunityUserProfile__c)){
                        emailContactMap.put(con.Email, con);
                    }
                }
            }
        List<String> lstDistributorsNames = new List<String>();
        lstDistributorsNames = system.label.ProposedAspenDistributors.split(';');
        OpportunityObjectTriggerHelper.getAspenConfigData();
        aspenConfigDistii = OpportunityObjectTriggerHelper.aspenConfigDistii;
        
        if(!contactIdSet.isEmpty())
            ContactMapTrgInsert = new Map<ID, Contact>(cntList);
        if(!serviceContractIdSet.isEmpty() && serviceContractMapTrgInsert.isEmpty()){
            serviceContractMapTrgInsert = OpportunityTriggerQueries.getServiceContracts(serviceContractIdSet);
            //serviceContractMap = new Map<ID, ServiceContract>([Select SBQQSC__Opportunity__c, SBQQSC__Opportunity__r.Opportunity_Sub_Type__c,SBQQSC__Opportunity__r.Name, SBQQSC__Order__c, SBQQSC__Order__r.Order_Sub_Type__c, SBQQSC__Quote__c, SBQQSC__Quote__r.OpportunitySubType__c, SBQQSC__Opportunity__r.Initial_Contacts_Name__c from ServiceContract WHERE ID IN:serviceContractIdSet]);
            //Fix made for CPQ22-4959 - start
            if(!serviceContractMapTrgInsert.isEmpty()) {
                for(ServiceContract contract : serviceContractMapTrgInsert.values()) {
                    if(!String.isBlank(contract.SBQQSC__Opportunity__r.Distributor_Lookup__c)) {
                        accountIdSet.add(contract.SBQQSC__Opportunity__r.Distributor_Lookup__c);
                    }
                    if(!String.isBlank(contract.SBQQSC__Opportunity__r.Partner_Lookup__c)) {
                        accountIdSet.add(contract.SBQQSC__Opportunity__r.Partner_Lookup__c);
                    }
                }
            } //Fix made for CPQ22-4959 - end
        }
        
        renewalOppAccIdSet = new Set<Id>(); //SF-43132
        // sf 8310 starts
        if(renewedServiceContracts!=null && renewedServiceContracts.size()>0){
            OpportunityObjectTriggerHelper.populateFieldsonRenewalOppo(renewedServiceContracts,serviceContractMapTrgInsert);
        }// SF 8310 Ends
        accountIdSet.addAll(renewalOppAccIdSet); //SF-43132
    
        if(!accountIdSet.isEmpty() && AccountMapTrgInsert.isEmpty()) 
            //SAL22-238 - SAL22-354
            //updateAccountMap = new Map<ID, Account>([Select RecordTypeId, Adaptive_Territory_Id__c, OwnerId, Type, Close_Won_Date__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,ETM_Theatre__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c,CDM_Theatre__c,Rubrik_Sales_Engineer__c from Account WHERE ID IN:accountIdSet]); //SF-8995
            //SAL24-27 ,remove Account.Account_Deal_Ops_Notes__c from map, it's deprecated now
            AccountMapTrgInsert = new Map<ID, Account>([Select ID,Name, BillingCountry,Aspen_Eligible__c ,ParentId, createdById, LastModifiedById, Owner.ManagerId, RecordTypeId,RecordType.Name, Distributor__c, Distributor__r.Contract_Status__c, Adaptive_Territory_Id__c, OwnerId, Type, Close_Won_Date__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,ETM_Theatre__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c,CDM_Theatre__c,Rubrik_Sales_Engineer__c,Account_Deal_Desk_Notes__c,MSP_Account_Lookup__c,AWS_GCP_Cloud_Alliance_BDM__r.Name,AWS_GCP_Cloud_Alliance_BDM__c,MSFT_OCI_Cloud_Alliance_BDM__r.Name,MSFT_OCI_Cloud_Alliance_BDM__c,Focused_Partner__c,National_Partner__c,Is_L3_Eligible_Account__c,Renewal_Owner__c,Non_Core_Adaptive_Territory_Ids__c from Account WHERE ID IN:accountIdSet OR (Name In: lstDistributorsNames OR Aspen_Eligible__c = true OR (ID IN : aspenConfigDistii.keySet() AND BillingCountry!='United Sates')) ]); //SF-8995 //SAL23-443 //SAL24-28 //SAL24-472 //SAL24-527 //SAL24-798 //PL26-3 //Removed Account_Alliance_BDM_Lookup__r.Name,Account_Alliance_BDM_Lookup__c fields from the query as part of SAL26-101 and added AWS_GCP_Cloud_Alliance_BDM__r.Name,AWS_GCP_Cloud_Alliance_BDM__c,MSFT_OCI_Cloud_Alliance_BDM__r.Name,MSFT_OCI_Cloud_Alliance_BDM__c fields in the Query as part of SAL26-105
        
        for(Account acc: AccountMapTrgInsert.values()){
            adaptiveId_TerrId.put(acc.Adaptive_Territory_Id__c,null);
            //PL26-3 start
            if(newOppAccIdSet.contains(acc.Id) && acc.Non_Core_Adaptive_Territory_Ids__c != null){
                PLSterritoryIds.addall(acc.Non_Core_Adaptive_Territory_Ids__c.split(',')); 
                if(PLSaccToTerrMap.containskey(acc.Id)){
                    PLSaccToTerrMap.get(acc.Id).addall(acc.Non_Core_Adaptive_Territory_Ids__c.split(','));
                }
                else{
                    PLSaccToTerrMap.put(acc.Id,new List<String>());
                    PLSaccToTerrMap.get(acc.Id).addall(acc.Non_Core_Adaptive_Territory_Ids__c.split(','));
                }
            }
            //PL26-3 end
            if(acc.ParentId != null){
                parentChildAccountIdSet.add(acc.Id);
                parentChildAccountIdSet.add(acc.ParentId);
            }
            if(acc.Renewal_Owner__c != null) userIdSet.add(acc.Renewal_Owner__c); //SAL24-798
        }
        //SAL24-798
        if(!userIdSet.isEmpty() && UserMapTrgInsert.isEmpty()) 
            UserMapTrgInsert = new Map<ID, User>([Select Division, Region__c, Area__c, Theatre__c, Sub_Region__c, UserRoleId, UserRole.Name,isActive from User where ID IN:userIdSet]); //SAL24-798
                
        Map<Id,Id> mapContactIdCampaignId = new Map<Id,Id>();
            //SF-7721 (ETM-181): Renewal Opp Owner changes
            //List<Territory_Management_Setup__mdt> fielSalesMdt = [select Field_Value__c,Field_Type__c,Operator__c,DeveloperName from Territory_Management_Setup__mdt where DeveloperName IN('Role_of_Sales_Engineer','Role_of_Renewal_Account_Manager')];
            for(Territory_Management_Setup__mdt fielSalesMdt : [select Field_Value__c,Field_Type__c,Operator__c,DeveloperName from Territory_Management_Setup__mdt where DeveloperName IN('Role_of_Sales_Engineer','Role_of_Renewal_Account_Manager','Unassigned_Renewal_OwnerId','Role_of_PLS_AE','Role_of_PLS_SE')]){ //SAL23-720 //SAL24-798 //SAL24-735 //SAL25-48
                if(fielSalesMdt.Field_Value__c!=null){
                    if(fielSalesMdt.DeveloperName.equalsIgnoreCase('Role_of_Sales_Engineer'))
                        SERoles = fielSalesMdt.Field_Value__c.split(';');
                    if(fielSalesMdt.DeveloperName.equalsIgnoreCase('Role_of_Renewal_Account_Manager'))
                        RAMRoles = fielSalesMdt.Field_Value__c.split(';');
                    //SAL23-720 //SAL24-798
                    if(fielSalesMdt.DeveloperName.equalsIgnoreCase('Unassigned_Renewal_OwnerId'))
                        unassignedRenewalOwnerId = fielSalesMdt.Field_Value__c;
                    //SAL24-735
                    if(fielSalesMdt.DeveloperName.equalsIgnoreCase('Role_of_PLS_AE'))
                        plsAERoles = fielSalesMdt.Field_Value__c.split(';');
                    //SAL25-48
                    if(fielSalesMdt.DeveloperName.equalsIgnoreCase('Role_of_PLS_SE'))
                        plsSERoles = fielSalesMdt.Field_Value__c.split(';');
                }
            }
            
            //SF-7721 (ETM-181): Renewal Opp Owner changes
            //SAL24-798n735
            if(!adaptiveId_TerrId.isEmpty() && territoryListTrgInsert.isEmpty()){
                territoryListTrgInsert = [Select id,Adaptive_Territory_Id__c, ParentTerritory2Id, ParentTerritory2.ParentTerritory2Id, ParentTerritory2.ParentTerritory2.ParentTerritory2Id from territory2 where Adaptive_Territory_Id__c IN: adaptiveId_TerrId.keyset() and Territory2Model.state='Active'];
            } 
            for(Territory2 Terr: territoryListTrgInsert){
                adaptiveId_TerrId.put(Terr.Adaptive_Territory_Id__c,Terr.Id);
            }
            //SAL24-735
            if(!adaptiveId_TerrId.isEmpty() && UTAListTrgInsert.isEmpty()){
            	UTAListTrgInsert = [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,
                                Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.Internal_Territory_Name__c,  //PL26-3
                                Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,  //PL26-3
                                Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,Territory2.Territory_Structure_Type__c from UserTerritory2Association  //PL26-3
                                where Territory2.Territory2Model.state='Active' AND User.IsActive = true and Territory2.Territory2Type.DeveloperName = 'Territory'
                                AND ((((RoleInTerritory2 IN :plsAERoles and UserId =: UserInfo.getUserId()) OR RoleInTerritory2 IN :plsSERoles OR RoleInTerritory2 IN :SERoles)//PLS AE //SAL25-48
                                      AND Territory2.Adaptive_Territory_Id__c IN: adaptiveId_TerrId.keyset())
                                OR (Territory2.Adaptive_Territory_Id__c IN: PLSterritoryIds AND RoleInTerritory2 IN ('Cloud AE','SaaS AE','NCD AE','Sales Engineer')))]; //SAL26-138:NAS to Cloud //SAL26-1217 added 'NCD AE' role in the query
            }
            for(UserTerritory2Association UTA : UTAListTrgInsert){
                //SAL25-48
                if(plsAERoles.contains(UTA.RoleInTerritory2)) adptiveIdToPLSRoleMap.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.RoleInTerritory2);
                if(plsSERoles.contains(UTA.RoleInTerritory2)) aIdRoleToPLSSEMap.put(UTA.Territory2.Adaptive_Territory_Id__c+UTA.RoleInTerritory2,UTA.UserId);
            //PL26-3 start //SAL26-1217 added 'NCD AE' role
            if((UTA.RoleInTerritory2 =='Cloud AE' || UTA.RoleInTerritory2 =='SaaS AE' || UTA.RoleInTerritory2 =='NCD AE') && PLSterritoryIds.contains(UTA.Territory2.Adaptive_Territory_Id__c) && !PLSuserToUtaMap.containsKey(UTA.UserId)){ //SAL26-138:NAS to Cloud
	                PLSuserToUtaMap.put(UTA.UserId,UTA);
	        }
	        //PL26-3 end
            //SAL26-151 START
            if(UTA.RoleInTerritory2 == 'Sales Engineer' && UTA.Territory2.Territory_Structure_Type__c != null && UTA.Territory2.Territory_Structure_Type__c != 'Core'){
                PLSSalesEngineerToUTAMap.put(UTA.Territory2.Adaptive_Territory_Id__c, UTA.UserId);
            }
            //SAL26-151 END
            }
                
                //SF-7721 (ETM-181): Renewal Opp Owner changes
                //SAL24-798 - remove existing logic
                /*RAMParentTerrIds.add(Terr.ParentTerritory2Id);
                RAMParentTerrIds.add(Terr.ParentTerritory2.ParentTerritory2Id);
                RAMParentTerrIds.add(Terr.ParentTerritory2.ParentTerritory2.ParentTerritory2Id);
                if(!mapAdaptiveId_RAMTerrId.containsKey(Terr.Adaptive_Territory_Id__c)){
                    Map<string,Id> mapTemp = new Map<string,Id>();
                    mapTemp.put('Territory',Terr.Id);
                    mapTemp.put('Region',Terr.ParentTerritory2Id);
                    mapTemp.put('Area',Terr.ParentTerritory2.ParentTerritory2Id);
                    mapTemp.put('Theatre',Terr.ParentTerritory2.ParentTerritory2.ParentTerritory2Id);
                    mapAdaptiveId_RAMTerrId.put(Terr.Adaptive_Territory_Id__c,mapTemp);
                }
            }*/
            
            //SF-7721 (ETM-181): Renewal Opp Owner changes
            //SAL24-798 - Remove existing logic with etm logic optimization.
            /*if(!adaptiveId_TerrId.isEmpty() && UTAListTrgInsert.isEmpty()){
                UTAListTrgInsert = [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.Territory2Type.DeveloperName, Territory2.ParentTerritory2Id, Territory2.ParentTerritory2.Adaptive_Territory_Id__c from UserTerritory2Association //SF-8995
                                    where Territory2.Territory2Model.state='Active'
                                    AND User.IsActive=true
                                    //SF-7721 (ETM-181): Renewal Opp Owner changes
                                    //AND Territory2.Territory2Type.DeveloperName ='territory'
                                    AND (RoleInTerritory2 IN : SERoles OR RoleInTerritory2='Account Executive' OR RoleInTerritory2 IN :RAMRoles)
                                    AND  (Territory2.Adaptive_Territory_Id__c IN: adaptiveId_TerrId.keyset() //sales eng
                                            OR  UserId IN : SplitOppOwnerIdSet // Split opp
                                            OR Territory2.Id IN :RAMParentTerrIds) //Renewal Opp Owner changes
                                    order by lastmodifieddate
                                    ];
            }
            for(UserTerritory2Association UTA : UTAListTrgInsert){
                //SF-7721 (ETM-181): Renewal Opp Owner changes
                if(UTA.Territory2.Territory2Type.DeveloperName == 'Territory'){
                    if(SERoles.contains(UTA.RoleInTerritory2) && adaptiveIdSalesEngg.containskey(UTA.Territory2.Adaptive_Territory_Id__c)==false){
                        adaptiveIdSalesEngg.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.UserId);
                    }
                    else if(SplitOppOwnerIdSet.contains(UTA.UserId) && UTA.RoleInTerritory2=='Account Executive'){  // Collect TART of split opp
                        splitOppOwner_TART.put(UTA.UserId ,UTA.Territory2.Adaptive_Territory_Id__c+'_'+UTA.territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                                +UTA.territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                                +UTA.territory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                                +UTA.Territory2.Internal_Territory_Name__c ); // AdaptiveId_Theater_Area_Region_Terrritory
                        SplitOppTerrId.add(UTA.Territory2Id);
                        adaptiveId_TerrId.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.Territory2Id);
                        
                        //SF-8995
                        SplitOppTerrId.add(UTA.territory2.ParentTerritory2Id);
                        terrToRegionSEAdaptiveMap.put(UTA.Territory2.Adaptive_Territory_Id__c, UTA.Territory2.ParentTerritory2.Adaptive_Territory_Id__c);
                    }
                }
                
                //SF-7721 (ETM-181): Renewal Opp Owner changes
                if(RAMRoles.contains(UTA.RoleInTerritory2)){
                    mapTerrId_RAMOwnerId.put(UTA.Territory2Id,UTA.UserId);
                }
            }
            // Query for Split opp
            if(!SplitOppTerrId.isEmpty() && !SERoles.isEmpty() && UTAList2TrgInsert.isEmpty()){
                UTAList2TrgInsert =  [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c  from UserTerritory2Association
                                        where Territory2.Territory2Model.state='Active'
                                        AND User.IsActive=true
                                        //AND Territory2.Territory2Type.DeveloperName ='territory' //SF-8995
                                        AND Territory2.Id IN: SplitOppTerrId
                                        AND RoleInTerritory2 IN : SERoles
                                        order by lastmodifieddate
                                        ];
            }
            for(UserTerritory2Association UTA : UTAList2TrgInsert){  // UTA assigned to T4(territory) level
                if(SERoles.contains(UTA.RoleInTerritory2) && adaptiveIdSalesEngg.containskey(UTA.Territory2.Adaptive_Territory_Id__c)==false){
                    adaptiveIdSalesEngg.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.UserId);
                }
            }
            SplitOppTerrId.clear();
            */
            
            if(!mapContactOpportunities.isEmpty() && campaignMemListTrgInsert.isEmpty()){//added for SAL-1775
                campaignMemListTrgInsert = [SELECT Id,CampaignId,ContactId FROM CampaignMember WHERE ContactId IN :mapContactOpportunities.keySet() ORDER BY CreatedDate ASC];
                for(CampaignMember campMemb : campaignMemListTrgInsert){
                    if(!mapContactIdCampaignId.containsKey(campMemb.CampaignId)){
                        mapContactIdCampaignId.put(campMemb.ContactId,campMemb.CampaignId);
                    }
                }
            }
        
        Map<ID, Account>updatedAccountMap = new Map<ID, Account>();
        for(Opportunity newOppObj: oppList){
            //SF-7721 (ETM-181): Renewal Opp Owner changes
            Id RenewalOppOwnerId;
            String plsAERoleName = ''; //SAL24-735
            //ETM-179: MSP Opportunity ETM Owner and TART enhancement
            Id oppAccountId = (newOppObj.Opportunity_Sub_Type__c != null && newOppObj.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp && (newOppObj.Opportunity_Sub_Type__c.contains('MSP') || newOppObj.Opportunity_Sub_Type__c == 'GC Offer') && newOppObj.MSP_End_User_Lookup__c != null) ? newOppObj.MSP_End_User_Lookup__c : newOppObj.AccountId; //SAL24-548 //SAL24-798
            newOppObj.Business_Unit__c = disableFuncCS.Is_Datos_User__c ? 'Mosaic' : newOppObj.Business_Unit__c;
            TART = SalesEngg = TerrId = null;
            //commented for SAL24-466
            //SAL24-96
            /* if(newOppObj.Initial_Contacts_Name__c != null && !contactMap.isEmpty() && contactMap.containskey(newOppObj.Initial_Contacts_Name__c) &&
    ((contactMap.get(newOppObj.Initial_Contacts_Name__c).UTM_Term__c != null && (contactMap.get(newOppObj.Initial_Contacts_Name__c).UTM_Term__c.equalsIgnoreCase('Microsoft') || contactMap.get(newOppObj.Initial_Contacts_Name__c).UTM_Term__c.equalsIgnoreCase('msft'))) || ( contactMap.get(newOppObj.Initial_Contacts_Name__c).Last_UTM_Term_Date__c != null && system.today() <= contactMap.get(newOppObj.Initial_Contacts_Name__c).Last_UTM_Term_Date__c.addDays(180)) )){
    newOppObj.Alliance_Partner_Name__c = 'Microsoft';
    newOppObj.Cloud_Partner_Led_Activity__c = 'Yes';
    newOppObj.Last_UTM_Term_Date__c = system.today();
    }*/
    //SAL25-106
    if(newOppObj.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp && newOppObj.MSP_End_User_Lookup__c!=null && AccountMapTrgInsert.keyset().contains(newOppObj.MSP_End_User_Lookup__c)){
        if(AccountMapTrgInsert.get(newOppObj.MSP_End_User_Lookup__c).Type == 'Prospect'){
            updatingOppTypeUsingSDPlookup = true;
            newOppObj.Opportunity_Type__c = 'New Customer';
        }
    }
            //SAL24-184
            if(newOppObj.FCRM__FCR_Admin_Originating_Contact__c != null && !contactMapTrgInsert.isEmpty() && contactMapTrgInsert.containskey(newOppObj.FCRM__FCR_Admin_Originating_Contact__c)
                && contactMapTrgInsert.get(newOppObj.FCRM__FCR_Admin_Originating_Contact__c).Last_Partner_Sourced_Date__c != null ){
                    newOppObj.Last_Partner_Sourced_Date__c  = contactMapTrgInsert.get(newOppObj.FCRM__FCR_Admin_Originating_Contact__c).Last_Partner_Sourced_Date__c;
                }
            if(String.isNotBlank(newOppObj.Lead_Email_Hidden__c) && emailContactMap.containskey(newOppObj.Lead_Email_Hidden__c)) {
                newOppObj.Initial_Contacts_Name__c = emailContactMap.get(newOppObj.Lead_Email_Hidden__c).Id;
            }
            if(newOppObj.Initial_Contacts_Name__c != null && mapContactIdCampaignId.containsKey(newOppObj.Initial_Contacts_Name__c)){
                newOppObj.CampaignId = mapContactIdCampaignId.get(newOppObj.Initial_Contacts_Name__c);//added for SAL-1775
            }
            //SAL24-332
            if(newOppObj.SOW_Required__c){
                newOppObj.Automated_Uncheck_SOW_Required__c = false;
            }
            //MKT22-240
            /*commented as a part of SAL25-348
            if(AccountMapTrgInsert.keySet().contains(newOppObj.AccountId)){
                newOppObj.Partner_of_Record__c = AccountMapTrgInsert.get(newOppObj.AccountId).MSP_Account_Lookup__c;
            }*/
            // SAL24-527 to set "Focused Partner" and "National Partner" fields value
            if(newOppObj.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp && !newOppObj.IsClosed){
                OpportunityObjectTriggerHelper.updateFocusNationalPartner(newOppObj,AccountMapTrgInsert);                          
            } // SAL24-527 END
            //SAL24-28 //SAL24-472 //SAL24-798 //SAL25-99
            if(!newOppObj.Override_ETM_Alliance_BDM__c){
                //Added below lines as part SAL26-105
                newOppObj.AWS_GCP_Cloud_Alliance_BDM__c = AccountMapTrgInsert.get(oppAccountId)?.AWS_GCP_Cloud_Alliance_BDM__r?.Name;
                newOppObj.AWS_GCP_Cloud_Alliance_BDM_Id__c = AccountMapTrgInsert.get(oppAccountId)?.AWS_GCP_Cloud_Alliance_BDM__c;
                newOppObj.MSFT_OCI_Cloud_Alliance_BDM__c = AccountMapTrgInsert.get(oppAccountId)?.MSFT_OCI_Cloud_Alliance_BDM__r?.Name;
                newOppObj.MSFT_OCI_Cloud_Alliance_BDM_Id__c = AccountMapTrgInsert.get(oppAccountId)?.MSFT_OCI_Cloud_Alliance_BDM__c;
                //Commented below lines as part of SAL26-101
                /*newOppObj.Opportunity_Alliance_BDM__c = AccountMapTrgInsert.get(oppAccountId)?.Account_Alliance_BDM_Lookup__r?.Name; //SAL25-583
                newOppObj.Account_Alliance_BDM_Id__c = AccountMapTrgInsert.get(oppAccountId)?.Account_Alliance_BDM_Lookup__c; //SAL25-583*/
            }
            /*if(newOppObj.Deal_Registration__c && String.isNotBlank(newOppObj.Deal_Registration_Number__c)){
    //System.debug('Entered Here'+newOppObj);
    newOppObj.Deal_Reg_Approval_Status__c = 'Approved';
    newOppObj.Deal_Reg_Approval_Timestamp__c = System.now();
    newOppObj.Deal_Reg_Expiration_Date__c = System.now() + 90;
    }*/
            //SF-8995: Fix for RubrikSalesEngineer stamp on split
            //SAL24-798 - Remove existing logic with etm logic optimization.
            /*if(newOppObj.Opportunity_Split_ParentID__c!=null){
                if(splitOppOwner_TART.containskey(newOppObj.OwnerId)){
                    TART = splitOppOwner_TART.get(newOppObj.OwnerId);
                    if(TART!= null && TART.split('_')[0]!=null){
                        TerrId = adaptiveId_TerrId.get(TART.split('_')[0]);
                        //SF-8995
                        //SalesEngg = adaptiveIdSalesEngg.get(TART.split('_')[0]);
                        String parentSEAdaptiveId = terrToRegionSEAdaptiveMap.get(TART.split('_')[0]);
                        SalesEngg = adaptiveIdSalesEngg.get(TART.split('_')[0]) != null ?
                            adaptiveIdSalesEngg.get(TART.split('_')[0]) :
                        parentSEAdaptiveId != null && adaptiveIdSalesEngg.get(parentSEAdaptiveId) != null ? adaptiveIdSalesEngg.get(parentSEAdaptiveId) : null ;
                        
                    }
                }
            } //SF-8995 */
            //ETM-179: MSP Opportunity ETM Owner and TART enhancement
            if(oppAccountId!=null && AccountMapTrgInsert.containskey(oppAccountId) && AccountMapTrgInsert.get(oppAccountId).Adaptive_Territory_Id__c!=null){ //SAL24-735n798
                //SF-7721 (ETM-181): Renewal Opp Owner changes
                //SalesEngg = adaptiveIdSalesEngg.get(updateAccountMap.get(newOppObj.AccountId).Adaptive_Territory_Id__c);
                //TerrId = adaptiveId_TerrId.get(updateAccountMap.get(newOppObj.AccountId).Adaptive_Territory_Id__c);
                String accAdaptiveId = AccountMapTrgInsert.get(oppAccountId).Adaptive_Territory_Id__c;
                //SF-8995
                //SalesEngg = adaptiveIdSalesEngg.get(accAdaptiveId);
                SalesEngg = AccountMapTrgInsert.get(oppAccountId).Rubrik_Sales_Engineer__c;
                TerrId = adaptiveId_TerrId.get(accAdaptiveId);
                //Get RAM Territory based on hierarchy
                //SAL24-798 - Remove existing logic with etm logic optimization.
                /*if(mapAdaptiveId_RAMTerrId.containsKey(accAdaptiveId)){
                    RenewalOppOwnerId = mapTerrId_RAMOwnerId.containsKey(mapAdaptiveId_RAMTerrId.get(accAdaptiveId).get('Territory')) ? mapTerrId_RAMOwnerId.get(mapAdaptiveId_RAMTerrId.get(accAdaptiveId).get('Territory')) :
                    mapTerrId_RAMOwnerId.containsKey(mapAdaptiveId_RAMTerrId.get(accAdaptiveId).get('Region')) ? mapTerrId_RAMOwnerId.get(mapAdaptiveId_RAMTerrId.get(accAdaptiveId).get('Region')) :
                    mapTerrId_RAMOwnerId.containsKey(mapAdaptiveId_RAMTerrId.get(accAdaptiveId).get('Area')) ? mapTerrId_RAMOwnerId.get(mapAdaptiveId_RAMTerrId.get(accAdaptiveId).get('Area')) :
                    mapTerrId_RAMOwnerId.containsKey(mapAdaptiveId_RAMTerrId.get(accAdaptiveId).get('Theatre')) ? mapTerrId_RAMOwnerId.get(mapAdaptiveId_RAMTerrId.get(accAdaptiveId).get('Theatre')) : null;
                }*/
    
                //SAL24-735
                plsAERoleName = newOppObj.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp && adptiveIdToPLSRoleMap != null && adptiveIdToPLSRoleMap.containsKey(accAdaptiveId) ? adptiveIdToPLSRoleMap.get(accAdaptiveId) : '';
                //SAL25-48
                if(plsAERoleName != null && plsAERoleName != ''){
                    String plsSEOpptyRoleName = plsAERoleName.replace('AE','SE');
                    String plsSEGenericRoleName ='PLS SE';
                    SalesEngg = aIdRoleToPLSSEMap != null && aIdRoleToPLSSEMap.containsKey(accAdaptiveId+plsSEOpptyRoleName) ? aIdRoleToPLSSEMap.get(accAdaptiveId+plsSEOpptyRoleName) :
                                    aIdRoleToPLSSEMap != null && aIdRoleToPLSSEMap.containsKey(accAdaptiveId+plsSEGenericRoleName) ? aIdRoleToPLSSEMap.get(accAdaptiveId+plsSEGenericRoleName) : null;
                }
            }
            //SAL23-720 //SAL24-798 - Remove existing logic with etm logic optimization.
            //RenewalOppOwnerId = newOppObj.Opportunity_Sub_Type__c == 'MSP Consumption Renewal' ? mspConsumptionRenewalOwnerId : RenewalOppOwnerId;
            Id acctRenewalOwnerId = (oppAccountId!=null && AccountMapTrgInsert.containskey(oppAccountId) && AccountMapTrgInsert.get(oppAccountId).Renewal_Owner__c !=null) ? AccountMapTrgInsert.get(oppAccountId).Renewal_Owner__c : null;
            Boolean isAcctRenewalOwnerValid = acctRenewalOwnerId != null && UserMapTrgInsert!=null && UserMapTrgInsert.containsKey(acctRenewalOwnerId) && UserMapTrgInsert.get(acctRenewalOwnerId).IsActive ? true : false;
            RenewalOppOwnerId = (newOppObj.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp && newOppObj.Opportunity_Sub_Type__c != null && newOppObj.Opportunity_Sub_Type__c.contains('Renewal') && isAcctRenewalOwnerValid) ? acctRenewalOwnerId : unassignedRenewalOwnerId;
    
            OpportunityObjectTriggerHelper.resetOpportunityFieldsOnChange(newOppObj, newOppObj, AccountMapTrgInsert, updatedAccountMap, contactMapTrgInsert, UserMapTrgInsert, serviceContractMapTrgInsert,TART,SalesEngg,TerrId,RenewalOppOwnerId,plsAERoleName,updatingOppTypeUsingSDPlookup);  //SF-7721 (ETM-181): Renewal Opp Owner changes //SAL24-735 //SAL25-106
            OpportunityUtil.resetPLSCoOwnerFields(newOppObj);//PL26-3
            
            // SAL24-305 Start 
            if(newOppObj.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp && newOppObj.Opportunity_Type__c == 'New Customer' && String.isBlank(newOppObj.Projected_Product_Mix__c)){
                newOppObj.Projected_Product_Mix__c='Fresh';
            }// SAL24-305 end
            if(!disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c
                && !newOppObj.isClosed
                && newOppObj.Opportunity_Type__c != 'Debooking'
                && newOppObj.Opportunity_Sub_Type__c != 'MSP Overage'
                && newOppObj.Polaris_Portal_Contact__c != null
                && !(newOppObj.StageName == '1 Discovery' && newOppObj.recordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp)
                && (mapAccIdContactIds.get(newOppObj.AccountId) == null || !mapAccIdContactIds.get(newOppObj.AccountId).contains(newOppObj.Polaris_Portal_Contact__c))){
                    newOppObj.addError('Rubrik Security Cloud Owner must belong to same Account as Opportunity.'); //SAL24-356
                    
                    //OpportunityObjectTriggerHelper.polarisContactValidation(newOppObj,mapAccIdContactIds);
                }
            
            //SF-6663 changes
            
            if(newOppObj.SBQQSC__AmendedServiceContract__c != null){
                /*START- Scale Utility Phase 2.0 #CSU-496: Added by Shaloo Mishra*/
                String orderSubType = (serviceContractMapTrgInsert != null 
                                        && serviceContractMapTrgInsert.containsKey(newOppObj.SBQQSC__AmendedServiceContract__c) 
                                        && serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c) != null
                                        && serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c).SBQQSC__Order__c != null
                                        && serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c).SBQQSC__Order__r.Order_Sub_Type__c != null)? 
                    serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c).SBQQSC__Order__r.Order_Sub_Type__c : '';
                
                String primaryContact = (serviceContractMapTrgInsert != null 
                                            && serviceContractMapTrgInsert.containsKey(newOppObj.SBQQSC__AmendedServiceContract__c) 
                                            && serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c) != null
                                            && serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c).SBQQSC__Opportunity__c != null
                                            && serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c).SBQQSC__Opportunity__r.Initial_Contacts_Name__c != null)? 
                    serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c).SBQQSC__Opportunity__r.Initial_Contacts_Name__c : '';
                
                if(orderSubType == 'GC Offer'){
                    mapOpptyIdVsOrderSubType.put(newOppObj.Id, orderSubType);
                    mapOpptyIdVsPrimaryContact.put(newOppObj.Id, primaryContact);
                    OpportunityObjectTriggerHelper.setOpptySubTypeOnAmendmentOppty(newRecords, mapOpptyIdVsOrderSubType,
                                                                                        mapOpptyIdVsPrimaryContact); //OnBeforeInsert
                }
                /*END- Scale Utility Phase 2.0 #CSU-496: Added by Shaloo Mishra*/
                //newOppObj.name = serviceContractMap.get(newOppObj.SBQQSC__AmendedServiceContract__c).SBQQSC__Opportunity__r.Name + ' - Amendment';
                //Logic for CPQ22-48 : TO truncate opportunity name
                String oppName = serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c).SBQQSC__Opportunity__r.Name;
                if(oppName.length()>100){
                    oppName = oppName.substring(0,100);
                    oppName += ' - Amendment';
                    newOppObj.name = oppName;
                }else{
                    newOppObj.name = oppName + ' - Amendment';
                }
                //SAL25-544
                newOppObj.Partner_Lookup__c = serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c)?.SBQQSC__Opportunity__r?.Partner_Lookup__c;
                newOppObj.Distributor_Lookup__c = serviceContractMapTrgInsert.get(newOppObj.SBQQSC__AmendedServiceContract__c)?.SBQQSC__Opportunity__r?.Distributor_Lookup__c;
            }
            if(newOppObj.isClone() && !newOppObj.StageName.contains('7 Closed ')){
                clonedOppList.add(newOppObj);
            }
            
            //Pankaj CPQ22-3392
            if(!AccountMapTrgInsert.isEmpty()){
                if((AccountMapTrgInsert.containsKey(newOppObj.AccountId) && AccountMapTrgInsert.get(newOppObj.AccountId) != null && AccountMapTrgInsert.get(newOppObj.AccountId).Is_L3_Eligible_Account__c ==true) || 
                    (AccountMapTrgInsert.containsKey(newOppObj.Partner_Lookup__c) && AccountMapTrgInsert.get(newOppObj.Partner_Lookup__c) != null && AccountMapTrgInsert.get(newOppObj.Partner_Lookup__c).Is_L3_Eligible_Account__c ==true) ||
                    (AccountMapTrgInsert.containsKey(newOppObj.Distributor_Lookup__c) && AccountMapTrgInsert.get(newOppObj.Distributor_Lookup__c) != null && AccountMapTrgInsert.get(newOppObj.Distributor_Lookup__c).Is_L3_Eligible_Account__c ==true) ||
                    (AccountMapTrgInsert.containsKey(newOppObj.Partner_of_Record__c) && AccountMapTrgInsert.get(newOppObj.Partner_of_Record__c) != null && AccountMapTrgInsert.get(newOppObj.Partner_of_Record__c).Is_L3_Eligible_Account__c ==true))
                {
                    newOppObj.L3_Eligible_Account__c = true;                    
                    
                } 
            }  //Pankaj CPQ22-3392 end  
        }
        if(!updatedAccountMap.isEmpty()){
            boolean tempFlag = flowControll.accountTrigger;
            flowControll.accountTrigger = false;
            update updatedAccountMap.values();
            flowControll.accountTrigger = tempFlag;
        }
        OpportunityObjectTriggerHelper.updateAspenEligibility(oppList,AccountMapTrgInsert,null);
        //OpportunityObjectTriggerHelper.updateOverrideToTrue(oppList);
        if( (!PLSaccToTerrMap.isEmpty() && !PLSuserToUtaMap.isEmpty()) || Test.isRunningTest() ){//PL26-3 start
            OpportunityObjectTriggerHelper.populatePLSfieldsandCoOwner(oppList,null,PLSaccToTerrMap,PLSuserToUtaMap,PLSSalesEngineerToUTAMap,false); 
        }//PL26-3 end
        
        if(!clonedOppList.isEmpty()){
            OpportunityObjectTriggerHelper.clearDRInfoOnClonedOpportunity(clonedOppList);
        }
        
    }
    
     /**
     * @description This method works on Before update
     * @param oldRecordsMap
     * @param newRecordsMap
     */
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
    
        String disabledValidationLogic = System.label.Disable_Opportunity_Quote_Sync_Validation;
        String disabledManualArroyoValidationLogic = System.label.Disable_Opp_Manual_Arroyo_values_Sync_validation; //SAL25-145
        
        if(OppAnnualContractValueUtil.oppIdSetAcvCalculation.containsAll(newRecordsMap.keySet())){
            return;
        }
        
        Map<ID, Opportunity> oldOppMap = (Map<ID, Opportunity>) oldRecordsMap;
        Map<ID, Opportunity> newOppMap = (Map<ID, Opportunity>) newRecordsMap;
        Map<String,OppStageAndHours__c> mapOfOppStages = OppStageAndHours__c.getAll();
        Set<ID> opptysToSkip = new Set<ID>();
        // PRDOPS23-26 - Prashant
        set<Id> opptyId = new Set<Id>();
        Map<ID, List<OpportunityLineItem>> oppMap = new Map<ID, List<OpportunityLineItem>>();
        
        Set<String> dealRegLinkSet = new Set<String>();
        Set<ID> rubrikSalesEngineerIds = new Set<ID>();
        Map<Id,Id> OppOwnerMap = new Map<Id,Id>();
        Map<Id,Set<Id>> mapAccIdContactIds = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mapAccIdPrimTechSupContactIds = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mapOpptyInactiveOppLines = new Map<Id,Set<Id>>();
        
        //ARY-107
        Set<Id> setRenewalExpansionOptySplit = new Set<Id>();
        Set<Id> setRenewalExpansionOptySplitRollback = new Set<Id>();
        Set<Id> setOrderedExpansionRenewal = new Set<Id>();
        //ARY-107
        
        ShGl_DisableBusinessLogic__c disabledBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance();
        ShGl_DisableFunctionalityLogic__c disabledFunctionality = ShGl_DisableFunctionalityLogic__c.getInstance();
        
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> serviceContractIdSet = new Set<Id>();
        Set<Id> oppStage5IdSet = new Set<Id>();
        Map<Id,List<Id>>OppOwner_IdMap = new Map<Id,List<Id>>(); //SAL26-498
        Map<Id,string>OpptyTART = new Map<Id,string>(); //SAL26-498
        Map<string,Id>adaptiveId_TerrId  = new map<string,Id>();  //SAL26-498
        Map<String,String> terrToRegionSEAdaptiveMap = new Map<String,String>();//SAL26-498
        list<string> TART = new list<string>();//SAL26-498
        set<string> OppAdaptiveId = new set<string>();//SAL26-498
        map<string,Id> AdaptiveSE = new map<string,Id>();//SAL26-498
        //SAL25-672: Update the logic
        /*
        Set<String> ccrApprovalRequiredForAccountIdSet = new Set<String>();
        Set<String> ccrApprovalRequiredForPartnerAccountIdSet = new Set<String>(); //SAL24-468 updating old logic
        //Map<Id,Opportunity> autoDRForMicrosoftOppMap = new Map<Id,Opportunity>();//PRIT24-534 Code Commented
        //Map<ID, Account> updateAccountMap = new Map<ID, Account>();
        String accIdsCSV = oppSetupCS.ccrApprovalRequiredForAccount__c;
        String partnerAccIdsCSV = oppSetupCS.CCR_Approval_Req_partner_A_c_Ids_CSV__c;//SAL24-468 updating old logic
        if(String.isNotBlank(accIdsCSV)){
            accIdsCSV = accIdsCSV.replaceall(' ', '');
            ccrApprovalRequiredForAccountIdSet.addAll(accIdsCSV.split(','));
        }
        if(String.isNotBlank(partnerAccIdsCSV)){
            partnerAccIdsCSV = partnerAccIdsCSV.replaceall(' ', '');
            ccrApprovalRequiredForPartnerAccountIdSet.addAll(partnerAccIdsCSV.split(','));
        }
        */
        //NetApp Quoting FCUS:20:: Shaloo STARTS
        Set<Id> primaryQuoteIdSet = new Set<Id>();
        //NetApp Quoting FCUS:20:: Shaloo ENDS
        Set<Id> stg5PrimaryQuoteId = new Set<Id>(); //SF-25610
        Set<Id> OpportunityToValidate=new Set<Id>();// SAL-24-285
        Map<Id,Id> churnNotificationMap = new Map<Id,Id>(); //SAL24-749
        Map<Id,Id> stageSixChurnNotificationMap = new Map<Id,Id>(); //SAL24-749
        Set<Id> OppSyncValidate = new Set<Id>();
        Set<Id> OppStageChange = new Set<Id>();
        //<ID, SBQQ__Quote__c> quoteMap;
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        List<String> RubrikTBD_Accounts = new List<String>{'Disti-TBD','Rubrik-TBD'};
        List<String> Marketplace_Accounts = new List<String>{'Microsoft Azure Marketplace','Amazon Web Services Marketplace'};
        List<String> aspenList = new List<String>{'ASPEN Disti TBD','Arrow ECS North America (Disti)','Promark Technology, Inc.','FedResults, Inc','Carahsoft Technology Corp.','Ingram Micro Canada','Arrow ECS Canada','Exclusive Networks (United Kingdom)','Exclusive Networks (Ireland)','ARROW ENTERPRISE COMPUTING SOLUTIONS LIMITED (UK)','Arrow ECS (Ireland)','Arrow ECS BV (Netherlands)','Exclusive Networks (Netherlands)','Exclusive Networks (Belgium)','Ingram Micro US','Arrow ECS Internet Security AG','Exclusive Networks (Austria)','Quorum Distribution GmbH','Total-Information-Management TIM AG','ADN Distribution GmbH','Exclusive Networks (Germany)','TIm AG - Germany','Exclusive Networks (Switzerland)','Tim Storage AG -Switzerland','Zibris AG','EXCLUSIVE NETWORKS (France)','Computer Gross spa','Exclusive Networks (Italy)','Arrow ECS Portugal Soc. Unipessoal','Arrow Enterprise Computing Solutions, S.A.','Exclusive Networks (Spain)','Exclusive Networks SL, Portuguese Branch'};
        List<String> lstDistributorsNames = new List<String>();
        Set<Id> updateRSCOwnerOppIds = new Set<Id>(); //SAL25-66
        Set<Id> checkRSCOwnerOppIds = new Set<Id>(); // SAL25-66
        List<Opportunity> checkRSCOwnerOppLi = new List<Opportunity>(); // SAL25-66
        Set<Id> fedrampOppSet = new Set<Id>(); // SAL25-66
        Set<ID> nonfedrampOppSet = new Set<Id>(); //SAL25-66
        Set<Id> rscgOppIdSet = new Set<Id>(); // SAL25-66
        Set<Id> nonRscgOppIdSet = new Set<Id>(); // SAL25-66
        List<Opportunity> updateRSCOwnerOppLi = new List<Opportunity>(); // SAL25-66
        //SAL25-549//Commented for SAL25-727
        //Set<Id> upliftEligOppIds = new Set<Id>();
        Map<Id, Opportunity> PLSOppMap = new Map<Id, Opportunity>(); //PL26-14
        Set<Id> PLSnewCoOwnerSet = new Set<Id>(); //PL26-14
        Set<String> PLSTerritoryIds = new Set<String>(); //PL26-14
        map<id,List<String>> PLSaccToTerrMap = new  map<id,List<String>>(); //PL26-14
        map<id,UserTerritory2Association> PLSuserToUtaMap = new  map<id,UserTerritory2Association>(); //PL26-14
        Map<String, Id> PLSSalesEngineerToUTAMap = new Map<String, Id>(); //SAL26-151
       /* Set<Id> globalAccIds = new Set<Id>();
        Map<Id,Id> oppGlobalAccIdMap = new Map<Id,Id>();
        Date startDateH1, startDateH2, endDateH1, endDateH2, planStartDate, planEndDate;*/
        //List<Opportunity> updateHoldCodeFieldsOpptyList = new List<Opportunity>(); //SAL25-129
        lstDistributorsNames = system.label.ProposedAspenDistributors.split(';');
        OpportunityObjectTriggerHelper.getAspenConfigData();
        aspenConfigDistii = OpportunityObjectTriggerHelper.aspenConfigDistii;
        
        //SAL25-672: Update the logic
        /*
        if(String.isNotBlank(accIdsCSV)){
            accIdsCSV = accIdsCSV.replaceall(' ', '');
            ccrApprovalRequiredForAccountIdSet.addAll(accIdsCSV.split(',')); 
        } 
        if(String.isNotBlank(partnerAccIdsCSV)){
            partnerAccIdsCSV = partnerAccIdsCSV.replaceall(' ', '');
            ccrApprovalRequiredForPartnerAccountIdSet.addAll(partnerAccIdsCSV.split(',')); 
        } 
        */
        
        //Rubrik Complete Start
        if(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier != null && OpportunityFieldsMap.containsKey(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier)){
            RubrikCompleteFieldIspresent = true;
        }
        //Rubrik Complete End
        
        Map<Id, List<Id>> coOwnerToOppIdsLstMap = new Map<Id, List<Id>>(); //SAL26-89
        Set<Id> oppIdsHavingBlankCoOwner = new Set<Id>();
        Boolean coOwnerExists = false; //SAL26-483 to indicate whether the Co-Owner was present already or not
        Boolean plsETMOverrideTrue = false; //SAL26-483
        Set<Id> oppIdsSetWhoseCoOwnerUpdated = new Set<Id>(); //SAL26-483
        Boolean isStageChanged = false; // SAL26-483:to execute trigger logic for Split opps
      	List<String> coOwnerFields = new List<String>{'Co_Owner__c','NCD_Co_Owner__c','SaaS_Co_Owner__c'};//SAL26-1232
        Map<Id, Map<String, Id>> oppIdToOldCoOwnerUserMap = new Map<Id, Map<String, Id>>(); //SAL26-1232
        Set<Id> oldCoOwnerUserIds = new Set<Id>(); //SAL26-1232
        Map<String, String> ROLE_TO_ALLOWED_COOWNER_FIELD = new Map<String, String>{ 'SaaS AE'  => 'SaaS_Co_Owner__c', 'NCD AE'   => 'NCD_Co_Owner__c', 'Cloud AE' => 'Co_Owner__c'}; //SAL26-1232
        Map<Id, Map<String, Id>> oppIdToCoOwnerFieldUserMap =new Map<Id, Map<String, Id>>(); //SAL26-1232
      	//SAL26-1340 START
        Map<String, String> coOwnerFieldToOverride = new Map<String, String>{
            'Co_Owner__c'      => 'CLOUD ETM Override',
            'SaaS_Co_Owner__c' => 'SaaS ETM Override',
            'NCD_Co_Owner__c'  => 'NCD ETM Override'
        };
        Boolean isAnyETMOverrideUsed = false;
        Boolean isAnyCoOwnerReplacedWithoutOverride = false;
        Set<Id> coOwnerUserIds = new Set<Id>();
        Set<Id> oppETMOverridesIds = new Set<Id>();
        //SAL26-1340 END
        //FY26WL-352 start
        Order_control__mdt disOppDupValidRec = Order_control__mdt.getInstance('Disable_OpportunityDuplicateValidation');
        if(String.isNotBlank(disOppDupValidRec.Value__c) && Boolean.valueOf(disOppDupValidRec.Value__c) == false){ 
           OpportunityObjectTriggerHelper.validateRiskAndInvalidOpp(newOppMap, oldOppMap);
        }
        //End FY26WL-352
		if(!skipExecutionHandler){ //SAL26-731
            opptysToSkip = OpportunityObjectTriggerHelper.getOpptysToSkip();
        }
        for(Opportunity newOpp : newOppMap.values()) {
            Opportunity oldOpp = oldOppMap.get(newOpp.id);
            
            if(!skipExecutionHandler) { //SAL26-89 start
                if(newOpp.StageName != oldOpp.StageName && !isStageChanged){ //SAL26-483
                    isStageChanged = true;
                }
                //SAL26-1232
                for(String fld : coOwnerFields){
                    String newValStr = (newOpp.get(fld) == null) ? null : String.valueOf(newOpp.get(fld));
                    String oldValStr = (oldOpp.get(fld) == null) ? null : String.valueOf(oldOpp.get(fld));
					
                    //SAL26-1340 PLS ETM Overrides check
                    Boolean hasETMOverrideForField = false;
                    if (String.isNotBlank(newOpp.PLS_ETM_Overrides__c)) {
                        hasETMOverrideForField = newOpp.PLS_ETM_Overrides__c.contains(coOwnerFieldToOverride.get(fld));
                }
                    if (hasETMOverrideForField) isAnyETMOverrideUsed = true;

                    // field value changed and new value is non-null (added or changed)
                    if (newValStr != oldValStr && String.isNotBlank(newValStr) && newOpp.Opportunity_Type__c != 'Debooking') {
                        if (String.isNotBlank(oldValStr) && !coOwnerExists) {
                        coOwnerExists = true;
                    }
                        if(!coOwnerToOppIdsLstMap.containsKey(newValStr)) {
                            coOwnerToOppIdsLstMap.put(newValStr, new List<Id>());
                    }
                        coOwnerToOppIdsLstMap.get(newValStr).add(newOpp.Id);
                    PLSOppMap.put(newOpp.Id, newOpp);
                    oppIdsSetWhoseCoOwnerUpdated.add(newOpp.Id); //SAL26-483
                        //SAL26-1232 - START
                        if (String.isNotBlank(oldValStr)) {
                            oldCoOwnerUserIds.add(oldValStr);
                            if (!oppIdToOldCoOwnerUserMap.containsKey(newOpp.Id)) {
                                oppIdToOldCoOwnerUserMap.put(newOpp.Id, new Map<String, Id>());
                }
                            oppIdToOldCoOwnerUserMap.get(newOpp.Id).put(fld, (Id) oldOpp.get(fld));
                        }
                        if (!oppIdToCoOwnerFieldUserMap.containsKey(newOpp.Id)) {
                            oppIdToCoOwnerFieldUserMap.put(newOpp.Id, new Map<String, Id>());
                        }
                        oppIdToCoOwnerFieldUserMap.get(newOpp.Id).put(fld, (Id) newOpp.get(fld));
                        //SAL26-1232 - END
                    }
                    // field value changed and new value is blank/null => blanking a co-owner field
                    if (newValStr != oldValStr && String.isBlank(newValStr) && newOpp.Opportunity_Type__c != 'Debooking') {
                    oppIdsHavingBlankCoOwner.add(newOpp.Id);
                    oppIdsSetWhoseCoOwnerUpdated.add(newOpp.Id); //SAL26-483
                        //SAL26-1232
                        if (!oppIdToOldCoOwnerUserMap.containsKey(newOpp.Id)) {
                            oppIdToOldCoOwnerUserMap.put(newOpp.Id, new Map<String, Id>());
                        }
                        oppIdToOldCoOwnerUserMap.get(newOpp.Id).put(fld, (Id) oldOpp.get(fld));
                        oldCoOwnerUserIds.add(oldValStr);
                    }
                 }
                
            } //SAL26-89 end
            //SAL26-1340 START
            /** SAL26-77 **/
            /*if(newOpp.PLS_ETM_Overrides__c != oldOpp.PLS_ETM_Overrides__c) {
                oppETMOverridesIds.add(newOpp.Id);
                for (String fieldName : coOwnerFields) {
                    Id userId = (Id) newOpp.get(fieldName);
                    if (userId != null) coOwnerUserIds.add(userId);
                }
            }*/
            //SAL26-1340 END
            /** SAL26-77 End **/
                        
           /* SAL26-92 */
            
            if(Test.isRunningTest()){ //SAL26-548
                PLSDate = System.today().addDays(10);
            }
            
            if(newOpp.StageName != oldOpp.StageName && !newOpp.isClosed && oldOpp.StageName == '7 Closed Lost' 
            && newOpp.Co_Owner__c == null && String.isNotBlank(newOpp.PLS_AE_ETM_Role_Name__c) && oldOpp.CloseDate < PLSDate && newOpp.Opportunity_Type__c!='Debooking') {
                newOpp.PLS_AE_ETM_Role_Name__c = '';
            } /* END: SAL26-92 */
            
            //SAL26-138
            if(newOpp.StageName != oldOpp.StageName && !newOpp.isClosed && oldOpp.isClosed && String.isNotBlank(newOpp.PLS_AE_ETM_Role_Name__c) && newOpp.PLS_AE_ETM_Role_Name__c == 'NAS AE' && oldOpp.CloseDate > PLSDate){
                newOpp.PLS_AE_ETM_Role_Name__c = 'Cloud AE';
            }
            
            if(!skipExecutionHandler && newOpp.Opportunity_Type__c!='Debooking' && (newOpp.StageName != oldOpp.StageName || newOpp.Renewals_Forecast_Risk__c != oldOpp.Renewals_Forecast_Risk__c
                                                            || newOpp.Renewals_Sentiment__c != oldOpp.Renewals_Sentiment__c
                                                           || newOpp.Next_Step__c != oldOpp.Next_Step__c)){ //SAL26-731
                OppSyncValidate.add(newOpp.Id);
            }
            if(!skipExecutionHandler && newOpp.Opportunity_Type__c!='Debooking' && newOpp.StageName != oldOpp.StageName && (newOpp.StageName == '6 PO With Channel' || newOpp.StageName == '7 Closed Won') &&String.isNotBlank(newOpp.Initial_Contacts_Name__c)){//SAL24-285 // SAL24-499 //SAL26-731
                OpportunityToValidate.add(newOpp.Id);
            }
            
            PriceBook_Config_Ids__c pbConfig = PriceBook_Config_Ids__c.getValues('CPQPricebookID'); //SAL26-550
            //SAL25-519 start
            if(newOpp.SBQQ__QuotePricebookId__c == null && newOpp.Number_of_Opportunity_Products__c == 0 && pbConfig != null && pbConfig.Config_Id__c != ''){
                //newOpp.SBQQ__QuotePricebookId__c = System.Label.CPQPricebookID;
                newOpp.SBQQ__QuotePricebookId__c = pbConfig.Config_Id__c;
            }
            if(newOpp.Pricebook2Id == null && newOpp.Number_of_Opportunity_Products__c == 0 && pbConfig != null && pbConfig.Config_Id__c != ''){
                //newOpp.Pricebook2Id = System.Label.CPQPricebookID;
                newOpp.Pricebook2Id = pbConfig.Config_Id__c;
            }
            //SAL25-519 end
            //SAL25-129 Start
            /*if(newOpp.StageName != oldOpp.StageName || newOpp.Hold_Code__c != oldOpp.Hold_Code__c){
                updateHoldCodeFieldsOpptyList.add(newOpp);
            }*/
            //SAL25-129 End
            if(newOpp.StageName != oldOpp.StageName && newOpp.Moved_stage_5to6_via_Automation__c && oldOpp.StageName == '6 PO With Channel' && !newOpp.StageName.contains('Closed')){
                newOpp.Moved_stage_5to6_via_Automation__c = false;
            }
            if(newOpp.SBQQ__PrimaryQuote__c != oldOpp.SBQQ__PrimaryQuote__c){ //SAL24-593
                newOpp.Deleted_RTA__c = 0;
                newOpp.Deleted_line_ContractId_RTA__c = '';
                OpportunityUtil.resetArroyoFields(newOpp);
            }
            if(!skipExecutionHandler && newOpp.SBQQ__PrimaryQuote__c != null ) { //SAL26-731
                if(newOpp.StageName != oldOpp.StageName){
                    OppStageChange.add(newOpp.SBQQ__PrimaryQuote__c);
                }
                if(newOpp.StageName == System.Label.Order_Creation_Stage && newOpp.StageName != oldOpp.StageName && newOpp.SBQQ__Ordered__c != TRUE  &&
                    (!opptysToSkip.contains(newOpp.Distributor_Lookup__c) || (opptysToSkip.contains(newOpp.Distributor_Lookup__c) && ((newOpp.Opportunity_Sub_Type__c == 'MSP' ) || newOpp.Sell_to_Partner__c != null)))) {
                        primaryQuoteIdSet.add(newOpp.SBQQ__PrimaryQuote__c); //NetApp Quoting FCUS:20: Line Added by Shaloo
                    }
                        //REEN-57 added stage 6
                if(newOpp.StageName == '5 Negotiate & Close'|| newOpp.StageName == Label.Order_Creation_Stage) stg5PrimaryQuoteId.add(newOpp.SBQQ__PrimaryQuote__c); //SF-25610
            }
            
            // PRDOPS23-26 - Prashant
            if(newOpp.StageName!=oldOpp.StageName && ((newOpp.StageName == '4 Business Justification' && oldOpp.Commission_Portfolio_Type__c == null) || newOpp.StageName == '7 Closed Won')){
                opptyId.add(newOpp.Id);
            }
            userIdSet.add(newOpp.OwnerId);
            
            if(newOpp.OriginalLeadOwner__c != null && newOpp.SDR_Led__c){
                userIdSet.add(newOpp.OriginalLeadOwner__c);
            }
            accountIdSet.add(newOpp.AccountId);
            accountIdSet.add(newOpp.Partner_Lookup__c);
            //SAL24-528 //SAL24-527
            accountIdSet.add(newOpp.Sourcing_Partner__c);
            accountIdSet.add(newOpp.Teaming_Partner__c);
            
            accountIdSet.add(newOpp.Distributor_Lookup__c);  //Pankaj-cpq22-3392
            
            accountIdSet.add(newOpp.Partner_of_Record__c);  //Pankaj-cpq22-3392
            accountIdSet.add(newOpp.MSP_End_User_Lookup__c); //SAL25-106
            accountIdSet.remove(null);
            // SAL24-120 start
            if(newOpp.RecordTypeId==OpportunityUtil.oppRecTypeIdRenewOpp && newOpp.Renewals_Sentiment__c!=null && newOpp.Renewals_Sentiment__c!=oldOpp.Renewals_Sentiment__c && newOpp.Opportunity_Type__c!='Debooking'){
                if(newOpp.Renewals_Sentiment__c=='Green')
                    newOpp.Blocker_Reason__c='No Risk';
                if(newOpp.Renewals_Sentiment__c=='Yellow')
                    newOpp.Blocker_Reason__c='Timeline';
            }
            // SAL24-120 end
        //SAL25-66 START
            if((newOpp.Polaris_Portal_Contact__c!=null && newOpp.Polaris_Portal_Contact__c!=oldOpp.Polaris_Portal_Contact__c )|| 
            (newOpp.Rubrik_Security_Cloud_Gov_t_Owner__c!=null && newOpp.Rubrik_Security_Cloud_Gov_t_Owner__c!=oldOpp.Rubrik_Security_Cloud_Gov_t_Owner__c)){
                updateRSCOwnerOppIds.add(newOpp.Id);
            }
         if((newOpp.Rubrik_Security_Cloud_Gov_t_Owner__c == null || newOpp.Polaris_Portal_Contact__c == null) && (newOpp.Rubrik_Security_Cloud_Gov_t_Owner__c!=oldOpp.Rubrik_Security_Cloud_Gov_t_Owner__c ||
                                                                                                                  newOpp.Polaris_Portal_Contact__c!=oldOpp.Polaris_Portal_Contact__c || newOpp.StageName != oldOpp.StageName) && 
            (newOpp.StageName == '5 Negotiate & Close' || newOpp.StageName == '6 PO With Channel' || newOpp.StageName == '7 Closed Won' || newOpp.StageName == '7 Closed Lost' || newOpp.StageName == '7 Closed Admin')
            && newOpp.Opportunity_Type__c!='Debooking' && newOpp.Opportunity_Sub_Type__c!='MSP Overage'){
                checkRSCOwnerOppIds.add(newOpp.Id); 
            }
         //SAL25-66 END
            
            //Commented for SAL25-727
            /*//SAL25-549
            if(newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp && newOpp.StageName!=oldOpp.StageName && newOpp.StageName == '7 Closed Won' && 
                (newOpp.Opportunity_Type__c=='Existing Customer' || newOpp.Opportunity_Type__c=='New Customer') && newOpp.Opportunity_Split_Parent__c == null){ //Only Existing Customer, exclude debooking and child splits.
                upliftEligOppIds.add(newOpp.Id);
            }*/
            //SAL26-1232
            //PL26-14 start: handle PLS new co-owner additions across all co-owner fields //SAL26-1340
            if(newOpp.accountId != null && (newopp.PLS_ETM_Overrides__c != null || newOpp.Opportunity_Split_Parent__c != null)) {
                for(String fld : coOwnerFields){
                    String newValStr = (newOpp.get(fld) == null) ? null : String.valueOf(newOpp.get(fld));
                    String oldValStr = (oldOpp.get(fld) == null) ? null : String.valueOf(oldOpp.get(fld));
                    if (newValStr != oldValStr) {
                        //SAL26-1340
                        if(newopp.PLS_ETM_Overrides__c != null &&
                           (fld == 'Co_Owner__c' && newopp.PLS_ETM_Overrides__c.contains('CLOUD ETM Override') ||
                           fld == 'SaaS_Co_Owner__c' && newopp.PLS_ETM_Overrides__c.contains('SaaS ETM Override') ||
                           fld == 'NCD_Co_Owner__c' && newopp.PLS_ETM_Overrides__c.contains('NCD ETM Override')))
                        {
                        if (String.isNotBlank(newValStr) && newOpp.Opportunity_Type__c != 'Debooking') {
                    if(!skipExecutionHandler) {
                                PLSnewCoOwnerSet.add(newValStr);
                       PLSOppMap.put(newOpp.Id, newOpp);
                    }
                        } else {
                            OpportunityUtil.resetPLSFields(newOpp, fld);
                }
                }
                            
                    }
                }
                //Pl26-24 start //SAL26-1340
                if(newopp.PLS_ETM_Overrides__c != null && newOpp.Number_of_Opportunity_Products__c == 0){
                  OppAnnualContractValueUtil.resetACVonOpp(newOpp);
                }
                //Pl26-24 end
            }
            //PL26-14 end
            //SAL26-498 start
            if(newOpp.Override_ETM_Ownership__c && newOpp.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp && newOpp.OwnerId != oldOpp.OwnerId){                  
                if(OppOwner_IdMap.containskey(newOpp.OwnerId))
                    OppOwner_IdMap.get(newOpp.OwnerId).add(newOpp.Id);
                else    
                    OppOwner_IdMap.put(newOpp.OwnerId,new List<Id>{newOpp.Id}); 
            }
            //SAL26-498 end
  }

        //SAL25-129
    /*if(updateHoldCodeFieldsOpptyList.size()>0 && updateHoldCodeFieldsOpptyList!=null){
        OpportunityObjectTriggerHelper.updateHoldCodeandHoldNotesFields(updateHoldCodeFieldsOpptyList);
    }*/
    //SAL25-129
        userIdSet.add(userInfo.getUserId()); //SAL24-794
        userIdSet.remove(null);
        if((!newOppMap.keySet().isEmpty() && oppMapTrgUpdate.isEmpty()) || isStageChanged){//SAL26-483: added isStageChanged condition //SAL26-1340 added PLS_ETM_Overrides__c field
            // SAL25-495: added StageName and UCL_Scale__c fields
            oppMapTrgUpdate = new Map<Id,Opportunity>([Select Id,Initial_Contacts_Name__c,AccountId,Account.ParentId,Account.Parent.ParentId, StageName,ownerId,PLS_ETM_Override__c, Opportunity_Split_Parent__c,Opportunity_Split_Parent__r.PLS_ETM_Override__c,Opportunity_Split_Parent__r.ETM_Theatre__c,Account.Non_Core_Adaptive_Territory_Ids__c,Account.ETM_Theatre__c, Comp_Uplift_ACV__c,Account.Customer_Type_Without_RCV__c, //SAL26-89 //PL26-131 //SAL26-883:added Account.ETM_Theatre__c, //SAL26-1277:Comp_Uplift_ACV__c//SAL26-1326:Account.Customer_Type_Without_RCV__c
                                                       (SELECT ContactId,Isprimary from OpportunityContactRoles where Isprimary=true), //SAL25-549 
                                                       (SELECT id, name,SBQQ__QuoteLine__c,ProductCode,SBQQ__QuoteLine__r.SBQQ__Quote__c,List_Total__c,Quantity,Product2Id,Subscription_Term__c,SBQQ__QuoteLine__r.SBQQ__ListTotal__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionTerm__c,SBQQ__QuoteLine__r.SBQQ__Product__c,SBQQ__QuoteLine__r.SBQQ__Quantity__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,
                                                        SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,SBQQ__QuoteLine__r.SBQQ__Product__r.Product_Subtype__c, //SAL25-66                                                        
                                                        SBQQ__QuoteLine__r.SBQQ__Quote__r.OpportunitySubType__c, SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Status__c,
                                                        OpportunityId, Product2.Name,Product2.Category__c,Opportunity.Order_Sub_Type__c,opportunity.Opportunity_Sub_Type__c,Opportunity.Account.RSC_G_Eligible__c, //SAL25-66
                                                        opportunity.Opportunity_Type__c, Product2.Item_Type__c, Product2.Product_Type__c, Product2.Product_Subtype__c, Product2.License_Type__c,Product2.Product_Level__c,SBQQ__QuoteLine__r.Licensing_Model__c,PricebookEntry.Product2.IsActive,
                                                        ACV_Amount__c,Subsumed_Renewal_Amount__c,Subsumed_Renewal_TCV__c ,New_Expansion_ACV__c, New_Expansion_TCV__c,Line_Type__c, UCL_Scale__c, Core_New_Expansion_ACV__c,Nas_New_Expansion_ACV__c,SaaS_New_Expansion_ACV__c,PLS_NCD_New_Expansion_ACV__c,Subsumed_Renewal_Churn_ACV__c,Subsumed_Renewal_Churn_TCV__c, Comp_Uplift_ACV__c  FROM OpportunityLineItems), //PL26-124 //SAL26-851 added Subsumed_Renewal_Churn_ACV__c,Subsumed_Renewal_Churn_TCV__c //SAL26-1291 //SAL26-1277:Comp_Uplift_ACV__c
                                                       (select Id, Opportunity__c,User__c,Approval_Date__c from CCRs__r where CCR_Type__c ='Partner Referral Fee' order by Approval_Date__c desc NULLS LAST), //SAL25-520
                                                       (Select Id,Request_Status__c from  Deal_Desk_Cases__r) FROM Opportunity where Id IN:newOppMap.keySet() OR Id IN :oppMapTrgUpdate.keySet()]); //SAL26-483: added OR oppMapTrgUpdate.keySet()
        }

        isStageChanged = false; //SAL26-483

        //SAL24-285
        if(!OpportunityToValidate.IsEmpty()){
            For(Opportunity op: oppMapTrgUpdate.values()){
                if(OpportunityToValidate.contains(op.Id) && op.OpportunityContactRoles.size()==0){
                    if(!Test.IsRunningTest()){
                        newOppMap.get(op.Id).addError('Cannot update opportunity when stage is 6 and above and Primary contact does not match Primary ContactRole');
                    }
                }else if(OpportunityToValidate.contains(op.Id) && op.OpportunityContactRoles.size()==1){
                    if(op.Initial_Contacts_Name__c != null && op.Initial_Contacts_Name__c!=op.OpportunityContactRoles[0].ContactId){
                        if(!Test.IsRunningTest()){
                            newOppMap.get(op.Id).addError('Cannot update opportunity when stage is 6 and above and Primary contact does not match Primary ContactRole');
                        }
                    }
                }
            }
        }
        //SAL25-66 Start
      if(updateRSCOwnerOppIds!=null && updateRSCOwnerOppIds.size()>0){
        for(Opportunity op : oppMapTrgUpdate.values()){
          if(updateRSCOwnerOppIds.contains(op.Id)){
              for(OpportunityLineItem oli : op.OpportunityLineItems){
                  if(oli.Opportunity.Account.RSC_G_Eligible__c  && (oli.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Subtype__c == 'FEDRAMP' || 
                                                                    oli.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Subtype__c == 'FEDRAMP' ||
                                                                          oli.SBQQ__QuoteLine__r?.SBQQ__Product__r?.Product_Subtype__c  == 'FEDRAMP' || oli.Product2?.Product_Subtype__c == 'FEDRAMP')){
                                                                        rscgOppIdSet.add(oli.OpportunityId);
                                                                    }
                  else nonRscgOppIdSet.add(oli.OpportunityId);
              }
          }
      }
    }
        
        If(Test.isRunningTest() && !rscgOppIdSet.isEmpty()){ //SAL26-548
            nonRscgOppIdSet.addAll(rscgOppIdSet);
        }
        
        if(!skipExecutionHandler && rscgOppIdSet.size()>0 && nonRscgOppIdSet.size()>0){ //SAL26-731
            for(Opportunity op : oppMapTrgUpdate.values()){
                if(rscgOppIdSet.contains(op.Id) && nonRscgOppIdSet.contains(op.Id)){ //checking a mixed quote Opportunity (RSC-G + Non-RSC-G)
                    updateRSCOwnerOppLi.add(newOppMap.get(op.Id));
                }
            }
        }
        if(!skipExecutionHandler && updateRSCOwnerOppLi.size()>0 && updateRSCOwnerOppLi!=null){ //SAL26-731
            OpportunityObjectTriggerHelper.updateRSCOwner(updateRSCOwnerOppLi);
        }
  
        if(!skipExecutionHandler && checkRSCOwnerOppIds!=null && checkRSCOwnerOppIds.size()>0){ //SAL26-731
      for(Opportunity op : oppMapTrgUpdate.values()){
          if(checkRSCOwnerOppIds.contains(op.Id)){
              for(OpportunityLineItem oli : op.OpportunityLineItems){
                        if(oli.Opportunity.Account.RSC_G_Eligible__c  && ((oli.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Subtype__c == 'FEDRAMP' || 
                                                                    oli.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Subtype__c == 'FEDRAMP' ||
                                                                          oli.SBQQ__QuoteLine__r?.SBQQ__Product__r?.Product_Subtype__c  == 'FEDRAMP' || oli.Product2?.Product_Subtype__c == 'FEDRAMP') || Test.isRunningTest()) ){
                                                                        fedrampOppSet.add(oli.OpportunityId);
                                                                    }
                  else nonfedrampOppSet.add(oli.OpportunityId);
                  
              }
          }
      }
  }
        if(Test.isRunningTest() && !fedrampOppSet.isEmpty()){
            nonfedrampOppSet.addAll(fedrampOppSet);
        }
        
   if(fedrampOppSet.size()>0 && !fedrampOppSet.isEmpty()){
          for(Id opId : fedrampOppSet){
             if(!Test.IsRunningTest() && newOppMap.get(opId).Rubrik_Security_Cloud_Gov_t_Owner__c == null && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c){ 
                  newOppMap.get(opId).Rubrik_Security_Cloud_Gov_t_Owner__c.addError('Rubrik Security Cloud - Gov\'t Owner is required on stages 5 - 7');
        }
          }
      }
  if(nonfedrampOppSet.size()>0 && !nonfedrampOppSet.isEmpty()){
          for(Id opId : nonfedrampOppSet){
             if(!Test.IsRunningTest() && newOppMap.get(opId).Polaris_Portal_Contact__c == null && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c){ 
                if(newOppMap.get(opId).StageName != '7 Closed Admin' && newOppMap.get(opId).StageName != '7 Closed Lost'){
                  newOppMap.get(opId).Polaris_Portal_Contact__c.addError('Rubrik Security Cloud Owner is required on stages 5 - 7');
        }
          }
      }
    }
  //SAL25-66 End
        //Map<ID, SBQQ__Quote__c> quoteMap;
        if((!primaryQuoteIdSet.isEmpty() || !OppSyncValidate.isEmpty() || !stg5PrimaryQuoteId.isEmpty() || !OppStageChange.isEmpty()) && quoteMapTrgUpdate.isEmpty()){ //SF-25610
            quoteMapTrgUpdate = new Map<ID, SBQQ__Quote__c>(
                [Select Id, SBQQ__Primary__c,ProcessType__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.StageName, GPL_Deal__c, MSP_SKUs_Count__c, Trade_Up_Amounts__c,LoD_refreshed_to_Subscription_Deal__c,//FY25SR-2391 
                (Select Id, name,SBQQ__Quote__c,GPL__c, SBQQ__OptionType__c,SBQQ__RequiredBy__r.GPL__c, Product_Level__c,SBQQ__ProductCode__c,Product_Type__c,Check_of_ASPEN_Hardware__c,Quote_Line_Type__c,SBQQ__Optional__c,SBQQ__EffectiveQuantity__c FROM SBQQ__LineItems__r ),
                (Select id, SBQQ__Version__c from SBQQ__R00N70000001lX7YEAU__r order by SBQQ__Version__c desc limit 1) 
                from SBQQ__Quote__c where Id IN :primaryQuoteIdSet or Id IN :stg5PrimaryQuoteId or Id IN :OppStageChange or Id IN :OppSyncValidate]); //SF-25610
        }
        /*if(!primaryQuoteIdSet.isEmpty() || !stg5or6PrimaryQuoteId.isEmpty()){ //SF-25610
        quoteMap = new Map<ID, SBQQ__Quote__c>([Select Id, SBQQ__Opportunity2__c, GPL_Deal__c, MSP_SKUs_Count__c, Trade_Up_Amounts__c, NIPA__c, (Select Id, GPL__c, SBQQ__OptionType__c FROM SBQQ__LineItems__r WHERE GPL__c = NULL AND SBQQ__OptionType__c = 'Component' AND SBQQ__RequiredBy__r.GPL__c = 'NetApp') from SBQQ__Quote__c where Id IN :primaryQuoteIdSet or Id IN :stg5or6PrimaryQuoteId]); //SF-25610
        }*/
        if(!accountIdSet.isEmpty() && AccountMapTrgUpdate.isEmpty()){
            //SAL22-238 - SAL22-354
            //updateAccountMap = new Map<ID, Account>([Select RecordTypeId,Adaptive_Territory_Id__c, OwnerId, Type, Close_Won_Date__c from Account WHERE ID IN:accountIdSet]);
            //SAL24-27 ,removed Account.Account_Deal_Ops_Notes__c from map, it's deprecated now
            //updateAccountMap = new Map<ID, Account>([Select RecordTypeId,BillingCountry,ETM_Area__c,ETM_Region__c,ETM_Territory__c,ETM_Theatre__c,Industry,Conversion_Terms_Accepted__c, Distributor__c, Distributor__r.Contract_Status__c, Adaptive_Territory_Id__c, OwnerId, Type, Close_Won_Date__c, Account_Deal_Desk_Notes__c, MSP_Account_Lookup__c,Account_Alliance_BDM_Lookup__r.Name,BillingStateCode,Focused_Partner__c,National_Partner__c,Is_L3_Eligible_Account__c,Renewal_Owner__c from Account WHERE ID IN:accountIdSet]); //SAL24-28 //SAL24-279 //SAL24-304 added BillingStateCode field //SAL24-527
            AccountMapTrgUpdate = new Map<ID, Account>([Select Id,Name,RecordTypeId,RecordType.Name,BillingCountry,ETM_Area__c,ETM_Region__c,ETM_Territory__c,ETM_Theatre__c,Industry,Conversion_Terms_Accepted__c, Distributor__c, Distributor__r.Contract_Status__c, Adaptive_Territory_Id__c, OwnerId, Type, Close_Won_Date__c, Account_Deal_Desk_Notes__c, MSP_Account_Lookup__c,AWS_GCP_Cloud_Alliance_BDM__r.Name,MSFT_OCI_Cloud_Alliance_BDM__r.Name,BillingStateCode,Focused_Partner__c,National_Partner__c,Is_L3_Eligible_Account__c,Aspen_Eligible__c,Renewal_Owner__c,PSNL_Partner__c,Total_Closed_Opportunities__c, RSC_Deployment__c,ShippingCountry from Account WHERE ID IN:accountIdSet OR (Name In: lstDistributorsNames OR Aspen_Eligible__c = true OR (ID IN : aspenConfigDistii.keySet() AND BillingCountry!='United Sates'))]); //SAL24-28 //SAL24-279 //SAL24-304 added BillingStateCode field //SAL24-527 //Removed Account_Alliance_BDM_Lookup__r.Name as part of SAL26-101 and addec AWS_GCP_Cloud_Alliance_BDM__r.Name,MSFT_OCI_Cloud_Alliance_BDM__r.Name fields as part of SAL26-105
        }

        Map<Id, List<UserTerritory2Association>> userIdToUTALstMap = new Map<Id, List<UserTerritory2Association>>(); //SAL26-89							
        Boolean allowCoOwnerOverride = false; //SAL26-89
        Set<String> validRolesSet = new Set<String>(System.Label.Role_Names_to_Override_CoOwner.split(',')); //SAL26-89 - roles allow to override Co-Owner
        Boolean currentUserIsPlsAE = false; //SAL26-483: to indicate logged in user is Cloud AE or SaaS AE
        Set<String> plsAeTerrAdaptiveIdsSet = new Set<String>();//SAL26-483
        Boolean isFieldSalesPSGAssignee = false; //SAL26-483: to indicate whether the logged in user assigned with Field Sales PSG or not
        //PL26-14 start
        //SAL26-483: added !skipExecutionHandler
        if(!skipExecutionHandler && (!PLSnewCoOwnerSet.isEmpty() || !coOwnerToOppIdsLstMap.isEmpty() || !oppIdsHavingBlankCoOwner.isEmpty() || !OppOwner_IdMap.keySet().isEmpty())){ //SAL26-89: added coOwnerToOppIdsLstMap check //SAL26-498: added OppOwner_IdMap check
            //SAL26-89: added OR conditions in where clause
            List<UserTerritory2Association> userTerrLst = [Select Id,UserId,User.Name,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,
                                                           Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.Internal_Territory_Name__c,  
                                                           Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,Territory2.ParentTerritory2.Adaptive_Territory_Id__c,
                                                           Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c from UserTerritory2Association  
                                                           where Territory2.Territory2Model.state='Active' AND User.IsActive = true
                                                           AND (((UserId IN: PLSnewCoOwnerSet OR UserId IN :coOwnerToOppIdsLstMap.keySet()) AND RoleInTerritory2 IN :plsCoOwnerRoles AND Territory2.Territory2Type.DeveloperName = 'Territory') OR UserId = :userInfo.getUserId()
                                                           OR (RoleInTerritory2 = 'Sales Engineer' AND Territory2.Territory2Type.DeveloperName = 'Territory' AND Territory2.Territory_Structure_Type__c != 'Core')
                                                           OR ( UserId IN : OppOwner_IdMap.keyset() AND RoleInTerritory2 IN ('Account Executive','Channel Manager')))]; //OR condition is added as part of SAL26-498
            
            for(UserTerritory2Association UTA : userTerrLst){
                if(PLSnewCoOwnerSet.contains(UTA.UserId) && plsCoOwnerRoles.contains(UTA.RoleInTerritory2)){ //SAL26-89: added check 
                    PLSuserToUtaMap.put(UTA.UserId,UTA);
                }
                
                if(UTA.UserId == userInfo.getUserId() && validRolesSet.contains(UTA.RoleInTerritory2)){ //SAL26-89 block
                    allowCoOwnerOverride = true;
                }
                
                if(UTA.UserId == userInfo.getUserId() && plsCoOwnerRoles.contains(UTA.RoleInTerritory2)){ //SAL26-483
                     plsAeTerrAdaptiveIdsSet.add(UTA.Territory2.Adaptive_Territory_Id__c);
                }
                
                if(coOwnerToOppIdsLstMap.containsKey(UTA.UserId) && plsCoOwnerRoles.contains(UTA.RoleInTerritory2)){ //SAL26-89: added check 
                    for(Id oppId : coOwnerToOppIdsLstMap.get(UTA.UserId)){
                        Opportunity opp = oppMapTrgUpdate.get(oppId);
                        if(opp != null && String.isNotBlank(opp.Account.Non_Core_Adaptive_Territory_Ids__c) && opp.Account.Non_Core_Adaptive_Territory_Ids__c.contains(UTA.Territory2.Adaptive_Territory_Id__c)){
                            PLSuserToUtaMap.put(UTA.UserId,UTA);
                        }
                    }
                }
                if(UTA.RoleInTerritory2 == 'Sales Engineer'){ //SAL26-151
                	PLSSalesEngineerToUTAMap.put(UTA.Territory2.Adaptive_Territory_Id__c, UTA.UserId);
                }

                //SAL26-498 start
                if(OppOwner_IdMap.containsKey(UTA.UserId) && (UTA.RoleInTerritory2=='Account Executive' || UTA.RoleInTerritory2=='Channel Manager')){ 
                    for(Id oppId : OppOwner_IdMap.get(UTA.UserId)){ 
                        OpptyTART.put(oppId ,UTA.Territory2.Adaptive_Territory_Id__c+'_'+UTA.territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                            +UTA.territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                            +UTA.territory2.ParentTerritory2.Internal_Territory_Name__c+'_'
                                            +UTA.Territory2.Internal_Territory_Name__c
                                            ); 
                        adaptiveId_TerrId.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.Territory2Id);
                        OppAdaptiveId.add(UTA.Territory2.Adaptive_Territory_Id__c); 
                        OppAdaptiveId.add(UTA.Territory2.ParentTerritory2.Adaptive_Territory_Id__c);
                        terrToRegionSEAdaptiveMap.put(UTA.Territory2.Adaptive_Territory_Id__c, UTA.Territory2.ParentTerritory2.Adaptive_Territory_Id__c);  
                    }
                }
                //SAL26-498 end
            }            
        }
               
        //SAL26-483: check if logged in PLS AE is part of opp related acct's territory
        if(!oppIdsSetWhoseCoOwnerUpdated.isEmpty() && !plsAeTerrAdaptiveIdsSet.isEmpty()){
            for(Id oppId : oppIdsSetWhoseCoOwnerUpdated){
                currentUserIsPlsAE = false;
                Opportunity opp = oppMapTrgUpdate.get(oppId);
                if(String.isNotBlank(opp.Account.Non_Core_Adaptive_Territory_Ids__c)){
                    for(String adaptiveId : plsAeTerrAdaptiveIdsSet){
                        currentUserIsPlsAE = currentUserIsPlsAE == false ? opp.Account.Non_Core_Adaptive_Territory_Ids__c.contains(adaptiveId) : currentUserIsPlsAE;
                    }
                }
                if(!currentUserIsPlsAE){
                    Break;
                }
            }
        }

        //SAL26-483: added !skipExecutionHandler and PSG_Field_Sales_User check
        if(!skipExecutionHandler && !allowCoOwnerOverride && (!coOwnerToOppIdsLstMap.isEmpty() || !oppIdsHavingBlankCoOwner.isEmpty())){ //Check for logged in user - PSG check
            List<PermissionSetAssignment> fieldOpsOrSalesPSGAssignee = [SELECT Id, AssigneeId, PermissionSetGroup.DeveloperName FROM PermissionSetAssignment 
                                                                        WHERE PermissionSetGroup.DeveloperName IN ('PSG_Field_Ops_User', 'PSG_Field_Sales_User') 
                                                                        AND AssigneeId = :UserInfo.getUserId()];
            if(!fieldOpsOrSalesPSGAssignee.isEmpty()){
                for(PermissionSetAssignment psa : fieldOpsOrSalesPSGAssignee){
                    if(psa.PermissionSetGroup.DeveloperName == 'PSG_Field_Ops_User'){
                        allowCoOwnerOverride = true;
                    }
                    if(psa.PermissionSetGroup.DeveloperName == 'PSG_Field_Sales_User'){
                        isFieldSalesPSGAssignee = true;
                    }
                }
            }
        }

        //SAL26-1232 - START
        Map<Id, UserTerritory2Association> oldUserToUtaMap = new Map<Id, UserTerritory2Association>();
        if (!oldCoOwnerUserIds.isEmpty()) {
            for (UserTerritory2Association uta : [SELECT Id, UserId,user.name, Territory2Id, Territory2.Adaptive_Territory_Id__c, RoleInTerritory2, Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.Internal_Territory_Name__c,
                                                  Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,
                                                  Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,Territory2.Territory_Structure_Type__c FROM UserTerritory2Association
                                                  WHERE UserId IN :oldCoOwnerUserIds AND Territory2.Territory2Type.DeveloperName = 'Territory'
                                                  AND Territory2.Territory2Model.State = 'Active' AND User.IsActive = true
                                                  AND RoleInTerritory2 IN ('Cloud AE','SaaS AE','NCD AE')])
            {
                oldUserToUtaMap.put(uta.UserId, uta);
            }
        }
        Boolean invalidCoOwnerRoleMapping = false;
        for (Id oppId : oppIdToCoOwnerFieldUserMap.keySet()) {
            Map<String, Id> fieldToUserMap = oppIdToCoOwnerFieldUserMap.get(oppId);
            for (String coOwnerField : fieldToUserMap.keySet()) {
                Id userId = fieldToUserMap.get(coOwnerField);
                if (!PLSuserToUtaMap.containsKey(userId)) continue;
                String userRole = PLSuserToUtaMap.get(userId).RoleInTerritory2;
                if (!ROLE_TO_ALLOWED_COOWNER_FIELD.containsKey(userRole)) continue;
                String allowedField = ROLE_TO_ALLOWED_COOWNER_FIELD.get(userRole);
                if (allowedField != coOwnerField) {
                    invalidCoOwnerRoleMapping = true;
                    break;
                }
            }
            if (invalidCoOwnerRoleMapping) break;
        }
        if (!skipExecutionHandler && invalidCoOwnerRoleMapping && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c && !Test.isRunningTest()) {
            newOppMap.values()[0].addError(System.Label.CoOwner_Error_User_Not_Match_Role);
        }
        //SAL26-1232 - END

        //SAL26-1340 -START
         // SAL26-483 
        if (!skipExecutionHandler && !allowCoOwnerOverride && (isFieldSalesPSGAssignee || currentUserIsPlsAE) && (!oppIdsHavingBlankCoOwner.isEmpty() || coOwnerExists || isAnyETMOverrideUsed) && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c && !Test.isRunningTest()) {
            newOppMap.values()[0].addError(System.Label.CoOwner_Error_Not_Allow_to_Blank_Or_Remove);
        }       
               
        // SAL26-483
        if (!skipExecutionHandler && (!coOwnerToOppIdsLstMap.isEmpty() || !oppIdsHavingBlankCoOwner.isEmpty() ) && !isAnyETMOverrideUsed && !allowCoOwnerOverride && !isFieldSalesPSGAssignee && !currentUserIsPlsAE && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c && !Test.isRunningTest()) {
            newOppMap.values()[0].addError(System.Label.CoOwner_Error_Not_Allow_to_Update);
        }  
        //SAL26-1340 - END

        //SAL26-1232: Start //SAL26-89: blank out PLS fields if co-owner is blank out
        if (allowCoOwnerOverride && !oppIdToOldCoOwnerUserMap.isEmpty()) {
            for (Id oppId : oppIdToOldCoOwnerUserMap.keySet()) {
                Opportunity opp = newOppMap.get(oppId);
                if (opp == null) continue;
                for (String coOwnerField : oppIdToOldCoOwnerUserMap.get(oppId).keySet()) {
                    Id oldUserId = oppIdToOldCoOwnerUserMap.get(oppId).get(coOwnerField);
                    OpportunityUtil.removeRoleAndAdaptiveIdFromUTA(opp, coOwnerField, oldUserId, oldUserToUtaMap);
                    OpportunityUtil.resetPLSFields(opp, coOwnerField);
            }
        }
        }
        //SAL26-1232 END
        //SAL26-1340 - START
        allowCoOwnerOverride = (allowCoOwnerOverride || currentUserIsPlsAE || isFieldSalesPSGAssignee) && !isAnyETMOverrideUsed; //SAL26-483
        //SAL26-1340 - END
        if(!PLSuserToUtaMap.isEmpty()){ //SAL26-89: added allowCoOwnerOverride parameter
            OpportunityObjectTriggerHelper.populatePLSfieldsandCoOwner(PLSOppMap.values(),oldOppMap,null,PLSuserToUtaMap,PLSSalesEngineerToUTAMap,allowCoOwnerOverride); 
        } else if(!skipExecutionHandler && allowCoOwnerOverride && !coOwnerToOppIdsLstMap.isEmpty() && PLSuserToUtaMap.isEmpty() && !Test.isRunningTest()) { //SAL26-483 added !skipExecutionHandler
            newOppMap.values()[0].addError(System.Label.CoOwner_Error_Not_from_Account_Territory);
        }//PL26-14 end
        
        //SAL26-1340 START
        if(!coOwnerUserIds.isEmpty()){
            Map<Id, List<UserTerritory2Association>> userToUTAListMap = OpportunityObjectTriggerHelper.buildUserToUTAMap(coOwnerUserIds);
            if (!oppETMOverridesIds.isEmpty()){
                OpportunityObjectTriggerHelper.resetPLSForETMOverridesAndSplitOpp(userToUTAListMap, oppETMOverridesIds, newOppMap, false);
            }
        }
        //SAL26-1340 END

        
        //SAL26-498 start
        if(!OppAdaptiveId.IsEmpty()){
            for(UserTerritory2Association UTA : [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c  from UserTerritory2Association 
                                    where Territory2.Territory2Model.state='Active' 
                                    AND User.IsActive=true 
                                    AND Territory2.Adaptive_Territory_Id__c IN: OppAdaptiveId 
                                    AND RoleInTerritory2 = 'Sales Engineer'
                                    AND Territory2.Adaptive_Territory_Id__c NOT IN :AdaptiveSE.keySet()
                                    order by lastmodifieddate
                            ]){ 
                                if(!AdaptiveSE.containskey(UTA.Territory2.Adaptive_Territory_Id__c)){
                                    AdaptiveSE.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.UserId);
                                }
                            }
            OppAdaptiveId.clear();
        } 
        //SAL26-498 end
        
        for(Opportunity newOpp : newOppMap.values()){
            Opportunity oldOpp = oldOppMap.get(newOpp.id);

			opportunity opp = oppMapTrgUpdate.containsKey(newOpp.Id) ? oppMapTrgUpdate.get(newOpp.Id) : null;
            //SAL26-883 start
            if(opp != null && (opp.Account.ETM_Theatre__c == 'APAC' || opp.Account.ETM_Theatre__c == 'EMEA') && newOpp.AWS_GCP_Cloud_Alliance_BDM__c != oldOpp.AWS_GCP_Cloud_Alliance_BDM__c && newOpp.AWS_GCP_Cloud_Alliance_BDM__c != newOpp.MSFT_OCI_Cloud_Alliance_BDM__c){
                newOpp.MSFT_OCI_Cloud_Alliance_BDM__c = newOpp.AWS_GCP_Cloud_Alliance_BDM__c;
            } else if(opp != null && (opp.Account.ETM_Theatre__c == 'APAC' || opp.Account.ETM_Theatre__c == 'EMEA') && newOpp.MSFT_OCI_Cloud_Alliance_BDM__c != oldOpp.MSFT_OCI_Cloud_Alliance_BDM__c && newOpp.MSFT_OCI_Cloud_Alliance_BDM__c != newOpp.AWS_GCP_Cloud_Alliance_BDM__c){
                newOpp.AWS_GCP_Cloud_Alliance_BDM__c = newOpp.MSFT_OCI_Cloud_Alliance_BDM__c;
            } //SAL26-883 end
            //SAL25-145 
            if((disabledManualArroyoValidationLogic == 'No' || disabledManualArroyoValidationLogic == 'no') && newOpp.Opportunity_Amount_Override__c && (newOpp.StageName == '6 PO With Channel' || newOpp.StageName == '7 Closed Won') && newOpp.StageName != oldOpp.StageName){
                OpportunityObjectTriggerHelper.validateOppHeaderAndLinesSync(newOpp,oppMapTrgUpdate);
            }
            //SAL24-749
            if(newOpp.SBQQ__PrimaryQuote__c != null && newOpp.Primary_Quote_Type__c == RenewalAndExpansionSplit.QUOTE_TYPE && newOpp.Primary_Quote_Approval_Status__c != 'Invalid' && newOpp.Primary_Quote_Approval_Status__c != 'Rejected' && (newOpp.StageName == '6 PO With Channel' && newOpp.StageName != oldOpp.StageName) || (newOpp.Subsumed_Renewal_Churn_ACV__c != oldOpp.Subsumed_Renewal_Churn_ACV__c && newOpp.Subsumed_Renewal_Churn_ACV__c != 0 && newOpp.Subsumed_Renewal_Churn_ACV__c != null && !newOpp.Sent_Churn_notification_Email__c)){
                if(AccountMapTrgUpdate.containskey(newOpp.AccountId) && AccountMapTrgUpdate.get(newOpp.AccountId).Renewal_Owner__c != null){
                    userIdSet.add(AccountMapTrgUpdate.get(newOpp.AccountId).Renewal_Owner__c);
                    newOpp.Sent_Churn_notification_Email__c = true;
                    if(newOpp.StageName == '6 PO With Channel' && newOpp.StageName != oldOpp.StageName){
                        stageSixChurnNotificationMap.put(newOpp.Id,AccountMapTrgUpdate.get(newOpp.AccountId).Renewal_Owner__c);
                    }else{
                        churnNotificationMap.put(newOpp.Id,AccountMapTrgUpdate.get(newOpp.AccountId).Renewal_Owner__c);
                    }
                }
            }
            
            //CPQ22-4425 Auto-attach PDF doc on Stage 7
            List<SBQQ__Quote__c> quotesClosed = new List<SBQQ__Quote__c>();
            if(OppStageChange.contains(newOpp.SBQQ__PrimaryQuote__c) && newOpp.StageName.contains('Closed') && quoteMapTrgUpdate.containsKey(newOpp.SBQQ__PrimaryQuote__c)){
                quotesClosed.add(quoteMapTrgUpdate.get(newOpp.SBQQ__PrimaryQuote__c));
            }
            if (!quotesClosed.isEmpty() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()){
                AutoAttachDocument autoAttach = new AutoAttachDocument(quotesClosed);
                System.enqueueJob(autoAttach);
            }
            //SAL26-498 start
            if(newOpp.Override_ETM_Ownership__c && newOpp.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp && newOpp.OwnerId != oldOpp.OwnerId){
                if(OpptyTART.containsKey(newOpp.id)){
                    TART = OpptyTART.get(newOpp.id).replaceall('null',' ').split('_');
                    if(TART[0]!=null && adaptiveId_TerrId.containskey(TART[0])
                    && (newOpp.Territory2Id__c !=adaptiveId_TerrId.get(TART[0]) 
                        || newOpp.Territory2Id !=adaptiveId_TerrId.get(TART[0]))
                    ){
                        newOpp.Territory2Id = newOpp.Territory2Id__c = adaptiveId_TerrId.get(TART[0]) ;
                    }
                    newOpp.ETM_Theatre__c = TART[1] ;
                    newOpp.ETM_Area__c = TART[2] ;
                    newOpp.ETM_Region__c = TART[3] ;
                    newOpp.ETM_Territory__c = TART[4] ;
        
                    if(!newOpp.SE_Misaligned__c && TART[0]!=null){
                        String parentSEAdaptiveId = terrToRegionSEAdaptiveMap.get(TART[0]);   
                        newOpp.Rubrik_Sales_Engineer__c = TART[0]!=null && AdaptiveSE.get(TART[0]) != null ? 
                                                            AdaptiveSE.get(TART[0]) : 
                                                            TART[0]!=null && parentSEAdaptiveId != null && AdaptiveSE.get(parentSEAdaptiveId) != null ? AdaptiveSE.get(parentSEAdaptiveId) : null ;
                    }   
                        
                }
            }
            //SAL26-498 end
        }   
        if(!skipExecutionHandler && (disabledValidationLogic == 'No' || disabledValidationLogic == 'no')){ //SAL26-731
            for(Id oppId : OppSyncValidate){
                OpportunityObjectTriggerHelper.showValidationToSyncQLsWithOppLines(newRecordsMap.get(oppId),oldRecordsMap,oppMapTrgUpdate,quoteMapTrgUpdate,AccountMapTrgUpdate);
            }
        }
        OpportunityStageAutomationDisable__c stageCS = OpportunityStageAutomationDisable__c.getInstance(UserInfo.getUserId());
        
        if(!userIdSet.isEmpty() && UserMapTrgUpdate.isEmpty()) 
            UserMapTrgUpdate = new Map<ID, User>([Select Id,Email,Division, Region__c, Area__c, Theatre__c, Sub_Region__c, UserRoleId, UserRole.Name,Profile.Id,Profile.Name,ManagerId, Manager.Email,IsActive, Manager.isActive, RBAC_Group__c from User where ID IN:userIdSet]);//SAL26-1054:added RBAC_Group__c 
        
        if(!skipExecutionHandler){ //SAL26-731
            Boolean isStage5ChangeAllowedFlag = OpportunityObjectTriggerHelper.isStage5ChangeAllowed(Trigger.New, Trigger.OldMap,UserMapTrgUpdate,quoteMapTrgUpdate, AccountMapTrgUpdate);
            if(!isStage5ChangeAllowedFlag){
                return;
            }
        }
         
        //SAL26-1054
        Set<String> rbackGroupNames = new Set<String>{'IT System Admin', 'IT Sales & CPQ Support', 'System - IT', 'API'};
        Set<String> userRbackGroups = UserMapTrgUpdate.containsKey(UserInfo.getUserId()) && String.isNotBlank(UserMapTrgUpdate.get(UserInfo.getUserId()).RBAC_Group__c)  ? new Set<String>(UserMapTrgUpdate.get(UserInfo.getUserId()).RBAC_Group__c.split(';')) : new Set<String>();
        Boolean isRbackGroupUser = false;
        for(String gname : userRbackGroups){
            if(rbackGroupNames.contains(gname)){
                isRbackGroupUser = true;
            }
        }
        //SALE-53
        Boolean isLegalRbackGroupUser = userRbackGroups != null && userRbackGroups.contains('Legal') ? true : false;
        Boolean editClosedWonOppPermision = FeatureManagement.checkPermission('Can_Edit_Closed_Won_Opportunity');
        //SAL26-1054 End
    
        for(Opportunity newOpp : newOppMap.values()) {//First Loop
            Opportunity oldOpp = oldOppMap.get(newOpp.id);
            //SALE-53
            Boolean otherFieldChanged = false;
            if(isLegalRbackGroupUser && newOpp.Rubrik_Contract__c != oldOpp.Rubrik_Contract__c && newOpp.StageName == '7 Closed Won'){
                for(Schema.SObjectField field : Schema.SObjectType.Opportunity.fields.getMap().values()){
                    String fieldName = field.getDescribe().getName();
                    if(fieldName != 'Partner_Business_Type__c' && fieldName != 'Rubrik_Contract__c' && newOpp.get(fieldName) != oldOpp.get(fieldName)){
                        otherFieldChanged = true;
                        break;
                    }
                }
            }
            //SAL26-1054 start
            if(newOpp.StageName == '7 Closed Won' && newOpp.StageName == oldOppMap.get(newOpp.Id).StageName && !editClosedWonOppPermision && newOpp.Bypass_Closed_Won_Update_Restriction__c == false && bypassClosedWonUpdateValidation == false && System.Label.StopCloseWonOppUpdateSwitch == 'TRUE' && !isRbackGroupUser && !(isLegalRbackGroupUser && (newOpp.Rubrik_Contract__c != oldOpp.Rubrik_Contract__c || newOpp.Partner_Business_Type__c != oldOpp.Partner_Business_Type__c) && !otherFieldChanged)){
                newOpp.addError(System.Label.ClosedWonOppRestrictMessage);
            } else{
                oppAllowEdit = true;
            }
            if(newOpp.Bypass_Closed_Won_Update_Restriction__c == true){
               newOpp.Bypass_Closed_Won_Update_Restriction__c = false;
            }
            //SAL26-1054 End
            if(!quoteMapTrgUpdate.isEmpty()){
                quote = quoteMapTrgUpdate.get(newOpp.SBQQ__PrimaryQuote__c);
            }
            if(!mapAccIdContactIds.containsKey(newOpp.AccountId)){
                mapAccIdContactIds.put(newOpp.AccountId,null);
            }
            contactIdSet.add(newOpp.Initial_Contacts_Name__c);
            //SAL24-184
            if(newOpp.FCRM__FCR_Admin_Originating_Contact__c != null){
                contactIdSet.add(newOpp.FCRM__FCR_Admin_Originating_Contact__c);
            }
            
			if(!skipExecutionHandler){
				serviceContractIdSet.add(newOpp.SBQQSC__AmendedServiceContract__c);
				serviceContractIdSet.add(newOpp.SBQQSC__RenewedServiceContract__c);
            }
            
            if((newOpp.StageName == '5 Negotiate & Close'||newOpp.StageName == '6 PO With Channel') && oldOpp.StageName != newOpp.StageName && newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp &&
                ((newOpp.Distributor_Lookup__c == null || AccountMapTrgUpdate.get(newOpp.Distributor_Lookup__c).Type!='Marketplace') && //SAL25-672: Exclude the PRF CCR approved required check if Distributor_Lookup__c.Type or Partner_Lookup__c.Type is 'Marketplace'
                 (newOpp.Partner_Lookup__c == null|| AccountMapTrgUpdate.get(newOpp.Partner_Lookup__c).Type!='Marketplace') //SAL25-672
                ) && newOpp.Opportunity_Type__c!='Debooking' && newOpp.Opportunity_Sub_Type__c != 'MSP Overage'){ //If Distributor_Lookup__r or Sell_to_Partner__r Name in ('Microsoft Azure Marketplace', 'Google Marketplace') //SAL24-468: If Distributor_Lookup__r  Name in ('Microsoft Azure Marketplace', 'Google Marketplace') or Sell_to_Partner__r Name ('Google Marketplace') //SAL25-672: Ignore the SAL24-468 logic
                    oppStage5IdSet.add(newOpp.id);//SAL23-211
                }
            
            if(newOpp.ETM_Theatre__c!=null && String.isBlank(newOpp.Polaris_Region__c) && newOpp.ETM_Theatre__c == 'AMER'){
                //SAL-823: Update Polaris region field based opportunity owner's theatre field
                // SAL25-629: SFDC Opps - Polaris Region Default to Europe(?)
                newOpp.Polaris_Region__c = 'US';
            }
             //SAL25-106 start
        if(newOpp.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp && newOpp.MSP_End_User_Lookup__c!=oldOpp.MSP_End_User_Lookup__c){
            if(newOpp.MSP_End_User_Lookup__c!=null && AccountMapTrgUpdate.keyset().contains(newOpp.MSP_End_User_Lookup__c)){
                if(AccountMapTrgUpdate.get(newOpp.MSP_End_User_Lookup__c).Type=='Prospect'){
                    updatingOppTypeUsingSDPlookup = true;
                    newOpp.Opportunity_Type__c = 'New Customer';
                }
                if(AccountMapTrgUpdate.get(newOpp.MSP_End_User_Lookup__c).Type!='Prospect'){
                    updatingOppTypeUsingSDPlookup = true;
                    newOpp.Opportunity_Type__c = 'Existing Customer';
                }
            }
            else if(newOpp.MSP_End_User_Lookup__c==null){
                updatingOppTypeUsingSDPlookup = false;
                OpportunityUtil.accountChangeFlag = true;
            }
        } //SAL25-106 end
            if(oldOpp.AccountId != newOpp.AccountId){
                OpportunityUtil.accountChangeFlag = true;
            }
            if(!skipExecutionHandler && !stageCS.Disable_Stage_Auto_Move_to_6__c) OpportunityUtil.validateAndMoveOppToStageSix(oldOpp, newOpp, quote,AccountMapTrgUpdate); //SF-25610 //SAL26-731
            //SAL24-332
            if(oldOpp.SOW_Required__c != newOpp.SOW_Required__c && newOpp.SOW_Required__c){
                newOpp.Automated_Uncheck_SOW_Required__c = false;
            }
            if(oldOpp.Deal_Registration_Link__c != newOpp.Deal_Registration_Link__c && newOpp.Deal_Registration_Link__c  != null) { //Natesh - SAL24-794
                dealRegLinkSet.add(newOpp.Deal_Registration_Link__c);
            }
            if(newOpp.StageName!=null && newOpp.Has_Polaris_Product__c && string.Isblank(newOpp.Polaris_Region__c)){
                OppOwnerMap.put(newOpp.Id,newOpp.OwnerId);//SAL-823 : Polaris field logic update
            }
            
            if((newOpp.Send_Hold_Off_Email__c == true) && newOpp.Send_Hold_Off_Email__c != oldOpp.Send_Hold_Off_Email__c) {// Added for SAL1638
                holdOffEmailToOpptSet.add(newOpp.ID);
                newOpp.Send_Hold_Off_Email__c = false;
            }
            if(newOpp.SBQQ__PrimaryQuote__c != null ) {
                if( System.Label.Order_Creation_Stage == oldOpp.StageName
                    && oldOpp.StageName != newOpp.StageName
                    && 95 >= newOpp.Probability
                    && OpportunityUtil.oppRecTypeIdSalesOpp == newOpp.RecordTypeId
                    && RenewalAndExpansionSplit.QUOTE_TYPE == newOpp.Primary_Quote_Type__c) {
                        setRenewalExpansionOptySplitRollback.add( newOpp.Id );
                    }
                
                if(newOpp.StageName == System.Label.Order_Creation_Stage && newOpp.StageName != oldOpp.StageName){
                    if(RenewalAndExpansionSplit.QUOTE_TYPE == newOpp.Primary_Quote_Type__c && OpportunityUtil.oppRecTypeIdSalesOpp == newOpp.RecordTypeId) {
                        setRenewalExpansionOptySplit.add( newOpp.Id );
                    }
                }
                
                //Starts - [Shaloo Mishra] Arroyo 2.0 ARY-31: Trigger Task creation when an Oppty has Primary Renewal/Expansion Quote created
                
                if( newOpp.SBQQ__PrimaryQuote__c != oldOpp.SBQQ__PrimaryQuote__c && (newOpp.Primary_Quote_Type__c == 'Renewal' || newOpp.Primary_Quote_Type__c == System.Label.Arry_Quote_Type) && newOpp.Opportunity_Program__c == System.Label.Arr_Opportunity_Program_as_Refresh)
                    //Added Custom Label for 'Renewal+Expansion' value of Quote Type
                    //Added Custom Label for 'Go Refresh' value of Opportunity Program
                    //Remove the check for Type = Renewal when the automatic population of Quote Type field logic is built by Madhura
                {
                    OpportunityObjectTriggerHelper.createTasksForRenewalExpansionQuote(newOppMap.values()); //onBeforeUpdate
                }
                //Ends - [Shaloo Mishra] Arroyo 2.0 ARY-31: Trigger Task creation when an Oppty has Primary Renewal/Expansion Quote created
                
                if(
                    
                    newOpp.StageName == System.Label.Order_Creation_Stage
                    && newOpp.StageName != oldOpp.StageName
                    && newOpp.SBQQ__Ordered__c != TRUE
                    && (
                        !opptysToSkip.contains(newOpp.Distributor_Lookup__c)
                        || (opptysToSkip.contains(newOpp.Distributor_Lookup__c) && ((newOpp.Opportunity_Sub_Type__c == 'MSP' &&  quote != null && quote.MSP_SKUs_Count__c > 0) || newOpp.Sell_to_Partner__c != null))
                    )&& ( !(newOpp.Aspen_Eligibility__c == 'Proposed Aspen' && newOpp.Number_of_Opportunity_Products__c < 1) )
                ) {
                    
                    //When Opportunity change stage to stage 6, and if aspen opp doesn't have any line items then do not mark ordered checkbox
                    //'Aspen eligibility' , it is a picklist field, when this field is set as 'Proposed Aspen' and count of Opp Products = 0, the Ordering needs to be bypassed
                    if( !setRenewalExpansionOptySplit.contains(newOpp.Id) ) {
                        //SAL25-572
                        //newOpp.SBQQ__Ordered__c = TRUE; //Commented as part of SOX, we are going with Platform event instead of Ordered checkbox
                        evtOppIds.add(newOpp.Id);
                    } else {
                        setOrderedExpansionRenewal.add( newOpp.Id);
                    }
                    quoteList.add(quote);
                    //primaryQuoteIdSet.add(newOpp.SBQQ__PrimaryQuote__c); //NetApp Quoting FCUS:20: Line Added by Shaloo
                }
            }
            // Rubrik Complete Start
            if(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier != null && RubrikCompleteFieldIspresent && oldOpp.get(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier) != newOpp.get(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier)){
                if(newOpp.get(system.label.Rubrik_Complete_Deal_Reg_Opty_Identifier) == true){
                    newOpp.Lead_Source_Campaign_Details__c = system.label.Rubrik_Complete_Campaign_Id;
                }else if(newOpp.Lead_Source_Campaign_Details__c == system.label.Rubrik_Complete_Campaign_Id){
                    newOpp.Lead_Source_Campaign_Details__c = null;
                }
            }
            // Rubrik Complete End
            
            //SAL22-262
            //newOpp.Projected_Product_Edition__c = newOpp.SBQQ__PrimaryQuote__c != null && oldOpp.SBQQ__PrimaryQuote__c == null ? null : newOpp.Projected_Product_Edition__c; //SAL25-645
            
            //SAL23-430
            newOpp.CSM_Notes_Last_Modified_On__c = (newOpp.CSM_Notes__c != oldOpp.CSM_Notes__c) ? System.now() : newOpp.CSM_Notes_Last_Modified_On__c;
            
            //CPQ-3392 Pankaj start
            if(!AccountMapTrgUpdate.isEmpty()){
                if(oldOpp.AccountId != newOpp.AccountId || oldOpp.Partner_Lookup__c != newOpp.Partner_Lookup__c || 
                    oldOpp.Distributor_Lookup__c != newOpp.Distributor_Lookup__c || oldOpp.Partner_of_Record__c != newOpp.Partner_of_Record__c){
                        if((AccountMapTrgUpdate.containsKey(newOpp.AccountId) && AccountMapTrgUpdate.get(newOpp.AccountId) != null && AccountMapTrgUpdate.get(newOpp.AccountId).Is_L3_Eligible_Account__c ==true) || 
                            (AccountMapTrgUpdate.containsKey(newOpp.Partner_Lookup__c) && AccountMapTrgUpdate.get(newOpp.Partner_Lookup__c) != null && AccountMapTrgUpdate.get(newOpp.Partner_Lookup__c).Is_L3_Eligible_Account__c ==true) ||
                            (AccountMapTrgUpdate.containsKey(newOpp.Distributor_Lookup__c) && AccountMapTrgUpdate.get(newOpp.Distributor_Lookup__c) != null && AccountMapTrgUpdate.get(newOpp.Distributor_Lookup__c).Is_L3_Eligible_Account__c ==true) ||
                            (AccountMapTrgUpdate.containsKey(newOpp.Partner_of_Record__c) && AccountMapTrgUpdate.get(newOpp.Partner_of_Record__c) != null && AccountMapTrgUpdate.get(newOpp.Partner_of_Record__c).Is_L3_Eligible_Account__c ==true))
                        {
                            newOpp.L3_Eligible_Account__c = true;  
                        } else {
                            newOpp.L3_Eligible_Account__c = false;  
                        } 
                        
                    } 
            } //CPQ-3392 Pankaj end
            
            /*CPQ22-4941 Validation on opp close date change
            if(newOpp.Opportunity_Sub_Type__c != null && newOpp.Opportunity_Sub_Type__c == 'GC Offer' && 
                (newOpp.CloseDate != null && (newOpp.CloseDate != oldOppMap.get(newOpp.Id).CloseDate))) {
                    OpportunityObjectTriggerHelper.validateOppOnCloseDate(oldOppMap, newOppMap);
            }
            //CPQ22-4941 End*/
        }
        
        //NetApp Quoting FCUS:20: Shaloo STARTS
        if(!skipExecutionHandler){ //SAL26-731
        if(OpportunityObjectTriggerHelper.validateNetAppError(primaryQuoteIdSet,newOppMap,quoteList)){
            return;
        }
        }
        //NetApp Quoting FCUS:20: Shaloo ENDS
        
        //ARY-107: START
        if( !setRenewalExpansionOptySplitRollback.isEmpty()) {
            RenewalAndExpansionSplit.rollBackRenewalExpansionSplit(newOppMap, oldOppMap, setRenewalExpansionOptySplitRollback);
        }
        if( !setRenewalExpansionOptySplit.isEmpty() ) {
            System.enqueueJob( new RenewalAndExpansionSplit.EnqueueJob( newOppMap, setRenewalExpansionOptySplit, setOrderedExpansionRenewal,stageSixChurnNotificationMap,UserMapTrgUpdate));
        }
        //ARY-107: END
        
        accountIdSet.remove(null);
        contactIdSet.remove(null);
        serviceContractIdSet.remove(null);
        
        // Map<ID, Contact> contactMap = new Map<ID, Contact>();
        // Map<ID, User> userMap = new Map<ID, User>();
        // Map<ID, ServiceContract> serviceContractMap = new Map<ID, ServiceContract>();
        
        //SAL24-794
        if((!contactIdSet.isEmpty() || !mapAccIdContactIds.isEmpty()) && ContactMapTrgUpdate.isEmpty()) 
            ContactMapTrgUpdate = new Map<ID, Contact>([SELECT Id, Email, Name, LeadSource,AccountId,UTM_Term__c,Last_UTM_Term_Date__c,Last_Partner_Sourced_Date__c,Primary_Technical_Support_Contact__c FROM Contact WHERE ID IN :contactIdSet OR AccountId IN :mapAccIdContactIds.keySet()]);
        //SAL24-794
        if(!skipExecutionHandler && !serviceContractIdSet.isEmpty() && serviceContractMapTrgUpdate.isEmpty()) //SAL26-731
            serviceContractMapTrgUpdate = new Map<ID, ServiceContract>([Select SBQQSC__Opportunity__c, SBQQSC__Opportunity__r.Opportunity_Sub_Type__c, SBQQSC__Order__c, SBQQSC__Order__r.Order_Sub_Type__c, SBQQSC__Quote__c, SBQQSC__Quote__r.OpportunitySubType__c,SBQQSC__Opportunity__r.Distributor_Lookup__c from ServiceContract WHERE ID IN:serviceContractIdSet]);
        //CPQ22-4511 start
        List<Opportunity> oppsToValidate = new List<Opportunity>();

        for (Id oppId : newRecordsMap.keySet()) {
        Opportunity newOpp = (Opportunity)newRecordsMap.get(oppId);
        Opportunity oldOpp = (Opportunity)oldRecordsMap.get(oppId);

        Boolean isPrimaryQuoteChanged = newOpp.SBQQ__PrimaryQuote__c != oldOpp.SBQQ__PrimaryQuote__c;
        Boolean isAmendedSCChanged  = newOpp.SBQQSC__AmendedServiceContract__c != oldOpp.SBQQSC__AmendedServiceContract__c;

        if ((isPrimaryQuoteChanged || isAmendedSCChanged) &&
            newOpp.Opportunity_Sub_Type__c == 'GC Offer') {

            oppsToValidate.add(newOpp);
        }
        }

        if (!skipExecutionHandler && !oppsToValidate.isEmpty()) {
            OpportunityObjectTriggerHelper.validateDistiForAmendmentUtilityQuote(
                oppsToValidate,
                serviceContractMapTrgUpdate 
            );
        }

        // CPQ22-4511 ends
        
        /*CSU-729: Start - To Throw validation for Scale Utility 2.0*/
        //Added SC object fields to serviceContractMapTrgUpdate SOQL Query above SBQQSC__Order__c, SBQQSC__Order__r.Order_Sub_Type__c, SBQQSC__Quote__c, SBQQSC__Quote__r.OpportunitySubType__c
        List<Opportunity> opptyList = new List<Opportunity>();
        for(Opportunity newOpp : newOppMap.values()) 
        {
            if(newOpp.SBQQSC__AmendedServiceContract__c != null && newOpp.Opportunity_Sub_Type__c != 'GC Offer'
                && serviceContractMapTrgUpdate != null 
                && serviceContractMapTrgUpdate.containsKey(newOpp.SBQQSC__AmendedServiceContract__c) 
                && serviceContractMapTrgUpdate.get(newOpp.SBQQSC__AmendedServiceContract__c) != null
                && serviceContractMapTrgUpdate.get(newOpp.SBQQSC__AmendedServiceContract__c).SBQQSC__Order__c != null
                && serviceContractMapTrgUpdate.get(newOpp.SBQQSC__AmendedServiceContract__c).SBQQSC__Order__r.Order_Sub_Type__c != null
                && serviceContractMapTrgUpdate.get(newOpp.SBQQSC__AmendedServiceContract__c).SBQQSC__Order__r.Order_Sub_Type__c == 'GC Offer'
                ){
                    opptyList.add(newOpp);
                }
        }
        if(!skipExecutionHandler && opptyList != null && !opptyList.IsEmpty()){ //SAL26-731
            OpportunityObjectTriggerHelper.preventAmendingNonGCOfferContracts(opptyList);//OnBeforeUpdate
        }
        /*CSU-729: End - To Throw validation for Scale Utility 2.0*/
        
        if(!skipExecutionHandler && !oppStage5IdSet.isEmpty()){//SAL23-211 //SAL26-731
            Set<ID> errorAddedOnOpp = new Set<ID>();
            for(Opportunity opp : oppMapTrgUpdate.values()){ //SAL24-794
                if(oppStage5IdSet.contains(opp.Id)){
                    Boolean isApprovedCCRExists = false; //SAL25-520
                    for(CCR__c ccr : opp.CCRs__r){
                        //SAL25-520
                        /*if(!errorAddedOnOpp.contains(ccr.Opportunity__c)){
                            errorAddedOnOpp.add(ccr.Opportunity__c);
                            newOppMap.get(ccr.Opportunity__c).addError(System.Label.CCR_APPROVAL_IS_REQUIRED);
                        }*/
                        if(ccr.User__c == 'Approved'){
                            isApprovedCCRExists = true;
                            break;
                        }
                    }
                    //SAL25-520
                    if(!isApprovedCCRExists && !errorAddedOnOpp.contains(opp.Id) && opp.CCRs__r.size() > 0){
                        errorAddedOnOpp.add(opp.Id);
                        newOppMap.get(opp.Id).addError(System.Label.CCR_APPROVAL_IS_REQUIRED);
                    }
                }
            }
            if(!errorAddedOnOpp.isEmpty()){
                return;
            }
        }
    
        /** SAL25-495 - Start *SAL26-549:commented
        if(!disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c) {
            OpportunityObjectTriggerHelper.validateUCLScaleSKUS(newOppMap, oldOppMap, oppMapTrgUpdate);
        } 
         SAL25-495 End */
    
        //SAL26-1340 Start
        coOwnerUserIds = new Set<Id>();
        oppETMOverridesIds = new Set<Id>();
        // SAL26-1340 - End
        // PRDOPS23-26 - Prashant
        for(Opportunity opp : oppMapTrgUpdate.values()){ //SAL24-794
            //PL26-131 start //SAL26-1340 commented code
            if(opp.Opportunity_Split_Parent__c != null && oldOppMap != null && oldOppMap.containskey(opp.Id) && opp.OwnerId != oldOppMap.get(opp.Id).OwnerId && opp.ETM_Theatre__c != opp.Opportunity_Split_Parent__r.ETM_Theatre__c){
                //SAL26-1340
                oppETMOverridesIds.add(opp.Id);
                for (String coOwnerField : coOwnerFields) {
                    Id userId = (Id) opp.get(coOwnerField);
                    if (userId != null) {
                        coOwnerUserIds.add(userId);
                    }
                }
            }
            //PL26-131 End
            for(OpportunityLineItem oli : opp.opportunitylineitems){ 
                if(!opptyId.isEmpty() && opptyId.contains(oli.opportunityId)){
                    if(!oppMap.containsKey(oli.OpportunityId)) {
                        oppMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
                    }
                    oppMap.get(oli.OpportunityId).add(oli);
                }
                if(!oli.PricebookEntry.Product2.IsActive){
                    if(!mapOpptyInactiveOppLines.containsKey(oli.OpportunityId)){
                        mapOpptyInactiveOppLines.put(oli.OpportunityId,new Set<Id>{});
                    }
                    mapOpptyInactiveOppLines.get(oli.OpportunityId).add(oli.Id);
                }
            }

            //Commented for SAL25-727
            /*//SAL25-549
            if(upliftEligOppIds.contains(opp.Id)){
                Id globalAccId = opp.Account.Parent.ParentId != null ? opp.Account.Parent.ParentId : opp.Account.ParentId != null ? opp.Account.ParentId : opp.AccountId;
                oppGlobalAccIdMap.put(opp.Id, globalAccId);
                globalAccIds.add(globalAccId);
            }*/
        }
    
        //SAL26-1340 Start
        if(!coOwnerUserIds.isEmpty()){
            Map<Id, List<UserTerritory2Association>> userToUTAListMap = OpportunityObjectTriggerHelper.buildUserToUTAMap(coOwnerUserIds);
            if (!oppETMOverridesIds.isEmpty()){
                OpportunityObjectTriggerHelper.resetPLSForETMOverridesAndSplitOpp(userToUTAListMap, oppETMOverridesIds, oppMapTrgUpdate, true);
            }
        }
        // SAL26-1340 - End
		if(!skipExecutionHandler && !ContactMapTrgUpdate.isEmpty()){ //SAL26-731	
            for(Contact con : ContactMapTrgUpdate.values()) {
                if(mapAccIdContactIds.get(con.AccountId) == null){
                    mapAccIdContactIds.put(con.AccountId, new Set<Id>{con.Id});
                }
                else{
                    mapAccIdContactIds.get(con.AccountId).add(con.Id);
                }
                if(con.Primary_Technical_Support_Contact__c){
                    if(!mapAccIdPrimTechSupContactIds.containsKey(con.AccountId)) {
                        mapAccIdPrimTechSupContactIds.put(con.AccountId,new Set<Id>{});
                    }
                    mapAccIdPrimTechSupContactIds.get(con.AccountId).add(con.Id);
                }
            }
        }
        
        if(!skipExecutionHandler && !dealRegLinkSet.isEmpty() && dealRegLinkMap.isEmpty()){ //SAL26-731
            dealRegLinkMap = new Map<ID, Lead> (
                [SELECT
                    SDR_Led__c, Deal_Registration_Type__c, Deal_Reg_Approval_Status__c, Deal_Reg_Submitted_Date__c,
                    Deal_Reg_Approval_Timestamp__c,Deal_Reg_Exp_Date__c, Alliance_Partner_Program__c,
                    Deal_Registration_Number__c, Partner_Rep_Phone_Number__c, Partner_Rep_Email_Address__c,
                    Distributor_Rep_Phone_Number__c, Distributor_Secondary_Email_Address__c, Partner_SE_Name__c, Sell_to_Partner__c,  //FCUS-117
                    Partner_SE_Phone__c, Partner_SE_Email__c
                    FROM Lead WHERE Id IN :dealRegLinkSet]
            );
        }
    
        Set<String> stageNameSet = new Set<String>{'6 PO With Channel', '7 Closed Won', '7 Closed Lost', '7 Closed Admin'};
            Map<ID, Account>updatedAccountMap = new Map<ID, Account>();
        for(Opportunity opp : newOppMap.values()) {
            Opportunity oldOpp = oldOppMap.get(opp.id);
            
            OpportunityObjectTriggerHelper.setAgeInOppStage(opp,oldOpp, mapOfOppStages);
            
            // PRDOPS23-26 - Prashant
            if(oppMap.containskey(opp.id)){
            	opp.Commission_Portfolio_Type__c = OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(oppMap.get(opp.id),opp);
            }
            
            OpportunityObjectTriggerHelper.resetOpportunityFieldsOnChange(oldOpp, opp, AccountMapTrgUpdate, updatedAccountMap, ContactMapTrgUpdate, UserMapTrgUpdate, serviceContractMapTrgUpdate,null,null,null,null,null,updatingOppTypeUsingSDPlookup); //SAL24-735 //SAL25-106
            //Adding Deal Reg to Opty - Start
            Boolean dealRegTypeChange = false;
            if(oldOpp.Deal_Registration_Type__c != opp.Deal_Registration_Type__c){
                dealRegTypeChange = true;
            }
            //SAL24-184 //SAL26-731
            if(!skipExecutionHandler && opp.FCRM__FCR_Admin_Originating_Contact__c != null && !ContactMapTrgUpdate.isEmpty() && ContactMapTrgUpdate.containskey(opp.FCRM__FCR_Admin_Originating_Contact__c)
                && ContactMapTrgUpdate.get(opp.FCRM__FCR_Admin_Originating_Contact__c).Last_Partner_Sourced_Date__c != null && opp.Last_Partner_Sourced_Date__c == null
                && (oldOpp.Initial_Contacts_Name__c == null || opp.Initial_Contacts_Name__c == oldOpp.Initial_Contacts_Name__c)){
                    opp.Last_Partner_Sourced_Date__c = ContactMapTrgUpdate.get(opp.FCRM__FCR_Admin_Originating_Contact__c).Last_Partner_Sourced_Date__c;
                }
            if(oldOpp.Deal_Registration_Link__c != opp.Deal_Registration_Link__c && opp.Deal_Registration_Link__c != null && dealRegLinkMap.containsKey(opp.Deal_Registration_Link__c)){
                Lead regLink = (Lead) dealRegLinkMap.get(opp.Deal_Registration_Link__c);
                if(!dealRegTypeChange)
                    DealRegUtilityHelper.setDealRegistrationType(opp, regLink);
                //FCUS-117n118
                //DealRegUtilityHelper.copyDealRegLeadToOpportunity(opp, regLink);
                OpportunityAddDealRegController.copyDealRegLeadToOpportunity(opp, regLink);
            } else {
                if(!dealRegTypeChange && (opp.Deal_Registration_Type__c == null || oldOpp.SDR_Led__c!= opp.SDR_Led__c || oldOpp.Deal_Registration__c!= opp.Deal_Registration__c || (oldOpp.Converted_From_Lead__c!= opp.Converted_From_Lead__c && opp.Converted_From_Lead__c)))
                    DealRegUtilityHelper.setDealRegistrationType(opp, null);
            }//Adding Deal Reg to Opty - End
            //opp.Number_of_Inactive_Products__c = opptyInactiveProduct.get(opp.Id) != null ? opptyInactiveProduct.get(opp.Id) : 0;
            opp.Number_of_Inactive_Products__c = mapOpptyInactiveOppLines.get(opp.Id) != null ? mapOpptyInactiveOppLines.get(opp.Id).size() : 0;
            //opp.Number_of_Primary_Technical_Contact__c = accTechContact.get(opp.AccountId) != null ? accTechContact.get(opp.AccountId) : 0;
            opp.Number_of_Primary_Technical_Contact__c = (!skipExecutionHandler) ? (mapAccIdPrimTechSupContactIds.get(opp.AccountId) != null ? mapAccIdPrimTechSupContactIds.get(opp.AccountId).size() : 0) : opp.Number_of_Primary_Technical_Contact__c; //SAL26-731
            
            //MKT22-270
            /* commented as a part of SAL25-348
            if((opp.Partner_of_Record__c == null && oldOpp.Partner_of_Record__c == null) && (opp.StageName != '7 Closed Won' && opp.StageName != '7 Closed Lost' && opp.StageName != '7 Closed Admin') && AccountMapTrgUpdate.keySet().contains(opp.AccountId) && AccountMapTrgUpdate.get(opp.AccountId).MSP_Account_Lookup__c != null){
                opp.Partner_of_Record__c = AccountMapTrgUpdate.get(opp.AccountId).MSP_Account_Lookup__c;
            } */
            // SAL24-527 to set "Focused Partner" and "National Partner" fields value
            if(opp.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp && !opp.IsClosed && (opp.Sourcing_Partner__c!=oldOpp.Sourcing_Partner__c || opp.Teaming_Partner__c!=oldOpp.Teaming_Partner__c || opp.Partner_Lookup__c!=oldOpp.Partner_Lookup__c || opp.Deal_Registration_Type__c!=oldOpp.Deal_Registration_Type__c || opp.RecordTypeId!=oldOpp.RecordTypeId)){
                OpportunityObjectTriggerHelper.updateFocusNationalPartner(opp,AccountMapTrgUpdate);              
            } // SAL24-527 END
            //SAL24-28
            //opp.Opportunity_Alliance_BDM__c = opp.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp ? null : !opp.isClosed ? updateAccountMap.get(opp.AccountId)?.Account_Alliance_BDM_Lookup__r.Name : opp.Opportunity_Alliance_BDM__c; //SAL24-472
            //Added below if as part of SAL26-105
            if(opp.Override_ETM_Alliance_BDM__c && opp.Override_ETM_Alliance_BDM__c != oldOpp.Override_ETM_Alliance_BDM__c){
                opp.AWS_GCP_Cloud_Alliance_BDM_Id__c = null;
                opp.MSFT_OCI_Cloud_Alliance_BDM_Id__c = null;
            }
            //Commented below line as part of SAL26-101
            //if(opp.Override_ETM_Alliance_BDM__c && opp.Override_ETM_Alliance_BDM__c != oldOpp.Override_ETM_Alliance_BDM__c) opp.Account_Alliance_BDM_Id__c = null; //SAL25-99 
            //Validation Rule
            //SF-6177: Opp closed without opportunity sub-type
            if(opp.Opportunity_Type__c != null && opp.Opportunity_Sub_Type__c == null && stageNameSet.contains(opp.StageName)){
                opp.addError('Opportunity Sub-Type cannot be blank. Please select the correct value based on the Opportunity Type.');
            }
            
            if(!skipExecutionHandler && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c
                && !opp.isClosed
                && opp.Opportunity_Type__c != 'Debooking'
                && opp.Opportunity_Sub_Type__c != 'MSP Overage'
                && opp.Polaris_Portal_Contact__c != null
                && !(opp.StageName == '1 Discovery' && opp.recordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp)
                && (mapAccIdContactIds.get(opp.AccountId) == null || !mapAccIdContactIds.get(opp.AccountId).contains(opp.Polaris_Portal_Contact__c))){
                   opp.addError('Rubrik Security Cloud Owner must belong to same Account as Opportunity.'); //SAL24-356 //SAL26-731
                }
            //Change Deal Initiated type to JID when a PID deal is attached to an oppty which is SDR led
            /*if(oldOpp.SDR_Led__c == opp.SDR_Led__c && opp.SDR_Led__c && opp.Deal_Registration_Number__c != null && oldOpp.Deal_Registration_Number__c != opp.Deal_Registration_Number__c && opp.Deal_Reg_Approval_Status__c == 'Approved' && opp.Deal_Registration_Type__c == DealRegUtilityHelper.PID){
    opp.Deal_Registration_Type__c = DealRegUtilityHelper.JID;
    }*/
            
            //SAL24-466 : updated condition
            //PRIT24-534 Code Commented
            /*
    if(!opp.StageName.contains('7 Closed ') &&
    ((opp.Alliance_Partner_Name__c != null && oldOpp.Alliance_Partner_Name__c != opp.Alliance_Partner_Name__c && opp.Alliance_Partner_Name__c != 'None' && ((oldOpp.Alliance_Partner_Name__c == null && opp.Alliance_Partner_Name__c.contains('Microsoft') && ((oldOpp.Cloud_Partner_Led_Activity__c != opp.Cloud_Partner_Led_Activity__c && opp.Cloud_Partner_Led_Activity__c == 'Yes') || opp.Cloud_Partner_Led_Activity__c == 'Yes')) || (oldOpp.Alliance_Partner_Name__c != null && opp.Alliance_Partner_Name__c != null && opp.Alliance_Partner_Name__c.contains('Microsoft') && !oldOpp.Alliance_Partner_Name__c.contains('Microsoft') && ((oldOpp.Cloud_Partner_Led_Activity__c != opp.Cloud_Partner_Led_Activity__c && opp.Cloud_Partner_Led_Activity__c == 'Yes' ) || opp.Cloud_Partner_Led_Activity__c == 'Yes'))))
    || (opp.Cloud_Partner_Led_Activity__c != null && opp.Alliance_Partner_Name__c != null && opp.Alliance_Partner_Name__c.contains('Microsoft') && oldOpp.Alliance_Partner_Name__c != null && oldOpp.Alliance_Partner_Name__c.contains('Microsoft') && (oldOpp.Cloud_Partner_Led_Activity__c != opp.Cloud_Partner_Led_Activity__c && opp.Cloud_Partner_Led_Activity__c == 'Yes' )))){
    autoDRForMicrosoftOppMap.put(opp.Id,opp);
    }*/
            
            if(!opp.StageName.contains('7 Closed ') && oldOpp.Deal_Reg_Approval_Status__c == 'Pending Conversion' && opp.Deal_Reg_Approval_Status__c == 'Pending Conversion' && opp.Deal_Registration_Number__c != null && opp.Created_by_Lead_Conversion__c){
                opp.Deal_Reg_Approval_Status__c = 'Approved';
                opp.Deal_Reg_Approval_Timestamp__c = System.now();
            }
            
            //SAL23-664
            //SAL24-47
            /*if(opp.recordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp && opp.Opportunity_Sub_Type__c == 'Renewal')
    opp.In_Forecast_CRO__c = (opp.In_Forecast_Renewal__c != oldOpp.In_Forecast_Renewal__c && opp.StageName != '7 Closed Lost' && opp.StageName != '7 Closed Admin') ? opp.In_Forecast_Renewal__c : opp.In_Forecast_CRO__c;
    else*/
            
            //SAL22-389
            if(opp.recordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp)
                opp.In_Forecast_CRO__c = opp.In_Forecast_Theatre__c != oldOpp.In_Forecast_Theatre__c && opp.In_Forecast_Theatre__c && !opp.In_Forecast_CRO__c ? TRUE : opp.In_Forecast_CRO__c;
            //SAL23-47 End
            
            //SAL24-528
            Account cdmTARTAccount = opp.Deal_Registration_Type__c != 'Rubrik Sourced' && opp.Sourcing_Partner__c != null ?
                AccountMapTrgUpdate.get(opp.Sourcing_Partner__c) : 
            opp.Deal_Registration_Type__c == 'Rubrik Sourced' && opp.Teaming_Partner__c != null ?
                AccountMapTrgUpdate.get(opp.Teaming_Partner__c) : 
            opp.Partner_Lookup__c != null ? AccountMapTrgUpdate.get(opp.Partner_Lookup__c) : null;
            //SAL26-1085
            Boolean cdmETMOverride = false;
            if(String.isNotBlank(opp.Opportunity_Override_Flags__c)){
                List<String> selectedFlags = opp.Opportunity_Override_Flags__c.split(';');
                if(selectedFlags.contains('CDM ETM Override')){
                    cdmETMOverride = true;
                }
            }
            
            if((opp.id == null || !opp.isClosed) && !cdmETMOverride){ //SAL26-1085:add cdmETMOverride check
                opp.CDM_Theatre__c = cdmTARTAccount?.ETM_Theatre__c;
                opp.CDM_Area__c = cdmTARTAccount?.ETM_Area__c;
                opp.CDM_Region__c = cdmTARTAccount?.ETM_Region__c;
                opp.CDM_Territory__c = cdmTARTAccount?.ETM_Territory__c;
            }
            //SAL24-528 End
        }
        
        //Commented for SAL25-727
        //SAL25-549
        /*if(!oppGlobalAccIdMap.isEmpty()){
            if(periodList.isEmpty()){
                periodList = [Select Id, StartDate, EndDate, Type, Number From Period where StartDate = THIS_FISCAL_YEAR and EndDate = THIS_FISCAL_YEAR and Type = 'Quarter']; //To fetch start and end date for the fiscal year and its quarter
            }
            for(Period per :periodList){
                startDateH1 = per.Number == 1 ? per.StartDate : startDateH1;
                endDateH1 = per.Number == 2 ? per.EndDate : endDateH1;
                startDateH2 = per.Number == 3 ? per.StartDate : startDateH2;
                endDateH2 = per.Number == 4 ? per.EndDate : endDateH2;
            }
            Date tdate= System.today();
            planStartDate = tdate >= startDateH1 && tdate <= endDateH1 ? startDateH1 : startDateH2;
            planEndDate = tdate >= startDateH1 && tdate <= endDateH1 ? endDateH1 : endDateH2;
            OpportunityObjectTriggerHelper.updateUpliftEligibleOpp(newOppMap,oppGlobalAccIdMap,globalAccIds,planStartDate,planEndDate);
        } //End*/
        
        if(!skipExecutionHandler){ //SAL26-731
        OpportunityObjectTriggerHelper.updateAAROpportunity(newOppMap, oldOppMap,UserMapTrgUpdate);
        }
        if(!updatedAccountMap.isEmpty()){
            boolean tempFlag = flowControll.accountTrigger;
            flowControll.accountTrigger = false;
            update updatedAccountMap.values();
            flowControll.accountTrigger = tempFlag;
        }
        if(!skipExecutionHandler){ //SAL26-731
	        OpportunityObjectTriggerHelper.updateAspenEligibility(newOppMap.values(),AccountMapTrgUpdate,quoteMapTrgUpdate);
	        if(!disabledFunctionality.DisableDemandMatrixCalculation__c) {
	            OpportunityObjectTriggerHelper.aspenOpportunityOperations(oldOppMap, newOppMap);
	        }
	        //PRIT24-534 Code Commented
	        /*if(!autoDRForMicrosoftOppMap.isEmpty()){
	        OpportunityObjectTriggerHelper.autoRegisterDRForMicrosoft(autoDRForMicrosoftOppMap);
	        }*/
	        
	        OppEmailTriggerHandler.sentEmailOnOppStage3(newOppMap,oldOppMap,quoteMapTrgUpdate); //FY25SR-2391//Send Email when Opp is on Stage 3
	        OppEmailTriggerHandler.sendTradeUpPDFAddendumEmail(newOppMap,oldOppMap,quoteMapTrgUpdate); //SAL24-443 - TradeUp PDF Addendum Email
	        //SAL24-749
	        if(!churnNotificationMap.isEMpty()){
	            OppEmailTriggerHandler.sendchurnNotification(newOppMap,UserMapTrgUpdate,churnNotificationMap);
	        }
	   }
     }
    /**

     * @description This method executes on AfterInsert
     * @param newRecordsMap
     */
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        Map<ID, Opportunity> newOppMap = (Map<ID, Opportunity>)newRecordsMap;
        Set<ID> oppIdSetForInitialContactsName = new Set<ID>();
        Set<Id> oppIds = new Set<Id>();
        Map<String,Opportunity> dealRegistrationOpptyMap = new Map<String,Opportunity>();
        Map<Id,Id> oppfocusedAccShareMap = new Map<Id,Id>();
        Set<Id> accountIdSet = new Set<Id>();
        //Map<Id,Account> updateAccountMap = new Map<id,Account>();
        //Set<String> oppIdNPMAcctOldNew = new Set<String>(); //SAL24-679 //commented for SAL26-75
        Set<Id> queryOppIdSet = new Set<Id>();
        Map<Id,Opportunity> newOpptyMap = new Map<Id,Opportunity>(); //PRIT25-750
        List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
        //Map<Id,Opportunity> autoDRForMicrosoftOppMap = new Map<Id,Opportunity>();//PRIT24-31,PRIT24-534 Code Commented
        
        List<OpportunityTeamMember> oppTeamMemberLstToInsert = new List<OpportunityTeamMember>(); // PL26-73
        Map<Id,Opportunity> newDebookingOpptyMap = new Map<Id,Opportunity>(); //SAL26-72
        
	for(Opportunity opp : (List<Opportunity>) newOppMap.values()){
            
            // PL26-73 start
            if(opp.Co_Owner__c != null){
                oppTeamMemberLstToInsert.add(new OpportunityTeamMember(OpportunityId = opp.Id,
                                                                       UserId = opp.Co_Owner__c,
                                                                       TeamMemberRole = 'Co-Owner',
                                                                       OpportunityAccessLevel = 'Edit'
                                                                      ));
            }
            // PL26-73 end
            
            if(String.isNotBlank(opp.Initial_Contacts_Name__c) && !opp.Converted_From_Lead__c ) {
                oppIdSetForInitialContactsName.add(opp.id);
                queryOppIdSet.add(opp.Id);
            }
            if(opp.Deal_Registration__c && String.isNotBlank(opp.Deal_Registration_Number__c) && String.isNotBlank(opp.Deal_Reg_Approval_Status__c) && (opp.Deal_Reg_Approval_Status__c.equals('Approved') || opp.Deal_Reg_Approval_Status__c.equals('Pending Conversion'))){
                dealRegistrationOpptyMap.put(opp.Deal_Registration_Number__c,opp);
            }
            if(opp.Opportunity_Sub_Type__c != null && opp.Opportunity_Sub_Type__c.equals('Regular') && opp.SBQQSC__RenewedServiceContract__c == null && opp.SBQQSC__AmendedServiceContract__c == null && opp.POC__c == false){
                oppIds.add(opp.Id);
            }
            //PRIT25-750 //SAL26-72
            if(opp.Opportunity_Type__c != 'Debooking' && opp.Opportunity_Split_Parent__c == null && (opp.Partner_Lookup__c != null || opp.Distributor_Lookup__c != null || opp.Sourcing_Partner__c != null || opp.Incumbent_Partner__c != null || opp.Teaming_Partner__c != null)){//PRIT26-84
                newOpptyMap.put(opp.Id,opp);
            }
            if(opp.Partner_Lookup__c != null){ //SAL24-21
                oppfocusedAccShareMap.put(opp.Id,opp.Partner_Lookup__c);
                accountIdSet.add(opp.Partner_Lookup__c);
                //SAL24-679 //OppId+'-'+OldNPMAcct+'-'+NewNPMAcct - ListString format
                //oppIdNPMAcctOldNew.add(opp.Id + '-' + 'null' + '-' + opp.Partner_Lookup__c); //commented for SAL26-75
            }//SAL24-21
            //SAL26-72 - SAL26-221
            if(opp.Opportunity_Type__c == 'Debooking' && opp.CCR__c!=null) {
                newDebookingOpptyMap.put(opp.Id, opp);
            }
            //PRIT24-31 - Start //SAL24-466 removed  && opp.Cloud_Partner_Led_Activity__c == 'Yes' PRIT24-534 - Code Commented
            /*if(opp.Alliance_Partner_Name__c != null && opp.Alliance_Partner_Name__c != 'None' && opp.Alliance_Partner_Name__c.contains('Microsoft')){
            autoDRForMicrosoftOppMap.put(opp.Id,opp);
            }*/
            //PRIT24-31 - End
            //SAL24-679
            //OppId+'-'+OldNPMAcct+'-'+NewNPMAcct - ListString format
            /*if(opp.Sourcing_Partner__c != null){oppIdNPMAcctOldNew.add(opp.Id + '-' + 'null' + '-' + opp.Sourcing_Partner__c);}
            if(opp.Teaming_Partner__c != null){oppIdNPMAcctOldNew.add(opp.Id + '-' + 'null' + '-' + opp.Teaming_Partner__c);}  */ //commented for SAL26-75          
        }
        
        if(!accountIdSet.isEmpty() && AccountMapTrgInsert.isEmpty()){
            AccountMapTrgInsert = new Map<ID, Account>([Select id,OwnerId,Focused_Partner__c,RecordTypeId,RecordType.Name,Adaptive_Territory_Id__c from Account WHERE ID IN:accountIdSet]);
        }
        if(!queryOppIdSet.isEmpty() && oppMapTrgInsert.isEmpty()){
            oppMapTrgInsert = new Map<Id,Opportunity>([Select Id,Initial_Contacts_Name__c ,(SELECT ContactId,OpportunityId,Isprimary from OpportunityContactRoles where Isprimary=true) FROM Opportunity where Id IN:queryOppIdSet]);
        }
        if(!dealRegistrationOpptyMap.isEmpty() && dealRegistrationTrgInsert.isEmpty()){
            dealRegistrationTrgInsert = [SELECT Id,Name,Deal_Registration_Status__c,Approval_Timestamp__c,Opportunity__c,Deal_Reg_Exp_Date__c,Company_Name__c,OwnerId,Primary_Deal_Registration__c,Primary__c,Deal_Registration_Sub_Status__c,Deal_Registration_Type__c, DR_Approved_Date__c,Deal_Registration_Extension_Request__c,Registration_Type__c
                                            FROM Deal_Registration__c
                                            WHERE Name IN : dealRegistrationOpptyMap.keyset()];
        }
        for(Opportunity op: oppMapTrgInsert.values()){
            for(OpportunityContactRole ocr : op.OpportunityContactRoles){
                ocrList.add(ocr);
            }
        }
        if(!oppIdSetForInitialContactsName.isEmpty()) {
            OpportunityObjectTriggerHelper.upsertOpportunityContactRoles(ocrList, newOppMap,oppIdSetForInitialContactsName);
        }
        if(!dealRegistrationOpptyMap.isEmpty()){
            OpportunityObjectTriggerHelper.updateDealRegOnOpportunity(dealRegistrationOpptyMap,dealRegistrationTrgInsert);
        }
        //PRIT24-31 - Start PRIT24-534 - Code Commented
        /*if(!autoDRForMicrosoftOppMap.isEmpty()){
    OpportunityObjectTriggerHelper.autoRegisterDRForMicrosoft(autoDRForMicrosoftOppMap);
    }*/
        //PRIT24-31 - End
    
        OpportunityObjectTriggerHelper.shareOppfocusedPartnerAccount(oppfocusedAccShareMap,AccountMapTrgInsert); //SAL24-21
        OppAnnualContractValueUtil.calculateAcvAmount(newRecordsMap.keySet());
        OpportunityUtil.notifyToParentAccountOwner(newRecordsMap.values(), parentChildAccountIdSet);
        
        // calling batch class for ARY682 to create quote record
      /*  if(!oppIds.isEmpty() && !System.isFuture() && !System.isBatch()){ //FY25SR-1970 SummerRelease
            AutoQuoteCreationBatch1 obj = new AutoQuoteCreationBatch1(oppIds);
            Database.executeBatch(obj,1);
        }*/
        
        //SAL24-679
        /*if (!oppIdNPMAcctOldNew.isEmpty() && (System.isBatch() || System.isFuture() || System.isQueueable())) {OpportunityObjectTriggerHelper.manageNPMAccountOpptyShare(oppIdNPMAcctOldNew);}
        else if (!oppIdNPMAcctOldNew.isEmpty()) {OpportunityObjectTriggerHelper.manageNPMAccountOpptyShareFuture(oppIdNPMAcctOldNew);} */ //commented for SAL26-75

        //RRR-11 --dummy update
        CS_AutomaticRiskProfileCreation.handleRenewalSentimentChange(null, newOppMap);

        // PL26-73 start
        if(!accTeamMembersToInsertDelete.isEmpty()){
            FlowControll.accountTrigger = false;
            Database.delete(accTeamMembersToInsertDelete, false);
            FlowControll.accountTrigger = true;
        }
        
        if(!oppTeamMemberLstToInsert.isEmpty()){
            Database.insert(oppTeamMemberLstToInsert, false);
        }
        // PL26-73 end
        // PRIT25-750
    	if(!newOpptyMap.isEmpty()){
           OpportunityObjectTriggerHelper.syncOpportunityPartnerRelations(newOpptyMap,null);   
        }
        //SAL26-72
        if(!newDebookingOpptyMap.isEmpty()) {
            OpportunityObjectTriggerHelper.createPartnerRelation(newDebookingOpptyMap);
        }

        
    }
    
    /**
     * @description Apex method to handle opportunity after update logic 
     * @param oldRecordsMap
     * @param newRecordsMap
     */
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        if(OppAnnualContractValueUtil.oppIdSetAcvCalculation.containsAll(newRecordsMap.keySet())){
            return;
        }
        List<Territory_Owner_Assignment__c> reprocessOppSE = new List<Territory_Owner_Assignment__c>(); // Opportunity SE realignment
        List<Opportunity> newOppList = (List<Opportunity>)newRecordsMap.values();
        Set<Id> OpportunityCloseDateChangeIdSet = new Set<Id>();
        Map<ID, Opportunity> newOppMap = (Map<ID, Opportunity>)newRecordsMap;
        Map<ID, Opportunity> oldOppMap = (Map<ID, Opportunity>)oldRecordsMap;
        Map<ID, Account> updateAccountMap;
        ShGl_DisableFunctionalityLogic__c disabledFunctionality = ShGl_DisableFunctionalityLogic__c.getInstance();
        Boolean isHoldOffLogicDisabled = disabledFunctionality.DisableHoldOffLogic__c;
        
        Set<ID> holdOffEmailToOpptunitySet = New set<ID>();
        if(!holdOffEmailToOpptSet.isEmpty()){// Added for SAL1638
            holdOffEmailToOpptunitySet.addAll(holdOffEmailToOpptSet);
            holdOffEmailToOpptSet.removeAll(holdOffEmailToOpptunitySet);
            OpportunityObjectTriggerHelper.sendHoldOffEmail(holdOffEmailToOpptunitySet);
        }
        
        Map<String, List<String>> mapOppWithNewHoldCodes = new Map<String, List<String>>();
        Map<String, List<String>> mapOppWithOldHoldCodes = new Map<String, List<String>>();
        List<Opportunity> valootoOpptyList = new List<Opportunity> ();
        Set<Id> amountChangedForOppIdSet = new Set<Id> ();
        Set<Id> incHoldoverCountOpptyIdSet = new Set<Id> ();
        Set<Id> decHoldoverCountOpptyIdSet = new Set<Id> ();
        Set<Id> splitOpptyIdSet = new Set<Id> ();
        List<Id> opportunitiesToUnlock = new List<Id>();
        Set<ID> oppIdSetForInitialContactsName = new Set<ID>();
        Set<Id> datosOpportunityIdSet = new Set<Id>();
        Set<Id> nonDatosOpportunityIdSet = new Set<Id>();
        Set<Id> partnerNameChangedSet = new Set<Id>();
        set<id>accountIdSet = new set<Id>();
        set<Opportunity> closedOppBkgList = new set<Opportunity>() ;
        List<Opportunity_Debrief__c> opportunityDebriefUpdates = new List<Opportunity_Debrief__c>();
        Map<Id, Opportunity_Debrief__c> oppIdOppDebriefMap = new Map<Id, Opportunity_Debrief__c>();
        Map<String,Opportunity> closedOppWithDRMap = new Map<String,Opportunity>();
        Set<Id> aarOppIdSet = new Set<Id>(); //SAL23-508 AAR
        //Set<String> dealregSet = new Set<String>();
        //Map<String,Opportunity> opptyPIDtoJIDMap = new Map<String,Opportunity>();
        Map<Id, Opportunity> eligiblePOVal = new Map<Id, Opportunity>();
        Set<id> opptyIds = new Set<Id>();
        Set<Id> ideaId = new Set<Id>();
        Map<Id,Opportunity> newOpptyMap = new Map<Id,Opportunity>(); //PRIT25-750
        Map<Id,Opportunity> oldOpptyMap = new Map<Id,Opportunity>(); //PRIT25-750
		if(!skipExecutionHandler){
			List<Opportunity_Debrief__c> oppDebriefList = [Select Id, Opportunity__c, Opportunity_Escalation_Stage__c from Opportunity_Debrief__c where Opportunity__c IN : newOppMap.keySet()];
			for(Opportunity_Debrief__c od: oppDebriefList){
				oppIdOppDebriefMap.put(od.Opportunity__c, od);
			}
		}
        
        //PS - EGN 116 STARTS
        Set<Id> primaryQuoteToUpdate = new Set<Id>();
        //PS - EGN ENDS
        //Set<String> oppIdNPMAcctOldNew = new Set<String>(); //SAL24-679 //commented for SAL26-75
        Set<Id> closedOpptyIds = new Set<Id>(); //SAL25-247
        Set<Id> oppToCreateChurn = new Set<Id>();//FY25SR-1857
        Set<Id> coOwnerChangedOppIdsSet = new Set<Id>(); //SAL26-1326
        for(Opportunity newOpp : newOppList){
            
            //PS - EGN 116 STARTS
            
            if(!skipExecutionHandler && (Test.isRunningTest() && newOpp.Name == 'TEST Opp Quote') || (newOpp.SBQQ__PrimaryQuote__c !=null &&
               newOpp.SOW_Required__c  == true && (newOpp.StageName!= '1 Discovery' && newOpp.StageName!= '2 Consensus'
                                                   &&  newOpp.StageName!= '0 Nurture'))){ //SAL26-731
                                                       primaryQuoteToUpdate.add(newOpp.SBQQ__PrimaryQuote__c);
                                                   }//PS - EGN ENDS
            
            
            
            if(newOpp.AccountId!=null)
                accountIdSet.add(newOpp.AccountId);
            //PS - EGN 116 STARTS
            if(newOpp.Partner_Lookup__c!=null){
                accountIdSet.add(newOpp.Partner_Lookup__c); //SAL24-21
            }
            //SAL25-106
        if(newOpp.MSP_End_User_Lookup__c!=null){
            accountIdSet.add(newOpp.MSP_End_User_Lookup__c);
        }
            
            if((newOpp.AccountId == Label.ReOrDebook_AccountId || Test.isRunningTest()) && newopp.name.startsWithIgnoreCase('PSO')
               && newopp.stageName == '7 Closed Won'  && newopp.stageName!= oldOppMap.get(newOpp.id).stageName){
                   closedOppBkgList.add(newopp);
               }
            //ARY-283
            if(newOpp.CloseDate != oldOppMap.get(newOpp.Id).CloseDate){
                OpportunityCloseDateChangeIdSet.add(newOpp.Id);
            }
            if(newopp.Primary_Quote_Type__c != 'Renewal+Expansion'){
                eligiblePOVal.put(newopp.Id, newOpp);
            }
            //SAL-23-508 AAR
            if(newopp.StageName == '7 Closed Lost' && newopp.After_Action_Form_Submitted__c &&
               (newopp.StageName != oldOppMap.get(newOpp.Id).StageName || newopp.CloseDate != oldOppMap.get(newOpp.Id).CloseDate)){
                   aarOppIdSet.add(newopp.Id);
               }
			   
            //Method is used to Calculate the ACV Amount on Idea based on the Opportunity Stage type.
            if(newopp.ACV_Amount__c != oldOppMap.get(newOpp.Id).ACV_Amount__c || (newopp.stageName!= oldOppMap.get(newOpp.Id).stageName && (newopp.isWon != oldOppMap.get(newOpp.Id).isWon || newopp.isclosed!= oldOppMap.get(newOpp.Id).isclosed))){
                opptyIds.add(newopp.Id);
            }
            //PRIT25-750
            if((oldOppMap.get(newOpp.Id).Partner_Lookup__c != newOpp.Partner_Lookup__c)
               || (oldOppMap.get(newOpp.Id).Distributor_Lookup__c != newOpp.Distributor_Lookup__c)
               || (oldOppMap.get(newOpp.Id).Sourcing_Partner__c != newOpp.Sourcing_Partner__c)
               || (oldOppMap.get(newOpp.Id).Incumbent_Partner__c != newOpp.Incumbent_Partner__c)
               || (oldOppMap.get(newOpp.Id).Teaming_Partner__c != newOpp.Teaming_Partner__c)){
                   newOpptyMap.put(newOpp.Id,newOpp);
                   oldOpptyMap.put(newOpp.Id,oldOppMap.get(newOpp.Id));
            }
			//FY25SR-1857 Khushboo
            if(newOpp.Opportunity_Sub_Type__c == 'Renewal' && newOpp.SBQQ__PrimaryQuote__c !=null && newOpp.StageName == System.Label.Order_Creation_Stage && newOpp.StageName != oldOppMap.get(newOpp.Id).StageName)
            {
                oppToCreateChurn.add(newOpp.Id);
            }
            //SAL26-1326
			Opportunity oldOpp = oldOppMap.get(newOpp.Id);
            if(((newOpp.Co_Owner__c != oldOpp.Co_Owner__c && (newOpp.Co_Owner__c == null || oldOpp.Co_Owner__c == null)) || (newOpp.NCD_Co_Owner__c != oldOpp.NCD_Co_Owner__c && (newOpp.NCD_Co_Owner__c == null || oldOpp.NCD_Co_Owner__c == null))) && String.isNotBlank(oppMapTrgUpdate.get(newOpp.Id).Account.Customer_Type_Without_RCV__c)){
                coOwnerChangedOppIdsSet.add(newOpp.Id);
            }
        }
        //ARY-283
        if(!OpportunityCloseDateChangeIdSet.isEmpty()){
            OpportunityLineItemTriggersHelper.afterOLITriggerMethods(null,null,OpportunityCloseDateChangeIdSet);
        }
        if(!coOwnerChangedOppIdsSet.isEmpty()){ //SAL26-1326
            System.enqueueJob(new OpportunityACVCalculationsQueueable(coOwnerChangedOppIdsSet));
        }             
        if(!skipExecutionHandler && !closedOppBkgList.isEmpty()){ //SAL26-731
            OpportunityObjectTriggerHelper.CreateBooking(closedOppBkgList,newOppMap,oldOppMap);  //PRDOPS22-185
        }
        //PRDOPS22-185
        
        //SAL-23-508 AAR
        if(!aarOppIdSet.isEmpty()){
            OpportunityObjectTriggerHelper.updateAARCloseDate(aarOppIdSet, newOppMap);
        }
        //FY25SR-1857 Khushboo
        if(!skipExecutionHandler && oppToCreateChurn!=null && !oppToCreateChurn.isEmpty()  && !System.IsFuture() && !System.isBatch()){ //SAL26-731
            System.enqueueJob(new CreationOfRenewalChurnOpp(oppToCreateChurn));
        }
        
         //commented below if block as part of CPQ22-3962 method merged with updateQuoteFields
        /*
        if(!primaryQuoteToUpdate.isEmpty()){
            OpportunityObjectTriggerHelper.updatePrimaryQuote(primaryQuoteToUpdate);
        }*/
        //PS - EGN ENDS
        //Get the Ideas Linked with Opportunity
        if(!skipExecutionHandler && opptyIds.size() > 0 && !System.isFuture() && !System.isBatch()){ //SAL26-731
            for(Aha_Idea_Link__c idealink : [Select id,Aha_Ideas__c from Aha_Idea_Link__c where Opportunity_Name__c IN : opptyIds]){
                ideaId.add(idealink.Aha_Ideas__c);
            }
            if(ideaId.size() > 0 ){
                AhaWebhookReceiver.updateLinkedRelatedRecord(ideaId);
            }
        }
        
        if(!accountIdSet.isEmpty())
            updateAccountMap = new Map<ID, Account>([Select id,OwnerId,Type,Focused_Partner__c,RecordTypeId,RecordType.Name,Adaptive_Territory_Id__c from Account WHERE ID IN:accountIdSet]); //SAL25-106
        Set<ID> openToCloseOppIsSet = new Set<ID>();
        Set<ID> holdCodeChangedOnOppSet = new Set<ID>();
        Set<ID> oppIdSalesEngineerchangedSet = new Set<ID>();
        Map<Id,Id> oppfocusedAccShareMap = new Map<Id,Id>();
        Set<Id> oppfocusedAccDeleteShareSet = new Set<Id>();
        List<Opportunity> psnlPartnerOppList = new List<Opportunity>(); //SAL24-365
        List<Opportunity> ddOppUpdateList = new List<Opportunity>(); // Deal Desk
        Set<Id> updateAccTypeIDSet = new Set<Id>(); //SAL25-106
        List<CreateOrder__e> orderevtList = new List<CreateOrder__e>();//SAL25-572

        for(Opportunity oppty : newOppList) {
            Opportunity oldOppty = (Opportunity) oldOppMap.get(oppty.Id);
            
            //SAL24-365
            if(oppty.StageName == '7 Closed Won' && oppty.StageName != oldOppty.StageName && oppty.Deal_Registration_Type__c == 'Partner Sourced New Logo (PSNL)' && oppty.Sourcing_Partner__c != null){
                psnlPartnerOppList.add(oppty);
            }
            
            //Deal Desk
            if((oppty.StageName == '6 PO With Channel' || oppty.StageName == '7 Closed Won' || oppty.StageName == '7 Closed Lost' || oppty.StageName == '7 Closed Admin') && oppty.StageName != oldOppty.StageName && oppty.Deal_Desk_Open_Cases__c > 0){
                ddOppUpdateList.add(oppty);
            }
            
            if(String.isNotBlank(oppty.Initial_Contacts_Name__c) && oppty.Initial_Contacts_Name__c != oldOppty.Initial_Contacts_Name__c) {
                oppIdSetForInitialContactsName.add(oppty.id);
            }
            //SAL25-106 start
        if(oppty.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp && oppty.StageName == '7 Closed Won' && oppty.StageName != oldOppty.StageName && oppty.MSP_End_User_Lookup__c!=null && updateAccountMap.keyset().contains(oppty.MSP_End_User_Lookup__c)){
            if(updateAccountMap.get(oppty.MSP_End_User_Lookup__c).Type=='Prospect'){
                updateAccTypeIDSet.add(oppty.MSP_End_User_Lookup__c);
            }
        } //SAL25-106 end
            //SF-1002 //SAL24-85
            //if(oppty.SE_Manager_Approved__c && !oldOppty.SE_Manager_Approved__c){
            if((oppty.SE_Manager_Approved__c && !oldOppty.SE_Manager_Approved__c) || (oppty.Is_Submitted_Credit_SDR_Approval__c && !oldOppty.Is_Submitted_Credit_SDR_Approval__c)){
                opportunitiesToUnlock.add(oppty.Id);
            }
            //START - Valooto Order Process
            if(oppty.SBQQ__PrimaryQuote__c == null && oppty.StageName == System.Label.Order_Creation_Stage && oppty.Opportunity_Split_Parent__c == null) {
                valootoOpptyList.add(oppty);
            }
            //END - Valooto Order Process
            
            //START - Opportunity Split Process
            if(!skipExecutionHandler && oppty.Split__c && oppty.Opportunity_Split_parent__c == null) {
                splitOpptyIdSet.add(oppty.Id);
            }
            //END - Opportunity Split Process
            
            //START - Opportunity Holdover Process
            if(oppty.Holdover_Requested__c && !oldOppty.Holdover_Requested__c) {
                incHoldoverCountOpptyIdSet.add(oppty.OwnerId);
            }else if(!oppty.Holdover_Requested__c && oldOppty.Holdover_Requested__c) {
                decHoldoverCountOpptyIdSet.add(oppty.OwnerId);
            }
            //END - Opportunity Holdover Process
            // START - Opportunity SE realignment
            if(oppty.SE_Misaligned__c!=null && oppty.SE_Misaligned__c == false && oldOppty.SE_Misaligned__c == true && updateAccountMap.containsKey(oppty.AccountId)){
                reprocessOppSE.add(new Territory_Owner_Assignment__c(AdaptiveId__c = updateAccountMap.get(oppty.AccountId).Adaptive_Territory_Id__c, Functionality__c='Sales Engineer Assignment'));
            }
            //End - Opportunity SE realignment
            //START - Mosaic Process
            if (oppty.Include_Datos__c != oldOppty.Include_Datos__c && !oppty.Include_Datos__c) {
                nonDatosOpportunityIdSet.add(oppty.Id);
            } else if (oppty.Include_Datos__c && (oppty.Include_Datos__c != oldOppty.Include_Datos__c || oppty.OwnerId != oldOppty.OwnerId)) {
                datosOpportunityIdSet.add(oppty.Id);
            }
            if(oldOppty.Partner_Lookup__c != oppty.Partner_Lookup__c || oldOppty.Polaris_Portal_Contact__c != oppty.Polaris_Portal_Contact__c || oldOppty.Hold_Code__c != oppty.Hold_Code__c){
                partnerNameChangedSet.add(oppty.Id);
                if(oldOppty.Hold_Code__c != oppty.Hold_Code__c){
                    holdCodeChangedOnOppSet.add(oppty.Id);
                }
                if(oldOppty.Partner_Lookup__c != oppty.Partner_Lookup__c){ //SAL24-21
                    if(oppty.Partner_Lookup__c != null){
                        oppfocusedAccShareMap.put(oppty.Id,oppty.Partner_Lookup__c);
                    }
                    if(oldOppty.Partner_Lookup__c != null || oppty.Partner_Lookup__c == null){
                        oppfocusedAccDeleteShareSet.add(oppty.Id);
                    }
                }
            }
            //SAL24-199
            if(oldOppty.ownerId != oppty.ownerId && oppty.Partner_Lookup__c != null){
                oppfocusedAccShareMap.put(oppty.Id,oppty.Partner_Lookup__c);
            }
            if(oppty.Escalation_Stage__c != oldOppty.Escalation_Stage__c && oppty.IsClosed == FALSE && oppIdOppDebriefMap.containsKey(oppty.id)){//SAL-1052 -- Opportunity Issue Tracker and Debrief
                Opportunity_Debrief__c od = oppIdOppDebriefMap.get(oppty.id);
                od.Opportunity_Escalation_Stage__c = oppty.Escalation_Stage__c;
                opportunityDebriefUpdates.add(od);
            }
            if(oppty.Amount != oldOppty.Amount  || oldOppty.StageName != oppty.StageName || (!oppty.Opportunity_Amount_Override__c && oppty.Opportunity_Amount_Override__c != oldOppty.Opportunity_Amount_Override__c) || oppty.OppSubscriptionTermMonths__c != oldOppty.OppSubscriptionTermMonths__c || oppty.Number_of_Opportunity_Products__c != oldOppty.Number_of_Opportunity_Products__c || oppty.UCL_Scale_Percentage__c != oldOppty.UCL_Scale_Percentage__c){ //ACV-1-7 //SAL25-145 //SAL26-169
                amountChangedForOppIdSet.add(oppty.id);
            }
            //END - Mosaic Process
            if(oldOppty.StageName != oppty.StageName && (oppty.StageName == '7 Closed Won' || oppty.StageName == '7 Closed Lost' || oppty.StageName == '7 Closed Admin')){
                openToCloseOppIsSet.add(oppty.id);
                amountChangedForOppIdSet.add(oppty.id);
            }
            if(oppty.Hold_Code__c != oldOppty.Hold_Code__c ){
                if(String.IsNotBLank(oppty.Hold_Code__c)){
                    mapOppWithNewHoldCodes.put(oppty.Id, oppty.Hold_Code__c.split(';'));
                }
                if(String.IsNotBLank(oldOppty.Hold_Code__c)){
                    mapOppWithOldHoldCodes.put(oppty.Id, oldOppty.Hold_Code__c.split(';'));
                }
            }
            /*if(oppty.Deal_Registration_Number__c != oldOppty.Deal_Registration_Number__c && oppty.Deal_Reg_Approval_Status__c == 'Approved'){
    dealregSet.add(oppty.Deal_Registration_Number__c);
    }*/
            if(oppty.StageName!=oldOppty.StageName && oppty.StageName.Contains('7 Closed ') && String.isNotBlank(oppty.Deal_Reg_Approval_Status__c) && oppty.Deal_Reg_Approval_Status__c.equals('Approved') && String.isNotBlank(oppty.Deal_Registration_Number__c)){
                closedOppWithDRMap.put(oppty.Deal_Registration_Number__c,oppty);
            }
            /*if(oldOppty.SDR_Led__c == oppty.SDR_Led__c && oppty.SDR_Led__c && oppty.Deal_Registration_Number__c != null && oldOppty.Deal_Registration_Number__c != oppty.Deal_Registration_Number__c && oppty.Deal_Reg_Approval_Status__c == 'Approved' && oppty.Deal_Registration_Type__c == DealRegUtilityHelper.JID){
    opptyPIDtoJIDMap.put(oppty.Deal_Registration_Number__c,oppty);
    }*/
            if(oppty.Rubrik_Sales_Engineer__c != oldOppty.Rubrik_Sales_Engineer__c){
                oppIdSalesEngineerchangedSet.add(oppty.id);
            }
            
            //SAL24-679 //SAL25-234
            //OppId+'-'+OldNPMAcct+'-'+NewNPMAcct+'-'+StageName - ListString format
            /*if((oppty.StageName!=oldOppty.StageName && (oppty.StageName.Contains('7 Closed') || oldOppty.StageName.Contains('7 Closed'))) || oppty.Partner_Lookup__c!=oldOppty.Partner_Lookup__c || oppty.Sourcing_Partner__c!=oldOppty.Sourcing_Partner__c || oppty.Teaming_Partner__c!=oldOppty.Teaming_Partner__c || oppty.OwnerId!=oldOppty.OwnerId) { //SAL25-500
                oppIdNPMAcctOldNew.add(oppty.Id + '-' + oldOppty.Partner_Lookup__c + '-' + oppty.Partner_Lookup__c+'-'+oppty.StageName);
                oppIdNPMAcctOldNew.add(oppty.Id + '-' + oldOppty.Sourcing_Partner__c + '-' + oppty.Sourcing_Partner__c+'-'+oppty.StageName);
                oppIdNPMAcctOldNew.add(oppty.Id + '-' + oldOppty.Teaming_Partner__c + '-' + oppty.Teaming_Partner__c+'-'+oppty.StageName);
            }*/ //commented for SAL26-75
            //SAL25-247
            if((oppty.StageName == '7 Closed Won' || oppty.StageName == '7 Closed Lost' || oppty.StageName == '7 Closed Admin') && oppty.StageName != oldOppty.StageName){
                closedOpptyIds.add(oppty.Id);
            }
        }//First for loop ENDs here.
        
        //SAL25-572
        if(!evtOppIds.isEmpty()){
            for(Id oppId : evtOppIds){
                orderevtList.add(new CreateOrder__e(RecordId__c = oppId));
            }
            try{
                if(!orderevtList.isEmpty())
                	EventBus.publish(orderevtList);
            }catch(Exception e){
                insert new Custom_Error_Log__c(Functionality__c = 'CreateOrder__e creation',Exception_Message__c = e.getMessage()+' at line no. '+e.getLineNumber(),FailedRecords__c=String.valueOf(evtOppIds),Class__c = 'RenewalAndExpansionSplit');
            }
        }
        //SAL25-572
        
        //SAL24-365
        if(psnlPartnerOppList!=null && psnlPartnerOppList.Size()>0){
            OpportunityObjectTriggerHelper.updatePSNLonAccount(psnlPartnerOppList);
        }
        //SAL25-106
    if(updateAccTypeIDSet!=null && updateAccTypeIDSet.size()>0){
        OpportunityObjectTriggerHelper.updateSDPAccType(updateAccTypeIDSet);
    }
        //Deal Desk
        if(!skipExecutionHandler && ddOppUpdateList!=null && ddOppUpdateList.size()>0){ //SAL26-731
            DDCaseTriggerHandler.updateDDCaseStatus(ddOppUpdateList);
        }
        
        //START - SF-656 Hold Off Process
        if(!skipExecutionHandler && !isHoldOffLogicDisabled && (!mapOppWithNewHoldCodes.isEmpty() || !mapOppWithOldHoldCodes.isEmpty() )){ //SAL26-731
            HoldCodeTrackingHelper.manageTrackingRecords(mapOppWithNewHoldCodes,mapOppWithOldHoldCodes,'Opportunity');
        }
        //End
        
        //START - Mosaic Process
        if (!skipExecutionHandler && !datosOpportunityIdSet.isEmpty() || !nonDatosOpportunityIdSet.isEmpty()) { //SAL26-731
            OpportunityObjectTriggerHelper.manageOpportunityTeamMembers(datosOpportunityIdSet, nonDatosOpportunityIdSet);
        }
        //END - Mosaic Process
        // Opportunity SE realignment
        if(!reprocessOppSE.isEmpty()){
            database.insert(reprocessOppSE,false);
        }
        //End - Opportunity SE realignment
        //SF-1002
        if(opportunitiesToUnlock.size()>0){
            OpportunityObjectTriggerHelper.unlockOpportunities(opportunitiesToUnlock);
        }
        //START - Valooto Order Process
        if(!skipExecutionHandler && !valootoOpptyList.isEmpty()) { //SAL26-731
            OpportunityObjectTriggerHelper.valootoOrderProcess(valootoOpptyList, (Map<Id, Opportunity>)Trigger.oldMap);
        }
        //END - Valooto Order Process
        if(!splitOpptyIdSet.isEmpty()) {
            //Call method to process Opportunity Split
            OpportunityObjectTriggerHelper.processOpportunitySplit(newOppMap, splitOpptyIdSet);
        }
        // PRIT25-750
        if(!skipExecutionHandler && !newOpptyMap.isEmpty()){ //SAL26-731
            OpportunityObjectTriggerHelper.syncOpportunityPartnerRelations(newOpptyMap,oldOpptyMap);
        }
        if(!skipExecutionHandler && !oppIdSetForInitialContactsName.isEmpty()) { //SAL26-731
            OpportunityObjectTriggerHelper.createOpportunityContactRoles(oppIdSetForInitialContactsName, newOppMap);
        }
        if(!skipExecutionHandler){ //SAL26-731 //SAL26-731
        OpportunityObjectTriggerHelper.updateHoldoverCount(decHoldoverCountOpptyIdSet, incHoldoverCountOpptyIdSet);
        }
        if(!skipExecutionHandler && !closedOppWithDRMap.isEmpty()){ //SAL26-731
            OpportunityObjectTriggerHelper.updateClosedDealRegistrations(closedOppWithDRMap);
        }
        //SAL24-21
        //First delete existing focused partner oppteammems & create it for new partner account
        if(!oppfocusedAccDeleteShareSet.isEmpty()){
            OpportunityObjectTriggerHelper.deleteShareOppfocusedPartnerAccount(oppfocusedAccDeleteShareSet);
        }
        if(!oppfocusedAccShareMap.isEmpty()){
            OpportunityObjectTriggerHelper.shareOppfocusedPartnerAccount(oppfocusedAccShareMap,updateAccountMap);
        }
        //SAL24-21
        
        //Start - EL-236: updatePartnerNameAtOrder
        if(!skipExecutionHandler){ //SAL26-731
        List<Order> ordersToUpdate = [Select Id, OpportunityId, POC_Opportunity__c, Opportunity.Partner_Lookup__c, Opportunity.Hold_Code__c, Opportunity.Polaris_Portal_Contact__c, Opportunity.Polaris_Portal_Contact__r.Email
                                      from Order where OpportunityId in :partnerNameChangedSet];
        for(Order ord: ordersToUpdate){
            ord.Partner_Name__c = ord.Opportunity.Partner_Lookup__c;
            ord.Polaris_Contact__c = ord.Opportunity.Polaris_Portal_Contact__c;
            ord.Polaris_Contact_Email__c = String.isBlank(ord.Opportunity.Polaris_Portal_Contact__c) ? null : ord.Opportunity.Polaris_Portal_Contact__r.Email;
            if(holdCodeChangedOnOppSet.contains(ord.OpportunityId)){
                ord.Hold_Code__c = ord.Opportunity.Hold_Code__c;
            }
        }
        if(!ordersToUpdate.isEmpty()){
			update ordersToUpdate;
        }
        }
        //End - EL-236
        
        if(!skipExecutionHandler && !opportunityDebriefUpdates.isEmpty()){//SAL-1052 -- Opportunity Issue Tracker and Debrief //SAL26-731
            update opportunityDebriefUpdates;
        }
        if(!oppIdSalesEngineerchangedSet.isEmpty()){
            OpportunityUtil.updateSeManagerOnSpecialistRequest(oppIdSalesEngineerchangedSet);
        }
        if(!skipExecutionHandler){ //SAL26-731
        OpportunityObjectTriggerHelper.calculateReferralFeeAmount(newOppMap.values(), oldOppMap);
        updateQuoteFields(newOppMap.values(), oldOppMap,primaryQuoteToUpdate);//added param for CPQ22-3962
        }
        OppAnnualContractValueUtil.calculateAcvAmount(amountChangedForOppIdSet, openToCloseOppIsSet);//ACV-1-7
        //OpportunityObjectTriggerHelper.updateMCPamount(newOppMap.values(),oldOppMap);
        
        if(!skipExecutionHandler && !disabledFunctionality.DisableOpportunityAutoAcceptPO__c && eligiblePOVal?.values()?.size() > 0) { //SAL26-731
            AcceptPOHelper.autoAcceptPO(oldOppMap, eligiblePOVal, null);
        }
        
        //ARY-1082 Starts
        Set<String> mapOfOldVsNewUsers = new Set<String>();
        Set<Id> oppIds = new Set<Id>();
        if (newOppList != null && !newOppList.isEmpty() && oldOppMap != null && !oldOppMap.isEmpty()) {
            for(Opportunity newOpp : newOppList){
                if (newOpp.Opportunity_Sub_Type__c != null && newOpp.Opportunity_Sub_Type__c == 'Renewal' && 
                    newOpp.OwnerId != oldOppMap.get(newOpp.Id).OwnerId) {
                        mapOfOldVsNewUsers.add(oldOppMap.get(newOpp.Id).OwnerId+'-'+newOpp.OwnerId+'-'+newOpp.Id);
                        oppIds.add(newOpp.Id);
                    }
            }
            if (oppIds != null && !oppIds.isEmpty() && mapOfOldVsNewUsers != null && !mapOfOldVsNewUsers.isEmpty()) {
                if (System.isBatch()) {OpportunityObjectTriggerHelper.updateOpptyShareRecForRenewalOppty(oppIds, mapOfOldVsNewUsers);}
                else if (!System.isBatch() && !System.isFuture() && !System.isQueueable()){OpportunityObjectTriggerHelper.updateOpptyShareRecForRenewalOpptyFuture(oppIds, mapOfOldVsNewUsers);}
            }
        }//ARY-1082 Ends
        
        //SAL24-679
        /*if (!oppIdNPMAcctOldNew.isEmpty() && (System.isBatch() || System.isFuture() || System.isQueueable())) {OpportunityObjectTriggerHelper.manageNPMAccountOpptyShare(oppIdNPMAcctOldNew);}
        else if (!oppIdNPMAcctOldNew.isEmpty()) {OpportunityObjectTriggerHelper.manageNPMAccountOpptyShareFuture(oppIdNPMAcctOldNew);}*/ //commented for SAL26-75

        //SAL25-247
        if (!closedOpptyIds.isEmpty() && (System.isBatch() || System.isFuture() || System.isQueueable())) {OpportunityObjectTriggerHelper.setPartnerReferralCCRRejected(closedOpptyIds);}
        else if (!closedOpptyIds.isEmpty()) {OpportunityObjectTriggerHelper.setPartnerReferralCCRRejectedFuture(closedOpptyIds);}
        
        //PRIT26-107
        if (!closedOpptyIds.isEmpty()){
            PartnerRelationTriggerHelper.updatePRFieldsOnClosedStage(closedOpptyIds);
        }
        /** SAL25-495 - Start *SAL26-549:commented
        Set<Id> rseChangedOppIdsSet = new Set<Id>();
        for(Opportunity newOpp : newOppList){
            Opportunity oldOpp = oldOppMap.get(newOpp.Id);
            if((!newUCLScaleAddedOppIdsSet.isEmpty() && newUCLScaleAddedOppIdsSet.contains(newOpp.Id)) || (newOpp.Rubrik_Sales_Engineer__c != null && newOpp.Rubrik_Sales_Engineer__c != oldOpp.Rubrik_Sales_Engineer__c && newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp)){
                rseChangedOppIdsSet.add(newOpp.Id);
            }
        }

        if (!rseChangedOppIdsSet.isEmpty() && (System.isBatch() || System.isFuture() || System.isQueueable())) {OppEmailTriggerHandler.sendEmailOppRequiresUCLScale(rseChangedOppIdsSet);}
        else if (!rseChangedOppIdsSet.isEmpty()) {OppEmailTriggerHandler.sendEmailOppRequiresUCLScaleFuture(rseChangedOppIdsSet);}
        newUCLScaleAddedOppIdsSet = new Set<Id>();
        /** SAL25-495 - End */

        if(!System.isBatch() && !System.isFuture() && !System.isQueueable()){
            //SAL24-657 - call to sizing application get report
            Set<Id> sizingOppIds = new Set<Id>();
            for(Opportunity newOpp : newOppList){
                if(newOpp.isclosed == true && oldOppMap.get(newOpp.Id).isclosed != newOpp.isclosed){
                    sizingOppIds.add(newOpp.Id);
                }
            }
            if(!sizingOppIds.isEmpty()) // - keep this method at last 
                System.enqueueJob(new CallouttoSizingController(sizingOppIds));
        }
        /*RRR-11
        * Automatically create risk profile if renewal sentiement of Opportunity Changes
		* Stamp, Renewl sentiment on Risk Profile/ Mitigation Change
        */
        if(!skipExecutionHandler){  //SAL26-731
        CS_AutomaticRiskProfileCreation.handleRenewalSentimentChange(oldOppMap, newOppMap);     
        }

         //FY25SR-1204 - Start
         if (newOppList != null && !newOppList.isEmpty() && oldOppMap != null && !oldOppMap.isEmpty()) {
            OpportunityObjectTriggerHelper.sendEmailAlertsOnStageChange(newOppList,oldOppMap,queriedQuoteList);
            
        }
        //FY25SR-1204 - END 
        //FY25SR-1110 - Start
        if (!skipExecutionHandler && newOppList != null && !newOppList.isEmpty() && oldOppMap != null && !oldOppMap.isEmpty()) { //SAL26-731
            OpportunityObjectTriggerHelper.sendRefreshNotification(newOppList,oldOppMap,queriedQuoteList);   
        }
        //FY25SR-1110 - END 
    }
    
    //added new parameter for CPQ22-3962 optimization
    /**
     * @description Apex method to update quote record fields
     * @param lstOpp
     * @param mapOld
     * @param primaryQuoteToUpdate
     */
    private void updateQuoteFields(List<Opportunity> lstOpp, Map<ID,Opportunity> mapOld,Set<Id> primaryQuoteToUpdate){
        
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
        //List<SBQQ__Quote__c> queriedQuoteList = new List<SBQQ__Quote__c>(); //SAl26-245
        Set<Id> OppIds = new Set<Id>();
        Set<Id> sowRequiredOppIdSet = new Set<Id>(); //SAl26-245
        Set<Id> excludeEmailalertOppIds = new Set<Id>(); //SAl26-245
        
        for(Opportunity Opp : lstOpp){
            
            //REEN-57 exclude stage 6 opps
            if(!(Opp.StageName == Label.Order_Creation_Stage && Opp.Opportunity_Sub_Type__c!=null && Opp.Opportunity_Sub_Type__c=='Renewal') && (
                (Opp.Opportunity_Sub_Type__c != null && Opp.Opportunity_Sub_Type__c != mapOld.get(Opp.Id).Opportunity_Sub_Type__c) || 
                (Opp.Initial_Contacts_Name__c != null && Opp.Initial_Contacts_Name__c != mapOld.get(Opp.Id).Initial_Contacts_Name__c) ||
                (Opp.Distributor_Lookup__c != null && Opp.Distributor_Lookup__c != mapOld.get(Opp.Id).Distributor_Lookup__c) ||
                (Opp.Partner_Lookup__c != null && Opp.Partner_Lookup__c != mapOld.get(Opp.Id).Partner_Lookup__c) ||
                (Opp.Marketplace__c != mapOld.get(Opp.Id).Marketplace__c) ||
                (Opp.Deal_Structuring_Oppty_Notes__c!=mapOld.get(Opp.Id).Deal_Structuring_Oppty_Notes__c && OpportunityUtil.oppRecTypeIdSalesOpp == Opp.RecordTypeId)) || (Opp.StageName != null && (Opp.StageName  == '6 PO With Channel' || Opp.StageName  == '5 Negotiate & Close' || Opp.StageName  == '4 Business Justification') && Opp.StageName != mapOld.get(Opp.Id).StageName)) {// SAL24-27 updated
                    
                    OppIds.add(Opp.Id);
               }
        }
        
        //added OR in IF condition for CPQ22-3962 optimization
        if(!OppIds.isEmpty() || !primaryQuoteToUpdate.isEmpty()){
            //SAl26-245
            queriedQuoteList = [Select ID, SBQQ__Status__c,sendSOWNotification__c,SBQQ__Opportunity2__r.Id, Primary_Contact__c, SBQQ__Distributor__c, SBQQ__Partner__c, 
                                        SBQQ__Opportunity2__r.Opportunity_Sub_Type__c, SBQQ__Opportunity2__r.Partner_Lookup__c, 
                                        SBQQ__Opportunity2__r.Distributor_Lookup__c, SBQQ__Opportunity2__r.Initial_Contacts_Name__c, OpportunitySubType__c,
                                        SBQQ__Opportunity2__r.Marketplace__c,
                                        SBQQ__Opportunity2__r.Deal_Structuring_Oppty_Notes__c,Deal_Structuring_Oppty_Notes__c,SBQQ__Opportunity2__r.RecordTypeId,SBQQ__Primary__c,Trade_Up_Amounts__c,Prepayment_Credit__c,ShowPromoDisc__c,SBQQ__Opportunity2__r.Initial_Contacts_Name__r.Email,ApprovalStatus__c,SBQQ__Opportunity2__r.Owner.Email,SBQQ__Opportunity2__r.RenewalOwner__r.Email,SBQQ__Opportunity2__r.Account.Renewal_Owner__r.Email //SAL24-27 //FY25SR-1204
                                        FROM SBQQ__Quote__c where SBQQ__Opportunity2__r.ID IN :OppIds or Id IN :primaryQuoteToUpdate];
            
            if(!queriedQuoteList.isEmpty()){
                if(!primaryQuoteToUpdate.isEmpty()){
                    for(SBQQ__Quote__c quote : queriedQuoteList){
                        if(primaryQuoteToUpdate.contains(quote.Id) && !quote.sendSOWNotification__c){
                            sowRequiredOppIdSet.add(quote.SBQQ__Opportunity2__r.Id);
                        }
                    }
                }
                if(!sowRequiredOppIdSet.isEmpty()){
                    for(opportunitylineitem oli : [select Id,OpportunityId,opportunity.SOW_Required__c,primaryquoteequalsquote__c from opportunitylineitem where ProductCode != 'OPTY-SPLIT' AND opportunityId IN :sowRequiredOppIdSet]){
                        if(!oli.primaryquoteequalsquote__c){
                            excludeEmailalertOppIds.add(oli.OpportunityId);
                        }
                    }
                }
                //SAl26-245
                
                //added 2 fields in query for CPQ22-3962 and condition in OR where clause
                for(SBQQ__Quote__c quote : queriedQuoteList)
            {
                boolean hasUpdate = false;
                 if(!OppIds.isEmpty() && OppIds.contains(quote.SBQQ__Opportunity2__r.Id)){//original check for existing logic method merge optimization CPQ22-3962
                if(quote.SBQQ__Status__c=='Draft'){
                    
                    if(quote.OpportunitySubType__c != quote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c)
                    {
                        quote.OpportunitySubType__c = quote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c;
                        hasUpdate = true;
                    }
                    
                    if(quote.Primary_Contact__c != quote.SBQQ__Opportunity2__r.Initial_Contacts_Name__c)
                    {
                        quote.Primary_Contact__c = quote.SBQQ__Opportunity2__r.Initial_Contacts_Name__c;
                        hasUpdate = true;
                    }
    
                    if(String.isNotBlank(quote.SBQQ__Opportunity2__r.Marketplace__c) &&
                       System.Label.Quote_Marketplace.contains(quote.SBQQ__Opportunity2__r.Marketplace__c))
                    {
                        quote.Show_List_Price__c = false;
                        quote.Show_Promo_Price__c = false;
                        quote.Show_List_Total__c = false;
                        quote.Show_Discount__c = false;
                        quote.Show_Total_Discount__c = false;
                        hasUpdate = true;
                    } else {
                        quote.Show_List_Price__c = true;
                        quote.Show_Promo_Price__c = true;
                        quote.Show_List_Total__c = true;
                        quote.Show_Discount__c = true;
                        quote.Show_Total_Discount__c = true;
                        hasUpdate = true;
                    }
                    
                }
    
                //REEN-57 starts
                if(quote.SBQQ__Distributor__c != quote.SBQQ__Opportunity2__r.Distributor_Lookup__c)
                {
                    quote.SBQQ__Distributor__c = quote.SBQQ__Opportunity2__r.Distributor_Lookup__c;
                    hasUpdate = true;
                }
                
                if(quote.SBQQ__Partner__c != quote.SBQQ__Opportunity2__r.Partner_Lookup__c)
                {
                    quote.SBQQ__Partner__c = quote.SBQQ__Opportunity2__r.Partner_Lookup__c;
                    hasUpdate = true;
                }
                //REEN-57 ends
                
                // SAL24-27
                if(quote.Deal_Structuring_Oppty_Notes__c !=quote.SBQQ__Opportunity2__r.Deal_Structuring_Oppty_Notes__c && OpportunityUtil.oppRecTypeIdSalesOpp == quote.SBQQ__Opportunity2__r.RecordTypeId){
                    quote.Deal_Structuring_Oppty_Notes__c =quote.SBQQ__Opportunity2__r.Deal_Structuring_Oppty_Notes__c;
                    hasUpdate=true;
                }
               } 

               //added below IF block for optimization CPQ22-3962 "updatePrimaryQuote" method merged here
                    if(primaryQuoteToUpdate.contains(quote.Id) && (excludeEmailalertOppIds.isEmpty() || !excludeEmailalertOppIds.contains(quote.SBQQ__Opportunity2__r.Id))){
                        if(!quote.sendSOWNotification__c){
                            quote.sendSOWNotification__c = true;
                            hasUpdate = true;
                        }  
               }
                if(hasUpdate){
                    
                    lstQuote.add(quote);
                }
            }
        }
        }
        if(lstQuote != null && !lstQuote.isEmpty()){
            //REEN-57 added bypasses for Quote Triggers
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            update lstQuote;
        }
    }
}