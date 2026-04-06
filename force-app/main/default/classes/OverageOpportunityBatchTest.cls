@isTest
public Class OverageOpportunityBatchTest {
    
     @isTest 
     static void testMethod_ExecuteBatch() { 
        //
        ShGl_DisableBusinessLogic__c cdf22 = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Campaign_Member_Triggers__c = true,
                                                                             Disable_Campaign_Trigger__c = true,
                                                                             Disable_Campaign_Validation_Rules__c = true,
                                                                             Disable_Order_Triggers__c = true);
        
         insert cdf22;
                                                                           	
         
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User usr = new User(Alias = 'standt', Email='test@testorg.com', 
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', ProfileId = p.Id, 
                            TimeZoneSidKey='America/Los_Angeles', UserName='testMSPUser1@test.com');
        insert usr;
        
        //AccountCreation
        Account acc = new Account(Name='Test - Account', OwnerId = usr.Id);
        insert acc;
         
       string recid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Distributor').getRecordTypeId();
        Account distiAcc1 = new Account(Name='Test - Account', OwnerId = usr.Id, Type = 'Distributor', RecordTypeid = recid);
        insert distiAcc1;
        
        Account accMSP1 = new Account(Name='Test - MSPAccount', OwnerId = usr.Id);
        insert accMSP1;
        
        Contact contactObj1 = new Contact(LastName = 'Test', LeadSource = 'Web', AccountId = acc.Id, Email = 'test@test.com');
        insert contactObj1;
        
        Contact contactMSP1 = new Contact(LastName = 'Test', LeadSource = 'Web', AccountId = accMSP1.Id, Email = 'test1@test.com');
        insert contactMSP1;
        
        TriggerControl__c objTrigger1 = new TriggerControl__c(Name = 'Opportunity', Disable_Trigger__c = false, 
                                                             DisableTrigger__c = false, SendEmail__c = false);
        insert objTrigger1;
        TriggerControl__c objOrderTrigger1 = new TriggerControl__c(Name = 'Order', Disable_Trigger__c = false, 
                                                             DisableTrigger__c = True, SendEmail__c = false);
        insert objOrderTrigger1;
        
        
        Opportunity opp1 = new Opportunity(Name = 'MSP Opp - Initial', StageName = '1 Discovery', CloseDate = System.today(), 
                                     ForecastCategoryName = 'Best Case', Initial_Contacts_Name__c = contactObj1.Id, AccountId = acc.Id,
                                     Business_Unit__c = 'Rubrik', Deal_Registration_Type__c = 'Rubrik Sourced',
                                     Opportunity_Type__c = 'New Customer', Opportunity_Sub_Type__c = 'MSP');
        insert opp1;
        
        Opportunity oppMSP1 = new Opportunity(Name = 'MSP Opp', StageName = '1 Discovery', CloseDate = System.today(), 
                                     ForecastCategoryName = 'Best Case', Initial_Contacts_Name__c = contactMSP1.Id, AccountId = accMSP1.Id,
                                     Business_Unit__c = 'Rubrik', Deal_Registration_Type__c = 'Rubrik Sourced',
                                     Opportunity_Type__c = 'New Customer', Opportunity_Sub_Type__c = 'MSP');
        insert oppMSP1;
        Id standardPriceBookId1 =  Test.getStandardPricebookId();
        
        PriceBook2 CPQPriceBook = new Pricebook2(Name='CPQ PriceBook');
        insert CPQPriceBook;
        //PriceBook2 CPQPriceBook = [select Id from Pricebook2 where Name='CPQ PriceBook'];
        Id CPQPriceBookId = CPQPriceBook.Id;
        system.debug('CPQ PriceBook in Test Class'+CPQPriceBookId);
        
        Order orderInstance1 = new Order();
        orderInstance1.AccountId = acc.Id;
        orderInstance1.OpportunityId = opp1.Id;
        orderInstance1.EffectiveDate = system.today();  
        orderInstance1.Status = 'Draft';
        orderInstance1.Type = 'Revenue';
        orderInstance1.Pricebook2Id = CPQPriceBookId; 
        insert orderInstance1;
                
        Order orderInstance12 = new Order();
        orderInstance12.AccountId = accMSP1.Id;
        orderInstance12.OpportunityId = oppMSP1.Id;
        orderInstance12.EffectiveDate = system.today();  
        orderInstance12.Status = 'Draft'; 
        orderInstance12.Type = 'Revenue';
        orderInstance12.Pricebook2Id = CPQPriceBookId;
        insert orderInstance12;
        
        Order orderNoforAcc1 = [Select Id,OrderNumber from Order WHERE AccountId = :acc.Id];
        Order orderNoforAccMSP1 = [Select Id,OrderNumber from Order WHERE AccountId = :accMSP1.Id];
        Product2 productObj1 = new Product2(Name='RBK-R6412S-CONS',ProductCode='RBK-R6412S-CONS',Family='R6000',isActive=true);
        insert productObj1;
         
        Product2 productObjHW1 = new Product2(Name='RBK-MSP-R6412S-HW-01',ProductCode='RBK-MSP-R6412S-HW-01',Family='R6000',isActive=true);
        insert productObjHW1;
        
        Product2 productObjAdd11 = new Product2(Name='RBK-RADAR-CONS',ProductCode='RBK-RADAR-CONS',Family='R6000',isActive=true);
        insert productObjAdd11;
        
        Product2 productObjAdd10 = new Product2(Name='RBK-CDP-CONS',ProductCode='RBK-CDP-CONS',Family='R6000',isActive=true);
        insert productObjAdd10;
        
        Product2 productObjAdd21 = new Product2(Name='RBK-CLON-CONS',ProductCode='RBK-CLON-CONS',Family='R6000',isActive=true);
        insert productObjAdd21;
        
        Product2 productObjAdd31 = new Product2(Name='RBK-RADAR-CONS-OVG',ProductCode='RBK-RADAR-CONS-OVG',Family='R6000',isActive=true);
        insert productObjAdd31;
        
        Product2 productObjAdd41 = new Product2(Name='RBK-CONS-OVG',ProductCode='RBK-CONS-OVG',Family='R6000',isActive=true);
        insert productObjAdd41;
        
        Product2 productObjAdd51 = new Product2(Name='RBK-CDP-CONS-OVG',ProductCode='RBK-CDP-CONS-OVG',Family='R6000',isActive=true);
        insert productObjAdd51;
        
        Product2 productObjAdd61 = new Product2(Name='RBK-CLON-CONS-OVG',ProductCode='RBK-CLON-CONS-OVG',Family='R6000',isActive=true);
        insert productObjAdd61;
        
        PricebookEntry pbConsStd = new PricebookEntry(Pricebook2Id=standardPriceBookId1
                                              , Product2Id=productObj1.Id
                                              , UnitPrice=30
                                              , isActive=true);
        insert pbConsStd;
        PricebookEntry pbCons = new PricebookEntry(Pricebook2Id=CPQPriceBookId 
                                              , Product2Id=productObj1.Id
                                              , UnitPrice=30
                                              , isActive=true);
        insert pbCons;
        PricebookEntry pbAddStd = new PricebookEntry(Pricebook2Id=standardPriceBookId1
                                              , Product2Id=productObjAdd11.Id
                                              , UnitPrice=20
                                              , isActive=true);
        insert pbAddStd;
        PricebookEntry pbAdd = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd11.Id
                                              , UnitPrice=20
                                              , isActive=true);
        insert pbAdd;
                                              
        PricebookEntry pbAdd1Std = new PricebookEntry(Pricebook2Id=standardPriceBookId1
                                              , Product2Id=productObjAdd10.Id
                                              , UnitPrice=15
                                              , isActive=true);
        insert pbAdd1Std;
        PricebookEntry pbAdd1 = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd10.Id
                                              , UnitPrice=15
                                              , isActive=true);
        insert pbAdd1; 
        
        PricebookEntry pbAdd2Std = new PricebookEntry(Pricebook2Id=standardPriceBookId1
                                              , Product2Id=productObjAdd21.Id
                                              , UnitPrice=40
                                              , isActive=true);
        insert pbAdd2Std;    
        PricebookEntry pbAdd2 = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd21.Id
                                              , UnitPrice=40
                                              , isActive=true);
        insert pbAdd2; 
        PricebookEntry pbHWStd = new PricebookEntry(Pricebook2Id=standardPriceBookId1
                                              , Product2Id=productObjHW1.Id
                                              , UnitPrice=20000
                                              , isActive=true);
        insert pbHWStd;
        PricebookEntry pbObjHW = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjHW1.Id
                                              , UnitPrice=20000
                                              , isActive=true);
        insert pbObjHW; 
        /*
        PricebookEntry pbAdd3Std = new PricebookEntry(Pricebook2Id=standardPriceBookId1
                                              , Product2Id=productObjAdd3.Id
                                              , UnitPrice=40
                                              , isActive=true);
        insert pbAdd3Std;            
        PricebookEntry pbAdd3 = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd3.Id
                                              , UnitPrice=11
                                              , isActive=true);
        insert pbAdd3;
        
        PricebookEntry pbAdd4Std = new PricebookEntry(Pricebook2Id=standardPriceBookId1
                                              , Product2Id=productObjAdd4.Id
                                              , UnitPrice=10
                                              , isActive=true);
        insert pbAdd4Std;
        PricebookEntry pbAdd4 = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd4.Id
                                              , UnitPrice=10
                                              , isActive=true);
        insert pbAdd4;
        
        PricebookEntry pbAdd5Std = new PricebookEntry(Pricebook2Id=standardPriceBookId1
                                              , Product2Id=productObjAdd5.Id
                                              , UnitPrice=10
                                              , isActive=true);
        insert pbAdd5Std;
        PricebookEntry pbAdd5 = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd5.Id
                                              , UnitPrice=12
                                              , isActive=true);
        insert pbAdd5;
        
        PricebookEntry pbAdd6Std = new PricebookEntry(Pricebook2Id=standardPriceBookId1
                                              , Product2Id=productObjAdd6.Id
                                              , UnitPrice=10
                                              , isActive=true);
        insert pbAdd6Std;
        PricebookEntry pbAdd6 = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd6.Id
                                              , UnitPrice=14
                                              , isActive=true);
        insert pbAdd6;
            */
        /*
        List<Product_Mapping_for_MSP_Overage__mdt> mappingList = new List<Product_Mapping_for_MSP_Overage__mdt>();
        Product_Mapping_for_MSP_Overage__mdt productObj1 = new Product_Mapping_for_MSP_Overage__mdt();
        productObj1.MasterLabel = 'Consumption Overage R6412S';
        productObj1.Consumption_AddOn_Product__c = 'RBK-R6412S-CONS';
        productObj1.Overage_Product__c = 'RBK-CONS-OVG';
        productObj1.Overage_Product_Id__c = productObjAdd4.Id;
        productObj1.Overage_Product_Price__c = 10;
        productObj1.Overage_Product_Pricebook_Id__c = pbAdd4.Id;
        mappingList.add(productObj1);
        
        Product_Mapping_for_MSP_Overage__mdt productObj2 = new Product_Mapping_for_MSP_Overage__mdt();
        productObj2.MasterLabel = 'AddOn Overage Radar';
        productObj2.Consumption_AddOn_Product__c = 'RBK-RADAR-CONS';
        productObj2.Overage_Product__c = 'RBK-RADAR-CONS-OVG';
        productObj2.Overage_Product_Id__c = productObjAdd3.Id;
        productObj2.Overage_Product_Price__c = 12;
        productObj2.Overage_Product_Pricebook_Id__c = pbAdd3.Id;
        mappingList.add(productObj2);
        
        Product_Mapping_for_MSP_Overage__mdt productObj3 = new Product_Mapping_for_MSP_Overage__mdt();
        productObj3.MasterLabel = 'AddOn Overage CDP';
        productObj3.Consumption_AddOn_Product__c = 'RBK-CDP-CONS';
        productObj3.Overage_Product__c = 'RBK-CDP-CONS-OVG';
        productObj3.Overage_Product_Id__c = productObjAdd5.Id;
        productObj3.Overage_Product_Price__c = 13;
        productObj3.Overage_Product_Pricebook_Id__c = pbAdd5.Id;
        mappingList.add(productObj3);
        
        Product_Mapping_for_MSP_Overage__mdt productObj4 = new Product_Mapping_for_MSP_Overage__mdt();
        productObj4.MasterLabel = 'AddOn Overage Clon';
        productObj4.Consumption_AddOn_Product__c = 'RBK-CLON-CONS';
        productObj4.Overage_Product__c = 'RBK-CLON-CONS-OVG';
        productObj4.Overage_Product_Id__c = productObjAdd6.Id;
        productObj4.Overage_Product_Price__c = 14;
        productObj4.Overage_Product_Pricebook_Id__c = pbAdd6.Id;
        mappingList.add(productObj4);
        
        insert mappingList;
        */
        
        
        OrderItem orderItemCons = new OrderItem();
        orderItemCons.OrderId = orderInstance1.Id;
        orderItemCons.Product2Id = productObj1.Id;
        orderItemCons.UnitPrice = pbCons.UnitPrice;
        orderItemCons.Quantity = 20;
        orderItemCons.PricebookEntryId = pbCons.Id;
        insert orderItemCons;
        OrderItem orderItemHW = new OrderItem();
        orderItemHW.OrderId = orderInstance1.Id;
        orderItemHW.Product2Id = productObjHW1.Id;
        orderItemHW.UnitPrice = pbObjHW.UnitPrice;
        orderItemHW.Quantity = 1;
        orderItemHW.PricebookEntryId = pbObjHW.Id;
        insert orderItemHW;
        OrderItem orderItemAdd = new OrderItem();
        orderItemAdd.OrderId = orderInstance1.Id;
        orderItemAdd.Product2Id = productObjAdd11.Id;
        orderItemAdd.UnitPrice = pbAdd.UnitPrice;
        orderItemAdd.Quantity = 20;
        orderItemAdd.PricebookEntryId = pbAdd.Id;
        insert orderItemAdd;
        OrderItem orderItemAdd1 = new OrderItem();
        orderItemAdd1.OrderId = orderInstance12.Id;
        orderItemAdd1.Product2Id = productObjAdd10.Id;
        orderItemAdd1.UnitPrice = pbAdd1.UnitPrice;
        orderItemAdd1.Quantity = 20;
        orderItemAdd1.PricebookEntryId = pbAdd1.Id;
        insert orderItemAdd1;
        OrderItem orderItemAdd2 = new OrderItem();
        orderItemAdd2.OrderId = orderInstance12.Id;
        orderItemAdd2.Product2Id = productObjAdd21.Id;
        orderItemAdd2.UnitPrice = pbAdd2.UnitPrice;
        orderItemAdd2.Quantity = 20;
        orderItemAdd2.PricebookEntryId = pbAdd2.Id;
        insert orderItemAdd2;
        
        List<Account> accWithOwner = [Select Id, Name FROM Account WHERE OwnerId = :usr.Id];
        system.debug('accwithOwner***'+accWithOwner );
        List<CPQ_MSP_Overage__c> overageList = new List<CPQ_MSP_Overage__c>();
        CPQ_MSP_Overage__c overage1 = new CPQ_MSP_Overage__c();
        overage1.Cluster_Id__c = '12345'; 
        overage1.Disti_Account__c = distiAcc1.Id;
        overage1.Cluster_Usage_in_TB__c = 25; 
        overage1.Usage_Type__c = 'Min';
        overage1.Initial_Order_Number__c = Integer.valueOf((orderNoforAcc1.OrderNumber));
        overage1.Account__c = acc.Id;
        overage1.Contract_Price_GIG__c = '0.13';
        overage1.Order__c = orderInstance1.Id;
        overage1.product__c = productObjHW1.Id;
        overage1.Period_Name__c = 'M0';
        overage1.Disti_Account__c = distiAcc1.Id;
        overageList.add(overage1);
        
        CPQ_MSP_Overage__c overage2 = new CPQ_MSP_Overage__c();
        overage2.Cluster_Id__c = '12345'; 
        overage2.Cluster_Usage_in_TB__c = 25; 
        overage2.Usage_in_TB__c = 25;
        overage2.Usage_Type__c = 'Overage';
        overage2.Account__c = acc.Id;
        overage2.Contract_Price_GIG__c = '0.13';
        overage2.Period_Name__c = 'M0';
        overageList.add(overage2);
        
        CPQ_MSP_Overage__c overage3 = new CPQ_MSP_Overage__c();
        overage3.Cluster_Id__c = '1234567'; 
        overage3.Cluster_Usage_in_TB__c = 25;
        overage3.Disti_Account__c = distiAcc1.Id;
        overage3.Usage_Type__c = 'Min';
        overage3.Initial_Order_Number__c = Integer.valueOf(orderNoforAccMSP1.OrderNumber);
        overage3.Account__c = accMSP1.Id;
        overage3.Contract_Price_GIG__c = '0.13';
        overageList.add(overage3);
        
        CPQ_MSP_Overage__c overage31 = new CPQ_MSP_Overage__c();
        overage31.Cluster_Id__c = '1234567'; 
        overage31.Cluster_Usage_in_TB__c = 25;
        overage31.Disti_Account__c = distiAcc1.Id;
        overage31.Usage_Type__c = 'Min';
        overage31.Initial_Order_Number__c = Integer.valueOf(orderNoforAccMSP1.OrderNumber);
        overage31.Account__c = accMSP1.Id;
        overage31.Contract_Price_GIG__c = '0.13';
        overageList.add(overage31);
        
        CPQ_MSP_Overage__c overage4 = new CPQ_MSP_Overage__c();
        overage4.Cluster_Id__c = '1234567'; 
        overage4.Cluster_Usage_in_TB__c = 25; 
        overage4.Usage_in_TB__c = 25;
        overage4.Usage_Type__c = 'Overage';
        overage4.Account__c = accMSP1.Id;
        overage4.Contract_Price_GIG__c = '0.13';
        overage4.Disti_Account__c = distiAcc1.Id;
        overageList.add(overage4);
        
        CPQ_MSP_Overage__c overage5 = new CPQ_MSP_Overage__c();
        overage5.Cluster_Id__c = '1234567'; 
        overage5.Cluster_Usage_in_TB__c = 25; 
        overage5.Usage_in_TB__c = 25;
        overage5.Usage_Type__c = 'Overage';
        overage5.Account__c = accMSP1.Id;
        overage5.Contract_Price_GIG__c = '0.13';
        overage5.Disti_Account__c = distiAcc1.Id;
        overageList.add(overage5);
        
        insert overageList;
       
        List<CPQ_MSP_Overage__c > overageUpdateList = [SELECT Id
                                                            , Account__c
                                                            , Cluster_Id__c
                                                            , Cluster_Usage_in_TB__c
                                                            , PO_Number__c
                                                            , Usage_in_TB__c
                                                            , Usage_Type__c
                                                            , Account__r.OwnerId
                                                            , Initial_Order_Number__c 
                                                            , Application_Serial_Number__c
                                                            , Product__c
                                                            , Disti_Account__c 
                                                            , Snapshot_Date__c
                                                            , Period_Start_Date__c
                                                            , Period_End_Date__c
                                                            , Period_Name__c
                                                            , Entitlement_Id__c
                                                            , Contract_Price_GIG__c
                                                            , Order__r.CreatedDate
                                                            , Order__r.Ship_To_Name__c
                                                            , Order__r.ShipToContactName__c
                                                            , Order__r.Ship_to_Email__c
                                                            , Order__r.Ship_To_Phone_Number__c
                                                            , Order__r.Shipping_Carrier__c
                                                            , Order__r.Service_Level__c
                                                            , Order__r.Shipping_Account_Number__c
                                                            , Order__r.ShippingCountry
                                                            , Order__r.ShippingStreet
                                                            , Order__r.ShippingCity
                                                            , Order__r.ShippingState
                                                            , Order__r.ShippingPostalCode
                                                            , Order__r.Opportunity.Initial_Contacts_Name__c
                                                            , Order__r.Opportunity.Alliance_HW_Partner__c
                                                            , Order__r.Opportunity.Alliance_Source_Type_HW__c
                                                            , Order__r.Opportunity.Alliance_Partner_Name__c
                                                            , Order__r.Opportunity.Alliance_Source_Type_SW__c
                                                            , Order__r.Opportunity.Cloud_Type__c
                                                            , Order__r.Opportunity.Installation_Assigned_To__c
                                                            , Order__r.Opportunity.Partner_Level_Of_Involvement__c
                                                            , Order__r.Opportunity.Has_Polaris_Product__c
                                                            , Order__r.Opportunity.Polaris_Region__c
                                                            , Order__r.Opportunity.Polaris_Portal_Contact__c
                                                            , Order__r.Opportunity.Key_Feature_Needs__c
                                                            , Order__c
                                                            , Product__r.Name
                                                           , Order__r.Opportunity.Lost_To_Won_Against__c
                                                           , Order__r.Opportunity.Win_Loss_Comments__c
                                                           , Order__r.Opportunity.Partner_Lookup__c
                                                           , Order__r.Opportunity.Primary_Competitor__c
                                                           , Order__r.Bill_To_Name__c
                                                         FROM CPQ_MSP_Overage__c 
                                                        WHERE Account__c = :acc.Id OR Account__c = :accMSP1.Id];
        OverageOpportunityBatch batchInstance = new OverageOpportunityBatch();
        
        Test.startTest();
        Database.QueryLocator ql = batchInstance.start(null);
        batchInstance.execute(null,overageUpdateList);
        batchInstance.Finish(null);
        //Database.executeBatch(batchInstance);
        Test.stopTest();
    }
    
    @isTest 
     static void testMethod_ExecuteBatchSWOnlyOrder() { 
        //
         ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Campaign_Member_Triggers__c = true,
                                                                             Disable_Campaign_Trigger__c = true,
                                                                             Disable_Campaign_Validation_Rules__c = true,
                                                                             Disable_Order_Triggers__c = true);
         insert cdf;
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User usr = new User(Alias = 'standt', Email='test@testorg.com', 
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', ProfileId = p.Id, 
                            TimeZoneSidKey='America/Los_Angeles', UserName='testMSPUser2@test.com');
        insert usr;
        
        //AccountCreation
        Account acc = new Account(Name='Test - Account', OwnerId = usr.Id);
        insert acc;
        string recid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Distributor').getRecordTypeId();
        Account distiAcc2 = new Account(Name='Test - Account', OwnerId = usr.Id, Type = 'Distributor', RecordTypeid = recid);
        insert distiAcc2;
        
        Account accMSP2 = new Account(Name='Test - MSPAccount', OwnerId = usr.Id);
        insert accMSP2;
        
        Contact contactObj2 = new Contact(LastName = 'Test', LeadSource = 'Web', AccountId = acc.Id, Email = 'test@test.com');
        insert contactObj2;
        
        Contact contactMSP2 = new Contact(LastName = 'Test', LeadSource = 'Web', AccountId = accMSP2.Id, Email = 'test1@test.com');
        insert contactMSP2;
        
        TriggerControl__c objTrigger = new TriggerControl__c(Name = 'Opportunity', Disable_Trigger__c = false, 
                                                             DisableTrigger__c = false, SendEmail__c = false);
        insert objTrigger;
        TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Order', Disable_Trigger__c = false, 
                                                             DisableTrigger__c = True, SendEmail__c = false);
        insert objOrderTrigger;
        
        
        Opportunity opp = new Opportunity(Name = 'MSP Opp - Initial', StageName = '1 Discovery', CloseDate = System.today(), 
                                     ForecastCategoryName = 'Best Case', Initial_Contacts_Name__c = contactObj2.Id, AccountId = acc.Id,
                                     Business_Unit__c = 'Rubrik', Deal_Registration_Type__c = 'Rubrik Sourced',
                                     Opportunity_Type__c = 'New Customer', Opportunity_Sub_Type__c = 'MSP');
        insert opp;
        
        Opportunity oppMSP = new Opportunity(Name = 'MSP Opp', StageName = '1 Discovery', CloseDate = System.today(), 
                                     ForecastCategoryName = 'Best Case', Initial_Contacts_Name__c = contactMSP2.Id, AccountId = accMSP2.Id,
                                     Business_Unit__c = 'Rubrik', Deal_Registration_Type__c = 'Rubrik Sourced',
                                     Opportunity_Type__c = 'New Customer', Opportunity_Sub_Type__c = 'MSP');
        insert oppMSP;
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 CPQPriceBook1 = new Pricebook2(Name='CPQ PriceBook');
        insert CPQPriceBook1;
        //PriceBook2 CPQPriceBook = [select Id from Pricebook2 where Name='CPQ PriceBook'];
        Id CPQPriceBookId = CPQPriceBook1.Id;
        system.debug('CPQ PriceBook in Test Class'+CPQPriceBookId);
        
        Order orderInstance = new Order();
        orderInstance.AccountId = acc.Id;
        orderInstance.OpportunityId = opp.Id;
        orderInstance.EffectiveDate = system.today();  
        orderInstance.Status = 'Draft';
        orderInstance.Type = 'Revenue';
        orderInstance.Pricebook2Id = CPQPriceBookId; 
        insert orderInstance;
                
        Order orderInstance2 = new Order();
        orderInstance2.AccountId = accMSP2.Id;
        orderInstance2.OpportunityId = oppMSP.Id;
        orderInstance2.EffectiveDate = system.today();  
        orderInstance2.Status = 'Draft'; 
        orderInstance2.Type = 'Revenue';
        orderInstance2.Pricebook2Id = CPQPriceBookId;
        insert orderInstance2;
        
        Order orderNoforAcc = [Select Id,OrderNumber from Order WHERE AccountId = :acc.Id];
        Order orderNoforAccMSP = [Select Id,OrderNumber from Order WHERE AccountId = :accMSP2.Id];
        Product2 productObj = new Product2(Name='RBK-SW-CONS',ProductCode='RBK-SW-CONS',isActive=true);
        insert productObj;
        
        Product2 productObjAdd = new Product2(Name='RBK-RADAR-CONS',ProductCode='RBK-RADAR-CONS',Family='R6000',isActive=true);
        insert productObjAdd;
        
        Product2 productObjAdd1 = new Product2(Name='RBK-CDP-CONS',ProductCode='RBK-CDP-CONS',Family='R6000',isActive=true);
        insert productObjAdd1;
        
        Product2 productObjAdd2 = new Product2(Name='RBK-CLON-CONS',ProductCode='RBK-CLON-CONS',Family='R6000',isActive=true);
        insert productObjAdd2;
        
        Product2 productObjAdd3 = new Product2(Name='RBK-RADAR-CONS-OVG',ProductCode='RBK-RADAR-CONS-OVG',Family='R6000',isActive=true);
        insert productObjAdd3;
        
        Product2 productObjAdd4 = new Product2(Name='RBK-CONS-OVG',ProductCode='RBK-CONS-OVG',Family='R6000',isActive=true);
        insert productObjAdd4;
        
        Product2 productObjAdd5 = new Product2(Name='RBK-CDP-CONS-OVG',ProductCode='RBK-CDP-CONS-OVG',Family='R6000',isActive=true);
        insert productObjAdd5;
        
        Product2 productObjAdd6 = new Product2(Name='RBK-CLON-CONS-OVG',ProductCode='RBK-CLON-CONS-OVG',Family='R6000',isActive=true);
        insert productObjAdd6;
         
        Product2 productObjSWWrapper = new Product2(Name='MSP Software - Dell',ProductCode='MSP Software - Dell',Family='R6000',isActive=true);
        insert productObjSWWrapper;
        PricebookEntry pbSWWrapper = new PricebookEntry(Pricebook2Id=standardPriceBookId
                                              , Product2Id=productObjSWWrapper.Id
                                              , UnitPrice=30
                                              , isActive=true);
        insert pbSWWrapper;
        PricebookEntry pbSWWrapperCPQ = new PricebookEntry(Pricebook2Id=CPQPriceBookId 
                                              , Product2Id=productObjSWWrapper.Id
                                              , UnitPrice=30
                                              , isActive=true);
        insert pbSWWrapperCPQ;
         
        PricebookEntry pbConsStd = new PricebookEntry(Pricebook2Id=standardPriceBookId
                                              , Product2Id=productObj.Id
                                              , UnitPrice=30
                                              , isActive=true);
        insert pbConsStd;
        PricebookEntry pbCons = new PricebookEntry(Pricebook2Id=CPQPriceBookId 
                                              , Product2Id=productObj.Id
                                              , UnitPrice=30
                                              , isActive=true);
        insert pbCons;
        PricebookEntry pbAddStd = new PricebookEntry(Pricebook2Id=standardPriceBookId
                                              , Product2Id=productObjAdd.Id
                                              , UnitPrice=20
                                              , isActive=true);
        insert pbAddStd;
        PricebookEntry pbAdd = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd.Id
                                              , UnitPrice=20
                                              , isActive=true);
        insert pbAdd;
                                              
        PricebookEntry pbAdd1Std = new PricebookEntry(Pricebook2Id=standardPriceBookId
                                              , Product2Id=productObjAdd1.Id
                                              , UnitPrice=15
                                              , isActive=true);
        insert pbAdd1Std;
        PricebookEntry pbAdd1 = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd1.Id
                                              , UnitPrice=15
                                              , isActive=true);
        insert pbAdd1; 
        
        PricebookEntry pbAdd2Std = new PricebookEntry(Pricebook2Id=standardPriceBookId
                                              , Product2Id=productObjAdd2.Id
                                              , UnitPrice=40
                                              , isActive=true);
        insert pbAdd2Std;    
        PricebookEntry pbAdd2 = new PricebookEntry(Pricebook2Id=CPQPriceBookId
                                              , Product2Id=productObjAdd2.Id
                                              , UnitPrice=40
                                              , isActive=true);
        insert pbAdd2; 
       
        
        OrderItem orderItemSWWrapper = new OrderItem();
        orderItemSWWrapper.OrderId = orderInstance2.Id;
        orderItemSWWrapper.Product2Id = productObjSWWrapper.Id;
        orderItemSWWrapper.UnitPrice = pbSWWrapperCPQ.UnitPrice;
        orderItemSWWrapper.Quantity = 20;
        orderItemSWWrapper.PricebookEntryId = pbSWWrapperCPQ.Id;
        insert orderItemSWWrapper;
        OrderItem orderItemCons = new OrderItem();
        orderItemCons.OrderId = orderInstance2.Id;
        orderItemCons.Product2Id = productObj.Id;
        orderItemCons.UnitPrice = pbCons.UnitPrice;
        orderItemCons.Quantity = 20;
        orderItemCons.PricebookEntryId = pbCons.Id;
        insert orderItemCons;
        OrderItem orderItemAdd = new OrderItem();
        orderItemAdd.OrderId = orderInstance2.Id;
        orderItemAdd.Product2Id = productObjAdd.Id;
        orderItemAdd.UnitPrice = pbAdd.UnitPrice;
        orderItemAdd.Quantity = 20;
        orderItemAdd.PricebookEntryId = pbAdd.Id;
        insert orderItemAdd;
        OrderItem orderItemAdd1 = new OrderItem();
        orderItemAdd1.OrderId = orderInstance2.Id;
        orderItemAdd1.Product2Id = productObjAdd1.Id;
        orderItemAdd1.UnitPrice = pbAdd1.UnitPrice;
        orderItemAdd1.Quantity = 20;
        orderItemAdd1.PricebookEntryId = pbAdd1.Id;
        insert orderItemAdd1;
        OrderItem orderItemAdd2 = new OrderItem();
        orderItemAdd2.OrderId = orderInstance2.Id;
        orderItemAdd2.Product2Id = productObjAdd2.Id;
        orderItemAdd2.UnitPrice = pbAdd2.UnitPrice;
        orderItemAdd2.Quantity = 20;
        orderItemAdd2.PricebookEntryId = pbAdd2.Id;
        insert orderItemAdd2;
        
        List<Account> accWithOwner = [Select Id, Name FROM Account WHERE OwnerId = :usr.Id];
        system.debug('accwithOwner***'+accWithOwner );
        List<CPQ_MSP_Overage__c> overageList = new List<CPQ_MSP_Overage__c>();
        CPQ_MSP_Overage__c overage1 = new CPQ_MSP_Overage__c();
        
        CPQ_MSP_Overage__c overage3 = new CPQ_MSP_Overage__c();
        overage3.Entitlement_Id__c = '12345677888'; 
        overage3.Cluster_Usage_in_TB__c = 25;
        overage3.Disti_Account__c = distiAcc2.Id;
        overage3.Usage_Type__c = 'Min';
        overage3.Initial_Order_Number__c = Integer.valueOf(orderNoforAccMSP.OrderNumber);
        overage3.Account__c = accMSP2.Id;
        overage3.Contract_Price_GIG__c = '0.13';
        overage3.Order__c = orderInstance2.Id;
        overage3.Product__c = productObj.Id;
        overage3.Period_Name__c = 'M0';
        overageList.add(overage3);
         
        CPQ_MSP_Overage__c overage31 = new CPQ_MSP_Overage__c();
        overage31.Entitlement_Id__c = '12345677888'; 
        overage31.Cluster_Usage_in_TB__c = 25;
        overage31.Disti_Account__c = distiAcc2.Id;
        overage31.Usage_Type__c = 'Min';
        overage31.Initial_Order_Number__c = Integer.valueOf(orderNoforAccMSP.OrderNumber);
        overage31.Account__c = accMSP2.Id;
        overage31.Contract_Price_GIG__c = '0.13';
        overage31.Order__c = orderInstance2.Id;
        overage31.Product__c = productObj.Id;
        overageList.add(overage31);
         
        CPQ_MSP_Overage__c overage6 = new CPQ_MSP_Overage__c();
        overage6.Entitlement_Id__c = '12345677888'; 
        overage6.Cluster_Usage_in_TB__c = 25; 
        overage6.Usage_in_TB__c = 25;
        overage6.Usage_Type__c = 'Overage';
        overage6.Account__c = accMSP2.Id;
        overage6.Contract_Price_GIG__c = '0.13';
        overage6.Disti_Account__c = distiAcc2.Id;
        overageList.add(overage6);
         
        CPQ_MSP_Overage__c overage7 = new CPQ_MSP_Overage__c();
        overage7.Entitlement_Id__c = '12345677888'; 
        overage7.Cluster_Usage_in_TB__c = 25; 
        overage7.Usage_in_TB__c = 25;
        overage7.Usage_Type__c = 'Overage';
        overage7.Account__c = accMSP2.Id;
        overage7.Contract_Price_GIG__c = '0.13';
        overage7.Disti_Account__c = distiAcc2.Id;
        overageList.add(overage7);
        
        insert overageList;
        
        
        List<CPQ_MSP_Overage__c > overageUpdateList = [SELECT Id
                                                            , Account__c
                                                            , Cluster_Id__c
                                                            , Cluster_Usage_in_TB__c
                                                            , PO_Number__c
                                                            , Usage_in_TB__c
                                                            , Usage_Type__c
                                                            , Account__r.OwnerId
                                                            , Initial_Order_Number__c 
                                                            , Application_Serial_Number__c
                                                            , Product__c
                                                            , Disti_Account__c 
                                                            , Snapshot_Date__c
                                                            , Period_Start_Date__c
                                                            , Period_End_Date__c
                                                            , Period_Name__c
                                                            , Entitlement_Id__c
                                                            , Contract_Price_GIG__c
                                                            , Order__r.CreatedDate
                                                            , Order__r.Ship_To_Name__c
                                                            , Order__r.ShipToContactName__c
                                                            , Order__r.Ship_to_Email__c
                                                            , Order__r.Ship_To_Phone_Number__c
                                                            , Order__r.Shipping_Carrier__c
                                                            , Order__r.Service_Level__c
                                                            , Order__r.Shipping_Account_Number__c
                                                            , Order__r.ShippingCountry
                                                            , Order__r.ShippingStreet
                                                            , Order__r.ShippingCity
                                                            , Order__r.ShippingState
                                                            , Order__r.ShippingPostalCode
                                                            , Order__r.Opportunity.Initial_Contacts_Name__c
                                                            , Order__r.Opportunity.Alliance_HW_Partner__c
                                                            , Order__r.Opportunity.Alliance_Source_Type_HW__c
                                                            , Order__r.Opportunity.Alliance_Partner_Name__c
                                                            , Order__r.Opportunity.Alliance_Source_Type_SW__c
                                                            , Order__r.Opportunity.Cloud_Type__c
                                                            , Order__r.Opportunity.Installation_Assigned_To__c
                                                            , Order__r.Opportunity.Partner_Level_Of_Involvement__c
                                                            , Order__r.Opportunity.Has_Polaris_Product__c
                                                            , Order__r.Opportunity.Polaris_Region__c
                                                            , Order__r.Opportunity.Polaris_Portal_Contact__c
                                                            , Order__r.Opportunity.Key_Feature_Needs__c
                                                            , Order__c
                                                            , Product__r.Name
                                                           , Order__r.Opportunity.Lost_To_Won_Against__c
                                                           , Order__r.Opportunity.Win_Loss_Comments__c
                                                           , Order__r.Opportunity.Partner_Lookup__c
                                                           , Order__r.Opportunity.Primary_Competitor__c
                                                           , Order__r.Bill_To_Name__c
                                                            FROM CPQ_MSP_Overage__c
                                                            WHERE Account__c = :acc.Id OR Account__c = :accMSP2.Id];
        OverageOpportunityBatch batchInstance = new OverageOpportunityBatch();
        
        Test.startTest();
        Database.QueryLocator ql = batchInstance.start(null);
        batchInstance.execute(null,overageUpdateList);
        batchInstance.Finish(null);
        //Database.executeBatch(batchInstance);
        Test.stopTest();
    }
}