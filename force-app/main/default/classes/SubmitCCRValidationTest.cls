@isTest
public class SubmitCCRValidationTest {
         @testSetup
        public static void setup() {   
            List<UserRole> rolesList=new List<UserRole>();
            for(integer i=0;i<5;i++){
                if(i==4){
                    UserRole vpRole=new UserRole(DeveloperName = 'VP', Name = 'VP'); 
                    rolesList.add(vpRole);
                }else{
                    UserRole role = new UserRole(DeveloperName = 'MyCustomRole'+i, Name = 'MyCustomRole'+i);
                    rolesList.add(role);
                }
            }
            insert rolesList;
            
            String uniqueUserName = 'SubmitCCRValidationTest' + DateTime.now().getTime() + '@testclass.com';           
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            List<User> userList=new List<User>();
            for(integer i=0;i<5;i++){
                if(i==4){
                    User vpUsr=new user(alias = 'std', email='testuser@testclass.com'+i,
                    emailencodingkey='UTF-8', firstname='test'+i, lastname='user'+i, languagelocalekey='en_US',
                    localesidkey='en_US', profileid = p.Id,
                    timezonesidkey='America/Los_Angeles', username=uniqueUserName+i,
                    UserRoleId = rolesList[i].Id);                    
                    userList.add(vpUsr);
                }else{
                User usr=new user(alias = 'std', email='testuser@testclass.com'+i,
                    emailencodingkey='UTF-8', firstname='test'+i, lastname='user'+i, languagelocalekey='en_US',
                    localesidkey='en_US', profileid = p.Id,
                    timezonesidkey='America/Los_Angeles', username=uniqueUserName+i,
                    UserRoleId = rolesList[i].Id);                    
                 userList.add(usr);
                }
            }
            insert userList;
            for(User us : userList){
                for(integer i=0;i<5;i++){
                    if(i != 4){
                        userList[i].ManagerId=userList[i+1].id;
                    }
                }
            }
            update userList;
            
            system.runAs(userList[0]){
            ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();
            setting.Name = 'System Administrator';
            setting.Disable_Opportunity_Old_Trigger__c = TRUE;
            setting.Disable_Order_Old_Trigger__c = TRUE;
            setting.Disable_Account_Old_Trigger__c = TRUE;
            insert setting;
            
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
            settingDisable.Name = 'System Administrator';
            settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;
            settingDisable.Disable_Opportunity_Triggers__c = TRUE;
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
            account acct1=new account(name='test account1',AccountNumber='1234561');
            insert acct1;
            contact con=new contact(lastname='test contact',leadsource='web',
                                  email='testc@test.com',accountId=acct.id);
            insert con;
            acct.AdvocateHub__Referral_Source__c=con.id;
            update acct;
            //insert new opportunity
            List<Opportunity> oppList=new List<Opportunity>();
            Opportunity opp=new Opportunity(
                                           Name='test Opportunity',
                                           AccountId=acct.id, 
                                           StageName='1 Discovery', 
                                           CloseDate=system.Today(),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install'
                                           );
            oppList.add(opp);
            Opportunity opp1=new Opportunity(
                                           Name='test Opportunity1',
                                           AccountId=acct1.id, 
                                           StageName='1 Discovery', 
                                           CloseDate=system.Today(),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install'
                                           );
            oppList.add(opp1);
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
                test.startTest();
        oppList[0].Pricebook2Id = pricebookId;
        oppList[0].StageName = '4 Business Justification';
        oppList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppList[0].SBQQ__PrimaryQuote__c = qt1.Id;
        update oppList[0];
        
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
         //update od;
         //system.debug('status-->'+od.Order_Status__c);
         od.Order_Status__c = 'Order Accepted';  
         od.SBQQ__Contracted__c = false;  
         od.Order_Accepted_By__c=userList[0].id;
         update od;
            
        Booking__c bkg=new Booking__c(
         Order__c=od.id,
         Opportunity__c=oppList[0].id,
         Account_Name__c=acct.id,
         status__c='Completed',
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
                                     );
        insert bkg;
       List<CCR__c> ccList=new List<CCR__c>();     
       CCR__c cc=new CCR__C(
           Comment__c='test',
           Opportunity__c=oppList[0].id,
           AssignmentStatus__c='Unassigned',
           User__c='Approved',
           CCR_Type__c='Customer Returns / Refunds', 
           Customer_Returns_Type__c = 'LineItem Based',   
           Amount__c=100,
           booking__c=bkg.id,
           Account_Name__c=acct.id,
           Impacts_Commission__c = TRUE,
           Affective_Person__c=userList[0].id,
           Return_Reasons__c='test',
           RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
       
       );
      ccList.add(cc);
      CCR__c cc1=new CCR__C(
           Comment__c='test',
           Opportunity__c=oppList[0].id,
           AssignmentStatus__c='Unassigned',
           User__c='Approved',
           CCR_Type__c='Partner Referral Fee',  
           Referral_Fee_Amount__c=100,
           Account_Name__c=acct.id,
           Impacts_Commission__c = TRUE,
           RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
      );
      ccList.add(cc1);
      CCR__c cc2=new CCR__C(
           Comment__c='test',
           Opportunity__c=oppList[1].id,
           AssignmentStatus__c='Unassigned',
           User__c='Approved',
           CCR_Type__c='Partner Referral Fee',  
           Referral_Fee_Amount__c=200,
           Account_Name__c=acct1.id,
           booking__c=bkg.id,
           Partner_Company_Name__c=acct.id,
           Impacts_Commission__c = TRUE,
                      RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
       );
      ccList.add(cc2);
      CCR__c cc3=new CCR__C(
           Comment__c='test',
           Opportunity__c=oppList[0].id,
           AssignmentStatus__c='Unassigned',
           User__c='Approved',
           CCR_Type__c='Customer Returns / Refunds', 
           Customer_Returns_Type__c ='LineItem Based',   
           Amount__c=500,
           booking__c=bkg.id,
           Account_Name__c=acct.id,
           Impacts_Commission__c = TRUE,
           Affective_Person__c=userList[0].id,
           Return_Reasons__c='test',
                      RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
       
       );
      ccList.add(cc3);
      CCR__c cc4=new CCR__C(
           Comment__c='test',
           Opportunity__c=oppList[0].id,
           AssignmentStatus__c='Unassigned',
           User__c='Approved',
           CCR_Type__c='Customer Returns / Refunds',    
           Amount__c=1000,
           booking__c=bkg.id,
           Account_Name__c=acct.id,
           Impacts_Commission__c = TRUE,
           Affective_Person__c=userList[0].id    ,
                      RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
   
       );
      ccList.add(cc4);   
      CCR__c cc5=new CCR__C(
           Comment__c='test',
           Opportunity__c=oppList[0].id,
           AssignmentStatus__c='Unassigned',
           User__c='Approved',
           CCR_Type__c='Customer Returns / Refunds',    
           Amount__c=1200,
           booking__c=bkg.id,
           Account_Name__c=acct.id,
           Impacts_Commission__c = TRUE,
           Affective_Person__c=userList[0].id,
           Return_Reasons__c='test',
                      RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()

       
       );
      ccList.add(cc5);
      insert ccList;
      List<Booking_AdjustmentItems__c>   baList=new List<Booking_AdjustmentItems__c>();    
      Booking_AdjustmentItems__c ba=new Booking_AdjustmentItems__c(
          CCR__c=ccList[0].id,
          OrderLineItemId__c=oritem.id,
          Quantity__c=1
      );
      baList.add(ba);
      Booking_AdjustmentItems__c ba1=new Booking_AdjustmentItems__c(
          CCR__c=ccList[4].id,
          OrderLineItemId__c=oritem.id,
          Quantity__c=1
      );
      baList.add(ba1);
      Booking_AdjustmentItems__c ba2=new Booking_AdjustmentItems__c(
          CCR__c=ccList[5].id,
          OrderLineItemId__c=oritem.id,
          Quantity__c=1
      );
      baList.add(ba2);
      insert baList;
      LCC_Submit_for_Approval_CCR_Controller.ccrApproval(ccList[0].Id);          
      test.stoptest();
            }
        }
      public static testMethod void testReturnsRefundCCR() {
         User usr=[Select id from User where alias ='std' limit 1];
          System.runAs(usr){
            test.startTest();          
                CCR__c ccrNew = [select id,Affective_Person__r.id from CCR__c where CCR_Type__c='Customer Returns / Refunds' limit 1];
              SubmitCCRValidation.ApprovalValidation(ccrNew.id);
            test.stopTest();
          }
   
      }
    public static testMethod void testPRFCCR() {
          User usr=[Select id from User where alias ='std' limit 1];
          System.runAs(usr){
            test.startTest();
                CCR__c ccrNew = [select id,Affective_Person__r.id from CCR__c where CCR_Type__c='Partner Referral Fee' limit 1];
                SubmitCCRValidation.ApprovalValidation(ccrNew.id);
            test.stopTest();
          }
      }
    public static testMethod void testPRFCCR1() {
        User usr=[Select id from User where alias ='std' limit 1];
        System.runAs(usr){
            test.startTest();
                CCR__c ccrNew = [select id,Affective_Person__r.id from CCR__c where CCR_Type__c='Partner Referral Fee' and Referral_Fee_Amount__c=200 limit 1];
                SubmitCCRValidation.ApprovalValidation(ccrNew.id);
            test.stopTest();
        }
      }
    public static testMethod void testReturnsRefundCCR1() {
        User usr=[Select id from User where alias ='std' limit 1];
        System.runAs(usr){
            test.startTest();
                CCR__c ccrNew = [select id,Affective_Person__r.id from CCR__c where CCR_Type__c='Customer Returns / Refunds' and Amount__c=500 limit 1];
                SubmitCCRValidation.ApprovalValidation(ccrNew.id);
            test.stopTest();
        }
      }
      public static testMethod void testReturnsRefundCCR2() {
          User usr=[Select id from User where alias ='std' limit 1];
          System.runAs(usr){
            test.startTest();
                CCR__c ccrNew = [select id,Affective_Person__r.id from CCR__c where CCR_Type__c='Customer Returns / Refunds' and Amount__c=1000 limit 1];
                SubmitCCRValidation.ApprovalValidation(ccrNew.id);
            test.stopTest();
          }
      }
      public static testMethod void testAffectivePerson(){
         List<User> usrList = [Select id,email from User where alias ='std'];
          System.runAs(usrList[0]){
         for(User usr : usrList){
            SubmitCCRValidation.getVPManager(usr.id);   
         }
      }
     } 
}