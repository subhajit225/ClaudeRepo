/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 07-29-2020
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log  
* Ver   Date         Author           Modification
* 1.0   07-06-2020   Ashwini Singh   Initial Version
* 1.0   26-04-2022   Rahul Agarwal   RWD - 1151 : Enhancement - Add Validation for Missing Software 
**/   

public class DisplayAllAssetsControllerPaginated2_v4 {
    
    public List < AssetWrapper > lstAssetWrapper {
        get; 
        set;
    }
    public List < AssetWrapper > selectedAssets {
        get;
        set;
    }
    public String searchStr {
        get;
        set;
    }
    public String quoteName {
        get;
        set;
    }
    public string selectedID {
        get;
        set;
    }
    public String selectedGroupId {
        get;
        set;
    }
    public String populateSelectedAsset {
        get;
        set;
    }
    public string strPricebookId {
        get;
        set;
    }
    public Boolean showAssets {
        get;
        set;
    }
    public Boolean showUpgrade {
        get;
        set;
    }
    public Map < string, string > MapId_US {
        get;
        set;
    }
    public string selectedoptionsstr {
        get;
        set;
    }
    public Boolean isOldCustomUpgradeSourceActive {
        get;
        set;
    }
    public Set < String > assetProductIdSet {
        get;
        set;
    }
    public List < asset > lstAsset;
    public String quoteId;
    /***/
    public Boolean rcdmValid = false;
    public static X0_RCDM_Dates__mdt rcdmDatesObj;
    /* quotRangeStart*/
    public Date quotRangeStart;
    /* quotRangeEnd*/
    public Date quotRangeEnd;
    
    /**IsOldProduct */
    public Boolean IsOldProduct = false;
    public String validAssetFieldCombinations {
        get;
        set;
    } //[Rahul Agarwal] RWD - 1151 : Enhancement - Add Validation for Missing Software
    
    public String JsonMap {
        get;
        set;
    } //[Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
    
    public String JsonMapAssetName {
        get;
        set;
    }
    public String JsonMapLicenseType {
        get;
        set;
    }
    public String JsonMapRubrikSuite {
        get;
        set;
    }
    public String JsonMapPaymentOption {
        get;
        set;
    }
    public String JsonMapSupportType {
        get;
        set;
    }
    public String JsonMapAssetGroup {
        get;
        set;
    }
    public Boolean isFederalAccount             { get; set; }
    public Boolean isNonFederalAccount          { get; set; }
    public Boolean isOnPremException            { get; set; }
    
    public Map < String, String > mapSerialNumberProdFamily = new Map < String, String > (); //[Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
    public Map < String, String > mapSerialNumberAssetName = new Map < String, String > ();
    public Map < String, String > mapSerialNumberLicenseType = new Map < String, String > ();
    public Map < String, String > mapSerialNumberRubrikSuite = new Map < String, String > ();
    public Map < String, String > mapSerialNumberPaymentOption = new Map < String, String > ();
    public Map < String, String > mapSerialNumberSupportType = new Map < String, String > ();
    public Map < String, String > mapSerialNumberAssetGroup = new Map < String, String > ();
    
    public String urlvalue = 'https://' + Apexpages.currentPage().getHeaders().get('Host');
    public string saveURL = urlvalue.replace('--c.', '--sbqq.') + '/apex/sb?scontrolCaching=1&id=QUOTEID#quote/le?qId=QUOTEID';
    public string cancelURL = urlvalue.replace('--c.', '--sbqq.') + '/apex/sb?scontrolCaching=1&id=QUOTEID#/quote/le?qId=QUOTEID';
    public string backToAsset = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/DisplayAllAssetsClone2?newid=QUOTEID';
    
    //Added for Sakura
    public Boolean isL3Account {
        get;
        set;
    }
    public String supportTypeValue;
    public Boolean isAccountApproved {
        get;
        set;
    }
    public Boolean bEditionAvailable {
        get;
        set;
    } 
    /*ITNPI-449*/
    public Boolean isDealOpsUser    { get; set; }
    
    public DisplayAllAssetsControllerPaginated2_v4() {
        validAssetFieldCombinations = '[]'; //[Rahul Agarwal] RWD - 1151 : Enhancement - Add Validation for Missing Software
        isOldCustomUpgradeSourceActive = false;
    }
    
    public void fetchAllAssets() {
        //system.debug('fetchAllAssets Called');
        showAssets = true;
        showUpgrade = false;
        MapId_US = New Map < string, string > ();
        
        //Added for Sakura
        isL3Account = false;
        isAccountApproved = false;
        bEditionAvailable = false;
        
        /*if(!Test.isRunningTest()) {*/
        quoteId = ApexPages.currentPage().getParameters().get('newid');
        //}
        List < SBQQ__Quote__c > lstquote = new List < SBQQ__Quote__c > ();
        lstAssetWrapper = new List < AssetWrapper > ();
        lstAsset = new list < asset > ();
        String accountId;
        quoteName = '';
        Set < string > ignoreProduct = new Set < string > ();
        
        assetProductIdSet = new Set < String > ();
        //Pulling all the source Products ids from upgrade scource object
        Map < String, List < Custom_Upgrade_Source__c >> MapProductId = getValidProducts();
        Set < String > assetNameSet = new Set < String > ();
        Map < String, String > MapAssetIdGroupText = new Map < String, String > ();
        //[Rahul Agarwal] RWD - 1151 : Enhancement - Add Validation for Missing Software 
        //Start here
        Set < String > validAssetFieldCombinationsSet = new Set < String > ();
         List<GroupMember> gm = [SELECT UserOrGroupId,Group.DeveloperName FROM GroupMember WHERE UserOrGroupId=: UserInfo.getUserId() AND Group.DeveloperName = 'Deal_Desk' LIMIT 1];
        if(!gm.isEmpty()){
            isDealOpsUser = true;
        }
        else{
            isDealOpsUser = false;
        }

        for (product2 productObj: [SELECT id, ProductCode, Product_Type__c, Product_Subtype__c, Family, Product_NIC_Type__c, Usable_Capacity__c, Capacity__c,
                                   Sales_Comp_Category__c, Product_Payment_Option__c, Support_Type__c
                                   FROM Product2
                                   WHERE(Product_Level__c = 'Hybrid Software'
                                         OR Product_Level__c = 'OnPrem')
                                   AND isActive = true
                                  ]) {
                                      String combination = productObj.Product_Type__c + '_' + productObj.Product_Payment_Option__c + '_' + productObj.Support_Type__c;
                                      validAssetFieldCombinationsSet.add(combination);
                                  }
        if (!validAssetFieldCombinationsSet.isEmpty()) {
            validAssetFieldCombinations = JSON.serialize(validAssetFieldCombinationsSet);
        }
        //End here
        
        try {
            lstquote = [SELECT
                        Id,
                        SBQQ__Account__c, L3_Support_Only__c,
                        SBQQ__Account__r.isFederalIntel__c,
                        Deal_Ops_Exceptions_Modified__c,
                        Name, Is_Federal_Eligible_Quote__c, RWD_Sales_Rep_Exception__c,  
                        SBQQ__PriceBook__c,
                        SBQQ__PricebookId__c,
                        Eligible_for_RCDM_T__c,
                        Is_Customer_Fully_Transitioned__c,
                        Selective_Account_Eligible_for_RCDM_T__c,
                        RWD_Deal_Ops_Exception__c,
                        SBQQ__Type__c,
                        (SELECT Id, Quote_Line_Type__c, SBQQ__StartDate__c, SBQQ__EndDate__c,SBQQ__ProductCode__c, Arroyo_Subscribed_Asset_Name__c, SBQQ__Product__r.ProductCode, 
                         Product_Type__c, Product_Subtype__c, SBQQ__Product__r.Family, Product_Level__c,
                         SBQQ__Product__r.Usable_Capacity__c, SBQQ__Product__r.Capacity__c,
                         SBQQ__UpgradedAsset__c,
                         SBQQ__UpgradedAsset__r.Product2Id,
                         SBQQ__PriorQuantity__c FROM SBQQ__LineItems__r)
                        FROM
                        SBQQ__Quote__c
                        WHERE
                        Id =: quoteId
                       ];
            
            for (SBQQ__Quote__c objQuote: lstquote) {
                strPricebookId = objQuote.SBQQ__PricebookId__c;
                quoteName = objQuote.Name;
                
                //Added for Sakura - Starts
                if (objQuote.SBQQ__Account__c != null) {
                    isL3Account = objQuote.L3_Support_Only__c != null ?
                        objQuote.L3_Support_Only__c : false;
                    isAccountApproved = objQuote.SBQQ__Account__r.isFederalIntel__c != null ?
                        objQuote.SBQQ__Account__r.isFederalIntel__c : false;
                }
                
                if (isL3Account) {
                    supportTypeValue = 'L3';
                } else {
                    supportTypeValue = 'Premium';
                }
                
                if (objQuote.SBQQ__Account__c != null && 
                    (objQuote.SBQQ__Account__r.isFederalIntel__c || 
                     (objQuote.Deal_Ops_Exceptions_Modified__c != null && 
                      objQuote.Deal_Ops_Exceptions_Modified__c.contains('Fed Customers Eligibility Exception:No')))) 
                {
                    bEditionAvailable = true;
                }
                system.debug('objQuote.SBQQ__Account__r.isFederalIntel__c : ' + objQuote.SBQQ__Account__r.isFederalIntel__c);
                system.debug('objQuote.Deal_Ops_Exceptions_Modified__c : ' + objQuote.Deal_Ops_Exceptions_Modified__c);
                system.debug('bEditionAvailable : ' + bEditionAvailable);
                system.debug('objQuote : ' + objQuote.Id);
                
                isFederalAccount = objQuote.Is_Federal_Eligible_Quote__c;
                
                isOnPremException = objQuote.RWD_Sales_Rep_Exception__c != null
                    && objQuote.RWD_Sales_Rep_Exception__c.contains('Exception for On-Prem Quoting');
                
                //Added for Sakura - Ends
                
                for (SBQQ__QuoteLine__c objQuoteLine: objQuote.SBQQ__LineItems__r) {
                    system.debug('UpgradedAsset :-> ' + objQuoteLine.SBQQ__UpgradedAsset__c);
                    if (objQuoteLine.SBQQ__UpgradedAsset__c != null && (objQuoteLine.SBQQ__PriorQuantity__c == null || objQuoteLine.SBQQ__PriorQuantity__c == 0)) {
                        system.debug('objQuoteLine.SBQQ__ProductCode__c Value:-> ' + objQuoteLine.SBQQ__ProductCode__c);
                        ignoreProduct.add(objQuoteLine.SBQQ__UpgradedAsset__c);
                    }
                    
                    //Shaloo - Add Logic for Already Refreshed Lines via expansion process
                    if (String.isNotBlank(objQuoteLine.Arroyo_Subscribed_Asset_Name__c)) {
                        System.debug('Enter when ArroyoAsset field is not Blank :-> ' + objQuoteLine.Arroyo_Subscribed_Asset_Name__c);
                        for (String assetName: objQuoteLine.Arroyo_Subscribed_Asset_Name__c.split(',')) {
                            assetName = assetName.trim();
                            assetNameSet.add(assetName);
                            system.debug('assetName :--> ' + assetName);
                            system.debug('assetNameSet :--> ' + assetNameSet);
                        }
                    }
                    //ends
                }
            } //End of for
            system.debug('ignoreProduct Value:-> ' + ignoreProduct);
            
            //Shaloo - Add Logic for Already Refreshed Lines via expansion process
            system.debug('Final assetNameSet :--> ' + assetNameSet);
            List < Asset > assetRecList = new List < Asset > ();
            Set < Id > assetRecIDs = new Set < Id > ();
            if (!assetNameSet.IsEmpty()) {
                System.debug('Enter when assetNameSet is not Empty :-> ' + assetNameSet.size());
                assetRecList = [SELECT Id, Name, SerialNumber, ProductCode, Product2.ProductCode, Status, UsageEndDate FROM Asset
                                WHERE SerialNumber IN: assetNameSet
                               ];
                system.debug('assetRecList :--> ' + assetRecList);
                
                if (!assetRecList.IsEmpty()) {
                    System.debug('Enter when assetRecList is not Empty :-> ' + assetRecList.size());
                    for (Asset assets: assetRecList) {
                        assetRecIDs.add(assets.Id);
                    }
                }
            }
            System.debug('Enter assetRecIDs :-> ' + assetRecIDs);
            System.debug('Enter assetRecIDs Size:-> ' + assetRecIDs.size());
            //Shaloo Ends- Add Logic for Already Refreshed Lines via expansion process
            
            if (!lstquote.isEmpty()) {
                //accountId = lstquote[0].SBQQ__Account__c;
                String[] applicableAssetStatus = new String[] {
                    'Purchased',
                        'Dispatched'
                        };
                            Date today = System.today(); //RWD-440 Go Refresh | Assets | Asset Selection Page
                
                List < Asset > assetList = [SELECT Id, AccountId, Name, SerialNumber, ProductCode, Status, Quantity, Support_Start_Date__c, 
                                            Premium_Support_End_Date__c, UsageEndDate, Rubrik_Suite__c, Payment_Options__c, Support_Type__c, 
                                            Licensing_Model__c, Asset.Product2Id, Asset.Product2.ProductCode, Asset.Product2.Product_NIC_Type__c, 
                                            Asset.Product2.Family, Asset.Product2.Usable_Capacity__c, Asset.Product2.Capacity__c, Asset.Product_Nic_Type__c
                                            FROM Asset WHERE
                                            AccountId =: lstquote[0].SBQQ__Account__c AND UsageEndDate = null AND
                                            Status IN: applicableAssetStatus AND Product2Id IN: MapProductId.keyset() AND
                                            Support_Start_Date__c != NULL AND Premium_Support_End_Date__c != NULL AND
                                            Id Not In: ignoreProduct AND Id Not In: assetRecIDs AND Premium_Support_End_Date__c > today];
                /**/
                // 04/27/2022
                system.debug('VALUE assetList:-> ' + assetList + ' , eziS: ' + assetList.size());
                //Start: Jay (04/11/2022)
                for (Asset assetObj: assetList) {
                    //assetProductIdSet.add(assetObj?.Product2Id);
                    assetObj.Support_Type__c = supportTypeValue;
                    //assetObj.Rubrik_Suite__c = 'Enterprise';
                    
                    if (MapProductId.containskey(assetObj.Product2Id)) {
                        
                        for (Custom_Upgrade_Source__c objUS: MapProductId.get(assetObj.Product2Id)) {
                            assetProductIdSet.add(assetObj ?.Product2Id);
                            
                            if (!String.isBlank(objUS.UpgradeProduct__r.Product_Level__c)) {
                                
                                IsOldProduct = false;
                            } else {
                                
                                IsOldProduct = true;
                                break;
                            }
                        }
                        if (IsOldProduct) {
                            break;
                        }
                    }
                }
                //End
                system.debug('2 VALUE assetList:-> ' + assetList);
                for (Asset objAsset: assetList) {
                    objAsset.Support_Type__c = supportTypeValue;
                    
                    //assetObj.Rubrik_Suite__c = 'Enterprise';
                    
                    AssetWrapper objwrapper = new AssetWrapper();
                    system.debug('VALUE MapProductId:-> ' + MapProductId);
                    system.debug('VALUE objAsset.Product2Id:-> ' + objAsset.Product2Id);
                    if (MapProductId.containskey(objAsset.Product2Id)) {
                        system.debug('2 VALUE objAsset.Product2Id:-> ' + objAsset.Product2Id);
                        List < UpgradeSourceWrapper > lstUSWrapper = new List < UpgradeSourceWrapper > ();
                        List < SelectOption > lstOptions = new List < SelectOption > ();
                        for (Custom_Upgrade_Source__c objUS: MapProductId.get(objAsset.Product2Id)) {
                            UpgradeSourceWrapper objUSWrapper = new UpgradeSourceWrapper();
                            objUSWrapper.objUs = objUS;
                            objUSWrapper.selectedSource = false;
                            objUSWrapper.OptionLabel = objUS.UpgradeProduct__r.Name;
                            objUSWrapper.OptionValue = objUS.UpgradeProduct__c + '_' + objAsset.id;
                            system.debug('VALUE isOldCustomUpgradeSourceActive:-> ' + isOldCustomUpgradeSourceActive);
                            //if(IsOldProduct) {
                            if (isOldCustomUpgradeSourceActive) {
                                system.debug('Old Active?:->' + isOldCustomUpgradeSourceActive);
                                //isOldCustomUpgradeSourceActive = true;
                                if (String.isBlank(objUS.UpgradeProduct__r.Product_Level__c)) {
                                    
                                    lstUSWrapper.add(objUSWrapper);
                                    SelectOption objOption = new SelectOption(objUS.UpgradeProduct__c + '_' + objAsset.id, objUS.UpgradeProduct__r.Name);
                                    //MapId_US.put(objAsset.id,objUS.UpgradeProduct__c);
                                    lstOptions.add(objOption);
                                }
                            } else {
                                //isOldCustomUpgradeSourceActive = false;
                                system.debug('2 Old Active?:->' + isOldCustomUpgradeSourceActive);
                                if (String.isNotBlank(objUS.UpgradeProduct__r.Product_Level__c)) {
                                    
                                    lstUSWrapper.add(objUSWrapper);
                                    SelectOption objOption = new SelectOption(objUS.UpgradeProduct__c + '_' + objAsset.id, objUS.UpgradeProduct__r.Name);
                                    //MapId_US.put(objAsset.id,objUS.UpgradeProduct__c);
                                    lstOptions.add(objOption);
                                }
                            }
                            objwrapper.assetFamily = objUS.Source_Product__r.Family; //Later Change it to Family field
                        }
                        objwrapper.options.addAll(lstOptions);
                        objwrapper.lstUS.addAll(lstUSWrapper);
                    }
                    objwrapper.objAsset = objAsset;
                    if (objAsset.Product2.Product_NIC_Type__c != null) {
                        // pulling in new values for old values  29-July-2020
                        objwrapper.objAsset.Product_Nic_Type__c = getNICtype(objAsset.Product2.Product_NIC_Type__c);
                    } else {
                        objwrapper.NIC_Type = '';
                    }
                    //objwrapper.objAsset.Rubrik_Suite__c = 'Business'; // 'Enterprise'; //Commented out to default Enterprise edition
                    objwrapper.licenseType = 'SaaS';
                    objwrapper.rubrikEditionInput = 'Enterprise';
                    objwrapper.supportTypeInput = supportTypeValue;
                    objwrapper.paymentOptionsInput = objwrapper.objAsset.Payment_Options__c;
                    if(isDealOpsUser){
                        objwrapper.rubrikEditionInput = 'Proactive';
                    }
                    else{
                        objwrapper.rubrikEditionInput = 'Enterprise';
                    }
                    
                    //objwrapper.selectedGroup = MapAssetIdGroupText.get(objwrapper.objAsset.Id);
                    
                    system.debug('licenseType1:-> ' + objwrapper.licenseType);
                    system.debug('RubrikSuite :-> ' + objwrapper.rubrikEditionInput);
                    system.debug('PaymentOption :-> ' + objwrapper.paymentOptionsInput);
                    system.debug('SupportType :-> ' + objwrapper.supportTypeInput);
                    system.debug('GroupAsset:-> ' + objwrapper.selectedGroup);
                    
                    lstAssetWrapper.add(objwrapper);
                    system.debug('VALUE lstAssetWrapper:-> ' + lstAssetWrapper);
                    lstAsset.add(objAsset);
                } //End of for
            }
            system.debug('2 VALUE lstAssetWrapper:-> ' + lstAssetWrapper);
            //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
            for (AssetWrapper obj: lstAssetWrapper) {
                system.debug('LType: ' + obj.licenseType);
                system.debug('ProdFamily: ' + obj.assetFamily);
                mapSerialNumberProdFamily.put(obj.objAsset.Id, obj.licenseType);
                mapSerialNumberAssetName.put(obj.objAsset.SerialNumber, obj.objAsset.SerialNumber);
                mapSerialNumberLicenseType.put(obj.objAsset.SerialNumber, obj.licenseType);
                mapSerialNumberRubrikSuite.put(obj.objAsset.SerialNumber, obj.rubrikEditionInput);
                mapSerialNumberPaymentOption.put(obj.objAsset.SerialNumber, obj.paymentOptionsInput);
                mapSerialNumberSupportType.put(obj.objAsset.SerialNumber, obj.supportTypeInput);
                mapSerialNumberAssetGroup.put(obj.objAsset.SerialNumber, obj.selectedGroup);
            }
            system.debug('mapSerialNumberAssetName:-> ' + mapSerialNumberAssetName);
            system.debug('mapSerialNumberLicenseType:-> ' + mapSerialNumberLicenseType);
            system.debug('mapSerialNumberRubrikSuite:-> ' + mapSerialNumberRubrikSuite);
            system.debug('mapSerialNumberPaymentOption:-> ' + mapSerialNumberPaymentOption);
            system.debug('mapSerialNumberSupportType:-> ' + mapSerialNumberSupportType);
            system.debug('mapSerialNumberAssetGroup:-> ' + mapSerialNumberAssetGroup);
            
            
            if (!mapSerialNumberProdFamily.isEmpty()) {
                JsonMap = JSON.serialize(mapSerialNumberProdFamily);
            }
            if (!mapSerialNumberAssetName.isEmpty()) {
                JsonMapAssetName = JSON.serialize(mapSerialNumberAssetName);
            }
            if (!mapSerialNumberLicenseType.isEmpty()) {
                JsonMapLicenseType = JSON.serialize(mapSerialNumberLicenseType);
            }
            if (!mapSerialNumberRubrikSuite.isEmpty()) {
                JsonMapRubrikSuite = JSON.serialize(mapSerialNumberRubrikSuite);
            }
            if (!mapSerialNumberPaymentOption.isEmpty()) {
                JsonMapPaymentOption = JSON.serialize(mapSerialNumberPaymentOption);
            }
            if (!mapSerialNumberSupportType.isEmpty()) {
                JsonMapSupportType = JSON.serialize(mapSerialNumberSupportType);
            }
            if (!mapSerialNumberAssetGroup.isEmpty()) {
                JsonMapAssetGroup = JSON.serialize(mapSerialNumberAssetGroup);
            }
            system.debug('JsonMapAssetName:-> ' + JsonMapAssetName);
            system.debug('JsonMapLicenseType:-> ' + JsonMapLicenseType);
            system.debug('JsonMapRubrikSuite:-> ' + JsonMapRubrikSuite);
            system.debug('JsonMapPaymentOption:-> ' + JsonMapPaymentOption);
            system.debug('JsonMapSupportType:-> ' + JsonMapSupportType);
            system.debug('JsonMapAssetGroup:-> ' + JsonMapAssetGroup);
            
            system.debug('JsonMap--> ' + JsonMap);
            //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
        }
        Catch(Exception ex) {
            system.debug('Exception in page : ' + ex);
        } //End of Try-Catch
        
    } //End of fetchAllAssets
    
    public Map < String, List < Custom_Upgrade_Source__c >> getValidProducts() {
        
        Map < String, List < Custom_Upgrade_Source__c >> mapId_SP = new Map < String, List < Custom_Upgrade_Source__c >> ();
        
        for (Custom_Upgrade_Source__c objsource: [SELECT Id, Source_Product__c, Source_Product__r.Name,
                                                  Source_Product__r.ProductCode, Source_Product__r.Family,
                                                  Display_Index__c, UpgradeProduct__r.Product_NIC_Type__c,
                                                  UpgradeProduct__r.Name, UpgradeProduct__r.ProductCode,
                                                  UpgradeProduct__r.Description, Active__c, Source_Product__r.Usable_Capacity__c, UpgradeProduct__r.Usable_Capacity__c, UpgradeProduct__r.Product_Level__c FROM Custom_Upgrade_Source__c WHERE Active__c = true ORDER BY Display_Index__c ASC
                                                 ]) {
                                                     if (String.isBlank(objsource.UpgradeProduct__r.Product_Level__c)) {
                                                         
                                                         isOldCustomUpgradeSourceActive = true;
                                                     }
                                                     
                                                     decimal sourceUsableCapacity = objsource.Source_Product__r.Usable_Capacity__c;
                                                     decimal upgradeUsableCapacity = objsource.UpgradeProduct__r.Usable_Capacity__c;
                                                     
                                                     if (objsource.Source_Product__c != null &&
                                                         mapId_SP.containsKey(objsource.Source_Product__c)
                                                         //&&
                                                        ) {
                                                            
                                                            mapId_SP.get(objsource.Source_Product__c).add(objsource);
                                                        } else {
                                                            List < Custom_Upgrade_Source__c > newLstUS = new List < Custom_Upgrade_Source__c > ();
                                                            
                                                            newLstUS.add(objsource);
                                                            mapId_SP.put(objsource.Source_Product__c, newLstUS);
                                                        }
                                                 } //End of for
        
        return mapId_SP;
    } //End of getValidProducts
    
    public void saveAssets() {
        selectedAssets = new List < AssetWrapper > ();
        List < String > lstIDs = new List < String > ();
        Map < String, String > mapString_String = new Map < String, String > ();
        Map < String, String > MapAssetIdGroupText = new Map < String, String > ();
        
        Map < String, String > MapAssetIdLicenseTypeText = new Map < String, String > ();
        Map < String, String > MapAssetIdRubrikSuiteText = new Map < String, String > ();
        Map < String, String > MapAssetIdPaymentOptionText = new Map < String, String > ();
        Map < String, String > MapAssetIdSupportTypeText = new Map < String, String > ();
        
        List < AssetWrapper > lstBlankGroup = new List < AssetWrapper > ();
        Map < String, List < AssetWrapper >> MapAssetGrpAssetRec = new Map < String, List < AssetWrapper >> ();
        Map < String, List < String >> MapAssetGrpAssetNameRec = new Map < String, List < String >> ();
        Map < String, String > MapAssetGrpAssetNameJoined = new Map < String, String > ();
        List < String > assetNameList;
        List < AssetWrapper > assetWrapList;
        Integer maxProdCapacity = 0;
        Integer numericCapacity = 0; //Earlier 0 was not initialized
        Map < String, String > mapProdIdProductCode = new Map < String, String > ();
        String subsAssetId = '';
        Set < String > groupUsed = new Set < String > ();
        
        boolean controllerError = false;
        
        Map < String, Map < String, String >> mapAssetIdFieldValueMap = new Map < String, Map < String, String >> ();
        
        system.debug('populateSelectedAsset>> ' + populateSelectedAsset);
        
        if (String.isNotBlank(populateSelectedAsset)) {
            List < String > lstSelectedID = populateSelectedAsset.split(',');
            for (String str: lstSelectedID) {
                String assetRecId = str.subString(0, 18);
                String fieldValues = str.subString(18, str.length());
                List < String > fieldValuesList = fieldValues.split('@');
                
                Map < String, String > fieldValueMap = new Map < String, String > ();
                system.debug('fieldValuesList>>' + fieldValuesList);
                for (String stringValue: fieldValuesList) {
                    if (String.isNotBlank(stringValue)) {
                        List < String > fieldValuesListAgain = stringValue.split('##');
                        system.debug('fieldValuesListAgain>>' + fieldValuesListAgain);
                        if(fieldValuesListAgain.size() > 1){
                            fieldValueMap.put(fieldValuesListAgain[0], fieldValuesListAgain[1]);
                        }
                        system.debug('fieldValueMap>>>' + fieldValueMap);
                    }
                    
                }
                system.debug('fieldValueMap>>>' + fieldValueMap);
                system.debug('assetRecId>>>' + assetRecId);
                mapAssetIdFieldValueMap.put(assetRecId, fieldValueMap);
            }
            
        }
        
        List < String > lstSelectedID = selectedID.split(',');
        system.debug('lstSelectedID1>> ' + lstSelectedID);
        system.debug('mapAssetIdFieldValueMap>> ' + mapAssetIdFieldValueMap);
        
        String regex1 = '', regex2 = '', regex3 = '', regex4 = '', regex5 = '', regex6 = '', regex7 = '', regex8 = '';
        
        if (String.isNotBlank(populateSelectedAsset)) {
            for (String strId1: populateSelectedAsset.split(',')) {
                system.debug('strId1A>>' + strId1);
                if (String.isNotBlank(strId1)) {
                    //regex1= strId1.subString(19, len1);
                    for (String str: mapAssetIdFieldValueMap.get(strId1.subString(0, 18)).keySet()) {
                        if (str == 'LicenseType') {
                            MapAssetIdLicenseTypeText.put(strId1.subString(0, 18), mapAssetIdFieldValueMap.get(strId1.subString(0, 18)).get('LicenseType'));
                        }
                        
                        if (str == 'RubrikEdition') {
                            MapAssetIdRubrikSuiteText.put(strId1.subString(0, 18), mapAssetIdFieldValueMap.get(strId1.subString(0, 18)).get('RubrikEdition'));
                        }
                        
                        if (str == 'PaymentOptions') {
                            MapAssetIdPaymentOptionText.put(strId1.subString(0, 18), mapAssetIdFieldValueMap.get(strId1.subString(0, 18)).get('PaymentOptions'));
                        }
                        
                        if (str == 'SupportType') {
                            MapAssetIdSupportTypeText.put(strId1.subString(0, 18), mapAssetIdFieldValueMap.get(strId1.subString(0, 18)).get('SupportType'));
                        }
                        if (str == 'AssetGroup') {
                            MapAssetIdGroupText.put(strId1.subString(0, 18), mapAssetIdFieldValueMap.get(strId1.subString(0, 18)).get('AssetGroup'));
                        }
                    }
                }
            }
        }
        System.debug('MapAssetIdLicenseTypeText Value:->> ' + MapAssetIdLicenseTypeText + ' ,MapAssetIdLicenseTypeTextValue:>> ' + MapAssetIdLicenseTypeText.size());
        System.debug('MapAssetIdRubrikSuiteText Value:->> ' + MapAssetIdRubrikSuiteText + ' ,MapAssetIdRubrikSuiteTextValue:>> ' + MapAssetIdRubrikSuiteText.size());
        System.debug('MapAssetIdPaymentOptionText Value:->> ' + MapAssetIdPaymentOptionText + ' ,MapAssetIdPaymentOptionTextValue:>> ' + MapAssetIdPaymentOptionText.size());
        System.debug('MapAssetIdSupportTypeText Value:->> ' + MapAssetIdSupportTypeText + ' ,MapAssetIdSupportTypeTextValue:>> ' + MapAssetIdSupportTypeText.size());
        
        if (String.isNotBlank(populateSelectedAsset)) {
            for (String strId: populateSelectedAsset.split(',')) {
                system.debug('strId>>' + strId);
                if (String.isNotBlank(strId)) {
                    Integer len = strId.length();
                    mapString_String.put(strId.subString(0, 18), strId.subString(0, 18));
                }
            }
        }
        System.debug('mapString_String Value:->> ' + mapString_String + ' ,SizeValue:>> ' + mapString_String.size());
        
        System.debug('selectedGroupId:->> ' + selectedGroupId);
        
        
        System.debug('mapString_String:->> ' + mapString_String + ' , SZIE: ' + mapString_String.SIZE());
        if (!Test.isRunningTest()) {
            if (quoteId == null) {
                quoteId = ApexPages.currentPage().getParameters().get('newid');
            }
        }
        String QuoteLineIds;
        //String NextPageUrl;
        
        //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
        Map<String,Integer> groupNamMaxCapacityMap = new Map<String,Integer>();
        Integer individualAssetCapacity = 0;
        for (AssetWrapper objAssetRec: lstAssetWrapper) {
            system.debug('objAssetRec>>' + objAssetRec);
            system.debug('AssetNameA:-> ' + objAssetRec.objAsset.Product2 + ' , licenseTypeW:-> ' + objAssetRec.licenseType);
            if (MapAssetIdGroupText.containskey(objAssetRec.objAsset.Id)) {
                objAssetRec.selectedGroup = MapAssetIdGroupText.get(objAssetRec.objAsset.Id);
            }
            if (MapAssetIdLicenseTypeText.containskey(objAssetRec.objAsset.Id)) {
                objAssetRec.licenseType = MapAssetIdLicenseTypeText.get(objAssetRec.objAsset.Id);
            }
            
            if(mapString_String.containsKey(objAssetRec.objAsset.Id)){
                individualAssetCapacity = Integer.valueOf((objAssetRec.objAsset.Product2.Capacity__c).replaceAll('TB', ''));
                if(String.isNotBlank(objAssetRec.selectedGroup)){
                    if(groupNamMaxCapacityMap.containskey(objAssetRec.selectedGroup) && groupNamMaxCapacityMap.get(objAssetRec.selectedGroup) < individualAssetCapacity){
                        groupNamMaxCapacityMap.put(objAssetRec.selectedGroup,individualAssetCapacity);
                    }
                    else if(!groupNamMaxCapacityMap.containskey(objAssetRec.selectedGroup)){
                        groupNamMaxCapacityMap.put(objAssetRec.selectedGroup,individualAssetCapacity);
                    }
                }
                
            }
            
            
        }
        system.debug('groupNamMaxCapacityMap>>'+groupNamMaxCapacityMap);
        for (AssetWrapper objAssetRec: lstAssetWrapper) {
            if (MapAssetIdLicenseTypeText.containskey(objAssetRec.objAsset.Id)) {
                objAssetRec.licenseType = MapAssetIdLicenseTypeText.get(objAssetRec.objAsset.Id);
            }
            system.debug('AssetNameB:-> ' + objAssetRec.objAsset.Product2 + ' , licenseTypeT:-> ' + objAssetRec.licenseType);
            system.debug('NIC_Type:-> ' + objAssetRec.NIC_Type);
            
            if (objAssetRec.objAsset != null && objAssetRec.objAsset.Product2 != null && objAssetRec.objAsset.Product2.Capacity__c != null) {
                numericCapacity = Integer.valueOf((objAssetRec.objAsset.Product2.Capacity__c).replaceAll('TB', ''));
            }
            system.debug('objAssetRec.selectedGroup>>Group' + objAssetRec.selectedGroup);
            system.debug('objAssetRec.selectedGroup>>Id>>' + objAssetRec.objAsset.Id);
            if (mapString_String.containsKey(objAssetRec.objAsset.Id)) {
                system.debug('objAssetRec.selectedGroup>>??'+objAssetRec.selectedGroup);
                system.debug('objAssetRec.objAsset.Product2Id'+objAssetRec.objAsset.Product2Id);
                if (objAssetRec.selectedGroup != null && objAssetRec.selectedGroup != '') {
                    if (MapAssetGrpAssetRec.containsKey(objAssetRec.selectedGroup)) {
                        system.debug('GroupX: ' + MapAssetGrpAssetRec.get(objAssetRec.selectedGroup));
                        MapAssetGrpAssetRec.get(objAssetRec.selectedGroup).add(objAssetRec);
                        
                    }
                    //already does not contain group
                    else {
                        system.debug('GroupY: ' + MapAssetGrpAssetRec);
                        assetWrapList = new List < AssetWrapper > ();
                        assetWrapList.add(objAssetRec);
                        MapAssetGrpAssetRec.put(objAssetRec.selectedGroup, assetWrapList);
                        
                    }
                    
                    if (MapAssetGrpAssetNameRec.containsKey(objAssetRec.selectedGroup)) {
                        MapAssetGrpAssetNameRec.get(objAssetRec.selectedGroup).add(objAssetRec.objAsset.Name);
                        subsAssetId = string.join(MapAssetGrpAssetNameRec.get(objAssetRec.selectedGroup), ' , ');
                        MapAssetGrpAssetNameJoined.put(objAssetRec.selectedGroup, subsAssetId);
                    } else {
                        assetNameList = new List < String > ();
                        assetNameList.add(objAssetRec.objAsset.Name);
                        MapAssetGrpAssetNameRec.put(objAssetRec.selectedGroup, assetNameList);
                        subsAssetId = string.join(MapAssetGrpAssetNameRec.get(objAssetRec.selectedGroup), ',');
                        MapAssetGrpAssetNameJoined.put(objAssetRec.selectedGroup, subsAssetId);
                    }
                    
                    if(!mapProdIdProductCode.containskey(objAssetRec.selectedGroup)){
                        if(groupNamMaxCapacityMap.get(objAssetRec.selectedGroup) == numericCapacity){
                            mapProdIdProductCode.put(objAssetRec.selectedGroup,objAssetRec.objAsset.Product2Id);
                        }
                        system.debug('mapProdIdProductCode-' + mapProdIdProductCode);
                    }
                    
                    
                } //group check ends
                else {
                    subsAssetId = objAssetRec.objAsset.Name;
                    MapAssetGrpAssetNameJoined.put(objAssetRec.objAsset.Name, subsAssetId);
                }
            }
        }
        system.debug('subsAssetId Final-->' + subsAssetId);
        system.debug('maxProdCapacityZ5: ' + maxProdCapacity);
        system.debug('mapProdIdProductCode-->' + mapProdIdProductCode); //Product Code with Max capacity
        system.debug('MapAssetGrpAssetRec-->' + MapAssetGrpAssetRec);
        //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
        
        System.debug('lstAssetWrapper Size:-- ' + lstAssetWrapper.size());
        Map < String, String > groupNameConfigurationMap = new Map < String, String > ();
        Map < String, String > groupNameFamilyMap = new Map < String, String > ();
        for (AssetWrapper obj: lstAssetWrapper) {
            obj.rubrikEditionInput = 'Business';
            system.debug('obj.rubrikEditionInput????' + obj.rubrikEditionInput);
            system.debug('obj.rubrikEditionInput>>'+obj.rubrikEditionInput);
            system.debug('obj.objAsset.Product2IdR: ' + obj.objAsset.Product2Id + ' LicenseTypeR:-> ' + obj.licenseType);
            if (MapAssetIdLicenseTypeText.containskey(obj.objAsset.Id)) {
                obj.licenseType = MapAssetIdLicenseTypeText.get(obj.objAsset.Id);
            }
            system.debug('obj.objAsset.Product2IdA: ' + obj.objAsset.Product2Id + ' LicenseTypeP:-> ' + obj.licenseType);
            system.debug('mapString_String:-> ' + mapString_String.containsKey(obj.objAsset.Id));
            
            AssetWrapper objSelectedAsset = new AssetWrapper();
            objSelectedAsset.licenseType = obj.licenseType;
            
            
            if (mapString_String.containsKey(obj.objAsset.Id)) {
                system.debug('obj.objAsset.Product2IdB: ' + obj.objAsset.Product2Id + ' LicenseTypeQ:-> ' + obj.licenseType);
                
                obj.selectedAsset = true;
                List < UpgradeSourceWrapper > lstsource = New List < UpgradeSourceWrapper > ();
                List < SelectOption > lstOptions = new List < SelectOption > ();
                objSelectedAsset.objAsset = obj.objAsset;
                if (MapAssetIdGroupText.containskey(obj.objAsset.Id)) {
                    obj.selectedGroup = MapAssetIdGroupText.get(obj.objAsset.Id);
                }
                system.debug('obj.rubrikEditionInput' + obj.rubrikEditionInput);
                system.debug('obj.paymentOptionsInput' + obj.paymentOptionsInput);
                system.debug('obj.supportTypeInput' + obj.supportTypeInput);
                system.debug('obj.licenseType' + obj.licenseType);
                
                if (MapAssetIdLicenseTypeText.containskey(obj.objAsset.Id)) {
                    obj.licenseType = MapAssetIdLicenseTypeText.get(obj.objAsset.Id);
                }
                if (MapAssetIdRubrikSuiteText.containskey(obj.objAsset.Id)) {
                    obj.rubrikEditionInput = MapAssetIdRubrikSuiteText.get(obj.objAsset.Id);
                }
                if (MapAssetIdPaymentOptionText.containskey(obj.objAsset.Id)) {
                    obj.paymentOptionsInput = MapAssetIdPaymentOptionText.get(obj.objAsset.Id);
                }
                if (MapAssetIdSupportTypeText.containskey(obj.objAsset.Id)) {
                    obj.supportTypeInput = MapAssetIdSupportTypeText.get(obj.objAsset.Id);
                }
                
                
                system.debug('obj.selectedGroup>>' + obj.selectedGroup);
                system.debug('obj.selectedGroup>>' + obj.objAsset.Id);
                
                //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
                if (obj.selectedGroup != null && obj.selectedGroup != '') {
                    objSelectedAsset.assetSerialName = MapAssetGrpAssetNameJoined.get(obj.selectedGroup);
                } else {
                    objSelectedAsset.assetSerialName = MapAssetGrpAssetNameJoined.get(obj.objAsset.Name);
                }
                system.debug('objSelectedAsset.assetSerialName:--> ' + objSelectedAsset.assetSerialName);
                system.debug('obj.lstUS A-->' + obj.lstUS);
                system.debug('obj.lstUS Size A:-->' + obj.lstUS.size());
                
                String grpWithProdId = obj.selectedGroup + '' + obj.objAsset.Product2Id;
                system.debug('obj.objAsset.Product2IdC: ' + obj.objAsset.Product2Id + ' LicenseTypeR:-> ' + obj.licenseType);
                
                //validation for configuration  and assetFamily
                system.debug('Concatinate' + obj.rubrikEditionInput + obj.paymentOptionsInput + obj.supportTypeInput);
                if(String.isNotBlank(obj.selectedGroup)){
                    if (groupNameConfigurationMap.containsKey(obj.selectedGroup)) {
                        if (groupNameConfigurationMap.get(obj.selectedGroup) != obj.rubrikEditionInput + obj.paymentOptionsInput + obj.supportTypeInput) {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Products under same Group should have similar configurations. Please select correct values for Rubrik Edition, Payment Options and Support Type'));
                            controllerError = true;
                        }
                    } else {
                        groupNameConfigurationMap.put(obj.selectedGroup, obj.rubrikEditionInput + obj.paymentOptionsInput + obj.supportTypeInput);
                        controllerError = false;
                        
                    }
                }
                system.debug('obj.assetFamily>>>'+obj.assetFamily);
                if(String.isNotBlank(obj.selectedGroup)){
                    if(groupNameFamilyMap.containsKey(obj.selectedGroup)){
                        if(groupNameFamilyMap.get(obj.selectedGroup) != obj.assetFamily){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Products from different families cannot be grouped together.'));
                            controllerError = true;
                        }
                    }
                    else{
                        groupNameFamilyMap.put(obj.selectedGroup,obj.assetFamily);
                    }
                }
                
                
                if ((!groupUsed.contains(grpWithProdId) && obj.selectedGroup != '' && obj.selectedGroup != null && mapProdIdProductCode.get(obj.selectedGroup) == obj.objAsset.Product2Id) || (obj.selectedAsset && !MapAssetGrpAssetRec.containsKey(obj.selectedGroup))) {
                    groupUsed.add(grpWithProdId);
                    system.debug('obj.lstUS-->' + obj.lstUS.size());
                    system.debug('obj.objAsset.Product2Id D: ' + obj.objAsset.Product2Id + ' LicenseTypeS:-> ' + obj.licenseType);
                    
                    for (UpgradeSourceWrapper objUSWrapper: obj.lstUS) {
                        system.debug('US objUSWrapper-->' + objUSWrapper);
                        if (getNICtype(objUSWrapper.objUs.UpgradeProduct__r.Product_NIC_Type__c) == obj.objAsset.Product_NIC_Type__c) {
                            lstsource.add(objUSWrapper);
                            system.debug('ee-->' + objUSWrapper.objUS.UpgradeProduct__c);
                            system.debug('ff-->' + obj.objAsset.id);
                            system.debug('gg-->' + objUSWrapper.objUS.UpgradeProduct__r.Name);
                            SelectOption objOption = new SelectOption(objUSWrapper.objUS.UpgradeProduct__c + '_' + obj.objAsset.id, objUSWrapper.objUS.UpgradeProduct__r.Name);
                            lstOptions.add(objOption);
                            objSelectedAsset.upgradeExists = true;
                            objSelectedAsset.maxCapProduct = objUSWrapper.objUS.Source_Product__r.ProductCode;
                            objSelectedAsset.assetFamily = objUSWrapper.objUS.Source_Product__r.Family; //Family
                            system.debug('objSelectedAsset.maxCapProduct-->' + objSelectedAsset.maxCapProduct);
                        }
                    } //End of for
                    system.debug('obj.rubrikEditionInput>>'+obj.rubrikEditionInput);
                    objSelectedAsset.selectedAsset = obj.selectedAsset;
                    objSelectedAsset.selectedSource = obj.selectedSource;
                    objSelectedAsset.options = lstOptions;
                    objSelectedAsset.lstUS = lstsource;
                    objSelectedAsset.selectedGroup = obj.selectedGroup;
                    objSelectedAsset.licenseType = obj.licenseType; //Added to fix population of SaaS & On Prem License Type
                    objSelectedAsset.rubrikEditionInput = obj.rubrikEditionInput;
                    objSelectedAsset.paymentOptionsInput = obj.paymentOptionsInput;
                    objSelectedAsset.supportTypeInput = obj.supportTypeInput;
                    system.debug('LicType: ' + objSelectedAsset.licenseType);
                    
                    if (objSelectedAsset.selectedGroup != null) {
                        selectedAssets.Add(objSelectedAsset);
                    } else {
                        lstBlankGroup.add(objSelectedAsset);
                    }
                    
                    if (obj.selectedAsset) {
                        if (obj.selectedSource != null) {
                            lstIDs.Add(obj.selectedSource);
                        }
                    }
                } //If Check Closed - groupUsed
            }
            else {
                system.debug('obj.rubrikEditionInput????' + obj.rubrikEditionInput);
                //If Check Closed - mapString_String
            }
        } //End of for - lstAssetWrapper
        
        selectedAssets.AddAll(lstBlankGroup);
        selectedAssets.sort();
        System.debug('selectedAssets Final:--> ' + selectedAssets);
        //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
        if (controllerError == false) {
            showAssets = false;
            showUpgrade = true;
        }
    } //Method Closed - saveAssets()
    
    public void CreateUpgradeAsssets() { //Updated the return type from pageReference to void for QLE Page Issue Fix
        List < string > lstIDs = new List < String > ();
        if (!Test.isRunningTest()) {
            if (quoteId == null) {
                quoteId = ApexPages.currentPage().getParameters().get('newid');
            }
        }
        for (AssetWrapper obj: selectedAssets) {
            system.debug('LT1:-> ' + obj.licenseType + ' , RS:-> ' + obj.rubrikEditionInput + ', PO:-> ' + obj.paymentOptionsInput + ' , ST:-> ' + obj.supportTypeInput);
            
            if (obj.selectedSource != null) {
                //lstIDs.Add(obj.selectedSource);
            }
            for (UpgradeSourceWrapper objWrapper: obj.lstUS) {
                if (objWrapper.selectedId != null &&
                    !String.isBlank(objWrapper.selectedId)) {
                        lstIDs.add(objWrapper.selectedId);
                    }
            }
        } //End of for
        List < String > lststring1 = new List < string > ();
        if (selectedoptionsstr != null) {
            System.debug('selectedoptionsstr : -> ' + selectedoptionsstr);
            lststring1 = selectedoptionsstr.split(',');
        }
        String quoteId1 = String.isBlank(quoteId) ? null : String.escapeSingleQuotes(quoteId.escapeHtml4());
        
        System.debug('lststring1 : -> ' + lststring1);
        
        Boolean isSuccess = AddQuoteLines(quoteId1, lststring1, selectedAssets);
        if (isSuccess) {
            String NextPageUrl = saveURL.replace('QUOTEID', quoteId1);
            pageReference nextpage = new pageReference(NextPageUrl);
            //return nextpage; //Removed the return as type is void now
        } else {
            //return null;
        }
    }
    
    public Boolean AddQuoteLines(
        String quoteId,
        List < String > productIds,
        List < AssetWrapper > assetsWrapper
    ) {
        //if(isOldProduct){
        if (isOldCustomUpgradeSourceActive) {
            Map < Id, PricebookEntry > productToPbeMap = new Map < Id, PricebookEntry > ();
            Map < Integer, SBQQ__QuoteLine__c > MapInteger_QLI = New Map < Integer, SBQQ__QuoteLine__c > ();
            //List<string> lstString = new List<string>();
            List < SBQQ__QuoteLine__c > lstQuoteLine = New List < SBQQ__QuoteLine__c > ();
            List < SBQQ__QuoteLine__c > lstQuoteLine2 = New List < SBQQ__QuoteLine__c > ();
            List < String > products = new List < String > ();
            Map < String, string > mapstr_str = New Map < String, String > ();
            Map < String, String > mapasset_edition = new Map < String, String > ();
            Map < String, String > map_AssetIdAssetName = new Map < String, String > (); //Declared by Shaloo for stamping Asset Names on QLI
            Integer qliNumber = 1;
            //query price book entries
            
            map < String, String > mapAssetId_US = new map < String, String > ();
            for (String strID: productIds) {
                List < String > lststring = strID.split('_');
                if (!lststring.IsEmpty()) {
                    
                    mapAssetId_US.put(lststring[1], lststring[0]);
                }
            }
            
            for (AssetWrapper eachWrapper: assetsWrapper) {
                mapasset_edition.put(eachWrapper.objAsset.Id, eachWrapper.objAsset.Rubrik_Suite__c);
                map_AssetIdAssetName.put(eachWrapper.objAsset.Id, eachWrapper.assetSerialName); //Added by Shaloo to populate the Map
            }
            system.debug('map_AssetIdAssetName:->> ' + map_AssetIdAssetName);
            List < SBQQ__Quote__c > lstQuote = [SELECT Id,
                                                SBQQ__SubscriptionTerm__c,
                                                SBQQ__LineItemCount__c,
                                                Eligible_for_RCDM_T__c,
                                                Is_Customer_Fully_Transitioned__c,
                                                Is_Federal_Eligible_Quote__c,
                                                Selective_Account_Eligible_for_RCDM_T__c,
                                                RWD_Deal_Ops_Exception__c,
                                                SBQQ__Type__c,
                                                (Select Id from SBQQ__LineItems__r where SBQQ__ProductCode__c = 'RBK-DATA-MIGRATION'),
                                                SBQQ__PriceBook__c
                                                from SBQQ__Quote__c
                                                where id =: quoteId
                                               ];
            if (!lstQuote.isEmpty()) {
                strPricebookId = lstQuote[0].SBQQ__PriceBook__c;
                qliNumber = (lstQuote[0].SBQQ__LineItemCount__c > 0 ? lstQuote[0].SBQQ__LineItemCount__c : 1).intValue();
            }
            List < SBQQ__ProductOption__c > lstOption = [Select Id,
                                                         Refresh_Default_Option__c,
                                                         SBQQ__ConfiguredSKU__c,
                                                         SBQQ__OptionalSKU__c,
                                                         SBQQ__Type__c,
                                                         SBQQ__Feature__c,
                                                         Refresh_Rubrik_Suite_Availability__c
                                                         FROM SBQQ__ProductOption__c
                                                         WHERE SBQQ__ConfiguredSKU__c IN: mapAssetId_US.values()
                                                         AND Refresh_Default_Option__c = true
                                                         ORDER BY SBQQ__Number__c ASC NULLS LAST
                                                        ];
            
            Integer parCounter = 1;
            List < QLIWrapper > lstWrapper = New List < QLIWrapper > ();
            for (String strSKU: mapAssetId_US.keyset()) {
                QLIWrapper objWrapper = New QLIWrapper();
                objWrapper.productId = mapAssetId_US.get(strSKU);
                objWrapper.strAssetId = strSKU;
                objWrapper.strKey = parCounter;
                if (mapasset_edition.containsKey(strSKU)) {
                    objWrapper.strRubrikEdition = mapasset_edition.get(strSKU);
                }
                //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
                if (map_AssetIdAssetName.containsKey(strSKU)) {
                    objWrapper.subsAssetNames = map_AssetIdAssetName.get(strSKU);
                }
                system.debug('objWrapper.subsAssetNames====' + objWrapper.subsAssetNames);
                //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
                lstWrapper.add(objWrapper);
                products.add(mapAssetId_US.get(strSKU));
                parCounter++;
                for (SBQQ__ProductOption__c objOption: lstOption) {
                    if (mapAssetId_US.get(strSKU) == objOption.SBQQ__ConfiguredSKU__c &&
                        mapasset_edition.containsKey(strSKU) &&
                        objOption.Refresh_Rubrik_Suite_Availability__c.contains(mapasset_edition.get(strSKU))
                       ) {
                           products.add(objOption.SBQQ__OptionalSKU__c);
                           QLIWrapper objWrapper1 = New QLIWrapper();
                           objWrapper1.productId = objOption.SBQQ__OptionalSKU__c;
                           objWrapper1.parentKey = objWrapper.strKey;
                           objWrapper1.option = objOption;
                           objWrapper1.strRubrikEdition = mapasset_edition.get(strSKU);
                           lstWrapper.add(objWrapper1);
                       }
                }
            }
            
            // added condition to add default QLIs if not already in Quote, convert to for if needed in future
            if (!lstQuote.isEmpty()) {
                if (lstQuote[0].SBQQ__LineItems__r.isEmpty()) {
                    
                    QLIWrapper objWrapper = New QLIWrapper();
                    objWrapper.productId = system.Label.MigrationSKU;
                    lstWrapper.add(objWrapper);
                    products.add(system.Label.MigrationSKU);
                }
            }
            
            List < PricebookEntry > pbEntries = [
                SELECT Id,
                Product2Id,
                UnitPrice,
                Product2.Product_Type__c, Product2.Product_Level__c, Product2.Category__c, 
                Product2.Description,
                Product2.SBQQ__SubscriptionTerm__c,
                Product2.SBQQ__SubscriptionType__c,
                Product2.ProductCode,
                product2.SBQQ__SubscriptionPricing__c,
                product2.SBQQ__NonDiscountable__c,
                Product2.SBQQ__DefaultQuantity__c
                ,Product2.Sales_Comp_Category__c
                FROM PricebookEntry
                WHERE Product2Id IN: products AND Pricebook2Id =: strPricebookId
                AND isactive = true
            ];
            
            // create map from product to their cooresponding pricebook entry for the Quote's pricebook
            
            
            for (PricebookEntry pbEntry: pbEntries) {
                
                productToPbeMap.put(pbEntry.Product2Id, pbEntry);
            }
            
            Integer count = 1;
            Map < decimal, SBQQ__QuoteLine__c > mapLines = New Map < decimal, SBQQ__QuoteLine__c > ();
            String quoteId1 = String.isBlank(quoteId) ? null : String.escapeSingleQuotes(quoteId.escapeHtml4());
            for (QLIWrapper objWrapper1: lstWrapper) {
                if (productToPbeMap.containsKey(objWrapper1.productId)) {
                    PricebookEntry pbEntry = productToPbeMap.get(objWrapper1.productId);
                    //system.debug('Pricebookentry -------'+pbEntry);
                    //productToPbeMap.put(pbEntry.Product2Id, pbEntry);
                    SBQQ__QuoteLine__c objLine = New SBQQ__QuoteLine__c();
                    objLine.SBQQ__Number__c = qliNumber++;
                    
                    objLine.SBQQ__PricebookEntryId__c = pbEntry.Id;
                    objLine.SBQQ__Quote__c = quoteId1;
                    objLine.Sales_Comp_Category__c = pbEntry.Product2.Sales_Comp_Category__c;
                    objLine.Product_Type__c = pbEntry.Product2.Product_Type__c; //earlier commented out
                    objLine.Product_Level__c = pbEntry.Product2.Product_Level__c; //Earlier commented out
                    objLine.Category__c = pbEntry.Product2.Category__c; //Earlier commented out
                    objLine.SBQQ__Product__c = pbEntry.Product2Id;
                    objLine.SBQQ__NetPrice__c = pbEntry.UnitPrice;
                    
                    if (pbEntry.Product2.SBQQ__DefaultQuantity__c != null) {
                        objLine.SBQQ__Quantity__c = pbEntry.Product2.SBQQ__DefaultQuantity__c;
                    }else {
                        objLine.SBQQ__Quantity__c = 1;
                    }
                    //objLine.SBQQ__Quantity__c = 1;
                    
                    System.debug('pbEntry.Product2.Product_Type__c: ' + pbEntry.Product2.Product_Type__c);
                    System.debug('ProductType' + objLine.Product_Type__c);
                    //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
                    if (objLine.SBQQ__Product__c == objWrapper1.productId) {
                        objLine.Arroyo_Subscribed_Asset_Name__c = objWrapper1.subsAssetNames; //SubscribedAssetNames__c
                        System.debug('objLine.Arroyo_Subscribed_Asset_Name__c====' + objLine.Arroyo_Subscribed_Asset_Name__c);
                    }
                    objLine.Special_Program__c = 'Refresh';
                    //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
                    
                    if (pbEntry.Product2Id != system.Label.MigrationSKU) {
                        objLine.Support_Type__c = 'Premium'; //Changed by S
                        objLine.Licensing_Model__c = 'Subscription';
                    }
                    objLine.Rubrik_Suite__c = objWrapper1.strRubrikEdition;
                    system.debug('RubrikSuite1 :-> ' + objLine.Rubrik_Suite__c);
                    
                    objLine.Payment_Options__c = 'Prepay';
                    if (objWrapper1.strAssetId != null) {
                        objLine.SBQQ__UpgradedAsset__c = objWrapper1.strAssetId;
                    }
                    
                    quoteLineSubs(objLine,pbEntry,lstquote);
                    objLine.SBQQ__DynamicOptionId__c = objWrapper1.option.SBQQ__Feature__c;
                    objLine.SBQQ__SubscriptionBase__c = 'list';
                    objLine.SBQQ__Description__c = pbEntry.product2.Description;
                    if (objWrapper1.parentKey != NULL) {
                        objLine.ParentQLIndex__c = objWrapper1.parentKey;
                        objLine.SBQQ__OptionType__c = objWrapper1.option.SBQQ__Type__c;
                        objLine.SBQQ__OptionLevel__c = 1;
                        objLine.SBQQ__ProductOption__c = objWrapper1.option.id;
                    } else {
                        objLine.QLIndex__c = objWrapper1.strKey;
                        system.debug('lstQuoteLine:->>>> ' + objLine.SBQQ__Product__c);
                        if (objWrapper1.strKey != null) {
                            objLine.SBQQ__Bundle__c = true;
                        }
                    }
                    //objLine.SBQQ__ConfigurationRequired__c = true;
                    lstQuoteLine.add(objLine);
                    MapInteger_QLI.put(count, objLine);
                }
            }
            
            SBQQ.TriggerControl.disable();
            Database.SaveResult[] results = Database.insert(lstQuoteLine);
            //insert lstQuoteLine;
            system.debug('lstQuoteLine:->>>> ' + lstQuoteLine + ' , SizeQLI:>> ' + lstQuoteLine.size());
            for (SBQQ__QuoteLine__c objLine: lstQuoteLine) {
                system.debug('objLine.QLIndex__:->>>> ' + objLine.QLIndex__c);
                
                if (objLine.QLIndex__c != null) {
                    mapLines.put(Integer.valueOf(objLine.QLIndex__c), objLine);
                }
            }
            system.debug('mapLinesA:->>>> ' + mapLines + ' , mapLinesSizeQLIA:>> ' + lstQuoteLine.size());
            
            for (SBQQ__QuoteLine__c objLine: lstQuoteLine) {
                system.debug('objLine.ParentQLIndex__cA:->>>> ' + objLine.ParentQLIndex__c);
                if (objLine.ParentQLIndex__c != null &&
                    mapLines.containsKey(objLine.ParentQLIndex__c)) {
                        objLine.SBQQ__RequiredBy__c = mapLines.get(objLine.ParentQLIndex__c).id;
                    }
            }
            Update lstQuoteLine;
            List < SBQQ__QuoteLineGroup__c > qlgroup = [SELECT Id, SBQQ__Quote__c, Name FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: quoteId
                                                        AND Name != 'Renewal Quote' AND Name != 'Disposition Quote' 
                                                        //Name = 'Expansion Quote'
                                                       ];
            if (!qlgroup.IsEmpty()) {
                for (SBQQ__QuoteLineGroup__c quoteGroup: qlgroup) {
                    if (quoteGroup.Name != System.Label.Arry_renewal_Group && quoteGroup.Name != System.Label.Arry_Disposition_Group
                        //quoteGroup.Name == 'Expansion Quote'
                       ) {
                           updateGroupOnQuoteLineItems(quoteId);
                       }
                }
            }
            //updateGroupOnQuoteLineItems(quoteId);
            SBQQ.TriggerControl.enable();
            return true;
        }
        
        //NewProduct logic
        else {
            /**
* Description : RWD-439 : Go Refresh | Configure Mapping | HW SKU Mapping
* Created By  : Jayaraman Iyer
**/
            //Start
            Map < String, Asset > assetIdVsAssetWrapperMap = new Map < String, Asset > ();
            List < String > assetsWrapperRubrikEditionList = new List < String > ();
            List < String > assetsWrapperRubrikEditionListOnPrem = new List < String > ();
            
            List < String > assetsWrapperSupportTypeList = new List < String > ();
            List < String > assetsWrapperPaymandOptionsList = new List < String > ();
            Map < Id, String > assetIdVsProductCombinationMap = new Map < Id, String > ();
            
            //RWD-952
            Map < ID, String > assetIdVsPayOptMap = new Map < ID, String > ();
            Map < String, String > assetToUsableCapacityMap = new Map < String, String > (); // [Rahul Agarwal] : RWD - 1209 : GoRefresh : Assign SAAS Cloud based on capacity
            Map < String, String > map_AssetIdAssetName = new Map < String, String > (); //Declared by Shaloo

    Map<String,String> rubrikSuite = new Map<String,String>();
rubrikSuite.put('Foundation','Foundation Edition');
rubrikSuite.put('Business','Business Edition');
rubrikSuite.put('Enterprise','Enterprise Edition');
rubrikSuite.put('Complete Pro','Complete Edition Pro');
rubrikSuite.put('Complete','Complete Edition');
rubrikSuite.put('Complete Elite','Complete Edition Elite');
rubrikSuite.put('Proactive','Proactive Edition');

Map<String,String> licenseTypeToRubrikSuite = new Map<String,String>();
licenseTypeToRubrikSuite.put('Foundation','%Foundation Edition%');
licenseTypeToRubrikSuite.put('Business','%Business Edition%');
licenseTypeToRubrikSuite.put('Enterprise','%Enterprise Edition%');

            for (AssetWrapper assetWrapperObj: assetsWrapper) {
                system.debug('LT2:-> ' + assetWrapperObj.licenseType + ' , RS2:-> ' + assetWrapperObj.rubrikEditionInput + ' , PO2:-> ' + assetWrapperObj.paymentOptionsInput + ' , ST2:-> ' + assetWrapperObj.supportTypeInput);
                system.debug('checked?:-> ' + assetWrapperObj.selectedAsset);
                //assetIdVsAssetWrapperMap.put(assetWrapperObj.objAsset.Id , new List<Asset>{assetWrapperObj.objAsset});
                assetIdVsAssetWrapperMap.put(assetWrapperObj.objAsset.Id, assetWrapperObj.objAsset);
                map_AssetIdAssetName.put(assetWrapperObj.objAsset.Id, assetWrapperObj.assetSerialName); //Added by Shaloo to populate the Map
                system.debug('map_AssetIdAssetName:->> ' + map_AssetIdAssetName);
                // [Rahul Agarwal] : RWD - 1209 : GoRefresh : Assign SAAS Cloud based on capacity
                // Start here
                if (assetWrapperObj.objAsset.Product2.Usable_Capacity__c > 30) {
                    assetToUsableCapacityMap.put(assetWrapperObj.objAsset.Id, '60');
                } else {
                    assetToUsableCapacityMap.put(assetWrapperObj.objAsset.Id, '30');
                }
                //End Here
                
                assetWrapperObj.objAsset.Rubrik_Suite__c = assetWrapperObj.rubrikEditionInput;
                assetWrapperObj.objAsset.Payment_Options__c = assetWrapperObj.paymentOptionsInput;
                assetWrapperObj.objAsset.Support_Type__c = assetWrapperObj.supportTypeInput;
                
                system.debug('SerialNumber: ' + assetWrapperObj.objAsset.SerialNumber + ' , RubrikSuite: ' + assetWrapperObj.objAsset.Rubrik_Suite__c);
                if (assetWrapperObj.objAsset.Rubrik_Suite__c != '' && assetWrapperObj.objAsset.Rubrik_Suite__c != null) {
                    system.debug('assetWrapperObj.objAsset.Id:->> ' + assetWrapperObj.objAsset.SerialNumber);

    if(rubrikSuite.containsKey(assetWrapperObj.objAsset.Rubrik_Suite__c)){
    assetsWrapperRubrikEditionList.add(rubrikSuite.get(assetWrapperObj.objAsset.Rubrik_Suite__c));
    
    if (assetWrapperObj.licenseType == 'On Prem' && licenseTypeToRubrikSuite.containsKey(assetWrapperObj.objAsset.Rubrik_Suite__c)) {
                            assetsWrapperRubrikEditionListOnPrem.add(licenseTypeToRubrikSuite.get(assetWrapperObj.objAsset.Rubrik_Suite__c));
                        }
                assetIdVsProductCombinationMap.put(assetWrapperObj.objAsset.Id, assetWrapperObj.licenseType + ':' + rubrikSuite.get(assetWrapperObj.objAsset.Rubrik_Suite__c)+ ':' + assetWrapperObj.objAsset.Payment_Options__c + ':' + assetWrapperObj.objAsset.Support_Type__c);
}
                    //End Here
                }
                //RWD-952
                
                
                if (assetWrapperObj.objAsset.Payment_Options__c != null) {
                    assetIdVsPayOptMap.put(assetWrapperObj.objAsset.Id, assetWrapperObj.objAsset.Payment_Options__c);
                }
                
                if (assetWrapperObj.objAsset.Payment_Options__c != null) {
                    assetsWrapperPaymandOptionsList.add(assetWrapperObj.objAsset.Payment_Options__c);
                }
                
                
                if (assetWrapperObj.objAsset.Support_Type__c != null) {
                    assetsWrapperSupportTypeList.add(assetWrapperObj.objAsset.Support_Type__c);
                }
            }
            
            //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
            /*system.debug('map_AssetIdAssetName Values:--> ' + map_AssetIdAssetName.keySet());
Map<String, String> mapTest = new Map<String, String>();
List<Asset> assetRecordList = new List<Asset>();
if(!map_AssetIdAssetName.IsEmpty()){
assetRecordList = [SELECT Id, Name, SerialNumber, ProductCode, Status, UsageEndDate FROM Asset 
WHERE Id IN: map_AssetIdAssetName.keySet()];
system.debug('assetRecordList :--> ' + assetRecordList);
*/
            //Set<Id> assetRecIDs = new Set<Id>();
            /*for(QLIWrapper objWrapper1 : lstWrapper){
assetRecList = [SELECT Id, Name, SerialNumber, ProductCode, Status, UsageEndDate FROM Asset 
WHERE SerialNumber IN: map_AssetIdAssetName.keyset()];
mapTest.put(assetRecList.Name);
system.debug('assetRecList :--> ' + assetRecList);
}*/
            /*for(Asset assets: assetRecordList){
mapTest.put(map_AssetIdAssetName.get(assets.Id), assets.Id);
}
system.debug('mapTest :--> ' + mapTest);
}*/
            //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
            
            Map < Id, String > assetIdVsEditionProductsMap = new Map < Id, String > ();
            
            system.debug('assetIdVsProductCombinationMap Final :-> ' + assetIdVsProductCombinationMap);
            system.debug('assetsWrapperRubrikEditionList :-> ' + assetsWrapperRubrikEditionList);
            system.debug('assetsWrapperRubrikEditionListOnPrem :-> ' + assetsWrapperRubrikEditionListOnPrem);
            system.debug('assetsWrapperPaymandOptionsList :-> ' + assetsWrapperPaymandOptionsList);
            system.debug('assetsWrapperSupportTypeList :-> ' + assetsWrapperSupportTypeList);
            
            if (!assetsWrapperRubrikEditionList.isEmpty() && !assetsWrapperPaymandOptionsList.isEmpty() && !assetsWrapperSupportTypeList.isEmpty()) {
                List < Product2 > editionProductDataList = [SELECT Id, Name, ProductCode, Product_Type__c, RWD_Rubrik_Edition_Offerings__c //Rubrik Edition
                                                            , On_Prem_Rubrik_Edition_Offerings__c, Product_Payment_Option__c //Paymand Options
                                                            , Support_Type__c //Support Type
                                                            FROM Product2
                                                            WHERE(RWD_Rubrik_Edition_Offerings__c IN: assetsWrapperRubrikEditionList OR On_Prem_Rubrik_Edition_Offerings__c LIKE: assetsWrapperRubrikEditionListOnPrem)
                                                            AND Product_Payment_Option__c IN: assetsWrapperPaymandOptionsList
                                                            AND Support_Type__c IN: assetsWrapperSupportTypeList
                                                           ];
                //Added Product_Type__c & On_Prem_Rubrik_Edition_Offerings__c in the query with additional where clause On_Prem_Rubrik_Edition_Offerings__c LIKE: assetsWrapperRubrikEditionListOnPrem
                
                system.debug('editionProductDataList :-> ' + editionProductDataList);
                system.debug('editionProductDataList Size:-> ' + editionProductDataList.size());
                system.debug('assetIdVsProductCombinationMap.keySet():-> ' + assetIdVsProductCombinationMap.keySet());
                
                //if(!editionProductDataList.isEmpty() && !isOldProduct) {
                String licenseTypeval = ''; //OnPrem Fix
                String productConbination = ''; //OnPrem Fix
                
                if (!editionProductDataList.isEmpty() && !isOldCustomUpgradeSourceActive) {
                    for (String assetId: assetIdVsProductCombinationMap.keySet()) {
                        
                        for (Product2 productObj: editionProductDataList) {
                            
                            if (productObj.On_Prem_Rubrik_Edition_Offerings__c != null) { //OnPrem Fix
                                system.debug('ENTER FOR ON PREM :-> ');
                                licenseTypeval = 'On Prem';
                                
                                productConbination = licenseTypeval + ':' + productObj.Product_Type__c + ':' + productObj.Product_Payment_Option__c + ':' + productObj.Support_Type__c;
                            } else if (productObj.RWD_Rubrik_Edition_Offerings__c != null) { //OnPrem Fix
                                system.debug('ENTER FOR SAAS :-> ');
                                licenseTypeval = 'SaaS';
                                productConbination = licenseTypeval + ':' + productObj.RWD_Rubrik_Edition_Offerings__c + ':' + productObj.Product_Payment_Option__c + ':' + productObj.Support_Type__c;
                            }
                            //String productConbination = licenseTypeval + ':' + productObj.RWD_Rubrik_Edition_Offerings__c+':'+productObj.Product_Payment_Option__c+':'+productObj.Support_Type__c;
                            
                            system.debug('productConbination :-> ' + productConbination);
                            system.debug('assetIdVsProductCombinationMap :-> ' + assetIdVsProductCombinationMap);
                            system.debug('GetAssetId :-> ' + assetIdVsProductCombinationMap.get(assetId));
                            system.debug('licenseTypeval1 :-> ' + licenseTypeval);
                            
                            if (productConbination.equalsIgnoreCase(assetIdVsProductCombinationMap.get(assetId))) {
                                system.debug('Here :-> ' + licenseTypeval);
                                if (licenseTypeval == 'SaaS') { //OnPrem Fix
                                    system.debug('Enter for Hybrid Lines ' + licenseTypeval);
                                    // [Rahul Agarwal] : RWD - 1209 : GoRefresh : Assign SAAS Cloud based on capacity
                                    if (productObj.RWD_Rubrik_Edition_Offerings__c.contains('Complete') && productObj.productcode.contains(assetToUsableCapacityMap.get(assetId))) {
                                        system.debug('CodeA ' + productObj.productcode);
                                        assetIdVsEditionProductsMap.put(assetId, productObj.Id);
                                    } else if (!productObj.RWD_Rubrik_Edition_Offerings__c.contains('Complete')) {
                                        system.debug('CodeB ' + productObj.productcode);
                                        assetIdVsEditionProductsMap.put(assetId, productObj.Id);
                                    }
                                } else if (licenseTypeval == 'On Prem') { //OnPrem Fix
                                    system.debug('Enter for On Prem Lines ' + licenseTypeval);
                                    assetIdVsEditionProductsMap.put(assetId, productObj.Id);
                                }
                                //}
                                
                            }
                            
                            
                        }
                    }
                }
            }
            system.debug('assetIdVsEditionProductsMap :-> ' + assetIdVsEditionProductsMap);
            //End
            Map < Id, PricebookEntry > productToPbeMap = new Map < Id, PricebookEntry > ();
            Map < Integer, SBQQ__QuoteLine__c > MapInteger_QLI = New Map < Integer, SBQQ__QuoteLine__c > ();
            List < SBQQ__QuoteLine__c > lstQuoteLine = New List < SBQQ__QuoteLine__c > ();
            List < SBQQ__QuoteLine__c > lstQuoteLine2 = New List < SBQQ__QuoteLine__c > ();
            List < String > products = new List < String > ();
            Map < String, string > mapstr_str = New Map < String, String > ();
            Integer qliNumber = 1;
            
            map < String, String > mapAssetId_US = new map < String, String > ();
            
            System.debug('productIds :-> ' + productIds); //getting this products from method call parameters
            for (String strID: productIds) {
                List < String > lststring = strID.split('_');
                System.debug('lststring :-> ' + lststring);
                if (!lststring.IsEmpty() && (lststring.size() > 1)) {
                    mapAssetId_US.put(lststring[1], lststring[0]);
                }
            }
            System.debug('mapAssetId_US :-> ' + mapAssetId_US);
            
            List < SBQQ__Quote__c > lstQuote = [SELECT Id,
                                                SBQQ__SubscriptionTerm__c,
                                                SBQQ__LineItemCount__c,
                                                Eligible_for_RCDM_T__c,
                                                Is_Customer_Fully_Transitioned__c,
                                                Is_Federal_Eligible_Quote__c,
                                                Selective_Account_Eligible_for_RCDM_T__c,
                                                RWD_Deal_Ops_Exception__c,
                                                SBQQ__Type__c,
                                                SBQQ__Status__c,
                                                RCDMT_EOL_Date__c,
                                                CreatedDate,
                                                Todays_Date__c,
                                                (Select Id from SBQQ__LineItems__r where SBQQ__ProductCode__c IN('RBK-DATA-MIGRATION', 'RA-DATA-MIGRATION')),
                                                SBQQ__PriceBook__c
                                                from SBQQ__Quote__c
                                                where id =: quoteId
                                               ];
            
            if (!lstQuote.isEmpty()) {
                strPricebookId = lstQuote[0].SBQQ__PriceBook__c;
                qliNumber = (lstQuote[0].SBQQ__LineItemCount__c > 0 ? lstQuote[0].SBQQ__LineItemCount__c : 1).intValue();
            }
            
            //This is use to fetch ProductFeature for HW SKUs(like "RH-6412S-02") base on his Parent like "RS-FE-GO-PE-PP"
            //Start
            List < SBQQ__ProductFeature__c > productFeatureList = new List < SBQQ__ProductFeature__c > ();
            if (!assetIdVsEditionProductsMap.isEmpty()) {
                
                productFeatureList = [Select Id,
                                      Name,
                                      SBQQ__ConfiguredSKU__c
                                      FROM SBQQ__ProductFeature__c
                                      WHERE SBQQ__ConfiguredSKU__c IN: assetIdVsEditionProductsMap.values() AND Name =: 'R6000 Series'
                                     ];
            }
            
            system.debug('productFeatureList:-> ' + productFeatureList + ' , Size: ' + productFeatureList.size());
            
            Map < String, String > configuredSKUIdVsProductFeatureIdMap = new Map < String, String > ();
            if (!productFeatureList.isEmpty()) {
                
                for (SBQQ__ProductFeature__c productFeatureObj: productFeatureList) {
                    
                    configuredSKUIdVsProductFeatureIdMap.put(productFeatureObj.SBQQ__ConfiguredSKU__c, productFeatureObj.Id);
                }
            }
            system.debug('configuredSKUIdVsProductFeatureIdMap:-> ' + configuredSKUIdVsProductFeatureIdMap + ' , Size1: ' + configuredSKUIdVsProductFeatureIdMap.size());
            //End
            
            Set < String > sBQQConfiguredSKUSet = new Set < String > ();
            sBQQConfiguredSKUSet.addAll(mapAssetId_US.values());
            sBQQConfiguredSKUSet.addAll(assetIdVsEditionProductsMap.values());
            
            system.debug('sBQQConfiguredSKUSet:-> ' + sBQQConfiguredSKUSet + ' , Size2: ' + sBQQConfiguredSKUSet.size());
            
            if(rcdmDatesObj == null){
                rcdmDatesObj = [SELECT Id, Order_Sub_Type__c, Order_Type__c, IT_Product_Type__c, Licensing_Type__c, Subscription_Term__c, DeveloperName, Approval_Category__c, List_Price__c, Product_Level__c, Subscription_Pricing__c, Subscription_Type__c, EndDate_Day__c, EndDate_Month__c, EndDate_Year__c,StartDate_Day__c, StartDate_Month__c,StartDate_Year__c,Special_Price__c, Description__c FROM X0_RCDM_Dates__mdt WHERE DeveloperName = 'RCDM_Dates' LIMIT 1];
                System.debug('>> ORCDM 3 <<');
            }
            
            if(rcdmDatesObj != null && rcdmDatesObj.EndDate_Year__c != null && rcdmDatesObj.EndDate_Month__c != null && lstQuote[0] != null &&  lstQuote[0].RCDMT_EOL_Date__c!= null) {
                quotRangeStart = Date.newInstance(Integer.valueOF(rcdmDatesObj.StartDate_Year__c), Integer.valueOF(rcdmDatesObj.StartDate_Month__c), Integer.valueOF(rcdmDatesObj.StartDate_Day__c));
               // quotRangeEnd = Date.newInstance(Integer.valueOF(rcdmDatesObj.EndDate_Year__c), Integer.valueOF(rcdmDatesObj.EndDate_Month__c), Integer.valueOF(rcdmDatesObj.EndDate_Day__c));
               quotRangeEnd = lstQuote[0].RCDMT_EOL_Date__c;// added for CPQ22-3874 
                
                if((lstQuote[0].SBQQ__Type__c == 'Quote' || lstQuote[0].SBQQ__Type__c == 'Renewal+Expansion') && lstQuote[0].SBQQ__Status__c == 'Draft' && lstQuote[0].Eligible_for_RCDM_T__c == true && lstQuote[0].Is_Customer_Fully_Transitioned__c == false &&
                (lstQuote[0].Selective_Account_Eligible_for_RCDM_T__c == true || (lstQuote[0].Selective_Account_Eligible_for_RCDM_T__c == false && lstQuote[0].RWD_Deal_Ops_Exception__c != null && lstQuote[0].RWD_Deal_Ops_Exception__c.contains('Ad-Hoc addition of OnPrem $0 RCDM'))) && lstQuote[0].Todays_Date__c < quotRangeEnd && lstQuote[0].Todays_Date__c >= quotRangeStart && (lstQuote[0].RWD_Deal_Ops_Exception__c == null || lstQuote[0].RWD_Deal_Ops_Exception__c == '') || (lstQuote[0].RWD_Deal_Ops_Exception__c != null && !lstQuote[0].RWD_Deal_Ops_Exception__c.contains('Allow removal of 0$ On Prem SKU'))
                  ) {
                      rcdmValid = true;
                      system.debug('? rcdmValid : '+rcdmValid);
                  }
            }  
            
            system.debug('> rcdmValid = true: '+rcdmValid);
            List < SBQQ__ProductOption__c > lstOption = new List < SBQQ__ProductOption__c > ();
            if (!mapAssetId_US.isEmpty() && rcdmValid == true) {
                system.debug('> rcdmValid = true: '+rcdmValid);
                lstOption = [Select Id,
                             Name,
                             Refresh_Default_Option__c,
                             SBQQ__ConfiguredSKU__c,
                             SBQQ__OptionalSKU__c,
                             SBQQ__OptionalSKU__r.Support_Type__c,
                             SBQQ__Type__c,
                             SBQQ__Feature__c,
                             Support_Type__c, //RWD-439 : Go Refresh | Configure Mapping | HW SKU Mapping (Jayaraman Iyer)
                             Category_Name__c //RWD-439 : Go Refresh | Configure Mapping | HW SKU Mapping (Jayaraman Iyer)
                             FROM SBQQ__ProductOption__c
                             WHERE SBQQ__ConfiguredSKU__c IN: sBQQConfiguredSKUSet
                             AND Refresh_Default_Option__c = true ORDER BY SBQQ__Number__c ASC NULLS LAST
                            ];
            } else if (!mapAssetId_US.isEmpty() && rcdmValid == false) {
                system.debug('> rcdmValid = false: '+rcdmValid);
                lstOption = [Select Id,
                             Name,
                             Refresh_Default_Option__c,
                             SBQQ__ConfiguredSKU__c,
                             SBQQ__OptionalSKU__c,
                             SBQQ__OptionalSKU__r.Support_Type__c,
                             SBQQ__OptionalSKU__r.X0__c,
                             SBQQ__Type__c,
                             SBQQ__Feature__c,
                             Support_Type__c, //RWD-439 : Go Refresh | Configure Mapping | HW SKU Mapping (Jayaraman Iyer)
                             Category_Name__c //RWD-439 : Go Refresh | Configure Mapping | HW SKU Mapping (Jayaraman Iyer)
                             FROM SBQQ__ProductOption__c
                             WHERE SBQQ__ConfiguredSKU__c IN: sBQQConfiguredSKUSet
                             AND Refresh_Default_Option__c = true AND SBQQ__OptionalSKU__r.X0__c = false ORDER BY SBQQ__Number__c ASC NULLS LAST
                            ];
            }
            system.debug('lstOption QLI:-> ' + lstOption);
            
            Integer parCounter = 1;
            List < QLIWrapper > lstWrapper = New List < QLIWrapper > ();
            Map < Id, Integer > assetIdVsParCounterMap = new Map < Id, Integer > ();
            
            /**
* Description : RWD-439 : Go Refresh | Configure Mapping | HW SKU Mapping
* Created By  : Jayaraman Iyer
**/
            //Start
            //Parent
            Map < String, QLIWrapper > assetIdVsQLIWrapperObjMap = new Map < String, QLIWrapper > ();
            //Parent Child (Product Option)
            Map < String, QLIWrapper > assetIdVsQLIWrapperObjChildMap = new Map < String, QLIWrapper > ();
            
            system.debug('assetIdVsEditionProductsMapVal: ' + assetIdVsEditionProductsMap + ' , sizeeee:- ' + assetIdVsEditionProductsMap.size());
            for (String assetId: assetIdVsEditionProductsMap.keySet()) {
                /*
This is for adding new QuoteLine base on Picklist values selection on Go Refresh fist page i.e.
Rubrik Edition, Paymand Options and Support Type like 'RS-FE-GO-PE-PP'
*/
                QLIWrapper objWrapper = new QLIWrapper();
                objWrapper.productId = assetIdVsEditionProductsMap.get(assetId);
                objWrapper.strAssetId = assetId;
                objWrapper.strKey = parCounter;
                //objWrapper.lineNumber = parCounter;
                system.debug('0 :->' + objWrapper.productId);
                
                lstWrapper.add(objWrapper);
                products.add(assetIdVsEditionProductsMap.get(assetId));
                assetIdVsParCounterMap.put(assetId, parCounter);
                assetIdVsQLIWrapperObjMap.put(assetId, objWrapper);
                
                system.debug('MapassetIdVsParCounterMap: ' + assetIdVsParCounterMap);
                
                //Start
                //Code for Populating Child lines(Product Option) of main parents like 'RS-FE-GO-PE-PP'
                for (SBQQ__ProductOption__c objOption: lstOption) {
                    
                    if (assetIdVsEditionProductsMap.get(assetId) == objOption.SBQQ__ConfiguredSKU__c) {
                        
                        products.add(objOption.SBQQ__OptionalSKU__c);
                        QLIWrapper objWrapper1 = New QLIWrapper();
                        objWrapper1.productId = objOption.SBQQ__OptionalSKU__c;
                        system.debug('A1A :->' + objWrapper1.productId);
                        
                        if (objWrapper != null) {
                            objWrapper1.parentKey = objWrapper.strKey;
                        }
                        system.debug('ParentKey: ' + objWrapper1.parentKey);
                        objWrapper1.option = objOption;
                        
                        /**
* Description : RWD-925: Update logic | Populate the Dynamic Option Id
* Created By  : Jayaraman Iyer
**/
                        
                        if (String.isNotBlank(objOption.SBQQ__OptionalSKU__c) && String.isNotBlank(objOption.SBQQ__Feature__c)) {
                            objWrapper1.dynamicOptionID = objOption.SBQQ__Feature__c + ':' + objOption.SBQQ__OptionalSKU__c;
                        } else if (String.isNotBlank(objOption.SBQQ__Feature__c)) {
                            objWrapper1.dynamicOptionID = objOption.SBQQ__Feature__c;
                        }
                        assetIdVsQLIWrapperObjChildMap.put(assetId, objWrapper1);
                        
                        lstWrapper.add(objWrapper1);
                    }
                }
                //End
                parCounter++;
            }
            Integer lineCounter = qliNumber == null ? 0 : qliNumber;
            
            for (String strSKU: mapAssetId_US.keyset()) {
                
                QLIWrapper objWrapper = New QLIWrapper();
                objWrapper.productId = mapAssetId_US.get(strSKU);
                system.debug('2:->' + objWrapper.productId);
                
                system.debug('assetIdVsParCounterMap:->' + assetIdVsParCounterMap + ' , getVal: ' + assetIdVsParCounterMap.get(strSKU));
                system.debug('parCounter :->' + parCounter);
                system.debug('strSKU :->' + strSKU);
                
                objWrapper.strAssetId = strSKU;
                objWrapper.strKey = parCounter;
                objWrapper.parentKey = assetIdVsParCounterMap.get(strSKU);
                system.debug('ProdWrapID: ' + objWrapper.productId + ' , parentKey :-> ' + objWrapper.parentKey);
                
                //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
                if (map_AssetIdAssetName.containsKey(strSKU)) {
                    objWrapper.subsAssetNames = map_AssetIdAssetName.get(strSKU);
                }
                System.debug('objWrapper.subsAssetNames====' + objWrapper.subsAssetNames);
                //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
                
                /**
* Description : RWD-925: Update logic | Populate the Dynamic Option Id
* Created By  : Jayaraman Iyer
**/
                String hWSKUsParentId = assetIdVsEditionProductsMap.containsKey(strSKU) ? assetIdVsEditionProductsMap.get(strSKU) : null;
                if (String.isNotBlank(hWSKUsParentId)) {
                    
                    String sBQQConfiguredSKU = mapAssetId_US.containsKey(strSKU) ? mapAssetId_US.get(strSKU) : null;
                    String sBQQFeature = configuredSKUIdVsProductFeatureIdMap.containsKey(hWSKUsParentId) ? configuredSKUIdVsProductFeatureIdMap.get(hWSKUsParentId) : null;
                    
                    
                    if (String.isNotBlank(sBQQConfiguredSKU) && String.isNotBlank(sBQQFeature)) {
                        
                        objWrapper.dynamicOptionID = sBQQFeature + ':' + sBQQConfiguredSKU;
                    } else if (String.isNotBlank(sBQQFeature)) {
                        
                        objWrapper.dynamicOptionID = sBQQFeature;
                    }
                }
                
                /**
* Description : RWD-439: Go Refresh | Configure Attributes |  Logic to populate the QLI Number field
* Created By  : Jayaraman Iyer
**/
                //Parent
                QLIWrapper objWrapperParent = assetIdVsQLIWrapperObjMap.containsKey(strSKU) ? assetIdVsQLIWrapperObjMap.get(strSKU) : null;
                system.debug('objWrapperParent:-> ' + objWrapperParent);
                if (objWrapperParent == null) {
                    
                } else {
                    
                    objWrapperParent.lineNumber = ++lineCounter;
                }
                
                //Child
                QLIWrapper objWrapperChild = assetIdVsQLIWrapperObjChildMap.containsKey(strSKU) ? assetIdVsQLIWrapperObjChildMap.get(strSKU) : null;
                if (objWrapperChild == null) {
                    
                } else {
                    
                    objWrapperChild.lineNumber = ++lineCounter;
                }
                
                if (assetIdVsParCounterMap.containsKey(strSKU)) {
                    
                    objWrapper.lineNumber = ++lineCounter;
                }
                
                lstWrapper.add(objWrapper);
                products.add(mapAssetId_US.get(strSKU));
                
                System.debug('products--->' + products);
                //parCounter++;
                
                for (SBQQ__ProductOption__c objOption: lstOption) {
                    
                    QLIWrapper objWrapper1 = New QLIWrapper();
                    
                    if (mapAssetId_US.get(strSKU) == objOption.SBQQ__ConfiguredSKU__c) {
                        
                        if (assetsWrapperSupportTypeList.contains(objOption.Support_Type__c) &&
                            (objOption.Category_Name__c).equalsIgnoreCase('Support') &&
                            (assetIdVsAssetWrapperMap.get(strSKU).Support_Type__c == objOption.SBQQ__OptionalSKU__r.Support_Type__c)
                           ) {
                               
                               products.add(objOption.SBQQ__OptionalSKU__c);
                               System.debug('productsA--->' + products);
                               
                               objWrapper1.productId = objOption.SBQQ__OptionalSKU__c;
                               system.debug('3 :->' + objWrapper1.productId);
                               
                               objWrapper1.parentKey = objWrapper.strKey;
                               objWrapper1.option = objOption;
                               
                               /**
* Description : RWD-925: Update logic | Populate the Dynamic Option Id
* Created By  : Jayaraman Iyer
**/
                               if (String.isNotBlank(objOption.SBQQ__OptionalSKU__c) && String.isNotBlank(objOption.SBQQ__Feature__c)) {
                                   
                                   objWrapper1.dynamicOptionID = objOption.SBQQ__Feature__c + ':' + objOption.SBQQ__OptionalSKU__c;
                               } else if (String.isNotBlank(objOption.SBQQ__Feature__c)) {
                                   
                                   objWrapper1.dynamicOptionID = objOption.SBQQ__Feature__c;
                               }
                               objWrapper1.lineNumber = ++lineCounter;
                               lstWrapper.add(objWrapper1);
                           } else if (objOption.Category_Name__c != 'Support') {
                               
                               products.add(objOption.SBQQ__OptionalSKU__c);
                               objWrapper1.productId = objOption.SBQQ__OptionalSKU__c;
                               system.debug('4 :->' + objWrapper1.productId);
                               
                               objWrapper1.parentKey = objWrapper.strKey;
                               system.debug('Pkey1:-> ' + objWrapper1.parentKey);
                               objWrapper1.option = objOption;
                               
                               /**
* Description : RWD-925: Update logic | Populate the Dynamic Option Id
* Created By  : Jayaraman Iyer
**/
                               if (String.isNotBlank(objOption.SBQQ__OptionalSKU__c) && String.isNotBlank(objOption.SBQQ__Feature__c)) {
                                   
                                   objWrapper1.dynamicOptionID = objOption.SBQQ__Feature__c + ':' + objOption.SBQQ__OptionalSKU__c;
                               } else if (String.isNotBlank(objOption.SBQQ__Feature__c)) {
                                   
                                   objWrapper1.dynamicOptionID = objOption.SBQQ__Feature__c;
                               }
                               objWrapper1.lineNumber = ++lineCounter;
                               lstWrapper.add(objWrapper1);
                           }
                    }
                }
                parCounter++;
            }
            
            // added condition to add default QLIs if not already in Quote, convert to for if needed in future
            if (!lstQuote.isEmpty()) {
                
                if (lstQuote[0].SBQQ__LineItems__r.isEmpty()) {
                    
                    
                    /**
* Description : RWD-443 : Go Refresh | Refresh HWs | Product Rules
* Created By  : ST
**/
                    //Start
                    System.debug('mapAssetId_US.values() QLI:==> ' + mapAssetId_US.values());
                    Map < string, string > migrationProductMap = new Map < string, string > ();
                    List < Product2 > migrationProductsList = [SELECT ID, ProductCode, Product_Level__c FROM Product2 WHERE ProductCode IN('RBK-DATA-MIGRATION', 'RA-DATA-MIGRATION') OR Id =: mapAssetId_US.values()];
                    
                    System.debug('migrationProductsList QLI:==> ' + migrationProductsList);
                    
                    for (Product2 product: migrationProductsList) {
                        if (product.ProductCode == 'RBK-DATA-MIGRATION' || product.ProductCode == 'RA-DATA-MIGRATION') {
                            migrationProductMap.put(product.ProductCode, product.Id);
                        }
                    }
                    
                    if (migrationProductsList.size() > 0) {
                        
                        Boolean isRbkDataMigrationEntryAdded = false;
                        Boolean isRaDataMigrationEntryAdded = false;
                        for (Product2 product: migrationProductsList) {
                            if (product.ProductCode != 'RBK-DATA-MIGRATION' && product.ProductCode != 'RA-DATA-MIGRATION') {
                                if (string.isNotBlank(product.Product_Level__c) && !isRaDataMigrationEntryAdded) {
                                    QLIWrapper objWrapper = New QLIWrapper();
                                    objWrapper.lineNumber = ++lineCounter;
                                    objWrapper.productId = migrationProductMap.get('RA-DATA-MIGRATION');
                                    lstWrapper.add(objWrapper);
                                    products.add(migrationProductMap.get('RA-DATA-MIGRATION'));
                                    isRaDataMigrationEntryAdded = true;
                                } else if (string.isBlank(product.Product_Level__c) && !isRbkDataMigrationEntryAdded) {
                                    QLIWrapper objWrapper = New QLIWrapper();
                                    objWrapper.lineNumber = ++lineCounter;
                                    objWrapper.productId = migrationProductMap.get('RBK-DATA-MIGRATION');
                                    lstWrapper.add(objWrapper);
                                    products.add(migrationProductMap.get('RBK-DATA-MIGRATION'));
                                    isRbkDataMigrationEntryAdded = true;
                                }
                            }
                        }
                    }
                    //End
                }
            }
            
            system.debug('productsval: ' + products);
            system.debug('productsval Size: ' + products.size());
            List < PricebookEntry > pbEntries = [
                SELECT Id,
                Product2Id,
                UnitPrice,
                Product2.Product_Type__c, Product2.Product_Level__c, Product2.Category__c, 
                Product2.Description,
                Product2.SBQQ__SubscriptionTerm__c,
                Product2.SBQQ__SubscriptionType__c,
                Product2.ProductCode,
                product2.SBQQ__SubscriptionPricing__c,
                product2.SBQQ__NonDiscountable__c,
                Product2.SBQQ__DefaultQuantity__c
                ,Product2.Sales_Comp_Category__c
                FROM PricebookEntry
                WHERE Product2Id IN: products AND Pricebook2Id =: strPricebookId
                AND isactive = true
            ];
            // create map from product to their cooresponding pricebook entry for the Quote's pricebook
            
            for (PricebookEntry pbEntry: pbEntries) {
                productToPbeMap.put(pbEntry.Product2Id, pbEntry);
            }
            System.debug('productToPbeMap QLI:==> ' + productToPbeMap);
            Integer count = 1;
            Map < decimal, SBQQ__QuoteLine__c > mapLines = New Map < decimal, SBQQ__QuoteLine__c > ();
            String quoteId1 = String.isBlank(quoteId) ? null : String.escapeSingleQuotes(quoteId.escapeHtml4());
            
            for (QLIWrapper objWrapper1: lstWrapper) {
                
                if (productToPbeMap.containsKey(objWrapper1.productId)) {
                    PricebookEntry pbEntry = productToPbeMap.get(objWrapper1.productId);
                    //system.debug('Pricebookentry -------'+pbEntry);
                    //productToPbeMap.put(pbEntry.Product2Id, pbEntry);
                    SBQQ__QuoteLine__c objLine = New SBQQ__QuoteLine__c();
                    
                    //RWD-952
                    String paymentopt = assetIdVsPayOptMap.containsKey(objWrapper1.strAssetId) ? assetIdVsPayOptMap.get(objWrapper1.strAssetId) : null;
                    
                    if (String.isNotBlank(paymentopt) || paymentopt != null) {
                        objLine.PP_Payment_Option__c = paymentopt;
                        objLine.PA_Payment_Option__c = paymentopt;
                    }
                    
                    objLine.SBQQ__Number__c = objWrapper1.lineNumber;
                    System.debug('Product QLI:==> ' + objLine.SBQQ__Product__c + 'Number: ' + objLine.SBQQ__Number__c);//Stamps for all QLIs
                    
                    objLine.SBQQ__PricebookEntryId__c = pbEntry.Id;
                    objLine.SBQQ__Quote__c = quoteId1;
                    objLine.Sales_Comp_Category__c = pbEntry.Product2.Sales_Comp_Category__c;
                    objLine.Product_Type__c = pbEntry.Product2.Product_Type__c; //Earlier commented out
                    objLine.Product_Level__c = pbEntry.Product2.Product_Level__c; //Earlier commented out
                    objLine.Category__c = pbEntry.Product2.Category__c; //Earlier commented out
                    objLine.SBQQ__Product__c = pbEntry.Product2Id;
                    objLine.SBQQ__NetPrice__c = pbEntry.UnitPrice;
                    
                    if (pbEntry.Product2.SBQQ__DefaultQuantity__c != null) {
                        objLine.SBQQ__Quantity__c = pbEntry.Product2.SBQQ__DefaultQuantity__c;
                        System.debug('ProductCodeA==> ' + objLine.SBQQ__Product__c + ' , QuantityA: ' + objLine.SBQQ__Quantity__c);
                    }else {
                        objLine.SBQQ__Quantity__c = 1;
                        objLine.RWD_Expected_Default_Quantity__c = 0;
                        //objLine.Default_DATA_MIGRATION_Qty_Temp__c = 0;
                        objLine.RWD_Polaris_SKUs_Quantity_Changed__c = true;
                        System.debug('ExpQty==> ' + objLine.SBQQ__Product__c + ' , QuantityB1: ' + objLine.RWD_Expected_Default_Quantity__c); // Data mig
                        System.debug('DefQtyTemp==> ' + objLine.SBQQ__Product__c + ' , QuantityB2: ' + objLine.Default_DATA_MIGRATION_Qty_Temp__c); 
                    }
                    //objLine.SBQQ__Quantity__c = 1;
                    
                    System.debug('pbEntry.Product2.Product_Type__c: ' + pbEntry.Product2.Product_Type__c);
                    System.debug('ProductType' + objLine.Product_Type__c);
                    //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
                    if (objLine.SBQQ__Product__c == objWrapper1.productId) {
                        objLine.Arroyo_Subscribed_Asset_Name__c = objWrapper1.subsAssetNames; //SubscribedAssetNames__c
                        System.debug('objLine.Arroyo_Subscribed_Asset_Name__c:==>' + objLine.Arroyo_Subscribed_Asset_Name__c);
                        
                        //objLine.SBQQ__OptionType__c = 'Related Product';
                    }
                    objLine.Special_Program__c = 'Refresh';
                    
                    if (objLine.Product_Type__c == 'HW Support') {
                        objLine.Arroyo_Subscribed_Asset_Name__c = objWrapper1.subsAssetNames;
                    }
                    //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
                    
                    if (pbEntry.Product2Id != system.Label.MigrationSKU) {
                        
                        if (objWrapper1.strAssetId != null) {
                            
                            String assetSupportType = assetIdVsAssetWrapperMap.containsKey(objWrapper1.strAssetId) ?
                                assetIdVsAssetWrapperMap.get(objWrapper1.strAssetId).Support_Type__c :
                            null;
                            objLine.Support_Type__c = assetSupportType;
                        }
                        objLine.Licensing_Model__c = 'Subscription';
                    }
                    //objLine.Rubrik_Suite__c='Foundation';
                    //objLine.Payment_Options__c= 'Prepay';
                    
                    if (objWrapper1.strAssetId != null) {
                        
                        objLine.SBQQ__UpgradedAsset__c = objWrapper1.strAssetId;
                        
                        String assetRubrikSuite = assetIdVsAssetWrapperMap.containsKey(objWrapper1.strAssetId) ?
                            assetIdVsAssetWrapperMap.get(objWrapper1.strAssetId).Rubrik_Suite__c :
                        null;
                        system.debug('assetRubrikSuite :-> ' + assetRubrikSuite);
                        
                        objLine.Rubrik_Suite__c = assetRubrikSuite;
                        //objLine.Rubrik_Suite__c = 'Foundation Set';
                        system.debug('RubrikSuite2 :-> ' + objLine.Rubrik_Suite__c);
                        
                        String assetPaymentOptions = assetIdVsAssetWrapperMap.containsKey(objWrapper1.strAssetId) ?
                            assetIdVsAssetWrapperMap.get(objWrapper1.strAssetId).Payment_Options__c :
                        null;
                        
                        objLine.Payment_Options__c = assetPaymentOptions;
                    }
                    
                    quoteLineSubs(objLine,pbEntry,lstquote);
                    //Already code for populating DynamicOptionId__c
                    //objLine.SBQQ__DynamicOptionId__c = objWrapper1.option.SBQQ__Feature__c;
                    
                    //Start
                    // Added to populate "Dynamic Option ID" base on "Product_Feature:ProductId" combination
                    // Jay is working on it 
                    if (String.isNotBlank(objWrapper1.dynamicOptionID)) {
                        
                        objLine.SBQQ__DynamicOptionId__c = objWrapper1.dynamicOptionID;
                    }
                    //End
                    
                    objLine.SBQQ__SubscriptionBase__c = 'list';
                    objLine.SBQQ__Description__c = pbEntry.product2.Description;
                    
                    if (objWrapper1.parentKey != NULL) {
                        system.debug('V1:> ' + objLine.SBQQ__Product__c);
                        objLine.ParentQLIndex__c = objWrapper1.parentKey;
                        objLine.SBQQ__OptionType__c = 'Related Product'; //objWrapper1.option.SBQQ__Type__c;
                        objLine.SBQQ__OptionLevel__c = 1;
                        objLine.SBQQ__ProductOption__c = objWrapper1.option.id;
                    } else {
                        system.debug('V1A:> ' + objLine.SBQQ__Product__c);
                        system.debug('strKeyA:> ' + objWrapper1.strKey);
                        objLine.QLIndex__c = objWrapper1.strKey;
                        system.debug('V1B:> ' + objLine.QLIndex__c);
                        if (objWrapper1.strKey != null) {
                            objLine.SBQQ__Bundle__c = true;
                        }
                    }
                    
                    if (objWrapper1.parentKey != NULL && objWrapper1.strKey != NULL) {
                        system.debug('V2:> ' + objLine.SBQQ__Product__c);
                        objLine.ParentQLIndex__c = objWrapper1.parentKey;
                        objLine.SBQQ__OptionType__c = 'Related Product'; //objWrapper1.option.SBQQ__Type__c;
                        objLine.SBQQ__OptionLevel__c = 1;
                        objLine.SBQQ__ProductOption__c = objWrapper1.option.id;
                        objLine.QLIndex__c = objWrapper1.strKey;
                        objLine.SBQQ__Bundle__c = true;
                    }
                    //objLine.SBQQ__ConfigurationRequired__c = true;
                    lstQuoteLine.add(objLine);
                    MapInteger_QLI.put(count, objLine);
                }
            }
            
            SBQQ.TriggerControl.disable();
            try {
                //Database.SaveResult[] results = Database.insert(lstQuoteLine);
                insert lstQuoteLine;
                // CHANGES FOR RWD-1077 STARTS
                SBQQ__Quote__c quoteToUpdate = new SBQQ__Quote__c();
                quoteToUpdate.Id = quoteId1;
                quoteToUpdate.Is_RWD_Polaris_Quote__c = true;
                quoteToUpdate.Is_Refreshed_Identifier__c = true;
                quoteToUpdate.Opportunity_Program__c = 'Refresh';
                update quoteToUpdate;
                // CHANGES FOR RWD-1077 ENDS
                
            } catch (Exception ex) {
                
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage());
                ApexPages.addMessage(msg);
                //apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()  , '' )) ;
                return false;
            }
            
            Set < String > setQuoteIds = new Set < String > ();
            
            system.debug('lstQuoteLine:->>>> ' + lstQuoteLine + ' , SizeQLI:>> ' + lstQuoteLine.size());
            for (SBQQ__QuoteLine__c objLine: lstQuoteLine) {
                system.debug('ProdIdA:> ' + objLine.SBQQ__Product__c + ' , QLIndex:->>>> ' + objLine.QLIndex__c);
                system.debug('ProdIdB:> ' + objLine.SBQQ__Product__c + ' , ParentQLIndex:->>>> ' + objLine.ParentQLIndex__c);
                if (objLine.QLIndex__c != null) {
                    system.debug('objLine.SBQQ__Product__c:->>>> ' + objLine.SBQQ__Product__c);
                    mapLines.put(Integer.valueOf(objLine.QLIndex__c), objLine);
                }
                setQuoteIds.add(objLine.SBQQ__Quote__c);
            }
            
            //Need to change parent
            system.debug('mapLines:->>>> ' + mapLines + ' , mapLinesSizeQLI:>> ' + mapLines.size());
            for (SBQQ__QuoteLine__c objLine: lstQuoteLine) {
                system.debug('objLine.ParentQLIndex__c:->>>> ' + objLine.ParentQLIndex__c);
                if (objLine.ParentQLIndex__c != null &&
                    mapLines.containsKey(objLine.ParentQLIndex__c)
                   ) {
                       objLine.SBQQ__RequiredBy__c = mapLines.get(objLine.ParentQLIndex__c).id;
                       system.debug('Product: ' + objLine.SBQQ__Product__c);
                   }
            }
            try {
                Update lstQuoteLine;
            } catch (Exception ex) {
                
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage());
                ApexPages.addMessage(msg);
                return false;
            }
            
            Integer totalSeqNum = 0;
            
            // Query all quoteLines of the Quote
            List < SBQQ__QuoteLine__c > lstResultQuoteLine = new List < SBQQ__QuoteLine__c > ();
            List < SBQQ__QuoteLine__c > lstResultUpdateQuoteLine = new List < SBQQ__QuoteLine__c > ();
            List < SBQQ__QuoteLineGroup__c > qlgroup = [SELECT Id, SBQQ__Quote__c, Name FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: quoteId
                                                        AND Name != 'Renewal Quote' AND Name != 'Disposition Quote'
                                                        //Name = 'Expansion Quote'
                                                       ];
            if (!qlgroup.IsEmpty()) {
                for (SBQQ__QuoteLineGroup__c quoteGroup: qlgroup) {
                    if (quoteGroup.Name != System.Label.Arry_renewal_Group  && quoteGroup.Name != System.Label.Arry_Disposition_Group 
                        //quoteGroup.Name == 'Expansion Quote'
                       ) {
                           updateGroupOnQuoteLineItems(quoteId);
                       }
                }
            }
            //updateGroupOnQuoteLineItems(quoteId);
            updateDispositionReasons(quoteId);//ARY-218: Added by Shaloo
            consolidateQuoteLineItems(quoteId);
            
            //NEW METHOD
            updatelineNumber(quoteId);
            SBQQ.TriggerControl.enable();
            return true;
        }
    } //End of AddProductsToQuote
    
    public static void updateGroupOnQuoteLineItems(String qId) {
        system.debug('****Called updateGroupOnQuoteLineItems***');
        SBQQ__Quote__c quoteArr = [SELECT Id, SBQQ__Type__c, Name FROM SBQQ__Quote__c WHERE Id =: qId];
        List < SBQQ__QuoteLine__c > qliList = [SELECT Id, SBQQ__Product__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c, Quote_Line_Type__c, Line_Type__c, SBQQ__Group__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: qId];
        SBQQ__QuoteLineGroup__c qlgroup = [SELECT Id, SBQQ__Quote__c, Name FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: qId
                                           AND Name = 'Expansion Quote'
                                          ];
        system.debug('qliList:-> ' + qliList);
        system.debug('qlgroup:-> ' + qlgroup);
        
        List < SBQQ__QuoteLine__c > qliListToUpdate = new List < SBQQ__QuoteLine__c > ();
        if (!qliList.IsEmpty()) {
            for (SBQQ__QuoteLine__c quoteLineObj: qliList) {
                system.debug('Quote Type:-> ' + quoteLineObj.SBQQ__Quote__r.SBQQ__Type__c);
                system.debug('QuoteLineType:-> ' + quoteLineObj.Quote_Line_Type__c);
                system.debug('LineType:-> ' + quoteLineObj.Line_Type__c);
                if (quoteLineObj.Quote_Line_Type__c == 'New') {
                    if (qlgroup != null) {
                        quoteLineObj.SBQQ__Group__c = qlgroup.Id;
                        //quoteLineObj.Is_Expansion_Line__c = true;
                        qliListToUpdate.add(quoteLineObj);
                        system.debug('SBQQ__Group__c:-> ' + quoteLineObj.SBQQ__Group__c);
                    }
                }
            }
        }
        if (!qliListToUpdate.isEmpty()) {
            try {
                update qliListToUpdate;
            } catch (Exception e) {
                System.debug('Insert Error:' + e.getMessage());
            }
        }
        
    }
    public static void consolidateQuoteLineItems(String qId) {
        try {
            system.debug('test palak'+qId);
            List<SBQQ__QuoteLine__c> quoteLineItemList = [SELECT Id
                                                          , SBQQ__ProductName__c
                                                          , SBQQ__Product__c
                                                          , SBQQ__StartDate__c
                                                          , SBQQ__EndDate__c
                                                          , SBQQ__Discount__c
                                                          , SBQQ__Quote__c
                                                          , SBQQ__Quantity__c
                                                          , SBQQ__RequiredBy__c
                                                          , SBQQSC__RenewedContractLine__c
                                                          //    , Is_Refresh__c
                                                          , Refreshed_Asset__c
                                                          ,SBQQ__RequiredBy__r.SBQQ__Product__c
                                                          ,SBQQ__RequiredBy__r.SBQQ__Product__r.Product_level__c
                                                          ,SBQQ__UpgradedAsset__c,
                                                          SBQQ__Product__r.Add_on_Level__c, 
                                                          SBQQ__RequiredBy__r.SBQQ__Product__r.Add_on_Level__c,
                                                          SBQQ__Product__r.X0__c,
                                                          SBQQ__RequiredBy__r.SBQQ__Quantity__c,
                                                          SBQQ__Product__r.Product_Type__c,
                                                          SBQQ__Product__r.Usable_Capacity__c,
                                                          SBQQ__Product__r.Product_level__c
                                                          
                                                          FROM SBQQ__QuoteLine__c
                                                          WHERE SBQQ__Quote__c =: qId AND Special_Program__c ='Refresh'
                                                         ];
            Map<String,String> ReqIDMAP = new Map<string,string>();
            Map<String,SBQQ__QuoteLine__c> addonLinesToBeMErged= new Map<string,SBQQ__QuoteLine__c>();
            Set<ID> toBeDelete = new Set<id>();
            Map<String,SBQQ__QuoteLine__c> prodIdvsQLIMap = new Map<string,SBQQ__QuoteLine__c>(); //MS
            
            Map<String,Decimal> reqbyIdvsQtyMap = new Map<String,Decimal>();
            
            for(SBQQ__QuoteLine__c quoteLineObj : quoteLineItemList) {
                system.debug('test palak'+quoteLineObj.SBQQ__RequiredBy__c);
                system.debug('test palak'+quoteLineObj.SBQQ__UpgradedAsset__c);
                system.debug('test palak'+quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_level__c);
                if(quoteLineObj.SBQQ__RequiredBy__c != null && (quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_level__c == 'Hybrid Software' || (quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_level__c == 'OnPrem' && quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__r.Add_on_Level__c == null))){
                    string Key = quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c;
                    if(ReqIDMAP.containsKey(key)){
                        system.debug('test palak'+ReqIDMAP.get(key));
                        system.debug('test palak'+quoteLineObj.SBQQ__RequiredBy__c);
                        if(ReqIDMAP.get(key) != quoteLineObj.SBQQ__RequiredBy__c){
                            toBeDelete.add(quoteLineObj.SBQQ__RequiredBy__c);
                        }
                    }else{
                        system.debug('test palak');
                        ReqIDMAP.put(key,quoteLineObj.SBQQ__RequiredBy__c);
                        system.debug('ReqIDMAP map-->'+ReqIDMAP);
                        
                    }
                    if(ReqIDMAP.get(key) == quoteLineObj.SBQQ__RequiredBy__c){
                        if(quoteLineObj.SBQQ__Product__r.X0__c || quoteLineObj.SBQQ__Product__r.Add_on_Level__c != null ){
                            addonLinesToBeMErged.put(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c+'-'+quoteLineObj.SBQQ__Product__c,quoteLineObj);
                        }
                    }
                    if( quoteLineObj.SBQQ__Product__r.Product_level__c == 'Hardware' && quoteLineObj.SBQQ__RequiredBy__c != null){
                        if(!reqbyIdvsQtyMap.containsKey(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c)){
                            reqbyIdvsQtyMap.put(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c, quoteLineObj.SBQQ__Product__r.Usable_Capacity__c);
                        } else {
                            Decimal tempQty = reqbyIdvsQtyMap.get(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c) + quoteLineObj.SBQQ__Product__r.Usable_Capacity__c;
                            reqbyIdvsQtyMap.put(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c, tempQty);
                        }
                    }
                    
                }
            }
            List<SBQQ__QuoteLine__c> qLList = new  List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> delList = new  List<SBQQ__QuoteLine__c>();
            for(SBQQ__QuoteLine__c quoteLineObj : quoteLineItemList){
                system.debug('test palak');
                if(addonLinesToBeMErged.containsKey(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c+'-'+quoteLineObj.SBQQ__Product__c) &&
                   addonLinesToBeMErged.get(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c+'-'+quoteLineObj.SBQQ__Product__c).Id != quoteLineObj.id  ){                   
                       delList.add(quoteLineObj);
                   }
                
                
                if(ReqIDMAP.containsKey(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c) &&
                   quoteLineObj.SBQQ__RequiredBy__c != ReqIDMAP.get(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c)  && quoteLineObj.SBQQ__UpgradedAsset__c != null){
                       quoteLineObj.SBQQ__RequiredBy__c = ReqIDMAP.get(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c);
                       qLList.add(quoteLineObj);
                       system.debug('test palak');
                       
                   }
                if(quoteLineObj.SBQQ__RequiredBy__c != null && reqbyIdvsQtyMap.containsKey(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c) && (quoteLineObj.SBQQ__Product__r.X0__c)){
                    quoteLineObj.SBQQ__Quantity__c = reqbyIdvsQtyMap.get(quoteLineObj.SBQQ__RequiredBy__r.SBQQ__Product__c); //MS
                    qLList.add(quoteLineObj);
                    system.debug('MS quoteLineObj.SBQQ__Quantity__c '+quoteLineObj.SBQQ__Quantity__c);                    
                }
                
                if(toBeDelete.contains(quoteLineObj.id)){
                    delList.add(quoteLineObj);
                    system.debug('test palak');
                }
            }
            if(!qLList.isEmpty()) {
                update qLList;                
            }
            if(!delList.isEmpty()) {
                delete delList;
            }
        } catch(Exception e) {
            System.debug('Exception in consolidateQuoteLineItems ==== ' + e + ' Line Num:'+ e.getLineNumber());
        }
    }
    //Replaced to consolidateQuoteLineItemsFF Ends MS
    public static void consolidateQuoteLineItemsFF(String qId) {
        
        try {
            
            List < SBQQ__QuoteLine__c > quoteLineItemList = [SELECT Id, SBQQ__ProductName__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Discount__c, SBQQ__Quote__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, SBQQSC__RenewedContractLine__c
                                                             FROM SBQQ__QuoteLine__c
                                                             WHERE SBQQ__Quote__c =: qId
                                                             //AND Is_Refresh__c = true
                                                             //AND SBQQ__RequiredBy__c = null
                                                            ];
            
            Map < Id, List < SBQQ__QuoteLine__c >> quoteIdVsquoteLineItemListMap = new Map < Id, List < SBQQ__QuoteLine__c >> ();
            Set < Id > quoteLineProductIdSet = new Set < Id > ();
            
            for (SBQQ__QuoteLine__c quoteLineObj: quoteLineItemList) {
                
                List < SBQQ__QuoteLine__c > quoteLineItemTempLst = quoteIdVsquoteLineItemListMap.get(quoteLineObj.SBQQ__Quote__c);
                
                if (quoteLineItemTempLst == null) quoteLineItemTempLst = new List < SBQQ__QuoteLine__c > ();
                
                quoteLineItemTempLst.add(quoteLineObj);
                quoteIdVsquoteLineItemListMap.put(quoteLineObj.SBQQ__Quote__c, quoteLineItemTempLst);
                quoteLineProductIdSet.add(quoteLineObj.SBQQ__Product__c);
            }
            
            List < Polaris_SKU_Mapping_V2__c > polarisSKUMappingList = [SELECT Id, Old_Product__c, New_Product__c
                                                                        FROM Polaris_SKU_Mapping_V2__c
                                                                        WHERE Old_Product__c IN: quoteLineProductIdSet
                                                                        AND New_Product__r.Name != 'No-Polaris-V2'
                                                                       ];
            
            Map < Id, Id > oldProdVsNewProdMap = new Map < Id, Id > ();
            for (Polaris_SKU_Mapping_V2__c polarisSKUMappingObj: polarisSKUMappingList) {
                
                oldProdVsNewProdMap.put(polarisSKUMappingObj.Old_Product__c, polarisSKUMappingObj.New_Product__c);
            }
            
            Map < Id, Map < String, List < SBQQ__QuoteLine__c >>> quoteIdVsMapOfProdKeyVsquoteLineItemListMap = getQuoteIdVsMapOfProdKeyVsquoteLineItemListMap(quoteIdVsquoteLineItemListMap, oldProdVsNewProdMap);
            
            List < SBQQ__QuoteLine__c > quoteLineItemToUpdateList = new List < SBQQ__QuoteLine__c > ();
            Map < Id, SBQQ__QuoteLine__c > qliIdVsquoteLineItemToUpdateMap = new Map < Id, SBQQ__QuoteLine__c > ();
            List < SBQQ__QuoteLine__c > quoteLineItemToDeleteList = new List < SBQQ__QuoteLine__c > ();
            List < Consolidated_Contract_Lines__c > consolidatedContractLineList = new List < Consolidated_Contract_Lines__c > (); //RWD-994
            
            Map < Id, SBQQ__QuoteLine__c > qliToDelVsMergedQLIObjMap = new Map < Id, SBQQ__QuoteLine__c > ();
            
            for (Id quoteId: quoteIdVsMapOfProdKeyVsquoteLineItemListMap.keySet()) {
                
                Map < String, List < SBQQ__QuoteLine__c >> prodKeyVsquoteLineItemListMap = quoteIdVsMapOfProdKeyVsquoteLineItemListMap.get(quoteId);
                //Map<String, String> prodKeyVsSBQQRequiredByMap = new Map<String, String>();
                for (String prodKey: prodKeyVsquoteLineItemListMap.keySet()) {
                    if (!prodKeyVsquoteLineItemListMap.get(prodKey).isEmpty() && prodKeyVsquoteLineItemListMap.get(prodKey).size() > 0) { //RWD-911 Ricky
                        SBQQ__QuoteLine__c quoteLineItemToUpdateObj = prodKeyVsquoteLineItemListMap.get(prodKey)[0];
                        
                        Decimal qty = 0.0;
                        for (SBQQ__QuoteLine__c quoteLineObj: prodKeyVsquoteLineItemListMap.get(prodKey)) {
                            qty += quoteLineObj.SBQQ__Quantity__c;
                            Id masterQuoteLineId = quoteLineItemToUpdateObj.Id; //RWD-994
                            if (quoteLineObj.Id != quoteLineItemToUpdateObj.Id) {
                                
                                quoteLineItemToDeleteList.add(quoteLineObj);
                                //+RWD-994
                                Consolidated_Contract_Lines__c consolidatedCL = new Consolidated_Contract_Lines__c(
                                    Quote_Line__c = masterQuoteLineId,
                                    Contract_Line_Item__c = quoteLineObj.SBQQSC__RenewedContractLine__c
                                );
                                consolidatedContractLineList.add(consolidatedCL);
                                //-RWD-994
                                qliToDelVsMergedQLIObjMap.put(quoteLineObj.Id, quoteLineItemToUpdateObj);
                            }
                        }
                        quoteLineItemToUpdateObj.SBQQ__Quantity__c = qty;
                        System.debug('ProductCodeC==> ' + quoteLineItemToUpdateObj.SBQQ__Product__c + ' , QuantityC: ' + quoteLineItemToUpdateObj.SBQQ__Quantity__c);
                        quoteLineItemToUpdateList.add(quoteLineItemToUpdateObj);
                        qliIdVsquoteLineItemToUpdateMap.put(quoteLineItemToUpdateObj.Id, quoteLineItemToUpdateObj);
                    }
                }
            }
            
            //+RWD-994
            /*
if(!consolidatedContractLineList.isEmpty()){
try{
insert consolidatedContractLineList;
}
catch(Exception e){
System.debug('Insert Error:' + e.getMessage());
}
}
*/
            //-RWD-994
            
            for (SBQQ__QuoteLine__c qliObj: quoteLineItemList) {
                
                if (qliToDelVsMergedQLIObjMap.containsKey(qliObj.SBQQ__RequiredBy__c)) {
                    
                    if (qliIdVsquoteLineItemToUpdateMap.containsKey(qliObj.Id)) {
                        
                        SBQQ__QuoteLine__c qliToUpdateObj = qliIdVsquoteLineItemToUpdateMap.get(qliObj.Id);
                        system.debug('qliToUpdateObj.SBQQ__Product__c:-> ' + qliToUpdateObj.SBQQ__Product__c);
                        qliToUpdateObj.SBQQ__RequiredBy__c = qliToDelVsMergedQLIObjMap.get(qliObj.SBQQ__RequiredBy__c).Id;
                        //quoteLineItemToUpdateList.add(qliToUpdateObj);
                        
                        qliIdVsquoteLineItemToUpdateMap.put(qliToUpdateObj.Id, qliToUpdateObj);
                    } else {
                        system.debug('qliToUpdateObj.SBQQ__Product__c1:-> ' + qliObj.SBQQ__Product__c);
                        qliObj.SBQQ__RequiredBy__c = qliToDelVsMergedQLIObjMap.get(qliObj.SBQQ__RequiredBy__c).Id;
                        //quoteLineItemToUpdateList.add(qliObj);
                        qliIdVsquoteLineItemToUpdateMap.put(qliObj.Id, qliObj);
                        
                    }
                }
            }
            
            if (!quoteLineItemToUpdateList.isEmpty()) {
                update qliIdVsquoteLineItemToUpdateMap.values();
            }
            
            if (!quoteLineItemToDeleteList.isEmpty()) {
                delete quoteLineItemToDeleteList;
            }
            
        } catch (Exception e) {
            
            System.debug('Exception in consolidateQuoteLineItems ==== ' + e + ' Line Num:' + e.getLineNumber());
        }
    }
    
    public static Map < Id, Map < String, List < SBQQ__QuoteLine__c >>> getQuoteIdVsMapOfProdKeyVsquoteLineItemListMap(
        Map < Id, List < SBQQ__QuoteLine__c >> quoteIdVsquoteLineItemListMap,
        Map < Id, Id > oldProdVsNewProdMap
    ) {
        
        Map < Id, Map < String, List < SBQQ__QuoteLine__c >>> quoteIdVsMapOfProdKeyVsquoteLineItemListMap = new Map < Id, Map < String, List < SBQQ__QuoteLine__c >>> ();
        if (quoteIdVsquoteLineItemListMap.isEmpty()) {
            return quoteIdVsMapOfProdKeyVsquoteLineItemListMap;
        }
        for (Id quoteId: quoteIdVsquoteLineItemListMap.keySet()) {
            
            Map < String, List < SBQQ__QuoteLine__c >> prodKeyVsquoteLineItemListMap = new Map < String, List < SBQQ__QuoteLine__c >> ();
            
            for (SBQQ__QuoteLine__c conLineItemObj: quoteIdVsquoteLineItemListMap.get(quoteId)) {
                
                String skuId = '';
                if (oldProdVsNewProdMap.containsKey(conLineItemObj.SBQQ__Product__c)) {
                    skuId = oldProdVsNewProdMap.get(conLineItemObj.SBQQ__Product__c);
                } else {
                    skuId = conLineItemObj.SBQQ__Product__c;
                    
                    String lineKey = skuId + ':' + conLineItemObj.SBQQ__RequiredBy__c + ':' + conLineItemObj.SBQQ__StartDate__c + ':' + conLineItemObj.SBQQ__EndDate__c + ':' + conLineItemObj.SBQQ__Discount__c;
                    List < SBQQ__QuoteLine__c > contLineItemTempList = prodKeyVsquoteLineItemListMap.get(lineKey);
                    if (contLineItemTempList == null) contLineItemTempList = new List < SBQQ__QuoteLine__c > ();
                    contLineItemTempList.add(conLineItemObj);
                    prodKeyVsquoteLineItemListMap.put(lineKey, contLineItemTempList);
                }
                quoteIdVsMapOfProdKeyVsquoteLineItemListMap.put(quoteId, prodKeyVsquoteLineItemListMap);
            }
            return quoteIdVsMapOfProdKeyVsquoteLineItemListMap;
        }
        return null;
    }
    public static void updatelineNumber(String qId) {
        system.debug('Called updatelineNumber');
        Map < String, SBQQ__QuoteLine__c > idvdQliMap = new Map < String, SBQQ__QuoteLine__c > ();
        Map < Id, String > mapCounterWithChildLines = New Map < Id, String > ();
        Map < Id, String > mapHardwareAssetName = New Map < Id, String > ();
        
        Map < String, Map < String, List < SBQQ__QuoteLine__c >>> parentIdvsChildVsListofGrandChildMap = new Map < String, Map < String, List < SBQQ__QuoteLine__c >>> ();
        List < SBQQ__QuoteLine__c > qliList = new List < SBQQ__QuoteLine__c > ();
        Integer linenumber = 0;
        Decimal tempQLINumber = 0;
        Decimal usableCapacityForSaas = 0;
        Map<Id, Decimal> mapHybIDVsQty = new Map<Id, Decimal>();
        
        Decimal existingQty =0;
        
        List < SBQQ__QuoteLine__c > quoteLineItemList = [SELECT Id, SBQQ__ProductCode__c, SBQQ__ProductName__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Discount__c, SBQQ__UpgradedAsset__c, 
                                                         SBQQ__UpgradedAsset__r.SerialNumber, SBQQ__Quote__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, SBQQSC__RenewedContractLine__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__c, SBQQ__Number__c, 
                                                         SBQQ__Product__r.Product_Type__c, Arroyo_Subscribed_Asset_Name__c, Usable_Capacity__c, SBQQ__Product__r.Usable_Capacity__c, SBQQ__Product__r.Product_Level__c, Product_Level__c FROM  SBQQ__QuoteLine__c 
                                                         WHERE SBQQ__Quote__c =: qId ];
        
        for (SBQQ__QuoteLine__c qliObj: quoteLineItemList) {
            if (!idvdQliMap.containsKey(qliObj.id)) {
                idvdQliMap.put(qliObj.id, qliObj);
            }
            
            if (qliObj.SBQQ__RequiredBy__c != null && String.isNotBlank(qliObj.Arroyo_Subscribed_Asset_Name__c)) {
                system.debug('qliObj.SBQQ__RequiredBy__c>>' + qliObj.SBQQ__RequiredBy__c);
                system.debug('ArroyoSubscribedAssetName>>' + qliObj.Arroyo_Subscribed_Asset_Name__c);
                system.debug('SBQQ__UpgradedAsset__r.SerialNumber>>' + qliObj.SBQQ__UpgradedAsset__r.SerialNumber);
                if (mapCounterWithChildLines.containsKey(qliObj.SBQQ__RequiredBy__c)) {
                    system.debug('if');
                    string allAssets = mapCounterWithChildLines.get(qliObj.SBQQ__RequiredBy__c) + ' , ' + qliObj.Arroyo_Subscribed_Asset_Name__c;
                    mapCounterWithChildLines.put(qliObj.SBQQ__RequiredBy__c, allAssets);
                } else {
                    system.debug('else');
                    mapCounterWithChildLines.put(qliObj.SBQQ__RequiredBy__c, qliObj.Arroyo_Subscribed_Asset_Name__c);
                }
            }
            
            if (qliObj.SBQQ__Product__r.Product_Type__c == 'Hardware') {
                mapHardwareAssetName.put(qliObj.Id, qliObj.Arroyo_Subscribed_Asset_Name__c);
            }
            if(qliObj.SBQQ__RequiredBy__c != null && qliObj.SBQQ__Product__c != null && qliObj.SBQQ__Product__r.Usable_Capacity__c !=null){
                if(mapHybIDVsQty.containsKey(qliObj.SBQQ__RequiredBy__c)){
                    existingQty = mapHybIDVsQty.get(qliObj.SBQQ__RequiredBy__c);
                    existingQty = existingQty + (qliObj.SBQQ__Product__r.Usable_Capacity__c * qliObj.SBQQ__Quantity__c);
                    mapHybIDVsQty.put(qliObj.SBQQ__RequiredBy__c,existingQty);
                }
                else {
                    mapHybIDVsQty.put(qliObj.SBQQ__RequiredBy__c,qliObj.SBQQ__Product__r.Usable_Capacity__c * qliObj.SBQQ__Quantity__c);
                }
            }
        }
        
        system.debug('mapCounterWithChildLines>>' + mapCounterWithChildLines);
        system.debug('mapHardwareAssetName>>' + mapHardwareAssetName);
        system.debug('mapHybIDVsQty>>' + mapHybIDVsQty);
        
        for (SBQQ__QuoteLine__c qliObj: quoteLineItemList) {
            if(mapHybIDVsQty.containskey(qliObj.Id)){
                system.debug('SKUA>' + qliObj.SBQQ__Product__c + ' , QTYA> ' + qliObj.SBQQ__Quantity__c);
                system.debug('usableCapacityForSaasZ: ' + usableCapacityForSaas);
                system.debug('mapHybIDVsQtyZ: ' + mapHybIDVsQty.get(qliObj.Id));
                qliObj.SBQQ__Quantity__c = mapHybIDVsQty.get(qliObj.Id);
            }
            if (qliObj.SBQQ__RequiredBy__c == null &&
                !parentIdvsChildVsListofGrandChildMap.containsKey(qliObj.Id)) {
                    parentIdvsChildVsListofGrandChildMap.put(qliObj.Id,
                                                             new Map < String, List < SBQQ__QuoteLine__c >> ());
                } else {
                    if (qliObj.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c == null &&
                        !parentIdvsChildVsListofGrandChildMap.get(qliObj.SBQQ__RequiredBy__c).containsKey(qliObj.Id)
                       ) {
                           parentIdvsChildVsListofGrandChildMap.get(qliObj.SBQQ__RequiredBy__c).put(qliObj.Id, new List < SBQQ__QuoteLine__c > ());
                       } else {
                           parentIdvsChildVsListofGrandChildMap.get(qliObj.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c).get(qliObj.SBQQ__RequiredBy__c).add(qliObj);
                       }
                }
            
            system.debug('qliObj???' + qliObj.Arroyo_Subscribed_Asset_Name__c);
            
            if (qliObj.Id != null && mapCounterWithChildLines.containskey(qliObj.Id)) {
                system.debug('qliObj.SBQQ__ProductCode__c??? ' + qliObj.SBQQ__ProductCode__c);
                qliObj.Arroyo_Subscribed_Asset_Name__c = mapCounterWithChildLines.get(qliObj.Id);
            }
            
            if (qliObj.SBQQ__RequiredBy__c != null && qliObj.SBQQ__Product__r.Product_Type__c == 'HW Support') {
                if (mapHardwareAssetName.containsKey(qliObj.SBQQ__RequiredBy__c)) {
                    qliObj.Arroyo_Subscribed_Asset_Name__c = mapHardwareAssetName.get(qliObj.SBQQ__RequiredBy__c);
                }
            }
        }
        
        System.debug('parentIdvsChildVsListofGrandChildMap--> ' + parentIdvsChildVsListofGrandChildMap);
        
        
        for (String grandparentId: parentIdvsChildVsListofGrandChildMap.keySet()) {
            
            idvdQliMap.get(grandparentId).SBQQ__Number__c = ++linenumber;
            System.debug('QLI ID:==> ' + idvdQliMap.get(grandparentId) + 'QLI Number: ' + idvdQliMap.get(grandparentId).SBQQ__Number__c); //For Hybrid and Data Migration Line
            
            qliList.add(idvdQliMap.get(grandparentId));
            
            for (String parentId: parentIdvsChildVsListofGrandChildMap.get(grandparentId).keySet()) {
                idvdQliMap.get(parentId).SBQQ__Number__c = ++linenumber;
                System.debug('QLI ID1:==> ' + idvdQliMap.get(parentId) + 'QLI Number1: ' + idvdQliMap.get(parentId).SBQQ__Number__c); //For HW lines
                
                qliList.add(idvdQliMap.get(parentId));
                
                for (SBQQ__QuoteLine__c qliObj: parentIdvsChildVsListofGrandChildMap.get(grandparentId).get(parentId))
                { //Loop For HW support and Accesories lines
                    system.debug('Value of linenumber: ' + linenumber);//2,3,4
                    
                    /*if(qliObj.SBQQ__Product__r.Product_Type__c == 'HW Support'){
system.debug('Value of linenumber B4B: ' + linenumber);//3
qliObj.SBQQ__Number__c = linenumber;
system.debug('Value of ++linenumber: ' + qliObj.SBQQ__Number__c);

tempQLINumber = qliObj.SBQQ__Number__c;
system.debug('Value of tempQLINumber: ' + tempQLINumber);
}

if(qliObj.SBQQ__Product__r.Product_Type__c == 'Accessories'){
system.debug('Value of linenumber B4A: ' + linenumber);//2, 4
tempQLINumber = ++linenumber;
system.debug('Value of tempQLINumber: ' + tempQLINumber);//4

qliObj.SBQQ__Number__c = ++tempQLINumber;

system.debug('Acc Line number ' + qliObj.SBQQ__Number__c);
}*/
                    System.debug('QLI ID2:==> ' + qliObj.Id + 'QLI Number2: ' + qliObj.SBQQ__Number__c); //For HW support and Accesories lines
                    
                    qliObj.SBQQ__Number__c = ++linenumber;
                    qliList.add(qliObj);
                }
                //linenumber++;
            }
        }
        try {
            update qliList;
        } catch (Exception ex) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage());
            ApexPages.addMessage(msg);
        }
        //updatelineNumberForDataMigSKU(qId);
    }
    
    public static void updatelineNumberForDataMigSKU(String qId) {
        system.debug('Called updatelineNumberForDataMigSKU');
        List < SBQQ__QuoteLine__c > qliList = new List < SBQQ__QuoteLine__c > ();
        List < SBQQ__QuoteLine__c > quoteLineItemList = [SELECT Id, SBQQ__ProductCode__c, SBQQ__ProductName__c, SBQQ__Product__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Discount__c, SBQQ__UpgradedAsset__c, 
                                                         SBQQ__UpgradedAsset__r.SerialNumber, SBQQ__Quote__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, SBQQSC__RenewedContractLine__c, 
                                                         SBQQ__RequiredBy__r.SBQQ__RequiredBy__c, SBQQ__Number__c, Special_Program__c,
                                                         SBQQ__Product__r.Product_Type__c, Arroyo_Subscribed_Asset_Name__c, Usable_Capacity__c, SBQQ__Product__r.Usable_Capacity__c, SBQQ__Product__r.Product_Level__c, Product_Level__c FROM  SBQQ__QuoteLine__c 
                                                         WHERE SBQQ__Quote__c =: qId AND Special_Program__c = 'Refresh' ORDER BY SBQQ__Number__c ASC];
        system.debug('QLIListSize: ' + quoteLineItemList.size());
        
        if(!quoteLineItemList.isEmpty()){
            for(SBQQ__QuoteLine__c qliObj: quoteLineItemList){
                if(qliObj.SBQQ__ProductCode__c.contains('DATA-MIGRATION')){
                    system.debug('DM Number: ' + qliObj.SBQQ__Number__c);
                    qliObj.SBQQ__Number__c = quoteLineItemList.size();
                    qliList.add(qliObj);
                }
            }
        }
        
        try {
            update qliList;
        } catch (Exception ex) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage());
            ApexPages.addMessage(msg);
        }
    }
    
    public pageReference cancel() {
        if (!Test.isRunningTest()) {
            if (quoteId == null) {
                quoteId = ApexPages.currentPage().getParameters().get('newid');
            }
        }
        String quoteId1 = String.isBlank(quoteId) ? null : String.escapeSingleQuotes(quoteId.escapeHtml4());
        String NextPageUrl = CancelURL.replace('QUOTEID', quoteId1);
        pageReference nextpage = new pageReference(NextPageUrl);
        return nextpage;
    }
    
    public void backToAssets() {
        if (!Test.isRunningTest()) {
            if (quoteId == null) {
                quoteId = ApexPages.currentPage().getParameters().get('newid');
            }
        }
        showAssets = true;
        showUpgrade = false;
    }
    
    public void searchAsset() {
        lstAssetWrapper = new List < AssetWrapper > ();
        
        for (Asset objAsset: lstAsset) {
            
            if (objAsset.SerialNumber.startsWith(searchStr)) {
                AssetWrapper objwrapper = new AssetWrapper();
                objwrapper.objAsset = objAsset;
                lstAssetWrapper.add(objwrapper);
            }
        } //End of for
    } //End of searchAsset
    
    public void clear() {
        lstAssetWrapper = new List < AssetWrapper > ();
        searchStr = '';
        for (Asset objAsset: lstAsset) {
            AssetWrapper objwrapper = new AssetWrapper();
            objwrapper.objAsset = objAsset;
            lstAssetWrapper.add(objwrapper);
        } //End of for
    } //End of clear
    
    public String getNICtype(String NICType) {
        If(NICType == '10GBase-T') {
            NICType = '10GBase-T NIC (Copper)';
        } else If(NICType == 'SFP+') {
            NICType = 'SFP+ NIC (Fiber)';
        }
        
        return NICType;
    }
    
    public class AssetWrapper implements Comparable {
        public Boolean selectedAsset {
            get;
            set;
        }
        public Asset objAsset {
            get;
            set;
        }
        public string NIC_Type {
            get;
            set;
        }
        public Boolean upgradeExists {
            get;
            set;
        }
        public List < UpgradeSourceWrapper > lstUS {
            get;
            set;
        }
        public String selectedSource {
            get;
            set;
        }
        public List < SelectOption > options {
            get;
            set;
        }
        
        //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
        public String selectedGroup {
            get;
            set;
        }
        public String maxCapProduct {
            get;
            set;
        }
        public String assetFamily {
            get;
            set;
        }
        public String assetSerialName {
            get;
            set;
        }
        //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
        /*public String licenseType;
public void setlicenseType(String input){
licenseType = input;
}
public String getlicenseType(){
return licenseType;
}*/
        public String licenseType {
            get;
            set;
        }
        public String rubrikEditionInput {
            get;
            set;
        }
        public String paymentOptionsInput {
            get;
            set;
        }
        public String supportTypeInput {
            get;
            set;
        }
        
        public AssetWrapper() {
            selectedAsset = false;
            objAsset = new asset();
            lstUS = new List < UpgradeSourceWrapper > ();
            selectedSource = '';
            options = new List < SelectOption > ();
            NIC_Type = '';
            upgradeExists = false;
            licenseType = 'SaaS';
            rubrikEditionInput = 'Business';
        }
        //Starts:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
        public Integer compareTo(Object compareTo) {
            AssetWrapper wrap = (AssetWrapper) compareTo;
            system.debug('selectedGroup:-> ' + selectedGroup);
            system.debug('wrap.selectedGroup:-> ' + wrap.selectedGroup);
            if (wrap.selectedGroup != null) {
                if (selectedGroup == wrap.selectedGroup) return 0;
                if (selectedGroup > wrap.selectedGroup) return 1;
                return -1;
            }
            return 0;
        }
        //Ends:-> [Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
    } //End of AssetWrapper class
    
    public class UpgradeSourceWrapper {
        public Boolean selectedSource {
            get;
            set;
        }
        public String selectedId {
            get;
            set;
        }
        public String OptionLabel {
            get;
            set;
        }
        public String OptionValue {
            get;
            set;
        }
        public Custom_Upgrade_Source__c objUs {
            get;
            set;
        }
        public UpgradeSourceWrapper() {
            selectedSource = false;
            objUs = new Custom_Upgrade_Source__c();
        }
    }
    
    public class QLIWrapper {
        public decimal strKey;
        public decimal parentKey;
        public string upgradedAsset;
        public string productId;
        public string dynamicOptionID;
        public SBQQ__ProductOption__c option;
        public string strAssetId;
        public decimal lineNumber;
        public string strRubrikEdition;
        public String subsAssetNames; //[Shaloo Mishra] Arroyo 2.0 : Development of Go Refresh with Asset Group
        public QLIWrapper() {
            upgradedAsset = '';
            productId = '';
            dynamicOptionID = '';
            option = new SBQQ__ProductOption__c();
            strRubrikEdition = '';
        }
    }
    /*public static void boosterMethod(){
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    } */
    //CR #5 change for Arroyo 2.0
    /* CR #5 ARY-218, 823: Start - Added by Shaloo */
    public static void updateDispositionReasons(String qId){/* CR #5 ARY-218, 823: Start - Added by Shaloo */
        system.debug('**** Called updateDispositionReasons in Go Refresh Class***');
        
        List <SBQQ__QuoteLine__c> qliList = [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c, Quote_Line_Type__c, Product_Type__c, 
                                             Line_Type__c, SBQQ__Group__c, Arroyo_Subscribed_Asset_Name__c, Special_Program__c, SubsAstNameInt__c,
                                             SubscribedAssetNames__c, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.Disposition_Reason__c, SBQQ__Hidden__c 
                                             FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: qId];
        system.debug('qliList:-> ' + qliList + 'qliListSize: ' + qliList.size());
        
        Id Quotegroupdes;
        Map<Id, SBQQ__QuoteLine__c> maptoupdateQL = new Map<Id, SBQQ__QuoteLine__c>();
        //List <SBQQ__QuoteLine__c> qliReqByListToUpdate = new List <SBQQ__QuoteLine__c>();
        Set<String> lstRefAssetNames;
        Boolean isRenewalANDExpansion = true;
        
        for(SBQQ__QuoteLineGroup__c grp: [SELECT Id, Name, SBQQ__Quote__c, SBQQ__Description__c, SBQQ__Quote__r.SBQQ__Type__c 
                                          FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: qId])
        {
            System.debug('qlgrp: ' + grp.Name);
            if(grp.Name == System.Label.Arry_Disposition_Group){
                Quotegroupdes = grp.Id;
            }
            /*if(grp.Name == System.Label.Arry_renewal_Group){
Quotegrouprenew = grp.Id;
}*/
            if(grp.SBQQ__Quote__r.SBQQ__Type__c != 'Renewal+Expansion'){
                isRenewalANDExpansion = false;
            }
        }
        
        if(Quotegroupdes == null && isRenewalANDExpansion){
            SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c();
            qlg.Name = System.Label.Arry_Disposition_Group;
            qlg.SBQQ__Quote__c = qId;
            qlg.SBQQ__Description__c = CPQ_Constants.DISPOSE_QUOTE_DESCRIPTION;
            insert qlg;
            
            Quotegroupdes = qlg.Id;
            //System.debug('Inside if qlgrp: ' + Quotegroupdes);
        }
        //System.debug('isRenewalANDExpansion--> ' + isRenewalANDExpansion);
        //System.debug('Quotegroupdes--> ' + Quotegroupdes);
        
        if (!qliList.IsEmpty()) {
            lstRefAssetNames = new Set<String>();
            for (SBQQ__QuoteLine__c quoteLineObj: qliList) {                
                if (quoteLineObj.Quote_Line_Type__c == 'New' && quoteLineObj.Special_Program__c == 'Refresh'){
                    system.debug('Enter HereT1:-> ' + quoteLineObj.Id);
                    
                    if(String.isNotBlank(quoteLineObj.Arroyo_Subscribed_Asset_Name__c)) {
                        for(String assetName : quoteLineObj.Arroyo_Subscribed_Asset_Name__c.split(',')) {
                            assetName = assetName.trim();
                            lstRefAssetNames.add(assetName);
                        }
                    }
                    system.debug('lstRefAssetNames: ' + lstRefAssetNames + ' ,lstRefSize: ' + lstRefAssetNames.size());
                }
            }
            
            for (SBQQ__QuoteLine__c quoteLineObj: qliList) {
                //if (quoteLineObj.Quote_Line_Type__c == 'Renewal' && quoteLineObj.SubscribedAssetNames__c != null){
                //&& quoteLineObj.Product_Type__c == 'HW Support'
                system.debug('Enter HereT2A:-> ' + quoteLineObj.SubscribedAssetNames__c);
                if(lstRefAssetNames!= null && !lstRefAssetNames.IsEmpty())
                {
                    for(String str: lstRefAssetNames){
                        if(quoteLineObj.Quote_Line_Type__c == 'Renewal' && quoteLineObj.SubscribedAssetNames__c != null
                           && quoteLineObj.SubscribedAssetNames__c.contains(str))
                        {
                            system.debug('Enter HereT3:-> ' + quoteLineObj.SubscribedAssetNames__c);
                            system.debug('Enter HereT4:-> ' + str);
                            quoteLineObj.Disposition_Reason__c = 'Refreshed';
                            quoteLineObj.SBQQ__Group__c = Quotegroupdes;
                            //qliReqByListToUpdate.add(quoteLineObj);
                            maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                        }
                        if(quoteLineObj.Quote_Line_Type__c == 'Renewal' && quoteLineObj.SubsAstNameInt__c != null
                           && quoteLineObj.SubsAstNameInt__c.contains(str)){
                               system.debug('Enter HereT3:-> ' + quoteLineObj.SubsAstNameInt__c);
                               system.debug('Enter HereT4:-> ' + str);
                               quoteLineObj.Disposition_Reason__c = 'Refreshed';
                               quoteLineObj.SBQQ__Group__c = Quotegroupdes;
                               //qliReqByListToUpdate.add(quoteLineObj);
                               maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                           }
                    }
                }
                //}
                /*if (quoteLineObj.Quote_Line_Type__c == 'Renewal' && quoteLineObj.SubsAstNameInt__c != null)
{
//&& quoteLineObj.SubscribedAssetNames__c == null //&& quoteLineObj.Product_Type__c == 'HW Support'
system.debug('Enter HereT2B:-> ' + quoteLineObj.Id);        
if(lstRefAssetNames!= null && !lstRefAssetNames.IsEmpty()){
for(String str: lstRefAssetNames){
if(quoteLineObj.SubsAstNameInt__c.contains(str)){
system.debug('Enter HereT3:-> ' + quoteLineObj.SubsAstNameInt__c);
system.debug('Enter HereT4:-> ' + str);
quoteLineObj.Disposition_Reason__c = 'Refreshed';
quoteLineObj.SBQQ__Group__c = Quotegroupdes;
//qliReqByListToUpdate.add(quoteLineObj);
maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
}
}
} 
}*/
            }
            //Logic to set disposition for HW lines related to HW support
            for (SBQQ__QuoteLine__c quoteLineObj: qliList) {
                if(quoteLineObj.Quote_Line_Type__c == 'Existing'){
                    system.debug('maptoupdateQL:-> ' + maptoupdateQL);
                    
                    if(maptoupdateQL != null && !maptoupdateQL.IsEmpty()){
                        for(SBQQ__QuoteLine__c qli: maptoupdateQL.values()){
                            system.debug('Enter HereT5:-> ' + quoteLineObj.Id);
                            system.debug('Enter HereT6:-> ' + qli.SBQQ__RequiredBy__c);
                            
                            if(quoteLineObj.Id == qli.SBQQ__RequiredBy__c){
                                system.debug('Enter HereT7:-> ' + qli.SBQQ__RequiredBy__c);
                                quoteLineObj.SBQQ__Hidden__c = TRUE;
                                quoteLineObj.Disposition_Reason__c = 'Refreshed';
                                quoteLineObj.SBQQ__Group__c = Quotegroupdes;
                                //qliListToUpdate.add(quoteLineObj);
                                maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                            }
                        }
                    }
                }
            }
        }
        system.debug('Enter HereT9:-> ' + maptoupdateQL.values() + ' SizeK: ' + maptoupdateQL.values().size());
        if (!maptoupdateQL.values().isEmpty()) {
            try {
                update maptoupdateQL.values();
                system.debug('After update:-> ' + maptoupdateQL.values() + ' SizeJ: ' + maptoupdateQL.values().size());
            } catch (Exception e) {
                System.debug('Insert Error:' + e.getMessage());
            }
        }
    }
public static SBQQ__QuoteLine__c quoteLineSubs(SBQQ__QuoteLine__c objLine, PriceBookEntry pbEntry, List<SBQQ__Quote__c> lstQuote){
        objLine.SBQQ__SubscriptionPricing__c = pbEntry.Product2.SBQQ__SubscriptionPricing__c;
        
        if (pbEntry.Product2.SBQQ__DefaultQuantity__c != null) {
            objLine.SBQQ__BundledQuantity__c = pbEntry.Product2.SBQQ__DefaultQuantity__c;
        }else {
            objLine.SBQQ__BundledQuantity__c = 1;
        }
        
        objline.SBQQ__ProductSubscriptionType__c = pbEntry.Product2.SBQQ__SubscriptionType__c;
        objLine.SBQQ__PackageProductCode__c = pbEntry.product2.ProductCode;
        objLine.SBQQ__SubscriptionType__c = pbEntry.Product2.SBQQ__SubscriptionType__c;
        //objLine.SBQQ__SubscriptionType__c = pbEntry.product2.SBQQ__SubscriptionType__c;
        objLine.SBQQ__NonDiscountable__c = pbEntry.Product2.SBQQ__NonDiscountable__c;
        objLine.SBQQ__DefaultSubscriptionTerm__c = pbEntry.product2.SBQQ__SubscriptionTerm__c;
        if (objLine.SBQQ__DefaultSubscriptionTerm__c != null) {
            objLine.SBQQ__SubscriptionTerm__c = lstQuote[0].SBQQ__SubscriptionTerm__c;
        }
        return objLine;
        
    }
} //End of DisplayAllAssetsControllerpportunityObject