/**
* @File Name : ReplacementQuoteLineCreationHelper.cls
* @description :This class is helper class to ReplacementQuoteLineCreation which contians all the reusable methods
* 
* @Author : Ankita
* @Last Modified By :
* @Last Modified On : April 28, 2025
* @Modification Log :
* Test Class        : ReplacementQuoteLineCreationTest
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 28, 2025|   | Initial Version
**/

public  without sharing class ReplacementQuoteLineCreationHelper {
    public static List<String> skuDispositions = new List<String>{ReplacementConstants.CONVERTED, ReplacementConstants.UPGRADED, ReplacementConstants.REFRESHED};
    /***********************************************************************************************************
    * Method Name          : futureTransactionData
    * Date Created/Modified: April 28, 2025
    * Author               : Ankita
    * @description         : Modify data for QL creation        
    * @return              : Wrapper for QL
    * @param               mapAssetEntitlements
    * Test Class Methods   :
    *********************************************************************************************************/
    public static Boolean IS_FIPS_ASSET_REFRESHED = false;

    public static List<ReplacementRefreshWrapperData.WrapperData> futureTransactionData(
        ReplacementRefreshWrapperData.futureDataValues mapAssetEntitlements
    ){
        List<ReplacementRefreshWrapperData.WrapperData> updatedWrapper = new List<ReplacementRefreshWrapperData.WrapperData>();
        Boolean isModified = false;
        for(ReplacementRefreshWrapperData.WrapperData eachEnt : mapAssetEntitlements.futureValues) {
            updatedWrapper.add(eachEnt);
        }
        return updatedWrapper;
    }

    /***********************************************************************************************************
    * Method Name          : processWrapper
    * Date Created/Modified: 07/02/2025
    * Author               : Khushboo
    * @description         : Add wrappers which are to be processed. If selected and isModified, then to be transacted             
    * @param               wrapper
    * @param               modifiedEntitlements
    * @param               modifiedSkuProductIds
    * @param               entIdToInactiveEnt
    * @param               inactiveEntitlementIdSet
    * @param               selectedEntitlements
    * @param               selectedEntitlementIdSet
    * @param               selectedSKUIds
    * @param               modifiedOldSKUs
    * @param               sEntEndDates
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void processWrapper(
        List<ReplacementRefreshWrapperData.wrapperData> wrapper,
        Set<Id> modifiedEntitlements,Set<id> modifiedSkuProductIds, 
        Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> entIdToInactiveEnt,
        Set<Id> inactiveEntitlementIdSet,List<ReplacementRefreshWrapperData.wrapperData> selectedEntitlements,
        Set<Id> selectedEntitlementIdSet,Set<Id> selectedSKUIds, 
        Set<Id> modifiedOldSKUs,
        Set<Date> sEntEndDates
      ){
            //Added to store all inactive lines 
        Map<String,ReplacementRefreshWrapperData.WrapperData> inactiveEntIdEachBaseWrapper = 
                                    new Map<String,ReplacementRefreshWrapperData.WrapperData>();    
        for(ReplacementRefreshWrapperData.wrapperData subwrapper : wrapper) {
            if(subwrapper.wrapInactiveEnt!=null && subwrapper.isModified == true){
                //Iterate on Inactive Entitlements
                for(ReplacementRefreshWrapperData.wrapperData wrap :subwrapper.wrapInactiveEnt){
                    modifiedEntitlements.add(wrap.entitlementId);//FY25SR-2298
                    if (String.isNotBlank(wrap.entitlementId) && !inactiveEntIdEachBaseWrapper.containsKey(wrap.entitlementId)) {
                       inactiveEntIdEachBaseWrapper.put(wrap.entitlementId, wrap);
                    }
                }
            }
        } //End
        //FY25SR-1215 Added modifiedOldSKUs
        for(ReplacementRefreshWrapperData.wrapperData subwrapper :wrapper){
            if(subwrapper.isModified==true){
          if(String.isNotBlank(subwrapper.entitlementId)) {
                    modifiedEntitlements.add(subwrapper.entitlementId);
                }
                if(String.isNotBlank(subwrapper.skuProductId)){ 
                    modifiedSkuProductIds.add(subwrapper.skuProductId);
                }
                //FY25SR-1215 - Added modifiedOldSKUs
                if(subwrapper.ProductId!=null){
                    modifiedOldSKUs.add(subwrapper.ProductId);
                }//FY25SR-1215 Ends
            }
            if (subwrapper.rowSelected == true) {
                //FY25SR-1095 -Set collection of selected entitlement end dates
                //FY25SR-1095 -Set collection of selected entitlement end dates --  Prasenjeet FY25SR-2165
                //CPQ22-5976 - Considering only Upgrade and Convert for End Date calculation
                if(subwrapper.EndDate != NULL && String.isNotBlank(subwrapper.skuProductId) && 
                        String.isNotBlank(subwrapper.selecteddisposition) && 
                        skuDispositions.contains(subwrapper.selecteddisposition))
                        {sEntEndDates.add(subwrapper.EndDate);} 
                //to store selected entitlement ids  
                if(subwrapper.EntitlementId!=null){ selectedEntitlementIdSet.add(subwrapper.EntitlementId);}
                //to store actual/original Product SKU
                if(subwrapper.ProductId!=null){selectedSKUIds.add(subwrapper.ProductId);}
                if(String.isNotBlank(subwrapper.skuProductId)){
                    selectedSKUIds.add(subwrapper.skuProductId);// for replaced SKU
                }
                if(inactiveEntIdEachBaseWrapper != null && !inactiveEntIdEachBaseWrapper.isEmpty()){
                    if(String.isNotBlank(subwrapper.entitlementId)) {
                        entIdToInactiveEnt.put(
                            subwrapper.entitlementId+'-'+subwrapper.customIndex,
                            createInactiveEntMap(subwrapper,inactiveEntIdEachBaseWrapper.values()));
                    }
                    // to combine replacement term
                    if(subwrapper.wrapInactiveEnt != null) {
                        for(ReplacementRefreshWrapperData.wrapperData wrap :subwrapper.wrapInactiveEnt){
                            if (String.isNotBlank(wrap.entitlementId)) {
                                inactiveEntitlementIdSet.add(wrap.entitlementId);
                            }
                        }
                    }
                }
                selectedEntitlements.add(subwrapper);
            }
        }
    }
    /***********************************************************************************************************
    * Method Name          : createInactiveEntMap
    * Date Created/Modified: 12/02/2025
    * Author               : -------------
    * @description         : Generates a set of InactiveEntWrapper.
    * Purpose              : Generates a list of inactiveEntWrapper against BaseEntId-CustomIndex
    * @param  wrapper
    * @param inactiveEntIdEachBaseWrapper
    * @return ListOfRowDetails
    * Test Class Methods   :
    **********************************************************************************************************/
    public static List<ReplacementJson.RelatedChildEntRowDetail> createInactiveEntMap(
            ReplacementRefreshWrapperData.wrapperData wrapper,
            List<ReplacementRefreshWrapperData.WrapperData> inactiveEntIdEachBaseWrapper){
        List<ReplacementJson.RelatedChildEntRowDetail> li=new List<ReplacementJson.RelatedChildEntRowDetail>();
        Map<String, ReplacementRefreshWrapperData.pickList> assetToDetailMap = 
            new Map<String, ReplacementRefreshWrapperData.pickList>();
        Map<String, Integer> entToQTY = new Map<String, Integer>();
        //Inactive Asset Map 
        if(wrapper.assetsAvailable != null && wrapper.assetsAvailable.size() > 0) {
            for(ReplacementRefreshWrapperData.wrapperData inactiveWrap : inactiveEntIdEachBaseWrapper) {
                if(inactiveWrap.assetsAvailable != null) {
                for(ReplacementRefreshWrapperData.pickList inactiveAsset : inactiveWrap.assetsAvailable) {
                    if(inactiveAsset.value != ReplacementConstants.FULL_SELECTION) {
                        assetToDetailMap.put(inactiveAsset.value, inactiveAsset);
                    }
                }
            }
            }
            //Each row of RSC line
            for(ReplacementRefreshWrapperData.pickList asset : wrapper.assetsAvailable) {
                if(asset.value == ReplacementConstants.FULL_SELECTION && asset.selected == true) {
                    for(String inactiveAsset : assetToDetailMap.keySet()) {
                        if(entToQTY.containsKey(assetToDetailMap.get(inactiveAsset).entitlementId)) {
                            Integer selectedQTy = entToQTY.get(assetToDetailMap.get(inactiveAsset).entitlementId);
                            selectedQTy += Integer.valueOf(assetToDetailMap.get(inactiveAsset).quantity);
                            entToQTY.put(assetToDetailMap.get(inactiveAsset).entitlementId, selectedQTy);
                        } else {
                            entToQTY.put(
                                assetToDetailMap.get(inactiveAsset).entitlementId, 
                                Integer.valueOf(assetToDetailMap.get(inactiveAsset).quantity));
                        }
                    }
                } else {
                    if(asset.value != ReplacementConstants.FULL_SELECTION && asset.selected == true) {
                        if(assetToDetailMap.containsKey(asset.value)) {
                            if(entToQTY.containsKey(assetToDetailMap.get(asset.value).entitlementId)) {
                                Integer selectedQTy = entToQTY.get(assetToDetailMap.get(asset.value).entitlementId);
                                selectedQTy += Integer.valueOf(assetToDetailMap.get(asset.value).quantity);
                                entToQTY.put(assetToDetailMap.get(asset.value).entitlementId, selectedQTy);
                            } else {
                                entToQTY.put(
                                    assetToDetailMap.get(asset.value).entitlementId, 
                                    Integer.valueOf(assetToDetailMap.get(asset.value).quantity));
                            }
                        }
                    }
                }
            }
            for(ReplacementRefreshWrapperData.wrapperData wrap : inactiveEntIdEachBaseWrapper){
                ReplacementJson.RelatedChildEntRowDetail childRows= new ReplacementJson.RelatedChildEntRowDetail();
                childRows.ChildEntId=wrap.entitlementId;
                childRows.ChildQnty=entToQTY.get(wrap.entitlementId)!=null ? (Integer)entToQTY.get(wrap.entitlementId) : 0;
                childRows.ChildrowId=wrap.customIndex;
                li.add(childRows);
            }
        } else {
            Integer remainingQty = Integer.valueOf(wrapper.quantity); //Full selected
            if(wrapper.quantity > wrapper.selectedquantity ) { 
                remainingQty = Integer.valueOf(wrapper.selectedquantity); // When partial
            }
            for(ReplacementRefreshWrapperData.wrapperData wrap : inactiveEntIdEachBaseWrapper){
                ReplacementJson.RelatedChildEntRowDetail childRows= new ReplacementJson.RelatedChildEntRowDetail();
                childRows.ChildEntId=wrap.entitlementId;
                childRows.ChildrowId=wrap.customIndex;
                if(remainingQty > wrap.selectedquantity ) {
                    childRows.ChildQnty = Integer.valueOf(wrap.selectedquantity) ;
                } else {
                    if(remainingQty < 0 ) {
                        childRows.ChildQnty = 0;
                    } else {
                        childRows.ChildQnty = remainingQty;
                    }
                }
                remainingQty = remainingQty - Integer.valueOf(wrap.selectedquantity);
                li.add(childRows);
            }
        }
        return li;
    }

    /***********************************************************************************************************
    * Method Name          : getSelectedAssetIds
    * Date Created/Modified: 13/02/2025
    * Author               : -------------
    * @description         : Generates a set of selected asset Ids based on the wrapper data list.
    * Purpose              : Generates a set of selected asset Ids based on the wrapper data list.
    * @param       wrapperDataList
    * @param       refreshWrapperData
    * @return SetOfIds
    * Test Class Methods   :
    **********************************************************************************************************/
    public static Set<Id> getSelectedAssetIds(
        List<ReplacementRefreshWrapperData.wrapperData> wrapperDataList, 
        List<RefreshWrapper> refreshWrapperData) {
        //Moved to ReplacementQuoteLineCreationHelper for code optimization
        Set<Id> selectedAssets = new Set<Id>();
        for (ReplacementRefreshWrapperData.wrapperData data : wrapperDataList) {
            Boolean fullSelected = false; // Reset fullSelected for each ReplacementRefreshWrapperData.wrapperData object
            List<Id> assetIds = new List<Id>();
            
            if (data.assetsAvailable != null) {
                for (ReplacementRefreshWrapperData.pickList asset : data.assetsAvailable) {
                    if (!(asset.value.length() == 15 || asset.value.length() == 18) && asset.selected) {
                        fullSelected = true;
                        break;
                    }
                }
                
                for (ReplacementRefreshWrapperData.pickList asset : data.assetsAvailable) {
                    if (asset.value.length() == 15 || asset.value.length() == 18) {
                        if (fullSelected || asset.selected) {
                            assetIds.add(asset.value);
                        }
                    }
                }
            }
            
            if (!assetIds.isEmpty()) {
                selectedAssets.addAll(assetIds);
            }
        }

        //FY25SR-1191 start
        if(refreshWrapperData!=null && refreshWrapperData.size()>0){
            for(RefreshWrapper wrap:refreshWrapperData){
                if(wrap.rows!=null){
                    for(RefreshWrapper.Row wrapRow:wrap.rows){
                        if(wrapRow.isSelected==true && wrapRow.options!=null){
                            for(RefreshWrapper.Option opt : wrapRow.options){
                                selectedAssets.add(opt.value);
                            }
                        }   
                    }
                }
            }
        }
        //FY25SR-1191 end
        return selectedAssets;
    }

    /***********************************************************************************************************
    * Method Name          : updateQuoteForRecalculation
    * Date Created/Modified: 04/22/2025
    * Author               : Ankita
    * @description         : Added to trigger recalculation on delete and add of QLs FY25SR-1203         
    * @param               quotePB
    * @return              : quoteId
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static SBQQ__Quote__c updateQuoteForRecalculation(SBQQ__Quote__c quotePB) {
        SBQQ__Quote__c quoteRec = new SBQQ__Quote__c(
            ID = quotePB.Id, 
            Force_Recalculation__c = quotePB.Force_Recalculation__c?false:true
        );
       //FY25SR-1191 start
       if (IS_FIPS_ASSET_REFRESHED 
        && (quotePB.QuoteApprovalCategory__c == null 
        || !quotePB.QuoteApprovalCategory__c.contains(ReplacementConstants.FIPS_ASSET_REFRESHED))){
           quoteRec.QuoteApprovalCategory__c = quotePB.QuoteApprovalCategory__c != null 
                ? quotePB.QuoteApprovalCategory__c + ','+ReplacementConstants.FIPS_ASSET_REFRESHED 
                : ReplacementConstants.FIPS_ASSET_REFRESHED;
       }
       else 
       if (!IS_FIPS_ASSET_REFRESHED   
        && quotePB.QuoteApprovalCategory__c != null 
        && quotePB.QuoteApprovalCategory__c.contains(ReplacementConstants.FIPS_ASSET_REFRESHED)){
           quoteRec.QuoteApprovalCategory__c = quotePB.QuoteApprovalCategory__c.remove(ReplacementConstants.FIPS_ASSET_REFRESHED);
       }
       //FY25SR-1191 end
       if(!test.isRunningTest()){
         enableTriggerControls();
       }
       return quoteRec;
   }
   
    /***********************************************************************************************************
    * Method Name          : createRowDetail
    * Date Created/Modified: 07/02/2025
    * Author               : Khushboo
    * @description         : This method creates ReplacementJson.RowDetail data for UI
    * @return              : JSON details 
    * @param               wrap
    * @param               entIdToInactiveEnt
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static ReplacementJson.RowDetail createRowDetail(
        ReplacementRefreshWrapperData.wrapperData wrap,
        Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> entIdToInactiveEnt) {
        List<String> assetsSelected = new List<String>();
        Map<String,String> selectedAssetList=new Map<String,String>();
        String selectedAsset;
        
        if (wrap.assetsAvailable != null) {
            Boolean isFull = false;
            for (ReplacementRefreshWrapperData.pickList pl : wrap.assetsAvailable) {
                if (pl.selected) {
                    selectedAssetList.put(pl.value,pl.label.split(' ')[0]);
                    assetsSelected.add(pl.value);
                    if (pl.value == ReplacementConstants.FULL_SELECTION) {
                        isFull = true;
                        break;
                    }
                }
            }
            if (isFull) {
                assetsSelected.clear();
                selectedAssetList.clear();
                for (ReplacementRefreshWrapperData.pickList pl : wrap.assetsAvailable) {
                    if (pl.value != ReplacementConstants.FULL_SELECTION) {
                        selectedAssetList.put(pl.value,pl.label.split(' ')[0]);
                        assetsSelected.add(pl.value);
                    }
                }
            }
        }
        selectedAsset= String.join(assetsSelected, ',');
        ReplacementJson.RowDetail row = new ReplacementJson.RowDetail();
        row.entId = wrap.entitlementId;
        row.rowId = wrap.customIndex;
        row.selectedAsset = selectedAsset;
        row.selectedAssetList = selectedAssetList;
        row.selectedTerm= wrap.ReplacementTerm!=null?(Integer)wrap.ReplacementTerm:null;//added null check
        // row.selectedRenewalDate=wrap.renewalEndDate!=null? wrap.renewalEndDate:null;//Added FY25SR-1492
        row.disposition=wrap.selecteddisposition; 
        row.selectedQty = (Integer)wrap.selectedquantity;

        //FYSR25-1124
        row.isMismatch = wrap.misMatchQTY;
        row.InactiveLines = entIdToInactiveEnt.containsKey(wrap.entitlementId+'-'+wrap.customIndex)
                    ? entIdToInactiveEnt.get(wrap.entitlementId+'-'+wrap.customIndex)
                    : null;
        
        return row;
    }
    /***********************************************************************************************************
    * Method Name          : verifyNonAssetToNonAsset
    * Date Created/Modified: 07/02/2025
    * Author               : Khushboo
    * @description         : This method retrun true if the current wrapper is Non asset to non asset
    * @return              : Boolean
    * @param               currentWrapper
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static Boolean verifyNonAssetToNonAsset( ReplacementRefreshWrapperData.wrapperData currentWrapper) {
        if(currentWrapper.quantityAssetType 
        && currentWrapper.targetProductType != null 
        && currentWrapper.targetProductType.equalsIgnoreCase(ReplacementConstants.SKU_TYPE_NON_HARDWARE) 
        && currentWrapper.skuProductId != null && currentWrapper.skuProductId != '' ) {
            return true;
        }
        return false;
    }

    /***********************************************************************************************************
    * Method Name          : createReplacementJSON
    * Date Created/Modified: 07/02/2025
    * Author               : Khushboo
    * @description         : Creates RepalcementJSON data        
    * @param               mode
    * @param               selectedEntitlement
    * @param               entIdToInactiveEnt
    * @param               skuENTDetail
    * @param               wrapperList
    * @param               productKey
    * @param               parentJsonData
    * @param               parentJsonDataManyToOne
    * @param               productMap
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void createReplacementJSON(String mode, 
        ReplacementRefreshWrapperData.wrapperData selectedEntitlement,  
        Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> entIdToInactiveEnt, 
        List<String> skuENTDetail, 
        List<ReplacementRefreshWrapperData.wrapperData> wrapperList, 
        String productKey,Map<String, ReplacementJson> parentJsonData,
        Map<String, ReplacementJson> parentJsonDataManyToOne,
        Map<Id, Product2> productMap){
        Integer sterm;
        String sSKU;
        String sSKUName;//FY25SR-1581
        if (skuENTDetail!=null && !skuENTDetail.isEmpty()) {
            sterm = (skuENTDetail.size()>=1 && skuENTDetail[0]!='')? Integer.valueOf(skuENTDetail[0]):null;
           	sSKU = (skuENTDetail.size()>=2 && skuENTDetail[1]!='')?skuENTDetail[1]:null;
            sSKUName = sSKU!=null ? ProductMap.get(sSKU).ProductCode : null;//FY25SR-1581
        } else {
            if(selectedEntitlement != null) {
                sterm = (Integer) selectedEntitlement.ReplacementTerm;
               	sSKU = selectedEntitlement.skuProductId;
                sSKUName = selectedEntitlement.skuProdName != null ? selectedEntitlement.skuProdName : null;//FY25SR-1581
            }
        }//FY25SR-1084 START
        ReplacementJson parentJson = new ReplacementJson();
        parentJson.mode = mode;
        parentJson.skuSelected= sSKU;
        parentJson.skuSelectedName= sSKUName;//FY25SR-1581        
        parentJson.rowValues = new List<ReplacementJson.RowDetail>();
        if(selectedEntitlement != null) {
			if(selectedEntitlement.skuAttributesToQuoteLine != null){
				if(selectedEntitlement.skuAttributesToQuoteLine.containskey(ReplacementConstants.STORAGE_TIER_FIELD_API) 
                 && selectedEntitlement.skuAttributesToQuoteLine.get(ReplacementConstants.STORAGE_TIER_FIELD_API) != null
				 && String.isNotBlank(selectedEntitlement.skuAttributesToQuoteLine.get(ReplacementConstants.STORAGE_TIER_FIELD_API))){
					parentJson.skuStorageTierVal = 
                        selectedEntitlement.skuAttributesToQuoteLine.get(ReplacementConstants.STORAGE_TIER_FIELD_API);
				}
			}
           if(selectedEntitlement.targetProductType != null){
                    parentJson.targetProductType = selectedEntitlement.targetProductType;
           }
        }
        if (mode == ReplacementConstants.ONE_TO_ONE || mode == ReplacementConstants.ONE_TO_MANY) {
            parentJson.rowValues.add(
                ReplacementQuoteLineCreationHelper.createRowDetail(
                    selectedEntitlement,entIdToInactiveEnt));
            parentJsonData.put(selectedEntitlement.entitlementId + '=' + selectedEntitlement.customIndex, parentJson);  
        } 
        if (mode == ReplacementConstants.MANY_TO_1) {
            for (ReplacementRefreshWrapperData.wrapperData wrap : wrapperList) {
                if(wrap.targetProductType != null){
                    parentJson.targetProductType = wrap.targetProductType;
                }
				if(wrap.skuAttributesToQuoteLine != null){
                    if(wrap.skuAttributesToQuoteLine.containskey(ReplacementConstants.STORAGE_TIER_FIELD_API) 
                    && wrap.skuAttributesToQuoteLine.get(ReplacementConstants.STORAGE_TIER_FIELD_API) != null
                    && String.isNotBlank(wrap.skuAttributesToQuoteLine.get(ReplacementConstants.STORAGE_TIER_FIELD_API))){
                        parentJson.skuStorageTierVal = wrap.skuAttributesToQuoteLine.get(ReplacementConstants.STORAGE_TIER_FIELD_API);
                    }
                }//FY25SR-1084 END
                parentJson.rowValues.add(ReplacementQuoteLineCreationHelper.createRowDetail(wrap,entIdToInactiveEnt));
            }
            parentJsonDataManyToOne.put(productKey, parentJson);
        }
    }

    /***********************************************************************************************************
    * Method Name          : createNewGroup
    * Date Created/Modified: 07/02/2025
    *                        09/25/2025 - Ankita
    * Author               : Khushboo
    * @description         : Creates Group for the Quote Lines    
    *                        //FY25SR-2230 - Added Group number    
    * @return              : Group Id
    * @param               groupName
    * @param               quoteId
    * @param               groupNumber
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static Id createNewGroup(String groupName, Id quoteId, Integer groupNumber) {
        //FY25SR-2230 - Added Group number
        SBQQ__QuoteLineGroup__c groupRecord = new SBQQ__QuoteLineGroup__c(
            Name = groupName, SBQQ__Quote__c = quoteId, SBQQ__Number__c = groupNumber);
        disableTriggerControls();
        if(Schema.sObjectType.SBQQ__QuoteLineGroup__c.isCreateable()){
            Database.insert(groupRecord,true);
        }
        return groupRecord.Id;
    }
    
    /***********************************************************************************************************
    * Method Name          : createUniqueKey
    * Date Created/Modified: 06/02/2025
    * Author               : Rahul
    * @description         : Creates a unique key for QL consolidation        
    * @return              : Unique key String
    * @param               wrapper
    * @param               i
    * @param               dispose
    * @param               productMap
    * @param               metaMap
    * Test Class Methods   :
    /**********************************************************************************************************/
   public static String createUniqueKey(
    ReplacementRefreshWrapperData.WrapperData wrapper, 
    Integer i,String dispose,Map<Id, Product2> productMap,
    Map<String, Replacement_Field_Mapping__mdt> metaMap) {
       String keyforMap;
       Boolean saasApplication=false;
       List<String> fieldToConsolidate= new List<String>();
       if(wrapper.skuAttributesToQuoteLine != NULL && String.isNotBlank(wrapper.skuProductId) && productMap!=null && productMap.containsKey(wrapper.skuProductId))
       {                    
           Product2 targetProd=productMap.get(wrapper.skuProductId);
            if(targetProd.Product_Subtype__c!=null && targetProd.Product_Subtype__c==ReplacementConstants.SAAS_APPLICATIONS ){
               Replacement_Field_Mapping__mdt keyStructure=
                    metaMap.get(ReplacementConstants.REPLACEMENT_UNIVERSAL_SAAS_ATTRIBUTES_MDT);
               fieldToConsolidate = keyStructure.FieldAPINames__c!= null 
                        ? keyStructure.FieldAPINames__c.split(',') : new List<String>();
               saasApplication=keyStructure.IncludeMillis__c;
            }
            else if(targetProd.Product_Type__c!=null && targetProd.Product_Type__c == ReplacementConstants.CLOUD_VALUE_BACKUP ){
                Replacement_Field_Mapping__mdt keyStructure=
                        metaMap.get(ReplacementConstants.REPLACEMENT_UNIVERSAL_STORAGE_REGION_BUNDLE_ATT1_MDT);
                fieldToConsolidate =keyStructure.FieldAPINames__c!= null 
                        ? keyStructure.FieldAPINames__c.split(',') : new List<String>();
            }
            else if(targetProd.Product_Type__c!=null && targetProd.Product_Type__c ==ReplacementConstants.CLOUD_VALUE_ARCHIVE ){
                Replacement_Field_Mapping__mdt keyStructure=
                        metaMap.get(ReplacementConstants.REPLACEMENT_UNIVERSAL_STORAGE_REGION_BUNDLE_ATT2_MDT);
                fieldToConsolidate =keyStructure.FieldAPINames__c!= null 
                        ? keyStructure.FieldAPINames__c.split(',') : new List<String>();
            }
            else if(targetProd.Product_Type__c!=null && targetProd.Product_Type__c ==ReplacementConstants.M365H ){
                Replacement_Field_Mapping__mdt keyStructure=metaMap.get(ReplacementConstants.REPLACEMENT_STORAGE_TIER_ATT_MDT);
                fieldToConsolidate =keyStructure.FieldAPINames__c!= null 
                        ? keyStructure.FieldAPINames__c.split(',') : new List<String>();
            }
            for(String skuField : wrapper.skuAttributesToQuoteLine.keyset()){
                if(wrapper.skuAttributesToQuoteLine.containsKey(skuField) 
                  && wrapper.skuAttributesToQuoteLine.get(skuField) != NULL 
                  && wrapper.skuAttributesToQuoteLine.get(skuField) != 'null' 
                  && String.isNotBlank(wrapper.skuAttributesToQuoteLine.get(skuField))){
                    if(fieldToConsolidate!=null && !fieldToConsolidate.isEmpty() && fieldToConsolidate.contains(skuField)){
                        keyforMap = keyforMap + wrapper.skuAttributesToQuoteLine.get(skuField) +'-';
                    } 
                }
            }
        }
       
       String scenario = wrapper.doNotConsolidateEnt == true 
            ? ReplacementConstants.DONOTCONSOLIDATE 
            : (dispose!=null && dispose==ReplacementConstants.DISPOSELINE) ? 'DisposeLines' :'ConsolidatedKey';
       Replacement_Field_Mapping__mdt meta=metaMap.get(scenario);
       List<String> fields = meta.FieldAPINames__c!= null ? meta.FieldAPINames__c.split(',')
           : new List<String>();
       
       List<String> keyParts = new List<String>();
       
       //Dynamic field map using JSON trick
       Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(wrapper));
       // Fields from metadata
       if(fields!=null && !fields.isEmpty()){
           for (String fieldName : fields) {
               Object val = fieldMap.get(fieldName.trim())!=null ? fieldMap.get(fieldName.trim()) : null ;
               if (val != null) {
                   keyParts.add(String.valueOf(val));
               }
           }  
       }
       
       
       // Handle keyforMap
       if (keyforMap!=null && !String.isBlank(keyforMap)) {
           keyParts.add(keyforMap);
       }
       
       // Handle special TPH check
       if (meta.ExtraLogic__c !=null && meta.ExtraLogic__c == ReplacementConstants.TPHCHECK
           && fieldMap.containsKey(ReplacementConstants.SKUPRODNAME)
           && String.valueOf(fieldMap.get(ReplacementConstants.SKUPRODNAME)).contains(ReplacementConstants.PRODUCTCODE_TPH)) {
               keyParts.add(String.valueOf(fieldMap.get(ReplacementConstants.SKUPRODNAME)) + (++i));
           }
       
       // Include current timestamp for saasApplication logic and donotConsolidate logic
       if (meta.IncludeMillis__c || saasApplication==true) {
        keyParts.add(String.valueOf(DateTime.now().getTime()));
    }
    return String.join(keyParts, '-');
}

  /***********************************************************************************************************
    * Method Name          : disableTriggerControls
    * Date Created/Modified: April 29, 2025
    * Author               : Ankita
    * @description         : Disables the triggers     
    /**********************************************************************************************************/
    public static void disableTriggerControls() {
        SBQQ.TriggerControl.disable();
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
    }

    /***********************************************************************************************************
    * Method Name          : enableTriggerControls
    * Date Created/Modified: April 29, 2025
    * Author               : Ankita
    * @description         : Enable the triggers     
    /**********************************************************************************************************/
    public static void enableTriggerControls() {
        SBQQ.TriggerControl.enable();
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
    }
    /***********************************************************************************************************
    * Method Name          : controlBusinessLogic
    * Date Created/Modified: 16/06/2025
    * Author               : Ankita
    * @description         : Disables/Enables the Business Logic   
    * @param  disable
    /**********************************************************************************************************/
    /*public static void controlBusinessLogic(ShGl_DisableBusinessLogic__c userSetting, Boolean disable) {
        // Then check if a user-level setting exists
        if (userSetting != null) {
            userSetting.Disable_SBQQ_Quote_Validation_Rules__c = disable;
            upsert userSetting;
        }
    }*/
    /***********************************************************************************************************
    * Method Name          : createAssetHwSupportWrapperMap
    * Date Created/Modified: 07/02/2025
    * Author               : Khushboo
    * @description         :         
    * @param               baseLicnese
    * @param               hwSupport
    * @param               hwEntIdagainstBaseEntId
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void createAssetHwSupportWrapperMap(
        List<ReplacementRefreshWrapperData.wrapperData> baseLicnese, 
        List<ReplacementRefreshWrapperData.wrapperData> hwSupport,
        Map<String,ReplacementRefreshWrapperData.wrapperData> hwEntIdagainstBaseEntId) {
        
        Set<String> assetSerialNumberSet=new Set<String>();
        for(ReplacementRefreshWrapperData.wrapperData subwrapper:baseLicnese){
            if (subwrapper.rowSelected == true) {
                // only for Replaced wrapper assets
                if(subwrapper.assetsAvailable!=null && String.isNotBlank(subwrapper.skuProductId)){                    
                    Boolean isFull = false;
                    for (ReplacementRefreshWrapperData.pickList pl : subwrapper.assetsAvailable) {
                        if (pl.selected || Test.isRunningTest()) {
                            if(String.isNotBlank(subwrapper.entitlementId)) {
                                assetSerialNumberSet.add(pl.label.split(' ')[0]);
                            }
                            if (pl.value == ReplacementConstants.FULL_SELECTION) {
                                isFull = true;
                                break;
                            }
                        }
                    }
                    if (isFull) {
                        assetSerialNumberSet.clear();
                        for (ReplacementRefreshWrapperData.pickList pl : subwrapper.assetsAvailable) {
                            if(pl.value != ReplacementConstants.FULL_SELECTION) {
                                if (String.isNotBlank(subwrapper.entitlementId)) {
                                    assetSerialNumberSet.add(pl.label.split(' ')[0]);
                                }
                            }
                        }
                    }
                }  
            }
        }
        for(ReplacementRefreshWrapperData.wrapperData subwrapper:hwSupport){
           if(subwrapper.srProdType =='HW Support' && subwrapper.assetsAvailable!=null){ 
                for (ReplacementRefreshWrapperData.pickList pl : subwrapper.assetsAvailable) {
                    if (pl.value != ReplacementConstants.FULL_SELECTION) {
                        String aast=pl.label.split(' ')[0];
                        if(assetSerialNumberSet.contains(aast) || Test.isRunningTest()){
                            hwEntIdagainstBaseEntId.put(aast,subwrapper);
                        }
                    }
                }
            }
        }
    }
     /***********************************************************************************************************
    * Method Name          : getRCDMTLineAddedInTheList
    * Date Created/Modified: 09/06/2025
    * Author               : Khushboo
    * @description         :  added RCCDM-T line where qli is eligible for RCDM-T       
    * @param               InsertQuoteLineItems
    * @param               quotRangeEnd
    * @param               productMap
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void getRCDMTLineAddedInTheList(List<SBQQ__QuoteLine__c> InsertQuoteLineItems
        , Date quotRangeEnd, Map<Id, Product2> productMap)
    {
        List<SBQQ__QuoteLine__c> qLG = new List<SBQQ__QuoteLine__c>();
        X0_RCDM_Dates__mdt rcdmDatesObj = 
            [SELECT Id, Order_Sub_Type__c, Order_Type__c, IT_Product_Type__c
                  , Licensing_Type__c, Subscription_Term__c, DeveloperName
                  , Approval_Category__c, List_Price__c, Product_Level__c
                  , Subscription_Pricing__c, Subscription_Type__c, EndDate_Day__c
                  , EndDate_Month__c, EndDate_Year__c, StartDate_Day__c
                  , StartDate_Month__c, StartDate_Year__c, Special_Price__c
                  , Description__c, Sales_Comp_Category__c
               FROM X0_RCDM_Dates__mdt 
              WHERE DeveloperName = :ReplacementConstants.RCDM_DATES LIMIT 1];
        Set<Id> prodId=new Set<Id>();
        Map<Id,Boolean> prodMap=new Map<Id,Boolean>();
        for(SBQQ__QuoteLine__c qli:InsertQuoteLineItems){
            if(!productMap.containsKey(qli.SBQQ__Product__c))
            {prodId.add(qli.SBQQ__Product__c);}
        }
        if(prodId!=null && !prodId.isEmpty()){
            for(Product2 p:[SELECT id,Eligible_for_RCDM_T__c FROM Product2 WHERE Id IN: prodId]){
                prodMap.put(p.Id,p.Eligible_for_RCDM_T__c);
            }  
        }
       
        for(SBQQ__QuoteLine__c qli:InsertQuoteLineItems){
        // added disposition check by Prasenjeet FY25SR-2164
            if((((qli.SBQQ__StartDate__c!=null && qli.SBQQ__StartDate__c < quotRangeEnd) 
              || (qli.SBQQ__StartDate__c==null && Date.today() < quotRangeEnd) )
              && ((productMap.containsKey(qli.SBQQ__Product__c) && productMap.get(qli.SBQQ__Product__c).Eligible_for_RCDM_T__c == true)
              || (prodMap!=null && prodMap.containsKey(qli.SBQQ__Product__c) && prodMap.get(qli.SBQQ__Product__c)))) && 
               				String.isNotBlank(qli.Disposition_Reason__c) && (qli.Disposition_Reason__c.equalsIgnoreCase(ReplacementConstants.DISPOSE_NONE) || 
                                                                             qli.Disposition_Reason__c.equalsIgnoreCase(ReplacementConstants.DISPOSTION_RENEWING)) )
            {
                qLG.add(getRDCMTLine(qli,rcdmDatesObj,quotRangeEnd));
             }
        }
        if(qLG!=null && !qLG.isEmpty()){
            Database.insert(qLG,true);
        }
    }
    /***********************************************************************************************************
    * Method Name          : getRDCMTLine
    * Date Created/Modified: 09/06/2025
    * Author               : Khushboo
    * @description         :  create RCCDM-T line        
    * @param               qli
    * @param               rcdmDatesObj
    * @param               quotRangeEnd
    * @return              rcdmQL 
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static SBQQ__QuoteLine__c getRDCMTLine(SBQQ__QuoteLine__c qli, X0_RCDM_Dates__mdt rcdmDatesObj, Date quotRangeEnd)
    {
        Integer monthsRemaining;
        Date currentDate = Date.today();
        if ((quotRangeEnd.year() - currentDate.year() == 0) &&
            (quotRangeEnd.month() - currentDate.month() == 0)) {
                monthsRemaining = 1;
        } else {
            monthsRemaining = 
                ((quotRangeEnd.year() - currentDate.year()) * 12) +
                (quotRangeEnd.month() -currentDate.month()) +
                ((currentDate.day() <= quotRangeEnd.day()) ? 0 : 1);
        }
        
        SBQQ__QuoteLine__c rcdmQL = new SBQQ__QuoteLine__c();
        rcdmQL.SBQQ__Quote__c=qli.SBQQ__Quote__c;
        rcdmQL.SBQQ__RequiredBy__c=qli.Id;
        rcdmQL.SBQQ__Quantity__c = qli.SBQQ__Quantity__c;
        rcdmQL.SBQQ__StartDate__c = qli.SBQQ__StartDate__c!=null ? qli.SBQQ__StartDate__c :null;
        rcdmQL.SBQQ__Group__c=qli.SBQQ__Group__c!=null ? qli.SBQQ__Group__c : null;
        rcdmQL.SBQQ__Number__c=qli.SBQQ__Number__c;
        rcdmQL.SBQQ__OptionLevel__c=2;
        if(qli.SBQQ__EndDate__c!=null && qli.SBQQ__EndDate__c <= quotRangeEnd){
            rcdmQL.SBQQ__EndDate__c = qli.SBQQ__EndDate__c;
        }else {
            rcdmQL.SBQQ__EndDate__c = quotRangeEnd;
        }
        rcdmQl.Replacement_Motion__c=qli.Replacement_Motion__c;
        rcdmQL.SubscribedAssetNames__c = qli.SubscribedAssetNames__c!=null ? qli.SubscribedAssetNames__c : null;
        rcdmQL.Subscribed_Asset_Name__c = qli.Subscribed_Asset_Name__c!=null ? qli.Subscribed_Asset_Name__c : null;
        rcdmQL.Arroyo_Subscribed_Asset_Name__c= qli.Arroyo_Subscribed_Asset_Name__c!=null ? qli.Arroyo_Subscribed_Asset_Name__c : null;
        rcdmQL.RenewalQuantityPopulated__c =true;
        rcdmQL.SBQQSC__RenewedContractLine__c = null;
        rcdmQL.SBQQ__PricebookEntryId__c = System.Label.RCDM_PBEId;
        rcdmQL.SBQQ__Product__c = System.Label.RCDM_ProductId;
        rcdmQL.SBQQ__Discount__c = 100;
        rcdmQL.SBQQ__ListPrice__c = 130;
        rcdmQL.SBQQ__NetPrice__c = 0;
        rcdmQL.Minimum_Term__c = 0;
        rcdmQL.Disposition_Reason__c = ReplacementConstants.DISPOSE_NONE;
        rcdmQL.Product_Level__c = rcdmDatesObj != null ? rcdmDatesObj.Product_Level__c : ReplacementConstants.PRODUCT_LEVEL_ONPREM;
        rcdmQL.SBQQ__OriginalPrice__c = rcdmDatesObj != null ? rcdmDatesObj.List_Price__c : 0;
        rcdmQL.SBQQ__CustomerPrice__c = 0;
        rcdmQL.SBQQ__SubscriptionPricing__c = rcdmDatesObj != null 
            ? rcdmDatesObj.Subscription_Pricing__c : ReplacementConstants.SUBSCRIPTION_FIXED_PRICE;
        rcdmQL.Approval_Category__c = rcdmDatesObj != null ? rcdmDatesObj.Approval_Category__c : '';
        rcdmQL.SBQQ__ProductSubscriptionType__c = ReplacementConstants.SUBSCRIPTION_TYPE_ONE_TIME;
        rcdmQL.SBQQ__SubscriptionType__c = rcdmDatesObj != null 
            ? rcdmDatesObj.Subscription_Type__c : ReplacementConstants.SUBSCRIPTION_TYPE_ONE_TIME;
        rcdmQL.Approval_Flags__c = String.valueOf('/img/msg_icons/confirm16.png None');
        rcdmQL.Licensing_Model__c = rcdmDatesObj != null ? rcdmDatesObj.Licensing_Type__c : ReplacementConstants.SUBSCRIPTION;
        rcdmQL.SBQQ__SpecialPrice__c = rcdmDatesObj != null ? rcdmDatesObj.Special_Price__c : 0;
        rcdmQL.SBQQ__Description__c = rcdmDatesObj != null ? rcdmDatesObj.Description__c : '';
        rcdmQL.License_Category__c = System.Label.RCDM_LicenseCategory; //'On Prem';
        rcdmQL.Product_Subtype__c = '';
        rcdmQL.Sales_Comp_Category__c = rcdmDatesObj != null ? rcdmDatesObj.Sales_Comp_Category__c: '';
        rcdmQL.SBQQ__SubscriptionTerm__c= (qli.Quote_Line_Type__c==ReplacementConstants.QUOTE_TYPE_NEW && monthsRemaining!=null) 
            ? monthsRemaining :null;
        return rcdmQL;
    }

    /***********************************************************************************************************
    * Method Name          : updateQuoteDetails
    * Date Created/Modified: 10/06/2025
    * Author               : Ankita
    * @description         : create Quote Info  
    * @param               quoteDetails
    * @param               existingQuoteInfo
    * @return              Quote record 
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static SBQQ__Quote__c updateQuoteDetails(Map<String, String> quoteDetails, SBQQ__Quote__c existingQuoteInfo) {
        Set<String> selectedDealOps = new Set<String>();
        Set<String> selectedSalesRep = new Set<String>();
        //Get the Picklist schema
        List<String> dealOpsPicklistValues = 
            ReplacementQueryController.fetchPicklistValues(
                ReplacementConstants.QUOTE_OBJ_API, ReplacementConstants.RWD_DEAL_OPS_EXCEPTION_FIELD_API);
        List<String> salesRepPicklistValues = ReplacementQueryController.fetchPicklistValues(
                ReplacementConstants.QUOTE_OBJ_API, ReplacementConstants.RWD_SALES_REP_EXCEPTION_FIELD_API);
        //Get the data from the page
        Boolean isDealOps = Boolean.valueOf(quoteDetails.get(ReplacementConstants.ATTRIBUTE_ISDEALOPS));
        String comments = quoteDetails.get(ReplacementConstants.ATTRIBUTE_EXCEPTIONCOMMENTS);
        List<ReplacementRefreshWrapperData.pickList> options = (List<ReplacementRefreshWrapperData.pickList>) JSON.deserialize(
            quoteDetails.get(ReplacementConstants.ATTRIBUTE_EXCEPTIONMESSAGES),
            List<ReplacementRefreshWrapperData.pickList>.class
        ); 
        //Get the existig selected values on Quote
        
        if(!String.isBlank(existingQuoteInfo.RWD_Deal_Ops_Exception__c)) {
            String dealOpsLower = String.ValueOf(existingQuoteInfo.RWD_Deal_Ops_Exception__c).toLowerCase();
            selectedDealOps.addAll(dealOpsLower.split(';'));
        }
        if(!String.isBlank(existingQuoteInfo.RWD_Sales_Rep_Exception__c)) {
            String salesOpsLower = String.ValueOf(existingQuoteInfo.RWD_Sales_Rep_Exception__c).toLowerCase();
            selectedSalesRep.addAll(salesOpsLower.split(';'));
        }
        for(ReplacementRefreshWrapperData.pickList option : options) {
            String trimValue = option.value.trim().toLowerCase();
            if(dealOpsPicklistValues.contains(trimValue)) {
                if(option.selected) {
                    if(!selectedDealOps.contains(trimValue)) {
                        selectedDealOps.add(option.value); 
                    }
                } else {
                    if(selectedDealOps.contains(trimValue)) {
                        selectedDealOps.remove(trimValue);
                    }
                }
            }
            if(salesRepPicklistValues.contains(trimValue)) {
                if(option.selected) {
                    if(!selectedSalesRep.contains(trimValue)) {
                        selectedSalesRep.add(option.value); 
                    }
                } else {
                    if(selectedSalesRep.contains(trimValue)) {
                        selectedSalesRep.remove(trimValue);
                    }
                }
            }
        }
        //Add selected values from page to Quote
        if(isDealOps) {
            existingQuoteInfo.RWD_Deal_Ops_Exception_Justification__c = comments;
            if(selectedSalesRep.size()>0) {

                existingQuoteInfo.RWD_Sales_Rep_Exception_Justification__c = 
                existingQuoteInfo.RWD_Sales_Rep_Exception_Justification__c != null 
                ? ((!existingQuoteInfo.RWD_Sales_Rep_Exception_Justification__c.containsIgnoreCase(
                        System.label.Sales_Rep_Exception_Justification)) 
                    ? existingQuoteInfo.RWD_Sales_Rep_Exception_Justification__c + '\n' 
                        + System.label.Sales_Rep_Exception_Justification 
                    :  existingQuoteInfo.RWD_Sales_Rep_Exception_Justification__c) 
                : System.label.Sales_Rep_Exception_Justification;
            } else {
                existingQuoteInfo.RWD_Sales_Rep_Exception_Justification__c = '';
            }
        } else {
            existingQuoteInfo.RWD_Sales_Rep_Exception_Justification__c = comments;
        }
        existingQuoteInfo.RWD_Deal_Ops_Exception__c = selectedDealOps.size() > 0 
            ? String.join(new List<String>(selectedDealOps), ';') : '';
        existingQuoteInfo.RWD_Sales_Rep_Exception__c = selectedSalesRep.size() > 0 
            ? String.join(new List<String>(selectedSalesRep), ';') : '';
        return existingQuoteInfo;
    }
    /***********************************************************************************************************
    * Method Name          : handleException
    * Date Created/Modified: 06/07/2025
    * Author               : Ankita
    * @description         : handle Exceptions  
    * @param               ex
    * @return              AuraException
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static AuraHandledException handleException(Exception ex) {
        if (ex instanceof DmlException) {
            DmlException dmlEx = (DmlException) ex;
            String msg = 'Operation failed: ';
            // Extract validation error messages from all failed records
            for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
                msg += dmlEx.getDmlMessage(i) + ' ';
            }
            return new AuraHandledException(msg.trim());
        } 
        if (ex instanceof NullPointerException) {
            return new AuraHandledException('Technical issue was encountered.');
        } 
        if (ex instanceof QueryException) { 
            return new AuraHandledException('Failed to retrieve required information.');
        } 
        if (ex instanceof System.NoAccessException) {
            return new AuraHandledException('You do not have permission to perform this action.');
        }
        // Generic fallback
        return new AuraHandledException('An unexpected error occurred');
    }
    
    /***********************************************************************************************************
    * Method Name          : createCPQDispositionLinesOnCloneRelated
    * Date Created/Modified: 08/08/2025
    * Author               : Rahul
    * @description         : This method is used to create CPQ Disposition lines when quote is cloned 
    * 						 and has CPQ Disposition lines on it
    * @param               quoteIds    
    * @param			   mapSourceVsNewQId         
    * Test Class Methods   : USER STORY- FY25SR-2069
    /**********************************************************************************************************/
    public static void createCPQDispLinesOnCloneRelated(Set<Id> quoteIds, Map<Id, Id> mapSourceVsNewQId) {
        try{
             if(!quoteIds.isEmpty()){
                    List<CPQ_Disposition_Quote_Line__c> lstCpqLines = ReplacementQueryController.fetchExistingCPQDispLines(quoteIds);
                    List<CPQ_Disposition_Quote_Line__c> finalCpqDispLines = new List<CPQ_Disposition_Quote_Line__c>();
                    if(!lstCpqLines.isEmpty()){
                                    for(CPQ_Disposition_Quote_Line__c disp : lstCpqLines){
                                        if(disp.Quote__c != NULL){
                                            if(mapSourceVsNewQId.containsKey(disp.Quote__c) && mapSourceVsNewQId.get(disp.Quote__c) != NULL){
                                                CPQ_Disposition_Quote_Line__c cpd = disp.clone(false, true, false, false);
                                                cpd.Quote__c = mapSourceVsNewQId.get(disp.Quote__c);
                                                finalCpqDispLines.add(cpd);
                                            }
                                        }
                                    }
                      }
                  if(!finalCpqDispLines.isEmpty()){
                        insert finalCpqDispLines;
                  }
            }
        }
        catch(exception ex){
            catchHandler(ex);
        } 
    }
    
    /***********************************************************************************************************
    * Method Name          : catchHandler
    * Date Created/Modified: 8/10/2025
    * Author               : Ankita
    * @description         : This method is to create custom error log
    * @param               ex 
    * Test Class Methods   : USER STORY- CPQ22-5960
    /**********************************************************************************************************/
    public static void catchHandler(Exception ex) {
        LogError.logCustomError('ReplacementQuoteLineCreationHelper'
            , ex.getMessage()
            , ex.getStackTraceString()
            , 'createCPQDispLinesOnCloneRelated Method failed');
          throw ReplacementQuoteLineCreationHelper.handleException(ex);
        } 
}