@isTest
public class OrderMainTestBLIentries {
       /* public static testMethod void testBLIentriesallExceptMSP() {
        //create account and contact to assign to opportunity
            ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();
            setting.Name = 'System Administrator';
            setting.Disable_Opportunity_Old_Trigger__c = TRUE;
            setting.Disable_Order_Old_Trigger__c = TRUE;
            setting.Disable_Account_Old_Trigger__c = TRUE;
            insert setting;
        
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
            settingDisable.Name = 'System Administrator';
            settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;
            settingDisable.Disable_Order_Validation_Rules__c = TRUE;
            insert settingDisable;
            
            List<TriggerControl__c> triggerList=new List<TriggerControl__c>();
            TriggerControl__c setting0 = new TriggerControl__c();
            setting0.Name = 'Order';
            setting0.DisableTrigger__c = TRUE;
            triggerList.add(setting0);
            TriggerControl__c setting1 = new TriggerControl__c();
            setting1.Name = 'Opportunity';
            setting1.DisableTrigger__c = TRUE;
            triggerList.add(setting1);
            insert triggerList;
            
            List<Account>accList = new List<Account>();
        accList.add(new account(name='test account',Type ='Distributor',AccountNumber='123456'));
        accList.add(new account(name='test account',AccountNumber='123456',RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId()
));
        insert accList;
            contact con=new contact(lastname='test contact',leadsource='web',
                                  email='testc@test.com',accountId=accList[0].id);
            insert con;
            accList[0].AdvocateHub__Referral_Source__c=con.id;
            update accList[0];
            //Create Rebate Entry
            List<Rebate_Table__c> rebateList=new List<Rebate_Table__c>();
            Rebate_Table__c rebate=new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Distributor Fee',
                Rebate_Deal_Type__c='All except MSP',
                Start_Date__c=system.Today()-10,
                End_Date__c=system.Today() + 180
            );
            rebateList.add(rebate);
            Rebate_Table__c rebate1=new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Distributor Fee',
                Rebate_Deal_Type__c='All except MSP',
                Start_Date__c=system.Today()-10
            );
            rebateList.add(rebate1);
            Rebate_Table__c rebate2=new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Velocity Partner Program Rebate'
            );
            rebateList.add(rebate2);
            insert rebateList;
            //insert new opportunity
            List<Opportunity> oppList=new List<Opportunity>();
            Opportunity oppy1=new Opportunity(
                                           Name='test Opportunity',
                                           AccountId=accList[0].id, 
                                           StageName='1 Discovery', 
                                           CloseDate=system.Today(),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install',
                               Distributor_Lookup__c=accList[0].id,
                                           Opportunity_Type__c='New Customer',
                               Opportunity_Sub_type__c = 'Regular',
                       Deal_Registration_Type__c = 'Partner Initiated Deal',
                                           Amount = 300000  ,
                                           Partner_Lookup__c=accList[1].id, 
                                           Primary_Competitor__c='Actifio'
                                           );
            oppList.add(oppy1);
        insert oppList;
                test.startTest();
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'Appliance'
                };
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        prodlist.add(pd);
        insert prodlist;
            
        Id pricebookId = Test.getStandardPricebookId();
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => accList[0].Id,
            'SBQQ__Opportunity2__c' => oppList[0].Id
        };
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppList[0].Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pricebookId;
        qt1.ApprovalStatus__c = 'Approved';
        insert qt1;
        
        
         oppList[0].Pricebook2Id = pricebookId;
        oppList[0].StageName = '4 Business Justification';
        oppList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppList[0].SBQQ__PrimaryQuote__c = qt1.Id;
        update oppList[0];

         Order od = new Order();
        od.Name='testOrder1';
        od.Status = 'Draft';
        od.Order_Status__c='Order Accepted';
        od.BookingStatus__c='Booking Failed';
        od.AccountId = accList[0].Id;
        od.OpportunityId = oppList[0].Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        od.ship_To_Name__c = accList[0].id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        od.SBQQ__Quote__c=qt1.id;
        //od.Hold_Code__c = 'Missing freight forwarder details';
        insert od;  
         
         Booking__c bkg=new Booking__c(
         Order__c=od.id,
         Opportunity__c=oppList[0].id,
         Account_Name__c=accList[0].id,
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
         );
         insert bkg;
         
         od.BookingStatus__c='Completed';
         update od;
         Set<Id> ordIdset=new Set<Id>();
         ordIdset.add(od.id);
         List<String> rebateListnew=new List<String>{'Distributor Fee','Velocity Partner Program Rebate'};
        //OrderService.createBLIforRebate(ordIdset,rebateListnew);
       test.stoptest();
    }*/
   /* public static testMethod void testBLIentriesMSP() {
        ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();
            setting.Name = 'System Administrator';
            setting.Disable_Opportunity_Old_Trigger__c = TRUE;
            setting.Disable_Order_Old_Trigger__c = TRUE;
            setting.Disable_Account_Old_Trigger__c = TRUE;
            insert setting;
        
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
            settingDisable.Name = 'System Administrator';
            settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;
            settingDisable.Disable_Order_Validation_Rules__c = TRUE;
            insert settingDisable;
            
            List<TriggerControl__c> triggerList=new List<TriggerControl__c>();
            TriggerControl__c setting0 = new TriggerControl__c();
            setting0.Name = 'Order';
            setting0.DisableTrigger__c = TRUE;
            triggerList.add(setting0);
            TriggerControl__c setting1 = new TriggerControl__c();
            setting1.Name = 'Opportunity';
            setting1.DisableTrigger__c = TRUE;
            triggerList.add(setting1);
            insert triggerList;
        //create account and contact to assign to opportunity
      List<Account>accList = new List<Account>();
        accList.add(new account(name='test account',AccountNumber='123456'));
        accList.add(new account(name='test account',AccountNumber='123456',RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId()
));
       insert accList;
        contact con=new contact(lastname='test contact',leadsource='web',
                                  email='testc@test.com',accountId=accList[0].id);
            insert con;
            accList[0].AdvocateHub__Referral_Source__c=con.id;
            update accList[0];
            //Create Rebate Entry
            List<Rebate_Table__c> rebateList=new List<Rebate_Table__c>();
            Rebate_Table__c rebate=new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Distributor Fee',
                Rebate_Deal_Type__c='MSP',
                Installation_Product__c ='ABC_InstallType',
                Value_Add_Distribution_fee__c = 3,
                Distributor_Installation_Fee__c= 8,
                Start_Date__c=system.Today()-10,
                End_Date__c=system.Today() + 180
            );
            rebateList.add(rebate);
            rebateList.add(new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Distributor Fee',
                Rebate_Deal_Type__c='ALL',
                Installation_Product__c ='ABC_InstallType',
                Value_Add_Distribution_fee__c = 3,
                Distributor_Installation_Fee__c= 8,
                Start_Date__c=system.Today()-10,
                End_Date__c=system.Today() + 180
            ));
            Rebate_Table__c rebate1=new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Distributor Fee',
                Rebate_Deal_Type__c='MSP',
                Start_Date__c=system.Today()-10
            );
            rebateList.add(rebate1);
            Rebate_Table__c rebate2=new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Velocity Partner Program Rebate'
            );
            rebateList.add(rebate2);
            insert rebateList;
            //insert new opportunity
            List<Opportunity> oppList=new List<Opportunity>();
            Opportunity oppy1=new Opportunity(
                                           Name='test Opportunity',
                                           AccountId=accList[0].id, 
                                           StageName='1 Discovery', 
                                           CloseDate=system.Today(),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install',
                                            //Distributor_Lookup__c=accList[0].id,
                                           Opportunity_Type__c='New Customer',
                               Opportunity_Sub_type__c = 'MSP',
                       Deal_Registration_Type__c = 'Partner Initiated Deal',
                                           Amount = 300000  ,
                                           Partner_Lookup__c=accList[1].id, 
                                           Primary_Competitor__c='Actifio'
                                           );
            oppList.add(oppy1);
        insert oppList;
                test.startTest();
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'Appliance'
                };
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);
                    pd.Family ='UCS'; 
                   prodlist.add((Product2)ShGl_TestFactory.createSObject(new Product2(), prodMap));   
        prodlist.add(pd);
        insert prodlist;
            
        Id pricebookId = Test.getStandardPricebookId();
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => accList[0].Id,
            'SBQQ__Opportunity2__c' => oppList[0].Id
        };
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppList[0].Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pricebookId;
        qt1.ApprovalStatus__c = 'Approved';
        insert qt1;
        
        
         oppList[0].Pricebook2Id = pricebookId;
        oppList[0].StageName = '4 Business Justification';
        oppList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppList[0].SBQQ__PrimaryQuote__c = qt1.Id;
        update oppList[0];

         Order od = new Order();
        od.Name='testOrder1';
        od.Status = 'Draft';
        od.Order_Status__c='Order Accepted';
        od.BookingStatus__c='Booking Failed';
        od.AccountId = accList[0].Id;
        od.OpportunityId = oppList[0].Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        od.ship_To_Name__c = accList[0].id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        od.SBQQ__Quote__c=qt1.id;
        //od.Hold_Code__c = 'Missing freight forwarder details';
        insert od;  
        PricebookEntry pbEntry = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = prodlist[0].Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            insert pbEntry;
        OrderItem OI = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA16240344007');
        insert OI;
         Booking__c bkg=new Booking__c(
         Order__c=od.id,
         Opportunity__c=oppList[0].id,
         Account_Name__c=accList[0].id,
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
         );
         insert bkg;
         
         od.BookingStatus__c='Completed';
         update od;
         Set<Id> ordIdset=new Set<Id>();
         ordIdset.add(od.id);
         List<String> rebateListnew=new List<String>{'Distributor Fee','Velocity Partner Program Rebate'};
        //OrderService.createBLIforRebate(ordIdset,rebateListnew);
       test.stoptest();
    }*/
    
   /* public static testMethod void testBLIentriesAll() {
        ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();
            setting.Name = 'System Administrator';
            setting.Disable_Opportunity_Old_Trigger__c = TRUE;
            setting.Disable_Order_Old_Trigger__c = TRUE;
            setting.Disable_Account_Old_Trigger__c = TRUE;
            insert setting;
        
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
            settingDisable.Name = 'System Administrator';
            settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;
            settingDisable.Disable_Order_Validation_Rules__c = TRUE;
            insert settingDisable;
            
            List<TriggerControl__c> triggerList=new List<TriggerControl__c>();
            TriggerControl__c setting0 = new TriggerControl__c();
            setting0.Name = 'Order';
            setting0.DisableTrigger__c = TRUE;
            triggerList.add(setting0);
            TriggerControl__c setting1 = new TriggerControl__c();
            setting1.Name = 'Opportunity';
            setting1.DisableTrigger__c = TRUE;
            triggerList.add(setting1);
            insert triggerList;
        //create account and contact to assign to opportunity
        List<Account>accList = new List<Account>();
        accList.add(new account(name='test account',AccountNumber='123456'));
        accList.add(new account(name='test account',AccountNumber='123456',RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId(),
         Focused_Partner__c=false ));
            insert accList;
        contact con=new contact(lastname='test contact',leadsource='web',
                                  email='testc@test.com',accountId=accList[0].id);
            insert con;
            accList[0].AdvocateHub__Referral_Source__c=con.id;
            update accList[0];
            //Create Rebate Entry
            List<Rebate_Table__c> rebateList=new List<Rebate_Table__c>();
            Rebate_Table__c rebate=new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Distributor Fee',
                Rebate_Deal_Type__c='All',
                Start_Date__c=system.Today()-10,
                End_Date__c=system.Today() + 180
            );
            rebateList.add(rebate);
            Rebate_Table__c rebate1=new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Distributor Fee',
                Rebate_Deal_Type__c='All',
                Start_Date__c=system.Today()-10
            );
            rebateList.add(rebate1);
            Rebate_Table__c rebate2=new Rebate_Table__c(
                Rebate__c = 10, ASPEN_Rebate__c = 8,
                Distributor__c = accList[0].id,
                Rebate_Type__c ='Velocity Partner Program Rebate'
            );
            rebateList.add(rebate2);
            insert rebateList;
            //insert new opportunity
            List<Opportunity> oppList=new List<Opportunity>();
            Opportunity oppy1=new Opportunity(
                                           Name='test Opportunity',
                                           AccountId=accList[0].id, 
                                           StageName='1 Discovery', 
                                           CloseDate=system.Today(),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install',
                                            //Distributor_Lookup__c=accList[0].id,
                                           Opportunity_Type__c='New Customer',
                               Opportunity_Sub_type__c = 'MSP',
                       Deal_Registration_Type__c = 'Partner Initiated Deal',
                                           Amount = 300000  ,
                                           Partner_Lookup__c=accList[1].id 
                                           );
            oppList.add(oppy1);
        insert oppList;
                test.startTest();
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'Appliance'
                };
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        prodlist.add(pd);
        insert prodlist;
            
        Id pricebookId = Test.getStandardPricebookId();
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => accList[0].Id,
            'SBQQ__Opportunity2__c' => oppList[0].Id
        };
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppList[0].Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pricebookId;
        qt1.ApprovalStatus__c = 'Approved';
        insert qt1;
        
        
         oppList[0].Pricebook2Id = pricebookId;
        oppList[0].StageName = '4 Business Justification';
        oppList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppList[0].SBQQ__PrimaryQuote__c = qt1.Id;
        oppList[0].Primary_Competitor__c='Actifio';
        update oppList[0];

         Order od = new Order();
        od.Name='testOrder1';
        od.Status = 'Draft';
        od.Order_Status__c='Order Accepted';
        od.BookingStatus__c='Booking Failed';
        od.AccountId = accList[0].Id;
        od.OpportunityId = oppList[0].Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        od.ship_To_Name__c = accList[0].id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        od.SBQQ__Quote__c=qt1.id;
        //od.Hold_Code__c = 'Missing freight forwarder details';
        insert od;  
         
         Booking__c bkg=new Booking__c(
         Order__c=od.id,
         Opportunity__c=oppList[0].id,
         Account_Name__c=accList[0].id,
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
         );
         insert bkg;
         
         od.BookingStatus__c='Completed';
         update od;
         Set<Id> ordIdset=new Set<Id>();
         ordIdset.add(od.id);
         List<String> rebateListnew=new List<String>{'Distributor Fee','Velocity Partner Program Rebate'};
        //OrderService.createBLIforRebate(ordIdset,rebateListnew);
       test.stoptest();
    }*/
    /*
    public static testMethod void testThirdPartyEntitlement() {
        //create account and contact to assign to opportunity
            ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();
            setting.Name = 'System Administrator';
            setting.Disable_Opportunity_Old_Trigger__c = TRUE;
            setting.Disable_Order_Old_Trigger__c = TRUE;
            setting.Disable_Account_Old_Trigger__c = TRUE;
            insert setting;
        
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
            settingDisable.Name = 'System Administrator';
            settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;
            settingDisable.Disable_Order_Validation_Rules__c = TRUE;
            insert settingDisable;
            
            List<TriggerControl__c> triggerList=new List<TriggerControl__c>();
            TriggerControl__c setting0 = new TriggerControl__c();
            setting0.Name = 'Order';
            setting0.DisableTrigger__c = TRUE;
            triggerList.add(setting0);
            TriggerControl__c setting1 = new TriggerControl__c();
            setting1.Name = 'Opportunity';
            setting1.DisableTrigger__c = TRUE;
            triggerList.add(setting1);
            
            TriggerControl__c setting2 = new TriggerControl__c();
            setting2.Name = 'Entitlement';
            setting2.DisableTrigger__c = TRUE;
            triggerList.add(setting2);
            insert triggerList;
            
            List<Account>accList = new List<Account>();
        accList.add(new account(name='test account',AccountNumber='123456'));
        accList.add(new account(name='test account',AccountNumber='123456',RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId()
));
        insert accList;
            contact con=new contact(lastname='test contact',leadsource='web',
                                  email='testc@test.com',accountId=accList[0].id);
            insert con;
            accList[0].AdvocateHub__Referral_Source__c=con.id;
            update accList[0];
            //insert new opportunity
            List<Opportunity> oppList=new List<Opportunity>();
            Opportunity oppy1=new Opportunity(
                                           Name='test Opportunity',
                                           AccountId=accList[0].id, 
                                           StageName='1 Discovery', 
                                           CloseDate=system.Today(),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install',
                               Distributor_Lookup__c=accList[0].id,
                                           Opportunity_Type__c='New Customer',
                               Opportunity_Sub_type__c = 'Regular',
                       Deal_Registration_Type__c = 'Partner Initiated Deal',
                                           Amount = 300000  ,
                                           Partner_Lookup__c=accList[1].id, 
                                           Primary_Competitor__c='Actifio'
                                           );
            oppList.add(oppy1);
        insert oppList;
                
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'UCS',
                'Product_Type__c' => '3rd Party Hardware'
                };
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        prodlist.add(pd);
        insert prodlist;
            
        Id pricebookId = Test.getStandardPricebookId();
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => accList[0].Id,
            'SBQQ__Opportunity2__c' => oppList[0].Id
        };
        
        PricebookEntry pbestandard = new PricebookEntry(Pricebook2Id=pricebookId , Product2Id=prodlist[0].Id, UnitPrice=99, isActive=true);
        insert new List<PricebookEntry>{pbestandard};
        
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppList[0].Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pricebookId;
        qt1.ApprovalStatus__c = 'Approved';
        insert qt1;
        
        
         oppList[0].Pricebook2Id = pricebookId;
        oppList[0].StageName = '4 Business Justification';
        oppList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppList[0].SBQQ__PrimaryQuote__c = qt1.Id;
        update oppList[0];

         Order od = new Order();
        od.Name='testOrder1';
        od.Status = 'Draft';
        
        od.BookingStatus__c='Booking Failed';
        od.AccountId = accList[0].Id;
        od.OpportunityId = oppList[0].Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        od.ship_To_Name__c = accList[0].id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        od.SBQQ__Quote__c=qt1.id;
        //od.Hold_Code__c = 'Missing freight forwarder details';
        insert od;  
        OrderItem oli1 = new OrderItem(

            OrderId = od.Id,
            Quantity = 5,
            PricebookEntryId = pbestandard.Id,
            UnitPrice = pbestandard.UnitPrice,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        insert oli1 ;
        setting0.DisableTrigger__c = False;
        update setting0;
         Test.startTest();
         od.Order_Status__c='Order Accepted';
         
         update od;

       test.stoptest();
    }
    */
    
}