/***********************************************************************************************************
 * Class Name           : SKUNewReplacementController
 * Date Created/Modified: 28/03/2024
 * Author               : Rahul/Shivani 
 * @description          : This class is used by SKUNewReplacement component.
 *                        Fetches all the records using product2, replacement grid object and returns
 *                        the list of products. Story: FY25SR-1081 , FY25SR-1084                       
 * Test Class           : SKUNewReplacementControllerTest
 * Dependant Components : SKUNewReplacement, newReplacement
/**********************************************************************************************************/

public class SKUNewReplacementController { 
    public static List<String> quoteTypes = new List<String>{ReplacementConstants.QUOTE_TYPE_RENEWAL, ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION};
    /***********************************************************************************************************
     * Method Name          : getSKUData
     * Date Created/Modified: 28/03/2024
     * Author               : Rahul/Shivani
     * @description         : This method returns the list of products by taking ReplacementCategory name 
     *                        as input parameter from entitlements on IBM screen and returns the list 
     *                        of eligible products for replacement
     * Test Class Methods   :
     * @return              : List of WrapperProuct values
     * @param       entData 
     * @param       quoteDet        
     * @param 		replacementanytoany
     /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<WrapperProuct> getSKUData(
        ReplacementRefreshWrapperData.WrapperData entData, 
        SBQQ__Quote__c quoteDet, Boolean replacementanytoany) { 
        try{
        List<WrapperProuct> listWrapperProuct = new List<WrapperProuct>();
        Set<string> sProdRep = new Set<string>(); 
        Map<String, String> mapNotAllowed = new Map<String, String>();
        Map<String, String> mapDowngrade = new Map<String, String>();
        Map<String, String> mapUpgradeMapping = new Map<String, String>();
        Set<Id> sRenewedProducts = new Set<Id>();
        String skuWithoutPaymentAndSupport;
        String srSupportPayment;
        if(entData.srSuppType != null && entData.srPaymentType != null){
            srSupportPayment = String.ValueOf(entData.srSuppType).toLowerCase() + String.ValueOf(entData.srPaymentType).toLowerCase();
        }
        if(entData.srRenewedProduct != null){
            sRenewedProducts.add(entData.srRenewedProduct);
        }
        if(entData.srCustomRenewedProduct != null){
            sRenewedProducts.add(entData.srCustomRenewedProduct);
        }
        if(entData != NULL && entData.SrprodRepCategory != NULL){            
            List<Replacement_Support__c> lstReplacePol = ReplacementQueryController.getSkuReplacementPolicyGrid();
            Id matrixRecordtypeId = Schema.getGlobalDescribe()
                    .get(ReplacementConstants.REPLACEMENT_SUPPORT_OBJ)
                    .getDescribe()
                    .getRecordTypeInfosByDeveloperName()
                    .get(ReplacementConstants.MATRIX_RECORDTYPE)
                    .getRecordTypeId();
            Id upgRecordTypeId = Schema.getGlobalDescribe()
                    .get(ReplacementConstants.REPLACEMENT_SUPPORT_OBJ)
                    .getDescribe()
                    .getRecordTypeInfosByDeveloperName()
                    .get(ReplacementConstants.UPGRADE_VALUE)
                    .getRecordTypeId();
            if(!lstReplacePol.isEmpty()){
                for(Replacement_Support__c rp: lstReplacePol){
                    if(rp.recordTypeId == matrixRecordtypeId && rp.Source_Replacement_Category__c != NULL){                        
                        if(rp.Source_Replacement_Category__c == entData.SrprodRepCategory){
                            sProdRep.add(rp.Target_Replacement_Category__c);
                    	}
                    }
                    if(rp.Path__c == ReplacementConstants.NOTALLOWED_VALUE){
                        mapNotAllowed.put(
                            ((rp.Source_Edition__c+rp.Target_Edition__c).deleteWhitespace()).toLowerCase(),
                            rp.Path__c);
                    }   
                    if(rp.Path__c == ReplacementConstants.DOWNGRADE_VALUE){
                        mapDowngrade.put(
                            ((rp.Source_Edition__c+rp.Target_Edition__c).deleteWhitespace()).toLowerCase(),
                            rp.Path__c);
                    }
                    if(rp.Path__c == ReplacementConstants.UPGRADE_VALUE){
                        mapUpgradeMapping.put(
                            ((rp.Source_Edition__c+rp.Target_Edition__c).deleteWhitespace()).toLowercase(), 
                            rp.Path__c);
                    }    
                }
            }
            
                Integer index = 0;
                Integer entCount = 1;             
                if(String.isNotBlank(entData.entitlementName)){
                        if(entData.entitlementName.startsWith('RA-')){ //FY25SR-2388
                            skuWithoutPaymentAndSupport = entData.entitlementName.removeEnd(entData.entitlementName.right(3));
                        }else{
                    skuWithoutPaymentAndSupport = entData.entitlementName.removeEnd(entData.entitlementName.right(5));
                }
                }
                /************ Below code is implemented as a part of FY25SR-1084 **************************/
                Map<String,Replacement_Field_Mapping__mdt> sPrdTypeSubTypeFieldMapping = new Map<String,Replacement_Field_Mapping__mdt>();//ITNPI-3260:stores all the product type/sub type details eligible for attributes from custom metadata.
                List<Replacement_Field_Mapping__mdt> lstProductTypeSubType 
                    = ReplacementQueryController.getListOfProductTypeSubType();
                Map<String, String> mapProdTypeSubTypeToFields = new Map<String, String>();
                Set<String> allSkuAttributes = new Set<String>();
                if(!lstProductTypeSubType.isEmpty()){
                    for(Replacement_Field_Mapping__mdt rep : lstProductTypeSubType){
                        sPrdTypeSubTypeFieldMapping.put(rep.Product_Type_Sub_Type__c, rep);//ITNPI-3260
                        if(rep.Product_Type_Sub_Type__c != NULL && rep.SKU_Attribute_Fields__c != NULL){
                            List<String> lstAttributeFields = rep.SKU_Attribute_Fields__c.split(',');
                            Set<String> setAttributesfields = new Set<String>(lstAttributeFields);
                            allSkuAttributes.addAll(setAttributesfields);
                            mapProdTypeSubTypeToFields.put(rep.Product_Type_Sub_Type__c, rep.SKU_Attribute_Fields__c);
                        }
                    }             
                }
                Map<String, String> parentMapFields = new Map<String, String>();
                if(!allSkuAttributes.isEmpty() && entData.originalQuoteLineIdForEnt != NULL){                      
                   	parentMapFields = ReplacementQueryController.getEntitlementsDynamicQuery(
                        allSkuAttributes, 
                        entData.originalQuoteLineIdForEnt);
                }
                
                /*****************************************************************************************/
                List<Product2> lstSkuProdData = new List<Product2>();
                /***********************FY25SR-1557 START ***********************************************/
                //FY25SR-2232
                Set<Id> setNewProductId = new Set<Id>();
                List<Polaris_SKU_Mapping_V2__c> lstSkuPolaris = new List<Polaris_SKU_Mapping_V2__c>();
                if(entData.v1Product == true && entData.productId != NULL){
                        lstSkuPolaris = ReplacementQueryController.getV2ProductIdsForRenewalV1(entData.productId);
                }
            	Set<String> newProdPaymentSupport = new Set<String>();
                if(!lstSkuPolaris.isEmpty()){
                    for(Polaris_SKU_Mapping_V2__c pm : lstSkuPolaris){
                       setNewProductId.add(pm.New_Product__c);
                       newProdPaymentSupport.add(pm.New_Product__r.ProductCode.removeEnd(pm.New_Product__r.ProductCode.right(5)));
                   }
                }
                //FY25SR-2232
                    if((replacementanytoany == true && entData.SrprodRepCategory != ReplacementConstants.ENTERPRISE_DATA_PROTECTION_TPH && 
                        entData.tphTypeEntitlement == false) || quoteDet.SBQQ__Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL || 
                        (quoteDet.SBQQ__Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION && entData.SrprodRepCategory == ReplacementConstants.NON_REPLACEABLE)){
                            lstSkuProdData 
                                = ReplacementQueryController.getSkuProductData(true, sProdRep, entData, setNewProductId, quoteDet); 
                    }else if(!sProdRep.isEmpty()){
                            lstSkuProdData 
                                = ReplacementQueryController.getSkuProductData(false, sProdRep, entData, setNewProductId, quoteDet);
                    }
                
                /***********************FY25SR-1557 END**************************************************/
                Set<Id> sHwAsset = new Set<Id>();
                /***Below code is implemented as a part of FY25SR-1080, 1081,1557, 1202 which includes Payment and Support switch changes for R+E and Renweal Quotes**/
                if(!lstSkuProdData.isEmpty()){ 
                    for(product2 objProd : lstSkuProdData){ //Added by Garima
                        String targetSupportPayment;
                        if(objProd.Support_Type__c != null && objProd.Product_Payment_Option__c != null){
                             targetSupportPayment = (String.ValueOf(objProd.Support_Type__c).toLowerCase() + String.ValueOf(objProd.Product_Payment_Option__c).toLowerCase());
                        }
                        String targetSkuWithoutPaymentAndSupport = '';
                        if(quoteTypes.contains(quoteDet.SBQQ__Type__c) && String.isNotBlank(objProd.ProductCode)) {
                            if(objProd.ProductCode.startsWith('RA-')){ //FY25SR-2388
                                targetSkuWithoutPaymentAndSupport = objProd.ProductCode.removeEnd(objProd.ProductCode.right(3));
                            }else{
                                targetSkuWithoutPaymentAndSupport = objProd.ProductCode.removeEnd(objProd.ProductCode.right(5));
                            }
                        }
                        if(!mapNotAllowed.containsKey(((entData.oldProductEdition+objProd.Edition__c).deleteWhitespace()).toLowerCase())){
                            if(mapDowngrade.containsKey(((entData.oldProductEdition+objProd.Edition__c).deleteWhitespace()).toLowerCase())
                                    && entData.SrprodLicSubCategoryVal == objProd.License_Sub_Category__c){
                                        System.debug(LoggingLevel.DEBUG, 'Replacement Not Allowed');
                            }else{
                                //FY25SR-1084 START
                                    String objProdTypeSubType = sPrdTypeSubTypeFieldMapping?.keySet().contains(objProd.Product_Subtype__c) ? objProd.Product_Subtype__c : //ITNPI-3260
                                    (sPrdTypeSubTypeFieldMapping?.keySet().contains(objProd.Product_Type__c) ? objProd.Product_Type__c : null);
                                      Replacement_Field_Mapping__mdt  fieldMapping = objProdTypeSubType!=null ?sPrdTypeSubTypeFieldMapping.get(objProdTypeSubType):null;
                                    if(fieldMapping != null && (String.isBlank(fieldMapping.Product_Level__c) ||(String.isNotBlank(fieldMapping.Product_Level__c) && fieldMapping.Product_Level__c.split(',').contains(objProd.Product_Level__c))) &&
                                        entData.productId != NULL && objProd.Id != NULL && entData.productId == objProd.Id){
                                        listWrapperProuct.add
                                            (formCommonSkuWrapper(
                                                objProd, index, entCount, mapUpgradeMapping, 
                                                fieldMapping, mapProdTypeSubTypeToFields, parentMapFields,sProdRep, false));
                                        entCount = entCount + 1;
                                    } //FY25SR-1084 END
                                    else if(quoteDet.SBQQ__Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL && 
                                        ((objProd.ProductCode != entData.entitlementName && 
                                        String.isNotBlank(skuWithoutPaymentAndSupport) && 
                                        String.isNotBlank(targetSkuWithoutPaymentAndSupport) && 
                                        targetSkuWithoutPaymentAndSupport == skuWithoutPaymentAndSupport) || //FY25SR-2232
                                            (!newProdPaymentSupport.isEmpty() && newProdPaymentSupport.contains(targetSkuWithoutPaymentAndSupport))
                                        )){
                                        listWrapperProuct.add(
                                            formCommonSkuWrapper(objProd, index, entCount, 
                                            mapUpgradeMapping, fieldMapping, mapProdTypeSubTypeToFields, 
                                            parentMapFields, sProdRep, false));
                                        entCount = entCount + 1;                  
                                    }else if(quoteDet.SBQQ__Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION && 
                                            String.isNotBlank(skuWithoutPaymentAndSupport) && String.isNotBlank(targetSkuWithoutPaymentAndSupport)
                                            && !sRenewedProducts.contains(objProd.Id))
                                            {  
                                               if(entData.SrprodRepCategory == ReplacementConstants.NON_REPLACEABLE && 
                                                ((objProd.ProductCode != entData.entitlementName && 
                                                    targetSkuWithoutPaymentAndSupport == skuWithoutPaymentAndSupport) || 
                                                (!newProdPaymentSupport.isEmpty() && newProdPaymentSupport.contains(targetSkuWithoutPaymentAndSupport)))
                                                ){
                                                    listWrapperProuct.add(
                                                        formCommonSkuWrapper(objProd, index, entCount, 
                                                        mapUpgradeMapping, fieldMapping, mapProdTypeSubTypeToFields, 
                                                        parentMapFields, sProdRep, true));
                                                    entCount = entCount + 1;
                                                }else if(entData.SrprodRepCategory != ReplacementConstants.NON_REPLACEABLE){
                                                    if((targetSkuWithoutPaymentAndSupport == skuWithoutPaymentAndSupport && entData.entitlementName != objProd.Name) || 
                                                        (!newProdPaymentSupport.isEmpty() && newProdPaymentSupport.contains(targetSkuWithoutPaymentAndSupport)
                                                        && String.isNotBlank(srSupportPayment) && String.IsNotBlank(targetSupportPayment) && 
                                                            srSupportPayment != targetSupportPayment)){
                                                        listWrapperProuct.add(
                                                            formCommonSkuWrapper(objProd, index, entCount, 
                                                            mapUpgradeMapping, fieldMapping, mapProdTypeSubTypeToFields, 
                                                            parentMapFields, sProdRep, true));
                                                        entCount = entCount + 1; 
                                                    }else if(targetSkuWithoutPaymentAndSupport != skuWithoutPaymentAndSupport){
                                                            if(!newProdPaymentSupport.isEmpty() && newProdPaymentSupport.contains(targetSkuWithoutPaymentAndSupport)
                                                                && String.isNotBlank(srSupportPayment) && String.IsNotBlank(targetSupportPayment) && 
                                                                    srSupportPayment == targetSupportPayment){
                                                                    System.debug(LoggingLevel.DEBUG, 'Product Not Eligible');
                                                            }else{
                                                                listWrapperProuct.add(
                                                                formCommonSkuWrapper(objProd, index, entCount, 
                                                                mapUpgradeMapping, fieldMapping, mapProdTypeSubTypeToFields, 
                                                                parentMapFields, sProdRep, false));
                                                                entCount = entCount + 1;
                                                            }
                                                    }
                                                }
                                               
                                        }
                            }
                        }
                    }
                }
        }
        return listWrapperProuct;     
        }
        catch(exception ex){
          Custom_Error_Log__c CaptureError = new Custom_Error_Log__c(
            Class__c='SkuNewReplacementController',
            Functionality__c='getSKUData Method failed',
            Exception_Message__c=ex.getMessage());
          insert CaptureError;
          throw ReplacementQuoteLineCreationHelper.handleException(ex);
        }                                             
    }
    
    
     /***********************************************************************************************************
     * Method Name          : formCommonSkuWrapper
     * Date Created/Modified: 10-March-2025
     * Author               : Rahul
     * @description         : This method returns Wrapper by mapping required product fields 
     * 
     * @return            : WrapperProuct  
     * @param       objProd  
     * @param       index
     * @param       entCount    
     * @param       mapUpgradeMapping
     * @param       fieldMapping
     * @param       mapProdTypeSubTypeToFields
     * @param       parentMapFields
     * @param       sProdRep
     * @param       paymentSwitchEligible
    /**********************************************************************************************************/
    public static WrapperProuct formCommonSkuWrapper(product2 objProd, Integer index, 
        Integer entCount, Map<String, String> mapUpgradeMapping, 
        Replacement_Field_Mapping__mdt fieldMapping, Map<String, String> mapProdTypeSubTypeToFields, 
        Map<String, String> parentMapFields, Set<String> sProdRep, Boolean paymentSwitchEligible){
        WrapperProuct objWrapperProduct = new WrapperProuct();
        objWrapperProduct.productId = objProd.Id ;
        objWrapperProduct.productName = objProd.Name ;
        objWrapperProduct.isRowSelected = false;
        objWrapperProduct.productEdition = objProd.Edition__c ;
        objWrapperProduct.productSupportType = objProd.Support_Type__c;
        objWrapperProduct.productReplacementCategory = objProd.Replacement_Category__c ;
        objWrapperProduct.productDescription = objProd.Description ;
        objWrapperProduct.productLicenseType = objProd.License_Type__c ;
        objWrapperProduct.productProductType = objProd.Product_Type__c ;
        objWrapperProduct.productSubType = objProd.Product_Subtype__c;  
        objWrapperProduct.sourceToDestinationMatrix = new List<String>(sProdRep); 
        objWrapperProduct.enablePaymentSwitchRE = paymentSwitchEligible;
        objWrapperProduct.hardwareNotRequiredForHybrid = 
        objProd.IsHardwareNotRequiredForHybridLicense__c == false ? false : true;
        objWrapperProduct.anyToAnyFlag = false;
        //FY25SR-1084 START
              
        if(fieldMapping!=null && (String.isBlank(fieldMapping.Product_Level__c) ||(String.isNotBlank(fieldMapping.Product_Level__c) && fieldMapping.Product_Level__c.split(',').contains(objProd.Product_Level__c))) && (String.isBlank(fieldMapping.Excluded_Replacement_Category__c) ||(String.isNotBlank(fieldMapping.Excluded_Replacement_Category__c) && !(fieldMapping.Excluded_Replacement_Category__c.split(',').contains(objProd.Replacement_Category__c))))){ //ITNPI-3260
            objWrapperProduct.attributeEligibleCheck = true;
        }
        else{
            objWrapperProduct.attributeEligibleCheck = false; 
        }
        
        //FY25SR-1084 END
        objWrapperProduct.showAttributeSection = false;
        objWrapperProduct.showAssets = false;	
        objWrapperProduct.productLicenseCategory = objProd.License_Category__c;
        objWrapperProduct.productLicenseSubCategory = objProd.License_Sub_Category__c;
        objWrapperProduct.productPaymentOption = objProd.Product_Payment_Option__c;
        objWrapperProduct.isHardWareProduct = false;
        objWrapperProduct.productCodeType = 
            mapProductCodeType(objProd.Product_Type__c, objProd.Product_Subtype__c, 
                objProd.Description, objProd.ProductCode);  
        objWrapperProduct.customIndex = '' + entCount + '.' + index;
        objWrapperProduct.showSelectCheckBox = true;
        objWrapperProduct.mapUpgradeMapping = mapUpgradeMapping;
        objWrapperProduct.productTypeSubTypeVsFieldMapping = mapProdTypeSubTypeToFields;
        objWrapperProduct.doNotConsolidateSKU = false; //FY25SR-1705
        objWrapperProduct.multiAddAssets = false;
        if(parentMapFields.KeySet().size() > 0){
            for(String str : parentMapFields.KeySet()){
                String value = parentMapFields.get(str) != null ? parentMapFields.get(str) : 'null';
                objWrapperProduct.setField(str, value, true);
            }
        }
        return objWrapperProduct;
    }
	
     /***********************************************************************************************************
      * Method Name          : getSchemaFieldsForQuoteLine
      * Date Created/Modified: 10/04/2025
      * Author               : Rahul
      * @description         : This Method returns the list of SKU Products
      * Story                : FY25SR-1084
      * @return              : List of SkuDrawerWrapperProduct wrapper 
      * @param 				   skuWrap
  /**********************************************************************************************************/
   @AuraEnabled(cacheable=true)
   public static List<SKUNewReplacementController.SkuDrawerWrapperProduct> getSchemaFieldsForQuoteLine(
        SKUNewReplacementController.WrapperProuct skuWrap) {
        try{
            List<SKUNewReplacementController.SkuDrawerWrapperProduct> lstSkuDrawerWrapper = 
                new List<SKUNewReplacementController.SkuDrawerWrapperProduct>();
            Set<String> FieldApiFromMetadata = new Set<String>();
            if(skuWrap != NULL && skuWrap.productTypeSubTypeVsFieldMapping != NULL){
                if(skuWrap.productProductType != NULL && 
                skuWrap.productTypeSubTypeVsFieldMapping.containsKey(skuWrap.productProductType) && 
                skuWrap.productTypeSubTypeVsFieldMapping.get(skuWrap.productProductType) != NULL){
                    List<String> lstAttributeFields = 
                        skuWrap.productTypeSubTypeVsFieldMapping.get(skuWrap.productProductType).split(',');
                    Set<String> setAttributesfields = new Set<String>(lstAttributeFields);
                    FieldApiFromMetadata.addAll(setAttributesfields);
                }
                if(skuWrap.productSubType != NULL && 
                skuWrap.productTypeSubTypeVsFieldMapping.containsKey(skuWrap.productSubType) && 
                skuWrap.productTypeSubTypeVsFieldMapping.get(skuWrap.productSubType) != NULL){
                    List<String> lstAttributeFields = 
                        skuWrap.productTypeSubTypeVsFieldMapping.get(skuWrap.productSubType).split(',');
                    Set<String> setAttributesfields = new Set<String>(lstAttributeFields);
                    FieldApiFromMetadata.addAll(setAttributesfields);
                }
            }
            Map<String, String> newMap = new Map<String, String>();
            Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Schema.SObjectType sobjType = gd.get('SBQQ__QuoteLine__c');
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
            Map<String, String> mapPicklistLabelToController = new Map<String, String>();
            Set<String> setPicklistFields = new Set<String>();
            Integer ints = 1;       		
            if(!FieldApiFromMetadata.isEmpty()){
                for(String st : FieldApiFromMetadata){
                    Map<String, Map<String, String>> mapContDependantValue = new Map<String, Map<String, String>>();
                    SKUNewReplacementController.SkuDrawerWrapperProduct wpSku = 
                        new SKUNewReplacementController.SkuDrawerWrapperProduct();
                    Schema.SObjectField field = MapofField.get(st);
                    Schema.DescribeFieldResult fr = field.getDescribe();
                    if(String.ValueOf(fr.getType()) == 'PICKLIST'){
                        if(String.ValueOf(fr.getController()) != null){
                                mapContDependantValue = 
                                    getGlobalPickList(ReplacementConstants.QUOTELINE_OBJ_API,String.ValueOf(fr.getController()),fr.getName());
                                wpSku.mapControllerValueToDependantLabelValue = mapContDependantValue;                                 	
                                Map<String, String> mapDependant = new Map<String, String>();
                                mapDependant.put(fr.getName(), String.ValueOf(fr.getController()));
                                wpSku.mapDependantControllerLabel = mapDependant;
                                wpSku.pickValues = getPickListEntries(fr,mapContDependantValue, true, skuWrap);	                                	
                        }else{
                            wpSku.pickValues = getPickListEntries(fr,mapContDependantValue, false, skuWrap);
                        }
                    }                
                    wpSku.fieldLabel = fr.getLabel(); 
                    wpSku.fieldApiName = fr.getName();
                    if(String.ValueOf(fr.getType()) == 'PICKLIST'){
                        wpSku.PickListType = true;
                    }else if(String.ValueOf(fr.getType()) == 'DOUBLE'){
                        wpSku.IntegerDoubleType = true;
                        wpSku.formatterValue = 'decimal';
                        wpSku.stepValue = fr.getScale() == 0 
                            ? String.ValueOf(fr.getScale()) : '0'+'.'+calculateStepValue(fr.getScale());
                    }else if(String.ValueOf(fr.getType()) == 'CURRENCY'){
                        wpSku.currencyType = true;
                        wpSku.formatterValue = 'currency';
                        wpSku.stepValue = fr.getScale() == 0 
                            ? String.ValueOf(fr.getScale()) : '0'+'.'+calculateStepValue(fr.getScale());
                    }else if(String.ValueOf(fr.getType()).contains('STRING') || String.ValueOf(fr.getType()).contains('TEXT')){
                        wpSku.TextType = true;
                    }
                    wpSku.fieldType = String.ValueOf(fr.getType());
                    wpSku.scaleValue = fr.getScale();
                    wpSku.precisionValue = fr.getPrecision();
                    wpSku.lengthOfTextField = fr.getLength();
                    wpSku.skuRowCustomIndex = ints+'.'+0;
                    ints = ints+1;
                    lstSkuDrawerWrapper.add(wpSku);
                } 
            }                 
            return lstSkuDrawerWrapper;
        } catch(exception ex){
            Custom_Error_Log__c CaptureError = 
                new Custom_Error_Log__c(Class__c='SkuNewReplacementController',
                                        Functionality__c='getSchemaFieldsForQuoteLine Method failed',
                                        Exception_Message__c=ex.getMessage());
            insert CaptureError;
            throw ReplacementQuoteLineCreationHelper.handleException(ex);
        }
      }
    
     /***********************************************************************************************************
      * Method Name          : getGlobalPickList
      * Date Created/Modified: 10/04/2025
      * Author               : Rahul
      * @description         : This Method returns the Map collection of picklist values
      * Story                : FY25SR-1084
      * @return              : Map of Controlling to dependant values
      * @param 				   objName
      * @param 				   contField
      * @param 				   depField
  /**********************************************************************************************************/
     public static Map<String,Map<String, String>> getGlobalPickList(String objName, String contField, String depField){   
		Map <String,Map<String, String>> controllingInfo = new Map <String,Map<String, String>>();          
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
            
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(contField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(depField).getDescribe();
        List <Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List <Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
            
        for(Schema.PicklistEntry  currControllingValue: controllingValues) {
            controllingInfo.put(currControllingValue.getLabel(), new Map<String, String>());
        }
            
        for (Schema.PicklistEntry currDependentValue: dependentValues) {
            String jsonString = JSON.serialize(currDependentValue);
            PickListInfo info = (PickListInfo) JSON.deserialize(jsonString, PickListInfo.class);
        
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer baseCount = 0;
            for (Integer curr: hexString.getChars()) {
                Integer val = 0;
                if (curr >= 65){
                val = curr - 65 + 10;
                }
                else {
                val = curr - 48;
                }
                if ((val & 8) == 8) { 
                    controllingInfo.get(
                        controllingValues[baseCount + 0].getLabel())
                        .put(currDependentValue.getLabel(), currDependentValue.getValue());
                }
                if ((val & 4) == 4) {        
                    controllingInfo.get(
                        controllingValues[baseCount + 1].getLabel())
                        .put(currDependentValue.getLabel(), currDependentValue.getValue());
                }
                if ((val & 2) == 2) {
                    controllingInfo.get(
                        controllingValues[baseCount + 2].getLabel())
                        .put(currDependentValue.getLabel(), currDependentValue.getValue());
                }
                if ((val & 1) == 1) {
                    controllingInfo.get(
                        controllingValues[baseCount + 3].getLabel())
                        .put(currDependentValue.getLabel(), currDependentValue.getValue());
                } 
                baseCount += 4;
            }
        }
        
        return controllingInfo;
    }
     /***********************************************************************************************************
      * Method Name          : calculateStepValue
      * Date Created/Modified: 10/04/2025
      * Author               : Rahul
      * Story                : FY25SR-1084
      * @description         : This Method returns the String value of calculated scale value
      * @return              : String value of calculated scale value
      * @param 					scaleVal
  /**********************************************************************************************************/
    public static String calculateStepValue(Integer scaleVal) {
        String str = '1';
        for(integer i=1;i<scaleVal;i++){            
                str = '0' + str;
        }
        return str;
    }

    /***********************************************************************************************************
      * Method Name          : fetchNetworkTypeForAssetNonAsset
      * Date Created/Modified: 01/07/2025
      * Author               : Rahul
      * Story                : FY25SR-1705
      * @description         : This Method returns the picklist values of networkType for skuAssetNonAssetSelection component
      * @return              : Picklistvalues
  /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<ReplacementRefreshWrapperData.PickList> fetchNetworkTypeForAssetNonAsset(){
        List<ReplacementRefreshWrapperData.PickList> returnPickListValues = 
            new List<ReplacementRefreshWrapperData.PickList>();
        Replacement_Field_Mapping__mdt objectData1= 
            Replacement_Field_Mapping__mdt.getInstance('NE_Type_Picklist_one');
        Replacement_Field_Mapping__mdt objectData2= 
            Replacement_Field_Mapping__mdt.getInstance('NE_Type_Picklist_two');
        returnPickListValues.add(
            mapPicklistValues(objectData1.Picklist_Label__c,objectData1.Picklist_Value__c, false,0,'',''));
        returnPickListValues.add(
            mapPicklistValues(objectData2.Picklist_Label__c,objectData2.Picklist_Value__c, false,0,'',''));
        return returnPickListValues;
    }
    
    /***********************************************************************************************************
      * Method Name          : mapPicklistValues
      * Date Created/Modified: 22/05/2025
      * Author               : Rahul
      * Story                : FY25SR-1705
      * @description         : This Method returns the picklist values for skuAssetNonAssetSelection component
      * @return              : Picklistvalues
      * @param 					label
      * @param                  value   
      * @param 					selected
      * @param                  quantity  
      * @param 					sourceCustomIndex
      * @param                  sourceEntId
  /**********************************************************************************************************/
    public static ReplacementRefreshWrapperData.PickList mapPicklistValues(
            String label, String value, Boolean selected, Decimal quantity, String sourceCustomIndex, String sourceEntId){
        ReplacementRefreshWrapperData.PickList pick = new ReplacementRefreshWrapperData.PickList();
        pick.label  = label;
        pick.value  = value;
        pick.selected = selected;
        pick.quantity = quantity;
        pick.entCustomIndex = sourceCustomIndex;
        pick.entitlementId = sourceEntId;
        return pick;
    }
    
    /***********************************************************************************************************
      * Method Name          : getPickListEntries
      * Date Created/Modified: 10/04/2025
      * Author               : Rahul
      * @description         : This Method returns the List of picklist values
      * Story                : FY25SR-1084
      * @return              : List of picklist values
      * @param 					fr
      * @param 					mapControllerValueToDependantLabelValue
      * @param 					dependant
      * @param 					skuWrap
  /**********************************************************************************************************/
    public static List<PickList> getPickListEntries(
            Schema.DescribeFieldResult fr, 
            Map<String, Map<String, String>> mapControllerValueToDependantLabelValue, 
            Boolean dependant, SKUNewReplacementController.WrapperProuct skuWrap) {
        List<PickList> lstStr = new List<PickList>();
        if(dependant == false){
            List<Schema.PicklistEntry> lstPickEntry = fr.getPicklistValues();
            for(Schema.PicklistEntry sPick : lstPickEntry){
                PickList pick = new PickList();
                pick.label  = sPick.getLabel();
                pick.value  = sPick.getValue();
                pick.selected = false;
                lstStr.add(pick);
            }
        }else{
            if(skuWrap.productCodeType != NULL){
                if(mapControllerValueToDependantLabelValue.containsKey(skuWrap.productCodeType) && 
                    mapControllerValueToDependantLabelValue.get(skuWrap.productCodeType) != NULL){
                    Map<String,String> mapStr = new Map<String, String>();
                    mapStr = mapControllerValueToDependantLabelValue.get(skuWrap.productCodeType);
                    for(String str : mapStr.KeySet()){
                        PickList pick = new PickList();
                        pick.label  = str;
                        pick.value  = mapStr.get(str);
                        pick.selected = false;
                        lstStr.add(pick);
                    }
                }
            }
        }
        return lstStr;
    }
    
    /***********************************************************************************************************
     * Method Name          : mapProductCodeType
     * Date Created/Modified: 10 May 2024
     * Author               : Rahul
     * @description         : Wrapper for SKU data     
     * Story                : FY25SR-1084
     * @return              : Returns string of product code type
     * @param 					productType
     * @param 					productSubType
     * @param 					description
     * @param 					prodCode      
    
    /**********************************************************************************************************/
    public static String mapProductCodeType(
        String productType, String productSubType, String description, String prodCode) {        
        String returnedProdCode;
        if(productType == ReplacementConstants.CLOUD_VALUE_ARCHIVE && productSubType != ReplacementConstants.FEDRAMP){
            returnedProdCode = 'CVA';
        }else if(productType == ReplacementConstants.CLOUD_VALUE_ARCHIVE && productSubType == ReplacementConstants.FEDRAMP){
            returnedProdCode = 'CVAG';
        }else if(productType == ReplacementConstants.CLOUD_VALUE_BACKUP && productSubType != ReplacementConstants.FEDRAMP){
            returnedProdCode = 'CVB';
        }else if(productType == ReplacementConstants.CLOUD_VALUE_BACKUP && productSubType == ReplacementConstants.FEDRAMP){
            returnedProdCode = 'CVBG'; 
        }else if((productType == ReplacementConstants.M365H && description.contains(ReplacementConstants.FIFTY_GB)) ||
                    (productType == ReplacementConstants.MH50_VALUE && description.contains(ReplacementConstants.FEGB50_VALUE)) ||
                    (productType == ReplacementConstants.MDX_VALUE && description.contains(ReplacementConstants.FIFTY_GB))){
            returnedProdCode = 'M365X'; 
        }else if((prodCode.contains(ReplacementConstants.MH_VALUE) && description.contains(ReplacementConstants.FEGB_VALUE)) || 
                prodCode.contains(ReplacementConstants.M365H) || prodCode.contains(ReplacementConstants.MD_VALUE) || prodCode.contains(ReplacementConstants.MDG_VALUE)){            
            returnedProdCode = 'M365';
        }        
		return returnedProdCode;        
    }
        
    /***********************************************************************************************************
     * Method Name          : WrapperProuct
     * Date Created/Modified: 10 May 2024
     * Author               : Rahul
     * @description              : Wrapper for SKU data     
     * @return            :   
     * @param        
     * Test Class Methods   : 
    /**********************************************************************************************************/
    public class WrapperProuct {
        /**
        * @description WrapperProuct constructor of SKU
        */
        public WrapperProuct() {
        		parentMetadataMapping = new Map<String, Object>();
    	}
         /***********************************************************************************************************
             * Method Name          : setField
             * Date Created/Modified: 10 May 2024
             * Author               : Rahul
             * @description         : Wrapper for SKU data     
             * @param 					key
             * @param 					value
             * @param 					Parent
         /**********************************************************************************************************/
        public void setField(String key, Object value, Boolean Parent) {
            if(Parent == true){
                parentMetadataMapping.put(key, value);
            }                 	
    	}        
        /**
        * @description parentMetadataMapping of SKU
        */
        @AuraEnabled public Map<String, Object> parentMetadataMapping { get; set; }
        /**
        * @description childMappingSKUattributes of SKU
        */
        @AuraEnabled public Map<String, String> childMappingSKUattributes { get; set; }
        /**
        * @description productName of SKU
        */
        @AuraEnabled public String productName{get; set;}
        /**
        * @description productId of SKU
        */
        @AuraEnabled public String productId {get; set;}
        /**
        * @description productEdition of SKU
        */
        @AuraEnabled public String productEdition{get; set;}
        /**
        * @description productReplacementCategory of SKU
        */
        @AuraEnabled public String productReplacementCategory{get; set;}
        /**
        * @description productDescription of SKU
        */
        @AuraEnabled public String productDescription{get; set;}
        /**
        * @description productLicenseType of SKU
        */
        @AuraEnabled public String productLicenseType{get; set;}
        /**
        * @description productProductType of SKU
        */
        @AuraEnabled public String productProductType{get; set;}
        /**
        * @description productSubType of SKU
        */
        @AuraEnabled public String productSubType{get; set;}
        /**
         * 
        * @description productCodeType of SKU
        */
        @AuraEnabled public String productCodeType {get; set;}
        /**
        * @description productLicenseCategory of SKU
        */
        @AuraEnabled public String productLicenseCategory{get; set;}
        /**
        * @description productLicenseSubCategory of SKU
        */
        @AuraEnabled public String productLicenseSubCategory{get; set;}
        /**
        * @description productPaymentOption of SKU
        */
        @AuraEnabled public String productPaymentOption{get; set;}
        /**
        * @description productSupportType of SKU
        */
        @AuraEnabled public String productSupportType {get;set;}
        /**
        * @description customIndex of SKU
        */
        @AuraEnabled public String customIndex {get; set;}   
        /**
        * @description dispositionReason of SKU
        */  
        @AuraEnabled public String dispositionReason{get; set;}
        /**
        * @description isRowSelected of SKU
        */
        @AuraEnabled public Boolean isRowSelected{get; set;}
        /**
        * @description isHardWareProduct of SKU
        */
        @AuraEnabled public Boolean isHardWareProduct{get; set;}
        /**
        * @description showSelectCheckBox of SKU
        */
        @AuraEnabled public Boolean showSelectCheckBox { get; set; }
        /**
        * @description errors related to SKU
        */
        @AuraEnabled public String errors {get; set;}
        /**
        * @description mapUpgradeMapping related to SKU
        */
        @AuraEnabled public Map<String, String> mapUpgradeMapping {get; set;}        
        /**
        * @description attributeEligibleCheck related to SKU
        */
        @AuraEnabled public Boolean attributeEligibleCheck {get; set;}
        /**
        * @description showAttributeSection related to SKU
        */
        @AuraEnabled public Boolean showAttributeSection {get; set;}
        /**
        * @description productTypeSubTypeVsFieldMapping related to SKU
        */
         @AuraEnabled public Map<String, String> productTypeSubTypeVsFieldMapping {get; set;}        
        /**
        * @description  sourceToDestinationMatrix related to SKU
        */
         @AuraEnabled public List<String> sourceToDestinationMatrix {get; set;}
         /**
        * @description  anyToAnyFlag related to SKU
        */
         @AuraEnabled public Boolean anyToAnyFlag {get; set;}
          /**
        * @description  hardwareNotRequiredForHybrid related to SKU
        */
         @AuraEnabled public Boolean hardwareNotRequiredForHybrid {get; set;}
         /**
        * @description pathFromSKU related to SKU
        */
       	 @AuraEnabled public String pathFromSKU { get; set; }  //FY25SR-1705
         /**
        * @description showAssets related to SKU
        */
       	//  @AuraEnabled public Boolean pathEligible { get; set; }
        /**
        * @description showAssets related to SKU
        */
       	 @AuraEnabled public Boolean showAssets { get; set; } //FY25SR-1705
         /**
        * @description multiAddAssets related to SKU
        */
       	 @AuraEnabled public Boolean multiAddAssets { get; set; } //FY25SR-1705
        /**
        * @description pathAssetSelected related to SKU
        */
       	 @AuraEnabled public List<ReplacementRefreshWrapperData.PickList> pathAssetSelected { get; set; } //FY25SR-1705
         /**
        * @description doNotConsolidateSKU related to SKU
        */
       	 @AuraEnabled public Boolean doNotConsolidateSKU { get; set; } //FY25SR-1705
         /**
        * @description enablePaymentSwitchRE related to SKU
        */
       	 @AuraEnabled public Boolean enablePaymentSwitchRE { get; set; } //CPQ22-5975

    }     
    
    /***********************************************************************************************************
     * Method Name          : PickList
     * Date Created/Modified: 10 May 2024
     * Author               : Rahul
     * Story                : FY25SR-1084
     * @description              : PickList for Wrapper of SKU data     
     * @return            :   
     * @param        
     * Test Class Methods   : 
    /**********************************************************************************************************/
    public class PickList { 
       /**
        * @description Value
        */
       @AuraEnabled
       public String value { get; set; }
       /**
        * @description label
        */
       @AuraEnabled
       public String label { get; set; }
       /**
        * @description selected
        */
       @AuraEnabled
       public Boolean selected { get; set; }
       /**
        * @description valueProcessed
        */
       @AuraEnabled
       public Boolean valueProcessed { get; set; }
     }
    
    /***********************************************************************************************************
     * Method Name          : SkuDrawerWrapperProduct
     * Date Created/Modified: 10/04/2025
     * Author               : Rahul
     * Story                : FY25SR-1084
     * @description         :Wrapper for Drawer component   
     * Test Class Methods   : 
    /**********************************************************************************************************/
    public class SkuDrawerWrapperProduct {
        /**
        * @description skuRowCustomIndex Value
        */
        @AuraEnabled public String skuRowCustomIndex { get; set; }
        /**
        * @description fieldLabel Value
        */
        @AuraEnabled public String fieldLabel { get; set; }
        /**
        * @description fieldValue
        */
        @AuraEnabled public String fieldValue { get; set; }
        /**
        * @description fieldApiName Value
        */
        @AuraEnabled public String fieldApiName { get; set; }
        /**
        * @description fieldType Value
        */
        @AuraEnabled public String fieldType { get; set; }
        /**
         * @description PickListType Value
         * */
        @AuraEnabled public Boolean PickListType { get; set; }
        /**
         * @description IntegerDoubleType Value
         * */
        @AuraEnabled public Boolean IntegerDoubleType { get; set; }
        /**
         * @description currencyType
         * */
        @AuraEnabled public Boolean currencyType { get; set; }
        /**
        * @description formatterValue
        */
        @AuraEnabled public String formatterValue { get; set; }
        /**
        * @description stepValue Value
        */
        @AuraEnabled public String stepValue { get; set; }
       /**
         * @description TextType Value
         * */
        @AuraEnabled public Boolean TextType { get; set; }
        /**
        * @description scaleValue Value
        */
        @AuraEnabled public Integer scaleValue { get; set; }
        /**
        * @description precisionValu Value
        */
        @AuraEnabled public Integer precisionValue { get; set; }
        /**
        * @description lengthOfTextField Value
        */
        @AuraEnabled public Integer lengthOfTextField { get; set; }
        /**
        * @description pickValues Value
        */
        @AuraEnabled public List<Picklist> pickValues { get; set; }
        /**
        * @description mapDependantControllerLabel
        */
        @AuraEnabled public Map<String, String> mapDependantControllerLabel { get; set; }
         /**
        * @description errorOccured
        */
        @AuraEnabled public Boolean errorOccured { get; set; }
        /**
        * @description errorMessage
        */
        @AuraEnabled public String errorMessage { get; set; }        
        /**
        * @description mapControllerValueToDependantLabel value 
        */
        @AuraEnabled public Map<String, Map<String, String>> mapControllerValueToDependantLabelValue { get; set; }       
    }
}