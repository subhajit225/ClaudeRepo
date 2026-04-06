/**
 * @Author      : 
 * @CreatedDate : 
 * @TstClass    : AccountTriggersHandler_Test
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1550          Vijay Kumar K R          Mar 14, 2023    [FedRAMP] Disable proactive cases
 * CS21-2006          Vijay Kumar K R          Nov 21, 2023    [FedRAMP 1.5] Enable case creation with email for hybrid RSC-G/RSC/CDM customers
 * PRIT25-128         Anshul Gupta             April, 2024     Company Name update on user on partner account name change
 * RRR-3              Sushant Arora            Nov 19, 2024    Automatic creation of Risk profile when CX Score changes
 * RRR-114            Sushant Arora            Jul 01, 2025    Removed RRR-3 logic and moved to the Account Risk object
 * -------------------------------------------------------------------------
 */
public class AccountTriggersHandler extends TriggerHandler {
    private static string USFEDRALSUPPORT='U.S. Federal Support (Legacy)';
    public static boolean disablePatchManagerUpdate = false;
    public static boolean disableCaseTeamMemberUpdate = false; //SAL24-735 - ETM H1FY25
    private Boolean isDisabled = false;
    @TestVisible
    private static Id partnerAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
    private static Set<ID> accountIdSet = new Set<ID>();
    private Boolean isEmaiAlertDisabled = false; //SAL24-675
    private Boolean isUSCitizenValidationDisabled = false; //CS21-3771
    private Boolean usCitizenValidationByPass = false;
    public static List<Sync_To_NS_On_Order_Event__e > syncToNsEvents = new List<Sync_To_NS_On_Order_Event__e>();//PRDOPS26-1071

    //CS21-2006:
    private static final String FEDRAMP_RSC_CDM_LABEL = System.label.FedRAMP_RSC_G_For_Case_Creation;
    //SAL24-798n799
    private static Boolean byPassExecution = false;//PRIT25-128
    String unassignedRenewalOwnerId = [select DeveloperName, Field_Value__c
                                       from Territory_Management_Setup__mdt
                                       where DeveloperName = 'Unassigned_Renewal_OwnerId']?.Field_Value__c;
    public AccountTriggersHandler(){
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_Account_Triggers__c;
        isEmaiAlertDisabled = disabled.Disable_Account_Email_Alerts__c; //SAL24-675

        ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
        isUSCitizenValidationDisabled = disabled.Disable_US_Citizen_Entitlement_Check__c; //CS21-3771
        usCitizenValidationByPass = TriggerConditionsBypass.isByPassed('USCitizenValidationByPass'); //CS21-3771 
        //this.setMaxLoopCount(2);
    }

    public override void beforeInsert() {
        if(!isDisabled) {
            System.debug('Inside AccountTriggerHandler - beforeInsert');
            Set<string> customerTypeSet = new Set<String>{'Customer','Reseller','Distributor','MSP-Reseller','MSP','MSP Customer','Marketplace','Alliance Partner','FSI','OEM'};
            if(PatchManager.ROUTE_ON_INSERT_ACCOUNT){
                Map<String, List<PatchManager__c>> patchMap = PatchManager.getPatchMap(Trigger.new, PatchManager.ACCOUNT);
                AccountTriggerHelper.patchManagerAssignment(Trigger.new, patchMap, true);
            }
            //SF-3683
            AccountTriggerHelper.setDefaultSegmentAssignment(Trigger.new, (Map<Id, Account>)Trigger.oldMap, true);
            
            //SAL23-275
            Set<Id> accOwnerIds = new Set<Id>();
            for(Account act : (List<Account>) Trigger.new) {
                accOwnerIds.add(act.OwnerId);
                // CS21-1550: [FedRAMP] Disable proactive cases
                if(isChanged('RSC_G_Support__c', act)){
                    disableProactiveCaseCreation(act);
                }
                //SAL24-656 //Commented as part of SAL26-1087
                /*if(customerTypeSet.contains(act.Type)){
                    act.NDA_in_Place__c = 'Yes';
                }*/

                //Updated as part of SAL26-1087
                if(act.Type != 'Prospect' && String.isNotBlank(act.Type)){ 
                    act.NDA_in_Place__c = 'Yes';
                }
				 if(act.RSC_G_Eligible__c && act.RSC_G_Account_Sync_status__c != 'In-Progress'){
                    act.RSC_G_Account_Sync_status__c = 'In-Progress';
                 }
                //SAL24-798n799 
                act.Renewal_Owner__c = act.Renewal_Owner__c == null && unassignedRenewalOwnerId != null ? unassignedRenewalOwnerId : act.Renewal_Owner__c;
                //Added for CS21-3192
                List<String> USCitizenFieldValues = act.U_S_citizen_service__c != null ? act.U_S_citizen_service__c.split(';') : new List<String>();
                if(!act.US_Federal_Account__c && USCitizenFieldValues.contains(USFEDRALSUPPORT) ){
                    act.US_Federal_Account__c=True;
                }
                
                //SAL26-11
                if(String.isnotBlank(act.Type) && act.Type.equalsIgnoreCase('Customer')){
                    act.Contract_Marketing_Opt_Out__c = true;
                    act.Contract_Marketing_Opt_Out_Date__c = System.now();
                }
            }
            AccountTriggerHelper.populateEtmTartValues(null, accOwnerIds, Trigger.new);
            AccountTriggerHelper.setSupportPortalFeatures(Trigger.new); //CS21-1052
        }
    }

    public override void beforeUpdate() {
        List<String> adapTerrIds = new List<String>(); //Pooled SE
        List<String> adapTerrIdsForPooledRSE = new List<String>(); //Pooled SE
        //SAL23-275
        Set<Id> accIdsForTartUpdate = new Set<Id>();
        Set<Id> accOwnerIds = new Set<Id>();
        Map<Id,Account> oldMap = new Map<Id,Account>(); 
        oldMap = (Map<Id,Account>)Trigger.oldMap;
        Set<Id> accIdsForUSCitizenUpdate = new Set<Id>(); //Added for CS21-3192
        Set<Id> accIdsWithActiveEntitlement = new Set<Id>(); //Added for CS21-3192
        Set<Id> accIdsForJIRA = new Set<Id>(); //Added for CS21-3643
        Set<string> customerTypeSet = new Set<String>{'Customer','Reseller','Distributor','MSP-Reseller','MSP','MSP Customer','Marketplace','Alliance Partner','FSI','OEM'};
            
        if(isDisabled == false && disablePatchManagerUpdate == false) {
            System.debug('Inside AccountTriggerHandler - beforeUpdate');
            List<Account> PartnerAccounts = new List<Account>();
            for(Account acct : (List<Account>) Trigger.new){
                Account oldAct = oldMap.get(acct.id);

				//SAL26-11
                if(String.isnotBlank(acct.Type) && acct.Type.equalsIgnoreCase('Customer') && (!acct.Contract_Marketing_Opt_Out__c || acct.Contract_Marketing_Opt_Out_Date__c == null)){
                    acct.Contract_Marketing_Opt_Out__c = true;
                    acct.Contract_Marketing_Opt_Out_Date__c = System.now();
                }

                //Added for CS21-3192
                List<String> USCitizenFieldValues = acct.U_S_citizen_service__c != null ? acct.U_S_citizen_service__c.split(';') : new List<String>();
                List<String> USCitizenFieldOldValues = oldAct.U_S_citizen_service__c != null ? oldAct.U_S_citizen_service__c.split(';') : new List<String>();
                List<String> USCitizen = system.label.U_S_citizen_service_values.split(',');
                if(USCitizenFieldValues != USCitizenFieldOldValues){
                    if(acct.U_S_citizen_service__c == null){
                        acct.US_Federal_Account__c=False;
                    }
                    else{
                        for(String val : USCitizenFieldValues){
                            if(!oldMap.get(acct.id).US_Federal_Account__c && !acct.US_Federal_Account__c && USCitizen.contains(val) ){
                    acct.US_Federal_Account__c=True;
                } 
                        }
                    }
                } 
                if(USCitizenFieldValues.contains('Purchased') && !USCitizenFieldOldValues.contains('Purchased') && !usCitizenValidationByPass && !isUSCitizenValidationDisabled){
                    accIdsForUSCitizenUpdate.add(acct.Id);
                }
                //Added for CS21-3192 end
                if(acct.RecordTypeId == partnerAccRecordTypeId){
                    PartnerAccounts.add(acct);
				}
				if(!oldMap.get(acct.id).RSC_G_Eligible__c && oldMap.get(acct.id).RSC_G_Account_Sync_status__c != 'In-Progress' && acct.RSC_G_Eligible__c){
                    acct.RSC_G_Account_Sync_status__c = 'In-Progress';
                }
                //CS21-2170 - start
                if(Schema.sObjectType.Account.fields.RSC_G_CS_Sync_status__c.isUpdateable()){
                    if(acct.RSC_G_Eligible__c  && acct.RSC_G_CS_Sync_status__c != 'In-Progress' && acct.RSC_G_CS_Sync_status__c != 'Resync'){
                        Boolean isResyc = false;
                        for(Schema.FieldSetMember each :  SObjectType.Account.FieldSets.FedRAMP_Resync_Fields.getFields()){
                            String fieldName = each.getFieldPath();
                            if(oldAct.get(fieldName) != acct.get(fieldName)){
                                isResyc = true;
                                break;
                            }
                        }
                        if(isResyc){
                            acct.RSC_G_CS_Sync_status__c = 'Resync';
                        }
                    }
                }
                
                //CS21-2170 - end
                //CS21-3643 oldAct
                if(acct.Account_Preference__c != oldAct.Account_Preference__c &&
                   (acct.Account_Preference__c != null && (
                    acct.Account_Preference__c.contains('Premium Account') ||
                    acct.Account_Preference__c.contains('Top Account') ||
                    acct.Account_Preference__c.contains('Top Accounts (Manual exception)')||
                   	acct.Account_Preference__c.contains('Strategic Account') ) ||
                    (oldAct.Account_Preference__c != null &&
                     (oldAct.Account_Preference__c.contains('Premium Account') ||
                      oldAct.Account_Preference__c.contains('Top Account') ||
                      oldAct.Account_Preference__c.contains('Top Accounts (Manual exception)') ||
                      oldAct.Account_Preference__c.contains('Strategic Account'))
                     ))
                   ){
                       accIdsForJIRA.add(acct.Id);
                   }
            }
            if(PatchManager.ROUTE_ON_INSERT_ACCOUNT){
                if(!accountIdSet.containsAll(Trigger.newMap.keySet())){
                    Map<String, List<PatchManager__c>> patchMap = PatchManager.getPatchMap(PartnerAccounts, PatchManager.ACCOUNT); // Update
                    AccountTriggerHelper.patchManagerAssignment(PartnerAccounts, patchMap, false);
                }
            }

            AccountTriggerHelper.setDefaultSegmentAssignment(Trigger.new, (Map<Id, Account>)Trigger.oldMap, false);  //SF-3683
            AccountTriggerHelper.setInsightMatches(Trigger.new, (Map<Id, Account>)Trigger.oldMap);  //CS21-528
        }
        //Added for CS21-3192
        if(!accIdsForUSCitizenUpdate.isEmpty()){
            String us_product_types = System.Label.Account_us_citizen_products;
            for(Entitlement et : [SELECT Id, AccountId, Status, Account.U_S_citizen_service__c, Product__r.Product_Type__c FROM Entitlement WHERE AccountId IN:accIdsForUSCitizenUpdate AND Product__r.Product_Type__c =: us_product_types AND Status = 'Active']){
                accIdsWithActiveEntitlement.add(et.AccountId);
            }
        }
        //Added for CS21-3192 end
        
        //SAL22-401
        if(!isDisabled) {
            AccountTriggerHelper.setAccountFields(Trigger.new, (Map<Id,Account>)Trigger.oldMap);

            //SAL23-275
            for(Account act : (List<Account>) Trigger.new) {
                Account oldAct = (Account) Trigger.oldMap.get(act.Id);

				//SAL26-883 start
                if((act.ETM_Theatre__c == 'APAC' || act.ETM_Theatre__c == 'EMEA') && act.AWS_GCP_Cloud_Alliance_BDM__c != oldAct.AWS_GCP_Cloud_Alliance_BDM__c && act.AWS_GCP_Cloud_Alliance_BDM__c != act.MSFT_OCI_Cloud_Alliance_BDM__c){
                    act.MSFT_OCI_Cloud_Alliance_BDM__c = act.AWS_GCP_Cloud_Alliance_BDM__c;
                } else if((act.ETM_Theatre__c == 'APAC' || act.ETM_Theatre__c == 'EMEA') && act.MSFT_OCI_Cloud_Alliance_BDM__c != oldAct.MSFT_OCI_Cloud_Alliance_BDM__c && act.MSFT_OCI_Cloud_Alliance_BDM__c != act.AWS_GCP_Cloud_Alliance_BDM__c){
                    act.AWS_GCP_Cloud_Alliance_BDM__c = act.MSFT_OCI_Cloud_Alliance_BDM__c;
                } //SAL26-883 end

                if(act.OwnerId != oldAct.OwnerId) {
                    if(act.Adaptive_Territory_Id__c == null || act.Adaptive_Territory_Id__c == '') {
                        accIdsForTartUpdate.add(act.Id);
                        accOwnerIds.add(act.OwnerId);
                    }
                }
				//SAL24-656
                if(act.Type != oldAct.Type){
                    //cpmmented as part of SAL26-1087
                    /*if(customerTypeSet.contains(act.Type)){
                    	act.NDA_in_Place__c = 'Yes';
                	}else if(act.Type == 'Prospect'){
                        act.NDA_in_Place__c = 'No';
                    }*/

                    // Added as part of SAL26-1087
                    if(act.Type != 'Prospect' && String.isNOTBLANK(act.Type)){ 
                        act.NDA_in_Place__c = 'Yes';
                    }
                }
                //SAL23-417
                if(!System.isBatch() && act.Rubrik_Sales_Engineer__c != oldAct.Rubrik_Sales_Engineer__c){
                    act.Is_RSE_Added_Manually__c = act.Rubrik_Sales_Engineer__c != null ? true : false;
                }

                // CS21-1550: [FedRAMP] Disable proactive cases
                if(isChanged('RSC_G_Support__c', act)){
                    disableProactiveCaseCreation(act);
                }
                 //Pooled SE Start
                if(!system.isBatch() && !system.isFuture() && !system.isQueueable()){
                    if(!oldAct.Pooled_SE_Override__c && act.Pooled_SE_Override__c && act.Adaptive_Territory_Id__c!=''){
                        act.Rubrik_Sales_Engineer_Id__c = oldAct.Rubrik_Sales_Engineer__c; //always should have SE from Core territory
                    if(!adapTerrIds.contains(act.Adaptive_Territory_Id__c)){
                        adapTerrIds.add(act.Adaptive_Territory_Id__c);
                    }
                }
                    if(act.Pooled_SE_Override__c && act.Adaptive_Territory_Id__c!='' && act.Rubrik_Sales_Engineer__c !=null && act.Rubrik_Sales_Engineer__c != oldAct.Rubrik_Sales_Engineer__c){
                    	if(!adapTerrIdsForPooledRSE.contains(act.Adaptive_Territory_Id__c)){
                            adapTerrIdsForPooledRSE.add(act.Adaptive_Territory_Id__c);
                    	}
                    }
                    if(oldAct.Pooled_SE_Override__c && !act.Pooled_SE_Override__c &&  act.Adaptive_Territory_Id__c == oldAct.Adaptive_Territory_Id__c){
                        act.Rubrik_Sales_Engineer__c = act.Rubrik_Sales_Engineer_Id__c; //copy SE of territory
                    }
                }
                //Pooled SE End
                
                //Added for CS21-3192
                if(!accIdsWithActiveEntitlement.contains(act.Id) && accIdsForUSCitizenUpdate.contains(act.Id)){
                    act.addError(System.label.No_Active_US_entitlement_on_Account);
                }
            }

            //SAL23-275
            if(!accIdsForTartUpdate.isEmpty()) {
                AccountTriggerHelper.populateEtmTartValues(accIdsForTartUpdate,accOwnerIds,Trigger.new);
            }
            //Pooled SE Start
            if(!adapTerrIds.isEmpty()) {
                AccountTriggerHelper.verifyPooledSECheckboxonRegion(adapTerrIds,Trigger.new);
                AccountTriggerHelper.verifyPooledSEonRegion(adapTerrIds,Trigger.new);
            }
            if(!adapTerrIdsForPooledRSE.isEmpty()){
                AccountTriggerHelper.verifyPooledSEonRegion(adapTerrIdsForPooledRSE,Trigger.new);
            }
            //Pooled SE End
        }
        
        //CS21-3646
        if(!accIdsForJIRA.isEmpty()){
            ZIssueSFTriggerHandler.updateCountByAccountPreference(accIdsForJIRA);
        }
    }

    /**
     * Description: CS21-1550: [FedRAMP] Disable proactive cases + 1.5 version
     * Method: disableProactiveCaseCreation 
     * params: Account objAcc
     * return: void
     **/
    public static void disableProactiveCaseCreation(Account objAcc){
        // RSC-G Product
        if(objAcc.RSC_G_Support__c != null
            && !String.valueOf(objAcc.RSC_G_Support__c).contains(FEDRAMP_RSC_CDM_LABEL)){
                objAcc.Snooze_Alerts_Until__c = date.today().addMonths(1200);
        }
        // Not an RSC-G Product
        else{
            objAcc.Snooze_Alerts_Until__c = null;
        }
    }

    public override void beforeDelete() {}

    public override void afterInsert() {
        accountIdSet.addAll(Trigger.newMap.keySet());
	//SAL23-72
        Set<Id> parentAccountIds = new Set<Id>();
        Set<Id> syncWithGovOrgAccIds = new Set<Id>();
        for(Account act : (List<Account>) Trigger.new) {
            if(act.ParentId != null){
                parentAccountIds.add(act.ParentId);
            }
           	if(act.RSC_G_Account_Sync_status__c == 'In-Progress'){
               syncWithGovOrgAccIds.add(act.id);
            }
        }
        //SAL23-72
        if(!parentAccountIds.isEmpty()) {
            //SAL24-555
            //AccountTriggerHelper.updateChildAccountsCount(parentAccountIds);
            if(System.isBatch() || system.isFuture()) AccountTriggerHelper.updateChildAccountsCount(parentAccountIds);
            else AccountTriggerHelper.updateChildAccountsCountFuture(parentAccountIds);
        }
        if(!syncWithGovOrgAccIds.isEmpty()){
            UtilityClass.publishGovOrgSyncEvents(syncWithGovOrgAccIds, 'Account');
        }
    }

    public override void afterUpdate() {
        if(!isDisabled) {
            Map<Id, Account> ownerChangedMap = new Map<Id, Account> ();
	    Map<Id, Account> accL3eligbleChange = new Map<Id, Account> (); //Pankaj CPQ22-3392
            set<string> accSetId = new set<string>();
            Set<Id> reassignAccIds = New Set <Id> (); // Account ids whose owner has to be reassigned
            Set<Id> accountIds = new Set<Id>(); // Accounts with Contract_Negotiation__c updated to true
            Set<Id> cemChangeAccountIdSet = new Set<Id>();
			Set<Id> DeactiveSmartHandAccIds = new Set<Id>();

            Map<Id, List<string>> mapAccountWithHoldChanged = new Map<Id, List<string>> ();//PRDOPS22-518

            //SAL22-238
            List<Id> ddNotesChangedIds = new List<Id>();
            //SAL24-28
            //List<String> accIdRSEOldNew = new List<String>(); //SAL22-338
            List<String> accIdUserOldNewForTeam = new List<String>(); 
            List<Id> allianceBDMChangedIds = new List<Id>();
            Set<Id> seChangedMap = new Set<Id>();   //CS21-770 : Update Case Notification Workflow Rule To Support Expanded Use of SE Misalignment
            List<AccountAuditLog__c> auditLogs = new List<AccountAuditLog__c>(); // CS21-891 - Audit "Enforce Admin Panel" field updates - Veera
	    //SAL23-72
            Set<Id> parentAccountIds = new Set<Id>();
             Set<Id> ModifiedAccountIds = new Set<Id>(); //CPQ22 -4283
            Set<ID> parentChildAccountIdSet = new Set<ID>();
            Set<Id> tartChangeIds = new Set<Id>(); //SAL24-528
            Set<Id> syncWithGovOrgAccIds = new Set<Id>();
            Set<Id> partnerAccNameChangeIdSet = new Set<Id>();//PRIT25-128
            Set<Id> custTypeChangedAccIdsSet = new Set<Id>();//SAL26-1326
           
            for (Account act : (List<Account>)Trigger.new ){
                Account oldAct = (Account)Trigger.oldMap.get(act.Id);
                //PRDOPS26-1071
                if(oldAct.Sync_to_NetSuite__c!= act.Sync_to_NetSuite__c && act.Sync_to_NetSuite__c){
                syncToNsEvents.add(new Sync_To_NS_On_Order_Event__e(AccountId__c  = act.Id));
                }
                if (act.OwnerId != oldAct.OwnerId){
                    ownerChangedMap.put(act.Id, act);
                }
                ////CPQ22-4283
                if (act.Is_Customer_Fully_Transitioned__c != oldAct.Is_Customer_Fully_Transitioned__c){ 
                     ModifiedAccountIds.add(act.Id); 
                 }
                 if (act.isPartner && act.isPartner != oldAct.isPartner){
                    accSetId.add(act.Id);
                }
                if(act.Disable_Auto_OwnerAssignment__c != oldAct.Disable_Auto_OwnerAssignment__c && act.Disable_Auto_OwnerAssignment__c==false){
                reassignAccIds.add(act.id);
                }

                //Start - PRDOPS22-518 - AS per the story, we have added the below logic by Sreeramulu Redladinne on 02/02/2022
                if(oldAct.Contract_Negotiation__c != act.Contract_Negotiation__c && act.Contract_Negotiation__c == true){
                    accountIds.add(act.Id);
				    if(!mapAccountWithHoldChanged.containsKey(act.Id))
					mapAccountWithHoldChanged.put(act.Id, new List<string> ());

					mapAccountWithHoldChanged.get(act.Id).add('contract Negotiation');
                }
				if(oldAct.EULA_revision_Required__c != act.EULA_revision_Required__c && act.EULA_revision_Required__c == true){
                    accountIds.add(act.Id);
                    if(!mapAccountWithHoldChanged.containsKey(act.Id))
					mapAccountWithHoldChanged.put(act.Id, new List<string> ());

					mapAccountWithHoldChanged.get(act.Id).add('Eula Req True');
                }
                if(oldAct.EULA_revision_Required__c != act.EULA_revision_Required__c && act.EULA_revision_Required__c == false){
                    accountIds.add(act.Id);
                    if(!mapAccountWithHoldChanged.containsKey(act.Id))
					mapAccountWithHoldChanged.put(act.Id, new List<string> ());

					mapAccountWithHoldChanged.get(act.Id).add('Eula Req false');
                }

                // End - PRDOPS22-518
                /*
                if(oldAct.Contract_Negotiation__c != act.Contract_Negotiation__c && act.Contract_Negotiation__c == true){
                    accountIds.add(act.Id);
                }
                */
				if(oldAct.Deactivate_Smart_Hands__c!= act.Deactivate_Smart_Hands__c && act.Deactivate_Smart_Hands__c== true){
                    DeactiveSmartHandAccIds.add(act.Id);
                }
                if(oldAct.Account_SAM__c != act.Account_SAM__c){
                    cemChangeAccountIdSet.add(act.Id);
                }
                //SAL22-238 & SAL22-354 //SAL24-27 ,remove Account.Account_Deal_Ops_Notes__c from this if condition it's deprecated now
                //|| oldAct.Account_Deal_Ops_Notes__c != act.Account_Deal_Ops_Notes__c
                if(oldAct.Account_Deal_Desk_Notes__c != act.Account_Deal_Desk_Notes__c ){
                    ddNotesChangedIds.add(act.Id);
                }
                //SAL22-338
                if(act.OwnerId != oldAct.OwnerId || oldAct.Rubrik_Sales_Engineer__c != act.Rubrik_Sales_Engineer__c){ //SAL24-373
                    //SAL24-28
                    //AccId+'-'+OldRSE+'-'+NewRSE+'-'+TeamMemberRole - ListString format
                    String tmpStr = act.Id + '-' + oldAct.Rubrik_Sales_Engineer__c + '-' + act.Rubrik_Sales_Engineer__c + '-' + 'Sales Engineer'; //SAL24-28
                    //accIdRSEOldNew.add(tempStr);
                    accIdUserOldNewForTeam.add(tmpStr);
                    if(oldAct.Rubrik_Sales_Engineer__c != act.Rubrik_Sales_Engineer__c) seChangedMap.add(act.Id); //SAL24-373
                }
                //SAL24-28 // Added AWS_GCP_Cloud_Alliance_BDM__c field in if as part of SAL26-104
                if(act.OwnerId != oldAct.OwnerId || oldAct.AWS_GCP_Cloud_Alliance_BDM__c != act.AWS_GCP_Cloud_Alliance_BDM__c){ //SAL24-373 //Removed Condition as part of SAL26-101 || oldAct.Account_Alliance_BDM_Lookup__c != act.Account_Alliance_BDM_Lookup__c 
                    //AccId+'-'+OldBDM+'-'+NewBDM+'-'+TeamMemberRole - ListString format
                    // Commented below lines as part of SAL26-101
                    /*String tmpStr = act.Id + '-' + oldAct.Account_Alliance_BDM_Lookup__c + '-' + act.Account_Alliance_BDM_Lookup__c + '-' + 'Alliance BDM';
                    accIdUserOldNewForTeam.add(tmpStr);*/
                    //Added below lines as part of SAL26-104 START
                    String tmpStr1 = act.Id + '-' + oldAct.AWS_GCP_Cloud_Alliance_BDM__c + '-' + act.AWS_GCP_Cloud_Alliance_BDM__c + '-' + 'AWS/GCP Alliance Rep';
                    accIdUserOldNewForTeam.add(tmpStr1);
                    //END SAL26-104 END
                    //allianceBDMChangedIds.add(act.Id); //SAL24-472
                }
                //SAL24-28 // Added  MSFT_OCI_Cloud_Alliance_BDM__c field in if as part of SAL26-104
                if(act.OwnerId != oldAct.OwnerId || oldAct.MSFT_OCI_Cloud_Alliance_BDM__c != act.MSFT_OCI_Cloud_Alliance_BDM__c){ 
                    //Added below lines as part of SAL26-104 START
                    String tmpStr1 = act.Id + '-' + oldAct.MSFT_OCI_Cloud_Alliance_BDM__c + '-' + act.MSFT_OCI_Cloud_Alliance_BDM__c + '-' + 'MSFT/OCL Alliance Rep';
                    accIdUserOldNewForTeam.add(tmpStr1);
                    //END SAL26-104 END
                }

                //CS21-891 - Audit "Enforce Admin Panel" field updates - Veera
                if (oldAct.Enforce_Admin_User__c != act.Enforce_Admin_User__c) {
                    auditLogs.add(RubrikEnforceAdminPanelController.generateAuditLog(act, oldAct));
                }
                //CS21-891

		//SAL23-72
                if(act.ParentId != oldAct.ParentId){
                    if(act.ParentId!=null){
                        parentAccountIds.add(act.ParentId);
                        parentChildAccountIdSet.add(act.id);
                        parentChildAccountIdSet.add(act.ParentId);
                    }
                    if(oldAct.ParentId!=null) parentAccountIds.add(oldAct.ParentId);
                }
                //SAL24-528
                if(act.ETM_Theatre__c != oldAct.ETM_Theatre__c || act.ETM_Area__c != oldAct.ETM_Area__c || act.ETM_Region__c != oldAct.ETM_Region__c || act.ETM_Territory__c != oldAct.ETM_Territory__c) 
                    tartChangeIds.add(act.Id);

		//Pankaj CPQ22-3392 start
                if(act.Is_L3_Eligible_Account__c != oldAct.Is_L3_Eligible_Account__c && !System.IsFuture() && !System.isBatch()) {                    
                    accL3eligbleChange.put(act.Id, act);
                    system.debug('Pankaj account'+accL3eligbleChange);
                    UpdateL3opportunityBatch ab=new UpdateL3opportunityBatch(accL3eligbleChange.KeySet());
                    database.executeBatch(ab);
                }
                //Pankaj CPQ22-3392 end
                if(act.RSC_G_Account_Sync_status__c == 'In-Progress' && oldAct.RSC_G_Account_Sync_status__c != 'In-Progress'){
                    syncWithGovOrgAccIds.add(act.id);
                }
                //PRIT25-128
                if(oldAct.Name != act.Name && act.isPartner && act.RecordTypeId == partnerAccRecordTypeId){
                    partnerAccNameChangeIdSet.add(act.Id);
                }
                
                //SAL26-1326
                if(act.Customer_Type_Without_RCV__c != oldAct.Customer_Type_Without_RCV__c){
                    custTypeChangedAccIdsSet.add(act.Id);
                }
            }
            
            //SAL26-1326
            if(!custTypeChangedAccIdsSet.isEmpty()){
                System.enqueueJob(new OpportunityACVCalculationsQueueable(custTypeChangedAccIdsSet));
            }
            //PRDOPS26-1071
            if(!syncToNsEvents.isempty()){
                AccountTriggerHelper.firingEventWhenSyncToNSIsTrue(syncToNsEvents);
            }  
            //SAL22-238 //SAL24-28 //SAL24-472 //SAL24-528
            if(!ddNotesChangedIds.isEmpty()) {
                AccountTriggerHelper.updateQuotesDealNotesfuture(ddNotesChangedIds); 
            } //SAL24-472
            //if(!ddNotesChangedIds.isEmpty() || !allianceBDMChangedIds.isEmpty()) { //SAL24-28
                //ddNotesChangedIds.addAll(allianceBDMChangedIds); //SAL24-28 //add all the account ids to update allianceBDM on open oppty
            //SAL24-528 
            if(!ddNotesChangedIds.isEmpty() || !tartChangeIds.isEmpty()) { //SAL24-28
                //ddNotesChangedIds.addAll(tartChangeIds); 
                if(System.isBatch() || system.isFuture()) AccountTriggerHelper.updateOpptyFields(ddNotesChangedIds, tartChangeIds); //PRIT25-171
                else AccountTriggerHelper.updateOpptyFieldsFuture(ddNotesChangedIds, tartChangeIds);
            }
            if(ownerChangedMap.size() > 0) {
                AccountTriggerHelper.keepOpportunityOwnerSame(ownerChangedMap, (Map<Id, Account>) Trigger.oldMap);
            }

            if(ownerChangedMap.size() > 0 || !cemChangeAccountIdSet.isEmpty() || !seChangedMap.isEmpty()) {
                String process = '';
                Set<Id> changedAccountIdSet = new Set<Id>();
                if(ownerChangedMap.size() > 0){
                    process = 'Account Owner;';
                    changedAccountIdSet.addAll(ownerChangedMap.keySet());
                }
                if(!cemChangeAccountIdSet.isEmpty()){
                    process = process + 'CEM;';
                    changedAccountIdSet.addAll(cemChangeAccountIdSet);
                }
                if(!seChangedMap.isEmpty()){
                    process = process + 'SE;';
                    changedAccountIdSet.addAll(seChangedMap);
                }
                If(!disableCaseTeamMemberUpdate) CaseTriggerHandler.accountTerritoryToCaseTeams(changedAccountIdSet, process, null); //SAL24-735 - ETM H1FY25
            }
            system.debug('@@ accSetId '+accSetId);
            if(!accSetId.isEmpty()){
                PartnerOnboardingRequestTriggerHelper.accountChannelprogMapping(accSetId);
            }
            if(reassignAccIds.size()>0){
            AccountTriggerHelper.eligibleETMOwnerAssignment(reassignAccIds);
            }
            //Start - PRDOPS22-518 - AS per the story, we have added the below logic by Sreeramulu Redladinne on 02/02/2022
            if(accountIds.isEmpty() == false){
                //AccountTriggerHelper.updateOrderStatusAndHoldCode(accountIds);
                AccountTriggerHelper.updateOrderStatusAndHoldCode(accountIds, mapAccountWithHoldChanged);
	        }
            //End - PRDOPS22-518
            //Added  by varsha  for-PRDOPS22_218
            if(!DeactiveSmartHandAccIds.isEmpty()){
                AccountTriggerHelper.updateEntitledForSmartHands(DeactiveSmartHandAccIds);
            }
             if(!ModifiedAccountIds.isEmpty()){ 
                 AccountTriggerHelper.updateAccountHistoryRelatedFields(ModifiedAccountIds); 
             } 
			AccountTriggerHelper.validateRASP(Trigger.new, (Map<Id, Account>)Trigger.oldMap);   //CS21-493
            accountIdSet.addAll(Trigger.newMap.keySet());
            //MKT22-270
           // AccountTriggerHelper.populateSDPartner((Map<Id,Account>)Trigger.oldMap, (Map<Id,Account>)Trigger.newMap); commented as a part of SAL25-348
            AccountTriggerHelper.focusedPartnerAccount((List<Account>) Trigger.new,(Map<Id,Account>)Trigger.oldMap); //SAL24-21

            //SAL22-338
            if(!accIdUserOldNewForTeam.isEmpty()) { //SAL24-28
                //if(System.isBatch()) AccountTriggerHelper.manageRSEAccountShare(accIdRSEOldNew); 
                //else AccountTriggerHelper.manageRSEAccountShareFuture(accIdRSEOldNew);
                //SAL23-183 //SAL24-28
                if(System.isBatch() || system.isFuture()) AccountTriggerHelper.manageAccountTeam(accIdUserOldNewForTeam); //PRIT25-171
                else AccountTriggerHelper.manageAccountTeamFuture(accIdUserOldNewForTeam);
            }

            //CS21-891 - Audit "Enforce Admin Panel" field updates - Veera
            if (!auditLogs.isEmpty()) {
                AccountTriggerHelper.createAccountAuditHistory(auditLogs);
            }
            //CS21-891 - End

	    //SAL23-72
            if(!parentAccountIds.isEmpty()) {
                //SAL24-555
                //AccountTriggerHelper.updateChildAccountsCount(parentAccountIds);
                if(System.isBatch() || system.isFuture()) AccountTriggerHelper.updateChildAccountsCount(parentAccountIds);
                else AccountTriggerHelper.updateChildAccountsCountFuture(parentAccountIds);
                if(!isEmaiAlertDisabled) AccountTriggerHelper.notifyToParentAccountOwner((List<Account>) Trigger.new, (Map<ID, Account>) Trigger.oldMap, parentChildAccountIdSet); //SAL24-675
            }
            if(!syncWithGovOrgAccIds.isEmpty()){
                UtilityClass.publishGovOrgSyncEvents(syncWithGovOrgAccIds, 'Account');
            }
            //PRIT25-128
            if(!partnerAccNameChangeIdSet.isEmpty() && !System.isBatch() && !System.isFuture() && !byPassExecution){
                AccountTriggerHelper.updateCompanyNameOnUserFuture(partnerAccNameChangeIdSet);
                byPassExecution = true;
            }
            if( !System.isBatch()){
            AccountTriggerHelper.updateLeadScore(Trigger.new, (Map<Id, Account>) Trigger.oldMap);
            }
        }
    }

    public override void afterDelete() {
    	//SAL23-72
        Set<Id> parentAccountIds = new Set<Id>(); 
        for(Account oldAct : (List<Account>) Trigger.old) {
            if(oldAct.ParentId != null){
                parentAccountIds.add(oldAct.ParentId);
            }
        }
        //SAL23-72
        if(!parentAccountIds.isEmpty()) {
            //SAL24-555
            //AccountTriggerHelper.updateChildAccountsCount(parentAccountIds);
            if(System.isBatch() || system.isFuture()) AccountTriggerHelper.updateChildAccountsCount(parentAccountIds);
            else AccountTriggerHelper.updateChildAccountsCountFuture(parentAccountIds);
        }
    }

    public override void afterUndelete() {  
    	//SAL23-72
        Set<Id> parentAccountIds = new Set<Id>();
        for(Account act : (List<Account>) Trigger.new) {
            if(act.ParentId != null){
                parentAccountIds.add(act.ParentId);
            }
        }
        //SAL23-72
        if(!parentAccountIds.isEmpty()) {
            //SAL24-555
            //AccountTriggerHelper.updateChildAccountsCount(parentAccountIds);
            if(System.isBatch() || system.isFuture()) AccountTriggerHelper.updateChildAccountsCount(parentAccountIds);
            else AccountTriggerHelper.updateChildAccountsCountFuture(parentAccountIds);
        }
    } 
}