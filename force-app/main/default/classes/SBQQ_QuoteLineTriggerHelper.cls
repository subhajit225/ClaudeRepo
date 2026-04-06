/**
 * Class Name : SBQQ_QuoteLineTriggerHelper 
* Created Date :- 01-06-2018 
 * @description : SBQQ_QuoteLineTriggerHelper class contains helper methods for SBQQ_QuoteLineTriggerHandler class.
 * Test Class : SBQQ_QuoteLineTriggerHandler_Test
    
//********************Change Logs*****************************************************************************
* 
* Change Request            Modified By          Date           Description 
*                                                               Inserted New populateFieldsOnQuoteLine Method
*                                                               Added the logic to Populate Hidden and Optional Field values to QuoteLines
* CPQ22-5617            Mustakim Shaikh        12-8-2025        Code Coverage & PMD Issue Fix under Tech-Debt User Story
*  
//********************Change Logs Ends*************************************************************************
**/   
public without sharing class SBQQ_QuoteLineTriggerHelper{
    public static List<Order> lstOrders; //Added for CPQ22-937
    static Set<Id> processedQuoteLines= new Set<Id>();
    /** allARYQLIRecord*/
    static List<SBQQ__QuoteLine__c> allARYQLIRecord;
    static  List<SBQQ__QuoteLine__c> allQLIRec;
    /** isRecursiveautoAddONDSKUs*/
    public static Boolean isRecursiveautoAddONDSKUs = false;

    /**
     * @description : This method populates fields on Quote Line during insert operation.
     * @param qliList List of SBQQ__QuoteLine__c records to be processed.
     */
    public static void populateFieldsOnInsert (List< SBQQ__QuoteLine__c> qliList) {
        Map < Id, SBQQ__Quote__c > mapIdRecordQuote = new Map < Id, SBQQ__Quote__c > ();
        Set < Id > quoteIdSet = new Set < Id > ();
        for(SBQQ__QuoteLine__c qli : qliList) {    
            qli.Product_Code__c = qli.SBQQ__PackageProductCode__c;
            qli.Source_List_Price__c = qli.SBQQ__ListPrice__c;
            qli.Source_Default_Term__c= qli.SBQQ__DefaultSubscriptionTerm__c;
            qli.Source_Option_POT__c= qli.Product_Option_Percent_of_Total__c;
            quoteIdSet.add(qli.SBQQ__Quote__c);
            //To blank out required_by_ext_Id__c on addition of New Products from Add Products page.
            if (qli.required_by_ext_Id__c != null) {
               qli.required_by_ext_Id__c = '';
            }
        }
        //GLCR-101 Commenting below logic as not quoteidset will never have a value
        /*if (!quoteIdSet.isEmpty()) {
            mapIdRecordQuote = new Map < Id, SBQQ__Quote__c > ([SELECT Id, SBQQ__Type__c FROM SBQQ__Quote__c WHERE Id =: quoteIdSet]);
        }
        
        for(SBQQ__QuoteLine__c qli : qliList) { 
            system.debug('qli:' + qli.SBQQ__ProductCode__c);   
            if (mapIdRecordQuote.containsKey(qli.SBQQ__Quote__c) && (mapIdRecordQuote.get(qli.SBQQ__Quote__c).SBQQ__type__c == 'Renewal+Expansion' || mapIdRecordQuote.get(qli.SBQQ__Quote__c).SBQQ__type__c == 'Renewal')) {
                qli.Disposition_Reason__c = 'None';
                system.debug('qli??'+qli.Disposition_Reason__c);
            }*/ //GLCR-101 Commenting below logic as not quoteidset will never have a value
            /*if(qli.Line_Type__c == 'New')
{
qli.Product_Level__c = qli.SBQQ__Product__r.Product_Level__c;
//quoteLinesToUpdate.add(qli);
system.debug('Product Level A: ' + qli.Product_Level__c);
}
else if(qli.Line_Type__c == 'Renewal' && qli.Disposition_Reason__c == 'Renewing')
{
qli.Product_Level__c = qli.SBQQ__Product__r.Product_Level__c;
//quoteLinesToUpdate.add(qli);
system.debug('Product Level B: ' + qli.Product_Level__c);
}
else if(qli.Line_Type__c == 'Renewal' && qli.Disposition_Reason__c == 'Renewing' 
&& qli.After_Conversion_Product_Level__c == 'Hardware')
{
qli.Product_Level__c = qli.After_Conversion_Product_Level__c;
//quoteLinesToUpdate.add(qli);
system.debug('Product Level C: ' + qli.Product_Level__c);
}*/
        //}//GLCR-101 Commenting below logic as not quoteidset will never have a value
    }
    
    //populate Asset details on Quote Line based on SBQQ__SubscribedAssetIds__c field
    /*public static void populateAssetDetails (List<SBQQ__QuoteLine__c> qliList){
        Map<Id, Asset> assetIdMap = new Map<Id, Asset>();
        Set<String> assetIdSet = new Set<String>();
        
        for(SBQQ__QuoteLine__c qli : qliList){
            if(String.isNotBlank(qli.SBQQ__SubscribedAssetIds__c)) {
                for(String asstId : qli.SBQQ__SubscribedAssetIds__c.split(',')) {
                    asstId = asstId.trim();    
                    assetIdSet.add(asstId); 
                }
            }
        }
        
        
        for(Asset ast : [SELECT Id, Name FROM Asset WHERE Id IN :assetIdSet]) {
            assetIdMap.put(ast.Id, ast);
        }
        System.debug('Inside SBQQ_QuoteLineTriggerHelper.populateAssetDetails : assetIdMap :: '+assetIdMap);
        
        for(SBQQ__QuoteLine__c qli : qliList) {
            String nameStr = '';
            if(String.isNotBlank(qli.SBQQ__SubscribedAssetIds__c) ) {
                for(String assetId : qli.SBQQ__SubscribedAssetIds__c.split(',')) {
                    assetId = assetId.trim();
                    
                    nameStr += assetIdMap.get( (Id) assetId ).Name+',';
                    
                    if( String.isBlank(qli.SubscribedAssetLookup__c) ) {
                        qli.SubscribedAssetLookup__c = (Id) assetId;
                    }
                }
                qli.SubscribedAssetNames__c = nameStr.removeEnd(',');
            }
        }
    }*/
    
    //SAL-148 : Method to throw error when Term on Subscription SKU is more than term on Premium Support sku on each bundle
    /*public static void populateBundlePremiumSupportAndSubscriptionTerm (List<SBQQ__QuoteLine__c> qliList) {
        
        Map<Id, Decimal> productBundleSubscriptTermMap = new Map<Id, Decimal> ();
        Map<Id, Decimal> productBundlePremiumSupportTermMap = new Map<Id, Decimal> ();
        List<SBQQ__QuoteLine__c> parentProductList = new List<SBQQ__QuoteLine__c> ();
        Set<Id> parentProductIdSet = new Set<Id> ();
        
        try {
            for (SBQQ__QuoteLine__c qli : qliList) {
                if (qli.SBQQ__RequiredBy__c != null && qli.SBQQ__SubscriptionTerm__c != null) {
                    if (qli.Is_Premium_Support__c) {
                        if (productBundlePremiumSupportTermMap.containsKey(qli.SBQQ__RequiredBy__c) 
                            && productBundlePremiumSupportTermMap.get(qli.SBQQ__RequiredBy__c) < qli.SBQQ__SubscriptionTerm__c) {
                                
                                productBundlePremiumSupportTermMap.put(qli.SBQQ__RequiredBy__c, qli.SBQQ__SubscriptionTerm__c);
                            } else if (!productBundlePremiumSupportTermMap.containsKey(qli.SBQQ__RequiredBy__c)) {
                                productBundlePremiumSupportTermMap.put(qli.SBQQ__RequiredBy__c, qli.SBQQ__SubscriptionTerm__c);
                            }
                        parentProductIdSet.add(qli.SBQQ__RequiredBy__c);
                    }   
                    if (!qli.Is_Premium_Support__c) {
                        if (productBundleSubscriptTermMap.containsKey(qli.SBQQ__RequiredBy__c) 
                            && productBundleSubscriptTermMap.get(qli.SBQQ__RequiredBy__c) < qli.SBQQ__SubscriptionTerm__c) {
                                
                                productBundleSubscriptTermMap.put(qli.SBQQ__RequiredBy__c, qli.SBQQ__SubscriptionTerm__c);
                            } else if (!productBundleSubscriptTermMap.containsKey(qli.SBQQ__RequiredBy__c)) {
                                productBundleSubscriptTermMap.put(qli.SBQQ__RequiredBy__c, qli.SBQQ__SubscriptionTerm__c);
                            }
                    }
                }
            }
            system.debug('qliList :: '+qliList);
            system.debug('parentProductIdSet :: '+parentProductIdSet);
            
            if(parentProductIdSet.size() > 0) {
                for (SBQQ__QuoteLine__c qli : [SELECT Id, Max_Subscription_Term__c, Bundle_Premium_Support_Term__c 
                                               FROM SBQQ__QuoteLine__c 
                                               WHERE Id IN :parentProductIdSet]) {
                                                   
                                                   qli.Max_Subscription_Term__c = productBundleSubscriptTermMap.get(qli.id);
                                                   qli.Bundle_Premium_Support_Term__c = productBundlePremiumSupportTermMap.get(qli.id);
                                                   parentProductList.add(qli);
                                               }
            }       
            
            if (!parentProductList.isEmpty()) {
                //update parentProductList;     
            }
            
        } catch (Exception e) {
            if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                qliList[0].addError(e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []'));
            } else {
                qliList[0].addError(e.getMessage());
            }
        } 
    }*/
    
    /**
     * @description : This method is used to validate as Quoting Restrictions if any then throws error.
     * @param newMap Map of SBQQ__QuoteLine__c records being inserted or updated.
     * @param OldMap OldMap of SBQQ__QuoteLine__c records being inserted or updated.
     * @param qlMap Map of existing SBQQ__QuoteLine__c records.
     * @param isInsert Boolean indicating if the operation is an insert.
     */
    public static void quotableByValidation(Map<Id,SBQQ__QuoteLine__c> newMap,Map<Id,SBQQ__QuoteLine__c> OldMap,Map<Id,SBQQ__QuoteLine__c> qlMap, Boolean isInsert){
        
        //System.debug(LoggingLevel.INFO, 'Records newMap '+newMap.values());
        List<SBQQ__QuoteLine__c> qlProcessList = new List<SBQQ__QuoteLine__c>();
        if(allQLIRec!= null && !allQLIRec.isEmpty()){
            qlProcessList.addAll(allQLIRec);
        }else if(qlMap!= null && !qlMap.isempty()){
            qlProcessList.addAll(qlMap.values());
        }
        System.debug(LoggingLevel.INFO, 'qlProcessList  '+qlProcessList.size());
        if(!qlProcessList.isEmpty()){                       
            for(SBQQ__QuoteLine__c ql : qlProcessList){
                Boolean isProfileError = false;
                Boolean isUserError = false;
                
                if(newMap.containsKey(ql.Id) && ql.Quote_Line_Type__c == 'New'){
                    //newMap.get(ql.Id).addError('test error');
                    //QL Is Insert                  
                    if(isInsert && ql.SBQQ__number__c == null){
                        //System.debug(LoggingLevel.INFO, 'isInsert check ' +isInsert);
                        //System.debug(LoggingLevel.INFO, 'isInsert record' +ql.SBQQ__ProductCode__c);
                        if(!String.isBlank(ql.SBQQ__Product__r.Quotable_By_Profiles__c)){
                            if(ql.SBQQ__Product__r.Quotable_By_Profiles__c.contains(ql.SBQQ__Quote__r.Running_User_Profile__c)){
                                continue;
                            }
                            else{
                                isProfileError = true;
                            }
                        }
                        if(!String.isBlank(ql.SBQQ__Product__r.Quotable_by_users__c)){
                            if(ql.SBQQ__Product__r.Quotable_by_users__c.stripHtmlTags().contains(UserInfo.getName())){
                                continue;
                            }
                            else{
                                isUserError = true;
                            }
                        }
                    }
                
                    else if(!isInsert){//QL is Updated                        
                            System.debug(LoggingLevel.INFO, 'isUpdate check ' +isInsert);                            
                           //ITNPI-3372 starts here:
                         String authUsers = ql.SBQQ__Product__r.Quotable_by_users__c?.stripHtmlTags();
                         
                         // Early exit if the product is quotable by everyone
                         if(String.isNotBlank(authUsers) && !authUsers.contains(UserInfo.getName())) {
                             SBQQ__QuoteLine__c newItem = newMap.get(ql.Id);
                             Boolean isM365Credit = newItem.Product_Type__c == CPQ_Constants.Product_Type_M365_ZRS &&
                                 newItem.Product_Subtype__c == CPQ_Constants.Product_Subtype_Credit;
                             // Trigger error if:// 1. It's NOT the M365 Credit product (general restriction)// 2. OR it IS the M365 Credit but the quantity was modified
                             if (!isM365Credit || (oldMap.containsKey(ql.Id) && newItem.SBQQ__Quantity__c != oldMap.get(ql.Id).SBQQ__Quantity__c)) {
                                    isUserError = true;
                                }
                            }
                         else if((String.isNotBlank(ql.SBQQ__Product__r.Quotable_By_Profiles__c) && 
                                  !ql.SBQQ__Product__r.Quotable_By_Profiles__c.contains(ql.SBQQ__Quote__r.Running_User_Profile__c))){
                                      isUserError = true;                     
                    }
                     }
                    //ITNPI-3372 ends here:
                    
                    if((isUserError || isProfileError) && !Test.isRunningTest()){
                        newMap.get(ql.Id).addError(System.label.Quotable_Validation_Message);
                    }
                }
                
            }
        }
        
    } 
    
    //CPQ22-4821 Ends here
    
    //CPQ22-5034 starts here
    /**
     * @description : This method is used to validate quotable by countries.
     * * @param newMap Map of SBQQ__QuoteLine__c records being inserted or updated.
     * @param qlMap Map of existing SBQQ__QuoteLine__c records.
     * @param isInsert Boolean indicating if the operation is an insert.
     */
    public static void quotableByCountriesValidation(Map<Id,SBQQ__QuoteLine__c> newMap,Map<Id,SBQQ__QuoteLine__c> qlMap, Boolean isInsert){
        //System.debug(LoggingLevel.INFO, 'Records newMap5034 '+newMap.values());
        List<SBQQ__QuoteLine__c> qlProcessList = new List<SBQQ__QuoteLine__c>();
        if(allQLIRec!= null && !allQLIRec.isEmpty()){
            qlProcessList.addAll(allQLIRec);
        }else if(qlMap!= null && !qlMap.isempty()){
            qlProcessList.addAll(qlMap.values());
        }
        System.debug(LoggingLevel.INFO, 'qlProcessList5034  '+qlProcessList.size());
        if(!qlProcessList.isEmpty()){                       
            for(SBQQ__QuoteLine__c ql : qlProcessList){
                Boolean isCountryError = false;            
                if(newMap.containsKey(ql.Id) && ql.Quote_Line_Type__c == 'New' && ql.SBQQ__Quote__r.SBQQ__Status__c != 'Approved' && ql.SBQQ__Quote__r.ApprovalStatus__c != 'Approved'){
                    //QL Is Insert                  
                    if(isInsert && ql.SBQQ__number__c == null){
                        //System.debug(LoggingLevel.INFO, 'isInsert record' +ql.SBQQ__ProductCode__c);
                        if(!String.isBlank(ql.SBQQ__Product__r.Quotable_By_Countries__c)){
                            if(ql.SBQQ__Product__r.Quotable_By_Countries__c.contains(ql.SBQQ__Quote__r.SBQQ__BillingCountry__c)&& ql.SBQQ__Product__r.Allow_mentioned_Countries_to_Quote__c == true){
                                continue;
                            }
                            else{
                                isCountryError = true;
                            }
                        }
                        
                    }else if(!isInsert){//QL is Updated                        
                            System.debug(LoggingLevel.INFO, 'isUpdate record' +isInsert);
                        if(!String.isBlank(ql.SBQQ__Product__r.Quotable_By_Countries__c)){
                            if(ql.SBQQ__Product__r.Quotable_By_Countries__c.contains(ql.SBQQ__Quote__r.SBQQ__BillingCountry__c)&& ql.SBQQ__Product__r.Allow_mentioned_Countries_to_Quote__c == true){
                                continue;
                            }
                            else{
                                isCountryError = true;
                            }
                        }
                    }
                
                    if(isCountryError){
                        newMap.get(ql.Id).addError(System.label.Quotable_By_Country_Validation_Message);
                    }
                }
                
            }
        }
        
    } 
    //CPQ22-5034 ends here
    /**
     * @description : This method is used to populate fields on Quote Line during insert operation.
     * @param newQuoteLines Map of SBQQ__QuoteLine__c records being inserted.
     */
    public static void populateFieldsOnQuoteLine(Map<Id,SBQQ__QuoteLine__c> newQuoteLines){            
        if(newQuoteLines!=null && newQuoteLines.size()>0){
            if (System.IsBatch() == false && System.isFuture() == false && System.isQueueable() == false) {
                updateQuoteLines(newQuoteLines.keySet());
            }         
        }    
    }
    
    //RWD-1013/RWD-382
    /**
     * @description : This method is used to populate Reinstatement Fee SKU default value on Quote Line.
     * @param newQuoteLines Map of SBQQ__QuoteLine__c records being inserted/updated.
     */
    public static void populateReinstatementFeeSkuDefaultValue(List<SBQQ__QuoteLine__c> newQuoteLines){            
        for(SBQQ__QuoteLine__c quoteLine : newQuoteLines){
            if(quoteLine.RnStatemntFee_included__c == false && 
               quoteLine.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal' &&
               (quoteLine.SBQQ__ProductCode__c == 'RBK-REINSTATE-FEE' || 
                quoteLine.SBQQ__ProductCode__c == 'RA-REINST-FEE-PP')){
                    quoteLine.RnStatemntFee_included__c = true;
                }
        }
    }

    /**
     * @description : This class is used to hold the context for Terms and Conditions.
     * @param   quoteLineIds : The Ids of the Quote Lines.
     */
    @future
    public static void updateQuoteLines(Set<Id> quoteLineIds){
        List<SBQQ__QuoteLine__c> quotelinesToUpdate = new List<SBQQ__QuoteLine__c>();
        if(Schema.sObjectType.SBQQ__QuoteLine__c.isAccessible()){
            List<SBQQ__QuoteLine__c> quoteLines = [select Id, SBQQ__Hidden__c, SBQQ__Optional__c from SBQQ__QuoteLine__c where Id IN:quoteLineIds and SBQQ__Product__r.Legacy_Software_Bundle__c = true and SBQQ__Quote__r.SBQQ__Type__c = 'Renewal'];
            System.debug(LoggingLevel.INFO, 'quotelines===' + quoteLines.size());
            if(quoteLines!=null && quoteLines.size()>0){
                for(SBQQ__QuoteLine__c quoteLine:quoteLines){
                    if(quoteLine.SBQQ__Hidden__c == false || quoteLine.SBQQ__Optional__c == false){
                        quoteLine.SBQQ__Hidden__c = true;
                        quoteLine.SBQQ__Optional__c = true; 
                        quotelinesToUpdate.add(quoteLine);
                    }
                } 
            }
            System.debug(LoggingLevel.INFO, 'quotelinesToUpdate===' + quotelinesToUpdate.size());
            if(quoteLinesToUpdate!=null && quotelinesToUpdate.size()>0){
                Database.update(quoteLinesToUpdate);
            }
        }
    }
    
    //CPQ22-937 Starts
    /**
    * Ticket:-PRDOPS21-206
    * Author:- Rahul P
    * @description :- send notification if quoteline is changed after corresponding order is Accepted/Shipped
    **/
    public static void quoteOrderNotification () {
        //System.debug('New Map Values ' + Trigger.newMap.values());
        //System.debug('Old Map Values ' + Trigger.oldMap.values());
        Map<Id,SBQQ__QuoteLine__c> newMap = (Map<Id,SBQQ__QuoteLine__c>)Trigger.newMap;
        Map<Id,SBQQ__QuoteLine__c> oldMap = (Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap;
        List<SBQQ__QuoteLine__c> NewList = (List<SBQQ__QuoteLine__c>)Trigger.new;
        List<SBQQ__QuoteLine__c> QuoteList;
        if(Trigger.isInsert){
            QuoteList = Trigger.New;
        }
        if(!Trigger.isInsert){
            QuoteList = Trigger.Old;
        }
        Map<Id,List<SBQQ__QuoteLine__c>> quoteLineMap = new Map<Id,List<SBQQ__QuoteLine__c>>();
        for(SBQQ__QuoteLine__c qoteLine : QuoteList){
            //GLCR-101 - Added Approved status so that this logic does not run unnecessary before approved status on quote
            if(qoteLine.SBQQ__Quote__c != null  && ((Trigger.isInsert) || (newMap.get(qoteLine.Id).Quote_Status__c != null && newMap.get(qoteLine.Id).Quote_Status__c == 'Approved' && newMap.get(qoteLine.Id).QuoteChangedEmailBody__c == null && oldMap.get(qoteLine.Id).QuoteChangedEmailBody__c == null)) && !processedQuoteLines.contains(qoteLine.Id)){
            //if(qoteLine.SBQQ__Quote__c != null  && ((Trigger.isInsert && (qoteLine.Quote_Status__c != null && qoteLine.Quote_Status__c == 'Approved')) || (newMap.get(qoteLine.Id).Quote_Status__c != null && newMap.get(qoteLine.Id).Quote_Status__c == 'Approved' && newMap.get(qoteLine.Id).QuoteChangedEmailBody__c == null && oldMap.get(qoteLine.Id).QuoteChangedEmailBody__c == null)) && !processedQuoteLines.contains(qoteLine.Id)){    
                if(quoteLineMap.containsKey(qoteLine.SBQQ__Quote__c)){
                    quoteLineMap.get(qoteLine.SBQQ__Quote__c).add(qoteLine);
                }
                else{
                    quoteLineMap.put(qoteLine.SBQQ__Quote__c,new List<SBQQ__QuoteLine__c>{qoteLine});
                }
                processedQuoteLines.add(qoteLine.Id);
            }
        }
        //GLCR-101 - Call method only if quoteLineMap is not empty
        if(!quoteLineMap.isEmpty()){
        SBQQ_QuoteLineTriggerHelper.quoteOrderNotification(quoteLineMap.keySet(),quoteLineMap,SBQQ__QuoteLine__c.SobjectType);     
    }
    }
    
    /**
    *Ticket:-PRDOPS21-206
    *Author:- Rahul P
    * @description :- send notification if quoteline is changed after corresponding order is Accepted/Shipped
    * @param setQuotes Set of Quote Ids to be processed.
    * @param lstSobjToCheck Map of Ids to List of sObject records to be processed.
    * @param sobj Schema.sObjectType of the object being processed.
    **/
    public static void quoteOrderNotification(Set<Id> setQuotes,Map<Id,List<Sobject>>lstSobjToCheck, Schema.sObjectType sobj){
        if(lstOrders == null){
            if(Schema.sObjectType.Order.isAccessible()){
                lstOrders = [SELECT Id,SBQQ__Quote__c,SBQQ__Quote__r.Name,SBQQ__Quote__r.SBQQ__NetAmount__c,OrderNumber FROM Order where SBQQ__Quote__c IN :setQuotes AND (Order_Status__c !='Rejected' AND Order_Status__c !='Returned')];     
            }   
        }
        //List<Order> lstOrders = [SELECT Id,SBQQ__Quote__c,SBQQ__Quote__r.Name,SBQQ__Quote__r.SBQQ__NetAmount__c,OrderNumber FROM Order where SBQQ__Quote__c IN :setQuotes AND (Order_Status__c !='Rejected' AND Order_Status__c !='Returned')];        
        Map<String,String> quoteNameLstOrderNames = new Map<String,String>();
        Map<String,Id> orderMap = new Map<String,Id>();
        Boolean isChanged;
        Map<String,Sobject> mapAffectedSobject = new Map<String,Sobject>();
        if(lstOrders.size() > 0){
            for(Order ord : lstOrders){
                if(lstSobjToCheck != null && ord != null && ord.SBQQ__Quote__c != null && lstSobjToCheck.get(ord.SBQQ__Quote__c) != null){
                    for(Sobject qoteLine : lstSobjToCheck.get(ord.SBQQ__Quote__c)){
                        if(!Trigger.isInsert){
                            isChanged = false;             
                            for(Schema.FieldSetMember fld :sobj.getDescribe().FieldSets.getMap().get('Order_Quote_Change_Notification').getFields()) {
                                if(qoteLine.get(fld.getFieldPath()) != Trigger.oldMap.get(qoteLine.Id).get(fld.getFieldPath())){
                                    isChanged = true;
                                    break;
                                }
                            } 
                            if(isChanged){
                                if(quoteNameLstOrderNames.containsKey(ord.SBQQ__Quote__r.Name)){
                                    String orderNames = quoteNameLstOrderNames.get(ord.SBQQ__Quote__r.Name);
                                    orderNames += ','+ord.OrderNumber;
                                    quoteNameLstOrderNames.put(ord.SBQQ__Quote__r.Name,orderNames);
                                }
                                else{
                                    quoteNameLstOrderNames.put(ord.SBQQ__Quote__r.Name,ord.OrderNumber);
                                }
                                orderMap.put(ord.OrderNumber,ord.Id);
                                mapAffectedSobject.put(ord.SBQQ__Quote__r.Name,qoteLine);
                                break;
                            }
                        }else if(Trigger.isInsert){
                            quoteNameLstOrderNames.put(ord.SBQQ__Quote__r.Name,ord.OrderNumber); 
                            mapAffectedSobject.put(ord.SBQQ__Quote__r.Name,qoteLine);
                        }
                    }
                }
            }
            if(!quoteNameLstOrderNames.isEmpty()){
                String usersThatModified = UserInfo.getFirstName()+' '+UserInfo.getLastName();
                for(String quoteName : quoteNameLstOrderNames.keySet()){
                    String body = 'Quote '+quoteName+' on Order ';
                    
                    for(String orderNumber : quoteNameLstOrderNames.get(quoteName).split(',')){
                        body += '<a target="_blank" href="'+URL.getSalesforceBaseUrl().toExternalForm() +'/' + orderMap.get(orderNumber)+'">'+orderNumber+'</a> ' + ',';
                    }
                    
                    body += ' was updated by '+UserInfo.getFirstName()+' '+UserInfo.getLastName();
                    mapAffectedSobject.get(quoteName).put('QuoteChangedEmailBody__c',body);
                }
                System.debug(LoggingLevel.INFO, '#Success *** Exit SBQQ_QuoteLineTriggerHelper.quoteOrderNotification() ***');
            }
        }
    }
    //CPQ22-937 Ends
    // SF 8332 starts
    /**
     * @description : This method is used to validate Quote Lines based on Opportunity Stage.
     * @param quotelines Map of SBQQ__QuoteLine__c records being processed.
     * @param RelatedobjectInfo Map of related SBQQ__QuoteLine__c records.
     */
    public static void validateQuoteLines(Map<Id,SBQQ__QuoteLine__c> quotelines,Map<Id,SBQQ__QuoteLine__c> RelatedobjectInfo){
        if(!quotelines.isEmpty() && RelatedobjectInfo != null && !RelatedobjectInfo.isEmpty()){
            SBQQ__QuoteLine__c qlRecord;
            for(SBQQ__QuoteLine__c ql : RelatedobjectInfo.values()){
                if(ql.SBQQ__Quote__r.Opportunity_Stage__c == '6 PO With Channel'|| ql.SBQQ__Quote__r.Opportunity_Stage__c == '7 Closed Won' || ql.SBQQ__Quote__r.Opportunity_Stage__c == '7 Closed Lost' || ql.SBQQ__Quote__r.Opportunity_Stage__c == '7 Closed Admin'){
                    qlRecord = quotelines.get(ql.Id);
                    if(!Test.isRunningTest()){
                        qlRecord.addError('The quoteline cannot be edited if the Opportunity is at Stage 6 PO with Channel, Stage 7 Closed Won, Stage 7 Closed Lost or Stage 7 Closed Admin.');
                    }
                    break;  
                }
                //CPQ22-2174
                /*if(ql.SBQQ__Product__r.Name.contains('RSCP') && ql.SBQQ__Product__r.Bundle_Features__c.contains('OnPrem CDM') && 
                   ((
                       ql.SBQQ__Quote__r.Is_Federal_Eligible_Quote__c == False && 
                       (ql.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c == null || 
                        (ql.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c != null && !ql.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c.containsIgnoreCase('Exception for On-Prem Quoting'))
                       ))
                    ||
                    (
                        ql.SBQQ__Quote__r.Is_Federal_Eligible_Quote__c == True && 
                        (ql.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c != null && ql.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c.containsIgnoreCase('Exception for On-Prem Quoting'))
                    )
                   )   
                  ) {
                      qlRecord = quotelines.get(ql.Id);
                      if(!Test.isRunningTest()) {
                          qlRecord.addError('The RSC SKUs are not available for quoting on this Quote.');    
                      }
                      break;  
                  }*/ //CPQ22-3866
            }   
        }  
    }// SF 8332 Ends
    
    /**
     * @description : Build underSF-8787, This method is created to query related object data of QLI on SBQQ_QuoteLineTriggerHandler.
     * @param QLIIds Set of SBQQ__QuoteLine__c Ids to be processed.
     * @return Map of SBQQ__QuoteLine__c records with their related object information.
     */
    public static Map<id,SBQQ__QuoteLine__c> getQLIRelatedObjectInfo(set<id> QLIIds){
        Map<id,SBQQ__QuoteLine__c> QLIMap;
        if(QLIIds != null && !QLIIds.isEmpty()){
            QLIMap = new Map<id,SBQQ__QuoteLine__c>([Select Id, SBQQSC__RenewedContractLine__c, SBQQ__Quote__r.Opportunity_Stage__c,SBQQ__Quote__r.ApprovalStatus__c, SBQQ__Product__r.Name, SBQQ__Product__r.Bundle_Features__c, SBQQ__Quote__r.Is_Federal_Eligible_Quote__c, SBQQ__Quote__r.RWD_Sales_Rep_Exception__c,SBQQ__Product__r.Quotable_by_users__c, SBQQ__Product__r.Quotable_By_Profiles__c,SBQQ__Quote__r.Running_User_Profile__c,SBQQ__Quote__r.Running_User_Record__c,Quote_Line_Type__c,SBQQ__Quote__r.SBQQ__BillingCountry__c,SBQQ__Quote__r.SBQQ__Status__c,SBQQ__Product__r.Quotable_By_Countries__c,SBQQ__Product__r.Allow_mentioned_Countries_to_Quote__c
                                                    from SBQQ__QuoteLine__c where Id IN:QLIIds]);
        }
        return QLIMap;
    }

    /**
     * @description : This method is used to validate the Add-On Date Check policy.
     * @param qliIds Set of SBQQ__QuoteLine__c Ids to be processed.
     * @param isOnDelete
     */
    @future
    public static void datePolicy(Set<Id> qliIds, Boolean isOnDelete) {
        Map<Id, Date> accEntMap = new Map<Id, Date>();
        List<SBQQ__Quote__c> quoteToUpdate = new List<SBQQ__Quote__c>();
        Set<Id> accountId = new Set<Id>(); 
        Map<Id, SBQQ__Quote__c> quoteIdAndQuoteForTrue = new Map<Id, SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> quoteIdAndQuoteForFalse = new Map<Id, SBQQ__Quote__c>();
        List<SBQQ__QuoteLine__c> newQlList = new List<SBQQ__QuoteLine__c>();
        //Set<SBQQ__Quote__c> quoteId = new Set<SBQQ__Quote__c>();

        Set<Id> setQuoteId = new Set<Id>();
        Map<Id, SBQQ__Quote__c> quoteIdVsQuoteContractNum = new Map<Id, SBQQ__Quote__c>();
        Set<Id> cliIds = new Set<Id>();
        String strContractNumber;
		Map<Id, Integer> quoteVsRemainingQL = new Map<Id, Integer>();
		Map<Id, Set<String>> quoteVsContractNames = new Map<Id, Set<String>>();
		Map<Id, ContractLineItem> cliMap = new Map<Id, ContractLineItem>();
        Map<Id, SBQQ__Quote__c> quoteIdVsQuote = new Map<Id, SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> quoteUpdateClone = new Map<Id, SBQQ__Quote__c>();
        
        newQlList = [SELECT Id,sbqq__quote__r.AddOn_Date_Check__c,sbqq__quote__r.SBQQ__Opportunity2__r.closedate,sbqq__quote__r.sbqq__SubscriptionTerm__c,sbqq__SubscriptionTerm__c, SBQQ__Product__r.License_Subtype__c,Line_Type__c,SBQQ__Product__r.Add_on_Level__c,SBQQ__EffectiveEndDate__c, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__r.SBQQ__Account__c,
                            SBQQSC__RenewedContractLine__c, SBQQSC__RenewedContractLine__r.SBQQSC__ContractNumber__c, SBQQSC__RenewedContractLine__r.ServiceContractId,SBQQSC__UpgradedContractLine__c,
                            SBQQ__Quote__r.CloneIteration__c, SBQQ__Quote__r.SBQQ__Source__c, SBQQ__Quote__r.SBQQ__Source__r.CloneIteration__c
                     FROM SBQQ__QuoteLine__c 
                     WHERE Id in :qliIds];
        for(SBQQ__QuoteLine__c qlIns :newQlList) {
            accountId.add(qlIns.SBQQ__Quote__r.SBQQ__Account__c );
            //CPQ22-5393  starts
			setQuoteId.add(qlIns.SBQQ__Quote__c);
            if (!quoteIdVsQuote.containsKey(qlIns.SBQQ__Quote__c)){
                quoteIdVsQuote.put(qlIns.SBQQ__Quote__c, qlIns.SBQQ__Quote__r);
            }
			if (qlIns.SBQQSC__RenewedContractLine__c != null) {
                cliIds.add(qlIns.SBQQSC__RenewedContractLine__c);
            } 
            if (qlIns.SBQQSC__UpgradedContractLine__c != null) {
                cliIds.add(qlIns.SBQQSC__UpgradedContractLine__c);
            } 
        }
        if(isOnDelete){
			for (SBQQ__QuoteLine__c ql : [SELECT Id, SBQQ__Quote__c, 
                                                SBQQSC__RenewedContractLine__c,
                                            SBQQSC__RenewedContractLine__r.SBQQSC__ContractNumber__c,
                                            SBQQSC__UpgradedContractLine__c,
                                            SBQQSC__UpgradedContractLine__r.SBQQSC__ContractNumber__c
                                             FROM SBQQ__QuoteLine__c 
                                            WHERE SBQQ__Quote__c IN :setQuoteId
                                            AND (SBQQSC__RenewedContractLine__c != null OR SBQQSC__UpgradedContractLine__c != null)]){
				Integer cnt = quoteVsRemainingQL.get(ql.SBQQ__Quote__c);
				if (cnt == null) {
                    quoteVsRemainingQL.put(ql.SBQQ__Quote__c, 1);
                } else {
                    quoteVsRemainingQL.put(ql.SBQQ__Quote__c, cnt + 1);
                }
			}
		}
        if (Schema.sObjectType.ContractLineItem.isAccessible()) {
            for (ContractLineItem cli : [SELECT Id, 
                                                ServiceContractId, 
                                                ServiceContract.ContractNumber,
                                                SBQQSC__ContractNumber__c     
                                        FROM ContractLineItem 
                                        WHERE Id IN :cliIds]) {
                cliMap.put(cli.Id, cli);
            }
        }
		for (SBQQ__QuoteLine__c ql : newQlList) {
            if(
                (cliMap.containsKey(ql.SBQQSC__RenewedContractLine__c) && cliMap.get(ql.SBQQSC__RenewedContractLine__c) != null) || 
                (cliMap.containsKey(ql.SBQQSC__UpgradedContractLine__c) && cliMap.get(ql.SBQQSC__UpgradedContractLine__c) != null)){
                ContractLineItem cli = cliMap.containsKey(ql.SBQQSC__RenewedContractLine__c) ? cliMap.get(ql.SBQQSC__RenewedContractLine__c) : cliMap.get(ql.SBQQSC__UpgradedContractLine__c);
				if (cli.ServiceContract != null && cli.ServiceContract.ContractNumber != null && String.isNotBlank(cli.ServiceContract.ContractNumber)) {
					strContractNumber = String.ValueOf(cli.ServiceContract.ContractNumber);
				}
			}
            if( String.isNotBlank(strContractNumber)){
                if (!quoteVsContractNames.containsKey(ql.SBQQ__Quote__c)) {
                    quoteVsContractNames.put(ql.SBQQ__Quote__c, new Set<String>());
                }
                    quoteVsContractNames.get(ql.SBQQ__Quote__c).add(strContractNumber);	
            }
        }
        //Clone Iteration 5393
         if(quoteIdVsQuote != null && quoteIdVsQuote.values().size() > 0)  {
                for(SBQQ__Quote__c qmap : quoteIdVsQuote.values()){
                    if(qmap.SBQQ__Source__c != null){
                        Integer sourceCloneIteration;
                        sourceCloneIteration = qmap.SBQQ__Source__r.CloneIteration__c == null ?
                                                1 :
                                                Integer.valueOf(qmap.SBQQ__Source__r.CloneIteration__c) + 1;
                        qmap.CloneIteration__c = sourceCloneIteration;
                        quoteUpdateClone.put(qmap.Id, qmap);
                    }
                }
            }
        //CPQ22-5393 ENDS
        For(Entitlement entIns :[SELECT Id,Product__c,Product__r.Product_Type__c, ServiceContractId,AccountId,EndDate from
                                 Entitlement where Status = 'Active' AND 
                                 (Product__r.Product_Type__c = 'RCDM Support' OR Product__r.Product_Type__c = 'HW Support') 
                                 and AccountId in :accountId]) {
                                     
                                     if(!accEntMap.containsKey(entIns.AccountId)) {
                                         accEntMap.put(entIns.AccountId, entIns.EndDate );
                                     }
                                     else {
                                         Date entDate = accEntMap.get(entIns.AccountId);
                                         if (entDate < entIns.EndDate) {
                                             accEntMap.put(entIns.AccountId, entIns.EndDate);
                                         }
                                     }    
                                 }
        
        if(accEntMap.size() > 0){
            for(SBQQ__QuoteLine__c ql :newQlList ) {
               if( ql.SBQQ__Product__r.License_Subtype__c == 'Add-On' && ql.SBQQ__Product__r.Add_on_Level__c != 'RCDM Add-On' && ql.Line_Type__c == 'New') {
                    
                    if(ql.SBQQ__EffectiveEndDate__c > accEntMap.get(ql.SBQQ__Quote__r.SBQQ__Account__c)) {
                        if(!quoteIdAndQuoteForTrue.containsKey(ql.SBQQ__Quote__c)) {
                            SBQQ__Quote__c quoteRec = new SBQQ__Quote__c (Id =ql.SBQQ__Quote__c,  AddOn_Date_Check__c = true);
                            quoteIdAndQuoteForTrue.put(ql.SBQQ__Quote__c,quoteRec);
                            
                        }
                    }
                    else if (ql.SBQQ__EffectiveEndDate__c==null && ql.sbqq__quote__r.SBQQ__Opportunity2__r.closedate!=null && (ql.sbqq__SubscriptionTerm__c!=null || ql.sbqq__quote__r.sbqq__SubscriptionTerm__c!=null)){
                        decimal term=null;
                        if(ql.sbqq__SubscriptionTerm__c!=null){
                            term=ql.sbqq__SubscriptionTerm__c;
                        }
                        else{
                            term=ql.sbqq__quote__r.sbqq__SubscriptionTerm__c;
                        }
                        if(term!=null){
                            if(ql.sbqq__quote__r.SBQQ__Opportunity2__r.closedate.addmonths(integer.valueof(term))>accEntMap.get(ql.SBQQ__Quote__r.SBQQ__Account__c)){
                                if(!quoteIdAndQuoteForTrue.containsKey(ql.SBQQ__Quote__c)) {
                                    SBQQ__Quote__c quoteRec = new SBQQ__Quote__c (Id =ql.SBQQ__Quote__c,  AddOn_Date_Check__c = true);
                                    quoteIdAndQuoteForTrue.put(ql.SBQQ__Quote__c,quoteRec);
                                    
                                }
                            }
                        }
                    }
                    if(!quoteIdAndQuoteForFalse.containsKey(ql.SBQQ__Quote__c) && !quoteIdAndQuoteForTrue.containsKey(ql.SBQQ__Quote__c) && ql.sbqq__quote__r.AddOn_Date_Check__c==true) {
                        
                        SBQQ__Quote__c quoteRec = new SBQQ__Quote__c (Id =ql.SBQQ__Quote__c,  AddOn_Date_Check__c = false);
                        quoteIdAndQuoteForFalse.put(ql.SBQQ__Quote__c,quoteRec);
                    }
                }
            }
        }

            //CPQ22-5393
            for(SBQQ__QuoteLine__c ql :newQlList ) {
                //CPQ22-5393 Starts
				if(quoteVsContractNames.containsKey(ql.SBQQ__Quote__c)) {
                   
					Set<String> setServiceContractNames = quoteVsContractNames.get(ql.SBQQ__Quote__c);
					Integer remaining = quoteVsRemainingQL.containsKey(ql.SBQQ__Quote__c) 
                                        ? quoteVsRemainingQL.get(ql.SBQQ__Quote__c) : 0;
					
                    if (setServiceContractNames != null && !setServiceContractNames.isEmpty() 
                    && ((remaining > 0 || remaining == null) || !isOnDelete)) {
                        
						SBQQ__Quote__c quoteRec = quoteIdVsQuoteContractNum.containsKey(ql.SBQQ__Quote__c) 
                                                    ? quoteIdVsQuoteContractNum.get(ql.SBQQ__Quote__c)
                                                    : new SBQQ__Quote__c (Id = ql.SBQQ__Quote__c);
                        quoteRec.AllContracts__c = String.join(new List<String>(setServiceContractNames), ', ');
                        quoteIdVsQuoteContractNum.put(ql.SBQQ__Quote__c, quoteRec);
					}
					else{
                        SBQQ__Quote__c quoteRec = new SBQQ__Quote__c (Id = ql.SBQQ__Quote__c,
													AllContracts__c = null);
						quoteIdVsQuoteContractNum.put(ql.SBQQ__Quote__c, quoteRec);
                    }
				}
                // Clone Iteration update
                if(quoteUpdateClone.containsKey(ql.SBQQ__Quote__c)){
                    SBQQ__Quote__c quoteRec = quoteIdVsQuoteContractNum.containsKey(ql.SBQQ__Quote__c) 
                                                    ? quoteIdVsQuoteContractNum.get(ql.SBQQ__Quote__c)
                                                    : new SBQQ__Quote__c (Id = ql.SBQQ__Quote__c);

                    quoteRec.CloneIteration__c =  quoteUpdateClone.get(ql.SBQQ__Quote__c).CloneIteration__c;                        
                    quoteIdVsQuoteContractNum.put(ql.SBQQ__Quote__c, quoteRec);
                }
            }
        list<sbqq__quote__c> quotestoupdate = new list<sbqq__quote__c>();
        if(!quoteIdAndQuoteForFalse.isempty()) {
            quotestoupdate.addall(quoteIdAndQuoteForFalse.values());
        }
        if(!quoteIdAndQuoteForTrue.isempty()){
            quotestoupdate.addall(quoteIdAndQuoteForTrue.values());
        }
        //CPQ22-5393 Starts
        if (!quoteIdVsQuoteContractNum.isEmpty()) {
            for (Id quoteId : quoteIdVsQuoteContractNum.keySet()) {
                // Avoid duplicate quote records in quotestoupdate
                Boolean alreadyAdded = false;
                for (SBQQ__Quote__c q : quotestoupdate) {
                    if (q.Id == quoteId) {
                        alreadyAdded = true;
						q.AllContracts__c = quoteIdVsQuoteContractNum.get(quoteId).AllContracts__c;
                        q.CloneIteration__c = quoteIdVsQuoteContractNum.get(quoteId).CloneIteration__c;
                        break;
                    }
                }
                if (!alreadyAdded) {
                    quotestoupdate.add(quoteIdVsQuoteContractNum.get(quoteId));
                }
            }
        } //CPQ22-5393 Ends
        if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable() && !quotestoupdate.isempty()){
            update quotestoupdate; 
        }
        SBQQ_QuoteLineTriggerHandler.recursionCheck = true;
    }
    //@future
    //POLARIS RWD-73 Make fields null when cloned
    /*public static void makeFieldsNullWhenCloned(Set<Id> QLlist){
        List<SBQQ__QuoteLine__c> recordsToUpdate = new List<SBQQ__QuoteLine__c>();
        for(Id qlId:QLlist){
            SBQQ__QuoteLine__c obj = new SBQQ__QuoteLine__c(Id = qlId);
            obj.isFieldNull__c = false;
            system.debug('obj.isFieldNull__c  '+ obj.isFieldNull__c);
            recordsToUpdate.add(obj);
        }
        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate;
        }
        
    }*/
    
    //CPQ22-1104 starts
    /**
     * @description : This method is used to validate the Subscribed Asset Ids on Quote Lines.
     * @param oldQliMap Map of existing SBQQ__QuoteLine__c records.
     * @param quoteLineRecords List of SBQQ__QuoteLine__c records being processed.
     */
    public static void validateSubscribedAssetIds(Map<Id,SBQQ__QuoteLine__c> oldQliMap, List<SBQQ__QuoteLine__c> quoteLineRecords){
        List<String> subsAssetNames = new List<String>();
        Integer countOfAssets;
        Boolean errorThrown = false;
        Set<Id> quoteIds = new Set<Id>();
        Map<Id, SBQQ__Quote__c> quoteDetails = new Map<Id, SBQQ__Quote__c>();
        
        for (SBQQ__QuoteLine__c lineObj : quoteLineRecords) {
            quoteIds.add(lineObj.SBQQ__Quote__c);
        }
        //added field Quoting_Desk_Exception__c in the query as part of SF-72381
        List<SBQQ__Quote__c> quotes = [Select Id, Name, SBQQ__Type__c,RWD_Deal_Ops_Exception__c,Quoting_Desk_Exception__c from SBQQ__Quote__c where Id IN: quoteIds];
        for (SBQQ__Quote__c quoteObj : quotes) {
            quoteDetails.put(quoteObj.Id, quoteObj);
        }
        /*if (quoteLineRecords.size() > 0) {
            
            for (SBQQ__QuoteLine__c lineRec : quoteLineRecords) {
                //If Line Type = New,get all Lines with Subscribed Asset Names. Count the number of Subscribed Asset Names.
                if (Test.isRunningTest() || (quoteDetails.containsKey(lineRec.SBQQ__Quote__c) && quoteDetails.get(lineRec.SBQQ__Quote__c).SBQQ__Type__c == 'Quote' && lineRec.Line_Type__c == 'New' && lineRec.SubscribedAssetNames__c != null)) {
                        subsAssetNames = lineRec.SubscribedAssetNames__c.split(',');
                        countOfAssets = subsAssetNames.size();
                        
                        //If PO = null, check eff Qty and count of Subs Asset Names. If not equal, error
                        if (lineRec.Product_Subtype__c == 'GO CNV' && lineRec.SBQQ__EffectiveQuantity__c != countOfAssets && 
                            (lineRec.SBQQ__EffectiveQuantity__c != oldQliMap.get(lineRec.id).SBQQ__EffectiveQuantity__c ||
                             lineRec.SubscribedAssetNames__c != oldQliMap.get(lineRec.id).SubscribedAssetNames__c)) {
                                 errorThrown = true;
                             } 
                    }
                //Exceptions for the validation not to fire
                // below If condition Change done as part of SF-72381, RWD_Deal_Ops_Exception__c is replaced with Quoting_Desk_Exception__c
                if (quoteDetails.get(lineRec.SBQQ__Quote__c).Quoting_Desk_Exception__c != null && 
                    (quoteDetails.get(lineRec.SBQQ__Quote__c).Quoting_Desk_Exception__c.contains('# of Assets match with Qty Exception'))) {
                        errorThrown = false;
                    }
                if (errorThrown == true) {
                    lineRec.addError('You cannot have Assets more or less than the Quantity. Please make necessary changes to Subscribed Asset Names');
                }
            }
        }*/
    }
    /*public static void populateSubscribedAssetIds(Map<Id,SBQQ__QuoteLine__c> oldQliMap, List<SBQQ__QuoteLine__c> quoteLineRecords){
        List<String> subsAssetNames = new List<String>();
        Map<String, Id> assetIdMap = new Map<String, Id>();
        Set<Id> quoteIds = new Set<Id>();
        Map<Id, SBQQ__Quote__c> quoteDetails = new Map<Id, SBQQ__Quote__c>();
        
        for (SBQQ__QuoteLine__c lineObj : quoteLineRecords) {
            quoteIds.add(lineObj.SBQQ__Quote__c);
        }
        List<SBQQ__Quote__c> quotes = [Select Id, Name, SBQQ__Type__c,RWD_Deal_Ops_Exception__c from SBQQ__Quote__c where Id IN: quoteIds];
        for (SBQQ__Quote__c quoteObj : quotes) {
            quoteDetails.put(quoteObj.Id, quoteObj);
        }
        if (quoteLineRecords.size() > 0) {
            for (SBQQ__QuoteLine__c lineRec : quoteLineRecords) {
                //If Line Type = New, get all Lines with Subscribed Asset Names. 
                if (lineRec.SubscribedAssetNames__c != oldQliMap.get(lineRec.id).SubscribedAssetNames__c) {
                    if (quoteDetails.containsKey(lineRec.SBQQ__Quote__c) && quoteDetails.get(lineRec.SBQQ__Quote__c).SBQQ__Type__c == 'Quote' && 
                        lineRec.Line_Type__c == 'New' && lineRec.SubscribedAssetNames__c != null) {
                            for (String assetName : lineRec.SubscribedAssetNames__c.split(',')) {
                                assetName = assetName.trim();
                                subsAssetNames.add(assetName);
                            }
                        }
                }
            }
            List<Asset> assetList = [SELECT Id, Name FROM Asset WHERE Name IN :subsAssetNames];
            for (SBQQ__QuoteLine__c lineRec : quoteLineRecords) {
                //Get all IDs related to Subscribed Asset Names and populate it on Subscribed Asset Ids
                for (Asset ast : assetList) {
                    assetIdMap.put(ast.Name, ast.Id);
                }
                String nameStr = '';
                if ((lineRec.SubscribedAssetNames__c != null && assetIdMap.size()>0)) {
                    for(String assetName : lineRec.SubscribedAssetNames__c.split(',')) {
                        assetName = assetName.trim();
                        nameStr += assetIdMap.get(assetName)+', ';
                    }
                    lineRec.SBQQ__SubscribedAssetIds__c = nameStr.removeEnd(', ');
                }
            }
        }
    }*/
    //CPQ22-1104 ends
    
    /*
//CPQ22-626 starts    
public static void createQuoteLineFromAPI(List<SBQQ__QuoteLine__c> quoteList,Set<Id> quotIdSet, Date quotRangeStart, Date quotRangeEnd){
Set<Id> renewalQuoteIds = new Set<Id>();
Set<Id> quoteIds = new Set<Id>();
Set<Id> updateQuoteIds = new Set<Id>();
Set<Id> quoteListCreate = new Set<Id>();
List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
for( SBQQ__QuoteLine__c qut:quoteList){
if(qut.SBQQ__Quote__r.SBQQ__Type__c == 'Quote') {
quoteIds.add(qut.Id);
}
else if(qut.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal') {
if(qut.SBQQ__Quote__r.SBQQ__Opportunity2__c!=null){
//oppId.add(qut.SBQQ__Quote__r.SBQQ__Opportunity2__c);
renewalQuoteIds.add(qut.Id);
}
}
}
system.debug('XYQuoteId'+quoteIds);
if(quoteIds != null && !quoteIds.isEmpty()) {

List<SBQQ__QuoteLine__c> qliList = [Select Id, SBQQ__ProductCode__c,SBQQ__Quote__c, SBQQ__Quote__r.IsRCDMAdded__c
from SBQQ__QuoteLine__c
where Id IN:quoteIds];
system.debug('ZZZQuoteList'+qliList);
for(SBQQ__QuoteLine__c objLine : qliList) {
if(String.valueOF(objLine.SBQQ__ProductCode__c).StartsWith('RS-')) {
quoteListCreate.add(objLine.SBQQ__Quote__c);
if(objLine.SBQQ__Quote__r.IsRCDMAdded__c == false) {
objLine.SBQQ__Quote__r.IsRCDMAdded__c = true;
lstQuote.add(objLine.SBQQ__Quote__r);
}
}
}
} 
if(!quoteListCreate.isEmpty()){
//cpqAPICall(quoteListCreate);
system.debug('ZZZYYY'+quoteListCreate);
for(Id quot: quoteListCreate){
QuoteReader reader = new QuoteReader();
if(quot!=null){
QuoteModel quoteModel = reader.read(String.valueOf(quot));
System.debug('Check'+quoteModel);


ProductReader reader1 = new ProductReader();
ProductModel productModel = reader1.read(System.Label.RCDM_ProductId,System.Label.RCDM_PBEId,'USD');
System.debug('Check'+productModel);


List<ProductModel> productModels = new List<ProductModel>();
productModels.add(productModel);
ProductAdder adder = new ProductAdder();
QuoteModel quoteWithProducts = adder.add(quoteModel, productModels, 0);
System.debug('Check'+quoteWithProducts);
System.debug('CheckLine'+quoteWithProducts.lineItems);

QuoteSaver saver = new QuoteSaver();
QuoteModel savedQuote = saver.save(quoteWithProducts);
System.debug(quoteWithProducts);
}
}
SBQQ__QuoteLine__c objLine = [SELECT Id, SBQQ__Quote__r.SBQQ__StartDate__c, SBQQ__Quote__r.SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c, SBQQ__Discount__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Quote__r.SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__c =: System.Label.RCDM_ProductId AND SBQQ__Quote__c IN: lstQuote];

objLine.SBQQ__Discount__c = 100;
objLine.SBQQ__StartDate__c = objLine.SBQQ__Quote__r.SBQQ__StartDate__c != null ? objLine.SBQQ__Quote__r.SBQQ__StartDate__c : Date.today();

objLine.SBQQ__EndDate__c =  objLine.SBQQ__Quote__r.SBQQ__EndDate__c != null && objLine.SBQQ__Quote__r.SBQQ__EndDate__c < quotRangeEnd ? objLine.SBQQ__Quote__r.SBQQ__EndDate__c : objLine.SBQQ__Quote__r.SBQQ__EndDate__c == null ? null : quotRangeEnd;

Decimal subTerm = objLine.SBQQ__EndDate__c != null ? objLine.SBQQ__Quote__r.SBQQ__StartDate__c.monthsBetween(objLine.SBQQ__EndDate__c) : objLine.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;

objLine.SBQQ__SubscriptionTerm__c = subTerm;
objLine.SBQQ__NetPrice__c = 0;

System.debug('>> LATER UPDATE: '+objLine);
update objLine;
}
system.debug('Check: '+quoteListCreate);
if(!lstQuote.isEmpty()) {
update lstQuote;
}
}//CPQ22-626 ends

@future
public static void createQuoteLineFromAPIRenewal(Set<Id> quotIdSet, Date quotRangeStart, Date quotRangeEnd){
Set<Id> renewalQuoteIds = new Set<Id>();
Set<Id> quoteIds = new Set<Id>();
Set<Id> updateQuoteIds = new Set<Id>();
Set<Id> quoteListCreate = new Set<Id>();
System.debug('>>> quotIdSet: '+quotIdSet);
List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();

if (quotIdSet != null && !quotIdSet.isEmpty()) {

List<SBQQ__QuoteLine__c> qliList = [Select Id, SBQQ__ProductCode__c,
SBQQSC__RenewedContractLine__r.SBQQSC__ProductName__c,
SBQQSC__RenewedContractLine__c , SBQQ__Quote__r.IsRCDMAdded__c
from SBQQ__QuoteLine__c
where SBQQ__Quote__c IN: quotIdSet];
if(!qliList.isEmpty()){
for(SBQQ__QuoteLine__c qli:qliList){
system.debug('ChecGowRenwew'+qli.SBQQSC__RenewedContractLine__c);
if(qli.SBQQSC__RenewedContractLine__c!=null){
system.debug('RenewProdMName'+qli.SBQQSC__RenewedContractLine__r.SBQQSC__ProductName__c);
String renewContractName = qli.SBQQSC__RenewedContractLine__r.SBQQSC__ProductName__c;
system.debug('RenewProdMName - '+renewContractName.startsWith('RBK-'));
system.debug('SBQQ__ProductCode__c- '+qli.SBQQ__ProductCode__c.startsWith('RS-'));
if(renewContractName.startsWith('RBK-') && qli.SBQQ__ProductCode__c.startsWith('RS-')){
quoteListCreate.addAll(quotIdSet);
if(qli.SBQQ__Quote__r.IsRCDMAdded__c == false) {
qli.SBQQ__Quote__r.IsRCDMAdded__c = true;
lstQuote.add(qli.SBQQ__Quote__r);
}
}   
}
}
}
}
if(!quoteListCreate.isEmpty()){
//cpqAPICall(quoteListCreate);
system.debug('ZZZYYY'+quoteListCreate);
for(Id quot: quoteListCreate){
QuoteReader reader = new QuoteReader();
if(quot!=null){
QuoteModel quoteModel = reader.read(String.valueOf(quot));
System.debug('Check'+quoteModel);


ProductReader reader1 = new ProductReader();
ProductModel productModel = reader1.read(System.Label.RCDM_ProductId,System.Label.RCDM_PBEId,'USD');
System.debug('Check'+productModel);


List<ProductModel> productModels = new List<ProductModel>();
productModels.add(productModel);
ProductAdder adder = new ProductAdder();
QuoteModel quoteWithProducts = adder.add(quoteModel, productModels, 0);
System.debug('Check'+quoteWithProducts);
System.debug('CheckLine'+quoteWithProducts.lineItems);

QuoteSaver saver = new QuoteSaver();
QuoteModel savedQuote = saver.save(quoteWithProducts);
System.debug(quoteWithProducts);
}
}
SBQQ__QuoteLine__c objLine = [SELECT Id, SBQQ__Quote__r.SBQQ__StartDate__c, SBQQ__Quote__r.SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c, SBQQ__Discount__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Quote__r.SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__c =: System.Label.RCDM_ProductId AND SBQQ__Quote__c IN: lstQuote];

objLine.SBQQ__Discount__c = 100;
objLine.SBQQ__StartDate__c = objLine.SBQQ__Quote__r.SBQQ__StartDate__c != null ? objLine.SBQQ__Quote__r.SBQQ__StartDate__c : Date.today();

objLine.SBQQ__EndDate__c =  objLine.SBQQ__Quote__r.SBQQ__EndDate__c != null && objLine.SBQQ__Quote__r.SBQQ__EndDate__c < quotRangeEnd ? objLine.SBQQ__Quote__r.SBQQ__EndDate__c : objLine.SBQQ__Quote__r.SBQQ__EndDate__c == null ? null : quotRangeEnd;

Decimal subTerm = objLine.SBQQ__EndDate__c != null ? objLine.SBQQ__Quote__r.SBQQ__StartDate__c.monthsBetween(objLine.SBQQ__EndDate__c) : objLine.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;

objLine.SBQQ__SubscriptionTerm__c = subTerm;
objLine.SBQQ__NetPrice__c = 0;

System.debug('>> LATER UPDATE: '+objLine);
update objLine;    
}
system.debug('Check: '+quoteListCreate);
if(!lstQuote.isEmpty()) {
update lstQuote;
}  
}*/
    /*ARROYO 2.0: STARTS- Added by Sameer*/
    /**
     * @description : This method is used to stop the deletion of Renewal Quote Lines based on specific conditions.
     * @param qliList List of SBQQ__QuoteLine__c records being processed.
     * @param quoteIdRecordMap Map of SBQQ__Quote__c records.
     */
    public static void stopDeletionOfRenewalLines(List<SBQQ__QuoteLine__c> qliList,Map<Id,SBQQ__Quote__c> quoteIdRecordMap){
        System.debug(LoggingLevel.INFO, '**Entered stopDeletionOfRenewalLines qliList.size() '+qliList.size());
        
        //CPQ22-4401 exlcude Reinstatement
        for(SBQQ__QuoteLine__c quoteLine : qliList){
            if(quoteLine.Line_Type__c == 'Renewal'
               && quoteLine.Product_Type__c != 'HW Support' && quoteLine.Product_Type__c != 'Reinstate Fee' && quoteLine.Special_Program__c != 'Conversion'
               && quoteIdRecordMap.get(quoteLine.SBQQ__Quote__c).SBQQ__Type__c =='Renewal+Expansion'){
                   quoteLine.addError('Renewal quotelines can not be deleted.');
               }
        }
    }
    //ARROYO 2.0: ENDS- Added by Sameer
    
    /** updateApprovalIdentifierForDisposition*/
    /**
     * @description : This method updates the approval identifier for disposition lines based on specific conditions.
     * @param newQLIMap Map of SBQQ__QuoteLine__c records being processed.
     */
    public static void updateApprovalIdentifierForDisposition(Map<Id, SBQQ__QuoteLine__c> newQLIMap) {
        System.debug(LoggingLevel.INFO, '**Method: updateApprovalIdentifierForDisposition called**');
        
        Set<Id> quoteId = new Set<Id>();
        List<SBQQ__QuoteLine__c> qltoUpdate = new List<SBQQ__QuoteLine__c>();
        Map<String, String> mapProductCodeVsLineType = new Map<String, String>();
        Map<Id, SBQQ__QuoteLine__c> maptoupdateQL = new Map<Id, SBQQ__QuoteLine__c>();
        
        if(newQLIMap != null && !newQLIMap.IsEmpty()){
            for(SBQQ__QuoteLine__c qli : newQLIMap.values()) {
                //system.debug('QuoteIDValue:-> ' + qli.SBQQ__Quote__c);
                //system.debug('QuoteType:-> ' + qli.SBQQ__Quote__r.SBQQ__Type__c);
                if(qli.SBQQ__Quote__c != null && (qli.SBQQSC__RenewedContractLine__c == null || qli.Quote_Line_Type__c == 'New')) {
                    quoteId.add(qli.SBQQ__Quote__c);
                }
            }  
        }
        
         allQLIRec = [SELECT Id, SBQQ__Product__c, SBQQ__ProductCode__c,SBQQ__number__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, 
                                              Required_By_Product_Code__c, Subscribed_Asset_Name__c, SBQQ__ListPrice__c, 
                                              SBQQ__NetPrice__c, Do_not_Renew__c, Disposition_Reason__c, Quote_Line_Type__c, 
                                              Line_Type__c, QuoteLine_Group_Name__c, SBQQ__Group__c, SBQQ__SubscriptionPricing__c,SBQQ__Product__r.Quotable_by_users__c, SBQQ__Product__r.Quotable_By_Profiles__c,SBQQ__Product__r.Quotable_By_Countries__c,SBQQ__Product__r.Allow_mentioned_Countries_to_Quote__c,SBQQ__Quote__r.Running_User_Profile__c,SBQQ__Quote__r.Running_User_Record__c,SBQQ__Quote__r.SBQQ__BillingCountry__c,SBQQ__Quote__r.SBQQ__Status__c,SBQQ__Quote__r.ApprovalStatus__c,
                                              Is_Approval_Needed_for_Disposition_Lines__c FROM SBQQ__QuoteLine__c WHERE 
                                              SBQQ__Quote__c =: quoteId];
        
        if(allQLIRec != null && !allQLIRec.IsEmpty()){
            for(SBQQ__QuoteLine__c qliRec: allQLIRec){
                if(qliRec.Quote_Line_Type__c == 'New'){
                    mapProductCodeVsLineType.put(qliRec.SBQQ__ProductCode__c, qliRec.Quote_Line_Type__c);
                }
            }
        }
        
        
        if(allQLIRec != null && !allQLIRec.IsEmpty()) {
            for (SBQQ__QuoteLine__c ql: allQLIRec) 
            {
                if(ql.Quote_Line_Type__c == 'Renewal'){
                    //System.debug(LoggingLevel.INFO, 'A :-> ' + ql.SBQQ__ProductCode__c);
                    //System.debug(LoggingLevel.INFO, 'B :-> ' + mapProductCodeVsLineType.containsKey(ql.SBQQ__ProductCode__c));
                    //System.debug(LoggingLevel.INFO, 'C :-> ' + mapProductCodeVsLineType.get(ql.SBQQ__ProductCode__c));
                    //System.debug(LoggingLevel.INFO, 'D :-> ' + ql.Quote_Line_Type__c);
                    //System.debug(LoggingLevel.INFO, 'E :-> ' + ql.Disposition_Reason__c);
                    
                    if(mapProductCodeVsLineType != null &&
                       mapProductCodeVsLineType.containsKey(ql.SBQQ__ProductCode__c) && 
                       mapProductCodeVsLineType.get(ql.SBQQ__ProductCode__c) != null &&
                       mapProductCodeVsLineType.get(ql.SBQQ__ProductCode__c) != ql.Quote_Line_Type__c &&
                       (ql.Disposition_Reason__c == 'Churn')) //|| ql.Disposition_Reason__c == 'Renew Later' 
                        //ql.SBQQ__ProductCode__c == 'RS-HW-SVC-PE-S3' && ql.Quote_Line_Type__c != 'New'
                    {
                        ql.Is_Approval_Needed_for_Disposition_Lines__c = TRUE;
                        maptoupdateQL.put(ql.Id, ql);
                        qltoUpdate.add(ql);
                        
                    }
                    else if(!mapProductCodeVsLineType.containsKey(ql.SBQQ__ProductCode__c)){
                        //System.debug(LoggingLevel.INFO, 'Inside Else :-> ' + qltoUpdate);
                        //System.debug(LoggingLevel.INFO, 'PcodeZZ :-> ' + ql.SBQQ__Product__c);
                        ql.Is_Approval_Needed_for_Disposition_Lines__c = FALSE;
                        maptoupdateQL.put(ql.Id, ql);
                        qltoUpdate.add(ql);
                    }
                }
            }
        }
        if(Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable() && qltoUpdate != NULL && !qltoUpdate.isEmpty()){
            System.debug(LoggingLevel.INFO, 'Inside Update :-> ' + qltoUpdate.size());
            
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            
            update qltoUpdate;
            //System.debug(LoggingLevel.INFO, 'After Update :-> ' + qltoUpdate);
            
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            SBQQ.TriggerControl.enable();
        }
    }
    //ARROYO 2.0 End - ARY-71: Logic Added by Shaloo for Arroyo Approvals
    
    /*ARROYO 2.0 Start - ARY-71: Logic Added by Shaloo to populate Quote Group on new lines for Renewal+Expansion for Arroyo*/
    /**
     * @description : This method populates the Quote Line Group for Quote Lines based on specific conditions.
     * @param qliList List of SBQQ__QuoteLine__c records being processed.
     */
    public static void populateQuoteLineGroup(List < SBQQ__QuoteLine__c > qliList) {
        System.debug(LoggingLevel.INFO, '** populateQuoteLineGroup **' + qliList.size());
        Set < Id > quoteSet = new Set < Id > ();

        //if(qliList!=null && qliList.size()>0){
        if (qliList != null && !qliList.isEmpty()) {
            for (SBQQ__QuoteLine__c qli: qliList) {
                if(qli.Scale_Utility_Product__c == false && qli.Scale_Utility_Product_Identifier__c == null && qli.Scale_Utility_Product_RSV_OND__c == null) {
                    quoteSet.add(qli.SBQQ__Quote__c);
                }
            }
        }
        System.debug(LoggingLevel.INFO, 'quoteSet : ' + quoteSet);

        if (System.IsBatch() == false && System.isFuture() == false && quoteSet != null && !quoteSet.IsEmpty()) {
            System.debug(LoggingLevel.INFO, 'quoteSet1 : ' + quoteSet.size());
            populateQuoteLineGroupFuture(quoteSet);
        }
    }
   /**populateQuoteLineGroupFuture */
   /**
    * @description : This method is a future method that populates the Quote Line Group for Quote Lines based on specific conditions.
    * @param quoteSet Set of Ids representing the quotes to be processed.
    */
    @future
    public static void populateQuoteLineGroupFuture(Set<Id> quoteSet) {
        System.debug(LoggingLevel.INFO, '** populateQuoteLineGroupFuture ** : ' + quoteSet.size());
        
        Map<Id, Id> quotegroupmap = new Map<Id, Id>();
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate= new List<SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> qliMapToUpdate= new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> qliRcdmMap = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> qliParentRcdmMap = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> qliAllDataMap = new Map<Id, SBQQ__QuoteLine__c>();
        Id Quotegroupdes, Quotegrouprenew, QuotegroupExp;
        List<SBQQ__QuoteLineGroup__c> qlGroupToDelete = new List<SBQQ__QuoteLineGroup__c>(); //ARY-1079
        Boolean DonotdeleteDesposition = false;//ARY-1079

        if(quoteSet != null && !quoteSet.IsEmpty() && allARYQLIRecord == null) {
            allARYQLIRecord =[SELECT Id, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, SBQQ__Existing__c,
                              Required_By_Product_Code__c, Subscribed_Asset_Name__c, SBQQ__ListPrice__c, Special_Program__c, SBQQ__Renewal__c, 
                              SBQQ__NetPrice__c, Do_not_Renew__c, Disposition_Reason__c, Quote_Line_Type__c, SBQQSC__RenewedContractLine__c,
                              Line_Type__c, QuoteLine_Group_Name__c, SBQQ__Group__c, SBQQ__SubscriptionPricing__c, SBQQ__Quote__c, Product_Type__c, 
                              SBQQ__Quote__r.SBQQ__Type__c, Is_Approval_Needed_for_Disposition_Lines__c, Product_Level__c, 
                              SBQQ__Group__r.Name, SBQQ__Group__r.Is_Expansion_Group__c, 
                              After_Conversion_Product_Level__c, SBQQ__Product__r.Product_Level__c FROM SBQQ__QuoteLine__c WHERE 
                              SBQQ__Quote__c =: quoteSet];
        }
        System.debug(LoggingLevel.INFO, 'allARYQLIRecordSize: ' + allARYQLIRecord.size());
        
        for(SBQQ__QuoteLineGroup__c grp: [SELECT Id, Name, SBQQ__Quote__c, SBQQ__Description__c, SBQQ__Quote__r.SBQQ__Type__c,
                                          Is_Expansion_Group__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: quoteSet WITH SECURITY_ENFORCED])
        {
            System.debug(LoggingLevel.INFO, 'qlgrp: ' + grp.Name);
            if(grp.Name == System.Label.Arry_Disposition_Group){
                Quotegroupdes = grp.Id;
                qlGroupToDelete.add(grp);//ARY-1079
            }
            if(grp.Name == System.Label.Arry_renewal_Group){
                Quotegrouprenew = grp.Id;
            }
            if(grp.Name != System.Label.Arry_renewal_Group && grp.Name != System.Label.Arry_Disposition_Group
               //System.Label.Arry_expansion_group
              ){
                  QuotegroupExp = grp.Id;
              }
        }
        
        if(allARYQLIRecord != null && !allARYQLIRecord.IsEmpty()){
        qliAllDataMap.putAll(allARYQLIRecord);
            for(SBQQ__QuoteLine__c qli : allARYQLIRecord){
        //RCDM grouping
                if(qliAllDataMap!= null && qliAllDataMap.size() > 0 && qli.SBQQ__ProductCode__c == 'RS-BT-RCDM-T'){
                    qliRcdmMap.put(qli.Id, qli);
                    if(qli.SBQQ__RequiredBy__c != null){
                        qliParentRcdmMap.put(qli.SBQQ__RequiredBy__c, qliAllDataMap.get(qli.SBQQ__RequiredBy__c));
                        continue;
                    }                                                   
                }
                //System.debug('Quote Type' + qli.SBQQ__Quote__r.SBQQ__Type__c);
                //System.debug(LoggingLevel.INFO, '1: ' + qli.SBQQSC__RenewedContractLine__c);
                //System.debug(LoggingLevel.INFO, '2: ' + qli.Quote_Line_Type__c);
                //System.debug(LoggingLevel.INFO, '3: ' + qli.SBQQ__Group__c);
                //System.debug(LoggingLevel.INFO, '4: ' + qli.SBQQ__Group__r.Name);
                //System.debug(LoggingLevel.INFO, '6: ' + qli.Disposition_Reason__c);
                //System.debug(LoggingLevel.INFO, '7: ' + qli.SBQQ__Existing__c);
                //System.debug(LoggingLevel.INFO, '8: ' + qli.SBQQ__Renewal__c);
                //System.debug(LoggingLevel.INFO, '9: ' + qli.Special_Program__c);
                
                //CPQ22-4401 exclude renewal lines
                if((qli.SBQQSC__RenewedContractLine__c == null || qli.Quote_Line_Type__c == 'New') && qli.Quote_Line_Type__c!='Renewal'
                   && qli.SBQQ__Group__c != null && qli.SBQQ__Group__r.Name != null 
                   && (qli.SBQQ__Group__r.Name == System.Label.Arry_renewal_Group || qli.SBQQ__Group__r.Name == System.Label.Arry_Disposition_Group)
                   && (qli.Disposition_Reason__c == 'None' || qli.Disposition_Reason__c == null || qli.Disposition_Reason__c == '')
                   && !qli.SBQQ__Existing__c && !qli.SBQQ__Renewal__c
                   && qli.Special_Program__c == null && qli.SBQQ__ProductCode__c != 'RS-BT-RCDM-T'&& QuotegroupExp != null)
                {
                    //System.debug(LoggingLevel.INFO, 'Exp Id : ' + qli.Id);
                    qli.SBQQ__Group__c = QuotegroupExp;
                    quoteLinesToUpdate.add(qli);
                    qliMapToUpdate.put(qli.Id, qli);
                }
                if((qli.Disposition_Reason__c == 'None' || qli.Disposition_Reason__c == 'Renewing')
                   && Quotegrouprenew != null && qli.Quote_Line_Type__c == 'Renewal' && qli.SBQQ__Group__r.Name != System.Label.Arry_renewal_Group && qli.SBQQ__Group__r.Name != System.Label.Arry_expansion_group && qli.SBQQ__Group__r.Is_Expansion_Group__c == false)
                {
                    //System.debug(LoggingLevel.INFO, 'Ren Id : ' + qli.Id);
                    qli.SBQQ__Group__c = Quotegrouprenew;
                    quoteLinesToUpdate.add(qli);
                    qliMapToUpdate.put(qli.Id, qli);
                }
                if((qli.Disposition_Reason__c != null && qli.Disposition_Reason__c != 'Renewing' && qli.Disposition_Reason__c != 'None')
                   && Quotegroupdes != null && qli.SBQQ__Group__r.Name != System.Label.Arry_Disposition_Group 
                   && qli.SBQQ__Group__r.Name != System.Label.Arry_expansion_group
                   && qli.SBQQ__Group__r.Is_Expansion_Group__c == false)
                {
                    //System.debug(LoggingLevel.INFO, 'Disp Id : ' + qli.Id);
                    qli.SBQQ__Group__c = Quotegroupdes;
                    quoteLinesToUpdate.add(qli);
                    qliMapToUpdate.put(qli.Id, qli);
                }
            }
        }
        //ARY-1079 Starts
        for (SBQQ__QuoteLine__c qli : allARYQLIRecord) {
            if (qli.SBQQ__Group__c == Quotegroupdes) {
                DonotdeleteDesposition = true;
                break;
            }
        }//ARY-1079 Ends
        
        System.debug(LoggingLevel.INFO, 'qliParentRcdmMap' + qliParentRcdmMap.size());
        System.debug(LoggingLevel.INFO, 'qliRcdmMap' + qliRcdmMap.size());
if(qliRcdmMap.size() > 0){
for(Id index : qliRcdmMap.keySet()){
    if(qliRcdmMap.get(index) != null && qliParentRcdmMap.get(qliRcdmMap.get(index).SBQQ__RequiredBy__c) != null){
            SBQQ__QuoteLine__c rcdmLine = qliRcdmMap.get(index);
            SBQQ__QuoteLine__c parentLine = qliParentRcdmMap.get(rcdmLine.SBQQ__RequiredBy__c);
            System.debug(LoggingLevel.INFO, 'parentLine' + parentLine.Id);
            if(parentLine!= null){
            rcdmLine.SBQQ__Group__c = parentLine.SBQQ__Group__c;
            quoteLinesToUpdate.add(rcdmLine);
            }
        }       
            
    }   
}
        
        //ARY-1079 Starts
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        if (qlGroupToDelete != null && !qlGroupToDelete.isEmpty() && DonotdeleteDesposition == false) {
            if (Schema.sObjectType.SBQQ__QuoteLineGroup__c.isDeletable()) {
                delete qlGroupToDelete;
            }
        }
        if (Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable() && quoteLinesToUpdate != null && !quoteLinesToUpdate.isEmpty()) {
            Database.update(quoteLinesToUpdate);
            System.debug(LoggingLevel.INFO, 'quoteLinesToUpdateSize: ' + quoteLinesToUpdate.size());
        }
        SBQQ.TriggerControl.enable();
        //ARY-1079 Ends
    }
    //End - ARY-71: Logic Added by Shaloo to populate Quote Group on new lines for Renewal+Expansion for Arroyo
   /* public static void populateDiscountThreshold(List<SBQQ__QuoteLine__c> quoteLineList) {
        Set<Id> QuoteId = new Set<Id>();
        Set<Id> cliId = new Set<Id>();
        Map<String,String>mapQL_Location = new Map<String,String>();
        Map<String, List<Tier_Quantity_Range_lookup_Table__c >> maxDiscount = new Map<String, List<Tier_Quantity_Range_lookup_Table__c >>();
        for(Tier_Quantity_Range_lookup_Table__c  objmdt : [Select id,Quantity_Lower_Bound__c,Quantity_Upper_Bound__c,Location__c,Discount_RSM__c,Approval_Category__c  from Tier_Quantity_Range_lookup_Table__c]){
            List<Tier_Quantity_Range_lookup_Table__c > lstTempMdt = new List<Tier_Quantity_Range_lookup_Table__c >();
            lstTempMdt.add(objmdt);
            if(maxDiscount.containsKey(objmdt.Approval_Category__c)){
                maxDiscount.get(objmdt.Approval_Category__c).addAll(lstTempMdt);
            }else{
                maxDiscount.put(objmdt.Approval_Category__c,lstTempMdt);   
            }
        }
        for(SBQQ__QuoteLine__c objQL : [Select Id,SBQQSC__RenewedContractLine__c,SBQQ__Quote__r.ETM_Theatre__c,Approval_Category__c from SBQQ__QuoteLine__c where Id IN:quoteLineList]){
            if(objQL.SBQQSC__RenewedContractLine__c != null){
                cliId.add(objQL.SBQQSC__RenewedContractLine__c);
            }
            if(objQL.SBQQ__Quote__r.ETM_Theatre__c == 'APAC' || objQL.SBQQ__Quote__r.ETM_Theatre__c == 'EMEA'|| objQL.SBQQ__Quote__r.ETM_Theatre__c =='MM-LATAM-IAE'){
                
                mapQL_Location.put(objQL.Id,'Non-US');
            }
            else{
                mapQL_Location.put(objQL.Id,'US');
            }
        }
        Map<Id, ContractLineItem> mapCLI = new Map<Id, ContractLineItem>([Select id,SBQQSC__QuoteLine__c,SBQQSC__QuoteLine__r.Promo_Disc__c,SBQQSC__QuoteLine__r.SBQQ__Quote__c,SBQQSC__QuoteLine__r.SBQQ__Quote__r.CSAT_Reason__c,SBQQSC__QuoteLine__r.SBQQ__Discount__c,SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c,SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__c,SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__c,SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c,SBQQSC__QuoteLine__r.SBQQ__TotalDiscountRate__c, SBQQSC__QuoteLine__r.Total_Discount__c,Promo_Disc__c,SBQQSC__Discount__c from ContractLineItem where Id IN: cliId]);
        
        for(SBQQ__QuoteLine__c objQL : quoteLineList ){
            
            if(mapCLI.containsKey(objQL.SBQQSC__RenewedContractLine__c)){
                if( !mapCLI.isEmpty() && objQL.Line_Type__c == 'Renewal' 
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQ__Quote__r.CSAT_Reason__c != null
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQ__Discount__c > 99.9
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c > 0
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c != 100){
                       objQL.SBQQ__Discount__c = mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c;
                   }
                if(!mapCLI.isEmpty() && objQL.Line_Type__c == 'Renewal'
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQ__Quote__r.CSAT_Reason__c != null
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQ__Discount__c > 99.9
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__c != null
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__c != null
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c!= null
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c!= 0.00
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c!= 100.00){
                       objQL.SBQQ__Discount__c = mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Discount__c;
                   }
                if(!mapCLI.isEmpty() && objQL.Line_Type__c == 'Renewal' 
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.Promo_Disc__c > 0.000
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.Promo_Disc__c < 100.000
                   && (mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQ__TotalDiscountRate__c == 100.00
                       || mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.Total_Discount__c == 100.00)
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).Promo_Disc__c > 0.000
                   && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__Discount__c > 0.00){
                       objQL.SBQQ__Discount__c = mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__Discount__c ;
                   }
                
                
                if(objQL.Approval_Category__c !=  null && maxDiscount.containsKey(objQL.Approval_Category__c)){
                    for(Tier_Quantity_Range_lookup_Table__c  objMeta : maxDiscount.get(objQL.Approval_Category__c)){
                        if((objMeta.Quantity_Lower_Bound__c != null && objMeta.Quantity_Upper_Bound__c !=null && objQL.SBQQ__Quantity__c >= objMeta.Quantity_Lower_Bound__c && objQL.SBQQ__Quantity__c <= objMeta.Quantity_Upper_Bound__c) || (objMeta.Location__c != null && objMeta.Location__c == mapQL_Location.get(objQL.Id))){
                            
                            if(!mapCLI.isEmpty() && objQL.Line_Type__c == 'Renewal' 
                               && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.Promo_Disc__c == 100.000){
                                   objQL.SBQQ__Discount__c = objMeta.Discount_RSM__c ;
                                   
                               }
                            if(!mapCLI.isEmpty() && objQL.Line_Type__c == 'Renewal'
                               && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQ__Quote__r.CSAT_Reason__c != null
                               && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQ__Discount__c > 99.9
                               && (mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c == null
                                   || mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c == 0
                                   || mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.CPQ_Prior_Discount__c == 100)
                               && mapCLI.get(objQL.SBQQSC__RenewedContractLine__c).SBQQSC__QuoteLine__r.SBQQSC__RenewedContractLine__c == null){
                                   objQL.SBQQ__Discount__c = objMeta.Discount_RSM__c;
                               }
                        }
                    }
                }
            }
        }
    }*/
    
    //Arroyo 2.0 Hypercare Request Validation - Start
    /**
*Author: Shaloo Mishra
*Description: Throw a validation error message to the user when trying to blank out the Renewed Contract Line linkage on the renewal lines
*/
    /*public static void validateCLILinkages(Map<Id, SBQQ__QuoteLine__c> quotelines){
        system.debug('**Enter for validateCLILinkages method**');
        
        if(quotelines != null && !quotelines.isEmpty()){
            SBQQ__QuoteLine__c qlRecord;
            for(SBQQ__QuoteLine__c newQLI: (List<SBQQ__QuoteLine__c>)Trigger.new){
                SBQQ__QuoteLine__c oldQLI = (SBQQ__QuoteLine__c) Trigger.oldMap.get(newQLI.Id);
                
                //system.debug('Old QLI Id: ' + oldQLI.Id + ' & Old CLI Value: ' + oldQLI.SBQQSC__RenewedContractLine__c + ' & Old QLI Type: ' + oldQLI.Quote_Line_Type__c);
                //system.debug('New QLI Id: ' + newQLI.Id + ' & New CLI Value: ' + newQLI.SBQQSC__RenewedContractLine__c + ' & New QLI Type: ' + newQLI.Quote_Line_Type__c);
                
                if(newQLI.SBQQSC__RenewedContractLine__c == null && oldQLI.Quote_Line_Type__c == 'Renewal' && 
                   newQLI.SBQQSC__RenewedContractLine__c != oldQLI.SBQQSC__RenewedContractLine__c){
                       qlRecord = quotelines.get(newQLI.Id);
                       if(!Test.isRunningTest()){
                           //system.debug('qlRecord: ' + qlRecord.Id);
                           qlRecord.addError('You cannot update the Renewed Contract Line field on renewal quote line records.');
                       }
                       break;  
                   }
            }   
        }  
    }*/
    //Arroyo 2.0 Hypercare Request Validation - End

    /**
     * @description : This method sets the Source List Price, Default Term, and Option Percent of Total for Quote Lines based on their Source.
     * @param quoteLineIds Set of Ids representing the Quote Lines to be processed.
     * This method retrieves the Source Quote Line records and updates the Source List Price, Default Term, and Option Percent of Total fields on the Quote Lines.
     * It ensures that the Quote Lines are only updated if they have a valid Source and the necessary fields are set.
     * @param oldMap Map of old Quote Line records for comparison.
     */
       public static void setSourceListPrice(Set<Id> quoteLineIds, Map<Id, SBQQ__QuoteLine__c> oldMap){
        List<SBQQ__QuoteLine__c> quotelinesToUpdate = new List<SBQQ__QuoteLine__c>();
        Map<Id, Decimal> qliListTotal = new Map<Id, Decimal>();
        
        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, SBQQ__Source__c, SBQQ__DefaultSubscriptionTerm__c, SBQQ__ListPrice__c, Product_Option_Percent_of_Total__c, SBQQ__Source__r.Product_Option_Percent_of_Total__c, SBQQ__Source__r.SBQQ__DefaultSubscriptionTerm__c,
         SBQQ__Source__r.SBQQ__ListPrice__c, Prior_Net_Total__c, SBQQ__SubscriptionTerm__c, SBQQ__Discount__c,SBQQ__Quote__r.SBQQ__Type__c, CPQ_Uplift__c, SBQQ__ProrateMultiplier__c, SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c,
          SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c,Do_not_Renew__c,SBQQSC__RenewedContractLine__r.Subscription_Term__c,PriorACVwithUplift__c, SBQQ__Product__r.SBQQ__SubscriptionTerm__c, RTAwithoutUplift__c, Prior_Net_Total_With_Uplift__c,
          SBQQSC__RenewedContractLine__r.Channel_Uplift__c, SBQQ__Quantity__c,SBQQ__NetTotal__c,SBQQ__RequiredBy__c,SBQQ__ProductOption__r.Refresh_Default_Option__c, Replacement_Details__c,Disposition_Reason__c,SBQQ__Quote__r.Force_Recalculation__c,SBQQSC__RenewedContractLine__c,SBQQ__NetPrice__c, SBQQ__Quote__r.Margin__c,SBQQ__Quote__r.Discount_Margin_Amount__c, SBQQ__Quote__r.QuoteApprovalCategory__c  FROM SBQQ__QuoteLine__c where Id IN:quoteLineIds ]; //ITNPI-2901 Added fields
        if(quoteLines!=null && quoteLines.size()>0){
            //ITNPI-2901 Starts
            Map<String,String> cliKeyQLIMapping = new Map<String,String>();///ITNPI-3207
            for(SBQQ__QuoteLine__c quoteLine:quoteLines){
                //ITNPI-3207
                String cliKey = quoteLine.SBQQSC__RenewedContractLine__c != null ? quoteLine.SBQQSC__RenewedContractLine__c + '_' + quoteLine.SBQQ__SubscriptionTerm__c : null;
                if(quoteLine.SBQQ__RequiredBy__c == null && !cliKeyQLIMapping.containsKey(cliKey)){
                    cliKeyQLIMapping.put(cliKey,quoteLine.id);
                }
                String qlineKey = quoteLine.SBQQ__RequiredBy__c != null && quoteLine.SBQQ__ProductOption__r.Refresh_Default_Option__c? quoteLine.SBQQ__RequiredBy__c :(cliKeyQLIMapping!=null && cliKeyQLIMapping.containsKey(cliKey) ?cliKeyQLIMapping.get(cliKey):quoteLine.Id);
                Decimal listTotal = quoteLine.SBQQ__ListPrice__c*quoteLine.SBQQ__Quantity__c;
                if(qliListTotal.containsKey(qlineKey)){
                    qliListTotal.put(qlineKey,qliListTotal.get(qlineKey)+listTotal); 
                }else{
                    qliListTotal.put(qlineKey,listTotal);
                } 
            }//ITNPI-2901 Ends

            for(SBQQ__QuoteLine__c quoteLine:quoteLines){
                //ITNPI-2901 Starts
                Boolean isUpdate = false;
                SBQQ__QuoteLine__c oldQLI = oldMap.get(quoteLine.Id);
                if (quoteLine.Do_not_Renew__c == true && String.isNotBlank(quoteLine.Replacement_Details__c) && quoteLine.Disposition_Reason__c == 'Renewing' && ((quoteLine.SBQQ__ProrateMultiplier__c != null && oldQLI.SBQQ__ProrateMultiplier__c == null) || (quoteLine.SBQQ__ProrateMultiplier__c != oldQLI.SBQQ__ProrateMultiplier__c))) {
                    ConvertToSaasRenewalBatch.populatePriorNetTotalOnQuoteLine(quoteLine, qliListTotal,cliKeyQLIMapping);///ITNPI-3207
                    isUpdate = true;
                }
                //ITNPI-2901 Ends
                if (quoteLine.SBQQ__Source__c != null) {
                    quoteLine.Source_List_Price__c = quoteLine.SBQQ__Source__r.SBQQ__ListPrice__c;
          quoteLine.Source_Default_Term__c = quoteLine.SBQQ__Source__r.SBQQ__DefaultSubscriptionTerm__c;
          quoteLine.Source_Option_POT__c = quoteLine.SBQQ__Source__r.Product_Option_Percent_of_Total__c;
                    quotelinesToUpdate.add(quoteLine);
                } else if (isUpdate) {
                    quotelinesToUpdate.add(quoteLine);
                }
            }
        }
        System.debug(LoggingLevel.INFO, 'quotelinesToUpdate===' + quotelinesToUpdate.size());
        if(Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable() && quoteLinesToUpdate!=null && quotelinesToUpdate.size()>0){
            SBQQ.TriggerControl.disable();
            Database.update(quoteLinesToUpdate);
            SBQQ.TriggerControl.enable();
        }
    }

    /*START: CSU-492 Auto-Addition of OND AR & SR SKUs on the New & Amendment Quotes by Shaloo*/
    /**
     * @description : This method is responsible for automatically adding OND AR & SR SKUs to the Quote Lines.
     * @param qliList List of SBQQ__QuoteLine__c records being processed.
     * @param calledfrom String indicating the context from which this method is called.
     */
    public static void autoAddONDSKUs(List < SBQQ__QuoteLine__c > qliList, String calledfrom) {
        Set < Id > quoteSet = new Set < Id > ();
        if (qliList != null && !qliList.isEmpty()) {
            for (SBQQ__QuoteLine__c qli: qliList) {
                if (qli.SBQQ__Quote__c != null) {
                    quoteSet.add(qli.SBQQ__Quote__c);
                }
            }
        }
        if (!System.IsBatch() && !System.isFuture() && !System.isQueueable() && quoteSet != null && !quoteSet.IsEmpty() /*&& !isRecursiveautoAddONDSKUs*/) {
            isRecursiveautoAddONDSKUs = true;
            autoAddONDSKUsFuture(quoteSet, calledfrom);
            ScaleUtilityAmendHelper.createAmendedScaleUGQLRecords(quoteSet);
        }
    }
    /*END: CSU-492 Auto-Addition of OND AR & SR SKUs on the New & Amendment Quotes by Shaloo*/
    /*START: CSU-492 Auto-Addition of OND AR & SR SKUs on the New & Amendment Quotes by Shaloo*/
    // @future
    // public static void autoAddONDSKUsFuture(Set < Id > quoteId, String calledfrom) {
    //     system.debug('Enter autoAddONDSKUsFuture: ' + quoteId + ' Vs calledfrom: ' + calledfrom);

    //     Integer lineNumberCount = 0;
    //     String QuoteRecType = ''; //Variable to store Quote Type
    //     String OpptyRecSubType = ''; //Variable to store Opportunity Sub-Type
    //     String strPricebookId = ''; //Variable to store Quote's Price Book ID

    //     Set < String > products = new Set < String > (); //Collection to store unique On Demand AR/SR Product IDs
    //     Set < Decimal > setEffQty; //Collection to store unique Effective Quantity values of the RSV QLIs when Eff Qty of any line is greater than zero
    //     Set < Decimal > setQty; //Collection to store unique Quantity values of the RSV QLIs

    //     List < SBQQ__QuoteLine__c > lstQLI; //Collection to store all the QLIs existing on a Quote
    //     List < SBQQ__QuoteLine__c > qliToInsert = new List < SBQQ__QuoteLine__c > (); //Collection to store AR & SR quote lines to be auto-added
    //     Map < String, SBQQ__QuoteLine__c > qliToInsertFinal = new Map < String, SBQQ__QuoteLine__c > (); //Collection to store AR & SR quote lines to be auto-added
    //     List < SBQQ__ProductOption__c > lstOnDemandProductOptions; //Collection to store all the On-Demand AR & SR Product Options
    //     List < PricebookEntry > pbEntries; //Collection to store all the Pricebook Entries for On-Demand AR & SR Products

    //     Map < Id, SBQQ__QuoteLine__c > qliMapToUpdate = new Map < Id, SBQQ__QuoteLine__c > (); //Collection to store list of QLIs to update Optional/Hidden
    //     Map < Id, SBQQ__QuoteLine__c > mapRSVXVsFUE = new Map < Id, SBQQ__QuoteLine__c > (); //Collection to store RSVX QLI ID Vs the Upgrade FUE SKUs QLI IDs present on the Quote
    //     Map < Id, PricebookEntry > productToPbeMap = new Map < Id, PricebookEntry > (); //Collection to store Price book Entries wrt to AR/SR Products

    //     Map < Id, String > mapEEARExistsForRSVX = new Map < Id, String > (); //Collection to store list of already existing EE-AR QLIs
    //     Map < Id, String > mapEESRExistsForRSVX = new Map < Id, String > (); //Collection to store list of already existing EE-SR QLIs

    //     Map < Id, SBQQ__QuoteLine__c > mapRSVXQLI = new Map < Id, SBQQ__QuoteLine__c > (); //Collection to store RSVX quote lines
    //     Map < Id, SBQQ__QuoteLine__c > mapRSVXProdIdVsRec = new Map < Id, SBQQ__QuoteLine__c > (); //Collection to store RSVX Product IDs Vs the associated RSVX QLI record

    //     Map < String, SBQQ__ProductOption__c > mapRSVXVsAROND_Option = new Map < String, SBQQ__ProductOption__c > (); //Collection to store all the On-Demand AR Product Options specific to RSVX Product Bundle [Config SKU Vs Optional SKU]
    //     Map < String, SBQQ__ProductOption__c > mapRSVXVsSROND_Option = new Map < String, SBQQ__ProductOption__c > (); //Collection to store all the On-Demand SR Product Options specific to RSVX Product Bundle [Config SKU Vs Optional SKU]

    //     Map < String, SBQQ__ProductOption__c > mapOptionId_AR = new Map < String, SBQQ__ProductOption__c > (); //Collection to store non-EE Specific AR Product Options specific to [Config SKU + Optional SKU] combination
    //     Map < String, SBQQ__ProductOption__c > mapOptionId_SR = new Map < String, SBQQ__ProductOption__c > (); //Collection to store non-EE Specific SR Product Options specific to [Config SKU + Optional SKU] combination

    //     Map < String, SBQQ__ProductOption__c > mapEEOptionId_AR = new Map < String, SBQQ__ProductOption__c > (); //Collection to store EE Specific AR Product Options specific to [Config SKU + Optional SKU] combination
    //     Map < String, SBQQ__ProductOption__c > mapEEOptionId_SR = new Map < String, SBQQ__ProductOption__c > (); //Collection to store EE Specific SR Product Options specific to [Config SKU + Optional SKU] combination

    //     Map < Id, String > mapRSVXwithExistingFEAR = new Map < Id, String > (); //Collection to store all the Bundled QLIs which already has ARs SKU options added
    //     Map < Id, String > mapRSVXwithExistingFESR = new Map < Id, String > (); //Collection to store all the Bundled QLIs which already has SRs SKU options added

    //     Map < String, Set < Decimal >> ReqByVsEffQty = new Map < String, Set < Decimal >> (); //Collection to store RSVX QLI ID Vs the unique Effective Quantity values of the RSV QLIs present for the specific RSVX Bundles to identify Ramp in the segments
    //     Map < String, Set < Decimal >> ReqByVsQty = new Map < String, Set < Decimal >> (); //Collection to store RSVX QLI ID Vs the unique Quantity values of the RSV QLIs present for the specific RSVX Bundles to identify Ramp in the segments

    //     Map < Id, Boolean > mapToAddFEAR_AmendmentQuote = new Map < Id, Boolean > (); //Collection to store RSVX QLI ID which needs to have FE-AR SKUs auto-added on Amendment Quote
    //     Map < Id, Boolean > mapToAddFESR_AmendmentQuote = new Map < Id, Boolean > (); //Collection to store RSVX QLI ID which needs to have FE-SR SKUs auto-added on Amendment Quote
    //     //Map<Id, Boolean> mapToAddEEAR_AmendmentQuote = new Map<Id, Boolean>();//Collection to IDENTIFY if we need to add EE-AR QLIs on Amendment Quote
    //     //Map<Id, Boolean> mapToAddEESR_AmendmentQuote = new Map<Id, Boolean>();//Collection to IDENTIFY if we need to add EE-SR QLIs on Amendment Quote

    //     Map < Id, Boolean > mapToAddEEAR_AmendmentQuote_v1 = new Map < Id, Boolean > (); //Collection to IDENTIFY if we need to add EE-AR QLIs on Amendment Quote
    //     Map < Id, Boolean > mapToAddEESR_AmendmentQuote_v1 = new Map < Id, Boolean > (); //Collection to IDENTIFY if we need to add EE-SR QLIs on Amendment Quote

    //     Map < String, SBQQ__QuoteLine__c > mapPCodeVsQLI_AR = new Map < String, SBQQ__QuoteLine__c > (); //Collection to store AR Product Code Vs the QLIs existing an a Quote
    //     Map < String, SBQQ__QuoteLine__c > mapPCodeVsQLI_SR = new Map < String, SBQQ__QuoteLine__c > (); //Collection to store SR Product Code Vs the QLIs existing an a Quote

    //     Map < String, String > mapCheck = new Map < String, String > ();
    //     Map < String, String > mapTest = new Map < String, String > ();

    //     Map < Id, SBQQ__QuoteLine__c > qliMapReqByRSV = new Map < Id, SBQQ__QuoteLine__c > ();

    //     if (lstOnDemandProductOptions == null) {
    //         lstOnDemandProductOptions = [SELECT Id, SBQQ__ConfiguredSKU__c, SBQQ__ConfiguredSKU__r.ProductCode, SBQQ__ConfiguredSKU__r.Product_Type__c,
    //             SBQQ__ConfiguredSKU__r.Support_Type__c, SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c,
    //             SBQQ__Feature__c, SBQQ__Feature__r.Name, SBQQ__Type__c, SBQQ__Number__c, SBQQ__OptionalSKU__c,
    //             SBQQ__OptionalSKU__r.ProductCode, SBQQ__OptionalSKU__r.Product_Type__c, SBQQ__OptionalSKU__r.Support_Type__c,
    //             SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c, SBQQ__OptionalSKU__r.Product_Level__c,
    //             SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c, SBQQ__OptionalSKU__r.Pricebook_Entry_Id__c,
    //             SBQQ__OptionalSKU__r.Product_Payment_Option__c, SBQQ__OptionalSKU__r.Description, SBQQ__ProductCode__c
    //             FROM SBQQ__ProductOption__c
    //             WHERE(SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c = 'OND AR'
    //                 OR SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c = 'OND SR')
    //             ORDER BY SBQQ__ConfiguredSKU__r.ProductCode, SBQQ__Number__c ASC
    //         ];
    //         system.debug('lstOnDemandProductOptions: ' + lstOnDemandProductOptions + ' lstOnDemandProductOptions Size: ' + lstOnDemandProductOptions.size());
    //     }

    //     if (lstOnDemandProductOptions != null && !lstOnDemandProductOptions.IsEmpty()) {
    //         for (SBQQ__ProductOption__c option: lstOnDemandProductOptions) {

    //             products.add(option.SBQQ__OptionalSKU__c);

    //             //For On-Demand AR SKUs Product Options
    //             if (option.SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c == 'OND AR') {
    //                 system.debug('Enter for creating OND AR Collections');
    //                 if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX'
    //                 || option.SBQQ__OptionalSKU__r.Product_Type__c == 'M365 Backup Storage'
    //                 || option.SBQQ__ProductCode__c.containsIgnoreCase('-SA-'))
    //             {
    //                     system.debug('Non-M365H SKU: ' + option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c);
    //                     mapRSVXVsAROND_Option.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__r.Product_Type__c)),
    //                         option);
    //                 }
    //                 if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX') {
    //                     system.debug('M365H SKU: ' + option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c);
    //                     system.debug('SBQQ__ConfiguredSKU__r.ProductCode SKU: ' + option.SBQQ__ConfiguredSKU__r.ProductCode);
    //                     system.debug('SBQQ__OptionalSKU__r.ProductCode SKU: ' + option.SBQQ__OptionalSKU__r.ProductCode);
    //                     system.debug('SBQQ__OptionalSKU__r.Product_Type__c SKU: ' + option.SBQQ__OptionalSKU__r.Product_Type__c);
    //                     system.debug('Yes/NoFE: ' + option.SBQQ__ConfiguredSKU__r.ProductCode.contains('FE-MD-RSVX'));
    //                     system.debug('Yes/NoEE: ' + option.SBQQ__ConfiguredSKU__r.ProductCode.contains('EE-MD-RSVX'));

    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Foundation Edition' && option.SBQQ__ConfiguredSKU__r.ProductCode.contains('FE-MD-RSVX')) {
    //                         system.debug('FE-MD-RSVX SKU: ' + option.SBQQ__OptionalSKU__r.ProductCode);
    //                         mapRSVXVsAROND_Option.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                                 'FE-MD-RSVX' + String.valueOf(option.SBQQ__OptionalSKU__r.Support_Type__c)),
    //                             option);
    //                     }
    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Enterprise Edition' && option.SBQQ__ConfiguredSKU__r.ProductCode.contains('EE-MD-RSVX')) {
    //                         system.debug('EE-MD-RSVX SKU: ' + option.SBQQ__OptionalSKU__r.ProductCode);
    //                         mapRSVXVsAROND_Option.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                                 'EE-MD-RSVX' + String.valueOf(option.SBQQ__OptionalSKU__r.Support_Type__c)),
    //                             option);
    //                     }
    //                 }

    //                 //For AR SKUs Non-Enterprise Edition
    //                 if ((option.SBQQ__ConfiguredSKU__r.Product_Type__c != 'Enterprise Edition' &&
    //                     option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX')
    //                     || (option.SBQQ__OptionalSKU__r.Product_Type__c == 'M365 Backup Storage'
    //                     && option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                     || (option.SBQQ__ProductCode__c.containsIgnoreCase('-SA-')
    //                     && option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                    ){
    //                     system.debug('Foundation non-M365H SKU: ' + option.SBQQ__ConfiguredSKU__r.ProductCode);
    //                     mapOptionId_AR.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) + String.valueOf(option.SBQQ__OptionalSKU__c)), option);
    //                 }
    //                 if (option.SBQQ__ConfiguredSKU__r.ProductCode.contains('FE-MD-RSVX') &&
    //                     option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX'
    //                 ) {
    //                     system.debug('FE-MD-RSVX M365H SKU: ' + option.SBQQ__ConfiguredSKU__r.ProductCode);

    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Foundation Edition') {
    //                         system.debug('Foundation FE-MD-RSVX M365H SKU: ' + option.SBQQ__OptionalSKU__r.ProductCode);
    //                         mapOptionId_AR.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__r.Support_Type__c)), option);
    //                     }
    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('Enterprise FE-MD-RSVX M365H SKU: ' + option.SBQQ__OptionalSKU__r.ProductCode);
    //                         mapOptionId_AR.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__r.Support_Type__c)), option);
    //                     }
    //                 }

    //                 //For AR SKUs Enterprise Edition
    //                 if ((
    //                         (option.SBQQ__ConfiguredSKU__r.Product_Type__c == 'Enterprise Edition' &&
    //                             option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX') ||
    //                         (option.SBQQ__ConfiguredSKU__r.ProductCode.contains('EE-MD-RSVX'))
    //                     )) {
    //                     //For AR SKUs non-M365H Scale Bundle
    //                     system.debug('Enterprise Non-M365H/EE-MD-RSVX SKU: ' + option.SBQQ__OptionalSKU__r.ProductCode);

    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Enterprise Edition' &&
    //                         option.SBQQ__ConfiguredSKU__r.Support_Type__c != null) {
    //                         if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == null) {
    //                             system.debug('RS-TB-EE-RSVX Option for Enterprise EE-AR: ' + mapEEOptionId_AR);
    //                             mapEEOptionId_AR.put(('RS-TB-EE-RSVX' + String.valueOf(option.SBQQ__ConfiguredSKU__r.Support_Type__c) +
    //                                 'Enterprise Edition'), option);
    //                         }
    //                         //For AR SKUs M365H Scale Bundle
    //                         if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX') {
    //                             system.debug('RS-UR-EE-MD-RSVX Option for Enterprise EE-AR: ' + mapEEOptionId_AR);
    //                             mapEEOptionId_AR.put(('RS-UR-EE-MD-RSVX' + String.valueOf(option.SBQQ__ConfiguredSKU__r.Support_Type__c) +
    //                                 'Enterprise Edition'), option);
    //                         }
    //                     }
    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Foundation Edition' &&
    //                         option.SBQQ__ConfiguredSKU__r.Support_Type__c != null) {
    //                         //For AR SKUs non-M365H Scale Bundle
    //                         system.debug('Foundation Non-M365H/EE-MD-RSVX SKU: ' + option.SBQQ__OptionalSKU__r.ProductCode);

    //                         if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == null) {
    //                             system.debug('RS-TB-EE-RSVX Option for Foundation EE-AR: ' + mapEEOptionId_AR);
    //                             mapEEOptionId_AR.put(('RS-TB-EE-RSVX' + String.valueOf(option.SBQQ__ConfiguredSKU__r.Support_Type__c) +
    //                                 'Foundation Edition'), option);
    //                         }
    //                         //For AR SKUs M365H Scale Bundle
    //                         if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX') {
    //                             system.debug('RS-UR-EE-MD-RSVX Option for Foundation EE-AR: ' + mapEEOptionId_AR);
    //                             mapEEOptionId_AR.put(('RS-UR-EE-MD-RSVX' + String.valueOf(option.SBQQ__ConfiguredSKU__r.Support_Type__c) +
    //                                 'Foundation Edition'), option);
    //                         }
    //                     }
    //                 }
    //             }
    //             //For On-Demand SR SKUs Product Options
    //             if (option.SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c == 'OND SR') {
    //                 system.debug('Enter for creating OND SR Collections');

    //                 if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX'
    //                 || option.SBQQ__OptionalSKU__r.Product_Type__c == 'M365 Backup Storage'
    //                 || option.SBQQ__ProductCode__c.containsIgnoreCase('-SA-')
    //               ){
    //                     system.debug('Non-M365H SR: ' + mapRSVXVsSROND_Option);
    //                     mapRSVXVsSROND_Option.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__r.Product_Type__c)),
    //                         option);
    //                 }
    //                 if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX') {
    //                     system.debug('M365H SR: ' + mapRSVXVsSROND_Option);
    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Foundation Edition' &&
    //                         option.SBQQ__ConfiguredSKU__r.ProductCode.contains('FE-MD-RSVX')
    //                     ) {
    //                         system.debug('Foundation FE-MD-RSVX SR: ' + mapRSVXVsSROND_Option);
    //                         mapRSVXVsSROND_Option.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                                 'FE-MD-RSVX' + String.valueOf(option.SBQQ__OptionalSKU__r.Support_Type__c)),
    //                             option);
    //                     }
    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Enterprise Edition' &&
    //                         option.SBQQ__ConfiguredSKU__r.ProductCode.contains('EE-MD-RSVX')
    //                     ) {
    //                         system.debug('Enterprise EE-MD-RSVX SR: ' + mapRSVXVsSROND_Option);
    //                         mapRSVXVsSROND_Option.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                                 'EE-MD-RSVX' + String.valueOf(option.SBQQ__OptionalSKU__r.Support_Type__c)),
    //                             option);
    //                     }
    //                 }
    //                 //For SR SKUs Non-Enterprise Edition
    //                 if (option.SBQQ__ConfiguredSKU__r.Product_Type__c != 'Enterprise Edition' &&
    //                     option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX') {
    //                     system.debug('Foundation Non-M365H SR: ' + mapOptionId_SR);
    //                     mapOptionId_SR.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) + String.valueOf(option.SBQQ__OptionalSKU__c)), option);
    //                 }
    //                 if ((option.SBQQ__ConfiguredSKU__r.ProductCode.contains('FE-MD-RSVX') &&
    //                     option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                     ||
    //                      (option.SBQQ__OptionalSKU__r.Product_Type__c == 'M365 Backup Storage'
    //                    && option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                      ||
    //                      (option.SBQQ__ProductCode__c.containsIgnoreCase('-SA-')
    //                    && option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                 ) {
    //                     system.debug('FE-MD-RSVX SR: ' + mapOptionId_SR);
    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Foundation Edition') {
    //                         system.debug('FE-MD-RSVX Foundation SR: ' + mapOptionId_SR);
    //                         mapOptionId_SR.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__r.Support_Type__c)), option);
    //                     }
    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('FE-MD-RSVX Enterprise SR: ' + mapOptionId_SR);
    //                         mapOptionId_SR.put((String.valueOf(option.SBQQ__ConfiguredSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__c) +
    //                             String.valueOf(option.SBQQ__OptionalSKU__r.Support_Type__c)), option);
    //                     }
    //                 }
    //                 //For SR SKUs Enterprise Edition
    //                 if ((
    //                         (option.SBQQ__ConfiguredSKU__r.Product_Type__c == 'Enterprise Edition' &&
    //                             option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX') ||
    //                         (option.SBQQ__ConfiguredSKU__r.ProductCode.contains('EE-MD-RSVX'))
    //                     )) {
    //                     system.debug('Enterprise Non-M356H/EE-MD-RSVX Enterprise SR: ' + mapEEOptionId_SR);

    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Enterprise Edition' &&
    //                         option.SBQQ__ConfiguredSKU__r.Support_Type__c != null) {
    //                         //For SR SKUs non-M365H Scale Bundle
    //                         if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == null) {
    //                             system.debug('Enterprise RS-TB-EE-RSVX SR: ' + mapEEOptionId_SR);
    //                             mapEEOptionId_SR.put(('RS-TB-EE-RSVX' + String.valueOf(option.SBQQ__ConfiguredSKU__r.Support_Type__c) +
    //                                 'Enterprise Edition'), option);
    //                         }
    //                         //For SR SKUs M365H Scale Bundle
    //                         if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX') {
    //                             system.debug('Enterprise RS-UR-EE-MD-RSVX SR: ' + mapEEOptionId_SR);
    //                             mapEEOptionId_SR.put(('RS-UR-EE-MD-RSVX' + String.valueOf(option.SBQQ__ConfiguredSKU__r.Support_Type__c) +
    //                                 'Enterprise Edition'), option);
    //                         }
    //                     }
    //                     if (option.SBQQ__OptionalSKU__r.Product_Type__c == 'Foundation Edition' &&
    //                         option.SBQQ__ConfiguredSKU__r.Support_Type__c != null) {
    //                         system.debug('Enterprise Non-M365H/EE-MD-RSVX Foundation SR: ' + mapEEOptionId_SR);
    //                         //For SR SKUs non-M365H Scale Bundle

    //                         if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == null) {
    //                             system.debug('Foundation RS-TB-EE-RSVX SR: ' + mapEEOptionId_SR);
    //                             mapEEOptionId_SR.put(('RS-TB-EE-RSVX' + String.valueOf(option.SBQQ__ConfiguredSKU__r.Support_Type__c) +
    //                                 'Foundation Edition'), option);
    //                         }
    //                         //For SR SKUs M365H Scale Bundle

    //                         if (option.SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX') {
    //                             system.debug('Foundation RS-UR-EE-MD-RSVX SR: ' + mapEEOptionId_SR);
    //                             mapEEOptionId_SR.put(('RS-UR-EE-MD-RSVX' + String.valueOf(option.SBQQ__ConfiguredSKU__r.Support_Type__c) +
    //                                 'Foundation Edition'), option);
    //                         }
    //                     }
    //                 }
    //             }
    //         }
    //     }
    //     system.debug('mapRSVXVsAROND_Option: ' + mapRSVXVsAROND_Option + ' & mapRSVXVsAROND_Option Size: ' + mapRSVXVsAROND_Option.size());
    //     system.debug('mapRSVXVsSROND_Option: ' + mapRSVXVsSROND_Option + ' & mapRSVXVsSROND_Option Size: ' + mapRSVXVsSROND_Option.size());
    //     system.debug('mapOptionId_AR: ' + mapOptionId_AR + ' & mapOptionId_AR Size: ' + mapOptionId_AR.size());
    //     system.debug('mapOptionId_SR: ' + mapOptionId_SR + ' & mapOptionId_SR Size: ' + mapOptionId_SR.size());
    //     system.debug('mapEEOptionId_AR: ' + mapEEOptionId_AR + ' & mapEEOptionId_AR Size: ' + mapEEOptionId_AR.size());
    //     system.debug('mapEEOptionId_SR: ' + mapEEOptionId_SR + ' & mapEEOptionId_SR Size: ' + mapEEOptionId_SR.size());

    //     if (quoteId != null && !quoteId.IsEmpty() && lstQLI == null) {
    //         lstQLI = [SELECT Id, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Number__c, SBQQ__ProductOption__c, Line_Type__c, SBQQ__Quote__c,
    //             SBQQ__RequiredBy__c, Scale_Utility_Product_RSV_OND__c, Scale_Utility_Product_Identifier__c, SBQQ__Quantity__c,
    //             SBQQ__EffectiveQuantity__c, SBQQ__PriorQuantity__c, Member_of_Bundle_Edition_s__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
    //             SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__r.OpportunitySubType__c, SBQQ__Quote__r.SBQQ__LineItemCount__c, Product_Type__c,
    //             SBQQ__SubscriptionTerm__c, SBQQ__SubscriptionPricing__c, SBQQ__SegmentIndex__c, SBQQ__Product__r.Pricebook_Entry_Id__c,
    //             SBQQ__SegmentLabel__c, SBQQ__Product__r.Support_Type__c, SBQQ__PricebookEntryId__c, SBQQ__NetPrice__c, SBQQ__ListPrice__c,
    //             SBQQ__Quote__r.SBQQ__PricebookId__c, SBQQSC__UpgradedContractLine__c, SBQQ__RequiredBy__r.Product_Type__c,
    //             SBQQ__Product__r.Product_Type__c, SBQQ__DynamicOptionId__c, Product_Level__c, Support_Type__c, Product_Payment_Option__c,
    //             SBQQ__RequiredBy__r.Scale_Utility_Product_Identifier__c, SBQQ__RequiredBy__r.SBQQ__ProductCode__c,
    //             SBQQ__RequiredBy__r.Scale_Utility_Product_RSV_OND__c, SBQQ__Product__r.Description, SBQQ__Quote__r.Name,
    //             SBQQ__ProductOption__r.SBQQ__OptionalSKU__r.Description, SBQQ__Description__c, SBQQ__ProrateMultiplier__c, SBQQ__Discount__c
    //             FROM SBQQ__QuoteLine__c WHERE
    //             SBQQ__Quote__c IN: quoteId
    //             ORDER BY SBQQ__RequiredBy__c, SBQQ__SegmentLabel__c ASC
    //         ];
    //         system.debug('lstQLI: ' + lstQLI + ' & lstQLI Size: ' + lstQLI.size());
    //     }

    //     if (lstQLI != null && !lstQLI.IsEmpty()) {
    //         for (SBQQ__QuoteLine__c qli: lstQLI) {
    //             lineNumberCount = qli.SBQQ__Quote__r.SBQQ__LineItemCount__c == null ? 0 : Integer.valueOf(qli.SBQQ__Quote__r.SBQQ__LineItemCount__c);
    //             strPricebookId = qli.SBQQ__Quote__r.SBQQ__PricebookId__c;

    //             system.debug('PCode: ' + qli.SBQQ__ProductCode__c +
    //                 ' & MoBE: ' + qli.Member_of_Bundle_Edition_s__c +
    //                 ' & OND?: ' + qli.Scale_Utility_Product_RSV_OND__c +
    //                 ' & SUPI?: ' + qli.Scale_Utility_Product_Identifier__c);

    //             if (qli.Member_of_Bundle_Edition_s__c == 'Scale Utility' && qli.Scale_Utility_Product_RSV_OND__c != 'OND' &&
    //                 qli.Scale_Utility_Product_RSV_OND__c != 'RSV' && qli.Scale_Utility_Product_Identifier__c != 'SU FUE' &&
    //                 qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('RSVX')
    //             ) {
    //                 system.debug('EnterKK');
    //                 mapRSVXQLI.put(qli.Id, qli); //To Store RSVX QLI ID wrt to it's QLI record
    //                 mapRSVXProdIdVsRec.put(qli.SBQQ__Product__c, qli); //To Store RSVX Product ID wrt to it's QLI record
    //             }

    //             if (qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null &&
    //                 (qli.Scale_Utility_Product_Identifier__c == 'OND AR' || qli.Scale_Utility_Product_Identifier__c == 'OND SR') &&
    //                 (qli.SBQQSC__UpgradedContractLine__c == null || qli.Line_Type__c == 'New')
    //             ) {
    //                 System.debug('AR Check: ' + qli.Id);
    //                 mapCheck.put((String.valueOf(qli.SBQQ__RequiredBy__c) + String.valueOf(qli.SBQQ__Product__c)),
    //                     qli.SBQQ__Product__c); //Map of OND AR SKU PCode Vs OND QLI Record
    //             }

    //             if (qli.Scale_Utility_Product_RSV_OND__c == 'RSV' || qli.Scale_Utility_Product_Identifier__c == 'M365 RSV SU') {
    //                 qliMapReqByRSV.put(String.valueOf(qli.SBQQ__RequiredBy__c), qli); //Map of ReqBy Id Vs RSV QLI Record
    //             }

    //             if (qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('OND') &&
    //                 qli.Member_of_Bundle_Edition_s__c == 'Scale Utility' &&
    //                 (qli.SBQQSC__UpgradedContractLine__c != null || qli.Line_Type__c == 'Amendment')
    //             ) {
    //                 system.debug('Enter to set ReqBy as NULL for Old OND QLIs' + qli.Id);
    //                 qli.SBQQ__RequiredBy__c = null;
    //                 qli.SBQQ__ProductOption__c = null;
    //                 qli.SBQQ__DynamicOptionId__c = null;
    //                 qliMapToUpdate.put(qli.Id, qli);
    //             }
    //         }
    //     }
    //     System.debug('mapRSVXQLI: ' + mapRSVXQLI + ' & mapRSVXQLI Size: ' + mapRSVXQLI.size());
    //     System.debug('mapRSVXProdIdVsRec: ' + mapRSVXProdIdVsRec + ' & mapRSVXProdIdVsRec Size: ' + mapRSVXProdIdVsRec.size());
    //     system.debug('products: ' + products + ' & products Size: ' + products.size());
    //     system.debug('strPricebookId: ' + strPricebookId);
    //     System.debug('mapCheck: ' + mapCheck + ' & mapCheckSize: ' + mapCheck.size());

    //     if (pbEntries == null && products != null && !products.IsEmpty() && strPricebookId != '') {
    //         pbEntries = [SELECT Id, Product2Id, UnitPrice, Product2.Product_Type__c, Product2.Product_Level__c, Product2.Category__c,
    //             Product2.Description, Product2.SBQQ__SubscriptionTerm__c, Product2.SBQQ__SubscriptionType__c, Product2.ProductCode,
    //             Product2.SBQQ__SubscriptionPricing__c, Product2.SBQQ__NonDiscountable__c, Product2.SBQQ__DefaultQuantity__c,
    //             Product2.Sales_Comp_Category__c FROM PricebookEntry WHERE Product2Id IN: products AND Pricebook2Id =: strPricebookId
    //             AND IsActive = TRUE
    //         ];
    //         system.debug('pbEntries: ' + pbEntries + ' & pbEntries Size: ' + pbEntries.size());
    //     }
    //     //Create Map from Product to their corresponding Pricebook Entry for the Quote's Pricebook

    //     if (pbEntries != null && !pbEntries.IsEmpty()) {
    //         for (PricebookEntry pbEntry: pbEntries) {
    //             productToPbeMap.put(pbEntry.Product2Id, pbEntry);
    //         }
    //     }
    //     system.debug('productToPbeMap: ' + productToPbeMap + ' & productToPbeMap Size: ' + productToPbeMap.size());

    //     if (mapRSVXQLI != null && !mapRSVXQLI.IsEmpty()) {
    //         for (SBQQ__QuoteLine__c eachQLIRec: mapRSVXQLI.values()) {
    //             setEffQty = new Set < Decimal > (); //Re-initalizing the set collection
    //             setQty = new Set < Decimal > (); //Re-initalizing the set collection

    //             if (lstQLI != null && !lstQLI.IsEmpty()) {
    //                 for (SBQQ__QuoteLine__c qli: lstQLI) {
    //                     if (qli.SBQQ__SegmentLabel__c != null &&
    //                         (qli.Scale_Utility_Product_RSV_OND__c == 'RSV' ||
    //                             (qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('MD-RSV-') &&
    //                                 qli.Scale_Utility_Product_Identifier__c == 'M365 RSV SU')
    //                             || (qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('-MBS-')
    //                                && qli.Scale_Utility_Product_Identifier__c == 'M365 RSV SU')
    //                            || (qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('-SA-')
    //                                && qli.Scale_Utility_Product_Identifier__c == 'M365 RSV SU')
    //                         ) &&
    //                         qli.SBQQ__RequiredBy__c != null &&
    //                         qli.SBQQ__RequiredBy__c == eachQLIRec.Id
    //                     ) {
    //                         system.debug('RSVReqBy: ' + qli.SBQQ__RequiredBy__c + ' Vs eachQLIRecId: ' + eachQLIRec.Id);

    //                         if (qli.SBQQ__EffectiveQuantity__c > 0) {
    //                             setEffQty.add(qli.SBQQ__EffectiveQuantity__c); //Unique Collection of Effective Quantity of the RSV Lines wrt to each RSVX Bundle
    //                             ReqByVsEffQty.put(qli.SBQQ__RequiredBy__c, setEffQty);
    //                         }
    //                         if (qli.SBQQ__Quantity__c != null && qli.SBQQ__Quantity__c > 0) {
    //                             setQty.add(qli.SBQQ__Quantity__c); //Unique Collection of Effective Quantity of the RSV Lines wrt to each RSVX Bundle
    //                             ReqByVsQty.put(qli.SBQQ__RequiredBy__c, setQty);
    //                         }
    //                     }

    //                     if (qli.Scale_Utility_Product_Identifier__c == 'SU FUE' && qli.SBQQ__RequiredBy__c == eachQLIRec.Id) {
    //                         system.debug('FUEReqBy: ' + qli.SBQQ__RequiredBy__c + ' vs FUEeachQLIRec.Id: ' + eachQLIRec.Id);
    //                         mapRSVXVsFUE.put(qli.SBQQ__RequiredBy__c, qli);
    //                     }
    //                 }
    //             }
    //         }
    //     }
    //     System.debug('ReqByVsEffQty: ' + ReqByVsEffQty + ' & ReqByVsEffQty Size: ' + ReqByVsEffQty.size());
    //     System.debug('ReqByVsQty: ' + ReqByVsQty + ' & ReqByVsQty Size: ' + ReqByVsQty.size());
    //     System.debug('mapRSVXVsFUE: ' + mapRSVXVsFUE + ' & mapRSVXVsFUE Size: ' + mapRSVXVsFUE.size());

    //     if (lstQLI != null && !lstQLI.IsEmpty()) {
    //         for (SBQQ__QuoteLine__c ql: lstQLI) {
    //             QuoteRecType = ql.SBQQ__Quote__r.SBQQ__Type__c;
    //             OpptyRecSubType = ql.SBQQ__Quote__r.OpportunitySubType__c;

    //             if (ql.SBQQ__Product__c != null &&
    //                 (ql.SBQQSC__UpgradedContractLine__c == null || ql.Line_Type__c == 'New')
    //             ) {
    //                 system.debug('To populate if AR/SR already exists : ' + ql.SBQQ__RequiredBy__c);

    //                 if (ql.Scale_Utility_Product_Identifier__c == 'OND AR'
    //                     //&& (ql.SBQQSC__UpgradedContractLine__c == null || ql.Line_Type__c == 'New')
    //                 ) {
    //                     System.debug('AR Present: ' + ql.Id);
    //                     mapPCodeVsQLI_AR.put(ql.SBQQ__ProductCode__c, ql); //Map of OND AR SKU PCode Vs OND QLI Record
    //                 }
    //                 if (ql.Scale_Utility_Product_Identifier__c == 'OND SR'
    //                     //&& (ql.SBQQSC__UpgradedContractLine__c == null || ql.Line_Type__c == 'New')
    //                 ) {
    //                     System.debug('SR Present: ' + ql.Id);
    //                     mapPCodeVsQLI_SR.put(ql.SBQQ__ProductCode__c, ql); //Map of OND SR SKU PCode Vs OND QLI Record
    //                 }
    //             }
    //             /* For AMENDMENT Quote */
    //             if (QuoteRecType == 'Amendment' && ql.SBQQ__RequiredBy__c != null) {
    //                 system.debug('Amendment - To check for RAMP: ' + ql.SBQQ__RequiredBy__c);

    //                 if (ReqByVsEffQty != null && !ReqByVsEffQty.IsEmpty() &&
    //                     ReqByVsEffQty.containsKey(ql.SBQQ__RequiredBy__c) && ReqByVsEffQty.get(ql.SBQQ__RequiredBy__c) != null
    //                 ) {
    //                     system.debug('R1: ' + ql.SBQQ__RequiredBy__c + ' PT1: ' + ql.SBQQ__RequiredBy__r.Product_Type__c);

    //                     //To Add FE-AR: When Eff Qty of any RSV QLI is greater than 0 & no FUE
    //                     if (ReqByVsEffQty.get(ql.SBQQ__RequiredBy__c).size() > 0 &&
    //                         ReqByVsQty.get(ql.SBQQ__RequiredBy__c).size() > 0 &&
    //                         (mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty() || !mapRSVXVsFUE.containsKey(ql.SBQQ__RequiredBy__c)) &&
    //                         (
    //                             (ql.Product_Type__c == 'Foundation Edition' &&
    //                                 ql.SBQQ__RequiredBy__r.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX') 
    //                                 || (ql.Product_Type__c == 'M365 Backup Storage' 
    //                               && ql.SBQQ__RequiredBy__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                              || (ql.SBQQ__ProductCode__c.containsIgnoreCase('-SA-')
    //                               && ql.SBQQ__RequiredBy__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                                 || (ql.SBQQ__ProductCode__c != null && ql.SBQQ__ProductCode__c.contains('RS-UR-FE-MD') &&
    //                                 ql.SBQQ__RequiredBy__r.Product_Type__c == 'M365H' &&
    //                                 ql.SBQQ__RequiredBy__r.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                         )
    //                     ) {
    //                         system.debug('Pure Capacity Expansion for FE-AR Addition: ' + ql.SBQQ__RequiredBy__c);
    //                         mapToAddFEAR_AmendmentQuote.put(ql.SBQQ__RequiredBy__c, true);
    //                         mapToAddFESR_AmendmentQuote.put(ql.SBQQ__RequiredBy__c, true);
    //                     }
    //                     if (ReqByVsQty != null && !ReqByVsQty.IsEmpty() &&
    //                         ReqByVsQty.containsKey(ql.SBQQ__RequiredBy__c) && ReqByVsQty.get(ql.SBQQ__RequiredBy__c) != null) {
    //                         system.debug('R2: ' + ql.SBQQ__RequiredBy__c + ' PT2: ' + ql.SBQQ__RequiredBy__r.Product_Type__c);
    //                         /* Start v1 */
    //                         if (((ReqByVsEffQty == null || ReqByVsEffQty.IsEmpty()) || ReqByVsQty.get(ql.SBQQ__RequiredBy__c).size() <= 1 ||
    //                                 ReqByVsQty.get(ql.SBQQ__RequiredBy__c).size() > 0) &&
    //                             mapRSVXVsFUE != null && !mapRSVXVsFUE.IsEmpty() && mapRSVXVsFUE.containsKey(ql.SBQQ__RequiredBy__c) &&
    //                             mapRSVXVsFUE.get(ql.SBQQ__RequiredBy__c) != null
    //                         ) {
    //                             //To Add EE-AR: When Eff Qty of any RSV QLI is equal to 0 & FUE exists
    //                             system.debug('Pure Upgrade for EE-AR Addition: ' + ql.SBQQ__RequiredBy__c +
    //                                 ' & QName: ' + ql.SBQQ__Quote__r.Name);
    //                             mapToAddEEAR_AmendmentQuote_v1.put(ql.SBQQ__RequiredBy__c, true); //To auto-add EE-AR
    //                             mapToAddEESR_AmendmentQuote_v1.put(ql.SBQQ__RequiredBy__c, true);
    //                         }
    //                         if (ReqByVsQty.get(ql.SBQQ__RequiredBy__c).size() > 0 &&
    //                             ReqByVsEffQty.get(ql.SBQQ__RequiredBy__c).size() > 0 &&
    //                             (ql.Product_Type__c == 'Enterprise Edition' ||
    //                                 (ql.Product_Type__c == 'M365H' && ql.SBQQ__ProductCode__c != null && ql.SBQQ__ProductCode__c.contains('EE-MD-RSV'))
    //                             )
    //                         ) {
    //                             system.debug('Capacity Expansion + Upgrade for EE-AR Addition: ' + ql.SBQQ__RequiredBy__c +
    //                                 ' & QName: ' + ql.SBQQ__Quote__r.Name);
    //                             mapToAddEEAR_AmendmentQuote_v1.put(ql.SBQQ__RequiredBy__c, true); //To auto-add EE-AR
    //                             mapToAddEESR_AmendmentQuote_v1.put(ql.SBQQ__RequiredBy__c, true);
    //                         }
    //                     }
    //                 }
    //                 system.debug('mapRSVXVsFUEj: ' + mapRSVXVsFUE.containsKey(ql.SBQQ__RequiredBy__c));
    //                 if ((ReqByVsEffQty == null || ReqByVsEffQty.IsEmpty()) &&
    //                     mapRSVXVsFUE != null && !mapRSVXVsFUE.IsEmpty() && mapRSVXVsFUE.containsKey(ql.SBQQ__RequiredBy__c) &&
    //                     mapRSVXVsFUE.get(ql.SBQQ__RequiredBy__c) != null
    //                 ) {
    //                     //To Add EE-AR: When Eff Qty of any RSV QLI is equal to 0 & FUE exists
    //                     system.debug('Pure Upgrade for EE-AR Addition: ' + ql.SBQQ__RequiredBy__c + ' & QName: ' + ql.SBQQ__Quote__r.Name);
    //                     mapToAddEEAR_AmendmentQuote_v1.put(ql.SBQQ__RequiredBy__c, true); //To auto-add EE-AR
    //                     mapToAddEESR_AmendmentQuote_v1.put(ql.SBQQ__RequiredBy__c, true);
    //                 }
    //             }
    //         }
    //     }
    //     System.debug('mapToAddFEAR_AmendmentQuote: ' + mapToAddFEAR_AmendmentQuote + ' & mapToAddFEAR_AmendmentQuote Size: ' + mapToAddFEAR_AmendmentQuote.size());
    //     System.debug('mapToAddFESR_AmendmentQuote: ' + mapToAddFESR_AmendmentQuote + ' & mapToAddFESR_AmendmentQuote Size: ' + mapToAddFESR_AmendmentQuote.size());
    //     system.debug('mapPCodeVsQLI_AR: ' + mapPCodeVsQLI_AR + ' & mapPCodeVsQLI_AR Size: ' + mapPCodeVsQLI_AR.size());
    //     system.debug('mapPCodeVsQLI_SR: ' + mapPCodeVsQLI_SR + ' & mapPCodeVsQLI_SR Size: ' + mapPCodeVsQLI_SR.size());
    //     System.debug('mapToAddEEAR_AmendmentQuote_v1: ' + mapToAddEEAR_AmendmentQuote_v1 + ' & mapToAddEEAR_AmendmentQuote_v1 Size: ' + mapToAddEEAR_AmendmentQuote_v1.size());
    //     System.debug('mapToAddEEAR_AmendmentQuote_v1: ' + mapToAddEEAR_AmendmentQuote_v1 + ' & mapToAddEEAR_AmendmentQuote_v1 Size: ' + mapToAddEEAR_AmendmentQuote_v1.size());

    //     for (SBQQ__QuoteLine__c allQLI: lstQLI) {
    //         for (SBQQ__QuoteLine__c ql: mapRSVXQLI.values()) {
    //             //To find if AR already exists and create a new collection to store AR QLIs to delete OR mark them Optional/Hidden
    //             if (allQLI.SBQQ__Product__c != null && mapPCodeVsQLI_AR != null && !mapPCodeVsQLI_AR.IsEmpty() &&
    //                 mapPCodeVsQLI_AR.containsKey(allQLI.SBQQ__ProductCode__c) &&
    //                 mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__RequiredBy__c != null &&
    //                 mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__RequiredBy__c == ql.Id) {
    //                 system.debug('Bundle has OND-AR SKU already auto-added & existing');

    //                 if (mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__ProductCode__c != null) {
    //                     system.debug('If FE RSVX already has FE-AR lines added: ' +
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c));

    //                     if (QuoteRecType == 'Quote' &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Foundation Edition') {
    //                         mapRSVXwithExistingFEAR.put(ql.Id, mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__ProductCode__c);
    //                         system.debug('Inside Quote: ' + mapRSVXwithExistingFEAR);
    //                     }
    //                     if (QuoteRecType == 'Amendment' &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Foundation Edition') {
    //                         mapRSVXwithExistingFEAR.put(ql.Id, mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__ProductCode__c);
    //                     }

    //                     if (mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('If EE RSVX already has AR lines added: ' + ql.Id +
    //                             ' vs: ' + mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__ProductCode__c);
    //                         mapEEARExistsForRSVX.put(ql.Id, mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__ProductCode__c);
    //                     }
    //                 }

    //                 System.debug('B4: ' + mapRSVXProdIdVsRec.containsKey(ql.SBQQ__Product__c) +
    //                     ' & B5: ' + allQLI.Id + ' vs ' + ql.Id + ' sv ' + ql.SBQQ__Product__c);
    //                 if (ql.SBQQ__Product__c != null &&
    //                     mapRSVXProdIdVsRec != null && !mapRSVXProdIdVsRec.IsEmpty() && mapRSVXProdIdVsRec.containsKey(ql.SBQQ__Product__c) &&
    //                     mapRSVXProdIdVsRec.get(ql.SBQQ__Product__c) != null) {
    //                     System.debug('Date on New Sale3');

    //                     mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__StartDate__c = mapRSVXProdIdVsRec.get(ql.SBQQ__Product__c).SBQQ__StartDate__c;
    //                     mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__EndDate__c = mapRSVXProdIdVsRec.get(ql.SBQQ__Product__c).SBQQ__EndDate__c;
    //                     //mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Quote__c = ql.SBQQ__Quote__c;
    //                     //mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Number__c = lineNumberCount + 1;
    //                     mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Scale_Utility_Product_RSV_OND__c = 'OND';
    //                     mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Scale_Utility_Product_Identifier__c = 'OND AR';
    //                     mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Quantity__c = 1;
    //                     mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Discount__c = 100;
    //                     mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__OptionLevel__c = 1;
    //                     mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__OptionType__c = 'Related Product';
    //                     mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__NetPrice__c = 0;

    //                     qliMapToUpdate.put(mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id, mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c));
    //                 }

    //                 /** START: Amendment Quote **/
    //                 if (QuoteRecType == 'Amendment') {
    //                     //Marking FE-AR as Optional/Hidden without Upgrade if user flips the Eff Quantity equal to 0
    //                     if ((mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty()) &&
    //                         (ReqByVsEffQty == null || ReqByVsEffQty.IsEmpty())
    //                     ) {
    //                         system.debug('Pure Expansion: Marking FE-AR QLIs as Optional/Hidden: ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c));

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                     }
    //                     if (allQLI.SBQQ__RequiredBy__c != null &&
    //                         ReqByVsEffQty != null && !ReqByVsEffQty.IsEmpty() &&
    //                         ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                         ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                         ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c).size() > 0 &&
    //                         (mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty() || !mapRSVXVsFUE.containsKey(allQLI.SBQQ__RequiredBy__c)) &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c != 'Enterprise Edition'
    //                     ) {
    //                         system.debug('Pure Expansion: Revert FE-AR QLIs as Optional/Hidden: ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c));

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = FALSE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = FALSE;
    //                     }
    //                     //Marking FE-AR as Optional/Hidden with Upgrade is present
    //                     if (mapRSVXVsFUE != null && !mapRSVXVsFUE.IsEmpty() &&
    //                         mapRSVXVsFUE.containsKey(mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__RequiredBy__c) &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c != 'Enterprise Edition') {
    //                         system.debug('Upgrade: Marking FE-AR as Optional/Hidden when FUE exists: ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                     }
    //                     //Marking EE-AR as Optional/Hidden with Upgrade is present
    //                     system.debug('KP00: ' + allQLI.SBQQ__ProductCode__c);
    //                     system.debug('KP0: ' + mapRSVXVsFUE);
    //                     system.debug('KP1: ' + allQLI.SBQQ__RequiredBy__r.Product_Type__c);
    //                     system.debug('KP2: ' + mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c);
    //                     system.debug('KP2: ' + allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c);
    //                     if ((mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty()) &&
    //                         allQLI.SBQQ__RequiredBy__r.Product_Type__c == 'Foundation Edition' &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('Upgrade when added under FE Bundle: Marking EE-AR as Optional/Hidden when No FUE exists : ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                     }
    //                     if ((mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty()) &&
    //                         allQLI.SBQQ__RequiredBy__r.Product_Type__c == 'M365H' &&
    //                         allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c != null &&
    //                         allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c.contains('UR-FE-MD-RSVX') &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('Upgrade when added under FE Bundle: Marking EE-AR as Optional/Hidden when No FUE exists : ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                     }
    //                     if ((mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty()) &&
    //                         allQLI.SBQQ__RequiredBy__r.Product_Type__c == 'M365H' &&
    //                         ((allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c != null && allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c.contains('UR-EE-MD-RSVX')) ||
    //                             allQLI.SBQQ__RequiredBy__r.Product_Type__c == 'Enterprise Edition') &&
    //                         (ReqByVsEffQty != null && !ReqByVsEffQty.IsEmpty() &&
    //                             ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                             ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                             ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c).size() > 0) &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('Upgrade when added under FE Bundle: Marking EE-AR as Optional/Hidden when No FUE exists : ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = FALSE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = FALSE;
    //                     }
    //                     if ((mapRSVXVsFUE != null && !mapRSVXVsFUE.IsEmpty()) &&
    //                         mapRSVXVsFUE.containsKey(mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__RequiredBy__c) &&
    //                         allQLI.SBQQ__RequiredBy__r.Product_Type__c == 'M365H' &&
    //                         allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c != null &&
    //                         allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c.contains('UR-FE-MD-RSVX') &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('Upgrade when added under FE Bundle: Marking EE-AR as Optional/Hidden when No FUE exists : ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = FALSE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = FALSE;
    //                     }
    //                     if ((mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty()) &&
    //                         allQLI.SBQQ__RequiredBy__r.Product_Type__c == 'Enterprise Edition' &&
    //                         ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                         ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                         ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() <= 1 &&
    //                         (ReqByVsEffQty == null || ReqByVsEffQty.IsEmpty()) &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('Upgrade: EE Bundle Marking EE-AR as Optional/Hidden when No FUE exists: ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                     }

    //                     if ((mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty()) &&
    //                         allQLI.SBQQ__RequiredBy__r.Product_Type__c == 'Enterprise Edition' &&
    //                         ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                         ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                         ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() > 1 &&
    //                         (ReqByVsEffQty != null && !ReqByVsEffQty.IsEmpty() && ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                             ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                             ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c).size() > 0) &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('Upgrade: EE Bundle Marking EE-AR as Optional/Hidden when No FUE exists: ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id);
    //                         system.debug('KK1 ' + allQLI.SBQQ__RequiredBy__r.Product_Type__c + allQLI.Id);
    //                         system.debug('KK2 ' + ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c).size());

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = FALSE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = FALSE;
    //                     }
    //                     if ((mapRSVXVsFUE != null && !mapRSVXVsFUE.IsEmpty()) &&
    //                         mapRSVXVsFUE.containsKey(mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__RequiredBy__c) &&
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('Upgrade: Marking EE-AR as Optional/Hidden when FUE exists: ' +
    //                             mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = FALSE;
    //                         mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = FALSE;
    //                     }
    //                     qliMapToUpdate.put(mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c).Id, mapPCodeVsQLI_AR.get(allQLI.SBQQ__ProductCode__c));
    //                 }
    //                 /** END: Amendment Quote **/
    //             }

    //             //To find if SR already exists and create a new collection to store SR QLIs to delete
    //             if (allQLI.SBQQ__Product__c != null && mapPCodeVsQLI_SR != null && !mapPCodeVsQLI_SR.IsEmpty() &&
    //                 mapPCodeVsQLI_SR.containsKey(allQLI.SBQQ__ProductCode__c) &&
    //                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__RequiredBy__c != null &&
    //                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__RequiredBy__c == ql.Id) {
    //                 system.debug('Bundle has OND-SR SKU already auto-added & existing');

    //                 if (mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__ProductCode__c != null) {
    //                     system.debug('If FE RSVX already has FE-SR lines added: ' +
    //                         mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c));

    //                     if (QuoteRecType == 'Quote' &&
    //                         mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Foundation Edition') {
    //                         system.debug('SR Present New: ' + ql.Id);
    //                         mapRSVXwithExistingFESR.put(ql.Id, mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__ProductCode__c);
    //                     }
    //                     if (QuoteRecType == 'Amendment' &&
    //                         mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Foundation Edition') {
    //                         system.debug('SR Present Amd: ' + ql.Id);
    //                         mapRSVXwithExistingFESR.put(ql.Id, mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__ProductCode__c);
    //                     }

    //                     if (mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('If RSVX already has SR lines added: ' + ql.Id);
    //                         mapEESRExistsForRSVX.put(ql.Id, mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__ProductCode__c);
    //                     }
    //                 }

    //                 System.debug('B4: ' + mapRSVXProdIdVsRec.containsKey(ql.SBQQ__Product__c) +
    //                     ' & B5: ' + allQLI.Id + ' vs ' + ql.Id + ' sv ' + ql.SBQQ__Product__c);
    //                 if (ql.SBQQ__Product__c != null &&
    //                     mapRSVXProdIdVsRec != null && !mapRSVXProdIdVsRec.IsEmpty() && mapRSVXProdIdVsRec.containsKey(ql.SBQQ__Product__c) &&
    //                     mapRSVXProdIdVsRec.get(ql.SBQQ__Product__c) != null) {
    //                     System.debug('Date on New Sale3');
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__StartDate__c = mapRSVXProdIdVsRec.get(ql.SBQQ__Product__c).SBQQ__StartDate__c;
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__EndDate__c = mapRSVXProdIdVsRec.get(ql.SBQQ__Product__c).SBQQ__EndDate__c;
    //                     //mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Quote__c = ql.SBQQ__Quote__c;
    //                     //mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Number__c = lineNumberCount + 1;
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Scale_Utility_Product_RSV_OND__c = 'OND';
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Scale_Utility_Product_Identifier__c = 'OND SR';
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Quantity__c = 1;
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Discount__c = 100;
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__OptionLevel__c = 1;
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__OptionType__c = 'Related Product';
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__NetPrice__c = 0;

    //                     qliMapToUpdate.put(mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id, mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c));
    //                 }
    //                 /** START: Amendment Quote **/
    //                 if (QuoteRecType == 'Amendment') {
    //                     //Marking FE-SR as Optional/Hidden without Upgrade when user flips to non-ramp Qty value
    //                     if (allQLI.SBQQ__RequiredBy__c != null &&
    //                         ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                         ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                         (mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty() || !mapRSVXVsFUE.containsKey(allQLI.SBQQ__RequiredBy__c)) &&
    //                         (ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() <= 1 ||
    //                             (ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() > 1 && (ReqByVsEffQty == null || ReqByVsEffQty.IsEmpty() || !ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c)))
    //                         )
    //                     ) {
    //                         system.debug('Pure Expansion - Marking FE-SR as Optional & Hidden without FUE: ' +
    //                             mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                         mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                         mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                     }
    //                     //Newly added to make FE-SR as optional
    //                     if (allQLI.SBQQ__RequiredBy__c != null &&
    //                         ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                         ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                         ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() > 1 &&
    //                         (ReqByVsEffQty != null && !ReqByVsEffQty.IsEmpty() && ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                             ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                             ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c).size() > 0) &&
    //                         (mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty() || !mapRSVXVsFUE.containsKey(allQLI.SBQQ__RequiredBy__c))
    //                     ) {
    //                         //Marking FE-SR as Optional/Hidden without Upgrade when user flips to ramp Qty value
    //                         system.debug('Pure Expansion - Revert FE-SR as Optional & Hidden without FUE: ' +
    //                             mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                         mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = FALSE;
    //                         mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = FALSE;
    //                     }
    //                     //Start - Marking FE-SR QLIs as Optional & Hidden when FUE is present
    //                     if (mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Foundation Edition') {
    //                         //Marking FE-SR as Optional/Hidden with Upgrade Eff Qty = 0
    //                         if ((mapRSVXVsFUE != null && !mapRSVXVsFUE.IsEmpty() &&
    //                                 mapRSVXVsFUE.containsKey(mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__RequiredBy__c))) {
    //                             system.debug('Pure Upgrade - Marking FE-SR QLIs as Optional & Hidden when FUE exists: ' +
    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                             mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                             mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                         }
    //                     }
    //                     if (mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Product_Type__c == 'Enterprise Edition') {
    //                         system.debug('PQR' + ql.Id + ' Vs: ' + allQLI.Id);

    //                         //Marking EE-SR as Optional & Hidden when FUE is present when there's no ramp
    //                         if (mapRSVXVsFUE != null && !mapRSVXVsFUE.IsEmpty() &&
    //                             mapRSVXVsFUE.containsKey(mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__RequiredBy__c)) {
    //                             system.debug('2K: ' + mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                             if (allQLI.SBQQ__RequiredBy__c != null &&
    //                                 ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                                 ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                                 ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() <= 1 &&
    //                                 ((ReqByVsEffQty != null && !ReqByVsEffQty.IsEmpty() &&
    //                                         ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                                         ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                                         ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c).size() > 0) ||
    //                                     (ReqByVsEffQty == null || ReqByVsEffQty.IsEmpty() && !ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c))
    //                                 )
    //                             ) {
    //                                 system.debug('1p: ' + mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                             }
    //                             if (allQLI.SBQQ__RequiredBy__c != null &&
    //                                 ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                                 ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                                 ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() > 1 &&
    //                                 ((ReqByVsEffQty != null && !ReqByVsEffQty.IsEmpty() &&
    //                                         ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                                         ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                                         ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c).size() > 0) ||
    //                                     (ReqByVsEffQty == null || ReqByVsEffQty.IsEmpty() && !ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c))
    //                                 )
    //                             ) {
    //                                 //Start - Marking EE-SR QLIs as Optional & Hidden when FUE is present when there is ramp back to old value
    //                                 system.debug('2p: ' + mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = FALSE;
    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = FALSE;
    //                             }
    //                         }
    //                         if ((mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty()) &&
    //                             (allQLI.SBQQ__RequiredBy__r.Product_Type__c == 'Foundation Edition' ||
    //                                 (allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c != null && allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c.contains('RS-UR-FE-MD-RSVX'))
    //                             )
    //                         ) {
    //                             system.debug('Upgrade: Marking EE-SR as Optional/Hidden when No FUE exists: ' +
    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);
    //                             mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                             mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                         }
    //                         if ((mapRSVXVsFUE == null || mapRSVXVsFUE.IsEmpty()) &&
    //                             (allQLI.SBQQ__RequiredBy__r.Product_Type__c == 'Enterprise Edition' ||
    //                                 (allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c != null && allQLI.SBQQ__RequiredBy__r.SBQQ__ProductCode__c.contains('RS-UR-EE-MD-RSVX'))
    //                             )
    //                         ) {
    //                             system.debug('Upgrade: Marking EE-SR as Optional/Hidden when No FUE exists: ' +
    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                             if (ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                                 ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                                 ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() <= 1 &&
    //                                 (ReqByVsEffQty != null && !ReqByVsEffQty.IsEmpty() &&
    //                                     ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                                     ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                                     ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c).size() > 0
    //                                 )
    //                             ) {
    //                                 system.debug('UpgradeX: ' + mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);

    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;
    //                             }
    //                             if (
    //                                 ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                                 ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                                 ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() > 1 &&
    //                                 (ReqByVsEffQty != null && !ReqByVsEffQty.IsEmpty() &&
    //                                     ReqByVsEffQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                                     ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                                     ReqByVsEffQty.get(allQLI.SBQQ__RequiredBy__c).size() > 0
    //                                 )
    //                             ) {
    //                                 system.debug('UpgradeY:' + mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id);
    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = FALSE;
    //                                 mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = FALSE;
    //                             }
    //                         }
    //                     }
    //                     qliMapToUpdate.put(mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id, mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c));
    //                 }
    //                 /** END: Amendment Quote **/

    //                 //Start - Quote: Marking SR QLIs as Optional & Hidden when Quantity is flipped back to non-ramp value
    //                 system.debug('allQLI.Id1: ' + allQLI.Id + ' Vs ql.Id1: ' + ql.Id);
    //                 if (QuoteRecType == 'Quote' &&
    //                     ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                     ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                     ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() <= 1
    //                 ) {
    //                     System.debug('Marking SR QLIs as Optional & Hidden when Quantity is flipped back to non-ramp value: ' +
    //                         mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c));
    //                     system.debug('allQLI.Id2: ' + allQLI.Id + ' Vs ql.Id2:' + ql.Id);

    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = TRUE;
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = TRUE;

    //                     qliMapToUpdate.put(mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id, mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c));
    //                 }
    //                 if (QuoteRecType == 'Quote' &&
    //                     ReqByVsQty != null && !ReqByVsQty.IsEmpty() && ReqByVsQty.containsKey(allQLI.SBQQ__RequiredBy__c) &&
    //                     ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c) != null &&
    //                     ReqByVsQty.get(allQLI.SBQQ__RequiredBy__c).size() > 1
    //                 ) {
    //                     //Quote: Marking SR QLIs as Optional & Hidden when Quantity is flipped back to ramp value
    //                     System.debug('Marking SR QLIs as Optional & Hidden when Quantity is flipped back to ramp value: ' +
    //                         mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c));
    //                     system.debug('allQLI.Id3: ' + allQLI.Id + ' Vs ql.Id3:' + ql.Id);

    //                     //To set flags as FALSE again when user gives ramp
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Optional__c = FALSE;
    //                     mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).SBQQ__Hidden__c = FALSE;

    //                     qliMapToUpdate.put(mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c).Id, mapPCodeVsQLI_SR.get(allQLI.SBQQ__ProductCode__c));
    //                 }
    //             }
    //         }
    //     }
    //     system.debug('mapRSVXwithExistingFEAR: ' + mapRSVXwithExistingFEAR + ' & mapRSVXwithExistingFEAR Size: ' + mapRSVXwithExistingFEAR.size());
    //     system.debug('mapRSVXwithExistingFESR: ' + mapRSVXwithExistingFESR + ' & mapRSVXwithExistingFESR Size: ' + mapRSVXwithExistingFESR.size());
    //     system.debug('mapEEARExistsForRSVX: ' + mapEEARExistsForRSVX + ' & mapEEARExistsForRSVX Size: ' + mapEEARExistsForRSVX.size());
    //     system.debug('mapEESRExistsForRSVX: ' + mapEESRExistsForRSVX + ' & mapEESRExistsForRSVX Size: ' + mapEESRExistsForRSVX.size());

    //     if (lstQLI != null && !lstQLI.IsEmpty()) {
    //         for (SBQQ__QuoteLine__c qli: lstQLI) {
    //             system.debug('Enter here: ' + qli.Id + ' Vs Product: ' + qli.SBQQ__Product__c);

    //             /********* AR ADDITION **********/
    //             if (qli.SBQQ__Product__c != null && mapRSVXVsAROND_Option != null && !mapRSVXVsAROND_Option.IsEmpty() &&
    //                 (mapRSVXVsAROND_Option.containsKey(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)) ||
    //                     mapRSVXVsAROND_Option.containsKey(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c) ||
    //                     mapRSVXVsAROND_Option.containsKey(String.valueOf(qli.SBQQ__Product__c) + 'EE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c)
    //                 ) &&
    //                 qli.SBQQ__Quote__c != null && OpptyRecSubType == 'GC Offer' &&
    //                 ((QuoteRecType == 'Amendment' &&
    //                     mapRSVXProdIdVsRec != null && !mapRSVXProdIdVsRec.IsEmpty() && mapRSVXProdIdVsRec.containskey(qli.SBQQ__Product__c) &&
    //                     mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c) != null &&
    //                     (
    //                         //Start: For adding FE-AR when Qty is changed & has Ramp, no FUE
    //                         (mapToAddFEAR_AmendmentQuote != null && !mapToAddFEAR_AmendmentQuote.IsEmpty() &&
    //                             mapToAddFEAR_AmendmentQuote.containsKey(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) &&
    //                             mapToAddFEAR_AmendmentQuote.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true &&
    //                             !mapRSVXwithExistingFEAR.containsKey(qli.Id)
    //                         )
    //                         //Start: For adding EE-AR when Qty is changed & has Ramp, yes FUE
    //                         ||
    //                         (mapToAddEEAR_AmendmentQuote_v1 != null && !mapToAddEEAR_AmendmentQuote_v1.IsEmpty() &&
    //                             mapToAddEEAR_AmendmentQuote_v1.containsKey(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) &&
    //                             mapToAddEEAR_AmendmentQuote_v1.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) != null &&
    //                             mapToAddEEAR_AmendmentQuote_v1.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true &&
    //                             !mapEEARExistsForRSVX.containsKey(qli.Id)
    //                         )
    //                     )
    //                 ))
    //             ) {
    //                 System.debug('Enter for AR Addition: ' + qli.Id + ' , : ' + qli.SBQQ__ProductCode__c + ' ,ProdType: ' + qli.Product_Type__c);

    //                 SBQQ__QuoteLine__c addAR_QLI = new SBQQ__QuoteLine__c();

    //                 addAR_QLI.SBQQ__Quote__c = qli.SBQQ__Quote__c;
    //                 addAR_QLI.SBQQ__Number__c = lineNumberCount + 1;
    //                 addAR_QLI.Scale_Utility_Product_RSV_OND__c = 'OND';
    //                 addAR_QLI.Scale_Utility_Product_Identifier__c = 'OND AR';
    //                 addAR_QLI.SBQQ__Quantity__c = 1;
    //                 addAR_QLI.SBQQ__Discount__c = 100;
    //                 addAR_QLI.SBQQ__OptionLevel__c = 1;
    //                 addAR_QLI.SBQQ__OptionType__c = 'Related Product';
    //                 addAR_QLI.SBQQ__NetPrice__c = 0;

    //                 //Added by Joyce for calculation of OnDemand_Discount__c
    //                 system.debug('qliMapReqByRSV: ' + qliMapReqByRSV + ' vs QName: ' + qli.SBQQ__Quote__r.Name + ' vs qli.Id: ' + qli.Id);
    //                 if ((mapRSVXVsFUE.containsKey(qli.Id) && mapRSVXVsFUE.get(qli.Id) != null &&
    //                         mapRSVXVsFUE.get(qli.Id).SBQQ__NetPrice__c != null &&
    //                         mapRSVXVsFUE.get(qli.Id).SBQQ__ProrateMultiplier__c != null &&
    //                         mapRSVXVsFUE.get(qli.Id).SBQQ__ListPrice__c != null) ||
    //                     (qliMapReqByRSV.containsKey(qli.Id) && qliMapReqByRSV.get(qli.Id) != null &&
    //                         qliMapReqByRSV.get(qli.Id).SBQQ__NetPrice__c != null &&
    //                         qliMapReqByRSV.get(qli.Id).SBQQ__ListPrice__c != null &&
    //                         qliMapReqByRSV.get(qli.Id).SBQQ__Discount__c != null)
    //                 ) {
    //                     addAR_QLI.OnDemand_Discount__c = mapRSVXVsFUE.containsKey(qli.Id) ?
    //                         ((1 - ((qliMapReqByRSV.get(qli.Id).SBQQ__NetPrice__c +
    //                                 (mapRSVXVsFUE.get(qli.Id).SBQQ__NetPrice__c / mapRSVXVsFUE.get(qli.Id).SBQQ__ProrateMultiplier__c)) /
    //                             (qliMapReqByRSV.get(qli.Id).SBQQ__ListPrice__c + mapRSVXVsFUE.get(qli.Id).SBQQ__ListPrice__c))) * 100).setScale(2) :
    //                         qliMapReqByRSV.get(qli.Id).SBQQ__Discount__c;
    //                 }
    //                 system.debug('X0: ' + mapToAddEEAR_AmendmentQuote_v1);
    //                 system.debug('X1: ' + mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id);
    //                 system.debug('X2: ' + mapToAddEEAR_AmendmentQuote_v1.containsKey(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id));
    //                 system.debug('X3: ' + mapEEARExistsForRSVX);
    //                 system.debug('X4: ' + mapEEARExistsForRSVX.containsKey(qli.Id));
    //                 system.debug('X5: ' + qli.SBQQ__ProductCode__c + ' Vs Product_Type: ' + qli.Product_Type__c);
    //                 if (mapEEOptionId_AR != null && !mapEEOptionId_AR.IsEmpty() &&
    //                     ((QuoteRecType == 'Amendment' &&
    //                         mapToAddEEAR_AmendmentQuote_v1 != null && !mapToAddEEAR_AmendmentQuote_v1.IsEmpty() &&
    //                         mapToAddEEAR_AmendmentQuote_v1.containsKey(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) &&
    //                         mapToAddEEAR_AmendmentQuote_v1.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true &&
    //                         !mapEEARExistsForRSVX.containsKey(qli.Id) &&
    //                         mapEEOptionId_AR.containsKey(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')) &&
    //                         (qli.Product_Type__c == 'Foundation Edition' || qli.Product_Type__c == 'Enterprise Edition')
    //                     ))
    //                 ) {
    //                     system.debug('Enter for New Quote Foundation AR-EE Option: ' + qli.Id + ' , : ' + qli.SBQQ__ProductCode__c);

    //                     if (qli.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX') {
    //                         if (QuoteRecType == 'Amendment' &&
    //                             qli.Product_Type__c == 'Foundation Edition'
    //                         ) {
    //                             system.debug('J1 AMD:');
    //                             addAR_QLI.SBQQ__Product__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__c;
    //                             //addAR_QLI.SBQQ__Description__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Description;
    //                             addAR_QLI.Product_Level__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Level__c;
    //                             addAR_QLI.Member_of_Bundle_Edition_s__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                             addAR_QLI.Product_Payment_Option__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                             addAR_QLI.Payment_Options__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         }
    //                         system.debug('PType: ' + qli.Product_Type__c + ' vs QName: ' + qli.SBQQ__Quote__r.Name);
    //                         if ((QuoteRecType == 'Amendment'
    //                                 //|| QuoteRecType == 'Quote'
    //                             ) &&
    //                             qli.Product_Type__c == 'Enterprise Edition'
    //                             //&& mapEEOptionId_AR.containsKey(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition'))
    //                         ) {
    //                             system.debug('J2 AMD1:');
    //                             addAR_QLI.SBQQ__Product__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__c;
    //                             //addAR_QLI.SBQQ__Description__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Description;
    //                             addAR_QLI.Product_Level__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Level__c;
    //                             addAR_QLI.Member_of_Bundle_Edition_s__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                             addAR_QLI.Product_Payment_Option__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                             addAR_QLI.Payment_Options__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                             addAR_QLI.SBQQ__ProductOption__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).Id;
    //                             addAR_QLI.Product_Type__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Type__c;

    //                             if (QuoteRecType == 'Amendment' &&
    //                                 mapEEOptionId_AR.containsKey(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')) &&
    //                                 mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')) != null) {
    //                                 system.debug('J2 AMD1 DynamicOptionId:');
    //                                 addAR_QLI.SBQQ__DynamicOptionId__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__Feature__c;
    //                             }
    //                         }
    //                         addAR_QLI.SBQQ__Description__c = mapEEOptionId_AR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Description;
    //                     }
    //                 }

    //                 if (mapEEOptionId_AR != null && !mapEEOptionId_AR.IsEmpty() &&
    //                     mapEEOptionId_AR.containsKey(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')) &&
    //                     ((QuoteRecType == 'Amendment' &&
    //                         mapToAddEEAR_AmendmentQuote_v1 != null && !mapToAddEEAR_AmendmentQuote_v1.IsEmpty() &&
    //                         mapToAddEEAR_AmendmentQuote_v1.containsKey(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) &&
    //                         mapToAddEEAR_AmendmentQuote_v1.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true &&
    //                         !mapEEARExistsForRSVX.containsKey(qli.Id) &&
    //                         qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null &&
    //                         (qli.SBQQ__ProductCode__c.contains('RS-UR-FE-MD-RSVX') ||
    //                             qli.SBQQ__ProductCode__c.contains('RS-UR-EE-MD-RSVX')
    //                         )
    //                     ))
    //                 ) {
    //                     system.debug('qli.SBQQ__Product__c: ' + qli.SBQQ__Product__c);

    //                     if (QuoteRecType == 'Amendment' &&
    //                         qli.Product_Type__c == 'Enterprise Edition' && qli.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX' &&
    //                         mapEEOptionId_AR.containsKey(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition'))
    //                     ) {
    //                         system.debug('J3 AMD:');
    //                         addAR_QLI.SBQQ__Product__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__c;
    //                         //addAR_QLI.SBQQ__Description__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Description;
    //                         addAR_QLI.Product_Level__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Level__c;
    //                         addAR_QLI.Member_of_Bundle_Edition_s__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                         addAR_QLI.Product_Payment_Option__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         addAR_QLI.Payment_Options__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         addAR_QLI.SBQQ__ProductOption__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).Id;
    //                         addAR_QLI.Product_Type__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Type__c;
    //                         addAR_QLI.SBQQ__DynamicOptionId__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__Feature__c;

    //                     }
    //                     if (QuoteRecType == 'Amendment' &&
    //                         qli.Product_Type__c == 'M365H' && qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null &&
    //                         (qli.SBQQ__ProductCode__c.contains('FE-MD-RSVX') ||
    //                             qli.SBQQ__ProductCode__c.contains('EE-MD-RSVX') //added newly ** m365h
    //                         )
    //                     ) {
    //                         system.debug('J4 AMD:' + qli.SBQQ__Product__c);
    //                         addAR_QLI.SBQQ__Product__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__c;
    //                         //addAR_QLI.SBQQ__Description__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Description;
    //                         addAR_QLI.Product_Level__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Level__c;
    //                         addAR_QLI.Member_of_Bundle_Edition_s__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                         addAR_QLI.Product_Payment_Option__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         addAR_QLI.Payment_Options__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;

    //                         if (qli.SBQQ__ProductCode__c.contains('FE-MD-RSVX') &&
    //                             mapOptionId_AR != null && !mapOptionId_AR.IsEmpty() &&
    //                             mapOptionId_AR.containsKey((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))) &&
    //                             mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))) != null
    //                         ) {
    //                             system.debug('J41 AMD:' + addAR_QLI.SBQQ__Product__c + ' & ' + qli.SBQQ__Product__r.Support_Type__c);
    //                             addAR_QLI.SBQQ__ProductOption__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).Id;
    //                             addAR_QLI.Product_Type__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).SBQQ__OptionalSKU__r.Product_Type__c;
    //                             addAR_QLI.SBQQ__DynamicOptionId__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).SBQQ__Feature__c;
    //                         }
    //                         system.debug('J42 AMD:' + mapEEOptionId_AR.containsKey(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')));
    //                         if (qli.SBQQ__ProductCode__c.contains('EE-MD-RSVX') &&
    //                             mapEEOptionId_AR != null && !mapEEOptionId_AR.IsEmpty() &&
    //                             mapEEOptionId_AR.containsKey(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')) &&
    //                             mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')) != null
    //                         ) {
    //                             system.debug('J43 AMD:' + addAR_QLI.SBQQ__Product__c + ' & ' + qli.SBQQ__Product__r.Support_Type__c);
    //                             addAR_QLI.SBQQ__ProductOption__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).Id;
    //                             addAR_QLI.Product_Type__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Type__c;
    //                             addAR_QLI.SBQQ__DynamicOptionId__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__Feature__c;
    //                         }
    //                     }
    //                     addAR_QLI.SBQQ__Description__c = mapEEOptionId_AR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Description;
    //                 }
    //                 if (QuoteRecType == 'Amendment' & mapOptionId_AR != null && !mapOptionId_AR.IsEmpty() &&
    //                     mapOptionId_AR.containsKey((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))) &&
    //                     mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))) != null
    //                 ) {
    //                     system.debug('W1:' + addAR_QLI.SBQQ__Product__c + ' & ' + qli.SBQQ__Product__c);
    //                     addAR_QLI.SBQQ__ProductOption__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))).Id;
    //                     addAR_QLI.Product_Type__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))).SBQQ__OptionalSKU__r.Product_Type__c;
    //                     addAR_QLI.SBQQ__DynamicOptionId__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))).SBQQ__Feature__c;
    //                 }

    //                 if ((QuoteRecType == 'Amendment' &&
    //                         mapToAddFEAR_AmendmentQuote != null && !mapToAddFEAR_AmendmentQuote.IsEmpty() &&
    //                         mapToAddFEAR_AmendmentQuote.containsKey(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) &&
    //                         mapToAddFEAR_AmendmentQuote.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true &&
    //                         !mapRSVXwithExistingFEAR.containsKey(qli.Id)
    //                     )) {
    //                     system.debug('Enter for Foundation FE-AR Version: ' + qli.SBQQ__Product__c);

    //                     if ((qli.Product_Type__c == 'Foundation Edition' && qli.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX')
    //                     || (qli.Product_Type__c == 'M365 Backup Storage' && qli.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                     || (qli.SBQQ__ProductCode__c.containsIgnoreCase('-SA-') && qli.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                     ) {
    //                         system.debug('B1');
    //                         addAR_QLI.SBQQ__Product__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__c;
    //                         addAR_QLI.SBQQ__Description__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Description;
    //                         addAR_QLI.Product_Level__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Product_Level__c;
    //                         addAR_QLI.Member_of_Bundle_Edition_s__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                         addAR_QLI.Product_Payment_Option__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         addAR_QLI.Payment_Options__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                     }
    //                     if (qli.Product_Type__c == 'M365H' && qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('FE-MD-RSVX')) {
    //                         system.debug('B2');
    //                         addAR_QLI.SBQQ__Product__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c;
    //                         addAR_QLI.SBQQ__Description__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Description;
    //                         addAR_QLI.Product_Level__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Product_Level__c;
    //                         addAR_QLI.Member_of_Bundle_Edition_s__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                         addAR_QLI.Product_Payment_Option__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         addAR_QLI.Payment_Options__c = mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                     }
    //                     if (qli.Product_Type__c == 'Foundation Edition' && qli.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX' &&
    //                         mapOptionId_AR != null && !mapOptionId_AR.IsEmpty() &&
    //                         mapOptionId_AR.containsKey((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))) &&
    //                         mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))) != null
    //                     ) {
    //                         system.debug('Enter for Foundation AR-FE Optionx: ');
    //                         addAR_QLI.SBQQ__ProductOption__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))).Id;
    //                         addAR_QLI.Product_Type__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))).SBQQ__OptionalSKU__r.Product_Type__c;

    //                         if (QuoteRecType == 'Amendment') {
    //                             addAR_QLI.SBQQ__DynamicOptionId__c = mapOptionId_AR.get(
    //                                 (String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addAR_QLI.SBQQ__Product__c))).SBQQ__Feature__c;
    //                         }
    //                     }

    //                     if (qli.Product_Type__c == 'M365H' && qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('FE-MD-RSVX') &&
    //                         mapOptionId_AR != null && !mapOptionId_AR.IsEmpty() &&
    //                         mapOptionId_AR.containsKey((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))) &&
    //                         mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))) != null
    //                     ) {
    //                         system.debug('Enter for Foundation AR-FE Optiony: ');
    //                         addAR_QLI.SBQQ__ProductOption__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).Id;
    //                         addAR_QLI.Product_Type__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).SBQQ__OptionalSKU__r.Product_Type__c;

    //                         if (QuoteRecType == 'Amendment') {
    //                             addAR_QLI.SBQQ__DynamicOptionId__c = mapOptionId_AR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsAROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).SBQQ__Feature__c;
    //                         }
    //                     }
    //                 }

    //                 if (mapRSVXProdIdVsRec != null && !mapRSVXProdIdVsRec.IsEmpty() && mapRSVXProdIdVsRec.containskey(qli.SBQQ__Product__c)) {
    //                     system.debug('AR: Enter to populate mandatory fields for all types of Quotes: ' + mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c));
    //                     addAR_QLI.SBQQ__RequiredBy__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id;
    //                     addAR_QLI.SBQQ__StartDate__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).SBQQ__StartDate__c;
    //                     addAR_QLI.SBQQ__EndDate__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).SBQQ__EndDate__c;
    //                     addAR_QLI.SBQQ__SubscriptionTerm__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).SBQQ__SubscriptionTerm__c;
    //                     addAR_QLI.SBQQ__SubscriptionPricing__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).SBQQ__SubscriptionPricing__c;
    //                 }
    //                 if (productToPbeMap != null && !productToPbeMap.IsEmpty() &&
    //                     productToPbeMap.containsKey(addAR_QLI.SBQQ__Product__c) &&
    //                     productToPbeMap.get(addAR_QLI.SBQQ__Product__c) != null) {
    //                     system.debug('Enter to set Prices for AR QLIs');
    //                     PricebookEntry pbEntry = productToPbeMap.get(addAR_QLI.SBQQ__Product__c);
    //                     addAR_QLI.SBQQ__PricebookEntryId__c = pbEntry.Id;
    //                     addAR_QLI.SBQQ__ListPrice__c = pbEntry.UnitPrice;
    //                 }
    //                 if (addAR_QLI.SBQQ__Product__c != null) {
    //                     mapTest.put((String.valueOf(addAR_QLI.SBQQ__RequiredBy__c) +
    //                             String.valueOf(addAR_QLI.SBQQ__Product__c)),
    //                         (String.valueOf(addAR_QLI.SBQQ__Product__c) +
    //                             String.valueOf(addAR_QLI.SBQQ__RequiredBy__c)));
    //                 }
    //                 qliToInsert.add(addAR_QLI);
    //             }

    //             /********* SR ADDITION **********/
    //             if (qli.SBQQ__Product__c != null && mapRSVXVsSROND_Option != null && !mapRSVXVsSROND_Option.IsEmpty() &&
    //                 (mapRSVXVsSROND_Option.containsKey(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)) ||
    //                     mapRSVXVsSROND_Option.containsKey(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c) ||
    //                     mapRSVXVsSROND_Option.containsKey(String.valueOf(qli.SBQQ__Product__c) + 'EE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c)
    //                 ) &&
    //                 qli.SBQQ__Quote__c != null && OpptyRecSubType == 'GC Offer' &&
    //                 ((QuoteRecType == 'Amendment' &&
    //                     mapRSVXProdIdVsRec != null && !mapRSVXProdIdVsRec.IsEmpty() && mapRSVXProdIdVsRec.containskey(qli.SBQQ__Product__c) &&
    //                     mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c) != null &&
    //                     (
    //                         //Start For FE-SR when No FUE & Qty is changed
    //                         (!mapRSVXwithExistingFESR.containsKey(qli.Id) &&
    //                             mapToAddFESR_AmendmentQuote != null && !mapToAddFESR_AmendmentQuote.IsEmpty() &&
    //                             mapToAddFESR_AmendmentQuote.containsKey(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) &&
    //                             mapToAddFESR_AmendmentQuote.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true
    //                         )
    //                         //Start For EE-SR when FUE exists & Qty is changed
    //                         ||
    //                         (!mapEESRExistsForRSVX.containsKey(qli.Id) &&
    //                             mapToAddEESR_AmendmentQuote_v1 != null && !mapToAddEESR_AmendmentQuote_v1.IsEmpty() &&
    //                             mapToAddEESR_AmendmentQuote_v1.containsKey(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) &&
    //                             mapToAddEESR_AmendmentQuote_v1.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true
    //                         )
    //                     )
    //                 ))
    //             ) {
    //                 System.debug('Enter for SR Addition: ' + qli.Id + ' Vs ' + qli.SBQQ__Product__c);

    //                 SBQQ__QuoteLine__c addSR_QLI = new SBQQ__QuoteLine__c();

    //                 addSR_QLI.SBQQ__Quote__c = qli.SBQQ__Quote__c;
    //                 addSR_QLI.SBQQ__Number__c = lineNumberCount + 1;
    //                 addSR_QLI.Scale_Utility_Product_RSV_OND__c = 'OND';
    //                 addSR_QLI.Scale_Utility_Product_Identifier__c = 'OND SR';
    //                 addSR_QLI.SBQQ__Quantity__c = 1;
    //                 addSR_QLI.SBQQ__Discount__c = 100;
    //                 addSR_QLI.SBQQ__OptionLevel__c = 1;
    //                 addSR_QLI.SBQQ__OptionType__c = 'Related Product';
    //                 addSR_QLI.SBQQ__NetPrice__c = 0;

    //                 //Added by Joyce for calculation of OnDemand_Discount__c
    //                 if ((mapRSVXVsFUE.containsKey(qli.Id) && mapRSVXVsFUE.get(qli.Id) != null &&
    //                         mapRSVXVsFUE.get(qli.Id).SBQQ__NetPrice__c != null &&
    //                         mapRSVXVsFUE.get(qli.Id).SBQQ__ProrateMultiplier__c != null &&
    //                         mapRSVXVsFUE.get(qli.Id).SBQQ__ListPrice__c != null) ||
    //                     (qliMapReqByRSV.containsKey(qli.Id) && qliMapReqByRSV.get(qli.Id) != null &&
    //                         qliMapReqByRSV.get(qli.Id).SBQQ__NetPrice__c != null &&
    //                         qliMapReqByRSV.get(qli.Id).SBQQ__ListPrice__c != null &&
    //                         qliMapReqByRSV.get(qli.Id).SBQQ__Discount__c != null)
    //                 ) {
    //                     addSR_QLI.OnDemand_Discount__c = mapRSVXVsFUE.containsKey(qli.Id) ?
    //                         ((1 - ((qliMapReqByRSV.get(qli.Id).SBQQ__NetPrice__c +
    //                                 (mapRSVXVsFUE.get(qli.Id).SBQQ__NetPrice__c / mapRSVXVsFUE.get(qli.Id).SBQQ__ProrateMultiplier__c)) /
    //                             (qliMapReqByRSV.get(qli.Id).SBQQ__ListPrice__c + mapRSVXVsFUE.get(qli.Id).SBQQ__ListPrice__c))) * 100).setScale(2) :
    //                         qliMapReqByRSV.get(qli.Id).SBQQ__Discount__c;
    //                 }

    //                 if (
    //                     ((QuoteRecType == 'Amendment' &&
    //                         ((mapToAddEESR_AmendmentQuote_v1 != null && !mapToAddEESR_AmendmentQuote_v1.IsEmpty() &&
    //                             mapToAddEESR_AmendmentQuote_v1.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true)) &&
    //                         !mapEESRExistsForRSVX.containsKey(qli.Id) &&
    //                         mapEEOptionId_SR != null && !mapEEOptionId_SR.IsEmpty() &&
    //                         qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null &&
    //                         (qli.SBQQ__ProductCode__c.contains('RS-UR-FE-MD-RSVX') ||
    //                             qli.SBQQ__ProductCode__c.contains('RS-UR-EE-MD-RSVX') //added newly ** m365h
    //                         )
    //                     ))
    //                 ) {
    //                     system.debug('Enter for New Quote SR Enterprise Version: ');

    //                     if (QuoteRecType == 'Amendment' && !mapEESRExistsForRSVX.containsKey(qli.Id)) {
    //                         system.debug('Enter for New Quote Enterprise SR-EE-MD Option: ' + qli.SBQQ__Product__c);

    //                         addSR_QLI.SBQQ__Product__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__c;
    //                         addSR_QLI.SBQQ__Description__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Description;
    //                         addSR_QLI.Product_Level__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Level__c;
    //                         addSR_QLI.Member_of_Bundle_Edition_s__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                         addSR_QLI.Product_Payment_Option__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         addSR_QLI.Payment_Options__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;

    //                         if (qli.SBQQ__ProductCode__c.contains('RS-UR-FE-MD-RSVX') &&
    //                             mapOptionId_SR != null && !mapOptionId_SR.IsEmpty() &&
    //                             mapRSVXVsSROND_Option != null && !mapRSVXVsSROND_Option.IsEmpty() &&
    //                             mapRSVXVsSROND_Option.containsKey(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c) &&
    //                             mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c) != null &&
    //                             mapOptionId_SR.containsKey((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))) &&
    //                             mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))) != null
    //                         ) {
    //                             system.debug('AMD Enterprise SR-EE-MD Option 1:' + qli.SBQQ__Product__c);
    //                             addSR_QLI.SBQQ__ProductOption__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).Id;
    //                             addSR_QLI.Product_Type__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Type__c;
    //                             addSR_QLI.SBQQ__DynamicOptionId__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).SBQQ__Feature__c;
    //                         }
    //                         if (qli.SBQQ__ProductCode__c.contains('RS-UR-EE-MD-RSVX') &&
    //                             mapEEOptionId_SR != null && !mapEEOptionId_SR.IsEmpty() &&
    //                             mapEEOptionId_SR.containsKey(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')) &&
    //                             mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')) != null
    //                         ) {
    //                             system.debug('AMD Enterprise SR-EE-MD Option 2:' + qli.SBQQ__Product__c);
    //                             addSR_QLI.SBQQ__ProductOption__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).Id;
    //                             addSR_QLI.SBQQ__DynamicOptionId__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__Feature__c;
    //                         }
    //                     }

    //                     if (qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('RS-UR-EE-MD-RSVX') && qli.Product_Type__c == 'M365H' &&
    //                         (QuoteRecType == 'Amendment')
    //                     ) {
    //                         system.debug('XYZ');
    //                         addSR_QLI.SBQQ__ProductOption__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).Id;
    //                         addSR_QLI.Product_Type__c = mapEEOptionId_SR.get(('RS-UR-EE-MD-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Type__c;
    //                     }
    //                 }

    //                 if (
    //                     (
    //                         (QuoteRecType == 'Amendment' &&
    //                             mapToAddEESR_AmendmentQuote_v1 != null && !mapToAddEESR_AmendmentQuote_v1.IsEmpty() &&
    //                             mapToAddEESR_AmendmentQuote_v1.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true &&
    //                             !mapEESRExistsForRSVX.containsKey(qli.Id) &&
    //                             (qli.Product_Type__c == 'Foundation Edition' ||
    //                                 qli.Product_Type__c == 'Enterprise Edition'
    //                             )
    //                         )
    //                     )
    //                 ) {
    //                     system.debug('Enter for New Quote Enterprise SR-EE Option: ');

    //                     if (QuoteRecType == 'Amendment' &&
    //                         (qli.Product_Type__c == 'Foundation Edition' || qli.Product_Type__c == 'Enterprise Edition')
    //                     ) {
    //                         system.debug('D1 AMD:');
    //                         addSR_QLI.SBQQ__Product__c = mapEEOptionId_SR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__c;
    //                         addSR_QLI.SBQQ__Description__c = mapEEOptionId_SR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Description;
    //                         addSR_QLI.Product_Level__c = mapEEOptionId_SR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Level__c;
    //                         addSR_QLI.Member_of_Bundle_Edition_s__c = mapEEOptionId_SR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                         addSR_QLI.Product_Payment_Option__c = mapEEOptionId_SR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         addSR_QLI.Payment_Options__c = mapEEOptionId_SR.get(('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + 'Enterprise Edition')).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                     }
    //                 }

    //                 if (QuoteRecType == 'Amendment' && mapOptionId_SR != null && !mapOptionId_SR.IsEmpty() &&
    //                     mapOptionId_SR.containsKey((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))) &&
    //                     mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))) != null
    //                 ) {
    //                     system.debug('W2:' + addSR_QLI.SBQQ__Product__c + ' & ' + qli.SBQQ__Product__c);
    //                     addSR_QLI.SBQQ__ProductOption__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))).Id;
    //                     addSR_QLI.Product_Type__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))).SBQQ__OptionalSKU__r.Product_Type__c;
    //                     addSR_QLI.SBQQ__DynamicOptionId__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))).SBQQ__Feature__c;
    //                 }
    //                 //Added Newly when EE-AR/SR is supposed to be added under Enterprise bundle
    //                 if (QuoteRecType == 'Amendment' && qli.Product_Type__c == 'Enterprise Edition' &&
    //                     mapEEOptionId_SR != null && !mapEEOptionId_SR.IsEmpty() &&
    //                     mapEEOptionId_SR.containsKey('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)) &&
    //                     mapEEOptionId_SR.get('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)) != null
    //                 ) {
    //                     system.debug('W3B:' + addSR_QLI.SBQQ__Product__c + ' & ' + qli.SBQQ__Product__c);
    //                     addSR_QLI.SBQQ__ProductOption__c = mapEEOptionId_SR.get('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).Id;
    //                     addSR_QLI.Product_Type__c = mapEEOptionId_SR.get('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Product_Type__c;
    //                     addSR_QLI.SBQQ__DynamicOptionId__c = mapEEOptionId_SR.get('RS-TB-EE-RSVX' + String.valueOf(qli.SBQQ__Product__r.Support_Type__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__Feature__c;
    //                 }
    //                 //add EE-SR on a FE Bundle
    //                 if (
    //                     (
    //                         (QuoteRecType == 'Amendment' &&
    //                             ((qli.Product_Type__c == 'Foundation Edition' && qli.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX') 
    //                             || (qli.Product_Type__c == 'M365 Backup Storage' && qli.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                             || (qli.SBQQ__ProductCode__c.containsIgnoreCase('-SA-') && qli.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                             || (qli.Product_Type__c == 'M365H' && qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('FE-MD-RSVX'))
    //                             ) &&
    //                             mapToAddFESR_AmendmentQuote != null && !mapToAddFESR_AmendmentQuote.IsEmpty() &&
    //                             mapToAddFESR_AmendmentQuote.containsKey(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) &&
    //                             mapToAddFESR_AmendmentQuote.get(mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id) == true &&
    //                             !mapRSVXwithExistingFESR.containsKey(qli.Id)
    //                         )
    //                     )
    //                 ) {
    //                     system.debug('When mapToAddSR_AmendmentQuote does not contains: ');
    //                     if ((qli.Product_Type__c == 'Foundation Edition' && qli.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX')
    //                     || (qli.Product_Type__c == 'M365 Backup Storage' && qli.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                     || (qli.SBQQ__ProductCode__c.containsIgnoreCase('-SA-') && qli.Scale_Utility_Product_Identifier__c == 'M365 SU RSVX')
    //                     ) {
    //                         addSR_QLI.SBQQ__Product__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__c;
    //                         addSR_QLI.SBQQ__Description__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Description;
    //                         addSR_QLI.Product_Level__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Product_Level__c;
    //                         addSR_QLI.Member_of_Bundle_Edition_s__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                         addSR_QLI.Product_Payment_Option__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         addSR_QLI.Payment_Options__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + String.valueOf(qli.SBQQ__Product__r.Product_Type__c)).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                     }
    //                     if (qli.Product_Type__c == 'M365H' && qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('FE-MD-RSVX')) {
    //                         addSR_QLI.SBQQ__Product__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c;
    //                         addSR_QLI.SBQQ__Description__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Description;
    //                         addSR_QLI.Product_Level__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Product_Level__c;
    //                         addSR_QLI.Member_of_Bundle_Edition_s__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
    //                         addSR_QLI.Product_Payment_Option__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                         addSR_QLI.Payment_Options__c = mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__r.Product_Payment_Option__c;
    //                     }
    //                     if (qli.Product_Type__c == 'Foundation Edition' && qli.Scale_Utility_Product_Identifier__c != 'M365 SU RSVX' &&
    //                         mapOptionId_SR != null && !mapOptionId_SR.IsEmpty() &&
    //                         mapOptionId_SR.containsKey((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))) &&
    //                         mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))) != null
    //                     ) {
    //                         system.debug('Enter for Foundation AR-FE Option: ');
    //                         addSR_QLI.SBQQ__ProductOption__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))).Id;
    //                         addSR_QLI.Product_Type__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))).SBQQ__OptionalSKU__r.Product_Type__c;

    //                         if (QuoteRecType == 'Amendment') {
    //                             addSR_QLI.SBQQ__DynamicOptionId__c = mapOptionId_SR.get(
    //                                 (String.valueOf(qli.SBQQ__Product__c) + String.valueOf(addSR_QLI.SBQQ__Product__c))).SBQQ__Feature__c;
    //                         }
    //                     }
    //                     if (qli.Product_Type__c == 'M365H' && qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('FE-MD-RSVX') &&
    //                         mapOptionId_SR != null && !mapOptionId_SR.IsEmpty() &&
    //                         mapOptionId_SR.containsKey((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))) &&
    //                         mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))) != null
    //                     ) {
    //                         system.debug('Enter for Foundation AR-FE Option: ');
    //                         addSR_QLI.SBQQ__ProductOption__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).Id;
    //                         addSR_QLI.Product_Type__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).SBQQ__OptionalSKU__r.Product_Type__c;

    //                         if (QuoteRecType == 'Amendment') {
    //                             addSR_QLI.SBQQ__DynamicOptionId__c = mapOptionId_SR.get((String.valueOf(qli.SBQQ__Product__c) + String.valueOf(mapRSVXVsSROND_Option.get(String.valueOf(qli.SBQQ__Product__c) + 'FE-MD-RSVX' + qli.SBQQ__Product__r.Support_Type__c).SBQQ__OptionalSKU__c) + String.valueOf(qli.SBQQ__Product__r.Support_Type__c))).SBQQ__Feature__c;
    //                         }
    //                     }
    //                 }

    //                 if (mapRSVXProdIdVsRec != null && !mapRSVXProdIdVsRec.IsEmpty() && mapRSVXProdIdVsRec.containskey(qli.SBQQ__Product__c)) {
    //                     system.debug('SR: Enter to populate mandatory fields for all types of Quotes: ');
    //                     addSR_QLI.SBQQ__RequiredBy__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).Id;
    //                     addSR_QLI.SBQQ__StartDate__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).SBQQ__StartDate__c;
    //                     addSR_QLI.SBQQ__EndDate__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).SBQQ__EndDate__c;
    //                     addSR_QLI.SBQQ__SubscriptionTerm__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).SBQQ__SubscriptionTerm__c;
    //                     addSR_QLI.SBQQ__SubscriptionPricing__c = mapRSVXProdIdVsRec.get(qli.SBQQ__Product__c).SBQQ__SubscriptionPricing__c;
    //                 }
    //                 if (productToPbeMap != null && !productToPbeMap.IsEmpty() &&
    //                     productToPbeMap.containsKey(addSR_QLI.SBQQ__Product__c) &&
    //                     productToPbeMap.get(addSR_QLI.SBQQ__Product__c) != null
    //                 ) {
    //                     system.debug('Enter to set Prices for SR QLIs');
    //                     PricebookEntry pbEntry = productToPbeMap.get(addSR_QLI.SBQQ__Product__c);
    //                     addSR_QLI.SBQQ__PricebookEntryId__c = pbEntry.Id;
    //                     addSR_QLI.SBQQ__ListPrice__c = pbEntry.UnitPrice;
    //                 }
    //                 if (addSR_QLI.SBQQ__Product__c != null) {
    //                     mapTest.put((String.valueOf(addSR_QLI.SBQQ__RequiredBy__c) +
    //                             String.valueOf(addSR_QLI.SBQQ__Product__c)),
    //                         (String.valueOf(addSR_QLI.SBQQ__Product__c) +
    //                             String.valueOf(addSR_QLI.SBQQ__RequiredBy__c)));
    //                 }
    //                 qliToInsert.add(addSR_QLI);
    //             }
    //         }
    //     }
    //     System.debug('mapTest: ' + mapTest + ' & mapTest Size: ' + mapTest.size());
    //     System.debug('qliToInsert: ' + qliToInsert + ' & qliToInsert Size: ' + qliToInsert.size());

    //     if (qliToInsert != NULL && !qliToInsert.IsEmpty()) {
    //         for (SBQQ__QuoteLine__c qliRec: qliToInsert) {
    //             system.debug('JJ1: ' + mapTest.containsKey((String.valueOf(qliRec.SBQQ__RequiredBy__c) + String.valueOf(qliRec.SBQQ__Product__c))));
    //             system.debug('JJ2: ' + qliRec.SBQQ__RequiredBy__c);
    //             system.debug('JJ3: ' + qliRec.SBQQSC__UpgradedContractLine__c);
    //             system.debug('JJ4: ' + qliRec.SBQQ__Product__c);

    //             if (qliRec.SBQQ__RequiredBy__c != null && qliRec.SBQQSC__UpgradedContractLine__c == null &&
    //                 mapTest != null && !mapTest.IsEmpty() &&
    //                 mapTest.containsKey((String.valueOf(qliRec.SBQQ__RequiredBy__c) + String.valueOf(qliRec.SBQQ__Product__c))) &&
    //                 mapTest.get((String.valueOf(qliRec.SBQQ__RequiredBy__c) + String.valueOf(qliRec.SBQQ__Product__c))) != null &&
    //                 mapTest.get((String.valueOf(qliRec.SBQQ__RequiredBy__c) + String.valueOf(qliRec.SBQQ__Product__c))) ==
    //                 (String.valueOf(qliRec.SBQQ__Product__c) + String.valueOf(qliRec.SBQQ__RequiredBy__c)) &&
    //                 (mapCheck == null || mapCheck.IsEmpty() ||
    //                     !mapCheck.containsKey((String.valueOf(qliRec.SBQQ__RequiredBy__c) + String.valueOf(qliRec.SBQQ__Product__c)))
    //                 )
    //             ) {
    //                 system.debug('Final: ' + qliRec.Id);
    //                 qliToInsertFinal.put((String.valueOf(qliRec.SBQQ__RequiredBy__c) + String.valueOf(qliRec.SBQQ__Product__c)),
    //                     qliRec);
    //             }
    //         }
    //     }
    //     system.debug('calledfrom: ' + calledfrom);
    //     system.debug('QuoteRecType: ' + QuoteRecType);
    //     if (qliToInsertFinal != NULL && !qliToInsertFinal.IsEmpty() &&
    //         !qliToInsertFinal.values().IsEmpty() &&
    //         (
    //             calledFrom == 'beforeUpdate' ||
    //             calledFrom == 'beforeInsert'
    //         )
    //     ) {
    //         System.debug('Before qliToInsert: ' + qliToInsertFinal + ' & Before qliToInsert Size: ' + qliToInsertFinal.size());
    //         //TriggerControls.disableQuoteTrigger = true;
    //         //TriggerControls.disableQuoteLineTrigger = true;
    //         SBQQ.TriggerControl.disable();

    //         insert qliToInsertFinal.values(); //qliToInsert;
    //         System.debug('After qliToInsert: ' + qliToInsert + ' & After qliToInsert Size: ' + qliToInsert.size());

    //         SBQQ.TriggerControl.enable();
    //     }
    //     if (qliMapToUpdate != NULL && !qliMapToUpdate.IsEmpty() && !qliMapToUpdate.values().IsEmpty()) {
    //         System.debug('Before qliMapToUpdate: ' + qliMapToUpdate + ' & Before qliMapToUpdate Size: ' + qliMapToUpdate.size());
    //         SBQQ.TriggerControl.disable();

    //         update qliMapToUpdate.values();
    //         System.debug('After qliMapToUpdate: ' + qliMapToUpdate + ' & After qliMapToUpdate Size: ' + qliMapToUpdate.size());
    //         SBQQ.TriggerControl.enable();
    //     }
    // }
    /*END: CSU-492 Auto-Addition of OND AR & SR SKUs on the New & Amendment Quotes by Shaloo*/

    /*START: CSU-492 Auto-Addition of OND AR & SR SKUs on the New & Amendment Quotes by Joyce*/
    /**
     * @description This method is used to auto-add On-Demand AR & SR SKUs on the New & Amendment Quotes.
     * @param quoteId Set of Quote Ids
     * @param calledfrom String to identify the context from which this method is called
     */
    @future
    public static void autoAddONDSKUsFuture(Set < Id > quoteId, String calledfrom) {
        System.debug(LoggingLevel.INFO, 'Entered autoAddONDSKUsFuture_v2');
        System.debug(LoggingLevel.INFO, 'calledfrom->'+calledfrom);
        System.debug(LoggingLevel.INFO, 'quoteId->'+quoteId);

        List < SBQQ__ProductOption__c > lstOnDemandProductOptions; //Collection to store all the On-Demand AR & SR Product Options
        Map < String, SBQQ__ProductOption__c > mapIdtToONDOption = new Map<String, SBQQ__ProductOption__c>(); //Collection to store all the On-Demand AR & SR Product Options
        Set < Id > products = new Set < Id > (); //Collection to store unique On Demand AR/SR Product IDs
        List < PricebookEntry > pbEntries; //Collection to store all the Pricebook Entries for On-Demand AR & SR Products
        Map < Id, PricebookEntry > productToPbeMap = new Map < Id, PricebookEntry > (); //Collection to store Price book Entries wrt to AR/SR Products
        String strPricebookId = ''; //Variable to store Quote's Price Book ID
        Boolean boolQuoteUncalculated = false; //Variable to store Quote's Price Book ID
        List<String> lstUpgradeTypes =  !String.isBlank(System.Label.RBK_SUUpgradeEditions) ? System.Label.RBK_SUUpgradeEditions.split(',') : new List<String>{'SU FUE', 'SU FUP', 'SU EUP', 'SU FUB', 'SU BUE'};
        Map<Id, Boolean> mapQuotesForceRecalc = new Map<Id, Boolean>();

        List < SBQQ__QuoteLine__c > lstQLI; //Collection to store all the QLIs existing on a Quote
        Map < Id, AutoAddONDSKUWrapper > mapQLIDToAddOnWrapper = new Map < Id, AutoAddONDSKUWrapper >(); //Collection to store all the QLIs existing on a Quote

        List < SBQQ__QuoteLine__c > lstQLIsToUpsert = new List < SBQQ__QuoteLine__c > ();
        List < SBQQ__QuoteLine__c > lstQLIsToDelete = new List < SBQQ__QuoteLine__c > ();
        Map < Id, SBQQ__QuoteLine__c > mapIdToQLIsUpdate = new Map < Id, SBQQ__QuoteLine__c > ();

        if (quoteId != null && !quoteId.IsEmpty() && lstQLI == null) {
            lstQLI = [SELECT Id, SBQQ__Product__c, SBQQ__ProductCode__c, SBQQ__Number__c, SBQQ__ProductOption__c, Line_Type__c, SBQQ__Quote__c,
                SBQQ__RequiredBy__c, Scale_Utility_Product_RSV_OND__c, Scale_Utility_Product_Identifier__c, SBQQ__Quantity__c,
                SBQQ__EffectiveQuantity__c, SBQQ__PriorQuantity__c, Member_of_Bundle_Edition_s__c, SBQQ__StartDate__c, SBQQ__EndDate__c,
                SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__r.OpportunitySubType__c, SBQQ__Quote__r.SBQQ__LineItemCount__c, Product_Type__c,
                SBQQ__SubscriptionTerm__c, SBQQ__SubscriptionPricing__c, SBQQ__SegmentIndex__c, SBQQ__Product__r.Pricebook_Entry_Id__c,
                SBQQ__SegmentLabel__c, SBQQ__Product__r.Support_Type__c, SBQQ__PricebookEntryId__c, SBQQ__NetPrice__c, SBQQ__ListPrice__c,
                SBQQ__Quote__r.SBQQ__PricebookId__c, SBQQSC__UpgradedContractLine__c, SBQQ__RequiredBy__r.Product_Type__c,
                SBQQ__Product__r.Product_Type__c, SBQQ__DynamicOptionId__c, Product_Level__c, Support_Type__c, Product_Payment_Option__c,
                SBQQ__RequiredBy__r.Scale_Utility_Product_Identifier__c, SBQQ__RequiredBy__r.SBQQ__ProductCode__c,
                SBQQ__RequiredBy__r.Scale_Utility_Product_RSV_OND__c, SBQQ__Product__r.Description, SBQQ__Quote__r.Name,
                SBQQ__ProductOption__r.SBQQ__OptionalSKU__r.Description, SBQQ__Description__c, SBQQ__ProrateMultiplier__c, SBQQ__Discount__c,
                SBQQ__Product__r.Upgrade_Path__c, SBQQ__Product__r.Scale_Utility_Upgrade_Editions__c, SBQQ__Optional__c, 
                SBQQ__ProductOption__r.SBQQ__Selected__c, SBQQ__Quote__r.SBQQ__Uncalculated__c, Quote_Line_Type__c, Storage_Region_Bundle_FrontEnd__c, 
                Storage_Region_Bundle__c, Product_Code_Type__c, SBQQ__Quote__r.Force_Recalculation__c
                FROM SBQQ__QuoteLine__c WHERE
                SBQQ__Quote__c IN: quoteId
                ORDER BY SBQQ__RequiredBy__c, SBQQ__SegmentLabel__c ASC
            ];
            System.debug(LoggingLevel.INFO, 'lstQLI Size: ' + lstQLI.size());
        }

        if (lstQLI != null && !lstQLI.isEmpty()) {
            strPricebookId = lstQLI[0].SBQQ__Quote__r.SBQQ__PricebookId__c;
            boolQuoteUncalculated = lstQLI[0].SBQQ__Quote__r.SBQQ__Uncalculated__c;

            if (Schema.sObjectType.SBQQ__ProductOption__c.isAccessible() && lstOnDemandProductOptions == null) {
                lstOnDemandProductOptions = [SELECT Id, SBQQ__ConfiguredSKU__c, SBQQ__ConfiguredSKU__r.ProductCode, SBQQ__ConfiguredSKU__r.Product_Type__c,
                    SBQQ__ConfiguredSKU__r.Support_Type__c, SBQQ__ConfiguredSKU__r.Scale_Utility_Product_Identifier__c,
                    SBQQ__Feature__c, SBQQ__Feature__r.Name, SBQQ__Type__c, SBQQ__Number__c, SBQQ__OptionalSKU__c,
                    SBQQ__OptionalSKU__r.ProductCode, SBQQ__OptionalSKU__r.Product_Type__c, SBQQ__OptionalSKU__r.Support_Type__c,
                    SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c, SBQQ__OptionalSKU__r.Product_Level__c,SBQQ__OptionalSKU__r.Product_Subtype__c,
                    SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c, SBQQ__OptionalSKU__r.Pricebook_Entry_Id__c, SBQQ__Selected__c,
                    SBQQ__OptionalSKU__r.Product_Payment_Option__c, SBQQ__OptionalSKU__r.Description, Product_Type__c, SBQQ__OptionalSKU__r.Scale_Utility_Upgrade_Editions__c, Storage_Region_Bundle_FrontEnd__c, Storage_Region_Bundle__c
                    FROM SBQQ__ProductOption__c
                    WHERE(SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c = 'OND AR'
                        OR SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c = 'OND SR')
                    ORDER BY SBQQ__ConfiguredSKU__r.ProductCode, SBQQ__Number__c ASC
                ];
                System.debug(LoggingLevel.INFO, 'lstOnDemandProductOptions Size: ' + lstOnDemandProductOptions.size());
            }
    
            if (lstOnDemandProductOptions != null && !lstOnDemandProductOptions.IsEmpty()) {
                for (SBQQ__ProductOption__c option: lstOnDemandProductOptions) {
                    products.add(option.SBQQ__OptionalSKU__c);
                    if(String.isNotBlank(option.SBQQ__OptionalSKU__r.Scale_Utility_Upgrade_Editions__c)) {
                        List<String> lstUGEditions = option.SBQQ__OptionalSKU__r.Scale_Utility_Upgrade_Editions__c.split(';');
                        for(String eachEdition : lstUGEditions) {
                            mapIdtToONDOption.put(option.SBQQ__ConfiguredSKU__c + '_' + option.SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c + '_' + eachEdition, option);
                        }
                    } 
                    if(option.SBQQ__Selected__c) {
                        mapIdtToONDOption.put(option.SBQQ__ConfiguredSKU__c + '_' + option.SBQQ__OptionalSKU__r.Scale_Utility_Product_Identifier__c+ '_'+option.SBQQ__Selected__c, option);
                    }
                }
            }

            if (Schema.sObjectType.PricebookEntry.isAccessible() && pbEntries == null && !products.IsEmpty() && strPricebookId != '') {
                pbEntries = [SELECT Id, Product2Id, UnitPrice, Product2.Product_Type__c, Product2.Product_Level__c, Product2.Category__c,
                    Product2.Description, Product2.SBQQ__SubscriptionTerm__c, Product2.SBQQ__SubscriptionType__c, Product2.ProductCode,
                    Product2.SBQQ__SubscriptionPricing__c, Product2.SBQQ__NonDiscountable__c, Product2.SBQQ__DefaultQuantity__c,
                    Product2.Sales_Comp_Category__c FROM PricebookEntry WHERE Product2Id IN: products AND Pricebook2Id =: strPricebookId
                    AND IsActive = TRUE
                ];
                System.debug(LoggingLevel.INFO, 'pbEntries Size: ' + pbEntries.size());
            }

            //Create Map from Product to their corresponding Pricebook Entry for the Quote's Pricebook
            if (pbEntries != null && !pbEntries.IsEmpty()) {
                for (PricebookEntry pbEntry: pbEntries) {
                    productToPbeMap.put(pbEntry.Product2Id, pbEntry);
                }
            }

            for (SBQQ__QuoteLine__c qli: lstQLI) {
                if (qli.SBQQ__RequiredBy__c != null && qli.SBQQ__RequiredBy__r.SBQQ__ProductCode__c != null && qli.SBQQ__RequiredBy__r.SBQQ__ProductCode__c.containsIgnoreCase('RSVX')) {
                    AutoAddONDSKUWrapper objAddOnWrap = new AutoAddONDSKUWrapper(qli.SBQQ__RequiredBy__c);
                    if (mapQLIDToAddOnWrapper.containsKey(qli.SBQQ__RequiredBy__c)) {
                        objAddOnWrap = mapQLIDToAddOnWrapper.get(qli.SBQQ__RequiredBy__c);
                    }
                    objAddOnWrap.quoteType = qli.SBQQ__Quote__r.SBQQ__Type__c;
                    if (!String.isBlank(qli.Scale_Utility_Product_Identifier__c) && qli.Scale_Utility_Product_Identifier__c.equalsIgnoreCase('OND AR') && qli.Quote_Line_Type__c.equalsIgnoreCase('New')) {
                        objAddOnWrap.lstARLines.add(qli);
                    } else if (!String.isBlank(qli.Scale_Utility_Product_Identifier__c) && qli.Scale_Utility_Product_Identifier__c.equalsIgnoreCase('OND SR') && qli.Quote_Line_Type__c.equalsIgnoreCase('New')) {
                        objAddOnWrap.lstSRLines.add(qli);
                    } else if (qli.SBQQ__ProductCode__c.containsIgnoreCase('RSV') && qli.SBQQ__SegmentIndex__c != null) {
                        objAddOnWrap.setSegmentQty.add(qli.SBQQ__Quantity__c);
                        if(qli.SBQQ__EffectiveQuantity__c > 0) {
                        objAddOnWrap.setSegmentEffQty.add(qli.SBQQ__EffectiveQuantity__c);
                        }
                        if (qli.SBQQ__SegmentIndex__c == 1) {
                            objAddOnWrap.qlRSVLine = qli;
                        }
                    } else if (String.isNotBlank(qli.Product_Type__c) && lstUpgradeTypes.contains(qli.Scale_Utility_Product_Identifier__c) && qli.Quote_Line_Type__c.equalsIgnoreCase('New')) {
                        objAddOnWrap.qlUGLine = qli;
                        objAddOnWrap.hasUGSKU = true;
                    } else if (qli.SBQQ__Product__c != null && qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.contains('OND') &&
                        qli.Member_of_Bundle_Edition_s__c == 'Scale Utility' &&
                        (qli.SBQQSC__UpgradedContractLine__c != null || qli.Line_Type__c == 'Amendment')
                        ) {
                        qli.SBQQ__RequiredBy__c = null;
                        qli.SBQQ__ProductOption__c = null;
                        qli.SBQQ__DynamicOptionId__c = null;
                        lstQLIsToUpsert.add(qli);
                    }
                    mapQLIDToAddOnWrapper.put(qli.SBQQ__RequiredBy__c, objAddOnWrap);
                    
                } else if (qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.containsIgnoreCase('RSVX')) {
                    AutoAddONDSKUWrapper objAddOnWrap = new AutoAddONDSKUWrapper(qli.Id);
                    if (mapQLIDToAddOnWrapper.containsKey(qli.Id)) {
                        objAddOnWrap = mapQLIDToAddOnWrapper.get(qli.Id);
                    }
                    objAddOnWrap.reqByRSVXLine = qli;
                    mapQLIDToAddOnWrapper.put(qli.Id, objAddOnWrap);
                }
            }

            Map<String, SBQQ__QuoteLine__c> mapRSVXEditionARLine = new Map<String, SBQQ__QuoteLine__c>();
            mapQLIDToAddOnWrapper.remove(null);
            System.debug(LoggingLevel.INFO, 'mapQLIDToAddOnWrapper.size->'+mapQLIDToAddOnWrapper.size());
            System.debug(LoggingLevel.INFO, 'mapQLIDToAddOnWrapper.keyset->'+mapQLIDToAddOnWrapper.keyset());
            for (AutoAddONDSKUWrapper eachRSVXWrapLine: mapQLIDToAddOnWrapper.values()) {
                Integer lineNumberCount = lstQLI.size();
                //System.debug(LoggingLevel.INFO, 'eachRSVXWrapLine->'+eachRSVXWrapLine);
                //System.debug(LoggingLevel.INFO, 'eachRSVXWrapLine.reqByRSVXLine->'+eachRSVXWrapLine.reqByRSVXLine);
                //System.debug(LoggingLevel.INFO, 'eachRSVXWrapLine.setSegmentQty->'+eachRSVXWrapLine.setSegmentQty);
                //System.debug(LoggingLevel.INFO, 'eachRSVXWrapLine.setSegmentEffQty->'+eachRSVXWrapLine.setSegmentEffQty);
                
                if (eachRSVXWrapLine.reqByRSVXLine != null 
                    && !eachRSVXWrapLine.setSegmentQty.isEmpty() && eachRSVXWrapLine.setSegmentQty.size() > 1
                    /*&& !eachRSVXWrapLine.setSegmentEffQty.isEmpty() && eachRSVXWrapLine.setSegmentEffQty.size() > 1*/) {
                    eachRSVXWrapLine.hasRamp = true;
                }
                
                //System.debug(LoggingLevel.INFO, 'eachRSVXWrapLine.hasRamp->'+eachRSVXWrapLine.hasRamp);

                //System.debug(LoggingLevel.INFO, 'eachRSVXWrapLine.hasUGSKU->'+eachRSVXWrapLine.hasUGSKU);
                if (eachRSVXWrapLine.hasUGSKU) {
                    Boolean hasUpgradedAR = false;
                    Boolean hasUpgradedSR = false;
                    String strUGtoEdition = '';
                    //if AR/SR is already added mark old AR/SR false and upgraded AR/SR true
                    if(String.isNotBlank(eachRSVXWrapLine.qlUGLine.Scale_Utility_Product_Identifier__c)) {
                        strUGtoEdition = eachRSVXWrapLine.qlUGLine.Scale_Utility_Product_Identifier__c.split(' ')[1].trim();
                    }
                    for(SBQQ__QuoteLine__c eachARLine : eachRSVXWrapLine.lstARLines) {
                        if(String.isNotBlank(strUGtoEdition) && String.isNotBlank(eachARLine.SBQQ__Product__r.Scale_Utility_Upgrade_Editions__c) 
                            && eachARLine.SBQQ__Product__r.Scale_Utility_Upgrade_Editions__c.containsIgnoreCase(strUGtoEdition)){
                            hasUpgradedAR = true;
                            if(eachARLine.SBQQ__Optional__c) {
                                eachARLine.SBQQ__Optional__c = false;
                                lstQLIsToUpsert.add(eachARLine);
                                mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                            }
                        } else if(!eachARLine.SBQQ__Optional__c) {
                            eachARLine.SBQQ__Optional__c = true;
                            //eachARLine.SBQQ__Discount__c = 100;
                            lstQLIsToUpsert.add(eachARLine);
                            mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                        }
                    }
                    for(SBQQ__QuoteLine__c eachSRLine : eachRSVXWrapLine.lstSRLines) {
                        if(String.isNotBlank(strUGtoEdition) && String.isNotBlank(eachSRLine.SBQQ__Product__r.Scale_Utility_Upgrade_Editions__c) 
                            && eachSRLine.SBQQ__Product__r.Scale_Utility_Upgrade_Editions__c.containsIgnoreCase(strUGtoEdition)){
                            hasUpgradedSR = true;
                            if(eachSRLine.SBQQ__Optional__c && eachRSVXWrapLine.hasRamp) {
                                eachSRLine.SBQQ__Optional__c = false;
                                lstQLIsToUpsert.add(eachSRLine);
                                mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                            } else if(!eachRSVXWrapLine.hasRamp) {
                                if(!eachSRLine.SBQQ__Optional__c) {
                                eachSRLine.SBQQ__Optional__c = true;
                                lstQLIsToUpsert.add(eachSRLine);
                                mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                            }
                            }
                        } else if(!eachSRLine.SBQQ__Optional__c) {
                            eachSRLine.SBQQ__Optional__c = true;
                            //eachSRLine.SBQQ__Discount__c = 100;
                            lstQLIsToUpsert.add(eachSRLine);
                            mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                        }
                    }
                    //else create new Upgrade AR/SR and mark old AR/SR as false
                    if(!hasUpgradedAR) {
                        //System.debug(LoggingLevel.INFO, 'optionNeeded --> '+eachRSVXWrapLine.reqByRSVXLine.SBQQ__Product__c + '_OND AR_' + strUGtoEdition);
                        SBQQ__ProductOption__c optionNeeded = mapIdtToONDOption.get(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Product__c + '_OND AR_' + strUGtoEdition);
                        System.debug(LoggingLevel.INFO, 'AR optionNeeded->'+optionNeeded);
                        if(optionNeeded != null) {
                            //Add new AR Line
                            SBQQ__QuoteLine__c addAR_QLI = new SBQQ__QuoteLine__c();
                            addAR_QLI.SBQQ__Quote__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c;
                            addAR_QLI.SBQQ__Number__c = lineNumberCount + 1;
                            addAR_QLI.Scale_Utility_Product_RSV_OND__c = 'OND';
                            addAR_QLI.Scale_Utility_Product_Identifier__c = 'OND AR';
                            addAR_QLI.SBQQ__Quantity__c = 1;
                            addAR_QLI.SBQQ__Discount__c = 100;
                            addAR_QLI.SBQQ__OptionLevel__c = 1;
                            addAR_QLI.SBQQ__OptionType__c = 'Related Product';
                            addAR_QLI.SBQQ__NetPrice__c = 0;
                            if (eachRSVXWrapLine.qlRSVLine != null || eachRSVXWrapLine.qlUGLine != null) {
                                addAR_QLI.OnDemand_Discount__c = eachRSVXWrapLine.qlUGLine != null ?
                                    ((1 - ((eachRSVXWrapLine.qlRSVLine.SBQQ__NetPrice__c +
                                            (eachRSVXWrapLine.qlUGLine.SBQQ__NetPrice__c / eachRSVXWrapLine.qlUGLine.SBQQ__ProrateMultiplier__c)) /
                                        (eachRSVXWrapLine.qlRSVLine.SBQQ__ListPrice__c + eachRSVXWrapLine.qlUGLine.SBQQ__ListPrice__c))) * 100).setScale(2) : eachRSVXWrapLine.qlRSVLine.SBQQ__Discount__c;
                                addAR_QLI.Product_Code_Type__c = eachRSVXWrapLine.qlRSVLine.Product_Code_Type__c;
                                addAR_QLI.Storage_Region_Bundle_FrontEnd__c = eachRSVXWrapLine.qlRSVLine.Storage_Region_Bundle_FrontEnd__c;
                                addAR_QLI.Storage_Region_Bundle__c = eachRSVXWrapLine.qlRSVLine.Storage_Region_Bundle__c;
                            }
                            //System.debug('AR optionNeeded.SBQQ__OptionalSKU__c->'+optionNeeded.SBQQ__OptionalSKU__c);
                            //System.debug('AR optionNeeded.SBQQ__OptionalSKU__r->'+optionNeeded.SBQQ__OptionalSKU__r);
                            addAR_QLI.SBQQ__Product__c = optionNeeded.SBQQ__OptionalSKU__c;
                            addAR_QLI.Product_Level__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Level__c;
                            addAR_QLI.Member_of_Bundle_Edition_s__c = optionNeeded.SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
                            addAR_QLI.Product_Payment_Option__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Payment_Option__c;
                            addAR_QLI.Payment_Options__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Payment_Option__c;
                            addAR_QLI.SBQQ__ProductOption__c = optionNeeded.Id;
                            addAR_QLI.Product_Type__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Type__c;
                            addAR_QLI.Product_Subtype__c  = optionNeeded.SBQQ__OptionalSKU__r.Product_Subtype__c;
                            addAR_QLI.SBQQ__Description__c = optionNeeded.SBQQ__OptionalSKU__r.Description;
                            addAR_QLI.SBQQ__DynamicOptionId__c = optionNeeded.SBQQ__Feature__c +':' + optionNeeded.SBQQ__OptionalSKU__c;
                            addAR_QLI.SBQQ__RequiredBy__c = eachRSVXWrapLine.reqByRSVXLine.Id;
                            addAR_QLI.SBQQ__StartDate__c =eachRSVXWrapLine.reqByRSVXLine.SBQQ__StartDate__c;
                            addAR_QLI.SBQQ__EndDate__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__EndDate__c;
                            addAR_QLI.SBQQ__SubscriptionTerm__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__SubscriptionTerm__c;
                            addAR_QLI.SBQQ__SubscriptionPricing__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__SubscriptionPricing__c;
                            addAR_QLI.SBQQ__PricebookEntryId__c = productToPbeMap.get(addAR_QLI.SBQQ__Product__c).Id;
                            addAR_QLI.SBQQ__ListPrice__c = productToPbeMap.get(addAR_QLI.SBQQ__Product__c).UnitPrice;
                            lstQLIsToUpsert.add(addAR_QLI);
                            mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                        }
                    }
                    if(!hasUpgradedSR) {
                        SBQQ__ProductOption__c optionNeeded = mapIdtToONDOption.get(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Product__c + '_OND SR_' + strUGtoEdition);
                        System.debug(LoggingLevel.INFO, 'SR optionNeeded->'+optionNeeded);
                        if(optionNeeded != null) {
                            //Add new SR Line
                            SBQQ__QuoteLine__c addSR_QLI = new SBQQ__QuoteLine__c();
                            addSR_QLI.SBQQ__Quote__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c;
                            addSR_QLI.SBQQ__Number__c = lineNumberCount + 1;
                            addSR_QLI.Scale_Utility_Product_RSV_OND__c = 'OND';
                            addSR_QLI.Scale_Utility_Product_Identifier__c = 'OND SR';
                            addSR_QLI.SBQQ__Quantity__c = 1;
                            addSR_QLI.SBQQ__Discount__c = 100;
                            addSR_QLI.SBQQ__OptionLevel__c = 1;
                            addSR_QLI.SBQQ__OptionType__c = 'Related Product';
                            addSR_QLI.SBQQ__NetPrice__c = 0;
                            if (eachRSVXWrapLine.qlRSVLine != null || eachRSVXWrapLine.qlUGLine != null) {
                                addSR_QLI.OnDemand_Discount__c = eachRSVXWrapLine.qlUGLine != null ?
                                    ((1 - ((eachRSVXWrapLine.qlRSVLine.SBQQ__NetPrice__c +
                                            (eachRSVXWrapLine.qlUGLine.SBQQ__NetPrice__c / eachRSVXWrapLine.qlUGLine.SBQQ__ProrateMultiplier__c)) /
                                        (eachRSVXWrapLine.qlRSVLine.SBQQ__ListPrice__c + eachRSVXWrapLine.qlUGLine.SBQQ__ListPrice__c))) * 100).setScale(2) :
                                    eachRSVXWrapLine.qlRSVLine.SBQQ__Discount__c;
                                addSR_QLI.Product_Code_Type__c = eachRSVXWrapLine.qlRSVLine.Product_Code_Type__c;
                                addSR_QLI.Storage_Region_Bundle_FrontEnd__c = eachRSVXWrapLine.qlRSVLine.Storage_Region_Bundle_FrontEnd__c;
                                addSR_QLI.Storage_Region_Bundle__c = eachRSVXWrapLine.qlRSVLine.Storage_Region_Bundle__c;
                            }
                            System.debug(LoggingLevel.INFO, 'SR optionNeeded.SBQQ__OptionalSKU__c->'+optionNeeded.SBQQ__OptionalSKU__c);
                            //System.debug(LoggingLevel.INFO, 'SR optionNeeded.SBQQ__OptionalSKU__r->'+optionNeeded.SBQQ__OptionalSKU__r);
                            addSR_QLI.SBQQ__Product__c = optionNeeded.SBQQ__OptionalSKU__c;
                            addSR_QLI.SBQQ__Description__c = optionNeeded.SBQQ__OptionalSKU__r.Description;
                            addSR_QLI.Product_Level__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Level__c;
                            addSR_QLI.Member_of_Bundle_Edition_s__c = optionNeeded.SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
                            addSR_QLI.Product_Payment_Option__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Payment_Option__c;
                            addSR_QLI.Payment_Options__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Payment_Option__c;
                            addSR_QLI.SBQQ__ProductOption__c = optionNeeded.Id;
                            addSR_QLI.Product_Type__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Type__c;
                            addSR_QLI.Product_Subtype__c  = optionNeeded.SBQQ__OptionalSKU__r.Product_Subtype__c;
                            addSR_QLI.SBQQ__DynamicOptionId__c = optionNeeded.SBQQ__Feature__c +':' + optionNeeded.SBQQ__OptionalSKU__c;
                            addSR_QLI.SBQQ__RequiredBy__c = eachRSVXWrapLine.reqByRSVXLine.Id;
                            addSR_QLI.SBQQ__StartDate__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__StartDate__c;
                            addSR_QLI.SBQQ__EndDate__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__EndDate__c;
                            addSR_QLI.SBQQ__SubscriptionTerm__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__SubscriptionTerm__c;
                            addSR_QLI.SBQQ__SubscriptionPricing__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__SubscriptionPricing__c;
                            addSR_QLI.SBQQ__PricebookEntryId__c = productToPbeMap.get(addSR_QLI.SBQQ__Product__c).Id;
                            addSR_QLI.SBQQ__ListPrice__c = productToPbeMap.get(addSR_QLI.SBQQ__Product__c).UnitPrice;
                            addSR_QLI.SBQQ__Optional__c = eachRSVXWrapLine.hasRamp ? false : true;
                            lstQLIsToUpsert.add(addSR_QLI);
                            mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                        }
                    }
                } 

                if((calledfrom != null && calledfrom == 'beforeDelete') || !eachRSVXWrapLine.hasUGSKU) {
                    Boolean hasAR = false;
                    Boolean hasSR = false;
                    //if Upgrade AR/SR is already added mark correct AR/SR as true/false
                    String strRSVXEdition = eachRSVXWrapLine.reqByRSVXLine.Product_Type__c;
                    for(SBQQ__QuoteLine__c eachARLine : eachRSVXWrapLine.lstARLines) {
                        if(eachARLine.SBQQ__ProductOption__r.SBQQ__Selected__c && eachARLine.Quote_Line_Type__c.equalsIgnoreCase('New')){
                            hasAR = true;
                            if(eachARLine.SBQQ__Optional__c) {
                                eachARLine.SBQQ__Optional__c = false;
                                lstQLIsToUpsert.add(eachARLine);
                                mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                            }
                        } else if(!eachARLine.SBQQ__Optional__c) {
                            eachARLine.SBQQ__Optional__c = true;
                            lstQLIsToUpsert.add(eachARLine);
                            mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                        }
                    }
                    for(SBQQ__QuoteLine__c eachSRLine : eachRSVXWrapLine.lstSRLines) {
                        System.debug(LoggingLevel.INFO, 'eachSRLine.Opt->'+eachSRLine.SBQQ__Optional__c);
                        if(eachSRLine.SBQQ__ProductOption__r.SBQQ__Selected__c && eachSRLine.Quote_Line_Type__c.equalsIgnoreCase('New')){
                            hasSR = true;
                            if(eachSRLine.SBQQ__Optional__c && eachRSVXWrapLine.hasRamp) {
                                    eachSRLine.SBQQ__Optional__c = false;
                                    lstQLIsToUpsert.add(eachSRLine);
                                    mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                            } else if(!eachRSVXWrapLine.hasRamp) {
                                if(!eachSRLine.SBQQ__Optional__c) {
                                    eachSRLine.SBQQ__Optional__c = true;
                                    lstQLIsToUpsert.add(eachSRLine);
                                    mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                                }
                            }
                        } else if(!eachSRLine.SBQQ__Optional__c) {
                            eachSRLine.SBQQ__Optional__c = true;
                            lstQLIsToUpsert.add(eachSRLine);
                            mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                        }
                    }

                    if(!hasAR && !eachRSVXWrapLine.setSegmentEffQty.isEmpty() && eachRSVXWrapLine.setSegmentEffQty.size() > 0 && eachRSVXWrapLine.quoteType.equalsIgnoreCase('Amendment')) {
                        SBQQ__ProductOption__c optionNeeded = mapIdtToONDOption.get(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Product__c + '_OND AR_' + true);
                        if(optionNeeded != null) {
                        //Add new AR Line
                        SBQQ__QuoteLine__c addAR_QLI = new SBQQ__QuoteLine__c();
                        addAR_QLI.SBQQ__Quote__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c;
                        addAR_QLI.SBQQ__Number__c = lineNumberCount + 1;
                        addAR_QLI.Scale_Utility_Product_RSV_OND__c = 'OND';
                        addAR_QLI.Scale_Utility_Product_Identifier__c = 'OND AR';
                        addAR_QLI.SBQQ__Quantity__c = 1;
                        addAR_QLI.SBQQ__Discount__c = 100;
                        addAR_QLI.SBQQ__OptionLevel__c = 1;
                        addAR_QLI.SBQQ__OptionType__c = 'Related Product';
                        addAR_QLI.SBQQ__NetPrice__c = 0;
                        if (eachRSVXWrapLine.qlRSVLine != null || eachRSVXWrapLine.hasUGSKU) {
                            addAR_QLI.OnDemand_Discount__c = eachRSVXWrapLine.hasUGSKU ?
                                ((1 - ((eachRSVXWrapLine.qlRSVLine.SBQQ__NetPrice__c +
                                        (eachRSVXWrapLine.qlUGLine.SBQQ__NetPrice__c / eachRSVXWrapLine.qlUGLine.SBQQ__ProrateMultiplier__c)) /
                                    (eachRSVXWrapLine.qlRSVLine.SBQQ__ListPrice__c + eachRSVXWrapLine.qlUGLine.SBQQ__ListPrice__c))) * 100).setScale(2) : eachRSVXWrapLine.qlRSVLine.SBQQ__Discount__c;
                            addAR_QLI.Product_Code_Type__c = eachRSVXWrapLine.qlRSVLine.Product_Code_Type__c;
                            addAR_QLI.Storage_Region_Bundle_FrontEnd__c = eachRSVXWrapLine.qlRSVLine.Storage_Region_Bundle_FrontEnd__c;
                            addAR_QLI.Storage_Region_Bundle__c = eachRSVXWrapLine.qlRSVLine.Storage_Region_Bundle__c;
                        }
                        addAR_QLI.SBQQ__Product__c = optionNeeded.SBQQ__OptionalSKU__c;
                        addAR_QLI.Product_Level__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Level__c;
                        addAR_QLI.Member_of_Bundle_Edition_s__c = optionNeeded.SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
                        addAR_QLI.Product_Payment_Option__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Payment_Option__c;
                        addAR_QLI.Payment_Options__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Payment_Option__c;
                        addAR_QLI.SBQQ__ProductOption__c = optionNeeded.Id;
                        addAR_QLI.Product_Type__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Type__c;
                        addAR_QLI.Product_Subtype__c  = optionNeeded.SBQQ__OptionalSKU__r.Product_Subtype__c;
                        addAR_QLI.SBQQ__Description__c = optionNeeded.SBQQ__OptionalSKU__r.Description;
                        addAR_QLI.SBQQ__DynamicOptionId__c = optionNeeded.SBQQ__Feature__c +':' + optionNeeded.SBQQ__OptionalSKU__c;
                        addAR_QLI.SBQQ__RequiredBy__c = eachRSVXWrapLine.reqByRSVXLine.Id;
                        addAR_QLI.SBQQ__StartDate__c =eachRSVXWrapLine.reqByRSVXLine.SBQQ__StartDate__c;
                        addAR_QLI.SBQQ__EndDate__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__EndDate__c;
                        addAR_QLI.SBQQ__SubscriptionTerm__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__SubscriptionTerm__c;
                        addAR_QLI.SBQQ__SubscriptionPricing__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__SubscriptionPricing__c;
                        addAR_QLI.SBQQ__PricebookEntryId__c = productToPbeMap.containsKey(addAR_QLI.SBQQ__Product__c) ? productToPbeMap.get(addAR_QLI.SBQQ__Product__c).Id : null;
                        addAR_QLI.SBQQ__ListPrice__c = productToPbeMap.containsKey(addAR_QLI.SBQQ__Product__c) ? productToPbeMap.get(addAR_QLI.SBQQ__Product__c).UnitPrice : 0;
                        lstQLIsToUpsert.add(addAR_QLI);
                        mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                    }
                    }
                    if(!hasSR && !eachRSVXWrapLine.setSegmentEffQty.isEmpty() && eachRSVXWrapLine.setSegmentEffQty.size() > 0 && eachRSVXWrapLine.hasRamp && eachRSVXWrapLine.quoteType.equalsIgnoreCase('Amendment')) {
                        SBQQ__ProductOption__c optionNeeded = mapIdtToONDOption.get(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Product__c + '_OND SR_' + true);
                        if(optionNeeded != null) {
                        //Add new SR Line
                        SBQQ__QuoteLine__c addSR_QLI = new SBQQ__QuoteLine__c();
                        addSR_QLI.SBQQ__Quote__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c;
                        addSR_QLI.SBQQ__Number__c = lineNumberCount + 1;
                        addSR_QLI.Scale_Utility_Product_RSV_OND__c = 'OND';
                        addSR_QLI.Scale_Utility_Product_Identifier__c = 'OND SR';
                        addSR_QLI.SBQQ__Quantity__c = 1;
                        addSR_QLI.SBQQ__Discount__c = 100;
                        addSR_QLI.SBQQ__OptionLevel__c = 1;
                        addSR_QLI.SBQQ__OptionType__c = 'Related Product';
                        addSR_QLI.SBQQ__NetPrice__c = 0;
                        if (eachRSVXWrapLine.qlRSVLine != null || eachRSVXWrapLine.hasUGSKU) {
                            addSR_QLI.OnDemand_Discount__c = eachRSVXWrapLine.hasUGSKU ?
                                ((1 - ((eachRSVXWrapLine.qlRSVLine.SBQQ__NetPrice__c +
                                        (eachRSVXWrapLine.qlUGLine.SBQQ__NetPrice__c / eachRSVXWrapLine.qlUGLine.SBQQ__ProrateMultiplier__c)) /
                                    (eachRSVXWrapLine.qlRSVLine.SBQQ__ListPrice__c + eachRSVXWrapLine.qlUGLine.SBQQ__ListPrice__c))) * 100).setScale(2) :
                                eachRSVXWrapLine.qlRSVLine.SBQQ__Discount__c;
                            addSR_QLI.Product_Code_Type__c = eachRSVXWrapLine.qlRSVLine.Product_Code_Type__c;
                            addSR_QLI.Storage_Region_Bundle_FrontEnd__c = eachRSVXWrapLine.qlRSVLine.Storage_Region_Bundle_FrontEnd__c;
                            addSR_QLI.Storage_Region_Bundle__c = eachRSVXWrapLine.qlRSVLine.Storage_Region_Bundle__c;
                        }
                        addSR_QLI.SBQQ__Product__c = optionNeeded.SBQQ__OptionalSKU__c;
                        addSR_QLI.SBQQ__Description__c = optionNeeded.SBQQ__OptionalSKU__r.Description;
                        addSR_QLI.Product_Level__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Level__c;
                        addSR_QLI.Member_of_Bundle_Edition_s__c = optionNeeded.SBQQ__OptionalSKU__r.Member_of_Bundle_Edition_s__c;
                        addSR_QLI.Product_Payment_Option__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Payment_Option__c;
                        addSR_QLI.Payment_Options__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Payment_Option__c;
                        addSR_QLI.SBQQ__ProductOption__c = optionNeeded.Id;
                        addSR_QLI.Product_Type__c = optionNeeded.SBQQ__OptionalSKU__r.Product_Type__c;
                        addSR_QLI.Product_Subtype__c  = optionNeeded.SBQQ__OptionalSKU__r.Product_Subtype__c;
                        addSR_QLI.SBQQ__DynamicOptionId__c = optionNeeded.SBQQ__Feature__c +':' + optionNeeded.SBQQ__OptionalSKU__c;
                        addSR_QLI.SBQQ__RequiredBy__c = eachRSVXWrapLine.reqByRSVXLine.Id;
                        addSR_QLI.SBQQ__StartDate__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__StartDate__c;
                        addSR_QLI.SBQQ__EndDate__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__EndDate__c;
                        addSR_QLI.SBQQ__SubscriptionTerm__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__SubscriptionTerm__c;
                        addSR_QLI.SBQQ__SubscriptionPricing__c = eachRSVXWrapLine.reqByRSVXLine.SBQQ__SubscriptionPricing__c;
                        addSR_QLI.SBQQ__PricebookEntryId__c = productToPbeMap.containsKey(addSR_QLI.SBQQ__Product__c) ? productToPbeMap.get(addSR_QLI.SBQQ__Product__c).Id : null;
                        addSR_QLI.SBQQ__ListPrice__c = productToPbeMap.containsKey(addSR_QLI.SBQQ__Product__c) ? productToPbeMap.get(addSR_QLI.SBQQ__Product__c).UnitPrice : 0;
                        addSR_QLI.SBQQ__Optional__c = eachRSVXWrapLine.hasRamp ? false : true;
                        lstQLIsToUpsert.add(addSR_QLI);
                        mapQuotesForceRecalc.put(eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__c, eachRSVXWrapLine.reqByRSVXLine.SBQQ__Quote__r.Force_Recalculation__c);
                    }
                }
                }

            }

            if (!lstQLIsToUpsert.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'lstQLIsToUpsert.size--->' + lstQLIsToUpsert.size());
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                SBQQ.TriggerControl.disable();
                if(Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable() && Schema.sObjectType.SBQQ__QuoteLine__c.isCreateable()){
                    upsert lstQLIsToUpsert;
                }
                SBQQ.TriggerControl.enable();
                List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();
                for(Id eachId : mapQuotesForceRecalc.keySet()) {
                    Boolean forceRecalc = !mapQuotesForceRecalc.get(eachId);
                    lstQuotes.add(new SBQQ__Quote__c(Id = eachId, Force_Recalculation__c = forceRecalc));
                }
                System.debug(LoggingLevel.INFO, 'lstQuotes to recalculate'+lstQuotes.size());
                if(!Test.isRunningTest()) {
                    update lstQuotes;
                }
            }
        }
    }
 /**
* @description CPQ22-6097 Enforces field editability rules on a list of records during trigger execution.
 * Compares old vs new values, checks against metadata rules, and throws errors if edits are not allowed.
* @Date 3 December 2025
*/
private static Map<String, QuoteFieldEditability__mdt> rulesCache;
/**
* @description CPQ22-6097 Ensure Schema.DescribeFieldResult limits
* @Date 3 December 2025
*/
    private static Map<String, Schema.SObjectField> fieldDescribeCache;
/**
* @description CPQ22-6097 Ensure method is running once only
* @Date 3 December 2025
*/
    private static Boolean hasRun = false;
   /**
* @description CPQ22-6097 Enforces field editability rules on a list of records during trigger execution.
 * Compares old vs new values, checks against metadata rules, and throws errors if edits are not allowed.
* @Date 3 December 2025
* @param lineList List<SBQQ__QuoteLine__c>
* @param oldLineMap Map<Id, SBQQ__QuoteLine__c
* @param RelatedobjectInfo Map of related SBQQ__QuoteLine__c records.
*/
    public static void enforceFieldEditablility(List<SBQQ__QuoteLine__c> lineList, Map<Id, SBQQ__QuoteLine__c> oldLineMap,Map<Id,SBQQ__QuoteLine__c> RelatedobjectInfo) {
         if (hasRun) {
            return;
        }
        hasRun = true;
        
        set<String> metadataProfiles = new set<String>();
        if(fieldDescribeCache == null){
        fieldDescribeCache = QuoteTriggerHelper.initFieldDescribeCache('SBQQ__QuoteLine__c');
        }
        if(rulesCache == null){
            rulesCache = QuoteTriggerHelper.getFieldEditableMetadata(metadataProfiles);
        }
        
        Boolean hasSpecialPermission = FeatureManagement.checkPermission('Special_DealOperations_Edit');
       
        
        for (SBQQ__QuoteLine__c newLine : lineList) {
            SBQQ__QuoteLine__c oldLine = oldLineMap.get(newLine.Id);
            String newStatus = RelatedobjectInfo.get(newLine.id).SBQQ__Quote__r.SBQQ__Status__c;

            String userProfileName = newLine.User_Profile__c;
            if(hasSpecialPermission){
                userProfileName = 'Deal Operations';
            }else if(!metadataProfiles.contains(userProfileName.trim())){
                userProfileName = 'All Other Profiles';
            }

            List<String> restrictedFields = new List<String>();
            // Get all fields that have values on the record
            //Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.SBQQ__QuoteLine__c.fields.getMap();
               if(!fieldDescribeCache.isEmpty()){      
            for (String fieldName : fieldDescribeCache.keySet()) {
                if (!fieldName.endsWith('__c')) {
                continue;
                }
                Object oldVal = oldLine.get(fieldName);
                Object newVal = newLine.get(fieldName);
                if (oldVal != newVal) {
                    Schema.DescribeFieldResult dfr = fieldDescribeCache.get(fieldName).getDescribe();
                   //FieldDefinition fd = fieldDescribeCache.get(fieldName);
                    // Skip formula fields
                    if (dfr.IsCalculated()) {
                        continue;
                    }
                    // Build key dynamically
                    String key = QuoteTriggerHelper.buildKey('SBQQ__QuoteLine__c', newStatus, userProfileName, fieldName);
                    if (!rulesCache.containsKey(key) && (newStatus == Constants.STATUS_IN_REVIEW || newStatus == Constants.STATUS_APPROVED)) {
                       restrictedFields.add(dfr.getLabel());
                    } else if(rulesCache.containsKey(key)){  // This will not be covered as metadata does not contains any field related to quote line
                        QuoteFieldEditability__mdt applicableRule = rulesCache.get(key);
                        if (!applicableRule.IsEditable__c) {
                          restrictedFields.add(dfr.getLabel());
                        }
                    }
                }
            }
        }
            
            if (!restrictedFields.isEmpty() && !Test.isRunningTest()) {
                SBQQ.TriggerControl.disable();
				try {
                newLine.addError(
                    label.Quote_FieldEdit_NotAllowed_InReviewApproved +' '+ String.join(restrictedFields, ', ')
                );
                }finally {
					SBQQ.TriggerControl.enable();
				}
            }
        }
    }
        /** GTMIT-49
* @description : This method populates FSI_Special_Program__c field on opportunity when the QL contains PayGo.
* @param quoteIdToProdType Map of Quote Ids to Product Types
* @param isDelete Boolean flag to indicate if the operation is delete
*/
    public static void populateFieldsOnOpportunity(Map<Id,String> quoteIdToProdType,Boolean isDelete){
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        Set<Id> payGoQuoteIds = new Set<Id>();
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.FSI_Special_Program__c
            FROM SBQQ__Quote__c
            WHERE SBQQ__Primary__c = true and Id IN :quoteIdToProdType.keySet() 
            AND SBQQ__Opportunity2__r.RecordType.DeveloperName = :CPQ_Constants.SALES_OPP_RECORDTYPE
        ];
        if(quotes!=null && !quotes.isEmpty()){
            if(isDelete){
                for(AggregateResult groupedResults: [Select count(id),SBQQ__Quote__c from SBQQ__QuoteLine__c where SBQQ__Quote__r.SBQQ__Primary__c = true and SBQQ__Quote__c IN :quoteIdToProdType.keySet() and Product_Type__c like :CPQ_Constants.PAYGO_Check  group by SBQQ__Quote__c ]){
                    payGoQuoteIds.add((Id)groupedResults.get('SBQQ__Quote__c'));
                }
            }
            for(SBQQ__Quote__c quote : quotes) {
                if(!isDelete && quote.SBQQ__Opportunity2__r.FSI_Special_Program__c != quoteIdToProdType.get(quote.Id)){
                    Opportunity opp = new Opportunity(Id = quote.SBQQ__Opportunity2__c,FSI_Special_Program__c = quoteIdToProdType.get(quote.Id));
                    oppToUpdate.add(opp);
                }else if(isDelete && !payGoQuoteIds.contains(quote.id)){
                    Opportunity opp = new Opportunity(Id = quote.SBQQ__Opportunity2__c,FSI_Special_Program__c = '');
                    oppToUpdate.add(opp);
                } 
            }
            
            if(!oppToUpdate.isEmpty()){
                flowControll.opportunityLineItemHandler = false;
                flowControll.opportunityTriggerHandler = false;
                update oppToUpdate;
                flowControll.opportunityLineItemHandler = true;
                flowControll.opportunityTriggerHandler = true;
            }
        }
    }
     

    //CPQ22-6097 END

    /**
     * @description Wrapper class to hold the required fields for Auto Add OND SKU
     **/
    public class AutoAddONDSKUWrapper {
        /**
         * @description Required By Id is the Id of the Quote Line Item which is required by the RSVX line
         */
        public Id requiredById {
            get;
            set;
        }
        /**
         * @description Quote Line Item which is required by the RSVX line
         **/
        public SBQQ__QuoteLine__c reqByRSVXLine {
            get;
            set;
        }
        public List<SBQQ__QuoteLine__c> lstARLines;
        public List<SBQQ__QuoteLine__c> lstSRLines;
        public Boolean hasUGSKU;
        public Boolean hasRamp;
        public String quoteType;
        public Set < Double > setSegmentQty;
        public Set < Double > setSegmentEffQty;
        public SBQQ__QuoteLine__c qlUGLine;
        public SBQQ__QuoteLine__c qlRSVLine;
        
        /**
         * @description Constructor to initialize the wrapper class
         * @param reqId - Id of the Quote Line Item which is required by the RSVX line
         */
        public AutoAddONDSKUWrapper(Id reqId) {
            this.requiredById = reqId;
            this.reqByRSVXLine = new SBQQ__QuoteLine__c();
            this.lstARLines = new List<SBQQ__QuoteLine__c>();
            this.lstSRLines = new List<SBQQ__QuoteLine__c>();
            this.hasUGSKU = false;
            this.hasRamp = false;
            this.setSegmentQty = new Set < Double > ();
            this.setSegmentEffQty = new Set < Double > ();
            this.qlUGLine = new SBQQ__QuoteLine__c();
            this.qlRSVLine = new SBQQ__QuoteLine__c();
            this.quoteType = '';
        }
    }
}