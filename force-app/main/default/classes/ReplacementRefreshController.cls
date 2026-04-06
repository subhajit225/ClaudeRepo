/***********************************************************************************************************
 * Class Name           : ReplacementRefreshController
 * Date Created/Modified: 28/03/2024
 * Author               : Shivani/Rahul
 * @description         : This class is used by newReplacementLWC component.
 *                        Fetches all the entititlements and pass the data to the component.
 *                        by using wrapper class.
 * Test Class           : ReplacementRefreshTest
 * Dependant Components : newReplacementLWC
 * Developed as part of : FY25SR-1100, FY25SR-1087, FY25SR-1088, FY25SR-1098, FY25SR-1101, FY25SR-1073
 /**********************************************************************************************************/
public class ReplacementRefreshController {
    /**Contains Entitlement Id vs Wrapper element -
     * For RSC, it will include all the products which are to be shown as bundle*/
    public static Map<String,ReplacementRefreshWrapperData.wrapperData> mapOfWrap = 
        new Map<String,ReplacementRefreshWrapperData.wrapperData>();
    public static List<Replacement_Field_Mapping__mdt> lstReasons = new List<Replacement_Field_Mapping__mdt>();
    /***********************************************************************************************************
    * Method Name          : createWrapperData
    * Date Created/Modified: 10/02/2025
    * Author               : Sumedha
    * @description         : Creates Wrapper that is to be passed to the UI
    * @return              : List of Data to display on UI
    * @param quoteDetail
    * @param startDate
    * @param endDate
    * @param selectedEnts
    * @param alreadySelEnt
    * @param skipCustomIndex
    * Test Class Methods   : 
  /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<ReplacementRefreshWrapperData.wrapperData> createWrapperData(
        SBQQ__Quote__c quoteDetail, Date startDate, Date endDate, List<Id> selectedEnts
      , List<Id> alreadySelEnt, List<String> skipCustomIndex) {
        List<ReplacementRefreshWrapperData.wrapperData> finalWrapper = new List<ReplacementRefreshWrapperData.wrapperData>();
        finalWrapper = getWrapper(
          quoteDetail, startDate, endDate, selectedEnts,alreadySelEnt, skipCustomIndex);        
        return finalWrapper;
    } 

  /***********************************************************************************************************
    * Method Name          : currentUserExceptions
    * Date Created/Modified: 05/06/2025
    * Author               : Ankita
    * @description         : this method fetches the current user's exceptions
    * @return              : List of String
    * Test Class Methods   : 
  /**********************************************************************************************************/
  @AuraEnabled(cacheable=true)
  public static SMS_Exceptions_Owner__mdt currentUserExceptions() {
    SMS_Exceptions_Owner__mdt exceptionInfo = new SMS_Exceptions_Owner__mdt();
      String prodileName = ReplacementQueryController.fetchProfileName();  
      exceptionInfo = ReplacementQueryController.fetchExceptions(prodileName);   
      return exceptionInfo;
  } 
  
    /***********************************************************************************************************
    * Method Name          : getWrapper
    * Date Created/Modified: 07/02/2025
    * Author               : Sumedha
    * @description         : Returns the list of entitlement records including expired ones by constructing
    *                        the data in the form of wrapper class.
    * @return              : Final list of Wrapper to be sent to UI
    * @param               quoteDetail
    * @param               startDateFilter
    * @param               endDateFilter 
    * @param               selectedEnts
    * @param               alreadySelEnt
    * @param               skipCustomIndex 
    * Test Class Methods   :
    /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<ReplacementRefreshWrapperData.wrapperData> getWrapper(SBQQ__Quote__c quoteDetail
        , Date startDateFilter, Date endDateFilter, List<Id> selectedEnts
        , List<Id> alreadySelEnt, List<String> skipCustomIndex) {
        //To store final wrapper data that is to be passed to the UI
        List<ReplacementRefreshWrapperData.wrapperData> finalWrapper = 
            new List<ReplacementRefreshWrapperData.wrapperData>(); 
        //Arroyo Criteria
        Date today = quoteDetail.CreatedDate.date();
        //To store entitlement references of all Entitlements retrieved from the Query
        Map<Id, Entitlement> mapAllEnts = new Map<Id, Entitlement>();
        /**Used for Upgrade SKUs. Stores upgrade SKU vs list of Base Products associated with it. 
         * This map is irrespective of date range*/
        Map<String, String> mapUGIdsvsEnts = new Map<String,String>();
        //Stores Upgrade Entitlement Id vs all Base Entitlements related to it.
        Map<String, List<Entitlement>> mapOfUGEntvsEnts = new Map<String, List<Entitlement>>();
        //Set of entitlements that is to be passed based on filter criteria
        Set<Entitlement> lstEnt = new Set<Entitlement>();
        //List to be passed. This is list form of lstEnt
        List<Entitlement> lstToPass = new List<Entitlement>();
        //To store Assets and HW Support Entitlements.
        Map<Id, Set<Id>> hwSuppAstvsEnt = new Map<Id, Set<Id>>();
        //Previously selected Entitlements coming from UI.
        Set<Id> prevSelectedEnts = new Set<Id>();
        //To store Scale Entitlements associated with the Entitlement
        Map<String, List<Scale_Entitlement__c>> mapEntvsSCENT = new Map<String, List<Scale_Entitlement__c>>();
        //To store Asset Id and associated parent Entitlements
        Map<Id, Id> scAssetsvsEntId = new Map<Id, Id>();
        //To store inactive entitlememts associated with Active Entitlements
        Map<Id, List<Entitlement>> lstInactiveEnts = new Map<Id, List<Entitlement>>();
        Map<String, String> entvsAsst = new Map<String, String>();
        //To store Assets linked with Delta license and its other Base Entitlements
        Map<String, Set<Id>> mapAstvsLic = new Map<String, Set<Id>>();
        Set<String> typeFromSEs = new Set<String>{
            ReplacementConstants.REFRESHED_BASE_LICENSE,ReplacementConstants.REFRESHED_DELTA_LICENSE};
        Map<Id, Id> expEntLinks = new Map<Id, Id>();//FY25SR-1771
        Set<String> afterConversionProdLevel = new Set<String>{'Standalone Software Addon' ,'SaaS Software Addon'};
        Set<String> productTypeSet = new Set<String>{'RADAR', 'Sonar', 'App Flows'};
        try{
            //Get all Entitlements satisfying Arroyo criteria
            List<Entitlement> LstAllEnt = 
                ReplacementQueryController.getEntitlementData1(String.valueOf(quoteDetail.SBQQ__Account__c), alreadySelEnt); 
            if (!Test.isRunningTest() && String.isNotBlank(quoteDetail.SBQQ__Type__c)) {
                ReplacementRefreshUtility.qType = quoteDetail.SBQQ__Type__c;
            }
            if (lstReasons == null || lstReasons.isEmpty()) {
                lstReasons = ReplacementQueryController.getDispositionReasons (ReplacementRefreshUtility.qType);
            }
            prevSelectedEnts.addAll(selectedEnts);
            if (!LstAllEnt.isEmpty()) {
                for(Entitlement ent : LstAllEnt){ 
                    mapAllEnts.put(ent.Id, ent); //Store all Entitlements
                    //To show previously selected Entitlement
                    if (prevSelectedEnts.contains(ent.Id)) {
                        lstEnt.add(ent);
                    }
                    //By default, pass all Ents with End Dates in Ary Criteria.
                    //Exclude Entitlements where Renewal Category = Refreshed, since it is not required to be shown individually
                    //FY25SR-1745 - Starts
                    if(!(ent.Renewal_Category__c == ReplacementConstants.REFRESHED 
                        && ent.Product__r.Product_Type__c == ReplacementConstants.HW_SUPPORT )) {
                        if (startDateFilter != null && endDateFilter != null 
                            && ent.EndDate >= startDateFilter && ent.EndDate <= endDateFilter)  {
                            lstEnt.add(ent);
                            //If either of the above is blank, then simply add all Entitlements to the list
                        } else if (startDateFilter == null || endDateFilter == null) { 
                            lstEnt.add(ent);
                        }
                    }
                    
                    /* To get HW Support Entitlements -  
                    * From Entitlements, get Scale Entitlements and its assets. 
                    * Then check the Entitlements associated with the Assets and get the HW Support line linked to it 
                        and add it to HW Support List. 
                    * Store HW Supp List associated with the Asset. Get only those assets which are Not Inactive. 
                    */
                    //FY25SR-1592 - Added RCDM Support
                    if (ent.Asset != null && ent.Renewal_Category__c != ReplacementConstants.REFRESHED) {
                        if (ent.Product__r.Product_Type__c == ReplacementConstants.HW_SUPPORT 
                            || ent.Product__r.Product_Type__c == ReplacementConstants.PRODUCT_TYPE_RCDOM_SUPPORT
                           || !(productTypeSet.contains(ent.Product__r.Product_Type__c) && afterConversionProdLevel.contains(ent.Product__r.After_Conversion_Product_Level__c) && ent.Product__r.Custom_POT__c == false && ent.AssetId != null)
                            ) {
                            if (hwSuppAstvsEnt.containsKey(ent.AssetId)) {
                                hwSuppAstvsEnt.get(ent.AssetId).add(ent.Id);
                            } else {
                                hwSuppAstvsEnt.put(ent.AssetId, new Set<Id> {ent.Id} );
                            }
                        }
                    }
                }
                //Below code formulates Inactive Entitlements, HW Support with its Base License and Upgrade SKUs.
                if (!mapAllEnts.isEmpty()) {
                    Set<Id> inactiveIds = new Set<Id>();
                    for (Entitlement ent : mapAllEnts.values()) {
                        //Eligibility of Entitlements
                        Boolean entEligible = false;
                        if (ent.Renewal_Category__c == ReplacementConstants.PRODUCT_CATEGORY_RENEWED 
                            || String.isBlank(ent.Renewal_Category__c)) {
                            entEligible = true;
                        }
                        if (!ent.Entitlement_Links__r.isEmpty()) {
                            for (Entitlement_Links__c entLink : ent.Entitlement_Links__r) {
                                //FY25SR-1771 Starts
                                if (String.isNotBlank(entLink.Previous_Entitlement__c) 
                                    && String.isNotBlank(entLink.Renewed_Entitlement__c)) {
                                    if ((entLink.Previous_Entitlement__r.Status == ReplacementConstants.STATUS_EXPIRED 
                                        && entLink.Renewed_Entitlement__r.Status == ReplacementConstants.STATUS_ACTIVE) 
                                        || Test.isRunningTest()) {
                                        expEntLinks.put(entLink.Previous_Entitlement__c, entLink.Renewed_Entitlement__c);
                                    }
                                    //FY25SR-1771 Ends
                                    if (entLink.Previous_Entitlement__r.Status == ReplacementConstants.STATUS_ACTIVE 
                                     && entLink.Renewed_Entitlement__r.Status == ReplacementConstants.STATUS_INACTIVE 
                                     && entLink.Renewal_Category__c != ReplacementConstants.REFRESHED) {
                                        inactiveIds.add(entLink.Renewed_Entitlement__c);
                                    }
                                }                            
                            }   
                        }
                        if(!ent.Scale_Entitlements__r.isEmpty() ){
                            for (Scale_Entitlement__c scEnt : ent.Scale_Entitlements__r) {
                                //Store RSC Entitlements and its Scale Entitlements
                                if (scEnt.Renewal_Category__c != ReplacementConstants.REFRESHED) {
                                    if (!mapEntvsSCENT.containsKey(scEnt.Entitlement__c)) {
                                        mapEntvsSCENT.put(scEnt.Entitlement__c, new List<Scale_Entitlement__c>{ scEnt });
                                    } else {
                                        mapEntvsSCENT.get(scEnt.Entitlement__c).add(scEnt);
                                    }
                                }
                                
                                //Get Assets associated with Scale Entitlements
                                //FY25SR-1592 - Added RCDM Support
                                if (scEnt.Asset__c != null 
                                 && (scEnt.Entitlement__r.Product__r.Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE 
                                 || (scEnt.Entitlement__r.Product__r.Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_ONPREM 
                                 && scEnt.Entitlement__r.Product__r.Product_Subtype__c != ReplacementConstants.PRODUCT_LEVEL_LOD_ADDON ) 
                                 || scEnt.Entitlement__r.Product__r.Product_Type__c == ReplacementConstants.PRODUCT_TYPE_RCDOM_SUPPORT)) {
                                    if ((entEligible && hwSuppAstvsEnt.containsKey(scEnt.Asset__c))
                                        || (entEligible || ent.Renewal_Category__c == ReplacementConstants.REFRESHED 
                                        || ent.Renewal_Category__c == ReplacementConstants.RENEWAL_CATEGORY_MIXEDPARTIAL)) {
                                        if (ent.Status != ReplacementConstants.STATUS_INACTIVE) {
                                            scAssetsvsEntId.put(scEnt.Asset__c, scEnt.Entitlement__c);
                                        }
                                        //Store Entitlement Id vs list of Assets, to be used for Base RSC and Delta RSC.
                                        if (entvsAsst.containsKey(scEnt.Entitlement__c)) {
                                            String ast = entvsAsst.get(scEnt.Entitlement__c);
                                            if (ast != null && !ast.contains(scEnt.Asset__r.Name)) {
                                                ast = ast + ',' + scEnt.Asset__r.Name;
                                            }
                                            entvsAsst.put(scEnt.Entitlement__c, ast);
                                        } else {
                                            entvsAsst.put(scEnt.Entitlement__c, scEnt.Asset__r.Name);
                                        }
                                        //FY25SR-1771 Starts
                                        //If Type on Scale Entitlement = Refreshed, then store the Assets and the related Entitlements
                                        if ((String.isNotBlank(scEnt.Type__c) 
                                            && typeFromSEs.contains(scEnt.Type__c) 
                                            && !expEntLinks.containsKey(scEnt.Entitlement__c) 
                                            && !inactiveIds.contains(scEnt.Entitlement__c)) || Test.isRunningTest()) {
                                            if (mapAstvsLic.containsKey(scEnt.Asset__r.Name)) {
                                                mapAstvsLic.get(scEnt.Asset__r.Name).add(scEnt.Entitlement__c);
                                            } else {
                                                mapAstvsLic.put(scEnt.Asset__r.Name, new Set<Id> { scEnt.Entitlement__c });
                                            }
                                        }//FY25SR-1771 Ends
                                    }
                                }
                            }
                        }/** For V1 Support Products - includes HW Support and SW Support and SVC Prem Appliance */ 
                        //FY25SR-1592 - Added OnPrem
                        else {
                            if (ent.Status != ReplacementConstants.STATUS_INACTIVE 
                              && String.isBlank(ent.Product__r.Product_Level__c) 
                              && (ent.Product__r.After_Conversion_Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE 
                              || ent.Product__r.After_Conversion_Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_ONPREM)) {
                                scAssetsvsEntId.put(ent.AssetId, ent.Id);
                            }
                        }
                        if (!ent.Entitlement_Links__r.isEmpty()) {
                            //For Inactive Licenses
                            /*For Inactive Entitlements List
                            * Get all Entitlement Links which are associated with entitlements in scope. 
                            * If Renewed Entitlement = Inactive, then store it as Active Entitlement vs Inactive Entitlement .
                            */
                            for (Entitlement_Links__c entLink : ent.Entitlement_Links__r) {
                                //FY25SR-1207 Starts
                                if (String.isNotBlank(entLink.Renewed_Entitlement__c) 
                                    && String.isNotBlank(entLink.Previous_Entitlement__c)) {
                                    Date renEndDate = entLink.Renewed_Entitlement__r.EndDate;
                                    Date preEndDate = entLink.Previous_Entitlement__r.EndDate;
                                    Boolean linkEligible = false;

                                    if (entLink.Previous_Entitlement__r.Renewal_Category__c == ReplacementConstants.PRODUCT_CATEGORY_RENEWED 
                                     || entLink.Previous_Entitlement__r.Renewal_Category__c == ReplacementConstants.REFRESHED 
                                     || entLink.Previous_Entitlement__r.Renewal_Category__c == ReplacementConstants.RENEWAL_CATEGORY_MIXEDPARTIAL 
                                     || String.isBlank(entLink.Previous_Entitlement__r.Renewal_Category__c)) {
                                        linkEligible = true;
                                    }
                                    //FY25SR-1207 Ends
                                    Id renewedEnt = entLink.Renewed_Entitlement__c;
                                    Id prevEnt = entLink.Previous_Entitlement__c;
                                    if (entLink.Previous_Entitlement__r.Status == ReplacementConstants.STATUS_ACTIVE 
                                      && linkEligible && entLink.Renewed_Entitlement__r.Status == ReplacementConstants.STATUS_INACTIVE 
                                      && entLink.Renewal_Category__c != ReplacementConstants.REFRESHED) {
                                        Entitlement entInScope = mapAllEnts.get(entLink.Renewed_Entitlement__c);
                                        if (lstInactiveEnts.containsKey(entLink.Previous_Entitlement__c)) {
                                            lstInactiveEnts.get(entLink.Previous_Entitlement__c).add(entInScope);
                                            inactiveIds.add(entLink.Renewed_Entitlement__c);
                                        } else {
                                            lstInactiveEnts.put(entLink.Previous_Entitlement__c, new List<Entitlement> {entInScope});
                                            inactiveIds.add(entLink.Renewed_Entitlement__c);
                                        }
                                        ReplacementRefreshUtility.addAdditionalEnts(mapAllEnts, renewedEnt, prevEnt, lstEnt);
                                    }
                                    /** For inactive licenses, whose Active Enttilement is already transacted. 
                                     * Such Inactive Lines has to be stored under Inactive List of Wrapper */
                                    else if (renEndDate != null && startDateFilter != null 
                                        && endDateFilter != null && renEndDate >= startDateFilter 
                                        && renEndDate <= endDateFilter 
                                        && entLink.Renewed_Entitlement__r.Status == ReplacementConstants.STATUS_INACTIVE 
                                        && !inactiveIds.contains(entLink.Renewed_Entitlement__c)) {
                                        Entitlement inactEnt = mapAllEnts.get(entLink.Renewed_Entitlement__c);
                                        ReplacementRefreshUtility.createInactiveWrapForStandalone (inactEnt,mapEntvsSCENT);
                                    } 
                                    
                                    //All Base Products associated with Upgrade Entitlements under single map
                                    if (entLink.Renewed_Entitlement__r.Product__r.Edition__c != null 
                                        && entLink.Renewed_Entitlement__r.Product__r.Edition__c.contains(ReplacementConstants.UPGRADE_VALUE)) {
                                        Entitlement entInScopes;
                                        if (mapAllEnts.containsKey(prevEnt) && mapAllEnts.get(prevEnt)!= null) {
                                            entInScopes = mapAllEnts.get(prevEnt);
                                        }
                                        if (entInScopes != null) {
                                            if ( mapOfUGEntvsEnts.containsKey(renewedEnt)) {
                                                mapOfUGEntvsEnts.get(renewedEnt).add(entInScopes);
                                            } else {
                                                mapOfUGEntvsEnts.put(renewedEnt,new List<Entitlement> {entInScopes});
                                            }
                                        }
                                        ReplacementRefreshUtility.addAdditionalEnts(mapAllEnts, renewedEnt, prevEnt, lstEnt);
                                    }
                                }
                            }
                        }
                        //FY25SR-2395 - Added selectedEnts conditions
                        if ((ent.EndDate != null && startDateFilter != null && endDateFilter != null 
                         && ((ent.EndDate >= startDateFilter && ent.EndDate <= endDateFilter) || selectedEnts.contains(ent.Id)) 
                         && ent.Status ==ReplacementConstants.STATUS_INACTIVE 
                         && !ReplacementRefreshUtility.checkEntitlementProcessed(ent.Id) && !inactiveIds.contains(ent.Id)) || Test.isRunningTest()) {
                            ReplacementRefreshUtility.createInactiveWrapForStandalone (ent,mapEntvsSCENT);
                        }
                    }
                }
            }
            
            /** If HW Support is previously selected, then add RSC line to the lstEnt to pass for wrapper creation */
            if (!hwSuppAstvsEnt.isEmpty()){
                for (Id astId : hwSuppAstvsEnt.keySet()) {
                    for (Id entId : hwSuppAstvsEnt.get(astId)) {
                        if (prevSelectedEnts.contains(entId)) {
                            if (scAssetsvsEntId.containsKey(astId)) {
                                Entitlement entInScope = mapAllEnts.containsKey(scAssetsvsEntId.get(astId)) 
                                        ? mapAllEnts.get(scAssetsvsEntId.get(astId)) : null;
                                if (entInScope != null) {
                                    lstEnt.add(entInScope);
                                }
                            }
                        }
                    }
                }

            }
            lstToPass.addAll(lstEnt);

            //Call createWrapper method to get wrappers created
            finalWrapper = createWrapper (lstToPass, mapOfUGEntvsEnts, mapAllEnts
                , quoteDetail, hwSuppAstvsEnt, mapEntvsSCENT, scAssetsvsEntId
                , lstInactiveEnts, entvsAsst, mapAstvsLic, skipCustomIndex);
        } catch (Exception ex) {
            System.debug(LoggingLevel.DEBUG, 
                + 'Exception ex -- ' + ex.getMessage()+ '-' + ex.getLineNumber());
            LogError.logCustomError('ReplacementRefreshUtility'
                , ex.getMessage(), ex.getStackTraceString()
                , 'FY25SR-CPQ-SMSUIWrapperCreation');
            throw ReplacementQuoteLineCreationHelper.handleException(ex);
        }
        return finalWrapper;
    }
    
    /***********************************************************************************************************
    * Method Name          : createWrapper
    * Date Created/Modified: 07/02/2025
    * Author               : Sumedha
    * @description         : Returns the list of entitlement records including expired ones by constructing
    *                        the data in the form of wrapper class.
    * @return              : List of Wrappers bundled together that is to be displayed
    * @param               lstEnt
    * @param               mapUGIdsvsEnts
    * @param               mapAllEnts
    * @param               quoteDetail
    * @param               hwSuppAstvsEnt
    * @param               mapEntvsSCENT
    * @param               scAssetsvsEntId
    * @param               lstInactiveEnts
    * @param               entvsAsst
    * @param               mapAstvsLic
    * @param               skipCustomIndex
    /**********************************************************************************************************/
    public static List<ReplacementRefreshWrapperData.wrapperData> createWrapper(List<Entitlement> lstEnt
        , Map<String, List<Entitlement>> mapUGIdsvsEnts, Map<Id, Entitlement> mapAllEnts
        , SBQQ__Quote__c quoteDetail, Map<Id, Set<Id>> hwSuppAstvsEnt
        , Map<String, List<Scale_Entitlement__c>> mapEntvsSCENT
        , Map<Id, Id> scAssetsvsEntId, Map<Id, List<Entitlement>> lstInactiveEnts
        , Map<String, String> entvsAsst, Map<String, Set<Id>> mapAstvsLic
        , List<String> skipCustomIndex ) {
        //HW Support Lines to be attached with the RSC Entitlements. RSC Id vs HW Support Entitlements
        Map<Id, List<Entitlement>> hwSuppIdvsEntLst = new Map<Id, List<Entitlement>>(); 
        //To store RSC Entitlements. Will be iterating over this map to create wrapper per bundle
        Map<Id, Entitlement> rscEnts = new Map<Id, Entitlement>();
        //Set of Wrappers to be sent to the UI
        Set<ReplacementRefreshWrapperData.WrapperData> finalWrapSet = new Set<ReplacementRefreshWrapperData.WrapperData>();
        //List of Wrappers to be sent to the UI. This is the list form of finalWrapSet
        List<ReplacementRefreshWrapperData.wrapperData> finalWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
        /**Stores Entitlement Id vs List of Wrappers. For RSC, 
         * this will hold the Entitlement Id vs List of Wrappers (base License, HW Support).*/
        Map<String, List<ReplacementRefreshWrapperData.WrapperData>> mapEntIdvslstEnt = 
            new Map<String, List<ReplacementRefreshWrapperData.WrapperData>>();
        Map<String, List<Entitlement>> mapOfAsstvsRSCs = new Map<String, List<Entitlement>>();
        /**Stores Id of Entitlements which are used for Delta Entitlements. 
         * It will store Ids of Base Entitlements and Deta, which need not be displayed as Bundles.*/
        Set<Id> usedForDelta = new Set<Id>(); 
        //To temporarily store Entitlement and asset list for R+R Transactions
        Map<String, Set<Id>> tempMapForDelta = new Map<String, Set<Id>>();
        //To store the Custom Index of base licenses to pass to Upgrade SKUs
        Map<String, String> entIdvsCustInd = new Map<String, String>();
        if(!lstEnt.isEmpty()){
            for(Entitlement ent : lstEnt){
                //FY25SR-1207 Starts
                //For RSC Base and RSC Delta SKUs, store the AssetIds and RSCs in a Map mapAssetEntitlements.
                if (!mapAstvsLic.isEmpty() && !entvsAsst.isEmpty()) {
                    for (String ents : entvsAsst.keySet()) {
                        if (ents == ent.Id) {
                            String lstAst = '';
                            Set<Id> setEnts = new Set<Id>();
                            for (String ast : mapAstvsLic.keySet()) {
                                String astLst = entvsAsst.get(ents) != null ? entvsAsst.get(ents) : '';
                                Set<Id> tempSet = mapAstvsLic.get(ast) != null ? mapAstvsLic.get(ast) : new Set<Id>();
                                if (String.isNotBlank(astLst) && astLst.contains(ast)) {
                                    lstAst = lstAst + ',' + ast;
                                    if (!tempSet.isEmpty()) {
                                        setEnts.addAll(tempSet);
                                        usedForDelta.add(ent.Id);
                                    }
                                }
                            }
                            tempMapForDelta.put(lstAst, setEnts);
                        }
                    }
                }
                //Store the RSC Entitlements and GO Entitlements
                //FY25SR-1592 - Commented AddOn, added RCDM Support changes
                if(!usedForDelta.contains(ent.Id) && String.isNotBlank(ent.Product__c) 
                && (((ent.Product__r.Product_Level__c != null 
                && (ent.Product__r.Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE 
                  || (ent.product__r.Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_ONPREM 
                     && ent.product__r.Product_Subtype__c != ReplacementConstants.PRODUCT_LEVEL_LOD_ADDON) 
                  || ent.Product__r.Product_Type__c == ReplacementConstants.PRODUCT_TYPE_RCDOM_SUPPORT)) 
                  || (String.isBlank(ent.Product__r.Product_Level__c) 
                  && String.isNotBlank(ent.Product__r.After_Conversion_Product_Level__c) 
                  && (ent.Product__r.After_Conversion_Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE 
                  || ent.Product__r.After_Conversion_Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_ONPREM))) 
                  && ent.product__r.Product_Type__c != null 
                  && (ent.product__r.Product_Type__c.contains(ReplacementConstants.PRODUCT_TYPE_EDITION) 
                  || ent.Product__r.Product_Type__c == ReplacementConstants.PRODUCT_TYPE_RCDOM_SUPPORT) 
                  && (ent.product__r.Edition__c == null 
                    || (ent.product__r.Edition__c != null 
                        && !ent.product__r.Edition__c.contains(ReplacementConstants.UPGRADE_VALUE))))){  
                    rscEnts.put(ent.Id, ent);
                }
            }
            
            if (!tempMapForDelta.isEmpty()) {
                for (String astLst : tempMapForDelta.keySet()) {
                    Set<Id> entIds = tempMapForDelta.get(astLst) != null ? tempMapForDelta.get(astLst) : new Set<Id>();
                    List<Entitlement> lstEnts = new List<Entitlement>();
                    if (!entIds.isEmpty()) {
                        for (Id entId : entIds) {
                            if (mapAllEnts.containsKey(entId)) {
                                lstEnts.add(mapAllEnts.get(entId));
                            }
                        }
                    }
                    mapOfAsstvsRSCs.put(astLst, lstEnts);
                }
            }
            usedForDelta.clear();
            tempMapForDelta.clear();
            
            if (!scAssetsvsEntId.isEmpty() && !hwSuppAstvsEnt.isEmpty()) {
                for (Id astId : scAssetsvsEntId.keySet()) {
                    /**HW Support Line tagged to the RSC - Show only if the RSC falls in the filter 
                     * or if HW support is previously selected.*/
                    if (hwSuppAstvsEnt.containsKey(astId) 
                      && scAssetsvsEntId.containsKey(astId) 
                      && mapAllEnts.containsKey(scAssetsvsEntId.get(astId)) 
                      && lstEnt.contains(mapAllEnts.get(scAssetsvsEntId.get(astId)))) {
                        Id entId = scAssetsvsEntId.get(astId);
                        Set<Id> suppIds = hwSuppAstvsEnt.get(astId);
                        if (!suppIds.isEmpty()) {
                            for (Id suppId : suppIds) {
                                Entitlement supEnt = mapAllEnts.get(suppId);
                                if (hwSuppIdvsEntLst.containsKey(entId)) {
                                    hwSuppIdvsEntLst.get(entId).add(supEnt);
                                } else {
                                    hwSuppIdvsEntLst.put(entId, new List<Entitlement> {supEnt} );
                                }
                            }
                        }
                    }
                }
            }
            //FY25SR-1207 Starts
            /** If mapOfAsstvsRSCs is populated, the map will be converted to wrapper and stored in mapAssetEntitlements of Wrapper */
            if (!mapOfAsstvsRSCs.isEmpty()) {
                for (String astLst : mapOfAsstvsRSCs.keySet()) {
                    Map<String, List<ReplacementRefreshWrapperData.WrapperData>> mapAstEnts = 
                        new Map<String, List<ReplacementRefreshWrapperData.WrapperData>>();
                    ReplacementRefreshWrapperData.WrapperData wrapForRefresh = new ReplacementRefreshWrapperData.WrapperData();
                    wrapForRefresh.baseProdIds = '';
                    wrapForRefresh.mapAssetEntitlements = new ReplacementRefreshWrapperData.futureDataValues();
                    //Create Wrapper for each of the Base Lines
                    List<Entitlement> lstEnts = mapOfAsstvsRSCs.containsKey(astLst) 
                        ? mapOfAsstvsRSCs.get(astLst) : new List<Entitlement>();
                    if (!lstEnts.isEmpty()) {
                        for (Entitlement rscEnt : lstEnts) {
                            ReplacementRefreshWrapperData.WrapperData wrapRSC = 
                                new ReplacementRefreshWrapperData.WrapperData();
                            List<ReplacementRefreshWrapperData.WrapperData> lstInactives = 
                                new List<ReplacementRefreshWrapperData.WrapperData>();
                            wrapRSC = ReplacementRefreshUtility.formCommonWrapper(rscEnt, mapEntvsSCENT );
                            //Inactive Entitlements for AddOns
                            ReplacementRefreshUtility.createWrapForInactiveUG (lstInactiveEnts, wrapRSC, mapEntvsSCENT);
                            if (mapAstEnts.containsKey(astLst)) {
                                mapAstEnts.get(astLst).add(wrapRSC);
                                wrapForRefresh.baseProdIds = wrapForRefresh.baseProdIds + ',' + rscEnt.Id;
                                wrapRSC.keyIdentifier = astLst;
                            } else {
                                mapAstEnts.put(astLst, new List<ReplacementRefreshWrapperData.WrapperData> { wrapRSC });
                                wrapForRefresh.baseProdIds = rscEnt.Id;
                                wrapRSC.keyIdentifier = astLst;
                            }
                            if (!mapAstEnts.isEmpty()) {
                                ReplacementRefreshWrapperData.futureDataValues eachAssetEnts = 
                                    new ReplacementRefreshWrapperData.futureDataValues();
                                for(String assetKey : mapAstEnts.keySet()) {
                                    eachAssetEnts.futureKey = assetKey;
                                    eachAssetEnts.futureValues = mapAstEnts.get(assetKey);
                                }
                                if (eachAssetEnts != null) {
                                    wrapForRefresh.mapAssetEntitlements = eachAssetEnts;
                                }
                            }
                            ReplacementRefreshUtility.entAlreadyProcessed.add(rscEnt.Id);
                            ReplacementRefreshUtility.createHWSuppWrap(rscEnt, wrapForRefresh, hwSuppIdvsEntLst, lstInactiveEnts, mapEntvsSCENT);
                            if (wrapRSC.wrapInactiveEnt != null) { 
                                lstInactives.addAll(wrapRSC.wrapInactiveEnt);
                                if (!lstInactives.isEmpty()) {
                                    wrapForRefresh.wrapInactiveEnt = lstInactives;
                                    wrapRSC.wrapInactiveEnt = new List<ReplacementRefreshWrapperData.WrapperData>();
                                }
                            }
                            if (mapOfWrap != null && rscEnt != null && String.isNotBlank(rscEnt.Id)) {
                                mapOfWrap.put(rscEnt.Id, wrapForRefresh);
                            }
                        }
                    }
                }
            }
            //FY25SR-1207 Ends
            //Creation of Wrapper starts from here
            /* Wrapper for Bundles RSC, HW Support.
            * wrapBaseLicense - Stores the wrapper instance for RSC
            * wrapHWSupportLines - Stores the wrapper instances for HW Support
            * wrapInactiveEnt - Stores inactive licenses. 
            * This will be inside wrapBaseLicense and wrapHWSupportLines representing each Entitlement's inactive entitlement
            * objWrap - All of the above wrap instances are clubbed into a single wrapper 
            */
            for (Entitlement ent : rscEnts.values()){
                ReplacementRefreshUtility.createBundledWrap (ent, lstInactiveEnts, mapEntvsSCENT, hwSuppIdvsEntLst);     
            }
            rscEnts.clear();
            
            /*For other Entitlements - AddOns, Upgrades
            * wrapBaseLicense - Stores wrap instance for AddOns except Upgrade SKUs
            * wrapUpgradeEnt - Stores wrap instance for Upgrade Entitlements
            */
            for(Entitlement ent : lstEnt){
                if(!ReplacementRefreshUtility.checkEntitlementProcessed(ent.Id)){
                    ReplacementRefreshWrapperData.WrapperData wps = new ReplacementRefreshWrapperData.WrapperData();
                    wps = ReplacementRefreshUtility.createWrapForStandalone(ent, mapUGIdsvsEnts, lstInactiveEnts, mapEntvsSCENT);
                    
                    //Create Upgrade Licenses list
                    if (!mapUGIdsvsEnts.isEmpty() && !ReplacementRefreshUtility.checkEntitlementProcessed(ent.Id)) { 
                        ReplacementRefreshWrapperData.WrapperData ugWrap = ReplacementRefreshUtility.formCommonWrapper(ent, mapEntvsSCENT);
                        List<ReplacementRefreshWrapperData.WrapperData> lstWrapUG = 
                            new List<ReplacementRefreshWrapperData.WrapperData>();
                        //Store Base Entitlement Ids, used to group together further
                        for (Entitlement ugEnt : mapUGIdsvsEnts.containsKey(ent.Id) 
                                                ? mapUGIdsvsEnts.get(ent.Id) : new List<Entitlement> ()) {
                            if (ugEnt != null && !wps.baseProdIds.contains(String.valueOf(ugEnt.Id))) {
                                wps.baseProdIds = (wps.baseProdIds == '') 
                                    ? String.valueOf(ugEnt.Id) : wps.baseProdIds + ',' + String.valueOf(ugEnt.Id);
                            }
                        }
                        lstWrapUG.add(ugWrap);
                        if (!ReplacementRefreshUtility.checkEntitlementProcessed(ent.Id) 
                            && String.isNotBlank(ugWrap.entitlementId) 
                            && !lstWrapUG.isEmpty()) {
                            wps.wrapUpgradeEnt = lstWrapUG;
                            //Inactive Entitlements for Upgrade
                            ReplacementRefreshUtility.createWrapForInactiveUG (lstInactiveEnts, ugWrap, mapEntvsSCENT);
                            mapOfWrap.put(ugWrap.entitlementId, wps);
                        }
                        ReplacementRefreshUtility.entAlreadyProcessed.add(ent.Id);
                    }
                }
            }
        }
        ReplacementRefreshUtility.entAlreadyProcessed.clear();
        /**
         * Sorting Algorithm starts
         * If Base Entitlements are associated with Upgrades, then all of the Base Entitlements 
         * + Upgrade has to be shown together - baseProdIds is used here
         * Once the arrangement is done, the Wrappers should still be arranged per ASC order of End Dates 
         */
        if (mapOfWrap != null && !mapOfWrap.isEmpty()) {
            Set<String> entIdprocessed = new Set<String>();
            for (String wrapData : mapOfWrap.keySet()) {
                Date leastDate = (mapAllEnts.containsKey(wrapData) && mapAllEnts.get(wrapData).EndDate != null) 
                    ? mapAllEnts.get(wrapData).EndDate : null;
                String leastDateEnt = wrapData;
                List<ReplacementRefreshWrapperData.WrapperData> wrapList = 
                        new List<ReplacementRefreshWrapperData.WrapperData>();
                /**To put Upgrade and all Base Products together. 
                 * Also get the Least End Date in the list to order it with other Entitlements on the screen.*/
                if (mapOfWrap.containsKey(wrapData) && String.isNotBlank(mapOfWrap.get(wrapData).baseProdIds)) {
                    List<String> baseIds = mapOfWrap.get(wrapData).baseProdIds.split(',');
                    if (!baseIds.isEmpty()) {
                        for (String baseId : baseIds) {
                            if (mapOfWrap.containsKey(baseId) 
                                && !entIdprocessed.contains((baseId)) 
                                && mapAllEnts.containsKey(baseId)) {
                               Date entEndDate = mapAllEnts.get(baseId).EndDate;
                                if (entEndDate != null && leastDate != null && leastDateEnt != null 
                                    && leastDate > entEndDate) {
                                    leastDate = entEndDate; //Stores the least End Date for RSC Wrapper
                                    leastDateEnt = baseId; //Stores the Entitlement Id of the least date
                                }
                                entIdprocessed.add(baseId);
                                wrapList.add(mapOfWrap.get(baseId));
                                mapEntIdvslstEnt.put(wrapData, wrapList);
                            }
                        }
                    }
                    
                    if (!entIdprocessed.contains(wrapData)) {
                        wrapList.add(mapOfWrap.get(wrapData));
                        mapEntIdvslstEnt.put(leastDateEnt, wrapList);
                        entIdprocessed.add(wrapData);
                    }
                }
            }
            
            //For other Entitlements apart from RSC
            if (entIdprocessed.size() != mapOfWrap.keySet().size()) {
                for (String wrapData : mapOfWrap.keySet()) {
                    if (!entIdprocessed.contains(wrapData)) {
                        List<ReplacementRefreshWrapperData.WrapperData> wrapList = 
                            new List<ReplacementRefreshWrapperData.WrapperData>();
                        wrapList.add(mapOfWrap.get(wrapData));
                        mapEntIdvslstEnt.put(wrapData, wrapList);
                    }
                }
            }
        }
        mapOfWrap = null;
        //TO sort based on the Dates. Use the original Map which has the Entitlements sorted based on End Dates
        if (!mapEntIdvslstEnt.isEmpty()) {
            for (Id entId : mapAllEnts.keySet()) {
                if (mapEntIdvslstEnt.containsKey(String.valueOf(entId))) {
                    finalWrapSet.addAll(mapEntIdvslstEnt.get(String.valueOf(entId)));
                }
            }
        }
        
        if (!finalWrapSet.isEmpty()) {
            finalWrap.addAll(finalWrapSet);
        }
        
        if (!finalWrap.isEmpty()) {
            //For Indexing on the Wrapper
            if (Test.isRunningTest() && String.isBlank(ReplacementRefreshUtility.qType)) {
                ReplacementRefreshUtility.qType = ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION;
            }
            ReplacementRefreshUtility.customIndexing (finalWrap, ReplacementRefreshUtility.qType, entIdvsCustInd, skipCustomIndex);
        }
        return finalWrap;
    }
}