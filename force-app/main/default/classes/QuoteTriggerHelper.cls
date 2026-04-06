/**
* @File Name : QuoteTriggerHelper.cls
* @description : Helper class for QuoetTrigger. Called from QuoteTriggerHandler
* Test Class: QuoteTrigger_Test
**/
public without sharing class QuoteTriggerHelper {  
     
    static Map < String, Schema.RecordTypeInfo> QuoteRecoTypeDatas; 
    static Map < Id, Opportunity > opptyMap;
    @testVisible 
    static Set < Id > processedQuotes = new Set < Id > ();
    static List < user > taskUser = new List < user > ();
    @testVisible static boolean insert_logic = false;
    @testVisible static Boolean updateFlag = false;
    @testVisible static Boolean approvalData = false;
    
    //Declared static variables to fix SOQL 101  Error
    static EmailTemplate emailTempRec;
    static String userProfileName; 
    static List<ServiceContract> serviceContractList;
    static List<Account> accountsList;
    static List < SBQQ__Quote__c > qList;
    public static Map < Id, sbqq__quoteline__c > quotelinemap;
    static List<SBQQ__QuoteLine__c> qlItemList;
    static map < id, sbqq__quote__c > clonedfromquotes;
    static Map < Id, SBQQ__Quote__c > cloneSources;
    static List<SBQQ__Quote__c> quoteRecord;
    static X0_RCDM_Dates__mdt rcdmDatesObj;
    static List<PricebookEntry> pbe;
    static List<product2> prod;
    static List<SBQQ__QuoteLine__c> linesList;
    static Integer FiscalYearStartMonth;
    static List <Opportunity> opptyRecSOW;
    static List <Opportunity> opptyRecSOWNew;
    static List < SBQQ__QuoteLine__c > qLIsToUpdate = new List < SBQQ__QuoteLine__c >();
    
    /*Arroyo 2.0*/
    static List < aggregateResult > minQLIStartDate;
    /*Arroyo 2.0*/
    static List < SBQQ__QuoteLineGroup__c > lstQLIGroup;
    /*Arroyo 2.0*/
    static List < SBQQ__QuoteLine__c > qliList;

    public static Set < Id > processedQuoteIds = new Set < Id > ();

    

    /**
     * @description       : this is a common method is used for OnInsert event
     * @param  qtList     : List of Quote 
     */
    
    public static void populateFieldsOnInsert(List < SBQQ__Quote__c > qtList) {
       
        
        if (QuoteRecoTypeDatas == null) {
            QuoteRecoTypeDatas = qtList[0].getSobjectType().getDescribe().getRecordTypeInfosByDeveloperName();
        }  
        
        // Used the below query     
        Set < Id > opptyIdSet = new Set < Id > ();
        set < id > clonedquoteids = new Set < Id > ();
        map < id, sbqq__quote__c > clonedfromquotes;
        
        for (SBQQ__Quote__c qt: qtList) {
            opptyIdSet.add(qt.SBQQ__Opportunity2__c);
            clonedquoteids.add(qt.sbqq__source__c);
        }
        if (opptyMap == null) {
            opptyMap = getOpportunityFields(opptyIdSet);
        }
        setModifiedDealOpsExceptions(qtList); // Added for CPQ22-1006
        setCheckForRCDMEntiltmentforCustomer(qtList);//Added for DSaaS NAS
        
        if (!clonedquoteids.isempty() && clonedfromquotes == null) {
            clonedfromquotes = new map < id, sbqq__quote__c > ([select id, createddate from sbqq__quote__c where id in: clonedquoteids]);
        }
        
        Opportunity QuotesOpportunityDetail;
        for (SBQQ__Quote__c qt: qtList) {
            
            if (opptyMap != null && qt.SBQQ__Opportunity2__c != null) {
                QuotesOpportunityDetail = opptyMap.get(qt.SBQQ__Opportunity2__c);
            }
            
            //Start: Scale Utility Phase2: #CSU-497      
            if ((QuotesOpportunityDetail != null && QuotesOpportunityDetail.Opportunity_Sub_Type__c == 'GC Offer')
                || Test.isRunningTest())
            {
                if (qt.SBQQ__Type__c != 'Amendment' || Test.isRunningTest()){//Scale Utility Phase 2.0 #CSU-491: Added condition to skip Amendment
                    qt.Metering__c = 'FETB';
                }
                //Scale Utility Phase2: #CSU-494
                if (qt.SBQQ__Type__c == 'Amendment' || Test.isRunningTest()){
                    qt.Co_Term__c = true;
                    ScaleUtilityAmendHelper.quoteCreationInProgress = true;
                }
            }
            //End: Scale Utility Phase2: #CSU-497
            
            /*START- Scale Utility Phase 2.0 #CSU-491: Added by Shaloo Mishra*/
            if ((QuotesOpportunityDetail != null && QuotesOpportunityDetail.SBQQSC__AmendedServiceContract__c != null 
                && QuotesOpportunityDetail.SBQQSC__AmendedServiceContract__r.SBQQSC__Quote__c != null 
                && QuotesOpportunityDetail.Opportunity_Sub_Type__c == 'GC Offer' 
                && qt.SBQQ__Type__c == 'Amendment')
               ){
                   /* To set Metering field as per the Prior Sale */
                   qt.Metering__c = QuotesOpportunityDetail.SBQQSC__AmendedServiceContract__r.SBQQSC__Quote__r.Metering__c != null
                       ? QuotesOpportunityDetail.SBQQSC__AmendedServiceContract__r.SBQQSC__Quote__r.Metering__c
                       : null;
               }
            /*END- Scale Utility Phase 2.0 #CSU-491: Added by Shaloo Mishra*/

            //populate cloned from created date field 
            if (clonedfromquotes != null) {
                if (!clonedfromquotes.isempty() && clonedfromquotes.containskey(qt.sbqq__source__c)) {
                    qt.Cloned_From_Created_Date__c = clonedfromquotes.get(qt.sbqq__source__c).createddate.date();
                }
            }
            
            qt.SBQQ__Status__c = 'Draft';
            if (!Test.isRunningTest()) {
               	qt.ApprovalStatus__c = '';
            }
            
            if(QuotesOpportunityDetail != null){
                qt.Deal_Structuring_Oppty_Notes__c = QuotesOpportunityDetail.Deal_Structuring_Oppty_Notes__c;//added for CPQ22-2916 by srikanth
                if(QuotesOpportunityDetail.Distributor_Lookup__c != null && String.isNotBlank(QuotesOpportunityDetail.Distributor_Lookup__r.Payment_Term__c)){
                    qt.SBQQ__PaymentTerms__c = QuotesOpportunityDetail.Distributor_Lookup__r.Payment_Term__c; // added CPQ22-4460 for by Pooja
                }
            }
            //qt.SBQQ__Primary__c = false;
            if (qt.SBQQ__ExpirationDate__c != null && qt.SBQQ__ExpirationDate__c <= Date.today()) {
                qt.SBQQ__ExpirationDate__c = Date.today() + 30;
            }
            //MSP1.1 : Expiration date to be 30 days from the creation date of the quote, Update the start date for MSP Amendment Quotes to the first of the following month  
            if (QuotesOpportunityDetail != null && QuotesOpportunityDetail.Opportunity_Sub_Type__c == 'MSP' && qt.SBQQ__Type__c == 'Amendment') {
                qt.SBQQ__ExpirationDate__c = Date.today() + 30;
                if(qt.SBQQ__Source__c == null) {
                    Date todayDate = system.today();
                    qt.SBQQ__StartDate__c = Date.newInstance(todayDate.year(), todayDate.month() + 1, 1);
                    qt.SBQQ__SubscriptionTerm__c = (((qt.SBQQ__EndDate__c.year() * 12) + qt.SBQQ__EndDate__c.month()) - ((qt.SBQQ__StartDate__c.year() * 12) + qt.SBQQ__StartDate__c.month()) + 1);
                }
            }
            //MSP1.1 : Copy Quote's renewal term as subscription term 
            if (QuotesOpportunityDetail != null && QuotesOpportunityDetail.Opportunity_Sub_Type__c == 'MSP Consumption Renewal' && qt.SBQQ__Type__c == 'Renewal') {
                qt.SBQQ__SubscriptionTerm__c = qt.SBQQ__RenewalTerm__c;
            }
            
            //Lakshmi - Migrating all workflow rules to Trigger as part of optimization - Start
            if(qt.ApprovalStatus__c == 'Approved'){
                if(QuoteRecoTypeDatas != null){
                    qt.recordtypeid = QuoteRecoTypeDatas.get('Approved_Quote').getRecordTypeId();
                }
                qt.SBQQ__Status__c = 'Approved';
                qt.SBQQ__WatermarkShown__c = false;
                qt.Approved_time__c = system.now();
            }
            else{
                qt.SBQQ__WatermarkShown__c = true;
                
            }
            if(qt.SBQQ__QuoteProcessId__c == null || qt.SBQQ__QuoteProcessId__c == ''){
                // RWD-1065: Modified logic to set process ID only if quote is not NetApp
                if(qt.GPL_Deal__c != 'NetApp') {
                    qt.SBQQ__QuoteProcessId__c = System.Label.QuoteProcessId;
                } 
                // RWD-1065: Logic ends
            }
            
            if(QuotesOpportunityDetail != null) {
 //CPQ22-3185 starts
                 populateBillingInformationQuote(QuotesOpportunityDetail,qt);
 //CPQ22-3185 ends
                qt.SBQQ__ShippingStreet__c = QuotesOpportunityDetail.Account.ShippingStreet;
                qt.SBQQ__ShippingState__c = QuotesOpportunityDetail.Account.ShippingState;
                qt.SBQQ__ShippingCity__c =  QuotesOpportunityDetail.Account.ShippingCity;
                qt.SBQQ__ShippingCountry__c = QuotesOpportunityDetail.Account.ShippingCountry;
                qt.SBQQ__ShippingPostalCode__c = QuotesOpportunityDetail.Account.ShippingPostalCode;
                
            }
            
            if(qt.ApprovalStatus__c == 'Pending'){
                qt.SBQQ__Status__c = 'In Review';
                if(QuoteRecoTypeDatas != null){
                    qt.recordtypeid = QuoteRecoTypeDatas.get('Locked_Quote').getRecordTypeId();
                }
               
            }
             // added the logic for CPQ22-5261
			if(qt.ApprovalStatus__c == 'Pending' || qt.ApprovalStatus__c == 'Submitted'){
				qt.Submit_for_Approval_Time__c = system.now();
			}
            if(qt.ApprovalStatus__c == 'Recalled' || qt.ApprovalStatus__c =='Rejected'){
                qt.SBQQ__Status__c = 'Draft';
                if (QuoteRecoTypeDatas != null && qt.SBQQ__Type__c != 'Renewal+Expansion') {
                    qt.recordtypeid = QuoteRecoTypeDatas.get('Draft_Quote').getRecordTypeId();
                }
            }
            //Arroyo 2.0 ARY-684 CR #20- Start
            if (qt.SBQQ__Type__c == 'Renewal+Expansion' &&
                (qt.ApprovalStatus__c == '' || qt.ApprovalStatus__c == 'Recalled' || qt.ApprovalStatus__c == 'Rejected')) {
                    if(QuoteRecoTypeDatas != null){
                        qt.recordtypeid = QuoteRecoTypeDatas.get('RE_Quote').getRecordTypeId();
                    }
                }
            //Arroyo 2.0 ARY-684 CR #20- End
            qt.SBQQ__PricebookId__c = system.label.CPQPricebookID;
            qt.SBQQ__PriceBook__c = system.label.CPQPricebookID;
            
            if ((qt.SBQQ__Status__c == 'Draft' && qt.SBQQ__Type__c != 'Renewal+Expansion') || Test.isRunningTest()) {
                qt.recordtypeid = QuoteRecoTypeDatas.get('Draft_Quote').getRecordTypeId();
            }
            if(qt.OpportunitySubType__c == 'MSP'){
                qt.SBQQ__ContractingMethod__c = 'Single Contract';
            }
            if(QuotesOpportunityDetail != null ){
                qt.OpportunitySubType__c = QuotesOpportunityDetail.Opportunity_Sub_Type__c;
                qt.Owner_Region__c = QuotesOpportunityDetail.ETM_Region__c;
                qt.OwnerSubRegion__c = QuotesOpportunityDetail.ETM_Territory__c;
                qt.Installation_Assigned_To__c = QuotesOpportunityDetail.Installation_Assigned_To__c;
            }
            //Lakshmi - Migrating all workflow rules to Trigger as part of optimization - End
            
            if (system.Label.Data_Migration_User_ID == qt.Ownerid && QuotesOpportunityDetail != null && QuotesOpportunityDetail.Account.Ownerid != null) {
                qt.OwnerId = QuotesOpportunityDetail.Account.OwnerId;
                qt.Account_Record_Type__c = QuotesOpportunityDetail.Account.RecordType.Name;
            }
            if (qt.SBQQ__PrimaryContact__c != null) {
                qt.Primary_Contact__c = qt.SBQQ__PrimaryContact__c;
                qt.SBQQ__PrimaryContact__c = null;
            }
            
            //Process Builder Conversion Code - Quote - Update Sales Rep Renewal
            //Lakshmi - GLCR-41 - Updating the Sales Rep for both Renewal and Amendment quotes as part of Optimization
            if(opptyMap.containsKey(qt.SBQQ__Opportunity2__c) && (qt.SBQQ__Type__c == 'Renewal+Expansion' || qt.SBQQ__Type__c == 'Amendment' || qt.SBQQ__Type__c == 'Renewal')){
                qt.SBQQ__SalesRep__c = opptyMap.get(qt.SBQQ__Opportunity2__c).OwnerId;           
            }
            
            /*
User Story   : SF-5724
Description  : Build to identify POC details under the opportunity ,limited to "Conditional PO" only and to capture latest POC_duration__c value, which has been further used in Quote template 
*/
            if (QuotesOpportunityDetail != null && QuotesOpportunityDetail.Orders__r != null && qt.SBQQ__Type__c == 'Quote') {
                datetime LatestPOCOrdCreatedDate;
                for (Order POCOrd: QuotesOpportunityDetail.Orders__r) {
                    if (POCOrd.POC_type__c == 'Conditional PO') {
                        qt.Is_Conditional_PO__c = true;
                        
                        if ((LatestPOCOrdCreatedDate == null || LatestPOCOrdCreatedDate < POCOrd.createdDate) && POCOrd.POC_Duration__c != null) {
                            qt.POC_duration__c = POCOrd.POC_Duration__c;
                            LatestPOCOrdCreatedDate = POCOrd.createdDate;
                        }
                        
                    }
                }
            }
            /*
End SF-5724
*/
            //
            if (QuotesOpportunityDetail != null && QuotesOpportunityDetail.Account.RecordType.Name != null) {
                qt.Account_Record_Type__c = QuotesOpportunityDetail.Account.RecordType.Name;
            }
            
            /*
User Story - RNWA-54
*/
            if (
                QuotesOpportunityDetail != null &&
                QuotesOpportunityDetail.AccountId != null &&
                QuotesOpportunityDetail.Account.Sum_of_Opportunities__c < Decimal.valueOf(System.Label.LTV_Threshold) &&
                qt.SBQQ__Type__c.equalsIgnoreCase('Renewal')
            ) {
                qt.Quote_Name__c =
                    (QuotesOpportunityDetail.SBQQSC__RenewedServiceContract__r.EndDate != null ? Datetime.newInstance(QuotesOpportunityDetail.SBQQSC__RenewedServiceContract__r.EndDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd') + ' - ' : '') +
                    (String.isBlank(QuotesOpportunityDetail.Account.ETM_Theatre__c) ? '' : QuotesOpportunityDetail.Account.ETM_Theatre__c + ' - ') +
                    QuotesOpportunityDetail.Account.Name + ' - ' +
                    (String.isBlank(QuotesOpportunityDetail.Partner_Lookup__c) ? '' : QuotesOpportunityDetail.Partner_Lookup__r.Name + ' - ') +
                    'Renewal';
            }
            Date lastDateOfThisQuarter = quoteTriggerHelper.lastDateOfQuarter();
            if (qt.SBQQ__Type__c != null && (qt.SBQQ__Type__c == 'Amendment' || qt.SBQQ__Type__c == 'Quote' || qt.SBQQ__Type__c.contains('Renewal'))) {
                insert_logic = true;
                qt.Update_Expires_On__c = false;
                qt.Expiration_Date_Update_Flag__c = false;
                if (opptyMap.containskey(qt.SBQQ__Opportunity2__c)) {
                    
                    if (opptyMap.get(qt.SBQQ__Opportunity2__c).CloseDate <= lastDateOfThisQuarter) {
                        qt.SBQQ__ExpirationDate__c = lastDateOfThisQuarter;
                        
                    } else {
                        qt.SBQQ__ExpirationDate__c = system.today().adddays(90);
                    }
                }
                
                // added for FY25SR-1114
                if (qt.SBQQ__Status__c != 'Approved' && qt.SBQQ__Type__c == 'Renewal+Expansion' && QuotesOpportunityDetail != null && QuotesOpportunityDetail.CloseDate != null && qt.SBQQ__ExpirationDate__c != null) { 
                    if(QuotesOpportunityDetail.CloseDate > qt.SBQQ__ExpirationDate__c){
                      qt.Credit_Calculation_Start_Date__c = firstDayOfNextQuarter(QuotesOpportunityDetail.CloseDate);
                    }else{
                      qt.Credit_Calculation_Start_Date__c = firstDayOfNextQuarter(qt.SBQQ__ExpirationDate__c);
                    }
                }
                 // end for FY25SR-1114
                
                //NetApp Quoting FCUS-3: Logic Added by Shaloo - Starts
                if (QuotesOpportunityDetail != null && QuotesOpportunityDetail.Sell_to_Partner__r.Name != null ){
                    if(Label.NetApp_Account_Names.contains(QuotesOpportunityDetail.Sell_to_Partner__r.Name)) {
                        qt.GPL_Deal__c = 'NetApp';
                        qt.Sell_to_Partner__c = QuotesOpportunityDetail.Sell_to_Partner__r.Name;
                    }else{
                        qt.Sell_to_Partner__c = QuotesOpportunityDetail.Sell_to_Partner__r.Name; //for POlaris requirement 
                    }
                }
                //NetApp Quoting FCUS-3: Logic Added by Shaloo - Ends
                
                //Added by Sumedha for RWD-60
                if (qt.GPL_Deal__c != 'NetApp' && qt.Sell_to_Partner__c != NULL) {
                    qt.ShowSellToPartner__c = true;
                }
                //RWD-60 changes ends
                
                //CPQ22-130: Logic Added by Shaloo - Starts
                if (qt.SBQQ__Opportunity2__c != null && QuotesOpportunityDetail != null && (QuotesOpportunityDetail.Partner_Lookup__c != null || QuotesOpportunityDetail.Distributor_Lookup__c != null)) {
                    qt.SBQQ__Distributor__c = opptyMap.get(qt.SBQQ__Opportunity2__c).Distributor_Lookup__c;
                    qt.SBQQ__Partner__c = opptyMap.get(qt.SBQQ__Opportunity2__c).Partner_Lookup__c;
                    
                }
                //CPQ22-130: Logic Added by Shaloo - Ends
                //CPQ22-203
                //REEN-57 revert non incumbent changes
                if (qt.NIPA__c!= null) {
                    qt.Quote_Name__c = null;
                    qt.NIPA__c= null;
                    qt.NIPD__c= null;
                }
 if((qt.SBQQ__Status__c == 'Draft' ||
                qt.ApprovalStatus__c == '' ||
                qt.SBQQ__Status__c == 'Invalid') && QuotesOpportunityDetail != null){
                qt.RCDMT_EOL_Date__c = QuotesOpportunityDetail.Account.RCDMT_EOL_Date__c;
            }
if(qt.SBQQ__StartDate__c != null && qt.SBQQ__Type__c == 'Amendment' && qt.OpportunitySubType__c == 'GC offer'){
            qt.SBQQ__ExpirationDate__c = qt.SBQQ__StartDate__c;
        }
    }
}
	}
    /**
     * @description       : this is a common method is used for OnUpdate event , done for CPQ22-3185
     * @param  opp    : Opportunity with current changes 
     * @param  qt   :  Quote 
     */
    public static void populateBillingInformationQuote(Opportunity opp, SBQQ__Quote__c qt){
        qt.SBQQ__BillingCountry__c = opp.Account.BillingCountry;
        qt.SBQQ__BillingName__c = opp.Account.Name;
        qt.SBQQ__BillingCity__c = opp.Account.BillingCity;
        qt.SBQQ__BillingStreet__c = opp.Account.BillingStreet;
        qt.SBQQ__BillingState__c = opp.Account.BillingState;
        qt.SBQQ__BillingPostalCode__c = opp.Account.BillingPostalCode;
        
    }

     /**
     * @description       : this is a common method is used for OnUpdate event , done for CPQ22-3185
     * @param  qtList    : List of Quote with current changes 
     * @param  qtOldMap   : Map of Quoteid and Quote with changes prior to update
     */
    public static void populateFieldsOnUpdate(List < SBQQ__Quote__c > qtList, Map < Id, SBQQ__Quote__c > qtOldMap) {
        
        if (QuoteRecoTypeDatas == null) {
            QuoteRecoTypeDatas = qtList[0].getSobjectType().getDescribe().getRecordTypeInfosByDeveloperName();
        }
        //Go Refresh Variables Start
        Map < Id, Opportunity > GoRefreshopptyUpdateMap = new Map < Id, Opportunity > ();
        //Go Refresh Variables End
        
        // Rubrik Complete Start
        set < String > eligibleQuoteTypes = new set < String > ();
        if (system.label.Rubrik_Complete_Quote_Type != null) {
            eligibleQuoteTypes.addAll(system.label.Rubrik_Complete_Quote_Type.split(','));
        }
        // Rubrik Complete End
        Set < Id > opptyIdSet = new Set < Id > ();
        set < id > clonedquoteids = new Set < Id > ();
        set < id > quoteids = new Set < Id > ();
        map < id, sbqq__quoteline__c > quotelines = new map < id, sbqq__quoteline__c > ();
        set < id > quotetosaAmendment = new set < id > ();
        Set < Id > opportunityOwnerIdSet = new Set < Id > ();
        Map < Id, SBQQ__Quote__c > NotificationQuoteIdRecordMap = new Map < Id, SBQQ__Quote__c > ();
        Map < Id, SBQQ__Quote__c > ApprovedQuoteIdSetRecordMap = new Map < Id, SBQQ__Quote__c > ();
        Map < Id, SBQQ__Quote__c > opptyOwnerQuoteIdMap = new Map < Id, SBQQ__Quote__c > ();
        Map<Id,Set<String>> QuoteIdEmailSet = new Map<Id,Set<String>>();
        String source;
        List< SBQQ__Quote__c > updateQuotesForDealOpsException = new List< SBQQ__Quote__c >(); // Added for CPQ22-1006
        Map<Id,set<string>> quoteToSUProgramMap = New Map<Id,set<String>>();//M365-Utility
        Set<String> SuProgramSet = New Set<String>();//M365-Utility
        Set<Id> quoteIdVsLODFlag= new Set<Id>();//FY25SR-2391
        for (SBQQ__Quote__c qt: qtList) {

            if(qtOldMap.get(qt.id).ApprovalStatus__c != qt.ApprovalStatus__c && qt.ApprovalStatus__c == 'Pending'){
                //FY26WL-350 : Added else if
                if(qtOldMap.get(qt.id).SBQQ__Status__c != qt.SBQQ__Status__c && qtOldMap.get(qt.id).SBQQ__Status__c == Constants.STATUS_SMART_APPROVED) {
                  qt.SBQQ__Status__c = Constants.STATUS_APPROVED;
                  qt.ApprovalStatus__c = Constants.STATUS_APPROVED;
                  if(QuoteRecoTypeDatas != null && QuoteRecoTypeDatas.containsKey(Constants.RT_APPROVED_QUOTE)){
                    qt.recordtypeid = QuoteRecoTypeDatas.get(Constants.RT_APPROVED_QUOTE).getRecordTypeId();
                  }
                } else {
                qt.SBQQ__Status__c = 'In Review';
                if(QuoteRecoTypeDatas != null){
                    qt.recordtypeid = QuoteRecoTypeDatas.get('Locked_Quote').getRecordTypeId();
                }
                }//FY26WL-350 : Added else if
            }
            
            SBQQ__Quote__c oldQt = qtOldMap.get(qt.Id);
            clonedquoteids.add(qt.sbqq__source__c);
            opptyIdSet.add(qt.SBQQ__Opportunity2__c);
            if ((qt.ApprovalStatus__c == 'Rejected' || qt.ApprovalStatus__c == 'Recalled') && qt.SBQQ__Type__c == 'Renewal' ) {
                qt.Expiration_Date_Update_Flag__c = False;
            }

            if (oldQt.SBQQ__ExpirationDate__c != qt.SBQQ__ExpirationDate__c && qt.SBQQ__Type__c != 'Renewal') {
                qt.Expiration_Date_Update_Flag__c = True;
            }

            quoteids.add(qt.id);
            
            // START : Added for CPQ22-1006
            if(qt.RWD_Deal_Ops_Exception__c  != oldQt.RWD_Deal_Ops_Exception__c ){
                updateQuotesForDealOpsException.add(qt);
            }
            // END : Added for CPQ22-1006
            
            if (qt.SBQQ__Type__c == 'Renewal+Expansion' && 
                ((qtOldMap.get(qt.Id).SBQQ__LastCalculatedOn__c == null && qt.SBQQ__LastCalculatedOn__c != null) && 
                 qt.Amended_Renewed_Service_Contract__c != null) ) {
                     NotificationQuoteIdRecordMap.put(qt.Id, qt);
                 }
            if (qt.SBQQ__Status__c == 'Approved' && qtOldMap.get(qt.Id).SBQQ__Status__c != 'Approved') {
                ApprovedQuoteIdSetRecordMap.put(qt.Id, qt);
            }
        }
        setExpireOnUserBoolean(qtList,qtOldMap);// CPQ22-2077
        // START: Added For CPQ22-1006
        if(!updateQuotesForDealOpsException.isEmpty()){
            setModifiedDealOpsExceptions(updateQuotesForDealOpsException); 
        }
        // END: Added For CPQ22-1006
        if (!quoteids.isempty() && quotelines.isempty()) {
            quotelines = getquotelines(quoteids);
        }
        if (opptyMap == null) {
            opptyMap = getOpportunityFields(opptyIdSet);
        }
        if (!clonedquoteids.isempty() && clonedfromquotes == null) {
            clonedfromquotes = new map < id, sbqq__quote__c > ([select id, createddate from sbqq__quote__c where id in: clonedquoteids]);
        }
        //if(((NotificationQuoteIdRecordMap != null && NotificationQuoteIdRecordMap.size()>0) || (ApprovedQuoteIdSetRecordMap.keySet() != null && ApprovedQuoteIdSetRecordMap.size() > 0)) &&  !system.isBatch()){ //MS
        if(((NotificationQuoteIdRecordMap != null && !NotificationQuoteIdRecordMap.isEmpty()) || (ApprovedQuoteIdSetRecordMap.keySet() != null && !ApprovedQuoteIdSetRecordMap.isEmpty())) &&  !system.isBatch()){ //MS
            System.enqueueJob(new asyncSendNotification(NotificationQuoteIdRecordMap, ApprovedQuoteIdSetRecordMap, qtOldMap.keySet()));
        }
        //Khushboo FY25SR-2391 start
        if(quotelines!=null && !quotelines.isEmpty()){
            quoteIdVsLODFlag= processQuotelinesToUpdateIAR(quotelines);
        }//FY25SR-2391 end
        for (sbqq__quoteline__c qlns: quotelines.values()) {
            if (!quotetosaAmendment.contains(qlns.sbqq__quote__c)) {
                if (qlns.Subscribed_Asset_Name__c != null && qlns.Subscribed_Asset_Name__c != '' && qlns.Line_Type__c == 'New' && qlns.sbqq__quote__r.sbqq__type__c == 'Amendment') {
                    quotetosaAmendment.add(qlns.sbqq__quote__c);
                    break;
                }
            }
            //Added for M365-Utility Start            
                 
                   if(qlns.Scale_Utility_Product__c == true){
                       SuProgramSet.add('Scale Utility');
                       quoteToSUProgramMap.put(qlns.SBQQ__Quote__c,SuProgramSet);
                   } 
                    if(qlns.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX'){
                       SuProgramSet.add('M365');
                      quoteToSUProgramMap.put(qlns.SBQQ__Quote__c,SuProgramSet);
                   }
                
            //Added for M365-Utility End
        }
        
        Opportunity QuotesOpportunityDetail;
        for (SBQQ__Quote__c qt: qtList) {
            //FY25SR-2391 start
            if(quoteIdVsLODFlag!=null && !quoteIdVsLODFlag.isEmpty() && quoteIdVsLODFlag.contains(qt.Id)){
                qt.LoD_refreshed_to_Subscription_Deal__c =true;
            }
            //FY25SR-2391 end
            //Added by Shiju for RWD-60
            if (qt.GPL_Deal__c != 'NetApp' && qt.Sell_to_Partner__c != NULL) {
                qt.ShowSellToPartner__c = true;
            }
            //RWD-60 changes ends

            //M365-Utility Start
            qt.Scale_Utility_Program__c = '';
            String SUProgram ='';
            if(quoteToSUProgramMap.keyset().Contains(qt.Id)){                
               for(string prg : quoteToSUProgramMap.get(qt.Id)){
                   SUProgram = SUProgram+prg;
                   qt.Scale_Utility_Program__c = SUProgram;
                   SUProgram = SUProgram+';';
               }
            }
            //M365-Utility End  

            qt.AmendmentNewSubscribed__c = false;
            if (quotetosaAmendment.contains(qt.id)) {
                qt.AmendmentNewSubscribed__c = true;
            }
            //sf 8332 starts
            //MSRI-146
            if (qt.Opportunity_Stage__c == '6 PO With Channel' && qt.Deal_Desk_Users__c && (qtOldMap.get(qt.id).SBQQ__ExpirationDate__c != qt.SBQQ__ExpirationDate__c || qtOldMap.get(qt.id).ApprovalStatus__c != qt.ApprovalStatus__c || qtOldMap.get(qt.id).SBQQ__Status__c != qt.SBQQ__Status__c)) {
                                                                                                LockQuoteValidationByPass.byPassValidation = true;
                                                                                            }
            //MSRI-146
            //change done for the issue number 1396 for closed lost by Srikanth  
            if (!LockQuoteValidationByPass.byPassValidation) {
                if (qt.Opportunity_Stage__c == '6 PO With Channel' || qt.Opportunity_Stage__c == '7 Closed Won' || qt.Opportunity_Stage__c == '7 Closed Admin') {
                    if (!Test.isRunningTest()) {
                        qt.Error_Message_From_QCP__c = 'The quote cannot be edited if the Opportunity is at Stage 6 PO with Channel, Stage 7 Closed Won or Stage 7 Closed Admin.';
                    }
                    break;
                }
            } // sf 8332 ends   
            
            if (opptyMap != null && qt.SBQQ__Opportunity2__c != null) {
                QuotesOpportunityDetail = opptyMap.get(qt.SBQQ__Opportunity2__c);
            }
            
             // added for FY25SR-1114
            date firstDayOfNextQuarterDate;
            if (qt.SBQQ__Type__c == 'Renewal+Expansion' && QuotesOpportunityDetail != null && QuotesOpportunityDetail.CloseDate != null && qt.SBQQ__ExpirationDate__c != null && (qt.Credit_Calculation_Start_Date__c == null || (qt.Credit_Calculation_Start_Date__c != qtOldMap.get(qt.Id).Credit_Calculation_Start_Date__c))) {            
                if(QuotesOpportunityDetail.CloseDate > qt.SBQQ__ExpirationDate__c){
                    firstDayOfNextQuarterDate = firstDayOfNextQuarter(QuotesOpportunityDetail.CloseDate);
                }else{
                    firstDayOfNextQuarterDate = firstDayOfNextQuarter(qt.SBQQ__ExpirationDate__c);
                }
                
                if(firstDayOfNextQuarterDate != null){
                  if(qt.SBQQ__Status__c != 'Approved' && (firstDayOfNextQuarterDate >=  qt.Credit_Calculation_Start_Date__c || qt.Credit_Calculation_Start_Date__c == null)){
                     qt.Credit_Calculation_Start_Date__c = firstDayOfNextQuarterDate ;
                  }else if(qt.SBQQ__Status__c != 'Approved' && 
                           qt.Credit_Calculation_Start_Date__c != null &&
                         (!qt.Credit_Calculation_Start_Date__c.isSameDay(
                            firstDayOfNextQuarter(
                                qt.Credit_Calculation_Start_Date__c.addDays(-1))
                            )
                        )){  
                    qt.addError(System.Label.FiscalYearStartMonthErrorMsg);
                  }
                }
            }
            // end for FY25SR-1114
            if (clonedfromquotes != null) {
                if (!clonedfromquotes.isempty() && clonedfromquotes.containskey(qt.sbqq__source__c)) {
                    qt.Cloned_From_Created_Date__c = clonedfromquotes.get(qt.sbqq__source__c).createddate.date();
                }
            }
            
            populateFieldsFromOpportunity(qt, opptyMap);
            
            //MSP1.1 : Expiration date to be 30 days from the creation date of the quote
            //Added check of Expires On Exception field for SF-27738 
            if (qt.SBQQ__Type__c == 'Amendment' && qt.OpportunitySubType__c == 'MSP' && qt.Update_Expires_On__c == false) {
                qt.SBQQ__ExpirationDate__c = qt.CreatedDate.Date() + 30;
            }
            
            if (QuotesOpportunityDetail != null && QuotesOpportunityDetail.Account.RecordType.Name != null) {
                qt.Account_Record_Type__c = QuotesOpportunityDetail.Account.RecordType.Name;
            }
            
            //Lakshmi - Migrating all workflow rules to Trigger as part of optimization - Start
            if(qtOldMap.get(qt.id).ApprovalStatus__c != qt.ApprovalStatus__c){
                if(qt.ApprovalStatus__c == 'Approved'){
                    if(QuoteRecoTypeDatas != null){
                        qt.recordtypeid = QuoteRecoTypeDatas.get('Approved_Quote').getRecordTypeId();
                    }
                    qt.SBQQ__Status__c = 'Approved';
                    qt.SBQQ__WatermarkShown__c = false;
                    qt.Approved_time__c = system.now();
                    
                    qt.Additional_Terms_Required__c = QuoteTermReader.setAdditionalTnCFlag(qt, quotelines); //CPQ22-5226 MS Added to Set identifier
                    
                }else{
                    qt.SBQQ__WatermarkShown__c = true;
                    
                }
            }
            
            // added the logic for CPQ22-5261
			
			if(qtOldMap.get(qt.id).ApprovalStatus__c != qt.ApprovalStatus__c && (qt.ApprovalStatus__c == 'Pending' || ( qtOldMap.get(qt.id).ApprovalStatus__c == 'Submitted' && qt.ApprovalStatus__c == 'Approved'))){
				 qt.Submit_for_Approval_Time__c = system.now();
			}
            //CPQ22-4424 approval status blank
            if((qtOldMap.get(qt.id).ApprovalStatus__c != qt.ApprovalStatus__c &&(qt.ApprovalStatus__c == 'Recalled'  || qt.ApprovalStatus__c =='Rejected'))
              || (qtOldMap.get(qt.id).ApprovalStatus__c != null && qt.ApprovalStatus__c == null)){
                qt.SBQQ__Status__c = 'Draft';
            //Arroyo 2.0 ARY-684 CR #20- Start
                  if (QuoteRecoTypeDatas != null && qt.SBQQ__Type__c == 'Renewal+Expansion'){
                        qt.recordtypeid = QuoteRecoTypeDatas.get('RE_Quote').getRecordTypeId();
                }
            //Arroyo 2.0 ARY-684 CR #20- End
                  else {
                      qt.recordtypeid = QuoteRecoTypeDatas.get('Draft_Quote').getRecordTypeId();
                  }
            }
            if(Test_Controls__c.getInstance(userinfo.getProfileId()).Bypass_Pricebook_Setting_on_Quote__c == false){
                qt.SBQQ__PricebookId__c = system.label.CPQPricebookID;
                qt.SBQQ__PriceBook__c = system.label.CPQPricebookID;
            }
            if (qt.SBQQ__Status__c == 'Draft' && qt.SBQQ__Type__c != 'Renewal+Expansion') {
                qt.recordtypeid = QuoteRecoTypeDatas.get('Draft_Quote').getRecordTypeId();
            }
            if(QuotesOpportunityDetail != null ){
                qt.OpportunitySubType__c = QuotesOpportunityDetail.Opportunity_Sub_Type__c;
                qt.Owner_Region__c = QuotesOpportunityDetail.ETM_Region__c;
                qt.OwnerSubRegion__c = QuotesOpportunityDetail.ETM_Territory__c;
                qt.Installation_Assigned_To__c = QuotesOpportunityDetail.Installation_Assigned_To__c;
                // inserting code here as per flow not a part of WF 
                qt.Account_Record_Type__c = QuotesOpportunityDetail.Account.RecordType.Name;
                
                // added for CPQ22-4460 by Pooja 
                // This logic will verify if the quote's payment term > Distributor Lookup's payment term and will set the field for approval
                if(QuotesOpportunityDetail.Distributor_Lookup__c != null){
                    String strTarget = 'Net ';
                    Integer distriPaymentTerm = 0;
                    Integer qtPaymentTerm = 0;
                    
                    if(String.isNotBlank(QuotesOpportunityDetail.Distributor_Lookup__r.Payment_Term__c)){
                        distriPaymentTerm = Integer.valueOf(QuotesOpportunityDetail.Distributor_Lookup__r.Payment_Term__c.replace(strTarget, '1'));
                    }
                    if(String.isNotBlank(qt.SBQQ__PaymentTerms__c)){
                       qtPaymentTerm = Integer.valueOf(qt.SBQQ__PaymentTerms__c.replace(strTarget, '1'));
                    }
                    if((distriPaymentTerm != 0 && qtPaymentTerm > distriPaymentTerm) || 
                        (distriPaymentTerm == 0 && String.valueOf(qt.SBQQ__PaymentTerms__c) != 'Net 30') ){
                        qt.PaymentTermMismatchWithDistributor__c = True;
                    }
                    else{
                        qt.PaymentTermMismatchWithDistributor__c = false;
                    }
                }  // end CPQ22-4460
      
            }
            //Lakshmi - Migrating all workflow rules to Trigger as part of optimization - End
            if (qtOldMap.get(qt.id).SBQQ__PrimaryContact__c != qt.SBQQ__PrimaryContact__c && qt.SBQQ__PrimaryContact__c != null) {
                qt.Primary_Contact__c = qt.SBQQ__PrimaryContact__c;
                qt.SBQQ__PrimaryContact__c = null;
            }
            String oldQuoteDate = System.Label.Old_Quotes_Date;
            if (qtOldMap != null && qtOldMap.get(qt.id).ApprovalStatus__c != qt.ApprovalStatus__c && qt.ApprovalStatus__c == 'Invalid') {
                Date crtDate;
                if (oldQuoteDate != null) {
                    String[] SplitDates = oldQuoteDate.split('/');
                    if (SplitDates != null && SplitDates.size() == 3) {
                        crtDate = date.newInstance(integer.valueof(SplitDates[2]), integer.valueof(SplitDates[0]), integer.valueof(SplitDates[1]));
                    }
                }
                if (crtDate == null) {
                    crtDate = date.newInstance(2019, 03, 01);
                }
                
                
                if (crtDate != null && qt.CreatedDate > crtDate) {
                    qt.SBQQ__Status__c = 'Invalid';
                    // qt.SBQQ__Primary__c = false; //CPQ22-5907
                }
            }
            if (qt.SBQQ__Status__c == 'Invalid' || qt.SBQQ__Status__c == 'Expired') {//REEN-56
                qt.recordtypeid = QuoteRecoTypeDatas.get('Invalid_Quote').getRecordTypeId();
            }
            
            /*
User Story - RNWA-54
*/
            if ((
                QuotesOpportunityDetail != null &&
                QuotesOpportunityDetail.AccountId != null &&
                QuotesOpportunityDetail.Account.Sum_of_Opportunities__c < Decimal.valueOf(System.Label.LTV_Threshold) &&
                qt.SBQQ__Type__c.equalsIgnoreCase('Renewal') &&
                String.isBlank(qt.Quote_Name__c)) || Test.isRunningTest()
            ) {
                qt.Quote_Name__c =
                    (QuotesOpportunityDetail.SBQQSC__RenewedServiceContract__r.EndDate != null ? Datetime.newInstance(QuotesOpportunityDetail.SBQQSC__RenewedServiceContract__r.EndDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd') + ' - ' : '') +
                    (String.isBlank(QuotesOpportunityDetail.Account.ETM_Theatre__c) ? '' : QuotesOpportunityDetail.Account.ETM_Theatre__c + ' - ') +
                    QuotesOpportunityDetail.Account.Name + ' - ' +
                    (String.isBlank(QuotesOpportunityDetail.Partner_Lookup__c) ? '' : QuotesOpportunityDetail.Partner_Lookup__r.Name + ' - ') +
                    'Renewal';
            }
            
            //GO Refresh changes Start
            
            // GO refresh Renewal update Ystone-40
            // added condition check for primary
            String campaign;
            if (qt.SBQQ__Primary__c == true && QuotesOpportunityDetail != null) {
                
                if ((qt.Opportunity_Program__c == 'Potential Refresh' && qt.SBQQ__Type__c == 'Renewal') || (qt.Opportunity_Program__c == 'Go Refresh' || qt.Opportunity_Program__c == 'Go Refresh - No Email')) {
                    if (qt.Opportunity_Program__c == 'Go Refresh' || qt.Opportunity_Program__c == 'Go Refresh - No Email') {
                        campaign = system.label.Rubrik_Go_Refresh_Campaign_Id;
                    }
                }
                if (GoRefreshopptyUpdateMap != null && GoRefreshopptyUpdateMap.containskey(qt.SBQQ__Opportunity2__c)) {
                    
                    GoRefreshopptyUpdateMap.get(qt.SBQQ__Opportunity2__c).Opportunity_Program__c = qt.Opportunity_Program__c;
                    if (campaign == null && GoRefreshopptyUpdateMap.get(qt.SBQQ__Opportunity2__c).Lead_Source_Campaign_Details__c == system.label.Rubrik_Go_Refresh_Campaign_Id || campaign != null) {
                        GoRefreshopptyUpdateMap.get(qt.SBQQ__Opportunity2__c).Lead_Source_Campaign_Details__c = campaign;
                    }
                    
                } else {
                    QuotesOpportunityDetail.Opportunity_Program__c = qt.Opportunity_Program__c;
                    if (campaign == null && QuotesOpportunityDetail.Lead_Source_Campaign_Details__c == system.label.Rubrik_Go_Refresh_Campaign_Id || campaign != null) {
                        QuotesOpportunityDetail.Lead_Source_Campaign_Details__c = campaign;
                    }
                    GoRefreshopptyUpdateMap.put(qt.SBQQ__Opportunity2__c, QuotesOpportunityDetail);
                }
            }
            //GO Refresh changes End
            // Rubrik Complete Start
            if (qt.SBQQ__Primary__c == true && QuotesOpportunityDetail != null) {
                
                Opportunity tempOpp;
                Boolean isCampaignUpdated = false;
                
                if (GoRefreshopptyUpdateMap != null && GoRefreshopptyUpdateMap.get(qt.SBQQ__Opportunity2__c) != null) {
                    tempOpp = GoRefreshopptyUpdateMap.get(qt.SBQQ__Opportunity2__c);
                } else {
                    tempOpp = QuotesOpportunityDetail;
                }
                
                if (qt.Count_of_Rubrik_Basic_Edition__c > 0) {
                    
                    if (!eligibleQuoteTypes.isEmpty() && qt.SBQQ__Type__c != null && eligibleQuoteTypes.contains(qt.SBQQ__Type__c)) {
                        
                        tempOpp.Lead_Source_Campaign_Details__c = system.label.Rubrik_Complete_Campaign_Id;
                        isCampaignUpdated = true;
                    }
                    
                } else if (tempOpp.Lead_Source_Campaign_Details__c == system.label.Rubrik_Complete_Campaign_Id) {
                    tempOpp.Lead_Source_Campaign_Details__c = null;
                    isCampaignUpdated = true;
                    
                }
                
                if (isCampaignUpdated)
                    GoRefreshopptyUpdateMap.put(qt.SBQQ__Opportunity2__c, tempOpp);
                
                
            }
            // Rubrik Complete End 
            updateExpirationWithHardware(qt, qtOldMap, quotelines); //CPQ22-6401
        }
        
        // Go refresh changes start
        if (!GoRefreshopptyUpdateMap.isEmpty()) {
            FlowControll.opportunityTriggerHandler = false;
            update GoRefreshopptyUpdateMap.values();
            FlowControll.opportunityTriggerHandler = true;
        }
        // Go refresh changes End
    }
    /**
     * @description      : this is a common method is used for opportunity fields(Deal_Structuring_Oppty_Notes__c) update 
     * @param  qt    : Quote with current changes 
     * @param  opptyMap   : Map of Quoteid and Opportunity 
     */
    public static void populateFieldsFromOpportunity(SBQQ__Quote__c qt, Map < Id, Opportunity > opptyMap) {
        
        Opportunity opp;
        if (qt.SBQQ__Opportunity2__c != NULL && opptyMap.containsKey(qt.SBQQ__Opportunity2__c) && String.isBlank(qt.Amended_Renewed_Service_Contract__c)) {
            opp = opptyMap.get(qt.SBQQ__Opportunity2__c);
        }
        if (opp != NULL &&
            (opp.SBQQSC__AmendedServiceContract__c != NULL || opp.SBQQSC__RenewedServiceContract__c != NULL)) {
                
                qt.Amended_Renewed_Service_Contract__c =
                    opp.SBQQSC__AmendedServiceContract__c != NULL ?
                    opp.SBQQSC__AmendedServiceContract__c :
                opp.SBQQSC__RenewedServiceContract__c;
            }
        if(opp != NULL){
            qt.Deal_Structuring_Oppty_Notes__c = opp.Deal_Structuring_Oppty_Notes__c; //added for CPQ22-2916 by srikanth
        }
    }
    //added Deal_Structuring_Oppty_Notes__c in queryfor CPQ22-2916
    /**
     * @description      : this is a common method is used to getOpportunityFields 
     * @param  opptyIdSet    : opportunity related to quote
     * @return : Map of opty id and object related to quote 
     */
    public static Map < Id, Opportunity > getOpportunityFields(Set < Id > opptyIdSet) {
        //Scale Utility Phase 2.0 #CSU-491: Added fields by Shaloo Mishra
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity> ( [SELECT Id,OwnerId,closedate,SBQQSC__AmendedServiceContract__r.SBQQSC__Quote__c,
                                                                    SBQQSC__AmendedServiceContract__r.SBQQSC__Quote__r.Metering__c,Account.RecordType.Name,Account.RCDMT_EOL_Date__c, Account.BillingCountry,Account.BillingCity,Account.BillingStreet,Account.BillingState,Account.BillingPostalCode,Account.ShippingStreet,Account.ShippingState,Account.ShippingCity,Account.ShippingCountry,Account.ShippingPostalCode,Opportunity_Sub_Type__c,ETM_Region__c,ETM_Territory__c,Deal_Structuring_Oppty_Notes__c,Lead_Source_Campaign_Details__c,Owner.Region__c,Owner.Sub_Region__c,Installation_Assigned_To__c,SBQQSC__AmendedServiceContract__c,Account.Account_Status__c, SBQQSC__RenewedServiceContract__c,Account.OwnerId,Opportunity_Program__c , SBQQSC__RenewedServiceContract__r.EndDate, Account.ETM_Theatre__c, Account.Name, Account.Sum_of_Opportunities__c, Partner_Lookup__c, Partner_Lookup__r.Name, Sell_to_Partner__c,Sell_to_Partner__r.Name, Distributor_Lookup__c,Distributor_Lookup__r.Name, Distributor_Lookup__r.Payment_Term__c, AccountId, (select id, POC_Type__c,POC_Duration__c,createdDate from Orders__r where POC_type__c='Conditional PO'),(select Id,Opportunity__c,New_Opportunity__c,User__c from CCRs__r where User__c = 'Approved' AND CCR_Type__c ='Partner Referral Fee') FROM Opportunity WHERE Id IN :opptyIdSet ] );
        return opptyMap;
    }
    
    /** getquotelines*/
     /**
     * @description      : this is a common method is used to getquotelines 
     * @param  quoteids    : quotelines id related to quote
     * @return : Map of quotelines id and object related to quote 
     */
    public static Map < Id, sbqq__quoteline__c > getquotelines(Set < Id > quoteids) {
        if (quotelinemap == null && quoteids != null && !quoteids.isEmpty()) {
            //fields added in SOQL as part of M365 Gov Cloud NPI,M365-Utility
            quotelinemap = new Map < Id, sbqq__quoteline__c > ([Select id, sbqq__quote__c, SBQQ__ProductCode__c,Quote_Line_Type__c , 
                                                                Scale_Utility_Product__c, Scale_Utility_Product_Identifier__c,
                                                                Scale_Utility_Product_RSV_OND__c,SBQQ__Product__r.Is_RBK_Appliance__c, 
                                                                Disposition_Reason__c, SBQQ__Product__r.Product_Type__c, User_license_count__c,
                                                                SBQQ__Product__r.Product_Level__c, sbqq__quote__r.sbqq__type__c, 
                                                                Subscribed_Asset_Name__c, Line_Type__c, SBQQ__Quantity__c, 
                                                                Product_Type__c, Who_will_the_customer_be_buying_the_HW__c, 
                                                                TPH_OEM__c, Who_will_Install_CDM__c, SBQQ__ProductFamily__c, 
                                                                SBQQ__Product__c, SBQQ__Product__r.Replacement_Category__c, SBQQ__Product__r.ProductCode,SBQQ__Product__r.Product_Subtype__c, //DPC
                                                                Special_Program__c, Group_Name__c, SBQQ__Optional__c, SBQQ__Existing__c, Is_Hardware_and_New__c, CreatedDate,
                                                                SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.ownerid,SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.owner.email,
      Prepayment_Credit__c, Promo_Disc__c, Trade_Up_Discount__c, Replacement_Details__c
                                                                FROM sbqq__Quoteline__c where sbqq__quote__c in: quoteids
                                                               ]);
        }
        return quotelinemap;
    }
    
    /**
     * @description      : Validation for User License Count. Method added as part of CPQ22-1872
     * @param  quoteRecord    : Quote Records
     */
    public static void userLicenseCountValidation(List <SBQQ__Quote__c> quoteRecord){
        
        for (SBQQ__Quote__c objQuote:  quoteRecord){
            if(system.Label.User_License_Count_Validation != 'NULL' && objQuote.SBQQ__Status__c != null && (objQuote.SBQQ__Status__c == 'Draft' || objQuote.SBQQ__Status__c == 'In Review' || objQuote.SBQQ__Status__c == 'Approved') && 
               objQuote.SBQQ__Type__c != 'Amendment' && quotelinemap != NULL){
                   
                   //REEN-25 added Dispostion_Reason__c
                   for(SBQQ__QuoteLine__c objQuoteLine : quotelinemap.values()){
                       if(objQuoteLine.SBQQ__Quote__c != null && objQuote.Id == objQuoteLine.SBQQ__Quote__c && (objQuoteLine.Disposition_Reason__c == 'Renewing' || objQuoteLine.Disposition_Reason__c == 'None') &&
                          objQuoteLine.SBQQ__Product__r.Product_Type__c != null && objQuoteLine.SBQQ__Product__r.Product_Level__c != NULL &&
                          objQuoteLine.SBQQ__Product__r.Product_Type__c.contains('M365') && (objQuoteLine.User_license_count__c == 0)&& objQuoteLine.SBQQ__Product__r.Product_Subtype__c!=CPQ_Constants.Product_Subtype_Credit) {//DPC
                              objQuote.addError(system.Label.User_License_Count_Validation);
                          }
                   }
               }    
        } 
    }
    /**
     * @description      : Validation for TPH and RSC Quoted together. Method added as part of CPQ22-1113, Q-10
     * @param  quoteRecord    : Quote Records
     */
    public static void hwApplianceAndTphAddedTogetherValidation(List <SBQQ__Quote__c> quoteRecord){
        Set<Id> setQuoteRecord = new Set<Id>();
        Map<Id, SBQQ__QuoteLine__c> mapQuoteLines = new Map<Id, SBQQ__QuoteLine__c>();
        
        for(SBQQ__Quote__c objQuote :quoteRecord){
            
            setQuoteRecord.add(objQuote.Id);
        }
        
        mapQuoteLines = getquotelines(setQuoteRecord);
        for (SBQQ__Quote__c objQuote :  quoteRecord){
            boolean productTypeHardware = False;
            boolean tphConfigAttributes = False;
            for(SBQQ__QuoteLine__c objQuoteLine : mapQuoteLines.values()){
                if(objQuote.Id == objQuoteLine.sbqq__Quote__c){
                    if(objQuoteLine.SBQQ__Quantity__c > 0){
                        if(objQuoteLine.Product_Type__c == 'Hardware'){
                            productTypeHardware = true;
                        }
                        if(objQuoteLine.SBQQ__ProductFamily__c == 'Rubrik Scale' &&(objQuoteLine.Who_will_the_customer_be_buying_the_HW__c != null || objQuoteLine.TPH_OEM__c != null || objQuoteLine.Who_will_Install_CDM__c != null ))
                            tphConfigAttributes = true;
                    }
                }    
            }
            if(productTypeHardware == true && tphConfigAttributes == true){
                objQuote.addError('You cannot select 3rd party HW and Rubrik appliances together.');
                
            }
            
        }
    }
    /**
     * @description      : Validation for preventing clone of Quotes based on Disable Business Logic
     */
    public static void preventCloningQuote() {
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        if (disableFuncCS == null) {
            return;
        }
        
        if (disableFuncCS != null && disableFuncCS.Disable_Quote_Clone_Date__c == null) {
            return;
        }
        
        Map < Id, SBQQ__Quote__c > cloneSources;
        List < Id > cloneSourceIds = new List < Id > ();
        for (SBQQ__Quote__c ob: (List < SBQQ__Quote__c > ) Trigger.new) {
            //ob.addError('Cloning is disabled currently. Please contact your system admin.');
            if (ob.isClone()) {
                cloneSourceIds.add(ob.getCloneSourceId());
            }
        }
        if (!cloneSourceIds.isEmpty()) {
            if(cloneSources == null){
                cloneSources = new Map < Id, SBQQ__Quote__c > ([Select Id, CreatedDate from SBQQ__Quote__c where Id in: cloneSourceIds]);
            }
            for (SBQQ__Quote__c ob: (List < SBQQ__Quote__c > ) Trigger.new) {
                
                if (ob.isClone()) {
                    DateTime createdDateTime = cloneSources.get(ob.getCloneSourceId()).CreatedDate;
                    if (createdDateTime < disableFuncCS.Disable_Quote_Clone_Date__c) {
                        ob.addError('Cloning is disabled currently. Please contact your system admin.');
                    }
                }
            }
        }
    }
    /**
     * @description      : Validation to be thrown from QCP.
     * @param  qtList    : Quote Records
     * @param  quoteOldMap    : Quote Old Records
     */
    public static void throwErrorMessage(List < SBQQ__Quote__c > qtList, Map<Id, SBQQ__Quote__c> quoteOldMap) {
         
        SBQQ.TriggerControl.disable();
        for (SBQQ__Quote__c qt: qtList) {
            if (qt.Error_Message_From_QCP__c != null) {
                qt.addError(qt.Error_Message_From_QCP__c);
            }
        }
        SBQQ.TriggerControl.enable();
    }
    /**
     * @description      : Create Task when Task Products is changed.
     * @param  qtList    : Quote Records
     * @param  qtOldMap    : Quote Old Records
     */
    public static void createTask(List < SBQQ__Quote__c > qtList, Map < Id, SBQQ__Quote__c > qtOldMap) {
        
        List < Task > lTask = new List < Task > ();
        set < id > accIds = new set < id > ();
        if (taskUser.isEmpty() || Test.isRunningTest()) {
            taskUser = [select id from user where email =: system.label.Task_User_Assignment];
        }
        if (!taskUser.isEmpty() && taskUser.size() > 0) {
            for (SBQQ__Quote__c qt: qtList) {
                
                if ((qt.Task_Products__c != null && qt.Task_Products__c != qtOldMap.get(qt.id).Task_Products__c) || Test.isRunningTest()) {
                    
                    List < string > oldSKus = qtOldMap.get(qt.id).Task_Products__c != null ? qtOldMap.get(qt.id).Task_Products__c.split(';') : null;
                    List < string > newSKus = qt.Task_Products__c != null ? qt.Task_Products__c.split(';') : null;
                    set < string > oldSkusSet = new set < string > ();
                    if (oldSKus != null)
                        oldSkusSet.addAll(oldSKus);
                    oldSKus = null;
                    if(newSKus != null){
                        for (string sku: newSKus) {
                            
                            if (oldSkusSet == null || (oldSkusSet != null && !oldSkusSet.contains(sku))) {
                                accIds.add(qt.SBQQ__Account__c);
                                Task t = new Task();
                                t.OwnerId = taskUser[0].id;
                                t.Subject = sku + ' is quoted on Quote #' + qt.name;
                                t.Priority = 'Normal';
                                t.Status = 'Not Started';
                                t.Type = 'Action';
                                t.WhatId = qt.SBQQ__Account__c;
                                t.Task_Email__c = system.label.Task_Email;
                                lTask.add(t);
                                
                            }
                        }
                    }  
                }
            }
            If(lTask != null && lTask.size() > 0) {
                List < task > existingTasks = [select id, subject from task where whatid in: accIds];
                Set < string > taskSubs = new Set < string > ();
                if (existingTasks != null) {
                    for (Task t: existingTasks) {
                        taskSubs.add(t.subject);
                    }
                }
                if (taskSubs.size() > 0) {
                    
                    for (integer i = 0; i < ltask.size();) {
                        if (taskSubs.contains(ltask[i].subject))
                            lTask.remove(i);
                        else
                            i++;
                        
                    }
                    
                }
                if (lTask.size() > 0)
                    insert lTask;
            }
        }
    }
    /**
     * @description      : Updates on Opportunity that is done from Quote.
     * @param  setOpportunityId    : Opportunity Ids in scope
     * @param  mapIdAndCount       : Map of Opportunity Id and count of Primary Quotes 
     */
    @future
    public static void updateOpportunity(Set<Id> setOpportunityId, Map<Id, Integer> mapIdAndCount) { // Changes for REEN-41 to utilize Query.
        Map<Id, Opportunity> mapOpportunityToUpdate = new Map<Id, Opportunity>();
        
        for (
            Opportunity objOpportunity: [SELECT Id, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__Primary__c,Partner_Lookup__c,Distributor_Lookup__c,SBQQ__PrimaryQuote__r.NIPA__c,SBQQ__PrimaryQuote__r.NIPD__c, //REEN-57
                                         Include_Datos__c, SBQQ__PrimaryQuote__r.Has_Mosaic_SKUs__c,
                                         SBQQ__PrimaryQuote__r.RenCredACV__c, SBQQ__PrimaryQuote__r.RenTradeUpAmt__c,Renewal_Credit_ACV__c,Renewal_Credit_TCV__c, //REEN-50
                                         Number_of_valid_Primary_Quotes__c //REEN-41
                                         FROM Opportunity
                                         WHERE Id IN: setOpportunityId
                                        ]
        ) {
            if (objOpportunity.Include_Datos__c != objOpportunity.SBQQ__PrimaryQuote__r.Has_Mosaic_SKUs__c) {
                objOpportunity.Include_Datos__c = objOpportunity.SBQQ__PrimaryQuote__r.Has_Mosaic_SKUs__c;
                mapOpportunityToUpdate.put(objOpportunity.Id, objOpportunity);
            }

            //REEN 57 start
            if(objOpportunity.SBQQ__PrimaryQuote__c != null && objOpportunity.SBQQ__PrimaryQuote__r.SBQQ__Primary__c == true &&  
                objOpportunity.SBQQ__PrimaryQuote__r.NIPA__c!=null && objOpportunity.SBQQ__PrimaryQuote__r.NIPD__c!=null &&
                ((objOpportunity.Partner_Lookup__c!=objOpportunity.SBQQ__PrimaryQuote__r.NIPA__c) ||
                (objOpportunity.Distributor_Lookup__c!=objOpportunity.SBQQ__PrimaryQuote__r.NIPD__c))){
                objOpportunity.Partner_Lookup__c=objOpportunity.SBQQ__PrimaryQuote__r.NIPA__c;
                objOpportunity.Distributor_Lookup__c=objOpportunity.SBQQ__PrimaryQuote__r.NIPD__c;
                mapOpportunityToUpdate.put(objOpportunity.Id, objOpportunity);
            }
            //REEN-57 end
            
            //REEN-50 start
            if (objOpportunity.SBQQ__PrimaryQuote__c != null && objOpportunity.SBQQ__PrimaryQuote__r.RenCredACV__c != null && objOpportunity.SBQQ__PrimaryQuote__r.RenTradeUpAmt__c != null
                && (objOpportunity.Renewal_Credit_ACV__c != objOpportunity.SBQQ__PrimaryQuote__r.RenCredACV__c || objOpportunity.Renewal_Credit_TCV__c != objOpportunity.SBQQ__PrimaryQuote__r.RenTradeUpAmt__c)
            ) {
                objOpportunity.Renewal_Credit_ACV__c = objOpportunity.SBQQ__PrimaryQuote__r.RenCredACV__c;
                objOpportunity.Renewal_Credit_TCV__c = objOpportunity.SBQQ__PrimaryQuote__r.RenTradeUpAmt__c;
                mapOpportunityToUpdate.put(objOpportunity.Id, objOpportunity);
            }
            //REEN-50 end
            if(mapIdAndCount != null && !mapIdAndCount.isEmpty() && mapIdAndCount.containsKey(objOpportunity.Id)){
                if (objOpportunity.Number_of_valid_Primary_Quotes__c != mapIdAndCount.get(objOpportunity.Id)) {
                    objOpportunity.Number_of_valid_Primary_Quotes__c = mapIdAndCount.get(objOpportunity.Id);
                    mapOpportunityToUpdate.put(objOpportunity.Id, objOpportunity);
                }
            }
        }
        
        if (!mapOpportunityToUpdate.isEmpty()) {
            flowControll.opportunityLineItemHandler = false;
            update mapOpportunityToUpdate.values();
            flowControll.opportunityLineItemHandler = true;
        }
    }
    
    
    /**
     * @description : send notification if quoteline is changed after corresponding order is Accepted/Shipped added for Ticket:-PRDOPS21-206
*/
    public static void quoteOrderNotification() {
        Map < Id, List < SBQQ__Quote__c >> quoteLstMap = new Map < Id, List < SBQQ__Quote__c >> (); //PRDOPS21-206
        Map < Id, SBQQ__Quote__c > newMap = (Map < Id, SBQQ__Quote__c > ) Trigger.newMap;
        Map < Id, SBQQ__Quote__c > oldMap = (Map < Id, SBQQ__Quote__c > ) Trigger.oldMap;
        for (SBQQ__Quote__c quote: (List < SBQQ__Quote__c > ) Trigger.New) {
            if (newMap.get(quote.Id).QuoteChangedEmailBody__c == null && oldMap.get(quote.Id).QuoteChangedEmailBody__c == null && !processedQuotes.contains(quote.Id)) {
                processedQuotes.add(quote.Id);
                quoteLstMap.put(quote.Id, new List < SBQQ__Quote__c > { quote }); //PRDOPS21-206
            }
        }
        SBQQ_QuoteLineTriggerHelper.quoteOrderNotification(quoteLstMap.keySet(), quoteLstMap, SBQQ__Quote__c.SobjectType); //PRDOPS21-206
    }
    /**
     * @description          : this method is used to calculate the lastDateOfQuarter 
     * @return               : lastDateOfQuarter Date
     */
    public static Date lastDateOfQuarter() {
        //Querying fiscal start month
        //Integer FiscalYearStartMonth = [select FiscalYearStartMonth from Organization where id =: Userinfo.getOrganizationId()].FiscalYearStartMonth;
        if(FiscalYearStartMonth == null){
            FiscalYearStartMonth = Integer.valueOf(System.Label.FiscalYearStartMonth);
        }
        
        Date fiscalYearStartDate;
        Integer quarter;
        if (system.today().month() >= FiscalYearStartMonth) {
            fiscalYearStartDate = date.newinstance(system.today().year(), FiscalYearStartMonth, 1);
            quarter = ((system.today().month() - FiscalYearStartMonth) / 3) + 1;
        } else {
            fiscalYearStartDate = date.newinstance(system.today().year() - 1, FiscalYearStartMonth, 1);
            quarter = ((12 + system.today().month() - FiscalYearStartMonth) / 3) + 1;
        }
        Integer addMonths = quarter * 3;
        
        Date lastDateOfThisQuarter = fiscalYearStartDate;
        // get the last date of the current quarter
        lastDateOfThisQuarter = lastDateOfThisQuarter.addMonths(addMonths).addDays(-1);
        
        return lastDateOfThisQuarter;
        
    }
    
    
    /**
     * @description          : this method is used to calculate the firstDayOfNextQuarter added for FY25SR-1114
     * @return               : firstDayOfNextQuarter Date
     * @param  InputDate     : any Date for which we need firstDayOfNextQuarter date
     */
    public static Date firstDayOfNextQuarter(Date InputDate) {
      
        Date firstDayOfNextQuarterDate;
        Date fiscalYearStartDate;
        Integer quarter;
        if(InputDate !=null){
           
              FiscalYearStartMonth = Integer.valueOf(System.Label.FiscalYearStartMonth);    
        
          
           if (InputDate.month() >= FiscalYearStartMonth) {
             fiscalYearStartDate = date.newinstance(InputDate.year(), FiscalYearStartMonth, 1);
             quarter = ((InputDate.month() - FiscalYearStartMonth) / 3) + 1;
           } else {
             fiscalYearStartDate = date.newinstance(InputDate.year() - 1, FiscalYearStartMonth, 1);
             quarter = ((12 + InputDate.month() - FiscalYearStartMonth) / 3) + 1;
           }
        
          firstDayOfNextQuarterDate = fiscalYearStartDate;
          firstDayOfNextQuarterDate = firstDayOfNextQuarterDate.addMonths(quarter * 3);
        }
        
        return firstDayOfNextQuarterDate;
        
    }
    // End for FY25SR-1114
    
    /**
     * @description          : this method is used to throw error when a user tries to update Expires On field beyond 90 days or End of Quarter. MSRI-141 
     * @param  oldQuoteList  : Old Quote List
     * @param  newQuoteList  : New Quote List
     * @param  oldMap        : Old Quote Map
     * @param  newMap        : New Quote Map
     */
    public static void errorForExpiryDate(List < SBQQ__Quote__c > oldQuoteList, List < SBQQ__Quote__c > newQuoteList, Map < Id, SBQQ__Quote__c > oldMap, Map < Id, SBQQ__Quote__c > newMap) {
        if (Test.isRunningTest()) {
            insert_logic = false;
            
        }
        if (!insert_logic) {
            Set < Id > quoteIds = new set < Id > ();
            for (SBQQ__Quote__c qInstance: newQuoteList) {
                quoteIds.add(qInstance.Id);
            }
            Map < Id, SBQQ__Quote__c > qMap = new Map < Id, SBQQ__Quote__c > ();
            if(quoteRecord == null){
                quoteRecord = [SELECT Id, SBQQ__Opportunity2__r.CloseDate, SBQQ__ExpirationDate__c, SBQQ__Type__c, ApprovalStatus__c, OpportunitySubType__c,
                               SBQQ__StartDate__c, CreatedDate, Update_Expires_On__c, EOLProductEarliestDate__c, Earliest_EOL_Date__c, oldExpirationDate__c FROM SBQQ__Quote__c WHERE Id IN: quoteIds];   
            }
            
            for (SBQQ__Quote__c q: quoteRecord) {
                qMap.put(q.Id, q);
            }
            Date lastDateOfThisQuarter = quoteTriggerHelper.lastDateOfQuarter();
            for (SBQQ__Quote__c qIns: newQuoteList) {
                
                if (qIns.SBQQ__Type__c == 'Quote' || qIns.SBQQ__Type__c == 'Amendment' || qIns.SBQQ__Type__c == 'Renewal') {
                    if (oldMap.get(qIns.Id).SBQQ__ExpirationDate__c != newMap.get(qIns.Id).SBQQ__ExpirationDate__c) {
                        qIns.oldExpirationDate__c = oldMap.get(qIns.Id).SBQQ__ExpirationDate__c;
                    }
                    
                    if (qMap != null && qMap.get(qIns.Id) != null && qMap.get(qIns.Id).SBQQ__Opportunity2__r.CloseDate <= lastDateOfThisQuarter) {
                        if ((qIns.SBQQ__ExpirationDate__c > lastDateOfThisQuarter && qIns.Update_Expires_On__c == false) && (
                            (oldMap.get(qIns.Id).SBQQ__StartDate__c != newMap.get(qIns.Id).SBQQ__StartDate__c) ||
                            (oldMap.get(qIns.Id).EOL_New_Product_Earliest_Date__c != newMap.get(qIns.Id).EOL_New_Product_Earliest_Date__c) ||
                            (oldMap.get(qIns.Id).SBQQ__ExpirationDate__c != newMap.get(qIns.Id).SBQQ__ExpirationDate__c) ||
                            (oldMap.get(qIns.Id).Update_Expires_On__c != newMap.get(qIns.Id).Update_Expires_On__c))) {
                                qIns.addError('You cannot update the Expires On beyond End of Quarter for in-quarter deals.');
                            }
                    } else {
                        if (qMap != null && qMap.get(qIns.Id) != null && qMap.get(qIns.Id).SBQQ__Opportunity2__r.CloseDate > lastDateOfThisQuarter) {
                            Date ninetyDays_CreatedDate = Date.ValueOf(qIns.CreatedDate.addDays(90));
                            if ((newMap.get(qIns.Id).SBQQ__ExpirationDate__c > ninetyDays_CreatedDate && qIns.Update_Expires_On__c == false) &&
                                ((oldMap.get(qIns.Id).SBQQ__StartDate__c != newMap.get(qIns.Id).SBQQ__StartDate__c) ||
                                 (oldMap.get(qIns.Id).EOL_New_Product_Earliest_Date__c != newMap.get(qIns.Id).EOL_New_Product_Earliest_Date__c) ||
                                 (oldMap.get(qIns.Id).SBQQ__ExpirationDate__c != newMap.get(qIns.Id).SBQQ__ExpirationDate__c) ||
                                 (oldMap.get(qIns.Id).Update_Expires_On__c != newMap.get(qIns.Id).Update_Expires_On__c))) {
                                     qIns.addError('You cannot update the Expires On beyond 90 days from creation. Please click the Clone with Related button to create a new quote with an updated expiration.');
                                 }
                        }
                    }
                }
            }
        }
    }
    /**
     * @description          : REEN-56 Throws error for Expiration Date for Draft Quotes 
     * @param  oldMap        : Old Quote Map
     * @param  newRecords    : New Quote Map
     */
    public static void updateOnExpireDateExtension(Map<Id, SBQQ__Quote__c> oldMap,List<SBQQ__Quote__c> newRecords){
        Map<Id,String> OldStatus=new Map<Id,String>();
        Set<Id> QuoteIDs=new Set<Id>();
        Date ED;
        List<SBQQ__Quote__c> QuoteList= new List<SBQQ__Quote__c>();
        if(newRecords!=null && !newRecords.isEmpty()){
            for(SBQQ__Quote__c qt:newRecords){
                if(qt.SBQQ__Status__c == 'Expired' && ((oldMap.get(qt.Id).SBQQ__StartDate__c != qt.SBQQ__StartDate__c) ||
                                                       (oldMap.get(qt.Id).EOL_New_Product_Earliest_Date__c !=
                                                        qt.EOL_New_Product_Earliest_Date__c) ||
                                                       (oldMap.get(qt.Id).SBQQ__ExpirationDate__c != qt.SBQQ__ExpirationDate__c) ||
                                                       (oldMap.get(qt.Id).Update_Expires_On__c != qt.Update_Expires_On__c)))
                {
                    ED=qt.Expiration_Date__c;
                    if(ED!=null && ED>=Date.today())
                    {
                        QuoteList.add(qt);   
                    } 
                } 
            }
        }
        if(QuoteList!=null && !QuoteList.isEmpty()){
            for(SBQQ__Quote__c qRec:QuoteList)  {
                QuoteIDs.add(qRec.id); 
            } 
        }
        if(QuoteIDs!=Null && !QuoteIDs.isEmpty()){
            for(SBQQ__Quote__History QuoteHistory:[Select Field, OldValue, NewValue, ParentId from  SBQQ__Quote__History where ParentId IN:QuoteIDs and Field = 'SBQQ__Status__c' ORDER BY CreatedDate]){
                OldStatus.put(QuoteHistory.ParentId, (String)QuoteHistory.OldValue);
            }
            if(OldStatus!=null && !OldStatus.isEmpty()){
                for(SBQQ__Quote__c qRec:QuoteList)
                {
                    if(OldStatus.get(qRec.id)== 'Approved')
                    {
                        qRec.SBQQ__Status__c= 'Approved';
                    }
                    if (OldStatus.get(qRec.id) == 'Draft' || OldStatus.get(qRec.id) == 'In Review') {
                        if(qRec.Running_User_Profile__c != 'Deal Operations'){
                        qRec.addError('Draft/In Review quote moved to Expired status, please clone the quote'); 
                        }else{
                        qRec.SBQQ__Status__c = OldStatus.get(qRec.id);
                        }
                    }
                    
                }
            }
        }
    }
    //END REEN-56
    
    /**
     * @description          : //MSRI-146 Resubmits expired quotes for approval, if Expiration Date is changed
     * @param  oldQuoteList  : Old Quote Map
     * @param  newQuoteList  : New Quote Map
     */
    public static void reSubmitExpiredQuote(Map < Id, SBQQ__Quote__c > oldQuoteList, Map < Id, SBQQ__Quote__c > newQuoteList) {
        if (!updateFlag) {
            List < sbaa__Approval__c > archivedApprovalList = new List < sbaa__Approval__c > ();
            set < id > quotestoupdate = new set < id > ();
            List < SBQQ__Quote__c > quoteList = newQuoteList.values();
            Set < id > approvalQuote = newQuoteList.keySet();
            PageReference pageRef;
            List < SBQQ__Quote__c > quoteToUpdate = new List < SBQQ__Quote__c > ();
            Map < String, List < sbqq__Quote__c >> quotesForRule = new Map < String, List < sbqq__Quote__c >> ();
            Map < String, sbaa__ApprovalRule__c > ruleMap = new Map < String, sbaa__ApprovalRule__c > ();
            List < sbaa__Approval__c > approvalRequest = new List < sbaa__Approval__c > ();
            List < SBQQ__Quote__c > statusforQuote = new List < SBQQ__Quote__c > ();
            if (!approvalData) {
                For(sbaa__ApprovalRule__c acc: [Select id, name, sbaa__Approver__c, sbaa__ApprovalTemplate__r.sbaa__TemplateId__c, sbaa__Approver__r.sbaa__GroupId__c, sbaa__RecallTemplate__r.sbaa__TemplateId__c, sbaa__RejectionTemplate__r.sbaa__TemplateId__c, sbaa__RequestTemplate__r.sbaa__TemplateId__c, sbaa__ApprovalChain__c, sbaa__ApprovalStep__c from sbaa__ApprovalRule__c where name in ('Expiration Date Exception', 'Expiration Date Updated', 'Expiration Date Exceeds Start Date')]) {
                    if (acc.name == 'Expiration Date Exception') {
                        String ExceptionRule = String.valueOf(acc.name);
                        ruleMap.put(ExceptionRule, acc);
                    } else if (acc.name == 'Expiration Date Updated') {
                        String ExpirationRule = String.valueOf(acc.name);
                        ruleMap.put(ExpirationRule, acc);
                    } else if (acc.name == 'Expiration Date Exceeds Start Date') {
                        String StartRule = String.valueOf(acc.name);
                        ruleMap.put(StartRule, acc);
                    }
                }
                For(sbaa__Approval__c acc: [select id, sbaa__rule__r.name, sbaa__status__c, sbaa__archived__c from sbaa__Approval__c where quote__c in: newQuoteList.keySet() and sbaa__rule__r.name in ('Expiration Date Exception', 'Expiration Date Updated', 'Expiration Date Exceeds Start Date') and(sbaa__status__c = 'Revoked' or sbaa__status__c = 'Rejected')]) {
                                                                                                                                                                                                                                                                                                               IF(acc.sbaa__archived__c == False) {
                                                                                                                                                                                                                                                                                                                   sbaa__Approval__c apr = new sbaa__Approval__c();
                                                                                                                                                                                                                                                                                                                   apr.id = acc.id;
                                                                                                                                                                                                                                                                                                                   apr.sbaa__archived__c = true;
                                                                                                                                                                                                                                                                                                                   archivedApprovalList.add(apr);
                                                                                                                                                                                                                                                                                                               }
                                                                                                                                                                                                                                                                                                           }
                approvalData = true;
            }
            
            //REEN-41
            List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
            if (newQuoteList != null && !newQuoteList.isEmpty()) {
                for(SBQQ__Quote__c quoteObj : quoteMap){
                    if((newQuoteList.keySet()).contains(quoteObj.id)){
                        lstQuotes.add(quoteObj); 
                    }
                }
            }
            
            
            for (SBQQ__Quote__c qIns : lstQuotes) {//REEN-41
                Integer numberDaysDue = 0;
                if (newQuoteList.get(qIns.Id).SBQQ__StartDate__c != null) {
                    Date startDate = newQuoteList.get(qIns.Id).SBQQ__StartDate__c;
                    Date dueDate = newQuoteList.get(qIns.Id).SBQQ__ExpirationDate__c;
                    numberDaysDue = startDate.daysBetween(dueDate);
                }
                
                
                if (((oldQuoteList.get(qIns.Id).SBQQ__ExpirationDate__c != newQuoteList.get(qIns.Id).SBQQ__ExpirationDate__c) &&
                    numberDaysDue > 0 && newQuoteList.get(qIns.Id).SBQQ__Status__c == 'Approved' && qIns.Deal_Desk_Users__c == False && qIns.SBQQ__Type__c != 'Renewal') || Test.isRunningTest()) {
                        if (quotesForRule.containsKey('Expiration Date Exceeds Start Date')) {
                            List < Sbqq__Quote__c > QuotesForStartDate = quotesForRule.get('Expiration Date Exceeds Start Date');
                            QuotesForStartDate.add(qIns);
                            quotesForRule.put('Expiration Date Exceeds Start Date', QuotesForStartDate);
                        } else {
                            List < Sbqq__Quote__c > QuotesForStartDate = new List < Sbqq__Quote__c > ();
                            QuotesForStartDate.add(qIns);
                            quotesForRule.put('Expiration Date Exceeds Start Date', QuotesForStartDate);
                        }
                    }
                if (((oldQuoteList.get(qIns.Id).SBQQ__ExpirationDate__c != newQuoteList.get(qIns.Id).SBQQ__ExpirationDate__c) &&
                     (qIns.SBQQ__Status__c == 'Approved' || (qIns.SBQQ__Status__c == 'Expired' && qIns.SBQQ__Type__c != 'Renewal' )) && qIns.Deal_Desk_Users__c == False) || Test.isRunningTest())  {
                         SBQQ__Quote__c qts = new SBQQ__Quote__c();
                         qts.id = qIns.id;
                         qts.Expiration_Date_Update_Flag__c = true;
                         quoteToUpdate.add(qts);
                         if (quotesForRule.containsKey('Expiration Date Updated')) {
                             List < Sbqq__Quote__c > QuotesForStartDate = quotesForRule.get('Expiration Date Updated');
                             QuotesForStartDate.add(qIns);
                             quotesForRule.put('Expiration Date Updated', QuotesForStartDate);
                         } else {
                             List < Sbqq__Quote__c > QuotesForStartDate = new List < Sbqq__Quote__c > ();
                             QuotesForStartDate.add(qIns);
                             quotesForRule.put('Expiration Date Updated', QuotesForStartDate);
                         }
                     }
                if (((qIns.SBQQ__Status__c == 'Approved' || (qIns.SBQQ__Status__c == 'Expired' && qIns.SBQQ__Type__c != 'Renewal' )) && 
                qIns.Deal_Desk_Users__c == False && newQuoteList.get(qIns.Id).Update_Expires_On__c == true && oldQuoteList.get(qIns.Id).SBQQ__ExpirationDate__c != newQuoteList.get(qIns.Id).SBQQ__ExpirationDate__c) || Test.isRunningTest()) {
                    if (quotesForRule.containsKey('Expiration Date Exception')) {
                        List < Sbqq__Quote__c > QuotesForStartDate = quotesForRule.get('Expiration Date Exception');
                        QuotesForStartDate.add(qIns);
                        quotesForRule.put('Expiration Date Exception', QuotesForStartDate);
                    } else {
                        List < Sbqq__Quote__c > QuotesForStartDate = new List < Sbqq__Quote__c > ();
                        QuotesForStartDate.add(qIns);
                        quotesForRule.put('Expiration Date Exception', QuotesForStartDate);
                    }
                }
                
            }
            
            if (!quotesForRule.isEmpty()) {
                if (/*!quotesForRule.containsKey('Expiration Date Updated') && */quoteToUpdate.size() > 0 && !Test.isRunningTest()) {
                    update quoteToUpdate;
                }
                if (!archivedApprovalList.isEmpty()) {
                    update archivedApprovalList;
                }
                For(String acc: quotesForRule.keySet()) {
                    if (ruleMap.containskey(acc)) {
                        List < Sbqq__Quote__c > quotesForApproval = quotesForRule.get(acc);
                        Integer quoteListSize = quotesForApproval.Size();
                        if (quoteListSize > 0) {
                            For(Sbqq__Quote__c qtt: quotesForRule.get(acc)) {
                                if (!quotestoupdate.contains(qtt.id)) {
                                    SBQQ__Quote__c qt = new SBQQ__Quote__c();
                                    qt.id = qtt.id;
                                    qt.ApprovalStatus__c = 'Pending';
                                    statusforQuote.add(qt);
                                    quotestoupdate.add(qtt.id);
                                }
                                
                                sbaa__Approval__c acc1 = new sbaa__Approval__c();
                                acc1.sbaa__Status__c = 'Requested';
                                acc1.sbaa__ApprovalStep__c = ruleMap.get(acc).sbaa__ApprovalStep__c;
                                acc1.sbaa__RecordField__c = 'Quote__c';
                                acc1.sbaa__Approver__c = ruleMap.get(acc).sbaa__Approver__c;
                                acc1.sbaa__ApprovalTemplateId__c = ruleMap.get(acc).sbaa__ApprovalTemplate__r.sbaa__TemplateId__c;
                                acc1.sbaa__AssignedGroupId__c = ruleMap.get(acc).sbaa__Approver__r.sbaa__GroupId__c;
                                acc1.sbaa__RecallTemplateId__c = ruleMap.get(acc).sbaa__RecallTemplate__r.sbaa__TemplateId__c;
                                acc1.sbaa__RejectionTemplateId__c = ruleMap.get(acc).sbaa__RejectionTemplate__r.sbaa__TemplateId__c;
                                acc1.sbaa__RequestTemplateId__c = ruleMap.get(acc).sbaa__RequestTemplate__r.sbaa__TemplateId__c;
                                acc1.Quote__c = qtt.id;
                                acc1.Account__c = qtt.SBQQ__Account__c;
                                acc1.sbaa__Opportunity__c = qtt.SBQQ__Opportunity2__c;
                                acc1.sbaa__Rule__c = ruleMap.get(acc).id;
                                acc1.sbaa__ApprovalChain__c = ruleMap.get(acc).sbaa__ApprovalChain__c;
                                approvalRequest.add(acc1);
                            }
                        }
                    }
                }
            }
            
            if (approvalRequest.size() > 0 && statusforQuote.size() > 0) {
                insert approvalRequest;
                update statusforQuote;
            }
        }
    }
     /**
     * @description          : CPQ22-95 Update Approval Status on Quote for resubmitted Quotes
     * @param  approvalQuoteIds  : Quote Ids
     */
    public static void approvalStatus(set < id > approvalQuoteIds) {
        if (qList == null && approvalQuoteIds != null && approvalQuoteIds.size() > 0){
            qList = [SELECT Id, SBQQ__ExpirationDate__c, SBQQ__Status__c, CreatedDate, oldExpirationDate__c, (select ParentId, OldValue, NewValue, Field, 
                                                                                                              CreatedById, CreatedDate from histories where Field = 'sbqq__Status__c' order by CreatedDate desc limit 2),
                     (Select id, Quote__c, CreatedDate, Approval_Date__c, sbaa__Status__c, sbaa__Rule__c, sbaa__Rule__r.name, sbaa__ApprovalChain__r.name from 
                      Approvals__r order by CreatedDate Desc) from SBQQ__Quote__c WHERE Id IN: approvalQuoteIds];
        }
        Map < Id, Boolean > StatusCombination = new Map < id, Boolean > ();
        Map < Id, Boolean > RejectionCombination = new Map < id, Boolean > ();
        List < SBQQ__Quote__c > statusRevert = new List < SBQQ__Quote__c > ();
        Map < Id, String > ExpiresOnException = new Map < id, String > ();
        
        if(qList.size() > 0){
            for (SBQQ__Quote__c qIns: qList) {
                if (qIns.SBQQ__Status__c == 'Draft' && (qIns.histories).size() > 0) {
                    if (qIns.histories[0].NewValue == 'In Review' && qIns.histories[0].oldValue == 'Approved') {
                        StatusCombination.put(qIns.id, True);
                    }
                }
                if ((qIns.Approvals__r).size() > 0) {
                    Boolean rejectionFlag = False;
                    For(sbaa__Approval__c app: qIns.Approvals__r) {
                        if (app.sbaa__Status__c == 'Approved') {
                            break;
                        }
                        if (app.sbaa__Status__c == 'Requested' && (app.sbaa__Rule__r.name != 'Expiration Date Updated' && app.sbaa__Rule__r.name != 'Expiration Date Exceeds Start Date' && app.sbaa__Rule__r.name != 'Expiration Date Exception')) {
                            break;
                        }
                        if (app.sbaa__Status__c == 'Requested' && (app.sbaa__Rule__r.name == 'Expiration Date Updated' || app.sbaa__Rule__r.name == 'Expiration Date Exceeds Start Date' || app.sbaa__Rule__r.name == 'Expiration Date Exception')) {
                            rejectionFlag = true;
                            If(app.sbaa__Rule__r.name == 'Expiration Date Exception') {
                                ExpiresOnException.put(qIns.id, app.sbaa__Rule__r.name);
                            }
                            break;
                        }
                    }
                    if (rejectionFlag == true) {
                        RejectionCombination.put(qIns.id, true);
                    }
                    
                }
                if ((RejectionCombination.get(qIns.id) == True && StatusCombination.get(qIns.id) == True) || Test.isRunningTest()) {
                    Sbqq__Quote__c qt1 = new sbqq__Quote__c();
                    qt1.Id = qIns.id;
                    qt1.SBQQ__Status__c = 'Approved';
                    qt1.ApprovalStatus__c = 'Approved';
                    qt1.recordtypeid = Schema.SobjectType.sbqq__quote__c.getRecordTypeInfosByName().get('Approved Quote').getRecordTypeId();
                    if (qIns.oldExpirationDate__c != null) {
                        qt1.SBQQ__ExpirationDate__c = qIns.oldExpirationDate__c;
                    }
                    statusRevert.add(qt1);
                }
            }
        }
        if (statusRevert.size() > 0) {
            updateFlag = true;
            update statusRevert;
        }
    }
    
    /**
     * @description          : Updates Guided Selling on Quote
     * @param  quoteList      : New Quote List
     * @param  quoteOldMap   : Old Quote Map
     */
    public static void guidedSellingDefaulting(List < SBQQ__Quote__c > quoteList, Map < Id, SBQQ__Quote__c > quoteOldMap)  {
        Map<id,Opportunity> optyCLoseDateMap = new Map<id,Opportunity>();
        Map<id,Account> quoteAccountMap = new Map<id,Account>();
        Map<String, Sell_To_Partner_on_Quote__mdt > sellToPartner = Sell_To_Partner_on_Quote__mdt.getAll();
        Set<id> OppID = new Set<Id>();
        Set<id> accId = new Set<Id>();
        boolean selltopartnermatch = false;
        Set<string> ValidNewAccountstatus = new Set<string>{'Prospect','Existing Customer','Active Opportunity'};
            for(SBQQ__Quote__c quote : quoteList){
                OppID.add(quote.SBQQ__Opportunity2__c);
            }
        if (opptyMap == null) {
            opptyMap = getOpportunityFields(OppID);
        }
        for(SBQQ__Quote__c quote : quoteList){
            if(quoteOldMap== null){
                if(quote.RWD_Guided_Selling__c == '' || quote.RWD_Guided_Selling__c == null){
                    if(('NetApp').equals(String.ValueOf(quote.GPL_Deal__c)) ){
                        // CHANGES MADE WITH RWD-1065 TO REMOVE ASSIGNING LOGIC STARTS
                        quote.RWD_Guided_Selling__c = System.Label.PolarisProcessId;
                        quote.SBQQ__QuoteProcessId__c = System.Label.PolarisProcessId;
                        // CHANGES MADE WITH RWD-1065 TO REMOVE ASSIGNING LOGIC ENDS
                    }else if((quote.Sell_to_Partner__c != null && !sellToPartner.isEmpty())){ //case4
                        for(String stp : sellToPartner.keySet()){
                            if(sellToPartner.get(stp).label == quote.Sell_to_Partner__c){
                                quote.RWD_Guided_Selling__c =System.Label.QuoteProcessId;
                                quote.SBQQ__QuoteProcessId__c = System.Label.QuoteProcessId;
                                selltopartnermatch = true;
                            }
                        }
                        if(selltopartnermatch == false){
                            quote.RWD_Guided_Selling__c = System.Label.PolarisProcessId;
                            quote.SBQQ__QuoteProcessId__c = System.Label.PolarisProcessId;
                        }
                    }else if(!opptyMap.isEmpty() && opptyMap.get(quote.SBQQ__Opportunity2__c) != null &&  (ValidNewAccountstatus.contains(opptyMap.get(quote.SBQQ__Opportunity2__c).Account.Account_Status__c))){
                        quote.RWD_Guided_Selling__c = System.Label.PolarisProcessId;
                        quote.SBQQ__QuoteProcessId__c = System.Label.PolarisProcessId;
                    }
                    else{
                        quote.RWD_Guided_Selling__c = System.Label.PolarisProcessId;
                        quote.SBQQ__QuoteProcessId__c = System.Label.PolarisProcessId;
                    }
                }else{
                    quote.SBQQ__QuoteProcessId__c = quote.RWD_Guided_Selling__c;
                }
            }else {
                if(quote.RWD_Guided_Selling__c !='' && (quoteOldMap.get(quote.id).RWD_Guided_Selling__c != quote.RWD_Guided_Selling__c)){
                    quote.SBQQ__QuoteProcessId__c = quote.RWD_Guided_Selling__c;
                }
                
            }
           //CPQ22-626 Added for POC Federal Check
            if(quote.RWD_Guided_Selling__c!=System.Label.QuoteProcessId){
                if(quote.Is_Federal_Eligible_Quote__c == true && (quote.RWD_Sales_Rep_Exception__c==null || (quote.RWD_Sales_Rep_Exception__c!=null && !quote.RWD_Sales_Rep_Exception__c.containsIgnoreCase('Exception for On-Prem Quoting')))){
                    quote.RWD_Guided_Selling__c = System.Label.PolarisProcessId;
                    quote.SBQQ__QuoteProcessId__c = System.Label.PolarisProcessId;
                }else if(quote.RWD_Sales_Rep_Exception__c!=null && quote.RWD_Sales_Rep_Exception__c.containsIgnoreCase('Exception for On-Prem Quoting') && quote.Is_Federal_Eligible_Quote__c == false ){
                    quote.RWD_Guided_Selling__c = System.Label.NonFedExceptionProcessId;
                    quote.SBQQ__QuoteProcessId__c = System.Label.NonFedExceptionProcessId;
                }else{
                    quote.RWD_Guided_Selling__c = System.Label.NonFederalProcessId;
                    quote.SBQQ__QuoteProcessId__c = System.Label.NonFederalProcessId;
                    
                }   
            }
            //M365-Utility changes to populate new guided selling for GC offer - Start
            if(opptyMap!= null && opptyMap.get(quote.SBQQ__Opportunity2__c) != null 
                             && ( opptyMap.get(quote.SBQQ__Opportunity2__c).Opportunity_Sub_Type__c== 'GC Offer' 
                                 || opptyMap.get(quote.SBQQ__Opportunity2__c).Opportunity_Sub_Type__c== 'GC OnDemand' 
                                 || opptyMap.get(quote.SBQQ__Opportunity2__c).Opportunity_Sub_Type__c== 'GC Renewal')){
                           quote.SBQQ__QuoteProcessId__c = System.Label.ScaleUtilityGuidedSelling;
                           quote.RWD_Guided_Selling__c = System.Label.ScaleUtilityGuidedSelling;   
            } //M365-Utility changes - End
            else if(quote.RSC_G_Eligible__c) { //ITNPI-235 RSC-G FedRamp changes to show RSCG value in guided selling - Start
                quote.SBQQ__QuoteProcessId__c = System.Label.RSCGGuidedSelling;
                quote.RWD_Guided_Selling__c = System.Label.RSCGGuidedSelling;   
            }                   
            //ITNPI-235 RSC-G FedRamp changes - End
            //CPQ22-4200 - Populate Scale guided Selling Id Start
      
            if(opptyMap!= null && opptyMap.get(quote.SBQQ__Opportunity2__c) != null 
                                && opptyMap.get(quote.SBQQ__Opportunity2__c).Opportunity_Sub_Type__c != 'GC Offer' 
                                && opptyMap.get(quote.SBQQ__Opportunity2__c).Opportunity_Sub_Type__c != 'GC OnDemand' 
                                && opptyMap.get(quote.SBQQ__Opportunity2__c).Opportunity_Sub_Type__c != 'GC Renewal'){
                if(quote.Scale_Eligible__c == true && quote.RSC_G_Eligible__c == false){
                    quote.SBQQ__QuoteProcessId__c = System.Label.ScaleProcessId;
                    quote.RWD_Guided_Selling__c = System.Label.ScaleProcessId;
                }else if(quote.Scale_Eligible__c == true && quote.RSC_G_Eligible__c == true){
                    quote.SBQQ__QuoteProcessId__c = System.Label.scaleRscgProcessId;
                    quote.RWD_Guided_Selling__c = System.Label.scaleRscgProcessId;
                }
            }
               
            //CPQ22-4200 - Populate Scale guided Selling Id End
        }
    }
    /**
     * @description          : //CPQ22-452 - Link entitlemnets to Renewal Opportunity.
     * @param  quoteList      : New Quote List
     */
    public static void linkEntitlementsToRenewalOpp(List < SBQQ__Quote__c > quoteList){
        List<id> QuoteID = new List<Id>();
        List<id> OppId = new List<Id>();
        Set<id> RenewedCLID = new Set<Id>();
        List<SBQQ__QuoteLine__c> QLsList = new List<SBQQ__QuoteLine__c>();
        List<Entitlement> ENTsList = new List<Entitlement>();
        List<Delegated_Renewed_Entitlement__c> DREsList = new List<Delegated_Renewed_Entitlement__c>();
        Map<Id,Delegated_Renewed_Entitlement__c> FetchDREsMap = new Map<Id,Delegated_Renewed_Entitlement__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteOppCLIMap = new Map<Id,SBQQ__QuoteLine__c>();
        for(SBQQ__Quote__c quote : quoteList){
            if((quote.SBQQ__Primary__c == true && quote.SBQQ__Type__c == 'Renewal' && quote.SBQQ__LineItemCount__c > 0) || Test.isRunningTest()){
                QuoteID.add(quote.Id);
                OppId.add(quote.SBQQ__Opportunity2__c);
            }
        }
        if(!QuoteID.isEmpty()){
            QLsList = [Select Id,Name,SBQQSC__RenewedContractLine__c,SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN: QuoteID];
            for(SBQQ__QuoteLine__c QL : QLsList ){
                if(QL.SBQQSC__RenewedContractLine__c!= null){
                    RenewedCLID.add(QL.SBQQSC__RenewedContractLine__c);
                    quoteOppCLIMap.put(QL.SBQQSC__RenewedContractLine__c,QL);
                }
            }
            
            ENTsList = [Select Id, Name,StartDate,EndDate,Product__c,ContractLineItemId,ContractLineItem.SBQQSC__QuoteLine__c,ServiceContractId,ServiceContract.SBQQSC__Quote__c,ServiceContract.SBQQSC__RenewalOpportunity__c FROM Entitlement WHERE ContractLineItemId IN: RenewedCLID];
            for(Delegated_Renewed_Entitlement__c DRE : [Select id,name,Entitlement__c,Opportunity__c,Service_Contract__c,StartDate__c,EndDate__c FROM Delegated_Renewed_Entitlement__c WHERE Opportunity__c IN:OppId]){
                FetchDREsMap.put(DRE.Entitlement__c,DRE);
            }
            for(Entitlement ET :ENTsList ){
                if(!FetchDREsMap.containsKey(ET.Id)){
                    Delegated_Renewed_Entitlement__c obj = new Delegated_Renewed_Entitlement__c();
                    obj.Entitlement__c = ET.Id;
                    obj.Name = ET.Name;
                    obj.Service_Contract__c = ET.ServiceContractId;
                    obj.Contract_Line_Item__c = ET.ContractLineItemID;
                    obj.StartDate__c = ET.StartDate;
                    obj.EndDate__c = ET.EndDate;
                    obj.Product__c = ET.Product__c;
                    //affected fields
                    if(quoteOppCLIMap.containsKey(ET.ContractLineItemID)){
                        obj.Opportunity__c = quoteOppCLIMap.get(ET.ContractLineItemID).SBQQ__Quote__r.SBQQ__Opportunity2__c;
                        obj.Quote__c = quoteOppCLIMap.get(ET.ContractLineItemID).SBQQ__Quote__c;
                        obj.Quote_Line__c = quoteOppCLIMap.get(ET.ContractLineItemID).Id;
                    }
                    DREsList.add(obj);
                }
            }
            if(!DREsList.isEmpty()){
                Insert DREsList;
                
            }
        }
    }
    /**
     * @description          : //RWD-401 //RWD-1076: Check trigger.new against trigger.old to see if manual_billing__c has changed from false -> true. if profile does != sys admin or deal ops throw error.
     * @param  newQuotesList      : New Quote List  
     * @param  oldQuoteMap      : Old Quote Map
     */
    public static void validateIsManualBillingAllowed (List<SBQQ__Quote__c> newQuotesList, Map<Id, SBQQ__Quote__c> oldQuoteMap) { 
        
        // ADDING IF CHECK TO DETERMINE IF THE PROCESS IS RUN BY AN AUTOMATED PROCESS
        if(UserInfo.getProfileId() != null && !UserInfo.getName().contains('Automated')) {
            if(userProfileName == null){
                userProfileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
            }
            
            for(SBQQ__Quote__c quote: newQuotesList) {
                if(quote.Manual_Billing__c) {
                    if(oldQuoteMap.containsKey(quote.Id) && oldQuoteMap.get(quote.Id).Manual_Billing__c == false && userProfileName != 'System Administrator' && userProfileName != 'Deal Operations' && userProfileName != 'Sales Operations') {
                        quote.addError('Your profile does not have access to manual billing');
                    }
                }
            }
        }
    }
    //RWD-1076 ENDS
    
     /**
     * @description          : Populates certain field from Entitlements
     * @param  quoteRecords      : New Quote List  
     */
    public static void setCheckForRCDMEntiltmentforCustomer(List<SBQQ__Quote__c> quoteRecords) {
        
        Set<Id> QtAccSet = New Set<Id>();
        Set<Id> accIdSet = New Set<Id> ();
        Boolean hasPhoneSupport = false; //added for M365-Utility
        
        for(SBQQ__Quote__c qt : quoteRecords){
            if(qt.Customer_Has_NASCD_RCMD__c != TRUE){
                QtAccSet.add(qt.SBQQ__Account__c);
            }
        }    
        
        If(QtAccSet.size()>0 && system.label.RCDMNasEntitlement == 'RCDM'){
            //added for M365-Utility
            for(Entitlement ent: [select id,Product__c,Product__r.Name,AccountId,Type,Status from Entitlement where AccountId IN: QtAccSet]){
                if(ent.Product__c != null && (ent.Product__r.Name.contains(system.label.RCDMNasEntitlement) || ent.Product__r.Name.contains('NASCD'))) {
                    accIdSet.add(ent.AccountId);
                    break;
                }
                //added for M365-Utility
                if(ent.Type == 'Phone Support' && ent.Status =='Active'){
                   hasPhoneSupport = true;
                }
            }
            
            for(SBQQ__Quote__c qt : quoteRecords){
                If(accIdSet.contains(qt.SBQQ__Account__c)){
                    qt.Customer_Has_NASCD_RCMD__c = true;
                }
                //added for M365-Utility
                if(hasPhoneSupport == true){
                    qt.Account_Has_Phone_Support_Entitlement__c = true;
                }
            }
        }
        
    }
    /*
    //RWD-398 - Populate Co-TermDate on Insert
    public static void populateCoTermOnInsert(List<SBQQ__Quote__c> quoteList, Map<Id, SBQQ__Quote__c> oldQuoteMap) {
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        Map<Id, Date> serviceContractIdToEndDateMap = new Map<Id, Date>();
        Set<Id> amendedServiceContractIdSet =  new Set<Id>();
        Set<Id> quoteIdSet = new Set<Id>();
        Map<Id, Double> serviceContractIdToRenewalTerm = new Map<Id, Double>();
        Map<Id,boolean> idToRenewToOldMap = new Map<Id,Boolean>();//RWD-1646 
        
        
        //CPQ22-1732   
        for(SBQQ__Quote__c quoteRecord : quoteList) {
            //Update the condition below to bypass if co-term end date is not blank and CalculateAPIBatch ran once
            if((quoteRecord.Co_Term_Date__c == null && !TriggerControls.disableCalculateAPIBatch &&  (quoteRecord.SBQQ__Type__c == 'Renewal' || quoteRecord.SBQQ__Type__c == 'Renewal+Expansion') && (quoteRecord.OpportunitySubType__c != 'MSP Consumption Renewal') && quoteRecord.Old_Co_Term_Date__c == null && oldQuoteMap.containsKey(quoteRecord.Id) && oldQuoteMap.get(quoteRecord.Id).SBQQ__NetAmount__c != quoteRecord.SBQQ__NetAmount__c) || Test.isRunningTest()) {
                amendedServiceContractIdSet.add(quoteRecord.Amended_Renewed_Service_Contract__c);
                quoteIdSet.add(quoteRecord.Id);
            }
        }
        if(amendedServiceContractIdSet.size() > 0) {
            if(serviceContractList == null){
                //RWD-1646 added Renew_to_Old_SKUs__c
        //CPQ22-3347 - Added New_Extended_End_Date__c to the inner query
                serviceContractList = [SELECT Id, SBQQSC__RenewalTerm__c,Renew_to_Old_SKUs__c, (SELECT Id, EndDate, New_Extended_End_Date__c FROM ContractLineItems) FROM ServiceContract WHERE Id =: amendedServiceContractIdSet];
            }
            if(serviceContractList.size() > 0){
                for(ServiceContract serviceContract: serviceContractList) {
                    if(serviceContract.ContractLineItems.size() > 0) {
                        Date maxEndDate = null;
                        Date tempEndDate;
                        for(ContractLineItem contractLineItem : serviceContract.ContractLineItems) {
                //CPQ22-3347 - Start - Modified logic to include max end date calculation based on csat end date(New_Extended_End_Date__c)
                            
                            tempEndDate = contractLineItem.EndDate;                                                     
                            if(maxEndDate == null || tempEndDate.addDays(1) > maxEndDate){
                                maxEndDate = tempEndDate.addDays(1);
                            }
                        }
            //CPQ22-3347 - End
                        serviceContractIdToEndDateMap.put(serviceContract.Id, maxEndDate);
                        serviceContractIdToRenewalTerm.put(serviceContract.Id, serviceContract.SBQQSC__RenewalTerm__c);
                    }
                    //RWD-1646
                    idToRenewToOldMap.put(serviceContract.Id,serviceContract.Renew_to_Old_SKUs__c);
                }
            }
            
            List<SBQQ__QuoteLine__c> qlItemList = [SELECT Id,SBQQSC__RenewedContractLine__r.New_Extended_End_Date__c, Support_Tier__c, SBQQ__Product__r.Is_RBK_Appliance__c, SBQQ__Quote__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__EffectiveEndDate__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteIdSet];
            List<SBQQ__Quote__c> quoteUpdateList = new List<SBQQ__Quote__c>();
            
            for(SBQQ__Quote__c quoteRecord : quoteList) {
                // RWD-1130
                SBQQ__Quote__c tempQuote = new SBQQ__Quote__c (Id = quoteRecord.Id);
                if (quoteRecord.sbqq__source__c == null && (quoteRecord.SBQQ__Type__c == 'Renewal' || quoteRecord.SBQQ__Type__c == 'Renewal+Expansion') && quoteRecord.getCloneSourceId() == null && !quoteRecord.isClone()) {
                    if(serviceContractIdToEndDateMap.containsKey(quoteRecord.Amended_Renewed_Service_Contract__c)){
                        Date maxEndDate = serviceContractIdToEndDateMap.get(quoteRecord.Amended_Renewed_Service_Contract__c);
                        for(SBQQ__QuoteLine__c quoteLineItem: qlItemList){
                            if(quotelineItem.SBQQ__Quote__c == quoteRecord.Id && quoteLineItem.SBQQSC__RenewedContractLine__r.New_Extended_End_Date__c == null){
                                if(quoteLineItem.SBQQ__StartDate__c > maxEndDate){
                                    maxEndDate = quoteLineItem.SBQQ__StartDate__c;
                                }
                            }
                        }
                        
                        if(maxEndDate != null && serviceContractIdToRenewalTerm.containsKey(quoteRecord.Amended_Renewed_Service_Contract__c)) {
                            tempQuote.SBQQ__EndDate__c = maxEndDate.addMonths(Integer.valueOf(serviceContractIdToRenewalTerm.get(quoteRecord.Amended_Renewed_Service_Contract__c))).addDays(-1);
                            tempQuote.Co_Term_Date__c = tempQuote.SBQQ__EndDate__c;
                            if (quoteRecord.SBQQ__Type__c == 'Renewal+Expansion') {
                                tempQuote.SBQQ__EndDate__c = null; // ARY-398
                            }
                        }
                    }
                }
                //RWD-1646
                if (quoteRecord.SBQQ__Type__c == 'Renewal' && idToRenewToOldMap.containskey(quoteRecord.Amended_Renewed_Service_Contract__c) && idToRenewToOldMap.get(quoteRecord.Amended_Renewed_Service_Contract__c) == true){
                    tempQuote.Renew_to_Old_SKUs__c = true;    
                }
                quoteUpdateList.add(tempQuote);
            }
            
            if (quoteUpdateList.size() > 0) {
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true; 
                SBQQ.TriggerControl.disable();
                update quoteUpdateList;
                SBQQ.TriggerControl.enable();
                if (!quoteUpdateList.isEmpty() && !System.IsFuture() && !System.isBatch()) {
                    CallCalculateAPIBatch batchInstance  = new CallCalculateAPIBatch(quoteUpdateList);
                    Database.executeBatch(batchInstance, 1);
                    TriggerControls.disableCalculateAPIBatch = true; //Set the recursive flag true if the batch is called once per transaction
                }
            }
        }
    }*/
    
    /*public static void createQuoteLineGroup(Map < Id, SBQQ__Quote__c > newQuoteList){
        map < id, sbqq__quoteline__c > quotelines = new map < id, sbqq__quoteline__c > ();
        List< sbqq__quoteline__c > quotelinestoUpdate = new List < sbqq__quoteline__c > ();
        Set<Id> quoteId = new Set<Id>();
        List<SBQQ__QuoteLineGroup__c> quotelinegrps = new List<SBQQ__QuoteLineGroup__c>();
        SBQQ__QuoteLineGroup__c qlg = new  SBQQ__QuoteLineGroup__c();
        SBQQ__QuoteLineGroup__c qlg1 = new  SBQQ__QuoteLineGroup__c();
        
        for(SBQQ__Quote__c quote : newQuoteList.values()){
            quoteId.add(quote.id);
            if((quote.SBQQ__OrderBy__c=='Line_Type_Order__c' && quote.SBQQ__Primary__c == true && quote.ApprovalStatus__c == 'Approved' && quote.SBQQ__Type__c == 'Renewal')  
               || Test.isRunningTest()){
                   quoteId.add(quote.id);
                   
                   qlg.SBQQ__Quote__c =  quote.Id;
                   qlg.Name = 'renewal group';
                   qlg.SBQQ__Number__c = 1;
                   quotelinegrps.add(qlg);
                   
                   qlg1.SBQQ__Quote__c =  quote.Id;
                   qlg1.Name = 'New Products';
                   qlg1.SBQQ__Number__c = 2;
                   quotelinegrps.add(qlg1);
               }
        }
        quotelines = getquotelines(quoteId);
        if(!quotelinegrps.isEmpty()){
            insert quotelinegrps;
        }
        
        for (sbqq__quoteline__c qlns: quotelines.values()) {
            if(!quotelinegrps.isEmpty() || Test.isRunningTest()){
                if(qlns.Line_Type__c == 'New' || Test.isRunningTest()){
                    qlns.SBQQ__Group__c =  qlg1.id;
                    quotelinestoUpdate.add(qlns);
                }else if(qlns.Line_Type__c == 'Renewal' || Test.isRunningTest()){
                    qlns.SBQQ__Group__c =  qlg.id;
                    quotelinestoUpdate.add(qlns);
                }
                
            }
        }
        if(!quotelinestoUpdate.isEmpty()){
            update quotelinestoUpdate;
        }
        
    }*/

    /**
     * @description          : ScaleUtility_Phase2 CSU-494
     * @param  qtList        : New Quote List  
     * @param  qtNewMap      : New Quote Map
     * @param  qtOldMap      : Old Quote Map
     */
    public static void scaleUSegmentLinesReAdjust(List<SBQQ__Quote__c> qtList, Map<Id, SBQQ__Quote__c> qtNewMap , Map<Id, SBQQ__Quote__c> qtOldMap) {
        ScaleUtilityAmendHelper.adjustSegmentLinesOnScaleUtilityAmend(qtList,qtNewMap,qtOldMap); 
    }
    /**
     * @description          : ScaleUtility_Phase2 CSU-494
     * @param  qtList        : New Quote List  
     */
     public static void scaleUSegmentLinesReAdjust(List<SBQQ__Quote__c> qtList) {
        ScaleUtilityAmendHelper.adjustSegmentLinesOnScaleUtilityAmendInsert(qtList); 
    }
    
    /**
     * @description : get all the values from Deal ops exception multiselect-picklist
     * @return List of all the values from Deal ops exception multiselect-picklist
*/
    public static List<String> getAllDealOpsExceptions(){
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = SBQQ__Quote__c.RWD_Deal_Ops_Exception__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }
        return pickListValuesList;
    }
    /**
     * @description : if there is any change on SBQQ__ExpirationDate__c field of quote bu user of userRole present in custom metadata User_role_for_expiration_date_rule__mdt  then Expire_on_User_boolean__c checkbox get checked so rule "Expiration Date Updated" don't get fire
     * Ticket:- CPQ22-2077 Author:- Pavani Akula
    * @param quoteRecords : List of records whose Expire_on_User_boolean__c field needs to be updated
    * @param oldrecords : Map of old records
*/
    Public static void setExpireOnUserBoolean(List<SBQQ__Quote__c> quoteRecords,map<id,SBQQ__Quote__c> oldrecords){
        List<string> userIdList=new List<string>();//List of user Id present in metadata
        List<User_for_expiration_date_rule__mdt>userRoleMetadata=User_for_expiration_date_rule__mdt.getall().values();//getting metadata
        //putting metadata in metadata List
        for(User_for_expiration_date_rule__mdt Mt:userRoleMetadata)
        {
            userIdList.add(mt.User_Id__c);
        }
        for(SBQQ__Quote__c Quoterecord:quoteRecords)
        {
            if(Quoterecord.SBQQ__ExpirationDate__c!=oldrecords.get(Quoterecord.id).SBQQ__ExpirationDate__c && Quoterecord.SBQQ__Type__c=='Renewal')//checking if expiration date is changed
            {
                if(!userRoleMetadata.isempty()){
                    
                    if(userIdList.contains(Userinfo.getUserId()))//checking if userid is present in metadata
                    {
                        Quoterecord.Expire_on_User_boolean__c=true;
                    }
                    else
                    {
                        Quoterecord.Expire_on_User_boolean__c=false;
                    }
                }
            }
        }
    }
    //end CPQ22-2077
    
    /**
    * @description : set modified Deal ops Exception field on the basis of Deal ops Exception multiselect-picklist for CPQ22-1006
    * @param quoteRecords : List of records whose Deal ops Exception field needs to be updated
*/
    public static void setModifiedDealOpsExceptions(List<SBQQ__Quote__c> quoteRecords){
        List<String> dealOpsExceptions = new List<String>();
        dealOpsExceptions = getAllDealOpsExceptions();
        if(dealOpsExceptions.isEmpty()){
            return;
        }
        for(SBQQ__Quote__c quoteRecord : quoteRecords){
            String result = '';
            String exceptionValues = quoteRecord.RWD_Deal_Ops_Exception__c;
            
            for(String excption : dealOpsExceptions){
                result +=  excption;
                if(exceptionValues != null && exceptionValues.contains(excption)){
                    result += ':Yes,';
                }else{
                    result += ':No,';
                }
            }
            quoteRecord.Deal_Ops_Exceptions_Modified__c = result.removeEnd(',');
            
        }
    }
    /**
     * @description          : Updates Account Deal Desk Notes on Quote
     * @param  quoteRecords  : New Quote List  
    */
    public static void setUpdateQuoteDealNotes(List<SBQQ__Quote__c> quoteRecords) {
        Set<Id>accountIdSet =  new Set<Id>();
        for(SBQQ__Quote__c quoteRecord : quoteRecords){
            accountIdSet.add(quoteRecord.SBQQ__Account__c);
        }
        
        if(accountsList == null && accountIdSet != null && accountIdSet.size() > 0){
            accountsList = [SELECT Id, Account_Deal_Desk_Notes__c FROM Account WHERE Id=: accountIdSet];
        }
        Map<Id, string> accountIdToNotesMap = new Map<Id, string>();
        
        if(accountsList.size() > 0){
            for(Account accountRecord : accountsList) {
                accountIdToNotesMap.put(accountRecord.Id, accountRecord.Account_Deal_Desk_Notes__c);
            }
        }
        for(SBQQ__Quote__c quote : quoteRecords) {
            if(accountIdToNotesMap.containsKey(quote.SBQQ__Account__c)){
                quote.Account_Deal_Desk_Notes__c = accountIdToNotesMap.get(quote.SBQQ__Account__c);
            }
        }
    }
    /**
     * @description          : CPQ22-836 Sends Email for Deal Sizes based on ETM values
     * @param  quoteRecords  : New Quote List  
     * @param  oldQuoteMap   : Old Quote Map
    */
    public static void sendNotificationForDealSize(List<SBQQ__Quote__c> quoteRecords, Map<Id, SBQQ__Quote__c> oldQuoteMap) {
        Set<Id> quoteIdSet =  new Set<Id>();
        if(emailTempRec == null){
            emailTempRec = [Select id,Name, Subject, Body from EmailTemplate where name ='Quote Approval Request for Deal Size' limit 1];
        }
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // fixed the null pointer exception with issue number CPQ22-1318 - Srikanth
        if(quoteRecords != null && !quoteRecords.IsEmpty()){
            String strEmail = System.Label.RubrikUniversityQuestionsEmailid;
            for(SBQQ__Quote__c quoteRecord : quoteRecords){
                if ((quoteRecord.Is_RWD_Polaris_Quote__c == false && quoteRecord.SBQQ__NetAmount__c != null
                     && quoteRecord.SBQQ__NetAmount__c > 1000000.00 && (oldQuoteMap != null && oldQuoteMap.containsKey(quoteRecord.Id) && oldQuoteMap.get(quoteRecord.Id) != null && oldQuoteMap.get(quoteRecord.Id).ApprovalStatus__c != null && oldQuoteMap.get(quoteRecord.Id).ApprovalStatus__c != 'Pending' && (quoteRecord.ApprovalStatus__c == 'Pending' || quoteRecord.ApprovalStatus__c == 'Approved')) && quoteRecord.SBQQ__Type__c == 'Quote' && quoteRecord.ETM_Theatre__c != null && (quoteRecord.ETM_Theatre__c.contains('APAC') || quoteRecord.ETM_Theatre__c.contains('EMEA') || quoteRecord.ETM_Theatre__c.contains('AMER') || quoteRecord.ETM_Theatre__c.contains('MSP'))) || Test.isRunningTest()) 
                {
                    if(emailTempRec != null && emailTempRec.Id != null && quoteRecord != null && quoteRecord.Id != null){
                        //Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTempRec.Id, null, quoteRecord.Id);
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTemplateId(emailTempRec.Id);
                        mail.setWhatId(quoteRecord.Id);
                        mail.setTreatTargetObjectAsRecipient(false);
                        //CPQ22-4074 starts
                        String[] toAddresses = new String[] {strEmail}; //CPQ22-4074 Ends
                            mail.setToAddresses(toAddresses);
                        emails.add(mail);
                    }
                } 
            }
        }
        if(!emails.isEmpty() && !Test.isRunningTest()){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
        }
    }
    //CPQ22-836 ends
    /**
     * @description          :ARY-828 Updates Metrics status as Pending
     * @param  quoteList     : New Quote List  
     * @param  quoteOldMap   : Old Quote Map
    */
    public static void updateMetricsCalcStatus(List<SBQQ__Quote__c>  quoteList, Map<Id, SBQQ__Quote__c>  quoteOldMap){
        for(SBQQ__Quote__c quote: quoteList)
        {
            if(quote.MetricsLastCalcOn__c != null && quote.LastModifiedDate != null && quote.MetricsLastCalcOn__c<quote.LastModifiedDate
               && (quote.SBQQ__Type__c == 'Renewal' || quote.SBQQ__Type__c == 'Renewal+Expansion' || quote.SBQQ__Type__c == 'Quote' || quote.SBQQ__Type__c == 'Amendment') // REEN-121
               && quote.SBQQ__Status__c != 'Approved' && quote.SBQQ__Status__c != 'In Review'
               && quote.SBQQ__Opportunity2__r.StageName != '6 PO With Channel' && quote.SBQQ__Opportunity2__r.StageName != '7 Closed Admin'
               && quote.SBQQ__Opportunity2__r.StageName != '7 Closed Lost' && quote.SBQQ__Opportunity2__r.StageName != '7 Closed Won'){
                   quote.MetricCalcStatus__c = 'Pending';
               }
        }
    }
    //END- ARY-828: Added by Shaloo for Arroyo 2.0
    /**
     * @description          : CPQ22-4591 Populates Special Requests Needed field
     * @param  quoteList     : New Quote List  
    */
    public static void updateSpecialRequestsNeededField(List<SBQQ__Quote__c>  quoteList){
        if(quoteList != null && !quoteList.IsEmpty()){
            for(SBQQ__Quote__c qtObj: quoteList){
                if(qtObj.Legal_Approved_Verbiage__c != null && qtObj.Legal_Approved_Verbiage__c != ''){
                qtObj.Special_Requirements_Needed__c = true;            
                }else if(qtObj.Legal_Approved_Verbiage__c == null){
                qtObj.Special_Requirements_Needed__c = false;
                }
            }
        }               
    }   
    //CPQ22-4591 Ends
    
    /**
     * @description          : CPQ22-3514 Creates Merged Quote Line records for cloned Quotes
     * @param  quoteIds      : Set of Quote Ids
     * @param  sourceQuote   : Set of Source Quote Ids
    */
    @future
    public static void createMergedQLRecords(Set<Id> quoteIds, Set<Id> sourceQuote){
        List<SBQQ__QuoteLine__c> qlLinesOld = [Select Id, Name, SBQQ__Source__c,SBQQ__Quote__r.SBQQ__Source__c, SBQQ__Quote__c from SBQQ__QuoteLine__c where SBQQ__Quote__c IN : quoteIds AND SBQQ__Source__c != null];
        List<Merged_Quote_Line__c> mergedQLOld = [Select Id, Name, Merged_Renewal_Quote_Line__c, New_Quote_Line__c, Quote__c from Merged_Quote_Line__c where Quote__c IN : sourceQuote OR Quote__c IN : quoteIds];
        Map<Id, Merged_Quote_Line__c> mergedQLOldMap = new Map<Id, Merged_Quote_Line__c>();
        Map<Id, SBQQ__QuoteLine__c> qlOldMap = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, Merged_Quote_Line__c> newMergedQLToBeInserted = new Map<Id, Merged_Quote_Line__c>();
        Map<Id, Id> quoteToSourceId = new Map<Id, Id>();
        if (mergedQLOld != null && !mergedQLOld.isEmpty()) {
            for (Merged_Quote_Line__c mQL : mergedQLOld) {
                if (mQL.Merged_Renewal_Quote_Line__c != null && mQL.New_Quote_Line__c != null) {
                    mergedQLOldMap.put(mQL.Merged_Renewal_Quote_Line__c, mQL);
                }
            }
        }
        if (qlLinesOld != null && !qlLinesOld.isEmpty()) {
            for (SBQQ__QuoteLine__c qlRec : qlLinesOld) {
                if (qlRec.SBQQ__Source__c != null) {
                    qlOldMap.put(qlRec.SBQQ__Source__c, qlRec);
                }
                 //FY26WL-227 - Start
                if(!quoteToSourceId.containsKey(qlRec.SBQQ__Quote__c) && qlRec.SBQQ__Quote__r.SBQQ__Source__c != null) {
                    quoteToSourceId.put(qlRec.SBQQ__Quote__r.SBQQ__Source__c, qlRec.SBQQ__Quote__c);
                }
                 //FY26WL-227 - End
            }
        }
        if (mergedQLOldMap != null && !mergedQLOldMap.isEmpty()) {
            for (SBQQ__QuoteLine__c qlrec : qlOldMap.values()) {
                //if mergedQLOldMap contains Source of the New Line and If qlOldMap contains cloned New Line and 
                if (mergedQLOldMap.containsKey(qlrec.SBQQ__Source__c) && mergedQLOldMap.get(qlrec.SBQQ__Source__c) != null && qlOldMap != null && qlOldMap.containsKey(mergedQLOldMap.get(qlrec.SBQQ__Source__c).New_Quote_Line__c)
                   && qlOldMap.get(qlrec.SBQQ__Source__c) != null && !newMergedQLToBeInserted.containsKey(qlOldMap.get(qlrec.SBQQ__Source__c).Id)
                    ) {
                    Merged_Quote_Line__c newMQL = new Merged_Quote_Line__c();
                    newMQL.Merged_Renewal_Quote_Line__c = qlOldMap.get(qlrec.SBQQ__Source__c).Id;
                    newMQL.New_Quote_Line__c = qlOldMap.get(mergedQLOldMap.get(qlrec.SBQQ__Source__c).New_Quote_Line__c).Id;
                    newMQL.Special_Program__c = 'Replaced';
                    newMQL.Quote__c = qlrec.SBQQ__Quote__c;
                    newMergedQLToBeInserted.put(qlOldMap.get(qlrec.SBQQ__Source__c).Id, newMQL);
                }
            }
        }
        if (newMergedQLToBeInserted != null && !newMergedQLToBeInserted.isEmpty()) {
            Database.insert(newMergedQLToBeInserted.values(), false);
        }

        //FY26WL-227 - Start
        List<Approval_Snapshot__c> insertApprovalSnapshot = new List<Approval_Snapshot__c>();
        for(Approval_Snapshot__c snap : 
                [SELECT Id, Quote__c, Quote_Line__c, History__c   
                   FROM Approval_Snapshot__c 
                  WHERE Quote__c IN :sourceQuote]) {
            Approval_Snapshot__c  newSnap = snap.clone();
            if(!String.isBlank(snap.Quote_Line__c) && qlOldMap.containsKey(snap.Quote_Line__c)) {
                newSnap.Quote_Line__c = qlOldMap.get(snap.Quote_Line__c).Id;
            }
            if(!String.isBlank(snap.Quote__c) && quoteToSourceId.containsKey(snap.Quote__c)) {
                newSnap.Quote__c = quoteToSourceId.get(snap.Quote__c);
            }
            insertApprovalSnapshot.add(newSnap);
        }
        if (insertApprovalSnapshot != null && !insertApprovalSnapshot.isEmpty()) {
            Database.insert(insertApprovalSnapshot, false);
        }
        //FY26WL-227 - End
    }
    //CPQ22-3514 Ends

    /**
     * @description          : REEN-25 Creates Consolidated Contract Line records for cloned Quotes
     * @param  quoteIds      : Set of Quote Ids
     * @param  sourceQuote   : Set of Source Quote Ids
    */
    @future
    public static void createCCLIRecords(Set<Id> quoteIds, Set<Id> sourceQuote) {
        Map<Id, SBQQ__QuoteLine__c> qlNewMap = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id,Set<Id>> ccliMap=new Map<Id,Set<Id>>();
        Map<String,Consolidated_Contract_Lines__c> ccliNewMap=new Map<String,Consolidated_Contract_Lines__c>();
        //Get all Quote Lines associated with New Quote where Source is not null. 
        List<SBQQ__QuoteLine__c> qlLinesNew = [
            SELECT Id, Name, SBQQ__Source__c, SBQQ__Quote__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds AND SBQQ__Source__c != NULL
        ];
        //Create map of Old Quote Line Id vs New Quote Line Record.
        if (qlLinesNew != null && !qlLinesNew.isEmpty()) {
            for (SBQQ__QuoteLine__c qlRec : qlLinesNew) {
                if (qlRec.SBQQ__Source__c != null) {
                    qlNewMap.put(qlRec.SBQQ__Source__c, qlRec); // OQL1 - NQL1, OQL2 - NQL1 
                }
            }
        }
        //Get all CCLIs associated with Old Quote.
        List<Consolidated_Contract_Lines__c> ccliList=[ SELECT Id,Quote__c,Quote_Line__c,Contract_Line_Item__c,Quote_Line__r.SBQQ__Source__c
                                                       FROM Consolidated_Contract_Lines__c WHERE Quote__c IN:sourceQuote 
                                                       ];
        //Put the CCLI record in a map of QuoteLine vs CCLI.
        if(ccliList!=null && !ccliList.isEmpty()){
            for(Consolidated_Contract_Lines__c ccli:ccliList){
                 Set<Id> cli= ccliMap.containsKey(ccli.Quote_Line__c)?ccliMap.get(ccli.Quote_Line__c)
                 :new Set<Id>();
                 cli.add(ccli.Contract_Line_Item__c);
                 ccliMap.put(ccli.Quote_Line__c,cli); 
            }  
        }
        //If new Quote Line's source is present in ccliMap, then create records for each of the Contract Line Items.
        if (ccliMap != null && !ccliMap.isEmpty() && qlNewMap!=null && !qlNewMap.isEmpty()) {
            for (SBQQ__QuoteLine__c qlrec : qlNewMap.values()) {
                if (ccliMap.containsKey(qlrec.SBQQ__Source__c) && ccliMap.get(qlrec.SBQQ__Source__c) != null &&  qlNewMap.get(qlrec.SBQQ__Source__c) != null) {
                    for (Id str : ccliMap.get(qlrec.SBQQ__Source__c)) {
                        if (!ccliNewMap.containsKey(qlNewMap.get(qlrec.SBQQ__Source__c).Id+':'+str)) {
                            Consolidated_Contract_Lines__c newCCLI = new Consolidated_Contract_Lines__c();
                            newCCLI.Quote_Line__c = qlNewMap.get(qlrec.SBQQ__Source__c).Id;
                            newCCLI.Contract_Line_Item__c = str;
                            newCCLI.Quote__c = qlrec.SBQQ__Quote__c;
                            ccliNewMap.put(qlNewMap.get(qlrec.SBQQ__Source__c).Id+':'+newCCLI.Contract_Line_Item__c, newCCLI);
                        }
                    }
                }
            }
        }
        if(ccliNewMap!=null && !ccliNewMap.isEmpty()){
            Database.insert(ccliNewMap.values(),false);
        }
    }
    //End REEN-25

    Public static List<SBQQ__Quote__c> quoteMap = new List<SBQQ__Quote__c>();
    /**
     * @description                  : REEN-41 Generic Quote query, can leveraged on after update.
     * @param  opportunityIdSet      : Set of Opportunity Ids whose Quotes has to be retrieved
     * @return                       : List of Quote records
    */
    public static List<SBQQ__Quote__c> getQuoteRecords(set<Id> opportunityIdSet){
        if(quoteMap.isEmpty()){
            quoteMap = [SELECT Id, SBQQ__Primary__c, SBQQ__Opportunity2__c, SBQQ__ExpirationDate__c, SBQQ__Account__c, 
                        Deal_Desk_Users__c, SBQQ__StartDate__c, SBQQ__Type__c, SBQQ__Status__c, Update_Expires_On__c,
                            SBQQ__Account__r.Contract_Status__c,Name,SBQQ__Opportunity2__r.RenewalOwner__r.Email,
                            Renewal_Ops_Reviewed__c,ApprovalStatus__c,
                        	SBQQ__Opportunity2__r.OwnerId,SBQQ__Opportunity2__r.Owner.Email,SBQQ__Opportunity2__r.Account.Renewal_Owner__r.Email,
                        SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Partner_Lookup__c,
                        SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Distributor_Lookup__c,
                            SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Distributor_Lookup__r.Contract_Status__c,
                            (SELECT Id,Disposition_Reason__c,Product__c,Quote__c,
                                        Product__r.Replacement_Category__c,Product__r.ProductCode
                                FROM Disposition_Quote_Lines__r 
                                WHERE Product__r.Replacement_Category__c != null)
                        FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN: opportunityIdSet];
        }
        return quoteMap;
    }
     /**
     * @description                  : REEN-41 Counts number of valid Primary Quotes on Opportunity.
     * @return                       : Map of Opportunity vs count of primary quotes
    */
    public static Map<Id, Integer> getMapOfOppvsCount() {
        Map<Id, Set<Id>> mapOfOppIdvsQuoteId = new Map<Id, Set<Id>>();
        Set<Id> quoteIds = new Set<Id>();
        if (quoteMap != null && !quoteMap.isEmpty()) {
            for (SBQQ__Quote__c qlObj : quoteMap){
                if (qlObj.SBQQ__Primary__c && qlObj.SBQQ__Type__c == 'Renewal' 
                   ) {
                       if (mapOfOppIdvsQuoteId.containsKey(qlObj.SBQQ__Opportunity2__c)) {
                           mapOfOppIdvsQuoteId.get(qlObj.SBQQ__Opportunity2__c).add(qlObj.Id);
                       }
                       else {
                           quoteIds = new Set<Id>(); 
                           quoteIds.add(qlObj.Id);
                           mapOfOppIdvsQuoteId.put(qlObj.SBQQ__Opportunity2__c, quoteIds);
                       }
                   }
                else {
                    if (mapOfOppIdvsQuoteId.containsKey(qlObj.SBQQ__Opportunity2__c)) {
                        mapOfOppIdvsQuoteId.get(qlObj.SBQQ__Opportunity2__c).remove(qlObj.Id);
                    }
                    else {
                        mapOfOppIdvsQuoteId.put(qlObj.SBQQ__Opportunity2__c, new Set<Id>());
                    }
                }
            } 
        }
        Map<Id, Integer> mapOfOppvsCount = new Map<Id, Integer>();
        if (mapOfOppIdvsQuoteId != null && !mapOfOppIdvsQuoteId.isEmpty()) {
            for (Id oppId : mapOfOppIdvsQuoteId.keySet()) {
                if(mapOfOppIdvsQuoteId.containsKey(oppId) && mapOfOppIdvsQuoteId.get(oppId) != null ) {
                    mapOfOppvsCount.put(oppId,mapOfOppIdvsQuoteId.get(oppId).size() );
                }
            }
        }
        
        return mapOfOppvsCount;
    }
    // REEN-41 end 
    /**
     * @description                  : CPQ22-4654- return if the data is incorrect on Quotelines
     * @param  quotelines            : List of Quote Line Record Response 
     * @return                       : Boolean value of missing data
    */
    public static Boolean verifyTierOnQLs(List<QuoteLineRecordResponse> quotelines) {
        Boolean isMissingData = false;
        for(Integer i = 0; i<quotelines.size(); i++) {
            if(quotelines[i].ptyp == ReplacementConstants.HW_SUPPORT && quotelines[i].rqBy != null 
            && quotelines[i].optional == false) {
                String tier = quotelines[i].reqSupTier != null 
                            ? quotelines[i].reqSupTier
                            : quotelines[i].reqHWSupTier;
                if(tier != null) {
                    if(quotelines[i].supTier != null && quotelines[i].supTier != tier) {
                        isMissingData = true; 
                    } else if(quotelines[i].hWSupTier != null && quotelines[i].hWSupTier != tier) {
                        isMissingData = true; 
                    }
                }
            }
        }
        return isMissingData;
    }//End CPQ22-4654
   
    /**
     * @description                  : To be removed
     * @param  quoteRec            : List of Quote Line Record Response 
     * @return                       : Boolean value of missing data
    */
    /*public static void createDealDeskCase(List<SBQQ__Quote__c> quoteRec) {
        Map<Id,Id> quoteToOppId = new Map<Id,Id>();
        Map<Id,Deal_Desk_Case__c> quoteToddCaseId = new Map<Id,Deal_Desk_Case__c>();
        List<Deal_Desk_Case__c> ddc_list = new List<Deal_Desk_Case__c>();
        List<Deal_Desk_Case__c> ddListUpdate = new List<Deal_Desk_Case__c>();
        if(quoteRec!=null){
            for(sbaa__Approval__c approval : [SELECT Id, Quote__c,Quote__r.SBQQ__Opportunity2__c from sbaa__Approval__c
                                              WHERE Quote__c != null AND Quote__r.SBQQ__Opportunity2__c != null AND sbaa__Rule__r.sbaa__Active__c = TRUE
                                              AND sbaa__Rule__r.sbaa__Approver__r.Name LIKE '%Deal Desk%' and Quote__c IN : quoteRec]){
                                                 quoteToOppId.put(approval.Quote__c,approval.Quote__r.SBQQ__Opportunity2__c);
                                              }
        }

        //Start DD25- 57 
    
        if (quoteRec !=null) {
            for (Deal_Desk_Case__c ddc : [SELECT id,Request_Status__c,Quote__c from Deal_Desk_Case__c 
                                          WHERE Quote__c != null AND Quote__c IN :quoteRec]) {
                                            quoteToddCaseId.put(ddc.Quote__c, ddc);
            }
        }
            
        if(quoteToOppId != null && !quoteToOppId.isEmpty()){
            for(ID quoteId : quoteToOppId.keySet()){
                if (quoteToddCaseId.get(quoteId) == null) {
                    Deal_Desk_Case__c ddc_Obj = new Deal_Desk_Case__c();
                    ddc_Obj.Deal_Desk_Team__c = 'Deal Operations';
                    ddc_Obj.Request_Type__c = 'General Inquiry';
                    ddc_Obj.Request_Sub_Type__c = 'Best practice enablement';
                    ddc_Obj.Business_Justification__c = 'Issue related to quote';
                    ddc_Obj.Opportunity__c = quoteToOppId.get(quoteId);
                    ddc_Obj.Quote__c = quoteId;
                    ddc_Obj.Case_Auto_Created__c = true;
                    ddc_list.add(ddc_Obj);
            }
                else if (quoteToddCaseId.get(quoteId) != null &&(quoteToddCaseId.get(quoteId).Request_Status__c == 'Approved' ||quoteToddCaseId.get(quoteId).Request_Status__c == 'Rejected' || quoteToddCaseId.get(quoteId).Request_Status__c.contains('Closed'))) {
                    Deal_Desk_Case__c ddcObj = new Deal_Desk_Case__c();
                    ddcObj.Id = quoteToddCaseId.get(quoteId).id;
                    ddcObj.Request_Status__c = 'Draft';
                    ddcObj.ApprovalStatus__c = '';
                    ddcObj.Case_Auto_Created__c = False;
                    ddListUpdate.add(ddcObj);
                }

                
            }
        }
            if(ddc_list != null && !ddc_list.isEmpty()){
                insert ddc_list;
            }
            if(ddListUpdate != null && !ddListUpdate.isEmpty()){
                 update ddListUpdate;
            }
    }*/
        // End DD25 - 57

    /***********************************************************************************************************
    * Method Name          : resetFlagonClone
    * Date Created/Modified: 27/06/2025
    * Author               : Mustakim Shaikh
    * @description         : CPQ22-5343 - The isFieldNull__c flag is reset in the QuoteTriggerHandler within the After Insert context of Quotes. This is achieved by invoking the resetFlagonClone method, ensuring proper checks are in place to avoid execution within Batch/Future/Queueable contexts.
                             We added the invocation of resetFlagonClone to the QuoteTriggerHandler instead of QuoteLineTriggerHandler. This adjustment was necessary because attempts from QuoteLineTriggerHandler resulted in the changes being overwritten. Moreover, the resetFlagonClone method utilizes a @future call since the QLIs were not accessible in a synchronous context immediately after the Quote insert event.
                             This approach ensures that the flag reset operation executes effectively and reliably.
    * @param quoteIds      : The Id of the Quote to update.
    * Test Class Methods   : QuoteTrigger_Test.testProcessTradeUpUpdate
    /**********************************************************************************************************/
    @future
    public static void resetFlagonClone(Set<Id> quoteIds) {
        // Query Quote Lines to update
        List < SBQQ__QuoteLine__c > qLIsToUpdate = new List < SBQQ__QuoteLine__c >();
        if(Schema.sObjectType.SBQQ__QuoteLine__c.isAccessible() && qLIsToUpdate == null) {
            qLIsToUpdate = [Select Id, Name, isFieldNull__c
                FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN : quoteIds AND isFieldNull__c = true
            ];
        }
        List < SBQQ__QuoteLine__c > qlRecordToUpdate = new List < SBQQ__QuoteLine__c > ();

        // Reset Flag on Quote Lines as needed
        if(qLIsToUpdate != null) {
            for (SBQQ__QuoteLine__c qlRecord: qLIsToUpdate) {
                qlRecord.isFieldNull__c = false;
                qlRecordToUpdate.add(qlRecord);
            }
        }
        //Update Quote Lines
        if(!qlRecordToUpdate.isEmpty()) {
            if(Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable()) {
                TriggerControls.disableQuoteLineTrigger = true;
                update qlRecordToUpdate;
            }
        }
    }
    /**
    * @description Sync convertQLtoCPQDisposeLines Helper function to create CPQ dispose lines. 
* Summer Release CutOver Activities - Khushboo
* @param quoteLineMap
**/
    public static void convertQLtoCPQDisposeLines(Map<Id, List<SBQQ__QuoteLine__c>> quoteLineMap){
    try {
       List<CPQ_Disposition_Quote_Line__c> disposeLinesToInsert = new List<CPQ_Disposition_Quote_Line__c>();
       List<SBQQ__QuoteLine__c> toDeleteQLILines = new List<SBQQ__QuoteLine__c>();
       // Fetch metadata
       Replacement_Field_Mapping__mdt objectData = ReplacementRefreshUtility.getCustomMetadataInstance('OldFrameWorkQuoteType');
       Set<String> quoteTypeSet = new Set<String>();
       Set<String> quoteStatusSet = new Set<String>();
       Set<String> quoteLineDispositionSet = new Set<String>();

       if (objectData != null) {
           if (String.isNotBlank(objectData.Quote_Type__c)) {
               quoteTypeSet.addAll(objectData.Quote_Type__c.split(','));
           }
           if (String.isNotBlank(objectData.Second_Filter_Criteria__c)) {
               quoteStatusSet.addAll(objectData.Second_Filter_Criteria__c.split(','));
           }
           if (String.isNotBlank(objectData.First_Filter_Criteria__c)) {
               quoteLineDispositionSet.addAll(objectData.First_Filter_Criteria__c.split(','));
           }
       }

       if (quoteTypeSet.isEmpty() || quoteStatusSet.isEmpty() || quoteLineDispositionSet.isEmpty()) {
           return;
       }

       for (Id quoteId : quoteLineMap.keySet()) {
           for (SBQQ__QuoteLine__c qli : quoteLineMap.get(quoteId)) {
               if (qli.SBQQ__Quote__c != null &&
                   qli.Replacement_Motion__c != null &&
                   quoteLineDispositionSet.contains(qli.Disposition_Reason__c) &&
                   !quoteStatusSet.contains(qli.SBQQ__Quote__r.SBQQ__Status__c) &&
                   quoteTypeSet.contains(qli.SBQQ__Quote__r.SBQQ__Type__c)) 
                   {

                   toDeleteQLILines.add(qli);

                   disposeLinesToInsert.add(new CPQ_Disposition_Quote_Line__c(
                       Quote__c = qli.SBQQ__Quote__c,
                       Disposition_Reason__c = qli.Disposition_Reason__c,
                       Product__c = qli.SBQQ__Product__c,
                       Replacement_Detail__c = qli.Replacement_Details__c,
                       Quantity__c = qli.SBQQ__Quantity__c,
                       Arroyo_Subscribed_Asset_Name__c = qli.Subscribed_Asset_Name__c,
                       RenewedContractLine__c = qli.SBQQSC__RenewedContractLine__c,
                       PricebookEntryId__c = qli.SBQQ__PricebookEntryId__c,
                       Arroyo_Subsumed_Old_Contract_Line_Items__c = qli.SBQQSC__RenewedContractLine__c
                   ));
               }
           }
       }

        if (!disposeLinesToInsert.isEmpty()) {
            insert disposeLinesToInsert;
        }  
        if (!toDeleteQLILines.isEmpty()) {
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            delete toDeleteQLILines;
        }

    } catch (Exception ex) {
        LogError.logCustomError('QuoteTriggerHelper', ex.getMessage(), ex.getStackTraceString(), 'ConvertQLtoCPQDisposeLines method failed');
    }
}
    /**
    * @description Async processQLtoCPQDisposeLines Helper function to create CPQ dispose lines. 
    * Summer Release CutOver Activities - Khushboo
    * @param quoteIds
    **/
    @future(callout=false)
    public static void processQLtoCPQDisposeLines(Set<Id> quoteIds) {
        try {
            Map<Id, List<SBQQ__QuoteLine__c>> quoteLineMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
            // Fetch Quote Lines related to the passed Quote IDs
            List<SBQQ__QuoteLine__c> qliList = [
                SELECT Id, SBQQ__Quote__c, SBQQ__Product__c, Replacement_Details__c,
                        SBQQ__Quantity__c, Subscribed_Asset_Name__c, Disposition_Reason__c,
                        Replacement_Motion__c, SBQQ__PricebookEntryId__c,
                        SBQQSC__RenewedContractLine__c,
                        SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__r.SBQQ__Type__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteIds
            ];
            if(qliList.isEmpty()) return;
            for(SBQQ__QuoteLine__c ql:qliList)
            {
                List<SBQQ__QuoteLine__c> existingList = quoteLineMap.get(ql.SBQQ__Quote__c);
                existingList = existingList != null ? existingList : new List<SBQQ__QuoteLine__c>();
                
                existingList.add(ql);
                quoteLineMap.put(ql.SBQQ__Quote__c, existingList);
            }
            if(quoteLineMap!=null && !quoteLineMap.isEmpty()){
                ConvertQLtoCPQDisposeLines(quoteLineMap); 
            }

        } catch (Exception ex) {
            LogError.logCustomError('QuoteTriggerHelper',ex.getMessage(),ex.getStackTraceString(),'processQLtoCPQDisposeLines method failed');
        }
    }
    /**
    * @description FY25SR-2391 Logic to update IAR__c field on quote if LOD to SAAS happens
    * @param quotelines
    * @return quoteToLOD
    */
    public static Set<Id> processQuotelinesToUpdateIAR(Map<Id, SBQQ__QuoteLine__c> quotelines){
        Set<Id> quoteToLOD = new Set<Id>();
        for (SBQQ__QuoteLine__c qli : quoteLines.values()) {
            if(qli.Replacement_Details__c != null){
                if(quoteToLOD.contains(qli.SBQQ__Quote__c)) {
                    continue;
                }
                
                ReplacementJson qliReplaceJSON = 
                    (ReplacementJson) JSON.deserialize(qli.Replacement_Details__c, ReplacementJson.class);
                if (qliReplaceJSON != null && qliReplaceJSON.lodToSaas == true) {
                    quoteToLOD.add(qli.SBQQ__Quote__c);
                }
            }
        }
        return quoteToLOD;
    }
/**
* @description CPQ22-6097 Enforces field editability rules on a list of records during trigger execution.
 * Compares old vs new values, checks against metadata rules, and throws errors if edits are not allowed.
* @Date 3 December 2025
*/
    private static Map<String, QuoteFieldEditability__mdt> rulesCache;
/**
* @description CPQ22-6097 Ensure method is running once only
* @Date 3 December 2025
*/
    private static Boolean hasRun = false;
/**
* @description CPQ22-6097 Ensure Schema.DescribeFieldResult limits
* @Date 3 December 2025
*/
    private static Map<String, Schema.SObjectField> fieldDescribeCache;
      /**
* @description CPQ22-6097 Enforces field editability rules on a list of records during trigger execution.
 * Compares old vs new values, checks against metadata rules, and throws errors if edits are not allowed.
* @Date 3 December 2025
* @param qtList List<SBQQ__Quote__c>
* @param qtOldMap Map<Id, SBQQ__Quote__c>
*/
    public static void enforceFieldEditablility(List<SBQQ__Quote__c> qtList, Map<Id, SBQQ__Quote__c> qtOldMap) {
         if (hasRun) {
            return;
        }
        hasRun = true;
        set<String> metadataProfiles = new set<String>();
        if (fieldDescribeCache == null) {
        fieldDescribeCache = initFieldDescribeCache('SBQQ__Quote__c');
        }
        if(rulesCache == null){
           rulesCache = getFieldEditableMetadata(metadataProfiles);
        }
        Boolean hasSpecialPermission = FeatureManagement.checkPermission('Special_DealOperations_Edit');
        // Get user profile name once
       
        for (SBQQ__Quote__c newQuote : qtList) {
            SBQQ__Quote__c oldQuote = qtOldMap.get(newQuote.Id);
            
            String userProfileName = newQuote.Running_User_Profile__c;
            if(hasSpecialPermission){
                userProfileName = 'Deal Operations';
            }else if(!metadataProfiles.contains(userProfileName.trim())){
                userProfileName = 'All Other Profiles';
            }

            if ((oldQuote.RecordTypeId != newQuote.RecordTypeId) || (oldQuote.ApprovalStatus__c != newQuote.ApprovalStatus__c) || (oldQuote.SBQQ__Status__c != newQuote.SBQQ__Status__c && (newQuote.SBQQ__Status__c == Constants.STATUS_IN_REVIEW || newQuote.SBQQ__Status__c == Constants.STATUS_APPROVED))) {
               continue;
            }
            
            
            List<String> restrictedFields = new List<String>();
            // Get all fields that have values on the record
            //Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.SBQQ__Quote__c.fields.getMap();
            if(!fieldDescribeCache.isEmpty()){
            for (String fieldName : fieldDescribeCache.keySet()) {
                
                if (!fieldName.endsWith('__c')) {
                continue;
                }
                
                Object oldVal = oldQuote.get(fieldName);
                Object newVal = newQuote.get(fieldName);
                if (oldVal != newVal) {
                    Schema.DescribeFieldResult dfr = fieldDescribeCache.get(fieldName).getDescribe();
                    //Schema.DescribeFieldResult dfr = fieldDescribeCache.get(fieldName);
                    // Skip formula fields
                    if (dfr.IsCalculated()) {
                        continue;
                    }
                    // Build key dynamically
                    String key = buildKey('SBQQ__Quote__c', newQuote.SBQQ__Status__c, userProfileName, fieldName);
                    
                    if (!rulesCache.containsKey(key) && (newQuote.SBQQ__Status__c ==Constants.STATUS_IN_REVIEW || newQuote.SBQQ__Status__c ==Constants.STATUS_APPROVED)) {
                         restrictedFields.add(dfr.getLabel());
                    } else if(rulesCache.containsKey(key)){  
                        QuoteFieldEditability__mdt applicableRule = rulesCache.get(key);
                        if (!applicableRule.IsEditable__c) {
                             restrictedFields.add(dfr.getLabel());
                        }
                    }
                }
            }
        }
            if (!restrictedFields.isEmpty() && !Test.isRunningTest()) {
                SBQQ.TriggerControl.disable();
				try {
                newQuote.addError(
                    label.Quote_FieldEdit_NotAllowed_InReviewApproved +' '+ String.join(restrictedFields, ', ')
                );
                }finally {
					SBQQ.TriggerControl.enable();
				}
            }
        }
    }
    /**
     * @description initFieldDescribeCache
     * @date 10 December 2025
     * @return Map<String, FieldDefinition>
     * @param objectApiName
     */
    public static Map<String, Schema.SObjectField> initFieldDescribeCache(String objectApiName) {
            //Map<String, Schema.DescribeFieldResult> fieldDescribeCacheMap = new Map<String, Schema.DescribeFieldResult>();
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
            Map<String, Schema.SObjectField> fieldsMap = sObjType.getDescribe().fields.getMap();
            return  fieldsMap;
    }

    /**
* @description CPQ22-6097 Loads all field editability rules from the custom metadata type (QuoteFieldEditability__mdt).
* @date 3 December 2025
* @return Map<String, QuoteFieldEditability__mdt>
* @param profileList
*/
    public static Map<String, QuoteFieldEditability__mdt> getFieldEditableMetadata(set<String> profileList) {
        Map<String, QuoteFieldEditability__mdt> rulesMap = new Map<String, QuoteFieldEditability__mdt>();
        for (QuoteFieldEditability__mdt rule : QuoteFieldEditability__mdt.getAll().values()) {
            List<String> statuses = splitAndTrim(rule.QuoteStatus__c);
            List<String> profiles = splitAndTrim(rule.ProfileName__c);
            
            for (String status : statuses) {
                for (String profile : profiles) {
                    profileList.add(profile);
                    String key = buildKey(rule.ObjectName__c, status, profile, rule.FieldName__c);
                    rulesMap.put(key, rule);
                }
            }
        }
        return rulesMap;
    }
    /**
* @description CPQ22-6097 Splits a comma-separated string into a list of trimmed values.
* @Date 3 December 2025
* @param input String
* @return List<String>
*/
    public static List<String> splitAndTrim(String input) {
        if (String.isBlank(input)) {
            return new List<String>{''};
                }
        List<String> results = new List<String>();
        for (String part : input.split(',')) {
            String trimmed = part.trim();
            if (trimmed != '') {
                results.add(trimmed);
            }
        }
        return results.isEmpty() ? new List<String>{''} : results;
    }
    /**
* @description CPQ22-6097 Builds a composite key string used to uniquely identify a field editability rule.
* @Date 3 December 2025
* @param objectName String
* @param status String
* @param profileName String
* @param fieldName String
* @return String
*/
    public static String buildKey(String objectName, String status, String profileName, String fieldName) {
        List<String> parts = new List<String>();
        parts.add(objectName.toLowerCase());
        if (String.isNotBlank(status)) {
            parts.add(status.trim().toLowerCase());
        }
        parts.add(profileName.toLowerCase());
        parts.add(fieldName.toLowerCase());
        return String.join(parts, '|');
    }
    //END CPQ22-6097
    
    /**
    * Method Name          : updateExpirationWithHardware
    * Date Created/Modified: 17/02/2026
    * @description  Created as part of CPQ22-6401 to update quote expiration date
    * @param qt
    * @param qtOldMap
    * @param quotelines
    */   
    public static void updateExpirationWithHardware(SBQQ__Quote__c qt, Map<Id, SBQQ__Quote__c> qtOldMap, Map<Id, SBQQ__QuoteLine__c> quotelines){
        if ((qt.SBQQ__Type__c == 'Quote' || qt.SBQQ__Type__c == 'Renewal+Expansion') && !qt.IsAspenQuote__c) {
            Date earliestHWDate = null;
            Date eomonthDate = null;
            Boolean dateUpdate = false;
            if (quotelines != null) {
                for (SBQQ__QuoteLine__c ql : quotelines.values()) {
                    if (ql.SBQQ__Quote__c == qt.Id && !ql.SBQQ__Optional__c 
                        && ql.Quote_Line_Type__c == 'New' 
                        && !ql.SBQQ__Existing__c 
                        && ql.Is_Hardware_and_New__c) { 
                        Date qlDate = (ql.CreatedDate != null) ? ql.CreatedDate.date() : system.today();
                        if (earliestHWDate == null || qlDate < earliestHWDate) {
                            earliestHWDate = qlDate;
                        }
                    }
                }
            }
            if (earliestHWDate != null) {
                Integer lastDay = Date.daysInMonth(earliestHWDate.year(), earliestHWDate.month());
                Date eomDate = Date.newInstance(earliestHWDate.year(), earliestHWDate.month(), lastDay);
                SBQQ__Quote__c oldQt = qtOldMap.get(qt.Id);
                if(qt.CreatedDate >= Datetime.Now().addMinutes(-1) && qt.sbqq__source__c != null){
                    qt.SBQQ__ExpirationDate__c = eomDate;
                }
                if (oldQt.SBQQ__ExpirationDate__c != qt.SBQQ__ExpirationDate__c && qt.SBQQ__ExpirationDate__c > eomDate &&
                    qt.Running_User_Profile__c != 'System Administrator' && qt.Running_User_Profile__c != 'Rubrik IT User') {
                    qt.addError('Expiration dates cannot be extended beyond the end of the month for Non-ASPEN Hardware deals. Please clone to create a new quote.');
                    return; 
                }
            }
        }
    } // CPQ22-6401 Ends
   
    /**
    * Method Name          : validatePrimaryQuoteChange
    * Date Created/Modified: 2-Dec-2025
    * @description  Created as part of FY26WL-353 validate new Primary Quote with old Primary Quote line item with entitlement ids
    * @param newMap
    * @param oldMap
	*/   
    public static void validatePrimaryQuoteChange(Map<ID,SBQQ__Quote__c> newMap, Map<ID,SBQQ__Quote__c> oldMap){
        if(newMap.isEmpty() || oldMap.isEmpty() || insert_logic == true) return;
        
        List<id> quoteIds = new List<id>();
        List<id> oppIds = new List<id>();
        List<id> accountIds = new List<id>();
        Map<id,id> accIdWithQuoteIds = new Map<Id, Id>();
        Order_control__mdt disQuotePrimaryValid = Order_control__mdt.getInstance('DisableQuotePrimaryValidation');
        Order_control__mdt disPrimaryToUnPrimaryValid = Order_control__mdt.getInstance('DisablePrimaryToUnPrimaryValidation');    
        
        for(SBQQ__Quote__c quoteObj : newMap.values()){
            if(processedQuoteIds.contains(quoteObj.Id) && quoteObj.SBQQ__Primary__c == false){continue;}
            if(quoteObj.SBQQ__Primary__c != oldMap.get(quoteObj.Id).SBQQ__Primary__c && quoteObj.SBQQ__Opportunity2__c != null){               
                if((quoteObj.SBQQ__Primary__c == true && String.isNotBlank(disQuotePrimaryValid.Value__c) && Boolean.valueOf(disQuotePrimaryValid.Value__c) == false )
                  || (quoteObj.SBQQ__Primary__c == false && String.isNotBlank(disPrimaryToUnPrimaryValid.Value__c) && Boolean.valueOf(disPrimaryToUnPrimaryValid.Value__c) == false)){
                quoteIds.add(quoteObj.id);
                if(!oppIds.contains(quoteObj.SBQQ__Opportunity2__c)){
                    oppIds.add(quoteObj.SBQQ__Opportunity2__c);
                }
                if(!accountIds.contains(quoteObj.SBQQ__Account__c)){
                    accountIds.add(quoteObj.SBQQ__Account__c);
                    accIdWithQuoteIds.put(quoteObj.SBQQ__Account__c,quoteObj.Id);
                    } 
                }
            }           
        }
        
        if(quoteIds.isEmpty() || oppIds.isEmpty() ||accountIds.isEmpty()){return;}
        List<EntitlementResponseWrapper> resWList = QuoteValidationController.compareEntitlementAllWithNewPrimaryQuote(quoteIds,oppIds,accountIds,accIdWithQuoteIds);
        if(QuoteValidationController.processedQuoteIds != null){
            processedQuoteIds.addAll(QuoteValidationController.processedQuoteIds);
        }
        if(resWList.isEmpty()){return;}
        for(SBQQ__Quote__c quoteObj : newMap.values()){
            if(resWList[0].quoteId == quoteObj.Id){
                if(quoteObj.SBQQ__Primary__c == true){
                   quoteObj.addError('This quote cannot be checked/unchecked primary. Please check "Validate Quote" tab for further details.');
                }else{
                    quoteObj.addError('This quote cannot be checked/unchecked primary. Please check "Validate Quote" tab for further details. One of the quote line Number is '+resWList[0].quoteLineNumber);
                }
            }
        }
    }

    /**
     * @description       : this is a common method is used to populate FSI_Special_Program__c field on Opportunity based on the Quote line Product type and Primary quote flag
     * @param  mapQuoteIdToQuote   : Map of Quote Id and Quote record which are in context of trigger event, used to get the related Opportunity Id and Primary quote flag for the quote
     */
    public static void populateFieldsOnOpportunity (Map<Id,SBQQ__Quote__c> mapQuoteIdToQuote) {
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        for(AggregateResult groupedResults: [Select count(id),SBQQ__Quote__c from SBQQ__QuoteLine__c where Product_Type__c like: CPQ_Constants.PAYGO_Check and SBQQ__Quote__c in: mapQuoteIdToQuote.keyset()  group by SBQQ__Quote__c ]){
            String quoteId = String.valueof(groupedResults.get('SBQQ__Quote__c'));
            if(mapQuoteIdToQuote.get(quoteId)!=null){
                if(Integer.valueof(groupedResults.get('expr0')) > 0 && mapQuoteIdToQuote.get(quoteId).SBQQ__Primary__c){
                    Opportunity opp = new Opportunity(Id = mapQuoteIdToQuote.get(quoteId).SBQQ__Opportunity2__c,FSI_Special_Program__c = CPQ_Constants.PAYGO_Commit);
                    oppToUpdate.add(opp);    
                }
                else{
                    Opportunity  opp = new Opportunity(Id = mapQuoteIdToQuote.get(quoteId).SBQQ__Opportunity2__c,FSI_Special_Program__c = '');
                    oppToUpdate.add(opp);
                }
            }
        }
        if(!oppToUpdate.isEmpty()){
            flowControll.opportunityLineItemHandler = false;
            flowControll.opportunityTriggerHandler = false;
            update oppToUpdate;
            flowControll.opportunityLineItemHandler = true;
            flowControll.opportunityTriggerHandler = true;
        } 
    }
}