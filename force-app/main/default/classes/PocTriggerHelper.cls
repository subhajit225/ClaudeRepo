public with sharing class PocTriggerHelper {
    
    private static Map<String, String> countryNameISOCodeMap;

    public static void createOrderDetails(Set<Id> oppIds, Set<Id> qualifiedPocIdSet, Map<ID, POC__c> oldPocMap, Map<ID, POC__c> newPocMap, Map<Id, Set<String>> mapProductCodesByPOCId, Set<String> productCodes) {
        countryNameISOCodeMap = getCountryNameISOCodeMap();
        //Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>([SELECT Id, AccountId, Pricebook2Id FROM Opportunity WHERE Id IN :oppIds]);
        Map<ID, POC__c> selectedPocMap = new Map<ID, POC__c>([SELECT Id, Opportunity__r.AccountId, Opportunity__r.Pricebook2Id, Polaris_Contact__r.Email FROM POC__c WHERE Id IN :qualifiedPocIdSet]);
        
        List<Order> orderList = new List<Order>();
        Set<Id> pricebook2Ids = new Set<Id>();
        for(ID pocId: qualifiedPocIdSet){
            POC__c oldPoc = oldPocMap.get(pocId);
            POC__c newPoc = newPocMap.get(pocId);
            //Opportunity oppObj = oppMap.get(newPoc.Opportunity__c);
            POC__c selectedPoc = selectedPocMap.get(newPoc.id);
            boolean isWebTryAndBuyTypePocExtended = (newPoc.POC_Stage__c == 'Extended POC' && newPoc.POC_Stage__c != oldPoc.POC_Stage__c && newPoc.POC_Type__c == 'Web Try and Buy');
            if((newPoc.Order__c != null && !isWebTryAndBuyTypePocExtended) || selectedPoc.Opportunity__c == null || selectedPoc.Opportunity__r.Pricebook2Id == null){
                continue;
            }
            pricebook2Ids.add(selectedPoc.Opportunity__r.Pricebook2Id);
            orderList.add(generateOrder(newPoc, selectedPoc, isWebTryAndBuyTypePocExtended));            
        }

        if(!orderList.isEmpty()){
            insert orderList;

            Map<Id, PricebookEntry> mapPricebookEntry = new Map<Id, PricebookEntry>([
                SELECT Id, Unitprice, Product2.Id, Product2.Name, Product2.ProductCode, Product2.Asset_Priority__c, Product2.License_Type__c FROM PricebookEntry
                WHERE Product2.ProductCode IN :productCodes AND Pricebook2Id IN :pricebook2Ids
            ]);
            createOrderLineItems(newPocMap, orderList, mapPricebookEntry, mapProductCodesByPOCId);
        }
    }
    public static void setProductCodes(POC__c newPoc, Map<Id, Set<String>> mapProductCodesByPOCId, Set<String> productCodes) {
        Set<String> codeProducts = new Set<String>();    
        List<String> codes = (newPoc.Product_Codes__c != null) ? newPoc.Product_Codes__c.split(';') : new List<String>();
        for(String code : codes) {
            List<String> codeParts = code.split('#');
            String productCode = codeParts.get(0);
            codeProducts.add(productCode);
        }
        if(newPoc.POC_Product_Code__c != null) {
            List<String> pocCodeParts = newPoc.POC_Product_Code__c.split('#');
            String pocProductCode = (!pocCodeParts.isEmpty()) ? pocCodeParts.get(0) : newPoc.POC_Product_Code__c;
            codeProducts.add(pocProductCode);
        }
        mapProductCodesByPOCId.put(newPoc.Id, codeProducts);
        if(!codeProducts.isEmpty()) {            
            productCodes.addAll(codeProducts);
        }
    }

    public static void createOrderLineItems(Map<ID, POC__c> newPocMap, List<Order> orderList, Map<Id, PricebookEntry> mapPricebookEntry, Map<Id, Set<String>> mapProductCodesByPOCId) {
        
        Map<String, PricebookEntry> mapPBEIdByProductCode = new Map<String, PricebookEntry>();
        for(PricebookEntry pbe : mapPricebookEntry.values()) {
            mapPBEIdByProductCode.put(pbe.Product2.ProductCode, pbe);
        }
        Map<Id, Set<Id>> appliancePBEIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> supportPBEIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> subscrPBEIds = new Map<Id, Set<Id>>();
        List<OrderItem> allOrderItemsList = new List<OrderItem>();
        List<POC__c> pocRequestsToUpdate = new List<POC__c>();
        List<OrderItem> tagedSupportSubscriptionProductList = new List<OrderItem>();
        List<Order_Event__e> orderEvents = new List<Order_Event__e>();
        for(Order ordObj: orderList){
            orderEvents.add(new Order_Event__e(Order_Id__c = ordObj.Id, Action_Type__c = 'POC_ORDER_AUTOFULFILL'));
            pocRequestsToUpdate.add(new POC__c(Id = ordObj.POC_Request__c, Order__c = ordObj.Id));
            POC__c newPocObj = newPocMap.get(ordObj.POC_Request__c);
            Set<String> productCodeList = mapProductCodesByPOCId.get(newPocObj.id);
            allOrderItemsList.addAll(generateOrderProducts(ordObj, newPocObj, productCodeList, mapPBEIdByProductCode, appliancePBEIds, supportPBEIds, subscrPBEIds));
        }
        if(!allOrderItemsList.isEmpty()){
            insert allOrderItemsList;
            tagedSupportSubscriptionProductList = tagSupportSubscriptionProducts(allOrderItemsList, mapPBEIdByProductCode, appliancePBEIds, supportPBEIds, subscrPBEIds);
        }
        if(!pocRequestsToUpdate.isEmpty()) {
            flowControll.POCRequestTriggerHandler = false;
            update pocRequestsToUpdate; // Tag OrderId on Poc Records.
            if(!tagedSupportSubscriptionProductList.isEmpty()) {
                boolean isOrderTriggerAlreadyBlocked = triggerControl.stopOrderTrigger;
                if(!isOrderTriggerAlreadyBlocked){
                    triggerControl.stopOrderTrigger = true;
                }
                triggerControl.stopOrderItemTrigger = true;
                //update tagedSupportSubscriptionProductList;
                Database.update(tagedSupportSubscriptionProductList, false);
                if(!isOrderTriggerAlreadyBlocked){
                    triggerControl.stopOrderTrigger = false;
                }
                triggerControl.stopOrderItemTrigger = false;
            }
            flowControll.POCRequestTriggerHandler = true;
        }
        if(!orderEvents.isEmpty()){
            if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Order_Old_Trigger__c){
                EventBus.publish(orderEvents);
            }
        }
    }

    private static List<OrderItem> generateOrderProducts(
        Order ordObj,
        POC__c newPocObj, 
        Set<String> productCodeList,
        Map<String, PricebookEntry> mapPBEIdByProductCode,
        Map<Id, Set<Id>> appliancePBEIds,
        Map<Id, Set<Id>> supportPBEIds,
        Map<Id, Set<Id>> subscrPBEIds        
    ) {
        List<OrderItem> newOrderItemsList = new List<OrderItem>();

        Set<Id> currentAppliancePBEIds = new Set<Id>();
        appliancePBEIds.put(ordObj.id, currentAppliancePBEIds);
        Set<Id> currentSupportPBEIds = new Set<Id>();
        supportPBEIds.put(ordObj.id, currentSupportPBEIds);
        Set<Id> currentSubscrPBEIds = new Set<Id>();
        subscrPBEIds.put(ordObj.id, currentSubscrPBEIds);

        if(productCodeList == null || productCodeList.isEmpty()){
            return newOrderItemsList;
        }
        Integer pocDuration = newPocObj.POC_Duration__c.contains(' ') ? Integer.valueOf(newPocObj.POC_Duration__c.split(' ')[0]) : Integer.valueOf(newPocObj.POC_Duration__c);
        Date actualStartDate = ordObj.Actual_Order_Ship_Date__c;
        Date actualEndDate = (actualStartDate != null) ? (actualStartDate.addDays(7).addDays(pocDuration)) : null;
        if(newPocObj.POC_Type__c == 'Web Try and Buy'){
            Date d = newPocObj.Planned_Installation_Date__c == null ? System.today() : newPocObj.Planned_Installation_Date__c;
            actualStartDate =  d;    
            actualEndDate =  d.addDays(pocDuration);             
            if(newPocObj.POC_Stage__c == 'Extended POC'){                            
                actualEndDate = actualEndDate.addDays(pocDuration);
            }
        }
        Set<String> applianceProductCodeSet = getApplianceProductCodeSet(newPocObj.POC_Product_Code__c);
        for(String productCode: productCodeList){
            PricebookEntry pbe = mapPBEIdByProductCode.get(productCode);
            System.debug(productCode+'\n~~~-' + pbe);
            if(pbe != null){
                List<String> pocOptionAndQty = getPocOptionAndQty(newPocObj, applianceProductCodeSet, productCode);
                String pocOption = pocOptionAndQty[0];
                Integer qty = Integer.valueOf(pocOptionAndQty[1]);

                OrderItem oli = new OrderItem();
                oli.OrderId = ordObj.Id;
                oli.PriceBookEntryId = pbe.id;
                oli.UnitPrice = 0;
                oli.Description = pbe.Product2.Name;
                oli.Quantity = qty;
                oli.Support_Start_Date__c = actualStartDate;
                oli.Support_End_Date__c = actualEndDate;
                oli.POC_Option__c = pocOption;
                //12299
                oli.User_license_count__c = newPocObj.Number_of_Users__c;
                if(applianceProductCodeSet.contains(productCode)) {
                    currentAppliancePBEIds.add(pbe.id);
                }
                if(POCRequestFormController.APPLIANCE_PREM_SUPPORT_PRODUCT_CODE == productCode) {
                    currentSupportPBEIds.add(pbe.id);
                }
                if(pbe.Product2.Asset_Priority__c == 2 || pbe.Product2.License_Type__c == 'Subscription') {
                    currentSubscrPBEIds.add(pbe.id);
                }
                newOrderItemsList.add(oli);
            }
        }
        return newOrderItemsList;
    }

    private static List<OrderItem> tagSupportSubscriptionProducts(
        List<OrderItem> allOrderItemsList,
        Map<String, PricebookEntry> mapPBEIdByProductCode,
        Map<Id, Set<Id>> appliancePBEIds,
        Map<Id, Set<Id>> supportPBEIds,
        Map<Id, Set<Id>> subscrPBEIds        
    ) {
        Map<Id, Set<Id>> applianceOrderItemIds = new Map<Id, Set<Id>>();
        List<OrderItem> supportOrderItems = new List<OrderItem>();
        List<OrderItem> subscrOrderItems = new List<OrderItem>();

        List<OrderItem> supportOrderItemsToUpdate = new List<OrderItem>();

        for(OrderItem oi : allOrderItemsList) {

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
        System.debug('~~-~:\n' + subscrOrderItems +'\n' + supportOrderItems + '\n' + supportOrderItemsToUpdate);
        return supportOrderItemsToUpdate;
    }

    private static List<String> getPocOptionAndQty(Poc__c newPocObj, Set<String> applianceProductCodeSet, String productCode){
        Integer qty = (applianceProductCodeSet.contains(productCode)) ? Integer.valueOf(newPocObj.POC_Qty__c) : 1;
        String pocOption = '';

        if(newPocObj.Product_Codes__c != null) {
            System.debug('---fullPOC.Product_Codes__c----'+ newPocObj.Product_Codes__c);
            List<String> productCodeParts = newPocObj.Product_Codes__c.split(';');
            System.debug('---productCodeParts----'+productCodeParts);
            for(String pc : productCodeParts) {
                System.debug('---pc----'+pc);
                List<String> codeParts = pc.split('#');
                System.debug('---codeParts----'+codeParts);

                if(!codeParts.isEmpty() && codeParts.size() >= 2 && productCode == codeParts.get(0)) {
                    qty = Integer.valueOf(codeParts.get(1));
                }
                if(!codeParts.isEmpty() && codeParts.size() >= 3 && productCode == codeParts.get(0)){
                    pocOption = codeParts.get(2);
                }
            }
        }
        return new List<String>{pocOption, ''+qty};
    }

    private static Set<String> getApplianceProductCodeSet(String pocProductCodesStr){
        Set<String> applianceProductCodeSet = new Set<String>();
        List<String> applianceProductCodes = pocProductCodesStr.split(';');
        for(String pr : applianceProductCodes) {
            List<String> prCodeParts = pr.split('#');
            String locPRCodeAppliance = prCodeParts.isEmpty() ? pr : prCodeParts.get(0);
            if('RBK-POLARIS-GPS' != locPRCodeAppliance && 'RBK-EDGE-OBJ' != locPRCodeAppliance) {
                applianceProductCodeSet.add(locPRCodeAppliance);
            }
        }
        return applianceProductCodeSet;
    }

    private static Order generateOrder(POC__c newPoc, POC__c selectedPoc, boolean isWebTryAndBuyTypePocExtended){
        Id pricebook2Id = selectedPoc.Opportunity__r.Pricebook2Id; 
        Id orderRecordId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        Order ord = new Order();
        ord.RecordTypeId = orderRecordId;
        ord.AccountId = selectedPoc.Opportunity__r.AccountId;
        ord.POC_Opportunity__c = newPoc.Opportunity__c;
        ord.EffectiveDate = System.today();
        ord.Status = 'Draft';
        ord.POC_Request__c = newPoc.Id;
        ord.Pricebook2Id = pricebook2Id;
        ord.Type = 'POC';
        ord.Order_Sub_Type__c = 'POC';
        if(newPoc.POC_Type__c == 'Web Try and Buy'){
            ord.Order_Sub_Type__c = 'Try N Buy';
            Integer pocDuration = 30;
            if(String.isNotBlank(newPoc.POC_Duration__c)){
                if(newPoc.POC_Duration__c.contains(' ')){
                    pocDuration = Integer.valueOf(newPoc.POC_Duration__c.split(' ')[0]);
                }else{
                    pocDuration = Integer.valueOf(newPoc.POC_Duration__c);
                }
            }
        }

        ord.ShipToContactName__c = newPoc.Shipping_Contact__c;
        ord.Ship_To_Phone_Number__c = newPoc.Shipping_Contact_Phone__c;
        ord.Ship_to_Email__c = newPoc.Shipping_Contact_Email__c;

        ord.ShippingCity = newPoc.Shipping_City__c;

        ord.ShippingCountryCode = countryNameISOCodeMap.get(newPoc.Shipping_Country__c);
        ord.ShippingStreet = newPoc.Shipping_Street__c;
        ord.ShippingPostalCode = newPoc.Shipping_Zip_Postal_Code__c;

        if(String.isNotBlank(newPoc.Shipping_State__c)
            && newPoc.Shipping_State__c.length() == 2) {
            ord.ShippingStateCode = newPoc.Shipping_State__c;
        }
        else {
            ord.ShippingState = newPoc.Shipping_State__c;
        }


        ord.Additional_Shipping_Comments__c = newPoc.POC_Shipping_Information_Comments__c;
        //Other Product Comments
        ord.Other_Product_Comments__c = newPoc.Other_Accessories__c;
        ord.Polaris_Region__c = newPoc.Polaris_Region__c;
        ord.Polaris_Contact__c = newPoc.Polaris_Contact__c;

        if(newPoc.Polaris_Contact__c != null){
            ord.Polaris_Contact_Email__c = selectedPoc.Polaris_Contact__r.Email;
        }
        return ord;
    }

    public static void onBeforeUpdate(POC__c newPoc, POC__c oldPoc) {
        if(oldPoc.POC_Stage__c != newPoc.POC_Stage__c || oldPoc.POC_Status_Details__c != newPoc.POC_Status_Details__c) {
            newPoc.Last_Update_POC_Status__c = System.today();
        }
        if(oldPoc.POC_Returned__c != newPoc.POC_Returned__c) {
            newPoc.POC_Return_Date__c = Datetime.now();
        }
        if(oldPoc.Approval_Status__c != newPoc.Approval_Status__c && newPoc.Approval_Status__c == 'Pending') {
            newPoc.POC_Submitter__c = UserInfo.getUserId();
        }
        if( (newPoc.POC_Stage__c == 'Extended POC' && newPoc.POC_Stage__c != oldPoc.POC_Stage__c) && newPoc.POC_Type__c == 'Web Try and Buy' && newPoc.Approval_Status__c == 'Approved'){
            Integer pocDuration = 30;
            if(String.isNotBlank(newPoc.POC_Duration__c)){
                if(newPoc.POC_Duration__c.contains(' ')){
                    pocDuration = Integer.valueOf(newPoc.POC_Duration__c.split(' ')[0]);
                }else{
                    pocDuration = Integer.valueOf(newPoc.POC_Duration__c);
                }
            }
            newPoc.POC_Extension_Duration__c = newPoc.POC_Duration__c;
            newPoc.POC_End_Date__c = newPoc.POC_End_Date__c.addDays(pocDuration);
        }
    }

    private static Map<String, String> getCountryNameISOCodeMap() {
        Map<String,String> maplabelVal=new Map<String,String>();
        Schema.sObjectType objType = Contact.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        List<Schema.PicklistEntry> values = fieldMap.get('MailingCountryCode').getDescribe().getPickListValues();
        for (Schema.PicklistEntry a : values){
           maplabelVal.put(a.getLabel(), a.getValue());
        }
        return maplabelVal;
    }

    public static void reassignRetunredAssets(Set<Id> orderIds){
        orderIds.remove(null);
        if(!orderIds.isEmpty()) {
            List<Account> unassignedAccount = [SELECT Id FROM Account WHERE Name = 'Unassigned' LIMIT 1];
            List<Asset> toReassign = [SELECT Id FROM Asset WHERE Order_Service_Item__r.OrderId IN :orderIds];
            for(Asset asset : toReassign) {
                asset.Status = 'POC Unassigned';
                asset.Order_Service_Item__c = null;
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

    public static void syncPocLines(List<POC__c> toProccess, Set<String> allProductCodes, Map<Id, Set<String>> mapProductCodesByPOCId) {
        //Map<Id, List<String>> pocProductCodesById = new Map<Id, List<String>>();
        Map<String, Id> pocProductsById = new Map<String, Id>();
        List<POC_Line__c> toDelete = new List<POC_Line__c>();
        List<POC_Line__c> toInsert = new List<POC_Line__c>();
        List<POC_Line__c> toUpdate = new List<POC_Line__c>();
        if(!toProccess.isEmpty()) {

            for(Product2 pr : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :allProductCodes]) {
                pocProductsById.put(pr.ProductCode, pr.Id);
            }
            for(POC__c poc : [SELECT Id, Product_Codes__c, POC_Product_Code__c, POC_Qty__c, (SELECT Id, Product_Code__c, Product__c, Quantity__c FROM POC_Lines__r) FROM POC__c WHERE Id IN :toProccess]) {

                Set<String> codeProducts = (mapProductCodesByPOCId.containsKey(poc.Id)) ? mapProductCodesByPOCId.get(poc.Id) : new Set<String>();
                List<POC_Line__c> pocLines = poc.POC_Lines__r;
				System.debug(codeProducts + '\n++++' + mapProductCodesByPOCId);
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
    
    public static void insertPocLines(List<POC__c> toProccess, Set<String> allProductCodes) {
        Map<Id, List<String>> pocProductCodesById = new Map<Id, List<String>>();
        Map<String, Id> pocProductsById = new Map<String, Id>();
        List<POC_Line__c> toInsert = new List<POC_Line__c>();
        if(!toProccess.isEmpty()) {

            for(Product2 pr : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :allProductCodes]) {
                pocProductsById.put(pr.ProductCode, pr.Id);
            }
            for(POC__c poc : toProccess) {

                List<String> codeProducts = (pocProductCodesById.containsKey(poc.Id)) ? pocProductCodesById.get(poc.Id) : new List<String>();
				Set<String> codeProductsSet = new Set<String>(codeProducts);
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
        if(!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
    
}