@isTest
public class UpdateHistoricalBookingBatchTest {
         @testSetup
         public static void setup() {  
          String uniqueUserName = 'BookingSyncBatchTest' + DateTime.now().getTime() + '@testclass.com';                               
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User usr=new user(alias = 'std', email='testuser@testclass.com',
            emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id,
            timezonesidkey='America/Los_Angeles', username=uniqueUserName);
            system.runAs(usr){
            
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
            setting2.Name = 'Booking';
            setting2.DisableTrigger__c = TRUE;
            triggerList.add(setting2);
            TriggerControl__c setting3 = new TriggerControl__c();
            setting3.Name = 'BookingAudit';
            setting3.DisableTrigger__c = TRUE;
            triggerList.add(setting3);
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
            List<Opportunity> oppList=new List<Opportunity>();
            Opportunity oppy1=new Opportunity(
                                           Name='test Opportunity',
                                           AccountId=acct.id, 
                                           StageName='1 Discovery', 
                                           CloseDate=Date.newInstance(2020, 01, 10),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install'
                                           );
            oppList.add(oppy1);
            Opportunity oppy2 =new Opportunity(
                                           Name='test Opportunity1',
                                           AccountId=acct.id, 
                                           StageName='1 Discovery', 
                                           CloseDate=system.Today(),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install'
                                           );
         oppList.add(oppy2);  
        insert oppList;
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
        test.startTest();
        Order od = new Order();
        od.Name='testOrder1';
        od.Status = 'Draft';
        od.Order_Status__c='Pending';
        //od.BookingStatus__c='None';
        od.AccountId = acct.Id;
        od.OpportunityId = oppList[0].Id;
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
        Order od1 = od.Clone();
        od1.OpportunityId = oppList[1].Id;
        insert od1;
        
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
        OrderItem oritem = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        insert oritem;
         od.Hold_Code__c=' ';
         od.Order_Status__c = 'Order Accepted';  
         od.SBQQ__Contracted__c = false;  
         od.Order_Accepted_By__c=usr.id;
         update od;
         
         List<Booking__c> bkgList=new List<Booking__c>();
         Booking__c bkg=new Booking__c(
         Order__c=od.id,
         Opportunity__c=oppList[0].id,
         Account_Name__c=acct.id,
         Field_Update_Status__c=' ',
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
                                     );
         insert bkg;
                
         Booking__c bkg1=bkg.clone();
         bkg1.Original_Booking__c=bkg.id;
         bkgList.add(bkg1);
         insert bkgList;
         //insert bkgList;
         
        oppList[0].closeDate=system.Today().addDays(5);            
       test.stoptest();                        
            }
         }
             public static testMethod void testBookingMethod() {
            Booking__c bkg=[SELECT id from Booking__c where Original_Booking__c=NULL LIMIT 1 ];
            test.startTest();                
                UpdateHistoricalBookingBatch uhbb=new UpdateHistoricalBookingBatch();
                ID batchprocessid=database.executeBatch(uhbb); 
            test.stopTest();   
          }
         
         }