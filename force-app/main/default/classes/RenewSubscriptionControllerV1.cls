/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 10-03-2022
* @last modified by  : Saurav Nirwal
* Modifications Log 
* Ver   Date         Author           Modification
* 1.0   11-18-21   Bryce Kilker   Initial Version
**/



public class RenewSubscriptionControllerV1 {
    
    public SBQQ__Quote__c quote {get; private set;}
    public List<ContractLineItem> CLI { get; set; }
    public String currentRecordId {get;set;}
    public List<SBQQ__Quote__c> quoteToProcess {get; set;}
    public Set<String> rbkContainsProductSet = new Set<String>();
    public List<SKU_Pricing_Products__mdt> listMetaData = new List<SKU_Pricing_Products__mdt>();
    public Map<String, String> newProductsMapFromMetadata = new Map<String, String>();
    public Set<String> splitProductNamesSet = new Set<String>();
    
    
    
    public List<ContractLineItemWrapper> contractLineItemWrapperList { get; set; }
    public Boolean allServiceContractChecked { get; set; }
    public Boolean landingPageRender {get; set;}
    
    public Boolean renderSecondPage {get; set;}
    public List<SelectedCLIAndProductWrapper> allSelectedCLIAndProductWrapperList{ get; set; }
    public Boolean allCLIProductsChecked { get; set; }
    
    public Map<String, Product2> mapSplitPricingProductNameVsProduct = new Map<String, Product2>();
    public Map<Id, List<ContractLineItem>> oldProductIdVsContractLineItemMap = new Map<Id, List<ContractLineItem>>();
    
    public List<SBQQ__QuoteLine__c> quoteLinesList { get; set; }
    public Set<Id> productIdsSet;
    Boolean renewToOld = false;
    Map<Id, List<Polaris_SKU_Mapping_V2__c>> oldProductVsPolarisSKUMappingListMap = new Map<Id, List<Polaris_SKU_Mapping_V2__c>>();
    
    public RenewSubscriptionControllerV1(ApexPages.StandardController controller) {
        currentRecordId  = ApexPages.CurrentPage().getparameters().get('newid');
        landingPageRender = true;
        renderSecondPage = false;
        allServiceContractChecked = false;
        allCLIProductsChecked = false;
        productIdsSet = new Set<Id>();
        contractLineItemWrapperList = new List<ContractLineItemWrapper>();
        allSelectedCLIAndProductWrapperList = new List<SelectedCLIAndProductWrapper>();
        quoteLinesList = new List<SBQQ__QuoteLine__c>();
        //RWD-1316 - Added Support Tier field
        listMetaData =[SELECT Old_Product__c, New_Product__c, Support_Tier__c FROM SKU_Pricing_Products__mdt];
        
        // Set<String> splitProductNamesSet = new Set<String>{'RS-HW-SVC-PE', 'RS-SW-SVC-PE', 'RS-HW-SVC-L3', 'RS-SW-SVC-L3'};
        
        for (SKU_Pricing_Products__mdt pricingProduct : listMetaData ) {
            String tierKey = (String.isNotBlank(pricingProduct.Support_Tier__c)) ? pricingProduct.Support_Tier__c+'-'+pricingProduct.Old_Product__c : '-'+pricingProduct.Old_Product__c;
            newProductsMapFromMetadata.put(tierKey, pricingProduct.New_Product__c);
            splitProductNamesSet.add(pricingProduct.New_Product__c);
        }
        
        
        if(currentRecordId == null || currentRecordId == '') {
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Quote Id Not Found'));
        }
        
        //RWD-1316 - Added Support Tier field
        for (Product2 product : [SELECT Id, Name, Category__c,Support_Tier__c FROM Product2 WHERE Name IN: splitProductNamesSet]) {
            
            mapSplitPricingProductNameVsProduct.put(product.Name, product);
        }
        quote = (currentRecordId == null) ? new SBQQ__Quote__c() :
        [ SELECT Id
         , SBQQ__Account__c
         , SBQQ__Opportunity2__c,Amended_Renewed_Service_Contract__c
         , SBQQ__Opportunity2__r.Pricebook2id
         , Co_Term_Date__c
         , (SELECT SBQQSC__RenewedContractLine__c FROM SBQQ__LineItems__r)
         FROM SBQQ__Quote__c
         WHERE Id =: currentRecordId
        ];
            
            if(quote == null) {
                
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Quote Not Found'));
            }
        
        
        Set<Id> cliRenewed = new Set<Id>();
        for (SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r){
            //contract lines already renewed on quote
            cliRenewed.add(qli.SBQQSC__RenewedContractLine__c);
        }
        
        //RWD-1316 - Added SBQQSC__RequiredByProduct__r.Support Tier field
        CLI = (quote == null) ? new List<ContractLineItem>() :
        [
            SELECT Id
            , ServiceContract.ContractNumber //Added on 15-07-2022 RWD-1570
            , Quantity //Added on 15-07-2022
            , SBQQSC__RenewalQuantity__c
            , SBQQSC__ListPrice__c
            , TotalPrice
            , SBQQSC__Discount__c
            , SBQQSC__AdditionalDiscountAmount__c
            , SBQQSC__BillingFrequency__c
            , SBQQSC__Bundled__c
            , SBQQSC__Bundle__c
            , SBQQSC__ComponentDiscountedByPackage__c
            , SBQQSC__ComponentSubscriptionScope__c
            , ServiceContractId
            , ServiceContract.Name
            , ServiceContract.SBQQSC__RenewalTerm__c
            , Description
            , SBQQSC__DiscountSchedule__c
            , SBQQSC__DiscountScheduleType__c
            , SBQQSC__DistributorDiscount__c
            , SBQQSC__DynamicOptionId__c
            , Product2Id, Product2.Name
            , Product2.Product_Level__c
            , Product2.Product_Type__c
            , Product2.Pricebook_Entry_Id__c
            , Product2.Product_Payment_Option__c
            , Product2.Support_Type__c
            , EndDate
            , List_Total__c
            , SBQQSC__MarkupAmount__c
            , SBQQSC__Number__c
            , SBQQSC__OptionDiscount__c
            , SBQQSC__OptionDiscountAmount__c
            , StartDate
            , SBQQSC__Product__c
            , SBQQSC__OptionLevel__c
            , SBQQSC__OptionType__c
            , SBQQSC__BundledQuantity__c
            , SBQQSC__PackageProductCode__c
            , SBQQSC__PackageProductDescription__c
            , Payment_Options__c
            , SBQQSC__PartnerDiscount__c
            , SBQQSC__Dimension__c
            , SBQQSC__PricingMethod__c
            , SBQQSC__ProductSubscriptionType__c
            , ListPrice
            , SBQQSC__ProrateMultiplier__c
            , SBQQSC__SegmentIndex__c
            , SBQQSC__SegmentKey__c
            , SBQQSC__SegmentLabel__c
            , SBQQSC__SpecialPrice__c
            , SBQQSC__SubscriptionPricing__c
            , Subscription_Term__c
            , SBQQSC__SubscriptionType__c
            , SBQQSC__TermDiscountSchedule__c
            , SBQQSC__UnitCost__c
            , CPQ_Uplift__c
            , SBQQSC__StartDate__c
            , TPH_Models_Gen__c
            , TPH_OEM__c
            , TPH_Quantity__c
            , Renewed__c
            , SBQQSC__ProductName__c
            , SBQQSC__Product__r.Name
            , SBQQSC__Product__r.Product_Level__c
            , LineItemNumber
            , Support_Type__c
            , ServiceContract.EndDate
            , ServiceContract.Renew_to_Old_SKUs__c
            , SBQQSC__RequiredByProduct__c
            , SBQQSC__RequiredByProduct__r.Name
            , SBQQSC__RequiredByProduct__r.Support_Tier__c
            , SBQQSC__RequiredById__c, SBQQSC__RootId__c
            , Licensing_Model__c
            , ServiceContract.SBQQSC__ActiveContract__c
            , Rubrik_Suite__c
            , (SELECT AssetId,Asset.Name,Asset.SBQQSC__RequiredByLineItem__c, 
            Asset.Product2.Product_Level__c, Asset.Product2.Product_Type__c, Asset.Product2.Pricebook_Entry_Id__c, Asset.Product2.Name,
            Asset.SBQQ__QuoteLine__r.SBQQ__ListPrice__c
                FROM Entitlements where Renewal_Category__c = '')
            FROM  ContractLineItem
            WHERE SBQQSC__Account__c =: quote.SBQQ__Account__c
            //AND Renewed__c = false Commented for REEN-24
            //AND  ServiceContract.SBQQSC__ActiveContract__c = 1 Commented for CPQ22-1870
            //AND ServiceContract.Id !=: quote.Amended_Renewed_Service_Contract__c
            //AND SBQQSC__RenewedDate__c = null Commented for REEN-24
            AND Id NOT IN :cliRenewed //REEN-24
            AND SBQQSC__RenewalQuantity__c > 0 //REEN-24
            ORDER BY ServiceContract.ContractNumber, LineItemNumber //Added on 15-07-2022 RWD-1570
        ];
            
            if(CLI == null || CLI.isEmpty()) {
                
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Contract Line Items Not Found'));
            }
        for(ContractLineItem contractLineItem : CLI) {
            productIdsSet.add(contractLineItem.Product2Id);
            productIdsSet.add(contractLineItem.SBQQSC__RequiredByProduct__c);
            contractLineItemWrapperList.add(new ContractLineItemWrapper(contractLineItem));
           // system.debug('@#1 ' + contractLineItem.Product2Id);
        }
    }
    
    public PageReference checkAllServiceContractItems() {
        
        for(ContractLineItemWrapper contractLineItemWrapperObj : contractLineItemWrapperList){
            contractLineItemWrapperObj.selected = allServiceContractChecked;
        }
        
        return null;
    }
    public PageReference handleCancel() {
        
        PageReference quotePageReference = new PageReference('/apex/sbqq__sb?scontrolCaching=1&id='+currentRecordId+'#quote/le?qId='+currentRecordId);
        quotePageReference.setRedirect(true);
        return quotePageReference;
    }
    
    public PageReference handleNext() {
        
        allSelectedCLIAndProductWrapperList.clear();
        oldProductIdVsContractLineItemMap.clear();
        landingPageRender = false;
        renderSecondPage = true;
        identifyMappingStructureForCLI(mapSplitPricingProductNameVsProduct);
        
        return null;
    }
    
    public PageReference handleBack() {
        
        landingPageRender = true;
        renderSecondPage = false;
        
        return null;
    }
    
    public PageReference handleRenew() {
        
        try {   
            if(validate()) {
                //create qoute lines with v1 products
                Boolean isOldQuoteLineInserted = createQLIFromCLIForRenew();
                
                if(isOldProductPresent() && isOldQuoteLineInserted) {
                    //convert v1 to v2 batch
                    Database.executeBatch(new ConvertToSaasRenewalBatch(new List<SBQQ__Quote__c>{quote}));
                }
                
                PageReference quotePageReference = new PageReference('/'+currentRecordId);
                quotePageReference.setRedirect(true);
                return quotePageReference;
            }
        }
        catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error : '+e.getMessage()));
        }
        
        return null;
    }
    
    public Boolean validate(){
        for(SelectedCLIAndProductWrapper cliWrapper : allSelectedCLIAndProductWrapperList) {
            if(cliWrapper.selectedCLiandProduct) {
                return true;
            }
        }
        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Select Atleast One Record To Renew'));
        return false;
    }
    
    public boolean isOldProductPresent(){
        for(SelectedCLIAndProductWrapper cliWrapper : allSelectedCLIAndProductWrapperList) {
            if(cliWrapper.selectedCLiandProduct && String.isBlank(cliWrapper.selectedContractLineItem.Product2.Product_Level__c)) {
                return true;
            }
        }
        return false;
    }
    
    public PageReference checkCLIProducts() {
        
        for(SelectedCLIAndProductWrapper selectedCLIAndProductWrapperObj : allSelectedCLIAndProductWrapperList) {
            
            if(selectedCLIAndProductWrapperObj.disableCheckbox == true) {
                
                selectedCLIAndProductWrapperObj.selectedCLiandProduct = false;
            } else {
                
                selectedCLIAndProductWrapperObj.selectedCLiandProduct = allCLIProductsChecked;
            }
        }
        return null;
    }
    
    public void identifyMappingStructureForCLI(Map<String, Product2> mapSplitPricingProductNameVsProduct) {
        
        if(!contractLineItemWrapperList.isEmpty()) {
            
            for(ContractLineItemWrapper contractLineItemWrapperObj : contractLineItemWrapperList) {
                if(contractLineItemWrapperObj.selected == true) {
                    if(!oldProductIdVsContractLineItemMap.containsKey(contractLineItemWrapperObj.contractLineItem.SBQQSC__Product__c)) {
                        oldProductIdVsContractLineItemMap.put(contractLineItemWrapperObj.contractLineItem.SBQQSC__Product__c, new List<ContractLineItem>());
                    }
                    oldProductIdVsContractLineItemMap.get(contractLineItemWrapperObj.contractLineItem.SBQQSC__Product__c).add(contractLineItemWrapperObj.contractLineItem);
                }
            }
        }
        
        //RWD-1316 - Added Support Tier field, Fix for SF-25590
        List<Polaris_SKU_Mapping_V2__c> polarisProductSKUMappingList = [SELECT Id
                                                                        , New_Product__r.Category__c
                                                                        /*, Hardware_Product__c
, Hardware_Product__r.Name
, Hardware_Product__r.Category__c*/
                                                                        , New_Product__c
                                                                        , New_Product__r.Support_Type__c
                                                                        , New_Product__r.ProductCode
                                                                        , New_Product__r.Family
                                                                        , New_Product__r.Product_Payment_Option__c
                                                                        , New_Product__r.Name
                                                                        , New_Product__r.Product_Level__c
                                                                        , Old_Product__r.Product_Level__c
                                                                        , Payment_Option__c
                                                                        , Support_Type__c
                                                                        , Old_Product__c
                                                                        , Support_Tier__c
                                                                        //, Usable_Capacity__c
                                                                        //, Product_Bundle_Parent__c
                                                                        FROM Polaris_SKU_Mapping_V2__c
                                                                        WHERE Old_Product__c IN : productIdsSet AND New_Product__r.Name != 'Does not Renew'];
        
        
        if(!polarisProductSKUMappingList.isEmpty()) {
            
            for(Polaris_SKU_Mapping_V2__c polarisProductSKUMappingObj : polarisProductSKUMappingList) {
                
                if (oldProductVsPolarisSKUMappingListMap.containsKey(polarisProductSKUMappingObj.Old_Product__c)) {
                    
                    oldProductVsPolarisSKUMappingListMap.get(polarisProductSKUMappingObj.Old_Product__c).add(polarisProductSKUMappingObj);
                } else {
                    
                    oldProductVsPolarisSKUMappingListMap.put(polarisProductSKUMappingObj.Old_Product__c, new List<Polaris_SKU_Mapping_V2__c> {polarisProductSKUMappingObj});
                }
            }
        }
        
        system.debug('*********** oldProductVsPolarisSKUMappingListMap '+oldProductVsPolarisSKUMappingListMap);
        
        if(!oldProductIdVsContractLineItemMap.isEmpty()) {
            Set<id> CLISet = new Set<id>();
            for(Id oldProductId : oldProductIdVsContractLineItemMap.keySet()) {
                for(ContractLineItem contractLine : oldProductIdVsContractLineItemMap.get(oldProductId)) {
                    
                    boolean cliadded= CLISet.add(contractLine.id);
                    if(!cliadded)
                        continue;
                    if(
                        // Check for split pricing statically for 2 products mentioned explictily
                        contractLine.SBQQSC__Product__r.Name == 'RBK-SVC-PREM-APPLIANCE' ||
                        contractLine.SBQQSC__Product__r.Name == 'RBK-SVC-APPLIANCE-L3'
                    ) {
                        String parentTier = contractLine.SBQQSC__RequiredByProduct__r.Support_Tier__c;
                        
                        if(contractLine.SBQQSC__Product__r.Name == 'RBK-SVC-PREM-APPLIANCE') {
                            String key = parentTier + '-'+'RBK-SVC-PREM-APPLIANCE';
                            String key2 = '-' + 'RBK-SVC-PREM-APPLIANCE';
                            String newExpectedHWProduct = newProductsMapFromMetadata.get(key);
                            String newExpectedSWProduct = newProductsMapFromMetadata.get(key2);
                            
                            allSelectedCLIAndProductWrapperList.add(
                                new SelectedCLIAndProductWrapper(
                                    new List<Polaris_SKU_Mapping_V2__c> {
                                        new Polaris_SKU_Mapping_V2__c (
                                            Old_Product__c = contractLine.SBQQSC__Product__c,
                                            New_Product__r = mapSplitPricingProductNameVsProduct.get(newExpectedHWProduct)
                                        ),
                                            new Polaris_SKU_Mapping_V2__c (
                                                Old_Product__c = contractLine.SBQQSC__Product__c,
                                                New_Product__r = mapSplitPricingProductNameVsProduct.get(newExpectedSWProduct)
                                            )
                                            },
                                    contractLine,
                                    false
                                )
                            );
                        } else if (contractLine.SBQQSC__Product__r.Name == 'RBK-SVC-APPLIANCE-L3') {
                            String key = parentTier + '-'+'RBK-SVC-APPLIANCE-L3';
                            String key2 = '-' + 'RBK-SVC-APPLIANCE-L3';
                            String newExpectedHWProduct = newProductsMapFromMetadata.get(key);
                            String newExpectedSWProduct = newProductsMapFromMetadata.get(key2);
                            
                            allSelectedCLIAndProductWrapperList.add(
                                new SelectedCLIAndProductWrapper(
                                    new List<Polaris_SKU_Mapping_V2__c> {
                                        new Polaris_SKU_Mapping_V2__c (
                                            Old_Product__c = contractLine.SBQQSC__Product__c,
                                            New_Product__r = mapSplitPricingProductNameVsProduct.get(newExpectedHWProduct)
                                        ),
                                            new Polaris_SKU_Mapping_V2__c(
                                                Old_Product__c = contractLine.SBQQSC__Product__c,
                                                New_Product__r = mapSplitPricingProductNameVsProduct.get(newExpectedSWProduct)
                                            )
                                            },
                                    contractLine,
                                    false
                                )
                            );
                        }
                    } else if(
                        //one to one
                        oldProductVsPolarisSKUMappingListMap.containsKey(oldProductId) &&
                        oldProductVsPolarisSKUMappingListMap.get(oldProductId).size() == 1
                    ) {
                       // system.debug('@#add2 ' + contractLine.Product2Id);
                        allSelectedCLIAndProductWrapperList.add(
                            new SelectedCLIAndProductWrapper(
                                oldProductVsPolarisSKUMappingListMap.get(oldProductId),
                                contractLine,
                                false
                            )
                        );
                    } else if (
                        // Check if there is One to Many Mapping present for Old SKU with New SKU
                        oldProductVsPolarisSKUMappingListMap.containsKey(oldProductId) &&
                        oldProductVsPolarisSKUMappingListMap.get(oldProductId).size() > 1
                    ) {
                        //RWD-1316 starts
                        String paymentOption = (contractLine.Payment_Options__c != null)
                            ? contractLine.Payment_Options__c
                            : contractLine.Product2.Product_Payment_Option__c;

                        String supportType = (contractLine.Support_Type__c != null)
                        ? contractLine.Support_Type__c
                        : contractLine.Product2.Support_Type__c;
                        
                        //SF-25590 Fix- Start
                        Set<Id> newProductId = new Set<Id>();
                        Boolean singleMapping = true;
                        
                        for(Polaris_SKU_Mapping_V2__c psm : oldProductVsPolarisSKUMappingListMap.get(oldProductId)){
                            
                            if(newProductId.size() > 0 && !newProductId.contains(psm.New_Product__c)){
                                singleMapping = false;
                            } 
                            newProductId.add(psm.New_Product__c);
                            
                        }
                        // This is one on one mapping, extra records in mapping are dummy to cover all payment option and support type combinations.
                        if(singleMapping == true){
                            if(oldProductVsPolarisSKUMappingListMap.get(oldProductId).size() > 0){
                                List<Polaris_SKU_Mapping_V2__c> newSingleMappedProduct = New List<Polaris_SKU_Mapping_V2__c>(); 
                                newSingleMappedProduct.add(oldProductVsPolarisSKUMappingListMap.get(oldProductId)[0]);
                               // system.debug('@#add3 ' + contractLine.Product2Id);
                                allSelectedCLIAndProductWrapperList.add(
                                    new SelectedCLIAndProductWrapper(
                                        newSingleMappedProduct,
                                        contractLine,
                                        false
                                    )
                                );
                            }  
                            
                        } //Fix for SF-25590 - End 
                        else{ // else part to run for one to many mapping
                            for (Polaris_SKU_Mapping_V2__c polarisSKUMapping : oldProductVsPolarisSKUMappingListMap.get(oldProductId)) {
                                if (polarisSKUMapping.Support_Tier__c == contractLine.SBQQSC__RequiredByProduct__r.Support_Tier__c || polarisSKUMapping.Support_Tier__c==null) {
                                    //Fix for SF-25590
                                    if(polarisSKUMapping.Support_Type__c == supportType &&
                                       polarisSKUMapping.Payment_Option__c == paymentOption) {
                                          // system.debug('@#add4 ' + contractLine.Product2Id);
                                           //oneToManyPolarisSKUMappingList.add(polarisSKUMapping);
                                           allSelectedCLIAndProductWrapperList.add(
                                               new SelectedCLIAndProductWrapper(
                                                   new List<Polaris_SKU_Mapping_V2__c> {
                                                       polarisSKUMapping
                                                           },
                                                   contractLine,
                                                   false
                                               )
                                           );
                                           //break;
                                       }
                                }
                            } //RWD-1316 - Ends
                        }
                        
                    } else if(oldProductIdVsContractLineItemMap.containsKey(oldProductId) && contractLine.SBQQSC__Product__r.Product_Level__c != '') {                    
                        //system.debug('@#add5 ' + contractLine.Product2Id);
                        allSelectedCLIAndProductWrapperList.add(
                            new SelectedCLIAndProductWrapper(
                                new List<Polaris_SKU_Mapping_V2__c> {},
                                contractLine,
                                false
                            )
                        );
                        
                    } else {
                       // system.debug('@#add6 ' + contractLine.Product2Id);
                        allSelectedCLIAndProductWrapperList.add(
                            new SelectedCLIAndProductWrapper(
                                new List<Polaris_SKU_Mapping_V2__c> {},
                                contractLine,
                                true
                            )
                        );
                    }
                }
            }
        } else {
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please Select Contract Line Item '));
        }
    }
    
    /**
    * Method to create renewed quote lins
    */
    public Boolean createQLIFromCLIForRenew() {
        
        // Stop the triggers
        SBQQ.TriggerControl.disable();
        QuoteTriggerHandler.disableQuoteTrigger = true;

        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> bundleLookup = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> hardwareLookup = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, ContractLineItem> cliMap = new Map<Id, ContractLineItem>();
        Date maxEndDate = quote.Co_Term_Date__c;
        
        for(SelectedCLIAndProductWrapper cliWrapper : allSelectedCLIAndProductWrapperList) {
            if(cliWrapper.selectedCLiandProduct && cliWrapper.selectedContractLineItem.Entitlements.size()>0) {
                ContractLineItem cli = cliWrapper.selectedContractLineItem;
                cliMap.put(cli.Id, cli);
                Entitlement ent = cli.Entitlements[0];
                
                //create hardware for support line
                if (ent.AssetId!=null && ent.Asset.Product2Id!=null && hardwareLookup!=null && !hardwareLookup.containsKey(cli.SBQQSC__RequiredById__c)){
                    //create hardware qli
                    
                   
                    SBQQ__QuoteLine__c hardwareQLI = createHardwareQLI(cli, ent.asset);
                    
                    quoteLines.add(hardwareQLI);

                    //add hardware qli to lookup
                    hardwareLookup.put(cli.SBQQSC__RequiredById__c, hardwareQLI);
                }

                //create quote line
                SBQQ__QuoteLine__c qli = createQLI(cli);
                
                quoteLines.add(qli);

                //add bundle qli to lookup
                if (ent.AssetId == null && cli.SBQQSC__Bundle__c){
                    bundleLookup.put(cli.Id, qli);
                }

                //set max enddate
                If(qli.SBQQ__EndDate__c!=null && (maxEndDate==null || qli.SBQQ__EndDate__c > maxEndDate)){
                    maxEndDate = qli.SBQQ__EndDate__c;
                }
            }
        }

        //update quote co-term date
        quote.Old_Co_Term_Date__c = null;
        if (quote.Co_Term_Date__c != maxEndDate && maxEndDate!=null){
            quote.Co_Term_Date__c = maxEndDate;
        }
        update quote;

        insert quoteLines;
        
        //set required by on quotelines
        if (quotelines!=null && !quotelines.isEmpty()){
            for (SBQQ__QuoteLine__c qli : quoteLines){
                ContractLineItem cli = cliMap.get(qli.SBQQSC__RenewedContractLine__c);
            
                //map hardware to bundle (v2)
                if (qli.SBQQ__RenewedAsset__c!=null && bundleLookup.containsKey(qli.SBQQ__RenewedAsset__r.SBQQSC__RequiredByLineItem__c)){
                    qli.SBQQ__RequiredBy__c = bundleLookup.get(qli.SBQQ__RenewedAsset__r.SBQQSC__RequiredByLineItem__c).Id;
                }
                //map addons to bundle (v2)
                else if (cli!=null && !cli.SBQQSC__Bundle__c   ){
                   
                    if((qli.Product_Type__c =='HW Support' || (cli.SBQQSC__PackageProductCode__c!= null && cli.SBQQSC__PackageProductCode__c.contains('-NRD-') )) /* && qli.Product_Level__c != null && */  && hardwareLookup.containsKey(cli.SBQQSC__RequiredById__c)){
                      
                        qli.SBQQ__RequiredBy__c= hardwareLookup.get(cli.SBQQSC__RequiredById__c).Id;
                        
                    //CPQKTLO-5864 end
                    }else{
                        if(bundleLookup.containsKey(cli.SBQQSC__RootId__c) ){
                          
                          qli.SBQQ__RequiredBy__c = bundleLookup.get(cli.SBQQSC__RootId__c).Id;
                         
                        }
                    }
                }
                //map support to hardware (v1 and v2), addons to hardware (v1)
                else if (cli!=null && hardwareLookup.containsKey(cli.SBQQSC__RequiredById__c) && qli.Product_Level__c != 'Hybrid Software'){
               // system.debug('Inside HW support req1122'+hardwareLookup.containsKey(cli.SBQQSC__RequiredById__c));
                    qli.SBQQ__RequiredBy__c = hardwareLookup.get(cli.SBQQSC__RequiredById__c).Id;
                }
            }
    
            update quoteLines;
        }
        
        // Start the triggers
        SBQQ.TriggerControl.enable();
        QuoteTriggerHandler.disableQuoteTrigger = false;
        return true;
    }
    
    /**
    * Method to create quote line
    */
    public SBQQ__QuoteLine__c createQLI(ContractLineItem cli) {
            
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
        qli.SBQQ__AdditionalDiscountAmount__c = cli.SBQQSC__AdditionalDiscountAmount__c;
        qli.SBQQ__BillingFrequency__c = cli.SBQQSC__BillingFrequency__c; 
        qli.SBQQ__Bundled__c = cli.SBQQSC__Bundled__c;
        qli.SBQQ__BundledQuantity__c = cli.SBQQSC__BundledQuantity__c;
        qli.SBQQ__ComponentDiscountedByPackage__c = cli.SBQQSC__ComponentDiscountedByPackage__c;
        qli.SBQQ__ComponentSubscriptionScope__c = cli.SBQQSC__ComponentSubscriptionScope__c;
        qli.SBQQ__Description__c = cli.Description;
        qli.SBQQ__Dimension__c = cli.SBQQSC__Dimension__c;
        qli.SBQQ__Discount__c = cli.SBQQSC__Discount__c;
        qli.SBQQ__DiscountSchedule__c = cli.SBQQSC__DiscountSchedule__c;
        qli.SBQQ__DiscountScheduleType__c = cli.SBQQSC__DiscountScheduleType__c;
        qli.SBQQ__DistributorDiscount__c = cli.SBQQSC__DistributorDiscount__c;
        qli.SBQQ__DynamicOptionId__c = cli.SBQQSC__DynamicOptionId__c;
        qli.SBQQ__ListPrice__c = cli.ListPrice;
        qli.Licensing_Model__c = cli.Licensing_Model__c;
        qli.SBQQ__MarkupAmount__c = cli.SBQQSC__MarkupAmount__c;
        qli.SBQQ__OptionDiscount__c = cli.SBQQSC__OptionDiscount__c;
        qli.SBQQ__OptionDiscountAmount__c = cli.SBQQSC__OptionDiscountAmount__c;
        qli.SBQQ__OptionLevel__c = cli.SBQQSC__OptionLevel__c;
        qli.SBQQ__OptionType__c = cli.SBQQSC__OptionType__c;
        qli.SBQQ__PackageProductDescription__c = cli.SBQQSC__PackageProductDescription__c;
        qli.SBQQ__PartnerDiscount__c = cli.SBQQSC__PartnerDiscount__c;
        qli.Payment_Options__c = cli.Payment_Options__c;
        qli.SBQQ__PricingMethod__c = cli.SBQQSC__PricingMethod__c;
        qli.SBQQ__Product__c = cli.Product2Id;
        qli.Product_Level__c = cli.Product2.Product_Level__c;
        qli.Product_Type__c = cli.Product2.Product_Type__c;
        qli.SBQQ__ProductSubscriptionType__c = cli.SBQQSC__ProductSubscriptionType__c;
        qli.SBQQ__ProratedListPrice__c = cli.ListPrice;
        qli.SBQQ__ProratedPrice__c = cli.ListPrice;
        qli.SBQQ__ProrateMultiplier__c = cli.SBQQSC__ProrateMultiplier__c;
        qli.SBQQ__PriorQuantity__c = cli.SBQQSC__RenewalQuantity__c;
        qli.SBQQ__Quantity__c = cli.SBQQSC__RenewalQuantity__c;
        qli.SBQQ__Quote__c = quote.Id;
        qli.SBQQSC__RenewedContractLine__c = cli.Id;
        qli.Rubrik_Suite__c = cli.Rubrik_Suite__c;
        qli.SBQQ__SegmentIndex__c = cli.SBQQSC__SegmentIndex__c;
        qli.SBQQ__SegmentKey__c = cli.SBQQSC__SegmentKey__c;
        qli.SBQQ__SegmentLabel__c = cli.SBQQSC__SegmentLabel__c;
        qli.SBQQ__SpecialPrice__c = cli.SBQQSC__SpecialPrice__c;
        qli.SBQQ__SubscriptionPricing__c = cli.SBQQSC__SubscriptionPricing__c;
        qli.SBQQ__SubscriptionType__c = cli.SBQQSC__SubscriptionType__c;
        qli.Support_Type__c = cli.Support_Type__c;
        qli.SBQQ__TermDiscountSchedule__c = cli.SBQQSC__TermDiscountSchedule__c;
        qli.TPH_Models_Gen__c =cli.TPH_Models_Gen__c;
        qli.TPH_OEM__c = cli.TPH_OEM__c;
        qli.TPH_Quantity__c =cli.TPH_Quantity__c;
        qli.SBQQ__UnitCost__c = cli.SBQQSC__UnitCost__c;
        qli.SBQQ__Uplift__c = String.isNotBlank(cli.CPQ_Uplift__c) ? Double.valueOf(cli.CPQ_Uplift__c) : null;
        qli.SBQQ__PricebookEntryId__c = cli.Product2.Pricebook_Entry_Id__c;
        
        qli.SBQQ__SubscriptionTerm__c = cli.ServiceContract.SBQQSC__RenewalTerm__c;
        qli.SBQQ__StartDate__c = cli.EndDate.addDays(1);
        qli.SBQQ__EndDate__c = qli.SBQQ__StartDate__c.addMonths((Integer)qli.SBQQ__SubscriptionTerm__c).addDays(-1);

        for(Entitlement ent : cli.Entitlements){
            qli.SubscribedAssetNames__c  = qli.SubscribedAssetNames__c  != null ? qli.SubscribedAssetNames__c  + ', ' + String.valueOf(ent.Asset.Name) : String.valueOf(ent.Asset.Name);
            qli.Subscribed_Asset_Name__c = qli.Subscribed_Asset_Name__c != null ? qli.Subscribed_Asset_Name__c + ', ' + String.valueOf(ent.Asset.Name) : String.valueOf(ent.Asset.Name);
        }
        
        return qli;
    }

    public SBQQ__QuoteLine__c createHardwareQLI(ContractLineItem cli, Asset asset) {

        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
        qli.Licensing_Model__c = cli.Licensing_Model__c;
        qli.SBQQ__OptionLevel__c = 1;
        qli.SBQQ__OptionType__c = 'Related Product';
        qli.SBQQ__Product__c = asset.Product2Id;
        qli.Product_Level__c = asset.Product2.Product_Level__c;
        qli.Product_Type__c = asset.Product2.Product_Type__c;
        qli.SBQQ__ProductSubscriptionType__c = cli.SBQQSC__ProductSubscriptionType__c;
        qli.Payment_Options__c = cli.Payment_Options__c;
        qli.SBQQ__ProrateMultiplier__c = 1;
        qli.SBQQ__PriorQuantity__c = cli.SBQQSC__RenewalQuantity__c;
        qli.SBQQ__Quantity__c = cli.SBQQSC__RenewalQuantity__c;
        qli.SBQQ__Quote__c = quote.Id;
        qli.Rubrik_Suite__c = cli.Rubrik_Suite__c;
        qli.SBQQ__SubscriptionType__c = cli.SBQQSC__SubscriptionType__c;
        qli.SBQQ__Uplift__c = String.isNotBlank(cli.CPQ_Uplift__c) ? Double.valueOf(cli.CPQ_Uplift__c) : null;
        qli.SBQQ__PricebookEntryId__c = asset.Product2.Pricebook_Entry_Id__c;
        qli.SBQQ__RenewedAsset__c = asset.Id;
        qli.SBQQ__RenewedAsset__r = asset;
        
        for(Entitlement ent : cli.Entitlements){
            qli.SBQQ__SubscribedAssetIds__c = qli.SBQQ__SubscribedAssetIds__c != null ? qli.SBQQ__SubscribedAssetIds__c + ', ' + String.valueOf(ent.AssetId) : String.valueOf(ent.AssetId);
        }
        
        return qli;
    }
    
    // Wrapper Class to hold the One to Many replacement Mappings
    public class ProductBundleWrapper {
        
        public SBQQ__QuoteLine__c firstLevelProduct {get;set;}
        public Map<SBQQ__QuoteLine__c, SBQQ__QuoteLine__c> secondWithThirdLevelProductMap {get;set;}
        public List<SBQQ__QuoteLine__c> secondLevelProduct {get;set;}
        public List<SBQQ__QuoteLine__c> thirdLevelProduct {get;set;}
        public SBQQ__Quote__c quote {get;set;}
        public Integer uniqueNo {get;set;}
    }
    
    public class ContractLineItemWrapper {
        
        public ContractLineItem contractLineItem {get; set;}
        public Boolean selected {get; set;}
        public Boolean activeContract{get; set;}
        
        public ContractLineItemWrapper(ContractLineItem contractLineItemObj) {
            
            contractLineItem = contractLineItemObj;
            if(contractLineItemObj.ServiceContract.SBQQSC__ActiveContract__c == 1){
                activeContract = true;
            }else{
                activeContract = false;
            }
            
            selected = false;
        }
    }
    
    public class SelectedCLIAndProductWrapper {
        
        public List<Polaris_SKU_Mapping_V2__c> newPolarisSKUMappingList {get; set;}
        public ContractLineItem selectedContractLineItem {get; set;}
        public Boolean selectedCLiandProduct {get; set;}
        public Boolean activeContract {get; set;}
        public Boolean disableCheckbox {get; set;}
        
        public SelectedCLIAndProductWrapper(List<Polaris_SKU_Mapping_V2__c> polarisSKUMappingList,
                                            ContractLineItem contractLineItemObj,
                                            Boolean checkboxDisableValue
                                           ) {
                                               newPolarisSKUMappingList = polarisSKUMappingList;
                                               selectedContractLineItem = contractLineItemObj;
                                               selectedCLiandProduct = false;
                                               disableCheckbox = checkboxDisableValue;
                                               if(contractLineItemObj.ServiceContract.SBQQSC__ActiveContract__c == 1){
                                                   activeContract = true;
                                               }else{
                                                   activeContract = false;
                                               }
                                           }
    }

}