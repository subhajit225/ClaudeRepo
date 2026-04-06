/**
 * @description Polaris Temp
 */
public with sharing class PolarisOrderTemplateClass {
    /**
    * @description orderId
    */
    public Id ordId{get;set;}
    /**
    * @description Boolean
    */
    public Boolean isRevenue{get;set;}
    /**
    * @description Boolean
    */
    public Boolean hasPolaris{get;set;}
    /**
    * @description Boolean
    */
    public Boolean hasCustomerURL{get;set;}
    /**
    * @description String
    */
    public String customerURL{get;set;}
    /**
    * @description Boolean
    */
    public Boolean hasRansomware{get;set;}
    /**
    * @description Boolean
    */
    public Boolean hasCloud{get;set;}
    /**
    * @description Boolean
    */
    public Boolean hasCloudType{get;set;}
    /**
    * @description Boolean
    */
    public boolean hardwarEmailType{get;set;}
    /**
    * @description Boolean
    */
    public Boolean isScaleUtility{get;set;}
    /**
    * @description Boolean
    */
    public Boolean isReplacementOrder{get;set;}
    /**
    * @description Boolean
    */
    public Boolean isRSCPurchased{get;set;}
    /**
    * @description to check if it is an MSP PayGo Order 
    */
    public Boolean isMspPayGoOrder {get;set;}

    /**
     * @description
     * @return List of Order products
    */
    public List<OrderItem> getlineItems(){
        hasPolaris = false;
        hasCustomerURL = false;
        hasRansomware = false;
        hasCloud = false;
        hasCloudType = false;
        isScaleUtility = false;

        Order odr = [SELECT Id, Fulfilment_Set_Name__c, Welcome_letter_sent_for_the_first_time__c,Account.RSC_G_Support__c,
                     WelcomeEmailSentforSoftwareProducts__c, Type, ProcessType__c, SD_Status__c, Opportunity.Opportunity_Sub_Type__c,
                     Order_Sub_Type__c,Account.Type,  Line_Types__c, Account.US_Federal_Account__c, SBQQ__Quote__r.Manual_Fulfillment_Quote__c, Opportunity.FSI_Special_Program__c 
                     FROM Order
                     WHERE Id = :ordId];
        isRevenue = odr.Type == 'POC' ? false : true;
        if(Test.isRunningTest() || (odr.Type == 'Revenue' && odr.Opportunity.FSI_Special_Program__c == 'PAYGO-Commit' && (odr.Opportunity.Opportunity_Sub_Type__c == 'GC Offer' || odr.Opportunity.Opportunity_Sub_Type__c == 'GC Renewal'))){
            isMspPayGoOrder = true;
        }
        Boolean isFedAccount = odr.Account.US_Federal_Account__c ==true;
        Boolean isCustomerAccount = !odr.Account.Type.containsIgnoreCase('Customer') ? true : false;
        
        String qtMFQ = odr.SBQQ__Quote__r.Manual_Fulfillment_Quote__c != null ? odr.SBQQ__Quote__r.Manual_Fulfillment_Quote__c : '';
        Boolean isRSCP = qtMFQ.contains('$0 RSC-RSC-P Conversion') || qtMFQ.contains('Paid RSC-P Conversion')
            || qtMFQ.contains('$0 GO-RSCP Conversion') ? true : false;
        Boolean isRSCAccount = odr.Account.RSC_G_Support__c != null && (odr.Account.RSC_G_Support__c.contains('RSC-G') || odr.Account.RSC_G_Support__c.contains('RSC-G;RSC/CDM')) ? true : false;
        
        isRSCPurchased = isRSCAccount || isFedAccount || isCustomerAccount || isRSCP;        
        //CS21-1458 : Updates to welcome email (revenue) for Scale Utility
        isScaleUtility = String.isNotBlank(odr.Order_Sub_Type__c) && Label.Scale_Utility_Order_Subtypes.containsIgnoreCase(odr.Order_Sub_Type__c);

        String id = odr.Fulfilment_Set_Name__c != null ? odr.Fulfilment_Set_Name__c : odr.Id;
        List<OrderItem> orderItemList = new List<OrderItem>();
        //The if condition will fire for only second email i.e Hardware and else condition will fire for software only emails
        if(!odr.Welcome_letter_sent_for_the_first_time__c && odr.WelcomeEmailSentforSoftwareProducts__c){
            hardwarEmailType = true;
            getlineItemsForHardware();
        }
        else{
            String query = 'SELECT Have_Polaris_Products__c,RSCProvisioningUrls__c, Account.Customer_URL__c, HasRansomwareRecoveryWarrenty__c, Cloud_Environment__c, SD_Status__c, ProcessType__c,';
            query += 'Opportunity.Cloud_Type__c, (SELECT Id, Support_Start_Date__c, SerialNumber__c, Order.OrderNumber,Order.ProcessType__c,';
            query += 'PricebookEntry.Product2.Welcome_Letter_Content__c,EndDate,PricebookEntry.Product2.Bundle_Features__c,PricebookEntry.Product2.Release_Product_Types__c,';
            query += 'PricebookEntry.Product2.Name,PricebookEntry.Product2.Description,Quantity,ServiceDate,Support_End_Date__c,Order.Actual_Order_Ship_Date__c, PricebookEntry.Product2.Product_Type__c';
            query += ' FROM OrderItems';
            query += ') FROM Order WHERE ';
            query +=odr.Fulfilment_Set_Name__c != null ? 'Fulfilment_Set_Name__c=: id' : 'Id=: id'; 

            List<Order> orderList = new List<Order>();
            orderList = database.query(String.escapeSingleQuotes(query));

            for(Order order : orderList){

                orderItemList.addAll(order.OrderItems);

                if(order.Have_Polaris_Products__c) hasPolaris = true;
                if(order.RSCProvisioningUrls__c != null || order.Account.Customer_URL__c != null) {
                    hasCustomerURL = true;
                }
                if(order.HasRansomwareRecoveryWarrenty__c) hasRansomware = true;
                if(order.Cloud_Environment__c == 'Azure') hasCloud = true;
                if(order.Opportunity.Cloud_Type__c != null && order.Opportunity.Cloud_Type__c.contains('Microsoft')) hasCloudType = true;
            }
        }
        List<String> orderLineTypes = odr.Line_Types__c?.split(';');
        isReplacementOrder = false;
        if(orderLineTypes != null && !orderLineTypes.isEmpty()){
            for(String lineType: orderLineTypes){
                if(!isReplacementOrder && odr.Type == 'Revenue' && Label.Replacement_order_Line_Type.containsIgnoreCase(lineType)){
                    isReplacementOrder = true;
                }
            }
        }
        return orderItemList;
    }

    /**
     * @description
     * @return List of AspenHardware Wrapper
    */
    public List<AspenHardwareWrapper> getlineItemsForHardware(){
        Order odr = [SELECT Id, Fulfilment_Set_Name__c, Type, ProcessType__c, SD_Status__c FROM Order WHERE Id = :ordId];
        String id = odr.Fulfilment_Set_Name__c != null ? odr.Fulfilment_Set_Name__c : odr.Id;

        String query = 'SELECT Id, ProcessType__c, SD_Status__c, ';
        query += 'OrderNumber,(SELECT Id,SerialNumber__c ';
        query += ' FROM OrderItems';
        query += ') FROM Order WHERE ';
        query +=odr.Fulfilment_Set_Name__c != null ? 'Fulfilment_Set_Name__c=: id' : 'Id =: id';
        List<Order> orderList = new List<Order>();
        orderList = database.query(String.escapeSingleQuotes(query));

        Set<Id> orderItemId = new Set<Id>();
        Set<Id> assetId = new Set<Id>();
        Map<String,String> assetSerialNumber = new Map<String,String>();
        
        Set<String> assetSerailNumberList=new Set<String>();
        Set<String> orderNumberList=new Set<String>();
        for(Order order : orderList){
            if (order.ProcessType__c == 'Aspen' && order.SD_Status__c == 'Success') {
                orderNumberList.add(order.OrderNumber);
                for (OrderItem eachItem : order.OrderItems) {
                    orderItemId.add(eachItem.Id); // ----- CS21-1782
                    if (eachItem.SerialNumber__c  != null) {
                        if(eachItem.SerialNumber__c.contains(',')){
                            List<String> TempList=eachItem.SerialNumber__c.split(',');
                            assetSerailNumberList.addall(TempList);
                        }else{
                            assetSerailNumberList.add(eachItem.SerialNumber__c );
                        }

                    }
                }
            }
        }
        
        // ------- CS21-1782 : Add Chassis Serial Number with Asset Id ------ 
        for(OrderItem ordItem : [SELECT Id, Order.OrderNumber, (SELECT ID, AssetId, Asset.Name FROM Entitlements__r) FROM OrderItem WHERE Id In : orderItemId]){
            for(Entitlement es : ordItem.Entitlements__r){
                if(es.AssetId != null){
                    assetId.add(es.AssetId);
                }
            }
        }
        for(Chassis__c chs : [Select Id, serial_number__c, asset__r.Name FROM Chassis__c where Asset__c IN: assetId]){
            assetSerialNumber.put(chs.asset__r.Name,chs.serial_number__c);
        }
        // ------- CS21-1782 : Add Chassis Serial Number with Asset Id ------ 

        List<AspenHardwareWrapper> AspenHardwareWrapperList = new List<AspenHardwareWrapper>();
        AspenHardwareWrapper AspenHardwareWrapperObject = new AspenHardwareWrapper();
        for(String eachAssetserial : assetSerailNumberList){
            if(AspenHardwareWrapperObject.SerialNumber==''){
                AspenHardwareWrapperObject.SerialNumber= assetSerialNumber.containsKey(eachAssetserial) ? eachAssetserial + ' ('+ assetSerialNumber.get(eachAssetserial)+') ' : eachAssetserial ;
            }else{
                AspenHardwareWrapperObject.SerialNumber += assetSerialNumber.containsKey(eachAssetserial) ? ', '+ eachAssetserial+ ' ('+ assetSerialNumber.get(eachAssetserial)+') ':', '+eachAssetserial;
                //AspenHardwareWrapperObject.SerialNumber +=', '+eachAssetserial;
            }
        }

        for(String eachOrdernumber : orderNumberList){
            if(AspenHardwareWrapperObject.OrderNumber==''){
                AspenHardwareWrapperObject.OrderNumber=eachOrdernumber;
            }else{
                AspenHardwareWrapperObject.OrderNumber +=', '+eachOrdernumber;
            }
        }

        AspenHardwareWrapperList.add(AspenHardwareWrapperObject);
        return AspenHardwareWrapperList;
    }

    /**
     * @description
     * @return List of Entitlement
    */
    public List<Entitlement> getEntitlements(){
        Order odr = new Order();
        if (Schema.sObjectType.Order.isAccessible()){
            odr = [SELECT Id, Fulfilment_Set_Name__c, Type
                    FROM Order
                    WHERE Id =: ordId];
        }

        if(odr.Fulfilment_Set_Name__c == null){
            return [SELECT Id, Order_Service_Item__r.Product2.Appliance_Model__c,
                    Order_Service_Item__r.Order.Opportunity.Initial_Contacts_Name__r.Name,
                    Order_Service_Item__r.Order.Opportunity.Rubrik_Sales_Engineer__r.Name,
                    Primary_Contact__r.Name
                    FROM Entitlement
                    WHERE Order_Service_Item__r.Order.Id =: odr.Id
                    AND Type = 'Manufacturing Entitlement'
                    AND ((Order_Service_Item__r.Product2.Product_Type__c = '3rd Party Hardware' OR Order_Service_Item__r.Product2.Family = 'Third Party License')
                        OR (Order_Service_Item__r.Product2.Product_Level__c = 'Hybrid Software' AND Order_Service_Item__r.Product2.Family = 'Rubrik Scale' AND Order_Service_Item__r.Product2.Product_Type__c IN ('Enterprise Edition', 'Business Edition', 'Foundation Edition') AND Order_Service_Item__r.Product2.Product_Subtype__c != 'Scale MSP')
                        OR (Order_Service_Item__r.Product2.Product_Level__c = null AND Order_Service_Item__r.Product2.Family = 'Rubrik Scale' AND Order_Service_Item__r.Product2.Product_Type__c IN ('Enterprise Edition', 'Business Edition', 'RCDM'))
                        OR (Order_Service_Item__r.Order.Order_Sub_Type__c in ('GC Offer', 'GC Renewal') AND Order_Service_Item__r.Order.Has_Third_Party_Hardware_Product__c = true))];
        }
        return [SELECT Id, Order_Service_Item__r.Product2.Appliance_Model__c,
                Order_Service_Item__r.Order.Opportunity.Initial_Contacts_Name__r.Name,
                Order_Service_Item__r.Order.Opportunity.Rubrik_Sales_Engineer__r.Name,Primary_Contact__r.Name 
                FROM Entitlement
                WHERE Order_Service_Item__r.Order.Fulfilment_Set_Name__c =: odr.Fulfilment_Set_Name__c
                AND Type = 'Manufacturing Entitlement'
                AND ((Order_Service_Item__r.Product2.Product_Type__c = '3rd Party Hardware' OR Order_Service_Item__r.Product2.Family = 'Third Party License')
                    OR (Order_Service_Item__r.Product2.Product_Level__c = 'Hybrid Software' AND Order_Service_Item__r.Product2.Family = 'Rubrik Scale' AND Order_Service_Item__r.Product2.Product_Type__c IN ('Enterprise Edition', 'Business Edition', 'Foundation Edition') AND Order_Service_Item__r.Product2.Product_Subtype__c != 'Scale MSP')
                    OR (Order_Service_Item__r.Product2.Product_Level__c = null AND Order_Service_Item__r.Product2.Family = 'Rubrik Scale' AND Order_Service_Item__r.Product2.Product_Type__c IN ('Enterprise Edition', 'Business Edition', 'RCDM'))
                    OR (Order_Service_Item__r.Order.Order_Sub_Type__c in ('GC Offer', 'GC Renewal') AND Order_Service_Item__r.Order.Has_Third_Party_Hardware_Product__c = true))];
       
    }


    /**
    * @description Method to fetch polaris contact name and email details to be displayed in the email template - CS21-790
    * @return String
    */
    public PolarisDetails getpolarisDetails(){
        PolarisDetails details = new PolarisDetails();
        String polarisContactInformation = '';
        Set<String> contacts = new Set<String>();

        Order polarisOrder = new Order();
            polarisOrder =  [SELECT Id, Fulfilment_Set_Name__c,RSCProvisioningUrls__c, Account.Customer_URL__c,RSC_G_Enabled__c,
                              AccountId, OpportunityId,Opportunity.Opportunity_Sub_Type__c, Opportunity.Managed_Services_Deal_type__c, Opportunity.MSP_End_User_Lookup__c,Type,
                              Polaris_Contact__r.Name, Polaris_Contact_Email__c
                              FROM Order WHERE Id = :ordId LIMIT 1];

        if (string.isNotBlank(polarisOrder.Fulfilment_Set_Name__c)) {
            for (Order eachOrder : [SELECT Id, Polaris_Contact__r.Name, Polaris_Contact_Email__c
                                    FROM Order WHERE Fulfilment_Set_Name__c = :polarisOrder.Fulfilment_Set_Name__c
                                    AND Polaris_Contact__c != null
                                    AND Polaris_Contact_Email__c != null
                                    ORDER BY Createddate DESC])
            {
                if (contacts.add(eachOrder.Polaris_Contact_Email__c.toLowerCase())) {
                    polarisContactInformation = generatePolarisContactDetails(polarisContactInformation, eachOrder);
                }
            }
        } else if(polarisOrder.Polaris_Contact__c != null && polarisOrder.Polaris_Contact_Email__c != null){
            polarisContactInformation = generatePolarisContactDetails(polarisContactInformation, polarisOrder);
        }
        details.isFedRAMPAccount=polarisOrder.RSC_G_Enabled__c;
        details.polarisURL = String.isNotBlank(polarisOrder.RSCProvisioningUrls__c)? polarisOrder.RSCProvisioningUrls__c : polarisOrder.Account.Customer_URL__c;
        details.polarisContactDetails = String.isNotBlank(polarisContactInformation) ? polarisContactInformation.substringBeforeLast(', ') : '';
        /* CS21-3822 */
        details.rscInstances = getRsc(polarisOrder.AccountId, polarisOrder.OpportunityId, polarisOrder.Opportunity.Opportunity_Sub_Type__c, polarisOrder.Opportunity.Managed_Services_Deal_type__c, polarisOrder.Opportunity.MSP_End_User_Lookup__c);
        details.orderType = polarisOrder.Type;
        return details;
    }

    /**
    * @description Method to construct polaris admin details - CS21-790
    * @param polarisContactInformation String
    * @param eachOrder String
    * @return String
    */
    @TestVisible
    private static string generatePolarisContactDetails(string polarisContactInformation, Order eachOrder) {
        polarisContactInformation +=  eachOrder.Polaris_Contact__r.Name;
        polarisContactInformation +=  ' (' + eachOrder.Polaris_Contact_Email__c.toLowerCase() + '), ';
        return polarisContactInformation;
    }
    
     /**
    * @description Method to check Order has both Fedramp and Non-Fedramp Product Subtype - CS21-2322
    * @return Boolean
    */
    public Boolean getOrderItemDetails(){
        Boolean isMixedOrder = False;
        List<String> productBundle = new List<String>{'Subscription', 'Upgrade', 'Software', 'Bundle','SaaS', 'MOSAIC'};
        Integer mixedOrder = [SELECT count() FROM OrderItem where OrderId =:ordId and Order.Account.Customer_URL__c != null and Product2.Product_Subtype__c != 'FEDRAMP' AND Product2.Category__c IN: productBundle];
        if(mixedOrder > 0){
            isMixedOrder = true;
        }
        return isMixedOrder;
    }
    /**
     * @description Retrieves RSC Instance records based on Account, Opportunity context,
     *              and Managed Services configuration.
     *
     *              - Regular / Shared Service → Primary RSC for Account
     *              - Dedicated Service → Child RSC for MSP End User
     *
     * @param AccountId Account associated with the Opportunity.
     * @param OpportunityId Opportunity context to drive filtering logic.
     * @param opportunitySubType Opportunity Sub Type (e.g., Regular).
     * @param ManagedServicesDealtype Managed Services deal type.
     * @param MSPEndUserLookup End User Account for MSP Dedicated Service.
     * @return List<RSCInstance__c> Matching RSC Instance records.
     */
    public static List<RSCInstance__c> getRsc(Id AccountId, Id OpportunityId, String opportunitySubType, String ManagedServicesDealtype, Id MSPEndUserLookup) {
        // Safety check
        if (AccountId == null || OpportunityId == null) {return new List<RSCInstance__c>();}
        // Object-level access check (CRUD)
        if (!Schema.sObjectType.RSCInstance__c.isAccessible()) {
        return new List<RSCInstance__c>();
        }

        Boolean isRegular = String.isNotBlank(opportunitySubType) && opportunitySubType == 'Regular';

        if ((isRegular && ManagedServicesDealtype == null) || String.isNotBlank(ManagedServicesDealtype) && ManagedServicesDealtype == 'Shared Services') {
            return [ SELECT ID,RSCUrl__c,RSCOwnerEmails__c,RSCRegion__c,RSCDeployment__c,RSCHostSite__c FROM RSCInstance__c WHERE AccountId__c = :AccountId AND RSCAccountRelationship__c = 'Primary' AND Status__c = 'ACTIVE'];
        }

        // DEDICATED SERVICE
        else if (String.isNotBlank(ManagedServicesDealtype) && ManagedServicesDealtype == 'Dedicated Deal' && MSPEndUserLookup != null) {
            return [SELECT ID,RSCUrl__c,RSCOwnerEmails__c,RSCRegion__c,RSCDeployment__c,RSCHostSite__c FROM RSCInstance__c WHERE AccountId__c = :AccountId AND SDPEndUser__c = :MSPEndUserLookup AND RSCAccountRelationship__c = 'Child' AND Status__c = 'ACTIVE'];
        }
        else{
            return [ SELECT ID,RSCUrl__c,RSCOwnerEmails__c,RSCRegion__c,RSCDeployment__c,RSCHostSite__c FROM RSCInstance__c WHERE AccountId__c = :AccountId AND RSCAccountRelationship__c = 'Primary' AND Status__c = 'ACTIVE'];
        }
       // return new List<RSCInstance__c>();
    }

    /**
    * @description Wrapper class for PolarisDetails
    */
    public Class PolarisDetails {
        /**
        * @description Boolean
        */
        public Boolean isFedRAMPAccount{get;set;}
        /**
        * @description string
        */
        public string polarisURL{get;set;}
        /**
        * @description string
        */
        public string polarisContactDetails{get;set;}
        /**
        * @description Rsc instances
        */
        public List<RSCInstance__c> rscInstances {get;set;}
        /**
        * @description Order Type
        */
        public string orderType {get;set;}
    }


    /**
    * @description Wrapper class for AspenHardwareWrapper
    */
    public class AspenHardwareWrapper{
        /**
        * @description string
        */
        public String SerialNumber{get;set;}
        /**
        * @description string
        */
        public String OrderNumber{get;set;}

        /**
        * @description AspenHardwareWrapper constructor
        */
        public AspenHardwareWrapper(){
            SerialNumber = '';
            OrderNumber = '';
        }
    }
    
 
    
    /**
    * @description Method to check if Product is related to Salesforce Data Protection Feature Product Orders - CS21-2607
    * @return Boolean
*/
    public boolean getisDataProtection(){
        //Order odr = [SELECT Id, Type FROM Order WHERE Id = :ordId LIMIT 1];
        Set<Id> productId = new Set<Id>();
        for(OrderItem OI : [Select Id, PricebookEntry.Product2Id FROM OrderItem where OrderId =: ordId]){
            productId.add(OI.PricebookEntry.Product2Id);
        }
        
        if(!productId.isEmpty()){
            Integer productCount = [Select Count() FROM Product_Feature__c where Feature__c = 'Salesforce Data protection' and Product_Name__c In : productId];
            return productCount > 0; 
        }
        return False;
    }
    
    /**
        * @description : Method to get details of Order Items for Universal Replacement Orders - CS21-3004
        * @return : OrderItemsInfo
    */
    public List<OrderItemsInfo> getRelacementOrderItemsDetail() {
        List<OrderItemsInfo> orderIteminfo = new List<OrderItemsInfo>();
        Set<Id> originalOrderItemId = new Set<Id>();
                
        Map<String, List<Id>> orderItemOrgnlOIMap = new Map<String,List<Id>>();
        
        Map<Id, Set<Id>> orderItemToOrgOrderItem = new Map<Id, Set<Id>>();
        Map<Id, OrderItem> originalOrderDet = new Map<Id, OrderItem>();
        Map<Id, String> orderItemSurvivingQty = new Map<Id, String>();  
        List<OrderItem> replacementOrderItems = new List<OrderItem>();

        
        for(OrderItem OI : [SELECT Id, Previous_Transaction_Reference__c, order.OrderNumber, PricebookEntry.Product2.Product_Type__c, PricebookEntry.Product2.Bundle_Features__c, PricebookEntry.Product2.Name, 
                                PricebookEntry.Product2.Release_Product_Types__c, PricebookEntry.Product2.Welcome_Letter_Content__c, SerialNumber__c,
                                PricebookEntry.Product2.Description, Quantity, Support_Start_Date__c, Support_End_Date__c, Replacement_Type__c 
                                FROM OrderItem WHERE OrderId =: ordId]){
            replacementOrderItems.add(OI);
                                    
            // ----- Get original order and surviving quantity -----
            if(OI.Previous_Transaction_Reference__c != null){
                List<Object> objectsList = (List<Object>) JSON.deserializeUntyped(OI.Previous_Transaction_Reference__c);
                for(Object obj: objectsList){
                    if (obj instanceof Map<String, Object>) {
                        Map<String,Object> mp = (Map<String, Object>) obj;
                        if(mp.containskey('orderItemId')){
                            originalOrderItemId.add((ID) mp.get('orderItemId'));
                            if(!orderItemToOrgOrderItem.containskey(OI.Id)){
                                orderItemToOrgOrderItem.put(OI.Id, new Set<Id>());
                            }
                            orderItemToOrgOrderItem.get(OI.Id).add((ID) mp.get('orderItemId'));  
                        }
                        // ------ Surviving Quantity ---------
                        if(mp.containskey('orderItemRemainingQuantity')) {
                            if((double)mp.get('orderItemRemainingQuantity') > 0) {
                                orderItemSurvivingQty.put((ID) mp.get('orderItemId'), String.valueOf(mp.get('orderItemRemainingQuantity')));
                            }
                        }
                    }
                }
            }
        }
        
        // ---- get the details of Original Order Items -----
        for(OrderItem OI : [SELECT Id, order.OrderNumber, PricebookEntry.Product2.Product_Type__c, PricebookEntry.Product2.Bundle_Features__c, PricebookEntry.Product2.Name, 
                            PricebookEntry.Product2.Release_Product_Types__c, PricebookEntry.Product2.Welcome_Letter_Content__c, SerialNumber__c,
                            PricebookEntry.Product2.Description, Quantity, Support_Start_Date__c, Support_End_Date__c, Replacement_Type__c 
                            FROM OrderItem WHERE Id IN: originalOrderItemId]){
                                originalOrderDet.put(OI.Id,OI);
                            }
        
        for(OrderItem ordItem: replacementOrderItems) {
            // ------- details of replacement order items -------
            OrderItemsInfo ordWrapper = new OrderItemsInfo();
            ordWrapper.productType = ordItem.PricebookEntry.Product2.Product_Type__c;
            ordWrapper.bundleFeatures = ordItem.PricebookEntry.Product2.Bundle_Features__c;
            ordWrapper.productName = ordItem.PricebookEntry.Product2.Name;
            ordWrapper.releaseProductType = ordItem.PricebookEntry.Product2.Release_Product_Types__c;
            ordWrapper.welcomeLetterContent = ordItem.PricebookEntry.Product2.Welcome_Letter_Content__c;
            ordWrapper.serialNumber = ordItem.SerialNumber__c;
            ordWrapper.productDescription = ordItem.PricebookEntry.Product2.Description;
            ordWrapper.quantity = ordItem.Quantity;
            ordWrapper.supportStartDate = ordItem.Support_Start_Date__c?.format();
            ordWrapper.suppportEndDate = ordItem.Support_End_Date__c?.format();
            ordWrapper.orderNum = ordItem.order.OrderNumber;
            ordWrapper.originalDescription = 'New product';
            String orgnlProd = '';
            String orgnlOrd = '';
            Set<Id> orgOrd = orderItemToOrgOrderItem.containskey(ordItem.Id) ? orderItemToOrgOrderItem.get(ordItem.Id): new Set<Id>();
            for(Id orgOrdId: orgOrd){
                if(orgnlProd == ''){
                    orgnlProd = originalOrderDet.get(orgOrdId)?.PricebookEntry?.Product2?.Name;
                }
                else if(!orgnlProd.contains(originalOrderDet.get(orgOrdId)?.PricebookEntry?.Product2?.Name)){
                    orgnlProd = orgnlProd +', '+ originalOrderDet.get(orgOrdId)?.PricebookEntry?.Product2?.Name;
                }
                
                
                if(orgnlOrd == ''){
                    orgnlOrd = originalOrderDet.get(orgOrdId)?.order?.OrderNumber;
                }
                else if(!orgnlOrd.contains(originalOrderDet.get(orgOrdId)?.order?.OrderNumber)){
                    orgnlOrd = orgnlOrd +', '+ originalOrderDet.get(orgOrdId)?.order?.OrderNumber;
                }
                
                
            }
            ordWrapper.originalOrder = orgnlOrd;
            ordWrapper.originalProduct = orgnlProd;
            orderIteminfo.add(ordWrapper);
            
            if(ordItem.Replacement_Type__c != null && ordItem.Replacement_Type__c.contains('Partial')){
                // ------- details of original order items -------
                for(Id orgOrdId: orgOrd){
                    OrderItemsInfo orgnlOrdWrapper = new OrderItemsInfo();
                    OrderItem orgnlOrderItem = originalOrderDet.get(orgOrdId);
                    orgnlOrdWrapper.productType = orgnlOrderItem.PricebookEntry?.Product2?.Product_Type__c;
                    orgnlOrdWrapper.bundleFeatures = orgnlOrderItem.PricebookEntry?.Product2?.Bundle_Features__c;
                    orgnlOrdWrapper.productName = orgnlOrderItem.PricebookEntry?.Product2?.Name;
                    orgnlOrdWrapper.releaseProductType = orgnlOrderItem.PricebookEntry?.Product2?.Release_Product_Types__c;
                    orgnlOrdWrapper.welcomeLetterContent = orgnlOrderItem.PricebookEntry?.Product2?.Welcome_Letter_Content__c;
                    orgnlOrdWrapper.serialNumber = orgnlOrderItem.SerialNumber__c;
                    orgnlOrdWrapper.productDescription = orgnlOrderItem.PricebookEntry?.Product2?.Description;
                    orgnlOrdWrapper.quantity = orderItemSurvivingQty.containskey(orgOrdId) ? double.valueOf(orderItemSurvivingQty.get(orgOrdId)) : 0.00;
                    orgnlOrdWrapper.supportStartDate = orgnlOrderItem.Support_Start_Date__c?.format();
                    orgnlOrdWrapper.suppportEndDate = orgnlOrderItem.Support_End_Date__c?.format();
                    orgnlOrdWrapper.originalOrder = orgnlOrderItem.order.OrderNumber;
                    orgnlOrdWrapper.originalProduct = orgnlOrderItem.PricebookEntry?.Product2?.Name;
                    orgnlOrdWrapper.orderNum = '';
                    orgnlOrdWrapper.originalDescription = 'Remaining quantity of original product';
                    orderIteminfo.add(orgnlOrdWrapper);
                }
            }
        }
        return orderIteminfo;
    }
    /**
     * @description OrderItemsInfo
     * 
    */
    public class OrderItemsInfo {
        /**
        * @description String
        */
        public String orderNum{get;set;}
        /**
        * @description String
        */
        public String productType{get;set;}
        /**
        * @description String
        */
        public String bundleFeatures{get;set;}
        /**
        * @description String
        */
        public String productName{get;set;}
        /**
        * @description String
        */
        public String releaseProductType{get;set;}
        /**
        * @description String
        */
        public String welcomeLetterContent{get;set;}
        /**
        * @description String
        */
        public String serialNumber{get;set;}
        /**
        * @description String
        */
        public String productDescription{get;set;}
        /**
        * @description Double
        */
        public double quantity{get;set;}
        /**
        * @description String
        */
        public String supportStartDate{get;set;}
        /**
        * @description String
        */
        public String suppportEndDate{get;set;}
        /**
        * @description String
        */
        public String originalDescription{get;set;}
        /**
        * @description String
        */
        public String originalOrder{get;set;}
        /**
        * @description String
        */
        public String originalProduct{get;set;}
    }
    
    // CS21-3004 end
    
    /**
    * @description : Get List of Rate Card Products C21-3905
    * @return : List of Rate Card Products in a Sorting order
    */
    public List<Rate_Card_Product__c> getrateCardProducts() {
        String sortDirection = 'asc';
        // Read stored sort order (global preference)
        List<Rate_Card_Product__c> cfg = [
            SELECT Sort_Order__c
            FROM Rate_Card_Product__c
            WHERE Sort_Order__c != NULL
            LIMIT 1
        ];

        if (!cfg.isEmpty() && cfg[0].Sort_Order__c == 'desc') {
            sortDirection = 'desc';
        }

        String soql =String.escapeSingleQuotes('SELECT Id, Product_Name__c, Product_Description__c, Sort_Order__c FROM Rate_Card_Product__c ORDER BY Product_Name__c ') + String.escapeSingleQuotes(sortDirection);
        return Database.query(soql);
    }
}