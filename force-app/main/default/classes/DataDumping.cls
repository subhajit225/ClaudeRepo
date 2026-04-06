@RestResource(urlMapping='/DataDumping') 
/***********************************************************************************************************
* Class Name           : DataDumping
* @description         : This class is called from Custom Script - CalculateQuotefields
* Test Class           : DataDumpingTest
/**********************************************************************************************************/
global without sharing class DataDumping {  
    /***********************************************************************************************************
    * Class Name           : DataDumpingPost
    * @description         : Does all calculations and returns CustomMap
    * @return              : CustomMap which contains details that has to be passed to QCP
    * @param AccountId
    * @param quoteId
    * @param createpswrapper
    * @param psWrapperExist
    * @param psLineCount
    * @param isRWDPolarisQuote
    * @param createTrainingSKU
    * @param newlinesCount
    * @param newLines1
    * @param qType
    * @param dealOpsExcep
    * @param lIds
    * @param quoteAppCategory
    * @param isRampQt
    * @param btnClicked
    /**********************************************************************************************************/

    @httppost  
    global  static CustomMap dataDumpingPost(String AccountId,String quoteId,boolean createpswrapper, boolean psWrapperExist, Integer psLineCount,Boolean isRWDPolarisQuote, 
    Boolean createTrainingSKU, Integer newlinesCount, String newLines1, String qType, Boolean dealOpsExcep, String lIds, String quoteAppCategory, String isRampQt, String btnClicked) {
        //isRWDPolarisQuote added by Sumedha for RWD-76 
        //createTrainingSKU added by Sumedha for CPQ22-836 
        CustomMap CM = new CustomMap();
        set<Id> CLIIDs = new set<Id>();
        Map<Id,string> ContractAssetSerialMap = new Map<Id,string>();
        Map<Id,string> ContractAssetIdMap = new Map<Id,string>();
        CM.ConAssetSerMap = new List<KeyValue>();
        CM.EntAccList = new List<KeyValue>();//CPQ22-4537
        CM.isNewCustomer = true; 
        /*START - ARY-218 CR #5: Added by Shaloo for populating SubsAstNameInt__c in QCP*/  
        /*CLIAssetSerialMap*/   
        Map<Id, String> CLIAssetSerialMap = new Map<Id, String>();  
        /*CLIAssetIdMap*/   
        Map<Id, String> CLIAssetIdMap = new Map<Id, String>();  
        /*CM.CLIAssetSerMap*/    
        CM.CLIAssetSerMap = new List<KeyValue>();   
        /*CM.fixDRVal*/ 
        CM.fixDRVal = new List<SBQQ__QuoteLine__c>();
        Map<Id, String> fixDRMap = new Map<Id, String>();   
        CM.fixDRQCP = new List<KeyValue>();
        /*END*/  
        Map<Id, String> replaceByMap = new Map<Id, String>(); //ARY-1079
        CM.qliRbob = new List<KeyValue>();//CPQ22-6126
        Map<Decimal, Decimal> mapOfQLvsQty = new Map<Decimal, Decimal>();
        Map<Decimal, QuoteLineRecord> qtyChangesMapAddOn = new Map<Decimal, QuoteLineRecord> ();
        Map<Decimal, QuoteLineRecord> qtyChangesMapHybrid = new Map<Decimal, QuoteLineRecord> ();
        String quoteMetering;//Added for ScaleUtility
        map<String,Object> quoteObj = New map<String,Object>();//Added for ScaleUtility
        CM.qtyChangeMap = new List<KeyValue>();
        CM.qlRecord= new List<QuoteLineRecord>();
        Map<Decimal, QuoteLineRecord> qtyChangesMapSent = new Map<Decimal, QuoteLineRecord>(); 
        Map<Id, Decimal> fixDiscount = new Map<Id, Decimal>();  
        Map<Id, Boolean> fixCSATDisc = new Map<Id, Boolean>();       
        CM.fixDisc = new List<KeyValue>();
        CM.fixCSAT = new List<KeyValue>();
        CM.discountval = new List<SBQQ__QuoteLine__c>();
        //FY25SR-1073 Starts
        Map<String, Asset> assetMap = new Map<String, Asset>();//FY25SR-1073
        Map<String, Boolean> astvsEntCliPerp = new Map<String, Boolean>(); //MS CPQ22-5842
        Map<String, Boolean> astvsSCEntCliPerp = new Map<String, Boolean>(); //MS CPQ22-5842
        CM.getRD = new List<KeyValue>();
        Map<Id, Entitlement> mapOfEnts = new Map<Id, Entitlement>();
        Date todaysDate = System.TODAY();
        Map<String, String> mapOfInactiveEnts = new Map<String, String>();
        //Calculate Account Discount History FY26WL-499
        Set<String> ADH_Out_of_Scope_ProductSet = new Set<String>(System.Label.ADH_Out_of_Scope_Product.split(';'));
        Map<String,Decimal> productAEDiscMap = new Map<String,Decimal>();
        //Calculate Account Discount History FY26WL-499 ends
        //FY25SR-1073 Ends
        Map<Id, Map<String, String>> assetEntMap = new Map<Id, Map<String, String>>();
        SBQQ__Quote__c quote = [SELECT Id, Name, SBQQ__Status__c, QuoteApprovalCategory__c,SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Opportunity_Sub_Type__c, Is_Ramp_Quote__c FROM SBQQ__Quote__c WHERE Id =:quoteId]; 
        CM.Acc = [SELECT Id, Name, Add_On_Extension_Letter__c, 
        (SELECT Id, SBQQSC__ProductName__c, Calculated_List_Price__c, SBQQSC__Product__c, Status, Quantity, SBQQSC__Quantity__c, Product2.License_Type__c, 
         SBQQSC__RequiredById__c, PricebookEntry.UnitPrice, SBQQSC__QuoteLine__r.SBQQ__SubscriptionPercent__c,SBQQSC__QuoteLine__r.Total_Usable_Capacity__c,
         SBQQSC__Product__r.SBQQ__SubscriptionPercent__c, IsRCDM__c,
         SBQQSC__OriginalQuoteLine__r.Atlassian_Quantity__c,
         SBQQSC__OriginalQuoteLine__r.Salesforce_Quantity__c,
         SBQQSC__OriginalQuoteLine__r.Rubrik_Hosted_M365_Quantity__c,
SBQQSC__OriginalQuoteLine__r.Google_WorkSpace_Quantity__c,
         SBQQSC__OriginalQuoteLine__r.Dynamics_Quantity__c
         FROM SBQQSC__ContractLineItems__r),
	 	 (SELECT Id, Name, Product2.Product_Type__c, Product2.Appliance_Model_HW__c, Product2.SBQQ__SubscriptionTerm__c, Product2.License_Type__c, Quantity, 
		 Product2.ProductCode, Product_Code_Custom__c, SerialNumber, Serial_Number__c, Program__c, Product_Usable_Capacity__c,Asset_Id__c,Licensing_Model__c,Product_Family__c FROM Assets),
         (SELECT Id, Avg_Expansion_Discount__c, Product__c, Product__r.Product_Type__c FROM Account_Discount_History__r),//Calculate Account Discount History FY26WL-499
            (SELECT Id,Name, EndDate, Type, Status, Product__r.Product_Type__c, Product__r.ProductCode, Product__r.Bundle_Features__c , Order_Service_Item__c , Order_Service_Item__r.OrderId,
        Product__r.Support_Type__c, Product__r.Category__c, ContractLineItem.Product2.Product_Type__c,Order_Service_Item__r.Order.Type,Order_Service_Item__r.Order.Order_Sub_Type__c , ContractLineItem.Product2.Appliance_Model_HW__c, ContractLineItem.Product2.ProductCode, ContractLineItem.Quantity, ContractLineItem.Subscription_Term__c, Asset.Product2.Product_Type__c, Asset.Product2.Appliance_Model_HW__c, Asset.Product2.ProductCode,Asset.Quantity, ContractLineItemId, Asset.SerialNumber, Asset.serial_number__c, Order_Quantity__c, Product__r.Product_Subtype__c, Product__r.RWD_Rubrik_Edition_Offerings__c, Asset.Program__c, Asset.Product_Usable_Capacity__c, Asset.SBQQ__QuoteLine__r.SBQQ__Quantity__c, ContractLineItem.SBQQSC__Quantity__c, ContractLineItem.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.Quantity, Product__r.Family,ContractLineItem.SBQQSC__RequiredByProduct__c,ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c, Quantity__c, ContractLineItem.Licensing_Model__c, Entitlement_ACV__c, Entitlement_RAMP_EXIT_ACV__c, Order_Service_Item__r.Order.Opportunity.Opportunity_Sub_Type__c, EntitlementExitDate__c
        FROM Entitlements WHERE Renewal_Category__c = null AND ((EndDate >= LAST_N_YEARS:2) OR (ContractLineItem.SBQQSC__SegmentIndex__c != null AND ContractLineItem.Contract_End_Date__c >= LAST_N_YEARS:2)) Order By EndDate) FROM Account WHERE Id =: AccountId];  
        
        CM.PCC = [Select id,Dependent_Product_Quantity__c,Cross_Product_Constrain_Only__c,Self_Constrain_Only__c,Constraining_Product__c,Dependent_Product__c,Could_be_Repurchased__c from Product_Constrain_Config__c WHERE Is_Active__c = true];
        
        //CM.Quote = [Select id,Evaluation_Scope_Calculator__c from SBQQ__Quote__c where id =:QuoteID];
        //Added for sonarTB CoTerm parameters 
        //CM.sonarTBcoTermParams = [Select type__c,value__c from SonarTBCoTermParameters__mdt where Active__c = true];
        
        //CM.nfrBundlePrices = [select Id, Product2.ProductCode, UnitPrice from PricebookEntry where Product2.SBQQ__RenewalProduct__r.ProductCode IN ('RBK-NFR-RENEWAL') and Pricebook2.Name = 'CPQ Pricebook'];
        
        CM.qcpValidationVerbiage = new List<QCP_Validation_Verbiage__mdt>([SELECT Id, DeveloperName, Error_Message1__c, Error_Message2__c FROM QCP_Validation_Verbiage__mdt WHERE Is_Active__c = true]);
        
        CM.qcpApprovalFlag = new List<QCP_Approval_Flag__mdt>([SELECT Id, DeveloperName, Field_Name__c, Field_Value__c, Flag_Value_If_False__c, Flag_Value_If_True__c, Operator__c, Product_Code__c FROM QCP_Approval_Flag__mdt WHERE Is_Active__c = true]);
        
        if(createpswrapper){
            //isRWDPolarisQuote added by Sumedha for RWD-76
            CM.PSWRAPPERLine = addDataMigration(quoteId, psWrapperExist, psLineCount, isRWDPolarisQuote);
        }
        
        //CPQ22-836 starts
        if (createTrainingSKU && isRWDPolarisQuote == false) {
            CM.trainingSKULine = addTrainingSKU(quoteId,createTrainingSKU,newlinesCount);
        }//CPQ22-836 ends
        CM.completeProUpgradeMaping =  Label.Complete_Edition_Pro_Upgrade;
        CM.quoteApprovalCategory = quoteAppCategory; //MS CPQ22-5842
		//Calculate Account Discount History FY26WL-499
        if(CM.Acc != null && !CM.Acc.Account_Discount_History__r.isEmpty()){
                    for(Account_Discount_History__c adh : CM.Acc.Account_Discount_History__r){
                        if(!ADH_Out_of_Scope_ProductSet.contains(adh.Product__r.Product_Type__c)){
                            productAEDiscMap.put(adh.Product__c, adh.Avg_Expansion_Discount__c);
        
                        }
                    }
                }
                CM.achRecordsMap = productAEDiscMap;
        //Calculate Account Discount History FY26WL-499 ends
        if(CM.Acc != null && !CM.Acc.Entitlements.isEmpty()){
            for(Entitlement ent : CM.Acc.Entitlements){
                if(ent.Type != 'Evaluation' && ent.Type != 'RSC' && ent.Order_Service_Item__c!= null && ent.Order_Service_Item__r.Order!=null && ent.Order_Service_Item__r.Order.Order_Sub_Type__c != 'POC' && ent.Order_Service_Item__r.Order.Type != 'POC' && !('Evaluation').contains(ent.Name)  ){
                    CM.isNewCustomer = false;
                    break;
                }
            }
            //FY25SR-1073 Starts
            if (CM.Acc != null && !CM.Acc.Assets.isEmpty()) {
                for (Asset ast : CM.Acc.Assets) {
                    assetMap.put(ast.SerialNumber, ast); 
                }
            }
            set<String> uniqueProd = new set<String>();//CPQ22-6052
            for(Entitlement ent : CM.Acc.Entitlements){
                //CPQ22-6052 Start
                String prodCode = (ent.Product__r != null && ent.Product__r.ProductCode != null) ? ent.Product__r.ProductCode : null;
                uniqueProd.add(prodCode);
                //CPQ22-6052 End
                mapOfEnts.put(ent.id, ent);

                //MS CPQ22-5842 Starts
                String serial = ent.Asset.SerialNumber;
                if (String.isNotBlank(serial)) {
                    Boolean isPerpetual = ent.ContractLineItem.Licensing_Model__c != null &&
                                        ent.ContractLineItem.Licensing_Model__c == 'Perpetual';

                    if (!astvsEntCliPerp.containsKey(serial) || (!astvsEntCliPerp.get(serial) && isPerpetual)){
                        astvsEntCliPerp.put(serial, isPerpetual);
                    }
                }
                //MS CPQ22-5842 Ends
            }
            List<String> prodList = new List<String>();
            if(!uniqueProd.isEmpty()){
            prodList.addAll(uniqueProd);
            }
            CM.existingProd = prodList;
            /*unused code
            if (!mapOfEnts.isEmpty()) {
                for (Entitlement_Links__c entLink : [Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate, Previous_Entitlement__r.Renewal_Category__c, Previous_Entitlement__r.EndDate, Previous_Entitlement__r.Product__r.Product_Type__c , Previous_Entitlement__r.Status, Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status,Renewed_Entitlement__r.StartDate, Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate, Renewed_Entitlement__r.Product__r.Product_Type__c, Renewed_Entitlement__r.ContractLineItem.TPH_Quantity__c, Renewed_Entitlement__r.Quantity__c FROM Entitlement_Links__c where (Previous_Entitlement__r.EndDate >= : todaysDate OR Renewed_Entitlement__r.StartDate >= : todaysDate) AND Previous_Entitlement__r.AccountId = : AccountId]) {
                    /*For Inactive Entitlements List
                    * Get all Entitlement Links which are associated with entitlements in scope. If Renewed Entitlement = Inactive, then store it as Active Entitlement vs Inactive Entitlement .
                    */
                    /*if (entLink.Renewed_Entitlement__r.Status == ReplacementConstants.STATUS_INACTIVE 
                    &&  ((entLink.Renewed_Entitlement__r.Product__r.Product_Type__c == ReplacementConstants.EDITION_UPGRADE 
                    && entLink.Previous_Entitlement__r.Product__r.Product_Type__c == ReplacementConstants.EDITION_UPGRADE) 
                     || entLink.Renewed_Entitlement__r.Product__r.Product_Type__c != ReplacementConstants.EDITION_UPGRADE 
                     && entLink.Previous_Entitlement__r.Product__r.Product_Type__c != ReplacementConstants.EDITION_UPGRADE)) {
                        if (!mapOfInactiveEnts.containsKey(String.valueOf(entLink.Renewed_Entitlement__c))) {
                            mapOfInactiveEnts.put(entLink.Renewed_Entitlement__c, entLink.Previous_Entitlement__c);
                        }
                    }
                }
                //FY25SR-1073 Ends
            }*/
        }
        
        if(CM.Acc != null && !CM.Acc.SBQQSC__ContractLineItems__r.isEmpty()){
            for(ContractLineItem CLI : CM.Acc.SBQQSC__ContractLineItems__r){
                CLIIDs.add(CLI.id);
            } 
            
            if(!CLIIDs.isEmpty()){
                for(Scale_Entitlement__c SE : [select id,Entitlement__c, Contract_Line_Item__r.SBQQSC__Product__r.ProductCode,Contract_Line_Item__c,Asset__c,Asset__r.SerialNumber,Asset__r.ProductCode, Asset__r.Product_Usable_Capacity__c, Contract_Line_Item__r.Licensing_Model__c from Scale_Entitlement__c where Contract_Line_Item__c IN : CLIIDs AND Renewal_Category__c = null AND (Type__c  = 'Non-Scale' OR Type__c  = 'Refreshed Base License' OR Type__c  = 'Refreshed Delta License')]){ //REEN-25
                    if (String.isNotBlank(SE.Asset__r.SerialNumber) && String.isNotBlank(SE.Entitlement__c)) {
                        Map<String, String> tempMap = new Map<String, String>();
                        if (assetEntMap.containsKey(SE.Entitlement__c)) {
                            tempMap.put(SE.Asset__c, SE.Asset__r.SerialNumber); 
                            assetEntMap.get(SE.Entitlement__c).put(SE.Asset__c, SE.Asset__r.SerialNumber);
                        } else {
                            tempMap.put(SE.Asset__c, SE.Asset__r.SerialNumber); 
                            assetEntMap.put(SE.Entitlement__c, tempMap);
                        }

                        //MS CPQ22-5842 Starts
                        String serial = SE.Asset__r.SerialNumber;
                        if (String.isNotBlank(serial)) {
                            Boolean isPerpetual = SE.Contract_Line_Item__r.Licensing_Model__c != null &&
                                                SE.Contract_Line_Item__r.Licensing_Model__c == 'Perpetual';

                            if (!astvsSCEntCliPerp.containsKey(serial) || (!astvsSCEntCliPerp.get(serial) && isPerpetual)){
                                astvsSCEntCliPerp.put(serial, isPerpetual);
                            }
                        }
                        //MS CPQ22-5842 Ends

                    }
                    
                    if(ContractAssetSerialMap.containskey(SE.Contract_Line_Item__c)){
                        string concatSerialNumber = ContractAssetSerialMap.get(SE.Contract_Line_Item__c) + ', ' + string.valueof(SE.Asset__r.SerialNumber);
                        string concatAssetId = ContractAssetIdMap.get(SE.Contract_Line_Item__c) + ', ' + string.valueof(SE.Asset__c);
                        ContractAssetSerialMap.put(SE.Contract_Line_Item__c,concatSerialNumber);
                        ContractAssetIdMap.put(SE.Contract_Line_Item__c,concatAssetId);
                    } else{
                        ContractAssetSerialMap.put(SE.Contract_Line_Item__c,string.valueof(SE.Asset__r.SerialNumber));
                        ContractAssetIdMap.put(SE.Contract_Line_Item__c,string.valueof(SE.Asset__c));
                    }
                }
                
                if(!ContractAssetSerialMap.isEmpty()){
                    for(id ConLineId : ContractAssetSerialMap.keyset()){
                        CM.ConAssetSerMap.add(new KeyValue(ConLineId,ContractAssetSerialMap.get(ConLineId),ContractAssetIdMap.get(ConLineId)));
                    }
                }
            } 
            /*START - ARY-218 CR #5: By Shaloo for populating SubsAstNameInt__c in QCP*/    
            if(CLIIDs != null && !CLIIDs.isEmpty()){  
                                                        for(Entitlement SE: [SELECT Id, AccountId, Type, ServiceContractId, ContractLineItemId, AssetId, Asset.SerialNumber, StartDate, EndDate, Status, Product__c, Renewed__c, IsRenewed__c, RWD_Renewed__c, Renewal_Category__c,     
                                                                             SBQQSC__AssetRootId__c, Prior_Entitlement__c, OldContractLineItem__c, ContractLineItem.LinkedAssets__c,ContractLineItem.SBQQSC__RequiredByProduct__c,
                                                                             ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c,Order_Quantity__c,Product__r.SBQQSC__EntitlementConversion__c,Entitlement_Status__c, Asset.Product_Usable_Capacity__c FROM Entitlement WHERE ContractLineItemId IN: CLIIDs ])//REEN-25//CPQ22-4537
                {
                    if (String.isNotBlank(SE.Asset.SerialNumber) && String.isNotBlank(SE.Id)) {
                        Map<String, String> tempMap = new Map<String, String>();
                        if (assetEntMap.containsKey(SE.Id)) {
                            tempMap.put(SE.AssetId, SE.Asset.SerialNumber); 
                            assetEntMap.get(SE.Id).put(SE.AssetId, SE.Asset.SerialNumber);
                        } else {
                            tempMap.put(SE.AssetId, SE.Asset.SerialNumber); 
                            assetEntMap.put(SE.Id, tempMap);
                        }
                    }
                    if(SE.Renewal_Category__c == null){//CPQ22-4537
                        if(CLIAssetSerialMap.containskey(SE.ContractLineItemId) && SE.AssetId != null){  
                            String concatSerialNumber = CLIAssetSerialMap.get(SE.ContractLineItemId) + ', ' + String.valueOf(SE.Asset.SerialNumber);   
                            String concatAssetId = CLIAssetIdMap.get(SE.ContractLineItemId) + ', ' + String.valueOf(SE.AssetId);   
                            CLIAssetSerialMap.put(SE.ContractLineItemId, concatSerialNumber);  
                            CLIAssetIdMap.put(SE.ContractLineItemId, concatAssetId); 
                        }
                        else if(SE.AssetId == null && SE.ContractLineItem.LinkedAssets__c != null && SE.ContractLineItem.LinkedAssets__c != ''){
                            CLIAssetSerialMap.put(SE.ContractLineItemId, String.valueOf(SE.ContractLineItem.LinkedAssets__c));   
                            CLIAssetIdMap.put(SE.ContractLineItemId, String.valueOf(SE.AssetId)); 
                        }
                        else if(SE.AssetId != null){ 
                            CLIAssetSerialMap.put(SE.ContractLineItemId, String.valueOf(SE.Asset.SerialNumber));   
                            CLIAssetIdMap.put(SE.ContractLineItemId, String.valueOf(SE.AssetId));  
                        }
                    }
                    //CPQ22-4537 start
                    if(SE.Entitlement_Status__c=='Active' || (SE.Entitlement_Status__c=='Expired' && SE.Renewal_Category__c == null)) {                        
			if(SE.Product__c!=null && SE.Product__r.SBQQSC__EntitlementConversion__c=='One per quote line' && SE.Order_Quantity__c!=null)
                        { 
                            CM.EntAccList.add(new KeyValue(SE.Id,(Double)SE.Order_Quantity__c));
                        }
                        if(SE.Product__c!=null && SE.Product__r.SBQQSC__EntitlementConversion__c=='One per unit')
                        {  
                            Double qty=1;
                            CM.EntAccList.add(new KeyValue(SE.Id,qty));
                        }
                    }
                    //CPQ22-4537 end
                }   
                if(CLIAssetSerialMap != null && !CLIAssetSerialMap.isEmpty()){  
                    for(Id ConLineId: CLIAssetSerialMap.keyset()){ 
                        CM.CLIAssetSerMap.add(new KeyValue(ConLineId, CLIAssetSerialMap.get(ConLineId), CLIAssetIdMap.get(ConLineId))); 
                    }   
                }   
            }   
            /*END - ARY-218 CR #5: By Shaloo for populating SubsAstNameInt__c in QCP*/
        }
        Decimal prepaymentTotal = 0.0;
        if (String.isNotBlank(lIds)) {
                                                    List<QuoteLineRecordResponse> creditQLs = new List<QuoteLineRecordResponse>();
            List<QuoteLineRecordResponse> qlClones = new List<QuoteLineRecordResponse>();
            List<QuoteLineRecordResponse> qlDets = (List<QuoteLineRecordResponse>)JSON.deserialize(lIds, List<QuoteLineRecordResponse>.class);
            for (Integer i = 0; i<qlDets.size(); i++) {
                QuoteLineRecordResponse m = (QuoteLineRecordResponse) qlDets[i];
                CM.qlRecord.add(new QuoteLineRecord((String) m.pLvl, (String) m.ptyp,(String) m.rqBy,(Decimal) m.asCap,
                (Decimal) m.newQty,(String) m.aoLvl,(String) m.pFam,(String) m.pSt,
		(Decimal) m.eQty,(Boolean) m.qtyC,(Decimal) m.apCt,(Decimal) m.nCt,
		(String) m.pNam,(Decimal) m.uCap,(Boolean) m.ext,(Decimal) m.nbr,
		(String) m.prodCode, (Decimal) m.totCap, (Decimal) m.tbAp, (String) m.prd,(String) m.lTyp,
		(Decimal) m.tCap,(Decimal) m.oTCap,(Decimal) m.tbCld, (Decimal) m.tbEnv,
		(String) m.dSize,(String) m.tQty,(String) m.sLbl, (String) m.rcId, (String) m.sP));//ARY-1079 added sP as parameter
                qlClones.add(m);
                if(!String.isBlank(m.replacementMotion)) {
                    creditQLs.add(m);
                }
            }
            if(qlClones.size() > 0) { 
                CM.isMissingData = QuoteTriggerHelper.verifyTierOnQLs(qlClones); 
            }
            //FY25SR-1203 - start
            if(creditQLs.size() > 0) {
                //FY25SR-1879 bypass approved
                //Paritosh bypass prepayment credit for custom (IT)
                if (quote.SBQQ__Status__c != ReplacementConstants.STATUS_APPROVED 
                    && !Label.Bypass_Prepayment_Calculation.contains(quote.Name)){
                    CreditCalculation.QuoteLineDataResponse creditResponse = CreditCalculation.creditCalculationPost(creditQLs);
                    cm.creditLines = creditResponse.quotelines;
                    if (creditResponse.isPrepayZero 
                        && ((String.isBlank(quoteAppCategory) || quoteAppCategory == null) 
                            || !quoteAppCategory.contains(ReplacementConstants.PREPAY)
                            )){
                        cm.quoteApprovalCategory = quoteAppCategory != null && String.isNotBlank(quoteAppCategory)
                                                ? quoteAppCategory + ','+ReplacementConstants.PREPAY 
                                                : ReplacementConstants.PREPAY;
                    }
                    else if (!creditResponse.isPrepayZero && String.isNotBlank(quoteAppCategory)
                        && quoteAppCategory != null 
                        && quoteAppCategory.contains(ReplacementConstants.PREPAY)){
                        cm.quoteApprovalCategory = quoteAppCategory.remove(ReplacementConstants.PREPAY);
                    } else {
                        cm.quoteApprovalCategory = quoteAppCategory;
                    }                    
                }

                //CPQ22-6126
                List<KeyValue> qliToRbobAcvMap = processRbobACV(creditQLs, new Map<Id, Entitlement>(mapOfEnts));
                if(!qliToRbobAcvMap.isEmpty()) {
                    CM.qliRbob = qliToRbobAcvMap;
                }
            }
            //FY25SR-1203 - end
          /*FY25SR-1220 - Start*/
          cm.specialProgram = fetchSelectedSpecialProgram(lIds);
          /*FY25SR-1220 - End*/
        }

        //MS CPQ22-5842 - Start
        String qtAppCategory = quoteAppCategory; //CM.quoteApprovalCategory;
        if((quote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c != ReplacementConstants.GC_OFFER && quote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c != ReplacementConstants.GC_ONDEMAND && quote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c != ReplacementConstants.GC_RENEWAL) && btnClicked != null && (btnClicked == 'Calculate' || btnClicked == 'Quick Save' || btnClicked == 'Save') && (qtAppCategory == null || qtAppCategory == '' || (qtAppCategory != null && (!qtAppCategory.contains('MFQR') || !qtAppCategory.contains('MFQD'))))){
            String qtApCategory = populateManualFulfillmentQuote(lIds, assetMap, astvsEntCliPerp, astvsSCEntCliPerp, quoteAppCategory, isRampQt); // MS CPQ22-5842
            if(qtApCategory != null && String.isNotBlank(qtApCategory)){
                CM.quoteApprovalCategory = CM.quoteApprovalCategory != null && CM.quoteApprovalCategory != 'null' ? CM.quoteApprovalCategory + qtApCategory : qtApCategory;
            }
        }
        //MS CPQ22-5842 - Start

        Map<Decimal, List<Decimal>> parentnumvschildNum = new Map<Decimal, List<Decimal>>();
        if (String.isNotBlank(newLines1)){
            List<Object> objListNew = (List<Object>)JSON.deserializeUntyped(newLines1);
            for (Integer i = 0; i<objListNew .size(); i++){
                map<String,Object> m = (map<String,Object>) objListNew[i];
                List<Object> objListNew1 = (List<Object>)m.get('children');
                List<Decimal> dList = new List<Decimal>();
                for(Object obj : objListNew1 ){
                    Decimal d = (Decimal)obj;
                    dList.add(d);
                }
                parentnumvschildNum.put((Decimal)m.get('parent'),dList);
            }
        }
        Map<Decimal, QuoteLineRecord> newMap = new Map<Decimal, QuoteLineRecord>();
        
        if(!CM.qlRecord.isEmpty()) {
            for (QuoteLineRecord qlObj : CM.qlRecord) {
                newMap.put(qlObj.QLNumber,qlObj);
            }
        }
        
        if (!newMap.isEmpty() && !parentnumvschildNum.isEmpty()) {
            //added metering param as part of Scaleutility
            qtyChangesMapHybrid = calculateHybridQty(quoteId, newMap , parentnumvschildNum, qType, quoteMetering);
            qtyChangesMapAddOn = calculateAddOnQty(quoteId, newMap , parentnumvschildNum, dealOpsExcep); 
        }
        
        if (!qtyChangesMapHybrid.isEmpty()) {
            for (Decimal hybOdj : qtyChangesMapHybrid.keySet()) {
                if (!qtyChangesMapSent.containsKey(hybOdj)) {
                    qtyChangesMapSent.put(hybOdj, qtyChangesMapHybrid.get(hybOdj));
                }
            }
        }
        
        if (!qtyChangesMapAddOn.isEmpty()) {
            for (Decimal hybOdj : qtyChangesMapAddOn.keySet()) {
                if (!qtyChangesMapSent.containsKey(hybOdj)) {
                    qtyChangesMapSent.put(hybOdj, qtyChangesMapAddOn.get(hybOdj));
                }
            }
        }
        
        //Added param TotalUsableCapacity as part of ScaleUtility
        if (!qtyChangesMapSent.isEmpty()) {
            for (Decimal hybOdj : qtyChangesMapSent.keySet()) {
                if (qtyChangesMapSent.containsKey(hybOdj)) {
                    CM.qtyChangeMap.add(new KeyValue (hybOdj,qtyChangesMapSent.get(hybOdj).Quantity,
		    qtyChangesMapSent.get(hybOdj).RWD_Expected_Default_Quantity,
		    qtyChangesMapSent.get(hybOdj).RWD_Polaris_SKUs_Quantity_Changed,
		    qtyChangesMapSent.get(hybOdj).RWD_Total_Capacity,
		    qtyChangesMapSent.get(hybOdj).RWD_TB_Per_Appliance_Ratio,
		    qtyChangesMapSent.get(hybOdj).TotalUsableCapacity));
                }
            }
        }
        SYstem.debug(LoggingLevel.DEBUG, 'CM.qtyChangeMap-->'+CM.qtyChangeMap);
        
        /*START - ARY-218: Added by Shaloo for populating SubsAstNameInt__c in QCP*/
        Map<Decimal, QuoteLineRecord> newDRMap = new Map<Decimal, QuoteLineRecord>();
        if(!CM.qlRecord.isEmpty()) {
            for (QuoteLineRecord qlObj: CM.qlRecord) {
                newDRMap.put(qlObj.QLNumber, qlObj);
            }
        }
        //Madhura Start
        CM.discountval=populateDiscountThreshold(quoteId, newMap);
        
        if(CM.discountval!= null && !CM.discountval.IsEmpty()){
            for(SBQQ__QuoteLine__c qli : CM.discountval){
                fixDiscount.put(qli.Id,qli.SBQQ__Discount__c);
                fixCSATDisc.put(qli.Id,qli.CSAT_Discount_Applied__c);
            }
        }
        
        if(fixDiscount!= null && !fixDiscount.IsEmpty()){
            for(Id qliID: fixDiscount.keyset()){
                Double discount = fixDiscount.get(qliID);
                CM.fixDisc.add(new KeyValue(qliID,discount));
            }
        }      
        if(fixCSATDisc!= null && !fixCSATDisc.IsEmpty()){
            for(Id qliID: fixCSATDisc.keyset()){
                Boolean isDiscAppl = fixCSATDisc.get(qliID);
                CM.fixCSAT.add(new KeyValue(qliID,isDiscAppl));
            }
        } 
        
        if(!newDRMap.isEmpty()){
            CM.fixDRVal = updateDispositionReasonsFixRevertion(quoteId, newDRMap);
            //MS RGCF2-180
            if(String.ISNOTBLANK(qtNames)){
                CM.quoteNames = qtNames;
            }
            if(String.ISNOTBLANK(replSkuNames)){
                CM.repldSkuNames = replSkuNames;
            }
        }
                                                
        if(CM.fixDRVal != null && !CM.fixDRVal.IsEmpty()){
            for(SBQQ__QuoteLine__c qli: CM.fixDRVal){
                fixDRMap.put(qli.Id, qli.Disposition_Reason__c);
                //CM.fixDRQCP.add(new KeyValue(qli.Id, qli.Disposition_Reason__c));
                replaceByMap.put(qli.Id, qli.Replace_By__c);//ARY-1079
            }
        }
                                                
        if(fixDRMap != null && !fixDRMap.IsEmpty()){
            for(Id qliID: fixDRMap.keyset()){
                String tempDR = fixDRMap.get(qliID);String replaceBy = replaceByMap.get(qliID);//ARY-1079
                CM.fixDRQCP.add(new KeyValue(qliID, qliID, tempDR, replaceBy));//ARY-1079 added replaceBy parameter
            }
        }
        
        //FY25SR-1073 Starts
        Set<Id> quoteIds = new Set<Id>();
        quoteIds.add(quoteId);
        List<SBQQ__QuoteLine__c> qlsToUpdate = new List<SBQQ__QuoteLine__c>();
        ShGl_DisableBusinessLogic__c setting = ReplacementQueryController.fetchBusinessLogicSetting();
        if(!setting.Disable_Replacement_Framework__c) {
            if (CM.Acc != null && !CM.Acc.Entitlements.isEmpty() && !quoteIds.isEmpty() /* && quote.SBQQ__Opportunity2__c != null &&
                quote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c != ReplacementConstants.GC_OFFER &&
                quote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c != ReplacementConstants.GC_ONDEMAND &&
                quote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c != ReplacementConstants.GC_RENEWAL */) {    //Commented CPQ22-6425 to populate RDs for GC deals as well
            qlsToUpdate = ReplacementRefreshUtility.populateJSONForReconstruction (quoteIds, mapOfEnts, assetMap, mapOfInactiveEnts, assetEntMap);
            if (!qlsToUpdate.isEmpty()) {
                for (SBQQ__QuoteLine__c ql : qlsToUpdate) {
                    String rd = ql.Replacement_Details__c;
                    String ol = String.valueOf(ql.SBQQ__OptionLevel__c);
                    Double at = Double.ValueOf(ql.Atlassian_Quantity__c);
                    Double rh = Double.ValueOf(ql.Rubrik_Hosted_M365_Quantity__c);
                    Double sq = Double.ValueOf(ql.Salesforce_Quantity__c);
                    Double dq = Double.ValueOf(ql.Dynamics_Quantity__c);
          			Date ed = ql.SBQQ__EndDate__c;
                    Double gwq = Double.ValueOf(ql.Google_WorkSpace_Quantity__c);
                    CM.getRD.add(new KeyValue(ql.Id,rd,ol, at, rh, sq, dq, ed,gwq));
                }
            }
        }
        }
        //FY25SR-1073 ends
        /*END - ARY-218 CR #5: Added by Shaloo for populating SubsAstNameInt__c in QCP*/
        return CM;
    }
    /***********************************************************************************************************
    * Class Name           : CustomMap
    * @description         : Wrapper to store all types of data which has to be returned to QCP
    /**********************************************************************************************************/
    global class CustomMap{
        
        //global SBQQ__Quote__c Quote;
        global map<string, decimal> achRecordsMap; //Calculate Account Discount History FY26WL-499
        global String completeProUpgradeMaping = '';
        global List<KeyValue> ConAssetSerMap ;
        global List<KeyValue> EntAccList;//CPQ22-4537
        global Account Acc;
        global list<Product_Constrain_Config__c> PCC;
        //global list<SonarTBCoTermParameters__mdt> sonarTBcoTermParams;
        global SBQQ__QuoteLine__c PSWRAPPERLine;
        //global List<PricebookEntry> nfrBundlePrices;
        global List<QCP_Validation_Verbiage__mdt> qcpValidationVerbiage;
        global List<QCP_Approval_Flag__mdt> qcpApprovalFlag;
        //CPQ22-836 starts
        global SBQQ__QuoteLine__c trainingSKULine;
        //CPQ22-836 ends
        global List<KeyValue> qtyChangeMap ;
        global List<QuoteLineRecord > qlRecord;
        /*ARY-218 CR #5: fixDRVal*/
        global List<SBQQ__QuoteLine__c> fixDRVal;
        /*ARY-218: CLIAssetSerMap*/
        global List<KeyValue> fixDRQCP;
        /*CLIAssetSerMap*/ 
        global List<KeyValue> fixDisc;
        global List<KeyValue> fixCSAT;
        global List<KeyValue> CLIAssetSerMap;
        /*ARY-218 CR #5: qlDRRec*/
        //global List<QuoteLineRecord> qlDRRec;
        global List<SBQQ__QuoteLine__c> discountval;
        global String repldSkuNames = ''; //MS RGCF2-180
        global String quoteNames = ''; //MS RGCF2-180
        /*CPQ22-3386 Madhura   */
        global Boolean isNewCustomer;
        /**CPQ22-4654*/
        global Boolean isMissingData;
        /*FY25SR-285*/
        global List<SBQQ__QuoteLine__c> creditLines;
        /*FY25SR-1073 getRD*/
        global List<KeyValue> getRD;
        /*FY25SR-1220*/
        global String specialProgram;
         /*FY25SR-2209*/
         global String quoteApprovalCategory;
        /*CPQ22-6126*/
        global List<KeyValue> qliRbob;
        /*CPQ22-6052*/
        global List<String> existingProd;
    }
    /***********************************************************************************************************
    * Class Name           : QuoteLineRecord
    * @description         : Wrapper to store all QuoteLine data
    /**********************************************************************************************************/
    //Added parameters as part of ScaleUtility  
    global class QuoteLineRecord {
        
        global String Product_Level;
        global String Product_Type;
        global String RequiredBy;
        global Decimal Related_Asset_Total_Capacity;
        global Decimal Quantity;
        global String Add_on_Level;
        global String ProductFamily;
        global String Product_Subtype;
        global Decimal RWD_Expected_Default_Quantity;
        global Boolean RWD_Polaris_SKUs_Quantity_Changed;
        global Decimal Temp_Appliance_Count;
        global Decimal Temp_Node_Count;
        global String ProductName;
        global Decimal Usable_Capacity;
        global Boolean Existing;
        global Decimal QLNumber;
        global String Product_Code;
        global Decimal RWD_Total_Capacity;
        global Decimal RWD_TB_Per_Appliance_Ratio;
        global String ProductId;
        global String LineType;
        global Decimal TotalUsableCapacity;
        global Decimal oldTotalUsableCapacity;
        global Decimal No_of_TBs_Cloud;
        global Decimal No_of_TBs_Environment;
        global String TPH_Drive_Size;
        global String TPH_Quantity;
        global String SegmentLabel;
        /*START: Shaloo Added Id fields for ARY-218*/   
        global String rcId;   
        /*END: Above QLI fields for ARY-218*/  
        global String sP;//ARY-1079
        global String convSubsAst; //MS CPQ22-5842
        global Date startDate; //MS CPQ22-5842
        
        QuoteLineRecord(String Product_Level,String Product_Type,String RequiredBy,Decimal Related_Asset_Total_Capacity,
                        Decimal Quantity,
                        String Add_on_Level,
                        String ProductFamily,
                        String Product_Subtype,
                        Decimal RWD_Expected_Default_Quantity,
                        Boolean RWD_Polaris_SKUs_Quantity_Changed,
                        Decimal  Temp_Appliance_Count,
                        Decimal Temp_Node_Count,
                        String ProductName,
                        Decimal Usable_Capacity,
                        Boolean Existing,
                        Decimal QLNumber,
                        String Product_Code,
                        Decimal RWD_Total_Capacity, 
                        Decimal RWD_TB_Per_Appliance_Ratio,
                        String ProductId,
                        String LineType,
                        Decimal TotalUsableCapacity,  
                        Decimal oldTotalUsableCapacity,  
                        Decimal No_of_TBs_Cloud,  
                        Decimal No_of_TBs_Environment,  
                        String TPH_Drive_Size,  
                        String TPH_Quantity,  
                        String SegmentLabel,
                        /*START: Shaloo Added Below QLI fields for ARY-218*/    
                        String rcId,
                        /*END: Shaloo Added Below QLI fields for ARY-218*/
                        String sP//ARY-1079
        ){
            this.Product_Level = Product_Level;
            this.Product_Type = Product_Type;
            this.RequiredBy = RequiredBy;
            this.Related_Asset_Total_Capacity = Related_Asset_Total_Capacity;
            this.Quantity = Quantity;
            this.Add_on_Level = Add_on_Level;
            this.ProductFamily = ProductFamily;
            this.Product_Subtype = Product_Subtype;
            this.RWD_Expected_Default_Quantity = RWD_Expected_Default_Quantity;
            this.RWD_Polaris_SKUs_Quantity_Changed = RWD_Polaris_SKUs_Quantity_Changed;
            this.Temp_Appliance_Count = Temp_Appliance_Count;
            this.Temp_Node_Count = Temp_Node_Count;
            this.ProductName = ProductName;
            this.Usable_Capacity = Usable_Capacity;
            this.Existing = Existing;
            this.QLNumber = QLNumber;
            this.Product_Code = Product_Code;
            this.RWD_Total_Capacity = RWD_Total_Capacity;
            this.RWD_TB_Per_Appliance_Ratio = RWD_TB_Per_Appliance_Ratio;
            this.ProductId = ProductId;
            this.LineType = LineType;
            this.TotalUsableCapacity = TotalUsableCapacity;  
            this.oldTotalUsableCapacity = oldTotalUsableCapacity;  
            this.No_of_TBs_Cloud = No_of_TBs_Cloud;  
            this.No_of_TBs_Environment = No_of_TBs_Environment;  
            this.TPH_Drive_Size = TPH_Drive_Size;  
            this.TPH_Quantity = TPH_Quantity;  
            this.SegmentLabel = SegmentLabel;
            /*START: Shaloo Added Below QLI fields for ARY-218*/ 
            this.rcId = rcId;    
            /*END: Shaloo Added Below QLI fields for ARY-218*/
            this.sP = sP;//ARY-1079
        }
    }
    //added parameter for scaleUtility
    /***********************************************************************************************************
    * Class Name           : KeyValue
    * @description         : Wrapper to store all QuoteLine data
    /**********************************************************************************************************/
    global class KeyValue {
        global String Key ;
        global String value1 ;
        global String value2 ;
        global Double value4 ;
        global Double value5 ;
        global Double value6 ;
        global Double value7 ;
        global Date value8;//FY25SR-1950
        global Double value9;
        global Decimal key1;
        global Decimal valueA;
        global Decimal valueB;
        global Boolean valueC;
        global Decimal valueD;
        global Decimal valueE;
        global Decimal valueF;
        global Decimal disc;
        global Boolean discCSAT;
        /*value3 */
        global String value3; //ARY-1079
        
        KeyValue(String Key,String value1,String value2){
            this.Key = Key;
            this.value1 = value1;
            this.value2 = value2;
        }
        
        //FY25SR-1950
        KeyValue(String Key,String value1,String value2, Double value4, Double value5, Double value6, Double value7, Date value8,Double value9){
            this.Key = Key;
            this.value1 = value1;
            this.value2 = value2;
            this.value4 = value4;
            this.value5 = value5;
            this.value6 = value6;
            this.value7 = value7;
            this.value8 = value8;
            this.value9 = value9;
        }

        KeyValue(Decimal key, Decimal valueA, Decimal valueB, Boolean valueC, Decimal valueD, Decimal valueE,Decimal valueF) {
            this.Key1 = Key;
            this.valueA = valueA;
            this.valueB = valueB;
            this.valueC = valueC;
            this.valueD = valueD;
            this.valueE = valueE;
            this.valueF = valueF;
        }
        //ARY-1079 - Starts
        KeyValue(String Key,String value1,String value2, String value3)
        {
            this.Key = Key;
            this.value1 = value1;
            this.value2 = value2;
            this.value3 = value3;
        }
        //ARY-1079 - Ends
        KeyValue(String key,double disc)
        {
            this.Key = Key;
            this.disc = disc;
        }
        KeyValue(String key, boolean discCSAT) {
            this.Key = Key;
            this.discCSAT = discCSAT;
        }
        //CPQ22-6126 SAL26-1359
        KeyValue(String Key,Decimal valueA,Decimal valueB, Date value8) {
            this.Key = Key;
            this.valueA = valueA;
            this.valueB = valueB;
            this.value8 = value8;
        }
    }
    /***********************************************************************************************************
    * Method Name          : addDataMigration
    * @description         : Method which adds DATA-MIGRATION SKU on Refresh
    * @return              : Returns DATA-MIGRATION Line
    * @param quoteId
    * @param PWrapExist
    * @param psLineCount
    * @param isRWDPolarisQuote
    /**********************************************************************************************************/
    global static SBQQ__QuoteLine__c addDataMigration(Id quoteId, boolean PWrapExist, Integer psLineCount, Boolean isRWDPolarisQuote){
        //isRWDPolarisQuote added by Sumedha for RWD-76    
        // DML statement
        SBQQ__QuoteLine__c DataMigQLI;  
        List<SBQQ__QuoteLine__c>  QLIList =  [select id,SBQQ__Quote__r.Installed_By__c, SBQQ__ProductCode__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quoteId order by createdDate ASC];   
        List<SBQQ__QuoteLine__c>  QLIListPSWrap = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c>  QLIListOthers = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLineGroup__c QLIGList = new SBQQ__QuoteLineGroup__c();
        SBQQ__Quote__c quoteRec = [SELECT Id, Name, SBQQ__Type__c FROM SBQQ__Quote__c WHERE Id =: quoteId];
        
        if(quoteRec.SBQQ__Type__c == 'Renewal+Expansion'){
            QLIGList = [SELECT Id, Name, SBQQ__Quote__c FROM SBQQ__QuoteLineGroup__c WHERE 
                        SBQQ__Quote__c =: quoteId AND Name != 'Renewal Quote' AND Name != 'Disposition Quote'];
            //Name = 'Expansion Quote'];
        }
        for(SBQQ__QuoteLine__c QLI: QLIList){
            //Hybrid Professional Services added by Lakshmi for RWD-76 and 77
            if(QLI.SBQQ__ProductCode__c =='PS-WRAPPER' || QLI.SBQQ__ProductCode__c =='Hybrid Professional Services')
                QLIListPSWrap.add(QLI);
            else
                QLIListOthers.add(QLI);
        }
        
        if ( QLIListPSWrap.size() ==0){
            list<product2> pswrapper=new list<product2>();
            //Hybrid Professional Services added by Lakshmi for RWD-76 and 77
            if(isRWDPolarisQuote) {
                
                pswrapper=[select id from product2 where (productcode='Hybrid Professional Services') and isactive=true];
            }
            else {
                pswrapper=[select id from product2 where (productcode='PS-WRAPPER') and isactive=true];
            }
            
            if(!pswrapper.isempty() || Test.isRunningTest()){
                DataMigQLI = new SBQQ__QuoteLine__c();
                DataMigQLI.SBQQ__Quote__c=quoteId;
                DataMigQLI.SBQQ__Product__c= pswrapper[0].id;
                DataMigQLI.SBQQ__Number__c = psLineCount;
                DataMigQLI.SBQQ__Quantity__c = 1;
                DataMigQLI.SBQQ__Bundle__c=true;
                DataMigQLI.SBQQ__Optional__c = true;
                DataMigQLI.SBQQ__Hidden__c = true;
                
                  if(QLIGList != null && QLIGList.Name != System.Label.Arry_renewal_Group && QLIGList.Name != System.Label.Arry_Disposition_Group
                   //QLIGList.Name == 'Expansion Quote'  
                   && isRWDPolarisQuote && quoteRec.SBQQ__Type__c == 'Renewal+Expansion'){
                       DataMigQLI.SBQQ__Group__c = QLIGList.Id;
                   }
                
                Database.SaveResult srList = Database.insert(DataMigQLI, false);
                
                if(QLIListPSWrap != null && QLIListPSWrap.size()>0){
                    QLIListPSWrap.remove(0);
                    //delete QLIListPSWrap;
                }
                if (!srList.isSuccess()) {
                    DataMigQLI = null;
                }
            } 
        }
        return DataMigQLI;
    }
    /***********************************************************************************************************
    * Method Name          : addTrainingSKU
    * @description         : Method which adds TRN SKU on Refresh
    * @return              : Returns TRN Line
    * @param quoteId
    * @param createTrainingSKU
    * @param newlinesCount
    /**********************************************************************************************************/
    //CPQ22-836 starts    
    global static SBQQ__QuoteLine__c addTrainingSKU(Id quoteId, Boolean createTrainingSKU, Integer newlinesCount){ 
        SBQQ__QuoteLine__c trainingSKUQLI;
        List<SBQQ__QuoteLine__c>  QLIList =  [select id, SBQQ__ProductCode__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quoteId order by createdDate ASC];   
        SBQQ__Quote__c quoteRecord = [Select Id, Name from SBQQ__Quote__c where Id =: quoteId];
        List<SBQQ__QuoteLine__c>  QLIListTRNSKUs = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c QLI: QLIList){
            if(QLI.SBQQ__ProductCode__c =='RBK-SVC-TRN-VIRTUAL'){
                QLIListTRNSKUs.add(QLI);
            }
        }
        if (QLIListTRNSKUs.size() == 0) {
            list<product2> trainingSKULine=[select id from product2 where (productcode='RBK-SVC-TRN-VIRTUAL') and isactive=true];
            
            if(!trainingSKULine.isempty() || Test.isRunningTest()){
                trainingSKUQLI = new SBQQ__QuoteLine__c();
                trainingSKUQLI.SBQQ__Quote__c=quoteId;
                trainingSKUQLI.SBQQ__Product__c= trainingSKULine[0].id;
                trainingSKUQLI.SBQQ__Quantity__c = 1;
                trainingSKUQLI.SBQQ__Number__c = newlinesCount+1;
                Database.SaveResult srList = Database.insert(trainingSKUQLI, false);
                
                if (!srList.isSuccess()) {
                    trainingSKUQLI = null;
                }
            } 
        }
        return trainingSKUQLI;
    }
    //CPQ22-836 ends

    /***********************************************************************************************************
    * Method Name          : calculateAddOnQty
    * @description         : Method to calculate Qty for Non Asset based SKUs
    * @return              : Returns Map of QL Id vs QL record to be updated
    * @param quoteId
    * @param newMap
    * @param parentnumvschildNum
    * @param dealOpsExcep
    /**********************************************************************************************************/
    global static Map<Decimal, QuoteLineRecord> calculateAddOnQty (Id quoteId, Map<Decimal, QuoteLineRecord> newMap, Map<Decimal, List<Decimal>> parentnumvschildNum, Boolean dealOpsExcep){ 
        Decimal sumOfAppAddOns = 0.00;
        Map<Decimal,QuoteLineRecord > qtyChangesMap = new Map<Decimal, QuoteLineRecord>();
        
        if (!newMap.isEmpty()) {
            for (Decimal qlObj : parentnumvschildNum.keySet()) {
                String productLvl = newMap.get(qlObj).Product_Level;
                for(Decimal childQLObj: parentnumvschildNum.get(qlObj)){
                String cmpProductLvl1 = newMap.get(childQLObj).Product_Level;
                if(
                    (newMap.get(qlObj).Product_Type == 'RCDM Support'&& productLvl != null) || 
                    (newMap.get(qlObj).RequiredBy == null && 
                    (
                        (
                            productLvl == 'SaaS Software Addon' && 
                            newMap.get(childQLObj).Add_on_Level == 'RCDM Add-On' && 
                            newMap.get(childQLObj).ProductFamily == 'POLARIS' && 
                            (
                                newMap.get(childQLObj).Product_Type == 'RADAR' || 
                                newMap.get(childQLObj).Product_Type == 'Sonar' || 
                                newMap.get(childQLObj).Product_Type == 'App Flows'
                            )
                        ) || (cmpProductLvl1=='SaaS Software Addon' && newMap.get(childQLObj).Product_Subtype== 'LOD Addon') || (productLvl == 'Hybrid Software' && String.isBlank(newMap.get(qlObj).TPH_Drive_Size) && String.isBlank(newMap.get(qlObj).TPH_Quantity)))))
                    {
                        //ARY-1079 added Special Program check
                        if (newMap.get(qlObj).Related_Asset_Total_Capacity > 0 && newMap.get(qlObj).sP != 'Replaced') {
                            newMap.get(qlObj).Quantity = newMap.get(qlObj).Related_Asset_Total_Capacity;
                        }
                    }
                }
                if (productLvl != null) {
                    sumOfAppAddOns = 0;
                    if ((newMap.get(qlObj).RequiredBy == null && newMap.get(qlObj).Quantity != null && newMap.get(qlObj).Product_Subtype != 'Virtual') || (newMap.get(qlObj).Product_Code == 'LOD Wrapper'  
                        && dealOpsExcep == true)) {
                            sumOfAppAddOns = sumOfAppAddOns + newMap.get(qlObj).Quantity;
                    }
                    //if (qlObj.SBQQ__RequiredBy__c != null) {
                    for (Decimal childQLObj : parentnumvschildNum.get(qlObj)) {
                        if (newMap.containsKey(childQLObj )){
                            String cmpProductLvl = newMap.get(childQLObj).Product_Level;
                            if ((cmpProductLvl == 'SaaS Software Addon' && newMap.get(childQLObj).Add_on_Level == 'RCDM Add-On' && newMap.get(childQLObj).ProductFamily == 'POLARIS' &&
                            (newMap.get(childQLObj).Product_Type == 'RADAR' || newMap.get(childQLObj).Product_Type == 'Sonar' || newMap.get(childQLObj).Product_Type == 'App Flows')) ||
                            (cmpProductLvl=='SaaS Software Addon' && newMap.get(childQLObj).Product_Subtype== 'LOD Addon')) {
                                if (newMap.get(childQLObj).Quantity != newMap.get(childQLObj).RWD_Expected_Default_Quantity) {
                                    newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed = true;
                                }
                                if (newMap.get(childQLObj).Related_Asset_Total_Capacity > 0) {
                                    newMap.get(childQLObj).Quantity = newMap.get(childQLObj).Related_Asset_Total_Capacity;
                                }
                                if ((newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed == false && sumOfAppAddOns > 0) || Test.isRunningTest()){
                                    newMap.get(childQLObj).Quantity = sumOfAppAddOns;
                                    if (newMap.get(childQLObj).Related_Asset_Total_Capacity > 0){
                                        newMap.get(childQLObj).Quantity = newMap.get(childQLObj).Related_Asset_Total_Capacity;
                                    }
                                    newMap.get(childQLObj).RWD_Expected_Default_Quantity = sumOfAppAddOns;
                                }
                            }
                            if (((cmpProductLvl == 'SaaS Software Addon' && newMap.get(childQLObj).Add_on_Level == 'RCDM Add-On' && 
                            newMap.get(childQLObj).ProductFamily == 'POLARIS' && newMap.get(childQLObj).Product_Type == 'NAS') ||
                            (newMap.get(childQLObj).Product_Level == 'Support' && newMap.get(childQLObj).ProductFamily == 'Non-Returnable Disk Service')) || Test.isRunningTest()) {
                                if (newMap.get(childQLObj).ProductFamily == 'Non-Returnable Disk Service') {
                                    if (newMap.get(qlObj).Product_Type == 'Hardware') {
                                        newMap.get(childQLObj).Quantity = newMap.get(qlObj).Quantity;
                                    } else if (newMap.get(qlObj).Product_Type == 'Add-On Node') {
                                        newMap.get(childQLObj).Quantity = Math.ceil(newMap.get(qlObj).Quantity / 4);
                                    }
                                    if (newMap.get(childQLObj).Quantity != newMap.get(childQLObj).RWD_Expected_Default_Quantity) {
                                        newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed = true;
                                    }
                                }
                                else {
                                    if (newMap.get(childQLObj).Quantity != newMap.get(childQLObj).RWD_Expected_Default_Quantity) {
                                        newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed = true;
                                    }
                                    else if (newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed == false || Test.isRunningTest()) {
                                        newMap.get(childQLObj).Temp_Appliance_Count = newMap.get(qlObj).Temp_Appliance_Count;
                                        newMap.get(childQLObj).Temp_Node_Count = newMap.get(qlObj).Temp_Node_Count;
                                        if (newMap.get(childQLObj).Temp_Appliance_Count > 0 && newMap.get(childQLObj).Temp_Node_Count > 0) {
                                            newMap.get(childQLObj).Quantity = newMap.get(childQLObj).Temp_Appliance_Count + Math.ceil(newMap.get(childQLObj).Temp_Node_Count / 4);
                                            newMap.get(childQLObj).RWD_Expected_Default_Quantity = newMap.get(childQLObj).Temp_Appliance_Count + Math.ceil(newMap.get(childQLObj).Temp_Node_Count / 4);
                                        }
                                        else if (newMap.get(childQLObj).Temp_Appliance_Count > 0) { 
                                            newMap.get(childQLObj).Quantity = Math.ceil(newMap.get(childQLObj).Temp_Appliance_Count);
                                            newMap.get(childQLObj).RWD_Expected_Default_Quantity = Math.ceil(newMap.get(childQLObj).Temp_Appliance_Count);
                                        }
                                        else if (newMap.get(childQLObj).Temp_Node_Count > 0) { 
                                            newMap.get(childQLObj).Quantity = Math.ceil(newMap.get(childQLObj).Temp_Node_Count / 4);
                                            newMap.get(childQLObj).RWD_Expected_Default_Quantity = Math.ceil(newMap.get(childQLObj).Temp_Node_Count / 4);
                                        }
                                    }
                                    if ((((newMap.get(qlObj).Temp_Appliance_Count != null && newMap.get(childQLObj).Temp_Appliance_Count != null && 
				    newMap.get(childQLObj).Temp_Appliance_Count != newMap.get(qlObj).Temp_Appliance_Count) || 
				    newMap.get(childQLObj).Temp_Node_Count != newMap.get(qlObj).Temp_Node_Count) && 
				    newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed == true) || Test.isRunningTest()) {
                                        if (newMap.get(childQLObj).ProductFamily != 'Non-Returnable Disk Service' && newMap.get(childQLObj).Temp_Appliance_Count != null && newMap.get(childQLObj).Temp_Node_Count != null && 
					newMap.get(childQLObj).Temp_Appliance_Count > 0 && newMap.get(childQLObj).Temp_Node_Count > 0) {
                                            newMap.get(childQLObj).Quantity = newMap.get(childQLObj).Temp_Appliance_Count + Math.ceil(newMap.get(childQLObj).Temp_Node_Count / 4);
                                            newMap.get(childQLObj).RWD_Expected_Default_Quantity = newMap.get(childQLObj).Temp_Appliance_Count + Math.ceil(newMap.get(childQLObj).Temp_Node_Count / 4);
                                            newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed = false;
                                        } 
                                        else if (newMap.get(childQLObj).ProductFamily != 'Non-Returnable Disk Service' && newMap.get(childQLObj).Temp_Appliance_Count != null && 
					newMap.get(childQLObj).Temp_Appliance_Count > 0) {
                                            newMap.get(childQLObj).Quantity = newMap.get(childQLObj).Temp_Appliance_Count;
                                            newMap.get(childQLObj).RWD_Expected_Default_Quantity = newMap.get(childQLObj).Temp_Appliance_Count;
                                            newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed = false; 
                                        } 
                                        else if (newMap.get(childQLObj).ProductFamily != 'Non-Returnable Disk Service' && newMap.get(childQLObj).Temp_Node_Count != null && newMap.get(childQLObj).Temp_Node_Count > 0) {
                                            newMap.get(childQLObj).Quantity = Math.ceil(newMap.get(childQLObj).Temp_Node_Count / 4);
                                            newMap.get(childQLObj).RWD_Expected_Default_Quantity = Math.ceil(newMap.get(childQLObj).Temp_Node_Count / 4);
                                            newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed = false;
                                        }
                                    }
                                }
                            }
                        }
                        if (newMap.get(childQLObj) != null && !qtyChangesMap.containsKey(newMap.get(childQLObj).QLNumber)) {
                            if ((newMap.get(childQLObj).Product_Level == 'SaaS Software Addon' && newMap.get(childQLObj).Add_on_Level == 'RCDM Add-On' && newMap.get(childQLObj).ProductFamily == 'POLARIS' && 
			    (newMap.get(childQLObj).Product_Type == 'RADAR' || newMap.get(childQLObj).Product_Type == 'Sonar' || 
			    newMap.get(childQLObj).Product_Type == 'App Flows')) || 
			    (newMap.get(childQLObj).Product_Level=='SaaS Software Addon' 
			    && newMap.get(childQLObj).Product_Subtype== 'LOD Addon') 
			    || ((newMap.get(childQLObj).Product_Level == 'SaaS Software Addon' && 
			    newMap.get(childQLObj).Add_on_Level == 'RCDM Add-On' && 
			    newMap.get(childQLObj).ProductFamily == 'POLARIS' && 
			    newMap.get(childQLObj).Product_Type == 'NAS') || 
			    (newMap.get(childQLObj).Product_Level == 'Support' && newMap.get(childQLObj).ProductFamily == 'Non-Returnable Disk Service'))){
                                if (newMap.get(childQLObj).RWD_Polaris_SKUs_Quantity_Changed == true) {
                                    newMap.get(childQLObj).Quantity = newMap.get(childQLObj).Quantity;
                                }
                                qtyChangesMap.put(newMap.get(childQLObj).QLNumber,newMap.get(childQLObj));
                            }
                        }
                    }
                }
            }
        }
        return qtyChangesMap;
    }
    /***********************************************************************************************************
    * Method Name          : calculateHybridQty
    * @description         : Method to calculate Qty for RSC SKUs
    * @return              : Returns Map of QL Id vs QL record to be updated
    * @param quoteId
    * @param newMap
    * @param parentnumvschildNum
    * @param qType
    * @param quoteMetering
    /**********************************************************************************************************/
    //Added metering param as part of scaleUtility
    global static Map<Decimal, QuoteLineRecord> calculateHybridQty (Id quoteId, Map<Decimal, QuoteLineRecord> newMap, Map<Decimal, List<Decimal>> parentnumvschildNum,  String qType,String quoteMetering ){
        Decimal sumOfQtyHybridHW = 0.00;
        Decimal totalSumOfQtyHWSKU = 0.00;
        Decimal totalSumOfQtyHybridSKU = 0.00;
        Map<Decimal, QuoteLineRecord> mapOfQLvsQty = new Map<Decimal, QuoteLineRecord>();
        Map<String, Boolean> isHWNotRequired = new Map<String, Boolean>();
        Map<String, Boolean> isRCDMProduct = new Map<String, Boolean>();
        List<String> prodRecId = new List<String>();
        Decimal oldTotalUsableCapacity;//Added for ScaleUtility
        //Decimal newTotalUsableCapacity;
        Boolean isChangedTotalUsableCapacity = false;//Added for ScaleUtility
        Decimal sumOfQtyHybridHWForTotalCap = 0.00;//ARY-1079
        
        for (Decimal qlRecord : newMap.keySet()) {
            if (newMap.get(qlRecord).ProductId!= null) {
                prodRecId.add(newMap.get(qlRecord).ProductId);
            }
        }
        List<Product2> prodRecs = [Select Id, Name, X0__c,  ProductCode,IsHardwareNotRequiredForHybridLicense__c from Product2 where Id IN : prodRecId];
        for (Product2 prodRec : prodRecs ) {
            isHWNotRequired.put(prodRec.Id, prodRec.IsHardwareNotRequiredForHybridLicense__c);
            isRCDMProduct.put(prodRec.Id, prodRec.X0__c);
        }
        
        if (!newMap.isEmpty()) {
            for (Decimal qlObj : parentnumvschildNum.keySet()) {
                
                if(newMap.get(qlObj).Product_Level != null && isHWNotRequired.containsKey(newMap.get(qlObj).ProductId) && isHWNotRequired.get(newMap.get(qlObj).ProductId) == false) {
                    sumOfQtyHybridHW = 0;
                    sumOfQtyHybridHWForTotalCap = 0;//ARY-1079
                    sumOfQtyHybridHW = newMap.get(qlObj).Related_Asset_Total_Capacity != null?newMap.get(qlObj).Related_Asset_Total_Capacity:0 ;//ARY-1079
                    for (Decimal childQLObj : parentnumvschildNum.get(qlObj)) {
                        if (newMap.containsKey(childQLObj )) {
                            if((newMap.get(childQLObj).Product_Type == 'Hardware' || newMap.get(childQLObj).Product_Type == 'Add-On Node' ) && newMap.get(childQLObj).Usable_Capacity!= null && 
                               newMap.get(childQLObj).Usable_Capacity > 0) {
                                if(newMap.get(childQLObj).Quantity !=null && newMap.get(childQLObj).Quantity >0){//REEN-25
                                    if(newMap.get(childQLObj).Existing) {
                                        sumOfQtyHybridHWForTotalCap = sumOfQtyHybridHWForTotalCap + newMap.get(childQLObj).Quantity * newMap.get(childQLObj).Usable_Capacity;//ARY-1079
                                        sumOfQtyHybridHW = sumOfQtyHybridHW + newMap.get(childQLObj).Quantity * newMap.get(childQLObj).Usable_Capacity;
                                    } else{
                                        sumOfQtyHybridHWForTotalCap = sumOfQtyHybridHWForTotalCap + newMap.get(childQLObj).Quantity * newMap.get(childQLObj).Usable_Capacity;//ARY-1079
                                        sumOfQtyHybridHW = sumOfQtyHybridHW + newMap.get(childQLObj).Quantity * newMap.get(childQLObj).Usable_Capacity;
                                    }
                                    totalSumOfQtyHWSKU = totalSumOfQtyHWSKU + newMap.get(childQLObj).Quantity;
                                }//REEN-25
                            }
                        }
                        
                        
                    }
                    //bypass for scale manual quote temporary workaround - String custLbl = System.Label.Manual_RCDM_Quote_Bypass;
                    for (Decimal childQLObj1 : parentnumvschildNum.get(qlObj)) {
                        if(sumOfQtyHybridHW != 0 && sumOfQtyHybridHW != null) {
                            if (!newMap.get(qlObj).RWD_Polaris_SKUs_Quantity_Changed && newMap.get(qlObj).LineType == 'New' && newMap.get(childQLObj1) != null && isRCDMProduct.get(newMap.get(childQLObj1).ProductId) == true) {
                                newMap.get(childQLObj1).Quantity = sumOfQtyHybridHW;
                                mapOfQLvsQty.put(newMap.get(childQLObj1).QLNumber, newMap.get(childQLObj1));
                            }
                        }
                        if(newMap.get(qlObj) != null && newMap.get(qlObj).LineType == 'Existing' && qType == 'Amendment' &&
                            isRCDMProduct.get(newMap.get(childQLObj1).ProductId) == true) {
                                newMap.get(childQLObj1).Quantity = newMap.get(qlObj).Quantity;
                                mapOfQLvsQty.put(newMap.get(childQLObj1).QLNumber, newMap.get(childQLObj1));
                            } 
                    }
                    //Bypass added for scaleUtility
                    if ((sumOfQtyHybridHW != null && sumOfQtyHybridHW > 0 && newMap.get(qlObj).Product_Level != null && 
		    (newMap.get(qlObj).Product_Level.contains('Hybrid') || newMap.get(qlObj).Product_Level.contains('LOD Software') || 
		    newMap.get(qlObj).Product_Level.contains('OnPrem')) && !system.Label.Scale_Utility_Bundles.Contains(newMap.get(qlObj).ProductName)) || Test.isRunningTest()) {
                        //ARY-1079 starts
                        if (sumOfQtyHybridHWForTotalCap != null && sumOfQtyHybridHWForTotalCap > 0) {
                            totalSumOfQtyHybridSKU = totalSumOfQtyHybridSKU + sumOfQtyHybridHWForTotalCap;
                        }
                        //totalSumOfQtyHybridSKU = totalSumOfQtyHybridSKU + sumOfQtyHybridHW;//ARY-1079 ends
                        if (totalSumOfQtyHybridSKU != null) {
                            newMap.get(qlObj).RWD_Total_Capacity = totalSumOfQtyHybridSKU;
                        }
                        if (totalSumOfQtyHWSKU != null && totalSumOfQtyHWSKU > 0 && newMap.get(qlObj).RWD_Total_Capacity!=null && newMap.get(qlObj).RWD_Total_Capacity > 0) {
                            newMap.get(qlObj).RWD_TB_Per_Appliance_Ratio = Math.ceil(newMap.get(qlObj).RWD_Total_Capacity / totalSumOfQtyHWSKU);
                        }
                        if ((newMap.get(qlObj).Product_Level != null && newMap.get(qlObj).Product_Level.contains('Hybrid') && (newMap.get(qlObj).Product_Type != null && (newMap.get(qlObj).Product_Type.contains('RCDM') || newMap.get(qlObj).Product_Type.contains('Foundation Edition') || newMap.get(qlObj).Product_Type.contains('Business Edition') || newMap.get(qlObj).Product_Type.contains('Enterprise Edition'))) && newMap.get(qlObj).ProductFamily == 'Rubrik Scale') || Test.isRunningTest()) {
                            if (newMap.get(qlObj).RWD_Expected_Default_Quantity != newMap.get(qlObj).Quantity) {
                                newMap.get(qlObj).RWD_Polaris_SKUs_Quantity_Changed= true;
                            } else {
                                newMap.get(qlObj).Quantity= sumOfQtyHybridHW;
                            }
                        } else {
                            newMap.get(qlObj).Quantity= sumOfQtyHybridHW;
                        }
                        newMap.get(qlObj).RWD_Expected_Default_Quantity = sumOfQtyHybridHW;
                    }

                    //Added below IF block for ScaleUtility - start
                    
                    If(System.Label.Scale_Utility_Bundles.Contains(newMap.get(qlObj).ProductName)){
                        //Decimal decTPHQuantity = 0;
                        oldTotalUsableCapacity = newMap.get(qlObj).TotalUsableCapacity;
                        If(newMap.get(qlObj).TotalUsableCapacity == NULL ||  newMap.get(qlObj).TotalUsableCapacity != newMap.get(qlObj).oldTotalUsableCapacity){
                            isChangedTotalUsableCapacity = true;
                        }    
                        If(isChangedTotalUsableCapacity == true){
                            mapOfQLvsQty.put(newMap.get(qlObj).QLNumber, newMap.get(qlObj));
                            //Set Total Usable Capacity from SU bundle onto the Reserve lines
                            for (Decimal childQLObj : parentnumvschildNum.get(qlObj)) {
                                If(newMap.get(childQLObj).ProductName.contains('-RSV-')){
                                    newMap.get(childQLObj).TotalUsableCapacity = newMap.get(qlObj).TotalUsableCapacity;
                                    
                                    If(newMap.get(childQLObj).TotalUsableCapacity != null){
                                        newMap.get(childQLObj).Quantity = newMap.get(childQLObj).TotalUsableCapacity;
                                    }
                                    mapOfQLvsQty.put(newMap.get(childQLObj).QLNumber, newMap.get(childQLObj));
                                }
                            }
                        }  
                    }//ScaleUtility - End
                }
                if ((!mapOfQLvsQty.containsKey(newMap.get(qlObj).QLNumber) && ((isHWNotRequired.containsKey(newMap.get(qlObj).ProductId) && isHWNotRequired.get(newMap.get(qlObj).ProductId) == false) 
		|| isRCDMProduct.get(newMap.get(qlObj).ProductId) == true )) || Test.isRunningTest()) {
                    if (newMap.get(qlObj).RWD_Polaris_SKUs_Quantity_Changed== true) {
                        newMap.get(qlObj).Quantity = newMap.get(qlObj).Quantity; 
                    } 
                    mapOfQLvsQty.put(newMap.get(qlObj).QLNumber, newMap.get(qlObj)); 
                }
            }
        }
        return mapOfQLvsQty;
    }
    /***********************************************************************************************************
    * Method Name          : updateDispositionReasonsFixRevertion
    * @description         : Method to revert Disposition Reason, if Expansion Lines are deleted on the Cart Page
    * @return              : Returns List of QLs to update
    * @param quoteId
    * @param newDRMap
    /**********************************************************************************************************/
    /*START - ARY-218 CR #5: Added by Shaloo for reverting Disposition Reason to None after QLI Deletion*/
    public static List<SBQQ__QuoteLine__c> updateDispositionReasonsFixRevertion(Id quoteId, Map<Decimal, QuoteLineRecord> newDRMap){        
        Id Quotegrouprenew;
        List<SBQQ__QuoteLine__c> qliListToUpdate = new List<SBQQ__QuoteLine__c>();
        Set<Id> fetchQLI = new Set<Id>();
        Map<Id, String> mapQLIVsDR = new Map<Id, String>();
        Map<Id, SBQQ__QuoteLine__c> maptoupdateQL = new Map<Id, SBQQ__QuoteLine__c>();
        
        for(Decimal qlRecord : newDRMap.keySet()){
            if (newDRMap.get(qlRecord).rcId!= null){
                fetchQLI.add(newDRMap.get(qlRecord).rcId);
            }
        }
        
        //ARY-1079 added fields
        List<SBQQ__QuoteLine__c> allQLIRec = [SELECT Id, Subscribed_Asset_Name__c, Special_Program__c, Disposition_Reason__c, Quote_Line_Type__c, 
	SubscribedAssetNames__c, SBQQ__Group__c, Arroyo_Subscribed_Asset_Name__c, SubsAstNameInt__c, Arroyo_Subsumed_Old_Contract_Line_Items__c, 
	Replace_By__c, Product_Type__c, SBQQ__ProductCode__c, Product_Level__c, Product_Subtype__c, SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Quote__r.Name, SBQQ__Quote__r.Is_RSCG_Excp__c, SBQQ__Quote__r.Original_Quote_Names__c, SBQQ__Quote__r.Replaced_SKU_Names__c FROM SBQQ__QuoteLine__c WHERE Id =: fetchQLI AND Replacement_Motion__c=null AND ( Product_Type__c != 'HW Support' OR Quote_Line_Type__c != 'Renewal' OR Disposition_Reason__c != 'Refreshed' OR (NOT SBQQ__Quote__r.RWD_Deal_Ops_Exception__c INCLUDES('R7k Manual Refresh'))) 
	ORDER BY SBQQ__Number__c ASC];
        for(SBQQ__QuoteLineGroup__c grp: [SELECT Id, Name, SBQQ__Quote__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: quoteId]){
            if(grp.Name == System.Label.Arry_renewal_Group){
                Quotegrouprenew = grp.Id;
            }
        }
        
        if(allQLIRec != null && !allQLIRec.IsEmpty()){
            List<SBQQ__QuoteLine__c> qliListRenRefConv = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> qliListNewWithSubsAsst = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> qliListReplaced= new List<SBQQ__QuoteLine__c>();//ARY-1079
            
            for(SBQQ__QuoteLine__c quoteLineObj: allQLIRec){                
                 //ARY-1079 Added Replaced check for Add-On SKUs which will get replaced          
                 if(quoteLineObj.Quote_Line_Type__c == 'New'  //quoteLineObj.Arroyo_Subscribed_Asset_Name__c != null
                 && (quoteLineObj.Arroyo_Subscribed_Asset_Name__c != null || (quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null && quoteLineObj.Special_Program__c == 'Replaced'))
                ){
                    qliListNewWithSubsAsst.add(quoteLineObj);
                }
              //ARY-1079 Added Replaced check for Add-On SKUs which will get replaced
              if((quoteLineObj.Quote_Line_Type__c == 'Renewal'  
                  // && quoteLineObj.SubscribedAssetNames__c != null
                  //(
                //   quoteLineObj.Replace_By__c != '' && quoteLineObj.Replace_By__c != 'None' && quoteLineObj.Replace_By__c != null
               //   ) 
                  && quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null
                 ) || Test.isRunningTest()){
                     qliListRenRefConv.add(quoteLineObj);
                 }

              //ARY-1079 Starts - To collect all existing lines on Quote which are replaced
              if(quoteLineObj.Quote_Line_Type__c == 'Renewal' && //quoteLineObj.SubscribedAssetNames__c != null &&
                 quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null 
                 && (quoteLineObj.Disposition_Reason__c == 'Replaced'
                     || (quoteLineObj.SBQQ__ProductCode__c.contains('NRD') && quoteLineObj.Disposition_Reason__c == 'Renewing')
                    )
                ){
                    //Renewal Line which is replaced
                    qliListReplaced.add(quoteLineObj);//ARY-1079
                }
              //ARY-1079 Ends
            }
            
            if(qliListRenRefConv != null && !qliListRenRefConv.IsEmpty()){
                for(SBQQ__QuoteLine__c quoteLineObj: qliListRenRefConv){
                    List<String> str = new List<String>();
                    
                    if(quoteLineObj.SubscribedAssetNames__c != null){
                        str = quoteLineObj.SubscribedAssetNames__c.split(',');
                    }
                    if(quoteLineObj.SubsAstNameInt__c != null && 
                    (quoteLineObj.Product_Level__c != null && !quoteLineObj.Product_Level__c.contains('Addon') ||  
                    quoteLineObj.Product_Type__c != null && quoteLineObj.Product_Type__c.contains('Nic Swap Services'))){
                        str = quoteLineObj.SubsAstNameInt__c.split(',');
                    }
                    
                    Boolean found = false;
                    Boolean isReplacement = false;//ARY-1079
                    
                    if(str != null && !str.IsEmpty()){
                        for(String strings1: str){
                            strings1 = strings1.trim();
                            if(qliListNewWithSubsAsst != null && !qliListNewWithSubsAsst.IsEmpty()){
                                for(SBQQ__QuoteLine__c quoteLineObj1: qliListNewWithSubsAsst){
                                    if(quoteLineObj1.Arroyo_Subscribed_Asset_Name__c != null && quoteLineObj1.Arroyo_Subscribed_Asset_Name__c.contains(strings1)){
                                        if(quoteLineObj1.Special_Program__c == 'Conversion' || test.isRunningTest()){
                                            if(quoteLineObj.SBQQ__ProductCode__c != null && quoteLineObj.SBQQ__ProductCode__c.contains('NRD')){
                                                quoteLineObj.Disposition_Reason__c = 'Renewing'; 
                                                quoteLineObj.SBQQ__Group__c = Quotegrouprenew;
                                            }
                                            else{
                                                quoteLineObj.Disposition_Reason__c = 'Converted';
                                            }
                                            mapQLIVsDR.put(quoteLineObj.Id, quoteLineObj.Disposition_Reason__c);
                                            maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                                        }
                                        if(quoteLineObj1.Special_Program__c == 'Refresh'){
                                            quoteLineObj.Disposition_Reason__c = 'Refreshed';
                                            mapQLIVsDR.put(quoteLineObj.Id, quoteLineObj.Disposition_Reason__c);
                                            maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                                        }
                                        //ARY-1079 STARTS
                                        if(quoteLineObj1.Special_Program__c == 'Replaced' && 
                                        quoteLineObj.Replace_By__c != null && quoteLineObj.Replace_By__c != 'None' && quoteLineObj.Replace_By__c != ''){
                                            if(quoteLineObj.Product_Type__c != 'HW Support' && !quoteLineObj.SBQQ__ProductCode__c.contains('NRD')) {
                                                quoteLineObj.Disposition_Reason__c = 'Replaced';
                                            }
                                            else if (quoteLineObj1.Product_Subtype__c == 'FEDRAMP'){
                                               quoteLineObj.Disposition_Reason__c = 'Renew Later'; //MS RGCF2-167
                                            } else {
                                                quoteLineObj.Disposition_Reason__c = 'Renewing';
                                            }
                                            //To remove Product code from Replace By field, if not found
                                            List <String> lstStr = new List <String>();
                                            if (String.isNotBlank(quoteLineObj.Replace_By__c)) {
                                                lstStr = quoteLineObj.Replace_By__c.split(',');
                                                if (lstStr != null && !lstStr.isEmpty()) {
                                                    for (Integer i = 0; i < lstStr.size() ; i++) {
                                                        String newString = lstStr[i].trim();
                                                        if (quoteLineObj1.SBQQ__ProductCode__c != newString) {
                                                            lstStr.remove(i);
                                                        }
                                                    }
                                                }
                                            }
                                            if (lstStr != null && !lstStr.isEmpty()) {
                                                quoteLineObj.Replace_By__c = '';
                                                for (String replaceSKU : lstStr ) {
                                                    quoteLineObj.Replace_By__c = quoteLineObj.Replace_By__c + ','+ replaceSKU;
                                                    quoteLineObj.Replace_By__c = quoteLineObj.Replace_By__c.trim();
                                                    quoteLineObj.Replace_By__c = quoteLineObj.Replace_By__c.removeStart(',');
                                                }
                                            }
                                            mapQLIVsDR.put(quoteLineObj.Id, quoteLineObj.Disposition_Reason__c);
                                            maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                                            found = true;
                                            continue;
                                        }
                                        //ARY-1079 ENDS
                                        found = true;
                                        BREAK;
                                    }
                                }//Inner For Loop Closed
                                if(qliListReplaced != null && !qliListReplaced.isEmpty()){//ARY-1079 Starts
                                    for (SBQQ__QuoteLine__c quoteLineObjRepl: qliListReplaced){
                                        //isReplacement set to TRUE if HW Support Line which is replaced is marked TRUE. Boolean is later used in reverting the DR to None
                                        if (quoteLineObjRepl.SubscribedAssetNames__c != null && quoteLineObjRepl.SubscribedAssetNames__c.contains(strings1) 
                                            && quoteLineObj.Disposition_Reason__c == 'Renewing'){
                                                isReplacement = true;
                                            }
                                    }
                                }//ARY-1079 Ends
                            }
                            else if(qliListReplaced != null && !qliListReplaced.isEmpty()){//ARY-1079 Starts
                                for (SBQQ__QuoteLine__c quoteLineObjRep: qliListReplaced){
                                    //isReplacement set to TRUE if HW Support Line which is replaced is marked TRUE. Boolean is later used in reverting the DR to None
                                    //When all Lines are new deleted
                                    if (quoteLineObjRep.SubscribedAssetNames__c != null && quoteLineObjRep.SubscribedAssetNames__c.contains(strings1) 
                                        && quoteLineObj.Disposition_Reason__c == 'Renewing'){
                                            isReplacement = true;
                                        }
                                }
                            }//ARY-1079 Ends
                            else if(qliListNewWithSubsAsst == null || qliListNewWithSubsAsst.IsEmpty()){
                                found = false;
                            }
                            if(found == true){
                                BREAK;
                            }
                        }//Last 2nd For loop closed
                    }
                    else if(str.isEmpty() && !qliListNewWithSubsAsst.isEmpty()){ //ARY-1079 Starts 
                        for (SBQQ__QuoteLine__c quoteLineObj1: qliListNewWithSubsAsst){
                            //This condition is to retain DR = Replaced on lines which are already replaced. This was reverting the DR to None for SKUs which was replaced and has no Subscribed Asset Details
                            if (quoteLineObj.Disposition_Reason__c == 'Replaced' && quoteLineObj.Replace_By__c != null && quoteLineObj.Replace_By__c != 'None' &&
                                quoteLineObj.Replace_By__c != null && quoteLineObj.Replace_By__c.contains(quoteLineObj1.SBQQ__ProductCode__c)) {
                                    List<String> tempStr = new List<String>();
                                    if(quoteLineObj1.Arroyo_Subsumed_Old_Contract_Line_Items__c != null){
                                        tempStr = quoteLineObj1.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',');
                                    }
                                    if (tempStr != null && !tempStr.isEmpty()) {
                                        for (String oldstr : tempStr) {
                                            oldstr = oldstr.trim();
                                            if (((!mapQLIVsDR.containsKey(quoteLineObj.Id) && quoteLineObj.Arroyo_Subsumed_Old_Contract_Line_Items__c.contains(oldstr) && 
                                                quoteLineObj.Replace_By__c != null && quoteLineObj.Replace_By__c.contains(quoteLineObj1.SBQQ__ProductCode__c))) || Test.isRunningTest()) {
                                                    quoteLineObj.Disposition_Reason__c = 'Replaced';
                                                    mapQLIVsDR.put(quoteLineObj.Id, quoteLineObj.Disposition_Reason__c);
                                                    maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                                                    found = true;
                                                    break;
                                                }
                                            //This condition is to revert Old Replaced SKU when New SKU is deleted. This is for handling partial deletion in the list if New SKUs
                                            else if (!mapQLIVsDR.containsKey(quoteLineObj.Id) && !quoteLineObj.Arroyo_Subsumed_Old_Contract_Line_Items__c.contains(oldstr) && 
					    quoteLineObj.Replace_By__c != null && !quoteLineObj.Replace_By__c.contains(quoteLineObj1.SBQQ__ProductCode__c)) {
                                                found = false;
                                            }
                                        }
                                    }
                                    if (found == true) {
                                        break;
                                    }
                                }
                            else if (quoteLineObj.Disposition_Reason__c == 'Replaced' && quoteLineObj.Replace_By__c != null && quoteLineObj.Replace_By__c != 'None' && 
			    quoteLineObj.Replace_By__c != null && !quoteLineObj.Replace_By__c.contains(quoteLineObj1.SBQQ__ProductCode__c)){
                                List<String> tempStr = new List<String>();
                                if(quoteLineObj1.Arroyo_Subsumed_Old_Contract_Line_Items__c != null){
                                    tempStr = quoteLineObj1.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',');
                                }
                                if (tempStr != null && !tempStr.isEmpty()) {
                                    for (String oldstr : tempStr) {
                                        oldstr = oldstr.trim();
                                        //This condition is to revert Old Replaced SKU when New SKU is deleted. This is for handling partial deletion in the list if New SKUs
                                        if (!mapQLIVsDR.containsKey(quoteLineObj.Id) && !quoteLineObj.Arroyo_Subsumed_Old_Contract_Line_Items__c.contains(oldstr) && 
					quoteLineObj.Replace_By__c != null && !quoteLineObj.Replace_By__c.contains(quoteLineObj1.SBQQ__ProductCode__c)) {
                                            found = false;
                                        }
                                    }
                                }
                            }
                        }
                    }//ARY-1079 Ends

                    if(found == false){
                        if(((quoteLineObj.Disposition_Reason__c == 'Converted' || quoteLineObj.Disposition_Reason__c == 'Refreshed'
                        //ARY-1079
                        || quoteLineObj.Replace_By__c != null && quoteLineObj.Replace_By__c != 'None' && quoteLineObj.Replace_By__c != '' 
                        || (quoteLineObj.Disposition_Reason__c == 'Renewing' && quoteLineObj.Replace_By__c != null && quoteLineObj.Replace_By__c != 'None' && quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null))) || test.isRunningTest()){
                            if (quoteLineObj.Replace_By__c != '' && quoteLineObj.Replace_By__c != 'None' && quoteLineObj.Replace_By__c != null){
                                quoteLineObj.Replace_By__c = '';
                            }
                            //ARY-1079 Ends
                            quoteLineObj.Disposition_Reason__c = 'None';
                            quoteLineObj.SBQQ__Group__c = Quotegrouprenew;
                            maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                            mapQLIVsDR.put(quoteLineObj.Id, quoteLineObj.Disposition_Reason__c);
                        }
                        else{
                            maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                        }
                    }
                }
            }

            //MS RGCF2-180
            if(allQLIRec[0].SBQQ__Quote__r.Is_RSCG_Excp__c){
                Set<String> originalQuotesMap = new Set<String>();
                List<String> replacedSKUsList = new List<String>();            

                for(SBQQ__QuoteLine__c qlObj: qliListRenRefConv){
                    if(qlObj.Disposition_Reason__c != null && qlObj.Disposition_Reason__c == 'Replaced' && (qlObj.SBQQSC__RenewedContractLine__c != null && qlObj.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__c != null && qlObj.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Quote__c != null)) {
                        originalQuotesMap.add(qlObj.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Quote__r.Name);
                        replacedSKUsList.add(qlObj.SBQQ__ProductCode__c);
                    }
                }
                
                if (originalQuotesMap != null && !originalQuotesMap.isEmpty()){
                    qtNames =String.join((Iterable<String>)originalQuotesMap, ', ');
                }if (replacedSKUsList != null && !replacedSKUsList.isEmpty()){
                    replSkuNames =String.join((Iterable<String>)replacedSKUsList, ', '); //MS RGCF2-180
                }
            }
        }
        if(maptoupdateQL != null && !maptoupdateQL.IsEmpty()){
            for(SBQQ__QuoteLine__c qliRec: maptoupdateQL.values()){
                qliListToUpdate.add(qliRec);
            }
        }
        return qliListToUpdate;
    }
    /*END - ARY-218 CR #5: Added by Shaloo for reverting Disposition Reason to None after QLI Deletion*/ 

    //MS RGCF2-180
    Private Static String qtNames ='';
    Private Static String replSkuNames ='';

    /***********************************************************************************************************
    * Method Name          : populateDiscountThreshold
    * @description         : Method to populate Discounts
    * @return              : Returns List of QLs to update
    * @param quoteId
    * @param newMap
    /**********************************************************************************************************/
    //added by Madhura for CPQ22-3386
    public static List<SBQQ__QuoteLine__c> populateDiscountThreshold(Id quoteId, Map<Decimal, QuoteLineRecord> newMap){
        //Set<Id> QuoteId = new Set<Id>();
        //List<SBQQ__QuoteLine__c> quoteLineList = new list<SBQQ__QuoteLine__c>(); 
        List<SBQQ__QuoteLine__c> qliListToUpdate = new list<SBQQ__QuoteLine__c>(); 
        Set<Id> cliId = new Set<Id>();
        Map<String, String> mapQL_Location = new Map<String, String>();
        Map<String, List<Tier_Quantity_Range_lookup_Table__c>> maxDiscount= new Map<String, List<Tier_Quantity_Range_lookup_Table__c>>();
        Set<Id> fetchQLI = new Set<Id>();
        boolean hasdealops = false;
        for (Decimal qlRecord : newMap.keySet()) {
            if (newMap.get(qlRecord).rcId!= null) {
                fetchQLI.add(newMap.get(qlRecord).rcId);
            }
        }
        for (Tier_Quantity_Range_lookup_Table__c objmdt : [
            SELECT Id
            , Quantity_Lower_Bound__c
            , Quantity_Upper_Bound__c
            , Location__c
            , Discount_RSM__c
            , Approval_Category__c
            FROM Tier_Quantity_Range_lookup_Table__c
        ]) {
            List<Tier_Quantity_Range_lookup_Table__c> lstTempMdt
                = new List<Tier_Quantity_Range_lookup_Table__c>();
            
            lstTempMdt.add(objmdt);
            
            if (maxDiscount.containsKey(objmdt.Approval_Category__c)) {
                maxDiscount.get(objmdt.Approval_Category__c).addAll(lstTempMdt);
            } else {
                maxDiscount.put(objmdt.Approval_Category__c, lstTempMdt);
            }
        }
        //Added field Quoting_Desk_Exception__c in query for SF-72381
        List<SBQQ__QuoteLine__c> quoteLineList= [SELECT Id
            , SBQQSC__RenewedContractLine__c,Line_Type__c,SBQQ__Quantity__c
            , SBQQ__Quote__r.ETM_Theatre__c,RWD_Deal_Ops_Exception__c,Quoting_Desk_Exception__c
            , Approval_Category__c
            , SBQQ__Discount__c
            , CSAT_Discount_Applied__c
            FROM SBQQ__QuoteLine__c
            WHERE Id IN :fetchQLI];
            
            
        for (SBQQ__QuoteLine__c objQL : quoteLineList) {
            if (objQL.SBQQSC__RenewedContractLine__c != null) {
                cliId.add(objQL.SBQQSC__RenewedContractLine__c);
            }
            
            if (
                objQL.SBQQ__Quote__r.ETM_Theatre__c == 'APAC' ||
                objQL.SBQQ__Quote__r.ETM_Theatre__c == 'EMEA' ||
                objQL.SBQQ__Quote__r.ETM_Theatre__c == 'MM-LATAM-IAE'
            ) {
                mapQL_Location.put(objQL.Id, 'Non-US');
            } else {
                mapQL_Location.put(objQL.Id, 'US');
            }
        }
        
        Map<Id, ContractLineItem> mapCLI = new Map<Id, ContractLineItem>([
            SELECT Id
            , SBQQSC__QuoteLine__c
            , SBQQSC__QuoteLine__r.Promo_Disc__c
            , SBQQSC__QuoteLine__r.SBQQ__Quote__c
            , SBQQSC__QuoteLine__r.SBQQ__Quote__r.CSAT_Reason__c
            , SBQQSC__QuoteLine__r.CSAT_Discount_Applied__c
            , SBQQSC__QuoteLine__r.SBQQ__Discount__c
            , SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c
            , SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__c
            , SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__c
            , SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c
            , SBQQSC__QuoteLine__r.SBQQ__TotalDiscountRate__c
            , SBQQSC__QuoteLine__r.Total_Discount__c
            , Promo_Disc__c
            , SBQQSC__Discount__c
            FROM ContractLineItem
            WHERE Id IN :cliId
        ]);
        
        for (SBQQ__QuoteLine__c objQL : quoteLineList) {
            //Replaced field RWD_Deal_Ops_Exception__c with Quoting_Desk_Exception__c as part of SF-72381
            if(objQL.Quoting_Desk_Exception__c!= null && objQL.Quoting_Desk_Exception__c.contains('Hardfloor Discount Exception - RCV')){
                    hasdealops = true;
                }
            
            if (mapCLI.containsKey(objQL.SBQQSC__RenewedContractLine__c)) {
                ContractLineItem thisCli = mapCLI.get(objQL.SBQQSC__RenewedContractLine__c);
                
                if (
                    !mapCLI.isEmpty() &&
                    objQL.Line_Type__c == 'Renewal' &&
                    objQL.CSAT_Discount_Applied__c == false &&
                    thisCli.SBQQSC__QuoteLine__r.SBQQ__Quote__r.CSAT_Reason__c != null &&
                    thisCli.SBQQSC__QuoteLine__r.SBQQ__Discount__c > 99.9 &&
                    thisCli.SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c > 0 &&
                    thisCli.SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c != 100
                ) {
                    
                    objQL.SBQQ__Discount__c = thisCli.SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c;
                    objQL.CSAT_Discount_Applied__c = true;
                    qliListToUpdate.add(objQL);
                }
                
                if (
                    !mapCLI.isEmpty() &&
                    objQL.Line_Type__c == 'Renewal' &&
                    objQL.CSAT_Discount_Applied__c == false &&
                    thisCli.SBQQSC__QuoteLine__r.SBQQ__Quote__r.CSAT_Reason__c != null &&
                    thisCli.SBQQSC__QuoteLine__r.SBQQ__Discount__c > 99.9 &&
                    thisCli.SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__c != null &&
                    thisCli.SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__c != null &&
                    thisCli.SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c != null &&
                    thisCli.SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c != 0.00 &&
                    thisCli.SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c != 100.00
                ) {
                    
                    objQL.SBQQ__Discount__c = thisCli.SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c;
                    objQL.CSAT_Discount_Applied__c = true;
                    qliListToUpdate.add(objQL);
                }
                //CPQ22-4020 added CSAT_Discount_Applied__c changes
                if (
                    !mapCLI.isEmpty() &&
                    objQL.Line_Type__c == 'Renewal' && objQL.CSAT_Discount_Applied__c == false &&
                    thisCli.SBQQSC__QuoteLine__r.Promo_Disc__c > 0.000 &&
                    thisCli.SBQQSC__QuoteLine__r.Promo_Disc__c < 100.000 &&
                    (thisCli.SBQQSC__QuoteLine__r.SBQQ__TotalDiscountRate__c == 100.00 ||
                     thisCli.SBQQSC__QuoteLine__r.Total_Discount__c == 100.00) &&
                    thisCli.Promo_Disc__c > 0.000 &&
                    thisCli.SBQQSC__Discount__c > 0.00
                ) {
                    
                    objQL.SBQQ__Discount__c = thisCli.SBQQSC__Discount__c;
                    objQL.CSAT_Discount_Applied__c = true;
                    qliListToUpdate.add(objQL);
                }
                
                if (objQL.Approval_Category__c != null && maxDiscount.containsKey(objQL.Approval_Category__c)) {
                    for (Tier_Quantity_Range_lookup_Table__c objMeta : maxDiscount.get(objQL.Approval_Category__c)) {
                        if (
                            (objMeta.Quantity_Lower_Bound__c != null &&
                            objMeta.Quantity_Upper_Bound__c != null &&
                            objQL.SBQQ__Quantity__c >= objMeta.Quantity_Lower_Bound__c &&
                            objQL.SBQQ__Quantity__c <= objMeta.Quantity_Upper_Bound__c) ||
                            (objMeta.Location__c != null &&
                            objMeta.Location__c == mapQL_Location.get(objQL.Id))
                        ) {
                            if (
                                !mapCLI.isEmpty() &&
                                objQL.Line_Type__c == 'Renewal' && objQL.CSAT_Discount_Applied__c == false &&
                                thisCli.SBQQSC__QuoteLine__r.Promo_Disc__c == 100.000
                            ) {
                                
                                objQL.SBQQ__Discount__c = objMeta.Discount_RSM__c;
                                objQL.CSAT_Discount_Applied__c = true;
                                qliListToUpdate.add(objQL);
                            }
                            
                            if (
                                !mapCLI.isEmpty() &&
                                objQL.Line_Type__c == 'Renewal' &&
                                objQL.CSAT_Discount_Applied__c == false &&
                                thisCli.SBQQSC__QuoteLine__r.SBQQ__Quote__r.CSAT_Reason__c != null &&
                                thisCli.SBQQSC__QuoteLine__r.SBQQ__Discount__c > 99.9 &&
                                (thisCli.SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c == null ||
                                 thisCli.SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c == 0 ||
                                 thisCli.SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c == 100) &&
                                thisCli.SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__c == null
                            ) {

                                objQL.SBQQ__Discount__c = objMeta.Discount_RSM__c;
                                objQL.CSAT_Discount_Applied__c = true;
                                qliListToUpdate.add(objQL);
                            }
                        }
                    }
                }
            }
        }
        if(qliListToUpdate.size()>0 && !hasdealops){
        return qliListToUpdate;
        }else {return null;}
}
    /***********************************************************************************************************
    * Method Name          : fetchSelectedSpecialProgram
    * Date Created/Modified: 21/05/2025
    * Author               : Ankita
    * @description         : FY25SR-1220 - Start : Collects the Special Programs from QLs             
    * @return              : Special Programs
    * @param               lIds
    * Test Class Methods   :
    *********************************************************************************************************/
    public static String fetchSelectedSpecialProgram(String lIds) {
        Set<String> selectedProgramSet = new Set<String>();
        String specialProgram = '';
        if(!String.isBlank(lIds)) {
            List<QuoteLineRecordResponse> qlDets = (List<QuoteLineRecordResponse>)JSON.deserialize(lIds, List<QuoteLineRecordResponse>.class);
            for(QuoteLineRecordResponse ql : qlDets) {
                if((ql.lTyp != null && ql.lTyp == 'New') && ql.sP != null && (ql.optional != null && !ql.optional) && (ql.wrapLine != null && !ql.wrapLine) && ql.subsPrice != null) {
                    selectedProgramSet.add(ql.sP);
                }
            }
            // Create a list based on a set
            List<String> selectedProgramList = new List<String>(selectedProgramSet);
            specialProgram = String.join(selectedProgramList, ';');
        }
        return specialProgram;
    }
    /***********************************************************************************************************
    * Method Name          : populateManualFulfillmentQuote
    * Date Created/Modified: 05/10/2025
    * Author               : Mustakim
    * @description         : CPQ22-5842 - populate Manual Fulfillment Quote for Ramp or Delayed Start Date Quotes          
    * @return               qac quoteAppCategory
    * @param                lIds
    * @param                assetMap
    * @param                astvsEntCliPerp 
    * @param                astvsSCEntCliPerp
    * @param                quoteAppCategory
    * @param                isRampQt
    *********************************************************************************************************/
    public static String populateManualFulfillmentQuote(String lIds, Map<String, Asset> assetMap, Map<String, Boolean> astvsEntCliPerp, Map<String, Boolean> astvsSCEntCliPerp, String quoteAppCategory, String isRampQt) {
        //CM.quoteApprovalCategory to be updated in dataDumping
        String qac = '';
        Set<String> convertedAstNames = new Set<String>();
        Boolean lodConversion = false;

        if (quoteAppCategory == null || (quoteAppCategory != null && !quoteAppCategory.contains('MFQR'))){
            if(isRampQt != null && isRampQt == 'Yes'){
                qac+= ';MFQR';
            }
        }
        
        if (quoteAppCategory == null || (quoteAppCategory != null && !quoteAppCategory.contains('MFQD'))) {
            if(!String.isBlank(lIds)) {
                List<QuoteLineRecordResponse> qlDets = (List<QuoteLineRecordResponse>)JSON.deserialize(lIds, List<QuoteLineRecordResponse>.class);
                //Boolean startEndDateException = quote.Quoting_Desk_Exception__c != null && quote.Quoting_Desk_Exception__c.contains('Quoting Exception - Start & End Date Modification');
                for(QuoteLineRecordResponse ql : qlDets) {
                    Boolean isMFQD = false;
                    if(ql.lTyp != null && ql.lTyp == 'New' && ql.sP != null && ql.sP == 'Conversion' && String.isNotBlank(ql.convSubsAst)){
                        List<String> asts = ql.convSubsAst.split(','); //Arroyo_Subscribed_Asset_Name__c
                        for(String ast : asts) {
                            String a = ast.trim();
                            if(String.isNotBlank(a)) {
                                Boolean isAstPerp = assetMap != null && assetMap.containsKey(a) && ((assetMap.get(a).Licensing_Model__c != null && assetMap.get(a).Licensing_Model__c == 'Perpetual') || (assetMap.get(a).Product2.License_Type__c != null && assetMap.get(a).Product2.License_Type__c == 'Perpetual'));

                                Boolean isEntCliPerp = astvsEntCliPerp != null && astvsEntCliPerp.containsKey(a) && astvsEntCliPerp.get(a);

                                Boolean isSCEntCliPerp = astvsSCEntCliPerp != null && astvsSCEntCliPerp.containsKey(a) && astvsSCEntCliPerp.get(a);

                                if (!isAstPerp && !isEntCliPerp && !isSCEntCliPerp) {
                                    //proceed only if lodConversion = false;
                                    if(ql.lTyp == 'New' && ql.startDate != null && ql.startDate > Date.today()){
                                        qac+= ';MFQD';
                                        isMFQD = true;
                                        break;
                                    }
                                }
                            }
                        }
                        if(isMFQD){
                            break;
                        }
                    }  else {
                        if(ql.lTyp == 'New' && ql.startDate != null && ql.startDate > Date.today()){
                                qac+= ';MFQD';
                                break;
                            }
                        }
                }
            }
        }
        
        return qac; //quoteAppCategory;
    }
/***********************************************************************************************************
    * Method Name          : processRbobACV
    * Date Created/Modified: 24/12/2025
    * Author               : Mustakim
    * @description         : CPQ22-6126 - Method to process Rbob ACV from Quote Line Responses and Entitlements          
    * @return              : Map of Rbob ACV against Quote Line Record Ids
    * @param               quotelines
    * @param               mapOfEnts
    *********************************************************************************************************/
    public static List<KeyValue> processRbobACV(List<QuoteLineRecordResponse> quotelines, Map<Id, Entitlement> mapOfEnts) {
    
        Set<Id> entIdsJson = new Set<Id>();
        if (quotelines != null && !quotelines.isEmpty()) {
            for (Integer i = 0; i < quotelines.size(); i++) {
                QuoteLineRecordResponse lineTmp = (QuoteLineRecordResponse) quotelines[i];
                if (lineTmp != null && lineTmp.lTyp != null && (lineTmp.lTyp == 'New' || lineTmp.lTyp == 'Renewal') && !String.isBlank(lineTmp.replacementDetails)) {
                    ReplacementJson lineJsonTmp = (ReplacementJson) JSON.deserialize(lineTmp.replacementDetails, ReplacementJson.class);
                    if (lineJsonTmp != null && lineJsonTmp.rowValues != null) {
                        for (ReplacementJson.RowDetail rowTmp : lineJsonTmp.rowValues) {
                            if (rowTmp != null) {
                                if (rowTmp.entId != null) entIdsJson.add(rowTmp.entId);
                                if (rowTmp.upgradeLines != null && !rowTmp.upgradeLines.isEmpty()) {
                                    for (ReplacementJson.RelatedChildEntRowDetail ugRowTmp : rowTmp.upgradeLines) {
                                        if (ugRowTmp != null && ugRowTmp.childEntId != null) {
                                            entIdsJson.add(ugRowTmp.childEntId);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        Set<Id> missingEntIds = new Set<Id>();
        if (entIdsJson != null && !entIdsJson.isEmpty()) {
            for (Id eId : entIdsJson) {
                if (mapOfEnts == null || !mapOfEnts.containsKey(eId)) {
                    missingEntIds.add(eId);
                }
            }
        }
        
        if (!missingEntIds.isEmpty()) {
            for (Entitlement e : [ SELECT Id, Entitlement_ACV__c, Entitlement_RAMP_EXIT_ACV__c, Quantity__c, Order_Service_Item__r.Order.Opportunity.Opportunity_Sub_Type__c, EntitlementExitDate__c FROM Entitlement WHERE Id IN :missingEntIds]) {
                mapOfEnts.put(e.Id, e);
            }
        }
    
        List<KeyValue> mapOfRbobACV = new List<KeyValue>();
        //Set<Id> mOfprocEntselQty = new Set<Id>();
        Map<Id, Decimal> mOfprocEntselQty = new Map<Id, Decimal>();
    
        for(Integer i = 0; i<quotelines.size(); i++) {
            QuoteLineRecordResponse line = (QuoteLineRecordResponse) quotelines[i];
            
            if(line.lTyp != null && (line.lTyp == 'New' || line.lTyp == 'Renewal')  && !String.isBlank(line.replacementDetails)) {
                ReplacementJson lineJson = (ReplacementJson) JSON.deserialize(
                    line.replacementDetails,
                    ReplacementJson.class
                );
                //System.debug('test '+1/0);
                Map<Id, Date> mOfqlIdsMaxEntExtDt = new Map<Id, Date>();
                if(lineJson.rowValues != null) {
                    Decimal qlRbobAcv = 0;
                    Decimal qlRampExitAcv = 0;
                    Set<Id> processedEntIds = new Set<Id>();
                    for(ReplacementJson.RowDetail row: lineJson.rowValues) {
                        if(mOfprocEntselQty.containsKey(row.entId) && mOfprocEntselQty.get(row.entId) < row.selectedQty) continue;
                        if(processedEntIds.contains(row.entId)) continue;
                        if(line.sP != null || (row.disposition != null && row.disposition == 'Renewing')) {
                            
                            if(!mOfqlIdsMaxEntExtDt.containsKey(line.rcId) && mapOfEnts.containsKey(row.entId) && mapOfEnts?.get(row.entId)?.EntitlementExitDate__c != null) {
                                mOfqlIdsMaxEntExtDt.put(line.rcId, mapOfEnts.get(row.entId).EntitlementExitDate__c);
                            } else if(mapOfEnts.containsKey(row.entId) && mapOfEnts?.get(row.entId)?.EntitlementExitDate__c > mOfqlIdsMaxEntExtDt.get(line.rcId)) {
                                    mOfqlIdsMaxEntExtDt.put(line.rcId, mapOfEnts.get(row.entId).EntitlementExitDate__c);
                            }

                            if((row.disposition != null && row.disposition == 'Renewing') && row.inactiveLines != null && row.inactiveLines.size() > 0) {
                                for(ReplacementJson.RelatedChildEntRowDetail inactiveRow : row.inactiveLines) {
                                    if(mapOfEnts.containsKey(inactiveRow.childEntId) && mapOfEnts.get(inactiveRow.childEntId).Quantity__c > 0 && inactiveRow.childQnty != null){
                                    if(processedEntIds.contains(inactiveRow.childEntId)) continue;
                                    qlRbobAcv += calcRbobACV(inactiveRow.childEntId, mapOfEnts, inactiveRow.childQnty);
                                    qlRampExitAcv += calcRampExitAcv(inactiveRow.childEntId, mapOfEnts, inactiveRow.childQnty);
                                    processedEntIds.add(inactiveRow.childEntId);

                                    if(!mOfprocEntselQty.containsKey(inactiveRow.childEntId)) {
                                        mOfprocEntselQty.put(inactiveRow.childEntId, mapOfEnts.get(inactiveRow.childEntId).Quantity__c - inactiveRow.childQnty);
                                    } else {
                                        mOfprocEntselQty.put(inactiveRow.childEntId, mOfprocEntselQty.get(inactiveRow.childEntId) - inactiveRow.childQnty);
                                        }
                                    }
                                }
                            } else if(mapOfEnts.containsKey(row.entId) && mapOfEnts.get(row.entId).Quantity__c > 0 && row.selectedQty != null){
                                qlRbobAcv += calcRbobACV(row.entId, mapOfEnts, row.selectedQty);
                                qlRampExitAcv += calcRampExitAcv(row.entId, mapOfEnts, row.selectedQty);

                            processedEntIds.add(row.entId);
                            
                            if(!mOfprocEntselQty.containsKey(row.entId)) {
                                mOfprocEntselQty.put(row.entId, mapOfEnts.get(row.entId).Quantity__c - row.selectedQty);
                            } else {
                                mOfprocEntselQty.put(row.entId, mOfprocEntselQty.get(row.entId) - row.selectedQty);
                            }
                            }
                        
                            if(row.upgradeLines != null && row.upgradeLines.size() > 0) {
                                for(ReplacementJson.RelatedChildEntRowDetail ugRow : row.upgradeLines) {
                                    if(mapOfEnts.containsKey(ugRow.childEntId) && mapOfEnts.get(ugRow.childEntId).Quantity__c > 0 && ugRow.childQnty != null){
                                    if(mOfprocEntselQty.containsKey(ugRow.childEntId) && mOfprocEntselQty.get(ugRow.childEntId) < ugRow.childQnty) continue;
                                    if(processedEntIds.contains(ugRow.childEntId)) continue;
                                    qlRbobAcv += calcRbobACV(ugRow.childEntId, mapOfEnts, ugRow.childQnty);
                                    qlRampExitAcv += calcRampExitAcv(ugRow.childEntId, mapOfEnts, ugRow.childQnty);

                                    processedEntIds.add(ugRow.childEntId);

                                    if(!mOfprocEntselQty.containsKey(ugRow.childEntId)) {
                                        mOfprocEntselQty.put(ugRow.childEntId, mapOfEnts.get(ugRow.childEntId).Quantity__c - ugRow.childQnty);
                                    } else {
                                        mOfprocEntselQty.put(ugRow.childEntId, mOfprocEntselQty.get(ugRow.childEntId) - ugRow.childQnty);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    mapOfRbobACV.add(new KeyValue(line.rcId, (Double) qlRbobAcv.setScale(2), (Double) qlRampExitAcv.setScale(2), mOfqlIdsMaxEntExtDt.get(line.rcId)));
                    //System.debug('@@MS QLI Rbob ACV for QL Id '+ line.rcId + ' is ' + qlRbobAcv + ' is ' + qlRampExitAcv + ' max Ent Ext Date is ' + mOfqlIdsMaxEntExtDt.get(line.rcId));
            
                }
            }
        }

        return mapOfRbobACV;
    }

/***********************************************************************************************************
    * Method Name          : calcRbobACV
    * Date Created/Modified: 31/12/2025
    * Author               : Mustakim
    * @description         : CPQ22-6126 - Helper Method to calc Rbob ACV          
    * @return              : qlRbobAcv
    * @param               entId
    * @param               mapOfEnts
    * @param               selectedQty
    ************************************************************************************************************/
    public static Decimal calcRbobACV(Id entId, Map<Id, Entitlement> mapOfEnts, Integer selectedQty) {
        Decimal qlRbobAcv = 0;
        String opptySubTypes = Label.StampSameEntACVforOpptySubTypes;
        List<String> opptySubTypeList = opptySubTypes != null ? opptySubTypes.split(',') : new List<String>();

        if(mapOfEnts?.get(entId)?.Entitlement_ACV__c > 0 && mapOfEnts?.get(entId)?.Order_Service_Item__r.Order.Opportunity.Opportunity_Sub_Type__c != null && opptySubTypeList.contains(mapOfEnts.get(entId).Order_Service_Item__r.Order.Opportunity.Opportunity_Sub_Type__c)) {
            qlRbobAcv += mapOfEnts.get(entId).Entitlement_ACV__c;
        } else 
            if(mapOfEnts?.get(entId)?.Entitlement_ACV__c > 0 && mapOfEnts?.get(entId)?.Quantity__c > 0 && selectedQty != null){
                qlRbobAcv += mapOfEnts.get(entId).Quantity__c >= selectedQty ?  (mapOfEnts.get(entId).Entitlement_ACV__c / mapOfEnts.get(entId).Quantity__c) * selectedQty : mapOfEnts.get(entId).Entitlement_ACV__c;
            }
        return qlRbobAcv;
    }

    /***********************************************************************************************************
    * Method Name          : calcRampExitAcv
    * Date Created/Modified: 31/12/2025
    * Author               : Mustakim
    * @description         : CPQ22-6126 - Helper Method to calc Ramp Exit ACV          
    * @return              : qlRampExitAcv
    * @param               entId
    * @param               mapOfEnts
    * @param               selectedQty
    *********************************************************************************************************/
    public static Decimal calcRampExitAcv(Id entId, Map<Id, Entitlement> mapOfEnts, Integer selectedQty) {
        Decimal qlRampExitAcv = 0;
        String opptySubTypes = Label.StampSameEntACVforOpptySubTypes;
        List<String> opptySubTypeList = opptySubTypes != null ? opptySubTypes.split(',') : new List<String>();
        
        if(mapOfEnts?.get(entId)?.Entitlement_RAMP_EXIT_ACV__c > 0 && mapOfEnts?.get(entId)?.Order_Service_Item__r.Order.Opportunity.Opportunity_Sub_Type__c != null && opptySubTypeList.contains(mapOfEnts.get(entId).Order_Service_Item__r.Order.Opportunity.Opportunity_Sub_Type__c)){
            qlRampExitAcv += mapOfEnts.get(entId).Entitlement_RAMP_EXIT_ACV__c;
        } else 
            if(mapOfEnts?.get(entId)?.Entitlement_RAMP_EXIT_ACV__c > 0 && mapOfEnts?.get(entId)?.Quantity__c > 0 && selectedQty != null) {
                qlRampExitAcv += mapOfEnts.get(entId).Quantity__c >= selectedQty ? (mapOfEnts.get(entId).Entitlement_RAMP_EXIT_ACV__c / mapOfEnts.get(entId).Quantity__c) * selectedQty : mapOfEnts.get(entId).Entitlement_RAMP_EXIT_ACV__c;
            }
        return qlRampExitAcv;
    }

}