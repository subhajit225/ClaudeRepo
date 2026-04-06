/**
* @File Name : ReplacementQuoteLineCreation.cls
* @description :This class creates quote line and CPQ Dispose lines from SMS UI on the basis of Disposition reason.
* FY25SR-1099,FY25SR-1089,FY25SR-1086,FY25SR-1083,FY25SR-1155,FY25SR-1159,FY25SR-1156,FY25SR-1095
* @Author :Khushboo Agrawal
* @Last Modified By :
* @Last Modified On : February 3, 2025
* @Modification Log :
* Test Class        :ReplacementQuoteLineCreationTest
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 3, 2025 |   | Initial Version
**/

public without sharing class ReplacementQuoteLineCreation { 
    
    public static final Map<String,String> DIS_REASON_SPECIAL_PROGRAM= 
        new Map<String,String>{'Upgraded'=>ReplacementConstants.UPGRADE_VALUE,'Converted'=>'Conversion'};//add Replaced,refresh
    public static String optyProgram = '';
    //added for FY25SR-1191 start   
    public static Boolean IsFipsAssetRefreshed = false;
    public static Set<Id> allAssetIds = new Set<Id>();
    public static Map<Id, Asset> selectAssetIDMap= new Map<Id, Asset>();
    //added for FY25SR-1191 End
    public static Integer num=0;
    public static Map<Id, Product2> productMap= new Map<Id, Product2>();
    public static Map<Id, Id> productPricebookEntryMap=new Map<Id, Id>();
    public static Map<Id, Entitlement> entitlementMap=new Map<Id, Entitlement>();
    public static Set<Date> sEntEndDates = new Set<Date>(); //FY25SR-1095
    //required for H/w Switch in case of Support switch  
    public static Map<String,Product2> ProductByCode=new MAp<String,Product2>();
    //To store CCLI to be inserted //FY25SR-1215 - Consolidation Changes
    public static Set<SBQQ__QuoteLine__c> consContractLinesInstances = new Set<SBQQ__QuoteLine__c>();
    //To store CCLI to be inserted //FY25SR-1215 - Consolidation Changes
    public static Set<SBQQ__QuoteLine__c> consolidatedLines = new Set<SBQQ__QuoteLine__c>();
    //To store CLI information - FY25SR-1215
    public static Map<Id, ContractLineItem> mapfCLIs = new Map<Id, ContractLineItem>();
    public static Map<Id, Decimal> contractLineCapacity = new Map<Id, Decimal>();
    // To store the auto added capacity lines and their related parent user lines
    public static Map<String,SBQQ__QuoteLine__c> capacityUserExpansionLinesMap = new Map<String,SBQQ__QuoteLine__c> (); //ITNPI-2901
    public static Map<String,SBQQ__QuoteLine__c> parentUserExpansionLinesMap = new Map<String,SBQQ__QuoteLine__c> (); //ITNPI-2901
    public static boolean skipAutoAddCapacitySkus = false;

     /***********************************************************************************************************
    * Method Name          : createNewQuoteLines
    * Date Created/Modified: 07/02/2025
    * Author               : Khushboo
    * @description         : Creates Quote Lines for each of the wrapper instance             
    * @return              : Quote Id
    * @param               quoteId
    * @param               lstWrapperEntitlement
    * @param               refreshWrapperData
    * @param               quoteDetail
    * Test Class Methods   :
    *********************************************************************************************************/
    @AuraEnabled
    public static id createNewQuoteLines(
        Id quoteId, 
        List<ReplacementRefreshWrapperData.wrapperData> lstWrapperEntitlement,
        List<RefreshWrapper> refreshWrapperData, String quoteDetail) {  
        try{
            List<ReplacementRefreshWrapperData.wrapperData> selectedEntitlements = new List<ReplacementRefreshWrapperData.wrapperData>();
            //to delete all the QLI related to Entitlement ids
            Set<Id> modifiedEntitlements = new Set<Id>();// to delete only modified lines
            Set<Id> modifiedSkuProductIds =new Set<Id>();//to delete SKUProductId related qlis in case of ManyToOne
            Set<Id> selectedEntitlementIdSet = new Set<Id>();
            Set<Id> inactiveEntitlementIdSet = new Set<Id>();
            Set<Id> selectedSKUIds= new Set<Id>();
            //FY25SR-1481-to exclude dispose h/w support for support switch in case of renewal quote
            Set<String> RenewalAssetonSupportSwitch= new Set<String>();
            //to store inactive entitlement againt active ent. Key will be (EntId + CustomIndex)-1ToMany->ENtId will be same
            Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> EntIdToInactiveEnt= 
                new Map<String,List<ReplacementJson.RelatedChildEntRowDetail>>();
            //store H/w support wrapper against asset (can be optimized for sure )
            Map<String,ReplacementRefreshWrapperData.wrapperData> HwEntIdagainstBaseEntId= 
                new Map<String,ReplacementRefreshWrapperData.wrapperData>();
            Set<id> modifiedOldSKUs = new Set<Id>();
            //get Custom Metadata records
            Map<String, Replacement_Field_Mapping__mdt> metaMap = Replacement_Field_Mapping__mdt.getAll();    
            if(lstWrapperEntitlement!=null && !lstWrapperEntitlement.isEmpty()){
                for(ReplacementRefreshWrapperData.wrapperData wrapper : lstWrapperEntitlement) {
                    if(wrapper.wrapBaseLicense!=null && !wrapper.wrapBaseLicense.isEmpty()){
                        //FY25SR-1215 Added modifiedOldSKUs
                        ReplacementQuoteLineCreationHelper.processWrapper(
                            wrapper.wrapBaseLicense
                          , modifiedEntitlements
                          , modifiedSkuProductIds
                          , EntIdToInactiveEnt
                          , inactiveEntitlementIdSet
                          , selectedEntitlements
                          , selectedEntitlementIdSet
                          , selectedSKUIds
                          , modifiedOldSKUs
                         , sEntEndDates);
                    }
                    //FY25SR-1215 Added modifiedOldSKUs
                    if(wrapper.wrapUpgradeEnt != null && !wrapper.wrapUpgradeEnt.isEmpty()){
                        ReplacementQuoteLineCreationHelper.processWrapper(
                          wrapper.wrapUpgradeEnt
                        , modifiedEntitlements
                        , modifiedSkuProductIds
                        , EntIdToInactiveEnt
                        , inactiveEntitlementIdSet
                        , selectedEntitlements
                        , selectedEntitlementIdSet
                        , selectedSKUIds
                        , modifiedOldSKUs
                        , sEntEndDates);
                    }
                    //FY25SR-1215 Added modifiedOldSKUs
                    if(wrapper.wrapHWSupportLines!=null && !wrapper.wrapHWSupportLines.isEmpty()){
                        ReplacementQuoteLineCreationHelper.processWrapper(
                          wrapper.wrapHWSupportLines
                        , modifiedEntitlements
                        , modifiedSkuProductIds
                        , EntIdToInactiveEnt
                        , inactiveEntitlementIdSet
                        , selectedEntitlements
                        , selectedEntitlementIdSet
                        , selectedSKUIds
                        , modifiedOldSKUs
                        , sEntEndDates);
                    }
                    //FY25SR-1207- Start
                    List<ReplacementRefreshWrapperData.WrapperData> replaceRefreshLicenses = 
                        new List<ReplacementRefreshWrapperData.WrapperData>();
                    if(wrapper.mapAssetEntitlements!=null) {
                        replaceRefreshLicenses = 
                            ReplacementQuoteLineCreationHelper.futureTransactionData(wrapper.mapAssetEntitlements);
                        ReplacementQuoteLineCreationHelper.processWrapper(
                          replaceRefreshLicenses
                        , modifiedEntitlements
                        , modifiedSkuProductIds
                        , EntIdToInactiveEnt
                        , inactiveEntitlementIdSet
                        , selectedEntitlements
                        , selectedEntitlementIdSet
                        , selectedSKUIds
                        , modifiedOldSKUs
                        , sEntEndDates
                        );
                    }
                    //FY25SR-1207- End
                    //bundle up H/w Support Wrapper againt its asset for support switch if the asset is selected in baselicense.
                    if(wrapper.wrapBaseLicense!=null && wrapper.wrapHWSupportLines!=null){
                        ReplacementQuoteLineCreationHelper.createAssetHwSupportWrapperMap(
                            wrapper.wrapBaseLicense, wrapper.wrapHWSupportLines, HwEntIdagainstBaseEntId);
                    }
                    //FY25SR-1207- Start
                    //Licensed R+R quote line
                    if(replaceRefreshLicenses != null && wrapper.wrapHWSupportLines!=null){
                        ReplacementQuoteLineCreationHelper.createAssetHwSupportWrapperMap(
                            replaceRefreshLicenses, wrapper.wrapHWSupportLines, HwEntIdagainstBaseEntId);
                    }
                    //FY25SR-1207- End
                }
            }
            //FY25SR-1191 start moved, added refresh wrapper
            allAssetIds=ReplacementQuoteLineCreationHelper.getSelectedAssetIds(
                    selectedEntitlements, refreshWrapperData);
            selectAssetIDMap = !allAssetIds.isEmpty() 
                             ? ReplacementQueryController.getAssetsBasedonIds( allAssetIds ) 
                             : new Map<Id, Asset>();
            //FY25SR-1191 end

            //FY25SR-1159,FY25SR-1155.
            List<RefreshWrapper> refreshRowList=new List<RefreshWrapper>();
            Set<Id> selectRefreshEntIds=new Set<Id>();
            Set<String> modifiedAssetIds=new Set<String>();//populate AssetIds for deletion
            Set<Id> selectedProductId= new Set<Id>();
            Set<Id> selectedSupportRefreshEntids= new Set<Id>(); 
            if(refreshWrapperData!=null && refreshWrapperData.size()>0){
                for(RefreshWrapper wrap:refreshWrapperData){
                    if(wrap.productId!=null){selectedProductId.add(wrap.productId);}
                    Boolean flag=false;
                    if(wrap.rows!=null){
                        for(RefreshWrapper.Row wrapRow:wrap.rows){
                            if(wrapRow.isModified==true) { 
                                if(wrapRow.previousAssetIds!=null){
                                modifiedAssetIds.addAll(wrapRow.previousAssetIds);
                                }
                                else if(wrapRow.selectedAssetIds!=null){
                                modifiedAssetIds.addAll(wrapRow.selectedAssetIds);
                                }
                            }
                            if(wrapRow.options!=null){
                                for(RefreshWrapper.Option opt:wrapRow.options){
                                    if(opt.selected==true){
                                        if (wrapRow.isModified==true){
                                            if(opt.supportProdId!=null){selectedProductId.add(opt.supportProdId);}
                                            if(opt.entitlementId!=null){selectRefreshEntIds.add(opt.entitlementId);}
                                            if(opt.supportEntId!=null){
                                                selectRefreshEntIds.add(opt.supportEntId);
                                                if(wrapRow.isSelected==true){
                                                    flag=true;
                                                    //to delete these entIds from repalcementJson/QLI and delete in case of support switch
                                                    selectedSupportRefreshEntids.add(opt.supportEntId);
                                                }
                                            }   
                                        }
                                        //FY25SR-1191 start 
                                        if (!ReplacementQuoteLineCreationHelper.IS_FIPS_ASSET_REFRESHED && wrapRow.isSelected) {
                                            Asset assetRecord = selectAssetIDMap.get(opt.value);
                                            if(assetRecord!=null && assetRecord.Product2Id!=null 
                                              && assetRecord.Product2.Product_SubType__c!=null 
                                              && assetRecord.Product2.Product_Subtype__c.contains(ReplacementConstants.FIPS)){
                                                ReplacementQuoteLineCreationHelper.IS_FIPS_ASSET_REFRESHED = true;
                                            }
                                        }
                                        //FY25SR-1191 end  
                                    }
                                }
                            } 
                        }
                    }
                    if(flag==true){
                        refreshRowList.add(wrap);  
                    }
                }            
            }
            if(selectedSupportRefreshEntids!=null && !selectedSupportRefreshEntids.isEmpty()){
                //delete R6K h/w support QuoteLine if QL got created.  
                modifiedEntitlements.addAll(selectedSupportRefreshEntids);
            }

        //Create a mapping of old and new SKU as key and mapping as the value
        //FY25SR-1215 - Moved below logic to this place
        Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMap = new Map<Id,Polaris_SKU_Mapping_V2__c>();
        Map <String, Polaris_SKU_Mapping_V2__c> v2MappingforHWsupport = new Map <String, Polaris_SKU_Mapping_V2__c>();
        for(Polaris_SKU_Mapping_V2__c skuMapping: ReplacementQueryController.getPolarisSKUMapping()) {
        if (!sourceSKUPolarisMap.containsKey(skuMapping.Old_Product__c)){
            sourceSKUPolarisMap.put(skuMapping.Old_Product__c,skuMapping);
        }
        
            String Key= skuMapping.Old_Product__c+'-'+(skuMapping.Support_Tier__c != null
                      ? skuMapping.Support_Tier__c:' ')+'-'+(skuMapping.Support_Type__c != null
                        ? skuMapping.Support_Type__c:' ')+'-'+(skuMapping.Payment_Option__c != null
                          ? skuMapping.Payment_Option__c:' ');
            v2MappingforHWsupport.put(Key, skuMapping);
        } 

        // Get the lines to be deleted from previous selection (only if modified)
        List<SBQQ__QuoteLine__c> qlToDelete= new List<SBQQ__QuoteLine__c>();
        List<CPQ_Disposition_Quote_Line__c> cpqDispositionLinesToDelete= new List<CPQ_Disposition_Quote_Line__c>();
        if((!modifiedEntitlements.isEmpty() || !modifiedAssetIds.isEmpty()) && quoteId!=null){
            //FY25SR-1215 - Added sourceSKUPolarisMap
            qlToDelete=ReplacementQueryController.getExistingQuoteLineForDeletion(
                quoteId,modifiedEntitlements,modifiedSkuProductIds,
                modifiedAssetIds, sourceSKUPolarisMap, modifiedOldSKUs);
            cpqDispositionLinesToDelete=
                ReplacementQueryController.getCpqDispositionLinesToDelete(quoteId,modifiedEntitlements);
            if (!qlToDelete.isEmpty() || !cpqDispositionLinesToDelete.isEmpty()) {
                ReplacementQuoteLineCreationHelper.disableTriggerControls();
                if(Schema.sObjectType.SBQQ__Quoteline__c.isDeletable()){
                   Database.delete(qlToDelete,true);
                }
                if(Schema.sObjectType.CPQ_Disposition_Quote_Line__c.isDeletable()){
                   Database.delete(cpqDispositionLinesToDelete,true); 
                }
                ReplacementQuoteLineCreationHelper.enableTriggerControls();
            }
        }
        //get the max number from quoteline
        num=ReplacementQueryController.getMaxNumberQuoteLine(quoteId);
        Set<Id> EntIds=new Set<Id>();
        /*removing EntIds from the replacement wrapper list for which QLi was 
            already created/remains after deleting modified lines-Not to recreate QLI.*/
        EntIds=ReplacementQueryController.getremainingEntIdsAfterDeletion(quoteId);
        
        //remove R6k h/w support ent id from replacement logic because these lines will be created in refresh logic
        if(selectedSupportRefreshEntids!=null){ //FY25SR-1159,FY25SR-1155.
          EntIds.addAll(selectedSupportRefreshEntids);  
        }
        
        //call reamining function
        List<ReplacementRefreshWrapperData.wrapperData> toProcess=
            new List<ReplacementRefreshWrapperData.wrapperData>();
        if(selectedEntitlements!=null && EntIds!=null && !EntIds.isEmpty()){
            for(ReplacementRefreshWrapperData.wrapperData wrapper : selectedEntitlements) {
                //excluding wrapper //exclude h/w support entId from refresh wrapper
                //FY25SR-2298 start
                String inactiveEntIds=null; 
                if(wrapper.wrapInactiveEnt!=null){ 
                    for(ReplacementRefreshWrapperData.wrapperData wrap :wrapper.wrapInactiveEnt){ 
                        if(String.isNotBlank(wrap.entitlementId)){
                            inactiveEntIds= wrap.entitlementId; 
                        } 
                    }
                } //FY25SR-2298 end
                if (!(EntIds.contains(wrapper.entitlementId) || (inactiveEntIds != null && EntIds.contains(inactiveEntIds)))) {//FY25SR-2298
                    toProcess.add(wrapper);  
                }
            }
            if(toProcess!=null && !toProcess.isEmpty())
            {
                selectedEntitlements= toProcess;
        }else{
                selectedEntitlements.clear(); 
            }
          }
        //Get Quote Details
        Boolean onQuoteConv = false;
        //FY25SR-1203 -start
        SBQQ__Quote__c quotePB = ReplacementQueryController.getQuoteDetails(quoteId);
        String qType = quotePB.SBQQ__Type__c;       
      
        //add refreshWrapperData
            SBQQ__Quote__c updateQuote = new SBQQ__Quote__c(Id = quoteId);
            updateQuote.RWD_Deal_Ops_Exception__c = quotePB.RWD_Deal_Ops_Exception__c;
            updateQuote.RWD_Sales_Rep_Exception__c = quotePB.RWD_Sales_Rep_Exception__c;
            updateQuote.RWD_Sales_Rep_Exception_Justification__c = quotePB.RWD_Sales_Rep_Exception_Justification__c ;
            updateQuote.RWD_Deal_Ops_Exception_Justification__c = quotePB.RWD_Deal_Ops_Exception_Justification__c;
            updateQuote = ReplacementQuoteLineCreationHelper.updateQuoteDetails(
                    (Map<String,String>)JSON.deserialize(
                        quoteDetail, Map<String,String>.class), updateQuote);
            updateQuote.SBQQ__QuoteTemplateId__c = '';
        skipAutoAddCapacitySkus =  updateQuote.RWD_Deal_Ops_Exception__c != null && updateQuote.RWD_Deal_Ops_Exception__c.contains(ReplacementConstants.REMOVE_AUTO_ADDED_CAPACITY_SKU) ? true : false;
        if(selectedEntitlements.isEmpty() && refreshRowList.isEmpty()){
            if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
                Database.update(updateQuote,true);
            }
            SBQQ__Quote__c quoteRec = ReplacementQuoteLineCreationHelper.updateQuoteForRecalculation(quotePB);
            quoteRec.SBQQ__QuoteTemplateId__c = quotePB.SBQQ__QuoteTemplateId__c;
            if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
                Database.update(quoteRec,true);
            }
            return quoteId;
        }
        //FY25SR-1203 -end
        if(inactiveEntitlementIdSet!=null){
            selectedEntitlementIdSet.addALL(inactiveEntitlementIdSet);//to get details of inactive entitlement too
        }
        if(selectRefreshEntIds!=null){ //FY25SR-1159,FY25SR-1155.
            selectedEntitlementIdSet.addALL(selectRefreshEntIds);//to get the ent details from refresh window too
        }
        // Query entitlement records along with related product information
         if(selectedEntitlementIdSet!=null && !selectedEntitlementIdSet.isEmpty()){
            entitlementMap = 
                new Map<Id, Entitlement>(ReplacementQueryController.getEntitlementsBasedonIds(selectedEntitlementIdSet));
         }   

        //FY25SR-1215 - Starts
        Set<String> productTypes = new Set<String>{
            ReplacementConstants.PRODUCT_TYPE_RADAR,
            ReplacementConstants.PRODUCT_TYPE_SONAR, 
            ReplacementConstants.PRODUCT_TYPE_APP_FLOWS};
        if (!entitlementMap.isEmpty() && (mapfCLIs == null || mapfCLIs.isEmpty())) {
            for (Entitlement ent : entitlementMap.values()) {
                if (String.isNotBlank(ent.ContractLineItemId)) {
                    mapfCLIs.put(ent.ContractLineItemId, ent.ContractLineItem); 
                    //Get Asset capacity per CLI.
                    //If Asset != null, then fetch from Asset
                    if(ent.assetid != null && ent.Asset.Product_Usable_Capacity__c != null){
                        if(contractLineCapacity.get(ent.ContractLineItemId) != null){
                            contractLineCapacity.put(ent.ContractLineItemId,
                                contractLineCapacity.get(ent.ContractLineItemId)+ent.Asset.Product_Usable_Capacity__c);
                        }else if(ent.assetid != null ){
                            contractLineCapacity.put(ent.ContractLineItemId,ent.Asset.Product_Usable_Capacity__c);
                        }
                    }

                    //For cases lik AddOns which will not have Asset details on the Entitlements, bring the Asset capacity directly from Parent Product on CLI
                    if(ent.assetid == null && ent.ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c != null){
                        if(contractLineCapacity.get(ent.ContractLineItemId) != null){
                            contractLineCapacity.put(ent.ContractLineItemId,
                                contractLineCapacity.get(
                                    ent.ContractLineItemId
                                )+ent.ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c);
                        }else if(ent.assetid == null ){
                            contractLineCapacity.put(ent.ContractLineItemId,
                                ent.ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c);
                        }
                    }
                    //If Asset is blank and no parent product. This is in case of V2 RSC and AddOns. Fetch the CLI Qty since it will be the converted Qty.
                    if(ent.assetid == null && ent.ContractLineItemId != null 
                        && ent.ContractLineItem.SBQQSC__RequiredByProduct__c == null){
                        if(contractLineCapacity.get(ent.ContractLineItemId) != null){
                            contractLineCapacity.put(ent.ContractLineItemId,
                                contractLineCapacity.get(ent.ContractLineItemId)+ent.ContractLineItem.SBQQSC__Quantity__c);
                        }else if(contractLineCapacity.get(ent.ContractLineItemId) == null ){
                            contractLineCapacity.put(ent.ContractLineItemId,ent.ContractLineItem.SBQQSC__Quantity__c);
                        }
                    }
                    //For Account AddOns which should take Contract Line Qty rather than Entitlement Qty
                    if(ent.ContractLineItemId != null 
                    && ent.Product__r.Add_on_Level__c == ReplacementConstants.PRODUCT_ADD_ON_LEVEL_RCDOM_ADDON 
                    && productTypes.contains(ent.Product__r.Product_Type__c) 
                    && ent.Product__r.SBQQSC__EntitlementConversion__c == ReplacementConstants.ENTITLEMENT_CONVERSION_ONE_PER_QL 
                    && ent.Product__r.Product_Level__c == null )  {
                        contractLineCapacity.put(ent.ContractLineItemId, ent.ContractLineItem.SBQQSC__Quantity__c);
                    }
                    //FY25SR-1663 Starts
                    if (String.isNotBlank(ent.ContractLineItem.SBQQSC__RenewalProductId__c) 
                    && ent.ContractLineItem.SBQQSC__Product__c != ent.ContractLineItem.SBQQSC__RenewalProductId__c) {
                        selectedProductId.add(ent.ContractLineItem.SBQQSC__RenewalProductId__c);
                    }
                    //FY25SR-1663 Ends
                }
            }
        }
        //FY25SR-1215 - Ends
        if(selectedProductId!=null){ //FY25SR-1159,FY25SR-1155.
           selectedSKUIds.addAll(selectedProductId); //to get refresh window product details too
        }
        //Get Product Data
        if(selectedSKUIds!=null && !selectedSKUIds.isEmpty()){
                productMap= ReplacementQueryController.getProductsBasedonIds(selectedSKUIds, new Set<String>());
            }
            if(!ProductMap.isEmpty()){
                for(Product2 p:ProductMap.values()){
                    ProductByCode.put(p.ProductCode,p);
                }
            }
            //Get Map of Product Id to its pricebook entry id
            productPricebookEntryMap = 
            ReplacementQueryController.createProductToPricebookEntryIdMap(quotePB.SBQQ__PriceBook__c);
          
            Map<String,Id> groupdIdNameMap=new Map<String,Id>();
            if(quotePB!=null && !quotePB.SBQQ__LineItemGroups__r.isEmpty()){
                for(SBQQ__QuoteLineGroup__c qLineGroup: quotePB.SBQQ__LineItemGroups__r){ 
                    groupdIdNameMap.put(qLineGroup.SBQQ__Quote__c + '#' + qLineGroup.Name, qLineGroup.Id);
                }
            }
            
            //Expansion Group
            if (!groupdIdNameMap.containsKey(quoteId + '#' + System.Label.Arry_expansion_group) 
            && qType != ReplacementConstants.QUOTE_TYPE_RENEWAL) {
                Id expansiongroupId = 
                    ReplacementQuoteLineCreationHelper.createNewGroup(System.Label.Arry_expansion_group, quoteId, 1);//FY25SR-2230 - Added Group number
                groupdIdNameMap.put(quoteId + '#' + System.Label.Arry_expansion_group, expansiongroupId);
            }
            //Disposition Group 
            if (!groupdIdNameMap.containsKey(quoteId + '#' + System.Label.Arry_Disposition_Group) 
            && qType != ReplacementConstants.QUOTE_TYPE_RENEWAL) {
                Id dispositionGroupID = 
                    ReplacementQuoteLineCreationHelper.createNewGroup(System.Label.Arry_Disposition_Group, quoteId, 3);//FY25SR-2230 - Added Group number
                groupdIdNameMap.put(quoteId + '#' + System.Label.Arry_Disposition_Group, dispositionGroupID);
            } 
            //Renewal Group (Move to QLI creation- if any line has disposition reason Renewing then only create RenewalGroupId)     
            if(!groupdIdNameMap.containsKey(quoteId + '#' + System.Label.Arry_renewal_Group) 
            && qType != ReplacementConstants.QUOTE_TYPE_RENEWAL) {
                Id renewalGroupId = 
                    ReplacementQuoteLineCreationHelper.createNewGroup(System.Label.Arry_renewal_Group, quoteId, 2);//FY25SR-2230 - Added Group number
                groupdIdNameMap.put(quoteId + '#' + System.Label.Arry_renewal_Group, renewalGroupId);
            }  
        
        
            //Create a map of multimapping records 
            //FY25SR-1592 Starts
            Map<String,Multi_Mapping_V2_Conversion__c> sourceSKUMultiMapping = 
                new Map<String,Multi_Mapping_V2_Conversion__c>();
            for (Multi_Mapping_V2_Conversion__c objMulti: ReplacementQueryController.getMultiMappingList()) {
                String key= objMulti.Source_Product__c+'-'+(objMulti.Support_Type__c!=null
                          ? objMulti.Support_Type__c:' ')+'-'+(objMulti.Payment_Option__c!=null
                            ? objMulti.Payment_Option__c:' ') + '-' + objMulti.Support_Tier__c;
                sourceSKUMultiMapping.put(key,objMulti);
            }
            //FY25SR-1592 Ends
            
            //to check mode of an entitlement (ManyTo1,1to1,1toMany)  
            Map<String, List<ReplacementRefreshWrapperData.wrapperData>> prodKeyWrapperList = 
                new Map<String, List<ReplacementRefreshWrapperData.wrapperData>>();
            Map<String,List<ReplacementRefreshWrapperData.wrapperData>> DisposeReplacementJson = 
                new Map<String,List<ReplacementRefreshWrapperData.wrapperData>>();
            //collect all QLI to insert in one list
            List<SBQQ__QuoteLine__c> insertQuoteLineItems = new List<SBQQ__QuoteLine__c>();
            //collect all the CPQ Dispose Quote Lines
            List<CPQ_Disposition_Quote_Line__c> insertCPQDisposeLines= new List<CPQ_Disposition_Quote_Line__c>();
            //assetSerialMap required for quantity calculation
            Map<String, Asset> assetSerialMap= new Map<String, Asset>();
            
            //start FY25SR-1159,FY25SR-1155.
            if(refreshRowList!=null && !refreshRowList.isEmpty()){
                List<SBQQ__QuoteLine__c> InsertRefreshQuoteLines = 
                    ReplacementQuoteLineCreationExtension.createQLIFromRefresh(
                        quoteId,refreshRowList,groupdIdNameMap,entitlementMap);
                if(InsertRefreshQuoteLines!=null && !InsertRefreshQuoteLines.isEmpty()){
                    insertQuoteLineItems.addAll(InsertRefreshQuoteLines);
                }
            }//end FY25SR-1159,FY25SR-1155.
        List<ReplacementRefreshWrapperData.wrapperData> processNonAssetAssetQl = 
            new List<ReplacementRefreshWrapperData.wrapperData>();
        if(selectedEntitlements!=null && !selectedEntitlements.isEmpty()){           
            //Initializing counter
            Integer i = 0 ;
            List<ReplacementRefreshWrapperData.PickList> assetPickList = 
                new List<ReplacementRefreshWrapperData.PickList>();
            for(ReplacementRefreshWrapperData.wrapperData wrapper :selectedEntitlements){
                Boolean rowFound = false;
                if(wrapper.selectedAssetsFromNonAsset != null && !wrapper.selectedAssetsFromNonAsset.isEmpty()){
                    for(ReplacementRefreshWrapperData.PickList pick : wrapper.selectedAssetsFromNonAsset){
                        if(pick.value != ReplacementConstants.NON_ASSET && pick.selected == true){
                            rowFound = true;
                        }
                    }
                }
                if(rowFound == true){
                    processNonAssetAssetQl.add(wrapper);
                }
                 //FY25SR-1084 START
                if(String.isNotBlank(wrapper.skuProductId)){
                    String manyToOneKey = 
                        ReplacementQuoteLineCreationHelper.createUniqueKey(wrapper, i,null,productMap,metaMap); //FY25SR-1705
                    List<ReplacementRefreshWrapperData.wrapperData> prodwrapper= 
                        prodKeyWrapperList.containsKey(manyToOneKey)
                        ? prodKeyWrapperList.get(manyToOneKey)
                        : new List<ReplacementRefreshWrapperData.wrapperData>();
                    prodwrapper.add(wrapper);
                    prodKeyWrapperList.put(manyToOneKey,prodwrapper);
                }
                else {//for Disposition lines only
                    String uniqueKey = 
                        ReplacementQuoteLineCreationHelper.createUniqueKey(
                            wrapper,null,ReplacementConstants.DISPOSELINE,null,metaMap);
                    List<ReplacementRefreshWrapperData.wrapperData> wrapperData= 
                        (DisposeReplacementJson!=null && DisposeReplacementJson.containsKey(uniqueKey))
                        ? DisposeReplacementJson.get(uniqueKey)
                        : new List<ReplacementRefreshWrapperData.wrapperData>();
                    wrapperData.add(wrapper);
                    DisposeReplacementJson.put(uniqueKey,wrapperData);   
                } 
            }
            if(selectAssetIDMap!=null && !selectAssetIDMap.isEmpty()){
                for(Asset assetRec: selectAssetIDMap.values()) {
                    assetSerialMap.put(assetRec.SerialNumber, assetRec);
                }
            }
            Map<String, String> entIdToModeMap = new Map<String, String>();
            Map<String, ReplacementJson> parentJsonData = new Map<String, ReplacementJson>();
            Map<String, ReplacementJson> parentJsonDataManyToOne = new Map<String, ReplacementJson>();
            Map<String, ReplacementJson> disposeJsonData =  new Map<String, ReplacementJson>();  
            Integer count = 0 ; 
            for (ReplacementRefreshWrapperData.wrapperData selectedEntitlement : selectedEntitlements) {
                //FY25SR-1084 START
               if(String.isNotBlank(selectedEntitlement.skuProductId)){
                    String manyToOneKey = 
                        ReplacementQuoteLineCreationHelper.createUniqueKey(
                            selectedEntitlement, count,null,productMap,metaMap); //FY25SR-1705
                    Integer prodCount = prodKeyWrapperList.containsKey(manyToOneKey)
                                      ? prodKeyWrapperList.get(manyToOneKey).size()
                                      : 1;
                    if (prodCount > 1) {
                        if (String.isNotBlank(selectedEntitlement.entitlementId)) {
                            entIdToModeMap.put(
                                selectedEntitlement.entitlementId + '=' + selectedEntitlement.customIndex, 
                                ReplacementConstants.MANY_TO_1);
                            continue;
                        }
                    }
                    if (entIdToModeMap.containsKey(selectedEntitlement.entitlementId + '=' + selectedEntitlement.customIndex)) {
                        entIdToModeMap.put(selectedEntitlement.entitlementId + '=' + selectedEntitlement.customIndex, 
                            ReplacementConstants.ONE_TO_MANY);
                    } else {
                        entIdToModeMap.put(selectedEntitlement.entitlementId + '=' + selectedEntitlement.customIndex, 
                            ReplacementConstants.ONE_TO_ONE);
                    }
                }
            }
            
            for (ReplacementRefreshWrapperData.wrapperData selectedEntitlement : selectedEntitlements) {//for Expansion Group lines
                if(String.isNotEmpty(selectedEntitlement.skuProductId)){
                    String mode = entIdToModeMap.get(selectedEntitlement.entitlementId + '=' 
                                + selectedEntitlement.customIndex);
                    // Skip the JSON creation for entitlement if mode is manyto1
                    if (mode == ReplacementConstants.MANY_TO_1)
                        continue;
                        ReplacementQuoteLineCreationHelper.createReplacementJSON(
                            mode
                          , selectedEntitlement
                          , EntIdToInactiveEnt
                          , null
                          , new List<ReplacementRefreshWrapperData.wrapperData>()
                          , null
                          , parentJsonData
                          , parentJsonDataManyToOne
                          , productMap);
                }   
            }
            
            if(prodKeyWrapperList!=null && !prodKeyWrapperList.isEmpty()){//for Expansion Group line
                for (String productKey : prodKeyWrapperList.keySet()) {
                    if( prodKeyWrapperList.get(productKey).size()>1)
                    {
                        List<ReplacementRefreshWrapperData.wrapperData> wrapperList = prodKeyWrapperList.get(productKey);
                        List<String> skuENTDetail= productKey.split('-');
                        ReplacementQuoteLineCreationHelper.createReplacementJSON(
                            ReplacementConstants.MANY_TO_1
                           , null
                           , EntIdToInactiveEnt
                           , skuENTDetail
                           , wrapperList
                           , productKey
                           , parentJsonData
                           , parentJsonDataManyToOne
                           , productMap);
                    }
                }
            }
            
            if(DisposeReplacementJson!=null && !DisposeReplacementJson.isEmpty()){//for CPQ Dispose lines only
                for(ReplacementRefreshWrapperData.wrapperData wrapper:selectedEntitlements){
                     String uniqueKey = 
                        ReplacementQuoteLineCreationHelper.createUniqueKey(
                            wrapper, null,ReplacementConstants.DISPOSELINE,null,metaMap);
                    if(disposeJsonData.isEmpty() || !disposeJsonData.containsKey(uniqueKey))
                    {
                        if(DisposeReplacementJson.containsKey(uniqueKey)){
                            if(DisposeReplacementJson.get(uniqueKey).size()>1){
                                if(!entIdToModeMap.containsKey(wrapper.entitlementId + '=' + wrapper.customIndex)){
                                    entIdToModeMap.put(wrapper.entitlementId + '=' + wrapper.customIndex, 
                                        ReplacementConstants.ONE_TO_MANY);
                                }
                            }
                            else{
                                if(!entIdToModeMap.containsKey(wrapper.entitlementId + '=' + wrapper.customIndex)){ 
                                    entIdToModeMap.put(wrapper.entitlementId + '=' + wrapper.customIndex,
                                        ReplacementConstants.ONE_TO_ONE);
                                }
                            }
                            ReplacementJson jsonData = new ReplacementJson();
                            jsonData.rowValues = new List<ReplacementJson.RowDetail>();
                            jsonData.mode = ReplacementConstants.DISPOSE;
                            if(wrapper.targetProductType != null){
                                jsonData.targetProductType = wrapper.targetProductType;
                            }
                            jsonData.renLine = wrapper.renLine;
                            for (ReplacementRefreshWrapperData.wrapperData wrap : DisposeReplacementJson.get(uniqueKey)) {
                                jsonData.rowValues.add(
                                    ReplacementQuoteLineCreationHelper.createRowDetail(wrap,EntIdToInactiveEnt));
                                if(wrap.targetProductType != null){
                                    jsonData.targetProductType = wrap.targetProductType;
                                }
                            }
                            disposeJsonData.put(uniqueKey,jsonData);
                        }
                    }
                }
            }
            
            if(processNonAssetAssetQl!=null && !processNonAssetAssetQl.isEmpty()){
                List<SBQQ__QuoteLine__c> insertR7KNonAssetLines = 
                    ReplacementQuoteLineCreationExtension.createQuoteLinesforNonAssetR7K(
                        quoteId,processNonAssetAssetQl,groupdIdNameMap,entitlementMap);
                if(insertR7KNonAssetLines!=null && !insertR7KNonAssetLines.isEmpty()){
                    insertQuoteLineItems.addAll(insertR7KNonAssetLines);
                }
            }
            
            //create Expansion group lines
            List<SBQQ__Quoteline__c> insertExpansionQuoteLineItems= 
                generateExpansionQuoteLines(quoteId
                    , selectedEntitlements
                    , groupdIdNameMap
                    , parentJsonDataManyToOne
                    , HwEntIdagainstBaseEntId
                    , sourceSKUPolarisMap
                    , assetSerialMap
                    , parentJsonData
                    , EntIdToInactiveEnt
                    , entIdToModeMap
                    , v2MappingforHWsupport
                    , selectedSupportRefreshEntids
                    , RenewalAssetonSupportSwitch
                    , entitlementMap
                    , metaMap);//FY25SR-1481, 1084
            if(insertExpansionQuoteLineItems!=null && !insertExpansionQuoteLineItems.isEmpty()){
                insertQuoteLineItems.addAll(insertExpansionQuoteLineItems);
            }
        if( capacityUserExpansionLinesMap != null && !capacityUserExpansionLinesMap.isEmpty()){
           
                insertQuoteLineItems.addAll(capacityUserExpansionLinesMap.Values());
            }
            //create Dispose and Renewal group lines
            List<SBQQ__Quoteline__c> insertDisposeQuoteLineItems= 
                generateDisposeAndRenewingQuoteLines(quoteId
                    , selectedEntitlements
                    , groupdIdNameMap
                    , sourceSKUPolarisMap
                    , assetSerialMap
                    , EntIdToInactiveEnt
                    , entIdToModeMap
                    , RenewalAssetonSupportSwitch
                    , entitlementMap
                    , metaMap);//FY25SR-1481, 1084
            if(insertDisposeQuoteLineItems!=null && !insertDisposeQuoteLineItems.isEmpty()){
                insertQuoteLineItems.addAll(insertDisposeQuoteLineItems);
            }
            //create CPQ Dispose Lines
            insertCPQDisposeLines=generateCPQDisposeLine(quoteId
                , selectedEntitlements
                , disposeJsonData
                , EntIdToInactiveEnt
                , sourceSKUPolarisMap
                , assetSerialMap
                , ProductMap
                , entIdToModeMap
                , metaMap);
        }
        //Start FY25SR-1663 RCDM-T auto-addition
        Boolean rcdmValidQuote = false;
        Date quotRangeEnd;
        if(quotePB!= null && quotePB.RCDMT_EOL_Date__c!= null) {
            quotRangeEnd  = quotePB.RCDMT_EOL_Date__c; // added for CPQ22-3874                          
            if(quotePB.Eligible_for_RCDM_T__c == true && quotePB.Is_Customer_Fully_Transitioned__c == false){
                rcdmValidQuote = true;
            }
        }
        //End FY25SR-1663     
        
        List<String> isConverted = new List<String>();
        List<Approval_Snapshot__c> updateApprovalSnapShot = new List<Approval_Snapshot__c>();/**FY26WL-227*/
        if(!insertQuoteLineItems.isEmpty() || !InsertCPQDisposeLines.isEmpty()){
    
            ReplacementQuoteLineCreationExtension.v1tov2Conversion(
                  insertQuoteLineItems
                , InsertCPQDisposeLines
                , sourceSKUPolarisMap
                , assetSerialMap
                , v2MappingforHWsupport
                , sourceSKUMultiMapping
                , isConverted);
            ReplacementQuoteLineCreationHelper.disableTriggerControls();
            if(Schema.sObjectType.SBQQ__Quoteline__c.isCreateable()){
                Database.insert(insertQuoteLineItems,true);
            }
            if(Schema.sObjectType.CPQ_Disposition_Quote_Line__c.isCreateable()){
               Database.insert(InsertCPQDisposeLines,true);
            } 
            /**FY26WL-227 Start*/
            for(SBQQ__Quoteline__c ql : insertQuoteLineItems) {
                System.debug('>>ql :: '+ql);
                System.debug('>>qlApproval_temp_field__c :: '+ql.Approval_temp_field__c);

                if(!String.isBlank(ql.Approval_temp_field__c)) {
                    updateApprovalSnapShot.add( 
                        new Approval_Snapshot__c(Id = ql.Approval_temp_field__c, Quote_Line__c  = ql.Id)
                    );
                }
            }
            if(!updateApprovalSnapShot.isEmpty() && Schema.sObjectType.Approval_Snapshot__c.isUpdateable()) {
                Database.update(updateApprovalSnapShot,true);
            }
            /**FY26WL-227 End*/
        /** Code to updated Requiredy By lines for the capacity lines  */
        if(capacityUserExpansionLinesMap !=null && !capacityUserExpansionLinesMap.isEmpty()){
            
            for(String ent : capacityUserExpansionLinesMap.KeySet()){
                SBQQ__QuoteLine__c capacityLines = capacityUserExpansionLinesMap.get(ent);
                capacityLines.SBQQ__RequiredBy__c = parentUserExpansionLinesMap.containsKey(ent) ? parentUserExpansionLinesMap.get(ent).Id : null;
                }

            	update capacityUserExpansionLinesMap.Values();
          }
            
             
            //Start FY25SR-1663 RCDM-T 
            if(rcdmValidQuote==true){
                ReplacementQuoteLineCreationHelper.getRCDMTLineAddedInTheList(
                    insertQuoteLineItems,quotRangeEnd,productMap);
            }
            //end FY25SR-1663 
        }
        //Update Quote record for calculate quote
        /********************* FY25SR-1095 ***************************/
        //Date quoteExpDate = quotePB.SBQQ__ExpirationDate__c != NULL ? quotePB.SBQQ__ExpirationDate__c : NULL;  Prasenjeet FY25SR-2165
        Date quoteExpDate;
        if(quotePB.SBQQ__Opportunity2__r.CloseDate <= quoteTriggerHelper.lastDateOfQuarter()){
            quoteExpDate = quoteTriggerHelper.lastDateOfQuarter();
        }else{
            quoteExpDate = date.valueof(quotePB.CreatedDate).adddays(90);
        }
        
        if(!sEntEndDates.isEmpty() && quoteExpDate != NULL){
            for(Date dt : sEntEndDates){
                if(dt < quoteExpDate){
                    quoteExpDate = dt;
                }
            }
        }
        /********************* FY25SR-1095 ***************************/
        List<String> selectedPrograms = new List<String>();

   
        updateQuote.Opportunity_Program__c= optyProgram!=null?optyProgram:null;
        updateQuote.SBQQ__ExpirationDate__c = quoteExpDate != NULL 
                                            ? quoteExpDate : quotePB.SBQQ__ExpirationDate__c;  //FY25SR-1095
        updateQuote.SBQQ__LineItemsGrouped__c = quotePB.SBQQ__Type__c != ReplacementConstants.QUOTE_TYPE_RENEWAL 
                                              ?  true : false; //FY25SR-1073 false for Renewals
        //FYSR25-1124- end
        updateQuote.SBQQ__QuoteTemplateId__c = '';
        if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
            Database.update(updateQuote,true);
        }
        ConvertToSaasRenewalBatch.convertDSAAS(updateQuote);//FY25SR-1663
        Boolean runV2toV2 = TRUE;
        ConvertToSaasRenewalBatch.convertV2ToV2(updateQuote, runV2toV2, insertQuoteLineItems);//CPQ22-5637
        //FY25SR-1203
        SBQQ__Quote__c quoteRec = ReplacementQuoteLineCreationHelper.updateQuoteForRecalculation(quotePB);
        quoteRec.SBQQ__QuoteTemplateId__c = quotePB.SBQQ__QuoteTemplateId__c;
        if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable()){
            Database.update(quoteRec,true);
         }
        return quoteId;
        }
        catch(exception ex){
        ReplacementQuoteLineCreationHelper.catchHandler(ex);
        }
    return quoteId;
     }

    /***********************************************************************************************************
    * Method Name          : generateExpansionQuoteLines
    * Date Created/Modified: 4/02/2025
    * Author               : 
    * @description         :  generate List of quoteline for ReplacementSKU (Wrapper.skuProductId) in Expansion Group 
    * @return              : List of Expansion Quote Lines
    * @param quoteId
    * @param selectedEntitlements
    * @param groupdIdNameMap
    * @param parentJsonDataManyToOne
    * @param HwEntIdagainstBaseEntId
    * @param sourceSKUPolarisMap
    * @param assetSerialMap
    * @param parentJsonData
    * @param EntIdToInactiveEnt
    * @param entIdToModeMap
    * @param v2MappingforHWsupport
    * @param selectedSupportRefreshEntids
    * @param RenewalAssetonSupportSwitch //FY25SR-1481
    * @param entitlementMap //FY25SR-1084
    * @param metaMap
    * Test Class Methods   :
    ***********************************************************************************************************/
    public static List<SBQQ__Quoteline__c> generateExpansionQuoteLines(
          Id quoteId
        , List<ReplacementRefreshWrapperData.wrapperData> selectedEntitlements
        , Map<String,Id> groupdIdNameMap
        , Map<String,ReplacementJson> parentJsonDataManyToOne
        , Map<String,ReplacementRefreshWrapperData.wrapperData> HwEntIdagainstBaseEntId
        , Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMap
        , Map<String, Asset> assetSerialMap
        , Map<String, ReplacementJson> parentJsonData
        , Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> EntIdToInactiveEnt
        , Map<String, String> entIdToModeMap
        , Map<String, Polaris_SKU_Mapping_V2__c> v2MappingforHWsupport
        , Set<Id> selectedSupportRefreshEntids
        , Set<String> RenewalAssetonSupportSwitch
        , Map<Id, Entitlement> entitlementMap
        , Map<String, Replacement_Field_Mapping__mdt> metaMap)
    {
        Integer i = 0 ;    
        Set<Id> selectedSkusForReplacement = new Set<Id>(); // ITNPI-2901 
        //for ManyTo1 (should create only 1 quoteline for skuProductId- Expansion lines)
        Map<String,SBQQ__QuoteLine__c> uniqueKeyQLI=new Map<String,SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> insertQLI=new List<SBQQ__QuoteLine__c>();
        //calculate qty. only in case of ManyTo1 and if SourceIsV1Product
        List<SBQQ__QuoteLine__c> ListofQLITOCalculateV1Qty =new List<SBQQ__QuoteLine__c>();
        //Expansion lines
        for (ReplacementRefreshWrapperData.wrapperData selectedEntitlement : selectedEntitlements) {
            //in case of expansion line, disposition reason never be ReplacementConstants.DISPOSE_AT_RISK or ReplacementConstants.DISPOSE_RENEW_LATER or ReplacementConstants.DISPOSE_CHURN
            //selectedEntitlement.selecteddisposition!=ReplacementConstants.DISPOSE_AT_RISK && selectedEntitlement.selecteddisposition!=ReplacementConstants.DISPOSE_RENEW_LATER
            if(String.isNotBlank(selectedEntitlement.selecteddisposition) 
            && String.isNotBlank(selectedEntitlement.skuProductId) 
            && String.isNotBlank(selectedEntitlement.entitlementId))
            {
                //FY25SR-1084 START
               String uniqueKey = ReplacementQuoteLineCreationHelper.createUniqueKey(
                    selectedEntitlement,i,null,productMap,metaMap); //FY25SR-1705
               //FY25SR-1084 END
                 Id contractLineItemId;
                if(!entitlementMap.isEmpty()){
                    if(entitlementMap.containsKey(selectedEntitlement.entitlementId) 
                    && entitlementMap.get(selectedEntitlement.entitlementId)!=null){
                        contractLineItemId= entitlementMap.get(selectedEntitlement.entitlementId).ContractLineItemId;
                    }
                }
                String replacementMotion = ReplacementConstants.UPGRADE_VALUE;
                Id groupId;
                String type;
                String  mode = entIdToModeMap.get(
                    selectedEntitlement.entitlementId + '=' + selectedEntitlement.customIndex);
                Id pricebookEntryId = productPricebookEntryMap.get(selectedEntitlement.skuProductId);
                Integer termInt = (Integer)selectedEntitlement.ReplacementTerm;
                ReplacementJson jsonData = new ReplacementJson();
                //For Expansion Qli   
                if (!uniqueKeyQLI.isEmpty() && uniqueKeyQLI.containsKey(uniqueKey) 
                    && selectedEntitlement.selecteddisposition!=ReplacementConstants.DISPOSTION_RENEWING) {//FY25SR-1481 do not consolidate renewal lines
                    SBQQ__QuoteLine__c existingQuoteLine = uniqueKeyQLI.get(uniqueKey);
                    if (String.isBlank(existingQuoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c)) {
                        existingQuoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c = contractLineItemId;
                    } else {
                        existingQuoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c += ',' + contractLineItemId;
                    }
                    //to combine contractLineItemId of inactive entitlements to active entitlement
                    List<String> cliIds=new List<String>();
                    if(EntIdToInactiveEnt.containsKey(selectedEntitlement.entitlementId+'-'+selectedEntitlement.customIndex)){
                        for(ReplacementJson.RelatedChildEntRowDetail inactiveEnt:
                            EntIdToInactiveEnt.get(selectedEntitlement.entitlementId+'-'+selectedEntitlement.customIndex))
                        {
                            String cli=entitlementMap.get(inactiveEnt.ChildEntId).ContractLineItemId;
                            cliIds.add(cli);
                        }
                    }
                    if(!cliIds.isEmpty()){
                        existingQuoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c+=','+String.join(cliIds, ',');
                    }
                }
                else{
                    if(selectedEntitlement.selecteddisposition.equals(ReplacementConstants.DISPOSTION_RENEWING)){//start FY25SR-1481
                        groupId= groupdIdNameMap.get(quoteId + '#' + System.Label.Arry_renewal_Group);
                        type= ReplacementConstants.QUOTE_TYPE_RENEWAL;
                        jsonData = 
                            ReplacementQuoteLineCreationExtension.createRepJSONforRenewing(
                                selectedEntitlement, EntIdToInactiveEnt);
                        jsonData.skuSelected= selectedEntitlement.skuProductId;
                        jsonData.skuSelectedName= selectedEntitlement.skuProdName;
                        ReplacementJson.RowDetail rowDetail=jsonData.rowValues[0];
                        rowDetail.isAutoDisposition=true;  
                       }
                    else{
                      groupId= groupdIdNameMap.get(quoteId + '#' + System.Label.Arry_expansion_group);
                      type= ReplacementConstants.QUOTE_TYPE_NEW;
                      jsonData = mode == ReplacementConstants.MANY_TO_1
                          ? parentJsonDataManyToOne.get(uniqueKey)
                          : parentJsonData.get(
                            selectedEntitlement.entitlementId + '=' + selectedEntitlement.customIndex
                            );
                    }//end FY25SR-1481
                    Set<String> assetNames = new Set<String>();
                    if (jsonData != null && jsonData.rowValues != null && !jsonData.rowValues.isEmpty()) {
                        for (ReplacementJson.RowDetail childRow : jsonData.rowValues) {
                            for (String assetName : childRow.selectedAssetList.values()) {
                                assetNames.add(assetName);
                            }
                        }
                    }
                    SBQQ__QuoteLine__C qli=
                        ReplacementQuoteLineCreationExtension.getQuoteLine(
                              quoteId
                            , selectedEntitlement
                            , productMap.get(selectedEntitlement.skuProductId)
                            , pricebookEntryId
                            , contractLineItemId
                            , jsonData
                            , groupId
                            , assetNames
                            , replacementMotion
                            , type
                            , EntIdToInactiveEnt
                            , entitlementMap);  //FY25SR-1084 
                    if(type==ReplacementConstants.QUOTE_TYPE_RENEWAL){//FY25SR-1481- for renewal, start date will be inactive ent enddate+1
                        Integer term= (Integer)qli.SBQQ__SubscriptionTerm__c;
                        if(EntIdToInactiveEnt.containsKey(selectedEntitlement.entitlementId+'-'+selectedEntitlement.customIndex)){
                            for(ReplacementJson.RelatedChildEntRowDetail inactiveEnt:
                                EntIdToInactiveEnt.get(selectedEntitlement.entitlementId+'-'+selectedEntitlement.customIndex))
                            {
                                Date inactiveEndDate=entitlementMap.get(inactiveEnt.ChildEntId).EndDate;
                                qli.SBQQSC__RenewedContractLine__c = 
                                    entitlementMap.get(inactiveEnt.ChildEntId).ContractLineItemId;//FY25SR-1125
                                qli.SBQQ__StartDate__c = inactiveEndDate+1;
                                break;
                            }
                            qli.SBQQ__EndDate__c =(selectedEntitlement.renewalEndDate!=null 
                                                 ? selectedEntitlement.renewalEndDate 
                                                 : qli.SBQQ__StartDate__c.addMonths(term)-1);//Added FY25SR-1492
                        }
                     }//end FY25SR-1481
                    if(selectedEntitlement.skuProdLicenseSubCategory != null 
                    && selectedEntitlement.skuProdLicenseSubCategory == ReplacementConstants.LICENSE_SUB_CATEGORY_RSC_GOV_CLOUD 
                    && selectedEntitlement.EndDate != null 
                    && selectedEntitlement.EndDate >= System.today())
                    {
                        qli.SBQQ__StartDate__c = System.Today()+ 30 ;//??
                        qli.SBQQ__EndDate__c = selectedEntitlement.EndDate ; //??    
                    }

                    if((productMap.containsKey(selectedEntitlement.productId) 
                    && productMap.get(selectedEntitlement.productId).Product_Level__c == null 
                    && productMap.get(selectedEntitlement.productId).Product_Type__c !=ReplacementConstants.HW_SUPPORT) 
                    || mode== ReplacementConstants.MANY_TO_1)//and add condition for MAnyTo1
                    {
                        ListofQLITOCalculateV1Qty.add(qli);//to calculate quantity
                    }
                    uniqueKeyQLI.put(uniqueKey,qli);//identifier for manyTo1 to create only one line
                    insertQLI.add(qli);
                    //FY25SR-1086 Support Switch- create H/w Support
                    //H/W Support creation should be happen only when it has h/w support associated with it.
                    //if replacedSKU-IsHardwareNotRequiredForHybridLicense__c = false and SBQQ__SubscriptionPricing__c != null and Replacement_Category__c != null
                    Product2 replacedSKu=ProductMap.get(selectedEntitlement.skuProductId);
                    if(replacedSKu.IsHardwareNotRequiredForHybridLicense__c==false &&
                       ProductMap.get(selectedEntitlement.productId).Support_Type__c != replacedSKu.Support_Type__c)
                    {
                        if(assetNames!=null){
                            RenewalAssetonSupportSwitch.addAll(assetNames);//FY25SR-1481
                            String supportType=replacedSKu.Support_Type__c;
                            Date ParentRenewalEndDate=selectedEntitlement.renewalEndDate!=null
                                                     ?selectedEntitlement.renewalEndDate:null;
                            List<SBQQ__QuoteLine__c> qlHW =
                                ReplacementQuoteLineCreationExtension.getHWSpprtQuoteLine(quoteId
                                    , selectedEntitlement.entitlementId
                                    , replacedSKu.Product_Type__c
                                    , termInt
                                    , ParentRenewalEndDate
                                    , HwEntIdagainstBaseEntId
                                    , assetNames
                                    , groupId
                                    , supportType
                                    , v2MappingforHWsupport
                                    , assetSerialMap
                                    , selectedEntitlement.selecteddisposition
                                    , EntIdToInactiveEnt
                                    , selectedSupportRefreshEntids
                                    , entitlementMap);//exclude H/w id from refresh//FY25SR-1492
                            if(!qlHW.isEmpty())
                            {
                                insertQLI.addALL(qlHW);
                            }
                        }
                    }
                    //end FY25SR-1086 
                    
                    //ITNPI-2901
                    if(selectedEntitlement.SrprodRepCategory == ReplacementConstants.M365_DATA_PROTECTION && selectedEntitlement.skuProdRepCategory == ReplacementConstants.M365_DATA_PROTECTION_USERS && !skipAutoAddCapacitySkus){
qli.Storage_Tier__c = '';           //Change added by Anjali for ITNPI-3206
      parentUserExpansionLinesMap.put(uniqueKey,qli);                        selectedSkusForReplacement.add(selectedEntitlement.skuProductId);
                        
						
                }
            }
        }
		}

        //Call calculateQuantityforV1
        if(!ListofQLITOCalculateV1Qty.isEmpty()){
            ReplacementQuoteLineCreationExtension.calculateQuantityforV1(
                ListofQLITOCalculateV1Qty,null,sourceSKUPolarisMap,assetSerialMap,productMap);
        }

        // autoadd lines ITNPI-2901
        if(parentUserExpansionLinesMap !=null && !parentUserExpansionLinesMap.isEmpty()){
            
			capacityUserExpansionLinesMap = ReplacementQuoteLineCreationExtension.autoAddNewLinesForReplacement(quoteId,parentUserExpansionLinesMap,selectedSkusForReplacement);
            
        }
        return InsertQLI;
    } 
    
    /***********************************************************************************************************
    * Method Name          : generateDisposeAndRenewingQuoteLines
    * Date Created/Modified: 4/02/2025
    * Author               : 
    * @description         :  generate list of quoteline for ReplacedSKU (Wrapper.ProductId)  
    * @return              : List of Quote Lines are Disposition and renewal
    * @param quoteId
    * @param selectedEntitlements
    * @param groupdIdNameMap
    * @param sourceSKUPolarisMap
    * @param assetSerialMap
    * @param EntIdToInactiveEnt
    * @param entIdToModeMap
    * @param RenewalAssetonSupportSwitch  //FY25SR-1481
    * @param entitlementMap //FY25SR-1084
    * @param metaMap
    * Test Class Methods   :
    ***********************************************************************************************************/
    public static List<SBQQ__Quoteline__c> generateDisposeAndRenewingQuoteLines(
        Id quoteId
      , List<ReplacementRefreshWrapperData.wrapperData> selectedEntitlements
      , Map<String,Id> groupdIdNameMap
      , Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMap
      , Map<String, Asset> assetSerialMap
      , Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> EntIdToInactiveEnt
      , Map<String, String> entIdToModeMap
      , Set<String> RenewalAssetonSupportSwitch
      , Map<Id, Entitlement> entitlementMap
      , Map<String, Replacement_Field_Mapping__mdt> metaMap)//FY25SR-1481,1084
    {
        //1ToMany Combine ent records if the ent have same disposition reason. Key='EntId-DispositionReason-SubscriptionTerm-RenewalEndDate'
        Map<String,SBQQ__QuoteLine__c> uniqueEntDisposedQli=new Map<String,SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> InsertDisposeQLI=new List<SBQQ__QuoteLine__c>();
        //calculate qty. if SourceIsV1Product and in case of 1ToMany
        List<SBQQ__QuoteLine__c> ListofQLITOCalculateQty =new List<SBQQ__QuoteLine__c>();
        Map<String, Integer> uniqueKeyToQty = new Map<String, Integer>();
        //for Renewing and Dispose Lines (Excluding ReplacementConstants.DISPOSE_AT_RISK,ReplacementConstants.DISPOSE_CHURN and ReplacementConstants.DISPOSE_RENEW_LATER)
        //exclude renewing lines where ReplacementSKU is not null-FY25SR-1481 for Renewal lines
        for (ReplacementRefreshWrapperData.wrapperData selectedEntitlement : selectedEntitlements) {
           if(String.isNotBlank(selectedEntitlement.selecteddisposition) 
            && selectedEntitlement.selecteddisposition!=ReplacementConstants.DISPOSE_AT_RISK 
            && selectedEntitlement.selecteddisposition!=ReplacementConstants.DISPOSE_CHURN 
            && selectedEntitlement.selecteddisposition!=ReplacementConstants.DISPOSE_RENEW_LATER 
            && String.isNotBlank(selectedEntitlement.entitlementId) 
            && String.isNotBlank(selectedEntitlement.ProductId) 
            && !(String.isNotBlank(selectedEntitlement.skuProductId) 
            && selectedEntitlement.selecteddisposition==ReplacementConstants.DISPOSTION_RENEWING))//FY25SR-1481
           {
            String uniqueKey = ReplacementQuoteLineCreationHelper.createUniqueKey(
                    selectedEntitlement, null,ReplacementConstants.DISPOSELINE,null,metaMap);
                Id contractLineItemId;
                if(!entitlementMap.isEmpty()){
                    if(entitlementMap.containsKey(selectedEntitlement.entitlementId) 
                    && entitlementMap.get(selectedEntitlement.entitlementId)!=null){
                        contractLineItemId= entitlementMap.get(selectedEntitlement.entitlementId).ContractLineItemId;
                    }
                }
                Id groupId;
                String replacementMotion;
                String type;
                String  mode = entIdToModeMap.get(
                    selectedEntitlement.entitlementId + '=' + selectedEntitlement.customIndex);
                Id pricebookEntryId = productPricebookEntryMap.get(selectedEntitlement.productId);
                ReplacementJson jsonData = ReplacementQuoteLineCreationExtension.createRepJSONforRenewing(
                    selectedEntitlement, EntIdToInactiveEnt);
                Map<String, ReplacementJson.RowDetail> mapEntRowDets = new Map<String, ReplacementJson.RowDetail>();
                if (!jsonData.rowValues.isEmpty()) {
                    for (ReplacementJson.RowDetail row : jsonData.rowValues) {
                        mapEntRowDets.put(row.entId, row);
                    }
                }
                Set<String> assetNames = new Set<String>();
                
                for (ReplacementJson.RowDetail childRow : jsonData.rowValues) {
                    for (String assetName : childRow.selectedAssetList.values()) {
                        assetNames.add(assetName);
                    }
                    if(uniqueKeyToQty.containsKey(uniqueKey)) {
                        uniqueKeyToQty.put(uniqueKey, uniqueKeyToQty.get(uniqueKey) + Integer.valueOf(childRow.selectedQty));
                    } else {
                        uniqueKeyToQty.put(uniqueKey, Integer.valueOf(childRow.selectedQty));
                    }
                }
               //start FY25SR-1481 exclude h/w support lines when disposition reason is renewing and h/w switch happens on renewal license line.
               Boolean presentHWsupport=false;
               if(RenewalAssetonSupportSwitch!=null 
                && !RenewalAssetonSupportSwitch.isEmpty() 
                && assetNames!=null 
                && !assetNames.isEmpty()){
                   presentHWsupport=true;
                   for(String idd:assetNames){
                       if(!RenewalAssetonSupportSwitch.contains(idd)){
                           presentHWsupport = false;
                           break; 
                       }
                   }
               }
               if(!(presentHWsupport 
                && selectedEntitlement.selecteddisposition==ReplacementConstants.DISPOSTION_RENEWING)){ //end FY25SR-1481
                if(!uniqueEntDisposedQli.isEmpty() 
                    && uniqueEntDisposedQli.containskey(uniqueKey) 
                    && selectedEntitlement.selecteddisposition!=ReplacementConstants.DISPOSTION_RENEWING)//do not consolidate Renewal lines
                {
                    SBQQ__QuoteLine__c ql=uniqueEntDisposedQli.get(uniqueKey);
                    ReplacementJson qliReplaceJSON = (ReplacementJson)JSON.deserialize(ql.Replacement_Details__c, ReplacementJson.class);
                    qliReplaceJSON.rowValues.add(mapEntRowDets.get(selectedEntitlement.entitlementId));
                    ql.Replacement_Details__c = JSON.serialize(qliReplaceJSON);
                    if(assetNames!=null){
                        if(String.isBlank(ql.SubscribedAssetNames__c)){
                            ql.SubscribedAssetNames__c = String.join(new List<String>(assetNames), ', ');
                        }else{
                            ql.SubscribedAssetNames__c += ', '+ String.join(new List<String>(assetNames), ', ');
                        }
                        if(String.isBlank(ql.Subscribed_Asset_Name__c)){
                            ql.Subscribed_Asset_Name__c = String.join(new List<String>(assetNames), ', ');
                        }else{
                            ql.Subscribed_Asset_Name__c +=','+ String.join(new List<String>(assetNames), ', ');
                        }
                    }
                    ql.SBQQ__Quantity__c = uniqueKeyToQty.get(uniqueKey);
                }
                else{
                    if(selectedEntitlement.selecteddisposition.equals(ReplacementConstants.DISPOSTION_RENEWING)){
                        groupId= groupdIdNameMap.get(quoteId + '#' + System.Label.Arry_renewal_Group);
                        replacementMotion=ReplacementConstants.UPGRADE_VALUE;
                        type=ReplacementConstants.QUOTE_TYPE_RENEWAL;
                    }else{
                        groupId= groupdIdNameMap.get(quoteId + '#' + System.Label.Arry_Disposition_Group);
                        //replacementMotion='Arroyo Dispose';//Need discussion with Kush
                        replacementMotion=ReplacementConstants.UPGRADE_VALUE;
                        type=ReplacementConstants.DISPOSE;
                    }
                    SBQQ__QuoteLine__C qli=ReplacementQuoteLineCreationExtension.getQuoteLine(
                        quoteId
                      , selectedEntitlement
                      , productMap.get(selectedEntitlement.ProductId)
                      , pricebookEntryId
                      , contractLineItemId
                      , jsonData
                      , groupId
                      , assetNames
                      , replacementMotion
                      , type
                      , EntIdToInactiveEnt
                      , entitlementMap); //FY25SR-1084 
                    uniqueEntDisposedQli.put(uniqueKey,qli);
                    //for renewal, start date will be inactive ent enddate+1
                    if(type==ReplacementConstants.QUOTE_TYPE_RENEWAL){
                        Integer term= (Integer)qli.SBQQ__SubscriptionTerm__c;
                        if(EntIdToInactiveEnt.containsKey(selectedEntitlement.entitlementId+'-'+selectedEntitlement.customIndex)){
                            for(ReplacementJson.RelatedChildEntRowDetail inactiveEnt:
                                EntIdToInactiveEnt.get(selectedEntitlement.entitlementId+'-'+selectedEntitlement.customIndex))
                            {
                                Date inactiveEndDate=entitlementMap.get(inactiveEnt.ChildEntId).EndDate;
                                qli.SBQQSC__RenewedContractLine__c = 
                                    entitlementMap.get(inactiveEnt.ChildEntId).ContractLineItemId;//FY25SR-1125
                                qli.SBQQ__StartDate__c = inactiveEndDate+1;
                                break;
                            }
                             qli.SBQQ__EndDate__c =(selectedEntitlement.renewalEndDate!=null 
                                                  ? selectedEntitlement.renewalEndDate 
                                                  : qli.SBQQ__StartDate__c.addMonths(term)-1);//Added FY25SR-1492
                        }
                     }
                    qli.SBQQ__Quantity__c = uniqueKeyToQty.get(uniqueKey);
                    ReplacementQuoteLineCreationExtension.swapRenProdsonQL(
                            qli, productMap, productPricebookEntryMap, selectedEntitlement.productId);//FY25SR-1663
                    if((productMap.containsKey(selectedEntitlement.productId) 
                     && productMap.get(selectedEntitlement.productId).Product_Level__c == null 
                     && productMap.get(selectedEntitlement.productId).Product_Type__c !=ReplacementConstants.HW_SUPPORT) 
                     || mode== ReplacementConstants.ONE_TO_MANY)
                    {
                        ListofQLITOCalculateQty.add(qli); 
                    }
                    InsertDisposeQLI.add(qli);
                }
               }//FY25SR-1481
            }
            
        }
        
        //Call calculateQuantityforV1
        if(!ListofQLITOCalculateQty.isEmpty()){
            ReplacementQuoteLineCreationExtension.calculateQuantityforV1(
                ListofQLITOCalculateQty,null,sourceSKUPolarisMap,assetSerialMap,productMap);
        }

        //FY25SR-1215 - Consolidation Changes
        //Remove additional line which has been consolidated.
        if (!consContractLinesInstances.isEmpty() && !consolidatedLines.isEmpty()) {
            for (SBQQ__QuoteLine__c qlRem : consContractLinesInstances) {
                if (!consolidatedLines.contains(qlRem) && InsertDisposeQLI.indexOf(qlRem) >= 0) {
                    InsertDisposeQLI.remove(InsertDisposeQLI.indexOf(qlRem));
                }
            }
        }
        //FY25SR-1215 - Consolidation Changes Ends
        return InsertDisposeQLI;
    }
    
    /***********************************************************************************************************
    * Method Name          : generateCPQDisposeLine
    * Date Created/Modified: 
    * Author               : 
    * @description         : generate lines for at risk and renew later in the object CPQ_Disposition_Quote_Line__c
    * @return              : List of Lines inserted on CPQ Disposition Quote Line object
    * @param Quote
    * @param SelectedWrapperEntitlements
    * @param disposeJsonData
    * @param InactiveEntMap
    * @param sourceSKUPolarisMap
    * @param assetSerialMap
    * @param ProductMap
    * @param entIdToModeMap
    * @param metaMap
    * Test Class Methods   :
    ***********************************************************************************************************/  
    public static List<CPQ_Disposition_Quote_Line__c> generateCPQDisposeLine(
        Id Quote,List<ReplacementRefreshWrapperData.wrapperData> SelectedWrapperEntitlements
        , Map<String, ReplacementJson> disposeJsonData
        , Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> InactiveEntMap
        , Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMap
        , Map<String, Asset> assetSerialMap
        , Map<Id,Product2> ProductMap
        , Map<String, String> entIdToModeMap
        , Map<String, Replacement_Field_Mapping__mdt> metaMap)
    {
        List<CPQ_Disposition_Quote_Line__c> insertCPQDisposeLines= new List<CPQ_Disposition_Quote_Line__c>();
        List<CPQ_Disposition_Quote_Line__c> CalculateQtyCPQDisposeLines= new List<CPQ_Disposition_Quote_Line__c>();
        //1ToMany (Combine with EntId,Dispose Reason and subscription term)
        Map<String,CPQ_Disposition_Quote_Line__c> uniqueCPQDisposeLines= new Map<String,CPQ_Disposition_Quote_Line__c>();
        
        if(SelectedWrapperEntitlements!=null){
            for(ReplacementRefreshWrapperData.wrapperData seletedEnt:SelectedWrapperEntitlements)
            {
                String uniqueKey = 
                 ReplacementQuoteLineCreationHelper.createUniqueKey(
                    seletedEnt,null,ReplacementConstants.DISPOSELINE,null,metaMap);
                if(String.isNotBlank(seletedEnt.entitlementId) 
                 && String.isNotBlank(seletedEnt.selecteddisposition) 
                 && String.isNotBlank(seletedEnt.ProductId) 
                 && (seletedEnt.selecteddisposition == ReplacementConstants.DISPOSE_AT_RISK 
                  || seletedEnt.selecteddisposition==ReplacementConstants.DISPOSE_RENEW_LATER 
                  || seletedEnt.selecteddisposition==ReplacementConstants.DISPOSE_CHURN))
                {  
                    String mode=entIdToModeMap.get(seletedEnt.entitlementId + '=' + seletedEnt.customIndex);  
                    ReplacementJson jsonData=new ReplacementJson();
                    Set<String> assetNames = new Set<String>();//to store asset serial no.
                    List<String> cliIds=new List<String>();//to Combine Inactive Entitlement- contractLineItem ids
                    
                    if(disposeJsonData.containsKey(uniqueKey)){
                        jsonData= disposeJsonData.get(uniqueKey);
                        if (jsonData != null && jsonData.rowValues != null && !jsonData.rowValues.isEmpty()) {
                            for (ReplacementJson.RowDetail childRow : jsonData.rowValues) {
                                if(childRow.selectedAssetList!=null && childRow.selectedAssetList.size()>0){
                                    for (String assetName : childRow.selectedAssetList.values()) {
                                        assetNames.add(assetName);
                                    }
                                }
                                if(childRow.InactiveLines!=null && childRow.InactiveLines.size()>0){
                                    for (ReplacementJson.RelatedChildEntRowDetail inactiveEnt : childRow.InactiveLines) {
                                        String cli=entitlementMap.get(inactiveEnt.ChildEntId).ContractLineItemId;
                                        cliIds.add(cli);
                                    }
                                }
                            }
                        }
                    }
                    if(uniqueCPQDisposeLines.isEmpty() || !uniqueCPQDisposeLines.containsKey(uniqueKey))
                    {   
                        CPQ_Disposition_Quote_Line__c cpqDispose=new CPQ_Disposition_Quote_Line__c(
                            Quote__c=Quote,
                            Disposition_Reason__c=seletedEnt.selecteddisposition,
                            Product__c=seletedEnt.ProductId,
                            Quantity__c=seletedEnt.selectedquantity,
                            Replacement_Detail__c=JSON.serialize(jsonData),
                            Arroyo_Subscribed_Asset_Name__c=String.join(new List<String>(assetNames), ', '),
                            RenewedContractLine__c=entitlementMap.get(seletedEnt.entitlementId).contractLineItemId,//FY25SR-1111
                            PricebookEntryId__c = productPricebookEntryMap.get(seletedEnt.ProductId),//FY25SR-1111
                            Arroyo_Subsumed_Old_Contract_Line_Items__c=
                               entitlementMap.get(seletedEnt.entitlementId).contractLineItemId
                        );
                        if(!cliIds.isEmpty()){
                            cpqDispose.Arroyo_Subsumed_Old_Contract_Line_Items__c+=','+String.join(cliIds, ',');
                        }
                        ReplacementQuoteLineCreationExtension.swapRenProdsonDQL(
                            cpqDispose, productMap, seletedEnt.ProductId);//FY25SR-1663
                        insertCPQDisposeLines.add(cpqDispose);
                        uniqueCPQDisposeLines.put(uniqueKey,cpqDispose);
                        //to calculate qty for v1 product only
                        if((ProductMap.containsKey(seletedEnt.ProductId) 
                         && ProductMap.get(seletedEnt.ProductId).Product_Level__c ==null 
                         && productMap.get(seletedEnt.productId).Product_Type__c !=ReplacementConstants.HW_SUPPORT) 
                          || mode==ReplacementConstants.ONE_TO_MANY){//added Khushboo
                            CalculateQtyCPQDisposeLines.add(cpqDispose);
                        }
                    }
                }
            }
            if(CalculateQtyCPQDisposeLines!=null){
                ReplacementQuoteLineCreationExtension.calculateQuantityforV1(
                    null,CalculateQtyCPQDisposeLines,sourceSKUPolarisMap,assetSerialMap,productMap);
            }
        }
        return insertCPQDisposeLines;
    }
}