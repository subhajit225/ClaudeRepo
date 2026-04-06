/**
 * @description This method covers the code for BookingAdjustmentController
 */

 @isTest
 public class BookingAdjustmentControllerTest {
 
     /**
      * @description This method sets the effective date
      */
     @testSetup
     public static void setup() {
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
         TriggerControls.disableQuoteTrigger = true;
 
         String uniqueUserName = 'BookingAdjustmentControllerTest' + DateTime.now().getTime() + '@testclass.com';
         Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
         User u=new user(alias = 'std', email='testuser@testclass.com',
             emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
             localesidkey='en_US', profileid = p.Id,
             timezonesidkey='America/Los_Angeles', username=uniqueUserName);
 
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
             ForecastCategoryName='Omitted',
             Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
             Installation_Assigned_To__c='FE Install'
         );
         insert oppty;
 
         list<Product2> prodlist = new list<Product2>();
         Map<String, Object> prodMap = new Map<String, Object> {
             'Name' => 'Pord A',
             'ProductCode' => 'ProductXYZ',
             'isActive' => true,
             'Family' => 'AIR',
             'Product_Type__c' => 'Appliance'
         };
         Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);
         prodlist.add(pd);
         Map<String, Object> prodMap2 = new Map<String, Object> {
             'Name' => 'Pord A',
             'ProductCode' => 'ProductXYZ',
             'isActive' => true,
             'Family' => 'AIR',
             'Product_Type__c' => 'GPS'
         };
         Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);
         //prodlist.add(pd2);
         Map<String, Object> prodMap3 = new Map<String, Object> {
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
         Map<String, Object> quoteMap = new Map<String, Object> {
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
         test.startTest();
         List<order>OrdList = new List<Order>();
         Order ord = new Order(Status='Draft',Order_Status__c='Pending',AccountId = acct.Id,OpportunityId = oppty.Id,EffectiveDate = Date.Today(),
             RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId(),Pricebook2Id = pricebookId);
         OrdList.add(ord);
         //OrdList.add(ord.clone(false, false, false, false));
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
 
         List<OrderItem>OrdItems = new List<OrderItem>();
         OrdItems.add(new OrderItem(OrderId=OrdList[0].Id, Quantity=1, PricebookEntryId=pbEntry.Id, UnitPrice = 100, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'));
         OrdItems.add(new OrderItem(OrderId=OrdList[0].Id, Quantity=2, PricebookEntryId=pbEntry.Id, UnitPrice = 150, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008'));
         insert OrdItems;
         system.debug(logginglevel.DEBUG,'status 1-->' + OrdList[0].Order_Status__c);
         //OrdList[0].Hold_Code__c=' ';
         //update od;
         system.debug(logginglevel.DEBUG,'status 2-->' + OrdList[0].Order_Status__c);
         OrdList[0].Order_Status__c = 'Shipped';
         OrdList[0].SBQQ__Contracted__c = false;
         update OrdList[0];
         Booking__c Booking = new Booking__c(Order__c = OrdList[0].id, Account_Name__c=acct.id,
             Opportunity__c=oppty.id,
             recordtypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
         );
         insert Booking;
 
         /* Approval Process scenario */
         CCR__c CCRWithNoAdj = new CCR__c(
             Comment__c='test',
             Opportunity__c=oppty.id,
             AssignmentStatus__c='Unassigned',
             User__c='Pending',
             CCR_Type__c='Customer Returns / Refunds',
             Amount__c=100,
             Account_Name__c=acct.id,
             Impacts_Commission__c = TRUE,
             Effective_Date__c=System.today(),
             Effective_End_Date__c=System.today(),
             Booking__c = Booking.Id,
             recordtypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId());
         insert CCRWithNoAdj ;
 
         Booking_AdjustmentItems__c bkgAdjLine = new Booking_AdjustmentItems__c(CCR__c = CCRWithNoAdj.Id,OrderLineItemId__c = OrdItems[0].Id,
             Adjusted_Item_Total_Price__c = 1 );
         insert bkgAdjLine;
         test.stopTest();
     }
     
     /**
      * @description This method covers the code for BookingAdjustmentController
      */
     public static testMethod void testMyController() {
         System.runAs(new User(Id=UserInfo.getUserId())) {
             test.startTest();
             CCR__c CCRWithNoAdj=[select id from CCR__c limit 1];
             Booking__C Booking=[select id from Booking__c limit 1];
             List<Order> OrdList = [select id,(select id from orderItems) from Order];
             SubmitCCRValidation.ApprovalValidation(CCRWithNoAdj.id);
 
             PageReference pageRef = Page.BookingAdjustment;
             Test.setCurrentPage(pageRef);
             ApexPages.currentPage().getParameters().put('id',Booking.id);
             ApexPages.currentPage().getParameters().put('ordId',OrdList[0].id);
             ApexPages.currentPage().getParameters().put('effDate',string.valueof(System.today()));
             BookingAdjustmentController controller = new BookingAdjustmentController();
             System.assertEquals(false, controller.displayLineItem, 'displayLineItem should be false initially');
             controller.getAdjustmentType();
             controller.getReturnsAmountType();
             controller.SelectedAType ='Change in Booking Policy / De-Risk Decision';
             controller.setDate();
             controller.TypeSelected();
             controller.createUpdateCCR();
 
             controller.SelectedAType ='Customer Returns / Refunds';
             controller.TypeSelected();
             controller.getReturnsType();
             controller.selectedReturnType ='Amount Based';
             controller.returnTypeSelected();
             controller.createUpdateCCR();
             controller.selectedReturnType ='LineItem Based';
             controller.returnTypeSelected();
             controller.returnAmountTypeSelected();
             controller.OrderLineItems[0].Selected = true;
             controller.OrderLineItems[1].Selected = true;
             controller.createUpdateCCR();
             CCR__c customerreturnCCR = [select id from ccr__c where CCR_Type__c='Customer Returns / Refunds' order by createddate desc limit 1];
             ApexPages.currentPage().getParameters().put('CCRId',customerreturnCCR.id);
             controller.OrderLineItems[1].Quantity = 10;
             controller.SelectedRowIndex = 0 ;
             controller.CheckQuantity();
             controller.createUpdateCCR();
             controller.OrderLineItems[1].Quantity = 1;
             controller.createUpdateCCR();
             controller.OrderLineItems[1].debookAmount = controller.OrderLineItems[1].remainingDebookAmount+100;
             controller.calculateTotalPrice();
             controller.createUpdateCCR();
             controller.OrderLineItems[1].debookAmount = controller.OrderLineItems[1].remainingDebookAmount;
             controller.selectedReturnAmountType = 'Partial';
             controller.calculateTotalPrice();
             controller.createUpdateCCR();
             controller.cancel();
             controller.selectedReturnAmountType = 'Complete';
             controller.calculateTotalPrice();
             controller.SelectedAType = Label.PartnerReferrals;
             controller.CRRAmount = 100;
             controller.TypeSelected();
             controller.createUpdateCCR();
             controller.effectiveDate = null;
             controller.createUpdateCCR();
             controller.effectiveDate = String.valueOf(System.today());
             controller.createUpdateCCR();

             PageReference pageRef1 = Page.BookingAdjustment;
             Test.setCurrentPage(pageRef1);
             ApexPages.currentPage().getParameters().put('CCRId',CCRWithNoAdj.id);
             test.stoptest();
         }
     }
 
     /**
      * @description This method covers the code for BookingAdjustmentController
      */
     @isTest
     public static void testCreateDeleteCCR() {
         System.runAs(new User(Id=UserInfo.getUserId())) {
             test.startTest();
             
             Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
             Order ord = [SELECT Id, TotalAmount, OpportunityId, AccountId, Opportunity.OwnerId FROM Order LIMIT 1];
             List<OrderItem> orderItems = [SELECT Id, UnitPrice, Quantity, TotalPrice FROM OrderItem WHERE OrderId = :ord.Id];
             Product2 prod = [SELECT Id, Name FROM Product2 LIMIT 1];
 
             CCR__c existingCCR = new CCR__c(
                 Comment__c='Existing CCR for update test',
                 Opportunity__c=ord.OpportunityId,
                 AssignmentStatus__c='Unassigned',
                 User__c='Pending',
                 CCR_Type__c='Customer Returns / Refunds',
                 Amount__c=10.00,
                 Account_Name__c=ord.AccountId,
                 Impacts_Commission__c = TRUE,
                 Effective_Date__c=System.today(),
                 Effective_End_Date__c=System.today(),
                 Booking__c = booking.Id,
                 recordtypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
             );
             insert existingCCR;
 
             Booking_AdjustmentItems__c adjItemToUpdate = new Booking_AdjustmentItems__c(
                 CCR__c = existingCCR.Id,
                 OrderLineItemId__c = orderItems[0].Id,
                 Adjusted_Item_Total_Price__c = 10.00,
                 Quantity__c = 1
             );
             insert adjItemToUpdate;
 
             Booking_AdjustmentItems__c adjItemToDelete = new Booking_AdjustmentItems__c(
                 CCR__c = existingCCR.Id,
                 OrderLineItemId__c = orderItems[1].Id,
                 Adjusted_Item_Total_Price__c = 20.00,
                 Quantity__c = 1
             );
             insert adjItemToDelete;
 
             PageReference pageRef = Page.BookingAdjustment;
             Test.setCurrentPage(pageRef);
             ApexPages.currentPage().getParameters().put('id', booking.Id);
             ApexPages.currentPage().getParameters().put('ordId', ord.Id);
             ApexPages.currentPage().getParameters().put('effDate', String.valueOf(System.today()));
             ApexPages.currentPage().getParameters().put('CCRId', existingCCR.Id);
 
             BookingAdjustmentController controller = new BookingAdjustmentController();
             System.assertEquals(true, controller.displayLineItem, 'displayLineItem should be true initially');
             controller.SelectedAType = 'Customer Returns / Refunds';
             controller.selectedReturnType = 'LineItem Based';
             controller.returnTypeSelected();
             controller.cancel();
             controller.updateadjustments = true;
 
             controller.OrderLineItems[0].Selected = true;
             controller.OrderLineItems[0].quantity = 1;
             controller.OrderLineItems[0].debookAmount = null;
             controller.OrderLineItems[0].totalUnitPrice = orderItems[0].UnitPrice;
             controller.OrderLineItems[0].totalPrice = orderItems[0].TotalPrice;
 
             controller.OrderLineItems[1].Selected = false;
 
             controller.AddedAdjustments = new Map<Id, Booking_AdjustmentItems__c>();
             controller.AddedAdjustments.put(orderItems[0].Id, adjItemToUpdate);
             controller.AddedAdjustments.put(orderItems[1].Id, adjItemToDelete);
 
             PageReference result = controller.createUpdateCCR();
             test.stopTest();
         }
     }
     /**
      * @description This method covers the code for BookingAdjustmentController
      */
     public static testMethod void testControllerException() {
         System.runAs(new User(Id=UserInfo.getUserId())) {
             test.startTest();
             CCR__c CCRWithNoAdj=[select id from CCR__c limit 1];
             Booking__C Booking=[select id from Booking__c limit 1];
             List<Order> OrdList = [select id,(select id from orderItems) from Order];
             SubmitCCRValidation.ApprovalValidation(CCRWithNoAdj.id);
             
             PageReference pageRef = Page.BookingAdjustment;
             Test.setCurrentPage(pageRef);
             BookingAdjustmentController controller = new BookingAdjustmentController();
             controller.selectedReturnType = 'LineItem Based';
             controller.returnTypeSelected();
             controller.createUpdateCCR(); 
             ApexPages.currentPage().getParameters().put('id',Booking.id);
             ApexPages.currentPage().getParameters().put('ordId',OrdList[0].id);
             ApexPages.currentPage().getParameters().put('effDate',string.valueof(System.today()));
             controller = new BookingAdjustmentController();
             System.assertEquals(false, controller.displayLineItem, 'displayLineItem should be false initially');
             delete OrdList[0].OrderItems;
             controller.returnTypeSelected();
             test.stopTest();
         }
     }
 }