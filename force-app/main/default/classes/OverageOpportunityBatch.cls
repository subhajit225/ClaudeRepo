global class OverageOpportunityBatch implements Database.Batchable<sObject>, Database.stateful, System.Schedulable{ 
    
    public static final String OPP_SUBTYPE = 'MSP Overage';
    public static final String OPP_NAME = 'Overage Opportunity';
    public static final String OPP_STAGE = '1 Discovery';
    public static final String OPP_TYPE = 'Existing Customer';
    public static final String OPP_REGISTRATION = 'Rubrik Sourced';
    public static final String OPP_STAGE_FINAL = '7 Closed Won';
    public static final String OPP_FORECAST = 'Closed';
    public static final String ORDER_TYPE = 'Revenue';
    public static final String ORDER_SUBTYPE = 'MSP Overage';
    public static final String ORDER_DRAFT = 'Draft';
    public static final String ORDER_PENDING = 'Pending';
    public static final String ORDER_CALC = 'Completed';
    public static final String ORDER_STATUS = 'Activated';
    public static final String MSP_ACTUAL ='MSP Actual';
    public static ID oppRecTypeIdSalesOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
    
    global Database.querylocator start(Database.BatchableContext BC){
        String query;
        //List<String> lstClusterId;
        //List<String> lstEntitlementId;
        //string recordId = 'aBT6f000000CbCH';
        
        //lstClusterId = System.Label.Cluster_Id.Split(',');
        //lstEntitlementId = System.Label.Entitlement_Id.Split(',');
        
        //String clId = 'MSP11UAT54323257888989';
        //Id entId = '5506f000004wdnSAAQ';
        query = 'SELECT Id, Account__c,Disti_Account__c, Application_Serial_Number__c, Cluster_Id__c, Entitlement_Id__c, Cluster_Usage_in_TB__c, Order__c, Period_End_Date__c,'
              + 'Period_Start_Date__c, PO_Number__c, Product__c,Period_Name__c,Snapshot_Date__c, Usage_in_TB__c, Usage_Type__c,Account__r.OwnerId,  Overage_Opportunity__c, Overage_Order__c, Contract_Price_GIG__c, Initial_Order_Number__c,' 
              + 'Product__r.Name,Order__r.CreatedDate, Order__r.Ship_To_Name__c, Order__r.ShipToContactName__c, Order__r.Ship_to_Email__c, Order__r.Ship_To_Phone_Number__c, Order__r.Shipping_Carrier__c, Order__r.Service_Level__c, Order__r.Shipping_Account_Number__c, Order__r.ShippingCountry,'
              + 'Order__r.ShippingStreet, Order__r.ShippingCity, Order__r.ShippingState, Order__r.ShippingPostalCode, Order__r.Opportunity.Initial_Contacts_Name__c, Order__r.Opportunity.Alliance_HW_Partner__c,'
              + 'Order__r.Opportunity.Alliance_Partner_Name__c, Order__r.Opportunity.Alliance_Source_Type_SW__c, Order__r.Opportunity.Cloud_Type__c, Order__r.Opportunity.Installation_Assigned_To__c,'
              + 'Order__r.Opportunity.Has_Polaris_Product__c, Order__r.Opportunity.Polaris_Region__c, Order__r.Opportunity.Polaris_Portal_Contact__c, Order__r.Opportunity.Key_Feature_Needs__c, Order__r.Opportunity.Lost_To_Won_Against__c,Order__r.Opportunity.Win_Loss_Comments__c,Order__r.Opportunity.Partner_Lookup__c,Order__r.Opportunity.Primary_Competitor__c,Order__r.Bill_To_Name__c'
              + ' FROM CPQ_MSP_Overage__c where Overage_Opportunity__c = NULL AND Overage_Order__c = NULL AND Contract_Price_GIG__c != NULL'
              + ' AND CreatedDate = THIS_MONTH'; //CPQ22-277 //SAL24-387 removed Order__r.Opportunity.Partner_Level_Of_Involvement__c,Order__r.Opportunity.Alliance_Source_Type_HW__c
        
        /*if(clusterId != 'NA' && entitlementId != 'NA') {
    
            query += ' AND (Cluster_Id__c IN: lstClusterId OR Entitlement_Id__c IN: lstEntitlementId)';
        }
        else if(clusterId != 'NA') {
            
            query += ' AND Cluster_Id__c IN: lstClusterId';
        }
        else if(entitlementId != 'NA') {
            
            query += ' AND Entitlement_Id__c IN: lstEntitlementId';
        }*/
        system.debug('####query'+query);
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new OverageOpportunityBatch(), 1);
    }

    global void execute(Database.BatchableContext BC, List<CPQ_MSP_Overage__c> scope){  
        
        system.debug('Ashwini scope' +scope);
    
        Set<String> orderNumberSet = new Set<String>(); 
        Set<String> oldOrderProductName = new Set<String>();
        
        Map<String, List<OrderItem>> oldOrderAndOrderProduct = new Map<String, List<OrderItem>>();
        Map<String, Product_Mapping_for_MSP_Overage__mdt> oldProductAndMapping = new Map<String, Product_Mapping_for_MSP_Overage__mdt>();
        Map<String, WrapperForOverageOpportunityBatch.AccountProductWrapper> clusterAndWrapperMap = new Map<String, WrapperForOverageOpportunityBatch.AccountProductWrapper>();
        Map<String, WrapperForOverageOpportunityBatch.AccountProductWrapper> entitlementAndWrapperMap = new Map<String, WrapperForOverageOpportunityBatch.AccountProductWrapper>();  //Ashwini SW Only
        Map<String,String> clusterAndOverage = new Map<String,String>();
        Map<String,String> entitlementAndOverage = new Map<String,String>();   //Ashwini SW Only
        Map<String, Set<String>> clusterAndApplicationId = new Map<String, Set<String>>();

        List<OrderItem> oldOrderItem = new List<OrderItem>();
        List<Opportunity> oppListToInsert = new List<Opportunity>();
        List<Order> orderListToInsert = new List<Order>();
        List<OrderItem> orderItemToInsert = new List<OrderItem>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityLineItem> oppProdToCreate = new List<OpportunityLineItem>();
        List<Opportunity> listOfOpportunityToUpdate = new List<Opportunity>();
        List<Order> orderToUpdate = new List<Order>();
        
        
        //Create date for Opportunity
        //Date nextMonthsDate = System.Today().toStartOfMonth().addMonths(-1);
        //Date overagePODate = System.Today().toStartOfMonth().addMonths(1);
        Date dateField = System.Today();
        Integer numberOfDays = Date.daysInMonth(dateField.year(), dateField.month());
        Date lastDayOfMonth = Date.newInstance(dateField.year(), dateField.month(), numberOfDays);
        
        Pricebook2 cpqPb = [SELECT Id
                                 , Name 
                              FROM Pricebook2 
                             WHERE Name = 'CPQ PriceBook' 
                             LIMIT 1];
         
        
        for(CPQ_MSP_Overage__c overage : scope) {
            
            system.debug('Ashwini overage cluster id' +overage.Cluster_Id__c);
            system.debug('Ashwini overage entitlement id' +overage.Entitlement_Id__c);
            //Create set of Order Number 
            if(overage.Initial_Order_Number__c != null) {
                orderNumberSet.add((String.valueOf(overage.Initial_Order_Number__c)).substringBefore('.'));
                //orderNumberSet.add(Integer.valueOf(overage.Initial_Order_Number__c));
                
                if(overage.Cluster_Id__c != null){    //Ashwini SW
                    if(! clusterAndApplicationId.containsKey(overage.Cluster_Id__c)) {
                    clusterAndApplicationId.put(overage.Cluster_Id__c, new Set<String> {overage.Application_Serial_Number__c});
                    }
                    else {
                        Set<String> serialNo = clusterAndApplicationId.get(overage.Cluster_Id__c);
                        serialNo.add(overage.Application_Serial_Number__c);
                        clusterAndApplicationId.put(overage.Cluster_Id__c, serialNo);
                    }
                    
                }
            }
            
        }
       
        oldOrderItem = [SELECT Id
                             , Product2Id
                             , Product2.Name
                             , Order.OrderNumber 
                             , Order.AccountId
                             , Order.Overage_PO__c
                             , Order.TotalAmount
                             , Back_end_Capacity__c
                             , Order.Id
                             , SerialNumber__c
                             , OrderItemNumber
                          FROM OrderItem 
                         WHERE Order.OrderNumber 
                            IN :orderNumberSet
                        ];

        Map<Id, Integer> mapOrderWithCountOfSW0CommitLines = new Map<Id, Integer>();
    
        Integer countOfSW0CommitLines = 0;
        Integer countOfAllLines = 0;

        for(OrderItem oldInstance :oldOrderItem){

            countOfAllLines = countOfAllLines+1;
            
            if(oldInstance.Back_end_Capacity__c == 0 && oldInstance.Order.TotalAmount == 0){
                if(!mapOrderWithCountOfSW0CommitLines.containsKey(oldInstance.Order.Id)){
               
                    countOfSW0CommitLines = countOfSW0CommitLines+1;
                
                }else{
                    countOfSW0CommitLines = mapOrderWithCountOfSW0CommitLines.get(oldInstance.Order.Id);
                    countOfSW0CommitLines = countOfSW0CommitLines+1;
                    
                }
                mapOrderWithCountOfSW0CommitLines.put(oldInstance.OrderId, countOfSW0CommitLines);
            }
    
            oldOrderProductName.add(oldInstance.Product2.Name);
            if(! oldOrderAndOrderProduct.containsKey(oldInstance.Order.OrderNumber)) {              
                oldOrderAndOrderProduct.put(oldInstance.Order.OrderNumber, new List<orderItem> {oldInstance});
            }  
            else{
                Boolean flagForDuplicate = false;
                List<orderItem> productNameDummy = oldOrderAndOrderProduct.get(oldInstance.Order.OrderNumber);
                List<orderItem> productNameList = oldOrderAndOrderProduct.get(oldInstance.Order.OrderNumber);
                for(OrderItem oIInstance :productNameDummy) {
                    if(oIInstance.Product2Id == oldInstance.Product2Id) {
                        flagForDuplicate = true; 
                        break;                       
                    }
                    
                    
                }
                if(flagForDuplicate == False) {
                        productNameList.add(oldInstance);
                        oldOrderAndOrderProduct.put(oldInstance.Order.OrderNumber, productNameList);
                }
            } 
        }
        
        Map<Id, Boolean> mapOrderWithCountOfSW0CommitFlag = new Map<Id, Boolean>();
        if(mapOrderWithCountOfSW0CommitLines.size()>0){
            for(Id idOrder :mapOrderWithCountOfSW0CommitLines.keyset()){
                Integer countOfSW0CommitLinesInLoop = mapOrderWithCountOfSW0CommitLines.get(idOrder);
                if(countOfSW0CommitLinesInLoop == countOfAllLines){
                    mapOrderWithCountOfSW0CommitFlag.put(idOrder,true);
                }else {
                    mapOrderWithCountOfSW0CommitFlag.put(idOrder,false);
                }
            }
        }
   
        //query custom metadata
        List<Product_Mapping_for_MSP_Overage__mdt> productMapping = new List<Product_Mapping_for_MSP_Overage__mdt>();
        productMapping = [SELECT Id
                               , DeveloperName
                               , MasterLabel
                               , Consumption_AddOn_Product__c
                               , Overage_Product__c
                               , Overage_Product_Id__c
                               , Overage_Product_Pricebook_Id__c
                               , Overage_Product_Price__c
                               , Actual_Product__c 
                               , Actual_Product_Id__c 
                               , Actual_Product_Pricebook_Id__c 
                               , Actual_Product_Price__c
                               , Product_to_map__c 
                            FROM Product_Mapping_for_MSP_Overage__mdt
                           WHERE Consumption_AddOn_Product__c IN :oldOrderProductName];
                           
        
        //Map of Old Product Name and custom metdata listStyleType
        for(Product_Mapping_for_MSP_Overage__mdt instance : productMapping) {
            
            if(! oldProductAndMapping.containsKey(instance.Consumption_AddOn_Product__c)) {
                oldProductAndMapping.put(instance.Consumption_AddOn_Product__c,instance); 
            }
        }
        
        for(CPQ_MSP_Overage__c overage : scope) {

            WrapperForOverageOpportunityBatch.AccountProductWrapper wrapperInstance = new WrapperForOverageOpportunityBatch.AccountProductWrapper();
            if(overage.Initial_Order_Number__c != null ){
                string orderNo = (String.valueOf(overage.Initial_Order_Number__c)).substringBefore('.');
                if(oldOrderAndOrderProduct.containsKey(orderNo)) {
                    List<OrderItem> orderItemList = new List<OrderItem>();
                    orderItemList = oldOrderAndOrderProduct.get((string.valueOf(overage.Initial_Order_Number__c)).substringBefore('.'));
                  
                if(overage.Cluster_Id__c != null){                                 
                    if(! clusterAndWrapperMap.containsKey(overage.Cluster_Id__c)) {
                        List<String> prodPbId = new List<String>();
                        
                        for(orderItem orderItemInstance : orderItemList) {
                            Product_Mapping_for_MSP_Overage__mdt mappingInstance = new Product_Mapping_for_MSP_Overage__mdt();
                            if(oldProductAndMapping.containsKey(orderItemInstance.Product2.Name)) {
                                mappingInstance = oldProductAndMapping.get(orderItemInstance.Product2.Name);   
                                wrapperInstance.ownerId = overage.Account__r.OwnerId;
                                wrapperInstance.distiAcc = overage.Disti_Account__c;
                                wrapperInstance.clusterId = overage.Account__c;
                                wrapperInstance.poNumber = orderItemInstance.Order.Overage_PO__c;
                                
                                //Set Fields from Order -- Ashwini MSP1.1PostGoLive
                                wrapperInstance.orderCreatedDate = overage.Order__r.CreatedDate; 
                                wrapperInstance.orderShipToName = overage.Order__r.Ship_To_Name__c;
                                wrapperInstance.orderShipToContactName = overage.Order__r.ShipToContactName__c;
                                wrapperInstance.orderShiptoEmail = overage.Order__r.Ship_to_Email__c;
                                wrapperInstance.orderShipToPhoneNumber = overage.Order__r.Ship_To_Phone_Number__c;
                                wrapperInstance.orderShippingCarrier = overage.Order__r.Shipping_Carrier__c;
                                wrapperInstance.orderServiceLevel = overage.Order__r.Service_Level__c;
                                wrapperInstance.orderShippingAccountNumber = overage.Order__r.Shipping_Account_Number__c;
                                wrapperInstance.orderShippingCountry = overage.Order__r.ShippingCountry;
                                wrapperInstance.orderShippingStreet = overage.Order__r.ShippingStreet;
                                wrapperInstance.orderShippingCity = overage.Order__r.ShippingCity;
                                wrapperInstance.orderShippingState = overage.Order__r.ShippingState;
                                wrapperInstance.orderShippingPostalCode = overage.Order__r.ShippingPostalCode;
                                wrapperInstance.orderBillToName = overage.Order__r.Bill_To_Name__c;
                                //Set Fields from Opportunity -- Ashwini MSP1.1PostGoLive
                                wrapperInstance.orderOpportunityInitialContactsName = overage.Order__r.Opportunity.Initial_Contacts_Name__c;
                                wrapperInstance.orderOpportunityAllianceHWPartner = overage.Order__r.Opportunity.Alliance_HW_Partner__c;
                                wrapperInstance.orderOpportunityAlliancePartnerName = overage.Order__r.Opportunity.Alliance_Partner_Name__c;
                                wrapperInstance.orderOpportunityAllianceSourceTypeSW = overage.Order__r.Opportunity.Alliance_Source_Type_SW__c;
                                wrapperInstance.orderOpportunityCloudType = overage.Order__r.Opportunity.Cloud_Type__c;
                                wrapperInstance.orderOpportunityInstallationAssignedTo = overage.Order__r.Opportunity.Installation_Assigned_To__c;
                                //wrapperInstance.orderOpportunityHasPolarisProduct = overage.Order__r.Opportunity.Has_Polaris_Product__c; 
                                //wrapperInstance.orderOpportunityPolarisRegion = overage.Order__r.Opportunity.Polaris_Region__c;
                                //wrapperInstance.orderOpportunityPolarisPortalContact = overage.Order__r.Opportunity.Polaris_Portal_Contact__c;
                                wrapperInstance.orderOpportunityKeyFeatureNeeds = overage.Order__r.Opportunity.Key_Feature_Needs__c;
                        wrapperInstance.orderOpportunityLostToWonAgainst = overage.Order__r.Opportunity.Lost_To_Won_Against__c;
                                wrapperInstance.orderOpportunityPartnerLookup = overage.Order__r.Opportunity.Partner_Lookup__c;
                                wrapperInstance.orderOpportunityPrimaryCompetitor = overage.Order__r.Opportunity.Primary_Competitor__c;
                                wrapperInstance.orderOpportunityWinLossComments = overage.Order__r.Opportunity.Win_Loss_Comments__c;
                                
                                Boolean SWWith0CommitOrder = false;
                                if(mapOrderWithCountOfSW0CommitFlag.containsKey(orderItemInstance.Order.Id)){
                                    SWWith0CommitOrder = mapOrderWithCountOfSW0CommitFlag.get(orderItemInstance.Order.Id);
                                }
                    
                                if(overage.Period_Name__c == 'M0' || SWWith0CommitOrder){
                                    if(overage.Product__r.Name != null && mappingInstance.Product_to_map__c != null && mappingInstance.Product_to_map__c.contains(overage.Product__r.Name)){
                                        if(!prodPbId.contains(mappingInstance.Actual_Product_Id__c  + '-' + mappingInstance.Actual_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c))){
                                            prodPbId.add(mappingInstance.Actual_Product_Id__c  + '-' + mappingInstance.Actual_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c));
                                        }
                                    }
                                } else {
                                    if(overage.Product__r.Name != null && mappingInstance.Product_to_map__c != null && mappingInstance.Product_to_map__c.contains(overage.Product__r.Name)){
                                        if(!prodPbId.contains(mappingInstance.Overage_Product_Id__c + '-' + mappingInstance.Overage_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c))){
                                            prodPbId.add(mappingInstance.Overage_Product_Id__c + '-' + mappingInstance.Overage_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c));
                                        }
                                    }
                                }
                                wrapperInstance.prodIdAndPbId = prodPbId;
                                
                                if(prodPbId != null){
                                    clusterAndWrapperMap.put(overage.Cluster_Id__c,wrapperInstance);
                                }

                            }
                        }   
                    }
                    else {
                        List<String> prodPbId = new List<String>();
                        for(orderItem orderItemInstanceElse : orderItemList) {
                          
                            Product_Mapping_for_MSP_Overage__mdt mappingInstanceElse = new Product_Mapping_for_MSP_Overage__mdt();
                            if(oldProductAndMapping.containsKey(orderItemInstanceElse.Product2.Name)) {
                                mappingInstanceElse = oldProductAndMapping.get(orderItemInstanceElse.Product2.Name);                                    
                                
                                if(clusterAndWrapperMap.containsKey(overage.Cluster_Id__c)) {
                                    wrapperInstance = clusterAndWrapperMap.get(overage.Cluster_Id__c);

                                    wrapperInstance.ownerId = overage.Account__r.OwnerId;
                                    wrapperInstance.distiAcc = overage.Disti_Account__c;
                                    wrapperInstance.clusterId = overage.Account__c;
                                    wrapperInstance.poNumber = orderItemInstanceElse.Order.Overage_PO__c;
                                    
                                    //Set Fields from Order -- Ashwini MSP1.1PostGoLive
                                    if(wrapperInstance.orderCreatedDate >= overage.Order__r.CreatedDate || wrapperInstance.orderCreatedDate == null){
                                        wrapperInstance.orderShipToName = overage.Order__r.Ship_To_Name__c;
                                        wrapperInstance.orderShipToContactName = overage.Order__r.ShipToContactName__c;
                                        wrapperInstance.orderShiptoEmail = overage.Order__r.Ship_to_Email__c;
                                        wrapperInstance.orderShipToPhoneNumber = overage.Order__r.Ship_To_Phone_Number__c;
                                        wrapperInstance.orderShippingCarrier = overage.Order__r.Shipping_Carrier__c;
                                        wrapperInstance.orderServiceLevel = overage.Order__r.Service_Level__c;
                                        wrapperInstance.orderShippingAccountNumber = overage.Order__r.Shipping_Account_Number__c;
                                        wrapperInstance.orderShippingCountry = overage.Order__r.ShippingCountry;
                                        wrapperInstance.orderShippingStreet = overage.Order__r.ShippingStreet;
                                        wrapperInstance.orderShippingCity = overage.Order__r.ShippingCity;
                                        wrapperInstance.orderShippingState = overage.Order__r.ShippingState;
                                        wrapperInstance.orderShippingPostalCode = overage.Order__r.ShippingPostalCode;
                                        wrapperInstance.orderBillToName = overage.Order__r.Bill_To_Name__c;
                                    }
                                    
                                    //Set Fields from Opportunity -- Ashwini MSP1.1PostGoLive
                                    wrapperInstance.orderOpportunityInitialContactsName = overage.Order__r.Opportunity.Initial_Contacts_Name__c;
                                    wrapperInstance.orderOpportunityAllianceHWPartner = overage.Order__r.Opportunity.Alliance_HW_Partner__c;
                                    wrapperInstance.orderOpportunityAlliancePartnerName = overage.Order__r.Opportunity.Alliance_Partner_Name__c;
                                    wrapperInstance.orderOpportunityAllianceSourceTypeSW = overage.Order__r.Opportunity.Alliance_Source_Type_SW__c;
                                    wrapperInstance.orderOpportunityCloudType = overage.Order__r.Opportunity.Cloud_Type__c;
                                    wrapperInstance.orderOpportunityInstallationAssignedTo = overage.Order__r.Opportunity.Installation_Assigned_To__c;
                                    //wrapperInstance.orderOpportunityHasPolarisProduct = overage.Order__r.Opportunity.Has_Polaris_Product__c; 
                                    //wrapperInstance.orderOpportunityPolarisRegion = overage.Order__r.Opportunity.Polaris_Region__c;
                                    //wrapperInstance.orderOpportunityPolarisPortalContact = overage.Order__r.Opportunity.Polaris_Portal_Contact__c;
                                    wrapperInstance.orderOpportunityKeyFeatureNeeds = overage.Order__r.Opportunity.Key_Feature_Needs__c;
                                    wrapperInstance.orderOpportunityLostToWonAgainst = overage.Order__r.Opportunity.Lost_To_Won_Against__c;
                                  wrapperInstance.orderOpportunityPartnerLookup = overage.Order__r.Opportunity.Partner_Lookup__c;
                                  wrapperInstance.orderOpportunityPrimaryCompetitor = overage.Order__r.Opportunity.Primary_Competitor__c;
                                  wrapperInstance.orderOpportunityWinLossComments = overage.Order__r.Opportunity.Win_Loss_Comments__c;
                                    
                                    if(wrapperInstance.prodIdAndPbId != null){
                                      prodPbId = wrapperInstance.prodIdAndPbId;
                                    }
                                    
                                    Boolean SWWith0CommitOrderElse = false;
                                    if(mapOrderWithCountOfSW0CommitFlag.containsKey(orderItemInstanceElse.Order.Id)){
                                        SWWith0CommitOrderElse = mapOrderWithCountOfSW0CommitFlag.get(orderItemInstanceElse.Order.Id);
                                    }

                                    if(overage.Period_Name__c == 'M0' || SWWith0CommitOrderElse){
                                        if(overage.Product__r.Name != null && mappingInstanceElse.Product_to_map__c != null && mappingInstanceElse.Product_to_map__c.contains(overage.Product__r.Name)){
                                            if(!prodPbId.contains(mappingInstanceElse.Actual_Product_Id__c + '-' + mappingInstanceElse.Actual_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c))){
                                                prodPbId.add(mappingInstanceElse.Actual_Product_Id__c + '-' + mappingInstanceElse.Actual_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c));
                                            }
                                        }
                                    } else {
                                        if(overage.Product__r.Name != null && mappingInstanceElse.Product_to_map__c != null && mappingInstanceElse.Product_to_map__c.contains(overage.Product__r.Name)){
                                            if(!prodPbId.contains(mappingInstanceElse.Overage_Product_Id__c + '-' + mappingInstanceElse.Overage_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c))){
                                                prodPbId.add(mappingInstanceElse.Overage_Product_Id__c + '-' + mappingInstanceElse.Overage_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c));
                                            }
                                        }

                                    }
                                    wrapperInstance.prodIdAndPbId = prodPbId;
                                    if(prodPbId != null){
                                        clusterAndWrapperMap.put(overage.Cluster_Id__c,wrapperInstance);
                                    }
                                }
                            }
                        }  
                    }
                    } else if(overage.Entitlement_Id__c != null){  //Ashwini SW Only -- Start
                    if(! entitlementAndWrapperMap.containsKey(overage.Entitlement_Id__c)) {
                        List<String> prodPbId = new List<String>();
                        for(orderItem orderItemInstance : orderItemList) {
                            Product_Mapping_for_MSP_Overage__mdt mappingInstance = new Product_Mapping_for_MSP_Overage__mdt();
                            if(oldProductAndMapping.containsKey(orderItemInstance.Product2.Name)) {
                                mappingInstance = oldProductAndMapping.get(orderItemInstance.Product2.Name);
                                wrapperInstance.ownerId = overage.Account__r.OwnerId;
                                wrapperInstance.distiAcc = overage.Disti_Account__c;
                                wrapperInstance.entitlementId = overage.Account__c;
                                wrapperInstance.poNumber = orderItemInstance.Order.Overage_PO__c;
                                
                                //Set Fields from Order -- Ashwini MSP1.1PostGoLive
                                wrapperInstance.orderCreatedDate = overage.Order__r.CreatedDate;
                                wrapperInstance.orderShipToName = overage.Order__r.Ship_To_Name__c;
                                wrapperInstance.orderShipToContactName = overage.Order__r.ShipToContactName__c;
                                wrapperInstance.orderShiptoEmail = overage.Order__r.Ship_to_Email__c;
                                wrapperInstance.orderShipToPhoneNumber = overage.Order__r.Ship_To_Phone_Number__c;
                                wrapperInstance.orderShippingCarrier = overage.Order__r.Shipping_Carrier__c;
                                wrapperInstance.orderServiceLevel = overage.Order__r.Service_Level__c;
                                wrapperInstance.orderShippingAccountNumber = overage.Order__r.Shipping_Account_Number__c;
                                wrapperInstance.orderShippingCountry = overage.Order__r.ShippingCountry;
                                wrapperInstance.orderShippingStreet = overage.Order__r.ShippingStreet;
                                wrapperInstance.orderShippingCity = overage.Order__r.ShippingCity;
                                wrapperInstance.orderShippingState = overage.Order__r.ShippingState;
                                wrapperInstance.orderShippingPostalCode = overage.Order__r.ShippingPostalCode;
                                wrapperInstance.orderBillToName = overage.Order__r.Bill_To_Name__c;
                                //Set Fields from Opportunity -- Ashwini MSP1.1PostGoLive
                                wrapperInstance.orderOpportunityInitialContactsName = overage.Order__r.Opportunity.Initial_Contacts_Name__c;
                                wrapperInstance.orderOpportunityAllianceHWPartner = overage.Order__r.Opportunity.Alliance_HW_Partner__c;
                                wrapperInstance.orderOpportunityAlliancePartnerName = overage.Order__r.Opportunity.Alliance_Partner_Name__c;
                                wrapperInstance.orderOpportunityAllianceSourceTypeSW = overage.Order__r.Opportunity.Alliance_Source_Type_SW__c;
                                wrapperInstance.orderOpportunityCloudType = overage.Order__r.Opportunity.Cloud_Type__c;
                                wrapperInstance.orderOpportunityInstallationAssignedTo = overage.Order__r.Opportunity.Installation_Assigned_To__c;
                                //wrapperInstance.orderOpportunityHasPolarisProduct = overage.Order__r.Opportunity.Has_Polaris_Product__c; 
                                //wrapperInstance.orderOpportunityPolarisRegion = overage.Order__r.Opportunity.Polaris_Region__c;
                                //wrapperInstance.orderOpportunityPolarisPortalContact = overage.Order__r.Opportunity.Polaris_Portal_Contact__c;
                                wrapperInstance.orderOpportunityKeyFeatureNeeds = overage.Order__r.Opportunity.Key_Feature_Needs__c;
                        wrapperInstance.orderOpportunityLostToWonAgainst = overage.Order__r.Opportunity.Lost_To_Won_Against__c;
                                wrapperInstance.orderOpportunityPartnerLookup = overage.Order__r.Opportunity.Partner_Lookup__c;
                                wrapperInstance.orderOpportunityPrimaryCompetitor = overage.Order__r.Opportunity.Primary_Competitor__c;
                                wrapperInstance.orderOpportunityWinLossComments = overage.Order__r.Opportunity.Win_Loss_Comments__c;
                                
                                Boolean SWWith0CommitOrderEntltmnt = false;
                                if(mapOrderWithCountOfSW0CommitFlag.containsKey(orderItemInstance.Order.Id)){
                                    SWWith0CommitOrderEntltmnt = mapOrderWithCountOfSW0CommitFlag.get(orderItemInstance.Order.Id);
                                }

                                if(overage.Period_Name__c == 'M0' || SWWith0CommitOrderEntltmnt){
                                    if(overage.Product__r.Name != null && mappingInstance.Product_to_map__c != null && mappingInstance.Product_to_map__c.contains(overage.Product__r.Name)){
                                        if(!prodPbId.contains(mappingInstance.Actual_Product_Id__c + '-' + mappingInstance.Actual_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c))){
                                            prodPbId.add(mappingInstance.Actual_Product_Id__c + '-' + mappingInstance.Actual_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c));
                                        }
                                    }
                                } else {
                                    if(overage.Product__r.Name != null && mappingInstance.Product_to_map__c != null && mappingInstance.Product_to_map__c.contains(overage.Product__r.Name)){
                                        if(!prodPbId.contains(mappingInstance.Overage_Product_Id__c + '-' + mappingInstance.Overage_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c))){
                                            prodPbId.add(mappingInstance.Overage_Product_Id__c + '-' + mappingInstance.Overage_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c));
                                        }
                                    }
                                }
                                wrapperInstance.prodIdAndPbId = prodPbId;
                                if(prodPbId != null){
                                    entitlementAndWrapperMap.put(overage.Entitlement_Id__c,wrapperInstance);
                                }
                            }
                        }   
                    }
                    else {
                        List<String> prodPbId = new List<String>();
                        for(orderItem orderItemInstanceElse : orderItemList) {
                            Product_Mapping_for_MSP_Overage__mdt mappingInstanceElse = new Product_Mapping_for_MSP_Overage__mdt();
                            if(oldProductAndMapping.containsKey(orderItemInstanceElse.Product2.Name)) {
                                mappingInstanceElse = oldProductAndMapping.get(orderItemInstanceElse.Product2.Name);                                    

                                if(entitlementAndWrapperMap.containsKey(overage.Entitlement_Id__c)) {
                                    wrapperInstance = entitlementAndWrapperMap.get(overage.Entitlement_Id__c);
                                    wrapperInstance.ownerId = overage.Account__r.OwnerId;
                                    wrapperInstance.distiAcc = overage.Disti_Account__c;
                                    wrapperInstance.entitlementId = overage.Account__c;
                                    wrapperInstance.poNumber = orderItemInstanceElse.Order.Overage_PO__c;
                                    
                                    //Set Fields from Order -- Ashwini MSP1.1PostGoLive
                                    if(wrapperInstance.orderCreatedDate >= overage.Order__r.CreatedDate || wrapperInstance.orderCreatedDate == null){
                                        wrapperInstance.orderShipToName = overage.Order__r.Ship_To_Name__c;
                                        wrapperInstance.orderShipToContactName = overage.Order__r.ShipToContactName__c;
                                        wrapperInstance.orderShiptoEmail = overage.Order__r.Ship_to_Email__c;
                                        wrapperInstance.orderShipToPhoneNumber = overage.Order__r.Ship_To_Phone_Number__c;
                                        wrapperInstance.orderShippingCarrier = overage.Order__r.Shipping_Carrier__c;
                                        wrapperInstance.orderServiceLevel = overage.Order__r.Service_Level__c;
                                        wrapperInstance.orderShippingAccountNumber = overage.Order__r.Shipping_Account_Number__c;
                                        wrapperInstance.orderShippingCountry = overage.Order__r.ShippingCountry;
                                        wrapperInstance.orderShippingStreet = overage.Order__r.ShippingStreet;
                                        wrapperInstance.orderShippingCity = overage.Order__r.ShippingCity;
                                        wrapperInstance.orderShippingState = overage.Order__r.ShippingState;
                                        wrapperInstance.orderShippingPostalCode = overage.Order__r.ShippingPostalCode;
                                        wrapperInstance.orderBillToName = overage.Order__r.Bill_To_Name__c;
                                    }
                                    //Set Fields from Opportunity -- Ashwini MSP1.1PostGoLive
                                    wrapperInstance.orderOpportunityInitialContactsName = overage.Order__r.Opportunity.Initial_Contacts_Name__c;
                                    wrapperInstance.orderOpportunityAllianceHWPartner = overage.Order__r.Opportunity.Alliance_HW_Partner__c;
                                    wrapperInstance.orderOpportunityAlliancePartnerName = overage.Order__r.Opportunity.Alliance_Partner_Name__c;
                                    wrapperInstance.orderOpportunityAllianceSourceTypeSW = overage.Order__r.Opportunity.Alliance_Source_Type_SW__c;
                                    wrapperInstance.orderOpportunityCloudType = overage.Order__r.Opportunity.Cloud_Type__c;
                                    wrapperInstance.orderOpportunityInstallationAssignedTo = overage.Order__r.Opportunity.Installation_Assigned_To__c;
                                    //wrapperInstance.orderOpportunityHasPolarisProduct = overage.Order__r.Opportunity.Has_Polaris_Product__c; 
                                    //wrapperInstance.orderOpportunityPolarisRegion = overage.Order__r.Opportunity.Polaris_Region__c;
                                    //wrapperInstance.orderOpportunityPolarisPortalContact = overage.Order__r.Opportunity.Polaris_Portal_Contact__c;
                                    wrapperInstance.orderOpportunityKeyFeatureNeeds = overage.Order__r.Opportunity.Key_Feature_Needs__c;
                          wrapperInstance.orderOpportunityLostToWonAgainst = overage.Order__r.Opportunity.Lost_To_Won_Against__c;
                                    wrapperInstance.orderOpportunityPartnerLookup = overage.Order__r.Opportunity.Partner_Lookup__c;
                                  wrapperInstance.orderOpportunityPrimaryCompetitor = overage.Order__r.Opportunity.Primary_Competitor__c;
                                  wrapperInstance.orderOpportunityWinLossComments = overage.Order__r.Opportunity.Win_Loss_Comments__c;

                                    if(wrapperInstance.prodIdAndPbId != null){
                                      prodPbId = wrapperInstance.prodIdAndPbId;
                                    }
                                    
                                    Boolean SWWith0CommitOrderEntltmntElse = false;
                                    if(mapOrderWithCountOfSW0CommitFlag.containsKey(orderItemInstanceElse.Order.Id)){
                                        SWWith0CommitOrderEntltmntElse = mapOrderWithCountOfSW0CommitFlag.get(orderItemInstanceElse.Order.Id);
                                    }

                                    if(overage.Period_Name__c == 'M0' || SWWith0CommitOrderEntltmntElse){
                                        if(overage.Product__r.Name != null && mappingInstanceElse.Product_to_map__c != null && mappingInstanceElse.Product_to_map__c.contains(overage.Product__r.Name)){
                                            if(!prodPbId.contains(mappingInstanceElse.Actual_Product_Id__c + '-' + mappingInstanceElse.Actual_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c))){
                                                prodPbId.add(mappingInstanceElse.Actual_Product_Id__c + '-' + mappingInstanceElse.Actual_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c));
                                            }
                                        }
                                    } else {
                                        if(overage.Product__r.Name != null && mappingInstanceElse.Product_to_map__c != null && mappingInstanceElse.Product_to_map__c.contains(overage.Product__r.Name)){
                                            if(!prodPbId.contains(mappingInstanceElse.Overage_Product_Id__c + '-' + mappingInstanceElse.Overage_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c))){
                                                prodPbId.add(mappingInstanceElse.Overage_Product_Id__c + '-' + mappingInstanceElse.Overage_Product_Pricebook_Id__c + '*' + Decimal.valueof(overage.Contract_Price_GIG__c));
                                            }
                                        }
                                    }
                                    
                                    wrapperInstance.prodIdAndPbId = prodPbId;
                                    if(prodPbId != null){
                                        entitlementAndWrapperMap.put(overage.Entitlement_Id__c,wrapperInstance);
                                    }
                                }
                            }
                        }  
                    }
                    }
                    //Ashwini SW Only -- End
                            
                        
                }  
            }
            else {
                if(overage.Usage_Type__c == 'Overage' && overage.Usage_in_TB__c > 0){
                    
                    if(overage.Cluster_Id__c != null){
              
                            if(clusterAndWrapperMap.containsKey(overage.Cluster_Id__c)) {
                                wrapperInstance = clusterAndWrapperMap.get(overage.Cluster_Id__c);
                                wrapperInstance.ownerId = overage.Account__r.OwnerId;
                                wrapperInstance.clusterId = overage.Account__c;
                                wrapperInstance.productQuantity = overage.Usage_in_TB__c;
                                
                                clusterAndWrapperMap.put(overage.Cluster_Id__c,wrapperInstance);
                            }
                            else {
                                WrapperForOverageOpportunityBatch.AccountProductWrapper wrapperInstanceelse = new WrapperForOverageOpportunityBatch.AccountProductWrapper();
                                wrapperInstanceelse.productQuantity = overage.Usage_in_TB__c; 
                                wrapperInstance.ownerId = overage.Account__r.OwnerId;
                                wrapperInstance.clusterId = overage.Account__c;
                                
                                clusterAndWrapperMap.put(overage.Cluster_Id__c, wrapperInstanceelse);
                            }
                    
                    } else if(overage.Entitlement_Id__c != null){
                            if(entitlementAndWrapperMap.containsKey(overage.Entitlement_Id__c)) {
                                wrapperInstance = entitlementAndWrapperMap.get(overage.Entitlement_Id__c);
                                wrapperInstance.ownerId = overage.Account__r.OwnerId;
                                wrapperInstance.entitlementId = overage.Account__c;
                                wrapperInstance.productQuantity = overage.Usage_in_TB__c;
                               
                                entitlementAndWrapperMap.put(overage.Entitlement_Id__c,wrapperInstance);
                            }
                            else {
                                WrapperForOverageOpportunityBatch.AccountProductWrapper wrapperInstanceelse = new WrapperForOverageOpportunityBatch.AccountProductWrapper();
                                wrapperInstanceelse.productQuantity = overage.Usage_in_TB__c;
                                wrapperInstance.ownerId = overage.Account__r.OwnerId;
                                wrapperInstance.entitlementId = overage.Account__c;
                                
                                entitlementAndWrapperMap.put(overage.Entitlement_Id__c, wrapperInstanceelse);
                            }
                    }
                }
                
                
            }  
        }
    
        for(String clusterMapInstance : clusterAndWrapperMap.Keyset()) {
                
                WrapperForOverageOpportunityBatch.AccountProductWrapper wrapperobj = new WrapperForOverageOpportunityBatch.AccountProductWrapper();
                
                wrapperobj = clusterAndWrapperMap.get(clusterMapInstance);
                
                if(wrapperobj.productQuantity > 0 && wrapperobj.prodIdAndPbId != null && wrapperobj.prodIdAndPbId.size() > 0) {
                    Opportunity opportunityInstance = new Opportunity();
                    opportunityInstance.Name = OPP_NAME;
                    opportunityInstance.OwnerId = wrapperobj.ownerId;
                    opportunityInstance.RecordTypeId = oppRecTypeIdSalesOpp;
                    opportunityInstance.AccountId = wrapperobj.clusterId;
                    opportunityInstance.StageName = OPP_STAGE;
                    opportunityInstance.Opportunity_Type__c = OPP_TYPE;
                    opportunityInstance.Opportunity_Sub_Type__c = OPP_SUBTYPE;
                    opportunityInstance.Cluster_Id__c = clusterMapInstance;
                    opportunityInstance.Distributor_Lookup__c = wrapperObj.distiAcc;
                    opportunityInstance.CloseDate = lastDayOfMonth;
                    opportunityInstance.Deal_Registration_Type__c = OPP_REGISTRATION;
                    opportunityInstance.Pricebook2Id = cpqPb.Id;
                    opportunityInstance.Initial_Contacts_Name__c = wrapperobj.orderOpportunityInitialContactsName;
                    opportunityInstance.Lost_To_Won_Against__c = wrapperobj.orderOpportunityLostToWonAgainst;
                    opportunityInstance.Partner_Lookup__c = wrapperobj.orderOpportunityPartnerLookup;
                    opportunityInstance.Primary_Competitor__c = wrapperobj.orderOpportunityPrimaryCompetitor;
                    opportunityInstance.Win_Loss_Comments__c = wrapperobj.orderOpportunityWinLossComments;

                    
                    //Set Fields from Opportunity -- Ashwini MSP1.1PostGoLive
                    opportunityInstance.Initial_Contacts_Name__c = wrapperobj.orderOpportunityInitialContactsName;
                    opportunityInstance.Alliance_HW_Partner__c = wrapperobj.orderOpportunityAllianceHWPartner;
                    opportunityInstance.Alliance_Partner_Name__c = wrapperobj.orderOpportunityAlliancePartnerName;
                    opportunityInstance.Alliance_Source_Type_SW__c = wrapperobj.orderOpportunityAllianceSourceTypeSW;
                    opportunityInstance.Cloud_Type__c = wrapperobj.orderOpportunityCloudType;
                    opportunityInstance.Installation_Assigned_To__c = wrapperobj.orderOpportunityInstallationAssignedTo;
                    //opportunityInstance.Has_Polaris_Product__c = wrapperobj.orderOpportunityHasPolarisProduct; 
                    //opportunityInstance.Polaris_Region__c = wrapperobj.orderOpportunityPolarisRegion;
                    //if(opportunityInstance.AccountId != null){ opportunityInstance.Polaris_Portal_Contact__c = wrapperobj.orderOpportunityPolarisPortalContact;}
                    opportunityInstance.Key_Feature_Needs__c = wrapperobj.orderOpportunityKeyFeatureNeeds;
                    
                    opportunityList.add(opportunityInstance);
                }
                
        }
        for(String entitlementMapInstance : entitlementAndWrapperMap.Keyset()) {
                
                WrapperForOverageOpportunityBatch.AccountProductWrapper wrapperobj = new WrapperForOverageOpportunityBatch.AccountProductWrapper();
                wrapperobj = entitlementAndWrapperMap.get(entitlementMapInstance);
                
                if(wrapperobj.productQuantity > 0 && wrapperobj.prodIdAndPbId != null && wrapperobj.prodIdAndPbId.size() > 0) {
                    Opportunity opportunityInstance = new Opportunity();
                    
                    opportunityInstance.Name = OPP_NAME;
                    opportunityInstance.OwnerId = wrapperobj.ownerId;
                    opportunityInstance.RecordTypeId = oppRecTypeIdSalesOpp;
                    opportunityInstance.AccountId = wrapperobj.entitlementId;
                    opportunityInstance.StageName = OPP_STAGE;
                    opportunityInstance.Opportunity_Type__c = OPP_TYPE;
                    opportunityInstance.Opportunity_Sub_Type__c = OPP_SUBTYPE;
                    opportunityInstance.Entitlement_Id__c = entitlementMapInstance;
                    opportunityInstance.Distributor_Lookup__c = wrapperObj.distiAcc;
                    opportunityInstance.CloseDate = lastDayOfMonth;
                    opportunityInstance.Deal_Registration_Type__c = OPP_REGISTRATION;
                    opportunityInstance.Pricebook2Id = cpqPb.Id;
                    opportunityInstance.Initial_Contacts_Name__c = wrapperobj.orderOpportunityInitialContactsName;
                    opportunityInstance.Lost_To_Won_Against__c = wrapperobj.orderOpportunityLostToWonAgainst;
                    opportunityInstance.Partner_Lookup__c = wrapperobj.orderOpportunityPartnerLookup;
                    opportunityInstance.Primary_Competitor__c = wrapperobj.orderOpportunityPrimaryCompetitor;
                    opportunityInstance.Win_Loss_Comments__c = wrapperobj.orderOpportunityWinLossComments;

                    //Set Fields from Opportunity -- Ashwini MSP1.1PostGoLive
                    opportunityInstance.Initial_Contacts_Name__c = wrapperobj.orderOpportunityInitialContactsName;
                    opportunityInstance.Alliance_HW_Partner__c = wrapperobj.orderOpportunityAllianceHWPartner;
                    opportunityInstance.Alliance_Partner_Name__c = wrapperobj.orderOpportunityAlliancePartnerName;
                    opportunityInstance.Alliance_Source_Type_SW__c = wrapperobj.orderOpportunityAllianceSourceTypeSW;
                    opportunityInstance.Cloud_Type__c = wrapperobj.orderOpportunityCloudType;
                    opportunityInstance.Installation_Assigned_To__c = wrapperobj.orderOpportunityInstallationAssignedTo;
                    //opportunityInstance.Has_Polaris_Product__c = wrapperobj.orderOpportunityHasPolarisProduct; 
                    //opportunityInstance.Polaris_Region__c = wrapperobj.orderOpportunityPolarisRegion;
                    //if(opportunityInstance.AccountId != null){ opportunityInstance.Polaris_Portal_Contact__c = wrapperobj.orderOpportunityPolarisPortalContact; }
                    opportunityInstance.Key_Feature_Needs__c = wrapperobj.orderOpportunityKeyFeatureNeeds;
            
                    opportunityList.add(opportunityInstance);
                }
                
        }
        
        system.debug('=====before==opportunityList===='+opportunityList);
        if(opportunityList.size() > 0) {
          insert opportunityList;
        }
        system.debug('=====after==opportunityList===='+opportunityList);
        
        for(Opportunity oppInstance : opportunityList) {
            if(clusterAndWrapperMap.containsKey(oppInstance.Cluster_Id__c) ) {

                WrapperForOverageOpportunityBatch.AccountProductWrapper wrapperClassInstance = clusterAndWrapperMap.get(oppInstance.Cluster_Id__c);
                if(wrapperClassInstance.clusterId == oppInstance.AccountId && wrapperClassInstance.productQuantity > 0) {
                    
                    for(String stringInstance: wrapperClassInstance.prodIdAndPbId) {
                        
                            OpportunityLineItem oppProdInstance = new OpportunityLineItem();
                            oppProdInstance.OpportunityId = oppInstance.Id;
                            oppProdInstance.Product2Id = stringInstance.substringBefore('-');
                            oppProdInstance.UnitPrice = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                            oppProdInstance.Quantity = wrapperClassInstance.productQuantity;
                            oppProdInstance.PricebookEntryId = (stringInstance.substringAfter('-')).substringBefore('*');
                            oppProdToCreate.add(oppProdInstance);
                                         
                    }
                    Order orderInstance = new Order();
                    orderInstance.AccountId = wrapperClassInstance.clusterId;
                    orderInstance.OpportunityId = oppInstance.Id;
                    orderInstance.Cluster_Id__c = oppInstance.Cluster_Id__c; 
                    orderInstance.EffectiveDate = lastDayOfMonth;
                    orderInstance.PoDate = lastDayOfMonth;
                    orderInstance.Type = ORDER_TYPE;
                    orderInstance.Order_Sub_Type__c = ORDER_SUBTYPE;
                    orderInstance.Status = ORDER_DRAFT;
                    orderInstance.SBQQ__PriceCalcStatus__c = ORDER_CALC;
                    orderInstance.PoNumber = wrapperClassInstance.poNumber;
                    orderInstance.Sync_to_NetSuite__c = TRUE;
                    orderInstance.Order_Status__c = ORDER_PENDING;
                    orderInstance.Pricebook2Id = cpqPb.Id;
                    orderInstance.Polaris_Fulfillment_Status__c = 'Not Needed';
                    //orderInstance.Have_Polaris_Products__c = FALSE;
                    orderInstance.Bill_To_Name__c = wrapperClassInstance.orderBillToName;
                    
                    //Set Fields from Order -- Ashwini MSP1.1PostGoLive
                    orderInstance.Ship_To_Name__c = wrapperClassInstance.orderShipToName;
                    orderInstance.ShipToContactName__c = wrapperClassInstance.orderShipToContactName;
                    orderInstance.Ship_to_Email__c = wrapperClassInstance.orderShiptoEmail;
                    orderInstance.Ship_To_Phone_Number__c = wrapperClassInstance.orderShipToPhoneNumber;
                    orderInstance.Shipping_Carrier__c = wrapperClassInstance.orderShippingCarrier;
                    orderInstance.Service_Level__c = wrapperClassInstance.orderServiceLevel;
                    orderInstance.Shipping_Account_Number__c = wrapperClassInstance.orderShippingAccountNumber;
                    orderInstance.ShippingCountry = wrapperClassInstance.orderShippingCountry;
                    orderInstance.ShippingStreet = wrapperClassInstance.orderShippingStreet;
                    orderInstance.ShippingCity = wrapperClassInstance.orderShippingCity;
                    orderInstance.ShippingState = wrapperClassInstance.orderShippingState;
                    orderInstance.ShippingPostalCode = wrapperClassInstance.orderShippingPostalCode;        

                    orderListToInsert.add(orderInstance);
                }
            
            }
            //Ashwini Sw Only 
            if(entitlementAndWrapperMap.containsKey(oppInstance.Entitlement_Id__c) ) {

                WrapperForOverageOpportunityBatch.AccountProductWrapper wrapperClassInstance = entitlementAndWrapperMap.get(oppInstance.Entitlement_Id__c);
                if(wrapperClassInstance.entitlementId == oppInstance.AccountId && wrapperClassInstance.productQuantity > 0) {                                       
                    for(String stringInstance: wrapperClassInstance.prodIdAndPbId) {
                        OpportunityLineItem oppProdInstance = new OpportunityLineItem();
                        oppProdInstance.OpportunityId = oppInstance.Id;
                        oppProdInstance.Product2Id = stringInstance.substringBefore('-');
                        oppProdInstance.UnitPrice = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                        oppProdInstance.Quantity = wrapperClassInstance.productQuantity;
                        oppProdInstance.PricebookEntryId = (stringInstance.substringAfter('-')).substringBefore('*');
                        oppProdToCreate.add(oppProdInstance);                        
                    }
                    Order orderInstance = new Order();
                    orderInstance.AccountId = wrapperClassInstance.entitlementId;
                    orderInstance.OpportunityId = oppInstance.Id;
                    orderInstance.Entitlement_Id__c = oppInstance.Entitlement_Id__c; 
                    orderInstance.EffectiveDate = lastDayOfMonth;
                    orderInstance.PoDate = lastDayOfMonth;
                    orderInstance.Type = ORDER_TYPE;
                    orderInstance.Order_Sub_Type__c = ORDER_SUBTYPE;
                    orderInstance.Status = ORDER_DRAFT;
                    orderInstance.SBQQ__PriceCalcStatus__c = ORDER_CALC;
                    orderInstance.PoNumber = wrapperClassInstance.poNumber;
                    orderInstance.Sync_to_NetSuite__c = TRUE;
                    orderInstance.Order_Status__c = ORDER_PENDING;
                    orderInstance.Pricebook2Id = cpqPb.Id;
                    orderInstance.Polaris_Fulfillment_Status__c = 'Not Needed';
                    //orderInstance.Have_Polaris_Products__c = FALSE;
                    orderInstance.Bill_To_Name__c = wrapperClassInstance.orderBillToName;
                    
                    //Set Fields from Order -- Ashwini MSP1.1PostGoLive
                    orderInstance.Ship_To_Name__c = wrapperClassInstance.orderShipToName;
                    orderInstance.ShipToContactName__c = wrapperClassInstance.orderShipToContactName;
                    orderInstance.Ship_to_Email__c = wrapperClassInstance.orderShiptoEmail;
                    orderInstance.Ship_To_Phone_Number__c = wrapperClassInstance.orderShipToPhoneNumber;
                    orderInstance.Shipping_Carrier__c = wrapperClassInstance.orderShippingCarrier;
                    orderInstance.Service_Level__c = wrapperClassInstance.orderServiceLevel;
                    orderInstance.Shipping_Account_Number__c = wrapperClassInstance.orderShippingAccountNumber;
                    orderInstance.ShippingCountry = wrapperClassInstance.orderShippingCountry;
                    orderInstance.ShippingStreet = wrapperClassInstance.orderShippingStreet;
                    orderInstance.ShippingCity = wrapperClassInstance.orderShippingCity;
                    orderInstance.ShippingState = wrapperClassInstance.orderShippingState;
                    orderInstance.ShippingPostalCode = wrapperClassInstance.orderShippingPostalCode;
                        
                    orderListToInsert.add(orderInstance);
                }
            }
               
                        
        }
        system.debug('=====before==oppProdToCreate===='+oppProdToCreate);
        if (!Test.isRunningTest()) {
            if(oppProdToCreate.size() > 0) {
                insert oppProdToCreate;
        }
        
        }
        system.debug('=====after==oppProdToCreate===='+oppProdToCreate);
        system.debug('=====before==orderListToInsert===='+orderListToInsert);
        if(orderListToInsert.size() > 0) {
            insert orderListToInsert;
        }
        system.debug('=====after==orderListToInsert===='+orderListToInsert);
        if(!Test.isRunningTest()){
        for(Opportunity oppInstance : opportunityList) {
            oppInstance.StageName = OPP_STAGE_FINAL;
            oppInstance.ForecastCategoryName = OPP_FORECAST; 
            oppInstance.SE_Forecast_Category__c = OPP_FORECAST;
            //Change for CPQ22-3856
            oppInstance.Opportunity_Sub_Type__c = OPP_SUBTYPE;
            //Change for CPQ22-3856
            oppInstance.Commission_Portfolio_Type__c = MSP_ACTUAL;
            /*oppInstance.Lost_To_Won_Against__c = 'Actifio';
            oppInstance.Partner_Lookup__c = '0014000001ibHik';
            oppInstance.Primary_Competitor__c = 'Actifio';
            oppInstance.Win_Loss_Comments__c = 'Test';*/
            listOfOpportunityToUpdate.add(oppInstance);              
        }
        
           system.debug('===listOfOpportunityToUpdate===before==='+listOfOpportunityToUpdate);
            if(listOfOpportunityToUpdate.size() > 0) {
                update listOfOpportunityToUpdate;
            }
            system.debug('===listOfOpportunityToUpdate===after==='+listOfOpportunityToUpdate);
        }
       
       for(Order orderInstance :orderListToInsert) {
           if(orderInstance.Cluster_Id__c != null){
            Set<String> serialNoSet = clusterAndApplicationId.get(orderInstance.Cluster_Id__c);
            String serialNo = '';
            for(String stInstance : serialNoSet) {
                serialNo = serialNo + stInstance + ',';
            }
            if(clusterAndWrapperMap.containsKey(orderInstance.Cluster_Id__c)) {
                    WrapperForOverageOpportunityBatch.AccountProductWrapper wrapperClassInstance = clusterAndWrapperMap.get(orderInstance.Cluster_Id__c);
                    if(wrapperClassInstance.clusterId == orderInstance.AccountId && wrapperClassInstance.productQuantity > 0) { 
                        
                        for(String stringInstance: wrapperClassInstance.prodIdAndPbId) {
                            
                            OrderItem orderItemInstance = new OrderItem ();
                            orderItemInstance.Product2Id = stringInstance.substringBefore('-');
                            orderItemInstance.UnitPrice = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                            orderItemInstance.Sales_Price__c = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                            orderItemInstance.Actual_Sales_Price__c = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                            orderItemInstance.Quantity = wrapperClassInstance.productQuantity;
                            orderItemInstance.OrderId = orderInstance.Id;
                            orderItemInstance.SerialNumber__c = serialNo.removeEnd(',');
                            orderItemInstance.Cluster_Id__c = orderInstance.Cluster_Id__c;                      
                            orderItemInstance.PricebookEntryId = (stringInstance.substringAfter('-')).substringBefore('*');
                            orderItemInstance.SBQQ__ProrateMultiplier__c = 1;
                            orderItemInstance.SBQQ__QuotedQuantity__c = wrapperClassInstance.productQuantity;
                            orderItemInstance.SBQQ__OrderedQuantity__c = wrapperClassInstance.productQuantity;
                            orderItemInstance.SBQQ__QuotedListPrice__c = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                            orderItemInstance.CPQ_MSP_Sales_Price__c = decimal.valueOf(stringInstance.substringAfter('*'));
                            orderItemToInsert.add(orderItemInstance);
                                                                        
                        }
                        if(! clusterAndOverage.containsKey(orderInstance.Cluster_Id__c)) {
                            clusterAndOverage.put(orderInstance.Cluster_Id__c, orderInstance.Id + '-' + orderInstance.OpportunityId);
                        }
                    }
                }
            } else if(orderInstance.Entitlement_Id__c != null){
                if(entitlementAndWrapperMap.containsKey(orderInstance.Entitlement_Id__c)) {
                    WrapperForOverageOpportunityBatch.AccountProductWrapper wrapperClassInstance = entitlementAndWrapperMap.get(orderInstance.Entitlement_Id__c);
                    if(wrapperClassInstance.entitlementId == orderInstance.AccountId && wrapperClassInstance.productQuantity > 0) {                                       
                        for(String stringInstance: wrapperClassInstance.prodIdAndPbId) {
                            OrderItem orderItemInstance = new OrderItem ();
                            orderItemInstance.Product2Id = stringInstance.substringBefore('-');
                            orderItemInstance.UnitPrice = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                            orderItemInstance.Sales_Price__c = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                            orderItemInstance.Actual_Sales_Price__c = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                            orderItemInstance.Quantity = wrapperClassInstance.productQuantity;
                            orderItemInstance.OrderId = orderInstance.Id;
                            orderItemInstance.Entitlement_Id__c = orderInstance.Entitlement_Id__c;                      
                            orderItemInstance.PricebookEntryId = (stringInstance.substringAfter('-')).substringBefore('*');
                            orderItemInstance.SBQQ__ProrateMultiplier__c = 1;
                            orderItemInstance.SBQQ__QuotedQuantity__c = wrapperClassInstance.productQuantity;
                            orderItemInstance.SBQQ__OrderedQuantity__c = wrapperClassInstance.productQuantity;
                            orderItemInstance.SBQQ__QuotedListPrice__c = (decimal.valueOf(stringInstance.substringAfter('*'))*1000);
                            orderItemInstance.CPQ_MSP_Sales_Price__c = decimal.valueOf(stringInstance.substringAfter('*'));
                            orderItemToInsert.add(orderItemInstance); 
                                                                        
                        }
                        if(! entitlementAndOverage.containsKey(orderInstance.Entitlement_Id__c)) {
                            entitlementAndOverage.put(orderInstance.Entitlement_Id__c, orderInstance.Id + '-' + orderInstance.OpportunityId);
                        }
                    }
                }
            }   
       
       }

       if(!Test.isRunningTest()) {
       if(orderItemToInsert.size() > 0) {
           insert orderItemToInsert;
       }
       
        for(Order orderInstance : orderListToInsert) {
            orderInstance.Status = ORDER_STATUS;
            orderToUpdate.add(orderInstance);
            
        }
        if(orderToUpdate.size() > 0) {
            update orderToUpdate;
        }

       }
        List<CPQ_MSP_Overage__c> overageRecordsToUpdate = new List<CPQ_MSP_Overage__c>();
        for(CPQ_MSP_Overage__c overage : scope) {
            if(overage.Cluster_Id__c != null){
                if(clusterAndOverage.containsKey(overage.Cluster_Id__c)) {
                    overage.Overage_Opportunity__c = (clusterAndOverage.get(overage.Cluster_Id__c)).substringAfter('-');
                    overage.Overage_Order__c = (clusterAndOverage.get(overage.Cluster_Id__c)).substringBefore('-');
                }
            } else if(overage.Entitlement_Id__c != null){
                if(entitlementAndOverage.containsKey(overage.Entitlement_Id__c)) {
                    overage.Overage_Opportunity__c = (entitlementAndOverage.get(overage.Entitlement_Id__c)).substringAfter('-');
                    overage.Overage_Order__c = (entitlementAndOverage.get(overage.Entitlement_Id__c)).substringBefore('-');
                }
            }
            overageRecordsToUpdate.add(overage);
        }
        system.debug('===before===overageRecordsToUpdate======='+overageRecordsToUpdate);
        update overageRecordsToUpdate;
        system.debug('===after====overageRecordsToUpdate======'+overageRecordsToUpdate);
    }   
 
    global void finish(Database.BatchableContext BC){
   
        
    }
    
}