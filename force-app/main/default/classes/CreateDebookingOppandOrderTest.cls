/**
* @description This is the Test class for CreateDebookingOppandOrder Apex Class
*/
@isTest
public class CreateDebookingOppandOrderTest {
    /**
    * @description This method creates the test data for test coverage 
    */
    @testSetup
    public static void setup() { 
        String uniqueUserName = 'CreateDebookingOppandOrderTest' + DateTime.now().getTime() + '@testclass.com';                      
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr=new user(alias = 'std', email='testuser@testclass.com.sandbox',
                          emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = p.Id,
                          timezonesidkey='America/Los_Angeles', username=uniqueUserName);
        
        System.runAs(usr){
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
            TriggerControl.stopOrderTrigger = true;
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
                                    email='testc@test.com.sandbox',accountId=acct.id);
            insert con;
            acct.AdvocateHub__Referral_Source__c=con.id;
            update acct;
            //insert new opportunity
            Opportunity oppty=new Opportunity(
                Name='Opportunity Created for Testing - Create Debooking Opportunity and Order',
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
            test.startTest();
            //Create your pricebook entry
            PricebookEntry pbEntry = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = prodlist[0].Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            insert pbEntry;
            
            od.Pricebook2Id = pricebookId;
            update od;
            OpportunityLineItem opptyLine = new OpportunityLineItem(product2Id = prodlist[0].Id,Line_Type_Text__c = 'New',pricebookentryid=pbEntry.Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppty.Id,Subsumed_Renewal_Amount__c = 1000,Subsumed_Renewal_TCV__c=1000);
            insert opptyLine;
            OrderItem oritem = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
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
            
            CCR__c cc=new CCR__C(
                Comment__c='test',
                Opportunity__c=oppty.id,
                AssignmentStatus__c='Unassigned',
                User__c='Approved',
                CCR_Type__c='Customer Returns / Refunds',   
                Return_Amount_Type__c = 'Partial', 
                Amount__c=100,
                booking__c=bkg.id,
                Account_Name__c=acct.id,
                Impacts_Commission__c = TRUE
                
            );
            insert cc;  
            Booking_AdjustmentItems__c ba=new Booking_AdjustmentItems__c(
                CCR__c=cc.id,
                OrderLineItemId__c=oritem.id,
                Quantity__c=1,
                Unit_Price__c = 10,
                Opportunity_Line_Item__c = opptyLine.Id
            );
            insert ba;
            
            cc.User__c='Approved';
            update cc;
            test.stoptest();
        }
    }
    
    /**
    * @description This method covers the CreateDebookingOppandOrder
    */
    public static testMethod void testOrderInsert1() {
        test.startTest();
        User usr=[select id from User where isActive = true AND email='testuser@testclass.com.sandbox' limit 1];
        system.runAs(usr){
            CCR__c ccrNew = [select id,Amount__c from CCR__c limit 1];
            
            List<Id> ccList=new List<Id>(); 
            ccList.add(ccrNew.id);
            CreateDebookingOPPandOrder controller = new CreateDebookingOPPandOrder(ccList);
            System.enqueueJob(controller);
            //CreateDebookingOPPandOrder.CreateNegativeOrder(ccList);
            system.assertEquals(controller.ccrIds, ccList );
        }
        test.stopTest();   
    }
}