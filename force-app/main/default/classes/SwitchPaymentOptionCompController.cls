//  *************************************************************************
//  Requirements
//  1. RWD-400 : Switch Payment Option
//  
//    Requirements developed by - Jayaraman   Iyer
//    Last Modified by - Jayaraman Iyer
//    Last Modified - 02/21/2022
//    Last modified for 1998  later adding comment on 31/march/23 (circleCi did not push changes to prod).
//  ************************************************************************

public without sharing class SwitchPaymentOptionCompController {

    @TestVisible
  private static SwitchPaymentOptionCompController instance = null;
  public static boolean isDisabled = false; //FY25SR-1706

  public SwitchPaymentOptionCompController() {
    this(Test.isRunningTest());
  }

    @TestVisible
  private SwitchPaymentOptionCompController(Boolean isGetInstanceMethodOrRunningTest) {
    if (isGetInstanceMethodOrRunningTest == false) {
      throw new System.MathException('Don\'t use the public constructor. Use the getInstance method.');
    }
    }

    public static SwitchPaymentOptionCompController getInstance() {
        if (instance == null) {
            instance = new SwitchPaymentOptionCompController(true);
        }
        return instance;
    }
    /**@description : gets User Instance for bypass
     * FY25SR-1706
    */
    public static void getBypass(){ 
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_Replacement_Framework__c;
    }

    @AuraEnabled(cacheable = true)
    public static List<ShowResultMapper> showQuotesLinesProducts(String quoteId) {
        getBypass(); //FY25SR-1706
        if (Test.isRunningTest()) {
            isDisabled = true;
        }
        
        if(isDisabled && quoteId != null && quoteId != '') {

            List<SBQQ__QuoteLine__c> quotesLinesList = [
                SELECT Id
                     , Name
                     , SBQQ__ProductCode__c
                     , SBQQ__Product__c
                     , SBQQ__Quote__c
                     , Payment_Options__c
                     , SBQQ__Product__r.Name
                     , SBQQ__Product__r.Product_Payment_Option__c
                     , SBQQ__RequiredBy__c
                     , Product_Level__c
                     , Product_Payment_Option__c
                     , Quote_Line_Type__c
                     , Product_Type__c
                     , SBQQ__ListPrice__c
                     , Approval_Discount__c
                     , SBQQ__NetTotal__c
                     , SBQQ__Quantity__c
                     , SBQQ__SubscriptionTerm__c
                     , Subscribed_Asset_Name__c
                     , SBQQ__PricebookEntryId__c
                     , SBQQ__Description__c
                     FROM SBQQ__QuoteLine__c
                     WHERE SBQQ__Quote__c =: quoteId
                     AND Product_Type__c != 'HW Support'
                     AND SBQQ__Product__r.X0__c = false
                     AND Product_Level__c != null
                     AND SBQQ__Product__r.Product_Payment_Option__c != null                
            ];

            if(!quotesLinesList.isEmpty()) {
                
                List<ShowResultMapper> showResultMapperList = new List<ShowResultMapper>();
                Set<string> productCodeSet = new Set<string>();
                Map<string, Decimal> priceBookEntryMap = new Map<string, Decimal>();

                for(SBQQ__QuoteLine__c quoteLine : quotesLinesList) {
                    
                    ShowResultMapper showResultMapper = new ShowResultMapper();
                    showResultMapper.quoteLine = quoteLine;
                    string currentProductCode = quoteLine.SBQQ__ProductCode__c;
                    string targetProductCode = '';
                    if(quoteLine.Product_Payment_Option__c == 'Prepay') {
                        targetProductCode = quoteLine.SBQQ__ProductCode__c.removeEnd('P');
                        targetProductCode = targetProductCode + 'A';
                    } else if(quoteLine.Product_Payment_Option__c == 'Annual') {
                        targetProductCode = quoteLine.SBQQ__ProductCode__c.removeEnd('A');
                        targetProductCode = targetProductCode + 'P';
                    }
                    showResultMapper.targetSku = targetProductCode;
                    productCodeSet.add(targetProductCode);
                    productCodeSet.add(currentProductCode);
                    showResultMapperList.add(showResultMapper);
                }

                if(productCodeSet.size() > 0) {
                    List<PricebookEntry> priceBookEntryList = [SELECT Id, Product2.Name, UnitPrice  from PricebookEntry where Pricebook2.Name = 'CPQ PriceBook' AND IsActive = true AND Product2.Name =: productCodeSet];
                    if(priceBookEntryList.size() > 0) {
                        for(PricebookEntry pbe : priceBookEntryList) {
                            priceBookEntryMap.put(pbe.Product2.Name, pbe.UnitPrice);
                        }                        
                    }
                }

                for(ShowResultMapper mapper: showResultMapperList) {
                    
                    if(priceBookEntryMap.containsKey(mapper.targetSku)) {
                        system.debug('Hi SwitchPaymentOptionCompController');
                        mapper.targetListPrice = priceBookEntryMap.get(mapper.targetSku);
                        mapper.targetNetTotal = mapper.targetListPrice * mapper.quoteLine.SBQQ__SubscriptionTerm__c * mapper.quoteLine.SBQQ__Quantity__c * ((100 - mapper.quoteLine.Approval_Discount__c) /100);
                    } 
                    if(priceBookEntryMap.containsKey(mapper.quoteLine.SBQQ__ProductCode__c)) {
                        system.debug('Hi SwitchPaymentOptionCompController2');
                        mapper.currentListPrice = priceBookEntryMap.get(mapper.quoteLine.SBQQ__ProductCode__c);                        
                    }                         
                }
                    
                System.debug('****showResultMapperList****: ' + showResultMapperList);
                return showResultMapperList;
            } else {
                
                return new List<ShowResultMapper> {};
            }
        } else {
            
            return new List<ShowResultMapper> {};
        }
    }

 @AuraEnabled
 public static List<List<UpdateResultWrapper>> switchPaymentOption(String quoteLineDataWrapper) {
        //Id quoteID = null;
        Map<Id, String> quoteLineIdVsSwitchedProductName = new Map<Id, String>();
        Map<Id, SBQQ__QuoteLine__c> quoteLineIdVSQuoteLineObj = new Map<Id, SBQQ__QuoteLine__c>();
        Map<String, Product2> productNameVsProductObj = new Map<String, Product2>();
        Map<Id, String> quoteLineIdVsProductPaymentOption = new Map<Id, String>();
        List<SBQQ__QuoteLine__c> updatedQuoteLine = new List<SBQQ__QuoteLine__c>();
        Map<String, PricebookEntry> productNameVsPriceBookEntryMap = new Map<String, PricebookEntry>();
        Set<Id> switchedProductIdset = new Set<Id>();
        //List<String> quoteLineName = new List<String>();
        List<List<UpdateResultWrapper>> updateResultWrapperList = new List<List<UpdateResultWrapper>>();
        List<SelectedQuoteLineDataWrapper> quoteLineDataWrapperList =
             (List<SelectedQuoteLineDataWrapper>)JSON.deserialize(quoteLineDataWrapper, List<SelectedQuoteLineDataWrapper>.class);
             System.debug('coming here ************* quoteLineDataWrapper   ' +quoteLineDataWrapper);
             System.debug('coming here *************  quoteLineDataWrapperList ' +quoteLineDataWrapperList);
        Map<String,List<String>> qliVsErrorMap = new Map<String,List<String>>();
        Map<String,String> qilVsErrorMapValidMessage = new Map<String,String>();
        if(quoteLineDataWrapperList != null && !quoteLineDataWrapperList.isEmpty()) {
            for(SelectedQuoteLineDataWrapper quoteDataWrapper : quoteLineDataWrapperList) {
                if(quoteDataWrapper.quoteLine.Product_Payment_Option__c == quoteDataWrapper.picklistValue){
                    if(qliVsErrorMap.containsKey(quoteDataWrapper.quoteLine.Id)){
                        qliVsErrorMap.get(quoteDataWrapper.quoteLine.Id).add('Already has same payment option');
                    }else{
                        qliVsErrorMap.put(quoteDataWrapper.quoteLine.Id, new List<String>{'Already has same payment option'});
                        qilVsErrorMapValidMessage.put(quoteDataWrapper.quoteLine.Id, quoteDataWrapper.quoteLine.Name);
                    }
                }
                quoteLineIdVSQuoteLineObj.put(quoteDataWrapper.quoteLine.Id, quoteDataWrapper.quoteLine);
                quoteLineIdVsSwitchedProductName.put(quoteDataWrapper.quoteLine.Id, quoteDataWrapper.changedName);
                quoteLineIdVsProductPaymentOption.put(quoteDataWrapper.quoteLine.Id, quoteDataWrapper.picklistValue);
                //quoteLineName.add(quoteDataWrapper.quoteLine.Name);
            }
        } else {
            return new List<List<UpdateResultWrapper>> {
                new List<UpdateResultWrapper>{
                    new UpdateResultWrapper(false, 'Error : Please Select Quote Lines')
                }
            };
        }
        if(!qliVsErrorMap.isEmpty()){
            List<List<UpdateResultWrapper>> listOfUpdateResultWrapperList = new List<List<UpdateResultWrapper>>();
            for(String qliId:qliVsErrorMap.keySet()){
                listOfUpdateResultWrapperList.add(new List<UpdateResultWrapper>{
                    new UpdateResultWrapper(false, 'Error :' + qliVsErrorMap.get(qliId)[0] + ' for ' + qilVsErrorMapValidMessage.get(qliId) )
                });
            }
            if(!listOfUpdateResultWrapperList.isEmpty()){
                return listOfUpdateResultWrapperList;
            }
        }
        
        List<Product2> switchProductData = [SELECT Id, Name, Description FROM Product2 WHERE Name IN: quoteLineIdVsSwitchedProductName.values()];
        if(switchProductData != null || !switchProductData.isEmpty()) {
            for(Product2 product : switchProductData) {
                productNameVsProductObj.put(product.Name, product);
                switchedProductIdset.add(product.Id);
            }
        } else {
            return new List<List<UpdateResultWrapper>> {
                new List<UpdateResultWrapper>{
                    new UpdateResultWrapper(false, 'Error : No Related Products found')
                }
            };
        }
        System.debug('switchedProductIdset  == >>> '+switchedProductIdset);
        List<PricebookEntry> pricebookEntryList = [SELECT Id, Name, UnitPrice, Product2Id, Product2.Name FROM PricebookEntry WHERE Pricebook2.Name ='CPQ PriceBook' AND Product2Id IN : switchedProductIdset];
        if(!pricebookEntryList.isEmpty()) {
            for(PricebookEntry priceBookEntry : pricebookEntryList) {
                productNameVsPriceBookEntryMap.put(priceBookEntry.Product2.Name, priceBookEntry);
            }
        }
        System.debug('productNameVsPriceBookEntryMap   ====> ' +productNameVsPriceBookEntryMap);
        System.debug('quoteLineIdVsSwitchedProductName  ===>  '+quoteLineIdVsSwitchedProductName.keySet());
        List<SBQQ__QuoteLine__c> allQuotesLines = new List<SBQQ__QuoteLine__c>();
        if(!quoteLineIdVsSwitchedProductName.isEmpty()) {
            Set<Id> quotelineIDs = new Set<Id>(quoteLineIdVsSwitchedProductName.keySet());
            String objQuery = 'SELECT ' + String.join(getAllFields('SBQQ__QuoteLine__c'), ',') + ' FROM SBQQ__QuoteLine__c WHERE id IN : quotelineIDs';
            system.debug('objQueryobjQuery    '+objQuery);
            allQuotesLines = Database.query(objQuery);
            //List<SBQQ__QuoteLine__c> allQuotesLines = [select id,SBQQ__Quote__c from SBQQ__QuoteLine__c where id in : quoteLineIdVsSwitchedProductName.keySet()];
            System.debug('allQuotesLines =====>'+allQuotesLines);
            for(SBQQ__QuoteLine__c actualQuoteLine : allQuotesLines) {
                System.debug('actualQuoteLine ==> '+actualQuoteLine.Name);
                //remove this
                //SBQQ__QuoteLine__c actualQuote = [select id from SBQQ__QuoteLine__c where id =: quoteLineId];
                SBQQ__QuoteLine__c clonedQuote = actualQuoteLine.clone(false, true, true, true);
                clonedQuote.SBQQ__Quote__c = actualQuoteLine.SBQQ__Quote__c;
                clonedQuote.SBQQ__Product__c = productNameVsProductObj.get(quoteLineIdVsSwitchedProductName.get(actualQuoteLine.Id)).Id;
                clonedQuote.Product_Payment_Option__c = quoteLineIdVsProductPaymentOption.get(actualQuoteLine.Id);
                clonedQuote.Payment_Options__c = quoteLineIdVsProductPaymentOption.get(actualQuoteLine.Id);
                clonedQuote.SBQQ__PricebookEntryId__c = productNameVsPriceBookEntryMap.get(quoteLineIdVsSwitchedProductName.get(actualQuoteLine.Id)).Id;
                clonedQuote.SBQQ__Description__c = productNameVsProductObj.get(quoteLineIdVsSwitchedProductName.get(actualQuoteLine.Id)).Description;
                clonedQuote.Identifier__c = actualQuoteLine.Name;
                //---clonedQuote.SBQQ__NetPrice__c = actualQuote.SBQQ__NetPrice__c;
                System.debug('Inserting cloned quote');
                updatedQuoteLine.add(clonedQuote);
                /*quoteLineIdVSQuoteLineObj.get(quoteLineId).SBQQ__Product__c = productNameVsProductObj.get(quoteLineIdVsSwitchedProductName.get(quoteLineId)).Id;
                quoteLineIdVSQuoteLineObj.get(quoteLineId).Product_Payment_Option__c = quoteLineIdVsProductPaymentOption.get(quoteLineId);
                quoteLineIdVSQuoteLineObj.get(quoteLineId).Payment_Options__c = quoteLineIdVsProductPaymentOption.get(quoteLineId);//RWD-1517
                quoteLineIdVSQuoteLineObj.get(quoteLineId).SBQQ__NetPrice__c =
                    productNameVsPriceBookEntryMap.ContainsKey(quoteLineIdVsSwitchedProductName.get(quoteLineId))
                    ? productNameVsPriceBookEntryMap.get(quoteLineIdVsSwitchedProductName.get(quoteLineId)).UnitPrice
                    : 0;
                updatedQuoteLine.add(quoteLineIdVSQuoteLineObj.get(quoteLineId));*/
                
            }
        } else {
            // return new List<UpdateResultWrapper> {
            //     new UpdateResultWrapper(false, 'Error : Conditions Not Matched For Switching')
            // };
            return new List<List<UpdateResultWrapper>> {
                new List<UpdateResultWrapper>{
                    new UpdateResultWrapper(false, 'Error : No quote line satisfies the condition.')
                }
            };
        }
        if(updatedQuoteLine != null || !updatedQuoteLine.isEmpty()) {
            System.debug(updatedQuoteLine);
            Database.SaveResult[] quoteLineUpdateList = Database.insert(updatedQuoteLine,false);
            Set<Id> clonedQuoteLineList = new Set<Id>();
            if(!quoteLineUpdateList.isEmpty()) {
                for (Database.SaveResult saveResult : quoteLineUpdateList) {
                    List<UpdateResultWrapper> updateResultObjList = new List<UpdateResultWrapper>();
                    if (saveResult.isSuccess()) {
                        clonedQuoteLineList.add(saveResult.getId());
                        updateResultObjList.add(new UpdateResultWrapper(true, 'Successfully updated quoteLine. QuoteLine ID : ' + saveResult.getId()));
                    } else {
                        for(Database.Error err : saveResult.getErrors()) {
                            updateResultObjList.add(new UpdateResultWrapper(false, 'Error : ' + err.getStatusCode() + ': ' + err.getFields()+' '+err.getMessage()));
                        }
                    }
                    updateResultWrapperList.add(updateResultObjList);
                }
            } else {
                //updateResultWrapperList.add(new UpdateResultWrapper(false, 'Error : No quoteline found to update !'));
                updateResultWrapperList.add(new List<UpdateResultWrapper>{
                    new UpdateResultWrapper(false, 'Error : No quoteline found to update !')
                });
            }
            System.debug('UpdateResultWrapper -> '+updateResultWrapperList);
            updateRelatedQuoteLines(clonedQuoteLineList);
            if(allQuotesLines.size() > 0){
                System.debug('deleting old quotelines');
                deleteOldQuoteLine(allQuotesLines);
            }
            return updateResultWrapperList;
        }
        else {
            // return new List<UpdateResultWrapper> {
            //     new UpdateResultWrapper(false, 'Error : Something Went Wrong, Please Try Again')
            // };
            return new List<List<UpdateResultWrapper>> {
                new List<UpdateResultWrapper>{
                    new UpdateResultWrapper(false, 'Error : Something Went Wrong, Please Try Again')
                }
            };
        }
    }
    /*
    * updates the related quotelines 
    **/
    public static void updateRelatedQuoteLines(Set<Id> clonedQuoteLineList){
        
        String clonedlinesQuery = 'select id, Identifier__c, SBQQ__Quote__r.id from SBQQ__QuoteLine__c where id in : clonedQuoteLineList';
        List<SBQQ__QuoteLine__c> clonedQuotelinesList = Database.query(clonedlinesQuery);
        Map<String, Id> requiredbymap = new Map<String,Id>();
        Id quoteId = null;
        for(SBQQ__QuoteLine__c quotelines : clonedQuotelinesList){
            requiredbymap.put(quotelines.Identifier__c,quotelines.id);
            quoteId = quotelines.SBQQ__Quote__r.id;
        }
        System.debug('requiredbymap  ==== >>>> '+requiredbymap);
        Set<String> requiredbySet = requiredbymap.keySet();
        String childLinesQuery = 'select id, SBQQ__RequiredBy__r.name,SBQQ__Quote__r.id from SBQQ__QuoteLine__c where SBQQ__RequiredBy__r.name in :requiredbySet ';
        System.debug('Query ====>>>>   '+childLinesQuery);
        System.debug('Quote ID  ========>>>>   '+quoteID+'Key Set  =====>  '+requiredbySet);
        List<SBQQ__QuoteLine__c> childlines = Database.query(childLinesQuery);
        System.debug('child lines ====>>> '+childlines);
        List<SBQQ__QuoteLine__c> toupdate = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c toupdateQuoteline :  childlines){
            String requiredbyKey = toupdateQuoteline.SBQQ__RequiredBy__r.Name;
            toupdateQuoteline.id = toupdateQuoteline.id;
            toupdateQuoteline.SBQQ__RequiredBy__c = requiredbymap.get(requiredbyKey);
            toupdate.add(toupdateQuoteline);
        }
        System.debug('Updating the new quote lines ===>>>>  '+toupdate);
        Database.update(toupdate);
    }
    
   /*
    * Deletes the related quotelines 
    **/
    public static void deleteOldQuoteLine(List<SBQQ__QuoteLine__c> allQuotesLines){
        
        Database.delete(allQuotesLines);
        
    }

   /*
    * fetches all the fields the related quotelines 
    **/
    
    public static list<String>  getAllFields(String sObjectName){
        list<String> listOfFields = new list<string>();
        Map<String, Schema.SObjectType> globalDescribeIns = Schema.getGlobalDescribe();    
        Map <String, Schema.SObjectField> fieldMap = globalDescribeIns.get(sObjectName).getDescribe().fields.getMap();
        
        for(Schema.SObjectField fieldAPI : fieldMap.values())
        {  
            Schema.DescribeFieldResult fieldDetail = fieldAPI.getDescribe();
            if(fieldDetail.isCreateable()){
                listOfFields.add(fieldDetail.getName());
            }
            
        }
        listOfFields.add('Name');
        for(String fieldNames : listOfFields){
            System.debug('list of fields --> ' +fieldNames);
        }
        return listOfFields;
    }
    
    public class SelectedQuoteLineDataWrapper {

        @AuraEnabled public SBQQ__QuoteLine__c quoteLine;
        @AuraEnabled public String changedName;
        @AuraEnabled public String picklistValue;
    }

    public class UpdateResultWrapper {

        @AuraEnabled public Boolean isSuccess = true;
        @AuraEnabled public String message = '';

        public UpdateResultWrapper(){}
        public UpdateResultWrapper(
            Boolean successValue,
            String errorMsg
        ) {

            this.isSuccess = successValue;
            this.message = errorMsg;
        }

    }

    public class ShowResultMapper {
        @AuraEnabled public SBQQ__QuoteLine__c quoteLine;
        @AuraEnabled public String targetSku;
        @AuraEnabled public Decimal targetListPrice;
        @AuraEnabled public Decimal targetNetTotal;
        @AuraEnabled public Decimal currentListPrice;
        
    }
}