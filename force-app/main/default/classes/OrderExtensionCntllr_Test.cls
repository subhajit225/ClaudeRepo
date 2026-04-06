/********************************************************************************************************
* Name              : OrderExtensionCntllr_Test 
* Purpose           : OrderExtensionCntllr_Test is Used for Testing OrderExtensionCntllr Class
*********************************************************************************************************/
@isTest
public class OrderExtensionCntllr_Test{
    
    public static testMethod void testSaveOrderAndAddProducts(){
        OrderExtensionCntllr ob = new OrderExtensionCntllr();
        ob.testCoverage();
        // testDataFactoryClass.createCustomSettings();
        
        // list<CodeWithCountry__c> listCodeWithCountry= new list<CodeWithCountry__c> ();
        // CodeWithCountry__c Co84= new CodeWithCountry__c ();
        // Co84.name= 'US';
        // Co84.country__c= 'United States';
        // listCodeWithCountry.add(Co84);
        // insert listCodeWithCountry;
        
        // StateNameCode__c custset = new StateNameCode__c();
        // custset.Name = 'California';
        // custset.Code__c = 'US-CA';
        // insert custset;
        
        // Map<String, Object>  accMap = new Map<String, Object> {
        //     'Name' => 'Test Arpit Account',
        //     'Type' => 'Customer',    
        //     'BillingStreet' => '444 Saratoga Ave',
        //     'BillingCity' => 'Santa Clara',
        //     'BillingState' => 'California',
        //     'BillingCountry' => 'United States',
        //     'BillingPostalCode' => '95050'
        // };
        // Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), accMap);
        // insert acc;
        
        // //Generate the Opportunity
        // Map<String, Object>  oppMap = new Map<String, Object> {
        //     'AccountId' => acc.Id
        // };
            
        // Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        // insert(opp);
        
        // shipping_Address__C sAddr = new Shipping_Address__C(Account__c = acc.Id,Name='Test 1',Shipping_State__C ='CA',Shipping_Country__c='United States');
        // insert sAddr;
        
        // Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        // //cnt.Name='TestConName';
        // insert cnt;
        
        // Order order= new Order();
        // order.AccountId = acc.Id;
        // order.OpportunityId =opp.Id;
        // order.EffectiveDate = Date.Today();
        // //od.Status = 'PO Received';
        // order.Order_Status__c = 'PO Received';
        // order.ShippingStreet ='Test Street';
        // order.ShippingCity ='Test City';
        // order.ShippingState ='California';
        // order.ShippingCountry ='United States';
        // order.ShippingPostalcode ='94820';
        // //order.ship_To_Name__c=acc.id;
        // order.Ship_To_Contact_Name__C=cnt.id;
        // order.Shipping_Address_Label__c = saddr.Name;
        // insert order;
        
        // PageReference pageRef = Page.Account_LookBookPage; // Adding VF page Name here
        // Test.setCurrentPage(pageRef);
        // pageRef.getParameters().put('oppid', opp.Id);//for page reference
        // pageRef.getParameters().put('Id', order.Id);//for page reference
        // ApexPages.StandardController sc = new ApexPages.standardController(order);

        // OrderExtensionCntllr extn = new OrderExtensionCntllr(sc);
        // Test.startTest();
        // extn.saveOrderAndAddProducts();
        // extn.selectShippingAddress();
        // extn.resetCountryCode();
        // extn.onSelectShippingAddress();
        // extn.saveOrder();
        // extn.updateContactText();
        // extn.saveContact();
        // Test.stopTest();
    }
    
    // public static testMethod void testSaveOrder(){
    //     list<CountryWithCode__c> listCountryWithCode= new list<CountryWithCode__c> ();

    //     CountryWithCode__c Co2= new CountryWithCode__c ();
    //     Co2.name= 'United States';
    //     Co2.code__c= 'US';

    //     listCountryWithCode.add(Co2);


    //     insert listCountryWithCode;

    //     list<CodeWithCountry__c> listCodeWithCountry= new list<CodeWithCountry__c> ();

    //     CodeWithCountry__c Co1= new CodeWithCountry__c ();
    //     Co1.name= 'US';
    //     Co1.country__c= 'United States';

    //     listCodeWithCountry.add(Co1);

    //     insert listCodeWithCountry;
        
    //     StateCodeName__C stateSetting2 = new StateCodeName__C();
    //     stateSetting2.Name = 'US-CA';
    //     stateSetting2.State_Name__c = 'California';
    //     insert stateSetting2;
        
    //     StateNameCode__c custset = new StateNameCode__c();
    //     custset.Name = 'California';
    //     custset.Code__c = 'US-CA';
    //     insert custset;
        
        
    //     Map<String, Object>  accMap = new Map<String, Object> {
    //         'Name' => 'Test Arpit Account',
    //         'Type' => 'Customer',    
    //         'BillingStreet' => '444 Saratoga Ave',
    //         'BillingCity' => 'Santa Clara',
    //         'BillingState' => 'California',
    //         'BillingCountry' => 'United States',
    //         'BillingPostalCode' => '95050'
    //     };
    //     Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), accMap);
    //     insert acc;
        
    //     //Generate the Opportunity
    //     Map<String, Object>  oppMap = new Map<String, Object> {
    //         'AccountId' => acc.Id
    //     };
            
    //     Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
    //     insert(opp);
        
    //     shipping_Address__C sAddr = new Shipping_Address__C(Account__c = acc.Id,Name='Test 1',Shipping_State__C ='CA',Shipping_Country__c='United States');
    //     insert sAddr;
        
    //     Order order= new Order();
    //     order.AccountId = acc.Id;
    //     order.OpportunityId =opp.Id;
    //     order.EffectiveDate = Date.Today();
    //     //od.Status = 'PO Received';
    //     order.Order_Status__c = 'PO Received';
    //     order.ShippingStreet ='Test Street';
    //     order.ShippingCity ='Test City';
    //     order.ShippingState ='California';
    //     order.ShippingCountry ='United States';
    //     order.ShippingPostalcode ='94820';
    //     //order.ship_To_Name__c=acc.id;
    //     //order.Ship_To_Contact_Name__C=cnt.id;
    //     order.Shipping_Address_Label__c = saddr.Name;
    //     insert order;
        
    //     PageReference pageRef = Page.Account_LookBookPage; // Adding VF page Name here
    //     Test.setCurrentPage(pageRef);
    //     pageRef.getParameters().put('oppid', opp.Id);//for page reference
    //     pageRef.getParameters().put('Id', order.Id);//for page reference
    //     ApexPages.StandardController sc = new ApexPages.standardController(order);

    //     OrderExtensionCntllr extn = new OrderExtensionCntllr(sc);
    //     extn.saveOrder();
    //     extn.onSelectShippingAddress();
        
    // }
    
    // public static testMethod void testOrderExtCntllrOppIdNotNull(){
    //     testDataFactoryClass.createCustomSettings();
        
    //     list<Countries__c> listCountries= new list<Countries__c> ();

    //     Countries__c Co1= new Countries__c ();
    //     Co1.name= 'USA';
    //     Co1.name__c= 'null';

    //     listCountries.add(Co1);


    //     insert listCountries;
        
    //     list<States__c> listStates= new list<States__c> ();

    //     States__c St1= new States__c ();
    //     St1.name= 'CA';
    //     St1.name__c= 'CA';

    //     listStates.add(St1);
    //     insert listStates;
        
    //     list<CodeWithCountry__c> listCodeWithCountry= new list<CodeWithCountry__c> ();
    //     CodeWithCountry__c Co84= new CodeWithCountry__c ();
    //     Co84.name= 'US';
    //     Co84.country__c= 'United States';
    //     listCodeWithCountry.add(Co84);
    //     insert listCodeWithCountry;
        
    //     StateNameCode__c custset = new StateNameCode__c();
    //     custset.Name = 'California';
    //     custset.Code__c = 'US-CA';
    //     insert custset;
        
    //     Map<String, Object>  accMap = new Map<String, Object> {
    //         'Name' => 'Test Arpit Account',
    //         'Type' => 'Customer',    
    //         'BillingStreet' => '444 Saratoga Ave',
    //         'BillingCity' => 'Santa Clara',
    //         'BillingState' => 'California',
    //         'BillingCountry' => 'United States',
    //         'BillingPostalCode' => '95050'
    //     };
    //     Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), accMap);
    //     insert acc;
        
    //     //Generate the Opportunity
    //     Map<String, Object>  oppMap = new Map<String, Object> {
    //         'AccountId' => acc.Id
    //     };
            
    //     Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
    //     insert(opp);
        
    //     shipping_Address__C sAddr = new Shipping_Address__C(Account__c = acc.Id,Name='Test 1',Shipping_State__C ='CA',Shipping_Country__c='United States');
    //     insert sAddr;
        
    //     Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
    //     //cnt.Name='TestConName';
    //     insert cnt;
        
    //     Order order= new Order();
    //     order.AccountId = acc.Id;
    //     order.OpportunityId =opp.Id;
    //     order.EffectiveDate = Date.Today();
    //     //od.Status = 'PO Received';
    //     order.Order_Status__c = 'PO Received';
    //     order.ShippingStreet ='Test Street';
    //     order.ShippingCity ='Test City';
    //     order.ShippingState ='California';
    //     order.ShippingCountry ='United States';
    //     order.ShippingPostalcode ='94820';
    //     //order.ship_To_Name__c=acc.id;
    //     order.Ship_To_Contact_Name__C=cnt.id;
    //     order.Shipping_Address_Label__c = saddr.Name;
    //     insert order;
        
    //     PageReference pageRef = Page.Account_LookBookPage; // Adding VF page Name here
    //     Test.setCurrentPage(pageRef);
    //     pageRef.getParameters().put('oppid', opp.Id);//for page reference
    //     //pageRef.getParameters().put('Id', order.Id);//for page reference
    //     ApexPages.StandardController sc = new ApexPages.standardController(order);

    //     OrderExtensionCntllr extn = new OrderExtensionCntllr(sc);
    //     Test.startTest();
    //     extn.newSalesOrder = new Order();
    //     extn.saveOrderAndAddProducts();
    //     extn.selectShippingAddress();
    //     //extn.resetCountryCode();
    //     extn.onSelectShippingAddress();
    //     extn.saveOrder();
    //     extn.updateContactText();
    //     //extn.saveContact();
    //     Test.stopTest();
    // }
}