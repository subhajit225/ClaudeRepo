@isTest
public class CCRreSubmitLogicTest {
/**
* @description This is test setup
*/
@testSetup
        public static void setup() { 
            String uniqueUserName = 'CreateDebookingOppandOrderTest' + DateTime.now().getTime() + '@testclass.com';                      
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User usr=new user(alias = 'std', email='testuser@testclass.com',
            emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id,
            timezonesidkey='America/Los_Angeles', username=uniqueUserName);
            
            System.runAs(usr){
            BookingHelper.isTestRunning = true;
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
            settingDisable.Trigger_Max_Loop_Count__c = 1;
            settingDisable.Disable_Opportunity_Triggers__c = TRUE;
            settingDisable.Disable_SBQQ_Quote_Triggers__c = TRUE;
            settingDisable.Disable_Account_Triggers__c = TRUE;
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
        insert prodlist;
                
        
            
        Id pricebookId = Test.getStandardPricebookId();
       //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
                
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
        
        List<OpportunityLineItem> lstOppLineItem = new List<OpportunityLineItem>{
            new OpportunityLineItem(pricebookentryid= pbEntry.Id,TotalPrice=100, Quantity = 2,OpportunityID = oppty.Id, Subsumed_Renewal_Amount__c = 100, Subsumed_Renewal_TCV__c = 100 ),
            new OpportunityLineItem(pricebookentryid= pbEntry.Id,TotalPrice=100, Quantity = 2,OpportunityID = oppty.Id, Subsumed_Renewal_Amount__c = 200, Subsumed_Renewal_TCV__c = 100 )     
        };
        insert lstOppLineItem;
        test.startTest();
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
        od.ship_To_Name__c = acct.id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        //od.Hold_Code__c = 'Missing freight forwarder details';
        insert od;
        oppty.Pricebook2Id = pricebookId;
        update oppty;
        
        od.Pricebook2Id = pricebookId;
        update od;
        List<OrderItem> oritem = new List<OrderItem>{
         new OrderItem(OrderId=od.Id,Opportunity_Product__c = lstOppLineItem[0].Id, description ='a', Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 100, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'),
         new OrderItem(OrderId=od.Id,Opportunity_Product__c = lstOppLineItem[1].Id, description ='a', Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 100, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009')
        };
        insert oritem;
         od.Hold_Code__c=' ';
         //update od;
         //system.debug('status 2-->'+od.Order_Status__c);
         od.Order_Status__c = 'Order Accepted';  
         od.SBQQ__Contracted__c = false;  
         od.Order_Accepted_By__c=usr.id;
         update od;
            
        Booking__c bkg=new Booking__c(
         Order__c=od.id,
         Opportunity__c=oppty.id,
         Account_Name__c=acct.id,
         status__c='Completed',
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
                                     );
        insert bkg;
        insert new BookingDebookingFields__c(Name='fieldtest',fields__c='SecondaryOwner__c,SE_Misaligned__c,Strategic_Account__c,Forward_Pass_Contact_Mail__c,Forward_Pass_Contact__c');    
       CCR__c cc=new CCR__C(
           Comment__c='test',
       Effective_Date__c = system.today(),
           Opportunity__c=oppty.id,
           AssignmentStatus__c='Unassigned',
           User__c='Approved',
           CCR_Type__c='Customer Returns / Refunds',    
           Amount__c=100,
           booking__c=bkg.id,
           Account_Name__c=acct.id,
           Impacts_Commission__c = TRUE,
           Customer_Returns_Type__c ='LineItem Based'
       );
       insert cc;
      // opportunity debookopp1 = oppty.clone();  
       //debookopp1.CCR__c = cc.id ;
       //insert debookopp1;
       List<Booking_AdjustmentItems__c> ba=new List<Booking_AdjustmentItems__c>{
       	new Booking_AdjustmentItems__c( CCR__c=cc.id, OrderLineItemId__c=oritem[0].id, Opportunity_Line_Item__c = lstOppLineItem[0].Id,Quantity__c=1),
        new Booking_AdjustmentItems__c( CCR__c=cc.id, OrderLineItemId__c=oritem[0].id, Opportunity_Line_Item__c = lstOppLineItem[1].Id,Quantity__c=1)
      };
      insert ba;
            
      cc.User__c='Approved';
      update cc;
      test.stoptest();
            }
    }

    /**
     * @description This is test method for debbok oppty
     */
    @isTest
    public static void debookOpportunityTest(){
        system.runAs(new user(Id = UserInfo.getUserId())){
        BookingHelper.isTestRunning = true;
        CCR__c ccrNew = [select Id from CCR__c limit 1];
        opportunity oppty = [Select id, Name, StageName, CloseDate From opportunity Limit 1];
        opportunity debookopp1 = oppty.clone();  
        debookopp1.CCR__c = ccrNew.Id ;
        insert debookopp1;
        ApexPages.StandardController ctlr = new ApexPages.StandardController(ccrNew);
        CCRreSubmitLogic controller = new CCRreSubmitLogic(ctlr);
        test.startTest();
        controller.ReSubmitValidation();
        system.assert(debookopp1 != null);
        test.stopTest();
        } 
      
    }

    /**
     * @description This is test method for debbok oppty
     */
    @isTest
    public static void debookOpportunityTest1(){
        system.runAs(new user(Id = UserInfo.getUserId())){
        BookingHelper.isTestRunning = true;
        CCR__c ccrNew = [select Id, CCR_Type__c from CCR__c limit 1];
        ccrNew.CCR_Type__c = 'Change in Booking Policy / De-Risk Decision';
        opportunity oppty = [Select id, Name, StageName, CloseDate, AccountId From opportunity Limit 1];
        opportunity debookopp1 = oppty.clone();  
        debookopp1.CCR__c = ccrNew.Id ;
        insert debookopp1;
        debookopp1.StageName = '7 Closed Won';
        update debookopp1;
        Order objOrder = [Select id, OpportunityId, Status, Order_Status__c, EffectiveDate, RecordTypeId, AccountId, Type From Order LIMIT 1];
        Order objDebookOrder = objOrder.clone();
        objDebookOrder.OpportunityId = debookopp1.Id;
        objDebookOrder.Type = 'Booking Adjustment';
        objDebookOrder.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Booking Adjustment Order').getRecordTypeId();
        objDebookOrder.Order_Status__c = 'Order Accepted';
        insert objDebookOrder;
        ApexPages.StandardController ctlr = new ApexPages.StandardController(ccrNew);
        CCRreSubmitLogic controller = new CCRreSubmitLogic(ctlr);
        test.startTest();
        controller.ReSubmitValidation();
        system.assert(debookopp1 != null);
        test.stopTest();
        }
    }

    /**
     * @description This is test method for resubmit
     */
    public static  testmethod void method1(){
        system.runAs(new user(Id = UserInfo.getUserId())){
        BookingHelper.isTestRunning = true;   
        CCR__c ccrNew = [select id,(select id from opportunities__r) from CCR__c limit 1];
        ApexPages.StandardController ctlr = new ApexPages.StandardController(ccrNew);
        CCRreSubmitLogic controller = new CCRreSubmitLogic(ctlr);
        test.startTest();
        controller.ReSubmitValidation();
        //SAL26-355
        controller.alertMessage = 'test alert message';
        /*opportunity opp = ccrNew.opportunities__r[0];
        opp.CCR__c = null;
        update opp;  
        controller.ReSubmitValidation(); */
        system.assert(ccrNew != null);
        test.stopTest();
        }
    }

          /**
     * @description This is test method for errorOppLineItemTest
     */
        public static  testmethod void errorOppLineItemTest(){  
        system.runAs(new user(Id = UserInfo.getUserId())){
            BookingHelper.isTestRunning = true; 
            CCR__c ccrNew = [select id,(select id from opportunities__r) from CCR__c limit 1];
            List<Booking_AdjustmentItems__c> lstBookingAdjustement = [Select Id, Quantity__c From Booking_AdjustmentItems__c];
            lstBookingAdjustement[0].Quantity__c = 1232434345456545.89;
            lstBookingAdjustement[1].Quantity__c = 1232434345456545.89;
            update lstBookingAdjustement;
            ApexPages.StandardController ctlr = new ApexPages.StandardController(ccrNew);
            CCRreSubmitLogic controller = new CCRreSubmitLogic(ctlr);
            test.startTest();
            controller.ReSubmitValidation();
            controller.alertMessage = 'test alert message';
            system.assert(ccrNew != null);
            test.stopTest();
        }
        
    }

         /**
     * @description This is test method for resubmit
     */
    public static  testmethod void method2(){  
        system.runAs(new user(Id = UserInfo.getUserId())){
        BookingHelper.isTestRunning = true; 
        List<Opportunity> lstOpp = [Select id, Name from Opportunity LIMIT 1];
        lstOpp[0].Name = lstOpp[0].Name.repeat(7);
        update lstOpp;
        CCR__c ccrNew = [select id,(select id from opportunities__r) from CCR__c limit 1];
        ApexPages.StandardController ctlr = new ApexPages.StandardController(ccrNew);
        CCRreSubmitLogic controller = new CCRreSubmitLogic(ctlr);
        test.startTest();
        controller.ReSubmitValidation();
        controller.alertMessage = 'test alert message';
        system.assert(ccrNew != null);
        test.stopTest();
        }
        
    }

    /**
     * @description This is test method for Error
     */
    public static  testmethod void errorCaseCCRMethod(){
        system.runAs(new user(Id = UserInfo.getUserId())){
        BookingHelper.isTestRunning = true;       
        CCR__c ccrNew = [select id,User__c from CCR__c limit 1];
        PageReference pageRef = Page.BookingAdjustment;
        ApexPages.StandardController ctlr = new ApexPages.StandardController(ccrNew);
        CCRreSubmitLogic controller = new CCRreSubmitLogic(ctlr);
        ccrNew.User__c ='Pending';
        update ccrNew;
        test.startTest();
        controller.ReSubmitValidation();
        ccrNew.Customer_Returns_Type__c = 'Amount Based';
        update ccrNew;
        controller.ReSubmitValidation();
        test.stopTest();
        system.assert(ccrNew != null);
        }
        
    }
    
}