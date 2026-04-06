/**
* @description       : This class is used for conversion of LOD assets to SaaS bundles under Sakura project.
* @author            : Anjali Patel 
* @group             : Sakura Team
* @Created on        : 08-26-2022
* Modifications Log  
* Ver   Date         Author           Modification 
* 1.0   08-26-2022   Anjali Patel   Initial Version
**/
public class ConvertAssetController{  
    /* Product types which are eligible for conversion
*/
    static final Set<String> ELIGIBLE_PRODUCT_TYPES = new Set<String> {
        'Hardware',
            'Appliance',
            'Add-On Node',
            'Node Upgrade'
            };
                
                /* QuoteId*/
                public String quoteId                      { get; set; }
    /* conversionQuote*/
    public SBQQ__Quote__c conversionQuote       { get; set; }
    /* assetEndDateRequired*/
    public Date assetEndDateRequired            { get; set; }
    /* assetEndDateDays*/
    public Integer assetEndDateDays             { get; set; }
    /* existingAssetMap*/
    public Map<String, Asset> existingAssetMap  { get; set; }
    /* lstWrapperAssets*/
    public List<AssetWrapper> lstWrapperAssets  { get; set; }
    /* selectedWrappers*/
    public List<AssetWrapper> selectedWrappers  { get; set; }
    /* isFederalAccount*/
    public Boolean isFederalAccount             { get; set; }
    /* isNonFederalAccount*/
    public Boolean isNonFederalAccount          { get; set; }
    /* isOnPremException*/
    public Boolean isOnPremException            { get; set; }
    /* strSearchAsset*/
    public String strSearchAsset                { get; set; }
    /* showConversionPage*/
    public Boolean showConversionPage           { get; set; }
    /* isConversionError*/
    public Boolean isConversionError            { get; set; }
    /* isAspenOppty*/
    private Boolean isAspenOppty;
    /* conversionQuoteGroup*/
    public Boolean isDealOpsExp            { get; set; }
    /* Added BY amdhura CPQ22-2984*/
    public List<SBQQ__QuoteLineGroup__c> conversionQuoteGroup { get; set; }//ARY-258: Added by Shaloo
    /* ARY-258: Added by Shaloo */
    public List<SBQQ__QuoteLine__c> qliListRecords { get; set; }//ARY-258: Added by Shaloo
    /*Added for CPQ22-3050*/
    public Map<Id, Boolean> mapProdEligibility;
    
        public Map<String,String> assetRSCCLiMap;  //Added by madhura CPQ22-3963
        public  Map<String,String> assetHWsupport ; //Added by madhura CPQ22-3963
        
        /*CPQ22-2071: Added by Shreejita*/
        public Boolean rcdmValidQuote = false;
        /* quotRangeStart*/
        public Date quotRangeStart;
        /* quotRangeEnd*/
        public Date quotRangeEnd;
        /* rcdmDatesObj*/
        static X0_RCDM_Dates__mdt rcdmDatesObj;
        /* lstConvUpgradeSrcPgm*/
        static List<Custom_Conversion_Upgrade_Source__c> lstConvUpgradeSrcPgm;
        /* lstProductOptions*/
        static List<SBQQ__ProductOption__c> lstProductOptions;
        /* lstConvUpgradeSrcSaaSNull*/
        static List<Custom_Conversion_Upgrade_Source__c> lstConvUpgradeSrcSaaSNull;
            /*ITNPI-449*/
        public Boolean isDealOpsUser  { get; set; }
        //CPQ22-3577
        List<String> supportMappedBundle = new List<String>();

    /* Method to show/hide asset end date option for specific profiles*/
    public Boolean getShowAssetEndDate() {
        return System.Label.Asset_End_Date_Input_Profiles
            .split(';')
            .contains(UserInfo.getProfileId().left(15));
    }
    
    /* Constructor*/
    public ConvertAssetController() {
        lstWrapperAssets = new List<AssetWrapper>();
        quoteId = ApexPages.currentPage().getParameters().get('newId');
        assetEndDateDays = 120;
        strSearchAsset = '';
        showConversionPage = false;
        isAspenOppty = false;
        isConversionError = false;
        assetEndDateRequired = Date.today().addDays(assetEndDateDays);
        mapProdEligibility = new Map<Id, Boolean>();
              assetRSCCLiMap = new Map<String,String>();  //Added by madhura CPQ22-3963
              assetHWsupport = new Map<String,String>() ; //Added by madhura CPQ22-3963
            if (quoteId == null
                || Id.valueOf(quoteId).getSObjectType() != SBQQ__Quote__c.sObjectType
               ) {
                   ApexPages.addMessage(
                       new ApexPages.Message(
                           ApexPages.Severity.FATAL,
                           'Error loading the page. Please confirm if a quote ID is correctly provided in the URL and refresh the page.'
                       )
                   );
                   return;
               }
            //added field for SF-72381
            conversionQuote = [
                SELECT Id
                , Name
                , SBQQ__Type__c
                , SBQQ__Account__c
                , SBQQ__LineItemCount__c
                , SBQQ__PriceBook__c
                , Is_Federal_Eligible_Quote__c
                , Selective_Account_Eligible_for_RCDM_T__c
                , RCDMT_EOL_Date__c
            , RWD_Sales_Rep_Exception__c
            , L3_Support_Only__c
            //, Earliest_QuoteLine_StartDate__c
            , SBQQ__Opportunity2__r.Aspen_Eligibility__c
            , Todays_Date__c
            , RWD_Deal_Ops_Exception__c
            , Running_User_Profile__c
            , Eligible_for_RCDM_T__c
            , Is_Customer_Fully_Transitioned__c
            , SBQQ__Status__c
            ,Quoting_Desk_Exception__c
            , (SELECT Id
               , SBQQ__ProductCode__c
               , SBQQ__Product__r.Eligible_for_RCDM_T__c
               , Product_Type__c //ARY-258: Added by Shaloo
               , Arroyo_Subscribed_Asset_Name__c
               , SBQQ__UpgradedAsset__c
               , SBQQ__UpgradedAsset__r.Product2Id
               , SBQQ__PriorQuantity__c
               FROM SBQQ__LineItems__r)
            FROM SBQQ__Quote__c
            WHERE Id =: quoteId
            LIMIT 1
        ];
        
        //Start- ARY-258: Added by Shaloo
        if(quoteId != null){
            conversionQuoteGroup = [SELECT Id, SBQQ__Quote__c, Name, SBQQ__Description__c, SBQQ__Quote__r.SBQQ__Type__c
                                    FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: quoteId];
        }
        
        qliListRecords = [SELECT Id, SBQQ__Product__r.Eligible_for_RCDM_T__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Product__c, Quote_Line_Type__c, Prior_Net_Total_With_Uplift__c,
                          SBQQ__Group__c, Special_Program__c, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.Disposition_Reason__c, 
                          Sales_Comp_Category__c, SBQQ__Product__r.Sales_Comp_Category__c, RTAwithoutUplift__c, PriorACVwithUplift__c,
                          Product_Type__c, Licensing_Model__c, SBQQ__NetPrice__c, Prior_Net_Total__c, CPQ_Prior_Discount__c, 
                          SBQQ__Discount__c, Discount_Margin__c, Approval_Flags__c, Arroyo_Subscribed_Asset_Name__c, CPQ_Uplift__c,
                          Subscribed_Asset_Name__c, SubscribedAssetNames__c,Support_Split_Percent__c,
                          SBQQSC__RenewedContractLine__c, Arroyo_Subsumed_Old_Contract_Line_Items__c, SBQQ__ProratedListPrice__c,
                          SBQQ__ProrateMultiplier__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SubsAstNameInt__c,RenewalQuantityPopulated__c,
                          SBQQ__SubscriptionTerm__c, SBQQ__DefaultSubscriptionTerm__c, SBQQ__ListPrice__c, PNTperMonth__c, SBQQ__Quantity__c,
                          PNTUpliftPerMonth__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId ORDER BY SBQQ__Number__c ASC];
        system.debug('qliListRecords:-> ' + qliListRecords + ' & qliListRecordsSize: ' + qliListRecords.size());
        //End- ARY-258: Added by Shaloo
        
        isFederalAccount = conversionQuote.Is_Federal_Eligible_Quote__c;
        
        isOnPremException = true;/*conversionQuote.RWD_Sales_Rep_Exception__c != null
            && conversionQuote.RWD_Sales_Rep_Exception__c.contains('Exception for On-Prem Quoting');*/
        
        //change as part of SF-72381 replaced RWD_Deal_Ops_Exception__c field with Quoting_Desk_Exception__c
        isDealOpsExp =  (conversionQuote.Running_User_Profile__c == 'System Administrator' || conversionQuote.Running_User_Profile__c=='Rubrik Light Administrator' || conversionQuote.Running_User_Profile__c=='Sales Operations' || conversionQuote.Running_User_Profile__c=='Deal Operations' );//CPQ22-2984
        
        isAspenOppty = conversionQuote.SBQQ__Opportunity2__r.Aspen_Eligibility__c != null &&
            (conversionQuote.SBQQ__Opportunity2__r.Aspen_Eligibility__c.contains('Proposed Aspen')
             || conversionQuote.SBQQ__Opportunity2__r.Aspen_Eligibility__c.contains('Actual Aspen'));
        List<GroupMember> gm = [SELECT UserOrGroupId,Group.DeveloperName FROM GroupMember WHERE UserOrGroupId=: UserInfo.getUserId() AND Group.DeveloperName = 'Deal_Desk' LIMIT 1];
        if(!gm.isEmpty()){
            isDealOpsUser = true;
        } 
        else{
            isDealOpsUser = false;
        }

        fetchEligibleAssetsForConversion();
    }
    
    /* Get all the eligible assets for conversion*/
    public void fetchEligibleAssetsForConversion() {
        assetEndDateRequired = Date.today().addDays(assetEndDateDays);
        lstWrapperAssets = new List<AssetWrapper>();
        existingAssetMap = new Map<String, Asset>();
        assetEndDateRequired = Date.today().addDays(assetEndDateDays);
        
        // Get all the assets for this quote that are already converted
        Set<String> assetsToIgnore = new Set<String>();
        String supportType = conversionQuote.L3_Support_Only__c
            ? 'L3'
            : 'Premium';
        
        for (SBQQ__QuoteLine__c existingLine : conversionQuote.SBQQ__LineItems__r) {
            if (existingLine.Arroyo_Subscribed_Asset_Name__c != null) {
                for (String assetName : existingLine.Arroyo_Subscribed_Asset_Name__c.split(',')) {
                    assetsToIgnore.add(assetName.trim());
                }
            }
        }
        
        for (Asset assetToConvert : [
            SELECT Id
            , Name
            , ProductCode
            , Asset.Product2.Name
            , Asset.Product2Id
            , Asset.Product2.Product_NIC_Type__c
            , Quantity
            , Support_Start_Date__c
            , Asset.Product2.Family
            , Premium_Support_End_Date__c
            , SerialNumber
            , Asset.Product2.Usable_Capacity__c
            , Licensing_Model__c
            , Rubrik_Suite__c
            , Payment_Options__c
            , Support_Type__c
            , Support_Tier__c
            , Asset.Product2.Capacity__c
            , Product2.Product_Type__c
            , Product2.License_Type__c
            , Order_Service_Item__c
            , Order_Service_Item__r.Product2Id
            , (SELECT Id
               , CreatedDate
                   , ContractLineItemId
                   ,AssetId
                   ,Asset.Name
                   , Status
                   , Order_Service_Item__r.Product2Id
                   , Order_Service_Item__r.Product2.Category__c
                   , Order_Service_Item__r.Product2.Add_on_Level__c
                   , Order_Service_Item__r.Product2.ProductCode
                   , Order_Service_Item__r.Product2.Name
                   , Order_Service_Item__r.Product2.Product_Type__c
                   , Order_Service_Item__r.Product2.License_Subtype__c
                   FROM Entitlements
                   //WHERE Status = 'Active'
                   ORDER BY CreatedDate DESC
                  )
                FROM Asset
                WHERE AccountId =: conversionQuote.SBQQ__Account__c
                AND SerialNumber NOT IN :assetsToIgnore
                AND (Product2.Product_Type__c IN :ELIGIBLE_PRODUCT_TYPES)
                AND (Licensing_Model__c = 'Perpetual' OR Product2.License_Type__c = 'Perpetual')
                AND Product_Family__c = 'R6000'
                AND Premium_Support_End_Date__c != null
            ]) {
                // Filter the assets based on serial number
                if (String.isNotBlank(strSearchAsset)
                    && assetToConvert.SerialNumber.containsIgnoreCase(strSearchAsset) == false
                   ) {
                       continue;
                   }
                
                existingAssetMap.put(assetToConvert.Name, assetToConvert.clone());
                
                assetToConvert.Support_Type__c = supportType;
                assetToConvert.Product_Nic_Type__c
                    = getNICtype(assetToConvert.Product2.Product_NIC_Type__c);
                if(isDealOpsUser){
                    assetToConvert.Rubrik_Suite__c = 'Proactive';
                }
                else{
                    assetToConvert.Rubrik_Suite__c = 'Enterprise';
                }
                
                AssetWrapper wrapper = new AssetWrapper();
                wrapper.asset = assetToConvert;
                
                lstWrapperAssets.add(wrapper);
                system.debug('lstWrapperAssets A:' + lstWrapperAssets);
            }
        }
        
        /* Method to clear the search entry*/
        public void clearSearch() {
            strSearchAsset = '';
            fetchEligibleAssetsForConversion();
        }
        
        /* Method to cancel and return to QLE*/
        public Pagereference cancelAndReturn() {
            Pagereference pgRef = Page.SBQQ__sb;
            pgRef.getParameters().put('id', quoteId);
            
            return pgRef;
        }
        
        /* Method to cancel and go back to first page*/
        public void cancelAndBack() {
            showConversionPage = false;
            isConversionError = false;
            selectedWrappers = new List<AssetWrapper>();
        }
        
        /* Method to show the SaaS products based on selection*/
        public void fetchConversionProducts() {
            selectedWrappers = new List<AssetWrapper>();
            Set<Id> parentOrderItemIds = new Set<Id>();
            Set<Id> assetIds = new Set<Id>();
            Map<Id, List<OrderItem>> orderItemRequiredByChildren
                = new Map<Id, List<OrderItem>>();
            
            Map<Id, List<Entitlement>> assetChildEntitlements
                = new Map<Id, List<Entitlement>>();
            
            Map<String, Custom_Conversion_Upgrade_Source__c> attributeConversionMap
                = new Map<String, Custom_Conversion_Upgrade_Source__c>();
            
            // Get only the selected records
            system.debug('lstWrapperAssets B:' + lstWrapperAssets);
            for (AssetWrapper wrapper : lstWrapperAssets) {
                if (wrapper.selected == true) {
                    selectedWrappers.add(wrapper);
                }
            }
            
            // Create a map of conversion attributes with the upgrade source record
            lstConvUpgradeSrcPgm = new List<Custom_Conversion_Upgrade_Source__c>([
                SELECT Id
                , Program__c
                , License_Type__c
                , Edition__c
                , Support_Type__c
                , Payment_Option__c
                , Saas_SKU__c
                , Saas_SKU__r.Name
                , Saas_SKU__r.Description
                FROM Custom_Conversion_Upgrade_Source__c
                WHERE Program__c = 'Convert'
            ]
                                                                                );
            
            for(Custom_Conversion_Upgrade_Source__c upgradeSource : lstConvUpgradeSrcPgm) {
                String attributeKey = upgradeSource.Edition__c
                    + upgradeSource.Payment_Option__c
                    + upgradeSource.Support_Type__c
                    + upgradeSource.License_Type__c;
                
                attributeConversionMap.put(attributeKey, upgradeSource);
            }
            
            // Create a list of all product IDs to be fetched for SaaS products
            for (AssetWrapper wrapper : selectedWrappers) {
                String attributeKey = wrapper.asset.Rubrik_Suite__c
                    + wrapper.asset.Payment_Options__c
                    + wrapper.asset.Support_Type__c
                    + wrapper.licenseType;
                
                if (attributeConversionMap.containsKey(attributeKey) == false) {
                    wrapper.isConversionPossible = false;
                    wrapper.conversionError = 'Mapping is not present for converting the selected SaaS bundle attributes. Please contact the System Administrator.';
                    
                    isConversionError = true;
                    
                    continue;
                }
                
                wrapper.convertSaasProductId = attributeConversionMap.get(attributeKey).SaaS_SKU__c;
                wrapper.convertSaasProduct = attributeConversionMap.get(attributeKey).SaaS_SKU__r;
                
                // Just add the parent order item Id record for the conversion asset
                // so that we can get all the children order items related to it
                parentOrderItemIds.add(wrapper.asset.Order_Service_Item__c);
                assetIds.add(wrapper.asset.Id);
            }
            
            for (AssetWrapper wrapper : selectedWrappers) {
                List<OrderItem> eligibleRequiredByOrderItems = new List<OrderItem>();
                List<Entitlement> eligibleEntitlements = new List<Entitlement>();
                Datetime dt;
                Set<String> productNameEntitlementSet = new Set<String>();

            // Make sure that only one support line is added to the converted products
            Boolean checkSupport = true;
            
            // Filter only the records as per the conditions in SKU-90
            system.debug('wrapper.asset.Entitlements0: ' + wrapper.asset.Entitlements);
            for (Entitlement childEntl : wrapper.asset.Entitlements) {
      // added by CPQ22-3963
                    if((childEntl.Order_Service_Item__r.Product2.Add_on_Level__c == 'RCDM Add-On' && childEntl.Order_Service_Item__r.Product2.Product_Type__c!= null && childEntl.Order_Service_Item__r.Product2.Product_Type__c.contains('Edition')) || childEntl.Order_Service_Item__r.Product2.Product_Type__c == 'RCDM Support' || childEntl.Order_Service_Item__r.Product2.Name=='RBK-SVC-APPLIANCE-L3' || childEntl.Order_Service_Item__r.Product2.Name== 'RBK-SVC-PREM-APPLIANCE'){ 
                System.debug('inside if');
                
                 
                System.debug('Date val above'+dt);
                //Date dd;
                System.debug('inside if'+assetRSCCLiMap);
                        if(assetRSCCLiMap== null ||  assetRSCCLiMap.isEmpty() || (!assetRSCCLiMap.isEmpty() && !assetRSCCLiMap.containsKey(childEntl.Asset.Name))){
                            System.debug('Mapval1');
                            dt = childEntl.CreatedDate;
                            // dd = Date.newInstance(dt.year(), dt.month(), dt.day());
                            System.debug('Date val if'+dt);
                           assetRSCCLiMap.put(childEntl.Asset.Name,String.ValueOf(childEntl.ContractLineItemId));
                        }else {
                            System.debug('Mapval1else');
                            System.debug('isdateEQUAL'+(dt==childEntl.CreatedDate));
                            //change for CPQ22-4311  
                            if(assetRSCCLiMap.containsKey(childEntl.Asset.Name) 
                            && !String.isBlank(childEntl.ContractLineItemId) 
                            && !(String.ValueOf(childEntl.ContractLineItemId)).contains(assetRSCCLiMap.get(childEntl.Asset.Name)) 
                            && dt == childEntl.CreatedDate){                                 System.debug('Mapval1elseif');
                                System.debug('Date val else'+dt);
                                String val = assetRSCCLiMap.get(childEntl.Asset.Name)+','+String.ValueOf(childEntl.ContractLineItemId);
                                assetRSCCLiMap.put(childEntl.Asset.Name,val.removeEnd(','));
                            }
                        }
                        System.debug('Mapval'+assetRSCCLiMap);
                    }
                    // for HW support added by CPQ22-3963
                    if((assetHWsupport.isEmpty() || assetHWsupport == null || (!assetHWsupport.isEmpty() && !assetHWsupport.containsKey(childEntl.Asset.Name)) ) && (childEntl.Order_Service_Item__r.Product2.Product_Type__c == 'HW Support' || childEntl.Order_Service_Item__r.Product2.Product_Type__c == 'Node Upgrade') ){ //Added Node Upgrade as part of CPQ22-4694
                        assetHWsupport.put(childEntl.Asset.Name,String.ValueOf(childEntl.ContractLineItemId));
                    }
                    System.debug('assetHWsupport'+assetHWsupport);
                    
                if (childEntl.Order_Service_Item__r.Product2.ProductCode.contains('RCDM')) continue;
                if (childEntl.Order_Service_Item__r.Product2.Name.contains('FNDN')) continue;
                if (childEntl.Order_Service_Item__r.Product2.Name.contains('RADAR')) continue;
                if (new Set<String> {'Accessories', 'Spares'}.contains(childEntl.Order_Service_Item__r.Product2.Product_Type__c)) continue;
                if (childEntl.Order_Service_Item__r.Product2.Category__c == 'Support'
                    && (!new Set<String> {'HW Support', 'Node Upgrade'}.contains(childEntl.Order_Service_Item__r.Product2.Product_Type__c)) //Added Node Upgrade as part of CPQ22-4694
                   ) continue;
                //Fix under SF-31866
                if ('Add-On'.equals(childEntl.Order_Service_Item__r.Product2.License_Subtype__c)
                    || 'CLON'.contains(childEntl.Order_Service_Item__r.Product2.ProductCode)) continue;
                
                //SKU-352: Added condition for adding only latest entitlement
                if (!productNameEntitlementSet.contains(childEntl.Order_Service_Item__r.Product2.Name) && checkSupport == true) {
                    eligibleEntitlements.add(childEntl);
                    productNameEntitlementSet.add(childEntl.Order_Service_Item__r.Product2.Name);
                    checkSupport = false;
                }
            }
            
            // orderItemRequiredByChildren.put(parentOrderItem.Id, eligibleRequiredByOrderItems);
            system.debug('eligibleEntitlements0: ' + eligibleEntitlements);
            assetChildEntitlements.put(wrapper.asset.Id, eligibleEntitlements);
        }
        
        // Assign the order item values for conversion of this particular asset
        system.debug('assetChildEntitlements0: ' + assetChildEntitlements);
        system.debug('selectedWrapperss0: ' + selectedWrappers);
        for (AssetWrapper wrapper : selectedWrappers) {
            wrapper.originalOrderItem = wrapper.asset.Order_Service_Item__r;
            // wrapper.childOrderItems = orderItemRequiredByChildren.get(wrapper.asset.Order_Service_Item__c);
            system.debug('Get0: ' + assetChildEntitlements.get(wrapper.asset.Id));
            wrapper.childEntitlements = assetChildEntitlements.get(wrapper.asset.Id);
            system.debug('Wrap Ent0: ' + wrapper.childEntitlements);
        }
        
        showConversionPage = true;
    }
    
    /* Method to convert the asset products into SaaS model*/
    public Pagereference convertAssets() {
        system.debug('Inside method convertAssets');
        List<SBQQ__QuoteLine__c> toInsertSaaSLines = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> toInsertHwLines = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> toInsertSupportLines = new List<SBQQ__QuoteLine__c>();
        Map<Id, PricebookEntry> productIdPbeMap = new Map<Id, PricebookEntry>();
        Set<Id> productIds = new Set<Id>();
        
        String quoteRenGroupIds = '';//ARY-258: Added by Shaloo
        String quoteExpGroupIds = '';//ARY-258: Added by Shaloo
        String quoteDispGroupIds = '';//ARY-258: Added by Shaloo
        String quoteGroupIds = '';
        System.debug(quoteRenGroupIds);
        Map<String, List<AssetWrapper>> attributesToSelectedAsset
            = new Map<String, List<AssetWrapper>>();
        
        // Get all the conversion information for all old products
        Map<Id, Custom_Conversion_Upgrade_Source__c> oldProductToSaaSProduct
            = new Map<Id, Custom_Conversion_Upgrade_Source__c>();
        
        // Map of support attributes and conversion information
        Map<String, Custom_Conversion_Upgrade_Source__c> supportTierUpgradeSource
            = new Map<String, Custom_Conversion_Upgrade_Source__c>();
        
        Map<Id, Id> saasProductAddonFeatureMap = new Map<Id, Id>();
        Map<Id, Id> saasProductHwFeatureMap = new Map<Id, Id>();
        Map<Id, Id> hwProductSupportFeatureMap = new Map<Id, Id>();
        
        Integer saasCount = 0, hwLineCount = 0, supportCount = 0;
        Map<Integer, Integer> hwIndexToSaasLineMap = new Map<Integer, Integer>();
        Map<Integer, Integer> supportIndexToHwLineMap = new Map<Integer, Integer>();
        
        Integer lineNumberCount = conversionQuote.SBQQ__LineItemCount__c == null
            ? 0
            : Integer.valueOf(conversionQuote.SBQQ__LineItemCount__c);
        
        //Start- ARY-258: Added by Shaloo
        if (conversionQuoteGroup != null && !conversionQuoteGroup.isEmpty()) {
            for (SBQQ__QuoteLineGroup__c qliGroup : conversionQuoteGroup) {
                if(qliGroup.Name == System.Label.Arry_renewal_Group){
                    quoteRenGroupIds = qliGroup.Id;
                }
                
                if(qliGroup.Name != System.Label.Arry_renewal_Group && qliGroup.Name != System.Label.Arry_Disposition_Group){
                    //qliGroup.Name == 'Expansion Quote'
                    quoteExpGroupIds = qliGroup.Id;
                }
            }
        }
        //End- ARY-258: Added by Shaloo
        
        lstConvUpgradeSrcSaaSNull  = new List<Custom_Conversion_Upgrade_Source__c>([
            SELECT Id
            , Support_Type__c
            , Old_Product__c
            , New_Product__c
            , Support_Tier__c
            , Product_Upgrade_Type__c
            , Old_Product__r.Category__c
            , Old_Product__r.RWD_Version__c
            , Old_Product__r.Name
            FROM Custom_Conversion_Upgrade_Source__c
            WHERE Saas_SKU__c = NULL
        ]);
        for (Custom_Conversion_Upgrade_Source__c upgradeSource : lstConvUpgradeSrcSaaSNull) {
            // CPQ22-3577 pro bundle mapped to support
            if (upgradeSource.Old_Product__r.Category__c == 'Bundle' && upgradeSource.Product_Upgrade_Type__c == 'Support'){
                supportMappedBundle.add(upgradeSource.Old_Product__r.Name);
            }
            else {
            oldProductToSaaSProduct.put(upgradeSource.Old_Product__c, upgradeSource);
            }
            
            // Create map of support attributes with upgrade source record
            // CPQ22-3577
            if ((upgradeSource.Old_Product__r.Category__c == 'Support' || (upgradeSource.Old_Product__r.Category__c == 'Bundle' && upgradeSource.Product_Upgrade_Type__c == 'Support'))
                && upgradeSource.Support_Tier__c != null
               ) {
                   String supportKey = upgradeSource.Old_Product__c
                       + upgradeSource.Support_Tier__c
                       + upgradeSource.Support_Type__c;
                   
                   supportTierUpgradeSource.put(supportKey, upgradeSource);
               }
        }
        
        Set<Id> newSupportIdSet = new Set<Id>();
        
        for (AssetWrapper wrapper : selectedWrappers) {
            String attributeKey = wrapper.asset.Rubrik_Suite__c
                + wrapper.asset.Payment_Options__c
                + wrapper.asset.Support_Type__c
                + wrapper.licenseType
                + wrapper.asset.Premium_Support_End_Date__c;
            
            if (attributesToSelectedAsset.containsKey(attributeKey)) {
                attributesToSelectedAsset.get(attributeKey).add(wrapper);
            } else {
                attributesToSelectedAsset.put(attributeKey, new List<AssetWrapper> { wrapper });
            }
            
            // All SaaS wrappers
            productIds.add(wrapper.convertSaasProductId);
            
            Id hwProductId = wrapper.asset.Product2Id, newHwProductId;
            
            // If v2 to v2 aspen conversion
            if (oldProductToSaaSProduct.containsKey(hwProductId)) {
                newHwProductId = oldProductToSaaSProduct.get(hwProductId).New_Product__c;
            }
            
            if (newHwProductId == null) {
                wrapper.isConversionPossible = false;
                wrapper.conversionError = 'Mapping not present for conversion of product ' + wrapper.asset.Product2.Name + '. Please contact the System Administrator.';
                
                isConversionError = true;
                
                continue;
            }
            
            productIds.add(newHwProductId);
            
            // All 2nd level lines (support)
            // for (OrderItem childItem : wrapper.childOrderItems) {
            for (Entitlement childEntl : wrapper.childEntitlements) {
                Custom_Conversion_Upgrade_Source__c upgradeSource
                    = oldProductToSaaSProduct.get(childEntl.Order_Service_Item__r.Product2Id);
                
                // Add the product for support tier
                //CPQ22-3577
                if ((childEntl.Order_Service_Item__r.Product2.Category__c == 'Support' || supportMappedBundle.contains(childEntl.Order_Service_Item__r.Product2.Name))
                    && wrapper.asset.Support_Tier__c != null ) {
                        String supportKey = childEntl.Order_Service_Item__r.Product2Id
                            + wrapper.asset.Support_Tier__c
                            + wrapper.asset.Support_Type__c;
                        upgradeSource = supportTierUpgradeSource.get(supportKey);
                        system.debug('newSupportIdSet l: ' + newSupportIdSet);
                        //system.debug('upgradeSource.New_Product__c l: ' + upgradeSource.New_Product__c);
                        if(upgradeSource != null && upgradeSource.New_Product__c != null){
                            newSupportIdSet.add(upgradeSource.New_Product__c);
                        }
                    }
                
                if (upgradeSource == null) {
                    continue;
                }
                if(upgradeSource != null && upgradeSource.New_Product__c != null){
                    productIds.add(upgradeSource.New_Product__c);
                }
            }
        }
        
        //Create Product option map
        Map<Id, Map<Id, SBQQ__ProductOption__c>> optionalSKUConfiguredSKUOptionMap
            = new Map<Id, Map<Id, SBQQ__ProductOption__c>>();
        
        for (SBQQ__ProductOption__c objOption : [
            SELECT Id
            , Name
            , Refresh_Default_Option__c
            , SBQQ__ConfiguredSKU__c
            , SBQQ__OptionalSKU__c
            , SBQQ__OptionalSKU__r.Support_Type__c
            , SBQQ__Type__c
            , SBQQ__Feature__c
            , Support_Type__c
            , Category_Name__c
            FROM SBQQ__ProductOption__c
            WHERE SBQQ__OptionalSKU__c IN: newSupportIdSet
        ]) {
            if (optionalSKUConfiguredSKUOptionMap.containsKey(objOption.SBQQ__OptionalSKU__c)) {
                //Check if inner map already has the configured SKU
                if (!optionalSKUConfiguredSKUOptionMap.get(objOption.SBQQ__OptionalSKU__c)
                    .containsKey(objOption.SBQQ__ConfiguredSKU__c)
                   ) {
                       optionalSKUConfiguredSKUOptionMap.get(objOption.SBQQ__OptionalSKU__c)
                           .put(objOption.SBQQ__ConfiguredSKU__c, objOption);
                   }
            } else {
                Map<Id, SBQQ__ProductOption__c> innerMap = new Map<Id, SBQQ__ProductOption__c>();
                innerMap.put(objOption.SBQQ__ConfiguredSKU__c, objOption);
                optionalSKUConfiguredSKUOptionMap.put(objOption.SBQQ__OptionalSKU__c, innerMap);
            }
        }
        
        for (PricebookEntry pbe : [
            SELECT Id
            , Pricebook2Id
            , Product2Id
            , Product2.Product_Level__c
            , Product2.Category__c
            , Product2.Product_Type__c
            , Product2.Usable_Capacity__c
            , Product2.RWD_Version__c
            , Product2.Description
            , Product2.SBQQ__SubscriptionPricing__c
            , Product2.Sales_Comp_Category__c
            , Product2.Eligible_for_RCDM_T__c
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
            AND Pricebook2Id =: conversionQuote.SBQQ__PriceBook__c
        ]) {
            productIdPbeMap.put(pbe.Product2Id, pbe);
        }
        
        // Get the Hardware feature IDs for SaaS products
        for (SBQQ__ProductFeature__c feature : [
            SELECT Id
            , Name
            , SBQQ__ConfiguredSKU__c
            FROM SBQQ__ProductFeature__c
            WHERE SBQQ__ConfiguredSKU__c IN :productIds
            AND (Name = 'R6000 Series - Rubrik Appliances' OR Name = 'R6000 Node Series' OR Name = 'Support')
        ]) {
            if (feature.Name == 'R6000 Node Series') {
                saasProductAddonFeatureMap.put(feature.SBQQ__ConfiguredSKU__c, feature.Id);
            } else if (feature.Name == 'R6000 Series - Rubrik Appliances') {
                saasProductHwFeatureMap.put(feature.SBQQ__ConfiguredSKU__c, feature.Id);
            } else if (feature.Name == 'Support') {
                hwProductSupportFeatureMap.put(feature.SBQQ__ConfiguredSKU__c, feature.Id);
            }
        }
        
        // For every attribute selection
        Date earliestQuoteLineStartDate = null;
        for (String attributeKey : attributesToSelectedAsset.keySet()) {
            List<AssetWrapper> wrappersWithSameAttributes
                = attributesToSelectedAsset.get(attributeKey);
            
            Integer usableCapacityForSaas = 0;
            Set<String> assetSerialNumbers = new Set<String>();
            AssetWrapper saasWrapper = wrappersWithSameAttributes[0];
            PricebookEntry saasPbe = productIdPbeMap.get(saasWrapper.convertSaasProductId);
            Date earliestSupportEndDate = saasWrapper.asset.Premium_Support_End_Date__c;
            
            if (saasWrapper.isConversionPossible == false) continue;
            
            // QL for SaaS quote line
            toInsertSaaSLines.add(
                new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = conversionQuote.Id,
                    SBQQ__Number__c = lineNumberCount++,
                    SBQQ__PricebookEntryId__c = saasPbe.Id,
                    SBQQ__Product__c = saasPbe.Product2Id,
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__Quantity__c = usableCapacityForSaas,
                    Category__c = saasPbe.Product2.Category__c,
                    Product_Level__c = saasPbe.Product2.Product_Level__c,
                    Product_Type__c = saasPbe.Product2.Product_Type__c,
                    RWD_Version__c = saasPbe.Product2.RWD_Version__c,
                    SBQQ__Description__c = saasPbe.Product2.Description,
                    SBQQ__SubscriptionPricing__c = saasPbe.Product2.SBQQ__SubscriptionPricing__c,
                    Special_Program__c = 'Conversion'
                )
            );
            
            mapProdEligibility.put(saasPbe.Product2Id, saasPbe.Product2.Eligible_for_RCDM_T__c);
            system.debug('> mapProdEligibility:  '+mapProdEligibility);
            
            for (AssetWrapper wrapper : wrappersWithSameAttributes) {
                if (wrapper.isConversionPossible == false) continue;
                
                if (earliestSupportEndDate > wrapper.asset.Premium_Support_End_Date__c) {
                    earliestSupportEndDate = wrapper.asset.Premium_Support_End_Date__c;
                }
                
                PricebookEntry hwPbe;
                Id oldProductId = wrapper.asset.Product2Id, hwProductId;
                
                hwProductId = oldProductToSaaSProduct.get(oldProductId).New_Product__c;
                hwPbe = productIdPbeMap.get(hwProductId);
                
                String productType = hwPbe.Product2.Product_Type__c;
                
                String dynamicOptionId = productType == 'Add-On Node' || productType == 'Node Upgrade'
                    ? saasProductAddonFeatureMap.get(saasWrapper.convertSaasProductId) + ':' + hwPbe.Product2Id
                    : saasProductHwFeatureMap.get(saasWrapper.convertSaasProductId) + ':' + hwPbe.Product2Id;
                
                // QL for HW quote line
                toInsertHwLines.add(
                    new SBQQ__QuoteLine__c(
                        SBQQ__Quote__c = conversionQuote.Id,
                        SBQQ__Number__c = lineNumberCount++,
                        SBQQ__PricebookEntryId__c = hwPbe.Id,
                        SBQQ__Product__c = hwPbe.Product2Id,
                        SBQQ__Quantity__c = 1,
                        SBQQ__OptionLevel__c = 1,
                        SBQQ__ListPrice__c = 0,
                        SBQQ__Existing__c = true,
                        SBQQ__Optional__c = true,
                        SBQQ__OptionType__c = 'Related Product',
                        SBQQ__Hidden__c = true,
                        //SBQQ__StartDate__c = wrapper.asset.Premium_Support_End_Date__c,
                        SBQQ__DynamicOptionId__c = dynamicOptionId,
                        Arroyo_Subscribed_Asset_Name__c = wrapper.asset.SerialNumber,
                        Category__c = hwPbe.Product2.Category__c,
                        Product_Level__c = hwPbe.Product2.Product_Level__c,
                        Product_Type__c = hwPbe.Product2.Product_Type__c,               //ARY-258: Added by Shaloo
                        RWD_Version__c = hwPbe.Product2.RWD_Version__c,
                        SBQQ__Description__c = hwPbe.Product2.Description,
                        SBQQ__SubscriptionPricing__c = hwPbe.Product2.SBQQ__SubscriptionPricing__c,
                        Special_Program__c = 'Conversion'
                        ,Sales_Comp_Category__c = hwPbe.Product2.Sales_Comp_Category__c
                    )
                );
                system.debug('toInsertHwLines A: ' + toInsertHwLines);
                hwIndexToSaasLineMap.put(hwLineCount, saasCount);
                assetSerialNumbers.add(wrapper.asset.SerialNumber);
                
                usableCapacityForSaas = hwPbe.Product2.Usable_Capacity__c == null
                    ? usableCapacityForSaas + 0
                    : usableCapacityForSaas + Integer.valueOf(hwPbe.Product2.Usable_Capacity__c);
                
                // QL for all support lines
                // for (OrderItem childItem : wrapper.childOrderItems) {
                system.debug('Wrap Ent: ' + wrapper.childEntitlements);
                for (Entitlement childEntl : wrapper.childEntitlements) 
                {
                    Custom_Conversion_Upgrade_Source__c supportSource
                        = oldProductToSaaSProduct.get(childEntl.Order_Service_Item__r.Product2Id);
                    
                    // If this is a tiered support then get the appropriate support tier product
                    //CPQ22-3577
                    if ((childEntl.Order_Service_Item__r.Product2.Category__c == 'Support' || supportMappedBundle.contains(childEntl.Order_Service_Item__r.Product2.Name))
                        && wrapper.asset.Support_Tier__c != null
                       ) {
                           String supportKey = childEntl.Order_Service_Item__r.Product2Id
                               + wrapper.asset.Support_Tier__c
                               + wrapper.asset.Support_Type__c;
                           supportSource = supportTierUpgradeSource.get(supportKey);
                       }
                    
                    if (supportSource == null) {
                        continue;
                    }
                    
                    PricebookEntry childPbe = productIdPbeMap.get(supportSource.New_Product__c);
                    
                    if (childPbe == null) {
                        wrapper.isConversionPossible = false;
                        wrapper.conversionError = 'Mapping not present for conversion of product ' + childEntl.Order_Service_Item__r.Product2.Name + '. Please contact the System Administrator.';
                        
                        toInsertHwLines.remove(hwLineCount);
                        toInsertSaaSLines.remove(saasCount);
                        
                        isConversionError = true;
                        
                        continue;
                    }
                    
                    Id prodOptionId;
                    //Get the correct Product option for Support SKU
                    if (optionalSKUConfiguredSKUOptionMap.containsKey(childPbe.Product2Id)) {
                        Map<Id, SBQQ__ProductOption__c> innerMap
                            = optionalSKUConfiguredSKUOptionMap.get(childPbe.Product2Id);
                        
                        if (innerMap.containsKey(hwPbe.Product2Id)) {
                            prodOptionId = innerMap.get(hwPbe.Product2Id).Id;
                        }
                    }
                    
                    toInsertSupportLines.add(
                        new SBQQ__QuoteLine__c(
                            SBQQ__Quote__c = conversionQuote.Id,
                            SBQQ__Number__c = lineNumberCount++,
                            SBQQ__PricebookEntryId__c = childPbe.Id,
                            SBQQ__Product__c = childPbe.Product2Id,
                            SBQQ__Quantity__c = 1,
                            SBQQ__OptionLevel__c = 1,
                            SBQQ__SubscriptionTerm__c = 36,
                            SBQQ__StartDate__c = wrapper.asset.Premium_Support_End_Date__c.addDays(1),
                            SBQQ__EndDate__c = wrapper.asset.Premium_Support_End_Date__c.addMonths(36).addDays(-1),
                            SBQQ__DynamicOptionId__c = hwProductSupportFeatureMap.get(hwPbe.Product2Id) + ':' + childPbe.Product2Id,
                            Arroyo_Subscribed_Asset_Name__c = wrapper.asset.SerialNumber,
                            Category__c = childPbe.Product2.Category__c,
                            RWD_Version__c = childPbe.Product2.RWD_Version__c,
                            Product_Level__c = childPbe.Product2.Product_Level__c,
                            Product_Type__c = childPbe.Product2.Product_Type__c,
                            SBQQ__Description__c = childPbe.Product2.Description,
                            SBQQ__SubscriptionPricing__c = childPbe.Product2.SBQQ__SubscriptionPricing__c,
                            SBQQ__ProductOption__c = prodOptionId,
                            Special_Program__c = 'Conversion'
                            ,Sales_Comp_Category__c = childPbe.Product2.Sales_Comp_Category__c
                        )
                    );
                    System.debug('toInsertSupportLines A: ' + toInsertSupportLines);
                    supportIndexToHwLineMap.put(supportCount, hwLineCount);
                    supportCount = supportCount + 1;
                }
                
                hwLineCount = hwLineCount + 1;
            }
            System.debug('toInsertSupportLines B: ' + toInsertSupportLines);
            System.debug('supportIndexToHwLineMapA: ' + supportIndexToHwLineMap);
            
            if (saasWrapper.isConversionPossible) {
                toInsertSaaSLines[saasCount].SBQQ__Quantity__c = usableCapacityForSaas;
                toInsertSaaSLines[saasCount].Arroyo_Subscribed_Asset_Name__c
                    = String.join(new List<String>(assetSerialNumbers), ', ');
 System.debug('whats the value > '+toInsertSaaSLines[saasCount].Arroyo_Subscribed_Asset_Name__c);
                        if(toInsertSaaSLines[saasCount].Arroyo_Subsumed_Old_Contract_Line_Items__c == null && toInsertSaaSLines[saasCount].Arroyo_Subscribed_Asset_Name__c!= null ){
                            String concatVal = '';
                            for(String sst : toInsertSaaSLines[saasCount].Arroyo_Subscribed_Asset_Name__c.split(',')){
                                System.debug('inside for');
                                System.debug('inside for>>'+assetRSCCLiMap);
                                if(!assetRSCCLiMap.isEmpty() && assetRSCCLiMap.containsKey(sst.trim())){
                                    System.debug('show strr'+sst);
                                    System.debug('concatVal1'+concatVal);
                                    if(!concatVal.contains(assetRSCCLiMap.get(sst.trim()))){
                                    concatVal += assetRSCCLiMap.get(sst.trim())+',';
                                    }
                                  System.debug('concatVal'+concatVal);
                                  System.debug('STR EXP Asset RSC line>'+concatVal);
                                }
                                toInsertSaaSLines[saasCount].Arroyo_Subsumed_Old_Contract_Line_Items__c = concatVal.removeEnd(',');
                            }
                        }
                toInsertSaaSLines[saasCount].Earliest_Support_End_Date__c = earliestSupportEndDate;
                toInsertSaaSLines[saasCount].SBQQ__StartDate__c = earliestSupportEndDate.addDays(1);
                toInsertSaaSLines[saasCount].SBQQ__EndDate__c = earliestSupportEndDate.addMonths(36).addDays(-1);
                
                //Start- ARY-258: Added by Shaloo
                if (conversionQuote != null
                    && conversionQuote.SBQQ__Type__c == 'Renewal+Expansion'
                    && quoteExpGroupIds != null
                    && toInsertSaaSLines[saasCount].Special_Program__c == 'Conversion'
                   ) {
                       //toInsertSaaSLines[saasCount].Quote_Line_Type__c == 'New' &&
                       toInsertSaaSLines[saasCount].SBQQ__Group__c = quoteExpGroupIds;
                   }
                //End- ARY-258: Added by Shaloo
            }
            
            if (earliestQuoteLineStartDate == null ||
                toInsertSaaSLines[saasCount].SBQQ__StartDate__c < earliestQuoteLineStartDate
               ) {
                   earliestQuoteLineStartDate = toInsertSaaSLines[saasCount].SBQQ__StartDate__c;
               }
            saasCount = saasCount + 1;
        }
        insert toInsertSaaSLines;
        
        // Add the required by for appropriate SaaS line
        Map<Id, Decimal> mapReqNumber = new Map<Id, Decimal>();
        for (Integer i = 0 ; i < toInsertHwLines.size() ; i++) {
            SBQQ__QuoteLine__c hwLine = toInsertHwLines[i];
            if(hwLine.SBQQ__Product__r.X0__c == false && hwIndexToSaasLineMap.containsKey(i)) {
                hwLine.SBQQ__RequiredBy__c = toInsertSaaSLines[hwIndexToSaasLineMap.get(i)].Id;
            }
            //Start- ARY-258: Added by Shaloo
            system.debug('QLIType2: ' + hwLine.Quote_Line_Type__c);
            mapReqNumber.put(hwLine.SBQQ__RequiredBy__c, hwLine.SBQQ__Number__c);
            System.debug('>> mapReqNumber: '+mapReqNumber);
            if (conversionQuote != null
                && conversionQuote.SBQQ__Type__c == 'Renewal+Expansion'
                && quoteExpGroupIds != null
                && hwLine.Special_Program__c == 'Conversion'
               ) {
                   hwLine.SBQQ__Group__c = quoteExpGroupIds;
               }
            //End- ARY-258: Added by Shaloo
        }
        
        Set<Id> hybridParentIds = new Set<Id>();
        for(SBQQ__QuoteLine__c objLine : toInsertSaaSLines) {
            hybridParentIds.add(objLine.SBQQ__Product__c);
        }
        Map<Id, Id> mapParentIdPOId = new Map<Id, Id>();
        lstProductOptions = new List<SBQQ__ProductOption__c>([Select Id, SBQQ__OptionalSKU__r.X0__c, SBQQ__OptionalSKU__r.ProductCode, SBQQ__ConfiguredSKU__c from SBQQ__ProductOption__c WHERE SBQQ__ConfiguredSKU__c IN : hybridParentIds AND SBQQ__OptionalSKU__r.X0__c = true]); 
        for(SBQQ__ProductOption__c objPO : lstProductOptions ) {
            mapParentIdPOId.put(objPO.SBQQ__ConfiguredSKU__c, objPO.Id);
        }
        System.debug('> mapParentIdPOId: '+mapParentIdPOId);
        //Start - CPQ22-2071: Added by Shreejita
        if(rcdmDatesObj == null){
            rcdmDatesObj = [SELECT Id, Order_Sub_Type__c, Order_Type__c, IT_Product_Type__c, Licensing_Type__c, Subscription_Term__c, DeveloperName, Approval_Category__c, List_Price__c, Product_Level__c, Subscription_Pricing__c, Subscription_Type__c, EndDate_Day__c, EndDate_Month__c, EndDate_Year__c,StartDate_Day__c, StartDate_Month__c,StartDate_Year__c,Special_Price__c, Description__c FROM X0_RCDM_Dates__mdt WHERE DeveloperName = 'RCDM_Dates' LIMIT 1];
            System.debug('>> ORCDM 3 <<');
        }
        
        if(rcdmDatesObj != null && rcdmDatesObj.EndDate_Year__c != null && rcdmDatesObj.EndDate_Month__c != null && rcdmDatesObj.EndDate_Day__c != null && conversionQuote!= null && conversionQuote.RCDMT_EOL_Date__c!= null) {
            quotRangeStart = Date.newInstance(Integer.valueOF(rcdmDatesObj.StartDate_Year__c), Integer.valueOF(rcdmDatesObj.StartDate_Month__c), Integer.valueOF(rcdmDatesObj.StartDate_Day__c));
            quotRangeEnd = conversionQuote.RCDMT_EOL_Date__c;// added for CPQ22-3874
            system.debug('End date>>'+quotRangeEnd);
            if(((conversionQuote.RWD_Deal_Ops_Exception__c == null || conversionQuote.RWD_Deal_Ops_Exception__c == '') || (conversionQuote.RWD_Deal_Ops_Exception__c != null && !conversionQuote.RWD_Deal_Ops_Exception__c.contains('Allow removal of 0$ On Prem SKU'))) && (conversionQuote.SBQQ__Type__c == 'Quote' || conversionQuote.SBQQ__Type__c == 'Renewal+Expansion') && conversionQuote.SBQQ__Status__c == 'Draft' && conversionQuote.Eligible_for_RCDM_T__c == true && conversionQuote.Is_Customer_Fully_Transitioned__c == false && conversionQuote.Todays_Date__c < quotRangeEnd && conversionQuote.Todays_Date__c >= quotRangeStart && (conversionQuote.Selective_Account_Eligible_for_RCDM_T__c == true || (conversionQuote.Selective_Account_Eligible_for_RCDM_T__c == false && conversionQuote.RWD_Deal_Ops_Exception__c != null && conversionQuote.RWD_Deal_Ops_Exception__c.contains('RCDM-T - Adding sku to transitioned account')))) {
                rcdmValidQuote = true;
                System.debug('>>rcdm-t: eligible: '+rcdmValidQuote);
            }
        }
        
        for(SBQQ__QuoteLine__c objParentLine: toInsertSaaSLines) {
            SBQQ__QuoteLine__c rcdmQL = new SBQQ__QuoteLine__c();
            system.debug('>Parent Line prod level: '+objParentLine.Product_Level__c);
            system.debug('> rcdmValidQuote: '+rcdmValidQuote);
            
            if(mapProdEligibility.containsKey(objParentLine.SBQQ__Product__c) && mapProdEligibility.get(objParentLine.SBQQ__Product__c) == true && rcdmValidQuote == true && objParentLine.SBQQ__StartDate__c < quotRangeEnd) {   
                System.debug('inside New RCDM Renewal'+objParentLine.Id);
                rcdmQL.SBQQ__RequiredBy__c = objParentLine.Id;
                rcdmQL.SBQQ__Quote__c = conversionQuote.Id;
                rcdmQL.SBQQ__Number__c = mapReqNumber.containsKey(objParentLine.Id) ? mapReqNumber.get(objParentLine.Id)+1 : 1;
                rcdmQL.SBQQ__ProductOption__c = mapParentIdPOId.containsKey(objParentLine.SBQQ__Product__c) ? mapParentIdPOId.get(objParentLine.SBQQ__Product__c) : rcdmQL.SBQQ__ProductOption__c;
                rcdmQL.SBQQ__PricebookEntryId__c = System.Label.RCDM_PBEId;
                rcdmQL.SBQQ__Product__c = System.Label.RCDM_ProductId;
                rcdmQL.SBQQ__Discount__c = 100;
                rcdmQL.SBQQ__Quantity__c = objParentLine.SBQQ__Quantity__c;
                rcdmQL.RWD_Expected_Default_Quantity__c = objParentLine.SBQQ__Quantity__c;
                rcdmQL.SBQQ__ListPrice__c = 130;
                rcdmQL.SBQQ__NetPrice__c = 0;
                rcdmQL.Product_Level__c = rcdmDatesObj != null ? rcdmDatesObj.Product_Level__c : 'OnPrem';
                rcdmQL.SBQQ__OriginalPrice__c = rcdmDatesObj != null ? rcdmDatesObj.List_Price__c : 0;
                rcdmQL.SBQQ__CustomerPrice__c = 0;
                rcdmQL.SBQQ__SubscriptionPricing__c = rcdmDatesObj != null ? rcdmDatesObj.Subscription_Pricing__c : 'Fixed Price';
                rcdmQL.Approval_Category__c = rcdmDatesObj != null ? rcdmDatesObj.Approval_Category__c : '';
                rcdmQL.SBQQ__ProductSubscriptionType__c = 'One-time';
                rcdmQL.SBQQ__SubscriptionType__c = rcdmDatesObj != null ? rcdmDatesObj.Subscription_Type__c : 'One-time';
                rcdmQL.Approval_Flags__c = String.valueOf('/img/msg_icons/confirm16.png None');
                rcdmQL.Licensing_Model__c = rcdmDatesObj != null ? rcdmDatesObj.Licensing_Type__c : 'Subscription';
                rcdmQL.SBQQ__SpecialPrice__c = rcdmDatesObj != null ? rcdmDatesObj.Special_Price__c : 0;
                rcdmQL.SBQQ__Description__c = rcdmDatesObj != null ? rcdmDatesObj.Description__c : '';
                rcdmQL.Category__c = 'Software';
                rcdmQL.Minimum_Term__c = 12;
                rcdmQL.Maximum_Term__c = 60;
                rcdmQL.SBQQ__DefaultSubscriptionTerm__c = 1;
                rcdmQL.SBQQ__OptionLevel__c = 1;
                rcdmQL.SBQQ__OptionType__c = 'Related Product';
                if (conversionQuote != null
                    && conversionQuote.SBQQ__Type__c == 'Renewal+Expansion'
                    && conversionQuoteGroup != null
                    && quoteExpGroupIds != null
                   ) {
                       rcdmQL.SBQQ__Group__c = quoteExpGroupIds;
                   }
                rcdmQL.Product_Subtype__c='';
                rcdmQL.License_Category__c = System.Label.RCDM_LicenseCategory; //'On Prem';
                toInsertHwLines.add(rcdmQL);    
                System.debug('toInsertHwLines: '+toInsertHwLines);
            }
        }
        
        
        insert toInsertHwLines;
        
        //Start- ARY-258: Added by Shaloo
        if (conversionQuoteGroup != null && !conversionQuoteGroup.isEmpty()) {
            for (SBQQ__QuoteLineGroup__c qliGroup: conversionQuoteGroup) {
                if (qliGroup.Name == System.Label.Arry_renewal_Group){
                    quoteGroupIds = qliGroup.Id;
                }
            }
        }
        //End- ARY-258: Added by Shaloo
        
        // Add the required by for appropriate HW line
        List <SBQQ__QuoteLine__c> qliRenHWSupportLine = new List <SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> mapQLIIdVsRec = new Map<Id, SBQQ__QuoteLine__c>();
        
        if (!qliListRecords.IsEmpty()){
            for (SBQQ__QuoteLine__c quoteLineObj: qliListRecords) {
                if(quoteLineObj.Quote_Line_Type__c == 'Renewal' && 
                   quoteLineObj.Product_Type__c == 'HW Support'
                   && quoteLineObj.Special_Program__c != 'Conversion'){
                       qliRenHWSupportLine.add(quoteLineObj);
                   }
            }
            system.debug('qliRenHWSupportLineA: ' + qliRenHWSupportLine + ' ,qliRenHWSupportLineSizeA: ' + qliRenHWSupportLine.size());
        }
        
        Set<String> convertedAssetNames = new Set<String>();
        if(toInsertSupportLines != null && !toInsertSupportLines.IsEmpty()){                            
            for(Integer i = 0 ; i < toInsertSupportLines.size() ; i++) {
                SBQQ__QuoteLine__c supportLine = toInsertSupportLines[i];
                system.debug('AssetName#: ' + supportLine.Arroyo_Subscribed_Asset_Name__c);
                if(supportLine.Arroyo_Subscribed_Asset_Name__c != null){
                    for(String assetName : supportLine.Arroyo_Subscribed_Asset_Name__c.split(',')){
                        assetName = assetName.trim();
                        convertedAssetNames.add(assetName);
                    }
                }
            }
        }
        system.debug('convertedAssetNames: ' + convertedAssetNames + ' & convertedAssetNamesSize: ' + convertedAssetNames.size());
        List<Asset> convertedAssetIdList = [SELECT Id, Name FROM Asset WHERE Name =: convertedAssetNames];
        Map<String, String> mapAssetNameVsId = new Map<String, String>();
        if(convertedAssetIdList != null && !convertedAssetIdList.IsEmpty()){
            for(Asset assetRec: convertedAssetIdList){
                mapAssetNameVsId.put(assetRec.Name, assetRec.Id);
            }
        }
        
        system.debug('mapAssetNameVsId: ' + mapAssetNameVsId + ' & mapAssetNameVsIdSize: ' + mapAssetNameVsId.size());
        system.debug('toInsertSupportLines: ' + toInsertSupportLines + ' & SupportSize' + toInsertSupportLines.size());
        
        if(toInsertSupportLines != null && !toInsertSupportLines.IsEmpty()){                           
            for (Integer i = 0 ; i < toInsertSupportLines.size() ; i++) {
                SBQQ__QuoteLine__c supportLine = toInsertSupportLines[i];
                
                System.debug('supportIndexToHwLineMapB: ' + supportIndexToHwLineMap);
                System.debug('supportIndexToHwLineMapB GetA: ' + supportIndexToHwLineMap.get(i));
                system.debug('Parent: ' + toInsertHwLines[supportIndexToHwLineMap.get(i)].Id);
                
                if(toInsertHwLines != null && !toInsertHwLines.IsEmpty()
                   && supportIndexToHwLineMap != null 
                   && supportIndexToHwLineMap.get(i) != null
                   && toInsertHwLines[supportIndexToHwLineMap.get(i)].Id != null){
                       supportLine.SBQQ__RequiredBy__c = toInsertHwLines[supportIndexToHwLineMap.get(i)].Id;
                       system.debug('ReqBy: ' + supportLine.SBQQ__RequiredBy__c);
                   }
                
                //Start- ARY-258: Added by Shaloo
                if (conversionQuote != null
                    && conversionQuote.SBQQ__Type__c == 'Renewal+Expansion'
                    && conversionQuoteGroup != null
                    && supportLine.Product_Type__c == 'HW Support'
                    && supportLine.Special_Program__c == 'Conversion'
                    && quoteGroupIds != null
                   ) {
                       supportLine.SBQQ__Group__c = quoteGroupIds;
                       supportLine.Disposition_Reason__c = 'Renewing';
                   }
                system.debug('HW Support SKU: ' + supportLine.SBQQ__Product__c);
                //End- ARY-258: Added by Shaloo
                
                //added by madhura ----
                //Start Summer Release changes- added this snippet outside below if block
                if(supportLine.Arroyo_Subscribed_Asset_Name__c != null){
                    for(String assetName : supportLine.Arroyo_Subscribed_Asset_Name__c.split(',')){
                        assetName = assetName.trim();
                        
                        String str11 = '';
                        if(!assetHWsupport.isEmpty() && assetHWsupport.containsKey(assetName)){
                            str11 += assetHWsupport.get(assetName);
                            supportLine.Arroyo_Subsumed_Old_Contract_Line_Items__c = str11;
                            supportLine.SBQQSC__RenewedContractLine__c = str11;
                            supportLine.Subscribed_Asset_Name__c = supportLine.Arroyo_Subscribed_Asset_Name__c;
                            supportLine.SubscribedAssetNames__c = supportLine.Arroyo_Subscribed_Asset_Name__c;
                            supportLine.SubsAstNameInt__c = supportLine.Arroyo_Subscribed_Asset_Name__c;
                        }
                     }
                  } //END Summer Release changes- added this snippet outside below if block
                
                if(qliRenHWSupportLine != null && !qliRenHWSupportLine.IsEmpty())
                {
                    for(SBQQ__QuoteLine__c quoteLineObj: qliRenHWSupportLine)
                    {
                        mapQLIIdVsRec.put(quoteLineObj.Id, quoteLineObj);
                        
                        system.debug('QLI Id: ' + quoteLineObj.Id);
                        List<String> str;
                        if(quoteLineObj.SubscribedAssetNames__c != null){
                            str = quoteLineObj.SubscribedAssetNames__c.split(',');
                            system.debug('str Id1: ' + str);
                        }
                        if(//quoteLineObj.SubscribedAssetNames__c == null && 
                            quoteLineObj.SubsAstNameInt__c != null){
                                str = quoteLineObj.SubsAstNameInt__c.split(', ');
                                system.debug('str Id2: ' + str);
                            }
                        /*if(quoteLineObj.SubscribedAssetNames__c == null && quoteLineObj.SubsAstNameInt__c != null){
str = quoteLineObj.SubsAstNameInt__c.split(', ');
system.debug('str Id2: ' + str);
}*/
                        //(removed snippet)Summer Release changes- added above this if block
                        //system.debug('str: ' + str + ' & strSize: ' + str.size());
                        if(str != null && !str.IsEmpty())
                        {
                            for(String strings1: str){
                                system.debug('RenAsstName: ' + strings1);
                                system.debug('H1: ' + supportLine.Arroyo_Subscribed_Asset_Name__c);
                                system.debug('H2: ' + supportLine.Quote_Line_Type__c);
                                system.debug('H3: ' + supportLine.Product_Type__c);
                                system.debug('H4: ' + supportLine.Special_Program__c);
                                
                                if(supportLine.Arroyo_Subscribed_Asset_Name__c.contains(strings1)
                                   //&& supportLine.Quote_Line_Type__c == 'Renewal' 
                                   && supportLine.Product_Type__c == 'HW Support'
                                   && supportLine.Special_Program__c == 'Conversion'
                                  ){
                                      //system.debug('Enter to SET Values' + supportLine.Id);
                                      //found = true;
                                      system.debug('stringsR: ' + strings1);
                                      system.debug('mapQLIIdVsRec: ' + mapQLIIdVsRec);
                                      system.debug('AB: ' + supportLine.Id);
                                      
                                      //quoteLineObj1.SBQQ__StartDate__c = mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__StartDate__c;
                                      //quoteLineObj1.SBQQ__EndDate__c = mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__EndDate__c;
                                      
                                      //quoteLineObj.Disposition_Reason__c = 'Converted';
                                      //quoteLineObj.SBQQ__Group__c = Quotegroupdes;
                                      //maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                                      supportLine.Special_Program__c = null;
                                      supportLine.Licensing_Model__c = mapQLIIdVsRec.get(quoteLineObj.Id).Licensing_Model__c;
                                      system.debug('Licensing Model: ' + supportLine.Licensing_Model__c);
                                      supportLine.Support_Split_Percent__c = mapQLIIdVsRec.get(quoteLineObj.Id).Support_Split_Percent__c;
                                      supportLine.CPQ_Uplift__c = mapQLIIdVsRec.get(quoteLineObj.Id).CPQ_Uplift__c;
                                      supportLine.RenewalQuantityPopulated__c = TRUE; 
                                      
                                      supportLine.SBQQ__SubscriptionTerm__c = mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__SubscriptionTerm__c;
                                      supportLine.SBQQ__DefaultSubscriptionTerm__c = mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__DefaultSubscriptionTerm__c;
                                      supportLine.SBQQ__ListPrice__c = mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__ListPrice__c;
                                      supportLine.SBQQ__ProrateMultiplier__c = mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__ProrateMultiplier__c;
                                      system.debug('Prorate Multiplier: ' + supportLine.SBQQ__ProrateMultiplier__c);
                                      
                                      supportLine.CPQ_Prior_Discount__c = mapQLIIdVsRec.get(quoteLineObj.Id).CPQ_Prior_Discount__c;
                                      system.debug('Prior Discount: ' + supportLine.CPQ_Prior_Discount__c);
                                      
                                      supportLine.SBQQ__ProratedListPrice__c = mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__ProratedListPrice__c;
                                      supportLine.RTAwithoutUplift__c  = (mapQLIIdVsRec.get(quoteLineObj.Id).RTAwithoutUplift__c  
                                                                          / str.size()).setScale(2);
                                      system.debug('RTAwithoutUplift__c : ' + supportLine.RTAwithoutUplift__c );
                                      
                                      supportLine.Prior_Net_Total__c = (mapQLIIdVsRec.get(quoteLineObj.Id).Prior_Net_Total__c 
                                                                        / str.size()).setScale(2);
                                      system.debug('Prior Net Total: ' + supportLine.Prior_Net_Total__c);
                                      
                                      if(mapQLIIdVsRec.get(quoteLineObj.Id).PNTperMonth__c != NULL){
                                          supportLine.PNTperMonth__c = (mapQLIIdVsRec.get(quoteLineObj.Id).PNTperMonth__c
                                                                        / str.size()).setScale(2);
                                          system.debug('PNTperMonth__c: ' + supportLine.PNTperMonth__c);
                                      }
                                      if(mapQLIIdVsRec.get(quoteLineObj.Id).PNTUpliftPerMonth__c != NULL){
                                          supportLine.PNTUpliftPerMonth__c = (mapQLIIdVsRec.get(quoteLineObj.Id).PNTUpliftPerMonth__c
                                                                              / str.size()).setScale(2);
                                          system.debug('PNTUpliftPerMonth__c: ' + supportLine.PNTUpliftPerMonth__c);
                                      }
                                      
                                      supportLine.Prior_Net_Total_With_Uplift__c = (mapQLIIdVsRec.get(quoteLineObj.Id).Prior_Net_Total_With_Uplift__c 
                                                                                    / str.size()).setScale(2);
                                      system.debug('Prior Net TotalW: ' + supportLine.Prior_Net_Total_With_Uplift__c); 
                                      
                                      supportLine.PriorACVwithUplift__c  = (mapQLIIdVsRec.get(quoteLineObj.Id).PriorACVwithUplift__c  
                                                                            / str.size()).setScale(2);
                                      system.debug('PriorACVwithUplift__c : ' + supportLine.PriorACVwithUplift__c );
                                      
                                      Decimal listTotal = supportLine.SBQQ__Quantity__c * mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__ProratedListPrice__c;
                                      if(listTotal != 0){
                                          supportLine.SBQQ__Discount__c = 
                                              (((listTotal - mapQLIIdVsRec.get(quoteLineObj.Id).Prior_Net_Total_With_Uplift__c) / 
                                                listTotal)*100).setScale(2);
                                      }
                                      //supportLine.SBQQ__Discount__c = mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__Discount__c;
                                      system.debug('Discount: ' + supportLine.SBQQ__Discount__c);
                                      
                                      /*supportLine.SBQQ__NetPrice__c = (mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__ProratedListPrice__c - 
((mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__ProratedListPrice__c 
* mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__Discount__c) / 100)).setScale(2);*/
                                      supportLine.SBQQ__NetPrice__c = (mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__ProratedListPrice__c - 
                                                                       ((mapQLIIdVsRec.get(quoteLineObj.Id).SBQQ__ProratedListPrice__c 
                                                                         * supportLine.SBQQ__Discount__c) / 100)).setScale(2);
                                      
                                      supportLine.Discount_Margin__c = mapQLIIdVsRec.get(quoteLineObj.Id).Discount_Margin__c;
                                      supportLine.Approval_Flags__c = mapQLIIdVsRec.get(quoteLineObj.Id).Approval_Flags__c;
                                      supportLine.Subscribed_Asset_Name__c = supportLine.Arroyo_Subscribed_Asset_Name__c;
                                      supportLine.SubscribedAssetNames__c = supportLine.Arroyo_Subscribed_Asset_Name__c;
                                      supportLine.SubsAstNameInt__c = supportLine.Arroyo_Subscribed_Asset_Name__c;
                                      
                                      
                                      supportLine.SubscribedAssetNames__c = supportLine.Arroyo_Subscribed_Asset_Name__c;
                                      supportLine.SBQQSC__RenewedContractLine__c = mapQLIIdVsRec.get(quoteLineObj.Id).SBQQSC__RenewedContractLine__c;
                                      system.debug('Renewed Contract Line: ' + supportLine.SBQQSC__RenewedContractLine__c);
                                      
                                      supportLine.Arroyo_Subsumed_Old_Contract_Line_Items__c = mapQLIIdVsRec.get
                                          (quoteLineObj.Id).Arroyo_Subsumed_Old_Contract_Line_Items__c;
                                      system.debug('Old Contract Line: ' + supportLine.Arroyo_Subsumed_Old_Contract_Line_Items__c);
                                      
                                      //maptoupdateQL.put(supportLine.Id, supportLine);
                                  }
                            }
                        }
                    }
                }
            }
        }
        system.debug('BeforeInsert: ' + toInsertSupportLines);
        insert toInsertSupportLines;
        system.debug('AfterInsert: ' + toInsertSupportLines);
        
        // Set the Is_RWD_Polaris_Quote__c on converted quote
        conversionQuote.Is_RWD_Polaris_Quote__c = true;
        //conversionQuote.Earliest_QuoteLine_StartDate__c = earliestQuoteLineStartDate;
        update conversionQuote;
        //updateDispositionReasonsGroup(conversionQuote.Id);//Added by Shaloo
        updateDispositionReasonsNew(conversionQuote.Id, qliListRecords);//Added by Shaloo
        return null;
    }
    
    /* ARY-218, 823: Start - Added by Shaloo */
    public static void updateDispositionReasonsNew(String qId, List <SBQQ__QuoteLine__c> qliListRecords){ /* CR #5 ARY-218, 823: Start - Added by Shaloo */
        
        List <SBQQ__QuoteLine__c> qliList = [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Product__c, Quote_Line_Type__c, SBQQ__Product__r.Eligible_for_RCDM_T__c,
                                             SBQQ__Group__c, Special_Program__c, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.Disposition_Reason__c, 
                                             Product_Type__c, Licensing_Model__c, SBQQ__NetPrice__c, Prior_Net_Total__c, CPQ_Prior_Discount__c, 
                                             Sales_Comp_Category__c, SBQQ__Product__r.Sales_Comp_Category__c,
                                             SBQQ__Discount__c, Discount_Margin__c, Approval_Flags__c, Arroyo_Subscribed_Asset_Name__c, 
                                             Subscribed_Asset_Name__c, SubscribedAssetNames__c,
                                             SBQQSC__RenewedContractLine__c, Arroyo_Subsumed_Old_Contract_Line_Items__c, SBQQ__ProratedListPrice__c,
                                             SBQQ__ProrateMultiplier__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SubsAstNameInt__c,
                                             SBQQ__SubscriptionTerm__c, SBQQ__DefaultSubscriptionTerm__c, SBQQ__ListPrice__c,
                                             SBQQ__Optional__c, SBQQ__Existing__c, SBQQ__Hidden__c, SBQQ__ProductCode__c
                                             FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: qId ORDER BY SBQQ__Number__c ASC];
        
        Id Quotegroupdes, Quotegrouprenew;
        Map<Id, SBQQ__QuoteLine__c> maptoupdateQL = new Map<Id, SBQQ__QuoteLine__c>();
        List <SBQQ__QuoteLine__c> qliRenHWSupportLine = new List <SBQQ__QuoteLine__c>();
        List <SBQQ__QuoteLine__c> qliConvNewWithSubsAsst= new List<SBQQ__QuoteLine__c>();
        Set<String> lstRefAssetNames;
        Boolean isRenewalANDExpansion = true;
        
        for(SBQQ__QuoteLineGroup__c grp: [SELECT Id, Name, SBQQ__Quote__c, SBQQ__Description__c, SBQQ__Quote__r.SBQQ__Type__c 
                                          FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: qId]){
                                              if(grp.Name == System.Label.Arry_Disposition_Group){
                                                  Quotegroupdes = grp.Id;
                                              }
                                              if(grp.Name == System.Label.Arry_renewal_Group){
                                                  Quotegrouprenew = grp.Id;
                                              }
                                              if(grp.SBQQ__Quote__r.SBQQ__Type__c != 'Renewal+Expansion'){
                                                  isRenewalANDExpansion = false;
                                              }
                                          }
        
        if(Quotegroupdes == null && isRenewalANDExpansion){
            SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c();
            qlg.Name = System.Label.Arry_Disposition_Group;
            qlg.Is_Disposition_Group__c = TRUE;
            qlg.SBQQ__Quote__c = qId;
            qlg.SBQQ__Description__c = CPQ_Constants.DISPOSE_QUOTE_DESCRIPTION;
            insert qlg;
            
            Quotegroupdes = qlg.Id;
        }
        
        if(!qliList.IsEmpty()){
            lstRefAssetNames = new Set<String>();
            
            for(SBQQ__QuoteLine__c quoteLineObj: qliList){               
                if(quoteLineObj.Special_Program__c == 'Conversion'){
                    qliConvNewWithSubsAsst.add(quoteLineObj);
                }
                
                if(quoteLineObj.Quote_Line_Type__c == 'New' && quoteLineObj.Arroyo_Subscribed_Asset_Name__c != null && String.isNotBlank(quoteLineObj.Arroyo_Subscribed_Asset_Name__c)){
                    for(String assetName : quoteLineObj.Arroyo_Subscribed_Asset_Name__c.split(',')){
                        assetName = assetName.trim();
                        lstRefAssetNames.add(assetName);
                    }
                }
                if(quoteLineObj.Quote_Line_Type__c == 'Renewal' && quoteLineObj.Product_Type__c == 'HW Support' && quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null){
                    qliRenHWSupportLine.add(quoteLineObj);
                }
            }
            
            if(qliRenHWSupportLine != null && !qliRenHWSupportLine.IsEmpty()){
                for(SBQQ__QuoteLine__c quoteLineObj: qliRenHWSupportLine) {
                    List<String> str;
                    if(quoteLineObj.SubscribedAssetNames__c != null){
                        str = quoteLineObj.SubscribedAssetNames__c.split(',');
                    }
                    if(quoteLineObj.SubsAstNameInt__c != null){
                        str = quoteLineObj.SubsAstNameInt__c.split(', ');
                    }
                    
                    Boolean found = false;
                    if(str != null && !str.IsEmpty()){
                        for(String strings1: str){
                            if(qliConvNewWithSubsAsst != null && !qliConvNewWithSubsAsst.IsEmpty()){
                                for(SBQQ__QuoteLine__c quoteLineObj1: qliConvNewWithSubsAsst){                                    
                                    if(quoteLineObj1.Arroyo_Subscribed_Asset_Name__c.contains(strings1) && quoteLineObj1.Quote_Line_Type__c == 'Renewal' && quoteLineObj1.Product_Type__c == 'HW Support'){
                                        found = true;
                                    }
                                    else{
                                        found = false; 
                                    }
                                }
                            }
                        }
                    }
                    if(found == false){
                        continue;
                    }
                }
            }
            
            for(SBQQ__QuoteLine__c quoteLineObj: qliList){
                if(quoteLineObj.Quote_Line_Type__c == 'Renewal' && quoteLineObj.SubscribedAssetNames__c != null && quoteLineObj.Special_Program__c != 'Conversion' && quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null){
                    if(lstRefAssetNames!= null && !lstRefAssetNames.IsEmpty()){
                        for(String str: lstRefAssetNames){
                            if(quoteLineObj.SubscribedAssetNames__c.contains(str)){
                                if(quoteLineObj.SBQQ__ProductCode__c != null && quoteLineObj.SBQQ__ProductCode__c.contains('NRD')){
                                    quoteLineObj.Disposition_Reason__c = 'Renewing'; 
                                    quoteLineObj.SBQQ__Group__c = Quotegrouprenew;
                                }
                                else{
                                    quoteLineObj.Disposition_Reason__c = 'Converted';
                                    quoteLineObj.SBQQ__Group__c = Quotegroupdes;
                                    quoteLineObj.SBQQ__Optional__c = TRUE;
                                    quoteLineObj.SBQQ__Existing__c = TRUE;
                                    quoteLineObj.SBQQ__Hidden__c = TRUE;
                                }
                                maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                            }
                        }
                    }
                }
                else if (quoteLineObj.Quote_Line_Type__c == 'Renewal' && quoteLineObj.SubscribedAssetNames__c == null && quoteLineObj.SubsAstNameInt__c != null && quoteLineObj.Special_Program__c != 'Conversion'){
                    if(lstRefAssetNames!= null && !lstRefAssetNames.IsEmpty()){
                        for(String str: lstRefAssetNames){
                            if(quoteLineObj.SubsAstNameInt__c.contains(str)){                                         
                                if(quoteLineObj.SBQQ__ProductCode__c != null && quoteLineObj.SBQQ__ProductCode__c.contains('NRD')){
                                    quoteLineObj.Disposition_Reason__c = 'Renewing'; 
                                    quoteLineObj.SBQQ__Group__c = Quotegrouprenew;
                                }
                                else{
                                    quoteLineObj.Disposition_Reason__c = 'Converted';
                                    quoteLineObj.SBQQ__Group__c = Quotegroupdes;
                                    quoteLineObj.SBQQ__Optional__c = TRUE;
                                    quoteLineObj.SBQQ__Existing__c = TRUE;
                                    quoteLineObj.SBQQ__Hidden__c = TRUE;
                                }
                                maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                            }
                        }
                    }
                }
            }
            //Logic to set disposition for HW lines related to HW support
            for (SBQQ__QuoteLine__c quoteLineObj: qliList) {
                if(quoteLineObj.Quote_Line_Type__c == 'Existing'){                    
                    if(maptoupdateQL != null && !maptoupdateQL.IsEmpty()){
                        for(SBQQ__QuoteLine__c qli: maptoupdateQL.values()){
                            if(quoteLineObj.Id == qli.SBQQ__RequiredBy__c){
                                quoteLineObj.SBQQ__Hidden__c = TRUE;
                                quoteLineObj.Disposition_Reason__c = 'Converted';
                                quoteLineObj.SBQQ__Group__c = Quotegroupdes;
                                quoteLineObj.SBQQ__Optional__c = TRUE;
                                quoteLineObj.SBQQ__Existing__c = TRUE;
                                quoteLineObj.SBQQ__Hidden__c = TRUE;
                                maptoupdateQL.put(quoteLineObj.Id, quoteLineObj);
                            }
                        }
                    }
                }
            }
        }
        if(!maptoupdateQL.values().isEmpty()){
            try{
                update maptoupdateQL.values();
            } catch(Exception e){
                System.debug('Insert Error:' + e.getMessage());
            }
        }
    }
    //ARY-218. 823: End - Added by Shaloo
    // Method to get the NIC Type for new combinations
    static String getNICtype (String NICType) {
        if (NICType == '10GBase-T') {
            return '10GBase-T NIC (Copper)';
        } else if (NICType == 'SFP+') {
            return 'SFP+ NIC (Fiber)';
        } else {
            return NICType;
        }
    }
    /*Booster method
    public static void boosterMethod (){
        Integer i=0;
        System.debug(i);
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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
    
    /* Wrapper class for asset table*/
    public class AssetWrapper {
        /* selected*/
        public Boolean selected                     { get; set; }
        /* asset*/
        public Asset asset                          { get; set; }
        /* convertSaasProductId*/
        public Id convertSaasProductId              { get; set; }
        /* convertSaasProduct*/
        public Product2 convertSaasProduct          { get; set; }
        /* licenseType*/
        public String licenseType                   { get; set; }
        /* assetGroup*/
        public String assetGroup                    { get; set; }
        /* isConversionPossible*/
        public Boolean isConversionPossible         { get; set; }
        /* conversionError*/
        public String conversionError               { get; set; }
        /* Added new attribute */
        private List<Entitlement> childEntitlements;//Added new attribute
        /* originalOrderItem*/
        private OrderItem originalOrderItem;
        /**childOrderItems */
        private List<OrderItem> childOrderItems;
        
        /* Constructor */
        public AssetWrapper() {
            childEntitlements = new List<Entitlement>();
            childOrderItems = new List<OrderItem>();
            isConversionPossible = true;
            licenseType = 'SaaS';
        }
    }
}