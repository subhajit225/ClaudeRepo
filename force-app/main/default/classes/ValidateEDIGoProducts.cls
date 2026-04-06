/*******************************************************************************************************************
 * @description       : Validate POitem with QLI for Go Products
 * @author            : 
 * @last modified on  : 06-05-2025
 * @last modified by  : Shrutika
 * */
public with sharing class ValidateEDIGoProducts {
    ValidationResults results;
    public ValidationsParams params;
    static Decimal threshold { get; set; }
    final String ERROR_CODE_TERM_MISMATCH = 'PO-12';
    final String ERROR_CODE_PRICE_MISMATCH = 'PO-10';
    final String ERROR_CODE_QUANTITY_MISMATCH = 'PO-11';
    final String ERROR_CODE_MATCHING_QLI_ABSENT = 'PO-101';
    final String ERROR_CODE_MATCHING_POLI_ABSENT = 'PO-24';
    final String ERROR_TYPE = 'External';
    Map<string,String> poitemIDByDifference = new  Map<string,String>();
    /**
     * @description isFinalRound
     */
    Public Boolean isFinalRound { get; set; }
    Set<String> setStrTokenForFinalRound { get; set; }
    Set<String> setStrTokenForFinalRoundWoPriceRestriction { get; set; } 
    Set<String> setStrTokenForFinalRoundWoQliRestriction { get; set; }
    Boolean needFinalRound { get; set; }
    Set<Id> setIdQliMatched { get; set; } 
    Map<Id, Set<Id>> mapQliIdSetIdRequiredBy { get; set; }
    Map<Id, WQli> mapWQli { get; set; }
    Map<String, List<WQLI>> mapQPTokenLstWQli { get; set; }
    Public static  Map<String, List<Decimal>> mapProductCodeWithPrice = new Map<String, List<Decimal>>(); 
    /**
   * @description HW PoitemvsUsableCapacity of HW
   */
    Map<Id, Decimal> mapIdHwPoliUsableCapacity { get; set; }
    Map<Id, Set<Id>> mapIdStagePoSetPoliAvailable { get; set; }
    Map<Id, Id> mapIdPoliIdStagePo { get; set; }
    Map<Id, Id> mapQuoteIdIdStagePoResponsible { get; set; }
    
    /**
   * @description declare ValidationParam
   */
    public class ValidationsParams {
         /**
        * @description threshold = 100
        **/
        public Decimal threshold { get; set; }
        /**
        * @description Failed Poitem which not matched
        **/
        public Set<Id> setIdFailedPoli { get; set; }
        /**
        * @description Quote Id of Go Product
        **/
        public Set<Id> setIdGoProductQuote { get; set; }
        /**
        * @description Stage Po Ids for Go Products
        **/
        public Set<Id> setIdGoProductStagePo { get; set; }
        /**
        * @description Map of QLi 
        **/
        public Map<Id, SBQQ__QuoteLine__c> mapQli { get; set; }
        /**
        * @description Map of All stage PO
        **/
        public Map<Id, PO_Stage__c> mapAllStagePo { get; set; }
        /**
        * @description map of Quote details
        **/
        public Map<Id, SBQQ__Quote__c> mapAllQuotes { get; set; }
        /**
        * @description Matching PO item
        **/
        public Map<Id, PO_Item_Stage__c> mapPoliMatched { get; set; }
        /**
        * @description Map of wpoli Object
        **/
        public Map<String, Map<Decimal, List<WPoli>>> mmPoli { get; set; }
        /**
        * @description Validation code
        **/
        public Map<String, POValidation_ErrorCode__c> validationCodes { get; set; }
    }
    /**
    * @description EDIGOProductValidationException
    **/
    public class EDIGOProductValidationException extends Exception {
    }

    /**...
     * @description isTolerablePriceDiff.
     * flags true, if  diff. between two prices is under threshold (less than or equals)
     * flags false, if  diff. between two prices is over threshold
     * @param  d1 Price1.
     * @param  d2 Price2
     * @return   Boolean flag  diff between two prices is under threshold.
     */
    private static Boolean isTolerablePriceDiff(Decimal d1, Decimal d2) {
        return ((d1 - d2).abs() <= threshold);
    }
    /**
    * @description Constructor
    **/
    public ValidateEDIGoProducts() {
        this.params = new ValidationsParams();
        this.results = new ValidationResults();
    }

    private static Boolean isHwProduct(Product2 objProd) {
        try {
            return (objProd.Product_Level__c.equals('Hardware') &&
            (objProd.Product_Type__c.equals('Hardware') || objProd.Product_Type__c.equals('Add-On Node')));
        } catch (Exception e) {
            return false;
        }
    }
    /**
     * @description isHWPoli Checks is POLI is HW
     * @param  objPoli objPoli POLI to Check
     * @return         true if HW POLI, false if not HW POLI
     */
    private Boolean isHWPoli(PO_Item_Stage__c objPoli) {
        return isHwProduct(objPoli.Product__r);
    }
    final static List<String> SAAS_PRODUCT_LEVEL_OPTIONS = new List<String>{ 'Hybrid Software', 'LOD Software','OnPrem' };
    private static Boolean isSaaSProduct(Product2 objProd) {
        try {
            return SAAS_PRODUCT_LEVEL_OPTIONS.contains(objProd.Product_Level__c);
        } catch (Exception e) {
            return false;
        }
    }
    final static List<String> ADDON_PRODUCT_LEVEL_OPTIONS = new List<String>{
        'SaaS Software Addon',
        'Standalone Software Addon',
        'Addon'
    };
    private static Boolean isAddonProduct(Product2 objProd) {
        try {
            return ADDON_PRODUCT_LEVEL_OPTIONS.contains(objProd.Product_Level__c);
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * @description validate Collected POLIs
     * @return   return Returns instance of ValidationResults, containing Matched, Unmatched POLIs, Stage PO & Many More
     */
    public ValidationResults validate() {
        try {
            System.debug(LoggingLevel.FINE,'Into ValidateEDIGoProducts.validate()');
            ValidateEDIGoProducts.threshold = params.threshold;
            collectAvailablePoli();
            collateQliRequiredByDependencies();
            collectUsableCapacityForHw();
            calculateQuantitySaaS();
            sortingCollectionsHere();
            matchPoliWithQli();
            checkForOrphanPolis();
            System.debug(LoggingLevel.FINE, 'End ValidateEDIGoProducts.validate()');
        } catch (Exception e) {
            System.debug(LoggingLevel.FINE, 'Exception Validating Go Products: ' + e + '\nAt ' + e.getStackTraceString());
        }
        return results;
    }

    /**
     * @description collectAvailablePoli
     * for all StagePO containing Go Products,
     * creates a map to map StagePO Id to Set<Id> of child POLIs
     */
    private void collectAvailablePoli() {
        mapIdStagePoSetPoliAvailable = new Map<Id, Set<Id>>();
        mapIdPoliIdStagePo = new Map<Id, Id>();
        mapQuoteIdIdStagePoResponsible = new Map<Id, Id>();
        for (Id stagePoId : params.setIdGoProductStagePo) {
            Set<Id> setIdPoliAvailable = new Set<Id>();
            PO_Stage__c objStagePo = params.mapAllStagePo.get(stagePoId);
            for (PO_Item_Stage__c objPoli : objStagePo.PO_Item_Stage__r) {
                setIdPoliAvailable.add(objPoli.Id);
                mapIdPoliIdStagePo.put(objPoli.Id, stagePoId);
                mapQuoteIdIdStagePoResponsible.put(objStagePo.Quote__c, stagePoId);
            }
            mapIdStagePoSetPoliAvailable.put(objStagePo.Id, setIdPoliAvailable);
        }
    }

    /**
     * @description collateQliRequiredByDependencies
     * for all QLI,
     *  1. create its dependency map to know
     *      which QLIs are required by which QLIs.
     *      Will use this later to Get all HW required By SaaS
     *  2.  Add QLi to map for its QP Token Map
     */
    @TestVisible
    private void collateQliRequiredByDependencies() {
        mapWQli = new Map<Id, WQli>();
        mapQliIdSetIdRequiredBy = new Map<Id, Set<Id>>();
        mapQPTokenLstWQli = new Map<String, List<WQLI>>();
        Set<Id> setIdQuoteAdded = new Set<Id>();
        // to populate mapQliIdSetQliIdRequired
        for (Id idStagePo : params.setIdGoProductStagePo) {
            // Id for stage Po containing  GO Products
            if (!params.mapAllStagePo.containsKey(idStagePo)) {
                throw new EDIGOProductValidationException(
                    'Stage PO for Id: ' +
                    idStagePo +
                    ' ' +
                    'Should be in passed parameter for all Stage POs'
                );
            }
            PO_Stage__c objStagePo = params.mapAllStagePo.get(idStagePo);

            if (!params.mapAllQuotes.containsKey(objStagePo.quote__c)) {
                throw new EDIGOProductValidationException(
                    'Quote for Id: ' +
                    objStagePo.quote__c +
                    ' ' +
                    'for Stage PO Id: ' +
                    idStagePo +
                    ' ' +
                    'Should be in passed parameter for all Quotes'
                );
            }
            SBQQ__Quote__c objQuote = params.mapAllQuotes.get(objStagePo.quote__c); // quote for this STage Po
            if (setIdQuoteAdded.contains(objQuote.Id)) {
                continue;
            }
            setIdQuoteAdded.add(objQuote.Id);

            for (SBQQ__QuoteLine__c objQli : objQuote.SBQQ__LineItems__r) {
                if(((objQuote.SBQQ__Type__c == 'Amendment' || objQuote.SBQQ__Type__c=='Renewal+Expansion' || objQli.Special_Program__c == 'Conversion') && objQli.SBQQ__Existing__c)
                   || objQli.SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c
                   || objQli.SBQQ__Product__r.SBQQ__Optional__c
                   || objQli.SBQQ__Optional__c) {continue;}
                WQli objWQli = new WQli(objQli);
                mapWQli.put(objWQli.id, objWQli);
                addWQliToDependency(objWQli);
                addWQliToQPTokenMap(objWQli);
            }
        }
    }

    /**
     * @description addWQliToDependency
     * adds WQLI to a dependency map such that
     * its map all its requiredBy QLI Id to Set<Id> required Qli
     * @param  objWQli objWQli description
     */
    private void addWQliToDependency(WQli objWQli) {
        // creates Dependency map
        if (String.isBlank(objWQli.qli.SBQQ__RequiredBy__c)) {
            return;
        }
        if (!mapQliIdSetIdRequiredBy.containsKey(objWQli.qli.SBQQ__RequiredBy__c)) {
            mapQliIdSetIdRequiredBy.put(objWQli.qli.SBQQ__RequiredBy__c, new Set<Id>());
        }
        mapQliIdSetIdRequiredBy.get(objWQli.qli.SBQQ__RequiredBy__c).add(objWQli.id);
    }

    /**
     * @description addWQliToQPTokenMap
     * adds Wrapped QLI to a Map with QP Token to List<WQLI>
     * @param  objWQli objWQli description
     */
    private void addWQliToQPTokenMap(WQli objWQli) {
        if (!mapQPTokenLstWQli.containsKey(objWQli.qpToken)) {
            mapQPTokenLstWQli.put(objWQli.qpToken, new List<WQLI>());
        }
        mapQPTokenLstWQli.get(objWQli.qpToken).add(objWQli);
    }

    /**
     * @description collectUsableCapacityForHw
     * Collect Usable Capacity for HW POLI, if its matched by previous Class
     * from QLi -> Product -> USable Capacity
     * Create a map of POLI Id -> its usable Capacity
     */
    @TestVisible
    private void collectUsableCapacityForHw() {
        mapIdHwPoliUsableCapacity = new Map<Id, Decimal>();
        for (PO_Item_Stage__c objPoli : params.mapPoliMatched.values()) {
            if (!params.setIdGoProductStagePo.contains(objPoli.Stage_PO__c)) {
                continue;
            }
            if (!isHWPoli(objPoli)) {
                continue;
            }
            mapIdHwPoliUsableCapacity.put(
                objPoli.Id,
                (mapWQli.get(objPoli.Quote_Line__c)).productUsableCapacity
                // (POLI -> Matched QLI ->) Product ->  Usable_Capacity__c
            );
        }
    }

    /**
     * @description calculateQuantitySaaSPerWPoli
     * for a given WPOLI,
     * if its a SaaS, Calculate its Usable Capacity
     * @param  objWPoli SaaS POLI to Calculate Quantity
     */
    @TestVisible
    private void calculateQuantitySaaSPerWPoli(WPoli objWPoli) {
        if (!objWPoli.isSaaS) {
            return;
        }
        Set<Id> setIdAvailablePolis = mapIdStagePoSetPoliAvailable.get(objWPoli.stagePO);
        for (Id idPoli : setIdAvailablePolis) {
            if (!mapIdHwPoliUsableCapacity.keySet().contains(idPoli)) {
                continue;
            }
            PO_Item_Stage__c p = params.mapPoliMatched.get(idPoli);
            objWPoli.addSaaSCapacity(
                mapWQli.get(p.Quote_Line__c), // WQLI of (Poli -> Matched Quoted)
                p.Quantity__c
            );
        }
    }

    /**
     * @description calculateQuantitySaaS
     * for all WPOLI, Calculate its SaaS Capacity, Available.
     */
    private void calculateQuantitySaaS() {
        for (String strQPToken : params.mmPoli.keySet()) {
            List<WPoli> lstWPoli = new List<WPoli>();
            for (List<WPoli> ls : params.mmPoli.get(strQPToken).values()) {
                lstWPoli.addAll(ls);
            }
            for (WPoli objWPoli : lstWPoli) {
                calculateQuantitySaaSPerWPoli(objWPoli);
            }
        }
        return;
    }

    /**
     * @description sortingCollectionsHere
     * Sorts QLIs & POLIs based on Implemented compareTo Mathod
     */
    private void sortingCollectionsHere() {
        for (String strToken : params.mmPoli.keySet()) {
            for (List<WQli> ls : mapQPTokenLstWQli.values()) {
                ls.sort();
            }
            for (List<WPoli> ls : params.mmPoli.get(strToken).values()) {
                ls.sort();
            }
        }
    }

    /**
     * @description Returns Suitable Validation Message,
     * Messag if found, Otherwise Generic Error Message
     * @param  s Error Code
     * @return   Suitable Error Mesage
     */
    @TestVisible
    private String getPoValidationErrorMsg(String s) {
        return params.validationCodes.get(s) != null
            ? params.validationCodes.get(s).Error_Issue__c
            : System.Label.Generic_Validation_Error_Mgs;
    }
    /**
     * @description createPoError Creates a Stage PO Error & adds it to collection
     * @param  strErrorCode   Error Code for which Error record will be created
     * @param  mapOtherParams contains Map for field Name to  values for which will be populated in Error Records.
     */
    private void createPoError(String strErrorCode, Map<String, Object> mapOtherParams) {
        if (
            mapOtherParams.containsKey('PO_Stage_Item_Id__c') &&
            String.isNotBlank((String) mapOtherParams.get('PO_Stage_Item_Id__c')) &&
            results.setIdPoliErrorGoProduct.contains((Id) mapOtherParams.get('PO_Stage_Item_Id__c'))
        ) {
            return;
        }
        PO_Stage_Errors__c objError = new PO_Stage_Errors__c(
            Name = strErrorCode,
            Error_Code__c = strErrorCode,
            Error_Message__c = getPoValidationErrorMsg(strErrorCode),
            Error_Type__c = ERROR_TYPE
        );
        for (String strPropApiName : mapOtherParams.keySet()) {
            objError.put(strPropApiName, mapOtherParams.get(strPropApiName));
        }
        if(objError.Name == ERROR_CODE_PRICE_MISMATCH && poitemIDByDifference.get((String)mapOtherParams.get('PO_Stage_Item_Id__c'))!= Null){
            objError.Error_Message__c =objError.Error_Message__c+', Difference : '+  poitemIDByDifference.get((String)mapOtherParams.get('PO_Stage_Item_Id__c'));

        }
        results.lstStageError.add(objError);
        if (
            mapOtherParams.containsKey('PO_Stage_Id__c') &&
            String.isNotBlank((String) mapOtherParams.get('PO_Stage_Id__c'))
        ) {
            Id idStagePo = (Id) mapOtherParams.get('PO_Stage_Id__c');
            results.setIdPoliErrorGoProduct = new Set<Id>();
            for (PO_Stage_Errors__c objStagePoError : results.lstStageError) {
                if (String.isBlank(objStagePoError.PO_Stage_Id__c)) {
                    continue;
                }
                if (
                    mapOtherParams.containsKey('PO_Stage_Id__c') &&
                    String.isNotBlank((String) mapOtherParams.get('PO_Stage_Id__c'))
                ) {
                    results.setIdPoliErrorGoProduct.add(objStagePoError.PO_Stage_Item_Id__c);
                }
            }
            results.setIdStagePoFailed.add(idStagePo);
            results.setIdQuoteLineFailed.add((Id) params.mapAllStagePo.get(idStagePo).get('Quote__c'));
        }
    }

    /**
     * @description createSuitablePoError
     * Creates a suitable Error Code, based on Parameters
     * @param  isMatchTerm     Boolean flag, whether or not 'Term' of POLIs is matching with QLI
     * @param  isMatchQuantity Boolean flag, whether or not 'Quantity' of POLIs is matching with QLI
     * @param  isMatchPrice    Boolean flag, whether or not 'Price' of POLIs is matching with QLI
     * @param  mapOtherParams  contains Map for field Name to  values for which will be populated in Error Records.
     * TODO 1: Make it so that it takes only one parameter & handles rest on its own
     */
    private void createSuitablePoError(
        Boolean isMatchTerm,
        Boolean isMatchQuantity,
        Boolean isMatchPrice,
        Map<String, Object> mapOtherParams
    ) {
        String strErrorCode;
        if (!isMatchTerm) {
            strErrorCode = ERROR_CODE_TERM_MISMATCH;
        } else if (!isMatchQuantity) {
            strErrorCode = ERROR_CODE_QUANTITY_MISMATCH;
        } else if (!isMatchPrice) {
            strErrorCode = ERROR_CODE_PRICE_MISMATCH;
        }
        createPoError(strErrorCode, mapOtherParams);
    }

    private void storeForFinalMatching(WQli objWQli) {
        if (setStrTokenForFinalRound == null) {
            setStrTokenForFinalRound = new Set<String>();
        }
        setStrTokenForFinalRound.add(objWQli.qpToken);
    }
    /**
    * @description AbstractLine for Po items for Term and unit Price
    **/
    @TestVisible
     class AbstractLine implements Comparable {
        Integer term { get; set; }
        Integer quantity { get; set; }
        String productCode { get; set; }
        Decimal granualPrice { get; set; }
        Decimal maxTerm { get; set; }
        @TestVisible
        Decimal netPrice {
            get {
                return (unitPrice * quantity);
            }
        }
        @TestVisible
        Decimal unitPrice {
            get {
                return (term * granualPrice);
            }
        }
        /**
        * @description Id
        **/
        Id id { get; set; }
        @TestVisible
        Boolean isEmpty() {
            return (String.isNotBlank(productCode) && (granualPrice != null) && (quantity != null) && (term != null));
        }
        /**
        * @description abstractLine
        **/
        public AbstractLine() {
            this.term = 0;
            this.quantity = 0;
            this.productCode = '';
            this.granualPrice = 0;
            this.maxTerm = 0;
        }
        /**
        * @description AbstractLine for QLI
        * @param objWQli
        * @param maxTerm
        **/
        public AbstractLine(WQli objWQli, Decimal maxTerm) {
            this.id = objWQli.id;
            this.term = objWQli.term.intValue();
            this.quantity = objWQli.quantity.intValue();
            this.productCode = objWQli.productCode;
            this.granualPrice = objWQli.granualPrice;
            this.maxTerm = maxTerm;
        }
        /**
        * @description AbstractLine for Poitem
        * @param objWPoli
        * @param maxTerm
        **/
        public AbstractLine(WPoli objWPoli, Decimal maxTerm) {
            this.id = objWPoli.id;
            this.term = objWPoli.term.intValue();
            this.quantity = objWPoli.quantity.intValue();
            this.productCode = objWPoli.productCode;
            this.granualPrice = objWPoli.granualPrice;
            this.maxTerm = maxTerm;
        }
        /**
        * @description compareable
        * @param x
        * @return boolean
        **/
        public Integer compareTo(Object x) {
            AbstractLine other = (AbstractLine) x;
            if (term == other.term) {
                if (quantity > other.quantity) {
                    return 1;
                } else if (quantity < other.quantity) {
                    return -1;
                }
                return 0;
            }
            if (term > other.term) {
                return -1;
            }
            return 1;
        }
        /**
        * @description createMapStrTQPCodeLstAbsLine
        * @param lstAbsLines
        * @return mapStrTQPCodeLstAbsLine
        **/
        private Map<String, List<AbstractLine>> createMapStrTQPCodeLstAbsLine(List<AbstractLine> lstAbsLines) {
            Map<String, List<AbstractLine>> mapStrTQPCodeLstAbsLine = new Map<String, List<AbstractLine>>();

            for (AbstractLine objAbsLine : lstAbsLines) {
                String strTQPCode =
                    String.ValueOf(objAbsLine.term) +
                    '-' +
                    String.ValueOf(objAbsLine.quantity) + 
                    '-' +
                    String.ValueOf(objAbsLine.granualPrice);
                if (!mapStrTQPCodeLstAbsLine.containsKey(strTQPCode)) {
                    mapStrTQPCodeLstAbsLine.put(strTQPCode, new List<AbstractLine>());
                }
                mapStrTQPCodeLstAbsLine.get(strTQPCode).add(objAbsLine);
            }
            return mapStrTQPCodeLstAbsLine;
        }
        
         /**
        * @description tryQuickComposeFirst
        * @param lstAbsLine
        * @param intMaxTerm
        * @return quickComposeElements
        **/

        public Map<String, Object> tryQuickComposeFirst(List<AbstractLine> lstAbsLine, Decimal intMaxTerm) {
            return quickComposeElements(createMapStrTQPCodeLstAbsLine(lstAbsLine), intMaxTerm);
        }

        /**
        * @description quickComposeElements
        * @param mapStrTermQuantityCodeLstAbsLine
        * @param decMaxTerm
        * @return mapResult
        **/
        public Map<String, Object> quickComposeElements(
            Map<String, List<AbstractLine>> mapStrTermQuantityCodeLstAbsLine,
            Decimal decMaxTerm
        ) {
            Map<String, Object> mapResult = new Map<String, Object>();

            List<AbstractLine> lstComposed = new List<AbstractLine>();
            Set<Id> setIdAbsComposed = new Set<Id>();

            for (String strTQCode : mapStrTermQuantityCodeLstAbsLine.keySet()) {
                Integer intTerm;
                Integer intQuantity;

                List<AbstractLine> lstAbsLine = mapStrTermQuantityCodeLstAbsLine.get(strTQCode);
                if (lstAbsLine.isEmpty()) {
                    continue;
                }
                {
                    List<String> lstStrTQCodeSplitted = strTQCode.split('-');
                    intTerm = Integer.valueOf(lstStrTQCodeSplitted.get(0));
                    intQuantity = Integer.valueOf(lstStrTQCodeSplitted.get(1));
                }
                Integer intLstSize = lstAbsLine.size();
                AbstractLine objAbsComposed = lstAbsLine.remove(0);
                if (intLstSize == 1) {
                    lstComposed.add(objAbsComposed);
                    continue;
                }
                Decimal decTermMult = (Math.ceil(decMaxTerm / objAbsComposed.term));
                Decimal term = Math.min(decTermMult, intLstSize);
                objAbsComposed.term =  (objAbsComposed.term * term).round().intValue();
                objAbsComposed.quantity =  (objAbsComposed.quantity * (intLstSize / term)).round().intValue();
                for(AbstractLine objAbsL :lstAbsLine) {
                    if(objAbsL.id == null) {
                        continue;
                    }
                    setIdAbsComposed.add(objAbsL.id);
                }
                lstComposed.add(objAbsComposed);

           }
            mapResult.put('AbstractLine List', lstComposed); 
            mapResult.put('AbstractLine Id Aggregated', setIdAbsComposed); 
            return mapResult;
        }
        
        /**
        * @description composeAbstractLine
        * @param objLine1
        * @param objLine2
        * @param maxTerm
        * @return booleam
        **/
        public Boolean composeAbstractLine(AbstractLine objLine1, AbstractLine objLine2, Decimal maxTerm) {
            AbstractLine objLineRes = new AbstractLine();
            if (isTermAddable(objLine1, objLine2, maxTerm)) {
                this.maxTerm = objLine1.maxTerm;
                this.productCode = objLine1.productCode;
                this.granualPrice = objLine1.granualPrice;
                this.quantity = objLine1.quantity;
                this.term = objLine1.term + objLine2.term;
                return true;
            }
            if (isQuantityAddable(objLine1, objLine2, maxTerm)) {
                this.maxTerm = objLine1.maxTerm;
                this.productCode = objLine1.productCode;
                this.granualPrice = objLine1.granualPrice;
                this.term = objLine1.term;
                this.quantity = objLine1.quantity + objLine2.quantity;
                return true;
            }
            return false;
        }
        /**
        * @description forceComposeAbstractLine
        * @param objLine1
        * @param objLine2
        * @param maxTerm
        * @return booleam
        **/
        public Boolean forceComposeAbstractLine(AbstractLine objLine1, AbstractLine objLine2, Decimal maxTerm) {
            if (isTermAddable(objLine1, objLine2, maxTerm)) {
                this.maxTerm = objLine1.maxTerm;
                this.productCode = objLine1.productCode;
                this.granualPrice = objLine1.granualPrice;
                this.quantity = objLine1.quantity;
                this.term = objLine1.term + objLine2.term;
                return true;
            }
            if (isQuantityAddable(objLine1, objLine2, maxTerm)) {
                this.maxTerm = objLine1.maxTerm;
                this.productCode = objLine1.productCode;
                this.granualPrice = objLine1.granualPrice;
                this.term = objLine1.term;
                this.quantity = objLine1.quantity + objLine2.quantity;
                return true;
            }
            if (forceTermAddable(objLine1, objLine2, maxTerm)) {
                this.maxTerm = objLine1.maxTerm;
                this.productCode = objLine1.productCode;
                this.granualPrice = objLine1.granualPrice;
                this.quantity = objLine1.quantity;
                this.term = objLine1.term + objLine2.term;
                return true;
            }
            return false;
        }
        /**
        * @description isTermAddable
        * @param objLine1
        * @param objLine2
        * @param maxTerm
        * @return booleam
        **/
        Boolean isTermAddable(AbstractLine objLine1, AbstractLine objLine2, Decimal maxTerm) {
            return ((objLine1.quantity == objLine2.quantity) ? (objLine1.term + objLine2.term <= maxTerm) : false);
        }
        /**
        * @description forceTermAddable
        * @param objLine1
        * @param objLine2
        * @param maxTerm
        * @return booleam
        **/
        Boolean forceTermAddable(AbstractLine objLine1, AbstractLine objLine2, Decimal maxTerm) {
            return (objLine1.term + objLine2.term <= maxTerm);
        }
        /**
        * @description isQuantityAddable
        * @param objLine1
        * @param objLine2
        * @param maxTerm
        * @return booleam
        **/
        Boolean isQuantityAddable(AbstractLine objLine1, AbstractLine objLine2, Decimal maxTerm) {
            return (objLine1.term == objLine2.term);
        }
    }
    /**
    * @description Aggreate stage Po items for Term and unit Price
    **/
    @TestVisible
     class AggregatedLine {
        Decimal id { get; set; }
        Decimal term { get; set; }
        Decimal maxTerm { get; set; }
        Decimal quantity { get; set; }
        String productCode { get; set; }
        Decimal qliGranualPrice { get; set; }
        Decimal granualPrice { get; set; }
        /**
        * @description setIdAggregated
        **/
        public Set<Id> setIdAggregated { get; set; }
        Set<Id> setIdNotAggregated { get; set; }
        Boolean isEmpty { get; set; }
        Boolean isIndividualAdded  = false;
        Decimal netPrice {
            get {
                return (unitPrice * quantity);
            }
        }
        Decimal unitPrice {
            get {
                return (term * granualPrice);
            }
        }
        List<AbstractLine> lstAbsLine = new List<AbstractLine>();
        @TestVisible
        List<AbstractLine> lstOriginalAbsLine {get;set;} // POLI ONLY

        /**
        * @description AggregatedLine
        * @param lstWPoli
        * @param qliGranualPrice
        * @param maxTerm
        **/
        public AggregatedLine(List<WPoli> lstWPoli, Decimal qliGranualPrice, Decimal maxTerm) {
            this.maxTerm = maxTerm;
            this.qliGranualPrice = qliGranualPrice;
            this.productCode = lstWPoli.get(0).productCode;
            this.setIdAggregated = new Set<Id>();
            lstAbsLine = new List<AbstractLine>();
            lstOriginalAbsLine = new List<AbstractLine>();
            for (WPoli objWPoli : lstWPoli) {
                lstAbsLine.add(new AbstractLine(objWPoli, maxTerm));
            }
            lstOriginalAbsLine = lstAbsLine.clone();
            tryForceAggregate = false;
            isEmpty = true;
            alreadyTriedForceAggregate = false;
            aggregate();
        }
        /**
        * @description AggregatedLine
        * @param lstWQli
        * @param qliGranualPrice
        * @param maxTerm
        **/
        public AggregatedLine(List<WQli> lstWQli, Decimal qliGranualPrice, Decimal maxTerm) {
            this.maxTerm = maxTerm;
            this.qliGranualPrice = qliGranualPrice;
            this.productCode = lstWQli.get(0).productCode;
            this.setIdAggregated = new Set<Id>();
            lstAbsLine = new List<AbstractLine>();
            for (WQli objWQli : lstWQli) {
                lstAbsLine.add(new AbstractLine(objWQli, maxTerm));
            }
            tryForceAggregate = false;
            isEmpty = true;
            alreadyTriedForceAggregate = false;
            /**
            * @description aggregate
            **/
            aggregate();
        }

        /**
        * @description AggregatedLine
        * @param productCode
        * @param qliGranualPrice
        * @param maxTerm
        **/
        public AggregatedLine(String productCode, Decimal qliGranualPrice, Decimal maxTerm) {
            lstAbsLine = new List<AbstractLine>();
            this.maxTerm = maxTerm;
            this.qliGranualPrice = qliGranualPrice;
            this.productCode = productCode;
            this.setIdAggregated = new Set<Id>();
        }
        /**
        * @description addIndividually
        * @param objWPoli
        **/
        public void addIndividually(WPoli objWPoli) {
            isIndividualAdded = true;
            lstAbsLine.add(new AbstractLine(objWPoli, maxTerm));
            /**
            * @description callAggregate
            **/
            callAggregate();
            isIndividualAdded = false;
            
        }
        /**
        * @description addIndividually
        * @param objWQli
        **/
        public void addIndividually(WQli objWQli) {
            isIndividualAdded = true;
            lstAbsLine.add(new AbstractLine(objWQli, maxTerm));
            /**
            * @description aggregate
            **/
            callAggregate();
            isIndividualAdded = false;
        }
        /**
        * @description aggregate
        **/
        private void callAggregate() {
            tryForceAggregate = false;
            isEmpty = true;
            alreadyTriedForceAggregate = false;
            /**
            * @description aggregate
            **/
            aggregate();
        }

        Boolean tryForceAggregate { get; set; }
        Boolean alreadyTriedForceAggregate { get; set; }

        /**
        * @description aggregate
        **/
        private void aggregate() {
            Integer idx = 0;
            try {
                if(lstOriginalAbsLine != null) { // is POLI Aggregation
                    lstAbsLine = lstOriginalAbsLine.clone();
                }
                if(!tryForceAggregate && !isIndividualAdded) {
                    Map<String, Object> mapQuickComposeResults = new AbstractLine().tryQuickComposeFirst(lstAbsLine, maxTerm);      
                    lstAbsLine = (List<AbstractLine>) mapQuickComposeResults.get('AbstractLine List'); 
                    setIdAggregated = (Set<Id>) mapQuickComposeResults.get('AbstractLine Id Aggregated');
                }
                if(lstAbsLine.size() == 1) {
                    lstAbsLine.get(2);
                }
                while (true) {
                    lstAbsLine.sort();
                    AbstractLine objAbsLine = new AbstractLine();
                    Boolean isComposed = objAbsLine.composeAbstractLine(
                        lstAbsLine.get(idx),
                        lstAbsLine.get(idx + 1),
                        maxTerm
                    );
                    if (!alreadyTriedForceAggregate && tryForceAggregate) {
                        isComposed = objAbsLine.forceComposeAbstractLine(
                            lstAbsLine.get(idx),
                            lstAbsLine.get(idx + 1),
                            maxTerm
                        );
                    }
                    if (!isComposed) {
                        idx++;
                        continue;
                    }
                    AbstractLine objAbsLineRemoved;
                    objAbsLineRemoved = lstAbsLine.remove(idx);
                    if (objAbsLineRemoved.id != null) {
                        setIdAggregated.add(objAbsLineRemoved.id);
                    }
                    objAbsLineRemoved = lstAbsLine.remove(idx);
                    if (objAbsLineRemoved.id != null) {
                        setIdAggregated.add(objAbsLineRemoved.id);
                    }
                    lstAbsLine.add(objAbsLine);
                    idx = 0;
                    continue;
                }
            } catch (ListException e) {
                if (lstAbsLine.size() == 1) {
                    isEmpty = false;
                    AbstractLine objAbsAggregated = lstAbsLine.get(0);
                    if (objAbsAggregated.id != null) {
                        setIdAggregated.add(objAbsAggregated.id);
                    }
                    granualPrice = objAbsAggregated.granualPrice;
                    term = objAbsAggregated.term;
                    quantity = objAbsAggregated.quantity;
                } else {
                    if (tryForceAggregate) {
                        alreadyTriedForceAggregate = true;
                        tryForceAggregate = false;
                    } else {
                        tryForceAggregate = true;
                        alreadyTriedForceAggregate = false;
                        aggregate();
                    }
                    Set<Id> setIdErrorPoli = setIdAggregated;
                    String strErrorCause = (lstAbsLine.get(0).term != maxTerm) ? 'Term' : 'quantity';
                    for (AbstractLine objAbsLine : lstAbsLine) {
                        if (objAbsLine.id != null) {
                            setIdErrorPoli.add(objAbsLine.id);
                        }
                    }
                }
            }
        }
        /**
        * @description isAlreadyAggregated
        * @param idLine
        * @return boolean
        **/
        @TestVisible
        private Boolean isAlreadyAggregated(Id idLine) {
            return setIdAggregated.contains(idLine);
        }
    }
    /**
    * @description calculate Aggregate Poitem line vs Quote line
    * @param objAggLine
    * @param objWQli
    * @return pricediff
    **/
    public decimal calculatePAPriceDiff(AggregatedLine objAggLine, WQli objWQli){
        Decimal totalPOIs = objAggLine?.setIdAggregated.size();
        Decimal paPriceDiff = ((objWQli?.qli?.SBQQ__NetPrice__c/objWQli?.qli?.SBQQ__SubscriptionTerm__c) * objAggLine.quantity * (objAggLine.term/totalPOIs)) - ((objAggLine.unitPrice/totalPOIs)* objAggLine.quantity);
        return Math.abs(paPriceDiff.setScale(2, System.RoundingMode.HALF_UP));
    }

    /**
     * @description Tries to match List of POLI to QLI & creates suitable error, if needed
     * @param  objAggLine List of POLI to match
     * @param  objWQli  QLI record to match POLIs with
     * @return Boolean flag Whether of not it matched.
     */
    @TestVisible
    private Boolean matchLstWPoliWithWQli(AggregatedLine objAggLine, WQli objWQli) {
        // make change accept Agg POLI
        if (objAggLine.isEmpty) {
            if(objAggLine.lstOriginalAbsLine != null){
                for(AbstractLine absLine :objAggLine.lstOriginalAbsLine){
                    createPoError(
                        ERROR_CODE_MATCHING_POLI_ABSENT,
                        new Map<String, Object>{
                            'Quote_Line__c' => objWQli.id,
                            'PO_Stage_Id__c' => mapQuoteIdIdStagePoResponsible.get(objWQli.quoteId),
                            'PO_Stage_Item_Id__c' => absLine.id
                        }
                    );
                }
            }else{
                createPoError(
                        ERROR_CODE_MATCHING_POLI_ABSENT,
                        new Map<String, Object>{
                            'Quote_Line__c' => objWQli.id,
                            'PO_Stage_Id__c' => mapQuoteIdIdStagePoResponsible.get(objWQli.quoteId)
                        }
                    );
            }
            if (mapQPTokenLstWQli.containsKey(objWQli?.qpToken)) {
                List<WQli> lstWQLI = mapQPTokenLstWQli.get(objWQli.qpToken);
                for (WQli tempWQLI : lstWQLI) {
                    if(objWQli.id == tempWQLI.id){
                        Integer WQLIIndex = lstWQLI.indexOf(tempWQLI);
                        lstWQLI.remove(WQLIIndex);
                        break;
                    }
                }
            }
            results.setStrTokenSkipError.add(objWQli.qpToken);
            return false;
        }

        Boolean isMatchTerm = (objAggLine.term == objWQli.term);
        Boolean isMatchQuantity = (objAggLine.quantity == objWQli.quantity);
        Boolean isMatchPrice = isTolerablePriceDiff(objWQli.netPrice, objAggLine.netPrice);

        if (!isMatchTerm || !isMatchPrice || !isMatchQuantity) {
            if (isFinalRound) {
                Decimal PALineDiff = calculatePAPriceDiff(objAggLine,objWQli);
                for (Id idAggregated : objAggLine.setIdAggregated) {
                    poitemIDByDifference.put(idAggregated,String.valueOf(Math.abs(PALineDiff).setScale(2, System.RoundingMode.HALF_UP)));  
                    //poitemIDByDifference.put(idAggregated,String.valueOf(Math.abs(objWQli.netPrice - objAggLine.netPrice).setScale(2, System.RoundingMode.HALF_UP)));
                    createSuitablePoError(
                        isMatchTerm,
                        isMatchQuantity,
                        isMatchPrice,
                        new Map<String, Object>{
                            'Quote_Line__c' => objWQli.id,
                            'PO_Stage_Item_Id__c' => idAggregated,
                            'PO_Stage_Id__c' => mapIdPoliIdStagePo.get(idAggregated)
                        }
                    );
                }
            }
            return false;
        }

        for (Id idAggregated : objAggLine.setIdAggregated) {
            results.mapPoliMatched.put(
                idAggregated,
                new PO_Item_Stage__c(Id = idAggregated, Quote_Line__c = objWQli.Id,type__c = objWQli.qli.Line_Type__c)
            );
        }
        return true;
    }

    /**
     * @description given a map of POLIs (Value) with Prices(Key) tries to match best on to QLI
     * @param  mapPriceLstWPoli map of POLIs (Value) with Prices(Key) to match
     * @param  objWQli          QLI record With one we try to match
     */
    private void matchLstWPoliWithWQliOnPossiblePrices(Map<Decimal, List<WPoli>> mapPriceLstWPoli, WQli objWQli) {
        List<Decimal> lstDecPossiblePrices = new List<Decimal>(mapPriceLstWPoli.keySet()); // list of All Price under same token
        List<Decimal> lstDecAbsDiffPrices = absDiffWithInThreshold(lstDecPossiblePrices); // Diff Price (under threshold)
        List<Decimal> lstDecSortedAbsDiffPrices = lstDecAbsDiffPrices.clone(); // Diff Price Cloned, to be sorted. low -> High
        lstDecSortedAbsDiffPrices.sort(); // Diff Price Sorted. low -> High
        if (lstDecAbsDiffPrices.isEmpty()) {
            for(List<WPoli>  lstWPoli :mapPriceLstWPoli.values()) {
                for(WPOLI objWPoli :lstWPoli) {
                    Decimal PALineDiff = ((objWQli?.qli?.SBQQ__NetPrice__c/objWQli?.qli?.SBQQ__SubscriptionTerm__c) * objWPoli?.poli.Quantity__c * objWPoli?.poli.SubscriptionTerm__c) - (objWPoli?.poli?.UnitPrice__c * objWPoli?.poli.Quantity__c);
                    poitemIDByDifference.put(objWPoli.poli.id,String.valueOf(Math.abs(PALineDiff).setScale(2, System.RoundingMode.HALF_UP)));  
                    //poitemIDByDifference.put(objWPoli.poli.id,String.valueOf(Math.abs(objWQli?.qli?.SBQQ__NetTotal__c - (objWPoli?.poli.Quantity__c * objWPoli?.poli?.UnitPrice__c)).setScale(2, System.RoundingMode.HALF_UP)));  
                    createPoError(ERROR_CODE_PRICE_MISMATCH,
                        new Map<String, Object>{
                            'Quote_Line__c' => objWQli.id,
                            'PO_Stage_Item_Id__c' => objWPoli.id,
                            'PO_Stage_Id__c' => objWPoli.stagePo
                        }
                    );
                }
            }
            return;
        }
        for (Decimal decX : lstDecSortedAbsDiffPrices) {
            Decimal decPrice = lstDecPossiblePrices.get(lstDecAbsDiffPrices.indexOf(decX));
            // Price = list of All Price <- Diff Price (under threshold) <- First Instance of decX
            if (
                matchLstWPoliWithWQli(
                    new AggregatedLine(mapPriceLstWPoli.get(decPrice), objWQli.granualPrice, objWQli.term),
                    objWQli
                )
            ) {
                // since matched, lets break loop & move over to next objWQLI
                needFinalRound = false;
                break;
            } 
        }
        // find onces with
        Decimal decPrice = lstDecPossiblePrices.get(lstDecAbsDiffPrices.indexOf(lstDecSortedAbsDiffPrices.get(0)));
        isFinalRound = needFinalRound;
        if (needFinalRound) {
            storeForFinalMatching(objWQli);
            isFinalRound = false;
        }
    }

    /**
     * @description Match POLIs with QLIs
     */
    private void matchPoliWithQli() {
        setIdQliMatched = new Set<Id>();
        setStrTokenForFinalRoundWoQliRestriction = new Set<String>();
        for (String strToken : mapQPTokenLstWQli.keySet()) {
            if (mapQPTokenLstWQli.get(strToken).size() > 1) {
                setStrTokenForFinalRoundWoQliRestriction.add(mapQPTokenLstWQli.get(strToken).get(0).qpToken);
                continue;
            }
            Map<Decimal, List<WPoli>> mapPriceLstWPoli = params.mmPoli.get(strToken);
            if (mapPriceLstWPoli == null) {
                continue;
            }
            for (WQli objWQli : mapQPTokenLstWQli.get(strToken)) {
                if (!(objWQli.isAddon || objWQli.isSaaS)) {
                    continue;
                }
                isFinalRound = false;
                needFinalRound = true;
                // look for exact match for granualPrice
                if (setIdQliMatched.contains(objWQli.id)) {
                    continue;
                }
                if (mapPriceLstWPoli.containsKey(objWQli.granualPrice)) {
                    // found Exact match for Price.
                    // lets try to match its term, Price & Quantity with matching POLIs
                    
                    if (
                        matchLstWPoliWithWQli(
                            new AggregatedLine(
                                mapPriceLstWPoli.get(objWQli.granualPrice),
                                objWQli.granualPrice,
                                objWQli.term
                            ),
                            objWQli
                        )
                    ) {
                        needFinalRound = false;
                        continue;
                    }
                }
                if (needFinalRound) {
                    matchLstWPoliWithWQliOnPossiblePrices(mapPriceLstWPoli, objWQli);
                }
            }
        }
        if (setStrTokenForFinalRound != null) {
            doFinalMatchingNow();
        }
        if (!setStrTokenForFinalRoundWoQliRestriction.isEmpty()) {
            doFinalMatchingWoQliRestriction();
        }

        return;
    }

    private void doFinalMatchingNow() {
        if (setIdQliMatched == null) {
            setIdQliMatched = new Set<Id>();
        }
        for (String strToken : setStrTokenForFinalRound) {
            Map<Decimal, List<WPoli>> mapPriceLstWPoli = params.mmPoli.get(strToken);
            if (mapPriceLstWPoli == null) {
                continue;
            }
            for (WQli objWQli : mapQPTokenLstWQli.get(strToken)) {
                if (!(objWQli.isAddon || objWQli.isSaaS)) {
                    continue;
                }
                // look for exact match for granualPrice
                if (setIdQliMatched.contains(objWQli.id)) {
                    continue;
                }
                Boolean matched;
                Decimal decPrice;
                if (mapPriceLstWPoli.containsKey(objWQli.granualPrice)) {
                    // found Exact match for Price.
                    // lets try to match its term, Price & Quantity with matching POLIs
                    decPrice = objWQli.granualPrice;
                } else {
                    List<Decimal> lstDecPossiblePrices = new List<Decimal>(mapPriceLstWPoli.keySet()); // list of All Price under same token
                    List<Decimal> lstDecAbsDiffPrices = absDiffWithInThreshold(lstDecPossiblePrices); // Diff Price (under threshold)
                    List<Decimal> lstDecSortedAbsDiffPrices = lstDecAbsDiffPrices.clone(); // Diff Price Cloned, to be sorted. low -> High
                    lstDecSortedAbsDiffPrices.sort(); // Diff Price Sorted. low -> High
                    if (lstDecAbsDiffPrices.isEmpty()) {
                        continue;
                    }
                    // find onces with
                    decPrice = lstDecPossiblePrices.get(lstDecAbsDiffPrices.indexOf(lstDecSortedAbsDiffPrices.get(0)));
                }
                List<WPoli> lstWPoliToMatch = new List<WPoli>();
                for (WPoli objWPoli : mapPriceLstWPoli.get(decPrice)) {
                    if (!results.mapPoliMatched.containsKey(objWPoli.id)) {
                        lstWPoliToMatch.add(objWPoli);
                    }
                }

                AggregatedLine objAggLine = new AggregatedLine(lstWPoliToMatch, objWQli.granualPrice, objWQli.term);
                if (objAggLine.isEmpty) {
                    createPoError(
                        ERROR_CODE_MATCHING_POLI_ABSENT,
                        new Map<String, Object>{
                            'Quote_Line__c' => objWQli.id,
                            'PO_Stage_Id__c' => mapQuoteIdIdStagePoResponsible.get(objWQli.quoteId)
                        }
                    );
                    results.setStrTokenSkipError.add(objWQli.qpToken);
                    matched = false;
                }

                Boolean isMatchTerm = (objAggLine.term == objWQli.term);
                Boolean isMatchQuantity = (objAggLine.quantity == objWQli.quantity);
                Boolean isMatchPrice = isTolerablePriceDiff(objWQli.netPrice, objAggLine.netPrice);
                if (!isMatchTerm || !isMatchPrice || !isMatchQuantity) {
                    if (!(isMatchTerm || isMatchPrice || isMatchQuantity)) {
                        if (setStrTokenForFinalRoundWoPriceRestriction == null) {
                            setStrTokenForFinalRoundWoPriceRestriction = new Set<String>();
                        }
                        setStrTokenForFinalRoundWoPriceRestriction.add(objWQli.qpToken);
                        continue;
                    }

                    Decimal PALineDiff = calculatePAPriceDiff(objAggLine,objWQli);
                    for (Id idAggregated : objAggLine.setIdAggregated) {
                        poitemIDByDifference.put(idAggregated,String.valueOf(Math.abs(PALineDiff).setScale(2, System.RoundingMode.HALF_UP)));  
                        //poitemIDByDifference.put(idAggregated,String.valueOf(Math.abs(objWQli.netPrice - objAggLine.netPrice).setScale(2, System.RoundingMode.HALF_UP)));  
                        createSuitablePoError(
                            isMatchTerm,
                            isMatchQuantity,
                            isMatchPrice,
                            new Map<String, Object>{
                                'Quote_Line__c' => objWQli.id,
                                'PO_Stage_Item_Id__c' => idAggregated,
                                'PO_Stage_Id__c' => mapIdPoliIdStagePo.get(idAggregated)
                            }
                        );
                    }

                    matched = false;
                }
            }
        }
        if (setStrTokenForFinalRoundWoPriceRestriction != null) {
            doFinalMatchingWoPriceRestriction();
        }
    }
    private void doFinalMatchingWoPriceRestriction() {
        if (setIdQliMatched == null) {
            setIdQliMatched = new Set<Id>();
        }
        for (String strToken : setStrTokenForFinalRoundWoPriceRestriction) {
            Map<Decimal, List<WPoli>> mapPriceLstWPoli = params.mmPoli.get(strToken);
            if (mapPriceLstWPoli == null) {
                continue;
            }
            for (WQli objWQli : mapQPTokenLstWQli.get(strToken)) {
                if (!(objWQli.isAddon || objWQli.isSaaS)) {
                    continue;
                }
                // look for exact match for granualPrice
                if (setIdQliMatched.contains(objWQli.id)) {
                    continue;
                }
                Boolean matched;

                List<WPoli> lstWPoliToMatch = new List<WPoli>();
                for (List<WPoli> lstWPoli : mapPriceLstWPoli.values()) {
                    for (WPoli objWPoli : lstWPoli) {
                        if (!results.mapPoliMatched.containsKey(objWPoli.id)) {
                            lstWPoliToMatch.add(objWPoli);
                        }
                    }
                }
                AggregatedLine objAggLine = new AggregatedLine(lstWPoliToMatch, objWQli.granualPrice, objWQli.term);

                // make change accept Agg POLI
                if (objAggLine.isEmpty) {
                    createPoError(
                        ERROR_CODE_MATCHING_POLI_ABSENT,
                        new Map<String, Object>{
                            'Quote_Line__c' => objWQli.id,
                            'PO_Stage_Id__c' => mapQuoteIdIdStagePoResponsible.get(objWQli.quoteId)
                        }
                    );
                    results.setStrTokenSkipError.add(objWQli.qpToken);
                    return;
                }

                Boolean isMatchTerm = (objAggLine.term == objWQli.term);
                Boolean isMatchQuantity = (objAggLine.quantity == objWQli.quantity);
                Boolean isMatchPrice = isTolerablePriceDiff(objWQli.netPrice, objAggLine.netPrice);

                if (!isMatchTerm || !isMatchPrice || !isMatchQuantity) {
                    
                    /*if (!isMatchPrice && !isMatchQuantity) {
                    }*/
                    Decimal PALineDiff = calculatePAPriceDiff(objAggLine,objWQli);
                    for (Id idAggregated : objAggLine.setIdAggregated) {
                        poitemIDByDifference.put(idAggregated,String.valueOf(Math.abs(PALineDiff).setScale(2, System.RoundingMode.HALF_UP)));  
                        //poitemIDByDifference.put(idAggregated,String.valueOf(Math.abs(objWQli.netPrice - objAggLine.netPrice).setScale(2, System.RoundingMode.HALF_UP)));              
                        createSuitablePoError(
                            isMatchTerm,
                            isMatchQuantity,
                            isMatchPrice,
                            new Map<String, Object>{
                                'Quote_Line__c' => objWQli.id,
                                'PO_Stage_Item_Id__c' => idAggregated,
                                'PO_Stage_Id__c' => mapIdPoliIdStagePo.get(idAggregated)
                            }
                        );
                    }
                }
            }
        }
    }

    private void doFinalMatchingWoQliRestriction() {
        for (String strToken : setStrTokenForFinalRoundWoQliRestriction) {
            Map<Decimal, List<WPoli>> mapPriceLstWPoli = params.mmPoli.get(strToken);
            if (mapPriceLstWPoli == null) {
                continue;
            }
            Map<Integer, List<WQli>> mapIntTermLstWQli = new Map<Integer, List<WQli>>();
            for (WQli objWQli : mapQPTokenLstWQli.get(strToken)) {
                if (!(objWQli.isAddon || objWQli.isSaaS)) {
                    continue;
                }
                // look for exact match for granualPrice
                if (setIdQliMatched.contains(objWQli.id)) {
                    continue;
                }
                Integer intCurrentTerm = Integer.valueOf(objWQli.term);
                if (!mapIntTermLstWQli.containsKey(intCurrentTerm)) {
                    mapIntTermLstWQli.put(intCurrentTerm, new List<WQli>());
                }
                mapIntTermLstWQli.get(intCurrentTerm).add(objWQli);
            }
            for (List<WQli> lstWQli : mapIntTermLstWQli.values()) {
                Boolean matched;

                List<WPoli> lstWPoliToMatch = new List<WPoli>();
                for (List<WPoli> lstWPoli : mapPriceLstWPoli.values()) {
                    for (WPoli objWPoli : lstWPoli) {
                        if (!results.mapPoliMatched.containsKey(objWPoli.id)) {
                            lstWPoliToMatch.add(objWPoli);
                        }
                    }
                }
                matchWPoliWithWQliAbstractLines(lstWPoliToMatch, lstWQli);
            }
        }
    }
    void matchWPoliWithWQliAbstractLines(List<WPoli> lstWPoli, List<WQli> lstWQli) {
        lstWQli.sort();
        lstWPoli.sort();
        Map<Id, Set<Id>> mapIdQliSetIdPoliMatched = new Map<Id, Set<Id>>();
        Map<String, String> mapStrPoliPoCodeErrorCode = new Map<String, String>();
        for (WQli objWQli : lstWQli) {
            AggregatedLine objAggPoli = new AggregatedLine(objWQli.productCode, objWQli.granualPrice, objWQli.term);
            Decimal decGranualPrice;
            for (WPoli objWPoli : lstWPoli) {
                if (
                    results.mapPoliMatched.containsKey(objWPoli.id) || mapIdQliSetIdPoliMatched.containsKey(objWQli.id)
                ) {
                    continue;
                }
                objAggPoli.addIndividually(objWPoli);
                if (decGranualPrice == null) {
                    decGranualPrice = objWPoli.granualPrice;
                }
                Decimal decNetPrice = objAggPoli.quantity * objAggPoli.term * objWPoli.granualPrice;
                Boolean isPriceMatch = isTolerablePriceDiff(decNetPrice, objWQli.netPrice);
                Boolean isTermMatch = (objAggPoli.term == objWQli.term);
                Boolean isQuantityMatch = (objAggPoli.quantity == objWQli.quantity);

                if (isTermMatch && isQuantityMatch && isPriceMatch) {
                    mapIdQliSetIdPoliMatched.put(objWQli.Id, objAggPoli.setIdAggregated);
                    Decimal PALineDiff = calculatePAPriceDiff(objAggPoli,objWQli);
                    for (Id idAggregated : objAggPoli.setIdAggregated) {
                        poitemIDByDifference.put(idAggregated,String.valueOf(Math.abs(PALineDiff).setScale(2, System.RoundingMode.HALF_UP))); 
                        //poitemIDByDifference.put(idAggregated,String.valueOf(Math.abs(decNetPrice - objWQli.netPrice).setScale(2, System.RoundingMode.HALF_UP)));  
                        results.mapPoliMatched.put(
                            idAggregated,
                            new PO_Item_Stage__c(Id = idAggregated, Quote_Line__c = objWQli.Id,type__c = objWQli.qli.Line_Type__c)
                        );
                        mapStrPoliPoCodeErrorCode.remove(idAggregated + '-' + objWPoli.stagePo);
                    }
                    break;
                } else {
                    for (Id idAggregated : objAggPoli.setIdAggregated) {
                        String strErrorCode;
                        if (!isTermMatch) {
                            strErrorCode = ERROR_CODE_TERM_MISMATCH;
                        } else if (!isQuantityMatch) {
                            strErrorCode = ERROR_CODE_QUANTITY_MISMATCH;
                        } else {
                            strErrorCOde = ERROR_CODE_PRICE_MISMATCH;
                        }
                        mapStrPoliPoCodeErrorCode.put(idAggregated + '-' + objWPoli.stagePo, strErrorCode);
                    }
                }
            }
        }

        for (String strPoliPoCode : mapStrPoliPoCodeErrorCode.keySet()) {
            List<String> lstPoliPoCodeSplit = strPoliPoCode.split('-');

            createPoError(
                mapStrPoliPoCodeErrorCode.get(strPoliPoCode),
                new Map<String, Object>{
                    'PO_Stage_Item_Id__c' => lstPoliPoCodeSplit[0],
                    'PO_Stage_Id__c' => lstPoliPoCodeSplit[1]
                }
            );
        }
    }

    /**
     * @description For given list of Decimals, return ones under threshold price
     * @param  lstDec list of Decimals
     * @return        ones under threshold price
     */
    private List<Decimal> absDiffWithInThreshold(List<Decimal> lstDec) {
        List<Decimal> res = new List<Decimal>();
        for (Decimal val : lstDec) {
            Decimal diff = (val - ValidateEDIGoProducts.threshold).abs();
            if (diff > ValidateEDIGoProducts.threshold) {
                continue;
            }
            res.add(diff);
        }
        return res;
    }
    @TestVisible
    private void createCollectionOfStagePoErrorPoliId() {
        results.setIdPoliErrorGoProduct = new Set<Id>();
        for (PO_Stage_Errors__c objStagePoError : results.lstStageError) {
            if (String.isBlank(objStagePoError.PO_Stage_Id__c)) {
                continue;
            }
            results.setIdPoliErrorGoProduct.add(objStagePoError.PO_Stage_Id__c);
        }
    }

    /**
     * @description Checks if a Decimal is not null
     * @param  d Decimal to check
     * @return   Boolean flag, true if not null, flase if Null
     */
    private static Boolean isNotNull(Decimal d) {
        return d != null;
    }
    /**
    * @description ValidationResults
    **/
    public class ValidationResults {
        /**
        * @description PoitemMatched Set
        **/
        public Map<Id, PO_Item_Stage__c> mapPoliMatched { get; set; }
        /**
        * @description Poli ummatched
        **/
        public Set<Id> setIdPoliUnMatched { get; set; }
        /**
        * @description failed QuoteIds
        **/
        public Set<Id> setIdQuoteFailed { get; set; }
        // POLI -> Stage PO -> Quote
        /**
        * @description failed QuoteLineIds
        **/
        public Set<Id> setIdQuoteLineFailed { get; set; } // Not initialised & not Using.
        /**
        * @description failed StagePo ids
        **/
        public Set<Id> setIdStagePoFailed { get; set; }
        /**
        * @description failed Tokenkip
        **/
        public Set<String> setStrTokenSkipError { get; set; }
        /**
        * @description failed PoitemError for Go sku
        **/
        public Set<Id> setIdPoliErrorGoProduct { get; set; }
        /**
        * @description list of stage Error
        **/
        public List<PO_Stage_Errors__c> lstStageError { get; set; }
        /**
        * @description ValidationResults
        **/
        public ValidationResults() {
            setIdPoliErrorGoProduct = new Set<Id>();
            setStrTokenSkipError = new Set<String>();
            setIdQuoteFailed = new Set<Id>();
            setIdPoliUnMatched = new Set<Id>();
            setIdStagePoFailed = new Set<Id>();
            lstStageError = new List<PO_Stage_Errors__c>();
            mapPoliMatched = new Map<Id, PO_Item_Stage__c>();
            setIdQuoteLineFailed = new Set<Id>();
        }
    }
    /**
    * @description WQLI comparable class
    * @return integer
    **/
    public class WQli implements Comparable {
        private SBQQ__QuoteLine__c qli { get; set; }
        /**
        * @description compare
        * @param x
        * @return integer
        **/
        public Integer compareTo(Object x) {
            WQli other = (WQli) x;
            if (quantity == other.quantity) {
                if (term > other.term) {
                    return -1;
                } else if (term < other.term) {
                    return 1;
                }
                return 0;
            }
            if (quantity > other.quantity) {
                return 1;
            }
            return -1;
        }
        /**
        * @description quoteId
        * @return quoteId
        **/
        public Id quoteId {
            get {
                return qli.SBQQ__Quote__c;
            }
        }
        /**
        * @description productUsableCapacity for HW
        * @return Usable capacity
        **/
        public Decimal productUsableCapacity {
            get {
                if (!isHw) {
                    return 0;
                }
                return qli.SBQQ__Product__r.Usable_Capacity__c;
            }
        }
        /**
        * @description term
        * @return decimal
        **/
        public Decimal term {
            get {
                return (isNotNull(qli.SBQQ__SubscriptionTerm__c) && qli.SBQQ__SubscriptionTerm__c != 0
                    ? qli.SBQQ__SubscriptionTerm__c
                    : 12);
            }
        }
        /**
        * @description netPrice
        * @return decimal
        **/
        public Decimal netPrice {
            get {
                return ((isNotNull(qli.SBQQ__NetPrice__c) && isNotNull(qli.SBQQ__Quantity__c))
                    ? qli.SBQQ__NetPrice__c * qli.SBQQ__Quantity__c
                    : 0);
            }
        }
        /**
        * @description productUsableCapacity for HW
        * @return usable capacity
        **/
        public Decimal usableCapacity {
            get {
                return qli.SBQQ__Product__r.Usable_Capacity__c;
            }
        }
        /**
        * @description Qli Id
        * @return Id
        **/
        public Id id {
            get {
                return qli.id;
            }
        }
        /**
        * @description quantity
        * @return qli quantity
        **/
        public Decimal quantity {
            get {
                return (isNotNull(qli.SBQQ__Quantity__c) ? qli.SBQQ__Quantity__c : 0);
            }
        }
        /**
        * @description ProductCode
        * @return ProductCode
        **/
        public String productCode {
            get {
                return qli.SBQQ__ProductCode__c;
            }
        }
        /**
        * @description unitPrice
        * @return unitPrice
        **/
        public Decimal unitPrice {
            get {
                return (netPrice / quantity);
            }
        }
        /**
        * @description granualprice
        * @return granualPrice
        **/
        public Decimal granualPrice {
            get {
                return unitPrice / term;
            }
        }
        private Map<String, Map<Decimal, Decimal>> mapPCodeDecQuantityDecUsableCapacity { get; set; }
        /**
        * @description Saas Product
        * @return saas
        **/
        public Boolean isSaaS {
            get {
                return ValidateEDIGoProducts.isSaaSProduct(qli.SBQQ__Product__r);
            }
        }
        /**
        * @description HW product
        * @return vliadate HW
        **/
        public Boolean isHw {
            get {
                return ValidateEDIGoProducts.isHwProduct(qli.SBQQ__Product__r);
            }
        }
        /**
        * @description addon product
        * @return vliadate addon
        **/
        public Boolean isAddon {
            get {
                return ValidateEDIGoProducts.isAddonProduct(qli.SBQQ__Product__r);
            }
        }
        /**
        * @description WQL
        * @param q
        **/
        public WQli(SBQQ__QuoteLine__c q) {
            this.qli = q;
        }

        /**
        * @description qpTokem
        * @return Quote and productcode
        **/
        public string qpToken {
            get {
                return qli.SBQQ__Quote__c + '-' + productCode;
            }
        }
    }
    /**
    * @description comparable
    **/
    public class WPoli implements Comparable {
        /**
        * @description WPoli
        * @param p
        **/
        public WPoli(PO_Item_Stage__c p) {
            this.poli = p;
            if (isSaaS) {
                mapPCodeCapacity = new Map<String, Decimal>();
            }
        }
        /**
        * @description Id
        * @return poitemid
        **/
        public Id id {
            get {
                return poli.id;
            }
        }
        /**
        * @description comparable
        * @param x
        * @return integer
        **/
        public Integer compareTo(Object x) {
            WPoli other = (WPoli) x;
            if (term == other.term) {
                if (quantity > other.quantity) {
                    return 1;
                } else if (quantity < other.quantity) {
                    return -1;
                }
                return 0;
            }
            if (term > other.term) {
                return 1;
            }
            return -1;
        }
        /**
        * @description Stage PO
        **/
        public String stagePO {
            get {
                return poli.Stage_PO__c;
            }
        }
        // use for HW only
        /**
        * @description use for HW only
        */
        public Decimal usableCapacity { get; set; }
        // use for Hw only
         /**
        * @description use for HW only
        * @param objQli
        */
        public void addHwCapacity(SBQQ__QuoteLine__c objQli) {
            usableCapacity = (objQli.SBQQ__Product__r.Usable_Capacity__c != null)
                ? objQli.SBQQ__Product__r.Usable_Capacity__c
                : 0;
        }

        // use for SaaS Only
        /**
        * @description use for SaaS only
        */
        Map<Id, Decimal> mapPoliIdCapacity { private get; private set; }
        // use for SaaS Only
        @TestVisible
        private Boolean isSaaSCapacityChanged = false;
        /**
        * @description use for SaaS only
        * @param objWQli
        * @param decPoliQuantity
        **/
        @TestVisible
        public void addSaaSCapacity(WQli objWQli, Decimal decPoliQuantity) {
            isSaaSCapacityChanged = true;
            mapPCodeCapacity.put(objWQli.productCode, objWQli.usableCapacity * decPoliQuantity);
        }
        // use for SaaS Only
        private Map<String, Decimal> mapPCodeCapacity { private get; private set; }
        /**
        * @description use for SaaS only
        **/
        @TestVisible
        public Boolean isSaaS {
            get {
                return ValidateEDIGoProducts.isSaaSProduct(poli.Product__r);
            }
        }
         /**
        * @description use for HW only
        **/
        public Boolean isHw {
            get {
                return ValidateEDIGoProducts.isHwProduct(poli.Product__r);
            }
        }
         /**
        * @description use for Addon only
        **/
        public Boolean isAddon {
            get {
                return ValidateEDIGoProducts.isAddonProduct(poli.Product__r);
            }
        }
        private PO_Item_Stage__c poli { get; set; }
        /**
        * @description ProductCode
        **/
        public String productCode {
            get {
                return poli.ProductCode__c;
            }
        }
         /**
        * @description Unit Price
        **/
        public Decimal unitPrice {
            get {
                return poli.UnitPrice__c;
            }
        }
         /**
        * @description term
        **/
        public Decimal term { // ! check back here
            get {
                // return poli.SubscriptionTerm__c;
                return isNotNull(poli.SubscriptionTerm__c) ? poli.SubscriptionTerm__c : 12;
            }
        }
        /**
        * @description granual Price
        **/
        public Decimal granualPrice {
            get {
                Decimal gPrice= null;
                if(!mapProductCodeWithPrice.containskey(productCode)){
                    mapProductCodeWithPrice.put(productCode, new List<decimal>{(unitPrice / term)} );
                    gPrice= unitPrice / term;
                }else{
                    for(decimal granPrice : mapProductCodeWithPrice.get(productCode) ){
                        decimal diff = granPrice - (unitPrice / term);
                        if(Math.abs(diff)< .01){
                            gPrice= granPrice;
                            
                        }
                    }
                    if(gPrice == null){
                        gPrice= unitPrice / term;
                        mapProductCodeWithPrice.get(productCode).add(gPrice);
                    }
                }
                return gPrice; 
            }
        }
         /**
        * @description netPrice
        **/
        public Decimal netPrice {
            get {
                return granualPrice * term * quantity;
            }
        }
        // SaaS Only
         /**
        * @description use for SaaS only
        **/
        @TestVisible
        private Double internalQuantity {
            get {
                if (!isSaaS) {
                    return 0;
                }
                Decimal q = 0;
                if (isSaaSCapacityChanged) {
                    for (Decimal x : mapPCodeCapacity.values()) {
                        q += x;
                    }
                    internalQuantity = q;
                    isSaaSCapacityChanged = false;
                }
                return internalQuantity;   
            }
            set;
        }
         /**
        * @description Quantity
        **/
        public Double quantity {
            get {
                return isNotNull(poli.Quantity__c) && poli.Quantity__c != 0 ? poli.Quantity__c : 0;
            }
        }
    }

     /**
     * @description check for Orphanpoitems
     **/
     @TestVisible
    private void checkForOrphanPolis() {
        Set<String> setStrOrphanTokens = new Set<String>();
        for (String strToken : params.mmPoli.keySet()) {
            if (mapQPTokenLstWQli.containsKey(strToken) && !mapQPTokenLstWQli.get(strToken).isEmpty()) {
                continue;
            }
            setStrOrphanTokens.add(strToken);
        }
        for (String strToken : setStrOrphanTokens) {
            for (List<WPoli> ls : params.mmPoli.get(strToken).values()) {
                for (WPoli objWPoli : ls) {
                    createPoError(
                        ERROR_CODE_MATCHING_QLI_ABSENT,
                        new Map<String, Object>{
                            'PO_Stage_Item_Id__c' => objWPoli.id,
                            'PO_Stage_Id__c' => objWPoli.stagePo
                        }
                    );
                }
            }
        }
    }
}