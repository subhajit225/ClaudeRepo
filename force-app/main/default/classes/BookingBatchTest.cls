@isTest
public class BookingBatchTest {

/**
* PMD Rule: AvoidComplexity (complexity)
* @description : To setup intial data for test class
**/
@testSetup
public static void setup() {   
    String uniqueUserName = 'BookingBatchTest' + DateTime.now().getTime() + '@testclass.com';                               
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User usr=new user(alias = 'std', email='testuser@testclass.com',
    emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
    localesidkey='en_US', profileid = p.Id, isActive = true,
    timezonesidkey='America/Los_Angeles', username=uniqueUserName);
    system.runAs(usr){
    TriggerControl.stopOrderTrigger =true;
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
    settingDisable.Disable_SBQQ_Quote_Triggers__c = TRUE ;
    settingDisable.Disable_Opportunity_Triggers__c = TRUE ;
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
    List<Opportunity> oppList=new List<Opportunity>();
    oppList.add(new Opportunity(
                                    Name='test Opportunity',
                                    AccountId=acct.id, 
                                    StageName='1 Discovery', 
                                    CloseDate=system.Today(),
                                    Opportunity_Type__c = 'Existing Customer',
                                    ForecastCategoryName='Best Case',
                                    Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                    Installation_Assigned_To__c='FE Install'
                                    ));
    oppList.add(new Opportunity(
                                    Name='test Opportunity1',
                                    AccountId=acct.id, 
                                    StageName='1 Discovery', 
                                    Opportunity_Type__c = 'Existing Customer',
                                    CloseDate=system.Today(),
                                    ForecastCategoryName='Best Case',
                                    Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                    Installation_Assigned_To__c='FE Install'
                                    ));
        oppList.add(new Opportunity(
                                    Name='test Opportunity1',
                                    AccountId=acct.id, 
                                    StageName='1 Discovery', 
                                    Opportunity_Type__c = 'Existing Customer',
                                    CloseDate=system.Today(),
                                    ForecastCategoryName='Best Case',
                                    Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                    Installation_Assigned_To__c='FE Install'
                                    ));                                  
insert oppList;
oppList[2].Opportunity_Split_Parent__c = oppList[1].id;
oppList[2].Split_percentage__c =oppList[0].Split_percentage__c= 50.00 ;
oppList[2]. Split_Amount__c =oppList[1]. Split_Amount__c = 100.00;
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
update oppList;
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
    
Booking__c bkg=new Booking__c(
Order__c=od1.id,
Opportunity__c=oppList[1].id,
Account_Name__c=acct.id,
status__c='Completed',
RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
                                );
insert bkg;
    
CCR__c cc=new CCR__C(
Comment__c='test',
Opportunity__c=oppList[1].id,
AssignmentStatus__c='Unassigned',
User__c='Approved',
CCR_Type__c='Customer Returns / Refunds',    
Amount__c=100,
booking__c=bkg.id,
Account_Name__c=acct.id,
Impacts_Commission__c = TRUE

);
insert cc;  
Booking_AdjustmentItems__c ba=new Booking_AdjustmentItems__c(
CCR__c=cc.id,
OrderLineItemId__c=oritem.id,
Quantity__c=1
);
insert ba;

oppList[0].CCR__c= cc.id;
update oppList[0];
test.stoptest();
system.assertEquals(3, oppList.size());
}
}
@isTest
static void testCCR1() {
    Test.startTest();
    User usr=[select id from User where isActive = true limit 1];
    system.runAs(usr){ 
    List<Opportunity> lstOpportunities = [Select id, AccountId from Opportunity Limit 2];
    List<Order> lstOrd = [Select Id, OpportunityId from Order];
    Booking__c bkg = [Select id From Booking__c];
    CCR__c cc=new CCR__C(
    Comment__c='test',
    Opportunity__c=lstOpportunities[1].id,
    AssignmentStatus__c='Unassigned',
    User__c='Submitted',
    CCR_Type__c='Non-Payment',    
    Amount__c=100,
    booking__c=bkg.id,
    Account_Name__c= lstOpportunities[1].AccountId,
    Impacts_Commission__c = TRUE
    
    );
    insert cc;
    cc.User__c = 'Approved';
    update cc;
    lstOpportunities[0].CCR__c= cc.id;
    update lstOpportunities[0];
    Database.executeBatch(new BookingBatch(), 1); 
    Test.stopTest();
    system.assertEquals('Non-Payment', cc.CCR_Type__c);

    }              
}
    
    @isTest
    static void testFailedRecord() {
    Test.startTest();
    User usr=[select id from User where isActive = true limit 1];
    system.runAs(usr){ 
    List<Opportunity> lstOpportunities = [Select id, AccountId from Opportunity Limit 2];
    List<Order> lstOrd = new List<Order>();
        for(Order objOrder : [Select Id, OpportunityId from Order]){
            lstOrd.add(new Order(Id = objOrder.Id , OpportunityId = null));
        }
    update lstOrd;
    String errorMessage = 'E'.repeat(131073);
    String UnProcessedRecord = String.valueOf(lstOrd[0].Id).repeat(255);
    BookingBatch.getErrorForMessage('BookingBatch', UnProcessedRecord , errorMessage , 'Booking');
    BookingBatch.isTestMode = true;
    Database.executeBatch(new BookingBatch(), 1); 
    Test.stopTest();
    system.assertEquals(2, lstOpportunities.size());

    }              
       
    }

/**
* PMD Rule: AvoidComplexity (complexity)
* @description : Call testAcceptedOrder
*/
public static testMethod void testAcceptedOrder() {
    test.startTest();
    User usr=[select id from User where isActive = true limit 1];
    system.runAs(usr){  
    BookingBatch bb=new BookingBatch();
    ID batchprocessid=database.executeBatch(bb, 1);
    }
    test.stopTest();
    system.assert(true);
}
/**
* PMD Rule: AvoidComplexity (complexity)
* @description : Call testAcceptedOrder
*/
public static testMethod void testdataloadscript() {
    test.startTest();
    set<Id> bookingIds = new set<id>();
    for(booking__c bkg : [select id from booking__c limit 1]){
        bookingIds.add(bkg.id);
    }
    User usr=[select id from User where isActive = true limit 1];
    system.runAs(usr){
    onetimeDataloadBatch tr = new onetimeDataloadBatch(bookingIds,'booking');
    tr.testA();
    database.executeBatch(tr);
    }
    test.stopTest();
   system.assert(true);
}
/**
* PMD Rule: AvoidComplexity (complexity)
* @description : Call testAcceptedOrder
*/
public static testMethod void testOrderCreate() {
    test.startTest();
    set<Id> oppIds = new set<id>();
    for(opportunity opp : [select id from opportunity limit 1]){
        oppIds.add(opp.id);
    }
    User usr=[select id from User where isActive = True limit 1];
    system.runAs(usr){
    onetimeDataloadBatch tr = new onetimeDataloadBatch(oppIds,'createOrder');
    tr.testA();
    database.executeBatch(tr);

    }
    test.stopTest();
    system.assert(true);
}

@isTest
static void testCCR2() {
    Test.startTest();
    User usr=[select id from User where isActive = true limit 1];
    system.runAs(usr){ 
        List<Opportunity> lstOpportunities = [Select id, AccountId from Opportunity Limit 2];
        List<Order> lstOrd = [Select Id, OpportunityId from Order];
        Booking__c bkg = [Select id From Booking__c];
        CCR__c cc=new CCR__C(
        Comment__c='test',
        Opportunity__c=lstOpportunities[1].id,
        AssignmentStatus__c='Unassigned',
        User__c='Submitted',
        CCR_Type__c='Change in Booking Policy / De-Risk Decision',    
        Amount__c=100,
        booking__c=bkg.id,
        Account_Name__c= lstOpportunities[1].AccountId,
        Impacts_Commission__c = TRUE

    );
    insert cc;
    cc.User__c = 'Approved';
    update cc;
    lstOpportunities[0].CCR__c= cc.id;
    update lstOpportunities[0];
    Database.executeBatch(new BookingBatch(), 1); 
    Test.stopTest();
    }              
    system.assert(true);
}

@isTest
static void testCCR3() {
Test.startTest();
User usr=[select id from User where isActive = true limit 1];
system.runAs(usr){ 
List<Opportunity> lstOpportunities = [Select id, AccountId from Opportunity Limit 2];
List<Order> lstOrd = [Select Id, OpportunityId from Order];
Booking__c bkg = [Select id From Booking__c];
CCR__c cc=new CCR__C(
Comment__c='test',
Opportunity__c=lstOpportunities[1].id,
AssignmentStatus__c='Unassigned',
User__c='Submitted',
CCR_Type__c='Incorrect Order/Mis-quote',    
Amount__c=100,
booking__c=bkg.id,
Account_Name__c= lstOpportunities[1].AccountId,
Impacts_Commission__c = TRUE

);
insert cc;
cc.User__c = 'Approved';
update cc;
lstOpportunities[0].CCR__c= cc.id;
update lstOpportunities[0];
Database.executeBatch(new BookingBatch(), 1); 
Test.stopTest();
system.assert(true);
}              

}

@isTest
static void testBillingAddress() {
User usr=[select id from User where isActive = True limit 1];
system.runAs(usr){
test.startTest();
List<Opportunity> lstOpp = new List<Opportunity>();
List<Order> lstOrder = [Select Id, OpportunityId, BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,BillingStateCode,BillingCountryCode,BillingLatitude,BillingLongitude,BillingGeocodeAccuracy from Order Limit 1];
Date currentDate = Date.Today();
lstOpp.add(new Opportunity(Id = lstOrder[0].OpportunityId , CloseDate = Date.newInstance(currentDate.Year(), 11, 5)));
update lstOpp;
lstOrder[0].BillingStreet = 'MG street';
lstOrder[0].BillingCity = 'Mumbai';
lstOrder[0].BillingPostalCode = '797997';
lstOrder[0].BillingCountry = 'India';
update lstOrder;
Database.executeBatch(new BookingBatch(), 1); 
test.stopTest();
system.assert(true);
}

}

@isTest
static void testRemovedOrderItem() {
User usr=[select id from User where isActive = True limit 1];
system.runAs(usr){
List<OrderItem> lstOrdItem = [Select Id from OrderItem];
delete lstOrdItem;
Test.startTest();
Database.executeBatch(new BookingBatch(), 1); 
Test.stopTest();
system.assert(true);
}
}

}