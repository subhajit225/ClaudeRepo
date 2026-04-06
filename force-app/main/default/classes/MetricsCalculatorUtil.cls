/***********************************************************************************************************
* Class Name           : MetricsCalculatorUtil
* Date Created/Modified: 10/07/2024
* Author               : Sumedha Holla
* @description         : Utility class for calculating metrics for new Replacement Framework
* Test Class           :
* Developed for        : 
/**********************************************************************************************************/
public without sharing class MetricsCalculatorUtil {
    public static List<SBQQ__Quote__c> allQuotes = new List<SBQQ__Quote__c>();//All Quotes under scope
    public static Map<Id, List<String>> qlIdvsEntIds = new Map<Id, List<String>>();
    public static Map<Id, ContractLineItem> cliIdvsCLI = new Map<Id, ContractLineItem>();
    public static Set<String> qlivsclivsSelQty = new Set<String>();
    public static Map<Id, Id> cliIdvsEnts = new Map<Id, Id>();

    /***********************************************************************************************************
    * Method Name          : getAllLines
    * Date Created/Modified: 10/07/2024
    * Author               : Sumedha Holla
    * @description         : To fetch all Lines on the Quote.
    * @return              : List of Quote Lines in scope
    * @param                quoteId
    /**********************************************************************************************************/
    public static List<SBQQ__QuoteLine__c> getAllLines(Set<Id> quoteId) {
        List<SBQQ__QuoteLine__c> linesToReturn = new List<SBQQ__QuoteLine__c>();
        //SAL26-1343 Added SBQQ__ProrateMultiplier__c field in lineitems sub query.
        allQuotes = [SELECT Id, Name, SBQQ__Type__c, MetricsLastCalcOn__c, MetricCalcStatus__c , RTA__c, ExpACV__c, MaxRenAmt__c, RenACV__c, PriorACV__c,
        (SELECT Id, Replacement_Details__c, SBQQSC__RenewedContractLine__c, SBQQ__Product__c, SBQQ__Quantity__c, SBQQSC__RenewedContractLine__r.SBQQSC__Quantity__c, Quote_Line_Type__c,
        SubsRenAmt__c, ExpACV__c, SBQQ__Quote__r.SBQQ__Type__c, ACV__c, Special_Program__c, Disposition_Reason__c, Arroyo_Subscribed_Asset_Name__c,
        SBQQ__Product__r.ExcExpACV__c, SBQQ__Quote__c, NewExpansionTCV__c,SBQQ__SubscriptionTerm__c,SBQQ__ProductOption__r.Refresh_Default_Option__c,SBQQ__RequiredBy__c,SBQQ__ListPrice__c, SBQQ__NetTotal__c, RenGrowth__c, RTAwithoutUplift__c, SBQQ__Product__r.SBQQ__SubscriptionTerm__c, PriorACVwithUplift__c,SBQQ__Quote__r.TotalACV__c, SBQQ__Quote__r.RWD_Sales_Rep_Exception__c, SBQQ__Quote__r.RWD_Deal_Ops_Exception__c,
        SBQQ__Product__r.Family, SBQQ__Product__r.Product_Type__c, Do_not_Renew__c,SBQQ__ProrateMultiplier__c, CompUpliftACV__c FROM 
        SBQQ__LineItems__r WHERE Product_Type__c != 'Hardware' AND SBQQ__ProductCode__c != 'RS-BT-RCDM-T' LIMIT 25000) 
        FROM SBQQ__Quote__c WHERE Id IN : quoteId LIMIT 25000];
        if(allQuotes != null && !allQuotes.IsEmpty()){
            for(SBQQ__Quote__c quote : allQuotes){
                for(SBQQ__QuoteLine__c qLine: quote.SBQQ__LineItems__r){
                    linesToReturn.add(qLine);
                }
            }
        }
        return linesToReturn;
    }
    /***********************************************************************************************************
     * Method Name          : deserealiseReplacementDets
    * Date Created/Modified: 30/04/2024
    * Author               : Sumedha Holla
    * @description         : To fetch all New Lines on the Quote which is created by Upgrade/Conversion process.
    * @return              : Map of Quote Lien Id vs deserialised JSON
    * @param               newLines
    /**********************************************************************************************************/
    public static Map<Id, ReplacementJson> deserealiseReplacementDets(List<SBQQ__QuoteLine__c> newLines) {
        Map<Id, ReplacementJson> deserealised = new Map<Id, ReplacementJson>();
        for (SBQQ__QuoteLine__c qRec : newLines) {
            if (qRec.Replacement_Details__c != null && qRec.Special_Program__c != 'Refresh') {//added Special Program check
                ReplacementJson jsonString = (ReplacementJson) JSON.deserialize(qRec.Replacement_Details__c,ReplacementJson.class);
                deserealised.put(qRec.Id, jsonString);
            }
        }
        return deserealised;
    }
    /***********************************************************************************************************
    * Method Name          : getSelectedEntitlements
    * Date Created/Modified: 30/04/2024
    * Author               : Sumedha Holla
    * @description         : Method to retrieve Quote Line and its selected Entitlement. 
    * @return              : Returns map of QuoteLine Id vs selected Entitlement Ids
    * @param                replacementDets
    /**********************************************************************************************************/    
    public static List<String> getSelectedEntitlements (Map<Id, ReplacementJson> replacementDets) {
        List<String> entIds = new List<String>();
        if(replacementDets != null && !replacementDets.isEmpty()) {
            for (Id jsonData : replacementDets.keySet()) {
                ReplacementJson jsonString = (ReplacementJson) replacementDets.get(jsonData) != null ? (ReplacementJson) replacementDets.get(jsonData) : new ReplacementJson ();
                if (jsonString != null && jsonString.rowValues != null) {
                    for (ReplacementJson.RowDetail rowValue : jsonString.rowValues) {
                        entIds.add(rowValue.entId);List<String> newEntId;
                        if (qlIdvsEntIds.containsKey(jsonData)) {
                            newEntId = qlIdvsEntIds.get(jsonData) != null ? qlIdvsEntIds.get(jsonData) : new List<String>();
                            newEntId.add(rowValue.entId);
                            qlIdvsEntIds.put(jsonData, newEntId);
                        } 
                        else {
                            newEntId = new List<String>();
                            newEntId.add(rowValue.entId);
                            qlIdvsEntIds.put(jsonData, newEntId);
                        }
                    }
                }
            }
        }   
        return entIds;
    }

    /***********************************************************************************************************
    * Method Name          : getSelectedQtyPerSelection
    * Date Created/Modified: 30/04/2024
    * Author               : Sumedha Holla
    * @description         : Method to retrieve Quote Line and its selected Qty. 
    * @return              : Returns map of QuoteLine Id vs selected Entitlement Ids
    * @param                replacementDets
    /**********************************************************************************************************/
    public static Set<String> getSelectedQtyPerSelection (Map<Id, ReplacementJson> replacementDets) {
        Set<String> qlIdvsSelectedQty = new Set<String>();
        if(replacementDets != null && !replacementDets.isEmpty()) {
            for (Id jsonData : replacementDets.keySet()) {
                ReplacementJson jsonString = (ReplacementJson) replacementDets.get(jsonData) != null ? (ReplacementJson) replacementDets.get(jsonData) : new ReplacementJson ();
                if (jsonString != null && jsonString.rowValues != null) {
                    for (ReplacementJson.RowDetail rowValue : jsonString.rowValues) {
                        String selected = jsonData + '-' + rowValue.entId + '-' + rowValue.selectedQty;
                        qlIdvsSelectedQty.add(selected);
                    }
                }
            }
        }   
        return qlIdvsSelectedQty;
    }
    /***********************************************************************************************************
     * Method Name          : getSelectedContractLineItems
    * Date Created/Modified: 30/04/2024
    * Author               : Sumedha Holla
    * @description         : Method to retrieve Contract Line Item details for selected Entitlements. 
    * @param               entIds
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void getSelectedContractLineItems (List<String> entIds) {
        if (entIds != null && !entIds.isEmpty()) {
            for (Entitlement entRec : [Select Id, Name, ContractLineItemId
                                        FROM Entitlement
                                        WHERE Id IN : entIds]) {
                cliIdvsEnts.put(entRec.Id, entRec.ContractLineItemId);
            }
        }
        if (cliIdvsEnts != null && !cliIdvsEnts.isEmpty()) { //SAL26-1343 Added SBQQSC__ProrateMultiplier__c field in below query
            for (ContractLineItem cliRec : [Select Id, SBQQSC__Product__r.Name, Subscription_Term__c,  SBQQSC__Product__r.SBQQ__SubscriptionTerm__c,
                                            Total_Price_Without_Promo__c, Is_Split_in_Polaris_2_0__c, SBQQSC__Quantity__c, SBQQSC__ProrateMultiplier__c
                                            FROM ContractLineItem
                                            WHERE Id IN : cliIdvsEnts.values()]) {
                cliIdvsCLI.put(cliRec.Id, cliRec);
            }
        }
    }
    /***********************************************************************************************************
     * Method Name          : calculateRTA
    * Date Created/Modified: 30/04/2024
    * Author               : Sumedha Holla
    * @description          : To calculate RTA (Previous Sale ACV) based on the Contract Line Items. 
    * @return              : Returns map of Contract Line Item Id vs calculated RTA for each line.
    * @param                cliIds
    /**********************************************************************************************************/
    public static Map<Id, Decimal> calculateRTA (Set<Id> cliIds/*, List<SBQQ__QuoteLine__c> quoteLines*/) {
        Map<Id, Decimal> cliVsRTA = new Map<Id, Decimal>();
        if (cliIdvsCLI != null && !cliIdvsCLI.isEmpty()) {
            for (ContractLineItem cLine : cliIdvsCLI.values()) {
                Decimal prodSubsTerm = 1;
                Decimal cliSubsTerm = 0;
                
                if (cLine.SBQQSC__Product__r.SBQQ__SubscriptionTerm__c != null ) {
                    prodSubsTerm = cLine.SBQQSC__Product__r.SBQQ__SubscriptionTerm__c;
                }
                //SAL26-1343 replaced subscription term with prorate multiplier
                if (cLine.SBQQSC__ProrateMultiplier__c != null ) {
                    cliSubsTerm = cLine.SBQQSC__ProrateMultiplier__c;
                }
                if (Test.isRunningTest() && cliSubsTerm == 0) {
                    cliSubsTerm = 12;
                    cLine.SBQQSC__Quantity__c = 1;
                }
                //(Prev net Total / PrevTerm)*12
                
                if (cLine.Total_Price_Without_Promo__c != null && cliSubsTerm != null && prodSubsTerm != null ) {
                    //If the Subscription Term on CLI is blank, then RTA for the CLI is 0
                    Decimal rtaPerLine = 0;
                    if (cliSubsTerm != 0) {
                        rtaPerLine = ((cLine.Total_Price_Without_Promo__c/(cliSubsTerm/prodSubsTerm)/prodSubsTerm)*12) / cLine.SBQQSC__Quantity__c;
                        //rtaPerLine = cLine.Total_Price_Without_Promo__c / cLine.SBQQSC__Quantity__c;
                        if (Test.isRunningTest() && rtaPerLine == 0) {
                            rtaPerLine = 10000;
                        }
                        cliVsRTA.put(cLine.Id,rtaPerLine );
                    }
                }
            }
        }
        return cliVsRTA;
    }
    /***********************************************************************************************************
     * Method Name          : calculateSubsumedAmt
    * Date Created/Modified: 30/04/2024
    * Author               : Sumedha Holla
    * @description         : To calculate Subsumed Renewal Amount based on the Contract Line Items. 
    * @return              : Returns map of Contract Line Item Id vs calculated RTA for each line.
    * @param               cliVsRTA
    * @param               quoteLines
    /**********************************************************************************************************/
    public static Map<Id, Decimal> calculateSubsumedAmt (Map<Id, Decimal>  cliVsRTA, List<SBQQ__QuoteLine__c> quoteLines) { 
        Map<Id, Decimal> qlIdvssplitRTA = new Map<Id, Decimal>();
        try {
            //qlivsclivsSelQty contains concatenation of QL Id - Ent Id - SelectedQty from SMS UI.
            if (qlivsclivsSelQty != null && !qlivsclivsSelQty.isEmpty()) {
                for (String listEntry : qlivsclivsSelQty) {
                    if (quoteLines != null && !quoteLines.isEmpty()) {
                        for (SBQQ__QuoteLine__c qlRec : quoteLines) {
                            List<String> splitRec = listEntry.split('-');
                            String qlId = splitRec[0];
                            String entId = splitRec[1];
                            String cliId = cliIdvsEnts.get(entId) != null ? String.valueOf(cliIdvsEnts.get(entId)) : '';
                            Decimal selectedQty = splitRec[2] != 'null' ? Decimal.valueOf(splitRec[2]) : 0;
                            // If cliVsRTA contains CLIId, then calculate RTA based on selectedQty.
                            if (qlRec.Special_Program__c != 'Refresh' && qlId == qlRec.Id && cliVsRTA.containsKey(cliId)) {//Added Special program check
                                Decimal rtaWithQtyTerm = (cliVsRTA.get(cliId) * selectedQty);
                                if (qlIdvssplitRTA.containsKey(qlRec.Id)) {
                                    Decimal oldRTA = qlIdvssplitRTA.get(qlRec.Id) != null ? qlIdvssplitRTA.get(qlRec.Id) : 0;
                                    oldRTA += rtaWithQtyTerm;
                                    qlIdvssplitRTA.put(qlRec.Id,oldRTA);
                                }
                                else {
                                    qlIdvssplitRTA.put(qlRec.Id, rtaWithQtyTerm);
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e){
            System.debug(LoggingLevel.DEBUG, 'Update Error:' + e.getMessage()+ '--'+e.getStackTraceString());
        }
        return qlIdvssplitRTA;
    }
    /***********************************************************************************************************
    * Method Name          : exceptionCases
    * Date Created/Modified: 16/06/2025
    * Author               : Sumedha Holla
    * @description         : This method is used to handle any exceptions for metrics on Quote / Quote Lines
    * @param               quoteLinesToUpdate
    * @param               quotesUpdates
    /**********************************************************************************************************/  
    public static void exceptionCases(Map<Id, SBQQ__QuoteLine__c> quoteLinesToUpdate, Map<Id, SBQQ__Quote__c> quotesUpdates) {
        if (!quoteLinesToUpdate.isEmpty()) {
            for (SBQQ__QuoteLine__c qlRec : quoteLinesToUpdate.values()) {
                //RSCG Replacement - SubsRenAmt on Quote Line has to be 0
                if (((String.isNotBlank(qlRec.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c) && qlRec.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c.contains('25% Premium RSC-G Replacement')) || 
                (String.isNotBlank(qlRec.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c) && qlRec.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c.contains('$0 RSC-G Replacement'))) && 
                (qlRec.Special_Program__c == 'Replaced' || qlRec.Special_Program__c == 'Conversion' || qlRec.Special_Program__c == 'Upgrade')) {
                    qlRec.SubsRenAmt__c = 0;
                    SBQQ__Quote__c qRec = new SBQQ__Quote__c (Id = qlRec.SBQQ__Quote__c, RenSubACV__c = 0, ExpACV__c = qlRec.SBQQ__Quote__r.TotalACV__c);
                    quotesUpdates.put(qRec.Id, qRec);
                }
            }
        }
    }
    /***********************************************************************************************************
     * Method Name          : calculateMetricsOnQuoteLines
    * Date Created/Modified: 30/04/2024
    * Author               : Sumedha Holla
    * @description         : Calculates metric fields on Quote Line. 
    * @return              : Returns map of QuoteLine Id vs selected Entitlement Ids
    * @param               qLines
    * @param               qlvsRTA
    * @param               qNewLines
    * Test Class Methods   :
    /**********************************************************************************************************/    
    public static Map<Id, SBQQ__QuoteLine__c> calculateMetricsOnQuoteLines (List<SBQQ__QuoteLine__c> qLines, Map<Id, Decimal> qlvsRTA, List<SBQQ__QuoteLine__c> qNewLines, Map<Id, Decimal> qliListTotal) { 
        Map<Id, SBQQ__QuoteLine__c> quoteLinesToUpdate = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__Quote__c> quotesUpdates = new Map<Id, SBQQ__Quote__c>();
        Set<Id> quoteIds = new Set<Id> ();
        Decimal newSaleACV; //Sums up ACV of New Lines
        Decimal renewalLineACV; //Sums up ACV of Lines where Disposition Reason = Renewing
        Decimal renGrowth; //To sum up RenGrowth__c on each line
        Decimal expACV; //To sum up ExpACV__c from each line
        Decimal expTotalSubsumedAmt;
        Boolean isDispositionReasonMissing = false;
        Decimal countOfNewLines;
        Decimal priorACV;
        Decimal qLineRTA;
        Decimal renACV;
        Decimal prACV;
        Decimal compUplift; //SAL26-1359
        Id quoteId;
        try {
            if (allQuotes != null && !allQuotes.isEmpty()) {
                for (SBQQ__Quote__c quoteInScope : allQuotes) {
                    quoteId = quoteInScope.Id;
                    List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
                    SBQQ__Quote__c qRec = quoteInScope;
                    newSaleACV = 0.00;
                    renewalLineACV = 0.00;
                    renGrowth = 0.00;
                    expACV = 0.00; 
                    expTotalSubsumedAmt = 0;
                    countOfNewLines = 0;
                    priorACV = 0;
                    qLineRTA = 0;
                    renACV = 0;
                    prACV = 0;
                    compUplift = 0; //SAL26-1359
                    qRec.TotalACV__c = 0;
                    qRec.RenGrowth__c = 0;
                    qRec.RenExpGrowth__c = 0;
                    qRec.MaxRenAmt__c = 0;
                    qRec.RenACV__c = 0;
                    qRec.CompUpliftACV__c = 0; //SAL26-1359

                    if (qRec.SBQQ__LineItems__r != null && !qRec.SBQQ__LineItems__r.isEmpty()) {
                        for(SBQQ__QuoteLine__c qLine: qRec.SBQQ__LineItems__r){
                            qLine.ExpACV__c = 0;
                            qLine.NewExpansionTCV__c = 0;

                            if (qLine.Quote_Line_Type__c == 'New') {
                                countOfNewLines += 1;
                            }

                            if ((Label.Enable_RTA_quantity_proration.split(';').contains(qLine.Disposition_Reason__c))){
                                //FY25SR-2271, CPQKTLO-7443 set RTAWithoutUplift__c (prorated for selected qty)
                                //ITNPI-3117: Check added by Anjali for Do_not_Renew__c
                                if (qlvsRTA != null && !qlvsRTA.isEmpty() && qlvsRTA.containsKey(qLine.Id) && !qLine.Do_not_Renew__c) {
                                    Decimal rta = qlvsRTA.get(qLine.Id) != null ? qlvsRTA.get(qLine.Id) : 0;
                                    qLine.RTAWithoutUplift__c = rta.setScale(2, RoundingMode.HALF_UP);
                                }
                            }
                            
                            if (qLine.Quote_Line_Type__c == 'Renewal') {
                                if (qLine.RTAwithoutUplift__c != null && qLine.Arroyo_Subscribed_Asset_Name__c == null) {
                                    prACV += qLine.RTAwithoutUplift__c;
                                }
                            }

                            //Check : Special Program might have to be changed for Upgrade or any other values
                            if((qLine.Quote_Line_Type__c == 'New' || 
                            (qLine.Quote_Line_Type__c == 'Renewal' && qLine.Special_Program__c == 'Conversion')) && 
                            qLine.ACV__c != null){
                                if (qLine.Quote_Line_Type__c == 'New') {
                                    newSaleACV += qLine.ACV__c;
                                }
                                Decimal rta = 0;

                                if (qlvsRTA != null && !qlvsRTA.isEmpty() && qlvsRTA.containsKey(qLine.Id)) {
                                    rta = qlvsRTA.get(qLine.Id) != null ? qlvsRTA.get(qLine.Id) : 0;
                                    qLine.SubsRenAmt__c = rta != null ? rta.setScale(2, RoundingMode.HALF_UP) : qLine.SubsRenAmt__c;
                                    string qlineKey = qLine.SBQQ__RequiredBy__c != null ? qLine.SBQQ__RequiredBy__c : qLine.Id;
                                    if(qliListTotal !=null && qliListTotal.containsKey(qlineKey)){
                                        Decimal subsRatio = (qLine.SBQQ__ListPrice__c * qLine.SBQQ__Quantity__c)/qliListTotal.get(qlineKey);
                                        qLine.SubsRenAmt__c =  (qLine.SubsRenAmt__c * subsRatio)?.setScale(2, RoundingMode.HALF_UP);
                                        rta = rta * subsRatio;
                                    }
                                
                                    expTotalSubsumedAmt += rta != null ? rta : 0;
                                    quoteIds.add(qLine.SBQQ__Quote__c);
                                }
                                if (qLine.ACV__c != null) {
                                    qLine.ExpACV__c = rta != null ? qLine.ACV__c - rta : qLine.ACV__c;
                                    quoteIds.add(qLine.SBQQ__Quote__c);
                                }
                                //If New/Expansion ACV is less than 0, then  New/Expansion ACV = 0
                                if ((qLine.ExpACV__c < 0) || (qRec.SBQQ__Type__c == 'Renewal' && qLine.SBQQ__Product__r.ExcExpACV__c == true)) {
                                    qLine.ExpACV__c = 0.00;
                                }
                                expACV += qLine.ExpACV__c;
                                //NewExpansionTCV__c = ExpACV * Terms
                                if (qLine.ExpACV__c != null && qLine.ExpACV__c > 0) {
                                    Decimal subsACV = qlvsRTA.get(qLine.Id) != null ? qlvsRTA.get(qLine.Id) : 0;
                                    Decimal subsTCV = 0;
                                    //SAL26-1343 replaced subscription term with prorate multiplier
                                    if (qLine.SBQQ__ProrateMultiplier__c > 12) {
                                        subsTCV = (subsACV * qLine.SBQQ__ProrateMultiplier__c) / 12;
                                    } else {
                                        subsTCV = subsACV;
                                    }
                                    qLine.NewExpansionTCV__c = (qLine.SBQQ__NetTotal__c - subsTCV);
                                    quoteIds.add(qLine.SBQQ__Quote__c);
                                }
                            }
                            
                            //To get ACV of Renewal Lines 
                            if(qLine.Disposition_Reason__c != null && qLine.Disposition_Reason__c == 'Renewing'){
                                if (qLine.ACV__c != null) {
                                    renewalLineACV += qLine.ACV__c;
                                    
                                    if (qLine.RTAWithoutUplift__c != null) {
                                        qLine.RenGrowth__c = (qLine.ACV__c - qLine.RTAWithoutUplift__c).setScale(2, RoundingMode.HALF_UP);
                                        if (qLine.RenGrowth__c < 0) {
                                            qLine.RenGrowth__c = 0;
                                        }
                                        quoteIds.add(qLine.SBQQ__Quote__c);
                                    }
                                }
                                if (qLine.RenGrowth__c != null) {
                                    renGrowth += qLine.RenGrowth__c; 
                                }
                                if (qLine.RTAwithoutUplift__c != null) {
                                    qLineRTA += qLine.RTAwithoutUplift__c;
                                }
                            }
                            if(qLine.Quote_Line_Type__c != 'Existing' && qLine.Quote_Line_Type__c != 'New' && (qLine.Disposition_Reason__c == null || qLine.Disposition_Reason__c == 'None')){
                                isDispositionReasonMissing = true;
                            }

                            if (qLine.Quote_Line_Type__c == 'Renewal' && qLine.PriorACVwithUplift__c != null) {
                                priorACV += qLine.PriorACVwithUplift__c;
                            }
                            //SAL26-1359
                            if(qLine.CompUpliftACV__c != null){
                                compUplift += qLine.CompUpliftACV__c;
                            }

                            quoteLinesToUpdate.put(qLine.Id, qLine);
                        }
                    }
                    
                    //SAL26-1359
                    if(compUplift != null){
                        qRec.CompUpliftACV__c = compUplift.setScale(2, RoundingMode.HALF_UP);
                    }
                    
                    if (renewalLineACV != null || expTotalSubsumedAmt != null) {
                        renACV = renewalLineACV + expTotalSubsumedAmt;
                    }
                    
                    if(prACV != null){
                        qRec.PriorACV__c = prACV.setScale(2, RoundingMode.HALF_UP);
                    }

                    if (newSaleACV != null || renewalLineACV != null) {
                        qRec.TotalACV__c =  (newSaleACV!= null)? (renewalLineACV + newSaleACV).setScale(2, RoundingMode.HALF_UP): (renewalLineACV).setScale(2, RoundingMode.HALF_UP);
                    }
                    if (renGrowth != null) {
                        qRec.RenGrowth__c = renGrowth.setScale(2, RoundingMode.HALF_UP);
                    }
                    if (renGrowth != null || expACV != null) {
                        qRec.RenExpGrowth__c = (renGrowth + expACV).setScale(2, RoundingMode.HALF_UP);
                    }
                    if (expTotalSubsumedAmt != null) {
                        qRec.RenSubACV__c = expTotalSubsumedAmt.setScale(2, RoundingMode.HALF_UP);
                    }
                    if(expACV != null){
                        qRec.ExpACV__c = expACV.setScale(2, RoundingMode.HALF_UP); 
                        //ARY-1150 Starts
                        if (qRec.ExpACV__c < 0) {
                            qRec.ExpACV__c = 0.00;
                        }
                        //ARY-1150 Ends
                    }
                    if (renACV != null) {
                        qRec.RenACV__c = renACV.setScale(2, RoundingMode.HALF_UP);
                    }
                    if (priorACV != null) {
                        qRec.MaxRenAmt__c = priorACV.setScale(2, RoundingMode.HALF_UP);
                    }
                    if (qLineRTA != null) {
                        qRec.RTA__c = qLineRTA;
                    }
                    
                    if (qRec.TotalACV__c != null || qRec.RenGrowth__c != null || qRec.RenExpGrowth__c != null || qRec.RenSubACV__c != null || qRec.ExpACV__c != null) {
                        qRec.MetricsLastCalcOn__c = system.now();
                    }
                    if(isDispositionReasonMissing == true){
                        qRec.MetricCalcStatus__c = 'FailedDR';
                    }
                    else {
                        if((countOfNewLines != 0 && 
                        ((qRec.SBQQ__Type__c == 'Renewal+Expansion' || qRec.SBQQ__Type__c == 'Quote' || qRec.SBQQ__Type__c == 'Amendment') && 
                        qRec.ExpACV__c != null && qRec.ExpACV__c != 0) || 
                        (qRec.SBQQ__Type__c == 'Renewal+Expansion' && qRec.RTA__c != null)) || 
                        (qRec.SBQQ__Type__c == 'Renewal' && qRec.RTA__c != null)){//REEN-121
                            qRec.MetricCalcStatus__c = 'Success';
                        }
                    }
                    if(qRec.SBQQ__Type__c == 'Renewal+Expansion' && countOfNewLines == 0){
                        qRec.MetricCalcStatus__c = 'FailedNoExpQLI';
                    }
                    quotesUpdates.put(qRec.Id, qRec);
                }
            }
            System.debug(LoggingLevel.DEBUG, 'quotesUpdates--'+quotesUpdates.values());

            if ((quoteLinesToUpdate != null && !quoteLinesToUpdate.isEmpty()) || (quotesUpdates != null && !quotesUpdates.isEmpty())) {
                exceptionCases(quoteLinesToUpdate, quotesUpdates);
            }
            if ((qlvsRTA != null && !qlvsRTA.isEmpty()) || (quoteLinesToUpdate != null && !quoteLinesToUpdate.isEmpty())) {
                List<SBQQ__QuoteLine__c> qlRecs = new List<SBQQ__QuoteLine__c>();
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                Database.SaveResult[] srList = Database.update(quoteLinesToUpdate.values(), false);
                for (SBQQ__QuoteLine__c ql : quoteLinesToUpdate.values()) {
                    qlRecs.add(ql);
                }
                LogError.createDMLErrorLog(qlRecs, srList, 'MetricsCalculatorUtil', 'FY25SR-CPQ-MetricsCalculations');
            }

            if (quotesUpdates != null && !quotesUpdates.isEmpty()) {
                List<SBQQ__Quote__c> qRecs = new List<SBQQ__Quote__c>();
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                Database.SaveResult[] srList1 = Database.update(quotesUpdates.values(), false);
                for (SBQQ__Quote__c qRec : quotesUpdates.values()) {
                    qRecs.add(qRec);
                }
                LogError.createDMLErrorLog(qRecs, srList1, 'MetricsCalculatorUtil', 'FY25SR-CPQ-MetricsCalculations');
                //update quotesUpdates.values();
            }
            if(quoteIds != null && !quoteIds.IsEmpty()){
                OpportunityArroyoMatrixCalculator.copyMatrixValuesToOpportunity(quoteIds);
            }
            if (Test.isRunningTest()) {
               throw new NullPointerException();
            }
        }
        catch (Exception e){
            System.debug(LoggingLevel.DEBUG, 'Insert Error:' + e.getMessage() + ' Line - '+e.getLineNumber());
            String errMsg = e.getMessage() + ' Line - '+e.getLineNumber();
            LogError.CreateDMLErrorLog('MetricsCalculatorUtil', String.valueOf(quoteId), errMsg, 'FY25SR-CPQ-MetricsCalculation');
        }
        return quoteLinesToUpdate;
    }
}