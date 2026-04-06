/***********************************************************************************************************
 * Class Name           : ReplacementQueryController
 * Date Created/Modified: 27/05/2024
 * Author               : Garima
 * @description         : This class is SOQL utility class which is used by all classes invloved in Replacement Framework.
 *                        Making queries on different objects and fetches data
                          Using Replacement_Field_Mapping__mdt metadata for filter criteria
 * Test Class           :
 /**********************************************************************************************************/
 public without sharing class ReplacementQueryController { 

    /***********************************************************************************************************
       * Method Name          : getPicklistValuesDispositionQuote
       * Date Created/Modified: 25/03/2025
       * Author               : Rahul
       * @description         : Fetches Disposition Reason Values for Manual depending on QuoteType
       * @return              : list of picklist value records
       * User Story           : FY25SR-1373
       * Test Class Methods   :
       * @param qType
       * @param drType
       /**********************************************************************************************************/
      @AuraEnabled(cacheable=true)
      public static List<SKUNewReplacementController.PickList> getPicklistValuesDispositionQuote(String qType, String drType) {
            List<Replacement_Field_Mapping__mdt> lstReasons = ReplacementQueryController.getDispositionReasons(qType);
            List<SKUNewReplacementController.PickList> lstPick = new List<SKUNewReplacementController.PickList>();
            if(!lstReasons.isEmpty()){
              for(Replacement_Field_Mapping__mdt repRec : lstReasons){
        if (drType == ReplacementConstants.MANUAL_TYPE) {
                      if (!repRec.Autoselected__c) { 
                          SKUNewReplacementController.PickList ps = new SKUNewReplacementController.PickList();
                          ps.value = repRec.Picklist_Value__c;
                          ps.label = repRec.Picklist_Label__c;
                          ps.selected = false;
                          lstPick.add(ps);
                      }
                  }
              }
            }
            return lstPick;
      } 
  
    /***********************************************************************************************************
       * Method Name          : getSMSScreenErrorMessages
       * Date Created/Modified: 11/03/2025
       * Author               : Shivani
       * @description         : Fetches the error messages for the SMS screen
       * @return              : list of SMS_Screen_Error_Messages__mdt records
       * Test Class Methods   :
       /**********************************************************************************************************/
      @AuraEnabled(cacheable=true)
      public static List<SMS_Screen_Error_Messages__mdt> getSMSScreenErrorMessages() {
    return [SELECT 
              Error_Message__c,
              Message_Label__c,
              DeveloperName
            FROM SMS_Screen_Error_Messages__mdt
              ];
      }
  
  /***********************************************************************************************************
    * Method Name          : getDisableBusinessLogic
    * Date Created/Modified: 20/06/2025
    * Author               : Shivani
   * @description         : Fetches the DisableBusinessLogic records for the SMS screen
    * @return              : list of ShGl_DisableBusinessLogic__c records
    * Test Class Methods   :
    /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Boolean getDisableBusinessLogic() {
        return ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId()).Disable_Validations_on_SMS_UI__c;
    }
  
  /***********************************************************************************************************
     * Method Name          : getR7kProducts
     * Date Created/Modified: 11/03/2025
     * Author               : Rahul
     * @description         : Fetches R7000 series products
     * @return              : list of Products records
     * Test Class Methods   :
     /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Product2> getR7kProducts() {
        List<Product2> lstEligibleProducts = new List<Product2>();
      Replacement_Field_Mapping__mdt objectData= getReplacementMetaData(ReplacementConstants.REPLACEMENT_R7_PRODUCT_MDT);
      String query = 'SELECT Id, Name,Family,Product_Type__c,RWD_Version__c,Product_NIC_Type__c,'
        + 'RWD_Hardware_Family__c, Refresh_Eligibility__c,Usable_Capacity__c, ProductCode FROM Product2 WHERE ' 
        + objectData.First_Filter_Criteria__c;
      lstEligibleProducts =  Database.Query(query.trim());
        return lstEligibleProducts;
    }

  /***********************************************************************************************************
     * Method Name          : getSmsPageSize
     * Date Created/Modified: 15/05/2025 - FY25SR-1374
     * Author               : Rahul
     * @description         : Fetches the pagesize for SMS UI Screen
     * @return              : Map<String, String>
     * Test Class Methods   :
     /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
  public static Map<String,String> getSmsPageSize() {
      Map<String, String> smsPageAndException = new Map<String, String>();
        Integer pageSize = 0;
      Replacement_Field_Mapping__mdt objectDataPage= getReplacementMetaData(ReplacementConstants.REPLACEMENT_PAGINATION_SIZE_MDT);
      if(objectDataPage.SMS_Page_Size__c != NULL){
        pageSize = Integer.ValueOf(objectDataPage.SMS_Page_Size__c);
        }
      smsPageAndException.put('pagesize', String.ValueOf(pageSize));

      String exceptionFound = 'mismatch notfound';
      Replacement_Field_Mapping__mdt objectDataExcep= getReplacementMetaData(ReplacementConstants.REPLACEMENT_MISMATCH_EXCLUDE);
      if(objectDataExcep.MismatchQuantitySkip__c	== true){
        exceptionFound = 'mismatch found';
      }
      smsPageAndException.put('mismatchexcep', exceptionFound);
      return smsPageAndException;
    }
    /***********************************************************************************************************
    * Method Name          : getLowerAndUpperBound
    * Date Created/Modified: 20/05/2025 - FY25SR-1745
    * Author               : Sumedha
    * @description         : Fetches the Lower Bound and Upper bound of Ary Criteria to be passed for SMS UI Screen
    * @return              : Custom Metadata record to be passed to the UI
  /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Replacement_Field_Mapping__mdt getLowerAndUpperBound() {
    Replacement_Field_Mapping__mdt objectData= getReplacementMetaData(ReplacementConstants.REPLACEMENT_FILTER_CRITERIA_MDT);
      return objectData;
    }
    
  /***********************************************************************************************************
    * Method Name          : getPreviousIbmData
    * Date Created/Modified: 05/04/2024
    *                      : 10 June 2024
    * Author               : SJ
    * @description         : Returns the JSON data for the IBM screen from RSC lines
    * @return              : List of ReplacementJson
    * @param quoteId
    * Test Class Methods   :
  /**********************************************************************************************************/
  @AuraEnabled
  public static List<ReplacementJson> getPreviousIbmData(String quoteId) {
    List<ReplacementJson> jsonToReturn = new List<ReplacementJson>();
    Set<String> fieldApiNames = new Set<String>();
    List<String> quotelineFields = new List<String>{
      'Id,SBQQ__RequiredBy__c', ReplacementConstants.REPLACEMENT_DETAILS_FIELD_API, 
      ReplacementConstants.QUOTE_LINE_TYPE_FIELD_API, ReplacementConstants.DISPOSITION_REASON_FIELD_API, 
      ReplacementConstants.SPECIAL_PROGRAM_FIELD_API, ReplacementConstants.PRODUCT_TYPE_FIELD_API,
      ReplacementConstants.PRODUCT_CODE_TYPE_FIELD_API, ReplacementConstants.SUPPORT_TYPE_FIELD_API,
      ReplacementConstants.PRODUCT_REPLACEMENT_CATEGORY_FIELD_API, ReplacementConstants.ENDDATE_FIELD_API};
    // Map objectMap;
    //Get metadata records for SBQQ_QuoteLine_c filter criteria 
    Replacement_Field_Mapping__mdt objectData= getReplacementMetaData(ReplacementConstants.REPLACEMENT_QUOTELINE_MDT);
    String whereClause= objectData.First_Filter_Criteria__c;
    fieldApiNames.addAll(fetchDeletionQuoteLineFields());
    fieldApiNames.addAll(getQuotelineFields());
    quotelineFields.addAll(new List<String>(fieldApiNames));
    fieldApiNames.add(ReplacementConstants.PRODUCT_CODE_TYPE_FIELD_API);
    fieldApiNames.add(ReplacementConstants.SUPPORT_TYPE_FIELD_API);
    fieldApiNames.add(ReplacementConstants.PRODUCT_REPLACEMENT_CATEGORY_FIELD_API);
    fieldApiNames.add(ReplacementConstants.ENDDATE_FIELD_API);
    List<String> detailObjectFields = new List<String>{'Id', Constants.QUOTELINE_FIELDAPI};
    //Added for FY25SR-1084 - END
    List<SBQQ__QuoteLine__c> quoteLines = 
      getQuoteLinesDetailsByQuoteId(quoteId, quotelineFields, detailObjectFields, Constants.APPROVAL_SNAPSHOT_CHILD_OBJ, whereClause);
    if(!quoteLines.isEmpty()){
      for (SBQQ__QuoteLine__c qLine : quoteLines) {
        if (qLine.Replacement_Details__c != null) {
          //FY25SR-1176 include refreshed HW Support
          ReplacementJson lineJson = 
            (ReplacementJson) JSON.deserialize(qLine.Replacement_Details__c, ReplacementJson.class);
          if((qLine.Quote_Line_Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL && (qLine.Disposition_Reason__c != ReplacementConstants.CONVERTED 
            && qLine.Disposition_Reason__c != ReplacementConstants.UPGRADED && (lineJson.mode!=NULL || qLine.Disposition_Reason__c == ReplacementConstants.REFRESHED)))
          || (qLine.Quote_Line_Type__c == ReplacementConstants.QUOTE_TYPE_NEW 
            && qLine.Product_Type__c != ReplacementConstants.HW_SUPPORT && String.isBlank(qLine.SBQQ__RequiredBy__c) && (qLine.Special_Program__c != ReplacementConstants.DISPOSE_REFRESH 
          || (qLine.Special_Program__c == ReplacementConstants.DISPOSE_REFRESH && qLine.Product_Type__c == ReplacementConstants.HARDWARE))) ) {
            //Added for FY25SR-1084 - Start
            jsonToReturn.add(recreateReplacementJson(qLine, lineJson, fieldApiNames));
            //Added for FY25SR-1084 - END
          }
        }
      }      
    }
    for(ReplacementJson json: getCPQPreviousIbmData(quoteId)) {
      jsonToReturn.add(json);
    }
    return jsonToReturn;
  }
  /***********************************************************************************************************
    * Method Name          : recreateReplacementJson
    * Date Created/Modified: 25/02/2025
    *                      : 
    * Author               : Ankita Varma
    * @description         : Recreate the JSON for Given Replacement Details
    * @return              : ReplacementJson
    * @param quoteLine
    * @param rJson
    * @param fieldApiNames
    * Test Class Methods   :
  /**********************************************************************************************************/
  private static ReplacementJson recreateReplacementJson(
      SBQQ__Quoteline__c quoteLine, ReplacementJson rJson, Set<String> fieldApiNames) {
    Map<String, String> dynamicFieldValuesMap = new Map<String, String>();
    ReplacementJson row = new ReplacementJson();
    if(rJson != null) {
      row.mode = rJson.mode;
      row.skuSelected = rJson.skuSelected;
      row.skuSelectedName = rJson.skuSelectedName;
      row.skuStorageTierVal = rJson.skuStorageTierVal;
      row.renLine = rJson.renLine;
      row.refreshCategoryId = rJson.refreshCategoryId;
      row.targetProductType = rJson.targetProductType;
      row.rowValues = rJson.rowValues;
      for(String fieldName : fieldApiNames) {
        if (fieldName.contains('.')) {
          // Handle relationship fields
          List<String> parts = fieldName.split('\\.');
          if (parts.size() == 2) {
              SObject relatedObj = quoteLine.getSObject(parts[0]);
              if (relatedObj != null && relatedObj.get(parts[1]) != null) {
                  dynamicFieldValuesMap.put(fieldName, String.valueOf(relatedObj.get(parts[1])));
              }
          }
        } else {
        if(quoteLine.get(fieldName) != null ) {
          dynamicFieldValuesMap.put(fieldName, String.valueOf(quoteLine.get(fieldName)));
        }
      }
      }
      //FY26WL-227 : Smart Approval - Start
      if(quoteLine.Approval_Snapshots__r != null && !quoteLine.Approval_Snapshots__r.isEmpty() 
        && quoteLine.Approval_Snapshots__r.size() > 0) {
          dynamicFieldValuesMap.put(Constants.PARAMETERNAME_SNAP ,quoteLine.Approval_Snapshots__r[0].Id);
      }
      //FY26WL-227 : Smart Approval - END
      row.dynamicFieldValues = dynamicFieldValuesMap;
    }
    
    return row;
  }
  /***********************************************************************************************************
    * Method Name          : getQuotelineFields
    * Date Created/Modified: 05/07/2025
    *                      : 
    * Author               : Ankita Varma
    * @description         : Recreate the JSON for Given Replacement Details
    * @return              : List of Quote line fields
    * Test Class Methods   :
  /**********************************************************************************************************/
  @AuraEnabled
  public static List<String> getQuotelineFields() {
    Set<String> quotelineFields = new Set<String>();
    List<String> quotelineFieldsList = new List<String>();
    List<Replacement_Field_Mapping__mdt> replacementFieldMapping = Replacement_Field_Mapping__mdt.getAll().values();
    for(Replacement_Field_Mapping__mdt rfm : replacementFieldMapping) {
      List<String> skuAttFields = new list<String>();
      if (rfm.SKU_Attribute_Fields__c != null && rfm.SKU_Attribute_Fields__c != '') {
        skuAttFields = rfm.SKU_Attribute_Fields__c.split(',');
      }
      if(!skuAttFields.isEmpty() && skuAttFields.size() > 0) {
        quotelineFields.addAll(skuAttFields);
      }
    }
    quotelineFieldsList.addAll(quotelineFields);
    return quotelineFieldsList;
  }
    /***********************************************************************************************************
      * Method Name          : getCPQPreviousIbmData
      * Date Created/Modified: 25/02/2025
      *                      : 
      * Author               : Ankita Varma
      * @description         : Returns the JSON data for the IBM screen from HW lines (Renew Later/At Risk)
      * @return              : List of ReplacementJson
      * @param quoteId
      * Test Class Methods   :
    /**********************************************************************************************************/
    @AuraEnabled
    public static List<ReplacementJson> getCPQPreviousIbmData(String quoteId) {
      List<ReplacementJson> jsonToReturn = new List<ReplacementJson>();
    for(CPQ_Disposition_Quote_Line__c qLine : 
          [SELECT Id, Replacement_Detail__c 
             FROM CPQ_Disposition_Quote_Line__c 
            WHERE Quote__c = :quoteId]){   
      if(qLine.Replacement_Detail__c == null)
          continue;
  
        ReplacementJson lineJson = (ReplacementJson) JSON.deserialize(qLine.Replacement_Detail__c, ReplacementJson.class);
        jsonToReturn.add(lineJson);
      }
      return jsonToReturn;
    }
    /***********************************************************************************************************
          * Method Name          : getMaxNumberQuoteLine
          * Date Created/Modified: 18/03/2025
          * Author               : Khushboo
          * @description         : This method fetches the MAX Quoteline number
          * @return              : MAX Quoteline number
          * @param qd
          * Test Class Methods   :
    /**********************************************************************************************************/
       public static Integer getMaxNumberQuoteLine(Id qd) {
           Integer num=0;
         for(AggregateResult ar : 
                [SELECT MAX(SBQQ__Number__c)numMax 
                   FROM SBQQ__Quoteline__c
                  WHERE SBQQ__Quote__c =:qd GROUP BY SBQQ__Quote__c limit 10]){
              Decimal maxNum = (Decimal)ar.get('numMax');  // Get the MAX value as a Decimal
              num = maxNum != null ? maxNum.intValue() : 0; // Convert Decimal to Integer (if not null)
           }
           return num;
       }
    /***********************************************************************************************************
      * Method Name          : getQuoteDetails
      * Date Created/Modified: 24/05/2024
      * Author               : Shivani
      * @description         : This method fetches the quote details
      * @return              : Quote Details
      * @param qd
      * Test Class Methods   :
    /**********************************************************************************************************/
    @AuraEnabled( cacheable=false )
    public static SBQQ__Quote__c getQuoteDetails(Id qd) {
      return [SELECT Id,
                    RWD_Deal_Ops_Exception__c,
                    SBQQ__PriceBook__c,               //FY25SR-1080
                    SBQQ__ExpirationDate__c,
                    Force_Recalculation__c,
                    Eligible_for_RCDM_T__c,
                    Is_Customer_Fully_Transitioned__c,Deal_Ops_Exception_RCDMT__c,
                    Selective_Account_Eligible_for_RCDM_T__c,Deal_Ops_Exception_AdHoc_RCDM__c,
                    RCDMT_EOL_Date__c,RCDMT_inRange__c,
                    CreatedDate,                       //FY25SR-1095
                    SBQQ__Type__c,                    //FY25SR-1080
                    Co_Term_Date__c,
                    SBQQ__PricebookId__c,             //FY25SR-1080
                    SBQQ__Account__c, Name, SBQQ__Account__r.Name, Credit_Calculation_Start_Date__c, //MS CPQ22-6072
                  Polaris_Region__c,				        //ITNPI-2901
				          RSC_Deployment__c,				        //ITNPI-2901
				          RBRK_NotSummaryVarCustomRuleId__c, //ITNPI-2901
                    SBQQ__Opportunity2__r.CloseDate,  //FY25SR-1095
                    SBQQ__Opportunity2__r.Aspen_Eligibility__c, SBQQ__Opportunity2__r.Override__c,
                    Polaris_Conversion__c, //FY25SR-1096
                    QuoteApprovalCategory__c, //FY25SR-1191
                  RWD_Sales_Rep_Exception__c, 
                  RWD_Deal_Ops_Exception_Justification__c, 
                  RWD_Sales_Rep_Exception_Justification__c,
                SBQQ__QuoteTemplateId__c,
                  (SELECT Id, Name, SBQQ__Quote__c FROM SBQQ__LineItemGroups__r),
                  (SELECT Id, Name, SBQQ__Quote__c, replacement_motion__c FROM SBQQ__LineItems__r),
                  (SELECT Id FROM Disposition_Quote_Lines__r)
              FROM SBQQ__Quote__c WHERE Id = :qd LIMIT 1];    
    }
  
    /***********************************************************************************************************
      * Method Name          : getQuoteLinesDetailsByQuoteId
      * Date Created/Modified: 10th June 2024
      * Author               : Ankita Varma
      * @description         : Returns all the Quote lines by Quote Id
      * @return              : List of Quote Lines added to the Quote.
      * @param quoteId
      * @param fieldSet
      * @param childFields
      * @param childObjectName 
      * @param whereClause
      * Test Class Methods   :
    /**********************************************************************************************************/
    public static List<SBQQ__QuoteLine__c> getQuoteLinesDetailsByQuoteId(String quoteId, List<String> fieldSet, List<String> childFields, String childObjectName, String whereClause) {
      String query = 'SELECT '+ String.join(fieldSet, ','); 
  
      if(childFields != null && !childFields.isEmpty()) {
        query += ' ,(SELECT '+ String.join(childFields, ',') + ' FROM '+ childObjectName +')';
      }
    query += ' FROM ' +ReplacementConstants.QUOTELINE_OBJ_API+' WHERE SBQQ__Quote__c= :quoteId';
      if(String.isNotBlank(whereClause)) {
        query += ' AND ' +whereClause;
      }
      return Database.query(query.trim());
    }
  
    /***********************************************************************************************************
      * Method Name          : createProductToPricebookEntryIdMap
      * Date Created/Modified: 24/05/2024
      * Author               : Shivani
      * @description         : This method fetches QuoteLineGroups from a quote
      * @return               : Returns Product Id and its associated PriceBookEntry
      * @param pricebookId
      * Test Class Methods   :
    /**********************************************************************************************************/
    public static Map<Id, Id> createProductToPricebookEntryIdMap(Id pricebookId) {
      Map<Id, Id> productPricebookEntryMap = new Map<Id, Id>();
  
      //Get metadata records for PriceBookEntry filter criteria
    Replacement_Field_Mapping__mdt objectData= getReplacementMetaData(ReplacementConstants.REPLACEMENT_PRICEBOOKENTRY_MDT);
      String whereClause= objectData.First_Filter_Criteria__c;
      
      String query= 'SELECT Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id = : pricebookId AND '+ whereClause;
      for(PricebookEntry entry : Database.Query(query.trim())){
        productPricebookEntryMap.put(entry.Product2Id, entry.Id);
      }
      return productPricebookEntryMap; 
    }
    /***********************************************************************************************************
    * Method Name          : getEntitlementsBasedonIds
    * Date Created/Modified: 24/05/2024
    * Author               : Shivani
    * @description         : This method fetches Entitlements Based on entitlement Id's
    * @return              : List of Entitlements based on Ids passed
    * @param selectedEntitlementIdSet
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static List<Entitlement> getEntitlementsBasedonIds(Set<Id> selectedEntitlementIdSet) {
      return [SELECT Id, Name,
                AssetId, Asset.Name,
                StartDate, EndDate,
              Asset.Product_Usable_Capacity__c, Asset.Order_Product_Name__c, Renewable__c,
              Product__c,  Subscription_Term__c,//FY25SR-2247
              Product__r.id, 
              Product__r.Name,
              Product__r.License_Type__c,
              Product__r.Product_Type__c,
              Product__r.Product_Subtype__c,
              Product__r.ProductCode,
              Product__r.License_Category__c,
              Product__r.License_Sub_Category__c,
              Product__r.Description,
              Product__r.Replacement_Category__c,
              Product__r.Edition__c,
                Product__r.SBQQSC__EntitlementConversion__c,
                Product__r.Product_Level__c,
              Product__r.Custom_POT__c,
                Order_Number__c,Order_Quantity__c,
                ContractLineItem.CPQ_Uplift__c,
                ContractLineItem.Total_Price_Without_Promo__c,
                ServiceContractId,ServiceContract.Name,
              ContractLineItemId,
              ContractLineItem.SBQQSC__OriginalQuoteLine__c,
                            ContractLineItem.Storage_Region_Bundle_FrontEnd__c,
                            ContractLineItem.Storage_Region_Bundle__c,
                            ContractLineItem.Storage_Tier__c,
                            ContractLineItem.Product_Code_Type__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Quantity__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_OEM__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Models_Gen__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Drive_Size__c,
                            ContractLineItem.TPH_Drive_Size__c,
                            ContractLineItem.TPH_Quantity__c,
                            ContractLineItem.TPH_OEM__c,
                            ContractLineItem.TPH_Models_Gen__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Rubrik_Hosted_M365_Quantity__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Atlassian_Quantity__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Salesforce_Quantity__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Dynamics_Quantity__c,
              				ContractLineItem.SBQQSC__OriginalQuoteLine__r.Google_WorkSpace_Quantity__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,
                            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,
                            ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c,
                            ContractLineItem.SBQQSC__Quantity__c, 
                            Asset.Product2.Add_on_Level__c,
                            Asset.Product2.Product_Subtype__c,
                            Product__r.Add_on_Level__c,
                            ContractLineItem.Product_SubType__c,
                            ContractLineItem.Product_Type__c,
                            ContractLineItem.SBQQSC__RenewalProductId__c,
                            ContractLineItem.SBQQSC__Product__c,
                            (
                            SELECT
                                Id,
                                Asset__c,
                                Asset__r.Name,
                                Entitlement__c,
                                Entitlement__r.Name,
                                Asset__r.Product_Usable_Capacity__c,
                                Asset__r.Order_Product_Name__c,
                                Asset__r.Product2.Add_on_Level__c,
                                Asset__r.Product2.Product_Subtype__c,
                                Entitlement__r.Product__r.Add_on_Level__c
                            FROM Scale_Entitlements__r
                              )
                FROM Entitlement WHERE Id IN: selectedEntitlementIdSet ORDER BY EndDate DESC];    
    }
  
    /***********************************************************************************************************
    * Method Name          : getProductsBasedonIds
    * Date Created/Modified: 24/05/2024
    * Author               : Shivani
    * @description         : This method fetches Products Based on Product Id's
    * @return              : List of Products based on Ids or Product Codes
    * @param selectedProductId
    * @param productCodes
    * Test Class Methods   :
    /**********************************************************************************************************/
            public static Map<Id, Product2> getProductsBasedonIds(Set<Id> selectedProductId, Set<String> productCodes) {
              if(productCodes!=null && productCodes.size()>0){
          return new Map<Id, Product2>([SELECT
                          Category__c,
                          Product_Level__c,
                          Product_Type__c,Product_Subtype__c,
                          RWD_Version__c,Support_Tier__c, Support_Type__c,
                          ProductCode,Product_Payment_Option__c,
                          Description,
                          Eligible_for_RCDM_T__c,
                                            License_Sub_Category__c,
                                            SBQQ__SubscriptionPricing__c,
                         After_Conversion_Product_Level__c,
                         SBQQ__RenewalProduct__c,Replacement_Category__c,IsHardwareNotRequiredForHybridLicense__c
                         ,Family, SBQQ__ConfigurationType__c //FY25SR-2385
                      FROM Product2
                   WHERE Id IN :selectedProductId 
                      OR ProductCode IN : productCodes 
                      OR (Product_Type__c = :ReplacementConstants.HW_SUPPORT 
                     AND Support_Tier__c !=null) 
                     OR Product_Type__c = :ReplacementConstants.ACCESSORIES
                      OR (Family= :ReplacementConstants.PRODUCTCODE_R7000 
                          AND Product_Type__c = :ReplacementConstants.HARDWARE)]);
              }else{
          return new Map<Id, Product2>([SELECT
                                              Category__c,
                                              Product_Level__c,
                                              Product_Type__c,Product_Subtype__c,
                                              RWD_Version__c,Support_Tier__c, Support_Type__c,
                                           ProductCode,Product_Payment_Option__c,
                                          Eligible_for_RCDM_T__c,
                                          Description,
                                          License_Sub_Category__c,
                                          SBQQ__SubscriptionPricing__c,
                                          After_Conversion_Product_Level__c,
                                          SBQQ__RenewalProduct__c,Replacement_Category__c,IsHardwareNotRequiredForHybridLicense__c
                                          ,Family, SBQQ__ConfigurationType__c //FY25SR-2385
                                        FROM Product2
                 WHERE Id IN: selectedProductId 
                    OR (Product_Type__c = :ReplacementConstants.HW_SUPPORT AND Support_Tier__c !=null) 
                    OR Product_Type__c = :ReplacementConstants.ACCESSORIES
                    OR (Family= :ReplacementConstants.PRODUCTCODE_R7000 
                        AND Product_Type__c = :ReplacementConstants.HARDWARE)]);
      }
    }
    
    /***********************************************************************************************************
    * Method Name          : getAssetsBasedonIds
    * Date Created/Modified: 24/05/2024
    * Author               : Shivani
    * @description         : This method fetches Products Based on Product Id's
    * @return              : Map of Ids vs Asset Records based on Ids
    * @param allAssetIds
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static Map<Id, Asset> getAssetsBasedonIds(Set<Id> allAssetIds) {
    return new Map<Id, Asset>( 
        [SELECT Id,
                                  Product2Id,
                                  Product2.Category__c,
                                  Product2.Product_Level__c,
                                  Product2.Product_Type__c,
                                Product2.Product_Subtype__c,
                                  Product2.RWD_Version__c,
                                  SerialNumber,
                                  Product2.Description,
                                  Product2.SBQQ__SubscriptionPricing__c,
                                  Product2.Sales_Comp_Category__c,
                                  Product_Usable_Capacity__c,
                                  SBQQSC__CurrentContractLineItem__c,
                                  SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__c, 
                                  SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c, 
                                  SBQQSC__CurrentContractLineItem__r.SBQQSC__Quantity__c,
                                  Support_Tier__c,Support_Type__c,Payment_Options__c,
                                  Product2.Add_on_Level__c,
                                  Product2.HW_Support_Tier__c, 
                                  (SELECT Id, AssetId, Product__c,
                        Product__r.Product_Type__c, 
                        Renewal_Category__c,ContractLineItemId,EndDate,
                                    Quantity__c,
                                    Asset.Product2.Add_on_Level__c,
                                    Product__r.Add_on_Level__c, entitlement_status__c
                                    FROM Entitlements)
                                FROM Asset
                                WHERE Id IN :allAssetIds]);
    }
      /***********************************************************************************************************
      * Method Name          : getExistingQuoteLineForDeletion
      * Date Created/Modified: 
      * Author               : Khushboo
      * @description         : Method to get the lines for deletion from the quote
      * @return              : List of Quote Lines for deletion
      * @param quoteId
      * @param modifiedEntitlements
      * @param modifiedSkuProductIds
      * @param modifiedAssetIds
      * @param sourceSKUPolarisMapping
      * @param modifiedOldSKUs
      * Test Class Methods   :
    /**********************************************************************************************************/
  public static List<SBQQ__QuoteLine__c> getExistingQuoteLineForDeletion(
    Id quoteId, Set<Id> modifiedEntitlements,Set<Id> modifiedSkuProductIds,
    Set<String> modifiedAssetIds, Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMapping,
    Set<Id> modifiedOldSKUs) {
        //FY25SR-1215 - Added sourceSKUPolarisMapping and modifiedOldSKUs
           List<SBQQ__QuoteLine__c> qlToDelete = new List<SBQQ__QuoteLine__c>();
           Set<Id> qliIDs =new Set<Id>();//to store all the entIds from qli replacement json.
    List<String> quotelineFields = new List<String>();
           //Get metadata records for SBQQ_QuoteLine_c_Deletion filter criteria   
           //FY25-1215 - Added Disposition_Reason__c, SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c,  Product_Level__c
    Replacement_Field_Mapping__mdt objectData= getReplacementMetaData(ReplacementConstants.REPLACEMENT_QUOTELINE_DELETION_MDT);
    String whereClause= objectData.First_Filter_Criteria__c;
    if(!String.isBlank(objectData.Quote_Line_API_Fields__c)) {
      quotelineFields.addAll(objectData.Quote_Line_API_Fields__c.split(','));
    }
    String additionalFields = quotelineFields.isEmpty() ? '' : ','+String.join(quotelineFields, ',');
    String query='SELECT Id, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Product__c, SBQQ__ProductCode__c, '
      + 'SBQQ__RequiredBy__r.SBQQ__Product__c,Replacement_Motion__c, Product_Level__c, '
      + 'SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c, Replacement_Details__c,'
      + 'SBQQ__RequiredBy__r.Replacement_Motion__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.Replacement_Motion__c, '//FY25SR-2385
      + 'Special_Program__c, Disposition_Reason__c, SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c'
      + additionalFields
      + ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId AND ' + whereClause;
      
    List<SBQQ__QuoteLine__c> queryQLI = Database.Query(query.trim());   
           if(queryQLI!=null && !queryQLI.isEmpty()){
               for (SBQQ__QuoteLine__c ql :queryQLI){
                //FY25SR-1215 Starts
        if(ql.Replacement_Details__c !=null) {//CPQ22-5929 
          ReplacementJson json = (ReplacementJson) JSON.deserialize(ql.Replacement_Details__c, ReplacementJson.class);//CPQ22-5929
                if (!modifiedOldSKUs.isEmpty()) {
                  for (Id oldId : modifiedOldSKUs) {
                    if (sourceSKUPolarisMapping.containsKey(oldId)) {
                      Polaris_SKU_Mapping_V2__c targetKSU = sourceSKUPolarisMapping.get(oldId);
              if(targetKSU != null && targetKSU.New_Product__r.Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE 
                && targetKSU.New_Product__r.License_Type__c != ReplacementConstants.LICENSE_TYPE_CONSUMPTION ) {
                        if (targetKSU.New_Product__c == ql.SBQQ__Product__c) {
                    // //CPQ22-5929 - start
                    for(ReplacementJson.RowDetail row : json.rowValues) {
                      if (modifiedEntitlements.contains(row.entId)) {
                          qliIDs.add(ql.id);
                        break;
                      }
                    } //CPQ22-5929 - end
                    // qliIDs.add(ql.id);
                  }
                        }
                      }
                    }
                  }
                }
                //FY25SR-1215 Ends
        if(ql.Special_Program__c != ReplacementConstants.DISPOSE_REFRESH){
          Boolean toDelete = false;
          if(ql.Replacement_Details__c !=null){
            ReplacementJson json = (ReplacementJson) JSON.deserialize(ql.Replacement_Details__c, ReplacementJson.class);
            if(json != null) {
              for(ReplacementJson.RowDetail row : json.rowValues) {
                               if (modifiedEntitlements.contains(row.entId)) {
                                   qliIDs.add(ql.id);
                                   break;
                               }
                           }
                       }
                       }
                     if(modifiedSkuProductIds!=null && modifiedSkuProductIds.size()>0){//added Khushboo
            if(modifiedSkuProductIds.contains(ql.SBQQ__Product__c)
                               || modifiedSkuProductIds.contains(ql.SBQQ__RequiredBy__r.SBQQ__Product__c)
                               || modifiedSkuProductIds.contains(ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c)){
                                   qliIDs.add(ql.id);
                               }
                       }
                   }
               }
               
               for (SBQQ__QuoteLine__c ql : queryQLI){
        if(ql.Special_Program__c != ReplacementConstants.DISPOSE_REFRESH){
          if(qliIDs.contains(ql.Id)){
            ReplacementJson json =String.isNotBlank(ql.Replacement_Details__c) ? (ReplacementJson) JSON.deserialize(ql.Replacement_Details__c, ReplacementJson.class):null;//added Khushboo
                           if (json != null) { 
                           for (ReplacementJson.RowDetail row : json.rowValues) {
                               modifiedEntitlements.add(row.entId);
                           }
                       }
                       }
                   }
                  }
            Set<Id> qlIdToDelete=new Set<Id>();//1663
               for (SBQQ__QuoteLine__c ql : queryQLI){
                   ReplacementJson json = String.isNotBlank(ql.Replacement_Details__c) ? (ReplacementJson) JSON.deserialize(ql.Replacement_Details__c, ReplacementJson.class) : null;
                   Boolean toDelete = false;
        if(ql.Special_Program__c != ReplacementConstants.DISPOSE_REFRESH){
                       if(ql.Replacement_Details__c !=null){
                        if (json != null) {
                          for (ReplacementJson.RowDetail row : json.rowValues) {
                               if (modifiedEntitlements.contains(row.entId)) {
                                   toDelete = true;
                                 qlIdToDelete.add(ql.Id);
                                   break;
                               }
                           }
                       }
                   }
        } else{//for Refresh lines
                       if(ql.Replacement_Details__c !=null){
                        if (json != null) {
                           for (ReplacementJson.RowDetail row : json.rowValues) {
                             if(row.selectedAsset != null && String.isNotBlank(row.selectedAsset)){
                               List<String> assets=row.selectedAsset.split(',');
                               for(String asseId: assets){
                                   if(modifiedAssetIds!=null && !modifiedAssetIds.isEmpty() && modifiedAssetIds.contains(asseId)){
                                       toDelete = true;
                                        qlIdToDelete.add(ql.Id);
                                       break;   
                                   }
                                }
                               }
                           }
                       }
                   }
                 }
                   if(toDelete){
                       qlToDelete.add(ql);
                      }
               }
             //Deletion for //1663
             if(qlIdToDelete!=null && !qlIdToDelete.isEmpty()){
                 for (SBQQ__QuoteLine__c ql :queryQLI){
                   if(ql.Replacement_Details__c ==null && 
                    (ql.Replacement_Motion__c!=null || 
                    (ql.SBQQ__RequiredBy__c!=null && qlIdToDelete.contains(ql.SBQQ__RequiredBy__c) && ql.SBQQ__RequiredBy__r.Replacement_Motion__c!=null) ||
                    (ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c!=null && qlIdToDelete.contains(ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c) 
                    && ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.Replacement_Motion__c!=null ) )//FY25SR-2385
                       ){
                           qlToDelete.add(ql);
                       }
                 }
             }
           }
           return qlToDelete;
       }
       
          /***********************************************************************************************************
            * Method Name          : getCpqDispositionLinesToDelete
            * Date Created/Modified:
            * Author               : Saket
            * @description         : Method to get the CPQ Disposition Quote Line records to be deleted
            * @return              : List of CPQ Disposition Lines which are scoped to delete
            * @param quoteId
            * @param modifiedEntitlements
            * Test Class Methods   :
          /**********************************************************************************************************/
          public static List<CPQ_Disposition_Quote_Line__c> getCpqDispositionLinesToDelete(String quoteId, Set<Id> modifiedEntitlements) {
            List<CPQ_Disposition_Quote_Line__c> toReturn = new List<CPQ_Disposition_Quote_Line__c>();
        
            for (CPQ_Disposition_Quote_Line__c cpqLine : [SELECT Id, Replacement_Detail__c, Quote__c FROM CPQ_Disposition_Quote_Line__c WHERE Quote__c =: quoteId]){
              if (cpqLine.Replacement_Detail__c != null) {
                ReplacementJson json = (ReplacementJson) JSON.deserialize(cpqLine.Replacement_Detail__c, ReplacementJson.class);
        
                if (json.rowValues != null) {
                  for (ReplacementJson.RowDetail row : json.rowValues) {
                    if (modifiedEntitlements.contains(row.entId)) {
                      toReturn.add(cpqLine);
                      break;
                    }
                  }
                }
              }
            }
            return toReturn;
          }
           
       /***********************************************************************************************************
      * Method Name          : getremainingEntIdsAfterDeletion
      * Date Created/Modified: 
      * Author               : Khushboo
      * @description         : Method to get the the set of entid after deletion of QLi and CPQ_Dispose lines.
      * @return              : Set of Entitlement Ids which are left after Quote Lines are deleted
      * @param quoteId
      * Test Class Methods   :
    /**********************************************************************************************************/
  public static Set<Id> getremainingEntIdsAfterDeletion(Id quoteId) {
    Set<Id> entIds =new Set<Id>();
    //FY25SR-1215 - Added SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c
    for(SBQQ__QuoteLine__c ql : 
        [SELECT Id, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Product__c, SBQQ__ProductCode__c, 
                SBQQ__RequiredBy__r.SBQQ__Product__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c, 
                Replacement_Details__c , SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c
           FROM SBQQ__QuoteLine__c 
          WHERE SBQQ__Quote__c =: quoteId 
            AND Replacement_Motion__c !=null 
            AND Special_Program__c != :ReplacementConstants.DISPOSE_REFRESH]){
              if(ql.Replacement_Details__c !=null){
              ReplacementJson json = (ReplacementJson) JSON.deserialize(ql.Replacement_Details__c, ReplacementJson.class);
              if (json != null) {
              for (ReplacementJson.RowDetail row : json.rowValues) {
               entIds.add(row.entId);
              }
            }
          }
          }
          
    for(CPQ_Disposition_Quote_Line__c cpqLine : 
        [SELECT Id, Replacement_Detail__c, Quote__c 
           FROM CPQ_Disposition_Quote_Line__c 
          WHERE Quote__c =: quoteId]) {
              if (cpqLine.Replacement_Detail__c != null) {
                  ReplacementJson json = (ReplacementJson) JSON.deserialize(cpqLine.Replacement_Detail__c, ReplacementJson.class);
                  if (json.rowValues != null) {
                      for (ReplacementJson.RowDetail row : json.rowValues) {
                          entIds.add(row.entId);
                      }
                  }
              }
          }
          return entIds;
      }
          /***********************************************************************************************************
          * Method Name          : getPolarisSKUMapping
          * Date Created/Modified: 27/05/2024
          * Author               : Garima
          * @description         : This method fetches Polaris_SKU_Mapping_V2__c Based on Id's
          * @return              : List of Polaris Mapping records
          /**********************************************************************************************************/
          public static List<Polaris_SKU_Mapping_V2__c> getPolarisSKUMapping() {
            //FY25SR-1215 - Added New_Product__r.Product_Level__c, New_Product__r.License_Type__c
              return [SELECT Id,
                                      Feature_Name_on_New_Product__c,
                                      New_Product__c,
                                      New_Product__r.Productcode,
                                      Old_Product__c,
                                      Old_Product__r.Productcode,
                  Old_Product__r.Custom_Renewal_Type__c, // ITNPI-3222
                                      New_Product__r.Eligible_for_RCDM_T__c,
                                      New_Product__r.Product_Type__c, 
                                      New_Product__r.Product_Subtype__c,
                                      Payment_Option__c,
                                      Quantity_Mapping_Type__c,
                                      Quantity_Ratio__c, 
                                      Support_Type__c,
                                      Support_Tier__c,
                                      New_Product__r.SBQQ__SubscriptionTerm__c,
                                      New_Product__r.Description,
                                      New_Product__r.Sales_Comp_Category__c,
                                      New_Product__r.Product_Level__c,
                                      New_Product__r.License_Type__c
              FROM Polaris_SKU_Mapping_V2__c 
             WHERE Old_Product__r.IsActive =true 
               AND New_Product__r.IsActive =true];
  }
        
          /***********************************************************************************************************
          * Method Name          : getMultiMappingList
          * Date Created/Modified: 27/05/2024
          * Author               : Garima
          * @description         : This method fetches Polaris_SKU_Mapping_V2__c Based on Id's
          * @return              : List of Multi Mapping Conversionn Records
          /**********************************************************************************************************/
          public static List<Multi_Mapping_V2_Conversion__c> getMultiMappingList() {
          //Get metadata records for Multi_Mapping_V2_Conversion_c filter criteria
    Replacement_Field_Mapping__mdt objectData= getReplacementMetaData(ReplacementConstants.REPLACEMENT_MULTI_MAPPING_V2_CONVERSION_MDT);
          String whereClause= objectData.First_Filter_Criteria__c;
          
         String query= 'SELECT Id, Pricing_Percent__c, Source_Product__c,Target_Product__c,Target_Product__r.product_type__c,'
                          + 'Payment_Option__c, After_Conversion_Product_Level__c, Support_Tier__c,'
                          + 'Support_Type__c,Feature_Name_on_New_Product__c,Option_Level__c FROM Multi_Mapping_V2_Conversion__c';
                        return Database.Query(query.trim());
        }
        
         /***********************************************************************************************************
        * Method Name          : getSkuReplacementPolicyGrid
        * Date Created/Modified: 05/06/2024
        * Author               : Garima
        * @description         : This method fetches Replacement_Policy_Grid_c based on Source Replacement Category
                             : Invoked from SKUNewReplacementController
        * @return              : List of Replacement Support Records
    /**********************************************************************************************************/
     public static List<Replacement_Support__c> getSkuReplacementPolicyGrid() {
      String query= 'SELECT Id,Name, Source_Replacement_Category__c, Target_Replacement_Category__c,'
        + 'Source_Edition__c,Target_Edition__c,Path__c, RecordTypeId FROM Replacement_Support__c '
        + 'WHERE Active__c = TRUE';
            return Database.Query(query.trim());
        }
      
  /*******************************************************************************************************************
  * Method Name          : getV2ProductIdsForRenewalV1
  * Date Created/Modified: 11/09/2025
  * Author               : Rahul Kappa
  * @description         : This Method fetches Polaris Mapping V2 products for renewal quote V1 product-- //FY25SR-2232
  * @return              : Set of V2 Product Id's;
  * @param oldProductId
  /********************************************************************************************************************/
  public static List<Polaris_SKU_Mapping_V2__c> getV2ProductIdsForRenewalV1(Id oldProductId){
        Replacement_Field_Mapping__mdt objectData = getReplacementMetaData(ReplacementConstants.RENEWAL_V1_QUERY);
        String query = 'SELECT ';
        query = query + objectData.First_Filter_Criteria__c + ' WHERE '+ objectData.Second_Filter_Criteria__c + ' =:oldProductId';
        List<Polaris_SKU_Mapping_V2__c> lstPolarisMapping = Database.Query(query.trim());
    return lstPolarisMapping;
  }
    
        /***********************************************************************************************************
      * Method Name          : getSkuProductData
      * Date Created/Modified: 05/06/2024
  * Author               : Rahul Kappa 
      * @description         : This method fetches Product data based on Replacement Category
                        : Invoked from SKUNewReplacementController - FY25SR-1084, 1081, 2232
    * @return retLstProd
      * @param exceptionFound
      * @param sProdRep
    * @param entData
  * @param setNewProductId
  * @param quoteDet
    **********************************************************************************************************/
  public static List<Product2> getSkuProductData(Boolean exceptionFound,Set<String> sProdRep,  
            ReplacementRefreshWrapperData.WrapperData entData, Set<Id> setNewProductId, SBQQ__Quote__c quoteDet) {
        List<Product2> retLstProd = new List<Product2>();
        Replacement_Field_Mapping__mdt objectData = getReplacementMetaData(ReplacementConstants.SKU_PRODUCT_QUERY);
        String baseQuery = 'SELECT Id, Name, Edition__c, Replacement_Category__c, Description, License_Type__c, Product_Type__c,Product_Level__c,'
         + 'ProductCode, Support_Type__c, License_Category__c, License_Sub_Category__c, Product_Code_Type__c, Product_Subtype__c,'
         + 'IsHardwareNotRequiredForHybridLicense__c, Product_Payment_Option__c, Family, SBQQ__ConfigurationType__c FROM Product2 WHERE ';
        
        String whereClause = objectData.First_Filter_Criteria__c;
        if(quoteDet.SBQQ__Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION &&
              entData.v1Product == false && entData.SrprodRepCategory != ReplacementConstants.NON_REPLACEABLE){
            whereClause = whereClause + objectData.Third_Filter_Criteria__c;
        }
        
        if (exceptionFound) { 
            whereClause = whereClause + objectData.Second_Filter_Criteria__c;
        } else {
            whereClause = whereClause + ' AND Replacement_Category__c IN :sProdRep';
        }
        if (entData.v1Product == true && !setNewProductId.isEmpty()) {
            whereClause = '(' + '('+whereClause+')' + ' OR (Id IN :setNewProductId AND isActive = true))';
        }
        // Final query 
        String finalQuery = baseQuery + whereClause + ' ORDER BY Name';
        
        List<Product2> lstProd = new List<Product2>();
        if(String.isNotBlank(finalQuery)){
            lstProd = Database.query(finalQuery.trim());
        }
        if (!lstProd.isEmpty()) {
            Set<Id> prodIds = new Set<Id>();
            for (Product2 p : lstProd) {
                prodIds.add(p.Id);
            }

            List<PricebookEntry> lstPbEntry = [
                SELECT Product2Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :quoteDet.SBQQ__PricebookId__c
            AND IsActive = true 
                  AND Product2Id IN :prodIds
            ];

            Set<Id> validProdIds = new Set<Id>();
            for (PricebookEntry pb : lstPbEntry) {
                validProdIds.add(pb.Product2Id);
              } 
          
            for (Product2 p : lstProd) {
                if (validProdIds.contains(p.Id)) {
                    retLstProd.add(p);
                    }
               }
        } 
        return retLstProd;
      }
      /***********************************************************************************************************
      * Method Name          : getEntitlementsDynamicQuery
      * Date Created/Modified: 14/06/2024
      * Author               : Rahul
      * @description         : This method fetches the Order Item Extension
                             : Invoked from CreditCalculation class
      * @return              : Returns Order Item Extension records
      * @param allSkuAttributes
      * @param qlId
    /**********************************************************************************************************/
    public static Map<String, String> getEntitlementsDynamicQuery(Set<String> allSkuAttributes, String qlId){
        Map<String, String> finalParentMap = new Map<String, String>();
    String query = 'SELECT Id,';
    for(String str : allSkuAttributes){
      query = query + str+',';
    }
    String finalQuery = query.removeEnd(',')+' FROM '+ReplacementConstants.QUOTELINE_OBJ_API+' WHERE ID = :qlId';
    List<SBQQ__QuoteLine__c> lstQuoteline = Database.Query(finalQuery.trim());
        if(lstQuoteline[0].Id != NULL){
            for (String fieldName : allSkuAttributes) {
                Object fieldValue = lstQuoteline[0].get(fieldName); // dynamically get the field value
                finalParentMap.put(fieldName, fieldValue != null ? String.valueOf(fieldValue) : null);
            }
        }         
      return finalParentMap;
    }

      /***********************************************************************************************************
        * Method Name          : getOrderItemExtensionCreditCal
        * Date Created/Modified: 14/06/2024
        * Author               : Garima
        * @description         : This method fetches the Order Item Extension
                               : Invoked from CreditCalculation class
        * @return              : Returns Order Item Extension records
        * @param orderLineIds
      /**********************************************************************************************************/
      public static List<Order_Item_Extension__c> getOrderItemExtensionCreditCal(List<Id> orderLineIds){
        //Get Order Line Extension
    Replacement_Field_Mapping__mdt objectData= getReplacementMetaData(ReplacementConstants.REPLACEMENT_CCORDERLITEMEXTENSTION_MDT);
    String whereClause= objectData.First_Filter_Criteria__c;
    String query = 'SELECT Id, Order_Line_ID__c,Credit_Calculation_Status__c,Per_DayQuantity_amount__c,'
      + 'Remaining_Amount__c, Order_Line_ID__r.EndDate, Order_Line_ID__r.ServiceDate FROM Order_Item_Extension__c '
      + 'WHERE '+ whereClause + ' AND Order_Line_ID__c IN: orderLineIds';
                      return Database.Query(query.trim());
      }
  
  /***********************************************************************************************************
    * Method Name          : getEntitlementData1
    * Date Created/Modified: 13/06/2024
    * Author               : Garima
    * @description         : This method fetches Entitlements based on NewReplacement LWC data
    * @return              : List of Entitlements associated with the Account
    * @param accountId
    * @param alreadySelEnt
  /**********************************************************************************************************/
  public static List<Entitlement> getEntitlementData1(String accountId, List<Id> alreadySelEnt) {
    //Get Entitlement data from Custom metadata
    Replacement_Field_Mapping__mdt objectData= getReplacementMetaData(ReplacementConstants.REPLACEMENT_ENTITLEMENT_MDT);
    String firstWhereClause= objectData.First_Filter_Criteria__c;
    String secondWhereClause= objectData.Second_Filter_Criteria__c;
    String thirdWhereClause= objectData.Third_Filter_Criteria__c;
    String renCategory = ReplacementConstants.PRODUCT_CATEGORY_RENEWED;
    String scaleMSP = ReplacementConstants.PRODUCT_SCALE_MSP;
    Date todaysDate = System.TODAY();
    String upgrade = ReplacementConstants.UPGRADE_VALUE;
    String refreshed = ReplacementConstants.REFRESHED;
    String query1 = 'SELECT Id, Name, AssetId, Asset.Name,StartDate,EndDate,Asset.Product_Usable_Capacity__c,'
      + 'Asset.Order_Product_Name__c, Asset.Product2.Name,Asset.Product2.RWD_Version__c,Asset.Product2.Product_Type__c,'
      + 'Asset.SBQQSC__CurrentContractLineItem__c,Asset.Product2.Family,Product__c,Product__r.Name,Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c,'
      + 'Product__r.Support_Type__c,Renewable__c,Product__r.License_Type__c,product__r.Product_Level__c,'
      + 'Product__r.Product_Type__c,Product__r.ProductCode,Product__r.License_Category__c,'
      + 'Product__r.License_Sub_Category__c,Product__r.Description,Product__r.Replacement_Category__c,'
      + 'product__r.After_Conversion_Product_Level__c,product__r.License_Subtype__c,Product__r.Edition__c,Product__r.Custom_POT__c,'
      + 'Product__r.Approval_Category__c,Product__r.SBQQ__SubscriptionPricing__c, '  //FY25SR-2388
      + 'Order_Number__c,Order_Quantity__c,ServiceContractId,Quantity__c,Status,Renewal_Category__c,'
      + 'Product__r.Product_Subtype__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,'
      + 'ServiceContract.Name,ServiceContract.ContractNumber,SBQQSC__AssetRootId__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,ContractLineItem.SBQQSC__Product__c,'
      + 'ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,'
      + 'ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,'
      + 'ContractLineItem.TPH_Drive_Size__c,ContractLineItem.TPH_Quantity__c,ContractLineItem.Licensing_Model__c,'
      + 'ContractLineItem.SBQQSC__OriginalQuoteLine__c,'
      + 'ContractLineItem.Product_Code_Type__c,ContractLineItem.Storage_Region_Bundle_FrontEnd__c,'
      + 'ContractLineItem.Storage_Region_Bundle__c,ContractLineItem.Storage_Tier__c,' 
      + 'ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_OEM__c,'
      + 'ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Models_Gen__c,'    
      + 'ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Drive_Size__c,'
      + 'ContractLineItem.SBQQSC__OriginalQuoteLine__r.TPH_Quantity__c,'
      + 'ContractLineItem.TPH_OEM__c,ContractLineItem.TPH_Models_Gen__c,ContractLineItem.Support_Type__c,'
      + 'ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,'
      + 'ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,'
      + 'ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,'
      + 'ContractLineItem.SBQQSC__RenewalProductId__c,Asset.Product2.Add_on_Level__c, '
      + 'Product__r.Add_on_Level__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,' 
      + 'ContractLineItem.Product_SubType__c, ContractLineItem.Product_Type__c,'
      + 'ContractLineItem.SBQQSC__QuoteLine__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,'
      + '(SELECT Id, Asset__c,Asset__r.Name,Entitlement__c,Entitlement__r.Name,'
        + 'Asset__r.SBQQSC__CurrentContractLineItem__c, Asset__r.Product_Usable_Capacity__c,'
        + 'Asset__r.Order_Product_Name__c,Asset__r.Product2Id, Asset__r.Product2.Name,'
        + 'Asset__r.Product2.RWD_Version__c,Asset__r.Product2.Product_Type__c,Asset__r.Product2.Add_on_Level__c,'
        + 'Entitlement__r.Product__r.Product_Level__c,Entitlement__r.Product__r.Product_Subtype__c,Entitlement__r.EndDate,'
        + 'Entitlement__r.Product__r.Add_on_Level__c, Asset__r.Product2.Family,Entitlement__r.Product__r.Product_Type__c,'
        + 'Type__c,Renewal_Category__c FROM Scale_Entitlements__r '
        + 'where (Renewal_Category__c = null OR Renewal_Category__c =: renCategory OR Renewal_Category__c =: refreshed) '
        + 'and Status__c !=\'Invalid\' ORDER BY Entitlement__r.EndDate ASC), '
      + '(Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate, '
      + 'Previous_Entitlement__r.Renewal_Category__c, Previous_Entitlement__r.EndDate, '
      + 'Previous_Entitlement__r.Product__r.Product_Type__c , Previous_Entitlement__r.Status, '
      + 'Previous_Entitlement__r.Product__r.Edition__c, Renewed_Entitlement__r.Name, '
      + 'Renewed_Entitlement__r.Status, Renewed_Entitlement__r.Product__r.Edition__c, Renewal_Category__c, '
      + 'Renewed_Entitlement__r.StartDate, Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate, '
      + 'Renewed_Entitlement__r.Product__r.Product_Type__c, Renewed_Entitlement__r.ContractLineItem.SBQQSC__QuoteLine__r.Special_Program__c ' 
      + ' FROM Entitlement_Links__r where Renewed_Entitlement__r.EndDate >= : todaysDate)'
      + ' FROM Entitlement WHERE AccountId = :accountId AND ContractLineItemId != null AND ';
        if(!alreadySelEnt.isEmpty()){
            query1 = query1 + ' Id NOT IN :alreadySelEnt AND ';
        }
       String query = query1 + firstWhereClause + ' '+ secondWhereClause + ' '+ thirdWhereClause+ ' ORDER BY EndDate ASC';
        
    return Database.Query(query.trim());
  }

      /***********************************************************************************************************
      * Method Name          : getDispositionReasons
      * Date Created/Modified: 04/03/2025
      * Author               : Sumedha
      * @description         : Gets the Disposition Reasons available for Renewals and Renewal+Expansion 
      * @return              : List of Disposition Reasons available
      * @param quoteType
      * Test Class Methods   : 
      /**********************************************************************************************************/
      @AuraEnabled(cacheable=true)
      public static List<Replacement_Field_Mapping__mdt> getDispositionReasons (String quoteType) {
    List<Replacement_Field_Mapping__mdt> lstOfReasons = 
      [SELECT Id, Autoselected__c, Picklist_Label__c, Picklist_Value__c, Quote_Type__c 
          FROM Replacement_Field_Mapping__mdt 
        WHERE Quote_Type__c = : quoteType];   
          return lstOfReasons;
      }

       /***********************************************************************************************************
    * Method Name          : getListOfProductTypeSubType
    * Date Created/Modified: 10/04/2025
    * Author               : Rahul
    * @description         : Gets the List of custom Metadata records where product type subtype is defined 
    * @return              : List of Product type/Subtype available
    * Test Class Methods   : 
    /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Replacement_Field_Mapping__mdt> getListOfProductTypeSubType() {
    List<Replacement_Field_Mapping__mdt> lstProductTypeSubType = 
      [SELECT Id, Product_Type_Sub_Type__c,SKU_Attribute_Fields__c,Excluded_Replacement_Category__c,DeveloperName,Product_Level__c 
          FROM Replacement_Field_Mapping__mdt 
        WHERE Product_Type_Sub_Type__c != NULL];   
    return lstProductTypeSubType;
  }

        /***********************************************************************************************************
        * Method Name          : getR7KProductOption
        * Date Created/Modified: 05/03/2025
        * Author               : Khushboo
        * @description         : This method fetches Product option of Support feature of R7000
        * @return              : Map of Product Options related to R7k
        /**********************************************************************************************************/
  public static Map<String, List<SBQQ__ProductOption__c>> getR7KProductOption(){
    Map<String, List<SBQQ__ProductOption__c>> productOptionMap = new Map<String, List<SBQQ__ProductOption__c>>();//CPQ22-6240
    Replacement_Field_Mapping__mdt objectData= getReplacementMetaData(ReplacementConstants.REPLACEMENT_PRODUCTOPTION_MDT);
    String whereClause= objectData.First_Filter_Criteria__c;
    String query='select id,SBQQ__ProductCode__c, SBQQ__OptionalSKU__c, Support_Type__c,'
      + 'Configured_SKU_ID__c,Configured_SKU_Name__c,Feature_Name__c from SBQQ__ProductOption__c where '
      + whereClause;
    for(SBQQ__ProductOption__c po:Database.Query(query.trim())) {
         String key = '';
         key += po.Configured_SKU_ID__c;
         key += (po.Feature_Name__c != ReplacementConstants.ACCESSORIES ? '-' + po.Support_Type__c : '');
         key += (po.Feature_Name__c != null && po.Feature_Name__c == ReplacementConstants.ACCESSORIES ? '-'+ReplacementConstants.ACCESSORIES : '');

        //CPQ22-6240
        if(key!=''){
        if (!productOptionMap.containsKey(key)) {
                productOptionMap.put(key, new List<SBQQ__ProductOption__c>());
            }
            // Add the accessory to the hardware's list of related accessories
        productOptionMap.get(key).add(po);
          }
      //productOptionMap.put(po.Configured_SKU_ID__c+'-'+po.Support_Type__c,po);//CPQ22-6240 - Commented above line and added logic to handle multiple product options for same config SKU Id with different support type
    //CPQ22-6240
    }
    return productOptionMap;
       }
       /***********************************************************************************************************
        * Method Name          : getQuoteDetails
        * Date Created/Modified: 24/05/2024
        * Author               : Shivani
        * @description         : This method fetches the quote details
        * @return              : List of Quotes and Quote Line details
        * @param quoteIds
      /**********************************************************************************************************/
      public static List<SBQQ__Quote__c> getQuoteandQLDets(Set<Id> quoteIds) {
        //FY25SR-1215 - Added SBQQ__Status__c, SBQQ__Type__c, Replacement_Motion__c
    return [SELECT Id, Name, SBQQ__Status__c, SBQQ__Type__c, RWD_Sales_Rep_Exception__c, 
                  RWD_Deal_Ops_Exception__c, RWD_Deal_Ops_Exception_Justification__c, 
                  RWD_Sales_Rep_Exception_Justification__c, 
                  (SELECT Id, CCLI__c,Product_Type__c, Product_Level__c, Replacement_Details__c, 
                          Quote_Line_Type__c, Disposition_Reason__c, SubscribedAssetNames__c, 
                          SBQQSC__RenewedContractLine__c, SBQQ__SubscriptionTerm__c,
                          SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__c,
                          SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Atlassian_Quantity__c,
                          SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Salesforce_Quantity__c,
                          SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Rubrik_Hosted_M365_Quantity__c,
                          SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Dynamics_Quantity__c,
                          SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQSC__RenewedContractLine__r.EndDate, Atlassian_Quantity__c,
                          SBQQSC__RenewedContractLine__r.SBQQSC__OriginalQuoteLine__r.Google_Workspace_Quantity__c,
                          Google_Workspace_Quantity__c,Salesforce_Quantity__c,Rubrik_Hosted_M365_Quantity__c,Dynamics_Quantity__c,
                          SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalTerm__c,
                          SBQQ__Quantity__c, SBQQ__OptionLevel__c, Replacement_Motion__c, 
                          Arroyo_Subsumed_Old_Contract_Line_Items__c, Special_Program__c,Arroyo_Subscribed_Asset_Name__c, 
                          SBQQ__ProductCode__c,SBQQ__Product__c,SBQQSC__RenewedContractLine__r.Licensing_Model__c,
                          SBQQ__Product__r.After_Conversion_Product_Level__c, SBQQ__Product__r.Product_Level__c , SBQQSC__RenewedContractLine__r.Product_Level__c
                          FROM SBQQ__LineItems__r WHERE 
                          Replacement_Motion__c = NULL AND SBQQ__Product__r.Product_Level__c != :ReplacementConstants.HARDWARE 
                          AND SBQQ__Product__r.After_Conversion_Product_Level__c != :ReplacementConstants.HARDWARE
                     ) 
              FROM SBQQ__Quote__c 
             WHERE Id IN : quoteIds];
    }

    /***********************************************************************************************************
    * Method Name          : fetchExceptions
    * Date Created/Modified: 03/06/2025
    * Author               : Ankita
    * @description         : FY25SR-1745 : This method fetches the list of exceptions for the logged in user
    * @return              : List of Exceptions
    * @param                profileName
  /**********************************************************************************************************/
  @AuraEnabled(cacheable=true)
  public static SMS_Exceptions_Owner__mdt fetchExceptions(String profileName) {
    SMS_Exceptions_Owner__mdt exceptions = new SMS_Exceptions_Owner__mdt();
    for(SMS_Exceptions_Owner__mdt result : SMS_Exceptions_Owner__mdt.getAll().values()) {
      if(result.Profile_Name__c != null 
        && result.Profile_Name__c.equalsIgnoreCase(profileName) 
        && !String.isBlank(result.Exception_Message__c)) {
        exceptions = result;
      }
    }
    return exceptions;
  }
  /***********************************************************************************************************
    * Method Name          : fetchProfileName
    * Date Created/Modified: 03/06/2025
    * Author               : Ankita
    * @description         : FY25SR-1124 : Returns Profile Name
    * @return              : String
  /**********************************************************************************************************/
  public static String fetchProfileName() {
    Id currentUserProfileId = UserInfo.getProfileId();
    //Retrieve profile name
    return [SELECT Name 
              FROM Profile 
             WHERE Id =: currentUserProfileId].Name;
  }
  /***********************************************************************************************************
    * Method Name          : fetchPicklistValues
    * Date Created/Modified: 03/06/2025
    * Author               : Ankita
    * @description         : FY25SR-1124 : returns picklist values
    * @return              : List of String
    * @param                objectName
    * @param                fieldName
  /**********************************************************************************************************/
  public static List<String> fetchPicklistValues(String objectName, String fieldName) {
    List<String> picklistValues = new List<String>();
    Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName) ;
    Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
    Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
    Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for( Schema.PicklistEntry pickListVal : ple){
      picklistValues.add(pickListVal.getValue().trim().toLowerCase());
    }
    return picklistValues;
  }

  /***********************************************************************************************************
    * Method Name          : fetchBusinessLogicSetting
    * Date Created/Modified: 23/06/2025
    * Author               : Ankita
    * @description         : FY25SR-1874 : returns custom setting
    * @return              : ShGl_DisableBusinessLogic__c
  /**********************************************************************************************************/
  public static ShGl_DisableBusinessLogic__c fetchBusinessLogicSetting() {
    ShGl_DisableBusinessLogic__c setting;
    // 1. Try User-level setting
    setting = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if (setting.Id != null) {
        return setting;
    }
    // 2. Try Profile-level setting
    setting = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getProfileId());
    if (setting.Id != null) {
        return setting;
    }
    // 3. Try Org-wide default
    setting = ShGl_DisableBusinessLogic__c.getOrgDefaults();
    if (setting.Id != null) {
        return setting;
    }
    // Nothing found
    return null;
  }

  /***********************************************************************************************************
    * Method Name          : fetchExistingCPQDispLines
    * Date Created/Modified: 08/08/2025
    * Author               : Rahul( Story Number - FY25SR-2069 )
    * @description         : Returns Disp lines related to new quotes inserted by cloning existing ones
    * @param			   quoteIds
    * @return              : List<CPQ_Disposition_Quote_Line__c>
  /**********************************************************************************************************/
  public static List<CPQ_Disposition_Quote_Line__c> fetchExistingCPQDispLines(set<Id> quoteIds) { 
      Replacement_Field_Mapping__mdt objectData = getReplacementMetaData(ReplacementConstants.REPLACEMENT_CPQDISPOSE_QUOTEQUERY);
      String query = 'SELECT Id, Name,';
      String firstWhereClause= objectData.First_Filter_Criteria__c;
      String whereClause = ' FROM CPQ_Disposition_Quote_Line__c WHERE Quote__c IN :quoteIds';
      query = query + firstWhereClause + whereClause;
      List<CPQ_Disposition_Quote_Line__c> lstCpqLines = Database.query(query.trim());
      return lstCpqLines;
  }

  /***********************************************************************************************************
  * Method Name          : getReplacementMetaData
  * Date Created/Modified: 08/10/2025
  * Author               : Ankita
  * @description         : CPQ22-5954 - Replacement Field Mapping record
  * @param               metadataName
  * @return              : Replacement_Field_Mapping__mdt
  /**********************************************************************************************************/
  public static Replacement_Field_Mapping__mdt getReplacementMetaData(String metadataName) {
    return Replacement_Field_Mapping__mdt.getInstance(metadataName);
  }
  /***********************************************************************************************************
    * Method Name          : fetchDeletionQuoteLineFields
    * Date Created/Modified: 13/10/2025
    * Author               : Ankita Varma
    * @description         : Returns api Name of Quote line field from Metadata
    * @return              : List of Quote line fields
    * Test Class Methods   :
  /**********************************************************************************************************/
  @AuraEnabled
  public static List<String> fetchDeletionQuoteLineFields() {
    //Added for FY25SR-1084 - Start
    List<String> fieldApiNames = new List<String>();
    Replacement_Field_Mapping__mdt quotelineFieldsMdt= getReplacementMetaData(ReplacementConstants.REPLACEMENT_QUOTELINE_DELETION_MDT);
    if(!String.isBlank(quotelineFieldsMdt.Quote_Line_API_Fields__c)) {
      fieldApiNames.addAll(quotelineFieldsMdt.Quote_Line_API_Fields__c.split(','));
    }
    return fieldApiNames;
  }
        
  /***********************************************************************************************************
  * Method Name          : getReplacementMultiMapping
  * Date Created/Modified: 08/10/2025
  * Author               : lokesh
  * @description         : ITNPI-2901 
  * @param                 selectedProductIds
  * @param                 configSKU
  * @param                 OptionalSku
  * @return              : Map<String,Multi_Mapping_V2_Conversion__c>
  /**********************************************************************************************************/
  public static Map<String,Multi_Mapping_V2_Conversion__c> getReplacementMultiMapping(Set<Id> selectedProductIds,set<String> configSKU, Set<String> OptionalSku) {
		Map<String,Multi_Mapping_V2_Conversion__c> autoAddSKUMap = new Map<String,Multi_Mapping_V2_Conversion__c>();
		 String fields = String.join(new List<String>{
            'Id',
            'Option_Level__c',
            'Quantity_Multiplier__c',
            'Active__c',
            'Payment_Option__c',
            'Pricing_Percent__c',
            'Source_Product__r.ProductCode',
            'Source_Product__c',
            'Support_Type__c',
            'Renewal_Type__c',
            'Target_Product__c',
            'Target_Product__r.ProductCode',
            'Target_Product__r.Sales_Comp_Category__c',
            'Target_Product__r.Pricebook_Entry_Id__c',
            'Target_Product__r.Approval_Category__c'
        }, ',');

        // Start base query
        String soql = 'SELECT ' + fields +
                    ' FROM Multi_Mapping_V2_Conversion__c WHERE Source_Product__c IN :selectedProductIds AND Active__c = true';
        // Add Active filter if requested
       For(Multi_Mapping_V2_Conversion__c repSKU:Database.query(soql.trim())){ 
		   String Region = repSKU.renewal_type__c != null ? repSKU.renewal_type__c.substring(repSKU.renewal_type__c.indexOf('-') + 1).trim() : null;
		   String skuKey = repSKU.Source_Product__c + '-' + Region;
		   autoAddSKUMap.put(skuKey,repSKU);
		   configSKU.add(repSKU.Source_Product__c);
		   OptionalSku.add(repSKU.Target_Product__c);
	   }
	   return autoAddSKUMap;
      
  }
}