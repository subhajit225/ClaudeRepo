public class OpportunityUtil {
    Private static String closedWon = '7 Closed Won';
    Private static String closedLost = '7 Closed Lost';
    Private static String closedAdmin = '7 Closed Admin';
    public static String pagSource = 'Product Assisted Growth (PAG)';//PAG-2
    public static String pqlSource = 'Product Qualified Lead (PQL)'; //SAL25-816
    public static ID defaultPriceBookId = null; 
    public static Boolean accountChangeFlag = false;
    public static Boolean accountTypeChangefromAccountTriggerHelper = false;
    public static set<Id> oppTypeChangeId = new Set<Id>();
    Private static ID accRecTypeIdCustomerProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
    public static ID oppRecTypeIdRenewOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
    public static ID oppRecTypeIdSalesOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
    public static Opportunity_Stage_Days__c oppSetupCS = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId());
    private static boolean isOpportunityTypeChangesAllowed = ShGl_DisableFunctionalityLogic__c.getInstance(UserInfo.getUserId()).Allow_Opportunity_Type_Changes__c;
    private static Set<String> stageSet3to5 = new Set<String>{'3 Technical Validation','4 Business Justification','5 Negotiate & Close'};
    private static ID accPDRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId(); //SAL25-416
    //private static Map<Id, User> userRoleMap = new Map<Id, User>([Select Id, UserRole.Name from User where UserRoleId !=null]);
    
    public static void resetOpportunityFieldsOnChange(
        Opportunity oldRecord, Opportunity newRecord, Map<ID, Account> accountMap, Map<ID, Account>updatedAccountMap,
        Map<ID, Contact> contactMap, Map<ID, User> userMap, Map<ID, ServiceContract> serviceContractMap,
        string TART , string SalesEngg,string TerrId, Id RenewalOppOwnerId, String plsAERole, Boolean updatingOppTypeUsingSDPlookup //SAL24-735 //SF-7721 (ETM-181): Renewal Opp Owner changes //SAL25-106
        ){    
        if(newRecord.id == null){// Insert Trigger event
            newRecord.SBQQ__Ordered__c = FALSE;
            newRecord.Deleted_RTA__c = 0;
            newRecord.Deleted_line_ContractId_RTA__c = '';
            if(newRecord.Opportunity_Split_Parent__c == null){
                newRecord.split__c = false; //SAL24-595
                newRecord.Split_percentage__c = 100; //SAL24-595
            }
            resetArroyoFields(newRecord);
            newRecord.Time_of_Last_Stage_Change__c = newRecord.Time_of_Last_Stage_Change__c == null ? Datetime.Now() : newRecord.Time_of_Last_Stage_Change__c;
            newRecord.manager_note_date_time__c = String.isNotBlank(newRecord.Manager_s_Note__c) ? Datetime.Now() : newRecord.manager_note_date_time__c;
            //newRecord.Area_VP_Notes_Timestamp__c = String.isNotBlank(newRecord.Area_VP_Notes__c) ? Datetime.Now() : newRecord.Area_VP_Notes_Timestamp__c;//Commented as part of SAL26-702
            newRecord.RD_Notes_Timestamp__c = String.isNotBlank(newRecord.RD_Notes__c) ? Datetime.Now() : newRecord.RD_Notes_Timestamp__c;
            newRecord.Theater_VP_Notes_Timestamp__c = String.isNotBlank(newRecord.Theater_VP_Notes__c) ? Datetime.Now() : newRecord.Theater_VP_Notes_Timestamp__c;
            DealRegUtilityHelper.setDealRegistrationType(newRecord, null);
            if(stageSet3to5.contains(newRecord.StageName)){
                newRecord.First_Stage_Changed_Date_Between_3to5__c = System.today();
            }
            /*if(contactMap.containsKey(newRecord.Initial_Contacts_Name__c) && contactMap.get(newRecord.Initial_Contacts_Name__c) != null){ // added for MKT22-96
                newRecord.PG_Day__c = contactMap.get(newRecord.Initial_Contacts_Name__c).PG_Day__c;
            }*/
            Test_Controls__c testControlsCS = Test_Controls__c.getInstance(UserInfo.getUserId());
            if((newRecord.SBQQ__QuotePricebookId__c == null || newRecord.Pricebook2Id == null) && defaultPriceBookId != null && !testControlsCS.Bypass_Pricebook_Setting_on_Opp__c){ 
                if(newRecord.SBQQ__QuotePricebookId__c == null)
                    newRecord.SBQQ__QuotePricebookId__c = defaultPriceBookId;
                if(newRecord.Pricebook2Id == null)
                    newRecord.Pricebook2Id = defaultPriceBookId;
            }
            //SAL23-727  //SAL24-47  
            /*if(newRecord.In_Forecast_Theatre__c != newRecord.In_Forecast_Renewal__c && (newRecord.Opportunity_Sub_Type__c == 'Renewal' || newRecord.Opportunity_Sub_Type__c == 'MSP Consumption Renewal')){
                newRecord.In_Forecast_Theatre__c = newRecord.In_Forecast_Renewal__c;
            } */
        }else{//Update trigger event
            if(!stageSet3to5.contains(oldRecord.StageName) && stageSet3to5.contains(newRecord.StageName)){
                newRecord.First_Stage_Changed_Date_Between_3to5__c = System.today();
            }
            newRecord.manager_note_date_time__c = newRecord.Manager_s_Note__c != oldRecord.Manager_s_Note__c ? Datetime.Now() : newRecord.manager_note_date_time__c;
            //newRecord.Area_VP_Notes_Timestamp__c = newRecord.Area_VP_Notes__c != oldRecord.Area_VP_Notes__c  ? Datetime.Now() : newRecord.Area_VP_Notes_Timestamp__c;//Commented as part of SAL26-702
            newRecord.RD_Notes_Timestamp__c = newRecord.RD_Notes__c != oldRecord.RD_Notes__c  ? Datetime.Now() : newRecord.RD_Notes_Timestamp__c;
            newRecord.Theater_VP_Notes_Timestamp__c = newRecord.Theater_VP_Notes__c != oldRecord.Theater_VP_Notes__c  ? Datetime.Now() : newRecord.Theater_VP_Notes_Timestamp__c;
        }
        //SAL23-727 //SAL24-47   
        /*if(newRecord.In_Forecast_Theatre__c != newRecord.In_Forecast_Renewal__c && (newRecord.Opportunity_Sub_Type__c == 'Renewal' || newRecord.Opportunity_Sub_Type__c == 'MSP Consumption Renewal')){
            newRecord.In_Forecast_Theatre__c = newRecord.In_Forecast_Renewal__c;
        } */    
        newRecord.Sell_to_Partner_text__c = newRecord.Sell_to_Partner__c;
        //FCUS-118
        String stpId = newRecord.Sell_to_Partner__c;
        newRecord.Alliance_HW_Partner__c = (newRecord.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(stpId)) ? 'NetApp' : newRecord.Alliance_HW_Partner__c;
        // newRecord.Alliance_Source_Type_HW__c = (newRecord.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(stpId)) ? 'Alliance Initiated Deal' : newRecord.Alliance_Source_Type_HW__c;//SAL24-387 
        //End
        if((newRecord.id == null || newRecord.StageName != oldRecord.StageName) && String.isNotBlank(newRecord.StageName)) {
            newRecord.Stage_Changed_Date__c = System.TODAY();
            if(newRecord.StageName == '6 PO With Channel'){
                newRecord.Stage_6_TimeStamp__c = system.now(); //capturing datetime of stage 6
            }
            //SAL23-436
            if(!string.isBlank(newRecord.Renewed_Fiscal_Quarter__c) && newRecord.Renewed_Fiscal_Quarter__c.contains('-') && (newRecord.StageName == closedWon || newRecord.StageName == closedLost || newRecord.StageName == closedAdmin)){
                String CloseQtr = '';
                date dt = date.today();
                if(dt > newRecord.closeDate){
                    dt = newRecord.closeDate;
                }
                if(dt.month() >= 2 && dt.month() <= 4){
                    CloseQtr = 'Q1';
                }else if(dt.month() >= 5 && dt.month() <= 7){
                    CloseQtr = 'Q2';
                }else if(dt.month() >= 8 && dt.month() <= 10){
                    CloseQtr = 'Q3';
                }else{
                    CloseQtr = 'Q4';
                }
                Integer CloseQtrVal = Integer.ValueOf(CloseQtr.substring(1,2));
                String RenewalQtr = newRecord.Renewed_Fiscal_Quarter__c.split('-')[0];
                Integer RenewalQtrVal = Integer.ValueOf(RenewalQtr.substring(1,2));
                Integer RenewalYearVal = Integer.ValueOf(newRecord.Renewed_Fiscal_Quarter__c.split('-')[1]);
                String CloseYear = String.ValueOf(dt.year()).substring(2,4);
                Integer CloseYearVal;
                if(dt.month() > 1){
                	CloseYearVal = Integer.ValueOf(CloseYear)+1;
                }else{
                    CloseYearVal = Integer.ValueOf(CloseYear);
                }
                if(RenewalYearVal == CloseYearVal){
                    if(RenewalQtrVal == CloseQtrVal){
                        newRecord.Opportunity_Renewal_Status__c = 'On-Time';
                    }else if(RenewalQtrVal >  CloseQtrVal){
                        newRecord.Opportunity_Renewal_Status__c = 'Early';
                    }else{
                        newRecord.Opportunity_Renewal_Status__c = 'Late';
                    }
                }else if(RenewalYearVal > CloseYearVal){
                    newRecord.Opportunity_Renewal_Status__c = 'Early';
                }else{
                    newRecord.Opportunity_Renewal_Status__c = 'Late';
                }
            }//SAL23-436
        }
        
        //PL26-47 start    
        resetOppProductMix(newRecord);
        //PL26-47 end 
        
        if((newRecord.id == null || newRecord.ForecastCategoryName != oldRecord.ForecastCategoryName) && String.isNotBlank(newRecord.ForecastCategoryName)) {
            newRecord.SE_Forecast_Category__c = newRecord.ForecastCategoryName; // Why do we have 2 same fields?
        }

        if(String.isNotBlank(newRecord.SecondaryOwnerSubmitter__c) && newRecord.SecondaryOwnerApproved__c != oldRecord.SecondaryOwnerApproved__c) {
            newRecord.SecondaryOwner__c = newRecord.SecondaryOwnerSubmitter__c;
        }
        //SAL26-1272 : when creating new split opportunity and RenewalOwner__c is not populated by User, set Renewal Owner same as Oportunity Owner
        if(!newRecord.Override_ETM_Ownership__c && !newRecord.RenewalOwnerApproved__c && newRecord.Opportunity_Split_ParentID__c != null) {
            newRecord.RenewalOwner__c = newRecord.OwnerId;
        } else if(!newRecord.Override_ETM_Ownership__c && newRecord.RenewalOwnerApproved__c && String.isNotBlank(newRecord.RenewalOwnerSubmitter__c)) {
            //SAL26-1272 : when RenewalOwner__c is not populated by User and RenewalOwnerApproved__c = true, set Renewal Owner from RenewalOwnerSubmitter__c
            newRecord.RenewalOwner__c = newRecord.RenewalOwnerSubmitter__c;
        }
        //SF-1002
        if(newRecord.SE_Misaligned__c && newRecord.SE_Misaligned__c != oldRecord.SE_Misaligned__c){
            newRecord.Rubrik_Sales_Engineer__c = newRecord.SE_Misalignment_User__c;
        }
        //SF-1808
        if(newRecord.PO_Received_Notification_Sent__c != oldRecord.PO_Received_Notification_Sent__c && newRecord.PO_Received_Notification_Sent__c ){
            newRecord.PO_Notification_Sent_timestamp__c = system.now(); //capturing datetime of PO Notification sent
            if(String.isBlank(newRecord.Stage_at_PO_notification_Sent__c)){ //SAL25-128 
                newRecord.Stage_at_PO_notification_Sent__c = newRecord.stageName;
            }
        }        
        
        Account accountObj = accountMap.get(newRecord.AccountId);
        Account mspAccount = accountMap.get(newRecord.MSP_End_User_Lookup__c); //SAL25-813
        User newOwnerUser = userMap.get(newRecord.OwnerId);
        System.debug('\nA~~~~: accountObj: ' + accountObj + '\n~~~~: newOwnerUser: ' + newOwnerUser+ '\n~~~~: Contact: ' + contactMap.get(newRecord.Initial_Contacts_Name__c));
        //ETM-179: MSP Opportunity ETM Owner and TART enhancement
        Account accountObjETM = (newRecord.Opportunity_Sub_Type__c != null && newRecord.RecordTypeId != oppRecTypeIdRenewOpp && (newRecord.Opportunity_Sub_Type__c.contains('MSP') || newRecord.Opportunity_Sub_Type__c == 'GC Offer') && newRecord.MSP_End_User_Lookup__c != null) ? accountMap.get(newRecord.MSP_End_User_Lookup__c) : accountObj; //SAL24-548 //SAL24-798
        //SAL25-416 //commented for SAL26-90
        //accountObjETM = (plsAERole != null && plsAERole != '' && accountObj.RecordTypeId == accPDRecId) ? newRecord.MSP_End_User_Lookup__c != null ? accountMap.get(newRecord.MSP_End_User_Lookup__c) : null : accountObjETM;
        //SAL23-391 //SAL24-735 
        //Account partnerLookup = newRecord.Partner_Lookup__c != null ? accountMap.get(newRecord.Partner_Lookup__c) : null;
        //resetOpportunityFieldsDependsOnAccount(oldRecord, newRecord, accountObj,TART, SalesEngg, TerrId, RenewalOppOwnerId); //SF-7721 (ETM-181): Renewal Opp Owner changes
        resetOpportunityFieldsDependsOnAccount(oldRecord, newRecord, accountObj, accountObjETM, TART, SalesEngg, TerrId, RenewalOppOwnerId, plsAERole, updatingOppTypeUsingSDPlookup); //SF-7721 (ETM-181): Renewal Opp Owner changes //SAL23-391 //SAL24-735 //SAL25-106
        resetOpportunityFieldsDependsOnStage(oldRecord, newRecord, accountObj);
        resetOpportunityFieldsDependsOnOwner(oldRecord, newRecord, newOwnerUser);
        resetOpportunityFieldsWorkFlowLogic(oldRecord, newRecord, accountMap, userMap);
        mergedProcessBuilders(oldRecord, newRecord, accountObj, contactMap.get(newRecord.Initial_Contacts_Name__c), serviceContractMap);
        updateAccountRecord(oldRecord, newRecord, accountObj, updatedAccountMap, mspAccount); //SAL25-813
    }
    //PL26-3 //PL26-14 start
    public static void resetPLSCoOwnerFields(Opportunity newOpp){
        newOpp.Co_Owner__c = newOpp.Opp_PLS_ETM_Theatre__c = newOpp.Opp_PLS_ETM_Area__c = newOpp.Opp_PLS_ETM_Region__c = newOpp.Opp_PLS_ETM_Territory__c = null; //PL26-3 //PL26-21 //PL26-34
        newOpp.SaaS_Co_Owner__c = newOpp.Opp_PLS_SaaS_ETM_Theatre__c = newOpp.Opp_PLS_SaaS_ETM_Area__c = newOpp.Opp_PLS_SaaS_ETM_Region__c = newOpp.Opp_PLS_SaaS_ETM_Territory__c = null; //SAL26-1232
        newOpp.NCD_Co_Owner__c = newOpp.Opp_PLS_NCD_ETM_Theatre__c = newOpp.Opp_PLS_NCD_ETM_Area__c = newOpp.Opp_PLS_NCD_ETM_Region__c = newOpp.Opp_PLS_NCD_ETM_Territory__c = null; //SAL26-1232
        newOpp.PLS_AE_ETM_Role_Name__c = ''; //PL26-21
        newOpp.Non_Core_Adaptive_Id__c = ''; //PL26-38,PL26-19
        if(newOpp.Id == null){
            if(newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp){
                newOpp.Core_PLS_Source__c = 'Core Sourced'; //PL26-52
            }
            else{
                 newOpp.Core_PLS_Source__c = null; //PL26-52
            }
        }
    }
    //PL26-3 //PL26-14 start
    //SAL26-1232 - START
    // Co-Owner field → Role value to remove from PLS_AE_ETM_Role_Name__c
    public static final Map<String, String> COOWNER_TO_ROLE = new Map<String, String>{
        'Co_Owner__c'      => 'Cloud AE',
        'NCD_Co_Owner__c'  => 'NCD AE',
        'SaaS_Co_Owner__c' => 'SaaS AE'
    };

    // Co-Owner field → PLS fields to reset
    public static final Map<String, List<String>> COOWNER_TO_PLS_FIELDS =
        new Map<String, List<String>>{
        'Co_Owner__c' => new List<String>{'Opp_PLS_ETM_Theatre__c', 'Opp_PLS_ETM_Area__c', 'Opp_PLS_ETM_Region__c', 'Opp_PLS_ETM_Territory__c'},
        'NCD_Co_Owner__c' => new List<String>{'Opp_PLS_NCD_ETM_Theatre__c', 'Opp_PLS_NCD_ETM_Area__c', 'Opp_PLS_NCD_ETM_Region__c', 'Opp_PLS_NCD_ETM_Territory__c'},
        'SaaS_Co_Owner__c' => new List<String>{'Opp_PLS_SaaS_ETM_Theatre__c', 'Opp_PLS_SaaS_ETM_Area__c', 'Opp_PLS_SaaS_ETM_Region__c', 'Opp_PLS_SaaS_ETM_Territory__c'}
    };

    private static String removeCsvValue(String csv, String valueToRemove) {
        if (String.isBlank(csv) || String.isBlank(valueToRemove)) return csv;
        List<String> remaining = new List<String>();
        for (String val : csv.split(',')) {
        
            String trimmed = val.trim();
            if (trimmed != valueToRemove) {
                remaining.add(trimmed);
            }
        }
        return remaining.isEmpty() ? null : String.join(remaining, ',');
    }

    public static void removeRoleAndAdaptiveIdFromUTA(Opportunity opp, String blankedCoOwnerField, String oldUserId, Map<Id, UserTerritory2Association> userIdToUTAMap){
        if (opp == null || !COOWNER_TO_ROLE.containsKey(blankedCoOwnerField)) return;
        String roleToRemove = COOWNER_TO_ROLE.get(blankedCoOwnerField);
        if (String.isNotBlank(opp.PLS_ETM_Overrides__c)) {
            for (String etmOverride : opp.PLS_ETM_Overrides__c.split(';')) {
                if (roleToRemove == OVERRIDE_TO_ROLE.get(etmOverride.trim())) return;
            }
        }
        opp.PLS_AE_ETM_Role_Name__c = removeCsvValue(opp.PLS_AE_ETM_Role_Name__c,roleToRemove);

        if (oldUserId != null && userIdToUTAMap != null && userIdToUTAMap.containsKey(oldUserId) && userIdToUTAMap.get(oldUserId).Territory2 != null) {
            String adaptiveId = userIdToUTAMap.get(oldUserId).Territory2.Adaptive_Territory_Id__c;
            opp.Non_Core_Adaptive_Id__c = removeCsvValue(opp.Non_Core_Adaptive_Id__c, adaptiveId);
        }
    }

    /* RESET DEPENDENT PLS FIELDS */
    public static void resetPLSFields(Opportunity opp, String coOwnerField ) {
        if (opp == null || !COOWNER_TO_PLS_FIELDS.containsKey(coOwnerField)) {
            return;
        }
        for (String plsField : COOWNER_TO_PLS_FIELDS.get(coOwnerField)) {
            opp.put(plsField, null);
        }
    }
    //SAL26-1232 - END

    //SAL26-1340 - START
    public static final Map<String, List<String>> overrideToPLSFields = new Map<String, List<String>>{
        'CLOUD ETM Override' => new List<String>{'Co_Owner__c', 'Opp_PLS_ETM_Area__c', 'Opp_PLS_ETM_Region__c', 'Opp_PLS_ETM_Territory__c', 'Opp_PLS_ETM_Theatre__c', 'PLS_AE_ETM_Role_Name__c', 'Rubrik_Co_Sales_Engineer__c'},
        'SaaS ETM Override' => new List<String>{ 'SaaS_Co_Owner__c', 'Opp_PLS_SaaS_ETM_Area__c', 'Opp_PLS_SaaS_ETM_Region__c', 'Opp_PLS_SaaS_ETM_Territory__c', 'Opp_PLS_SaaS_ETM_Theatre__c','PLS_AE_ETM_Role_Name__c'},
        'NCD ETM Override' => new List<String>{'NCD_Co_Owner__c', 'Opp_PLS_NCD_ETM_Area__c', 'Opp_PLS_NCD_ETM_Region__c', 'Opp_PLS_NCD_ETM_Territory__c', 'Opp_PLS_NCD_ETM_Theatre__c','PLS_AE_ETM_Role_Name__c'}
    };

    private static final Map<String, String> OVERRIDE_TO_ROLE = new Map<String, String>{
        'CLOUD ETM Override' => 'Cloud AE',
        'NCD ETM Override'   => 'NCD AE',
        'SaaS ETM Override'  => 'SaaS AE'
    };

    public static void resetPLSFieldsForSplitOppETMOverrides(Set<String> primaryOverrides, Set<String> splitOverrides, Opportunity opp) {
       for (String overrideKey : overrideToPLSFields.keySet()) {
            if (primaryOverrides.contains(overrideKey) || splitOverrides.contains(overrideKey)) continue;
            resetPLSFields(opp, overrideKey);
        }
    }

    /* REMOVE ROLE + ADAPTIVE IDS */
    public static void resetRoleAndIdForSplitOppETMOverrides(Set<String> etmOverrides, Map<String, Set<String>> roleToAdaptiveIdsMap, Opportunity opp) {
        Set<String> roleSet = new Set<String>();
        Set<String> adaptiveSet = new Set<String>();
		
        for (String role : roleToAdaptiveIdsMap.keySet()) {
            roleSet.add(role);
            adaptiveSet.addAll(roleToAdaptiveIdsMap.get(role));
        }

        for (String etm : etmOverrides) {
            String role = OVERRIDE_TO_ROLE.get(etm);
            if (String.isBlank(role)) continue;
            roleSet.remove(role);
            if (roleToAdaptiveIdsMap != null && roleToAdaptiveIdsMap.containsKey(role)) {
                adaptiveSet.removeAll(roleToAdaptiveIdsMap.get(role));
            }
        }

        opp.PLS_AE_ETM_Role_Name__c = setToCsv(roleSet);
        opp.Non_Core_Adaptive_Id__c = setToCsv(adaptiveSet);
    }

    /* APPEND ROLE + ADAPTIVE IDS */
    public static void appendRoleAndIdForSplitOppETMOverrides(Set<String> etmOverrides, Map<String, Set<String>> roleToAdaptiveIdsMap, Opportunity opp) {
        Set<String> roleSet = csvToSet(opp.PLS_AE_ETM_Role_Name__c);
        Set<String> adaptiveSet = csvToSet(opp.Non_Core_Adaptive_Id__c);
        Set<String> excludedRoles = new Set<String>();
        for (String etm : etmOverrides) {
        
            excludedRoles.add(OVERRIDE_TO_ROLE.get(etm));
        }
        
        for (String role : roleToAdaptiveIdsMap.keySet()) {
            if (excludedRoles.contains(role)) continue;
            roleSet.add(role);

            adaptiveSet.addAll(roleToAdaptiveIdsMap.get(role));

        }
        opp.PLS_AE_ETM_Role_Name__c = setToCsv(roleSet);
        opp.Non_Core_Adaptive_Id__c = setToCsv(adaptiveSet);
    }

    /* =========================================================
    * CSV HELPERS (FAST & SAFE)
    * ========================================================= */
    private static Set<String> csvToSet(String csv) {
        Set<String> result = new Set<String>();
        if (String.isBlank(csv)) return result;
        for (String val : csv.split(',')) {
            if (!String.isBlank(val)) {
                result.add(val.trim());
            }
        }
        return result;
    }

    private static String setToCsv(Set<String> values) {
        return (values == null || values.isEmpty()) ? null : String.join(new List<String>(values), ',');
    }

    //SAL26-1340 - END
    //PL26-3 //PL26-14 start //SAL26-1232 - END

    //PL26-47 start
    public static void resetOppProductMix(Opportunity newOpp){
        if((newOpp.Core_New_Expansion_ACV__c != 0 && newOpp.Core_New_Expansion_ACV__c != null) &&
        (newOpp.PLS_New_Expansion_ACV__c != 0 && newOpp.PLS_New_Expansion_ACV__c != null)&& newOpp.Opp_Product_Mix__c != 'Bundled'){
                newOpp.Opp_Product_Mix__c = 'Bundled';
        }
        if((newOpp.Core_New_Expansion_ACV__c != 0 && newOpp.Core_New_Expansion_ACV__c != null) &&
        (newOpp.PLS_New_Expansion_ACV__c == 0 || newOpp.PLS_New_Expansion_ACV__c == null)&& newOpp.Opp_Product_Mix__c != 'Core Standalone'){
                newOpp.Opp_Product_Mix__c = 'Core Standalone';
        }
        if((newOpp.Core_New_Expansion_ACV__c == 0 || newOpp.Core_New_Expansion_ACV__c == null) &&
        (newOpp.PLS_New_Expansion_ACV__c != 0 && newOpp.PLS_New_Expansion_ACV__c != null)&& newOpp.Opp_Product_Mix__c != 'PLS Standalone'){
                newOpp.Opp_Product_Mix__c = 'PLS Standalone';
        }
        if((newOpp.Core_New_Expansion_ACV__c == 0 || newOpp.Core_New_Expansion_ACV__c == null) &&
        (newOpp.PLS_New_Expansion_ACV__c == 0 || newOpp.PLS_New_Expansion_ACV__c == null)&& newOpp.Opp_Product_Mix__c != ''){
                newOpp.Opp_Product_Mix__c = '';
        }
    }
    //PL26-47 end
    public static void updateAccountRecord(Opportunity oldRecord, Opportunity newRecord, Account accountObj, Map<ID, Account> updatedAccountMap, Account mspAccount){ //SAL25-813
        if(accountObj == null) return;
        /* Workflow Rule Name: Account Type Updater
            *   Updates Account Type to Customer if Type is Prospect and Not Partner or Distributor when Opportunity is Close Won
            *   If associated Account's Record Type is Customer/Prospect AND Account-Type is Prospect AND Opportunity's Stage is '7 Closed Won'
                Set Type = 'Customer' on associated Account.
            *   (Account: Account Record Type == Customer/Prospect) AND (Account: Type == Prospect) AND (Account: TypeNOT EQUAL TOCustomer,Reseller,Distributor) AND (Opportunity: Stage == 7 Closed Won)
            *   Account: Type = 'Customer'
        */
        /** SAL25-495: Removing existing logic *
        if(accRecTypeIdCustomerProspect == accountObj.RecordTypeId && accountObj.Type == 'Prospect' && newRecord.StageName == '7 Closed Won'){
            accountObj.Type = 'Customer';
            updatedAccountMap.put(accountObj.id, accountObj);
        }
        /** SAL25-495 End */
        if(newRecord.StageName != oldRecord.StageName){
            /* Workflow Rule Name: OPP stage 7 for uncheck Nonstandard EULA
                *   If Stage set to either Closed Won or 7 Closed Lost,Set Nonstandard EULA = false
                *   Opportunity: Stage == 7 Closed Won,7 Closed Lost
                *   Account: Nonstandard EULA = false
            */
            if(accountObj != null && (newRecord.StageName == '7 Closed Won' || newRecord.StageName == '7 Closed Lost' || newRecord.StageName == '7 Closed Admin')){
                accountObj.Nonstandard_EULA__c = false;
                updatedAccountMap.put(accountObj.id, accountObj);
            }
        }
        /* Process Builder's Name: Account-Update Close Won Date
            Updating Close Won Date on opportunity , whenever first Opportunity under Account gets CLOSED WON
            If Opportunity Stage is 7 Closed Won and Close Won Date is null,
                   -Set Close Won Date same as Opportunity Closed Date.
        */
        If(newRecord.StageName == '7 Closed Won' && (newRecord.id == null || newRecord.StageName != oldRecord.StageName)){
            if(accountObj != null && accountObj.Close_Won_Date__c == null){
                accountObj.Close_Won_Date__c = newRecord.CloseDate;
                updatedAccountMap.put(accountObj.id, accountObj);
            }
            //SAL25-813
            if(mspAccount != null && mspAccount.MSP_Account_Lookup__c != accountObj.Id && mspAccount.Id != accountObj.Id){ //Avoid CIRCULAR_DEPENDENCY, Hierarchy Constraint Violation
                mspAccount.MSP_Account_Lookup__c = accountObj.Id;
                updatedAccountMap.put(mspAccount.id, mspAccount);
            }
        }
    }
    //PL26-40 start
    public static Opportunity setPLSCoOwnerFields(Opportunity splitOpp,Opportunity primaryOpp, list<String> fieldNames){
        for(string fld : fieldNames){
            splitOpp.put(fld, primaryOpp.get(fld));
        }
        return splitOpp;
    }
    //PL26-40 end

    public static void resetOpportunityFieldsWorkFlowLogic(Opportunity oldRecord, Opportunity newRecord, Map<ID, Account> accountMap, Map<Id, User> userMap){
                                                          
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
        ShGl_DisableFunctionalityLogic__c disableFunctionalityLogicCS = ShGl_DisableFunctionalityLogic__c.getInstance(UserInfo.getUserId());
        Test_Controls__c testControlsCS = Test_Controls__c.getInstance(UserInfo.getUserId());
        
        /**Process Builder - Sales Operations - Opportunity On Edit  */ //SAL22-378
        if( (newRecord.ID == null || oldRecord.Partner_Lookup__c != newRecord.Partner_Lookup__c ) 
            && (newRecord.Distributor_Lookup__c == null || (newRecord.Distributor_Lookup__c != null && newRecord.ETM_Theatre__c==null? false : newRecord.ETM_Theatre__c.contains('AMER') ))
            && newRecord.Partner_Lookup__c != null 
            && newRecord.SBQQSC__AmendedServiceContract__c == null
        ){
            Account partnerLookup = accountMap.get(newRecord.Partner_Lookup__c);
            if(partnerLookup != null && partnerLookup.Distributor__c != null){
                if(newRecord.ID == null && newRecord.Opportunity_Sub_Type__c == 'Renewal' && OpportunityObjectTriggerHelper.ACCOUNT_CONTRACT_STATUS_SET.contains(partnerLookup.Distributor__r.Contract_Status__c)){
                    //do nothing
                }else if(!OpportunityObjectTriggerHelper.ACCOUNT_CONTRACT_STATUS_SET.contains(partnerLookup.Distributor__r.Contract_Status__c)){
                    newRecord.Distributor_Lookup__c = partnerLookup.Distributor__c;
                }
            }
        }

        /* Workflow Rule Name: Opp-Update Close Date to 180 days
            *   default close date to 180 days out once converted from Lead
            *   If  Lead Email Hidden field is not blank, set Opportunity: Close Date as 180 days later from today.
            *   Opportunity: Lead Email HiddenNOT EQUAL TOnull
            *   Opportunity: Close Date = Today() + 180
        */
        if(newRecord.ID == null && String.isNotBlank(newRecord.Lead_Email_Hidden__c)){
            newRecord.CloseDate = System.Today() + 180;
        }
    
    
        /* Workflow Rule Name: Agreed to POC terms Validation
            *   Workflow to check AGREED TO POC TERMS, When Agreed to POC terms is accepted on the Initial contacts Name
            *   If Agreed to POC terms Validation is true/selected, Set Agreed to POC terms to TRUE
            *   Agreed_to_POC_terms_Validation__c = TRUE
            *   Opportunity: Agreed to POC terms = true
        
        newRecord.Agreed_to_POC_terms__c = newRecord.Agreed_to_POC_terms_Validation__c ? true : newRecord.Agreed_to_POC_terms__c;
        */


        /* Workflow Rule Name: CPQ: Update Price Book on Creation
            *   If new record is getting created without priceBook, set default pricebook to 'CPQ PriceBook'
            *   AND( SBQQ__QuotePricebookId__c == null, $Setup.Test_Controls__c.Bypass_Pricebook_Setting_on_Opp__c == false)
    
            *   Opportunity: Quote Pricebook Id = '01s1W0000003MzoQAE'
        */
        
        /* Workflow Rule Name: Estimated Close Date
            *   If Closed date get change, keep previous Closed date on Last Closed Date field.
            *   ISCHANGED(CloseDate)
    
            *   Opportunity: Last Close Date = PRIORVALUE(CloseDate)
    
        */
        newRecord.Estimated_Close_Date__c = newRecord.CloseDate != oldRecord.CloseDate ? oldRecord.CloseDate : newRecord.Estimated_Close_Date__c;
    
        /* Workflow Rule Name: Inside Sales - Update SDR Led Date on Edit
            *   If SDR_Led is CHECKED and OriginalLeadOwner field get changed, Set  SDR-Led Checked Date with current Date-Time.
            *   ISCHANGED(OriginalLeadOwner__c)&&SDR_Led__c=TRUE&&NOT(ISBLANK(OriginalLeadOwner__c))
            *   Opportunity: SDR-Led Checked Date = NOW()
        */
        //newRecord.SDR_Led_Checked_Date__c = newRecord.OriginalLeadOwner__c != oldRecord.OriginalLeadOwner__c && newRecord.SDR_Led__c && String.isNotBlank(newRecord.OriginalLeadOwner__c) ? System.now() : newRecord.SDR_Led_Checked_Date__c;
          newRecord.SDR_Led_Checked_Date__c = newRecord.SDR_Led__c != oldRecord.SDR_Led__c && newRecord.SDR_Led__c ? System.now() : newRecord.SDR_Led_Checked_Date__c; //SAL26-523
    
        /* Workflow Rule Name: Next step date/time Field Update
            *   If Next Step field value changed, set Next Step date/time to current date time
            *   ISCHANGED( Next_Step__c )
    
            *   Opportunity: Next Step date/time = Now()
        */
        newRecord.Next_Step_date_time__c = newRecord.Next_Step__c != oldRecord.Next_Step__c ? System.now() : newRecord.Next_Step_date_time__c;
    
        /* Workflow Rule Name: Opp- Update Risk Identified Date WF
            *   If Risk Identifie checked set default Risk Identified Date to today if not mentioned.
            *   (Opportunity: Risk Identified == True) AND (Opportunity: Risk Identified Date == null)
            *   Opportunity: Risk Identified Date = TODAY()
        */
        newRecord.Risk_Identified_Date__c = newRecord.Risk_Identified__c && newRecord.Risk_Identified_Date__c == null ? System.today() : newRecord.Risk_Identified_Date__c; 
    
    

        /* Workflow Rule Name: Opp-Update Managers Note Update Date
            *   If Managers Note field got changed, update RSM notes Timestamp to current date-time.
            *   ISCHANGED(Manager_s_Note__c)
            *   Opportunity: RSM notes Timestamp = Now
        */
        if(newRecord.Manager_s_Note__c !=  oldRecord.Manager_s_Note__c){
            newRecord.manager_note_date_time__c = System.now();
        }
    
    
        /* Workflow Rule Name: Opportunity_Escalation
            *   SF-1187 - Need a field to pull reports on to highlight Opportunities that have become escalated.
            *   If Escalation_Stage got changed, set Date Last Escalation Stage Change to today.
            *   NOT(ISBLANK(TEXT(Escalation_Stage__c))) && TEXT(Escalation_Stage__c) <> TEXT(PRIORVALUE(Escalation_Stage__c))
    
            *   Opportunity: Date Last Escalation Stage Change = today()
        */
        if(newRecord.Escalation_Stage__c !=  oldRecord.Escalation_Stage__c && String.isNotBlank(newRecord.Escalation_Stage__c)){
            newRecord.Date_Last_Escalation_Stage_Change__c = System.today();
        }
    
    
  
        /* Workflow Rule Name: Push Counter
            *   Increment the Push Counter field by 1
            *   If Closed Date changed to future month (Afetr current month), increase Opportunity: Push Counter by 1.
            *   IF( CloseDate > PRIORVALUE( CloseDate ), IF (CloseDate) <> MONTH(PRIORVALUE( CloseDate )) , TRUE, FALSE), FALSE)
            *   Opportunity: Push Counter = Opportunity: Push Counter +1
        */
        if(newRecord.CloseDate > oldRecord.CloseDate && newRecord.CloseDate.month() != oldRecord.CloseDate.month()){
            newRecord.Push_Counter__c = newRecord.Push_Counter__c == null ? 1 : newRecord.Push_Counter__c + 1;
        }
    
        /* Workflow Rule Name: Stagnant Field Update
            *   If Prior Stage Date is TODAY's date, mark Stagnant (Historical) field to CHECKED.
            *   Opportunity: Prior Stage Date == TODAY 
            *   Opportunity: Stagnant (Historical) = true
        */
        newRecord.Stagnant__c = (newRecord.Prior_Stage_Date__c == System.today()) ? true : newRecord.Stagnant__c;
    
        /* Workflow Rule Name: Technical Validation - Date Completed
            *   If StageName is 4 Business Justification or Technical_Validation is checked and Technical Validation - Date Achieved is null, set default value for field Technical Validation - Date Achieved as current datr/time
            *   AND( ISBLANK(Technical_Validation_Date_Achieved__c), OR(TEXT(StageName) = 4 Business Justification, Technical_Validation__c = TRUE))
            *   Opportunity: Technical Validation - Date Achieved = now()
        */
        
        if(newRecord.Technical_Validation_Date_Achieved__c == null && (newRecord.Technical_Validation__c || newRecord.StageName == '4 Business Justification')){
            newRecord.Technical_Validation_Date_Achieved__c = System.now();
        }
    
    
        /* Workflow Rule Name: Technical Validation Update Tracking
            *   Capture when Technical Validation Update field is last updated.To do- If possible move it to Trigger.
            *   If  Technical Validation Next Step field get changed, update last changed date on Technical Validation Last Touch field.
            *   ISCHANGED(Technical_Validation_Next_Step__c)
            *   Opportunity: Technical Validation Last Touch = NOW()
        */
        
        if(newRecord.Technical_Validation_Next_Step__c !=  oldRecord.Technical_Validation_Next_Step__c){
            newRecord.Technical_Validation_Last_Touch__c = System.now();

            /* Workflow Rule Name: Update Current State Timestamp
                *   If  Technical Validation Next Step field get changed, update last changed date on Current State Date/Time field.
                *   ISCHANGED( Technical_Validation_Next_Step__c )
                *   Opportunity: Current State Date/Time = NOW()
            */
            newRecord.Current_State_Date_Time__c = System.now();

        }
    
        //SAL26-357 Update Specialist Update Last Touch field to current date/time if MostRecentSEMUpdate__c is changed 
        if(newRecord.MostRecentSEMUpdate__c !=  oldRecord.MostRecentSEMUpdate__c){
            newRecord.Specialist_Update_Last_Touch__c = System.now();
        }
    
        /* Workflow Rule Name: Update Win Date Hidden
            *   Updates hidden Win Date field for win notices
            *   If Opportunity got Closed Stage value as 7 Closed Won and Win Alert Sent is not checked, Set Win Date Hidden as today's Date.
            *   (Opportunity: Closed == True) and (Opportunity: Stage == 7 Closed Won) and (Opportunity: Win Alert Sent == False) 
            *   Opportunity: Win Date Hidden = today()
        */
        if(newRecord.isClosed && newRecord.StageName == '7 Closed Won' && !newRecord.Win_Alert_Sent__c && (!oldRecord.isClosed || oldRecord.StageName != '7 Closed Won')){
            newRecord.Win_Date_Hidden__c = System.today();
        }
        
        /* Workflow Rule Name: Date Entered Stage 3
            *   Updates Stage 3 Date
            *   If Opportunity Stage is 3 Technical Validation, Set stage 3 date as today's Date.
            *   (Opportunity: StageName == 3 Technical Validation)
            *   Opportunity: Stage 3 Date = today()
        */
        if(newRecord.StageName != oldRecord.StageName && newRecord.StageName == '3 Technical Validation'){
            newRecord.Stage_3_Date__c = system.today();
        }
        //Sales Operations - Stamp SDR Orig LO Role	
        if(newRecord.OriginalLeadOwner__c != null && newRecord.SDR_Led__c){
            User uObj = userMap.get(newRecord.OriginalLeadOwner__c);
            if(uObj != null && uObj.UserRoleId != null){
                newRecord.OriginalLeadOwnerRole__c = userMap.get(newRecord.OriginalLeadOwner__c).UserRole.Name;
            }
        }
        
        if(newRecord.POC_Phase__c != oldRecord.POC_Phase__c){
            /* Workflow Rule Name: POC - Completed Date
            *   Updates POC - Completed Date
            *   If Opportunity POC phase is completed, Set POC completed date as today's Date.
            *   (Opportunity: POC_Phase__c == Completed)
            *   Opportunity: POC Completed Date = today()
        */
            if(newRecord.POC_Phase__c == 'Completed'){
                newRecord.POC_Completed_Date__c = system.today();
            }
            /* Workflow Rule Name: POC - In Progress Date
            *   Updates POC - In Progress Date
            *   If Opportunity POC phase is In Progress, Set POC In Progress date as today's Date.
            *   (Opportunity: POC_Phase__c == In Progress)
            *   Opportunity: POC In Progress Date = today()
        */
            else if(newRecord.POC_Phase__c == 'In Progress'){
                newRecord.POC_In_Progress_Date__c = system.today();
            }
            /* Workflow Rule Name: POC - Planned Date
            *   Updates POC - Planned Date
            *   If Opportunity POC phase is Planned POC, Set POC Planned date as today's Date.
            *   (Opportunity: POC_Phase__c == Planned POC)
            *   Opportunity: POC Planned Date = today()
        */
        /*
            else if(newRecord.POC_Phase__c == 'Planned POC'){
                newRecord.POC_Planned_Date__c = system.today();
            }
            */
        }
        //SAL24-708
        newRecord.Technical_Close_Date_Push_Counter__c = newRecord.Technical_Close_Date__c > oldRecord.Technical_Close_Date__c && newRecord.Technical_Close_Date__c.month() != oldRecord.Technical_Close_Date__c.month() ? newRecord.Technical_Close_Date_Push_Counter__c == null ? 1 : newRecord.Technical_Close_Date_Push_Counter__c + 1 : newRecord.Technical_Close_Date_Push_Counter__c;
    }

    
    public static void resetOpportunityFieldsDependsOnAccount(Opportunity oldRecord, Opportunity newRecord, Account accountObj, Account accountObjETM, string TARTStr,string salesEngg,Id TerrId, Id RenewalOppOwnerId, String plsAERole,Boolean updatingOppTypeUsingSDPlookup){ //SF-7721 (ETM-181): Renewal Opp Owner changes //ETM-179 //SAL23-391 //SAL24-735 //SAL25-106
        List<string> TART ;
        
        if(accountObj != null){
            System.debug('CP salesEngg'+salesEngg);
            if(!accountTypeChangefromAccountTriggerHelper){ 
                if(newRecord.id == null &&  
                    newRecord.Opportunity_Type__c!='Debooking'
                    ){
                        if(salesEngg!=null  && newRecord.SE_Misaligned__c == false) { // &&newRecord.SE_Misaligned__c!=null
                        newRecord.Rubrik_Sales_Engineer__c = salesEngg;
                        } 
                        //ETM-179: MSP Opportunity ETM Owner and TART enhancement
                    //SAL23-275
                    //if( newRecord.Opportunity_Split_ParentID__c==null   && accountObjETM.Adaptive_Territory_Id__c!=null){  
                    if( newRecord.Opportunity_Split_ParentID__c==null){
                        //ETM-178: OVerride ETM Ownership
                        //if(newRecord.Disable_Auto_OwnerAssignment__c==false){
                        if(newRecord.Disable_Auto_OwnerAssignment__c==false && newRecord.Override_ETM_Ownership__c==false){
                            //SF-7721 (ETM-181): Renewal Opp Owner changes
                            //newRecord.OwnerId = accountObj.OwnerId;
                            //ETM-179: MSP Opportunity ETM Owner and TART enhancement
                            //SAL24-798 - Remove existing logic
                            //newRecord.OwnerId = (newRecord.Opportunity_Sub_Type__c == 'Renewal' || newRecord.Opportunity_Sub_Type__c == 'MSP Consumption Renewal') && RenewalOppOwnerId != null ? RenewalOppOwnerId : accountObjETM.OwnerId; //ETM-179 //SAL23-720
                            newRecord.OwnerId = (newRecord.RecordTypeId == oppRecTypeIdRenewOpp && newRecord.Opportunity_Sub_Type__c != null && newRecord.Opportunity_Sub_Type__c.contains('Renewal')) ? RenewalOppOwnerId : accountObjETM?.OwnerId; //SAL25-416
                        } 
                        //SAL24-735 
                        //newRecord.OwnerId = plsAERole != null && plsAERole != '' ? UserInfo.getUserId() : newRecord.OwnerId; //Removed under PL26-21
                        //newRecord.PLS_AE_ETM_Role_Name__c = plsAERole; //removed for PL26-21
                        newRecord.Territory2Id = newRecord.Territory2Id__c =  TerrId;
                        //if((newRecord.Opportunity_Sub_Type__c != null && newRecord.RecordTypeId != oppRecTypeIdRenewOpp && (newRecord.Opportunity_Sub_Type__c.contains('MSP') || newRecord.Opportunity_Sub_Type__c == 'GC Offer') && newRecord.MSP_End_User_Lookup__c != null) || (plsAERole != null && plsAERole != '' && accountObj.RecordTypeId == accPDRecId)){ newRecord.Territory2Id =  null; } //SAL24-669 //SAL24-798 //SAL25-416//SAL26-90:commented
                        if(newRecord.Opportunity_Sub_Type__c != null && newRecord.RecordTypeId != oppRecTypeIdRenewOpp && (newRecord.Opportunity_Sub_Type__c.contains('MSP') || newRecord.Opportunity_Sub_Type__c == 'GC Offer') && newRecord.MSP_End_User_Lookup__c != null){ newRecord.Territory2Id =  null; } //SAL26-90:added
                        //ETM-179: MSP Opportunity ETM Owner and TART enhancement //SAL25-416
                        newRecord.ETM_Theatre__c = newRecord.Override_ETM_Ownership__c ? newRecord.ETM_Theatre__c : accountObjETM?.ETM_Theatre__c;
                        newRecord.ETM_Area__c = newRecord.Override_ETM_Ownership__c ? newRecord.ETM_Area__c : accountObjETM?.ETM_Area__c;
                        newRecord.ETM_Region__c = newRecord.Override_ETM_Ownership__c ? newRecord.ETM_Region__c : accountObjETM?.ETM_Region__c;
                        newRecord.ETM_Territory__c = newRecord.Override_ETM_Ownership__c ? newRecord.ETM_Territory__c : accountObjETM?.ETM_Territory__c;
                        //SAL23-391 //SAL24-528
                        /*newRecord.CDM_Theatre__c = partnerLookup?.ETM_Theatre__c;
                        newRecord.CDM_Area__c = partnerLookup?.ETM_Area__c;
                        newRecord.CDM_Region__c = partnerLookup?.ETM_Region__c;
                        newRecord.CDM_Territory__c = partnerLookup?.ETM_Territory__c;*/
                        
                        //SF-7721 (ETM-181) - Renewal Opp changes: Assign Account Owner to Opp.RenewalOwner
                        //SAL26-1272 : At the time of opportunity creation (except split and debouncing), when RenewalOwner__c is not populated by User, Assign Account Owner to Opp.RenewalOwner
                        if(!newRecord.Override_ETM_Ownership__c && !newRecord.RenewalOwnerApproved__c){
                            newRecord.RenewalOwner__c = accountObjETM.OwnerId;
                        }

                        //SAL23-443 - Alliance Rep
                        //newRecord.Opportunity_Alliance_BDM__c = accountObjETM.Account_Alliance_BDM__c; //SAL24-28 

                    }
                    //SAL24-798 - Remove existing logic with etm logic optimization.
                    /*else if(newRecord.id == null && newRecord.Opportunity_Split_ParentID__c !=null){  
                    if(String.isNotBlank(TARTStr)){
                    TART = TARTStr.replaceall('null',' ').split('_');
                    system.debug('Opportunity TART'+TART);
                    if(TerrId !=null){
                    newRecord.Territory2Id = newRecord.Territory2Id__c = TerrId ;
                    }
                    newRecord.ETM_Theatre__c = TART[1] ;
                    newRecord.ETM_Area__c = TART[2] ;
                    newRecord.ETM_Region__c = TART[3] ;
                    newRecord.ETM_Territory__c = TART[4] ;
                    }
                    else{
                        newRecord.Territory2Id = newRecord.Territory2Id__c = newRecord.ETM_Theatre__c = newRecord.ETM_Area__c = newRecord.ETM_Region__c = newRecord.ETM_Territory__c = null ;
                    }
                    //Update TART based on USer
                }*/
                } 
                //SAL24-279 //SAL24-528 
                /*if(newRecord.id == null || (!newRecord.isClosed && oldRecord.Partner_Lookup__c != newRecord.Partner_Lookup__c)){
                    newRecord.CDM_Theatre__c = partnerLookup?.ETM_Theatre__c;
                    newRecord.CDM_Area__c = partnerLookup?.ETM_Area__c;
                    newRecord.CDM_Region__c = partnerLookup?.ETM_Region__c;
                    newRecord.CDM_Territory__c = partnerLookup?.ETM_Territory__c;
                }*/
            }
        
            /* Workflow Rule Name: Opportunity-Update Opp type based on Account Type
                *   This WF updates the type of Opportunity based on Account
                *   If Account.Type is not 'Customer', 'Reseller', 'Distributor' and StageName is not '7 Closed Won',
                    Set Opportunity Type as 'New Customer'
                *   AND(NOT(ISPICKVAL(Account.Type,'Customer')), NOT(ISPICKVAL(Account.Type,'Reseller')), NOT(ISPICKVAL(Account.Type,'Distributor')),NOT(ISPICKVAL(StageName,'7 Closed Won')))
                *   Opportunity: Opportunity Type  = 'New Customer'
            */
            if(newRecord.IsClosed == FALSE && newRecord.Opportunity_Type__c != 'Debooking'){
                Set<String> accTypeSet = new Set<String>{'Customer', 'Reseller', 'Distributor'};
                if(newRecord.Id == null || ((accountChangeFlag || accountTypeChangefromAccountTriggerHelper) && newRecord.recordtypeId == oppRecTypeIdSalesOpp)){  //SAL24-257
                    if(newRecord.Opportunity_Type__c != 'New Customer' && !accTypeSet.contains(accountObj.Type)){
                        newRecord.Opportunity_Type__c = 'New Customer';
                        if(accountTypeChangefromAccountTriggerHelper){ //SAL24-257
                            oppTypeChangeId.add(newRecord.Id);
                            if(newRecord.Opportunity_Sub_Type__c != '' && newRecord.Opportunity_Sub_Type__c == 'Renewal'){
                            	newRecord.Opportunity_Sub_Type__c = 'Regular';
                        	}
                        }
                    }
                    /* Workflow Rule Name: Opportunity-Update Opp type based on Account Type Existing
                        *   This WF updates the type of Opportunity based on Account
                        *   If Account.Type in ,'Customer' or 'MSP-Reseller' and StageName is not '7 Closed Won'Set Opportunity Type = 'Existing Customer'
                        *   AND(OR(ISPICKVAL(Account.Type,'Customer'),ISPICKVAL(Account.Type,'MSP-Reseller')) ,NOT(ISPICKVAL(StageName,'7 Closed Won')))
                        *   Opportunity: Opportunity Type = 'Existing Customer'
                    */
                    if((newRecord.Id == null || newRecord.Opportunity_Type__c != 'Existing Customer') && (accountObj.Type == 'Customer' || accountObj.Type == 'MSP-Reseller') && !updatingOppTypeUsingSDPlookup){ //SAL25-106
                        newRecord.Opportunity_Type__c = 'Existing Customer';
                        if(accountTypeChangefromAccountTriggerHelper){ //SAL24-257
                            oppTypeChangeId.add(newRecord.Id);
                        }
                    }

                    /* Workflow Rule Name: Opportunity-Update Opp type to Partner
                        *   This WF updates the type of Opportunity based on Account
                        *   If Account.Type is 'Reseller' and StageName is not '7 Closed Won' and Number_of_NFR_Products  > 0Set  Opportunity Type = Partner
                        *   AND( ISPICKVAL(Account.Type,'Reseller'), NOT(ISPICKVAL(StageName,'7 Closed Won')), Number_of_NFR_Products__c > 0 )
                        *   Opportunity: Opportunity Type = Partner
                    */
                    if((newRecord.Id == null || newRecord.Opportunity_Type__c != 'Partner') && accountObj.Type == 'Reseller' && newRecord.Number_of_NFR_Products__c > 0  && !updatingOppTypeUsingSDPlookup){ //SAL25-106
                        newRecord.Opportunity_Type__c = 'Partner';
                        if(accountTypeChangefromAccountTriggerHelper){ //SAL24-257
                            oppTypeChangeId.add(newRecord.Id);
                    }
                    }
                    accountChangeFlag = false; //SAL24-257
                }else if(!accountTypeChangefromAccountTriggerHelper && newRecord.Opportunity_Type__c != oldRecord.Opportunity_Type__c && !isOpportunityTypeChangesAllowed  && !updatingOppTypeUsingSDPlookup){ //SAL25-106
                    newRecord.Opportunity_Type__c = oldRecord.Opportunity_Type__c; // Reset old value
                }
            }
            //SAL22-238
            //newRecord.Account_Deal_Desk_Notes__c = (newRecord.Id == null || newRecord.AccountId != oldRecord.AccountId) ? accountObj.Account_Deal_Desk_Notes__c : newRecord.Account_Deal_Desk_Notes__c;
            //Added by Sumedha for CPQ22-313
            if (!accountTypeChangefromAccountTriggerHelper && newRecord.IsClosed == FALSE) {
                newRecord.Account_Deal_Desk_Notes__c = (newRecord.Id == null || newRecord.AccountId != oldRecord.AccountId) ? accountObj.Account_Deal_Desk_Notes__c : newRecord.Account_Deal_Desk_Notes__c;
                //SAL22-354
                //SAL24-27 ,removed Account.Account_Deal_Ops_Notes__c from here, it's deprecated now
                //newRecord.Account_Deal_Ops_Notes__c = (newRecord.Id == null || newRecord.AccountId != oldRecord.AccountId) ? accountObj.Account_Deal_Ops_Notes__c : newRecord.Account_Deal_Ops_Notes__c;
            } 
        }        
    }

    public static void resetOpportunityFieldsDependsOnOwner(Opportunity oldRecord, Opportunity newRecord, User newOwnerUser){
        if(newOwnerUser != null){
            /* Workflow Rule Name: Opp-Ownership Counter Update.
                *   && Owner.Profile.Name !='Rubrik inside sales'
                *   If Owner get changed and he is not from Inside Sales Division, increase Ownership Change Counter by 1.
                *   ISCHANGED(OwnerId) &&( Owner.Division ) != 'Inside Sales' && PRIORVALUE(Division__c) !='Inside Sales'
                *   Opportunity: Ownership Change Counter = IF(ISBLANK(Ownership_Change_Counter__c),1,Ownership_Change_Counter__c+1)
            */
            if(newRecord.id == null || newRecord.OwnerId !=  oldRecord.OwnerId && newOwnerUser != null){
                /*if(oldRecord.Division__c !='Inside Sales' && newOwnerUser.Division != 'Inside Sales'){
                    newRecord.Ownership_Change_Counter__c = newRecord.Ownership_Change_Counter__c == null ? 1 : newRecord.Ownership_Change_Counter__c + 1;
                }*/ //SAL26-704: Commented

                /* Workflow Rule Name: Update Owner Region
                    *   If Owner record is getting changed, set below fields:  Opportunity: Owner Region = Owner.Region Opportunity: Owner Area = Owner.Area Opportunity: Owner Theatre = Owner.Theatre Opportunity: Owner Sub Region = Owner.Sub_Region
                    *   OR(ISChanged(OwnerId),ISNEW())
                    *   Opportunity: Owner Region = Owner.Region__c Opportunity: Owner Area = Owner.Area__c 
                            Opportunity: Owner Theatre = Owner.Theatre__c Opportunity: Owner Sub Region = Owner.Sub_Region__c
                */
                newRecord.Owner_Region__c = newOwnerUser.Region__c;
                newRecord.Owner_Area__c = newOwnerUser.Area__c;
                newRecord.Owner_Theatre__c = newOwnerUser.Theatre__c;
                newRecord.Owner_Sub_Region__c = newOwnerUser.Sub_Region__c;
            }

            /* Workflow Rule Name: Update Owner related fields
                    *   Update Region, Sub_Region and Theatre text fields based on Current Owner
                    *   If StageName changed to  '7 Closed Won' or '7 Closed Lost'  or Owner get changed, 
                        reset below fields:- Area (Hidden) = Owner.Area- Region (Hidden) = Owner.Region- Sub Region (Hidden) = Owner.Sub_Region- Theatre (Hidden) = Owner.Theatre
                    *   OR( AND( ISCHANGED(StageName), OR( ISPICKVAL(StageName, '7 Closed Won'), ISPICKVAL(StageName, '7 Closed Lost') ) ), AND( OR( ISPICKVAL(StageName, '7 Closed Won'), ISPICKVAL(StageName, '7 Closed Lost') ) , ISCHANGED(OwnerId) ) )
                    *   Opportunity: Owner Region = Owner.Region__c 
                        Opportunity: Owner Area = Owner.Area__c 
                        Opportunity: Owner Theatre = Owner.Theatre__c 
                        Opportunity: Owner Sub Region = Owner.Sub_Region__c
                */
            if((newRecord.StageName == '7 Closed Won' || newRecord.StageName == '7 Closed Lost' ) && (newRecord.id == null || oldRecord.StageName != newRecord.StageName || (newRecord.OwnerId !=  oldRecord.OwnerId))){
                newRecord.Region_Text__c = newOwnerUser.Region__c;
                //newRecord.Area_Text__c = newOwnerUser.Area__c; //Commeneted as part of SAL26-702
                newRecord.Theatre_Text__c = newOwnerUser.Theatre__c;
                newRecord.Sub_Region_Text__c = newOwnerUser.Sub_Region__c;
            }
        }
    }

    public static void resetOpportunityFieldsDependsOnStage(Opportunity oldRecord, Opportunity newRecord, Account accountObj){
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
        if(newRecord.StageName != oldRecord.StageName){

            /* Workflow Rule Name: Closed Lost Mgr Notification
                *   Notify manager when opp is moved to closed lost. Manager can discuss with rep and try to save the deal.
                *   If  StageName is '7 Closed Lost' Set Stage Lost From as previous Stage.
                *   AND ( NOT ( $Setup.ShGl_DisableBusinessLogic__c.Disable_Opportunity_Workflow_Rules__c ) , NOT ( $Setup.ShGl_DisableBusinessLogic__c.Disable_Opportunity_Email_Alerts__c ) , ISPICKVAL ( StageName , '7 Closed Lost' ) )
                *   Opportunity: Stage Lost From= TEXT(PRIORVALUE(StageName))
            */
            if(newRecord.StageName == '7 Closed Lost' || newRecord.StageName == '7 Closed Admin'){
                if(!disableBusinessLogicCS.Disable_Opportunity_Workflow_Rules__c && !disableBusinessLogicCS.Disable_Opportunity_Email_Alerts__c){
                    newRecord.Stage_Lost_From__c = oldRecord.StageName;
                }
                /* Workflow Rule Name: SE_ForecastCategory_update -Opportunity_Stage_ClosedLost
                    *   SF-428 Update field value & auto populate based on oppty stage
                    *   If Stage is set to '7 Closed Lost' Set SEM Forecast Category field as Omitted
                    *   Opportunity: Stage == 7 Closed Lost 
                    *   Opportunity: SEM Forecast Category = Omitted
                */
                newRecord.SE_Forecast_Category__c = 'Omitted';
            }
            /* Workflow Rule Name: Opp - Stage Changed to Closed Won
                *   SAL-296 - Set flag to TRUE when Oppty Stage updated to 7 Closed Won
                *   If  StageName changed to  '7 Closed Won', set below fields:Opportunity: In Forecast (Area)= true,Opportunity: In Forecast (RD) = true,Opportunity: In Forecast (RSM) = trueOpportunity: In Forecast (Theatre) = true
                *   AND (NOT ( $Setup.ShGl_DisableBusinessLogic__c.Disable_Opportunity_Workflow_Rules__c ) ,ISCHANGED( StageName ) ,ISPICKVAL( StageName , '7 Closed Won'))
                *   Opportunity: In Forecast (Area)= true,Opportunity: In Forecast (RD) = true,Opportunity: In Forecast (RSM) = trueOpportunity: In Forecast (Theatre) = true
            */
            //SAL25-49
            //if(newRecord.StageName == '7 Closed Won' && !disableBusinessLogicCS.Disable_Opportunity_Workflow_Rules__c){
            if(newRecord.StageName == '7 Closed Won' || newRecord.StageName == '6 PO With Channel'){
                newRecord.In_Forecast_Area__c = true;
                newRecord.In_Forecast_RD__c = true;
                newRecord.In_Forecast_RSM__c = true;
                newRecord.In_Forecast_Theatre__c = true;
                //SAL22-453
                newRecord.InForecastRVP__c = true;
                newRecord.In_Forecast_CRO__c = true;
                newRecord.In_Forecast_TVP__c = true; //SAL24-709
                /* Workflow Rule Name: SE_ForecastCategory_update -Opportunity_Stage_ClosedWon
                    *   SF-428 Update field value & auto populate based on oppty stage
                    *   If Stage is set to '7 Closed Won' Set SEM Forecast Category field as Closed
                    *   Opportunity: Stage == 7 Closed Won 
                    *   Opportunity: SEM Forecast Category = Closed
                */
                newRecord.SE_Forecast_Category__c = 'Closed';
                 //PL26-23
                 if(newRecord.Co_Owner__c!=null || newRecord.SaaS_Co_Owner__c!=null || newRecord.NCD_Co_Owner__c!=null){
                    newRecord.PLS_AVP_Path__c = newRecord.PLS_RD_Path__c = newRecord.PLS_RVP_Path__c = newRecord.PLS_AE_Path__c = true; 
                 }else {
                    newRecord.PLS_AVP_Path__c = newRecord.PLS_RD_Path__c = newRecord.PLS_RVP_Path__c = newRecord.PLS_AE_Path__c = false; 
                 }
            }

            //SAL25-49
            if(newRecord.StageName == '7 Closed Lost' || newRecord.StageName == '7 Closed Admin' || newRecord.StageName == '0 Nurture'){
                newRecord.In_Forecast_Area__c = newRecord.In_Forecast_RD__c = newRecord.In_Forecast_RSM__c = newRecord.In_Forecast_Theatre__c = newRecord.InForecastRVP__c = newRecord.In_Forecast_CRO__c = newRecord.In_Forecast_TVP__c = false;
                //PL26-23
                newRecord.PLS_AVP_Path__c = newRecord.PLS_RD_Path__c = newRecord.PLS_RVP_Path__c = newRecord.PLS_AE_Path__c = false; 
            }

            /* Workflow Rule Name: Opportunity closed Date Update
                *   If StageName got changed to  '7 Closed Won' or '7 Closed Lost' and Closed date is blank or in future, set Closed Date to Today
                *   AND(ISCHANGED(StageName),OR(ISPICKVAL(StageName, '7 Closed Won'),ISPICKVAL(StageName, '7 Closed Lost')),OR(ISBLANK(CloseDate),AND(NOT(ISBLANK(CloseDate)),CloseDate > TODAY())))
                *   Opportunity: Close Date = today()
            */
            if((newRecord.StageName == '7 Closed Won' || newRecord.StageName == '7 Closed Lost' || newRecord.StageName == '7 Closed Admin') && (newRecord.CloseDate == null || newRecord.CloseDate > System.TODAY())){
                newRecord.CloseDate = System.today();
            }
            /* Workflow Rule Name: Actual Close Date
                *   This rule updates Actual Close Date into the Actual Close Date Field
                *   If Stage is 7 Closed LostSet Close Date as today's dateSet Actual Close Lost Date as today's date
                *   Opportunity: Stage == 7 Closed Lost
                *   Opportunity: CloseDate = TODAY()Opportunity: Actual Close Lost Date= TODAY()
            */
            newRecord.Actual_Close_Lost_Date__c = (newRecord.StageName == '7 Closed Lost') ? System.today() : newRecord.Actual_Close_Lost_Date__c;

                
            /* Workflow Rule Name: Oppty-Update Advanced Past Stage 1 Rule
                *   This workflow is initiated once opportunities stage is changed from stage 1 to higher satges
                *   If StageName got changed from 1 Discovery to 2 Consensus, 3 Technical Validation,  4 Business Justification, 5 Negotiate & Close or 7 Closed WonSet Advanced Past Stage 1 = trueSet Advanced Past Stage 1 (Date/Time) = current date/time
                *   AND( OR( AND( ISCHANGED(StageName),ISPICKVAL(PRIORVALUE(StageName),1 Discovery),ISPICKVAL(StageName, 2 Consensus) ),AND( ISCHANGED(StageName),ISPICKVAL(PRIORVALUE(StageName),1 Discovery),ISPICKVAL(StageName, 3 Technical Validation) ),AND( ISCHANGED(StageName),ISPICKVAL(PRIORVALUE(StageName),1 Discovery),ISPICKVAL(StageName, 4 Business Justification) ),AND( ISCHANGED(StageName),ISPICKVAL(PRIORVALUE(StageName),1 Discovery),ISPICKVAL(StageName, 5 Negotiate & Close) ),AND( ISCHANGED(StageName),ISPICKVAL(PRIORVALUE(StageName),1 Discovery),ISPICKVAL(StageName, 7 Closed Won) ) ) )
                *   Opportunity: Advanced Past Stage 1 = trueAdvanced Past Stage 1 (Date/Time) = Now()
            */
            Set<String> advancedPastStageSet = new Set<String>{'2 Consensus','3 Technical Validation','4 Business Justification','5 Negotiate & Close','7 Closed Won'};
            if(oldRecord.StageName == '1 Discovery' && advancedPastStageSet.contains(newRecord.StageName)){
                newRecord.Advanced_Past_Stage_1__c = true;
                newRecord.Advanced_Past_Stage_1_Date_Time__c = System.now();
            }
        
            /* Workflow Rule Name: Oppty-Update Advanced Past Stage 2 Rule
                *   This workflow is initiated once opportunities stage is changed from stage 2 to higher satges
                *   If StageName got changed from 2 Consensus to 3 Technical Validation, 4 Business Justification , 5 Negotiate & Close or  7 Closed WonSet  Advanced Past Stage 2 = trueSet Advanced Past Stage 2(Date/Time) = current Date/time
                *   AND( OR( AND( ISCHANGED(StageName),ISPICKVAL(PRIORVALUE(StageName),2 Consensus),ISPICKVAL(StageName, 3 Technical Validation) ),AND( ISCHANGED(StageName),ISPICKVAL(PRIORVALUE(StageName),2 Consensus),ISPICKVAL(StageName, 4 Business Justification) ),AND( ISCHANGED(StageName),ISPICKVAL(PRIORVALUE(StageName),2 Consensus),ISPICKVAL(StageName, 5 Negotiate & Close) ),AND( ISCHANGED(StageName),ISPICKVAL(PRIORVALUE(StageName),2 Consensus),ISPICKVAL(StageName, 7 Closed Won) ) ) )
                *   Opportunity: Advanced Past Stage 2 = trueOpportunity: Advanced Past Stage 2(Date/Time) = Now()
            */
            Set<String> advancedPastStage2Set = new Set<String>{'3 Technical Validation','4 Business Justification','5 Negotiate & Close','7 Closed Won'};
            if(oldRecord.StageName == '2 Consensus' && advancedPastStageSet.contains(newRecord.StageName)){
                newRecord.Advanced_Past_Stage_2__c = true;
                newRecord.Advanced_Past_Stage_2_Date_Time__c = System.now(); 
            }
        }
        If(newRecord.StageName == '7 Closed Won' && (newRecord.id == null || newRecord.StageName != oldRecord.StageName)){
            newRecord.In_Forecast_Renewal__c = false;
        }
        //SAL23-437
        if((newRecord.StageName == '7 Closed Lost' || newRecord.StageName == '7 Closed Admin') && (newRecord.id == null || newRecord.StageName != oldRecord.StageName)){
            newRecord.CloseDate = System.today();
        }

    }    

    public static void mergedProcessBuilders(Opportunity oldRecord, Opportunity newRecord, Account accountObj, Contact initialContact, Map<ID, ServiceContract> serviceContractMap){
        ServiceContract amendedSC = serviceContractMap.get(newRecord.SBQQSC__AmendedServiceContract__c);
        ServiceContract renewedSC = serviceContractMap.get(newRecord.SBQQSC__RenewedServiceContract__c);
        System.debug('\nC~~~~: oldRecord: ' + oldRecord + '\n~~~~: newRecord: ' + newRecord + '\n~~~~: renewedSC: ' 
        + renewedSC + '\n~~~~: amendedSC: ' + amendedSC + '\n~~~~: serviceContractMap: ' + serviceContractMap);
        //-----------------------Process Builder------------------
        /* Process Builder's Name: Update Subtype for MSP Amendment Opportunities
            Update the Opportunity Sub Type to MSP for amended MSP quotes
            If AmendedServiceContract is not null and its Opportunity field is not null and this Opportunity's Sub_Type is either null or has MSP value
            Update Sub Type to MSP in current Opportunity too.
        */
        //ServiceContract amendedSC = serviceContractMap.get(newRecord.SBQQSC__AmendedServiceContract__c); 
        if(newRecord.SBQQSC__AmendedServiceContract__c != null && (newRecord.id == null || newRecord.SBQQSC__AmendedServiceContract__c != oldRecord.SBQQSC__AmendedServiceContract__c)){
            if(amendedSC != null && amendedSC.SBQQSC__Opportunity__c != null 
                && (amendedSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c == 'MSP Consumption Renewal' || amendedSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c == 'MSP')){
                newRecord.Opportunity_Sub_Type__c = 'MSP';
                if (newRecord.id == null) {
                    newRecord.Opportunity_Type__c = 'Existing Customer';
                }else if(newRecord.Opportunity_Type__c != oldRecord.Opportunity_Type__c &&  !isOpportunityTypeChangesAllowed){
                    newRecord.Opportunity_Type__c = oldRecord.Opportunity_Type__c;
                }
                //SAL24-798 - Remove existing logic
                /*if(newRecord.id == null && accountObj != null){
                    newRecord.ownerId = accountObj.OwnerId;
                }*/
            }
        }
        
        if(newRecord.id == null && newRecord.RecordTypeId == oppRecTypeIdRenewOpp){
            //MSP1.1 - By Ashwini G.
            if(renewedSC != null){
                  
                    if(renewedSC.SBQQSC__Opportunity__c != null && renewedSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c != null && renewedSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c == 'MSP' && renewedSC.SBQQSC__Order__c != null && renewedSC.SBQQSC__Order__r.Order_Sub_Type__c != null && renewedSC.SBQQSC__Order__r.Order_Sub_Type__c.contains('MSP')){
                         newRecord.Opportunity_Sub_Type__c = 'MSP Consumption Renewal';
                            
                        //SAL24-798 - Remove existing logic
                        /*if(accountObj != null){
                            newRecord.ownerId = accountObj.OwnerId;
                        }*/
                    }else if(renewedSC.SBQQSC__Opportunity__c != null && renewedSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c != null && (renewedSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c == 'GC Offer' || renewedSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c == 'GC Renewal')  && renewedSC.SBQQSC__Order__c != null && renewedSC.SBQQSC__Order__r.Order_Sub_Type__c != null && renewedSC.SBQQSC__Order__r.Order_Sub_Type__c.contains('GC')){
                        newRecord.Opportunity_Sub_Type__c = 'GC Renewal';
                    }
                    else{
                        newRecord.Opportunity_Sub_Type__c = 'Renewal';
                    }
                
            }else{
                newRecord.Opportunity_Sub_Type__c = 'Renewal';
            }
            newRecord.Opportunity_Type__c = 'Existing Customer';
        }

        /* Process Builder's Name: Opp-Last Stage Update Date v1.4
            Added Renewal Path Logic
            #1: If Opportunity Stage is  1 Discovry and Closed Date is withing next 180 days,
                   -Set Last Stage Update Date to today's Date
                   - Schedule Email alert on 90th days from Last Stage Update Date.(on 90th day.)

            #2: If Opportunity Stage is 2 Concensus and Closed Date is withing next 180 days,
                   -Set Last Stage Update Date to today's Date
                   - Schedule Email alert on 90th days from Last Stage Update Date.(on 90th day.)

            #3: If Opportunity Stage is 7 Closed Won and Sub-Type is Renewal,
                   -Set Renewal Path to TRUE

            #4: If Opportunity Stage is 7 Closed Lost and Sub-Type is Renewal,
                   -Set Renewal Path to FALSE
            - Field update should move to Trigger 
            - Email Alert should move to Workflow
        */
        System.debug(newRecord.StageName + '\n----: ' + (System.today().daysBetween(newRecord.CloseDate)));
        If((newRecord.StageName == '1 Discovery' || newRecord.StageName == '2 Consensus') && newRecord.CloseDate != null && 
           (System.today().daysBetween(newRecord.CloseDate)) <= 180){
            newRecord.Last_Stage_Update_Date__c = System.today();
        }else If(newRecord.StageName == '7 Closed Won' && newRecord.Opportunity_Sub_Type__c == 'Renewal'){
               newRecord.In_Forecast_Renewal__c = true;
        }else If((newRecord.StageName == '7 Closed Lost' || newRecord.StageName == '7 Closed Admin') && newRecord.Opportunity_Sub_Type__c == 'Renewal'){
               newRecord.In_Forecast_Renewal__c = false;
        }
  
        /* Process Builder's Name: Opp- Field Updates

            #1- While Create or Update Opportuniuty, if Help_Needed field has value
                 - Set Help Needed Date to Today
            #2- While Create or Update Opportuniuty, if Help_Needed_From field has value
                 - Set Help Needed From Updated Date to Today
            #3- While Create or Update Opportuniuty, if Exec_Sponsor field has value
                 - Set Exec Sponsor Updated Date to Today
            #4- While Create or Update Opportuniuty, if Legal_Priority field has value
                 - Set Help Legal Priority Updated Date to Today
        */
        If(newRecord.Help_Needed__c != null && (newRecord.id == null || newRecord.Help_Needed__c != oldRecord.Help_Needed__c)){
            newRecord.Help_Needed_Date__c = System.today();
        }
        /*If(newRecord.Help_Needed_From__c != null && (newRecord.id == null || newRecord.Help_Needed_From__c != oldRecord.Help_Needed_From__c)){
            newRecord.Help_Needed_From_Updated_Date__c = System.today();
        }*/



        /* Process Builder's Name: Opp- Lead Source Update

            If Initial_Contacts_Name is not null, 
            - Update Lead Source same as Initial_Contacts_Name's Lead Source
        */
        //SAL26-731
        If(!OpportunityObjectTriggerHandler.skipExecutionHandler && newRecord.Initial_Contacts_Name__c != null && (newRecord.id == null || newRecord.Initial_Contacts_Name__c != oldRecord.Initial_Contacts_Name__c)){
            //Contact initialContact = contactMap.get(newRecord.Initial_Contacts_Name__c);
            //PAG-2 - Added LeadSource != PAG check. In case of PAG Opty we need to keep Source as PAg, irrespective of Pr Contacts Source
            if(initialContact != null && newRecord.LeadSource != pagSource && newRecord.LeadSource != pqlSource){ // newRecord.LeadSource != pqlSource added for SAL25-816
                newRecord.LeadSource = initialContact.LeadSource;
            }
        }

        /* Process Builder's Name: Opp-Update Original Lead Owner after Appproval
            This WF updates original Lead Owner lookup to SDR/ISR once approved
            If SDR_Led is updated to True, 
            - Update Original Lead Owner to Initial_Submitter_Name

            If record got created with Original Lead Owner as null,  set default Original Lead Owner to Lead Owner.
        */
        if(newRecord.OriginalLeadOwner__c == null && newRecord.SDR_Led__c && newRecord.SDR_Led__c != oldRecord.SDR_Led__c){ //SAL24-405
            newRecord.OriginalLeadOwner__c = newRecord.Initial_Submitter_Name__c;
        }
        /*else if(newRecord.id == null && newRecord.OriginalLeadOwner__c == null){
            newRecord.OriginalLeadOwner__c = newRecord.Opportunity_Lead_Owner_Id__c;
        }*/ //SAL25-70

    }
    /**
     * Auto Update the Opportunity from Stage 5 to Stage  6 
     * Criteria - All opportunies Sales + Renewal Opportunity 
        - All required fields from stage 1 - 4 required are populated -
        - When the Cloud environment is not Blank
        - When the Rubrik CDM Release on source is not Blank 
        - When the Polaris Region is not Blank
        - When the Polaris Portal Contact is not Blank 
        - When the PO received notification is True 
        - When the RSM Validation is True "
     */
    public static void validateAndMoveOppToStageSix(Opportunity oldRecord, Opportunity newRecord, SBQQ__Quote__c primaryQuote, Map<Id,Account> accountMap){ //SF-25610
        //Select ID, Name, StageName, Cloud_Environment__c, Rubrik_CDM_Release_on_source_cluster__c, Polaris_Region__c, Polaris_Portal_Contact__c, PO_Received_Notification_Sent__c, Hold_Code__c, RecordType.name from Opportunity where ID in ('', '')
        System.debug('Inside  validateAndMoveOppToStageSix ');
        Set<string> stageNames = new Set<string>{'1 Discovery','2 Consensus','3 Technical Validation','4 Business Justification','5 Negotiate & Close'};
        Boolean rubrikContractConditions = false;
        if(!accountMap.isEmpty() && 
           accountMap.containskey(newRecord.AccountId)){
            if(accountMap.get(newRecord.AccountId).BillingStateCode != 'NY'&& 
                accountMap.get(newRecord.AccountId).BillingCountry == 'United States' && 
                (accountMap.get(newRecord.AccountId).ETM_Area__c == 'AMER-SLED-1' || accountMap.get(newRecord.AccountId).ETM_Area__c == 'AMER-SLED-2') && //SAL24-852
               (String.isNotBlank(newRecord.Rubrik_Contract__c) || String.isNotBlank(newRecord.Partner_Business_Type__c)) && 
               (accountMap.get(newRecord.AccountId).Industry == 'Education' || accountMap.get(newRecord.AccountId).Industry == 'State Government' || accountMap.get(newRecord.AccountId).Industry == 'Local Government' 
               	|| accountMap.get(newRecord.AccountId).Industry == 'Government' || accountMap.get(newRecord.AccountId).Industry == 'Education - K-12' 
               	|| accountMap.get(newRecord.AccountId).Industry == 'Education - Higher Ed' || accountMap.get(newRecord.AccountId).Industry == 'Special District' 
               	|| accountMap.get(newRecord.AccountId).Industry == 'K-12 Schools' ||accountMap.get(newRecord.AccountId).Industry == 'Local' || accountMap.get(newRecord.AccountId).Industry == 'State')){
                    rubrikContractConditions = true;
               }else if(accountMap.get(newRecord.AccountId).BillingStateCode == 'NY' && //SAL24-304
                        (String.isNotBlank(newRecord.Rubrik_Contract__c) || (newRecord.Rubrik_Contract__c == 'State of New York OGS' && String.isNotBlank(newRecord.Partner_Business_Type__c)))){
                   rubrikContractConditions = true;
               }
               }
               //SAL25-591
               if(((newRecord.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp && stageNames.contains(newRecord.StageName)) || newRecord.StageName == '5 Negotiate & Close') && newRecord.PO_Received_Notification_Sent__c && newRecord.Opportunity_Type__c != 'Debooking' 
                && newRecord.Opportunity_Sub_Type__c != 'MSP Overage' && newRecord.Opportunity_Sub_Type__c != 'MSP'                                           
                && String.isNotBlank(newRecord.Cloud_Environment__c) 
                // && String.isNotBlank(newRecord.Partner_Level_Of_Involvement__c)
                && ((String.isNotBlank(newRecord.Lost_To_Won_Against__c) && newRecord.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp) || newRecord.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp) //SAL25-548
                && ((String.isNotBlank(newRecord.Win_Loss_Comments__c ) && newRecord.RecordTypeId != OpportunityUtil.oppRecTypeIdRenewOpp) || newRecord.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp) //SAL25-548
                && String.isNotBlank(newRecord.Cloud_Type__c)
                // && (String.isNotBlank(newRecord.Alliance_Source_Type_HW__c) || (String.isBlank(newRecord.Alliance_Source_Type_HW__c) && newRecord.Alliance_HW_Partner__c.contains('None'))) //SAL24-387
                //&& (String.isNotBlank(newRecord.Cloud_Partner_Led_Activity__c) || (String.isNotBlank(newRecord.Alliance_Partner_Name__c) && newRecord.Alliance_Partner_Name__c.contains('None')))                && (String.isNotBlank(newRecord.Cloud_Partner_Impact__c)|| (String.isNotBlank(newRecord.Alliance_Partner_Name__c) && newRecord.Alliance_Partner_Name__c.contains('None')))  //SAL25-591
                && (String.isNotBlank(newRecord.Alliance_Partner_Name__c) && (!newRecord.Alliance_Partner_Name__c.contains(';') || newRecord.Alliance_Partner_Name__c.contains('None')))
                && (((String.isNotBlank(newRecord.Forward_Pass_Contact__c) && String.isNotBlank(newRecord.Forward_Pass_Contact_Mail__c)) && newRecord.Forward_Pass__c > 0 ) || (newRecord.Forward_Pass__c == 0 || newRecord.Forward_Pass__c == null))   //SF-25610
                && !rubrikContractConditions//SAL24-304
                && ((newRecord.Old_TradeUp_Click_Thru_Process__c && (newRecord.Remove_Trade_Up_Hold__c || (primaryQuote != null && (primaryQuote.Trade_Up_Amounts__c == null || primaryQuote.Trade_Up_Amounts__c <= 0)))) //SF-25610 //SAL24-443
                    || (!newRecord.Old_TradeUp_Click_Thru_Process__c && (newRecord.PDF_Addendum_Email_Delivered__c || (primaryQuote != null && (primaryQuote.Trade_Up_Amounts__c == null || primaryQuote.Trade_Up_Amounts__c <= 0))))) //SAL24-443
                && (String.isBlank(newRecord.Opportunity_Program__c) || (String.isNotBlank(newRecord.Opportunity_Program__c) && !newRecord.Opportunity_Program__c.contains('Conversion')) || (String.isNotBlank(newRecord.Opportunity_Program__c) && newRecord.Opportunity_Program__c.contains('Conversion') && String.isNotBlank(newRecord.Click_Thru_Contact_Email__c) && newRecord.Click_Through_Email_Sent__c == true && !accountMap.isEmpty() && accountMap.containskey(newRecord.AccountId) && accountMap.get(newRecord.AccountId).Conversion_Terms_Accepted__c == true)) //SAL23-788
                && (newRecord.UCL_Scale_Percentage__c == null || (newRecord.UCL_Scale_Percentage__c != null && newRecord.Scale_Cloud_Validated__c && newRecord.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp)) //SAL26-157
        ){
            boolean isPolarisConditionMatched = (!newRecord.Has_Polaris_Product__c || (newRecord.Has_Polaris_Product__c && newRecord.Polaris_Portal_Contact__c != null && String.isNotBlank(newRecord.Polaris_Region__c) ));
            if(isPolarisConditionMatched){ //SAL25-591
                newRecord.StageName = '6 PO With Channel';
                newRecord.Moved_stage_5to6_via_Automation__c = true; //SAL23-853
            }
        }
    }
    public static void notifyToParentAccountOwner(List<Opportunity> newOpportunityList, Set<ID> parentChildAccountIdSet){//SAL23-189
        Map<ID, Account> parentChildAccountsDetailsMap = new Map<ID, Account>([Select ID, Name, RecordTypeId, RecordType.Name, ParentId, createdById, LastModifiedById, ETM_Area__c, ETM_Region__c, ETM_Territory__c, ETM_Theatre__c, OwnerId, Owner.Name, Owner.ManagerId from Account where ID IN :parentChildAccountIdSet]);
        Set<Id> accountOwnersIdSet = new Set<Id>();
        for(Account ac: parentChildAccountsDetailsMap.values()){
            accountOwnersIdSet.add(ac.OwnerId);
        }
        Map<Id, Id> userIdRsmUserIdMap =  getRSMUser(accountOwnersIdSet);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        ID templateId = [Select id from EmailTemplate where DeveloperName = 'NewOpportunityUnderDiffTerritorySubAC'].id;
        for(Opportunity opp : newOpportunityList) {
            if(opp.AccountId != null && opp.Opportunity_Type__c != 'Debooking' && opp.Opportunity_Sub_Type__c != 'MSP Overage' && opp.RecordTypeId != oppRecTypeIdRenewOpp){ //SAL23-480
                Account childAc =  parentChildAccountsDetailsMap.get(opp.AccountId);
                if(childAc != null && childAc.ParentId != null){
                    Account parentAc = parentChildAccountsDetailsMap.get(childAc.ParentId);
                    if(childAc.OwnerId != parentAc.OwnerId && parentAc.RecordType.Name == 'Customer/Prospect' &&
                     (String.isBlank(childAc.ETM_Territory__c) || (String.isNotBlank(childAc.ETM_Territory__c) &&  
                     childAc.ETM_Territory__c != parentAc.ETM_Territory__c) && parentAc.ETM_Theatre__c != 'DNA' && childAc.ETM_Theatre__c != 'DNA')
                     ){
                        mails.add(EmailHelper.getSingleEmailMessageObj(
                            /*toUserIds = */ new Set<String>{'' + parentAc.OwnerId, '' + userIdRsmUserIdMap.get(parentAc.OwnerId), '' + childAc.OwnerId, '' + userIdRsmUserIdMap.get(childAc.OwnerId)}, 
                            /*ccUserIds = */ null,
                            /*bccUserIds = */ null,
                            /*fromUserId = */ opp.LastModifiedById, 
                            /*recordIdToMailMerge = */ opp.id, 
                            /*templateId = */ templateId
                        ));
                    }
                }
            }
        }
        if(!mails.isEmpty() && !Test.isRunningTest()) {
            Messaging.SendEmailResult[] r = Messaging.sendEmail(mails);
        }
    }

    
    public static Map<Id, Id> getRSMUser(Set<Id> userIdSet){ 
        Map<Id, Id> userToParentTerrIdMap = new Map<Id, Id>();
        for(UserTerritory2Association uta :[SELECT Id, UserId, Territory2Id, Territory2.Territory2Type.DeveloperName, Territory2.ParentTerritory2Id 
                FROM UserTerritory2Association WHERE Territory2.Territory2Model.State = 'Active' and UserId IN :userIdSet and RoleInTerritory2 = 'Account Executive' and Territory2.Territory2Type.DeveloperName = 'Territory']){
            if(uta.Territory2?.ParentTerritory2Id != null){
                userToParentTerrIdMap.put(uta.UserId, uta.Territory2.ParentTerritory2Id);
            }
        }

        Map<Id, Id> terrToRSMMap = new Map<Id, Id>();
        for(UserTerritory2Association uta :[SELECT Id, UserId, Territory2Id FROM UserTerritory2Association
                                            WHERE Territory2.Territory2Model.State = 'Active' and Territory2Id IN :userToParentTerrIdMap.values() and RoleInTerritory2 = 'Regional Director' and Territory2.Territory2Type.DeveloperName = 'Region']){
            terrToRSMMap.put(uta.Territory2Id, uta.UserId);
        }
        
        Map<Id, Id> userToRSMMap = new Map<Id, Id>();
        for(Id uId :userIdSet){
            userToRSMMap.put(uId, (userToParentTerrIdMap.containsKey(uId) ? terrToRSMMap.get(userToParentTerrIdMap.get(uId)): null) );
        }
        return userToRSMMap;
    }

    public static void updateSeManagerOnSpecialistRequest(Set<ID> oppIdSalesEngineerchangedSet){
        List<Specialist_Request__c> srList = new List<Specialist_Request__c>();
        for(Specialist_Request__c sr: [Select ID, Opportunity__c, Opportunity__r.Rubrik_Sales_Engineer__r.ManagerId, SE_Manager__c from Specialist_Request__c where ID IN :oppIdSalesEngineerchangedSet]){
            if(sr.Opportunity__r.Rubrik_Sales_Engineer__c != null && sr.Opportunity__r.Rubrik_Sales_Engineer__r.ManagerId != sr.SE_Manager__c){
                sr.SE_Manager__c = sr.Opportunity__r.Rubrik_Sales_Engineer__r.ManagerId;
                srList.add(sr);
            }
        }
        if(!srList.isEmpty()){
            update srList;
        }
    }
    //SAL24-682
    public static void resetArroyoFields(Opportunity opp){
        opp.Expansion_ACV__c = 0;
        if(!opp.Opportunity_Amount_Override__c){ //SAL25-145
		opp.New_Expansion_ACV__c = 0;
	        opp.New_Expansion_TCV__c = 0;
	        opp.Renewal_Subsumed_ACV__c = 0;
	        opp.Subsumed_Renewal_TCV__c = 0;
            opp.Comp_Uplift_ACV__c = 0; //SAl26-1277
	        OppAnnualContractValueUtil.resetACVonOpp(opp); //PL26-24
        }
        opp.Expansion__c = 0;
        opp.Total_Quote_Value_ACV__c = 0;
        opp.Max_Renewal_Amount__c = 0;
        opp.Prior_Annual_Contract_Value__c = 0;
        opp.Renewal_ACV__c = 0;
        opp.Renewal_TCV__c = 0;
        opp.RSC_Version__c  = ''; //SAL26-94
        opp.Has_UCL_Scale_Products__c = false; //SAL26-389
        opp.RBOBACV__c = 0; //FY25SR-1119
    }
}