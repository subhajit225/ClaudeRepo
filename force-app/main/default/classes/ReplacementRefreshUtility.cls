/**
* @File Name : ReplacementRefreshUtility.cls
* @description : The utililty class for Replacement and Refresh classes
* @Author : Rahul/Shivani/Ankita/Sumedha
* @Last Modified By :
* @Last Modified On : February 3, 2025
* Developed as part of : FY25SR-1100, FY25SR-1087, FY25SR-1088, FY25SR-1098, FY25SR-1101, FY25SR-1073
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 3, 2025 |   | Initial Version
**/

public without sharing class ReplacementRefreshUtility { 
    public static String qType; //Type of Quote
    //Set of Entitlements processed
    public static Set<Id> entAlreadyProcessed = new Set<Id>();
    /***********************************************************************************************************
    * Method Name          : createBundledWrap
    * Date Created/Modified: 18/03/2025
    * Author               : Sumedha
    * @description         : Creates Wrapper for RSC and HW Support bundled together
    * @param ent
    * @param lstInactiveEnts 
    * @param mapEntvsSCENT
    * @param hwSuppIdvsEntLst
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void createBundledWrap(Entitlement ent, Map<Id, List<Entitlement>> lstInactiveEnts,
    Map<String, List<Scale_Entitlement__c>> mapEntvsSCENT, Map<Id, List<Entitlement>> hwSuppIdvsEntLst) {
        ReplacementRefreshWrapperData.wrapperData objWrap = new ReplacementRefreshWrapperData.wrapperData();
        objWrap.wrapInactiveEnt = new List<ReplacementRefreshWrapperData.wrapperData>();
        //Create wrap for base license
        List<ReplacementRefreshWrapperData.wrapperData> baseLice = new List<ReplacementRefreshWrapperData.wrapperData>();
        
        ReplacementRefreshWrapperData.wrapperData objWrapperData = formCommonWrapper(ent, mapEntvsSCENT );
        //FY25SR-1207 - added mapAstvsLic and Status check
        //Gets inactive entitlements associated with wrapBaseLicense
        createWrapForInactiveUG (lstInactiveEnts, objWrapperData, mapEntvsSCENT);
        if (!checkEntitlementProcessed(ent.Id) && ent.Status != ReplacementConstants.STATUS_INACTIVE) {
            baseLice.add(objWrapperData);   
            objWrap.wrapBaseLicense = baseLice;
        }
        //Gets inactive entitlements associated with wrapBaseLicense
        entAlreadyProcessed.add(ent.Id);

        //For HW Support Wrapper
        createHWSuppWrap (ent, objWrap, hwSuppIdvsEntLst, lstInactiveEnts, mapEntvsSCENT);
        
        //Adds to the map only if Entitlement id is present
        if (String.isNotBlank(objWrapperData.entitlementId) && 
        ((objWrap.wrapBaseLicense != null && !objWrap.wrapBaseLicense.isEmpty()) 
          || (objWrap.wrapHWSupportLines != null && !objWrap.wrapHWSupportLines.isEmpty()))) {
            ReplacementRefreshController.mapOfWrap.put(objWrapperData.entitlementId, objWrap);
        }
    }
    /***********************************************************************************************************
    * Method Name          : createHWSuppWrap
    * Date Created/Modified: 28/03/2025
    * Author               : Sumedha
    * @description         : Create Wrapper for HW Support SKUs and attach it with the RSC Entitlement
    * @param rscEnt
    * @param wrapInScope
    * @param hwSuppIdvsEntLst
    * @param lstInactiveEnts
    * @param mapEntvsSCENT
    /**********************************************************************************************************/
    public static void createHWSuppWrap(Entitlement rscEnt, ReplacementRefreshWrapperData.WrapperData wrapInScope
        , Map<Id, List<Entitlement>>  hwSuppIdvsEntLst, Map<Id, List<Entitlement>> lstInactiveEnts
        , Map<String, List<Scale_Entitlement__c>> mapEntvsSCENT) {
        //For HW Support Wrapper
        if (!hwSuppIdvsEntLst.isEmpty() && hwSuppIdvsEntLst.containsKey(rscEnt.Id) && hwSuppIdvsEntLst.get(rscEnt.Id) != null ) {
            for(Entitlement ets : hwSuppIdvsEntLst.get(rscEnt.Id)){
                List<ReplacementRefreshWrapperData.WrapperData> lstWrap1 = new List<ReplacementRefreshWrapperData.WrapperData>();
                ReplacementRefreshWrapperData.WrapperData wps = formCommonWrapper(ets, mapEntvsSCENT ); 
                //Gets inactive entitlements associated with each of HW Support Entitlement
                createWrapForInactiveUG (lstInactiveEnts, wps, mapEntvsSCENT );
                //FY25SR-1207 - added mapAstvsLic, Status check and existingLst
                if (!checkEntitlementProcessed(ets.id) && ets.Status != ReplacementConstants.STATUS_INACTIVE) {
                    lstWrap1.add(wps);
                    if (wrapInScope.wrapHWSupportLines != null && !wrapInScope.wrapHWSupportLines.isEmpty()) {
                        List<ReplacementRefreshWrapperData.WrapperData> existingLst = wrapInScope.wrapHWSupportLines;
                        existingLst.addAll(lstWrap1);
                        wrapInScope.wrapHWSupportLines = existingLst;
                    } else {
                        wrapInScope.wrapHWSupportLines = lstWrap1;
                    }
                }
                entAlreadyProcessed.add(ets.Id);
            }
        }
        if(wrapInScope.wrapHWSupportLines == NULL){
            wrapInScope.wrapHWSupportLines = new List<ReplacementRefreshWrapperData.wrapperData>();
        }
    }

    /***********************************************************************************************************
     * Method Name          : getDispositionValue
     * Date Created/Modified: 28/03/2024
     * Author               : Shivani/Rahul
     * @description         : Creates picklist values for disposition reason based on Manual/Automatic Selection
     * @return              : List of picklist values
     * @param drType
     * Test Class Methods   :
     /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<ReplacementRefreshWrapperData.pickList> getDispositionValue(String drType) {
        List<ReplacementRefreshWrapperData.pickList> picklistVals = new List<ReplacementRefreshWrapperData.pickList>();
        if (Test.isRunningTest() && String.isBlank(qType)) {
            qType = ReplacementConstants.QUOTE_TYPE_RENEWAL;
        }
        List<ReplacementRefreshWrapperData.pickList> picklistValues = new List<ReplacementRefreshWrapperData.pickList>();
        if (!ReplacementRefreshController.lstReasons.isEmpty()) {
            for (Replacement_Field_Mapping__mdt repRec : ReplacementRefreshController.lstReasons) {
                if (drType == ReplacementConstants.AUTO_TYPE) {
                    if (repRec.Autoselected__c) {
                        ReplacementRefreshWrapperData.pickList objU =(picklistData (repRec));
                        picklistVals.add(objU);
                    }
                } 
                if (drType == ReplacementConstants.MANUAL_TYPE) {
                    if (!repRec.Autoselected__c) { 
                        ReplacementRefreshWrapperData.pickList objU = (picklistData (repRec));
                        picklistVals.add(objU);
                    }
                }
            }
        }
        picklistValues = picklistVals;
        return picklistValues;
    }
    /***********************************************************************************************************
    * Method Name          : picklistData
    * Date Created/Modified: 06/02/2025
    * Author               : Sumedha
    * @description         : Common fields to create wrapper. 
    * @return              : Wrapper data that has been created
    * @param                repRec
    /**********************************************************************************************************/
    public static ReplacementRefreshWrapperData.pickList picklistData(Replacement_Field_Mapping__mdt repRec) {
        ReplacementRefreshWrapperData.pickList objU = new ReplacementRefreshWrapperData.pickList();
        objU.value = repRec.Picklist_Value__c;
        objU.label = repRec.Picklist_Label__c;
        objU.selected = false;
        return objU;
    }

    /***********************************************************************************************************
    * Method Name          : formCommonWrapper
    * Date Created/Modified: 06/02/2025 --- 04/06/2025
    * Author               : Shivani/Rahul
    * @description         : Common fields to create wrapper. 
    * @return              : Wrapper data that has been created
    * @param                objEntitlement 
    * @param                mapEntitlemmemntNameToScaleEntitlements
    * Test Class Methods   : 
    /**********************************************************************************************************/
    public static ReplacementRefreshWrapperData.wrapperData formCommonWrapper(Entitlement objEntitlement
        , Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements ){
        //Holds wrapper instance
        ReplacementRefreshWrapperData.wrapperData objWrapperData = 
            new ReplacementRefreshWrapperData.wrapperData();
        //Holds asset names which are available per entitlement
        Set<ReplacementRefreshWrapperData.pickList> assetsAvailable = 
            new Set<ReplacementRefreshWrapperData.pickList>();
        //Holds asset names which are available per entitlement
        Map<String, Set<ReplacementRefreshWrapperData.pickList>> setassetsAvailable = 
            new Map<String, Set<ReplacementRefreshWrapperData.pickList>>();
         
        List<ReplacementRefreshWrapperData.pickList> autoDispositionValues = getDispositionValue(ReplacementConstants.AUTO_TYPE); 
        List<ReplacementRefreshWrapperData.pickList> manualDispositionValues = getDispositionValue(ReplacementConstants.MANUAL_TYPE); 
        //Create wrapper instance using Entitlement data
        objWrapperData.entitlementName = objEntitlement.Product__r.Name; 
        objWrapperData.entitlementId = objEntitlement.ID;
        objWrapperData.StartDate = objEntitlement.StartDate;
        objWrapperData.EndDate = objEntitlement.EndDate;
        objWrapperData.SrprodRepCategory = objEntitlement.product__r.Replacement_Category__c;
        if (objEntitlement.EndDate != null) {
            Integer monthDiff = System.today().monthsBetween(objWrapperData.EndDate);
            if (objWrapperData.EndDate.day() > System.today().day()) monthDiff++;
            objWrapperData.RemainingTerm = monthDiff > 0 ? monthDiff : 1;
        }
        objWrapperData.ReplacementTerm = (objWrapperData.RemainingTerm == null || objWrapperData.RemainingTerm <= 12) 
            ? 12 : objWrapperData.RemainingTerm;
        objWrapperData.entitlementOrderNumber = objEntitlement.Order_Number__c;
        objWrapperData.SrprodLicSubCategoryVal = objEntitlement.product__r.License_Sub_Category__c;
        objWrapperData.oldProductEdition = objEntitlement.product__r.Edition__c;
        objWrapperData.serviceContractName = objEntitlement.ServiceContract.Name;
        objWrapperData.serviceContractNumber = objEntitlement.ServiceContract.ContractNumber;
        objWrapperData.serviceContractId = objEntitlement.ServiceContractId;
        objWrapperData.productId = objEntitlement.product__c;
        objWrapperData.srSuppType = objEntitlement.product__r.Support_Type__c;
	    objWrapperData.srPaymentType = objEntitlement.product__r.Product_Payment_Option__c;
        objWrapperData.srProdType = objEntitlement.product__r.Product_Type__c; //FY25SR-2316
        objWrapperData.srRenewedProduct = objEntitlement.product__r.SBQQ__RenewalProduct__c;
        objWrapperData.srCustomRenewedProduct = objEntitlement.product__r.Custom_Renewal_Product__c;
        objWrapperData.rootId = objEntitlement.SBQQSC__AssetRootId__c;
        
        //FY25SR-2388 start  
            if(objEntitlement.product__r.Product_Level__c == 'Support' || (objEntitlement.Product__r.ProductCode.startsWith('RA-') && 
               objEntitlement.Product__r.SBQQ__SubscriptionPricing__c!=null && 
               //FY26WL-435 updated product type warranty to RRW
               (objEntitlement.product__r.Approval_Category__c == 'PSS - CX'  || objEntitlement.product__r.Product_Type__c == ReplacementConstants.PRODUCT_TYPE_RRW )))
            {
               objWrapperData.disableSKU = true;
            }
        //FY25SR-2388 end
        //FY25SR-2232
        if(objEntitlement.product__r.Product_Level__c == NULL){
            objWrapperData.v1Product = true; 
        }else{
            objWrapperData.v1Product = false; 
        }
        //FY25SR-2232
        //FY25SR-1557 START
        if((objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Quantity__c != NULL 
          || objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_OEM__c != NULL 
          || objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Models_Gen__c != NULL 
          || objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Drive_Size__c != NULL) 
          && (objEntitlement.Product__r.Replacement_Category__c == ReplacementConstants.ENTERPRISE_DATA_PROTECTION_TPH 
          || objEntitlement.Product__r.Replacement_Category__c == ReplacementConstants.ENTERPRISE_DATA_PROTECTION_SCALE)){
                objWrapperData.tphOEM = objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_OEM__c;
                objWrapperData.tphModels = objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Models_Gen__c;
                objWrapperData.tphDriveSize = objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Drive_Size__c;
                objWrapperData.tphQuantity = objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Quantity__c;
                objWrapperData.tphTypeEntitlement = true;
           }else{
                objWrapperData.tphTypeEntitlement = false;
           }
        //FY25SR-1557 END
        objWrapperData.tphHWPurchasedFrom = 
            objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c;
        objWrapperData.tphWhoWillDoImaging = 
            objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c;
        objWrapperData.oldSKUwrapBundleVal = 
            objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c;
        objWrapperData.oldSKUwrapBundleBackVal = 
            objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c;
        objWrapperData.oldSKUwrapProductType = 
            objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c;
        objWrapperData.oldSKUwrapTierVal = objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c;
        // objWrapperData.quantity = String.isNotBlank(objEntitlement.ContractLineItem.TPH_Quantity__c) 
        //         ? Integer.valueOf(objEntitlement.ContractLineItem.TPH_Quantity__c)
        //         : objEntitlement.Quantity__c;
        objWrapperData.quantity = objEntitlement.Quantity__c;        
        objWrapperData.selectedquantity = objWrapperData.quantity;
        objWrapperData.skuProdCodeType = objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c;
        objWrapperData.selecteddisposition = '';
        objWrapperData.rowSelected = false;
        objWrapperData.showAdd = false;
        objWrapperData.errors = '';
        objWrapperData.showSelectCheckBox = true;
        objWrapperData.partialReplacement = false;
        //objWrapperData.srSuppType = objEntitlement.ContractLineItem.Support_Type__c;
        objWrapperData.renLine = false;
        objWrapperData.renewalEndDate = null;
        objWrapperData.originalQuoteLineIdForEnt = objEntitlement.ContractLineItem.SBQQSC__OriginalQuoteLine__c;
        //To create Disposition Reasons - auto and manual
        objWrapperData.autoDisposition = autoDispositionValues;
        objWrapperData.manualDisposition = manualDispositionValues;

        /**For Renewal Quotes, Replacement Terms and Remaining Term has to be 12 */
        if (qType == ReplacementConstants.QUOTE_TYPE_RENEWAL) {
            objWrapperData.ReplacementTerm = 12;
            objWrapperData.RemainingTerm = 12;
        }

        //FY25SR-1592 Added below attribute
        objWrapperData.srcLicModel = objEntitlement.ContractLineItem.Licensing_Model__c;

        objWrapperData.doNotConsolidateEnt = false;//FY25SR-1124
        objWrapperData.textToShow = '';//FY25SR-1580
        objWrapperData.misMatchQTY = false;//FY25SR-2071

        /**To evaluate Assets to be shown per entitlement selection. 
         * This considers assets present on the Entitlements + Scale Entitlements*/
        if (!String.isBlank(objEntitlement.AssetId) && !String.isBlank(objEntitlement.Id)) {
            Boolean isSCAsset = mapEntitlemmemntNameToScaleEntitlements.containsKey(objEntitlement.Id) 
                              &&  mapEntitlemmemntNameToScaleEntitlements.get(objEntitlement.Id).size() > 0;
            ReplacementRefreshWrapperData.pickList objpickListAll = ReplacementRefreshWrapperData.createpicKlistValues(
                ReplacementConstants.FULL_SELECTION, 
                ReplacementConstants.FULL_SELECTION,
                objEntitlement.Id,
                objEntitlement.Name,
                0,
                false,
                false,
                false,
                true
            );
            assetsAvailable.add(objpickListAll);
            setassetsAvailable.put(ReplacementConstants.FULL_SELECTION, assetsAvailable);
            String asstTB = String.valueOf(objEntitlement.Asset.Product_Usable_Capacity__c);
            asstTB = asstTB.replace('.00', ' TB)');
            if(!isSCAsset) {
                ReplacementRefreshWrapperData.pickList objpickList = ReplacementRefreshWrapperData.createpicKlistValues(
                    String.valueOf(objEntitlement.Asset.ID),
                    objEntitlement.Asset.Name + ' (' + objEntitlement.Asset.Product2.Name + ') (' + asstTB,
                    String.valueOf(objEntitlement.Id),
                    objEntitlement.Name,
                    double.valueOf(objEntitlement.Asset.Product_Usable_Capacity__c),
                    false,
                    false,
                    false,
                    true
                );
                assetsAvailable.add(objpickList);
                setassetsAvailable.put(objEntitlement.Asset.ID, assetsAvailable);
            }
        }
        if (!mapEntitlemmemntNameToScaleEntitlements.isEmpty() 
            && mapEntitlemmemntNameToScaleEntitlements.containskey(objEntitlement.Id)) {
            if (String.isBlank(objEntitlement.AssetId) && !String.isBlank(objEntitlement.Id)) {
                ReplacementRefreshWrapperData.pickList objpickListAll = ReplacementRefreshWrapperData.createpicKlistValues(
                    ReplacementConstants.FULL_SELECTION,
                    ReplacementConstants.FULL_SELECTION,
                    String.valueOf(objEntitlement.Id),
                    objEntitlement.Name,
                    0,
                    false,
                    false,
                    false,
                    true
                );
                assetsAvailable.add(objpickListAll);
                setassetsAvailable.put(ReplacementConstants.FULL_SELECTION, assetsAvailable);
            }
            for (Scale_Entitlement__c objScale : mapEntitlemmemntNameToScaleEntitlements.get(objEntitlement.Id)) {
                if (String.isNotBlank(objScale.Entitlement__c)) {
                    String asstTB = String.valueOf(objScale.Asset__r.Product_Usable_Capacity__c);
                    asstTB = asstTB.replace('.00', ' TB)');
                    ReplacementRefreshWrapperData.pickList objpickListobjScale = 
                        ReplacementRefreshWrapperData.createpicKlistValues(
                            String.valueOf(objScale.Asset__c),
                            objScale.Asset__r.Name + ' (' + objScale.Asset__r.Product2.Name + ') (' + asstTB,
                            String.valueOf(objScale.Entitlement__c),
                            objScale.Entitlement__r.Name,
                            Double.valueOf(objScale.Asset__r.Product_Usable_Capacity__c),
                            false,
                            false,
                            false,
                            true
                            );
                
                    if (!setassetsAvailable.containsKey(objScale.Asset__c)) {
                        assetsAvailable.add(objpickListobjScale);
                        setassetsAvailable.put(objScale.Asset__c, assetsAvailable);
                    }
                }
            }
        }
        objWrapperData.assetsAvailable = new List<ReplacementRefreshWrapperData.pickList>(assetsAvailable);
        return objWrapperData;
    }
    /***********************************************************************************************************
    * Method Name          : createWrapForInactiveUG
    * Date Created/Modified: 06/02/2025
    * Author               : Sumedha
    * @description         : Creates Inactive Entitlements for Active Entitlements values for Full and List of Assets 
    * @param               lstInactiveEnts
    * @param               wrapData
    * @param               mapEntvsSCENT
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void createWrapForInactiveUG (Map<Id, List<Entitlement>> lstInactiveEnts
        , ReplacementRefreshWrapperData.WrapperData wrapData, 
        Map<String, List<Scale_Entitlement__c>> mapEntvsSCENT) {
        List<ReplacementRefreshWrapperData.WrapperData> lstWrap = new List<ReplacementRefreshWrapperData.WrapperData>();
        List<Entitlement> lstEnts = lstInactiveEnts.containsKey(wrapData.entitlementId) 
            ? lstInactiveEnts.get(wrapData.entitlementId) : new List<Entitlement> ();
        for (Entitlement inactiveEnt : lstInactiveEnts.containsKey(wrapData.entitlementId) 
            ? lstInactiveEnts.get(wrapData.entitlementId) : new List<Entitlement> ()) {
            //FY25SR-1207 Starts
            if (inactiveEnt != null) {
                ReplacementRefreshWrapperData.WrapperData wrappData = formCommonWrapper(inactiveEnt, mapEntvsSCENT);
                lstWrap.add(wrappData);
                Integer monthDiff = System.today().monthsBetween(wrappData.EndDate);
                if (wrappData.EndDate.day() > System.today().day()) monthDiff++;
                if (wrappData.EndDate != null) {
                    wrapData.RemainingTerm = monthDiff > 0 ? monthDiff : 1;
                }
                wrapData.ReplacementTerm = wrapData.RemainingTerm;
                //FY25SR-2395 - starts
                wrapData.ReplacementTerm = (wrapData.RemainingTerm == null || wrapData.RemainingTerm <= 12) 
                ? 12 : wrapData.RemainingTerm;
                //FY25SR-2395 - end
                wrappData.showSelectCheckBox = false;
                wrappData.baseProdIds = (wrappData.baseProdIds == '' || wrappData.baseProdIds == null) 
                    ? String.valueOf(wrapData.entitlementId) 
                    : wrapData.entitlementId + ',' + String.valueOf(wrapData.entitlementId);//FY25SR-1207
                wrapData.wrapInactiveEnt = lstWrap;
                entAlreadyProcessed.add(inactiveEnt.Id);
            }
        }  
    }
    /***********************************************************************************************************
    * Method Name          : customIndexing
    * Date Created/Modified: 19/02/2025
    * Author               : Sumedha
    * @description         : To provide indices for the Wrappers. 
    * @param                lstFinalEntsWrap
    * @param                qType
    * @param                entIdvsCustInd
    * @param                skipCustomIndex
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void customIndexing (List<ReplacementRefreshWrapperData.WrapperData> lstFinalEntsWrap
        , String qType, Map<String, String> entIdvsCustInd, List<String> skipCustomIndex) {
        Integer entCount = 0;
        String text = 'Associated with Licenses labeled with Indices - ' + '\n';//FY25SR-1580
        /**
         * Iterate over list of main wrapper. 
         * If wrapBaseLicense, wrapUpgradeEnt is present, then entCount = entCount + 1
         * If wrapHWSupportLines is present, then entCount remains as is, index = index + 1
         */
        Set<Integer> setCustomIndex = new Set<Integer>();
        if(!skipCustomIndex.isEmpty()){
            for(String st : skipCustomIndex){
                setCustomIndex.add(Integer.ValueOf(st));
            }
        }
        if (!lstFinalEntsWrap.isEmpty()) {
            for (ReplacementRefreshWrapperData.WrapperData mainWrap : lstFinalEntsWrap) {
                entCount = entCount + 1;
                if(!setCustomIndex.isEmpty()){
                    while (setCustomIndex.contains(entCount)) {
                            entCount++;
                    }
                }
                Integer index = 1;
                if (mainWrap.mapAssetEntitlements != null && !mainWrap.mapAssetEntitlements.futureValues.isEmpty()) {
                    mainWrap.customIndex = '' + entCount + '.' + index + '.0';
                }
                if (mainWrap.wrapBaseLicense != null && !mainWrap.wrapBaseLicense.isEmpty()) {
                    for (ReplacementRefreshWrapperData.WrapperData baseLicWrap : mainWrap.wrapBaseLicense) {
                        baseLicWrap.customIndex = '' + entCount + '.' + index + '.0';
                        entIdvsCustInd.put(baseLicWrap.entitlementId, baseLicWrap.customIndex);//FY25SR-1580
                    }
                }
                if (mainWrap.wrapHWSupportLines != null && !mainWrap.wrapHWSupportLines.isEmpty()) {
                    for (ReplacementRefreshWrapperData.WrapperData hwSuppWrap : mainWrap.wrapHWSupportLines) {
                        index = index + 1;
                        hwSuppWrap.customIndex = '' + entCount + '.' + index + '.0';
                    }
                }
                if (mainWrap.wrapUpgradeEnt != null && !mainWrap.wrapUpgradeEnt.isEmpty()) {
                    for (ReplacementRefreshWrapperData.WrapperData ugWrap : mainWrap.wrapUpgradeEnt) {
                        ugWrap.customIndex = '' + entCount + '.' + index + '.0';
                    }
                }
                if (mainWrap.wrapInactiveEnt != null && !mainWrap.wrapInactiveEnt.isEmpty() 
                    && (mainWrap.mapAssetEntitlements == null || mainWrap.mapAssetEntitlements.futureValues.isEmpty())) {
                    for (ReplacementRefreshWrapperData.WrapperData inactWrap : mainWrap.wrapInactiveEnt) {
                        inactWrap.customIndex = '' + entCount + '.' + index + '.0';
                    }
                }
                 //FY25SR-2395 - starts
                if((mainWrap.wrapBaseLicense == null || mainWrap.wrapBaseLicense.isEmpty())
                && (mainWrap.mapAssetEntitlements == null || mainWrap.mapAssetEntitlements.futureValues.isEmpty())
                && (mainWrap.wrapInactiveEnt != null && !mainWrap.wrapInactiveEnt.isEmpty())) {
                    for(ReplacementRefreshWrapperData.WrapperData inactWrap : mainWrap.wrapInactiveEnt) {
                        inactWrap.showSelectCheckBox = true;
                    }
                    mainWrap.wrapBaseLicense = mainWrap.wrapInactiveEnt ;
                    mainWrap.wrapInactiveEnt = new List<ReplacementRefreshWrapperData.WrapperData>();
                }
                //FY25SR-2395- ends
            }
            //FY25SR-1580 Starts
            if (!entIdvsCustInd.isEmpty()) {
                for (ReplacementRefreshWrapperData.WrapperData mainWrap : lstFinalEntsWrap) {
                    if (mainWrap.wrapUpgradeEnt != null && !mainWrap.wrapUpgradeEnt.isEmpty()) {
                        if (String.isNotBlank(mainWrap.baseProdIds)) {
                            List<String> tempStr = mainWrap.baseProdIds.split(',');
                            if (!tempStr.isEmpty()) {
                                for (String entId : tempStr) {
                                    if (entIdvsCustInd.containsKey(entId)) {
                                        String index = entIdvsCustInd.get(entId);
                                        text = text + index + ', ';
                                    }
                                }
                            }
                        }
                        if (text.length() > 0) {
                            mainWrap.textToShow = text.removeEnd(', ');
                        } else {
                            mainWrap.textToShow = '';
                        }
                    }
                }
            }
            //FY25SR-1580 Ends
        }
    }  
    /***********************************************************************************************************
    * Method Name          : createWrapForStandalone
    * Date Created/Modified: 26/03/2025
    * Author               : Sumedha
    * @description         : Populates Replacement Details field on Quote Lines on Renewal Quotes 
    * @return              : List of Quote Lines to update for Replacement Details field
    * @param               ent
    * @param               mapUGIdsvsEnts
    * @param               lstInactiveEnts
    * @param               mapEntvsSCENT
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static ReplacementRefreshWrapperData.WrapperData createWrapForStandalone (Entitlement ent
        , Map<String, List<Entitlement>> mapUGIdsvsEnts, Map<Id, List<Entitlement>> lstInactiveEnts
        , Map<String, List<Scale_Entitlement__c>> mapEntvsSCENT ) {
        //FY25SR-1207 - added mapAstvsLic
        List<ReplacementRefreshWrapperData.wrapperData> baseLice = new List<ReplacementRefreshWrapperData.wrapperData>();
        ReplacementRefreshWrapperData.WrapperData wpsWrap = new ReplacementRefreshWrapperData.WrapperData();
        ReplacementRefreshWrapperData.wrapperData objWrapperData = new ReplacementRefreshWrapperData.WrapperData();
        wpsWrap.wrapBaseLicense = new List<ReplacementRefreshWrapperData.wrapperData>();
        wpsWrap.wrapHWSupportLines = new List<ReplacementRefreshWrapperData.wrapperData>();
        wpsWrap.wrapInactiveEnt = new List<ReplacementRefreshWrapperData.wrapperData>();
        wpsWrap.wrapUpgradeEnt = new List<ReplacementRefreshWrapperData.wrapperData>();
        wpsWrap.baseProdIds = ''; 
               
        //For AddOns
        if (!mapUGIdsvsEnts.containsKey(ent.Id)) {
            objWrapperData = formCommonWrapper(ent, mapEntvsSCENT);
            //FY25SR-1207 - added mapAstvsLic and Status check
            //Inactive Entitlements for AddOns
            createWrapForInactiveUG (lstInactiveEnts, objWrapperData, mapEntvsSCENT);
            if (!checkEntitlementProcessed(ent.Id) && String.isNotBlank(objWrapperData.entitlementId) 
                && ent.Status != ReplacementConstants.STATUS_INACTIVE) {
                baseLice.add(objWrapperData);
                wpsWrap.wrapBaseLicense = baseLice;
                ReplacementRefreshController.mapOfWrap.put(objWrapperData.entitlementId, wpsWrap);
            }
            entAlreadyProcessed.add(ent.Id);
        }
        return wpsWrap;
    }
    /***********************************************************************************************************
    * Method Name          : populateJSONForReconstruction
    * Date Created/Modified: 04/03/2025
    * Author               : Sumedha
    * @description         : Populates Replacement Details field on Quote Lines on Renewal Quotes - FY25SR-1215
    * @return              : List of Quote Lines to update for Replacement Details field
    * @param               quoteIds
    * @param               mapEnts
    * @param               assetLst
    * @param               mapOfInactiveEnts
    * @param               assetEntMap
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static List<SBQQ__QuoteLine__c> populateJSONForReconstruction (Set<Id> quoteIds
        , Map<Id, Entitlement> mapEnts, Map<String, Asset> assetLst
        , Map<String, String> mapOfInactiveEnts, Map<Id, Map<String, String>> assetEntMap) {
        Map<Id, List<String>> cliVsEntLst = new Map<Id, List<String>>();
        List<SBQQ__QuoteLine__c> qlsToUpdate = new List<SBQQ__QuoteLine__c>();
        Map<Id, List<String>> mapEntvsAstNames = new Map<Id, List<String>> ();
        
        List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();

        if (quoteIds != null && !quoteIds.isEmpty()) {
            lstQuotes = ReplacementQueryController.getQuoteandQLDets (quoteIds);
        }

        //Get CLI List and Ent List
        if (!mapEnts.isEmpty()) {
            cliVsEntLst = getCLIEntLst (mapEnts);
            mapEntvsAstNames = getEntAsstList (assetEntMap);
        }

        //For each of the Renewal Quote which is not approved or In Review, populate Replacement Details field for the first time.
        if (!lstQuotes.isEmpty()) {
            for (SBQQ__Quote__c quoteRec : lstQuotes) {
                if (/*quoteRec.SBQQ__Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL  //incorporate for both renewal, R+E
                    && */quoteRec.SBQQ__Status__c != ReplacementConstants.STATUS_APPROVED 
                    && quoteRec.SBQQ__Status__c != ReplacementConstants.STATUS_IN_REVIEW) {
                        for (SBQQ__QuoteLine__c ql : quoteRec.SBQQ__LineItems__r) {
                            if(ql.Quote_Line_Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL || 
                                    (ql.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && 
                                     ql.Quote_Line_Type__c == ReplacementConstants.QUOTE_TYPE_NEW && 
                                     ql.Special_Program__c ==  ReplacementConstants.CONVERT_VALUE && 
                                     ql.Arroyo_Subscribed_Asset_Name__c != null) //for Renewal and new LODtoSAAS
                                ){
                                   Boolean lodToSaas=false;
                                   if (String.isNotBlank(ql.Arroyo_Subscribed_Asset_Name__c)) {
                                       for (String s : ql.Arroyo_Subscribed_Asset_Name__c.split(',')) {
                                         
                                           if (String.isNotBlank(s) && assetLst!=null && assetLst.containsKey(s.trim()) && assetLst.get(s.trim())!=null){
                                              if(assetLst.get(s.trim()).Licensing_Model__c == ReplacementConstants.PREPETUAL && assetLst.get(s.trim()).Product_Family__c == ReplacementConstants.PRODUCTCODE_R6000)
                                              {
                                                lodToSaas = true;
                                                  break;
                                              }
                                           }
                                       }
                                   }
                                   getReplacementDetails(quoteRec.SBQQ__Type__c,ql, cliVsEntLst, assetEntMap, assetLst, mapEntvsAstNames, mapEnts,lodToSaas);
                                   qlsToUpdate.add(ql);
                               }
                        } 
                }
            }
        }
        return qlsToUpdate;
    }
    /***********************************************************************************************************
    * Method Name          : getReplacementDetails
    * Date Created/Modified: 04/03/2025
    * Author               : Sumedha
    * @description         : Populates Replacement Details field on Quote Lines on Renewal Quotes - FY25SR-1215
    * @param               qType
    * @param               qLine
    * @param               cliVsEntLst
    * @param               assetEntMap
    * @param               asstCap
    * @param               mapEntvsAstNames
    * @param               mapEnts
    * @param               lodToSaas
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void getReplacementDetails (String qType, SBQQ__QuoteLine__c qLine, Map<Id, List<String>> cliVsEntLst
        , Map<Id, Map<String, String>> assetEntMap , Map<String, Asset> asstCap
        , Map<Id, List<String>> mapEntvsAstNames, Map<Id, Entitlement> mapEnts,Boolean lodToSaas) { 
            //To store the JSON per Quote Line
            Map<Id, ReplacementJson> mapOfJSON = new Map<Id, ReplacementJson>();
            ReplacementJson jsonData;
            Boolean lodTOSAASConversion= false;
            Boolean lodToSaasHwSupport = false;
            if(lodToSaas == true && qLine.Quote_Line_Type__c == ReplacementConstants.QUOTE_TYPE_NEW && qLine.Special_Program__c==ReplacementConstants.CONVERT_VALUE && String.isNotBlank(qLine.Arroyo_Subscribed_Asset_Name__c)){
                lodTOSAASConversion =true;
            }
            if(lodToSaas == true && qLine.Arroyo_Subscribed_Asset_Name__c!=null && qLine.Quote_Line_Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL && qLine.Product_Type__c == ReplacementConstants.HW_SUPPORT){
               lodToSaasHwSupport =true; 
          }
            //Already processed Entitlements
            Set<String> alreadySeen = new Set<String>();
            Set<String> setStr = new Set<String>();
            Set<String> lodToSaasAssetSet = new Set<String>();
            if (lodTOSAASConversion || lodToSaasHwSupport) { 
                if (String.isNotBlank(qLine.Arroyo_Subsumed_Old_Contract_Line_Items__c)) {
                    for (String s : qLine.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',')) {
                        if (String.isNotBlank(s)) {
                            setStr.add(s.trim());
                        }
                    }
                }
                if (String.isNotBlank(qLine.Arroyo_Subscribed_Asset_Name__c)) {
                    for (String s : qLine.Arroyo_Subscribed_Asset_Name__c.split(',')) {
                        if (String.isNotBlank(s)) {
                            lodToSaasAssetSet.add(s.trim());
                        }
                    }
                 }
            } else {
                if (String.isNotBlank(qLine.CCLI__c)) {
                    for (String s : qLine.CCLI__c.split(',')) {
                        if (String.isNotBlank(s)) {
                            setStr.add(s.trim());
                        }
                    }
                }
                if (qLine.SBQQSC__RenewedContractLine__c != null) {
                    setStr.add(qLine.SBQQSC__RenewedContractLine__c);
                }
            }
            
          if(!setStr.isEmpty() && !cliVsEntLst.isEmpty()) {
            //Create new JSON for the line. 
              jsonData = new ReplacementJson();
              jsonData.rowValues = new List<ReplacementJson.RowDetail>();
              if(lodTOSAASConversion == true){
                  jsonData.skuSelectedName= qLine.SBQQ__ProductCode__c; 
                  jsonData.skuSelected= qLine.SBQQ__Product__c;
                  jsonData.mode =null; 
              }
              else{
                 jsonData.mode = ReplacementConstants.DISPOSE;  
              }
              if(qType == ReplacementConstants.QUOTE_TYPE_RENEWAL && lodTOSAASConversion == false){
                  jsonData.renLine = true;   
              }
            for (String str : setStr) {
                str = str.trim();
                if (cliVsEntLst.containsKey(str) && !cliVsEntLst.get(str).isEmpty()) {
                     //For each of the Entitlements associated with the CLI will create a new row in the JSON
                    for (String entId : cliVsEntLst.get(str)) {
                        if (lodTOSAASConversion || lodToSaasHwSupport) {
                            boolean presentENT = false;
                            Map<String, String> innerMap = assetEntMap.get(entId);
                            for (String assetName : innerMap.values()) {
                                if (lodToSaasAssetSet.contains(assetName)) {
                                    presentENT = true;
                                    break;
                                }
                            }
                             if (!presentENT) {
                                continue;
                            }
                        }
                        if (!alreadySeen.contains(entId)) {
                            String selectedAsset;
                            Map<String, String> assetList = new Map<String, String>();
                            ReplacementJson.RowDetail row = new ReplacementJson.RowDetail();
                            row.entId = entId;
                            row.selectedTerm = qLine.SBQQ__SubscriptionTerm__c!=null ? Integer.valueOf(qLine.SBQQ__SubscriptionTerm__c) :12 ;
                            row.rowId =  '0.0.0'; 
                            if (!assetEntMap.isEmpty() && assetEntMap.containsKey(entId)) {
                                Map<String, String> innerMap = assetEntMap.get(entId);
                                if (lodTOSAASConversion || lodToSaasHwSupport) {
                                    List<String> assPresent = new List<String>();
                                    Map<String, String> filteredMap = new Map<String, String>();
                                    for (String assetId : innerMap.keySet()) {
                                        String serialNumber = innerMap.get(assetId);
                                         if (lodToSaasAssetSet.contains(serialNumber)){ //Only add matching assetIds
                                            filteredMap.put(assetId, serialNumber);
                                            assPresent.add(assetId); 
                                        }
                                    }
                                    selectedAsset = String.join(assPresent, ',');
                                    assetList.putAll(filteredMap);
                                } else {
                                    selectedAsset = String.join(new List<String>(innerMap.keySet()), ',');
                                    assetList.putAll(innerMap);
                                }
                            }

                            if(jsonData.targetProductType == null && String.isNotBlank(selectedAsset)){
                                    jsonData.targetProductType = ReplacementConstants.HARDWARE;
                                }else{
                                    if(jsonData.targetProductType == null)
                                    {jsonData.targetProductType = ReplacementConstants.SKU_TYPE_NON_HARDWARE;}
                                }
                                row.selectedAsset = selectedAsset;
                                row.selectedAssetList = assetList;
                           if(mapEnts.containsKey(entId) && mapEnts.get(entId).Product__r.ProductCode.contains('NRD')){
                               row.selectedQty =(assetList!=null && !assetList.isEmpty()) ? assetList.size():Integer.valueOf(mapEnts.get(entId).Quantity__c);  
                            }
                            else
                                if ((String.isBlank(qLine.SBQQSC__RenewedContractLine__r.Product_Level__c))
                                    || qLine.Product_Type__c == ReplacementConstants.HW_SUPPORT) {
                                        row.selectedQty = mapEnts.containsKey(entId) 
                                            ? Integer.valueOf(mapEnts.get(entId).Quantity__c) 
                                            : Integer.valueOf(qLine.SBQQ__Quantity__c);
                                    } else {
                                        Decimal qty=0;
                                        if(assetList!=null && !assetList.isEmpty() && qLine.Product_Type__c != ReplacementConstants.HW_SUPPORT){
                                            for(String s: assetList.values()){
                                                qty+=asstCap.containsKey(s)? asstCap.get(s).Product_Usable_Capacity__c:0;
                                            }
                                            row.selectedQty = Integer.valueOf(qty); 
                                        }
                                        else{
                                            row.selectedQty = Integer.valueOf(qLine.SBQQ__Quantity__c);   
                                        }
                                    } 
                            if(lodTOSAASConversion || lodToSaasHwSupport){
                                jsonData.lodToSaas = true;
                            }
                            if(lodTOSAASConversion){
                                row.disposition = ReplacementConstants.CONVERTED;  
                             }
                            else
                                if(qLine.Disposition_Reason__c == ReplacementConstants.DISPOSTION_RENEWING){
                                    row.disposition = ReplacementConstants.DISPOSTION_RENEWING;  
                                }
                            else
                                if(qLine.Disposition_Reason__c == ReplacementConstants.DISPOSE_AT_RISK ){
                                    row.disposition =ReplacementConstants.DISPOSE_AT_RISK ;  
                                    jsonData.renLine = false;
                                }
                            else
                                if(qLine.Disposition_Reason__c == ReplacementConstants.DISPOSE_RENEW_LATER){
                                    row.disposition = ReplacementConstants.DISPOSE_RENEW_LATER;
                                    jsonData.renLine = false;
                                }
                            else{//if disposition reason does not update on QuoteLines.
                                row.disposition = ReplacementConstants.DISPOSTION_RENEWING; 
                            }
                             
                            alreadySeen.add(entId);
                            jsonData.rowValues.add(row);
                            mapOfJSON.put(qLine.Id, jsonData);
                        }
                    }
                }
            }
        }
        //Populate Quote Line with Replacement Details
        ReplacementJSON jsonToPop = mapOfJSON.containsKey(qLine.id) ? mapOfJSON.get(qLine.id) : null;
        if (jsonToPop != null) {
            qLine.Replacement_Details__c = JSON.serialize(jsonToPop);
            qLine.Replacement_Motion__c = ReplacementConstants.UPGRADE_VALUE;
            qLine.SBQQ__OptionLevel__c = qLine.SBQQ__OptionLevel__c == null ? 0 : qLine.SBQQ__OptionLevel__c;
        }
        qLine.Atlassian_Quantity__c = qLine.SBQQSC__RenewedContractLine__c != null 
            && qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__c != null 
            && qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Atlassian_Quantity__c != null 
         ? qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Atlassian_Quantity__c 
         : qLine.Atlassian_Quantity__c;
        qLine.Salesforce_Quantity__c = qLine.SBQQSC__RenewedContractLine__c != null 
            && qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__c != null 
            && qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Salesforce_Quantity__c != null 
          ? qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Salesforce_Quantity__c 
          : qLine.Salesforce_Quantity__c;
        qLine.Rubrik_Hosted_M365_Quantity__c = qLine.SBQQSC__RenewedContractLine__c != null 
            && qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__c != null 
            && qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Rubrik_Hosted_M365_Quantity__c != null 
          ? qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Rubrik_Hosted_M365_Quantity__c 
          : qLine.Rubrik_Hosted_M365_Quantity__c;
        qLine.Dynamics_Quantity__c = qLine.SBQQSC__RenewedContractLine__c != null 
            && qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__c != null 
            && qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Dynamics_Quantity__c != null 
          ? qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Dynamics_Quantity__c 
          : qLine.Dynamics_Quantity__c;
         qLine.Google_Workspace_Quantity__c = qLine.SBQQSC__RenewedContractLine__c != null 
		    && qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__c != null 
			&& qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Google_Workspace_Quantity__c != null 
		  ? qLine.SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Google_Workspace_Quantity__c 
		  : qLine.Google_Workspace_Quantity__c;
		Integer monthsToAdd = Integer.valueOf(qLine.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalTerm__c) != null 
            ? Integer.valueOf(qLine.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalTerm__c) 
            : 12;
        Date startDate = qLine.SBQQSC__RenewedContractLine__r.EndDate != null 
            ? qLine.SBQQSC__RenewedContractLine__r.EndDate.addDays(1) 
            : null;
        qLine.SBQQ__EndDate__c = (qLine.SBQQ__EndDate__c == null && startDate != null) ? startDate.addMonths(monthsToAdd).addDays(-1) : qLine.SBQQ__EndDate__c;
    }
    /***********************************************************************************************************
    * Method Name          : getCLIEntLst
    * Date Created/Modified: 04/03/2025
    * Author               : Sumedha
    * @description         : Get combination of CLIs and List of Entitlements associated to it. - FY25SR-1215
    * @return              : Map of CLI Id and List of Entitlement Ids.
    * @param                 mapEnts
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static Map<Id, List<String>> getCLIEntLst (Map<Id, Entitlement> mapEnts) {
        Map<Id, List<String>> cliVsEntLst = new Map<Id, List<String>>();
        if (!mapEnts.isEmpty()) {
            for (Entitlement ent : mapEnts.values()) {
                if (String.isNotBlank(ent.ContractLineItemId)) {
                    if (cliVsEntLst.containsKey(ent.ContractLineItemId)) {
                        cliVsEntLst.get(ent.ContractLineItemId).add(ent.Id);
                    } else {
                        cliVsEntLst.put(ent.ContractLineItemId, new List<String>{ent.Id});
                    }
                }
            }
        }
        return cliVsEntLst;
    }
    /***********************************************************************************************************
    * Method Name          : getEntAsstList
    * Date Created/Modified: 04/03/2025
    * Author               : Sumedha
    * @description         : Get combination of Entitlement and Asset Ids associated to it. - FY25SR-1215
    * @return              : Map of Entitlements and Asset Ids.
    * @param                 assetEntMap
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static Map<Id, List<String>> getEntAsstList (Map<Id, Map<String, String>> assetEntMap) {
        Map<Id, List<String>> mapEntvsAstNames = new Map<Id, List<String>> ();
        if (!assetEntMap.isEmpty()) {
            for (Id entid : assetEntMap.keySet()) {
                if (assetEntMap.containsKey(entid)) {
                    Map<String, String> str = assetEntMap.get(entid);
                    for (String astName : str.keySet()) {
                        if (mapEntvsAstNames.containsKey(entId)) {
                            mapEntvsAstNames.get(entId).add(astName);
                        } else {
                            mapEntvsAstNames.put(entId, new List<String> {astName});
                        }
                    }
                }
            }
        }
        return mapEntvsAstNames;    
    }

     /***********************************************************************************************************
    * Method Name          : createInactiveWrapForStandalone
    * Date Created/Modified: 04/03/2025
    * Author               : Sumedha
    * @description         : Creates Inactive lines if its not associated with any Linkages.
    * @param                 ent
    * @param                 mapEntvsSCENT
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void createInactiveWrapForStandalone (Entitlement ent, Map<String, List<Scale_Entitlement__c>> mapEntvsSCENT) {
        ReplacementRefreshWrapperData.wrapperData objWrap = new ReplacementRefreshWrapperData.wrapperData();
        objWrap.wrapInactiveEnt = new List<ReplacementRefreshWrapperData.wrapperData>();
        //Create wrap for base license
        List<ReplacementRefreshWrapperData.wrapperData> inactiveLic = new List<ReplacementRefreshWrapperData.wrapperData>();
        ReplacementRefreshWrapperData.wrapperData objWrapperData = formCommonWrapper(ent, mapEntvsSCENT );
        Integer monthDiff = objWrapperData.EndDate != null ? System.today().monthsBetween(objWrapperData.EndDate) : null;
        if (monthDiff != null && objWrapperData.EndDate.day() > System.today().day()) monthDiff++;
        if (monthDiff != null && objWrapperData.EndDate != null) {
            objWrapperData.RemainingTerm = monthDiff > 0 ? monthDiff : 1;
        }
        //FY25SR-2395 - starts
        objWrapperData.ReplacementTerm = (objWrapperData.RemainingTerm == null || objWrapperData.RemainingTerm <= 12) 
            ? 12 : objWrapperData.RemainingTerm;
        //FY25SR-2395 - Ends
        objWrapperData.showSelectCheckBox = false;
        inactiveLic.add(objWrapperData);
        objWrap.wrapInactiveEnt = inactiveLic;
        if ((objWrapperData != null && objWrapperData.entitlementId != null) && !Test.isRunningTest()) {
            ReplacementRefreshController.mapOfWrap.put(objWrapperData.entitlementId, objWrap);
        }
        entAlreadyProcessed.add(ent.Id);
    }
    /***********************************************************************************************************
    * Method Name          : addAdditionalEnts
    * Date Created/Modified: 07/02/2025
    * Author               : Sumedha
    * @description         : 
    @param   mapAllEnts
    @param   renewedEnt
    @param   prevEnt
    @param   lstEnt
    /**********************************************************************************************************/
    public static void addAdditionalEnts (Map<Id, Entitlement> mapAllEnts, Id renewedEnt, Id prevEnt, Set<Entitlement> lstEnt) {
        Entitlement newEntInScope;
        Entitlement entInScope;
        if (mapAllEnts.containsKey(prevEnt) && mapAllEnts.get(prevEnt)!= null) {
            entInScope = mapAllEnts.get(prevEnt);
        }   
        if (mapAllEnts.containsKey(renewedEnt) && mapAllEnts.get(renewedEnt)!= null) {
            newEntInScope = mapAllEnts.get(renewedEnt);
        }
        if (entInScope != null && newEntInScope != null 
            && entInScope.Renewal_Category__c != ReplacementConstants.REFRESHED 
            && newEntInScope.Renewal_Category__c != ReplacementConstants.REFRESHED) {
            //For Upgrade SKUs and Delta SKUs, add the whole bundle if anyone of the SKU is present in the filter
            if (lstEnt.contains(entInScope) && newEntInScope != null) {
                lstEnt.add(newEntInScope);
            }
            //If Upgrade falls in the range, then add all Base Products into the List to process
            if (lstEnt.contains(newEntInScope) && entInScope != null) {
                lstEnt.add(entInScope);
            }
        }
    }

    /***********************************************************************************************************
    * Method Name          : checkEntitlementProcessed
    * Date Created/Modified: 10/07/2025
    * Author               : Paritosh
    * @description         : check if entitlement already processed
    @param  entId
    @return  boolean
    /**********************************************************************************************************/

    public static Boolean checkEntitlementProcessed(Id entId){
        return (entAlreadyProcessed.contains(entId) && !Test.isRunningTest());
    }
    /***********************************************************************************************************
    * Method Name          : getCustomMetadataInstance
    * Date Created/Modified: 06/08/2025
    * Author               : Khushboo
    * @description         : get quoteType using Custom Metadata
    @param  record
    @return  objectData
    /**********************************************************************************************************/
    public static Replacement_Field_Mapping__mdt getCustomMetadataInstance(String record){
       Replacement_Field_Mapping__mdt objectData= 
            Replacement_Field_Mapping__mdt.getInstance(record);
        return objectData;
    }
}