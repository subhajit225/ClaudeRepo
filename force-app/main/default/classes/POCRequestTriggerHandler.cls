/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-28-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class POCRequestTriggerHandler implements ITrigger {
/*
    Set<ID> oppIdSet = new Set<ID>();//SF-4931
    //private static Set<ID> oppIdSetForTryNBuyFlag = new Set<ID>();
    List<POC__c> pocList = new List<POC__c>();
    List<Order> orderList = new List<Order>();
    List<Contact> conList= new List<Contact>();
    Map<String,String> mapOfConAccId = new Map<String, String>();
    Set<String> contactSet = new Set<String>(); 
*/
    /**
     * @description This method is called prior to execution of a BEFORE trigger.
     * Use this to cache any data required into maps prior execution of the trigger.
     */
    public void bulkBefore(){
        String str = '';
    }

    /**
     * @description This method is called prior to execution of an AFTER trigger.
     * It orchestrates the creation of Orders and Order Items,
     * and synchronizes POC Lines based on changes to POC Requests.
     */
    public void bulkAfter(){
         String str = '';
        /*
        if(!Trigger.isDelete && (Trigger.isAfter || Trigger.isUpdate)) {
            createOrderAndOrderItems();
            syncPOCLines();
        }

        if(Trigger.isUpdate) {
            reassignRetunredAssets();
        }
*/
    }

    /**
     * @description This method is called iteratively for each record to be inserted during a BEFORE trigger.
     * Never execute any SOQL/SOSL etc in this and other iterative methods.
     * @param so The SObject record being inserted.
     */
    public void beforeInsert(SObject so) {
         String str = '';
    }

    /**
     * @description This method is called iteratively for each record to be updated during a BEFORE trigger.
     * It updates various date and user fields on the POC record based on changes to POC Stage, Status Details,
     * Approval Status, and POC Returned flag. It also handles POC extension logic for 'Web Try and Buy' POCs.
     * @param oldSo The old version of the SObject record before the update.
     * @param so The new version of the SObject record after the update.
     */
    public void beforeUpdate(SObject oldSo, SObject so){
         String str = '';
        /*POC__c poc = (POC__c)so;
        POC__c oldPoc = (POC__c)oldSo;

        if(oldPoc != null){
            if(oldPoc.POC_Stage__c != poc.POC_Stage__c || oldPoc.POC_Status_Details__c != poc.POC_Status_Details__c) {
                poc.Last_Update_POC_Status__c = System.today();
            }
            if(oldPoc.POC_Returned__c != poc.POC_Returned__c) {
                poc.POC_Return_Date__c = Datetime.now();
            }
            if(oldPoc.Approval_Status__c != poc.Approval_Status__c && poc.Approval_Status__c == 'Pending') {
                poc.POC_Submitter__c = UserInfo.getUserId();
            }
            if( (poc.POC_Stage__c == 'Extended POC' && poc.POC_Stage__c != oldPoc.POC_Stage__c) && poc.POC_Type__c == 'Web Try and Buy' && poc.Approval_Status__c == 'Approved'){
                Integer pocDuration = 30;
                if(String.isNotBlank(poc.POC_Duration__c)){
                    if(poc.POC_Duration__c.contains(' ')){
                        pocDuration = Integer.valueOf(poc.POC_Duration__c.split(' ')[0]);
                    }else{
                        pocDuration = Integer.valueOf(poc.POC_Duration__c);
                    }
                }
                poc.POC_Extension_Duration__c = poc.POC_Duration__c;
                poc.POC_End_Date__c = poc.POC_End_Date__c.addDays(pocDuration);
            }
        }*/
    }

    /**
     * @description This method is called iteratively for each record to be deleted during a BEFORE trigger.
     * @param so The SObject record being deleted.
     */
    public void beforeDelete(SObject so){
         String str = '';
    }

    /**
     * @description This method is called iteratively for each record inserted during an AFTER trigger.
     * It adds the Opportunity ID of the new POC to a set for further processing.
     * Always put field validation in the 'After' methods in case another trigger has modified any values.
     * The record is 'read only' by this point.
     * @param so The SObject record that was inserted.
     */
    public void afterInsert(SObject so){
         String str = '';
       // oppIdSet.add(((POC__c)so).Opportunity__c);
    }

    /**
     * @description This method is called iteratively for each record updated during an AFTER trigger.
     * @param oldSo The old version of the SObject record before the update.
     * @param so The new version of the SObject record after the update.
     */
    public void afterUpdate(SObject oldSo, SObject so){
         String str = '';
    }

    /**
     * @description This method is called iteratively for each record deleted during an AFTER trigger.
     * @param so The SObject record that was deleted.
     */
    public void afterDelete(SObject so){
         String str = '';
    }

    /**
     * @description This method is called once all records have been processed by the trigger.
     * Use this method to accomplish any final operations such as creation or updates of other records.
     * Specifically, it updates the 'Most_Recent_POC_Request__c' field on related Opportunities.
     */
    public void andFinally(){
         String str = '';
        //SF-4931: Opportunity Lookup to Most Recent POC Request
      /*  oppIdSet.remove(null);
        List<Opportunity> oppList = new List<Opportunity>();
        if(!oppIdSet.isEmpty()){
            for(POC__c pocRequest : (List<POC__c>)Trigger.new){
            //[Select Opportunity__c, createdDate, ID, POC_Type__c  from POC__c where Opportunity__c in : oppIdSet AND ID in : pocIdSet]){
                Opportunity opp = null;
                if(oppIdSet.contains(pocRequest.Opportunity__c)){
                    opp = opp == null ? new Opportunity(ID = pocRequest.Opportunity__c) : opp;
                    opp.Most_Recent_POC_Request__c = pocRequest.id;
                }
                if(opp != null){
                    oppList.add(opp);
                }
            }
        }
        if(!oppList.isEmpty()){
            update oppList;
        }
        
        */
        
    }
/* 
    public static Pricebook2 stdPriceBook {
       get {
            if (stdPriceBook == null){
                if(Test.isRunningTest()) {
                   stdPriceBook = new Pricebook2(Id = Test.getStandardPricebookId());
                }
                else {
                    stdPriceBook = [select id, name from Pricebook2 where isStandard = true limit 1];
                }
            }
            return stdPriceBook;
        }
        set;
        
    }*/
/*
    public static void reassignRetunredAssets() {
        List<POC__c> pocRequests = Trigger.new;
        Map<Id, SObject> pocRequestsOld = Trigger.oldMap;
        Set<Id> orderIds = new Set<Id>();

        for(POC__c poc : pocRequests) {
            POC__c oldPoc = (pocRequestsOld != null) ? (POC__c)pocRequestsOld.get(poc.Id) : null;

            if(oldPoc != null && oldPoc.POC_Returned__c != poc.POC_Returned__c) {
                orderIds.add(poc.Order__c);
            }
        }

        orderIds.remove(null);

        if(!orderIds.isEmpty()) {
            List<Account> unassignedAccount = [SELECT Id FROM Account WHERE Name = 'Unassigned' LIMIT 1];
            List<Asset> toReassign = [SELECT Id FROM Asset WHERE Order_Service_Item__r.OrderId IN :orderIds];
            for(Asset asset : toReassign) {
                asset.Status = 'POC Unassigned';
                asset.Order_Service_Item__c = null;
                //SF-10524
                asset.InstallDate = null;
                asset.POO_Ship_Date__c = null;
                asset.SE_POC_Expected_Return_Date__c = null;
                asset.SE_POC_Notes__c = null;
                asset.SE_POC_Return_Status__c = null;
                //End
                if(!unassignedAccount.isEmpty()) {
                    asset.AccountId = unassignedAccount.get(0).Id;
                }
            }
            if(!toReassign.isEmpty()) {
                update toReassign;
            }
        }
    }

    public static void syncPOCLines() {
        List<POC__c> pocRequests = Trigger.new;
        Map<Id, SObject> pocRequestsOld = Trigger.oldMap;
        Map<Id, List<String>> pocProductCodesById = new Map<Id, List<String>>();
        Map<String, Id> pocProductsById = new Map<String, Id>();
        Set<String> allProductCodes = new Set<String>();

        List<POC__c> toProccess = new List<POC__c>();
        List<POC_Line__c> toDelete = new List<POC_Line__c>();
        List<POC_Line__c> toInsert = new List<POC_Line__c>();
        List<POC_Line__c> toUpdate = new List<POC_Line__c>();

        for(POC__c poc : pocRequests) {
            POC__c pocOld = (pocRequestsOld != null) ? (POC__c)pocRequestsOld.get(poc.Id) : null;

            if(
                (pocOld != null
                    && (pocOld.Product_Codes__c != poc.Product_Codes__c || pocOld.POC_Product_Code__c != poc.POC_Product_Code__c || pocOld.POC_Qty__c != poc.POC_Qty__c))
                || (pocOld == null
                    && (poc.Product_Codes__c != null && poc.POC_Product_Code__c != null))) {

                toProccess.add(poc);

                List<String> codes = (poc.Product_Codes__c != null) ? poc.Product_Codes__c.split(';') : new List<String>();
                List<String> codeProducts = new List<String>();

                for(String code : codes) {
                    List<String> codeParts = code.split('#');
                    String productCode = codeParts.get(0);
                    if(poc.POC_Product_Code__c != code) {
                        codeProducts.add(productCode);
                        allProductCodes.add(productCode);
                    }
                }

                if(poc.POC_Product_Code__c != null) {

                    List<String> pocCodeParts = poc.POC_Product_Code__c.split('#');
                    String pocProductCode = (!pocCodeParts.isEmpty()) ? pocCodeParts.get(0) : poc.POC_Product_Code__c;

                    //codeProducts.add(poc.POC_Product_Code__c);
                    //allProductCodes.add(poc.POC_Product_Code__c);
                    codeProducts.add(pocProductCode);
                    allProductCodes.add(pocProductCode);
                }

                pocProductCodesById.put(poc.Id, codeProducts);
            }
        }

        for(Product2 pr : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :allProductCodes]) {
            pocProductsById.put(pr.ProductCode, pr.Id);
        }

        if(!toProccess.isEmpty()) {
            for(POC__c poc : [SELECT Id, Product_Codes__c, POC_Product_Code__c, POC_Qty__c, (SELECT Id, Product_Code__c, Product__c, Quantity__c FROM POC_Lines__r) FROM POC__c WHERE Id IN :toProccess]) {

                List<String> codeProducts = (pocProductCodesById.containsKey(poc.Id)) ? pocProductCodesById.get(poc.Id) : new List<String>();
                List<POC_Line__c> pocLines = poc.POC_Lines__r;

                if(codeProducts.isEmpty()) {
                    if(!pocLines.isEmpty()) {
                        toDelete.addAll(pocLines);
                    }
                }
                else {
                    Set<String> codeProductsSet = new Set<String>(codeProducts);

                    if(!pocLines.isEmpty()) {

                        Set<String> codes = (poc.Product_Codes__c != null) ? new Set<String>(poc.Product_Codes__c.split(';')) : new Set<String>();
                        Set<Id> processedIds = new Set<Id>();
                        Set<String> notExist = new Set<String>();
                        Set<String> processedProductCodes = new Set<String>();

                        for(String code : codes) {
                            List<String> codeParts = code.split('#');
                            String productCode = codeParts.get(0);
                            Integer productQty = (codeParts.size() >= 2 && String.isNotBlank(codeParts.get(1))) ? Integer.valueOf(codeParts.get(1)) : 1;

                            List<String> pocCodeParts = poc.POC_Product_Code__c.split('#');
                            String pocProductCode = (!pocCodeParts.isEmpty()) ? pocCodeParts.get(0) : poc.POC_Product_Code__c;

                            //if(poc.POC_Product_Code__c == productCode && poc.POC_Qty__c != null) {
                            if(pocProductCode == productCode && poc.POC_Qty__c != null) {
                                productQty = (Integer)poc.POC_Qty__c;
                            }
                            Boolean isExist = false;

                            for(POC_Line__c pl : pocLines) {
                                if(productCode == pl.Product_Code__c) {
                                    if(processedIds.contains(pl.Id)) continue;

                                    isExist = true;
                                    processedIds.add(pl.Id);
                                    processedProductCodes.add(productCode);
                                    Id productId = pocProductsById.get(productCode);

                                    toUpdate.add(
                                        new POC_Line__c(Id = pl.Id, Quantity__c = productQty, Product__c = productId)
                                    );
                                }
                            }

                            if(!isExist) {
                                if(processedProductCodes.contains(productCode)) continue;
                                Id productId = pocProductsById.get(productCode);
                                toInsert.add(
                                    new POC_Line__c(Quantity__c = productQty, Product__c = productId, POC_Request__c = poc.Id)
                                );
                                processedProductCodes.add(productCode);
                            }
                        }

                        for(POC_Line__c pl : pocLines) {
                            if(!codeProductsSet.contains(pl.Product_Code__c)) {
                                toDelete.add(
                                    new POC_Line__c(Id = pl.Id)
                                );
                            }
                        }


                    }
                    else {
                        Set<String> processedProductCodes = new Set<String>();
                        Set<String> codes = (poc.Product_Codes__c != null) ? new Set<String>(poc.Product_Codes__c.split(';')) : new Set<String>();

                        for(String code : codes) {
                            List<String> codeParts = code.split('#');
                            String productCode = codeParts.get(0);
                            if(processedProductCodes.contains(productCode)) continue;
                            Integer productQty = (codeParts.size() >= 2 && String.isNotBlank(codeParts.get(1))) ? Integer.valueOf(codeParts.get(1)) : 1;

                            List<String> pocCodeParts = poc.POC_Product_Code__c.split('#');
                            String pocProductCode = (!pocCodeParts.isEmpty()) ? pocCodeParts.get(0) : poc.POC_Product_Code__c;

                            //if(poc.POC_Product_Code__c == productCode && poc.POC_Qty__c != null) {
                            if(pocProductCode == productCode && poc.POC_Qty__c != null) {
                                productQty = (Integer)poc.POC_Qty__c;
                            }
                            Id productId = pocProductsById.get(productCode);

                            toInsert.add(
                                new POC_Line__c(Quantity__c = productQty, Product__c = productId, POC_Request__c = poc.Id)
                            );
                            processedProductCodes.add(productCode);
                        }
                    }
                }

            }
        }

        if(!toDelete.isEmpty()) {
            delete toDelete;
        }
        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }
        if(!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
/*
    private static String getCountryISOCode(String countryName) {
        String result = countryName;

        Map<String,String> maplabelVal=new Map<String,String>();
        // Get the object type of the SObject.
        Schema.sObjectType objType = Contact.getSObjectType();
        // Describe the SObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        // Get a map of fields for the SObject
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        // Get the list of picklist values for this field.
        list<Schema.PicklistEntry> values = fieldMap.get('MailingCountryCode').getDescribe().getPickListValues();
        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a : values){
           maplabelVal.put(a.getLabel(), a.getValue());
        }

        if(maplabelVal.get(countryName) != null) {
            result = maplabelVal.get(countryName);
            system.debug('ISO CODE: '+maplabelVal.get(result));
        }

        return result;
    }

    public static void createOrderAndOrderItems() {
        /*List<POC__c> pocRequests = Trigger.new;
        Map<Id, SObject> pocRequestsOld = Trigger.oldMap;
        List<Order> ordersToInsert = new List<Order>();

        Id orderRecordId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();

        Map<Id, POC__c> mapFull = new Map<Id, POC__c>([
            SELECT Id, Opportunity__c, Opportunity__r.AccountId, POC_Qty__c, POC_Product_Code__c,Product_Codes__c,
                Shipping_Contact__c,Shipping_Contact_Phone__c,Shipping_Contact_Email__c, Planned_Installation_Date__c,
                Ship_To_Country__c,Shipping_Street__c,Shipping_Zip_Postal_Code__c,Shipping_City__c,
                Shipping_State__c,Shipping_Country__c,POC_Product_and_Duration_Information__c,Other_Accessories__c, Number_of_Users__c, //12299
                POC_Duration__c, POC_Shipping_Information_Comments__c, Polaris_Region__c, Polaris_Contact__c, Polaris_Contact__r.Email
            FROM POC__c
            WHERE Id IN :pocRequests AND POC_Type__c != 'Virtual Lab'
        ]);

        List<String> productCodes = new List<String>();
        Map<Id, List<String>> mapProductCodesByPOCId = new Map<Id, List<String>>();
        Map<Id, Id> mapPricebookIdByOppId = new Map<Id, Id>();
        Set<Id> pricebook2Ids = new Set<Id>();

        Set<Id> oppIds = new Set<Id>();
        for(POC__c poc : pocRequests) {
            if(poc.POC_Type__c == 'Virtual Lab'){
                continue;
            }
            POC__c pocOld = (pocRequestsOld != null) ? (POC__c)pocRequestsOld.get(poc.Id) : null;
            POC__c fullPOC = mapFull.get(poc.Id);

            if(pocOld != null && poc.Approval_Status__c == 'Approved' && fullPOC.Opportunity__c != null){
                if(pocOld.Approval_Status__c != poc.Approval_Status__c
                  || (poc.POC_Stage__c == 'Extended POC' && poc.POC_Stage__c != pocOld.POC_Stage__c && poc.POC_Type__c == 'Web Try and Buy')
                  ){
                  oppIds.add(fullPOC.Opportunity__c);
                  }

            }
        }

        if(!oppIds.isEmpty()) {

            List<Opportunity> oppList = [
                SELECT Id, Pricebook2Id,
                    (SELECT PriceBookEntry.Pricebook2Id FROM OpportunityLineItems LIMIT 1)
                FROM Opportunity
                WHERE Id IN :oppIds
            ];

            for(Opportunity opp : oppList) {
                if(!opp.OpportunityLineItems.isEmpty()) {
                    mapPricebookIdByOppId.put(opp.Id, opp.OpportunityLineItems.get(0).PriceBookEntry.Pricebook2Id);
                }
                if(opp.Pricebook2Id != null) {
                    mapPricebookIdByOppId.put(opp.Id, opp.Pricebook2Id);
                }
            }
            
            Map<ID, Date> pocStartDateMap = new Map<ID, Date>();
            Map<ID, Date> pocEndDateMap = new Map<ID, Date>();
            for(POC__c poc : pocRequests) {
                if(poc.POC_Type__c == 'Virtual Lab'){
                    continue;
                }
                POC__c pocOld = (pocRequestsOld != null) ? (POC__c)pocRequestsOld.get(poc.Id) : null;
                boolean isWebTryAndBuyTypePocExtended = (poc.POC_Stage__c == 'Extended POC' && poc.POC_Stage__c != pocOld.POC_Stage__c && poc.POC_Type__c == 'Web Try and Buy');
                if((poc.Order__c != null && !isWebTryAndBuyTypePocExtended) || poc.Opportunity__c == null) continue;
                POC__c fullPOC = mapFull.get(poc.Id);
                Id pricebook2Id = (mapPricebookIdByOppId.containsKey(fullPOC.Opportunity__c)) ? mapPricebookIdByOppId.get(fullPOC.Opportunity__c) : stdPriceBook.Id;
                
                pricebook2Ids.add(pricebook2Id);
                if(pocOld != null && poc.Approval_Status__c == 'Approved' && (pocOld.Approval_Status__c != poc.Approval_Status__c   || isWebTryAndBuyTypePocExtended ) ){
                    Order ord = new Order();
                    ord.RecordTypeId = orderRecordId;
                    ord.AccountId = fullPOC.Opportunity__r.AccountId;
                    //ord.OpportunityId = fullPOC.Opportunity__c;
                    ord.POC_Opportunity__c = fullPOC.Opportunity__c;

                    ord.EffectiveDate = System.today();
                    //ord.Carnet_No__c = poc.Carnet_No__c;
                    //ord.Carnet_Expiration_Date__c = poc.Carnet_Expiration_Date__c;
                    //ord.Planned_Installation_Date__c = poc.Planned_Installation_Date__c;
                    //ord.POC_Duration__c = poc.POC_Duration__c;
                    //ord.POC_Relocation__c = poc.POC_Relocation__c;
                    ord.Status = 'Draft';
                    ord.POC_Request__c = poc.Id;
                    ord.Pricebook2Id = pricebook2Id;
                    ord.Type = 'POC';
                    ord.Order_Sub_Type__c = 'POC';
                    if(poc.POC_Type__c == 'Web Try and Buy'){
                        ord.Order_Sub_Type__c = 'Try N Buy';
                        Integer pocDuration = 30;
                        if(String.isNotBlank(poc.POC_Duration__c)){
                            if(poc.POC_Duration__c.contains(' ')){
                                pocDuration = Integer.valueOf(poc.POC_Duration__c.split(' ')[0]);
                            }else{
                                pocDuration = Integer.valueOf(poc.POC_Duration__c);
                            }
                        }
                        Date d = poc.Planned_Installation_Date__c == null ? System.today() : poc.Planned_Installation_Date__c;
                        pocStartDateMap.put(poc.Id, d);
                        pocEndDateMap.put(poc.Id, d.addDays(pocDuration));
                        if(isWebTryAndBuyTypePocExtended){                            
                            pocEndDateMap.put(poc.Id, d.addDays(pocDuration).addDays(pocDuration));
                        }
                        /*else{
                            oppIdSetForTryNBuyFlag.add(fullPOC.Opportunity__c);
                        }
                    }

                    ord.ShipToContactName__c = fullPOC.Shipping_Contact__c;
                    ord.Ship_To_Phone_Number__c = fullPOC.Shipping_Contact_Phone__c;
                    ord.Ship_to_Email__c = fullPOC.Shipping_Contact_Email__c;

                    ord.ShippingCity = fullPOC.Shipping_City__c;

                    ord.ShippingCountryCode = getCountryISOCode(fullPOC.Shipping_Country__c);
                    //ord.ShippingCountry = fullPOC.Shipping_Country__c;// fullPOC.Ship_To_Country__c;

                    ord.ShippingStreet = fullPOC.Shipping_Street__c;
                    ord.ShippingPostalCode = fullPOC.Shipping_Zip_Postal_Code__c;

                    if(String.isNotBlank(fullPOC.Shipping_State__c)
                        && fullPOC.Shipping_State__c.length() == 2) {
                        ord.ShippingStateCode = fullPOC.Shipping_State__c;
                    }
                    else {
                        ord.ShippingState = fullPOC.Shipping_State__c;
                    }


                    ord.Additional_Shipping_Comments__c = fullPOC.POC_Shipping_Information_Comments__c;
                    //Other Product Comments
                    ord.Other_Product_Comments__c = fullPOC.Other_Accessories__c;
                    ord.Polaris_Region__c = fullPOC.Polaris_Region__c;
                    ord.Polaris_Contact__c = fullPOC.Polaris_Contact__c;

                    if(fullPOC.Polaris_Contact__c != null){
                        ord.Polaris_Contact_Email__c = fullPOC.Polaris_Contact__r.Email;
                    }

                    List<String> codes = (poc.Product_Codes__c != null) ? poc.Product_Codes__c.split(';') : new List<String>();
                    List<String> codeProducts = new List<String>();
                    //if(!codes.isEmpty()) {
                    //    mapProductCodesByPOCId.put(poc.Id, codes);
                    //    productCodes.addAll(codes);
                    //}
                    for(String code : codes) {
                        List<String> codeParts = code.split('#');
                        String productCode = codeParts.get(0);
                        codeProducts.add(productCode);
                    }

                    if(!codeProducts.isEmpty()) {
                        mapProductCodesByPOCId.put(poc.Id, codeProducts);
                        productCodes.addAll(codeProducts);
                    }

                    ordersToInsert.add(ord);
                }
            }

            if(!ordersToInsert.isEmpty()) {
                //Database.SaveResult sr[] = Database.insert(ordersToInsert, false);
                insert ordersToInsert;

                List<ORder> toUpdateORder = new List<ORder>();
                for(Order o : [SELECT Id, OrderNumber, Name, Pricebook2Id FROM ORder WHERE ID IN :ordersToInsert]) {
                    Order no = new ORder(Id = o.Id);//, Name = 'Demo-' + o.OrderNumber);
                    if(Test.isRunningTest()) {
                        no.Pricebook2Id = Test.getStandardPricebookId();
                        toUpdateORder.add(no);
                    }
                    else {
                        if (o.Pricebook2Id == null) {
                            no.Pricebook2Id = stdPriceBook.ID;//'01s1W000000JfaG';// full uat pricebook V73_2_2017_12_12_07_37_19
                            toUpdateORder.add(no);
                        }
                    }
                }
                if(!toUpdateORder.isEmpty()) {
                    update toUpdateORder;
                }


                List<POC__c> pocRequestsToUpdate = new List<POC__c>();

                Map<Id, Decimal> prodQuantityMap= new Map<Id, Decimal>();
                Map<Id, Product2> mapProducts = new Map<Id, Product2>();
                Map<Id, List<Id>> mapPBE = new Map<Id, List<Id>>();
                Map<Id, PriceBookEntry> mapPBEs = new Map<Id, PriceBookEntry>();
                List<OrderItem> newOrderItemsList = new List<OrderItem>();
                Map<String, Id> mapPBEIdByProductCode = new Map<String, Id>();

                Map<Id, PricebookEntry> mapPricebookEntry = new Map<Id, PricebookEntry>([
                    SELECT
                       Id,
                       Unitprice,
                       Product2.Id,
                       Product2.Name,
                       Product2.ProductCode,
                       Product2.Asset_Priority__c,
                       Product2.License_Type__c
                    FROM PricebookEntry
                    WHERE Product2.ProductCode IN :productCodes AND Pricebook2Id IN :pricebook2Ids
                ]);

                for(Id pbeId : mapPricebookEntry.keySet()) {
                    mapPBEIdByProductCode.put(mapPricebookEntry.get(pbeId).Product2.ProductCode, pbeId);
                    mapPBEs.put(pbeId, mapPricebookEntry.get(pbeId));
                }

                ordersToInsert = [SELECT Id, Actual_Order_Ship_Date__c, POC_Request__c, Pricebook2Id FROM Order WHERE Id IN :ordersToInsert];
                System.debug('---ordersToInsert--'+json.serialize(ordersToInsert));


                Map<Id, Set<Id>> appliancePBEIds = new Map<Id, Set<Id>>();
                Map<Id, Set<Id>> supportPBEIds = new Map<Id, Set<Id>>();
                Map<Id, Set<Id>> subscrPBEIds = new Map<Id, Set<Id>>();

                for(Order ord : ordersToInsert) {

                    Set<String> pocProductCodes = new Set<String>(mapProductCodesByPOCId.get(ord.POC_Request__c));
                    POC__c fullPOC = mapFull.get(ord.POC_Request__c);

                    Set<String> applianceProductCodeSet = new Set<String>();
                    List<String> applianceProductCodes = fullPOC.POC_Product_Code__c.split(';');
                    for(String pr : applianceProductCodes) {
                        List<String> prCodeParts = pr.split('#');
                        String locPRCodeAppliance = prCodeParts.isEmpty() ? pr : prCodeParts.get(0);
                        if('RBK-POLARIS-GPS' != locPRCodeAppliance && 'RBK-EDGE-OBJ' != locPRCodeAppliance) {
                            applianceProductCodeSet.add(locPRCodeAppliance);
                        }
                    }


                    Integer podDuration = 0;
                    if('7 Days' == fullPOC.POC_Duration__c) {
                        podDuration = 7;
                    }
                    if('15 Days' == fullPOC.POC_Duration__c || '15' == fullPOC.POC_Duration__c) {
                        podDuration = 15;
                    }
                    if('30 Days' == fullPOC.POC_Duration__c) {
                        podDuration = 30;
                    }
                    if('60 Days' == fullPOC.POC_Duration__c) {
                        podDuration = 60;
                    }
                    if('90 Days' == fullPOC.POC_Duration__c) {
                        podDuration = 90;
                    }
                    if('120 Days' == fullPOC.POC_Duration__c) {
                        podDuration = 120;
                    }

                    Date actualStartDate = ord.Actual_Order_Ship_Date__c;
                    Date actualEndDate = (actualStartDate != null) ? (actualStartDate.addDays(7).addDays(podDuration)) : null;

                    pocRequestsToUpdate.add(
                        new POC__c(Id = ord.POC_Request__c, Order__c = ord.Id)
                    );

                    for(String productCode : pocProductCodes) {
                        System.debug('---productCode----'+productCode);
                        Id pbeId = mapPBEIdByProductCode.get(productCode);
                        PricebookEntry pbe = mapPBEs.get(pbeId);
                        System.debug('---pbeId----'+pbeId);
                        System.debug('---pbe----'+pbe);
                        //Integer qty = (productCode == fullPOC.POC_Product_Code__c) ? Integer.valueOf(fullPOC.POC_Qty__c) : 1;
                        Integer qty = (applianceProductCodeSet.contains(productCode)) ? Integer.valueOf(fullPOC.POC_Qty__c) : 1;
                        String pocOption = '';

                        if(null != fullPOC.Product_Codes__c) {
                            System.debug('---fullPOC.Product_Codes__c----'+fullPOC.Product_Codes__c);
                            List<String> productCodeParts = fullPOC.Product_Codes__c.split(';');
                            System.debug('---productCodeParts----'+productCodeParts);
                            for(String pc : productCodeParts) {
                                System.debug('---pc----'+pc);
                                List<String> codeParts = pc.split('#');
                                System.debug('---codeParts----'+codeParts);

                                if(!codeParts.isEmpty() && codeParts.size() >= 2
                                    && productCode == codeParts.get(0)) {

                                    qty = Integer.valueOf(codeParts.get(1));
                                }
                                if(!codeParts.isEmpty() && codeParts.size() >= 3
                                    && productCode == codeParts.get(0)){
                                    pocOption = codeParts.get(2);
                                }
                            }
                        }

                        if(pbeId != null && pbe != null) {
                            OrderItem oli = new OrderItem();
                            oli.OrderId = ord.Id;
                            oli.PriceBookEntryId = pbeId;
                            oli.UnitPrice = 0;//pbe.UnitPrice;
                            oli.Description = pbe.Product2.Name;
                            oli.Quantity = qty;//pbe.Quantity;
                            oli.Support_Start_Date__c = actualStartDate;
                            oli.Support_End_Date__c = actualEndDate;
                            oli.POC_Option__c = pocOption;
                            //12299
                            oli.User_license_count__c = fullPOC.Number_of_Users__c;
                            if(ord.POC_Request__c != null && pocEndDateMap.containsKey(ord.POC_Request__c)){
                                oli.Support_Start_Date__c = pocStartDateMap.get(ord.POC_Request__c);
                                oli.Support_End_Date__c = pocEndDateMap.get(ord.POC_Request__c);
                            }
                            if(applianceProductCodeSet.contains(productCode)) {
                                Set<Id> apbeIds = (appliancePBEIds.get(ord.Id) != null) ? appliancePBEIds.get(ord.Id) : new Set<Id>();
                                apbeIds.add(pbeId);
                                appliancePBEIds.put(ord.Id, apbeIds);
                            }
                            /*if(POCRequestFormController.APPLIANCE_PREM_SUPPORT_PRODUCT_CODE == productCode) {

                                Set<Id> spbeIds = (supportPBEIds.get(ord.Id) != null) ? supportPBEIds.get(ord.Id) : new Set<Id>();
                                spbeIds.add(pbeId);
                                supportPBEIds.put(ord.Id, spbeIds);
                            } //Comment as getting error while running test class. Will revert (do not revert back)
                            if(pbe.Product2.Asset_Priority__c == 2 || pbe.Product2.License_Type__c == 'Subscription') {

                                Set<Id> spbeIds = (subscrPBEIds.get(ord.Id) != null) ? subscrPBEIds.get(ord.Id) : new Set<Id>();
                                spbeIds.add(pbeId);
                                subscrPBEIds.put(ord.Id, spbeIds);
                            }

                            newOrderItemsList.add(oli);
                        }

                    }

                }

                if(!newOrderItemsList.isEmpty()) {
                    System.debug('---newOrderItemsList--'+json.serialize(newOrderItemsList));
                    insert newOrderItemsList;

                    Map<Id, Set<Id>> applianceOrderItemIds = new Map<Id, Set<Id>>();
                    List<OrderItem> supportOrderItems = new List<OrderItem>();
                    List<OrderItem> supportOrderItemsToUpdate = new List<OrderItem>();
                    List<OrderItem> subscrOrderItems = new List<OrderItem>();

                    for(OrderItem oi : newOrderItemsList) {

                        Set<Id> currentAppliancePBEIds = (appliancePBEIds.get(oi.OrderId) != null) ? appliancePBEIds.get(oi.OrderId) : new Set<Id>();
                        Set<Id> currentSupportPBEIds = (supportPBEIds.get(oi.OrderId) != null) ? supportPBEIds.get(oi.OrderId) : new Set<Id>();
                        Set<Id> currentSubscrPBEIds = (subscrPBEIds.get(oi.OrderId) != null) ? subscrPBEIds.get(oi.OrderId) : new Set<Id>();

                        if(currentAppliancePBEIds.contains(oi.PriceBookEntryId)) {
                            Set<Id> aOiIds = applianceOrderItemIds.get(oi.OrderId) != null ? applianceOrderItemIds.get(oi.OrderId) : new Set<Id>();
                            aOiIds.add(oi.Id);
                            applianceOrderItemIds.put(oi.OrderId, aOiIds);
                        }

                        if(currentSupportPBEIds.contains(oi.PriceBookEntryId)) {
                            supportOrderItems.add(oi);
                        }
                        if(currentSubscrPBEIds.contains(oi.PriceBookEntryId)) {
                            subscrOrderItems.add(oi);
                        }
                    }

                    for(OrderItem oi : subscrOrderItems) {

                        Set<Id> currentApplianceOrderItemIds = applianceOrderItemIds.get(oi.OrderId);

                        List<Id> applianceOrderProducts = new List<Id>(currentApplianceOrderItemIds);
                        Id applianceOrderProduct = (!applianceOrderProducts.isEmpty()) ? applianceOrderProducts.get(0) : null;

                        if(applianceOrderProduct != null) {
                            OrderItem toUpd = new OrderItem(Id = oi.Id);
                            toUpd.SBQQ__RequiredBy__c = applianceOrderProduct;

                            supportOrderItemsToUpdate.add(toUpd);

                            //currentApplianceOrderItemIds.remove(applianceOrderProduct);
                            //applianceOrderItemIds.put(oi.OrderId, currentApplianceOrderItemIds);
                        }
                    }

                    for(OrderItem oi : supportOrderItems) {

                        Set<Id> currentApplianceOrderItemIds = applianceOrderItemIds.get(oi.OrderId);

                        List<Id> applianceOrderProducts = new List<Id>(currentApplianceOrderItemIds);
                        Id applianceOrderProduct = (!applianceOrderProducts.isEmpty()) ? applianceOrderProducts.get(0) : null;

                        if(applianceOrderProduct != null) {
                            OrderItem toUpd = new OrderItem(Id = oi.Id);
                            toUpd.SBQQ__RequiredBy__c = applianceOrderProduct;

                            supportOrderItemsToUpdate.add(toUpd);

                            currentApplianceOrderItemIds.remove(applianceOrderProduct);
                            applianceOrderItemIds.put(oi.OrderId, currentApplianceOrderItemIds);
                        }
                    }



                    if(!supportOrderItemsToUpdate.isEmpty()) {
                        Database.update(supportOrderItemsToUpdate, false);
                    }
                }

                if(!pocRequestsToUpdate.isEmpty()) {
                    flowControll.POCRequestTriggerHandler = false;
                    update pocRequestsToUpdate;
                    flowControll.POCRequestTriggerHandler = true;
                }
                if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Order_Old_Trigger__c){ 
                autoFulfillPOCOrders(ordersToInsert);
                }  
            }
        }
        
    }
/*
    private static void autoFulfillPOCOrders(List <order> orders){
        List<Order_Event__e> orderEvents = new List<Order_Event__e>();
        for(Order ord: orders){
            //if(ord.Type == 'POC' && ord.Order_Status__c != 'Shipped' && !ord.Has_Hardware_Products__c && (!ord.Have_Polaris_Products__c || ord.Polaris_Fulfillment_Status__c == 'Completed')){
                orderEvents.add(new Order_Event__e(Order_Id__c = ord.Id, Action_Type__c = 'POC_ORDER_AUTOFULFILL'));
            //}
        }

        if(orderEvents.size()>0){
            EventBus.publish(orderEvents);
        }
    }*/
}