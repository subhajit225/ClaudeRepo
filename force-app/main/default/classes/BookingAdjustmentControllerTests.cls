@isTest
public class BookingAdjustmentControllerTests {

    public static testMethod void testMyController() {         
        //create user
        String uniqueUserName = 'BookingAdjustmentControllerTests' + DateTime.now().getTime() + '@testclass.com';           
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u=new user(alias = 'std', email='testuser@testclass.com',
            emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id,
            timezonesidkey='America/Los_Angeles', username=uniqueUserName);
        
        System.runAs(u) {
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
            account acct=new account(name='test account',AccountNumber='123456');
            insert acct;
            contact con=new contact(lastname='test contact',leadsource='web',
                                  email='testc@test.com',accountId=acct.id);
            insert con;
            acct.AdvocateHub__Referral_Source__c=con.id;
            update acct;
            //insert new opportunity
            Opportunity oppty=new Opportunity(
                                           Name='test Opportunity',
                                           AccountId=acct.id, 
                                           StageName='1 Discovery', 
                                           CloseDate=system.Today(),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install'
                                           );
            insert oppty;

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
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'GPS'
                };
                    Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);  
        //prodlist.add(pd2);
        Map<String, Object>  prodMap3 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'RADAR'
                };
                    Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3);  
        //prodlist.add(pd3);
        insert prodlist;
        Id pricebookId = Test.getStandardPricebookId();
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => acct.Id,
            'SBQQ__Opportunity2__c' => oppty.Id
        };
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppty.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pricebookId;
        qt1.ApprovalStatus__c = 'Approved';
        insert qt1;
        
        oppty.Pricebook2Id = pricebookId;
        oppty.StageName = '4 Business Justification';
        oppty.Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        update oppty;
        List<order>OrdList = new List<Order>();
        Order od = new Order();
        od.Name='testOrder1';
        od.Status = 'Draft';
        od.Order_Status__c='Pending';
        //od.BookingStatus__c='None';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        //od.Hold_Code__c = 'Missing freight forwarder details';
        //insert od;
        OrdList.add(od);
        OrdList.add(od.clone(false, false, false, false));
        if(OrdList.size()>0)
        insert OrdList ;
        
       
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        OrdList[0].Pricebook2Id = pricebookId;
        update od;
        List<OrderItem>OrdItems = new List<OrderItem>();
        OrdItems.add(new OrderItem(OrderId=OrdList[0].Id, Quantity=1, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'));
        OrdItems.add(new OrderItem(OrderId=OrdList[0].Id, Quantity=2, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008'));
         insert OrdItems;
         system.debug('status 1-->'+OrdList[0].Order_Status__c);
         OrdList[0].Hold_Code__c=' ';
         update od;
         system.debug('status 2-->'+OrdList[0].Order_Status__c);
         OrdList[0].Order_Status__c = 'Shipped';  
         OrdList[0].SBQQ__Contracted__c = false;  
         update OrdList[0];
           Booking__c Booking = new Booking__c(Order__c = OrdList[0].id, Opportunity__c =oppty.id, Account_Name__c=acct.id);
            insert Booking;
      

        PageReference pageRef = Page.BookingAdjustment;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',Booking.id);
        ApexPages.currentPage().getParameters().put('ordId',OrdList[0].id);
      
        BookingAdjustmentController controller = new BookingAdjustmentController();
        controller.getAdjustmentType();
        controller.SelectedAType ='Change in Booking Policy / De-Risk Decision';
        controller.TypeSelected();
        //controller.CreateCCR();
        controller.SelectedAType ='Customer Returns / Refunds';
        
        
        controller.TypeSelected();
        controller.OrderLineItems[1].Quantity = 10;
        controller.SelectedRowIndex = 0;
        
        controller.OrderLineItems[0].Selected = true;
        controller.OrderLineItems[1].Selected = true;
        system.debug('cp OrderLineItems'+controller.OrderLineItems);
        controller.CheckQuantity();
        //controller.CreateCCR();
        
        controller.OrderLineItems[1].Quantity = 1;
        //controller.CreateCCR();
        controller.Cancel();
        controller.SelectedAType ='Partner Referrals';
        controller.TypeSelected();
        
        //error case
        
        /*controller.CheckQuantity();
        controller.CreateCCR(); */
        
        ApexPages.currentPage().getParameters().put('ordId',OrdList[1].id);
        controller.SelectedAType ='Customer Returns / Refunds';
        system.debug('check2 params'+ApexPages.currentPage().getParameters());
        controller.TypeSelected();
    }
    }
}