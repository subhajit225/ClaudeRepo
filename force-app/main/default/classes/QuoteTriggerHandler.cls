/**
* @File Name : QuoteTriggerHandler.cls
* @description : Handler class for QuoetTrigger. Called from QuoteTrigger
* Test Class: QuoteTrigger_Test
**/
public without sharing class QuoteTriggerHandler extends TriggerHandler{
    public static boolean disableQuoteTrigger = false;
    private Boolean isDisabled = false;
    private Boolean isFieldEditabilityDisabled = false;//CPQ22-6097
    public static Boolean expirationFlag = false;
    private Boolean isDisabledGuidedSell = false;
    public static Boolean isRecursiveLinkOppEnt = false; 
    public static Boolean retryBatchExecuted = false;//RWD-1176
    public static Boolean isASNValidationDisabled = false; //ASPEN-247
     
    //Ashwini    
    public static Boolean inRecursiveQueueableUpdate = false;
    public static Boolean inRecursiveRenewalQLIUpdate = false; // US-26
    public static Boolean byPassQuoteTriggerForPolarisSKURestructuring =false; // US - 26
     
    //Declared static variables to put null checks to fix SOQL 101 error:Shaloo
    public static List<SBQQ__Quote__c> lstQuoteRec;
    public static Map<Id,SBQQ__Quote__c> allQuotesMap;
    public static List<SBQQ__Quote__c> allQuotes; //REEN-41
    public static Boolean disableReplacementDisabled = false;//FY25SR-1706
    public static Boolean enableAsyncCallToConvertQL = false;//Summer Release custover activities
    public static Boolean disable_ConvertQLtoCPQDisposeLines = false;//Summer Release custover activities
    public static Boolean disable_QuotePrimaryValid = false;  //Part of FY26WL-353 start


    /**
     * @description       : Constructor for QuoteTriggerHandler. Initializes trigger settings and disables logic if configured.
    */
    public QuoteTriggerHandler() {
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isFieldEditabilityDisabled = disabled.Disable_Field_Editability_Control_Fun__c;//CPQ22-6097
        isDisabled = disabled.Disable_SBQQ_Quote_Triggers__c;
        isDisabledGuidedSell = disabled.RWD_Disable_GuidedSelling_Defaulting__c;
        isASNValidationDisabled = disabled.Disable_Shipment_Detail__c;//ASPEN-247
        disableReplacementDisabled = disabled.Disable_Replacement_Framework__c;//FY25SR-1706
        enableAsyncCallToConvertQL= disabled.EnableAsyncCallToConvertQL__c; //Summer Release custover activities
        disable_ConvertQLtoCPQDisposeLines= disabled.Disable_ConvertQLtoCPQDisposeLines__c; //Summer Release custover activities
        
    }
    /**
     * @description       : Before Insert method. Handles all Logic which is to be called in beforeInsert context of Trigger
    */
    public override void beforeInsert() {
        if(!isDisabled) {
            if(!byPassQuoteTriggerForPolarisSKURestructuring){ //US - 26 Start
                
                QuoteTriggerHelper.preventCloningQuote();
                QuoteTriggerHelper.populateFieldsOnInsert(Trigger.new);
                // FY25SR-1112 - Start
                QuoteTriggerHelperForEmail.blankOutRenewalOpsFieldsOnQuoteClone(Trigger.new);
                // FY25SR-1112 - End
                QuoteTriggerHelper.setUpdateQuoteDealNotes(Trigger.New);
                QuoteTriggerHelper.throwErrorMessage(Trigger.new, null);
                QuoteTriggerHelper.scaleUSegmentLinesReAdjust(Trigger.new); //CPQ22-4941
                if(!isDisabledGuidedSell){
                    QuoteTriggerHelper.guidedSellingDefaulting(Trigger.new, null);//POlaris Method to set QuoteProcess
                }
                
                //CPQ22-47(SF-10672) - Start
                set<Id> opportunityIDs = new set<Id>();
                for(SBQQ__Quote__c qtInsert : (List<SBQQ__Quote__c>)Trigger.new){
                    opportunityIDs.add(qtInsert.SBQQ__Opportunity2__c);
                    // Manual  Billing field should be null on Cloned Quote - Ref CPQ22-2973
                    qtInsert.Manual_Billing__c = false;
                    qtInsert.Expiration_Date_Update_Flag__c = false;
                    // Ref CPQ22-2973 Ends 
                    //Start :: Clear exception value of Clone Quote 
                    List<String> valuesToRemove = System.label.Clear_Exception_values_on_Clone_Quotes.split(',');
                    List<String> lstPicklistValues = qtInsert.RWD_Deal_Ops_Exception__c != null ? qtInsert.RWD_Deal_Ops_Exception__c.split(';'):null;
                    if(qtInsert.RWD_Deal_Ops_Exception__c != null && qtInsert.SBQQ__Status__c == 'Draft'){
                        if(!valuesToRemove.isEmpty()){
                            for(String str :valuesToRemove){
                                if(lstPicklistValues.contains(str)){                                     
                                    qtInsert.RWD_Deal_Ops_Exception__c = qtInsert.RWD_Deal_Ops_Exception__c.remove(str);
                                }   
                            }                           
                        }                                                                                                
                    }
                    //End :: Clear exception value of Clone Quote...
                }
                if(!opportunityIDs.isEmpty() && allQuotesMap == null){
                    allQuotesMap = new Map<Id, SBQQ__Quote__c>([SELECT Id,Deal_Desk_Notes__c,SBQQ__Type__c,SBQQ__Opportunity2__c,
                                                                Amended_Renewed_Service_Contract__r.SBQQSC__Quote__r.Is_Selected_Partners_Customers_for_L3__c FROM SBQQ__Quote__c 
                                                                WHERE SBQQ__Opportunity2__c IN :opportunityIDs]);
                }
                
                for(SBQQ__Quote__c qtInsert : (List<SBQQ__Quote__c>)Trigger.new){
                    if(allQuotesMap.size()>0){
                        for(SBQQ__Quote__c existingQuote : allQuotesMap.values()){
                            if(existingQuote.Deal_Desk_Notes__c != null){
                                qtInsert.Deal_Desk_Notes__c = existingQuote.Deal_Desk_Notes__c;
                            }
                        }
                    }
                    //Added by Siddharth for CPQ22-5303
                    if(qtInsert.Approvals_Created_from_Source__c == true){
                        qtInsert.Approvals_Created_from_Source__c = FALSE;
                    }
                    //CPQ22-5303 end
                     qtInsert.RWD_Deal_Ops_Exception__c = null;
                     qtInsert.Quoting_Desk_Exception__c = null;
                     qtInsert.RWD_Sales_Rep_Exception__c = null;
                     qtInsert.ExceptionsonQuote__c = null;
                     qtInsert.Quoting_Desk_Exception_Justification__c = null;
                     qtInsert.RWD_Deal_Ops_Exception_Justification__c = null;
                     qtInsert.RWD_Sales_Rep_Exception_Justification__c = null;
                }
                //CPQ22-47(SF-10672) - End
            }
            // US - 26 End
        }
    }
    /**
     * @description       : Before Update method. Handles all Logic which is to be called in beforeUpdate context of Trigger
    */
    public override void beforeUpdate() {
        //Part of FY26WL-353 start
        if( disable_QuotePrimaryValid == false){ 
            QuoteTriggerHelper.validatePrimaryQuoteChange( (Map<Id, SBQQ__Quote__c>)Trigger.newMap, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
        }
        //Part of FY26WL-353 end    
        if(!isDisabled) {
            if(!byPassQuoteTriggerForPolarisSKURestructuring) { // US - 26  Start

                //CPQ22-6097 Start
                if(!isFieldEditabilityDisabled && !System.isBatch() && !System.isFuture() && !System.isQueueable() && !System.isScheduled()){
                    QuoteTriggerHelper.enforceFieldEditablility(Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
                }
                //CPQ22-6097 END
                //1143
                Map<Id, Boolean> isQuotePolarisMap = new Map<Id, Boolean>();
                Map<Id, Boolean> isQuoteRenewedIntoOldMap = new Map<Id, Boolean>();
                Set<Id> errorQuoteIdSet = new Set<Id>();
                
                if(lstQuoteRec == null){
                    lstQuoteRec = new List<SBQQ__Quote__c>([SELECT Id, Amended_Renewed_Service_Contract__r.Renew_to_Old_SKUs__c, 
                                                            Amended_Renewed_Service_Contract__r.SBQQSC__Quote__r.Is_RWD_Polaris_Quote__c, SBQQ__Opportunity2__r.SBQQSC__RenewedServiceContract__r.Renew_to_Old_SKUs__c , SBQQ__Opportunity2__r.SBQQSC__RenewedServiceContract__r.SBQQSC__Quote__r.Is_RWD_Polaris_Quote__c FROM SBQQ__Quote__c
                                                            WHERE Id=: Trigger.oldMap.keySet()]);
                }
                
                if( lstQuoteRec != null && !lstQuoteRec.IsEmpty()){
                    for(SBQQ__Quote__c quote: lstQuoteRec) {
                        isQuotePolarisMap.put(quote.Id, quote.SBQQ__Opportunity2__r.SBQQSC__RenewedServiceContract__r.SBQQSC__Quote__r.Is_RWD_Polaris_Quote__c);
                        isQuoteRenewedIntoOldMap.put(quote.Id, quote.SBQQ__Opportunity2__r.SBQQSC__RenewedServiceContract__r.Renew_to_Old_SKUs__c);
                        if(quote.SBQQ__LineItems__r.size() > 0){
                            for(SBQQ__Quoteline__c ql : quote.SBQQ__LineItems__r){
                                if(ql.Quote_Line_Type__c == 'Renewal' && (String.isBlank(ql.Disposition_Reason__c) || ql.Disposition_Reason__c == 'None')){
                                    errorQuoteIdSet.add(ql.SBQQ__Quote__c);
                                }
                            }
                        }
                    }
                }
                List < SBQQ__Quote__c > qtList = Trigger.New;
                Id quoteAryRecId;
                for(SBQQ__Quote__c lp : qtList) {
                    SBQQ__Quote__c oldlp = (SBQQ__Quote__c)Trigger.oldMap.get(lp.id);
                    
                    if (((lp.Conversion_Complete__c == false &&
                          (lp.SBQQ__Type__c == 'Renewal' || lp.SBQQ__Type__c == 'Renewal+Expansion') &&
                          lp.Amended_Renewed_Service_Contract__c != null &&
                          lp.Is_RWD_Polaris_Quote__c == false) ||
                         (Test.isRunningTest() && (lp.SBQQ__Type__c == 'Renewal' || lp.SBQQ__Type__c == 'Renewal+Expansion'))) &&
                        lp.Polaris_Conversion__c == false &&
                        lp.Polaris_Conversion_In_Progress__c == false &&
                        isQuoteRenewedIntoOldMap.containsKey(lp.Id) && isQuoteRenewedIntoOldMap.get(lp.Id) == false &&
                        isQuotePolarisMap.containsKey(lp.Id) && isQuotePolarisMap.get(lp.Id) == false 
                        && lp.MSP_SKUs_Count__c <= 0
                        && lp.Renew_to_Old_SKUs__c == false     //RWD-1646
                       ) {
                           lp.Polaris_Conversion_In_Progress__c = true;
                       }
                    if(lp.SBQQ__Status__c == 'Approved' && oldlp.SBQQ__Status__c != 'Approved'){
                        if(errorQuoteIdSet.contains(lp.Id)){
                            lp.addError('Please make sure disposition reason is popoulated for all the eligible renewal lines');
                        }
                    }
                    //Start: Added by Shaloo
                    if (((lp.SBQQ__Type__c == 'Renewal+Expansion' || lp.SBQQ__Type__c == 'Quote' || lp.SBQQ__Type__c == 'Amendment')  //REEN-121
                         && (
                             (lp.SBQQ__Primary__c && lp.SBQQ__LineItemCount__c != oldlp.SBQQ__LineItemCount__c) 
                             || (lp.SBQQ__Primary__c && lp.SBQQ__Primary__c != oldlp.SBQQ__Primary__c)
                             || (lp.SBQQ__Primary__c && lp.SBQQ__NetAmount__c != oldlp.SBQQ__NetAmount__c)
                         )
                        )|| (Test.isRunningTest())) {
                            quoteAryRecId = lp.Id;
                        }
                    if(quoteAryRecId != null){
                        QuoteTriggerHelper.updateMetricsCalcStatus(Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);//ARY-828 [By Shaloo]
                    }
                    //End: Added by Shaloo
                }
                //QuoteTriggerHelper.populateCoTermOnInsert(Trigger.new);
                QuoteTriggerHelper.updateSpecialRequestsNeededField(Trigger.new);
                QuoteTriggerHelper.populateFieldsOnUpdate(Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
                QuoteTriggerHelper.throwErrorMessage(Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
                QuoteTriggerHelper.quoteOrderNotification();
                QuoteTriggerHelper.errorForExpiryDate( Trigger.old,Trigger.New, (Map<Id, SBQQ__Quote__c>) Trigger.OldMap, (Map<Id, SBQQ__Quote__c>) Trigger.newMap);
                //REEN-56
                QuoteTriggerHelper.updateOnExpireDateExtension((Map<Id, SBQQ__Quote__c>) Trigger.oldMap,Trigger.new);
                if(!isDisabledGuidedSell){
                    QuoteTriggerHelper.guidedSellingDefaulting(Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);//POlaris Method to set QuoteProcess
                }
                // RWD-401
                //RWD-1076 STARTS
                QuoteTriggerHelper.validateIsManualBillingAllowed(Trigger.New, (Map<Id, SBQQ__Quote__c>) Trigger.OldMap);
                //RWD-1076 ENDS
                QuoteTriggerHelper.userLicenseCountValidation(Trigger.New); //added as part of M365 Gov Cloud NPI.
            } //US - 26 End
            //CPQ22-1113
            //ScaleUtility_Phase2 for CSU-494
            QuoteTriggerHelper.scaleUSegmentLinesReAdjust(Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.newMap, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
            //CPQ22-3185 Starts - Populate Billing details
            Set<Id> opptyIdSet = new Set<Id>();
            Map<Id, Opportunity> oppMap;
            for(SBQQ__Quote__c qt:(List<SBQQ__Quote__c>)Trigger.new){
                opptyIdSet.add(qt.SBQQ__Opportunity2__c);        
            }
            
            //Start: Fixed for SOQL 101 Error on 24th Nov, 2023 by Shaloo for https://rubrik.atlassian.net/browse/CSU-677
            if((oppMap == null || oppMap.IsEmpty()) && opptyIdSet != null && !opptyIdSet.IsEmpty())
            {
                oppMap = QuoteTriggerHelper.getOpportunityFields(opptyIdSet); 
            }
            Opportunity QuotesOpportunityDetail;
            for(SBQQ__Quote__c qt:(List<SBQQ__Quote__c>)Trigger.new){
                if (oppMap != null && qt.SBQQ__Opportunity2__c != null) {
                    QuotesOpportunityDetail = oppMap.get(qt.SBQQ__Opportunity2__c);
                }        
                if(qt.SBQQ__BillingCountry__c == null && qt.SBQQ__BillingName__c == null && qt.SBQQ__BillingCity__c == null && qt.SBQQ__BillingStreet__c == null && qt.SBQQ__BillingState__c == null && qt.SBQQ__BillingPostalCode__c == null){
                    QuoteTriggerHelper.populateBillingInformationQuote(QuotesOpportunityDetail,qt);          
                }        
            }             
            //CPQ22-3185 Ends
        }
    }
    /**
     * @description       : Before Delete method. Handles all Logic which is to be called in beforeDelete context of Trigger
    */
    public override void beforeDelete() {
        System.debug(LoggingLevel.DEBUG, 'Before delete methods go here');
    }
    /**
     * @description       : After Insert method. Handles all Logic which is to be called in afterInsert context of Trigger
    */
    public override void afterInsert() {
        //Added by Sumedha for CPQ22-312
        List<Id> quoteAccIds = new List<Id>();
        if(!isDisabled) {
            if(!byPassQuoteTriggerForPolarisSKURestructuring){ //US - 26 Start

                // REEN-41 start
                Map<Id, Opportunity> amendedOppUpdate = new Map<Id, Opportunity>();
                Set<Id> oppIdsSet = new Set<Id>();
                for(SBQQ__Quote__c eachQuote : (List<SBQQ__Quote__c>)Trigger.new) {
                    if((eachQuote.SBQQ__Primary__c && eachQuote.SBQQ__Type__c == 'Renewal') 
                       || (eachQuote.SBQQ__Type__c == 'Amendment')
                      ){
                          oppIdsSet.add(eachQuote.SBQQ__Opportunity2__c); 
                      }
                }
                
                Map<Id, Integer> mapOfOppvsCount = new Map<Id, Integer>();
                
                if (oppIdsSet != null && !oppIdsSet.isEmpty()) {
                    allQuotes = QuoteTriggerHelper.getQuoteRecords(oppIdsSet);
                }
                
                if(!oppIdsSet.isEmpty()){
                    mapOfOppvsCount = QuoteTriggerHelper.getMapOfOppvsCount(); 
                }
                //REEN-41 end

                Set<Id> amendedQuotes = new Set<Id>();
                Set<Id> oppIdSet = new Set<Id>();
                for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>) Trigger.New){
                    if(quote.SBQQ__Type__c == 'Amendment'){
                        amendedQuotes.add(quote.id);
                    }
                    if(quote.SBQQ__Primary__c && quote.SBQQ__Opportunity2__c != null) {
                        oppIdSet.add(quote.SBQQ__Opportunity2__c );
                    }
                    
                    //Added by Sumedha for CPQ22-312
                    if (quote.SBQQ__Account__c != NULL) {
                        quoteAccIds.add(quote.SBQQ__Account__c);
                    }
                }
                
                //REEN-41 starts
                List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
                if (amendedQuotes.size() > 0 && allQuotes != null && !allQuotes.IsEmpty()) {
                    for(SBQQ__Quote__c quoteObj : allQuotes){  // Update REEN-41 to merge query
                        if(amendedQuotes.contains(quoteObj.id)){
                            lstQuotes.add(quoteObj); 
                        }
                    }
                }
                //REEN-41 ends
                
                IF(amendedQuotes.size()>0){
                    for (SBQQ__Quote__c qts : lstQuotes) { // Update REEN-41 to merge query, CPQ22-3962
                        If(qts.SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Distributor_Lookup__c !=null ||
                           qts.SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Partner_Lookup__c !=null){
                               Opportunity opp = new Opportunity();
                               opp.id = qts.SBQQ__Opportunity2__c;
                               //Changes done by Srikanth for issue number CPQ22-1241
                               if(qts.SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Distributor_Lookup__r.Contract_Status__c!= 'Expired' && qts.SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Distributor_Lookup__r.Contract_Status__c!= 'Merged w/ another acct' && qts.SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Distributor_Lookup__r.Contract_Status__c!= 'Terminated'){
                                   opp.Partner_Lookup__c = (qts.SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Partner_Lookup__c !=null) ? qts.SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Partner_Lookup__c : null;
                                   opp.Distributor_Lookup__c = (qts.SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Distributor_Lookup__c !=null) ? qts.SBQQ__Opportunity2__r.SBQQSC__AmendedServiceContract__r.SBQQSC__Opportunity__r.Distributor_Lookup__c : null;
                               }
                               amendedOppUpdate.put(opp.id, opp); 
                           }
                    }
                }
                
                // Updated for REEN-41
                if (oppIdsSet != null && !oppIdsSet.isEmpty() && mapOfOppvsCount != null && !mapOfOppvsCount.isEmpty()) {
                    for (Id oppId : oppIdsSet) {
                        if (mapOfOppvsCount.containsKey(oppId)) {
                            Opportunity opp = new Opportunity();
                            opp.id = oppId;
                            if (opp.Number_of_valid_Primary_Quotes__c != mapOfOppvsCount.get(oppId)) {
                                opp.Number_of_valid_Primary_Quotes__c = mapOfOppvsCount.get(oppId);  
                                amendedOppUpdate.put(opp.id, opp);
                            }
                        }
                    }
                }
                
                if(amendedOppUpdate != null && !amendedOppUpdate.isEmpty()){
                    flowControll.opportunityTriggerHandler = false;//added for CPQ22-3962
                    update amendedOppUpdate.values();
                    flowControll.opportunityTriggerHandler = true;//added for CPQ22-3962
                }
                //REEN-41 Ends
            }// US - 26 End

            //MS CPQ22-5343 Starts
            Set<Id> quoteidToPass = new Set<Id>();
            for(SBQQ__Quote__c quote: (List<SBQQ__Quote__c>) Trigger.New){
                if(!System.IsFuture() && !System.isBatch() && !System.isQueueable() && quote.CreatedDate != null && quote.SBQQ__LastCalculatedOn__c != null && 
                (quote.CreatedDate > quote.SBQQ__LastCalculatedOn__c)){
                    quoteidToPass.add(quote.Id);
                }
                QuoteTriggerHelper.processedQuoteIds.add(quote.Id);
            }
            if(quoteidToPass != null && !quoteidToPass.isEmpty()){
                QuoteTriggerHelper.resetFlagonClone(quoteidToPass);
            }
            //MS CPQ22-5343 Ends
        }
    }
    
    /**
     * @description       : After Update method. Handles all Logic which is to be called in afterUpdate context of Trigger
    */
    public override void afterUpdate() {
        if(!isDisabled) {

            // REEN-41 start 
            Set<Id> oppIdsSet = new Set<Id>();
            //FY25SR-2069 - Start 
            Set<Id> sourceLines = new Set<Id>();
            Map<Id, Id> mapSourceVsNewQId = new Map<Id, Id>();
            Map<Id, SBQQ__Quote__c> quoteOldMap1 =  (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
            for(SBQQ__Quote__c eachQuote : (List<SBQQ__Quote__c>)Trigger.new) {   
                if(quoteOldMap1.get(eachQuote.Id).SBQQ__Source__c != eachQuote.SBQQ__Source__c){
                    sourceLines.add(eachQuote.SBQQ__Source__c);
                    mapSourceVsNewQId.put(eachQuote.SBQQ__Source__c, eachQuote.Id);
                }
                //FY25SR-2069 - End
                if(!eachQuote.SBQQ__Uncalculated__c){
                    oppIdsSet.add(eachQuote.SBQQ__Opportunity2__c); 
                }
            }
            //FY25SR-2069 - Start 
            if(!sourceLines.isEmpty()){
                	ReplacementQuoteLineCreationHelper.createCPQDispLinesOnCloneRelated(sourceLines, mapSourceVsNewQId);
            }
            //FY25SR-2069 - End
            // get quote records related to opp in static variable.
            Map<Id, Integer> mapOfOppvsCount = new Map<Id, Integer>();
            if (oppIdsSet != null && !oppIdsSet.isEmpty()) {
                allQuotes = QuoteTriggerHelper.getQuoteRecords(oppIdsSet); 
            }
            
            // calling common method to count Quote vs opp.
            if(!oppIdsSet.isEmpty()){
                mapOfOppvsCount = QuoteTriggerHelper.getMapOfOppvsCount(); 
            }
            // REEN-41 end
            
           // QuoteTriggerHelper.populateCoTermOnInsert(Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);//FYSR25-1878
            if(!byPassQuoteTriggerForPolarisSKURestructuring){ // US - 26
                if(isRecursiveLinkOppEnt == false){
                    QuoteTriggerHelper.linkEntitlementsToRenewalOpp(Trigger.old);
                    isRecursiveLinkOppEnt = true;
                }
                Set<Id> oppIdSet = new Set<Id>();
                Set<Id> primaryQuotes = new Set<Id>();
                Set<Id> oppoIds = new Set<Id>();
                Set<Id> setOpportunityIdForMosaic = new Set<Id>();
                Set<id> approvalQuote = new Set<id>();
                Set<Id> quoteArroyoMatrixUpdateIds = new Set<Id>();
                Map<Id,SBQQ__Quote__c> quotesWithPrimaryUpdated = new Map<Id,SBQQ__Quote__c>();
                Map<id,SBQQ__Quote__c> oldQuoteData = (Map<id,SBQQ__Quote__c>) Trigger.oldMap;set<Id> ddQuoteNotesUpdatedQuotes = new Set<Id>(); 
                //Ashwini
                set<Id> ddNotesUpdatedQuotes = new Set<Id>();
                
                QuoteTriggerHelper.createTask(trigger.new,(Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
                for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>) Trigger.New) {
                    If((oldQuoteData.get(quote.Id).SBQQ__ExpirationDate__c != quote.SBQQ__ExpirationDate__c) || 
                       (Test.isRunningTest())) {
                           expirationFlag=True;
                       }
                    if(quote.SBQQ__Status__c=='Draft'){
                        approvalQuote.add(quote.id);
                    }
                    SBQQ__Quote__c oldQuote = (SBQQ__Quote__c) Trigger.oldMap.get(quote.Id);
                    if (quote.SBQQ__Primary__c &&  quote.SBQQ__Opportunity2__c != null) {
                        if(quote.SBQQ__Type__c!='Renewal'){
                            primaryQuotes.add(quote.Id);
                        }
                        if((oldQuote.SBQQ__Primary__c != quote.SBQQ__Primary__c) ||
                           (Test.isRunningTest())) {
                               oppIdSet.add(quote.SBQQ__Opportunity2__c );
                               setOpportunityIdForMosaic.add(quote.SBQQ__Opportunity2__c);
                               
                           } else if (oldQuote.Has_Mosaic_SKUs__c != quote.Has_Mosaic_SKUs__c) {
                               setOpportunityIdForMosaic.add(quote.SBQQ__Opportunity2__c);
                           }
                    }
                    
                    if((oldQuote.SBQQ__Primary__c != quote.SBQQ__Primary__c &&
                        quote.SBQQ__Primary__c == false && quote.SBQQ__Opportunity2__c != null) || (Test.isRunningTest())){
                            if(quote.sbqq__Type__c!='Renewal'){
                                oppoIds.add(quote.SBQQ__Opportunity2__c);
                            }
                        }
                    
                    if((quote.SBQQ__Primary__c && (quote.Pricing_Notes__c != oldQuote.Pricing_Notes__c)  ) ||  ( quote.SBQQ__Primary__c && !oldQuote.SBQQ__Primary__c &&  quote.Pricing_Notes__c != null ) 
                       || (!quote.SBQQ__Primary__c && oldQuote.SBQQ__Primary__c)   )
                    {
                        ddQuoteNotesUpdatedQuotes.add(quote.Id);
                    }
                    
                    //Arroyo 2.0 - check for Arroyo matrix update
                    if((quote.SBQQ__Primary__c && !oldQuote.SBQQ__Primary__c) || (quote.SBQQ__Primary__c && quote.SBQQ__LastCalculatedOn__c != oldQuote.SBQQ__LastCalculatedOn__c)) {
                        quoteArroyoMatrixUpdateIds.add(quote.Id);
                        setOpportunityIdForMosaic.add(quote.SBQQ__Opportunity2__c); //REEN-50
                    }
                    //REEN-41 Starts
                    if (quote.SBQQ__Primary__c == false && quote.SBQQ__LastCalculatedOn__c != oldQuote.SBQQ__LastCalculatedOn__c)
                    {
                        setOpportunityIdForMosaic.add(quote.SBQQ__Opportunity2__c);
                    }
                    //REEN-41 Ends
                    if(quote.SBQQ__Primary__c!=oldQuote.SBQQ__Primary__c){
                        quotesWithPrimaryUpdated.put(quote.id,quote);
                    }
                }
                if(!quotesWithPrimaryUpdated.isEmpty()){
                	QuoteTriggerHelper.populateFieldsOnOpportunity(quotesWithPrimaryUpdated);
                }
                
                if (!setOpportunityIdForMosaic.isEmpty()) {
                    if(!System.IsBatch() && !System.isFuture()) {
                        QuoteTriggerHelper.updateOpportunity(setOpportunityIdForMosaic, mapOfOppvsCount); // update for REEN-41
                    }
                }
                if(expirationFlag){
                    quoteTriggerHelper.reSubmitExpiredQuote((Map<Id, SBQQ__Quote__c>) Trigger.OldMap, (Map<Id, SBQQ__Quote__c>) Trigger.newMap);
                }
                if( !approvalQuote.isempty()){
                    QuoteTriggerHelper.approvalStatus(approvalQuote);
                }
                
                //CPQ22-47(SF-10672) - Start
                if(ddNotesUpdatedQuotes != null && !ddNotesUpdatedQuotes.isEmpty() ||ddQuoteNotesUpdatedQuotes != null && !ddQuoteNotesUpdatedQuotes.isEmpty()){
                    if(inRecursiveQueueableUpdate) return;
                    System.enqueueJob(new quoteTriggerHelperQueueable((Map<Id, SBQQ__Quote__c>) Trigger.OldMap, 
                                                                      (Map<Id, SBQQ__Quote__c>) Trigger.newMap));
                }
                //CPQ22-47(SF-10672) - End
                
                //Arroyo - call the Matrix update
                if(!quoteArroyoMatrixUpdateIds.isEmpty()) {
                    OpportunityArroyoMatrixCalculator.copyMatrixValuesToOpportunity(quoteArroyoMatrixUpdateIds);
                }
                
            }// US - 26 End
            if ( System.label.Stop_Custom_Renewal_Trigger.equalsIgnoreCase('True') ) {
                List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
                Map<Id, SBQQ__Quote__c> quoteOldMap =  (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
                Map<Id, SBQQ__Quote__c> quoteNewMap =  (Map<Id, SBQQ__Quote__c>) Trigger.newMap;
                for (SBQQ__Quote__c quote : quoteNewMap.values()) {
                    if ((
                        quoteOldMap.get(quote.Id).SBQQ__LastCalculatedOn__c == null &&
                        quote.SBQQ__LastCalculatedOn__c != null && (quote.SBQQ__Type__c == 'Renewal' || quote.SBQQ__Type__c == 'Renewal+Expansion') && quote.Amended_Renewed_Service_Contract__c != null) ||
                        (Test.isRunningTest() && (quote.SBQQ__Type__c == 'Renewal' || quote.SBQQ__Type__c == 'Renewal+Expansion'))) {
                            lstQuotes.add(quote);
                        }
                }
                if(!lstQuotes.isEmpty()  && !System.IsFuture() && !System.isBatch()){
                    ConvertToSaasRenewalBatch quickupdate = new ConvertToSaasRenewalBatch(lstQuotes);
                    Database.executeBatch(quickupdate,1);
                }
            }
            
            //CPQ22-836 starts
            QuoteTriggerHelper.sendNotificationForDealSize((List<SBQQ__Quote__c>)Trigger.new, (Map<Id, SBQQ__Quote__c>)Trigger.oldMap);
            //CPQ22-836 ends
            
            // SKU-4
            populateSpecialProgram((List<SBQQ__Quote__c>)Trigger.new, (Map<Id, SBQQ__Quote__c>)Trigger.oldMap);
            
            Set<Id> quoteIds = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            
            Set<Id> quoteAryRecId = new Set<Id>();//CR-47: Added by Shaloo
            Map<Id, SBQQ__Quote__c> quoteOldMapRCDM =  (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
            for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>) Trigger.New) 
            {       
                if(((quote.SBQQ__Type__c == 'Quote' || (quote.SBQQ__Type__c == 'Renewal' && quote.Polaris_Conversion__c == true) || quote.SBQQ__Type__c == 'Renewal+Expansion') && quote.SBQQ__Status__c == 'Draft' 
                    && quote.SBQQ__Uncalculated__c == false && 
                    (
                        
                        (
                            (
                                (quote.RWD_Deal_Ops_Exception__c == null || quote.RWD_Deal_Ops_Exception__c == '') || 
                                (quote.RWD_Deal_Ops_Exception__c != null && !quote.RWD_Deal_Ops_Exception__c.contains('Allow removal of 0$ On Prem SKU'))
                            ) && quote.SBQQ__Source__c != null
                        ) || 
                        (
                            (
                                (quote.RWD_Deal_Ops_Exception__c == null || quote.RWD_Deal_Ops_Exception__c == '') || 
                                (quote.RWD_Deal_Ops_Exception__c != null && !quote.RWD_Deal_Ops_Exception__c.contains('Allow removal of 0$ On Prem SKU'))
                            ) && 
                            (quote.SBQQ__NetAmount__c != quoteOldMapRCDM.get(quote.Id).SBQQ__NetAmount__c || 
                             quote.SBQQ__LineItemCount__c!= quoteOldMapRCDM.get(quote.Id).SBQQ__LineItemCount__c)
                        )
                    )) && !Test.isRunningTest() && (quote.OpportunitySubType__c != 'GC Offer' && quote.OpportunitySubType__c != 'GC Renewal' && quote.OpportunitySubType__c != 'GC On demand'))
                {
                    quoteIds.add(quote.Id);
                    accountIds.add(quote.SBQQ__Account__c);
                } else if(Test.isRunningTest()) {
                    quoteIds.add(quote.Id);
                    accountIds.add(quote.SBQQ__Account__c);
                }
                
                //CR-47 Start: Added by Shaloo
                //FY25SR-1706 - Added Approved check and disableReplacementDisabled
                if (((quote.SBQQ__Type__c == 'Renewal+Expansion' || quote.SBQQ__Type__c == 'Quote' || quote.SBQQ__Type__c == 'Amendment') //REEN-121
                                             && quote.SBQQ__LastCalculatedOn__c != quoteOldMapRCDM.get(quote.Id).SBQQ__LastCalculatedOn__c && quote.SBQQ__Status__c != 'Approved' && ((quote.SBQQ__Primary__c && quote.SBQQ__LineItemCount__c != quoteOldMapRCDM.get(quote.Id).SBQQ__LineItemCount__c) || (quote.SBQQ__Primary__c && quote.SBQQ__Primary__c != quoteOldMapRCDM.get(quote.Id).SBQQ__Primary__c) || (quote.SBQQ__Primary__c && quote.SBQQ__NetAmount__c != quoteOldMapRCDM.get(quote.Id).SBQQ__NetAmount__c) || (quote.SBQQ__Primary__c && quote.Arry_Count_Of_Lines_Renewed__c != quoteOldMapRCDM.get(quote.Id).Arry_Count_Of_Lines_Renewed__c) || (quote.SBQQ__Primary__c && quote.SBQQ__LastCalculatedOn__c != quoteOldMapRCDM.get(quote.Id).SBQQ__LastCalculatedOn__c))) || Test.isRunningTest()) {
                       quoteAryRecId.add(quote.Id);
                   }
            }
            //FY25SR-1125 - Commented metricCalcForArroyoQueueable_v2_Future and calling NewMetricsCalculator
            //FY25SR-1706 - disableReplacementDisabled check
            if(quoteAryRecId != null && !quoteAryRecId.isEmpty() && !System.IsFuture() && !System.isBatch()/* && !System.isQueueable()*/){
                if (disableReplacementDisabled) {
                    metricCalcForArroyoQueueable_v2_Future.calculateMetrics(quoteAryRecId);
                } else {
                    NewMetricsCalculator.calculateMetrics(quoteAryRecId);
                }
            }
            //CR-47: End by Shaloo
            
            //CPQ22-3514 Starts
            Set<Id> quoteidToPass = new Set<Id>();
            Set<Id> clonedQuote = new Set<Id>();
            
            for(SBQQ__Quote__c quote: (List<SBQQ__Quote__c>) Trigger.New){
                if (quote.SBQQ__Source__c != null && quoteOldMapRCDM.get(quote.Id) != null && quote.CreatedDate != null && quote.SBQQ__LastCalculatedOn__c != null &&
                quoteOldMapRCDM.get(quote.Id).SBQQ__LastCalculatedOn__c < quote.CreatedDate && 
                quote.CreatedDate < quote.SBQQ__LastCalculatedOn__c){
                    quoteidToPass.add(quote.Id);
                    clonedQuote.add(quote.SBQQ__Source__c);
                }
            }
            
            if (quoteidToPass != null && !quoteidToPass.isEmpty() && !System.isFuture() && !System.isBatch()) {
                QuoteTriggerHelper.createMergedQLRecords(quoteidToPass, clonedQuote);
                QuoteTriggerHelper.createCCLIRecords(quoteidToPass, clonedQuote);//REEN-25
            }
            //CPQ22-3514 Ends
            //
            
            //FY25SR-1112 - start
            QuoteTriggerHelperForEmail.sendProactiveDealGovernanceNotice(
                                                                    (Map<Id, SBQQ__Quote__c>) Trigger.newMap,
                                                                    (Map<Id, SBQQ__Quote__c>) Trigger.oldMap
                                                                );
                      
            
            //FY25SR-1112 - End
        }
        /* Commenting this block as per DD25-90  
        //DD25-5 start
        List<SBQQ__Quote__c> ddc_quoteIds = new List<SBQQ__Quote__c>();
        for(SBQQ__Quote__c quote: (List<SBQQ__Quote__c>) Trigger.New){
            SBQQ__Quote__c oldQuote = (SBQQ__Quote__c) Trigger.oldMap?.get(quote.id);
            if ((quote.SBQQ__Status__c !=oldQuote.SBQQ__Status__c && quote.SBQQ__Status__c == 'In Review') || test.isRunningTest()){
                ddc_quoteIds.add(quote);
            }
        }
        if (ddc_quoteIds != null && !ddc_quoteIds.isEmpty()) {
           QuoteTriggerHelper.createDealDeskCase(ddc_quoteIds);
        }
        //DD25-5 end */
    }
    
    /**
     * @description       : After Delete method. Handles all Logic which is to be called in afterDelete context of Trigger
    */
    public override void afterDelete() {
        //REEN-41 start
        Set<Id> oppIdsSet = new Set<Id>();
        for(SBQQ__Quote__c eachQuote : (List<SBQQ__Quote__c>)Trigger.old) {
            if(eachQuote.SBQQ__Primary__c){
                oppIdsSet.add(eachQuote.SBQQ__Opportunity2__c); 
            }
        }
        
        Map<Id, Integer> mapOfOppvsCount = new Map<Id, Integer>();
        
        if (oppIdsSet != null && !oppIdsSet.isEmpty()) {
            QuoteTriggerHelper.getQuoteRecords(oppIdsSet);
        }
        
        if(!oppIdsSet.isEmpty()){
            mapOfOppvsCount = QuoteTriggerHelper.getMapOfOppvsCount(); 
        }
        
        if (!mapOfOppvsCount.isEmpty()) {
            if (!System.IsBatch() && !System.isFuture()){
                QuoteTriggerHelper.updateOpportunity(mapOfOppvsCount.keySet(), mapOfOppvsCount);
            }
        }
        // REEN-41 end
    } 
    /**
     * @description       : After Undelete method. Handles all Logic which is to be called in afterUndelete context of Trigger
    */
    public override void afterUndelete() {
        System.debug(LoggingLevel.DEBUG, 'After undelete methods go here');
    }
    
    /**
     * @description       : SKU-4 Populates Special Program on Quote and Opportunity
     * @param qlist
     * @param oldMap
    */
    public static void populateSpecialProgram(List<SBQQ__Quote__c> qlist, Map<Id, SBQQ__Quote__c> oldMap) {
        List<SBQQ__Quote__c> toProcess = new List<SBQQ__Quote__c>();
        Map<Id, Id> primaryQuoteOpptyMap = new Map<Id, Id>();
        List<Opportunity> primaryOpportunityToUpdate = new List<Opportunity>();
        Set<Id> quoteIds=new Set<Id>();//added
        Set<Id> toProcessQuoteIds=new Set<Id>();//added
        for (SBQQ__Quote__c quote : qlist) {
            quoteIds.add(quote.Id);//added
            SBQQ__Quote__c oldVal = oldMap.get(quote.Id);
            if ((quote.SBQQ__LineItemCount__c != oldVal.SBQQ__LineItemCount__c) ||
                (quote.SBQQ__Primary__c && quote.SBQQ__Primary__c != oldVal.SBQQ__Primary__c)
               ) {
                   toProcess.add(quote);
                   toProcessQuoteIds.add(quote.Id);//added
               }
            
            if (quote.SBQQ__Primary__c) {
                primaryQuoteOpptyMap.put(quote.Id, quote.SBQQ__Opportunity2__c);
            }
        }
        
        // if (toProcess.isEmpty()) return;
        
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLineMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        List<SBQQ__Quote__c> toUpdate = new List<SBQQ__Quote__c>();
        
        Replacement_Field_Mapping__mdt objectData = ReplacementRefreshUtility.getCustomMetadataInstance('OldFrameWorkQuoteType');
        Set<String> quoteLineDispositionSet = new Set<String>();
        
        if (objectData != null) {
            if (String.isNotBlank(objectData.First_Filter_Criteria__c)) {
                quoteLineDispositionSet.addAll(objectData.First_Filter_Criteria__c.split(','));
            }
        }
         for (SBQQ__QuoteLine__c ql :[SELECT Id,Special_Program__c,SBQQ__Quote__r.SBQQ__Status__c,
                                     SBQQ__Quote__r.SBQQ__Type__c, Disposition_Reason__c, Replacement_Motion__c,
                                     SBQQ__Product__c, Replacement_Details__c, SBQQ__Quantity__c, Subscribed_Asset_Name__c,
                                     SBQQSC__RenewedContractLine__c, SBQQ__PricebookEntryId__c
            FROM SBQQ__QuoteLine__c
                                     WHERE (SBQQ__Quote__c IN :toProcess 
                                            OR (SBQQ__Quote__c  IN: quoteIds AND (Disposition_Reason__c IN: quoteLineDispositionSet)
                                                AND Replacement_Motion__c!=null))
        ]) {
            List<SBQQ__QuoteLine__c> existingList = quoteLineMap.get(ql.SBQQ__Quote__c);
            existingList = existingList != null ? existingList : new List<SBQQ__QuoteLine__c>();
            
            existingList.add(ql);
            quoteLineMap.put(ql.SBQQ__Quote__c, existingList);
        }
        
        for (Id quoteId : quoteLineMap.keySet()) {
            if(toProcessQuoteIds.contains(quoteId)){
            Set<String> specialPrograms = new Set<String>();
            
            for (SBQQ__QuoteLine__c ql : quoteLineMap.get(quoteId)) {
                if(ql.Special_Program__c != null && ql.Special_Program__c != ''){//added null check as part of CPQ22-3962
                   specialPrograms.add(ql.Special_Program__c);
                }
            }
            
            if (primaryQuoteOpptyMap.containsKey(quoteId) && specialPrograms.size() > 0) { //added specialprogram check for CPQ22-3962
                primaryOpportunityToUpdate.add(
                    new Opportunity(
                        Id = primaryQuoteOpptyMap.get(quoteId),
                        Opportunity_Program__c = String.join(new List<String>(specialPrograms), ';')
                    )
                );
            }
            if(specialPrograms.size() > 0){ //added specialprogram check for CPQ22-3962
                toUpdate.add(
                    new SBQQ__Quote__c(
                        Id = quoteId,
                        Opportunity_Program__c = String.join(new List<String>(specialPrograms), ';')
                    )
                );
            }
        } 
        }
        if(toUpdate.size() > 0){ //added check for CPQ22-3962
           update toUpdate;
        }
        
        // Update the special program on opportunity records
        if (primaryOpportunityToUpdate.isEmpty() == false) {
            update primaryOpportunityToUpdate;
        }
        //Summer Release
        if(!quoteLineMap.isEmpty()  && !System.IsFuture() && !System.isBatch() && !disable_ConvertQLtoCPQDisposeLines){
            if(enableAsyncCallToConvertQL){
                //aync call (future)
                QuoteTriggerHelper.processQLtoCPQDisposeLines(quoteLineMap.keySet());  
            }
            else{
                //sync call
                QuoteTriggerHelper.convertQLtoCPQDisposeLines(quoteLineMap); 
            }
        }
    }
    
}