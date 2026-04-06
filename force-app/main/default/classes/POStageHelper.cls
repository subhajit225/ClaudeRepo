/**************************************************************************************************    
 * @description       : POStageHelper
 * @author            : Prashant Kumar
 ******************************************************************************/
public with sharing class POStageHelper {                 

    public static Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>(); 
    private static Map<String,Id> quoteNameIdMap = new Map<String,Id>();
    public static Map<Id,PO_Stage__c> allStagePOmap = new  Map<Id,PO_Stage__c>();
    public static set<id> validateQuote = new set<id>(); // ..holds quoteId if all the .corresponding po's are marked for staged.
    public static Map<id,PO_Stage__c> poStagesToUpdateMap = new Map<id,PO_Stage__c>();
    public static Set<Id> setIdStagePoShouldNotValidate = new Set<Id>();
    public static Map<String,String> errorCodeMap = new Map<String,String>();
    public static Order_control__mdt disableAspenForFlex = Order_control__mdt.getInstance('Disable_Aspen_For_Flex');
    private static final String INVALID_INDEX_EXPECTED_NUM_PO_ERROR_CODE = 'PO-30A';
    private static final String INVALID_INDEX_INDEX_GT_EXPECTED_NUM_PO_ERROR_CODE = 'PO-30C';
    private static final String INVALID_INDEX_ERROR_CODE = 'PO-30B';
    private static final String INVALID_INDEX_ROOT_ERROR_CODE = 'PO-30';
    private static final String DUPLICATE_STAGE_PO_ERROR_CODE = 'PO-31';
    private static final String PO_RECEIVED_FOR_ASPEN_NON_ARROYO_QUOTE = 'PO-33'; 
    private static final String MISSING_QUOTE_NUMBER_ON_STAGE_PO = 'PO-05';
    private static final String PREVALIDATE_ERROR_TYPE = 'External';
    private static final Map<String, String> SUB_ERRROR_CODE_MAP =  new Map<String, String> {
        INVALID_INDEX_EXPECTED_NUM_PO_ERROR_CODE => INVALID_INDEX_ROOT_ERROR_CODE,
        INVALID_INDEX_INDEX_GT_EXPECTED_NUM_PO_ERROR_CODE => INVALID_INDEX_ROOT_ERROR_CODE,
        INVALID_INDEX_ERROR_CODE => INVALID_INDEX_ROOT_ERROR_CODE
    };
    private static Map<Id,String> quoteToStagePoCMMap =  new Map<Id,String>();
    private static Map<Id,Map<Integer,Integer>> mapRwdQuoteIdMapIndexCountStagePos =  new Map<Id,Map<Integer,Integer>>();
    private static Map<Id,Map<Integer,Id>> mapRwdQuoteIdMapIndexIdSuccessPo =  new Map<Id,Map<Integer,Id>>();
    public static Map<Id, PO_Stage_Errors__c> mapStagePOIdPreValidateStagePoErrRwdQuote = new Map<Id, PO_Stage_Errors__c>();
    public static Set<Id> setIdStagePoDisorderedIndexes = new Set<Id>(); // This will be used to freeze Stage POs to Staged State
    public static Map<Id, PO_Stage_Address__c> mapPOStageAddr = new Map<Id, PO_Stage_Address__c>();//PRDOPS23-365 - External Validation for Wrong Email Id from Disti
    private static String getFinalErrorCode(String strErrorCode) {
        return SUB_ERRROR_CODE_MAP.containsKey(strErrorCode) ? SUB_ERRROR_CODE_MAP.get(strErrorCode) : strErrorCode;
    }

    private static Boolean checkForZeroIndexes(PO_Stage__c objStagePo){
        if((
            (objStagePo.Expected_number_of_POs__c != null && objStagePo.Expected_number_of_POs__c >= 1)  && 
            (objStagePo.PO_Index__c != null && objStagePo.PO_Index__c >= 1) 
        )){
            return true;
        }
        return false;
    }
    private static Boolean compareIndexes(PO_Stage__c objStagePo){
        if(objStagePo.Expected_number_of_POs__c >= objStagePo.PO_Index__c){
            return true;
        }
        return false;
    }
    @TestVisible
    private static Boolean isDisOrdered(PO_Stage__c objStagePo) {
        try {
            return (mapRwdQuoteIdMapIndexCountStagePos.get(objStagePo.Quote__c).get( (Integer) objStagePo.PO_Index__c) != 1);
        } catch (NullPointerException e){
            System.debug(LoggingLevel.FINEST, 'NullPointerException in isNotDisOrdered');
            return false;
        }
    }
    @TestVisible
    private static Boolean isDuplicate(PO_Stage__c objStagePo) { 
        try {
            return (
                (mapRwdQuoteIdMapIndexIdSuccessPo.get(objStagePo.Quote__c).containsKey((Integer) objStagePo.PO_Index__c)) && 
                (objStagePo.Id != mapRwdQuoteIdMapIndexIdSuccessPo.get(objStagePo.Quote__c).get( (Integer) objStagePo.PO_Index__c))
            );
        } catch (NullPointerException e){
            System.debug(LoggingLevel.FINEST, 'NullPointerException in isDuplicate');
            return true;
        }
    }

    private static String getPoValidationErrorMsg(String strErrorCode) {
        return (
            (mapErrCodeStrMsg.get(strErrorCode) != null)
            ? mapErrCodeStrMsg.get(strErrorCode).Error_Issue__c
            : System.Label.Generic_Validation_Error_Mgs);
    }
    private static PO_Stage_Errors__c createErrorRec(Id idStagePo, String strErrorCode) {
        String strErrorMessage = getPoValidationErrorMsg(strErrorCode);
        strErrorCode = getFinalErrorCode(strErrorCode);
        if(!(poStagesToUpdateMap.containsKey(idStagePo) && poStagesToUpdateMap.get(idStagePo).PO_Validation_Status__c == 'Failure')){
            poStagesToUpdateMap.put(idStagePo,new PO_Stage__c(Id = idStagePo, PO_Validation_Status__c = 'Failure'));
        }
        return new PO_Stage_Errors__c(
            Name = strErrorCode,
            Error_Code__c = strErrorCode,
            PO_Stage_Id__c = idStagePo,
            Error_Message__c = strErrorMessage,
            Error_Type__c = PREVALIDATE_ERROR_TYPE
        );
    }
    private static Boolean isHardware(List<PO_Item_Stage__c> lstPoItems){
        Boolean isHardware = false;
        for(PO_Item_Stage__c objPoitem : lstPoItems){
            if(objPoitem.ProductCode__c != null && (String.isNotBlank(objPoitem.Product__r.Appliance_Model_HW__c) || objPoitem.Product__r.Product_Type__c == 'Spares')){    
                isHardware = true;  
                break;    
            } 

        }
        return isHardware;
    }


        /**
  * @author Prashant Kumar
  * @date 05-03-2025
  * @description copy single stage PO details to order
  * @param stagePOList
  * @param newMap
  * @param oldMap
  * @param rerunExtVal
  */   
     public static void init(List<PO_Stage__c> stagePOList,map<id,PO_Stage__c> newMap,map<id,PO_Stage__c> oldMap,Boolean rerunExtVal){ 
        getValidationCodeData();
        set<string> quoteNames = new set<string>(); 
        set<id> TrgrStagedQuoteId = new set<id>();
        set<string> validStages = new set<string>{'Staged','Success','Success - 855 Sent','Order Accepted','Order Accepted - 855 Sent'};
        Map<string,integer> quote_ExpActStagePOs = new map <string,integer>(); // expectedstagepo vs actual stage po (quoteId-expectednumber,receivedpo's)
        Map<String,Decimal> quotePoindexMap =  new Map<String,Decimal>(); // added for PRDOPS24-821
        for(PO_Stage__c poStage : stagePOList){
            if(poStage.Quote_number__c != null){
                quoteNames.add(poStage.Quote_number__c);   
            }
        }
        system.debug(LoggingLevel.DEBUG, 'quoteNames' + quoteNames);
        if(quoteMap.isEmpty()){
            for(SBQQ__Quote__c quote : [select id,Credit_Calculation_Start_Date__c, name, SBQQ__LineItemCount__c, SBQQ__Primary__c, SBQQ__Status__c,SBQQ__PaymentTerms__c, SBQQ__NetAmount__c, SBQQ__Account__c,SBQQ__ExpirationDate__c,SBQQ__Opportunity2__r.Ownerid,SBQQ__Opportunity2__r.Owner.Email,SBQQ__Opportunity2__r.Opportunity_Sub_Type__c,SBQQ__Opportunity2__c,SBQQ__Type__c,Payment_year_2__c,MSP_SKUs_Count__c, Is_RWD_Polaris_Quote__c, ProcessType__c,
                                    Is_Conditional_PO__c,Legal_Approved_Verbiage__c,Scale_Quote__c, Quoting_Desk_Exception__c,
                                    (select Id,Prepayment_Credit__c,SBQQ__Product__r.Bundle_Features__c,SBQQ__Product__r.Product_Level__c,SBQQ__Product__r.Name ,SBQQ__Quote__c, SBQQ__NetTotal__c,SBQQ__NetPrice__c,SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__SubscriptionTerm__c,SBQQ__Product__r.IsHardwareNotRequiredForHybridLicense__c, SBQQ__Product__r.Product_Subtype__c,SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c,SBQQ__Product__r.Appliance_Model_HW__c, SBQQ__Product__r.Product_Type__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c,SBQQ__RequiredBy__r.SBQQ__ProductCode__c,SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,
                                    Special_Program__c,Line_Type__c,SBQQ__RequiredBy__r.Payment_Options__c,SBQQ__Product__r.Usable_Capacity__c,SBQQ__Product__r.Product_Payment_Option__c,SBQQ__Product__r.SBQQ__Optional__c,SBQQ__Optional__c,SBQQ__RenewedAsset__c,SBQQ__Quote__r.SBQQ__Type__c,Name,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.Name,SBQQ__Bundle__c,SBQQ__Existing__c,SBQQ__UpgradedAsset__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,SBQQ__Product__r.Family,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Family,SBQQ__RequiredBy__r.SBQQ__Product__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Family,SBQQ__Quote__r.ProcessType__c  from SBQQ__LineItems__r order by SBQQ__Number__c) 
                                    from SBQQ__Quote__c where name IN: quoteNames]){ 
            quoteMap.put(quote.id,quote);
            //system.debug(LoggingLevel.DEBUG,'quote lines'+JSON.serialize(quoteMap.get(quote.id).SBQQ__LineItems__r)); 
            quoteNameIdMap.put(quote.name,quote.id);
            mapRwdQuoteIdMapIndexCountStagePos.put(quote.Id, new Map<Integer, Integer>());
            mapRwdQuoteIdMapIndexIdSuccessPo.put(quote.Id, new Map<Integer, Id>());
          }
        }
        for(PO_Stage__c po: stagePOList){ 
            if(po.Customer_Requested_Ship_Date__c != null && po.Customer_Requested_Ship_Date__c.length() == 8){
              String year = po.Customer_Requested_Ship_Date__c.substring(0,4);
              String month = po.Customer_Requested_Ship_Date__c.substring(4,6);
              String day = po.Customer_Requested_Ship_Date__c.substring(6,8);
      
              po.Customer_Requested_Ship_Date__c = year + '-' + month + '-' + day; 
            }
        }
        
        if((allStagePOmap.isEmpty() && newMap != null && oldMap!= null) || rerunExtVal) {
            for(PO_Stage__c stgpo : [SELECT Id,Payment_Terms__c,Payment_schedule_type__c,Note_on_Contingency_and_Special_Language__c, ShippingStateCode__c,ShippingPostalCode__c,ShippingCity__c,ShippingStreet__c,Shipping_Method__c,Bill_To_Name_Str__c,Partner_Email__c,Customer_Requested_Ship_Date__c,ShippingCountryCode__c,Ship_To_Phone_Number__c,Ship_To_Contact_Name__c,End_User_PO__c,Account_name__c,ContractManufacturer__c,PoNumber__c,opportunity__c,EDI_DISTI_ID__c,Name,PO_Internal_Validation_Status__c,PO_Validation_Status__c,Expected_number_of_POs__c,PO_Index__c,Bill_To_Name__c,Bill_To_Name__r.Payment_Term__c,Quote__c, Quote_number__c,TotalAmount__c,Quote__r.Name,Quote__r.ProcessType__c,Quote__r.SBQQ__Type__c,Quote__r.Opportunity_Program__c,Quote__r.Scale_Quote__c,(select Id, Name, Stage_PO__c,Quote_Line__c,Quote_Line__r.SBQQ__RequiredBy__c,Stage_PO__r.Expected_number_of_POs__c,Stage_PO__r.name,Stage_PO__r.Quote__c ,Quantity__c, UnitPrice__c, Product__c,SubscriptionTerm__c, ProductCode__c, Subscription_Term_Description__c,EDI_Line_Number__c, Buyer_Part_Number__c, Deliver_By__c, Est_Ship_Date__c,
                                 Stage_PO__r.Bill_To_Name__c, Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c,Product__r.Appliance_Model_HW__c,Product__r.Product_Type__c,Product__r.Product_Level__c,Product__r.ProductCode,Product__r.Usable_Capacity__c,Product__r.Product_Payment_Option__c,Product__r.Product_Subtype__c,Product__r.Family,Type__c,Product__r.Bundle_Features__c, Product__r.Eligible_for_RCDM_T__c from PO_Item_Stage__r where ProductCode__c NOT IN :Constants.DUMMY_PRODUCTS) from  PO_Stage__c where Quote__c IN: quoteMap.keyset()]){
                                    if(stgPO.ContractManufacturer__c!=null && !quoteToStagePoCMMap.containskey(stgpo.Quote__c)){
                                        quoteToStagePoCMMap.put(stgpo.Quote__c,stgPO.ContractManufacturer__c);
                                    } 

            if((validStages.contains(stgpo.PO_Validation_Status__c)|| (newMap.get(stgpo.id) != null && newMap.get(stgpo.id).PO_Validation_Status__c =='Staged' && (oldMap == null || oldMap.get(stgpo.id).PO_Validation_Status__c != 'Staged'))) || (rerunExtVal &&  stgpo.PO_Validation_Status__c != 'Failure' && stgpo.PO_Validation_Status__c != 'Failure - 855 Sent')) {

                    Integer intCurrentIdx = (Integer) stgpo.PO_Index__c;
                    if(!mapRwdQuoteIdMapIndexCountStagePos.get(stgpo.Quote__c).containsKey(intCurrentIdx)) {
                        mapRwdQuoteIdMapIndexCountStagePos.get(stgpo.Quote__c).put(intCurrentIdx, 0);
                    }
                    if (validStages.contains(stgpo.PO_Validation_Status__c) && stgpo.PO_Validation_Status__c!='Staged'
	                  && newMap.get(stgpo.id) == null) {  // TODO: refer to Internal State & Also if 1 PO from a set of 5 is success, show duplicate error on all POs under validation
                       mapRwdQuoteIdMapIndexIdSuccessPo.get(stgpo.Quote__c).put(intCurrentIdx, stgpo.Id);
                     }
                    mapRwdQuoteIdMapIndexCountStagePos.get(stgpo.Quote__c).put(
                        intCurrentIdx, 
                        mapRwdQuoteIdMapIndexCountStagePos.get(stgpo.Quote__c).get(intCurrentIdx) + 1
                    );
                }
             if((stgpo.PO_Validation_Status__c == 'Staged' || (newMap.get(stgpo.id) != null && newMap.get(stgpo.id).PO_Validation_Status__c =='Staged' && (oldMap == null || oldMap.get(stgpo.id).PO_Validation_Status__c != 'Staged'))) || (rerunExtVal &&  stgpo.PO_Validation_Status__c != 'Failure' && stgpo.PO_Validation_Status__c != 'Failure - 855 Sent')){
                 allStagePOmap.put(stgpo.id,stgpo);
                 if(stgpo.PO_Validation_Status__c != 'Staged'){
                     TrgrStagedQuoteId.add(stgpo.Quote__c);
                 }
                 if(stgpo.Expected_number_of_POs__c != null){
                     Id quoteId = stgpo.Quote__c!= null ? stgpo.Quote__c : quoteNameIdMap.get(stgPO.Quote_number__c);
                     if(quoteId != null){
                         //PRDOPS24-995
                        if(!quotePoindexMap.containsKey(quoteId+'-'+stgPO.PO_Index__c)){
                            quotePoindexMap.put(quoteId+'-'+stgPO.PO_Index__c,stgPO.PO_Index__c);
                        }
                        if(quote_ExpActStagePOs.containsKey(quoteId+'-'+stgPO.Expected_number_of_POs__c)){
                            quote_ExpActStagePOs.put(quoteId+'-'+stgPO.Expected_number_of_POs__c ,quote_ExpActStagePOs.get(quoteId+'-'+stgpo.Expected_number_of_POs__c)+1 );
                         }
                         else{
                            quote_ExpActStagePOs.put(quoteId+'-'+stgpo.Expected_number_of_POs__c,1) ;
                         }
                     }
                    
                } else {
                    setIdStagePoShouldNotValidate.add(stgpo.Id);
                    mapStagePOIdPreValidateStagePoErrRwdQuote.put(
                        stgpo.Id, 
                        createErrorRec(stgpo.Id, INVALID_INDEX_EXPECTED_NUM_PO_ERROR_CODE)
                    );

                }
             }       
         }
         system.debug(LoggingLevel.DEBUG, 'quote_ExpActStagePOs' + quote_ExpActStagePOs);
         for(string quoteIdExpectenumber : quote_ExpActStagePOs.keyset()){
            list<string> quotePO = new list<string>(quoteIdExpectenumber.split('-'));
            if((quotePO.size() == 2 && TrgrStagedQuoteId.contains(quotePO[0]) && 
               integer.valueOf(quotePO[1]) == quote_ExpActStagePOs.get(quoteIdExpectenumber) &&
               quotePoindexMap.containsKey(quoteIdExpectenumber) && 
               Integer.valueOf(quotePoindexMap.get(quoteIdExpectenumber)) == quote_ExpActStagePOs.get(quoteIdExpectenumber)) &&
               !(quoteMap.containsKey(quotePO[0]) && quoteMap.get(quotePO[0]).SBQQ__Opportunity2__c != null && quoteMap.get(quotePO[0]).SBQQ__Opportunity2__r.Opportunity_Sub_Type__c != null && (quoteMap.get(quotePO[0]).SBQQ__Opportunity2__r.Opportunity_Sub_Type__c == 'GC Offer' || quoteMap.get(quotePO[0]).SBQQ__Opportunity2__r.Opportunity_Sub_Type__c == 'GC Renewal'))
             ){               
                validateQuote.add(quotePO[0]);
            }
            
         }
        }
        system.debug(LoggingLevel.DEBUG, 'quoteMap' + quoteMap);
        system.debug(LoggingLevel.DEBUG, 'allStagePOmap' + allStagePOmap);
        system.debug(LoggingLevel.DEBUG, 'validateQuote' + validateQuote);



    }
    private static Map<String, POValidation_ErrorCode__c> getValidationCodeData() {
        if(mapErrCodeStrMsg == null) {
            mapErrCodeStrMsg = POValidation_ErrorCode__c.getAll();
        }
        return mapErrCodeStrMsg;
    }
    //PRDOPS25-734
    /**
  * @author Prashant Kumar
  * @date 05-03-2025
  * @description Run validation While deleting Stage Pos
  * @param oldStagePOMap
  */
    public static void  customValidationOnDeletePOStage(Map<Id, PO_Stage__c> oldStagePOMap) {
        Boolean hasCustomPermission = FeatureManagement.checkPermission('Allow_Stage_PO_Delete');
        for(PO_Stage__c stagePoRecord : oldStagePOMap.values()){
            if (!hasCustomPermission && !Test.isRunningTest()) {
                stagePoRecord.adderror('You are not authorized to delete this Stage PO data, hence please create support ticket with ProdOps Support or email "ProdOpsapps@rubrik.com" with details.');
            }
        }
    }
    private static Map<String, POValidation_ErrorCode__c> mapErrCodeStrMsg;

      /**
      * @author Prashant Kumar
      * @date 05-03-2025
      * @description all stage Level Validations.
      * @param stagePOList
      * @param newMap
      * @param oldMap
      * @param oppMap
      */
      public static void validationCheck(List<PO_Stage__c> stagePOList, Map<Id, PO_Stage__c> newMap, Map<Id, PO_Stage__c> oldMap, Map<id,opportunity> oppMap) {
        List<PO_Stage_Errors__c> errorsToInsert = new List<PO_Stage_Errors__c>();
        Map<Id, List<PO_Item_Stage__c>> mapPoIdToLstPoItems = new Map<Id, List<PO_Item_Stage__c>>();
        Map<string,POValidation_ErrorCode__c> validationCodes = getValidationCodeData();
        if(!allStagePOmap.values().isEmpty()){
        for(PO_Stage__c poStage :  allStagePOmap.values()){
            for(PO_Item_Stage__c POItem : poStage.PO_Item_Stage__r){
            if(mapPoIdToLstPoItems.containsKey(poStage.Id)){
            mapPoIdToLstPoItems.get(poStage.Id).add(POItem);
            }else {
            mapPoIdToLstPoItems.put(poStage.Id, new List<PO_Item_Stage__c>{ POItem });
            }
            }
            Boolean checkIfOptionMatched = false;
            if(poStage.EDI_DISTI_ID__c == 'PO PDF'){
            String picklistNameForStagePo = Order_control__mdt.getInstance('Picklist_For_StagePO').Value__c;
            List<String> getAllPicklistnames = getAllListFromMeta(picklistNameForStagePo);
            String storeOneApi;
            if(getAllPicklistnames.size() >=1){
            for(String str : getAllPicklistnames){
            if(getPicklistValues('PO_Stage__c').containsKey(str) && !getPicklistValues('PO_Stage__c').get(str).contains(String.valueOf(poStage.get(str)))){
            checkIfOptionMatched = true;
            }
            }
            }
            }
            
            PO_Stage__c oldPOStage = oldMap.get(poStage.Id);
            if(!(validateQuote.contains(quoteNameIdMap.get(poStage.Quote_number__c))) && ((newMap.containskey(poStage.id) && newMap.get(poStage.id).PO_Validation_Status__c!= 'Staged') || (!newMap.containskey(poStage.id) && poStage.PO_Validation_Status__c != 'Staged') || (oppMap != null && oppMap.get(poStage.opportunity__c) != null && (oppMap.get(poStage.opportunity__c).Opportunity_Sub_Type__c == 'GC Offer' || oppMap.get(poStage.opportunity__c).Opportunity_Sub_Type__c == 'GC Renewal')))) {
                continue;
            }
            Map<String, String> errorCodes = new Map<String, String>();
            Boolean isQualified = !mapStagePOIdPreValidateStagePoErrRwdQuote.containsKey(poStage.Id);
            Boolean isDisOrderedIndexes = false;
            if (isQualified && isDuplicate(poStage)) {
                isQualified = false;
                if(validateQuote.contains(poStage?.Quote__c)) validateQuote.remove(poStage?.Quote__c); // PRDOPS24-1090
                errorsToInsert.add(createErrorRec(poStage.Id, DUPLICATE_STAGE_PO_ERROR_CODE));
            }

            if (isQualified && isDisOrdered(poStage)) {
                isQualified = false;
                setIdStagePoDisorderedIndexes.add(poStage.Id);
                isDisOrderedIndexes = true;
            }

            if(isQualified && !checkForZeroIndexes(poStage)) {
                isQualified = false;
                errorsToInsert.add(createErrorRec(poStage.Id, INVALID_INDEX_ERROR_CODE));
            }
            if(isQualified && !compareIndexes(poStage) ) {
                isQualified = false;
                errorsToInsert.add(createErrorRec(poStage.Id, INVALID_INDEX_INDEX_GT_EXPECTED_NUM_PO_ERROR_CODE));
            } 
  
  String typeOfQuote;
  String isQuoteAspen;
  Boolean checkCMonQuote = (quoteToStagePoCMMap!=null && quoteToStagePoCMMap.containskey(poStage.Quote__c));
  if(poStage.Quote__c!=null){
  typeOfQuote=quoteMap?.get(poStage.Quote__c).SBQQ__Type__c;
  isQuoteAspen =quoteMap?.get(poStage.Quote__c)?.ProcessType__c;
  }
Boolean bypassValidationWhenAllPosNotCreated = (!validateQuote.isempty() &&
                                            !quoteNameIdMap.isempty() &&
                                            !string.isblank(poStage.Quote_number__c) &&
                                            quoteNameIdMap.get(poStage.Quote_number__c)!=null &&
                                            validateQuote.contains(quoteNameIdMap.get(poStage.Quote_number__c)));

  if (isQualified && (disableAspenForFlex?.Value__c != null && !boolean.valueOf(disableAspenForFlex?.Value__c))&& poStage.Quote__c!= null && (!String.isBlank(typeOfQuote) && !String.isBlank(isQuoteAspen) && typeOfQuote!='Renewal+Expansion' && typeOfQuote!='Renewal' && isQuoteAspen == 'Aspen' && poStage.EDI_DISTI_ID__c!='PO PDF' && String.isBlank(poStage.ContractManufacturer__c) && !checkCMonQuote) && bypassValidationWhenAllPosNotCreated) {
  errorsToInsert.add(createErrorRec(poStage.Id, PO_RECEIVED_FOR_ASPEN_NON_ARROYO_QUOTE));
  }  
  
            

            if(isQualified && oppMap != null && oppMap.get(poStage.opportunity__c) != null && oppMap.get(poStage.opportunity__c).Opportunity_Sub_Type__c== 'MSP' && poStage.Quote__c != null && quoteMap.containsKey(poStage.Quote__c) && quoteMap.get(poStage.Quote__c).MSP_SKUs_Count__c > 0){
                System.debug(LoggingLevel.DEBUG, 'test validation check '+oppMap.get(poStage.opportunity__c).Orders__r);
            System.debug(LoggingLevel.DEBUG, 'test validation check '+oppMap.get(poStage.opportunity__c).Opportunity_Sub_Type__c);

                errorCodes.put('PO-21', '');
            }

            if(isQualified && String.isBlank(poStage.PoNumber__c)){ 
                errorCodes.put('PO-01', 'Missing PO Number.');
            }

            if(isQualified && String.isBlank(poStage.End_User_PO__c)){
                errorCodes.put('PO-02', 'Missing End-user PO Number.');
            }
                
                if(isQualified && poStage.Quote__c != null && quoteMap.containsKey(poStage.Quote__c)){
                    if(poStage.Payment_Terms__c != quoteMap.get(poStage.Quote__c).SBQQ__PaymentTerms__c
                        && (poStage.Bill_To_Name__c != null && poStage.Payment_Terms__c != poStage.Bill_To_Name__r.Payment_Term__c)){
                        errorCodes.put('PO-07', 'Payment Terms do not match the quote/Distributor.');
                    }
                    if(quoteMap.get(poStage.Quote__c).Payment_year_2__c != 0 && String.isBlank(poStage.Payment_schedule_type__c)){
                errorCodes.put('PO-23', 'Payment schedule is missing');
            }
        }
                
            if(isQualified && String.isBlank(poStage.Account_name__c)){
                errorCodes.put('PO-06', 'Account Name missing.');
            }

            if(isQualified){
                setErrorCodesOnMissingShippingDetails(poStage,errorCodes,mapPoIdToLstPoItems);
            }

            system.debug(LoggingLevel.DEBUG, 'test class check bill to '+poStage.Bill_To_Name_Str__c);
            if(isQualified && String.isBlank(poStage.Bill_To_Name_Str__c)){
                errorCodes.put('PO-03', 'Missing Bill to Name.');
            }
            if(isQualified && String.isNotBlank(poStage.Shipping_Method__c) && poStage.Shipping_Method__c != 'FCA Origin'){
                errorCodes.put('PO-08', 'Missing Shipping Terms (FCA).');
            }
            /**ORDERAUTO-192 Changes 
            if(isQualified && String.isBlank(poStage.Partner_Name__c)){
                errorCodes.put('PO-13', 'Missing Reseller/partner name');
            }
            */
            if(isQualified && checkIfOptionMatched){
            errorCodes.put('PO-35', 'Wrong Value For Payment Or Shipping Terms');
            }

            
            if(isQualified && isEmailInvalid(poStage))
            {
                errorCodes.put('PO-34', 'Invalid Email Address');  
            }
            if(!isQualified && !isDisOrderedIndexes) {

                if(!(poStagesToUpdateMap.containsKey(poStage.Id) && poStagesToUpdateMap.get(poStage.Id).PO_Validation_Status__c == 'Failure')){
                    poStagesToUpdateMap.put(poStage.Id,new PO_Stage__c(Id = poStage.Id, PO_Validation_Status__c = 'Failure'));
                    validateQuote.remove(poStage.Quote__c); 
                }
                POItemStageHelperClass.failedStgPOId.add(poStage.Id);
            }
            boolean isValidated = true; 
            Date customerReqDate;
            if(poStage.Quote__r.SBQQ__Type__c != 'Renewal'){
                try {
                    if(poStage.Customer_Requested_Ship_Date__c != null && poStage.Customer_Requested_Ship_Date__c != ''){
                        customerReqDate = Date.valueOf(poStage.Customer_Requested_Ship_Date__c);
                    }
                }
                catch(TypeException e) {
                    isvalidated = false;
                }
                if(!isValidated){
                    errorCodes.put('PO-39', 'Date format is not correct, expected format yyyy-mm-dd');
                }
            }
            for(String errorCode : errorCodes.keySet()){
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = errorCode, Error_Code__c = errorCode, 
                    Error_Message__c = (!errorCodeMap.isempty() && errorCodeMap.containskey(errorCode)) ? errorCodeMap.get(errorCode) : validationCodes.get(errorCode) != null? validationCodes.get(errorCode).Error_Issue__c :  system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'External'
                );
                if(!(poStagesToUpdateMap.containsKey(poStage.Id) && poStagesToUpdateMap.get(poStage.Id).PO_Validation_Status__c == 'Failure')){
                    poStagesToUpdateMap.put(poStage.Id,new PO_Stage__c(Id = poStage.Id, PO_Validation_Status__c = 'Failure'));
                }
                errorsToInsert.add(error);
            }
        }
        }
        else {
            for(PO_Stage__c poStage : stagePOList){
                if ((String.isBlank(poStage.Quote__c)  || String.isBlank(poStage.Quote_number__c)) && poStage.PO_Validation_Status__c == 'Staged') {
                    errorsToInsert.add(createErrorRec(poStage.Id, MISSING_QUOTE_NUMBER_ON_STAGE_PO));
                }     
            }  
        }
        if(errorsToInsert.size()>0){
            insert errorsToInsert;
        }

    }
           /**
  * @author Prashant Kumar
  * @date 05-03-2025
  * @description     PO with no carrier provided defaults to Mainfreight when order is created.
  * @param stagePOList
  */
     //Implemented for Cypress-70
    public static void populateStageDefaults(List<PO_Stage__c> stagePOList){
        Set<String> tangibleProducts = new Set<String>(); 
        for(PO_Stage__c poStage: stagePOList){
                 Boolean allNonTangibleItems = true;  
                 if(allStagePOmap.get(poStage.Id)!=null){
                    for(PO_Item_Stage__c poi : allStagePOmap.get(poStage.Id).PO_Item_Stage__r){   
                        if(poi.ProductCode__c != null && (String.isNotBlank(poi.Product__r.Appliance_Model_HW__c) || poi.Product__r.Product_Type__c == 'Spares')){    
                            allNonTangibleItems = false;  
                         break;    
                     } 
                 } 
                    if(allNonTangibleItems && poStage.PO_Validation_Status__c == 'Staged'){
                    poStage.Shipping_Account_Number__c=null;    
                    poStage.Service_Level__c ='N/A';    
                    poStage.Shipping_Carrier__c ='No Shipping Required';    
                    } 
                  if(String.isBlank(poStage.Shipping_Method__c) && ((poStage.EDI_DISTI_ID__c == 'PO PDF' && poStage.Distributor_Name__c == system.label.Shipping_Distributor_Name) || poStage.EDI_DISTI_ID__c!='PO PDF'))
                        poStage.Shipping_Method__c = 'FCA Origin';
                
      if(String.isBlank(poStage.Shipping_Account_Number__c) && String.isBlank(poStage.Shipping_Carrier__c) && String.isBlank(poStage.Service_Level__c) && ((poStage.EDI_DISTI_ID__c == 'PO PDF' && poStage.Distributor_Name__c == system.label.Shipping_Distributor_Name) || poStage.EDI_DISTI_ID__c!='PO PDF')){

                    poStage.Shipping_Account_Number__c='RUBREVSFO';
                    poStage.Service_Level__c ='Economy';
                    poStage.Shipping_Carrier__c ='Watchpoint';

                }
                if(poStage.PO_Validation_Status__c == 'Staged'){
                    poStage.PO_Internal_Validation_Status__c = 'Pending';
                       poStage.Hardware_PO_Id__c ='';
                }
                 }

        }
            

    }
/**
  * @author Prashant Kumar
  * @date 05-03-2025
  * @description Set Record Type For Ingram,Arrow,PO PDF
  * @param stagePOList
  */
    public static void setRecordType(List<PO_Stage__c> stagePOList){
        Set<String> accountNames = new Set<String>();
        for(PO_Stage__c stagePO : stagePOList){
            if(stagePO.EDI_DISTI_ID__c == 'ARROW'){
                stagePO.RecordTypeId = Schema.SObjectType.PO_Stage__c.getRecordTypeInfosByName().get('Arrow').getRecordTypeId();
            }
            else if(stagePO.EDI_DISTI_ID__c == 'INGRAM'){
                stagePO.RecordTypeId = Schema.SObjectType.PO_Stage__c.getRecordTypeInfosByName().get('Promark').getRecordTypeId();
            }
            else if(stagePO.EDI_DISTI_ID__c == 'PO PDF') {
                stagePO.RecordTypeId = Schema.SObjectType.PO_Stage__c.getRecordTypeInfosByName().get('PO PDF').getRecordTypeId();
            }
        }
    }
/**
  * @author Prashant Kumar
  * @date 05-03-2025
  * @description Set Stage Po Fields on before insert 
  * @param stagePOList
  * @param oldMap
  */
   public static void populateAccountDetails(List<PO_Stage__c> stagePOList,Map<Id, PO_Stage__c> oldMap){
       Sfdc_Disti_Mapping__mdt getmeta = OrderInserthelper.getDistributorMetadata(null);

      Set<Id> accountId = new Set<Id>();
        Map<String,String> getValueBasedOnNumber = new Map<String,String>();            
        String paymentTermMapping = Order_control__mdt.getInstance('Payment_Term_Mapping').Value__c;
          String cmMapping = Order_control__mdt.getInstance('ContractManufacturer_Mapping_For_Glynt').Value__c;

      Map<String,String> paymentTermMappingMap = (Map<String,String>)JSON.deserialize(paymentTermMapping,Map<String,String>.class);
          Map<String,String> CmMap = (Map<String,String>)JSON.deserialize(cmMapping,Map<String,String>.class);

      for(PO_Stage__c stagePO : stagePOList){
            if(oldMap == null || oldMAp.get(stagePO.id).Distributor_Name__c != stagePO.Distributor_Name__c){
                if(stagePO.EDI_DISTI_ID__c == 'PO PDF'){
      String distributor = stagePO.Distributor_Name__c;
      if(distributor!=null && distributor.contains(',')){
      distributor = distributor.removeEnd(',');
      }else if(distributor!=null && distributor.contains(':')){
      distributor = distributor.removeEnd(':');
      }
      Sfdc_Disti_Mapping__mdt  metarecord;
      if(distributor!=null)
         metarecord = test.isRunningTest() ? Sfdc_Disti_Mapping__mdt.getInstance('Exclusive_Networks_SAS') : Orderinserthelper.distiMetadataMapBasedOnLabel.get(distributor.toLowercase().deleteWhitespace());
      
         system.debug(LoggingLevel.DEBUG, 'metarecord ######' + metarecord);
                    if(metarecord!=null && !metarecord.Disable_Distii__c){
      if(stagePO.Shipping_Carrier__c!=null && stagePO.Shipping_Carrier__c.contains(',')){
      String replaceCarrier = stagePO.Shipping_Carrier__c.replace(',','');
      stagePO.Shipping_Carrier__c = replaceCarrier;
      }

      if(stagePO.Account_name__c!=null && stagePO.Account_name__c.contains(':')){
      String accountName = stagePO.Account_name__c.replace(':','');
      stagePO.Account_name__c = accountName;
      }
      
      if(stagePO.Quote_number__c!=null && stagePO.Quote_number__c.contains(':')){
      String quoteNumber = stagePO.Quote_number__c.replace(':','');
      stagePO.Quote_number__c = quoteNumber;
      }
        
      if(stagePO.Ship_To_Phone_Number__c!=null && stagePO.Ship_To_Phone_Number__c.contains(':')){
      String shipToPhoneNumber = stagePO.Ship_To_Phone_Number__c.replace(':','');
      stagePO.Ship_To_Phone_Number__c = shipToPhoneNumber;
      }
      if(stagePO.Ship_To_Contact_Name__c!=null && stagePO.Ship_To_Contact_Name__c.contains(':')){
      String shipToContact = stagePO.Ship_To_Contact_Name__c.replace(':','');
      stagePO.Ship_To_Contact_Name__c = shipToContact;
      }
      
        String isQuoteAspen;
        if(stagePo.Quote__c!=null)
        isQuoteAspen =quoteMap.containsKey(stagePo.Quote__c)? quoteMap.get(stagePo.Quote__c)?.ProcessType__c: '';
        //String isQuoteAspen =quoteMap.get(stagePO.Quote__c).ProcessType__c;
        String carasoft  = System.Label.Shipping_Distributor_Name;
        String cmValueFromGlynt = stagePO.CM_Value_From_Glynt__c; 

        if(!String.isBlank(isQuoteAspen) && isQuoteAspen == 'Aspen' && metarecord.PO_Disti_Name__c != carasoft)            
        stagePo.ContractManufacturer__c = Order_control__mdt.getInstance('Smci')?.Value__c;
        if(cmValueFromGlynt!=null  && !String.isBlank(isQuoteAspen) && isQuoteAspen == 'Aspen' && metarecord.PO_Disti_Name__c == carasoft){
            cmValueFromGlynt = cmValueFromGlynt.replaceAll('[^a-zA-Z0-9\\s+]', '');
            cmValueFromGlynt = cmValueFromGlynt.toLowercase().deleteWhitespace();

            if(CmMap!=null && CmMap.keyset().contains(cmValueFromGlynt)){
                stagePO.ContractManufacturer__c = CmMap.get(cmValueFromGlynt);
            }else{
                if (cmValueFromGlynt.contains('super') || cmValueFromGlynt.contains('smci')){
                    stagePo.ContractManufacturer__c = Order_control__mdt.getInstance('Smci')?.Value__c;
                }else if(cmValueFromGlynt.contains('flex')){
                    stagePo.ContractManufacturer__c = Order_control__mdt.getInstance('Flex')?.Value__c;
                }
            }

        }         

      
       // ORDERAUTO-28,ORDERAUTO-30  
         String convertStringToInt = Order_control__mdt.getInstance('Regex_For_Subscription_Term').Value__c;
                     String fcaList = Order_control__mdt.getInstance('FCA_Origin_List').Value__c;
                     List<String> getAllPicklistnames = getAllListFromMeta(fcaList.toLowerCase());
                     for(String str : getPicklistValues('PO_Stage__c').get('Payment_Terms__c')){
                     getValueBasedOnNumber.put(str.replaceAll(convertStringToInt, ''),str);
                     }
      if(stagePO.Payment_Terms__c!=null){

                if(paymentTermMappingMap.keyset().contains(stagePO.Payment_Terms__c)) {
                    stagePO.Payment_Terms__c = paymentTermMappingMap.get(stagePO.Payment_Terms__c);
                }else if(getValueBasedOnNumber.keyset().contains(stagePO.Payment_Terms__c.replaceAll(convertStringToInt, ''))){
                    stagePO.Payment_Terms__c = getValueBasedOnNumber.get(stagePO.Payment_Terms__c.replaceAll(convertStringToInt, ''));
          }else{
              stagePO.Payment_Terms__c = 'Other';
          }
      }
        if(stagePO.Shipping_Method__c!=null){
        String shippingMethod = stagePO.Shipping_Method__c.toLowercase();
                    if(stagePO.Shipping_Method__c!=null && (getAllPicklistnames.contains(shippingMethod) || shippingMethod.contains('fca')))
                        stagePO.Shipping_Method__c = 'FCA origin';
        }
  
      
                    // Date Logic For Different DateFormat Of Vendors
                    String poDate = stagePO.Stage_PO_Date__c;
                  

    String amountFormatt;
    String stringToBeParsed;
    if(stagepo.Stage_Total_Amount_Text__c!=null){
        stringToBeParsed = getFormatBasedOnAmountByGlynt(stagepo.Stage_Total_Amount_Text__c,metarecord);
        if(stringToBeParsed!=null){
    amountFormatt = getamount(stringToBeParsed ,stagepo.Stage_Total_Amount_Text__c);
    stagepo.TotalAmount__c = Decimal.valueOf(amountFormatt.deleteWhitespace());
    }
    } 
   
  
      
        stagePO.PoDate__c = system.today();
              List<String> splitAddress = new List<String>();
                    if(stagePO.Pdf_Address__c != null)
                    splitAddress =  stagePO.Pdf_Address__c.split('\n');
                    // check If email is Valid
      String emailIdToAssign;  
      List<String> emailId;  
      if(splitAddress.size() > 1){  
      String splitEmailText = splitAddress[splitAddress.size()-1];  
      if(splitEmailText.contains('Email:'))  
      emailId = splitEmailText.split('Email:');  
                  if(emailId!=null && !emailId.isEmpty()){    
      emailIdToAssign = emailId[1];  
      }  
      }  
      if(emailIdToAssign!=null){  
      String emailRegex = Order_control__mdt.getInstance('Email_regex').Value__c;  
      Pattern emailPattern = Pattern.compile(emailRegex);  
      Matcher partnerEmailMatch = emailPattern.matcher(emailIdToAssign);  
      if(partnerEmailMatch.matches()){  
      stagePO.Ship_to_Email__c = emailIdToAssign;  
      }  
      }
                                      
                        stagePO.ShippingCountryCode__c    = metarecord?.Default_Country__c;
      if(stagePO.ShippingCountryCode__c!= 'US' && stagePO.ShippingCountryCode__c!= 'CA'){
                stagePO.ShippingStateCode__c = null;
                stagePO.ShippingState__c = null;       
      }     
    
        /*stagePO.ShippingStreet__c = stagePO.Pdf_Address__c;    
                    if((stagePO.Pdf_Address__c!=null && splitAddress.size() == 1  && metarecord.Regex__c!=null && metarecord.city_index__c == metarecord.Zipcode_Index__c) || (splitAddress.size() > 1  && metarecord.Regex__c!=null &&  metarecord.city_index__c == metarecord.Zipcode_Index__c)){
                        String regex = metarecord.Regex__c;
                        Pattern zipPattern = Pattern.compile(regex);
                        String str = splitAddress[Integer.valueOf(metarecord.city_index__c)-1];
                        Matcher zipMatcher = zipPattern.matcher(str);
                        system.debug('zipMatcher ' + zipMatcher);
                        if (zipMatcher.find()) {
                            String zip = zipMatcher.group(0);
                            stagePO.ShippingPostalCode__c = zip;
                            stagePO.ShippingCity__c = str;
                          // Logic To Get the State Code
                            if(stagePO.ShippingCountry__c == 'US' || stagePO.ShippingCountry__c == 'CA'){
                            String stateRegex = metarecord.State_Regex__c;
                            Matcher stateMatcher = zipPattern.matcher(str.substringBefore(zip));
                            if (stateMatcher.find()) {
                                String stateCode = stateMatcher.group(0);
                                stagePo.ShippingStateCode__c = stateCode;
                            }   

                        }
                        }
                        
                    }else if(splitAddress.size() > 1  && metarecord.city_index__c != metarecord.Zipcode_Index__c){
                        Pattern zipPattern = Pattern.compile(metarecord.Regex__c);
                        String str = stagePO.Pdf_Address__c;
                        Matcher zipMatcher = zipPattern.matcher(str);
                        if (zipMatcher.find()) {
                            system.debug('zipMatcher ' + zipMatcher);
                            String zip = zipMatcher.group(0);
                            stagePO.ShippingPostalCode__c = zip;
          if(splitAddress[Integer.valueOf(metarecord.city_index__c)-1] != null){
          string city = splitAddress[Integer.valueOf(metarecord.city_index__c)-1].length()> 36 ? splitAddress[Integer.valueOf(metarecord.city_index__c)-1].substring(0, 36)+'..':  splitAddress[Integer.valueOf(metarecord.city_index__c)-1];
          stagePO.ShippingCity__c = city;
          }
  
                        }   
                    } */

                      if(distributor !=null && 
                       Orderinserthelper.distiMetadataMapBasedOnLabel.containskey(distributor.toLowercase().deleteWhitespace().trim()) && 
                       Orderinserthelper.distiMetadataMapBasedOnLabel.get(distributor.toLowercase().deleteWhitespace()).Sfdc_Id__c!=null){
                           stagePO.Bill_To_Name__c   = Orderinserthelper.distiMetadataMapBasedOnLabel.get(distributor.toLowercase().deleteWhitespace()).Sfdc_Id__c;    
         stagePO.Distributor_Email_Address__c = Orderinserthelper.distiMetadataMapBasedOnLabel.get(distributor.toLowercase().deleteWhitespace()).Distributor_Email_Address__c;
    
        }
                    if(stagePO.Bill_To_Name__c!=null)
                        accountId.add(stagePO.Bill_To_Name__c);
                }
            }
     }      
        }

        

        
    
    }
/**
  * @author Prashant Kumar
  * @date 05-03-2025
  * @description clear Error_Messages__c field when stage Po is staged.
  * @param stagePOList
  * @param oldMap
  */
    public static void cleanErrorMessage(List<PO_Stage__c> stagePOList, Map<Id, PO_Stage__c> oldMap){
        for(PO_Stage__c stagePO : stagePOList){
            PO_Stage__c oldValue = oldMap.get(stagePO.Id);
            if(stagePO.PO_Validation_Status__c != oldValue.PO_Validation_Status__c && stagePO.PO_Validation_Status__c == 'Staged' ){
                stagePO.Error_Messages__c = '';
            }
        }
    }
/** 
  * @author Prashant Kumar
  * @date 05-03-2025
  * @description populate quote related details on Stage PO
  * @param stagePOList
  * @param oldMAp
  */ 
    public static void populateQuoteDetails(List<PO_Stage__c> stagePOList,map<id,PO_Stage__c> oldMAp){
        
        for(PO_Stage__c poStage : stagePOList){
                   
                    if((oldMAp == null || oldMAp.get(poStage.id).Quote_number__c != poStage.Quote_number__c) &&  quoteNameIdMap.get(poStage.Quote_number__c) != null){        
                        SBQQ__Quote__c quote = quoteMap?.get(quoteNameIdMap.get(poStage.Quote_number__c)) ;
                        poStage.Quote__c = quote.id ;
                        poStage.LineCount__c = quote.SBQQ__LineItemCount__c;
                        poStage.IsQuotePrimary__c = quote.SBQQ__Primary__c;
                        poStage.Opportunity_Owner_LK__c = quote.SBQQ__Opportunity2__r.Ownerid;
                        poStage.Opportunity__c = quote.SBQQ__Opportunity2__c;        

                    }
                
                    


            }

    }
   /** 
  * @author Prashant Kumar
  * @date 05-03-2025
  * @description External Validation for Wrong Email Id from Disti
  * @param objStagePo
  * @return Boolean
  */ 
    //PRDOPS23-365 - External Validation for Wrong Email Id from Disti
    public static Boolean isEmailInvalid(PO_Stage__c objStagePo) {
        Boolean res = false;
        Boolean poStgAddrEmailMatch = true;
        Boolean poPartEmailMatch = true;
        String emailRegex = Order_control__mdt.getInstance('Email_regex').Value__c;
        Pattern emailPattern = Pattern.compile(emailRegex);
        System.debug(LoggingLevel.DEBUG, 'Stage PO Partner Email: '+objStagePo.Partner_Email__c);
        if(objStagePo.Partner_Email__c!=null)
        {
          Matcher partnerEmailMatch = emailPattern.matcher(objStagePo.Partner_Email__c);
            if(!partnerEmailMatch.matches())
            {
                poPartEmailMatch = false;
            }
        }
        if(mapPOStageAddr.get(objStagePo.Id)!=null)
        {
            System.debug(LoggingLevel.DEBUG, mapPOStageAddr.get(objStagePo.Id).Email__c);
            if(mapPOStageAddr.get(objStagePo.Id).Email__c != null){
                Matcher poStageAddrEmailMatch = emailPattern.matcher(mapPOStageAddr.get(objStagePo.Id).Email__c);
                if(!poStageAddrEmailMatch.matches())
                {
                    poStgAddrEmailMatch = false;
                }
            }
        }
        System.debug(LoggingLevel.DEBUG, 'PO Stage Addr Email Valid: '+ poStgAddrEmailMatch);
        System.debug(LoggingLevel.DEBUG, 'Stage PO Partner Email Valid: '+poPartEmailMatch);
        if (!poPartEmailMatch || !poStgAddrEmailMatch)
        {
            res = true;
        }
        System.debug(LoggingLevel.DEBUG, 'isPOStage or Addr Email Invalid: '+res);
        return res;
    }
        /** 
         * @author Prashant Kumar
        * @date 05-03-2025
        * @description External Validation for Wrong Email Id from Disti
        * @param ObjectApi_name
        * @return Map<String,List<String>>
        */
         public static Map<String,List<String>> getPicklistValues(String ObjectApi_name){ 
        List<string> options = new List<string>();
        Map<String,List<string>> storeAlloptions = new Map<String,List<string>>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        for (Schema.SObjectField field : fieldMap.values()) {
            if(field.getDescribe().getType() == Schema.DisplayType.PICKLIST){
                List<Schema.PicklistEntry> pick_list_values = fieldMap.get(field.getDescribe().getName()).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
                for (Schema.PicklistEntry a : pick_list_values) { 
                    if(!storeAlloptions.containsKey(field.getDescribe().getName())) {
                        storeAlloptions.put(field.getDescribe().getName(), new List<String>());
                    }
                    storeAlloptions.get(field.getDescribe().getName()).add(a.getLabel());
                }
            }
        }
        return storeAlloptions;

    }
    
    /*public static Date getDateBasedOnFormat(String textDate,Sfdc_Disti_Mapping__mdt metarecord){
        String poDate = textDate;
        Date dateToBeReturned;
        string format;
        if(poDate!=null && metarecord!=null && metarecord.format__c!=null){
             format =metarecord.format__c;
            String firstDelimiter = format.substring(1,2);
            String month = format.substring(0,1);
            String dateposition = format.substring(2,3);
            String year = format.substring(4,5);
            String secondDelimiter = format.substring(3,4);
      if(!poDate.contains(firstDelimiter) || !poDate.contains(secondDelimiter)){
      poDate =  poDate.replaceAll('[^0-9]', ' ');
      firstDelimiter= ' ';
      secondDelimiter = ' ';
      }  
            List<String> firstString = poDate.split(firstDelimiter, 2);
            List<String> secondString = firstString[1].trim().split(secondDelimiter,2);
            List<String> combinedList = new List<String>{firstString[0].deleteWhitespace(),secondString[0].deleteWhitespace(),secondString[1].deleteWhitespace()};
            Map<String,String> mapOfAllItems = new Map<String,String>();
            mapOfAllItems.put(month,combinedList[0]);
            mapOfAllItems.put(dateposition,combinedList[1]);
            mapOfAllItems.put(year,combinedList[2]);
            Map<String,Integer> monthMapping = new Map<String,Integer>{
                'jan' =>1,
                    'feb' => 2,
                    'mar' =>3,
                    'apr' =>4,
                    'may' => 5,
                    'jun' => 6,
                    'jul' => 7,
                    'aug' => 8,
                    'sep' => 9,
                    'oct'=>10,
                    'nov' => 11,
                    'dec' => 12
                    };
            Integer checkyear =  integer.valueOf(mapOfAllItems.get('Y'));
            checkyear = checkyear < 2000 ? checkyear + 2000 : checkyear;
            if(mapOfAllItems.get('M').length() >= 3){
                String sizeString = mapOfAllItems.get('M').toLowercase();
                sizeString = sizeString.substring(0, 3);
                Integer monthnumber = monthMapping.get(sizeString);
                dateToBeReturned = Date.newInstance(checkyear,monthnumber,integer.valueOf(mapOfAllItems.get('D')));
            }else{
                dateToBeReturned = Date.newInstance(checkyear,integer.valueOf(mapOfAllItems.get('M')),integer.valueOf(mapOfAllItems.get('D')));
            }
        }
      return dateToBeReturned;
    }

*/
 /** 
         * @author Prashant Kumar
        * @date 05-03-2025
        * @description split metadata value into list of string
        * @param metavalue
        * @return Map<String,List<String>>
        */
  public static List<String> getAllListFromMeta(String metavalue){
  List<String> getAllPicklistnames = new List<String>();
  if(metavalue!=null && metavalue.contains(',')){
      getAllPicklistnames =  metavalue.split(',');
  }else{
      getAllPicklistnames.add(metavalue);
  }
  return getAllPicklistnames;
  }
   /** 
         * @author Prashant Kumar
        * @date 05-03-2025
        * @description convert amount based on the regex from metadata.
        * @param formatt
        * @param amtText
        * @return string
        */
  public static string getamount(string formatt,string amtText){
  Map<String,String> m = (Map<String,String>)JSON.deserialize(formatt,Map<String,String>.class);
  system.debug(LoggingLevel.DEBUG, 'm is ' + m.keyset());
  for(String character : m.keyset()){
  amtText =   amtText.replace(character,m.get(character));
  }
  String regex = Order_control__mdt.getInstance('Regex_For_USD_Removal').Value__c;  
  amtText = amtText.replaceAll(regex, '');
  return  amtText;
  }
    

    
      /** 
         * @author Prashant Kumar
        * @date 05-03-2025
        * @description PRDOPS23-365 - External Validation for Wrong Email Id from Disti
        * @param stagePOList
        * @param oldMap
        */
    //PRDOPS23-365 - External Validation for Wrong Email Id from Disti
    public static void populateStageAddress(List<PO_Stage__c> stagePOList, Map<Id,PO_Stage__c> oldMap)
    {   
        Set<Id> poStageId = new Set<Id>();
        for(PO_Stage__c poStage: stagePOList)
        {
            if(poStage.PO_Validation_Status__c =='Staged' && oldMap.get(poStage.Id).PO_Validation_Status__c != 'Staged')
            {
                poStageId.add(poStage.Id);
            }
        }
        if(poStageId.size()>0)
        {
          List<PO_Stage_Address__c> poAddrList = [Select Id,Email__c,PO_Stage__r.Ship_to_Email__c,PO_Stage__c,PO_Stage__r.PO_Validation_Status__c from PO_Stage_Address__c where PO_Stage__c in:poStageId  and (Address_Type__c='Shipp to Address' or Address_Type__c='Ship to Address')];
            for(PO_Stage_Address__c poAddr: poAddrList)
            { 
                 mapPOStageAddr.put(poAddr.PO_Stage__c,poAddr);
          }
            for(PO_Stage__c poStage: stagePOList)
            {
                if(mapPOStageAddr.get(poStage.Id)!=null)
                {                    
                    String emailRegex = Order_control__mdt.getInstance('Email_regex').Value__c;
                    Pattern emailPattern = Pattern.compile(emailRegex);
                    String partneremail = mapPOStageAddr.get(poStage.Id).Email__c;
                    if(partneremail!=null)
                    {
                        Matcher poStageAddrEmailMatch = emailPattern.matcher(partneremail);
                        System.debug(LoggingLevel.DEBUG, 'poStageAddrEmailMatch.matches(): '+poStageAddrEmailMatch.matches());
                        if(poStageAddrEmailMatch.matches())
                        {
                            poStage.Ship_to_Email__c = partneremail;  
                        }
                    }
                } 
            }
        } 
    }

// PRDOPS24-821
   /** 
         * @author Prashant Kumar
        * @date 05-03-2025
        * @description PRDOPS23-365 - Update Stage List as part of PRDOPS24-821
        */
 public static void updateStagePO(){
        if(!poStagesToUpdateMap.isEmpty()){
            try{
              update poStagesToUpdateMap.values();  
            }catch(exception e){
                system.debug(LoggingLevel.DEBUG, 'exception occured due to '+e.getMessage());
                system.debug(LoggingLevel.DEBUG, 'exception occured at line no '+e.getLineNumber());
            }
            
        }
    }
 /** 
         * @author Prashant Kumar
        * @date 05-03-2025
        * @description PRDOPS23-365 - Update Stage List as part of PRDOPS24-821
        * @param priceToFormatt
        * @param metarecord
        * @return String
        */
    public static String getFormatBasedOnAmountByGlynt(String priceToFormatt,Sfdc_Disti_Mapping__mdt metarecord){
        Boolean isAmountInUsFormat = false;
        String stringToBeParsed;
        String regexToIdentifyUSPriceFormat = Order_control__mdt.getInstance('Regex_For_US_Formatt_Amount_Price').Value__c;
        if(priceToFormatt!=null && regexToIdentifyUSPriceFormat!=null){
            Pattern regexToIdentifyUSPriceFormatPattern = Pattern.compile(regexToIdentifyUSPriceFormat);
            Matcher partnerEmailMatch = regexToIdentifyUSPriceFormatPattern.matcher(priceToFormatt);
            isAmountInUsFormat = partnerEmailMatch.matches();
            system.debug(LoggingLevel.DEBUG, 'matches #### ' + partnerEmailMatch.matches());
        }
       system.debug(LoggingLevel.DEBUG, 'isAmountInUsFormat is ### ' + isAmountInUsFormat);
        if(isAmountInUsFormat){
            stringToBeParsed = Order_control__mdt.getInstance('Default_Price_Format').Value__c;
        }else{    
            if(metarecord.Price_Mapping__c!=null){
                stringToBeParsed = metarecord.Price_Mapping__c;
            }else{
                stringToBeParsed = Order_control__mdt.getInstance('Default_Price_Format').Value__c;
            }
        }
        return stringToBeParsed;
    }
    /** 
    * @author Prashant Kumar
    * @date 05-03-2025
    * @description PRDOPS26-979 - Set Dynamic Error Message For Missing Shipping Details
    * @param poStage
    * @param errorCodes
    * @param mapPoIdToLstPoItems
    */
    public static void setErrorCodesOnMissingShippingDetails(PO_Stage__c poStage, Map<String, String> errorCodes,Map<Id, List<PO_Item_Stage__c>> mapPoIdToLstPoItems) {
        List<String> missingFields = new List<String>();

        List<Map<String, Object>> fieldConfigs = new List<Map<String, Object>>{
        new Map<String, Object>{
            'apiName' => 'Ship_To_Phone_Number__c',
            'label' => 'Ship To Phone Number',
            'condition' => new List<Boolean>{ mapPoIdToLstPoItems.containsKey(poStage.Id) && mapPoIdToLstPoItems.get(poStage.Id) != null && isHardware(mapPoIdToLstPoItems.get(poStage.Id)) }
        },
        new Map<String, Object>{ 'apiName' => 'Ship_To_Contact_Name__c', 'label' => 'Ship To Contact Name' },
        new Map<String, Object>{ 'apiName' => 'ShippingCountryCode__c', 'label' => 'Shipping Country' },
        new Map<String, Object>{
            'apiName' => 'ShippingStateCode__c',
            'label' => 'Shipping State',
            'condition' => new List<Boolean>{ poStage.ShippingCountryCode__c == 'US' || poStage.ShippingCountryCode__c == 'CA' }
        },
        new Map<String, Object>{ 'apiName' => 'ShippingPostalCode__c', 'label' => 'Shipping Postal Code' },
        new Map<String, Object>{ 'apiName' => 'ShippingCity__c', 'label' => 'Shipping City' },
        new Map<String, Object>{ 'apiName' => 'ShippingStreet__c', 'label' => 'Shipping Street' }
        };

        for (Map<String, Object> config : fieldConfigs) {
        Boolean shouldCheck = true;

        if (config.containsKey('condition')) {
            // Evaluate all conditions (AND logic)
            for (Boolean cond : (List<Boolean>) config.get('condition')) {
            shouldCheck = shouldCheck && cond;
            }
        }

        if (shouldCheck && String.isBlank((String) poStage.get((String) config.get('apiName')))) {
            missingFields.add((String) config.get('label'));
        }
        }

        // If ANY fields are missing → add error
        if (!missingFields.isEmpty()) {
        errorCodes.put('PO-04', 'Missing Ship To Address.');
        errorCodeMap.put('PO-04', 'Missing Ship-to Information: ' + String.join(missingFields, ', ') + '.');
        }
    }    

 

}