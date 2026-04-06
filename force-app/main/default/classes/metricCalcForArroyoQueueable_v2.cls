/**Queuebale class for metric Calculation */
public class metricCalcForArroyoQueueable_v2 implements Queueable{ 
    /**qtList */
    public Map<Id, SBQQ__Quote__c> qtList;
    /**qtOldMap */ 
    public Map<Id, SBQQ__Quote__c> qtOldMap;
    /**quoteId */ 
    Set<Id> quoteId; 
    
    /**Constructor */
    public metricCalcForArroyoQueueable_v2 (Set<Id> QuoteId){
        this.quoteId = QuoteId;
    }
    
    /**execute method */
    public void execute (QueueableContext context){
        system.debug('**Execute Metrics**');
        metricCalcForArroyoQueueable_v2.calculateMetrics(quoteId);
    }
    
    /**calculateMetrics */
    public static void calculateMetrics(Set<Id> quoteId){
        system.debug('calculateMetrics Method: ' + quoteId.size());
        
        List<SBQQ__Quote__c> allQuotes = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quoteToUpdate = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quoteToUpdateBeforeCalc = new List<SBQQ__Quote__c>();
        List<SBQQ__QuoteLine__c> qliListToUpdateBeforeCalc = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> qliListToUpdate = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> lstRenewalQLIs = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> lstExpansionQLIs = new List<SBQQ__QuoteLine__c>();
        Set<String> sccRenewalQLI = new Set<String>();
        Set<String> sccExpansionQLI = new Set<String>();
        Set<String> lstRefreshedAssetNames;
        Set<String> lstSubAssetNames;
        Set<String> lstSubAssetNamesRBK;
        Set<String> lstAllMatchedAssetNames;
        Set<Id> quoteIds = new Set<Id>();
        Map<Id, SBQQ__QuoteLine__c> qliListToUpdateBeforeCalcMap = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> qliListToUpdateMap = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, List<SBQQ__QuoteLine__c>> mapRenewalQLIs = new Map<Id, List<SBQQ__QuoteLine__c>>();
        Map<Id, List<SBQQ__QuoteLine__c>> mapExpansionQLIs = new Map<Id, List<SBQQ__QuoteLine__c>>();
        Map<String, List<Sales_Comp_Category_Mapping__mdt>> mapSCCVsObjRecList = new Map<String, List<Sales_Comp_Category_Mapping__mdt>>();
        Map<String, Sales_Comp_Category_Mapping__mdt> mapSCCVsObjRec = new Map<String, Sales_Comp_Category_Mapping__mdt>();
        Map<Id, Boolean> RenewalQLSubStae = new Map<Id, Boolean>();
        Map<Id, Decimal> RenewalQLSubAmount = new Map<Id, Decimal>();
        Map<String, String> mapSubAssetVsRenCLI = new Map<String, String>();
        Map<String, String> mapSCCVsRenCLI = new Map<String, String>();
        Map<String, Decimal> mapReplaceProdCodeVsNewLineCount = new Map<String, Decimal>();
        Map<Id, SBQQ__QuoteLine__c> qltoUpdate2 = new Map<Id, SBQQ__QuoteLine__c>();
        Map<String, SBQQ__QuoteLine__c> mapProductCodeVsLineType = new Map<String, SBQQ__QuoteLine__c>();
        Map<String, SBQQ__QuoteLine__c> mapReqProductCodeVsLineType = new Map<String, SBQQ__QuoteLine__c>();
        String tempSCCategory = '';
        Boolean isDispositionReasonMissing = false;
        Boolean setHasChurnAtQuote = false;
        Decimal renewalAmtForRenewingQLI;
        Decimal rtaAmount;
        Decimal rtaAmountQLI;
        Decimal maxRenewalAmt, upliftedPriorACVToBeRemoved;
        Decimal priorACV, rtaToBeRemoved;
        Decimal newSaleNetTotal = 0;
        Decimal expTotalSubsumedAmt = 0;
        Decimal renewalACV = 0;
        Decimal qliExpACV = 0;
        Decimal expansionACV;
        Decimal tempRenewalACV;
        Decimal totSubAmt;
        Decimal grossChurn;
        Decimal renewalGrowthQLI = 0;
        Decimal renewalGrowthExpQLI;
        Decimal counter;
        Decimal tempReplaceQLICount = 0;
        quoteIds = quoteId;
        Set<String> processedOldCLI = new Set<String>();
        Map<Id, Integer> mapRenLinevsAssetCount = new Map<Id, Integer>();//CPQ22-3650
        Set<String> assetnamenonExp = new Set<String>();
        Set<Id> renewalLines = new Set<Id>();//Added for CPQ22-4693
        Map<Id, Merged_Quote_Line__c> mqlRecs = new Map<Id, Merged_Quote_Line__c>();//Added for CPQ22-4693
        
        if(quoteId != null && !quoteId.IsEmpty()){
            allQuotes = [SELECT Id, Name, SBQQ__Type__c, PriorACV__c, RTA__c, MaxRenAmt__c, TotalACV__c, RenACV__c, ExpACV__c, RenSubACV__c, GrossChurn__c, GrossChurnRate__c, RenGrowth__c, RenExpGrowth__c, NetChurnRate__c, MetricCalcStatus__c, MetricsLastCalcOn__c, HasChurn__c,(SELECT Id,SBQQ__Quote__c, SBQQ__ProductCode__c, SBQQ__RenewedAsset__c, SBQQ__Quantity__c, Quote_Line_Type__c, Disposition_Reason__c, RenGrowth__c, SubsRenAmt__c, Arroyo_Subscribed_Asset_Name__c, SBQQ__NetTotal__c, ACV__c, ExpACV__c, RTAwithoutUplift__c, PriorACVwithUplift__c, SBQQSC__RenewedContractLine__c, SubscribedAssetNames__c, Sales_Comp_Category__c, Arroyo_Subsumed_Old_Contract_Line_Items__c, ChurnAmt__c, Prior_Net_Total_With_Uplift__c, CCLI__c, Special_Program__c, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.SubscribedAssetNames__c, SBQQ__Product__c, Subscribed_Asset_Name__c, SBQQ__Group__c, Is_Approval_Needed_for_Disposition_Lines__c, SBQQ__RequiredBy__r.SBQQ__ProductCode__c, Product_Level__c, Product_Type__c, SBQQ__RequiredBy__r.Product_Level__c, SBQQ__EndDate__c, Replace_By__c, SubsAstNameInt__c, IsDeleted, SBQQ__Product__r.ExcExpACV__c FROM SBQQ__LineItems__r WHERE Product_Type__c != 'Hardware' LIMIT 25000) FROM SBQQ__Quote__c WHERE Id =: quoteId LIMIT 25000];}//REEN-121 added SBQQ__Product__r.ExcExpACV__c
        
        if(allQuotes != null && !allQuotes.IsEmpty()){
            //added by madhura to fix Expiredasset conversion
            for(SBQQ__Quote__c quote : allQuotes){
                SBQQ__Quote__c existingQuote = allQuotes[0];
                for(SBQQ__QuoteLine__c qli: existingQuote.SBQQ__LineItems__r){
                    String subsAssetName = String.isNotBlank(qli.SubscribedAssetNames__c) ? qli.SubscribedAssetNames__c: qli.SubsAstNameInt__c;
                    if( qli.Quote_Line_Type__c == 'Renewal' && String.isNotBlank(subsAssetName) && qli.Arroyo_Subscribed_Asset_Name__c == null ){
                            for(String assetName : subsAssetName.split(',')){
                                assetName = assetName.trim();
                                assetnamenonExp.add(assetName);
                                
                            }
                    }
                    //Added for CPQ22-4693
                    if (qli.Quote_Line_Type__c == 'Renewal' && qli.Sales_Comp_Category__c != null && qli.Special_Program__c != 'Conversion') {
                        renewalLines.add(qli.Id);
                    }//Ends
                    
                }
            }
            
          //Added for CPQ22-4693
          if (renewalLines != null && !renewalLines.isEmpty()) {
            List<Merged_Quote_Line__c> mqlList = [Select Id, New_Quote_Line__c, Merged_Renewal_Quote_Line__c from Merged_Quote_Line__c where Merged_Renewal_Quote_Line__c IN : renewalLines];
            if (mqlList != null && !mqlList.isEmpty()) {
                for (Merged_Quote_Line__c mql : mqlList) {
                    if (mql.New_Quote_Line__c != null && mql.Merged_Renewal_Quote_Line__c != null) {
                        mqlRecs.put(mql.New_Quote_Line__c, mql);
                    }
                }
            }
          }//Ends
            
            
            for(SBQQ__Quote__c quote : allQuotes){
                SBQQ__Quote__c existingQuote = allQuotes[0];
                for(SBQQ__QuoteLine__c qli: existingQuote.SBQQ__LineItems__r){
                    if(qli.Quote_Line_Type__c == 'New'){
                        qli.RenGrowth__c = null;
                        qli.SubsRenAmt__c = null;
                        qli.ExpACV__c = null;
                        qli.ChurnAmt__c = null;
                       
                        String subsAssetName = String.isNotBlank(qli.Arroyo_Subscribed_Asset_Name__c) ? qli.Arroyo_Subscribed_Asset_Name__c: null;
                                subsAssetName = (subsAssetName != null)? subsAssetName.replaceAll('(\\s+)', '') : '';
                                if(subsAssetName != null && subsAssetName != ''){
                                    for(String assetName : subsAssetName.split(',')){
                                        if(assetnamenonExp.contains(assetName)){
                                            qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
                                        }
                                    }
                                }
                                else if (mqlRecs.containsKey(qli.Id)) { //Added for CPQ22-4693
                                    qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = null;
                                }
                        qli.Is_Approval_Needed_for_Disposition_Lines__c = false;
                        qliListToUpdateBeforeCalc.add(qli);
                    }
                }
                quote.PriorACV__c = null;
                quote.RTA__c = null; 
                quote.MaxRenAmt__c = null;
                quote.TotalACV__c = null;
                quote.RenACV__c = null; 
                quote.ExpACV__c = null; 
                quote.RenSubACV__c = null;
                quote.GrossChurn__c = null;
                quote.GrossChurnRate__c = null;
                quote.RenGrowth__c = null;
                quote.RenExpGrowth__c = null;    
                quote.NetChurnRate__c = null;   
                quote.HasChurn__c = false;
                quoteToUpdateBeforeCalc.add(quote);
            }
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            //update quoteToUpdateBeforeCalc;
            
            if(qliListToUpdateBeforeCalc != null && !qliListToUpdateBeforeCalc.IsEmpty()){
                for(SBQQ__QuoteLine__c qli: qliListToUpdateBeforeCalc){
                    if(!qliListToUpdateBeforeCalcMap.containsKey(qli.Id)){
                        qliListToUpdateBeforeCalcMap.put(qli.Id, qli);
                    }
                    else{
                        qliListToUpdateBeforeCalcMap.put(qli.Id, qli);
                    }
                }
            }
            if(qliListToUpdateBeforeCalcMap.values().size()>0){
                //update qliListToUpdateBeforeCalcMap.values();
            }
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            SBQQ.TriggerControl.enable();
        }
        
        if(allQuotes != null && !allQuotes.IsEmpty()){
            for(SBQQ__Quote__c quote : allQuotes){
                SBQQ__Quote__c existingQuote = allQuotes[0];
                renewalAmtForRenewingQLI = 0;
                rtaAmount = 0;
                rtaAmountQLI = 0;
                maxRenewalAmt = 0;
                upliftedPriorACVToBeRemoved = 0;
                grossChurn = 0;
                counter = 0;
                for(SBQQ__QuoteLine__c qli: existingQuote.SBQQ__LineItems__r){
                    if(qli.Quote_Line_Type__c == 'New' && qli.SBQQ__ProductCode__c != 'RS-BT-RCDM-T'){counter += 1;}
                    if((qli.Quote_Line_Type__c == 'New' || qli.SBQQSC__RenewedContractLine__c == null)){
                        //For Standalone SKUs
                        if((qli.SBQQ__RequiredBy__c == null || (qli.SBQQ__RequiredBy__c != null && qli.SBQQ__RequiredBy__r.Product_Level__c != null && qli.SBQQ__RequiredBy__r.Product_Level__c == 'Wrapper')) && qli.Product_Level__c !='Hybrid Software' && qli.Product_Level__c !='LOD Software' && qli.Product_Level__c !='OnPrem'){
                            mapProductCodeVsLineType.put(qli.SBQQ__ProductCode__c, qli);  
                        }
                        //For Bundled SKUs
                        if((qli.SBQQ__RequiredBy__c != null && qli.SBQQ__RequiredBy__r.Product_Level__c != null && qli.SBQQ__RequiredBy__r.Product_Level__c != 'Wrapper')){ 
                            mapReqProductCodeVsLineType.put((qli.SBQQ__RequiredBy__r.SBQQ__ProductCode__c + qli.SBQQ__ProductCode__c), qli);
                        }
                    }
                    if(qli.Sales_Comp_Category__c != null && (qli.Arroyo_Subsumed_Old_Contract_Line_Items__c != null || (qli.Quote_Line_Type__c == 'Renewal' && qli.Special_Program__c == 'Conversion'))){
                        mapSCCVsRenCLI.put(qli.Sales_Comp_Category__c + qli.Arroyo_Subsumed_Old_Contract_Line_Items__c, 
                                           qli.Arroyo_Subsumed_Old_Contract_Line_Items__c);
                    }
                    //START: Logic for Renewal Lines
                    if(qli.Quote_Line_Type__c == 'Renewal' && qli.Sales_Comp_Category__c != null){                        
                        if(qli.CCLI__c != null && qli.SBQQSC__RenewedContractLine__c == null){
                            qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = qli.CCLI__c;
                        }
                        else if(qli.SBQQSC__RenewedContractLine__c != null && qli.CCLI__c == null){
                            qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = qli.SBQQSC__RenewedContractLine__c;
                        }
                        else if(qli.SBQQSC__RenewedContractLine__c != null && qli.CCLI__c != null){
                            if(qli.CCLI__c.contains(qli.SBQQSC__RenewedContractLine__c)){
                                qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = qli.CCLI__c;
                            }
                            if(!qli.CCLI__c.contains(qli.SBQQSC__RenewedContractLine__c)){
                                qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = qli.SBQQSC__RenewedContractLine__c + ',' + qli.CCLI__c;
                            }
                        }
                        if(qli.Special_Program__c != 'Conversion'){
                            sccRenewalQLI.add(qli.Sales_Comp_Category__c);
                            if(qli.SubscribedAssetNames__c != null && qli.SubscribedAssetNames__c != '' && qli.SBQQSC__RenewedContractLine__c != null && qli.Arroyo_Subsumed_Old_Contract_Line_Items__c != null){
                                mapSubAssetVsRenCLI.put(qli.SubscribedAssetNames__c+qli.Sales_Comp_Category__c, qli.Arroyo_Subsumed_Old_Contract_Line_Items__c);
                            }
                            if(qli.SubsAstNameInt__c != null && qli.SubsAstNameInt__c != '' && qli.SBQQSC__RenewedContractLine__c != null && qli.Arroyo_Subsumed_Old_Contract_Line_Items__c != null){  
                                mapSubAssetVsRenCLI.put(qli.SubsAstNameInt__c + qli.Sales_Comp_Category__c, qli.Arroyo_Subsumed_Old_Contract_Line_Items__c); 
                            }
                            lstRenewalQLIs.add(qli);
                            mapRenewalQLIs.put(qli.SBQQ__Quote__c, lstRenewalQLIs);
                        }
                        if(qli.PriorACVwithUplift__c != null && qli.Arroyo_Subscribed_Asset_Name__c == null){
                            maxRenewalAmt += qli.PriorACVwithUplift__c;
                        }
                        if(qli.RTAwithoutUplift__c != null){
                            rtaAmountQLI += qli.RTAwithoutUplift__c;
                        }
                        if(qli.RTAwithoutUplift__c != null && 
                           qli.Disposition_Reason__c != null && qli.Disposition_Reason__c != 'None' && qli.Disposition_Reason__c != System.Label.DRChurn && qli.Disposition_Reason__c != System.Label.DRRenewLater && qli.Disposition_Reason__c != System.Label.DRAtRisk && qli.Arroyo_Subscribed_Asset_Name__c == null){
                               rtaAmount += qli.RTAwithoutUplift__c;
                           }
                        if(qli.Disposition_Reason__c != null && qli.Disposition_Reason__c == 'Renewing'){
                            if(qli.ACV__c != null){renewalAmtForRenewingQLI += qli.ACV__c;}
                            if(qli.RTAwithoutUplift__c != null && qli.ACV__c != null){
                                Decimal tempDiff = (qli.ACV__c - qli.RTAwithoutUplift__c);
                                renewalGrowthQLI = renewalGrowthQLI + tempDiff;
                                qli.RenGrowth__c = (qli.ACV__c - qli.RTAwithoutUplift__c).setScale(2, RoundingMode.HALF_UP);
                            }
                        }
                        if(qli.Disposition_Reason__c != null && qli.Disposition_Reason__c == 'Churn'){
                            if(qli.RTAwithoutUplift__c != null){
                                qli.ChurnAmt__c = qli.RTAwithoutUplift__c;
                                grossChurn += qli.ChurnAmt__c;
                            }
                            if(qli.RTAwithoutUplift__c != null && qli.ACV__c != null && qli.ACV__c != 0 && qli.RTAwithoutUplift__c > qli.ACV__c){
                                qli.ChurnAmt__c = (qli.RTAwithoutUplift__c - qli.ACV__c);
                                grossChurn += qli.ChurnAmt__c;
                            }
                        }
                        if((qli.Disposition_Reason__c == null || qli.Disposition_Reason__c == 'None') && qli.Quote_Line_Type__c != 'Existing'){
                            isDispositionReasonMissing = true;
                        }
                        if(!qliListToUpdate.contains(qli)){qliListToUpdate.add(qli);}
                        qliListToUpdateMap.put(qli.Id, qli);
                    }
                    //END: Logic for Renewal Lines
                    //START: Logic for Expansion Lines
                    if((qli.Quote_Line_Type__c == 'New' && qli.Sales_Comp_Category__c != null) || (qli.Quote_Line_Type__c == 'Renewal' && qli.Special_Program__c == 'Conversion' && qli.Sales_Comp_Category__c != null)){
                        sccExpansionQLI.add(qli.Sales_Comp_Category__c);
                        lstExpansionQLIs.add(qli);
                        mapExpansionQLIs.put(qli.SBQQ__Quote__c, lstExpansionQLIs);
                        if(qli.Quote_Line_Type__c == 'New' && qli.ACV__c != null){
                            newSaleNetTotal += qli.ACV__c; 
                        }
                        if(qli.ACV__c != null){
                            qliExpACV = qli.SubsRenAmt__c != null? qli.ACV__c - qli.SubsRenAmt__c
                                : qli.ACV__c;
                        }
                    }
                    //END: Logic for Expansion Lines
                }//All QLI Loop
            }//Quote loop
        }// empty check
        //END: Creating separate lists of Sales Comp category for Renewal & Expansion New QLIs
        
        //ARY-1079 Added by Sumedha for Replace scenario - Starts
        Set<Id> renQLiIds = new Set<Id>();
        List<Merged_Quote_Line__c> lstMergedQLs = new List<Merged_Quote_Line__c>();
        Map<String, Merged_Quote_Line__c> mapOfQLIswithMergeLines = new Map<String, Merged_Quote_Line__c>();
        Set<Id> processedRenLine = new Set<Id>();
        if (lstRenewalQLIs != null && !lstRenewalQLIs.isEmpty()) {
            for (SBQQ__QuoteLine__c qli : lstRenewalQLIs) {
                if (qli.id != null) {
                    renQLiIds.add(qli.id);
                }
            }
        }
        
        if (renQLiIds != null && !renQLiIds.isEmpty()) {
            lstMergedQLs = [Select Id, Merged_Renewal_Quote_Line__c, New_Quote_Line__c from Merged_Quote_Line__c where Merged_Renewal_Quote_Line__c IN : renQLiIds];
            if (lstMergedQLs != null && !lstMergedQLs.isEmpty()) {
                for (Merged_Quote_Line__c mQL : lstMergedQLs) {
                    mapOfQLIswithMergeLines.put(mQL.Merged_Renewal_Quote_Line__c, mQL);
                }
            }
        }
        //ARY-1079 Added by Sumedha for Replace scenario - Ends
        
        if(allQuotes != null && !allQuotes.IsEmpty())
        {
            for(SBQQ__Quote__c quote : allQuotes){
                SBQQ__Quote__c existingQuote = allQuotes[0];
                for(SBQQ__QuoteLine__c ql: existingQuote.SBQQ__LineItems__r) 
                {
                    if(ql.Quote_Line_Type__c == 'Renewal'){
                        if(ql.Disposition_Reason__c == 'Churn' && (((ql.SBQQ__RequiredBy__c == null || (ql.SBQQ__RequiredBy__c != null && ql.SBQQ__RequiredBy__r.Product_Level__c != null && ql.SBQQ__RequiredBy__r.Product_Level__c == 'Wrapper')) && mapProductCodeVsLineType != null && mapProductCodeVsLineType.containsKey(ql.SBQQ__ProductCode__c) && mapProductCodeVsLineType.get(ql.SBQQ__ProductCode__c) != null && mapProductCodeVsLineType.get(ql.SBQQ__ProductCode__c).Quote_Line_Type__c != ql.Quote_Line_Type__c) || (ql.SBQQ__RequiredBy__c != null && ql.SBQQ__RequiredBy__r.Product_Level__c != null && ql.SBQQ__RequiredBy__r.Product_Level__c != 'Wrapper' && mapReqProductCodeVsLineType != null && mapReqProductCodeVsLineType.containsKey(ql.SBQQ__RequiredBy__r.SBQQ__ProductCode__c + ql.SBQQ__ProductCode__c) && mapReqProductCodeVsLineType.get(ql.SBQQ__RequiredBy__r.SBQQ__ProductCode__c + ql.SBQQ__ProductCode__c) != null && mapReqProductCodeVsLineType.get(ql.SBQQ__RequiredBy__r.SBQQ__ProductCode__c + ql.SBQQ__ProductCode__c).Quote_Line_Type__c != ql.Quote_Line_Type__c))){                              
                            //For Standalone SKUs
                            if(ql.SBQQ__RequiredBy__c == null && ql.Product_Level__c !='Hybrid Software'&& ql.Product_Level__c !='LOD Software' && ql.Product_Level__c !='OnPrem'){
                                SBQQ__QuoteLine__c qliRec = new SBQQ__QuoteLine__c(Id = mapProductCodeVsLineType.get(ql.SBQQ__ProductCode__c).Id,Is_Approval_Needed_for_Disposition_Lines__c = TRUE);
                                qltoUpdate2.put(qliRec.Id, qliRec); 
                            }
                            //For SKUs added under Bundles
                            if(ql.SBQQ__RequiredBy__c != null){
                                SBQQ__QuoteLine__c qliRec = new SBQQ__QuoteLine__c(Id = mapReqProductCodeVsLineType.get(ql.SBQQ__RequiredBy__r.SBQQ__ProductCode__c + ql.SBQQ__ProductCode__c).Id, Is_Approval_Needed_for_Disposition_Lines__c = TRUE);
                                qltoUpdate2.put(qliRec.Id, qliRec); 
                            }
                        }
                        else if(!mapProductCodeVsLineType.containsKey(ql.SBQQ__ProductCode__c) || !mapReqProductCodeVsLineType.containsKey(ql.SBQQ__RequiredBy__r.SBQQ__ProductCode__c + ql.SBQQ__ProductCode__c)){                                   
                            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(Id = ql.Id, Is_Approval_Needed_for_Disposition_Lines__c = FALSE);
                            qltoUpdate2.put(qli1.Id, qli1);
                        }
                    }
                }
            }
        }
        if(qltoUpdate2 != NULL && !qltoUpdate2.isEmpty()){
            for(SBQQ__QuoteLine__c qliRecord: qltoUpdate2.values()){
                if(qliRecord.Is_Approval_Needed_for_Disposition_Lines__c == true){
                    setHasChurnAtQuote = true;
                }
            }
        }
        //START: Creating mapping of Sales Comp category from the Custom Metadata Records
        List<Sales_Comp_Category_Mapping__mdt> sccmMetaDataList = [SELECT Id, Label, DeveloperName, Mapped_Sales_Comp_Category__c, Priority__c FROM Sales_Comp_Category_Mapping__mdt ORDER BY Label, Priority__c ASC LIMIT 25000];
        if(sccmMetaDataList != null && !sccmMetaDataList.IsEmpty()){
            for(Sales_Comp_Category_Mapping__mdt recMetaData: sccmMetaDataList){
                mapSCCVsObjRec.put(recMetaData.Label, recMetaData);
                if(!mapSCCVsObjRecList.containsKey(recMetaData.Label)){
                    mapSCCVsObjRecList.put(recMetaData.Label, new List<Sales_Comp_Category_Mapping__mdt>{recMetaData});
                }
                else{
                    mapSCCVsObjRecList.get(recMetaData.Label).add(recMetaData);
                }
            }
        }
        //END: Creating mapping of Sales Comp category from the Custom Metadata Records
        renewalGrowthExpQLI = 0;
        if(allQuotes != null && !allQuotes.IsEmpty() && mapRenewalQLIs != null && !mapRenewalQLIs.IsEmpty() && mapExpansionQLIs != null && !mapExpansionQLIs.IsEmpty()){
            tempRenewalACV = 0;
            //REEN-121
            /*for(SBQQ__Quote__c quoteRec: allQuotes){
                if(quoteRec != null && mapExpansionQLIs.get(quoteRec.Id) != null){
                    for(SBQQ__QuoteLine__c qliExpansion: mapExpansionQLIs.get(quoteRec.Id)){
                        if(quoteRec != null && mapRenewalQLIs.get(quoteRec.Id) != null){
                            for(SBQQ__QuoteLine__c qliRenewal: mapRenewalQLIs.get(quoteRec.Id)){
                                if(qliRenewal.Disposition_Reason__c == 'Replaced' && qliRenewal.Replace_By__c == qliExpansion.SBQQ__ProductCode__c){
                                    tempReplaceQLICount = tempReplaceQLICount + 1;
                                    mapReplaceProdCodeVsNewLineCount.put(qliRenewal.Replace_By__c, tempReplaceQLICount);
                                }
                            }
                        }
                    }
                }
            }*/               
            String validSubsAssetName = '';
            for(SBQQ__Quote__c quoteRec: allQuotes){
                if(quoteRec != null && mapExpansionQLIs != null && !mapExpansionQLIs.isEmpty() && mapExpansionQLIs.get(quoteRec.Id) != null){//REEN-121
                    for(SBQQ__QuoteLine__c qliExpansion: mapExpansionQLIs.get(quoteRec.Id)){
                        if(qliExpansion.ACV__c != null){
                            qliExpansion.ExpACV__c = qliExpansion.SubsRenAmt__c != null? qliExpansion.ACV__c - qliExpansion.SubsRenAmt__c : qliExpansion.ACV__c;
                            //ARY-1150 Starts
                            if (qliExpansion.ExpACV__c < 0) {
                                qliExpansion.ExpACV__c = 0.00;
                            }
                            //ARY-1150 Ends
                        }
                        if(qliExpansion.Sales_Comp_Category__c != null){
                            tempSCCategory = qliExpansion.Sales_Comp_Category__c;
                        }
                        lstRefreshedAssetNames = new Set<String>();
                        if(String.isNotBlank(qliExpansion.Arroyo_Subscribed_Asset_Name__c)){
                            for(String assetName : qliExpansion.Arroyo_Subscribed_Asset_Name__c.split(',')){
                                assetName = assetName.trim();
                                lstRefreshedAssetNames.add(assetName);
                            }
                        }
                        priorACV = 0;
                        rtaToBeRemoved = 0;
                        expansionACV = 0;
                        if(quoteRec != null && mapRenewalQLIs != null && !mapRenewalQLIs.isEmpty() && mapRenewalQLIs.get(quoteRec.Id) != null){//REEN-121
                            for(SBQQ__QuoteLine__c qliRenewal: mapRenewalQLIs.get(quoteRec.Id)){                                   
                                lstSubAssetNames = new Set<String>();
                                lstSubAssetNamesRBK = new Set<String>();
                                lstAllMatchedAssetNames = new Set<String>();
                                String subsAssetName = String.isNotBlank(qliRenewal.SubscribedAssetNames__c) ? qliRenewal.SubscribedAssetNames__c: qliRenewal.SubsAstNameInt__c;
                                subsAssetName = (subsAssetName != null)? subsAssetName.replaceAll('(\\s+)', '') : '';
                                if(subsAssetName != null && subsAssetName != ''){
                                    for(String assetName : subsAssetName.split(',')){
                                        if(lstRefreshedAssetNames.contains(assetName)){
                                            lstAllMatchedAssetNames.add(assetName);
                                        }
                                    }
                                }
                                if(String.isNotBlank(qliRenewal.SubscribedAssetNames__c)){
                                    if(qliRenewal.SBQQ__ProductCode__c != 'RBK-SVC-PREM-APPLIANCE' && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO') && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') && !qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE')){
                                        for(String assetName : qliRenewal.SubscribedAssetNames__c.split(',')){
                                            assetName = assetName.trim();
                                            lstSubAssetNames.add(assetName);
                                        }
                                    }
                                    if(qliRenewal.SBQQ__ProductCode__c != null && (qliRenewal.SBQQ__RequiredBy__c != null) && (qliRenewal.SBQQ__ProductCode__c == 'RBK-SVC-PREM-APPLIANCE' || qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO') || qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') || qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE'))){
                                        for(String assetName : qliRenewal.SubscribedAssetNames__c.split(',')){
                                            assetName = assetName.trim();
                                            lstSubAssetNamesRBK.add(assetName);
                                        }
                                    }
                                }
                                if(String.isNotBlank(qliRenewal.SubsAstNameInt__c)){ 
                                    if(qliRenewal.SBQQ__ProductCode__c != 'RBK-SVC-PREM-APPLIANCE' && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO') && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') && !qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE')){  
                                        for(String assetName : qliRenewal.SubsAstNameInt__c.split(',')){ 
                                            assetName = assetName.trim(); 
                                            lstSubAssetNames.add(assetName);  
                                        } 
                                    } 
                                    if(qliRenewal.SBQQ__ProductCode__c != null && (qliRenewal.SBQQ__RequiredBy__c != null) && (qliRenewal.SBQQ__ProductCode__c == 'RBK-SVC-PREM-APPLIANCE' || qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO') || qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') || qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE'))){  
                                        for(String assetName : qliRenewal.SubsAstNameInt__c.split(',')){   
                                            assetName = assetName.trim();    
                                            lstSubAssetNamesRBK.add(assetName);  
                                        }    
                                    }    
                                }                                   
                                if(qliRenewal.ACV__c != null){
                                    qliRenewal.ExpACV__c = qliRenewal.SubsRenAmt__c != null? qliRenewal.ACV__c - qliRenewal.SubsRenAmt__c : qliRenewal.ACV__c;
                                    //ARY-1150 Starts
                                    if (qliRenewal.ExpACV__c < 0) {
                                        qliRenewal.ExpACV__c = 0.00;
                                    }
                                    //ARY-1150 Ends
                                }
                                if(qliRenewal.RTAwithoutUplift__c != null && qliRenewal.Arroyo_Subscribed_Asset_Name__c == NULL){
                                    priorACV += qliRenewal.RTAwithoutUplift__c;
                                }
                                if(qliRenewal.Disposition_Reason__c == 'Replaced' && qliRenewal.Replace_By__c == qliExpansion.SBQQ__ProductCode__c && qliRenewal.SBQQ__Quantity__c == qliExpansion.SBQQ__Quantity__c){
                                    qliExpansion.Special_Program__c = 'Replaced';
                                }
                                if((RenewalQLSubStae != null && !RenewalQLSubStae.IsEmpty() && RenewalQLSubStae.get(qliRenewal.Id) == true) &&
                                   processedOldCLI.contains(qliRenewal.SBQQSC__RenewedContractLine__c+'-'+qliExpansion.Sales_Comp_Category__c)){
                                       continue;//to skip the execution of logic below
                                   }
                                
                                //CPQ22-3650 Starts
                                //Check for Assets in the Expansion Line vs Renewal Lines. If all Assets of a Renewal Line is present on the Expansion Line, then we will skip the iteration.
                                String assetsList = qliRenewal.SubscribedAssetNames__c != null ? qliRenewal.SubscribedAssetNames__c : qliRenewal.SubsAstNameInt__c;
                                List<String> assetsOnRenLine = new List<String>();
                                if (qliRenewal.Disposition_Reason__c != System.Label.DRChurn && qliRenewal.Disposition_Reason__c != System.Label.DRRenewLater && qliRenewal.Disposition_Reason__c != System.Label.DRAtRisk && qliRenewal.Disposition_Reason__c != 'None' && 
                                    String.isNotBlank(qliExpansion.Arroyo_Subscribed_Asset_Name__c) && String.isNotBlank(assetsList)) {
                                        assetsOnRenLine = assetsList.split(',');
                                        if (assetsOnRenLine != null && !assetsOnRenLine.isEmpty()) {
                                            for (String asset : assetsOnRenLine) {
                                                asset = asset.trim();
                                                if (qliExpansion.Arroyo_Subscribed_Asset_Name__c.contains(asset)) {
                                                    if (mapRenLinevsAssetCount.containsKey(qliRenewal.Id)) {
                                                        Integer count = mapRenLinevsAssetCount.get(qliRenewal.Id);
                                                        count++;
                                                        mapRenLinevsAssetCount.put(qliRenewal.Id, count);
                                                    }
                                                    else {
                                                        mapRenLinevsAssetCount.put(qliRenewal.Id, 1);
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                //CPQ22-3650 Ends
                                
                                totSubAmt = RenewalQLSubAmount.get(qliRenewal.Id) != null? RenewalQLSubAmount.get(qliRenewal.Id) : 0;
                                RenewalQLSubAmount.put(qliRenewal.Id, totSubAmt);
                                //ARY-1079 added qliRenewal.RTAwithoutUplift__c > 0
                                //Added mapRenLinevsAssetCount check. If True, then all of the Asset Names are subsumed into the Expansion Line, else false.
                                //Set RenewalQLSubStae only of RTA is subsumed and the Assets are subsumed.
                                //CPQ22-3650 Starts Added mapRenLinevsAssetCount checks below
                                if(qliRenewal.RTAwithoutUplift__c == totSubAmt && qliRenewal.RTAwithoutUplift__c > 0 && 
                                   mapRenLinevsAssetCount != null && !mapRenLinevsAssetCount.isEmpty() && mapRenLinevsAssetCount.get(qliRenewal.Id) != null && 
                                   mapRenLinevsAssetCount.get(qliRenewal.Id) == assetsOnRenLine.size()
                                  ){
                                      RenewalQLSubStae.put(qliRenewal.Id, true);
                                  }else{
                                      RenewalQLSubStae.put(qliRenewal.id, false);
                                  }
                                if(qliRenewal.RTAwithoutUplift__c != null && lstSubAssetNames != null && !lstSubAssetNames.isEmpty() && qliRenewal.SBQQ__ProductCode__c != null && qliRenewal.SBQQ__ProductCode__c != 'RBK-SVC-PREM-APPLIANCE' && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO')
                                   && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') && !qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE')){
                                       if(lstSubAssetNames != null && !lstSubAssetNames.isEmpty() && lstAllMatchedAssetNames != null && !lstAllMatchedAssetNames.isEmpty()){
                                           tempRenewalACV = (qliRenewal.RTAwithoutUplift__c / lstSubAssetNames.size()) * lstAllMatchedAssetNames.size();
                                       }
                                       else{
                                           tempRenewalACV = qliRenewal.RTAwithoutUplift__c / lstSubAssetNames.size();
                                       }
                                   }
                                if(qliRenewal.RTAwithoutUplift__c != null && lstSubAssetNamesRBK != null && !lstSubAssetNamesRBK.IsEmpty() && qliRenewal.SBQQ__ProductCode__c != null && (qliRenewal.SBQQ__ProductCode__c == 'RBK-SVC-PREM-APPLIANCE' || qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO') || qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') || qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE'))){
                                    if(lstAllMatchedAssetNames != null && !lstAllMatchedAssetNames.IsEmpty()){
                                        tempRenewalACV = (qliRenewal.RTAwithoutUplift__c / lstSubAssetNamesRBK.size()) * lstAllMatchedAssetNames.size();
                                    }
                                    else{
                                        tempRenewalACV = qliRenewal.RTAwithoutUplift__c / lstSubAssetNamesRBK.size();
                                    }
                                }
                                //STARTS : If Subscribed Asset Names__c is present   
                                if(qliRenewal.SubscribedAssetNames__c != null && String.ISNOTBLANK(qliRenewal.SubscribedAssetNames__c)){  
                                    validSubsAssetName = qliRenewal.SubscribedAssetNames__c; 
                                }    
                                if(qliRenewal.SubsAstNameInt__c != null && String.ISNOTBLANK(qliRenewal.SubsAstNameInt__c)){    
                                    validSubsAssetName = qliRenewal.SubsAstNameInt__c;   
                                } 
                                if (String.ISBLANK(qliRenewal.SubscribedAssetNames__c) //&& String.ISBLANK(qliRenewal.SubsAstNameInt__c) 
                                    && (qliRenewal.Product_Level__c != null && qliRenewal.Product_Level__c.contains('Addon'))
                                    && String.ISBLANK(qliExpansion.SubscribedAssetNames__c) && String.ISBLANK(qliExpansion.SubsAstNameInt__c)) {
                                        validSubsAssetName = '';
                                    }                                   
                                if(validSubsAssetName != null && validSubsAssetName != ''){
                                    if(lstRefreshedAssetNames != null && !lstRefreshedAssetNames.IsEmpty() && !lstRefreshedAssetNames.isEmpty()){
                                        for(String refAssetName: lstRefreshedAssetNames){
                                            if(qliRenewal.Sales_Comp_Category__c != null && mapSCCVsObjRecList != null && mapSCCVsObjRecList.containskey(qliRenewal.Sales_Comp_Category__c) != null && mapSCCVsObjRecList.get(qliRenewal.Sales_Comp_Category__c) != null  && ((mapSubAssetVsRenCLI != null && mapSubAssetVsRenCLI.containsKey(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) && mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c == null) || ((mapSubAssetVsRenCLI != null && mapSubAssetVsRenCLI.containsKey(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) && mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && !qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c.contains(mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c)))))){
                                                for(Sales_Comp_Category_Mapping__mdt recMetaData : mapSCCVsObjRecList.get(qliRenewal.Sales_Comp_Category__c)){
                                                    if(validSubsAssetName != null && validSubsAssetName.contains(refAssetName) && recMetaData.Mapped_Sales_Comp_Category__c == qliExpansion.Sales_Comp_Category__c && qliRenewal.Disposition_Reason__c != 'Renewing' && qliRenewal.Disposition_Reason__c != 'None'){
                                                        if(qliRenewal.SBQQ__ProductCode__c != 'RBK-SVC-PREM-APPLIANCE' && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO') && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') && !qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE') && !tempSCCategory.contains('RUBRIK') && qliRenewal.Disposition_Reason__c != System.Label.DRChurn && qliRenewal.Disposition_Reason__c != System.Label.DRRenewLater && qliRenewal.Disposition_Reason__c != System.Label.DRAtRisk && qliRenewal.Disposition_Reason__c != 'None'){
                                                            totSubAmt = + tempRenewalACV.setScale(2, RoundingMode.HALF_UP);                                                                         
                                                            if(qliExpansion.Special_Program__c != 'Conversion'){                                                                             
                                                                qliExpansion.SubsRenAmt__c = qliExpansion.SubsRenAmt__c != null? (qliExpansion.SubsRenAmt__c + tempRenewalACV).setScale(2, RoundingMode.HALF_UP) : 
                                                                tempRenewalACV.setScale(2, RoundingMode.HALF_UP);
                                                                //qliExpansion.SubsRenTCV__c = (qliExpansion.SubsRenAmt__c / 12) * qliExpansion.SBQQ__SubscriptionTerm__c;
                                                            }                                                                         
                                                            qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != '') ? qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c + ' , ' + mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) : mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c);
                                                        }
                                                        if(((qliRenewal.SBQQ__ProductCode__c == 'RBK-SVC-PREM-APPLIANCE' || qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO') || qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') || qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE')) && !tempSCCategory.contains('RUBRIK') && qliRenewal.Disposition_Reason__c != System.Label.DRChurn && qliRenewal.Disposition_Reason__c != System.Label.DRRenewLater && qliRenewal.Disposition_Reason__c != System.Label.DRAtRisk && qliRenewal.Disposition_Reason__c != 'None')){
                                                            totSubAmt += (tempRenewalACV * 0.07).setScale(2, RoundingMode.HALF_UP);
                                                            if(qliExpansion.Special_Program__c != 'Conversion'){
                                                                qliExpansion.SubsRenAmt__c = qliExpansion.SubsRenAmt__c != null? (qliExpansion.SubsRenAmt__c + (tempRenewalACV * 0.07)).setScale(2, RoundingMode.HALF_UP) : (tempRenewalACV * 0.07).setScale(2, RoundingMode.HALF_UP);
                                                                //qliExpansion.SubsRenTCV__c = (qliExpansion.SubsRenAmt__c / 12) * qliExpansion.SBQQ__SubscriptionTerm__c;
                                                            }                                                                         
                                                            qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != '') ? qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c + ' , ' + mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) : mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c);
                                                            //HW Support Expansion Lines
                                                        }
                                                        if(qliRenewal.SBQQ__ProductCode__c != 'RBK-SVC-PREM-APPLIANCE' && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO') && !qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') && !qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE') && tempSCCategory.contains('RUBRIK') && qliRenewal.Disposition_Reason__c != System.Label.DRChurn && qliRenewal.Disposition_Reason__c != System.Label.DRRenewLater && qliRenewal.Disposition_Reason__c != System.Label.DRAtRisk && qliRenewal.Disposition_Reason__c != 'None'){
                                                            totSubAmt = + tempRenewalACV.setScale(2, RoundingMode.HALF_UP);
                                                            qliExpansion.SubsRenAmt__c = qliExpansion.SubsRenAmt__c != null? (qliExpansion.SubsRenAmt__c + tempRenewalACV).setScale(2, RoundingMode.HALF_UP) : tempRenewalACV.setScale(2, RoundingMode.HALF_UP);                                                                         
                                                            //qliExpansion.SubsRenTCV__c = (qliExpansion.SubsRenAmt__c / 12) * qliExpansion.SBQQ__SubscriptionTerm__c;                                                                         
                                                            qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != '') ? qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c + ' , ' + mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) : mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c);
                                                        }
                                                    }
                                                    if(validSubsAssetName != null && validSubsAssetName.contains(refAssetName) && recMetaData.Mapped_Sales_Comp_Category__c != tempSCCategory && (qliRenewal.SBQQ__ProductCode__c == 'RBK-SVC-PREM-APPLIANCE' || qliRenewal.SBQQ__ProductCode__c.contains('SUB-PRO') || qliRenewal.SBQQ__ProductCode__c.contains('SUB-HYB') || qliRenewal.SBQQ__ProductCode__c.contains('PRO-BUNDLE')) && tempSCCategory.contains('RUBRIK') && qliRenewal.Disposition_Reason__c != 'Renewing' && qliRenewal.Disposition_Reason__c != System.Label.DRChurn && qliRenewal.Disposition_Reason__c != System.Label.DRRenewLater && qliRenewal.Disposition_Reason__c != System.Label.DRAtRisk && qliRenewal.Disposition_Reason__c != 'None'){
                                                        totSubAmt = + (tempRenewalACV * 0.93).setScale(2, RoundingMode.HALF_UP);
                                                        qliExpansion.SubsRenAmt__c = qliExpansion.SubsRenAmt__c != null? (qliExpansion.SubsRenAmt__c + (tempRenewalACV * 0.93)).setScale(2, RoundingMode.HALF_UP) : (tempRenewalACV * 0.93).setScale(2, RoundingMode.HALF_UP);
                                                        //qliExpansion.SubsRenTCV__c = (qliExpansion.SubsRenAmt__c / 12) * qliExpansion.SBQQ__SubscriptionTerm__c;                                                                   
                                                        qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != '') ? qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c + ' , '  + mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) : mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c);
                                                        //Hybrid SW Expansion Lines
                                                    }
                                                }//for loop closed - metadata
                                            }//null check if closed
                                        }//loop closed                              
                                    }
                                    else{// for single asset names
                                        if(qliRenewal.Sales_Comp_Category__c != null && mapSCCVsObjRecList != null && mapSCCVsObjRecList.containskey(qliRenewal.Sales_Comp_Category__c) != null && 
                                           mapSCCVsObjRecList.get(qliRenewal.Sales_Comp_Category__c) != null){
                                               for(Sales_Comp_Category_Mapping__mdt recMetaData : mapSCCVsObjRecList.get(qliRenewal.Sales_Comp_Category__c)){
                                                   if(qliExpansion.Arroyo_Subscribed_Asset_Name__c != null && validSubsAssetName != null && recMetaData.Mapped_Sales_Comp_Category__c != null && tempSCCategory != null && validSubsAssetName.contains(qliExpansion.Arroyo_Subscribed_Asset_Name__c) && recMetaData.Mapped_Sales_Comp_Category__c == tempSCCategory && qliRenewal.Disposition_Reason__c != 'Renewing' && qliRenewal.Disposition_Reason__c != System.Label.DRChurn && qliRenewal.Disposition_Reason__c != System.Label.DRRenewLater && qliRenewal.Disposition_Reason__c != System.Label.DRAtRisk && qliRenewal.Disposition_Reason__c != 'None' && ((mapSubAssetVsRenCLI != null && mapSubAssetVsRenCLI.containsKey(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) && mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c == null) || ((mapSubAssetVsRenCLI != null && mapSubAssetVsRenCLI.containsKey(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) && mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && !qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c.contains(mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c)))))){
                                                       totSubAmt = + tempRenewalACV.setScale(2, RoundingMode.HALF_UP);                                                            
                                                       qliExpansion.SubsRenAmt__c = qliExpansion.SubsRenAmt__c != null? (qliExpansion.SubsRenAmt__c + tempRenewalACV).setScale(2, RoundingMode.HALF_UP) : tempRenewalACV.setScale(2, RoundingMode.HALF_UP);
                                                       //qliExpansion.SubsRenTCV__c = (qliExpansion.SubsRenAmt__c / 12) * qliExpansion.SBQQ__SubscriptionTerm__c;
                                                       qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != '') ? qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c + ' , ' + mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c) : mapSubAssetVsRenCLI.get(validSubsAssetName+qliRenewal.Sales_Comp_Category__c);
                                                   }
                                               }//for loop closed - metadata
                                           }//null check if closed
                                    }   
                                }
                                //ENDS: If Subscribed Asset Names__c is present
                                //STARTS: If Subscribed Asset Names__c is NOT present
                                else{
                                    //ARY-1079 Starts
                                    if (processedRenLine.contains(qliRenewal.Id)) {
                                        continue;
                                    }
                                    //ARY-1079 Ends
                                    if(qliRenewal.Sales_Comp_Category__c != null && mapSCCVsObjRecList != null && mapSCCVsObjRecList.containskey(qliRenewal.Sales_Comp_Category__c) && RenewalQLSubStae != null && RenewalQLSubStae.get(qliRenewal.Id) != null && RenewalQLSubStae.get(qliRenewal.Id) == false && mapSCCVsObjRecList.get(qliRenewal.Sales_Comp_Category__c) != null && qliRenewal.Disposition_Reason__c != 'Renewing' && qliRenewal.Disposition_Reason__c != 'None'){                                           
                                        for(Sales_Comp_Category_Mapping__mdt recMetaData : mapSCCVsObjRecList.get(qliRenewal.Sales_Comp_Category__c)){
                                            if(recMetaData.Mapped_Sales_Comp_Category__c == tempSCCategory && qliRenewal.Disposition_Reason__c != System.Label.DRChurn && qliRenewal.Disposition_Reason__c != System.Label.DRRenewLater && qliRenewal.Disposition_Reason__c != System.Label.DRAtRisk && qliRenewal.Disposition_Reason__c != 'None'){                                                      
                                                if(qliRenewal.RTAwithoutUplift__c != null){
                                                    //ARY-1079 Starts
                                                    //if (qliRenewal.Replace_By__c != null && qliRenewal.Replace_By__c != 'None' && qliExpansion.Special_Program__c == 'Replaced') {
                                                    if (mapOfQLIswithMergeLines != null && !mapOfQLIswithMergeLines.isEmpty()) {
                                                        if (!processedRenLine.contains(qliRenewal.Id) &&  mapOfQLIswithMergeLines.containsKey(qliRenewal.Id) && mapOfQLIswithMergeLines.get(qliRenewal.Id) != null && 
                                                            mapOfQLIswithMergeLines.get(qliRenewal.Id).New_Quote_Line__c == qliExpansion.Id && String.isNotBlank(qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c)) {
                                                                List<String> lststr = qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',');
                                                                Map<Id, SBQQ__QuoteLine__c> returnMap = new Map<Id, SBQQ__QuoteLine__c>();
                                                                returnMap = calculateMetricsForReplaced(qliRenewal, qliExpansion, lststr, processedRenLine);
                                                                if (returnMap != null && !returnMap.isEmpty() && returnMap.get(qliExpansion.id) != null) {
                                                                    qliExpansion.SubsRenAmt__c  = returnMap.get(qliExpansion.id).SubsRenAmt__c;
                                                                    qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = returnMap.get(qliExpansion.id).Arroyo_Subsumed_Old_Contract_Line_Items__c;
                                                                    processedRenLine.add(qliRenewal.Id);
                                                                }
                                                            }
                                                        //}
                                                    }
                                                    else {//ARY-1079 Ends
                                                        //CPQ22-3514 Starts added RenewalQLSubStae condition
                                                        if (RenewalQLSubStae != null && !RenewalQLSubStae.IsEmpty() && RenewalQLSubStae.get(qliRenewal.Id) == false) {
                                                            totSubAmt = + (qliRenewal.RTAwithoutUplift__c).setScale(2, RoundingMode.HALF_UP);
                                                            qliExpansion.SubsRenAmt__c = qliExpansion.SubsRenAmt__c != null? (qliExpansion.SubsRenAmt__c + qliRenewal.RTAwithoutUplift__c).setScale(2, RoundingMode.HALF_UP) : (qliRenewal.RTAwithoutUplift__c).setScale(2, RoundingMode.HALF_UP);
                                                            //qliExpansion.SubsRenTCV__c = (qliExpansion.SubsRenAmt__c / 12) * qliExpansion.SBQQ__SubscriptionTerm__c;
                                                            if((mapSCCVsRenCLI != null && mapSCCVsRenCLI.containsKey(qliRenewal.Sales_Comp_Category__c+qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c) && mapSCCVsRenCLI.get(qliRenewal.Sales_Comp_Category__c+qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c) != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c == null) || ((mapSCCVsRenCLI != null && mapSCCVsRenCLI.containsKey(qliRenewal.Sales_Comp_Category__c+qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c) && mapSCCVsRenCLI.get(qliRenewal.Sales_Comp_Category__c+qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c) != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && !qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c.contains(mapSCCVsRenCLI.get(qliRenewal.Sales_Comp_Category__c+qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c))))){                                                                
                                                                qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != '') ? qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c + ' , ' + mapSCCVsRenCLI.get(qliRenewal.Sales_Comp_Category__c+qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c) : mapSCCVsRenCLI.get(qliRenewal.Sales_Comp_Category__c+qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c);
                                                            }
                                                            if (tempRenewalACV != 0 && tempRenewalACV != null) {
                                                                totSubAmt = + tempRenewalACV.setScale(2, RoundingMode.HALF_UP);
                                                            }
                                                        }    
                                                    }
                                                }
                                            }
                                        }//for loop closed - metadata
                                    }//null check if closed
                                }//Else is closed
                                //ENDS: If Subscribed Asset Names__c is NOT present
                                //ARY-1079 Added by Sumedha for replacement scenarios - Starts
                                if (mapOfQLIswithMergeLines != null && !mapOfQLIswithMergeLines.isEmpty()) {
                                    if (!processedRenLine.contains(qliRenewal.Id) && mapOfQLIswithMergeLines.containsKey(qliRenewal.Id) && mapOfQLIswithMergeLines.get(qliRenewal.Id) != null && 
                                        mapOfQLIswithMergeLines.get(qliRenewal.Id).New_Quote_Line__c == qliExpansion.Id) {
                                            if (!processedRenLine.contains(qliRenewal.Id) && qliRenewal.Sales_Comp_Category__c != null && mapSCCVsObjRecList != null && mapSCCVsObjRecList.containskey(qliRenewal.Sales_Comp_Category__c) != null &&
                                                mapSCCVsObjRecList.get(qliRenewal.Sales_Comp_Category__c) != null && qliRenewal.Disposition_Reason__c != 'Renewing' && qliRenewal.Disposition_Reason__c != 'None') {
                                                    for(Sales_Comp_Category_Mapping__mdt recMetaData : mapSCCVsObjRecList.get(qliRenewal.Sales_Comp_Category__c)){
                                                        if(!processedRenLine.contains(qliRenewal.Id) && recMetaData.Mapped_Sales_Comp_Category__c == tempSCCategory && qliRenewal.Disposition_Reason__c != System.Label.DRChurn && 
                                                           qliRenewal.Disposition_Reason__c != System.Label.DRRenewLater && qliRenewal.Disposition_Reason__c != System.Label.DRAtRisk && qliRenewal.Disposition_Reason__c != 'None'){ 
                                                               if (!processedRenLine.contains(qliRenewal.Id) && String.isNotBlank(qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c)) {
                                                                   List<String> str = qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',');
                                                                   
                                                                   Map<Id, SBQQ__QuoteLine__c> returnMap1 = new Map<Id, SBQQ__QuoteLine__c>();
                                                                   returnMap1 = calculateMetricsForReplaced(qliRenewal, qliExpansion, str, processedRenLine);
                                                                   if (returnMap1 != null && !returnMap1.isEmpty() && returnMap1.get(qliExpansion.id) != null) {
                                                                       qliExpansion.SubsRenAmt__c  = returnMap1.get(qliExpansion.id).SubsRenAmt__c;
                                                                       qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = returnMap1.get(qliExpansion.id).Arroyo_Subsumed_Old_Contract_Line_Items__c;
                                                                       processedRenLine.add(qliRenewal.Id);
                                                                   }
                                                               }
                                                           }
                                                    }
                                                }
                                        }
                                    
                                }
                                /*else if(mapOfQLIswithMergeLines.isEmpty() && !processedRenLine.contains(qliRenewal.Id) &&  
qliRenewal.Disposition_Reason__c == 'Replaced' && qliRenewal.Replace_By__c == qliExpansion.SBQQ__ProductCode__c && 
qliRenewal.SBQQ__Quantity__c == qliExpansion.SBQQ__Quantity__c){  
qliExpansion.SubsRenAmt__c = qliExpansion.SubsRenAmt__c != null? (qliExpansion.SubsRenAmt__c + qliRenewal.RTAwithoutUplift__c):qliRenewal.RTAwithoutUplift__c;
qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != '') ? qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c + ' , ' +qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c:qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c;
processedRenLine.add(qliRenewal.Id);
}*/
                                //ARY-1079 Added by Sumedha for replacement scenarios - Ends   
                                //Revert for Map stamping: RenewalQLSubAmount, RenewalQLSubStae
                                RenewalQLSubAmount.put(qliRenewal.Id, totSubAmt);
                            }//FOR Loop CLOSED : Renewal QLIs
                        }
                        if(qliExpansion.ACV__c != null){
                            qliExpansion.ExpACV__c = qliExpansion.SubsRenAmt__c != null? qliExpansion.ACV__c - qliExpansion.SubsRenAmt__c: qliExpansion.ACV__c;
                            //ARY-1150 Starts
                            if (qliExpansion.ExpACV__c < 0) {
                                qliExpansion.ExpACV__c = 0.00;
                            }
                            //ARY-1150 Ends

                            //REEN-121 starts
                            if (quoteRec.SBQQ__Type__c == 'Renewal' && qliExpansion.SBQQ__Product__r.ExcExpACV__c == true) {
                                qliExpansion.ExpACV__c = 0.00;
                            }
                            //REEN-121 ends
                        }
                        if(!qliListToUpdate.contains(qliExpansion)){
                            qliListToUpdate.add(qliExpansion);
                        }
                        qliListToUpdateMap.put(qliExpansion.Id, qliExpansion);
                        
                        if (qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && String.isNotBlank(qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c)) {
                            List<String> strOldCLI = qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',');
                            if (strOldCLI != null && !strOldCLI.isEmpty()) {
                                for (String str : strOldCLI) {
                                    str = str.trim();
                                    processedOldCLI.add(str+'-'+qliExpansion.Sales_Comp_Category__c);
                                }
                            }
                        }
                    }//FOR Loop CLOSED : Expansion QLIs
                }
            }// loop for quote
        }//Lists not empty check closed
        if(allQuotes != null && !allQuotes.IsEmpty()){
            for(SBQQ__Quote__c quoteRec: allQuotes){
                if(quoteRec.SBQQ__Type__c == 'Renewal'){
                    priorACV = 0;
                    newSaleNetTotal = 0;
                    renewalGrowthExpQLI = 0;
                    expansionACV = 0;
                    if(mapExpansionQLIs != null && !mapRenewalQLIs.IsEmpty() && mapRenewalQLIs.containsKey(quoteRec.Id) && mapRenewalQLIs.get(quoteRec.Id) != NULL){
                        for(SBQQ__QuoteLine__c qliRenewal: mapRenewalQLIs.get(quoteRec.Id)){
                            if(renewalAmtForRenewingQLI != null){
                                renewalACV = renewalAmtForRenewingQLI;
                            }
                            if(qliRenewal.ExpACV__c != null && qliRenewal.Quote_Line_Type__c == 'New'){
                                expansionACV += qliRenewal.ExpACV__c;
                            }
                            if(qliRenewal.ACV__c != null){
                                renewalGrowthExpQLI += qliRenewal.ACV__c; 
                            }
                            if(qliRenewal.Quote_Line_Type__c == 'New' && qliRenewal.ACV__c != null){
                                newSaleNetTotal += qliRenewal.ACV__c; 
                            }
                            else{
                                newSaleNetTotal = 0;   
                            }
                            if(qliRenewal.RTAwithoutUplift__c != null && qliRenewal.Arroyo_Subscribed_Asset_Name__c == null){
                                priorACV += qliRenewal.RTAwithoutUplift__c;
                            }
                            if((qliRenewal.Disposition_Reason__c == null || qliRenewal.Disposition_Reason__c == 'None') && (qliRenewal.Quote_Line_Type__c != 'Existing' || qliRenewal.SBQQ__RenewedAsset__c == null)){
                                isDispositionReasonMissing = true;
                            }
                        }
                    }
                }
                if(quoteRec.SBQQ__Type__c == 'Renewal+Expansion'|| quoteRec.SBQQ__Type__c == 'Amendment' || quoteRec.SBQQ__Type__c == 'Quote'){ //REEN-121
                    if(mapExpansionQLIs != null && !mapExpansionQLIs.IsEmpty() && mapExpansionQLIs.containsKey(quoteRec.Id) != null && mapExpansionQLIs.get(quoteRec.Id) != null){
                        for(SBQQ__QuoteLine__c qliExpansion: mapExpansionQLIs.get(quoteRec.Id)){
                            if(qliExpansion.SubsRenAmt__c != null){
                                expTotalSubsumedAmt += qliExpansion.SubsRenAmt__c;
                            }
                            if(renewalAmtForRenewingQLI != null){
                                renewalACV = (expTotalSubsumedAmt!= null)?  expTotalSubsumedAmt + renewalAmtForRenewingQLI: renewalAmtForRenewingQLI;
                            }
                            if(qliExpansion.ExpACV__c != null && qliExpansion.Quote_Line_Type__c == 'New'){
                                expansionACV += qliExpansion.ExpACV__c;
                            }
                            if(qliExpansion.ACV__c != null){
                                renewalGrowthExpQLI += qliExpansion.ACV__c; 
                            }
                        }
                    }
                }
                if(priorACV != null){
                    quoteRec.PriorACV__c = (rtaToBeRemoved != null)? (priorACV - rtaToBeRemoved).setScale(2, RoundingMode.HALF_UP):priorACV.setScale(2, RoundingMode.HALF_UP);
                }
                if(rtaAmount != null){
                    quoteRec.RTA__c = (rtaToBeRemoved != null)? (rtaAmount - rtaToBeRemoved).setScale(2, RoundingMode.HALF_UP):rtaAmount.setScale(2, RoundingMode.HALF_UP);
                }
                if(maxRenewalAmt != null){
                    quoteRec.MaxRenAmt__c = upliftedPriorACVToBeRemoved != null? (maxRenewalAmt - upliftedPriorACVToBeRemoved).setScale(2, RoundingMode.HALF_UP):maxRenewalAmt.setScale(2, RoundingMode.HALF_UP);
                }
                if(renewalAmtForRenewingQLI != null){
                    quoteRec.TotalACV__c = (newSaleNetTotal!= null)? (renewalAmtForRenewingQLI + newSaleNetTotal).setScale(2, RoundingMode.HALF_UP): (renewalAmtForRenewingQLI).setScale(2, RoundingMode.HALF_UP);
                }
                if(renewalACV != null){
                    quoteRec.RenACV__c = renewalACV.setScale(2, RoundingMode.HALF_UP);
                }
                if(expansionACV != null){
                    quoteRec.ExpACV__c = expansionACV.setScale(2, RoundingMode.HALF_UP); 
                    //ARY-1150 Starts
                    if (quoteRec.ExpACV__c < 0) {
                        quoteRec.ExpACV__c = 0.00;
                    }
                    //ARY-1150 Ends
                }
                if(expTotalSubsumedAmt != null){
                    quoteRec.RenSubACV__c = expTotalSubsumedAmt.setScale(2, RoundingMode.HALF_UP);
                }
                if(grossChurn != null){
                    quoteRec.GrossChurn__c = grossChurn.setScale(2, RoundingMode.HALF_UP);
                }
                if(rtaAmount != null && grossChurn != null){
                    quoteRec.GrossChurnRate__c = (rtaAmount != null && rtaAmount >0)? ((grossChurn / rtaAmount) * 100).setScale(2, RoundingMode.HALF_UP): 0;
                }
                if(renewalGrowthQLI != null){
                    quoteRec.RenGrowth__c = renewalGrowthQLI.setScale(2, RoundingMode.HALF_UP);
                }
                if(renewalGrowthQLI != null && expansionACV != null){
                    quoteRec.RenExpGrowth__c = (renewalGrowthQLI + expansionACV).setScale(2, RoundingMode.HALF_UP);
                }
                quoteRec.NetChurnRate__c = (quoteRec.GrossChurn__c != null && quoteRec.RenExpGrowth__c != null && quoteRec.RTA__c > 0)? (((quoteRec.GrossChurn__c - quoteRec.RenExpGrowth__c) / quoteRec.RTA__c ) * 100).setScale(2, RoundingMode.HALF_UP): 0;
                quoteRec.MetricsLastCalcOn__c = system.now();
                if(setHasChurnAtQuote == true){
                    quoteRec.HasChurn__c = true;
                }
                if(isDispositionReasonMissing == true){
                    quoteRec.MetricCalcStatus__c = 'FailedDR';
                }
                if(isDispositionReasonMissing == false && quoteRec.SBQQ__Type__c == 'Renewal'){
                    quoteRec.MetricCalcStatus__c = 'Success';
                }
                if(quoteRec.SBQQ__Type__c == 'Renewal+Expansion' && counter == 0){
                    quoteRec.MetricCalcStatus__c = 'FailedNoExpQLI';
                }
                if(isDispositionReasonMissing == false && counter != 0 && (quoteRec.SBQQ__Type__c == 'Renewal+Expansion' || quoteRec.SBQQ__Type__c == 'Quote' || quoteRec.SBQQ__Type__c == 'Amendment') && quoteRec.ExpACV__c != null && quoteRec.ExpACV__c != 0){  //REEN-121
                    quoteRec.MetricCalcStatus__c = 'Success';
                }
                if(isDispositionReasonMissing == false && counter != 0 && quoteRec.SBQQ__Type__c == 'Renewal+Expansion' && quoteRec.MaxRenAmt__c != null && quoteRec.RTA__c != null && quoteRec.NetChurnRate__c != null){
                    quoteRec.MetricCalcStatus__c = 'Success';
                }
                if(isDispositionReasonMissing == false && quoteRec.SBQQ__Type__c == 'Renewal' && quoteRec.MaxRenAmt__c != null && quoteRec.RTA__c != null && quoteRec.NetChurnRate__c != null){
                    quoteRec.MetricCalcStatus__c = 'Success';
                }
                quoteToUpdate.add(quoteRec);
            }
        }
        Boolean systemErrorCaught = false;
        try{
            if(quoteToUpdate != null && !quoteToUpdate.IsEmpty()){
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                Database.SaveResult[] sRlt = Database.update(quoteToUpdate, false);
                LogError.createDMLErrorLog(quoteToUpdate, sRlt, 'metricCalcForArroyoQueueable_v2', 'metricCalcForArroyoQueueable_v2');
                SBQQ.TriggerControl.disable();
            }
        }
        catch (Exception e){
            System.debug('Insert Error System Error:' + e.getMessage());
            systemErrorCaught = true;
        }
        if(systemErrorCaught == true){
            if(allQuotes != null && !allQuotes.IsEmpty()){
                for(SBQQ__Quote__c quoteRec: allQuotes){
                    quoteRec.MetricCalcStatus__c = 'SystemError';  
                    quoteToUpdate.add(quoteRec);
                }
            }
            if(quoteToUpdate != null && !quoteToUpdate.IsEmpty()){                
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                update quoteToUpdate;
                SBQQ.TriggerControl.disable();
            }
        }
        if(qliListToUpdate != null && !qliListToUpdate.IsEmpty()){
            for(SBQQ__QuoteLine__c qli: qliListToUpdate){
                if(!qliListToUpdateMap.containsKey(qli.Id)){
                    qliListToUpdateMap.put(qli.Id, qli);
                }
                else{
                    qliListToUpdateMap.put(qli.Id, qli);
                }
            }
        }
        try{
            if(qliListToUpdateMap.values().size() > 0){
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                update qliListToUpdateMap.values();
                SBQQ.TriggerControl.disable();
            }
            if(quoteIds != null && !quoteIds.IsEmpty() && quoteIds.size() > 0){
                OpportunityArroyoMatrixCalculator.copyMatrixValuesToOpportunity(quoteIds);
            }
        }
        catch (Exception e){
            System.debug('Insert Error:' + e.getMessage());
        }
    }
    //ARY-1079 Starts
    public static Map<Id, SBQQ__QuoteLine__c> calculateMetricsForReplaced (SBQQ__QuoteLine__c qliRenewal, SBQQ__QuoteLine__c qliExpansion, List<String> lststr, Set<Id> processedRenLine) {
        Map<Id, SBQQ__QuoteLine__c> mapToRet = new Map<Id, SBQQ__QuoteLine__c>();
        if (!processedRenLine.contains(qliRenewal.Id) && lststr != null && !lststr.isEmpty()) {
            for (String oldCLI : lststr) {
                oldCLI = oldCLI.trim();
                if (!processedRenLine.contains(qliRenewal.Id) && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && !qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c.contains(oldCLI)) {
                    qliExpansion.SubsRenAmt__c = qliExpansion.SubsRenAmt__c != null? (qliExpansion.SubsRenAmt__c + qliRenewal.RTAwithoutUplift__c):qliRenewal.RTAwithoutUplift__c;
                    qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c != '') ? qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c + ' , ' +qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c:qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c;
                    mapToRet.put(qliExpansion.Id, qliExpansion);
                    //processedRenLine.add(qliRenewal.Id);
                }
                else if (!processedRenLine.contains(qliRenewal.Id) && qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c == null){
                    qliExpansion.SubsRenAmt__c = qliRenewal.RTAwithoutUplift__c;
                    qliExpansion.Arroyo_Subsumed_Old_Contract_Line_Items__c = qliRenewal.Arroyo_Subsumed_Old_Contract_Line_Items__c;
                    //processedRenLine.add(qliRenewal.Id); 
                    mapToRet.put(qliExpansion.Id, qliExpansion);
                }
            }
        }
        return mapToRet;
    }
    
    //ARY-1079 Starts
}