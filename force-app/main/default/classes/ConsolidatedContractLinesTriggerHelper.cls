/**
* @File Name : ConsolidatedContractLinesTriggerHelper.cls
* @description : Helper class for Consolidated Contract Line Trigger
* Developed as part of : Arroyo Project
**/
public class ConsolidatedContractLinesTriggerHelper{
    public static Map<Id, ReplacementJson> mapOfJSON = new Map<Id, ReplacementJson>();
    public static Set<String> alreadySeen = new Set<String>();
    /***********************************************************************************************************
    * Method Name          : populatePriorNetTotalFields
    * @description         : Populates CCLI and Prior Net Total fields on Consolidated Quote Lines
    * @param               newCCLRecords
    /**********************************************************************************************************/
    public static void populatePriorNetTotalFields(List<Consolidated_Contract_Lines__c> newCCLRecords){
        Set<Id> quoteIdSet = new Set<Id>();
        List<SBQQ__QuoteLine__c> newQliList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> qliToUpdate = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> updatedQLIRec = new List<SBQQ__QuoteLine__c>();
        Decimal tempTotalPriceWithUplift = 0; //RWD-1459(Initialized the variable to 0)
        Decimal totalNetPriceWithUplift; //RWD-1459
        Set<Id> cliIds = new Set<Id>(); // FY25SR-1215 - Added to get CCLI Ids. 
        Map<String, Decimal> asstCap = new Map<String, Decimal>(); // FY25SR-1215 - Asset Id vs Usable Capacity
        Map<Id, List<String>> mapEntvsAstNames = new Map<Id, List<String>> ();  // FY25SR-1215 - Entitlement Id vs Asset Ids
        List<Entitlement> lstEnts = new List<Entitlement>();
        List<Scale_Entitlement__c> scEnts = new List<Scale_Entitlement__c>();
        Map<Id, List<String>> cliVsEntLst = new Map<Id, List<String>>();
        Map<Id, Map<String, String>> assetEntMap = new Map<Id, Map<String, String>>();
        Map<Id, Decimal> entQty = new Map<Id, Decimal>();

        for(Consolidated_Contract_Lines__c objRec: newCCLRecords){
            quoteIdSet.add(objRec.Quote_Line__c); 
        }
        
        if(!quoteIdSet.IsEmpty()){
            newQliList = ([SELECT Id, SBQQ__Product__r.CPQ_Uplift__c, CPQ_Uplift__c, SBQQ__Quote__c, SBQQ__Quote__r.Polaris_Conversion__c, 
                           SBQQ__NetPrice__c, SBQQ__Quantity__c, SBQQSC__RenewedContractLine__c, SBQQSC__RenewedContractLine__r.Subscription_Term__c, 
                           SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c,SBQQSC__RenewedContractLine__r.TotalPrice, SBQQ__ListTotal__c, SBQQSC__RenewedContractLine__r.Product_Level__c, 
                           Total_Prior_Net_Total__c, SBQQ__SubscriptionTerm__c, CCLI__c, Arroyo_Subsumed_Old_Contract_Line_Items__c, Replacement_Details__c, Product_Level__c, 
                           (SELECT Id, Contract_Line_Item__c, Contract_Line_Item__r.LineItemNumber, 
                            Contract_Line_Item__r.TotalPrice,Contract_Line_Item__r.Total_Price_Without_Promo__c FROM Consolidated_Contract_Lines__r) 
                           FROM SBQQ__QuoteLine__c WHERE Id IN: quoteIdSet]);
        }
        
        //FY25SR-1215 Changes start - Added below loop to get all associated CLIs
        if (!newQliList.isEmpty()) {
            for(SBQQ__QuoteLine__c qliVal: newQliList){ 
                for(Consolidated_Contract_Lines__c cclRec: qliVal.Consolidated_Contract_Lines__r){
                    if (String.isNotBlank(cclRec.Contract_Line_Item__c)) {
                        cliIds.add(cclRec.Contract_Line_Item__c);
                    }
                }
            }
        }
        //get Eligible Entitlements and Scale Entitlements related to CCLI Ids
        
        if (!cliIds.isEmpty()) {
            lstEnts = [Select Id, Name, AssetId, Asset.SerialNumber, Asset.Product_Usable_Capacity__c, Quantity__c, ContractLineItemId from Entitlement WHERE ContractLineItemId IN : cliIds AND Renewal_Category__c = NULL];
        }
        if (!cliIds.isEmpty()) {
            scEnts = [Select Id, Name, Entitlement__c, Asset__c, Asset__r.SerialNumber, Asset__r.Product_Usable_Capacity__c, Contract_Line_Item__c from Scale_Entitlement__c WHERE Contract_Line_Item__c IN : cliIds AND Renewal_Category__c = NULL];
        }
        //From the list of Entitlements, get map of CLIs vs Entitlements.
        if (!lstEnts.isEmpty()) {
            for (Entitlement ent : lstEnts) {
                entQty.put(ent.Id, ent.Quantity__c);
                if (cliVsEntLst.containsKey(ent.ContractLineItemId)) {
                    cliVsEntLst.get(ent.ContractLineItemId).add(ent.Id);
                } else {
                    cliVsEntLst.put(ent.ContractLineItemId, new List<String> { ent.Id });
                }
                //Formulate Asset associated with Entitleemnts
                if (String.isNotBlank(ent.AssetId)) {
                    Map<String, String> tempMap = new Map<String, String>();
                    if (assetEntMap.containsKey(ent.Id)) {
                        tempMap.put(ent.AssetId, ent.Asset.SerialNumber); 
                        assetEntMap.get(ent.Id).put(ent.AssetId, ent.Asset.SerialNumber);
                    } else {
                        tempMap.put(ent.AssetId, ent.Asset.SerialNumber); 
                        assetEntMap.put(ent.Id, tempMap);
                    }
                    //For storing Asset ids and Usable Capacity
                    asstCap.put(ent.AssetId, ent.Asset.Product_Usable_Capacity__c);
                }
            }
        }
        
        //From the list of Scale Entitlements, get Asset vs Entitlement map
        if (!scEnts.isEmpty()) {
            for (Scale_Entitlement__c scEnt : scEnts) {
                if (String.isNotBlank(scEnt.Asset__c)) {
                    Map<String, String> tempMap = new Map<String, String>();
                    if (assetEntMap.containsKey(scEnt.Entitlement__c)) {
                        tempMap.put(scEnt.Asset__c, scEnt.Asset__r.SerialNumber); 
                        assetEntMap.get(scEnt.Entitlement__c).put(scEnt.Asset__c, scEnt.Asset__r.SerialNumber);
                    } else {
                        tempMap.put(scEnt.Asset__c, scEnt.Asset__r.SerialNumber); 
                        assetEntMap.put(scEnt.Entitlement__c, tempMap);
                    }
                    //For storing Asset ids and Usable Capacity
                    asstCap.put(scEnt.Asset__c, scEnt.Asset__r.Product_Usable_Capacity__c);
                }
            }
        }

        mapEntvsAstNames = ReplacementRefreshUtility.getEntAsstList(assetEntMap);
        //FY25SR-1215 Changes Ends 
        
        if(!newQliList.IsEmpty()){
            for(SBQQ__QuoteLine__c qliVal: newQliList){
                Decimal tempCount = 0;
                tempTotalPriceWithUplift = 0;
                String consolidateCLIIds = '';
                /*Added by Shaloo: To populate Old CLI linkage along with Renewed CLI & CCLI value*/
                String oldCLIValue = '';
                
                for(Consolidated_Contract_Lines__c cclRec: qliVal.Consolidated_Contract_Lines__r){
                    if(consolidateCLIIds != ''){
                        consolidateCLIIds += ',';
                    }
                    consolidateCLIIds += cclRec.Contract_Line_Item__c;
                    
                    tempCount = tempCount + cclRec.Contract_Line_Item__r.Total_Price_Without_Promo__c; //Added tempCount +
                    
                    if(qliVal.SBQQ__Product__r.CPQ_Uplift__c != null && qliVal.SBQQ__Product__r.CPQ_Uplift__c != ''){
                        //RWD-1459 //Added tempTotalPriceWithUplift +
                        tempTotalPriceWithUplift = tempTotalPriceWithUplift + 
                            (cclRec.Contract_Line_Item__r.Total_Price_Without_Promo__c + 
                             ((cclRec.Contract_Line_Item__r.Total_Price_Without_Promo__c * Decimal.ValueOf(qliVal.SBQQ__Product__r.CPQ_Uplift__c))/100));
                    }
                }
                //FY25SR-1215 - call getReplacementDetails to populate JSON on Quote Lines
                if (String.isNotBlank(consolidateCLIIds)) {
                    List<String> cclis = consolidateCLIIds.split(',');
                    getReplacementDetails (qliVal, cclis, cliVsEntLst, assetEntMap, asstCap, mapEntvsAstNames, entQty);
                }
                
                String jsonData = JSON.serialize(mapOfJSON.containsKey(qliVal.Id) ? mapOfJSON.get(qliVal.Id) : null);
                String jsonToPop;
                if (jsonData != null) {
                    jsonToPop = jsonData;
                }
                //FY25SR-1215 Ends
                
                /*START: Added by Shaloo: To populate Old CLI linkage along with Renewed CLI & CCLI value*/
                if(qliVal.SBQQSC__RenewedContractLine__c != null && consolidateCLIIds == ''){
                    oldCLIValue = qliVal.SBQQSC__RenewedContractLine__c;
                }
                else if(qliVal.SBQQSC__RenewedContractLine__c == null && consolidateCLIIds != ''){
                    oldCLIValue = consolidateCLIIds;
                }
                else if(qliVal.SBQQSC__RenewedContractLine__c != null && consolidateCLIIds != ''){
                    oldCLIValue = qliVal.SBQQSC__RenewedContractLine__c + ',' + consolidateCLIIds;
                }
                else{
                    oldCLIValue = consolidateCLIIds;
                }
                /*END: Added by Shaloo: To populate Old CLI linkage along with Renewed CLI & CCLI value*/
                
                Decimal varCount = qliVal.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c;
                
                tempCount = tempCount + varCount;
                
                if(tempTotalPriceWithUplift != null
                   && qliVal.SBQQSC__RenewedContractLine__c != null
                   && qliVal.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c != null){
                       //Might need to multiply by Uplift here //RWD-1459
                       if(qliVal.SBQQ__Product__c != null && qliVal.SBQQ__Product__r.CPQ_Uplift__c != null){
                           totalNetPriceWithUplift = tempTotalPriceWithUplift + 
                               (varCount + ((qliVal.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c * Decimal.ValueOf(qliVal.SBQQ__Product__r.CPQ_Uplift__c))/100));   
                       }
                       else{
                           totalNetPriceWithUplift = tempTotalPriceWithUplift + 
                               (varCount + qliVal.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c);   
                       }
                   }

                
                //Added field Net Price Total with Uplift for RWD-1459
                //FY25SR-1215 - Added Replacement_Details__c field
                qliToUpdate.add(new SBQQ__QuoteLine__c(
                    Id = qliVal.Id,
                    Total_Prior_Net_Total__c  = tempCount,
                    Total_Prior_Net_Total_With_Uplift__c = totalNetPriceWithUplift,
                    CCLI__c = consolidateCLIIds,
                    /*Added by Shaloo: To populate Old CLI linkage along with Renewed CLI & CCLI value*/
                    Arroyo_Subsumed_Old_Contract_Line_Items__c = oldCLIValue,
                    Replacement_Details__c = jsonToPop
                ));
            }
            updatedQLIRec = qliToUpdate;
        }
        if(!updatedQLIRec.IsEmpty()){
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            Database.update(updatedQLIRec);
            SBQQ.TriggerControl.enable();
        }
    }

   /***********************************************************************************************************
    * Method Name          : getReplacementDetails
    * Date Created/Modified: 04/04/2025
    * Author               : Sumedha
    * @description         : Populates Replacement Details field on Quote Lines on Renewal Quotes 
    * @param               qLine
    * @param               strLst
    * @param               cliVsEntLst
    * @param               assetEntMap
    * @param               asstCap
    * @param               mapEntvsAstNames
    * @param               entQty
    /**********************************************************************************************************/
    public static void getReplacementDetails (SBQQ__QuoteLine__c qLine, List<String> strLst ,Map<Id, List<String>> cliVsEntLst ,Map<Id, Map<String, String>> assetEntMap, Map<String, Decimal> asstCap, Map<Id, List<String>> mapEntvsAstNames, Map<Id, Decimal> entQty) {
        ReplacementJSON jsonData;//Holds the JSON to be populated on the field

        //Since the method is called after the Quote Line is created, there will already be JSON populated, get the current status of the field and use it later
        if (String.isNotBlank(qLine.Replacement_Details__c) && !mapOfJSON.containsKey(qLine.Id)) {
            ReplacementJson qliReplaceJSON = (ReplacementJson)JSON.deserialize(qLine.Replacement_Details__c, ReplacementJson.class);
            for (ReplacementJson.RowDetail existRow : qliReplaceJSON.rowValues) {
                alreadySeen.add(existRow.entId);
            }
            mapOfJSON.put(qLine.Id, qliReplaceJSON);
        }

        //strLst - list of CLIs in scope (includes and CCLI)
        if(!strLst.isEmpty() && !cliVsEntLst.isEmpty()) {
            for (String str : strLst) {
                str = str.trim();
                //cliVsEntLst - has CLIs and its associated Entitlements. If Entitlements are present, then new rows are created for each of the Ents.
                if (cliVsEntLst.containsKey(str) && !cliVsEntLst.get(str).isEmpty()) {
                    //If the Quote Line already has JSON created, then add rows to the same JSON.
                    if (mapOfJSON.containsKey(qLine.Id)) {
                        jsonData = mapOfJSON.get(qLine.Id);
                        for (String entId : cliVsEntLst.get(str)) {
                            if (!alreadySeen.contains(entId)) {
                                String selectedAsset;
                                Map<String, String> assetList = new Map<String, String>();
                                if (assetEntMap.containsKey(entId)) {assetList.putAll(assetEntMap.get(entId));} 
                                if (mapEntvsAstNames.containsKey(entId)) {selectedAsset = String.join(mapEntvsAstNames.get(entId), ',');}
                                ReplacementJson.RowDetail row = new ReplacementJson.RowDetail();
                                row.entId = entId;
                                row.selectedTerm = 12;
                                row.rowId =  '0.0.0'; 
                                row.selectedAsset = selectedAsset;
                                row.selectedAssetList = assetList;
                                if (String.isBlank(qLine.SBQQSC__RenewedContractLine__r.Product_Level__c)) {
                                   row.selectedQty = entQty.containsKey(entId) ? Integer.valueOf(entQty.get(entId)) : Integer.valueOf(qLine.SBQQ__Quantity__c);
                                } else {
                                   row.selectedQty = asstCap.containsKey(selectedAsset) ? Integer.valueOf(asstCap.get(selectedAsset)) : Integer.valueOf(qLine.SBQQ__Quantity__c);
                                }
                                row.disposition = 'Renewing'; 
                                jsonData.rowValues.add(row);
                                alreadySeen.add(entId);
                            }
                            mapOfJSON.put(qLine.Id, jsonData); 
                        }
                    }
                }
            }
        }       
    }
}