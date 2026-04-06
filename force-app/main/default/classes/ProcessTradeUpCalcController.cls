public class ProcessTradeUpCalcController {
    @AuraEnabled
    public static List < RecordsData > fetchRecords(Id quoteId, Id qlId, String searchString, String values) {
        Map < String, String > options = new Map < String, String > ();
        List < Entitlement > entitlementRecords = new List < Entitlement > ();
        SBQQ__Quote__c quoteRecord = new SBQQ__Quote__c();
        SBQQ__QuoteLine__c quoteLineRecord = new SBQQ__QuoteLine__c();
        Map < Id, Entitlement > mapOfEntitlement = new Map < Id, Entitlement > ();
        Set < String > TradeUpSNset = New Set < String > (); //CPQ22-1695 Pankaj change
        Set < String > ClosedWonAssets = New Set < String > ();//CPQ22-4806 Change
        Id OppID;//CPQ22-4806 Change
        if (quoteId != null) {
            quoteRecord = [Select Id, Name, SBQQ__Account__c, SBQQ__Account__r.ParentId,SBQQ__Opportunity2__c from SBQQ__Quote__c where Id =: quoteId];//CPQ22-4806 Khushboo 
            OppID= quoteRecord.SBQQ__Opportunity2__c;//CPQ22-4806 Change
            quoteLineRecord = [select id, SBQQ__Product__c, Product_Type__c, SBQQ__Product__r.Name, SBQQ__Product__r.Eligible_HW_for_Expansion__c, SBQQ__Product__r.Appliance_Model_HW__c, SBQQ__Product__r.Tradeup_Pattern__c from SBQQ__QuoteLine__c where Id =: qlId];
        }
        //Display all ENtitlements if Parent Account = null
        //If not null, get all ENtitlements from Account where Parent Account = Account in scope

        try {
            List < RecordsData > recordsDataList = new List < RecordsData > ();
            System.debug('values-->' + values);
            List < String > selectedvalues = (List < String > ) JSON.deserialize(values, List < String > .class);
            List < Entitlement > listWithoutParent = [Select Id, Name from Entitlement where(AccountId =: quoteRecord.SBQQ__Account__c) AND Account.ParentId = NULL];
            //List<Account> childrenAccount = [Select Id, Name from Account where ParentId =: quoteRecord.SBQQ__Account__c];
            Map < Id, Account > childrenAccount = new Map < Id, Account > ([Select Id, Name from Account where ParentId =: quoteRecord.SBQQ__Account__c]);
            // CPQ22-1695 Pankaj Start
            Map < Id, Account > ParentAccount = new Map < Id, Account > ([Select Id, Name from Account where Id =: quoteRecord.SBQQ__Account__r.ParentId]);
            //fetching all the primary approved quote's quotelines having tradeUp S/N
            //CPQ22-4806 start
            for (SBQQ__QuoteLine__c QLwithTradeUpSN: [select id, Replacement_Motion__c,name, SBQQ__Quote__r.name, SBQQ__Product__r.Name, Subscribed_Asset_Name__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.name, Trade_Up_Serial_Number__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName,SBQQ__Quote__r.SBQQ__Opportunity2__c,SBQQ__Quote__r.SBQQ__Primary__c,SBQQ__Quote__r.SBQQ__Status__c from SBQQ__QuoteLine__c
                    where(SBQQ__Quote__r.SBQQ__Account__r.Id =: quoteRecord.SBQQ__Account__c or SBQQ__Quote__r.SBQQ__Account__r.ParentId IN: childrenAccount.keySet() or SBQQ__Quote__r.SBQQ__Account__r.Id IN: ParentAccount.KeySet())
                 ]) {
                if (QLwithTradeUpSN.Trade_Up_Serial_Number__c != null) {
                    String valuesString = QLwithTradeUpSN.Trade_Up_Serial_Number__c;
                    List < String > valuesList = valuesString.split(', ');
                    if(QLwithTradeUpSN.SBQQ__Quote__r.SBQQ__Primary__c == true
                       && QLwithTradeUpSN.SBQQ__Quote__r.SBQQ__Status__c == 'Approved' 
                       && QLwithTradeUpSN.SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName == '7 Closed Won')
                    {
                      ClosedWonAssets.addAll(valuesList);  
                    }
                    if(QLwithTradeUpSN.SBQQ__Quote__r.SBQQ__Opportunity2__c!=OppId && QLwithTradeUpSN.SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName != '7 Closed Lost' && QLwithTradeUpSN.SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName != '7 Closed Admin' && QLwithTradeUpSN.SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName != '7 Closed Won')
                    {
                      TradeUpSNset.addAll(valuesList); 
                    }
                }
            } //CPQ22-4806 end
            // system.debug('TradeUpSNset########    '+TradeUpSNset);
            // CPQ22-1695 Pankaj end
            List < Id > childList = new List < Id > ();
            String query = '';
            String likeGO = '-GO';
            String notNode = 'NODE';
            if (!childrenAccount.isEmpty()) {

                childList.addAll(childrenAccount.keySet());
                //Get all Entitlements with Account = Children Account + Current Account
                query = 'Select Id, Name, AssetId, Product__c,Asset.Rubrik_Suite__c, Product__r.Name,Asset.Product2.Appliance_Model_HW__c, AnnualContractValue__c, asset.serial_number__c, Asset.ProductCode,asset.Free_HW_Refresh_Forfeited__c,Asset.Premium_Support_End_Date__c from Entitlement where (AccountId = ' + '\'' + quoteRecord.SBQQ__Account__c + '\'' + ' OR AccountId IN: childList ) AND (asset.Eligible_for_Free_HW__c=\'True\' OR asset.Eligible_for_Free_HW__c=\'True - Manual\') AND asset.Free_HW_Refresh_Forfeited__c = false AND Name LIKE ' + '\'%' + likeGO + '%\'' + ' AND (NOT Name LIKE ' + '\'%' + notNode + '%\'' + ')';
                //query = 'Select Id, Name, AssetId, Product__c, Product__r.Name, AnnualContractValue__c, asset.serial_number__c, Asset.ProductCode from Entitlement where (AccountId =: ' + '\'' + quoteRecord.SBQQ__Account__c + '\''+' OR AccountId IN: ' + childrenAccount +') AND (NOT Name LIKE ' + '\'%' + notNode + '%\'' + ')';
            } else {
                query = 'Select Id, Name, AssetId, Product__c,Asset.Rubrik_Suite__c, Product__r.Name,Asset.Product2.Appliance_Model_HW__c, AnnualContractValue__c, asset.serial_number__c, Asset.ProductCode,Asset.Premium_Support_End_Date__c from Entitlement where AccountId =' + '\'' + quoteRecord.SBQQ__Account__c + '\'' + ' AND (asset.Eligible_for_Free_HW__c=\'True\' OR asset.Eligible_for_Free_HW__c=\'True - Manual\') AND asset.Free_HW_Refresh_Forfeited__c = false AND Name LIKE ' + '\'%' + likeGO + '%\'' + ' AND (NOT Name LIKE ' + '\'%' + notNode + '%\'' + ')';
                //query = 'Select Id, Name, AssetId, Product__c, Product__r.Name, AnnualContractValue__c, asset.serial_number__c, Asset.ProductCode from Entitlement where AccountId = ' + '\'' + quoteRecord.SBQQ__Account__c + '\''+' AND (NOT Name LIKE ' + '\'%' + notNode + '%\'' + ')';
            }
            /*if(selectedvalues != null) {
                query += ' AND Id IN: selectedvalues LIMIT 49999';
            }*/
            if (string.isBlank(searchString)) {
                searchString = ' ';
            }
            query += ' AND Asset.Name LIKE ' + '\'%' + String.escapeSingleQuotes(searchString.trim()) + '%\'  ORDER By Asset.Premium_Support_End_Date__c LIMIT 49999';
            System.debug('Query-->' + query);
            for (Entitlement entObj: Database.query(query)) {
                if (quoteLineRecord != null && ((quoteLineRecord.SBQQ__Product__r.Eligible_HW_for_Expansion__c != null && quoteLineRecord.SBQQ__Product__r.Eligible_HW_for_Expansion__c.containsIgnoreCase(entObj.Asset.Product2.Appliance_Model_HW__c)) || quoteLineRecord.Product_Type__c == 'Edition Upgrade' || quoteLineRecord.SBQQ__Product__r.Tradeup_Pattern__c != null ) && entObj.Asset.Premium_Support_End_Date__c!= null) {//CPQ22-4806 Khushboo
                    //CPQ22-1695 Pankaj start
                    if (entObj.asset != null && !String.isBlank(entObj.asset.serial_number__c) && !TradeUpSNset.contains((String) entObj.asset.serial_number__c) && !ClosedWonAssets.contains((String) entObj.asset.serial_number__c))
                    //CPQ22-1695 Pankaj end
                    {
                        String convertedEditions = '';
                        if (entObj.asset.Rubrik_Suite__c == 'Business') {
                            convertedEditions = 'BE';
                        } else if (entObj.asset.Rubrik_Suite__c == 'Enterprise') {
                            convertedEditions = 'EE';
                        } else {
                            convertedEditions = 'FE';
                        }
                        recordsDataList.add(new RecordsData((String) entObj.asset.serial_number__c + '    (' + entObj.asset.ProductCode + ')' + '    (' + convertedEditions + ')'+' '+String.valueOf(entObj.asset.Premium_Support_End_Date__c.format() ), (String) entObj.get('id')));
                    }
                }
            }
            return recordsDataList;
        } catch (Exception err) {
            System.debug('err.getMessage()-->' + err.getMessage());

            if (String.isNotBlank(err.getMessage()) && err.getMessage().contains('error:')) {
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else {
                throw new AuraHandledException(err.getMessage());
            }
        }
    }

    @AuraEnabled
    public static List < SBQQ__QuoteLine__c > fetchQuoteLineRecords(Id quoteId) {
        //Fetch all Quote Lines
        
        List < SBQQ__QuoteLine__c > quoteLines = [SELECT Id, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__ListPrice__c,
            Trade_Up_Serial_Number__c, Replacement_Motion__c , Product_Level__c, Category__c, SBQQ__RequiredBy__c, SBQQ__Number__c, Suggested_Discount_to_Maximize_ACV_HW__c, SBQQ__Product__r.Tradeup_Pattern__c,SBQQ__Quote__r.RWD_Sales_Rep_Exception__c
            FROM SBQQ__QuoteLine__c WHERE
            SBQQ__Quote__c =: quoteId AND(Category__c IN('Bundle', 'Hardware') OR (SBQQ__Product__r.Tradeup_Pattern__c != '' OR SBQQ__Product__r.Tradeup_Pattern__c !=null)) AND Line_Type__c = 'New'
        ];
        
        
        return quoteLines;
    }

    @AuraEnabled
    public static List < SBQQ__QuoteLine__c > getNumberOfBundles(Id quoteId) {
        //Fetch number of Bundles in Quote
        List<SBQQ__QuoteLine__c> quoteLines = new list<SBQQ__QuoteLine__c>();
        List < SBQQ__QuoteLine__c > quoteLines1 = [SELECT Id,Replacement_Motion__c, Name, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__ListPrice__c,
            Trade_Up_Serial_Number__c, Product_Level__c, Category__c, SBQQ__RequiredBy__c, SBQQ__SubscriptionTerm__c,
            Required_By_Product_Code__c, Trade_Up_Discount__c, Expected_Trade_Up_Discount__c, Existing_Editions__c, Previous_Total_Discount_HW__c, Max_Credit_Amount__c, Existing_TB__c, SBQQ__Product__r.Tradeup_Pattern__c,
            Existing_RSC_Discount__c, Product_Type__c, Existing_RSC_Discount_HW__c, Suggested_Discount_to_Maximize_ACV_HW__c,SBQQ__Quote__r.RWD_Sales_Rep_Exception__c
            FROM SBQQ__QuoteLine__c WHERE
            SBQQ__Quote__c =: quoteId AND Line_Type__c = 'New'
            AND(Category__c = 'Bundle'
                OR SBQQ__Product__r.Tradeup_Pattern__c != null ) AND SBQQ__Product__r.Eligible_For_Trade_Up__c = true AND SBQQ__RequiredBy__c = null
            
            /*Product_Level__c IN ('Hybrid Software','LOD Software','OnPrem') AND 
            Product_Type__c IN ('Enterprise Edition', 'Business Edition','Edition Upgrade','Foundation Edition')*/
        ];
        
        /*for(SBQQ__QuoteLine__c ql : quoteLines1){
System.debug('SBQQ__ProductCode__c'+ql.SBQQ__ProductCode__c);
System.debug('RWD_Sales_Rep_Exception__c'+ql.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c);
if(ql.SBQQ__Product__r.Tradeup_Pattern__c== null || ql.SBQQ__Product__r.Tradeup_Pattern__c== '' || !ql.SBQQ__Product__r.Tradeup_Pattern__c.contains('Sales Rep Exception') ){
quoteLines.add(ql);
}else if(ql.SBQQ__Product__r.Tradeup_Pattern__c!= null && ql.SBQQ__Product__r.Tradeup_Pattern__c!= '' && ql.SBQQ__Product__r.Tradeup_Pattern__c.contains('Sales Rep Exception') && ql.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c!= null && ql.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c.contains('Trade Up - FE - Exceptions')){
System.debug('inside elseif');
quoteLines.add(ql);
}
}
//quoteLines.remove(quoteLinestoremove);
System.debug('show bundles>>'+quoteLines);*/
        
        return quoteLines1;
    }

    @AuraEnabled
    public static List < String > validateAssets(Id quoteId, Map < Id, List < Id >> mapOfReqByVsEnt, Map < Id, Integer > mapOfReqByVsCount) {
        //Validations for Assets entered
        System.debug('mapOfReqByVsEnt-->' + mapOfReqByVsEnt);
        System.debug('mapOfReqByVsCount-->' + mapOfReqByVsCount);
        List < String > validationErrorMsgs = new List < String > ();
        List < Entitlement > entitlementRecords = new List < Entitlement > ();
        Map < Id, Entitlement > mapOfEntitlement = new Map < Id, Entitlement > ();
        Map < Id, String > mapOfAssetVsHWModel = new Map < Id, String > ();
        List < Id > selectedAssetList = new List < Id > ();
        List < String > notEligibleAssets = new List < String > ();
        Map < String, String > mapOfProdvsEligibleHW = new Map < string, String > ();
        Map < Id, Id > mapOfEntIdvsAssetIds = new Map < Id, Id > ();
        Map < Id, Id > mapOfAssetIdVsHWId = new Map < Id, Id > ();
        List < Id > values = new List < Id > ();
        Map < Id, String > mapOfAssetIdvsName = new Map < Id, String > ();
        Map < Id, Decimal > mapOfReqByvsCountofHW = new Map < Id, Decimal > ();
        Map < Id, Integer > mapOfReqByvsInp = new Map < Id, Integer > ();
        Map < Id, Integer > mapOfReqByvsTradedAssets = new Map < Id, Integer > ();
        Map < Id, Decimal > mapOfReqByvsHWQty = new Map < Id, Decimal > ();
        Map < Id, Integer > mapOfReqByvsAssetsonHW = new Map < Id, Integer > ();

        for (List < Id > subList: mapOfReqByVsEnt.values()) values.addAll(subList);
        System.debug('Valuesvalidate>>' + values);
        entitlementRecords = [Select Id, Name, AssetId, Product__c, Product__r.Name, AnnualContractValue__c from Entitlement where Id IN: values];
        if (!entitlementRecords.isEmpty()) {
            for (Entitlement entitlementObj: entitlementRecords) {
                selectedAssetList.add(entitlementObj.AssetId);
                mapOfEntIdvsAssetIds.put(entitlementObj.Id, entitlementObj.AssetId);
            }
        }

        Map < Id, Asset > assetForTradeUp = new Map < Id, Asset > ([Select Id, Name, Rubrik_Suite__c, Product2Id, Product2.Appliance_Model_HW__c, SBQQ__Discount__c, Product2.Usable_Capacity__c, Quantity
            from Asset where Id IN: selectedAssetList
        ]);
        if (!entitlementRecords.isEmpty()) {
            for (Entitlement entObj: entitlementRecords) {
                mapOfEntitlement.put(entObj.AssetId, entObj);
            }
        }
        if (!entitlementRecords.isEmpty()) {
            for (Asset assetObj: assetForTradeUp.values()) {
                if (mapOfEntitlement.containskey(assetObj.Id)) {
                    for (Entitlement entObj: mapOfEntitlement.values()) {
                        if (mapOfEntitlement.containsKey(assetObj.Id)) {
                            String assetHWModel = assetObj.Product2.Appliance_Model_HW__c;
                            mapOfAssetVsHWModel.put(assetObj.Id, assetHWModel);
                            mapOfAssetIdvsName.put(assetObj.Id, assetObj.Name);
                        }
                    }
                }
            }
        }
        List < SBQQ__QuoteLine__c > qlListLicenses = [Select Id,SBQQ__Quote__r.RWD_Sales_Rep_Exception__c, Name, SBQQ__RequiredBy__c, SBQQ__Product__r.Appliance_Model_HW__c, SBQQ__RequiredBy__r.Product_Level__c,
            SBQQ__ProductName__c, SBQQ__Quantity__c, Appliance_Model_HW__c, SBQQ__Product__r.Eligible_HW_for_Expansion__c,
            SBQQ__ProductCode__c, Existing_RSC_Discount_HW__c, Trade_Up_Serial_Number__c, Trade_Up_Discount__c, Expected_Trade_Up_Discount__c, Suggested_Discount_to_Maximize_ACV_HW__c, Trade_Up_Serial_Number_on_HW__c, Product_Type__c, SBQQ__Product__r.Tradeup_Pattern__c from SBQQ__QuoteLine__c where
            SBQQ__Quote__c =: quoteId AND Line_Type__c = 'New'
            AND SBQQ__Product__r.Eligible_For_Trade_Up__c = true AND(Category__c = 'Bundle'
                OR (SBQQ__Product__r.Tradeup_Pattern__c != '' AND SBQQ__Product__r.Tradeup_Pattern__c!= null))
        ];
        /*Product_Level__c IN ('Hybrid Software','LOD Software','OnPrem') AND 
        Product_Type__c IN ('Enterprise Edition', 'Business Edition','Edition Upgrade', 'Foundation Edition')*/
        List < SBQQ__QuoteLine__c > qlList = [Select Id,SBQQ__Quote__r.RWD_Sales_Rep_Exception__c, Name, SBQQ__RequiredBy__c, SBQQ__Product__r.Appliance_Model_HW__c, SBQQ__RequiredBy__r.Product_Level__c,
            SBQQ__ProductName__c, SBQQ__Quantity__c, Appliance_Model_HW__c, SBQQ__Product__r.Eligible_HW_for_Expansion__c, SBQQ__ProductCode__c,
            Existing_RSC_Discount_HW__c, Trade_Up_Serial_Number_on_HW__c, Trade_Up_Discount__c, Expected_Trade_Up_Discount__c, Suggested_Discount_to_Maximize_ACV_HW__c, SBQQ__Product__r.Tradeup_Pattern__c
            from SBQQ__QuoteLine__c where
            SBQQ__Quote__c =: quoteId AND Line_Type__c = 'New'
            AND((Product_Level__c = 'Hardware'
                AND Product_Type__c = 'Hardware') OR (SBQQ__Product__r.Tradeup_Pattern__c!= null AND SBQQ__Product__r.Tradeup_Pattern__c!= ''))
        ];

        for (SBQQ__QuoteLine__c qlObj: qlListLicenses) {
            for (String assetId: mapOfAssetIdvsName.values()) {
                if (qlObj.Trade_Up_Serial_Number__c != null && qlObj.Trade_Up_Serial_Number__c.contains(assetId)) {
                    validationErrorMsgs.add('The Asset entered is already been traded for ' + qlObj.SBQQ__ProductCode__c + '. Please select a different one.'); // validation 3
                    break;
                } else {
                    if (String.isNotBlank(qlObj.Trade_Up_Serial_Number__c)) {
                        List < String > listOfAssets = qlObj.Trade_Up_Serial_Number__c.split(',');
                        Integer countOfAssets = listOfAssets.size();
                        mapOfReqByvsTradedAssets.put(qlObj.Id, countOfAssets);
                    }
                }
            }
        }
        for (SBQQ__QuoteLine__c qlObj: qlListLicenses) {
            Decimal qtyOfHW = 0.00;
            Integer assetEntered = 0;
            for (SBQQ__QuoteLine__c qlObj2: qlList) {
                if (qlObj2.SBQQ__RequiredBy__c == qlObj.Id) {
                    qtyOfHW += qlObj2.SBQQ__Quantity__c;
                }else if(qlObj2.SBQQ__RequiredBy__c == null){
                    qtyOfHW = qlObj.SBQQ__Quantity__c;
                }
                if (mapOfReqByVsCount.containsKey(qlObj2.Id) && qlObj2.SBQQ__RequiredBy__c == qlObj.Id) {
                    assetEntered += mapOfReqByVsCount.get(qlObj2.Id);
                }
                if (String.isNotBlank(qlObj2.Trade_Up_Serial_Number_on_HW__c)) {
                    List < String > listOfAssets = qlObj2.Trade_Up_Serial_Number_on_HW__c.split(',');
                    Integer countOfAssets = listOfAssets.size();
                    mapOfReqByvsAssetsonHW.put(qlObj2.Id, countOfAssets);
                }
                mapOfReqByvsHWQty.put(qlObj2.Id, qlObj2.SBQQ__Quantity__c);
            }
            mapOfReqByvsCountofHW.put(qlObj.Id, qtyOfHW);
            mapOfReqByvsInp.put(qlObj.Id, assetEntered);
        }

        for (SBQQ__QuoteLine__c qlObj: qlListLicenses) {
            for (SBQQ__QuoteLine__c qlObj2: qlList) {
                if (!mapOfReqByvsCountofHW.isEmpty()) {
                    Integer countToVerify = 0;
                    if (mapOfReqByvsInp.containsKey(qlObj.Id) != null && mapOfReqByvsInp.containsKey(qlObj.Id) && mapOfReqByvsTradedAssets.containsKey(qlObj.Id)) {
                        countToVerify = (mapOfReqByvsInp.get(qlObj.Id) + mapOfReqByvsTradedAssets.get(qlObj.Id));
                        System.debug('Test>'+countToVerify);
                        System.debug('mapOfReqByvsCountofHW>'+mapOfReqByvsCountofHW);
                        System.debug('Test qlObjLice>'+qlObj.SBQQ__ProductName__c);
                        System.debug('Test qlObj2child>'+qlObj2.SBQQ__ProductName__c);
                        if (countToVerify > Integer.valueOf(mapOfReqByvsCountofHW.get(qlObj.Id))) {
                            validationErrorMsgs.add('You cannot provide Assets more than Qty of HW Model.');
                            break;
                        }
                    }
                }
                if (!mapOfReqByvsHWQty.isEmpty() && !mapOfReqByvsAssetsonHW.isEmpty()) {
                    if (mapOfReqByvsAssetsonHW.containsKey(qlObj2.Id) && mapOfReqByVsCount.containsKey(qlObj2.Id) && mapOfReqByvsHWQty.containsKey(qlObj2.Id) &&
                        (mapOfReqByvsAssetsonHW.get(qlObj2.Id) + mapOfReqByVsCount.get(qlObj2.Id)) > Integer.valueOf(mapOfReqByvsHWQty.get(qlObj2.Id))) {
                            System.debug('show validation:'+mapOfReqByvsAssetsonHW);
                            System.debug('show validationmapOfReqByVsCount:'+mapOfReqByVsCount);
                            System.debug('show mapOfReqByvsHWQty:'+mapOfReqByvsHWQty);
                        validationErrorMsgs.add('You cannot provide Assets more than Qty of HW Model.');
                        break;
                    }
                }
            }
            break;
        }
        
        for (Id qlId: mapOfReqByVsEnt.keySet()) {
            for (Id entId: mapOfReqByVsEnt.get(qlId)) {
                if (!mapOfAssetIdVsHWId.containsKey(mapOfEntIdvsAssetIds.get(entId))) {
                    mapOfAssetIdVsHWId.put(mapOfEntIdvsAssetIds.get(entId), qlId);
                } else {
                    validationErrorMsgs.add(mapOfAssetIdvsName.get(mapOfEntIdvsAssetIds.get(entId)) + ' cannot be selected since it is already selected for other HW Model'); // validation 3
                    break;
                }

            }
        }

        for (SBQQ__QuoteLine__c qlObj: qlList) {
            if (qlObj.SBQQ__Product__r.Eligible_HW_for_Expansion__c != null && qlObj.SBQQ__Product__r.Appliance_Model_HW__c != null) {
                mapOfProdvsEligibleHW.put(qlObj.SBQQ__Product__r.Appliance_Model_HW__c, qlObj.SBQQ__Product__r.Eligible_HW_for_Expansion__c);
            }
            for (String assetId: mapOfAssetIdVsHWId.keySet()) {
                if (qlObj.Id == mapOfAssetIdVsHWId.get(assetId)) {
                    //Check if HW Qty = Assets Entered
                    if (qlObj.SBQQ__Quantity__c >= mapOfReqByVsCount.get(qlObj.Id)) {
                        //Check if entered Assets is eligible or not
                        if (!mapOfProdvsEligibleHW.isEmpty()) {
                            System.debug('map1>>' + mapOfProdvsEligibleHW.get(qlObj.SBQQ__Product__r.Appliance_Model_HW__c));
                            System.debug('map2>>' + mapOfAssetVsHWModel.get(assetId));

                            if (mapOfProdvsEligibleHW.get(qlObj.SBQQ__Product__r.Appliance_Model_HW__c) != null && !mapOfProdvsEligibleHW.get(qlObj.SBQQ__Product__r.Appliance_Model_HW__c).contains(mapOfAssetVsHWModel.get(assetId))) {
                                System.debug('Eligible Asset NOT found');
                                if (!mapOfAssetIdvsName.isEmpty()) {
                                    notEligibleAssets.add(mapOfAssetIdvsName.get(assetId));
                                }
                            }
                        }
                    } else {
                        System.debug('Count NOT Match');
                        if (!mapOfAssetIdvsName.isEmpty()) {
                            validationErrorMsgs.add('Number of Assets can be less or equal to HW Model Quantity. Please make necessary changes for ' + qlObj.SBQQ__ProductCode__c + ' and then click Confirm.'); // validation 3
                        }
                        break;
                    }
                }
            }
        }
        
        if (notEligibleAssets?.size() > 0) {
            validationErrorMsgs.add('Selected Asset(s) is/are not eligible for expansion since it belongs to lower HW Model. Please select Assets which are equivalent or greater than the quoted HW Model : ' + notEligibleAssets); // validation 1 and 4
        }
        return validationErrorMsgs;
    }

    @AuraEnabled
    public static List < QuotelineData > callCalcConfirmationFromMap(Id quoteId, Map < Id, List < Id >> mapOfReqByVsEnt) {

        //Does all calculations and displays the result on the screen
        List < Entitlement > entitlementRecords = new List < Entitlement > ();
        Map < Id, Entitlement > mapOfEntitlement = new Map < Id, Entitlement > ();
        Map < Id, Entitlement > assetAssociatedWithEntitlement = new Map < Id, Entitlement > ();
        Set < String > assetIdSet = new Set < String > ();
        Map < Id, String > mapOfAssetVsEdition = new Map < Id, String > ();
        Set < Id > assetProdIds = new Set < Id > ();
        Map < Id, Decimal > mapOfProdvsPrice = new Map < Id, Decimal > ();
        List < PricebookEntry > assetProdPrice = new List < PricebookEntry > ();
        List < Id > selectedAssetList = new List < Id > ();
        Map < Id, Id > mapOfEntIdvsAssetIds = new Map < Id, Id > ();
        List < Id > values = new List < Id > ();
        Map < Id, Id > mapOfAssetIdVsqlId = new Map < Id, Id > ();
        Map < String, SBQQ__QuoteLine__c > mapOfQLToDisplay = new Map < String, SBQQ__QuoteLine__c > ();
        Map < Id, String > mapOfReqByvsAssetNames = new Map < Id, String > ();
        Map < Id, Id > mapOfQLIdvsReqById = new Map < Id, Id > ();
        Map < Id, String > mapOfFinalUpdate = new Map < Id, String > ();
        Map < Id, Decimal > mapOfReqByvsMaxCredVal = new Map < Id, Decimal > ();
        Map < Decimal, SBQQ__QuoteLine__c > productFamilyMap = new Map < Decimal, SBQQ__QuoteLine__c > ();
        Map < Decimal, SBQQ__QuoteLine__c > productFamilyMapSorted = new Map < Decimal, SBQQ__QuoteLine__c > ();
        List < Decimal > orderingList = new List < Decimal > ();
        Map < String, Decimal > mapOfReqByvsRSCDisc = new Map < String, Decimal > ();
        Map < String, Decimal > mapOfReqByvsSuggestedDisc = new Map < String, Decimal > ();
        List < String > existingSN = new list < String > ();
        Set < String > assetNames = new Set < String > ();
        List < QuotelineData > QuotelineDataList = new List < QuotelineData > ();
        Map < Id, Decimal > qliIdAndTradeupAmount = new Map < Id, Decimal > ();
        //------------------------------------------------------------------------------------------
        // changes done by Prasenjeet added SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c //SAL26-1343 Added SBQQ__ProrateMultiplier__c,SBQQ__RequiredBy__r.SBQQ__ProrateMultiplier__c fields
        List < SBQQ__QuoteLine__c > qlList = [Select Id, Name,SBQQ__ProrateMultiplier__c,SBQQ__RequiredBy__r.SBQQ__ProrateMultiplier__c, Trade_Up_Serial_Number__c, Existing_Editions__c, Previous_Total_Discount_HW__c, SBQQ__RequiredBy__c, SBQQ__OriginalPrice__c, SBQQ__Product__r.Trade_Up_HW_Value__c,
            SBQQ__Product__r.Trade_Up_Multiplier__c, SBQQ__RequiredBy__r.Product_Level__c, SBQQ__RequiredBy__r.Trade_Up_Multiplier__c,
            SBQQ__RequiredBy__r.Trade_Up_Serial_Number__c, SBQQ__Product__r.Capacity__c, SBQQ__ProductName__c, SBQQ__Quantity__c,
            SBQQ__Quote__r.SBQQ__SubscriptionTerm__c, SBQQ__Product__r.Usable_Capacity__c, SBQQ__RequiredBy__r.SBQQ__OriginalPrice__c, SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Trade_Up_HW_Value__c,
            Appliance_Model_HW__c, Max_Credit_Amount__c, Existing_TB__c, Existing_RSC_Discount__c,SBQQ__Product__r.Promo_Code__c,
            SBQQ__ProductCode__c, Trade_Up_Serial_Number_on_HW__c, Required_By_Product_Code__c, SBQQ__Number__c, SBQQ__SubscriptionTerm__c, Trade_Up_Multiplier__c,
            Product_Level__c, Product_Type__c, SBQQ__Quote__c, Category__c, Usable_Capacity__c, Existing_RSC_Discount_HW__c, Trade_Up_Discount__c, Expected_Trade_Up_Discount__c, Suggested_Discount_to_Maximize_ACV_HW__c, SBQQ__Product__r.Eligible_For_Trade_Up__c,
            Trade_Up_Discount_Applied__c, Switcher_Promo_Discount_Temp__c, Promo_Disc__c, Trade_Up_Discount_Prior__c, SBQQ__ListTotal__c, Trade_Up_Discount_Monthly__c, SBQQ__Product__r.Tradeup_Pattern__c

            from SBQQ__QuoteLine__c where SBQQ__Quote__c =: quoteId AND Line_Type__c = 'New'
            AND /*SBQQ__Product__r.Eligible_For_Trade_Up__c = TRUE*/((Product_Level__c = 'Hardware'
                AND Product_Type__c = 'Hardware') OR( /*Product_Level__c = 'OnPrem'*/ Product_Type__c = 'Edition Upgrade'
                AND SBQQ__Product__r.Eligible_For_Trade_Up__c = TRUE) OR(SBQQ__Product__r.Tradeup_Pattern__c!= ''
                AND SBQQ__Product__r.Eligible_For_Trade_Up__c = TRUE)) ORDER BY SBQQ__Number__c
        ];
        Map < String, Id > mapAssetQli = new Map < String, Id > ();
        Map < String, Id > mapAssetENT = new Map < String, Id > ();
        Map < String, Id > mapAssetname = new Map < String, Id > ();
        for (SBQQ__QuoteLine__c qle: qlList) {

            if (qle.SBQQ__RequiredBy__r != null && qle.SBQQ__RequiredBy__r.Trade_Up_Serial_Number__c != '' && qle.SBQQ__RequiredBy__r.Trade_Up_Serial_Number__c != null && (qle.SBQQ__Product__r.Tradeup_Pattern__c == null ||  qle.SBQQ__Product__r.Tradeup_Pattern__c == '')) {
                System.debug('qle.SBQQ__RequiredBy__r.Trade_Up_Serial_Number__c' + qle.SBQQ__RequiredBy__r.Trade_Up_Serial_Number__c);
                String valuesString = qle.SBQQ__RequiredBy__r.Trade_Up_Serial_Number__c;
                List < String > valuesList = valuesString.split(', ');
                assetNames.addAll(valuesList);
                for (String str: valuesList) {
                    mapAssetQli.put(str, qle.Id);
                    System.debug('shoel existing bundle>' + mapAssetQli);
                }
            }else if(qle.SBQQ__RequiredBy__r != null && qle.SBQQ__Product__r.Tradeup_Pattern__c!=null && qle.Trade_Up_Serial_Number__c !=null && qle.Trade_Up_Serial_Number__c != ''){
                String valuesString1 = qle.Trade_Up_Serial_Number__c;
                List < String > valuesList1 = valuesString1.split(', ');
                assetNames.addAll(valuesList1);
                for (String str: valuesList1) {
                    mapAssetQli.put(str, qle.id);
                    System.debug('shoel existing pattern>' + mapAssetQli);
                }
            }else if (qle.Trade_Up_Serial_Number__c != null && qle.Trade_Up_Serial_Number__c != '') {
                String valuesString1 = qle.Trade_Up_Serial_Number__c;
                List < String > valuesList1 = valuesString1.split(', ');
                assetNames.addAll(valuesList1);
                for (String str: valuesList1) {
                    mapAssetQli.put(str, qle.id);
                    System.debug('shoel existing SNstandalone>' + mapAssetQli);
                }
            }

        }
        System.debug('here is the map asst'+mapAssetQli);
        List < Entitlement > entlst = [Select Id, Asset.Name, Name, AssetId, Product__c, Product__r.Name, AnnualContractValue__c from Entitlement where Asset.Name IN: assetNames AND Name like '%GO%'
            AND(NOT Name LIKE '%notNode%')
        ];
        System.debug('show val>>' + entlst);

        //-----------------------------------------------------------------------------------------------------------------------------------
        for (List < Id > subList: mapOfReqByVsEnt.values()) values.addAll(subList);
        System.debug('Valuesvalidate>>' + values);
        if (entlst.size() > 0) {
            for (Entitlement ent: entlst) {
                values.add(ent.id);
                mapAssetENT.put(ent.Asset.Name, ent.Id);
            }
        }
        System.debug('mapAssetENTmadhura>>' + mapAssetENT);

        //for(String asset : mapAssetQli.keySet()){

        //List of Asset records entered on QLE
        entitlementRecords = [Select Id, Name, AssetId, Product__c, Product__r.Name, AnnualContractValue__c from Entitlement where Id IN: values];
        for (Entitlement entitlementObj: entitlementRecords) {
            selectedAssetList.add(entitlementObj.AssetId);
            mapOfEntIdvsAssetIds.put(entitlementObj.Id, entitlementObj.AssetId); //got values
        }
        System.debug('mapOfReqByVsEnt >> ' + mapOfReqByVsEnt);
        System.debug('entitlementRecords >> ' + entitlementRecords);

        for (Id prodId: mapOfReqByVsEnt.keySet()) {
            for (Id entId: mapOfReqByVsEnt.get(prodId)) {
                mapOfAssetIdVsqlId.put(mapOfEntIdvsAssetIds.get(entId), prodId);
            }
        }
        System.debug('mapOfAssetIdVsqlId >> ' + mapOfAssetIdVsqlId);
        System.debug('selectedAssetList >> ' + selectedAssetList);

        Map < Id, Asset > assetForTradeUp = new Map < Id, Asset > ([Select Id, Name, Rubrik_Suite__c, SBQQ__Discount__c, Product2Id, Product2.Trade_Up_HW_Value__c, Product2.Appliance_Model_HW__c, Product2.Usable_Capacity__c, Quantity
            from Asset where((Id IN: selectedAssetList) OR(Name IN: assetNames))
        ]);
        System.debug('assetForTradeUp >> ' + assetForTradeUp);
        //added by madhura

        for (Asset asset: assetForTradeUp.values()) {
            mapAssetname.put(asset.Name, asset.Id);
        }
        if (!assetForTradeUp.isEmpty()) {

            for (String asset: mapAssetQli.keySet()) {
                //for(Id qli : mapAssetQli.get(asset)){
                mapOfAssetIdVsqlId.put(mapAssetname.get(asset), mapAssetQli.get(asset));
                System.debug('mapOfAssetIdVsqlIdmadhura' + mapOfAssetIdVsqlId);
                //}

            }


        }
        for (String asset: mapAssetQli.keySet()) {
            for (Id qli: mapAssetQli.values()) {
                if (mapOfReqByVsEnt.containsKey(qli)) {
                    List < Id > entId = mapOfReqByVsEnt.get(qli);
                    entId.add(mapAssetENT.get(asset));
                    mapOfReqByVsEnt.put(mapAssetQli.get(asset), entId);
                } else {
                    mapOfReqByVsEnt.put(mapAssetQli.get(asset), new List < Id > {
                        mapAssetENT.get(asset)
                    });
                }

            }
        }

        System.debug('show map madhura' + mapOfReqByVsEnt);

        //Map of Entitlements associated with Account
        if (!entitlementRecords.isEmpty()) {
            for (Entitlement entObj: entitlementRecords) {
                mapOfEntitlement.put(entObj.AssetId, entObj);
            }
        }
        //Check if Asset entered is present in the Account. If yes, add Asset Id and Entitlement to a map
        if (!entitlementRecords.isEmpty()) {
            for (Asset assetObj: assetForTradeUp.values()) {
                if (mapOfEntitlement.containskey(assetObj.Id)) {
                    for (Entitlement entObj: mapOfEntitlement.values()) {
                        if (mapOfEntitlement.containsKey(assetObj.Id)) {
                            assetAssociatedWithEntitlement.put(assetObj.Id, entObj);
                            assetProdIds.add(assetObj.Product2Id); // to get Price from Existing Asset for Existin $/TB calculations
                            String assetEdition = assetObj.Rubrik_Suite__c;
                            mapOfAssetVsEdition.put(assetObj.Id, assetEdition);
                        }
                    }
                }
            }
            if (!assetProdIds.isEmpty()) {
                assetProdPrice = [Select Id, Name, UnitPrice, Product2Id from PriceBookEntry where Product2Id IN: assetProdIds];
                for (Asset assetObj: assetForTradeUp.values()) {
                    for (PriceBookEntry pbeObj: assetProdPrice) {
                        if (assetObj.Product2Id == pbeObj.Product2Id) {
                            mapOfProdvsPrice.put(assetObj.Id, pbeObj.UnitPrice);
                        }
                    }
                }
            }
        }

        // Store the Discount table too in this Custom Metadata, for calculations
        List < Trade_Up_Program_Utility__mdt > lstCapacityDiscount = [Select Id, Discount__c, Capacity_Lower_Bound__c, Capacity_Upper_Bound__c from Trade_Up_Program_Utility__mdt
            where Discount__c != null AND Capacity_Lower_Bound__c != null AND Capacity_Upper_Bound__c != null
        ];

        //Calculates all required values HW level

        for (SBQQ__QuoteLine__c qlRecord: qlList) {
            System.debug('qlRecord >> ' + qlRecord);
            //Stamp Existing Editions & HW Model on respective QL
            qlRecord.Existing_Editions__c = null;
            qlRecord.Previous_Total_Discount_HW__c = null;
            qlRecord.Existing_TB__c = 0.00;
            qlRecord.Max_Credit_Amount__c = 0.00;
            qlRecord.Existing_RSC_Discount__c = null;
            qlRecord.Existing_RSC_Discount_HW__c = null;
            qlRecord.Trade_Up_Serial_Number__c = '';
            //qlRecord.Expected_Trade_Up_Discount__c = 0.00;
            // qlRecord.Suggested_Discount_to_Maximize_ACV_HW__c = '';
            //qlRecord.Trade_Up_Discount__c = 0.00;
            qlRecord.Promo_Disc__c = null;
            qlRecord.Total_Discount__c = null;
            qlRecord.Switcher_Promo_Discount_Temp__c = null;
            STring tempConcat = '';
            String tempEdition = qlRecord.Existing_Editions__c != null ? qlRecord.Existing_Editions__c + ', ' : '';
            String tempDisc = qlRecord.Previous_Total_Discount_HW__c != null ? qlRecord.Previous_Total_Discount_HW__c + ', ' : '';
            Decimal tempACV = 0.00;
            Decimal maxCredAmount = 0.00;
            Decimal existingRSCDisc = 0.00;
            Decimal suggestedDisc = 0.00;
            Decimal QLtradeUpDiscMonthly = 0.00;
            Integer SubsTerm = 36;
            String concatenatedRSC = qlRecord.Existing_RSC_Discount_HW__c != null ? qlRecord.Existing_RSC_Discount_HW__c + ', ' : '';
            List < Decimal > lstRSCDisc = new List < Decimal > ();
            Decimal minValue = 0.00;
            String tempConcatAssetIds = '';




            if (!mapOfAssetIdVsqlId.isEmpty()) {
                System.debug('IN mapOfAssetIdVsqlId');

                for (String assetId: mapOfAssetIdVsqlId.keySet()) {
                    if (qlRecord.Id == mapOfAssetIdVsqlId.get(assetId)) {
                        System.debug('IN qlRecord.Id == mapOfAssetIdVsqlId.get(assetId) >> ' + assetId);

                        Integer rSCMultiplier;
                        List < String > rSCMultiplierList = new List < String > ();
                        if (System.Label.TradeUp_Edition_RSC_Multiplier != '') {
                            //Getting Values of RSC Multipler based on Edition in order FE,BE,EE 
                            rSCMultiplierList = System.Label.TradeUp_Edition_RSC_Multiplier.split(',');
                        }

                        String convertedEditions = '';
                        if (mapOfAssetVsEdition.get(assetId) == 'Business') {
                            convertedEditions = 'BE';
                            rSCMultiplier = Integer.valueOf(rSCMultiplierList[1]);
                        } else if (mapOfAssetVsEdition.get(assetId) == 'Enterprise') {
                            convertedEditions = 'EE';
                            rSCMultiplier = Integer.valueOf(rSCMultiplierList[2]);
                        } else {
                            convertedEditions = 'FE';
                            rSCMultiplier = Integer.valueOf(rSCMultiplierList[0]);
                        }
                        tempEdition += convertedEditions + ', ';
                        if (assetForTradeUp.get(assetId).SBQQ__Discount__c != null) {
                            tempDisc += assetForTradeUp.get(assetId).SBQQ__Discount__c + '%, ';
                        } else {
                            tempDisc += '0%, ';
                        }
                         tempACV = assetAssociatedWithEntitlement.get(assetId).AnnualContractValue__c/assetForTradeUp.get(assetId).Product2.Usable_Capacity__c/12;

                        //System.debug('assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c >> '+ assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c);

                        Integer selectedQuantity = mapOfReqByVsEnt.get(qlRecord.Id).size();
                        if (qlRecord.SBQQ__RequiredBy__c != null && (qlRecord.SBQQ__Product__r.Tradeup_Pattern__c == null || qlRecord.SBQQ__Product__r.Tradeup_Pattern__c == '' )
                            && qlRecord.SBQQ__RequiredBy__r.Trade_Up_Multiplier__c !=null && assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c!=null) {

                            if (qlRecord.SBQQ__RequiredBy__r.SBQQ__ProrateMultiplier__c <= SubsTerm) { //SAL26-1343 replaced subscription term with prorate multiplier
                                maxCredAmount += assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c /*selectedQuantity*/ * qlRecord.SBQQ__RequiredBy__r.Trade_Up_Multiplier__c * qlRecord.SBQQ__RequiredBy__r.SBQQ__ProrateMultiplier__c / 36;//SAL26-1343 replaced subscription term with prorate multiplier
                            } else {
                                maxCredAmount += assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c /*selectedQuantity*/ * qlRecord.SBQQ__RequiredBy__r.Trade_Up_Multiplier__c * SubsTerm / 36;
                            }
            
                                qliIdAndTradeupAmount.put(qlRecord.SBQQ__RequiredBy__c, maxCredAmount);
            
                 existingRSCDisc = calRscVal(tempACV,rSCMultiplier);
                  
                   lstRSCDisc.add(existingRSCDisc);
                            
                        } else if ( qlRecord.SBQQ__Product__r.Tradeup_Pattern__c == 'Addon' && assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c!=null) {
                            System.debug('Else assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c ' + assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c);
                        
              
                            if (qlRecord.SBQQ__ProrateMultiplier__c <= SubsTerm) { //SAL26-1343 replaced subscription term with prorate multiplier
                                maxCredAmount += assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c /*selectedQuantity*/ * qlRecord.SBQQ__ProrateMultiplier__c / 36; //SAL26-1343 replaced subscription term with prorate multiplier
                            } else {
                                maxCredAmount += assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c /*selectedQuantity*/ * SubsTerm / 36;
                            }
            
                            qliIdAndTradeupAmount.put(qlRecord.Id, maxCredAmount);
                            
                              //qlRecord.Existing_RSC_Discount__c = minValue;
                existingRSCDisc = calRscVal(tempACV,rSCMultiplier);
               
                lstRSCDisc.add(existingRSCDisc);
                           
                        } else {
                            
              if(qlRecord.SBQQ__Product__r.Tradeup_Pattern__c!= null && qlRecord.SBQQ__Product__r.Tradeup_Pattern__c!= '' &&qlRecord.SBQQ__Product__r.Tradeup_Pattern__c.Contains('Hybrid')
                 && qlRecord.Trade_Up_Multiplier__c !=null && assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c!=null){
                if (qlRecord.SBQQ__ProrateMultiplier__c <= SubsTerm) { //SAL26-1343 replaced subscription term with prorate multiplier
                                maxCredAmount += assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c * qlRecord.Trade_Up_Multiplier__c * qlRecord.SBQQ__ProrateMultiplier__c / 36; //SAL26-1343 replaced subscription term with prorate multiplier
                            } else {
                                maxCredAmount += assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c  * qlRecord.Trade_Up_Multiplier__c * SubsTerm / 36;
                            }
              }else{
                  if(  qlRecord.Trade_Up_Multiplier__c !=null && assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c!=null){
                      if (qlRecord.SBQQ__ProrateMultiplier__c <= SubsTerm) { //SAL26-1343 replaced subscription term with prorate multiplier
                          maxCredAmount += assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c /*selectedQuantity*/* qlRecord.Trade_Up_Multiplier__c  * qlRecord.SBQQ__ProrateMultiplier__c / 36; //SAL26-1343 replaced subscription term with prorate multiplier
                      } else {
                          maxCredAmount += assetForTradeUp.get(assetId).Product2.Trade_Up_HW_Value__c /*selectedQuantity*/* qlRecord.Trade_Up_Multiplier__c  * SubsTerm / 36;
                      }
                  }
              }
                            qliIdAndTradeupAmount.put(qlRecord.Id, maxCredAmount);
              existingRSCDisc = calRscVal(tempACV,rSCMultiplier);
             
                lstRSCDisc.add(existingRSCDisc);
                            
                        }


                           /* tempACV = assetAssociatedWithEntitlement.get(assetId).AnnualContractValue__c / assetForTradeUp.get(assetId).Product2.Usable_Capacity__c / 12;
                            existingRSCDisc = (1 - ((tempACV * 1.08) / rSCMultiplier)) * 100; //MS Added to Calculate RSC Disc based on Edition
                            existingRSCDisc = existingRSCDisc.SetScale(2);*/
                            concatenatedRSC += String.valueOf(existingRSCDisc) + '%' + ', ';
                            tempConcat += assetForTradeUp.get(assetId).Name + ', ';
                            tempConcatAssetIds += assetId + ', ';
                           // lstRSCDisc.add(existingRSCDisc);
                            System.debug('existingRSCDisc' + existingRSCDisc);
                            


                    }
                }
            }
            if (qlRecord.Trade_Up_Serial_Number_on_HW__c == null) {
                qlRecord.Trade_Up_Serial_Number_on_HW__c = '';
            }
            qlRecord.Trade_Up_Serial_Number_on_HW__c = tempConcat.removeEnd(', ');
            qlRecord.Existing_Editions__c = tempEdition.removeEnd(', ');
            qlRecord.Previous_Total_Discount_HW__c = tempDisc.removeEnd(', ');
            if (qlRecord.Existing_TB__c == null) {
                qlRecord.Existing_TB__c = 0.00;
            }
            qlRecord.Existing_TB__c += tempACV.SetScale(2);
            System.debug('show existing TB'+ qlRecord.Existing_TB__c);
            if (qlRecord.Max_Credit_Amount__c == null) {
                qlRecord.Max_Credit_Amount__c = 0.00;
            }
            System.debug('maxCredAmount >> ' + maxCredAmount.SetScale(2));

            qlRecord.Max_Credit_Amount__c += maxCredAmount.SetScale(2);
            qlRecord.Existing_RSC_Discount_HW__c = concatenatedRSC.removeEnd(', ');

            if ( /*qlRecord.Product_Level__c == 'OnPrem' && qlRecord.Product_Type__c == 'Edition Upgrade'*/ qlRecord.SBQQ__Product__r.Eligible_For_Trade_Up__c && (qlRecord.Product_Type__c == 'Edition Upgrade' || (qlRecord.SBQQ__Product__r.Tradeup_Pattern__c != null && qlRecord.SBQQ__Product__r.Tradeup_Pattern__c != ''))) {
                if (qlRecord.Expected_Trade_Up_Discount__c == null) {
                    qlRecord.Expected_Trade_Up_Discount__c = 0.00;
                }
                qlRecord.Expected_Trade_Up_Discount__c = maxCredAmount.SetScale(2);
                if (qlRecord.Trade_Up_Serial_Number__c == null) {
                    qlRecord.Trade_Up_Serial_Number__c = '';
                }

                qlRecord.Trade_Up_Serial_Number__c = qlRecord.Trade_Up_Serial_Number__c + ', ' + tempConcat.removeEnd(', ');
                qlRecord.Trade_Up_Serial_Number__c = qlRecord.Trade_Up_Serial_Number__c.removeStart(', ');
               
            }
        if (!lstRSCDisc.isEmpty()) {
                                minValue = lstRSCDisc[0];
                                for (Integer i = 0; i < lstRSCDisc.size(); i++) {
                                    if (lstRSCDisc[i] < minValue)
                                        minValue = lstRSCDisc[i];
                                }
                            }
                            qlRecord.Existing_RSC_Discount__c = minValue;
                            System.debug('min val>>' + minValue);
            

            System.debug('mapOfAssetIdVsqlId >> ' + mapOfAssetIdVsqlId);
            for (String assetId: mapOfAssetIdVsqlId.keySet()) {
                if (qlRecord.Id == mapOfAssetIdVsqlId.get(assetId)) {
                    mapOfQLToDisplay.put(qlRecord.Id, qlRecord);
                    System.debug('mapOfQLToDisplay qlRecord >> ' + qlRecord);

                }
            }
        }


        for (SBQQ__QuoteLine__c qlObj: mapOfQLToDisplay.values()) {
            mapOfReqByvsAssetNames.put(qlObj.Id, qlObj.Trade_Up_Serial_Number_on_HW__c);
            mapOfReqByvsMaxCredVal.put(qlObj.Id, qlObj.Max_Credit_Amount__c);

            //mapOfReqByvsRSCDisc.put(qlObj.Id, qlObj.Existing_RSC_Discount__c);

            System.debug('mapOfReqByvsRSCDisc' + mapOfReqByvsRSCDisc);
            if (qlObj.Product_Level__c == 'Hardware' && qlObj.Product_Type__c == 'Hardware') {
                mapOfQLIdvsReqById.put(qlObj.Id, qlObj.SBQQ__RequiredBy__c);
                //madhura added for suggested disc
        if( qlObj.SBQQ__RequiredBy__c!= null){
          if(!mapOfReqByvsRSCDisc.isEmpty()  && mapOfReqByvsRSCDisc.containsKey(qlObj.SBQQ__RequiredBy__c)){
             if(qlObj.Existing_RSC_Discount__c > 0 && qlObj.Existing_RSC_Discount__c < mapOfReqByvsRSCDisc.get(qlObj.SBQQ__RequiredBy__c)){
               mapOfReqByvsRSCDisc.put(qlObj.SBQQ__RequiredBy__c, qlObj.Existing_RSC_Discount__c);
             }
          }else{
              if(qlObj.Existing_RSC_Discount__c > 0){
            mapOfReqByvsRSCDisc.put(qlObj.SBQQ__RequiredBy__c, qlObj.Existing_RSC_Discount__c);
            }
          }
        }
          
                    System.debug('mapOfQLIdvsReqById'+mapOfQLIdvsReqById);
                }
        else if(qlObj.SBQQ__Product__r.Eligible_For_Trade_Up__c && (qlObj.Product_Type__c == 'Edition Upgrade' || (qlObj.SBQQ__Product__r.Tradeup_Pattern__c!=null && qlObj.SBQQ__Product__r.Tradeup_Pattern__c !=''))){
                    mapOfQLIdvsReqById.put(qlObj.Id, qlObj.Id);
          //madhura added for suggested disc
          if(!mapOfReqByvsRSCDisc.isEmpty() && mapOfReqByvsRSCDisc.containsKey(qlObj.id)){
             if(qlObj.Existing_RSC_Discount__c > 0 && qlObj.Existing_RSC_Discount__c < mapOfReqByvsRSCDisc.get(qlObj.Id)){
               mapOfReqByvsRSCDisc.put(qlObj.Id, qlObj.Existing_RSC_Discount__c);
             }
          }else{
              if(qlObj.Existing_RSC_Discount__c > 0){
             mapOfReqByvsRSCDisc.put(qlObj.Id, qlObj.Existing_RSC_Discount__c);
          }
             }
          
                }
        }

        //Calculates values on Bundle level
        for (SBQQ__QuoteLine__c qlObj: [SELECT Id, Name, Trade_Up_Serial_Number__c, Existing_Editions__c, Previous_Total_Discount_HW__c, SBQQ__RequiredBy__c, SBQQ__OriginalPrice__c, SBQQ__Product__r.Trade_Up_HW_Value__c, SBQQ__Product__r.Trade_Up_Multiplier__c, SBQQ__RequiredBy__r.Product_Level__c, SBQQ__RequiredBy__r.Trade_Up_Multiplier__c,
                SBQQ__RequiredBy__r.Trade_Up_Serial_Number__c, SBQQ__Product__r.Capacity__c, SBQQ__ProductName__c, SBQQ__Quantity__c,
                SBQQ__Quote__r.SBQQ__SubscriptionTerm__c, SBQQ__Product__r.Usable_Capacity__c, SBQQ__RequiredBy__r.SBQQ__OriginalPrice__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Trade_Up_HW_Value__c,
                Appliance_Model_HW__c, Max_Credit_Amount__c, Existing_TB__c, Existing_RSC_Discount__c,PRE_Promo_Expiration_Date__c,Custom_Promo_Discount_Applicable__c,
                SBQQ__ProductCode__c, Trade_Up_Serial_Number_on_HW__c, Required_By_Product_Code__c, SBQQ__Number__c, SBQQ__SubscriptionTerm__c, Trade_Up_Multiplier__c,
                Product_Level__c, Product_Type__c, SBQQ__Quote__c, Trade_Up_Discount__c, Expected_Trade_Up_Discount__c, Category__c, Existing_RSC_Discount_HW__c, Usable_Capacity__c, SBQQ__Product__r.Eligible_For_Trade_Up__c,
                Suggested_Discount_to_Maximize_ACV_HW__c, Trade_Up_Discount_Applied__c, Switcher_Promo_Discount_Temp__c, Promo_Disc__c, Trade_Up_Discount_Prior__c, Trade_Up_Discount_Monthly__c,
                SBQQ__ListTotal__c, SBQQ__Product__r.Tradeup_Pattern__c FROM SBQQ__QuoteLine__c WHERE
                SBQQ__Quote__c =: quoteId AND Line_Type__c = 'New'
                AND SBQQ__Product__r.Eligible_For_Trade_Up__c = true
                /*((Category__c = 'Bundle' AND 
                Product_Level__c IN ('Hybrid Software','LOD Software','OnPrem') AND 
                Product_Type__c IN ('Enterprise Edition', 'Business Edition','Edition Upgrade', 'Foundation Edition')) OR ((Product_Level__c = 'OnPrem' AND Product_Type__c = 'Edition Upgrade')))*/
                ORDER BY SBQQ__Number__c
            ]) {


            //String tempConcat = qlObj.Trade_Up_Serial_Number__c!=null?qlObj.Trade_Up_Serial_Number__c+', ':'';
            String tempConcat = '';
            qlObj.Expected_Trade_Up_Discount__c = 0.00;
            Decimal maxCredVal = 0.00;
            //maxCredVal= qlObj.Expected_Trade_Up_Discount__c!=null?qlObj.Expected_Trade_Up_Discount__c:0.00;
            String minValue;
            Decimal minValueToStamp = 0.00;
            Decimal discountOnCap = 0.00;
            System.debug('mapOfReqByvsMaxCredVal >> ' + mapOfReqByvsMaxCredVal);

            for (SBQQ__QuoteLine__c qlObj2: mapOfQLToDisplay.values()) {
                System.debug('qlObj2 >> ' + qlObj2.SBQQ__ProductName__c);

                if (qlObj.Id == mapOfQLIdvsReqById.get(qlObj2.Id)) {
                    //qlObj.Trade_Up_Serial_Number__c = '';
                    System.debug('qlObj >> ' + qlObj.SBQQ__ProductName__c);
                    qlObj.Trade_Up_Serial_Number_on_HW__c = '';
                    qlObj.Existing_Editions__c = '';
                    qlObj.Previous_Total_Discount_HW__c = '';
                    qlObj.Existing_TB__c = 0.00;
                    qlObj.Max_Credit_Amount__c = 0.00;
                    qlObj.Existing_RSC_Discount__c = null;
                    qlObj.Existing_RSC_Discount_HW__c = '';
                    qlObj.Trade_Up_Serial_Number__c = '';
                    qlObj.Expected_Trade_Up_Discount__c = 0.00;
                    qlObj.Suggested_Discount_to_Maximize_ACV_HW__c = '';
                    qlObj.Trade_Up_Discount__c = 0.00;
                    qlObj.Promo_Disc__c = null;
                    qlObj.Total_Discount__c = null;
                    qlObj.Switcher_Promo_Discount_Temp__c = null;
                    qlObj.Trade_Up_Discount_Applied__c = false;
                    qlObj.Trade_Up_Discount_Monthly__c = 0.00;


                    tempConcat += mapOfReqByvsAssetNames.get(qlObj2.Id) + ', ';
                    maxCredVal += mapOfReqByvsMaxCredVal.get(qlObj2.Id);
                    System.debug('mapOfReqByvsRSCDisc >> ' + mapOfReqByvsRSCDisc);
                    for(String s1:mapOfReqByvsRSCDisc.keySet()) {
                            if (s1 == qlObj.Id) {
              System.debug('s1'+s1);
                  System.debug('ListminValue'+minValue);
                            System.debug('minValue >> '+ minValue);
                            minValueToStamp = mapOfReqByvsRSCDisc.get(qlObj.Id);
                            System.debug('minValueToStamp >> '+ minValueToStamp); 
                

                            }
                        }
                }
                System.debug('maxCredVal >> ' + maxCredVal);
                System.debug('minValueToStamp >> ' + minValueToStamp);

                Decimal totalTB = 0.00;
                if (qlObj2.Product_Level__c == 'Hybrid Software' || qlObj2.Product_Level__c == 'LOD Software' || qlObj2.Product_Type__c == 'Edition Upgrade' || (qlObj2.SBQQ__Product__r.Tradeup_Pattern__c != null && qlObj2.SBQQ__Product__r.Tradeup_Pattern__c !='')) {
                    totalTB = qlObj.SBQQ__Quantity__c;
                } else if (qlObj2.Usable_Capacity__c != null) {
          System.debug('show hardware+');
          System.debug('show Usable_Capacity__c+'+qlObj2.Usable_Capacity__c);
                    totalTB = qlObj2.SBQQ__Quantity__c * qlObj2.Usable_Capacity__c;
                }
                System.debug('totalTB >> ' + totalTB);

                for (Trade_Up_Program_Utility__mdt utiltiyItem: lstCapacityDiscount) {
                    System.debug('utiltiyItem.Capacity_Lower_Bound__c >> ' + utiltiyItem.Capacity_Lower_Bound__c);
                    System.debug('utiltiyItem.Capacity_Upper_Bound__c >> ' + utiltiyItem.Capacity_Upper_Bound__c);

                    if (totalTB >= utiltiyItem.Capacity_Lower_Bound__c && totalTB < utiltiyItem.Capacity_Upper_Bound__c) {
                        discountOnCap = utiltiyItem.Discount__c;
                    }
                }
                qlObj.Trade_Up_Serial_Number__c = tempConcat.removeEnd(', ');
                System.debug('before IF minValueToStamp >> ' + minValueToStamp);
                if (minValueToStamp == 0.00 && qlObj.Suggested_Discount_to_Maximize_ACV_HW__c != null) {
                    //minValueToStamp = Decimal.valueOf(qlObj.Suggested_Discount_to_Maximize_ACV_HW__c.removeEnd('%'));
                }
                System.debug('after minValueToStamp >> ' + minValueToStamp);
                System.debug('discountOnCap >> ' + discountOnCap);
                Decimal tempSuggestedDisc;
                Decimal tempSuggestedDisccomp;
                if(minValueToStamp <= 0){
                     tempSuggestedDisc =    discountOnCap;
                 
                }else{
                
                    tempSuggestedDisc = minValueToStamp < discountOnCap ? minValueToStamp : discountOnCap;
                }
                System.debug('tempSuggestedDisc????' + tempSuggestedDisc);
                if (tempSuggestedDisc == NULL) {
                    tempSuggestedDisc = 0.00;
                }
                if (qlObj2.SBQQ__RequiredBy__c != null && (qlObj2.SBQQ__Product__r.Tradeup_Pattern__c == null || qlObj2.SBQQ__Product__r.Tradeup_Pattern__c == '') && mapOfReqByvsSuggestedDisc.containsKey(qlObj2.SBQQ__RequiredBy__c) ) {
                    System.debug('Hardware line' + mapOfReqByvsSuggestedDisc.containsKey(qlObj2.SBQQ__RequiredBy__c));
          tempSuggestedDisccomp = mapOfReqByvsSuggestedDisc.get(qlObj2.SBQQ__RequiredBy__c);
          System.debug('tempSuggestedDisccomp'+tempSuggestedDisccomp);
          if( tempSuggestedDisc < tempSuggestedDisccomp){
            mapOfReqByvsSuggestedDisc.put(qlObj2.SBQQ__RequiredBy__c, tempSuggestedDisc);
            System.debug('correct value>>'+mapOfReqByvsSuggestedDisc);
          }
                    //tempSuggestedDisc = mapOfReqByvsSuggestedDisc.get(qlObj2.SBQQ__RequiredBy__c);
                    System.debug('tempSuggestedDisc####' + tempSuggestedDisc);
                }/*else if(qlObj2.SBQQ__RequiredBy__c != null && qlObj2.SBQQ__Product__r.Tradeup_Pattern__c != '' && mapOfReqByvsSuggestedDisc.containsKey(qlObj2.Id)){ 
            tempSuggestedDisc = mapOfReqByvsSuggestedDisc.get(qlObj2.Id);
                    System.debug('tempSuggestedDisc@@@@@@' + tempSuggestedDisc);
        }*/else if (qlObj2.SBQQ__RequiredBy__c != null && (qlObj2.SBQQ__Product__r.Tradeup_Pattern__c == null || qlObj2.SBQQ__Product__r.Tradeup_Pattern__c == '')) {
                    mapOfReqByvsSuggestedDisc.put(qlObj2.SBQQ__RequiredBy__c, tempSuggestedDisc);
                    System.debug('hardware map>hardware+' + mapOfReqByvsSuggestedDisc);
                } /*else if(qlObj2.SBQQ__RequiredBy__c != null && qlObj2.SBQQ__Product__r.Tradeup_Pattern__c != ''){
           mapOfReqByvsSuggestedDisc.put(qlObj2.Id, tempSuggestedDisc);
                    System.debug('hardware map>addon+' + mapOfReqByvsSuggestedDisc);
        }*/else {
            
                    mapOfReqByvsSuggestedDisc.put(qlObj.Id, tempSuggestedDisc);
          System.debug('mapOfReqByvsSuggestedDiscelse'+mapOfReqByvsSuggestedDisc);
           
                }
                /*if(qlObj2.SBQQ__Product__r.Tradeup_Pattern__c=='Addon' && mapOfReqByvsSuggestedDisc.containsKey(qlObj2.Id)){
                    tempSuggestedDisc += mapOfReqByvsSuggestedDisc.get(qlObj2.Id);
                    }else{
                    mapOfReqByvsSuggestedDisc.put(qlObj2.Id,tempSuggestedDisc);
                    }*/


                if (qlObj2.SBQQ__RequiredBy__c!=null && (qlObj2.SBQQ__Product__r.Tradeup_Pattern__c == null || qlObj2.SBQQ__Product__r.Tradeup_Pattern__c == '')) {
                    qlObj.Suggested_Discount_to_Maximize_ACV_HW__c = mapOfReqByvsSuggestedDisc.get(qlObj2.SBQQ__RequiredBy__c) != NULL ? String.valueOf(mapOfReqByvsSuggestedDisc.get(qlObj2.SBQQ__RequiredBy__c)) + '%' : '0.00%';
                    System.debug('I am here' + qlObj2.Id);
                    System.debug('I am here2' + mapOfReqByvsSuggestedDisc);
                }/*else if(qlObj2.SBQQ__RequiredBy__c!=null && qlObj2.SBQQ__Product__r.Tradeup_Pattern__c != ''){
          qlObj2.Suggested_Discount_to_Maximize_ACV_HW__c = mapOfReqByvsSuggestedDisc.get(qlObj2.Id) != NULL ? String.valueOf(mapOfReqByvsSuggestedDisc.get(qlObj2.Id)) + '%' : '0.00%';
                    
        }*/
                if (maxCredVal != 0.00) {


                    qlObj.Expected_Trade_Up_Discount__c = maxCredVal;

                }


                if ((qlObj2.Product_Level__c == 'OnPrem' || qlObj2.SBQQ__Product__r.Eligible_For_Trade_Up__c) && (qlObj2.Product_Type__c == 'Edition Upgrade' || (qlObj2.SBQQ__Product__r.Tradeup_Pattern__c != null && qlObj2.SBQQ__Product__r.Tradeup_Pattern__c !=''))) {
                    //qlObj2.Suggested_Discount_to_Maximize_ACV_HW__c = qlObj.Suggested_Discount_to_Maximize_ACV_HW__c;
                    qlObj2.Suggested_Discount_to_Maximize_ACV_HW__c = mapOfReqByvsSuggestedDisc.get(qlObj2.Id) != null ? String.valueOf(mapOfReqByvsSuggestedDisc.get(qlObj2.Id)) + '%' : '0.00%';
                    mapOfQLToDisplay.put(qlObj2.Id, qlObj2);
                    System.debug('I am here2');
                    System.debug('I am here2' + mapOfReqByvsSuggestedDisc);

                }
               /* if (qlObj2.SBQQ__Product__r.Tradeup_Pattern__c == 'Addon') {
                    //qlObj2.Suggested_Discount_to_Maximize_ACV_HW__c = qlObj.Suggested_Discount_to_Maximize_ACV_HW__c;
                    qlObj2.Suggested_Discount_to_Maximize_ACV_HW__c = mapOfReqByvsSuggestedDisc.get(qlObj2.Id) != null ? String.valueOf(mapOfReqByvsSuggestedDisc.get(qlObj2.Id)) + '%' : '0.00%';
                    mapOfQLToDisplay.put(qlObj2.Id, qlObj2);


                }*/
                System.debug('qlObj.Suggested_Discount_to_Maximize_ACV_HW__c' + qlObj.Suggested_Discount_to_Maximize_ACV_HW__c);
                System.debug('qlObj2.Suggested_Discount_to_Maximize_ACV_HW__c' + qlObj2.Suggested_Discount_to_Maximize_ACV_HW__c);


            }
            System.debug('b mapOfQLToDisplay >> ' + mapOfQLToDisplay);
            System.debug('qlObj1 >> ' + qlObj);
            if ((qlObj.Product_Level__c != 'OnPrem' && qlObj.Product_Type__c != 'Edition Upgrade' && !mapOfQLToDisplay.containsKey(qlObj.Id) && qlObj.Trade_Up_Serial_Number__c != '' && qlObj.Trade_Up_Serial_Number__c != null)) {
                mapOfQLToDisplay.put(qlObj.Id, qlObj);
            }
        }
        System.debug('a mapOfQLToDisplay >> ' + mapOfQLToDisplay);

        //For sorting the result to display based on final Map
        for (SBQQ__QuoteLine__c qliObj: mapOfQLToDisplay.values()) {
            System.debug('qliObj.Trade_Up_Discount__c' + qliObj.Trade_Up_Discount__c);
            System.debug('qliObj.Expected_Trade_Up_Discount__c' + qliObj.Expected_Trade_Up_Discount__c);

            qliObj.Trade_Up_Discount__c = qliObj.Expected_Trade_Up_Discount__c;

            productFamilyMap.put(qliObj.SBQQ__Number__c, qliObj);
        }
        System.debug('productFamilyMap.keyset() >> ' + productFamilyMap.keyset());
        //Add all elements of Set into a list
        orderingList.addAll(productFamilyMap.keyset());
        //Sort the List
        orderingList.sort();
        System.debug('orderingList >> ' + orderingList);
        for (Integer i = 0; i < orderingList.size(); i++) {
            productFamilyMapSorted.put(orderingList[i], productFamilyMap.get(orderingList[i]));
        }

        for (SBQQ__QuoteLine__c qliObj: productFamilyMapSorted.values()) {
            QuotelineDataList.add(new QuotelineData(qliObj, qliIdAndTradeupAmount.get(qliObj.id)));
        }
        System.debug('productFamilyMapSorted >> ' + productFamilyMapSorted);

        //return productFamilyMapSorted.values();
        return QuotelineDataList;
    }


    @AuraEnabled
    public static void callFinalUpdate(String quoteLinesToUpdateString, Map < Id, List < Id >> mapOfReqByVsEnt, Id quoteId) {
        List < SBQQ__QuoteLine__c > quotesTobeUpdatedFinal = new List < SBQQ__QuoteLine__c > ();
        Set < Id > quoteIds = new Set < Id > ();
        decimal tradeUpmonthly = 0.00;
        List < QuotelineData > quoteLinesToUpdate = (List < QuotelineData > ) JSON.deserialize(quoteLinesToUpdateString, List < QuotelineData > .class);
        List < SBQQ__Quote__c > quotesToUpdate = new List < SBQQ__Quote__c > ();
        Map < Id, String > mapOfBundlevsSNNos = new Map < Id, String > ();
        Map < Id, Decimal > mapOfBundlesvsTradeUpDisc = new Map < Id, Decimal > ();
        Boolean editionUpgradePresent = false;
        if (!quoteLinesToUpdate.isEmpty()) {
            for (QuotelineData qlObjCustom: quoteLinesToUpdate) {
                SBQQ__QuoteLine__c qlObj = qlObjCustom.Quoteline;
                quotesTobeUpdatedFinal.add(qlObjCustom.Quoteline);
                //Pankaj's change 2975
                system.debug('Trade_Up_Discount__c##########' + qlObj.Trade_Up_Discount__c);
                system.debug('Expecated tradeUp discount##########' + qlObj.Expected_Trade_Up_Discount__c);

                if (qlObj.Trade_Up_Discount__c != null) {
                    if (qlObj.SBQQ__ProrateMultiplier__c <= 36) { //SAL26-1343 replaced subscription term with prorate multiplier
                        system.debug('qlObjCustom.TradeupAmountWithdecimalPlaces^^^^^^^^^' + qlObjCustom.TradeupAmountWithdecimalPlaces);
                        system.debug('tradeUpmonthly ==== ^^^^^^^^^' + tradeUpmonthly);
                        if (qlObjCustom.TradeupAmountWithdecimalPlaces != null && qlObj.id != null && (qlObj.Trade_Up_Discount__c == qlObjCustom.TradeupAmountWithdecimalPlaces.setscale(2))) {
                            tradeUpmonthly = qlObjCustom.TradeupAmountWithdecimalPlaces / qlObj.SBQQ__ProrateMultiplier__c; //SAL26-1343 replaced subscription term with prorate multiplier
                            system.debug('tradeUpmonthly ==== ^^^^^^^^^' + tradeUpmonthly);
                        } else {
                            tradeUpmonthly = qlObj.Trade_Up_Discount__c / qlObj.SBQQ__ProrateMultiplier__c; //SAL26-1343 replaced subscription term with prorate multiplier
                        }

                    } else {
                        tradeUpmonthly = qlObj.Trade_Up_Discount__c / 36;
                    }
               if(String.isBlank(qlObj.SBQQ__Product__r.Promo_Code__c) && qlObj.PRE_Promo_Expiration_Date__c >= System.Today()){
                        qlObj.TradeUp_Promo__c = qlObj.SBQQ__Product__r.Promo_Code__c.replace('Promo', '').trim()+'/TradeUp';
                    }
                    else{
                        qlObj.TradeUp_Promo__c = 'Trade Up Promo';
                    }
                    qlObj.Promo_Code__c = 'Trade Up Promo';
                    qlObj.Custom_Promo_Discount_Applicable__c = false;
                }
                qlObj.Trade_Up_Discount_Monthly__c = tradeUpmonthly;
                system.debug('tradeUpmonthly  ##########' + qlObj.Trade_Up_Discount_Monthly__c);
                //Pankaj's change 2975 end

                if (qlObj.Max_Credit_Amount__c != 0) {
                    qlObj.Max_Credit_Amount__c = 0;
                }
            }
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            //update quoteLinesToUpdate;
            update quotesTobeUpdatedFinal;
            SBQQ.TriggerControl.enable();
        }
        if (!quoteLinesToUpdate.isEmpty()) {
            for (QuotelineData qlObjCustom: quoteLinesToUpdate) {
                SBQQ__QuoteLine__c qlObj = qlObjCustom.Quoteline;
                quoteIds.add(qlObj.SBQQ__Quote__c);
                if (qlObj.Category__c == 'Bundle') {
                    mapOfBundlevsSNNos.put(qlObj.Id, qlObj.Trade_Up_Serial_Number__c);
                    mapOfBundlesvsTradeUpDisc.put(qlObj.Id, qlObj.Expected_Trade_Up_Discount__c);
                }
                if (qlObj.Product_Type__c == 'Edition Upgrade') {
                    editionUpgradePresent = true;
                }
            }
        }

        for (SBQQ__Quote__c quoteObj: [Select Id, Name, Force_Recalculation__c, Trade_Up_Serial_Numbers__c, Trade_Up_Amounts__c, Has_UGNoTradeUpDisc__c, Show_Trade_Up_Discount__c from SBQQ__Quote__c where Id IN: quoteIds]) {
            String tempConcat = '';
            Decimal tempACV = 0.00;
            for (Id qlObjId: mapOfBundlevsSNNos.keySet()) {
                tempConcat += mapOfBundlevsSNNos.get(qlObjId) + ', ';
                tempACV += mapOfBundlesvsTradeUpDisc.get(qlObjId);
            }
            quoteObj.Trade_Up_Serial_Numbers__c = tempConcat.removeEnd(', ');
            quoteObj.Trade_Up_Amounts__c = tempACV.SetScale(2);
            quoteObj.Show_Trade_Up_Discount__c = quoteObj.Trade_Up_Amounts__c > 0.00 ? true : false;
            quoteObj.Has_UGNoTradeUpDisc__c = editionUpgradePresent;
            quotesToUpdate.add(quoteObj);
        }
        if (!quotesToUpdate.isEmpty()) {
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            //SBQQ.TriggerControl.disable();
            update quotesToUpdate;
            //SBQQ.TriggerControl.enable();

            if (!System.IsFuture() && !System.isBatch() && TriggerControls.disableCalculateAPIBatch == false) {
                CallCalculateAPIBatch batchInstance = new CallCalculateAPIBatch(quotesToUpdate);
                //Database.executeBatch(batchInstance, 1);
                TriggerControls.disableCalculateAPIBatch = true;
            }
        }
    }

    @AuraEnabled
    public static void clearRecords(Id quoteId, Id bundleId) {
        List < SBQQ__QuoteLine__c > quoteLinesToUpdate = [Select Id, Name, Trade_Up_Serial_Number__c, Existing_Editions__c, Previous_Total_Discount_HW__c, SBQQ__RequiredBy__c, SBQQ__OriginalPrice__c, SBQQ__Product__r.Trade_Up_HW_Value__c,
            SBQQ__Product__r.Trade_Up_Multiplier__c, SBQQ__RequiredBy__r.Product_Level__c, SBQQ__RequiredBy__r.Trade_Up_Multiplier__c,
            SBQQ__RequiredBy__r.Trade_Up_Serial_Number__c, SBQQ__Product__r.Capacity__c, SBQQ__ProductName__c, SBQQ__Quantity__c,
            SBQQ__Quote__r.SBQQ__SubscriptionTerm__c, SBQQ__Product__r.Usable_Capacity__c, SBQQ__RequiredBy__r.SBQQ__OriginalPrice__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Trade_Up_HW_Value__c,
            Appliance_Model_HW__c, Max_Credit_Amount__c, Existing_TB__c, Existing_RSC_Discount__c,PRE_Promo_Expiration_Date__c,SBQQ__Product__r.Promo_Code__c,
            SBQQ__ProductCode__c, Trade_Up_Serial_Number_on_HW__c, Required_By_Product_Code__c, SBQQ__Number__c, SBQQ__SubscriptionTerm__c, Trade_Up_Multiplier__c,
            Product_Level__c, Product_Type__c, SBQQ__Quote__c, Category__c, Usable_Capacity__c, Existing_RSC_Discount_HW__c, Suggested_Discount_to_Maximize_ACV_HW__c, Trade_Up_Discount_Monthly__c, SBQQ__Product__r.Tradeup_Pattern__c
            from SBQQ__QuoteLine__c where SBQQ__Quote__c =: quoteId AND Line_Type__c = 'New'
            AND(SBQQ__Product__r.Eligible_For_Trade_Up__c = true OR(Product_Level__c = 'Hardware'
                AND(Product_Type__c = 'Hardware'
                    OR Product_Type__c = 'Edition Upgrade'
                    OR SBQQ__Product__r.Tradeup_Pattern__c != '')))
        ];
        List < SBQQ__QuoteLine__c > qlRecordToUpdate = new List < SBQQ__QuoteLine__c > ();
        List < SBQQ__Quote__c > quotesToUpdate = new List < SBQQ__Quote__c > ();

        if (quoteLinesToUpdate != null) {
            for (SBQQ__QuoteLine__c qlRecord: quoteLinesToUpdate) {
                if (qlRecord.SBQQ__RequiredBy__c == bundleId || qlRecord.Id == bundleId) {
                    qlRecord.Trade_Up_Serial_Number_on_HW__c = '';
                    qlRecord.Existing_Editions__c = '';
                    qlRecord.Previous_Total_Discount_HW__c = '';
                    qlRecord.Existing_TB__c = 0.00;
                    qlRecord.Max_Credit_Amount__c = 0.00;
                    qlRecord.Existing_RSC_Discount__c = 0.00;
                    qlRecord.Existing_RSC_Discount_HW__c = '';
                    qlRecord.Trade_Up_Serial_Number__c = '';
                    qlRecord.Expected_Trade_Up_Discount__c = 0.00;
                    qlRecord.Suggested_Discount_to_Maximize_ACV_HW__c = '';
                    qlRecord.Trade_Up_Discount__c = 0.00;
                    qlRecord.Promo_Disc__c = null;
                    qlRecord.Total_Discount__c = null;
                    qlRecord.Switcher_Promo_Discount_Temp__c = null;
                    qlRecord.Trade_Up_Discount_Applied__c = false;
                    qlRecord.Trade_Up_Discount_Monthly__c = 0.00;

                    if(String.isBlank(qlRecord.SBQQ__Product__r.Promo_Code__c) && qlRecord.PRE_Promo_Expiration_Date__c >= System.Today()){
                        qlRecord.TradeUp_Promo__c = qlRecord.SBQQ__Product__r.Promo_Code__c.replace('Promo', '').trim()+'/TradeUp';
                    }
                    else{
                        qlRecord.TradeUp_Promo__c = 'Custom';
                    }
                    qlRecord.Promo_Code__c = '';
                }
                qlRecordToUpdate.add(qlRecord);
            }
            if (!qlRecordToUpdate.isEmpty()) {
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                SBQQ.TriggerControl.disable();
                update qlRecordToUpdate;
                SBQQ.TriggerControl.enable();
            }
            Set < Id > quoteIds = new Set < Id > ();
            if (!quoteLinesToUpdate.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj: quoteLinesToUpdate) {
                    quoteIds.add(qlObj.SBQQ__Quote__c);
                }
            }
            if (!quoteIds.isEmpty()) {
                for (SBQQ__Quote__c quoteObj: [Select Id, Name, Force_Recalculation__c, Trade_Up_Serial_Numbers__c, Trade_Up_Amounts__c, Has_UGNoTradeUpDisc__c, Show_Trade_Up_Discount__c from
                        SBQQ__Quote__c where Id IN: quoteIds
                    ]) {
                    quoteObj.Trade_Up_Serial_Numbers__c = '';
                    quoteObj.Trade_Up_Amounts__c = 0.00;
                    quoteObj.Show_Trade_Up_Discount__c = false;
                    quoteObj.Has_UGNoTradeUpDisc__c = false;
                    quotesToUpdate.add(quoteObj);
                }
            }
            if (!quotesToUpdate.isEmpty()) {
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                SBQQ.TriggerControl.disable();
                update quotesToUpdate;
                SBQQ.TriggerControl.enable();
            }
        }
    }
    public class RecordsData {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public RecordsData(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    public class QuotelineData {
        @AuraEnabled public SBQQ__QuoteLine__c Quoteline {
            get;
            set;
        }
        @AuraEnabled public Decimal TradeupAmountWithdecimalPlaces {
            get;
            set;
        }
        public QuotelineData(SBQQ__QuoteLine__c Quoteline, Decimal TradeupAmountWithdecimalPlaces) {
            this.Quoteline = Quoteline;
            this.TradeupAmountWithdecimalPlaces = TradeupAmountWithdecimalPlaces;
        }
    }

    public static Decimal calRscVal(Decimal tempACV,Integer rscMultiplier){
      Decimal existingRSCDisc = 0.00;
      existingRSCDisc = (1-((tempACV*1.08)/rSCMultiplier))*100; //MS Added to Calculate RSC Disc based on Edition
      existingRSCDisc = existingRSCDisc.SetScale(2);
                  // lstRSCDisc.add(existingRSCDisc);
       return existingRSCDisc;
          
  }    
}