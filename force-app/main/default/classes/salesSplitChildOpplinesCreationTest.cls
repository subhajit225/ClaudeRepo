@isTest
public class salesSplitChildOpplinesCreationTest {
    @testSetup
    public static void setup() {          
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = False;
        TriggerControl__c setting2 = new TriggerControl__c();
        
        setting2.Name = 'Contact';
        setting2.DisableTrigger__c = False;
        TriggerControl__c setting3 = new TriggerControl__c();
        setting3.Name = 'Entitlement';
        setting3.DisableTrigger__c = False;
        insert new List<TriggerControl__c>{setting1, setting2, setting3};
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','BillingpostalCode'=>'809','BillingStreet'=>'sdf'};
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(),accMap);
        
        Account acc = new Account(Name='testAccount1');
        insert new List<Account>{acct, acc};
            
        Contact con = new Contact(FirstName='john', LastName='doe', Email='john@doe.com', AccountId=acct.Id);
        insert con;
        
        Date closeDt = System.Today()+30;
        
        Opportunity oppr = TestDataFactory.getOpportunity(acct);
        oppr.ACV_Amount__c = 100;
        insert oppr;
        
        Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true);
        pd.IsActive = true;
        insert pd;
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        PricebookEntry pbestandard = new PricebookEntry(Pricebook2Id=standardPriceBookId, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pb1.id, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        insert new List<PricebookEntry>{pbestandard, pbe};
        Product2 p2ex = [SELECT Name FROM Product2 WHERE Id = :pd.Id];
        System.assertEquals(pd.Name,p2ex.Name);
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prod1 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true
        );
        Product2 prod3 = new Product2(
            Name = 'RBK-REDGE-10-MO-CLOUT',
            ProductCode = 'RBK-REDGE-10-MO',
            isActive = true
        );
        Product2 prod4 = new Product2(
            Name = 'RBK-RCDM-10-MO-CLON',
            ProductCode = 'RBK-RCDM-AWS-MO',
            isActive = true
        );
        insert new List<Product2>{prod1, prod2, prod3, prod4};
            
        PricebookEntry pbStanEntry1 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry4 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>{
            pbStanEntry1,
                pbStanEntry2,
                pbStanEntry3,
                pbStanEntry4,
                pbEntry1,
                pbEntry2,
                pbEntry3,
                pbEntry4
                };
                    
        Order ordr = new Order(Type='Revenue' ,  AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
                               ShippingCity ='Test City',
                               ShippingState =null,
                               ShippingCountry ='Austria',
                               ShippingPostalcode ='94820',
                               EffectiveDate=system.Today(), Status='Pending'
                              );
        insert ordr;
        Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:ordr.id LIMIT 1 ];
        
        od.Pricebook2Id = pb1.Id;
        update od;
        Asset asst = new Asset(
            Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        Asset asst3 = new Asset(
            Name= 'Test1234567Asset3', SerialNumber= 'Test1234567Asset3',Serial_Number__c= 'Test1234567Asset3',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        Asset asst4 = new Asset(
            Name= 'Test1234567Asset4', SerialNumber= 'Test1234567Asset4',Serial_Number__c= 'Test1234567Asset4',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        Asset asst2 = new Asset(
            Name= 'Test1234567Asset2', SerialNumber= 'Test1234567Asset2',Serial_Number__c= 'Test1234567Asset2',Product2ID=prod3.Id,
            Accountid =acct.Id
        );
        insert new List<Asset>{asst, asst3, asst4, asst2};
        oppr.StageName ='6 PO Recieved';
        ordr.ShipToContactName__c = 'sh';
        ordr.Shipping_Method__c ='EXW';
        ordr.Shipping_Carrier__c ='AIT';
        ordr.Service_Level__c ='Same Day';
        ordr.Bill_To_Name__C =acct.id;
        ordr.est_Ship_Date__C =System.Today().addDays(7);
        ordr.Status='Order Accepted' ;
        
        OrderItem oli1 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry1.Id,
            UnitPrice = pbEntry1.UnitPrice,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        OrderItem oli2 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry2.Id,
            UnitPrice =  pbEntry2.UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        OrderItem oli3 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry3.Id,
            UnitPrice =  pbEntry3.UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        OrderItem oli4 = new OrderItem(
            OrderId = ordr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry4.Id,
            UnitPrice =  pbEntry4.UnitPrice,
            SerialNumber__c = 'Test1234567Asset',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        insert new List<OrderItem>{oli1, oli2, oli3, oli4};
            
        Booking__c bkg=new Booking__c(
            Order__c=od.id,
            Opportunity__c=oppr.id,
            Account_Name__c=acc.id,
            RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
        );
        insert bkg;
        
        Map<String, Object>  CCRMap = new Map<String, Object> {
            'Comment__c'=>'test',
                'Opportunity__c'=>oppr.id,
                'AssignmentStatus__c'=>'Unassigned',
                'User__c'=>'Pending',
                'Account_Name__c'=>acc.id,
                'Effective_Date__c'=>System.today(),
                'Impacts_Commission__c'=>true,
                'Effective_End_Date__c'=>System.today(), 
                'Booking__c'=> bkg.id,
                'recordtypeId' => Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
                };
                    List<CCR__c> CCRList = (List<CCR__c>) ShGl_TestFactory.createSObjectList(new CCR__c(),3, CCRMap); 
        insert CCRList;
        
        Map<String, Object>  CCRPartnerIncentiveMap = new Map<String, Object> {
            'User__c'=>'Pending',
                'CCR_Type__c'=> 'Marketing SPIFF',
                'Meeting_Date__c'=> System.today().addDays(-7),
                'Customer_Email_Address__c' => con.Email,
                'recordtypeId' => Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Partner Claim Form').getRecordTypeId()
                };
        List<CCR__c> CCRPartnerIncentiveList = (List<CCR__c>) ShGl_TestFactory.createSObjectList(new CCR__c(),3, CCRPartnerIncentiveMap); 
        insert CCRPartnerIncentiveList;
        
        List<CountryWithCode__c> countryWCode = new List<CountryWithCode__c>();
        CountryWithCode__c cRec = new CountryWithCode__c();
        cRec.Name='United States';
        cRec.Code__c='US';
        countryWCode.add(cRec);
        Insert countryWCode;
    }    
    
    public static testMethod void afterupdateTestMethodSplitCCR1() {
        
        ShGl_DisableBusinessLogic__c sbl = new ShGl_DisableBusinessLogic__c(Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Old_Trigger__c=true,Disable_Opportunity_Triggers__c=true,SetupOwnerId=UserInfo.getOrganizationId());
        insert sbl;
        
        Account acc = TestDataFactory.getAccount();
        insert acc;
        Contact cont = new Contact(firstname='first', lastname='last', accountId=acc.id);
        insert cont;
        
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acc.Id
                };
                    
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        Opportunity tempOpp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        Opportunity tempOpp2 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);    
        List<Opportunity> opptyList = new List<Opportunity> ();
        opptyList.add(opp);
        opptyList.add(tempOpp);
        opp.ACV_Amount__c = 3455;
        opp.split_percentage__c = 50;
        opp.Amount = 23444;
        opp.split__c = false;
        opp.split_amount__c = 6777;
        tempOpp.split_percentage__c = 30;
        tempOpp.Amount = 23444;
        tempOpp2.split_percentage__c = 20;
        tempOpp2.Amount = 23444;    
        insert opptyList;
        opptyList[1].Opportunity_Split_Parent__c = opp.Id;
        update opptyList[1]; 
        tempOpp2.ownerID = userinfo.getUserId();    
        tempOpp2.Opportunity_Split_Parent__c = opp.Id;
        
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode = 'OPTY-SPLITS');
        insert newProd;
        
        Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', isActive = true);
        insert priceBook;
        
        Id standardPBId = test.getStandardPricebookId();        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 400,
            PriceBook2Id = standardPBId,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        opp.Pricebook2Id=standardPBId;
        opp.Split_percentage__c=25;
        opp.split_amount__c = 0.00;
        opp.Initial_Contacts_Name__c = cont.Id;
        update opp;
        tempOpp.Pricebook2Id=standardPBId;
        update tempOpp;
        
        OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000,
                                                              Quantity = 2,OpportunityID = opp.Id
                                                             );
        insert oppLine;
        system.debug('Opportunity Line items:'+opp.OpportunityLineItems);
        
        test.startTest();
        List<User> uList = [select id from user limit 3];    
        String jsonwrap = '[{"splitopp":{"Opportunity_Split_Parent__c":"'+opptyList[0].Id+'","Id":"'+opptyList[1].Id+'","OwnerId":"'+userinfo.getUserId()+'","Split_percentage__c":50,"split__c":true,"Amount":85345.005,"StageName":"1 Discovery","AccountId":"'+acc.Id+'","CloseDate":"2022-10-21","Opportunity_Type__c":"Existing Customer","Opportunity_Sub_Type__c":"Regular","ACV_Amount__c":"35744.068333333336","Owner":{"Name":"Pavanaja Yellajosyula","Id":"'+userinfo.getUserId()+'"},"ownerID":"'+userinfo.getUserId()+'","split_percentage__c":50},"index":1}]';
        String jsonwrap1 = '[{"splitopp":{"Name":"testOpp2","split_amount__c":2344,"Opportunity_Split_Parent__c":"'+opptyList[0].Id+'","Id":null,"OwnerId":"'+userinfo.getUserId()+'","Split_percentage__c":50,"split__c":true,"Amount":85345.005,"StageName":"1 Discovery","AccountId":"'+acc.Id+'","CloseDate":"2022-10-21","Opportunity_Type__c":"Existing Customer","Opportunity_Sub_Type__c":"Regular","ACV_Amount__c":"35744.068333333336","Owner":{"Name":"Pavanaja Yellajosyula","Id":"'+userinfo.getUserId()+'"},"ownerID":"'+userinfo.getUserId()+'","split_percentage__c":50},"index":1}]'; 
        OpportunitySplitLWCController.getOppDetails(opptyList[0].Id);
        OpportunitySplitLWCController.getSplitOppDetails(opptyList[0].Id);
        List<Id> prevOwnerIdList = new List<Id>();
        prevOwnerIdList.add(userinfo.getUserId());    
        OpportunitySplitLWCController.saveItem(opptyList[0],jsonwrap1,2000,0,prevOwnerIdList,true,true);  
        
        List<CCR__c> CCRList = [SELECT id,Name,CCR_Type__c,User__c,CCR_Split_Exception__c from CCR__c where CCR_Split_Exception__c = true];       
        
        for(CCR__c ccr : CCRList){
            ccr.User__c = 'Approved';
        }
        
        String uniqueUserName = 'CCRTriggerTest' + DateTime.now().getTime() + '@testclass.com';                      
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr=new user(alias = 'std', email='testuser@testclass.com',
                          emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = p.Id,
                          timezonesidkey='America/Los_Angeles', username=uniqueUserName);
        
        system.runAs(usr){
            update CCRList;
        }
        Test.stopTest();
        system.assertnotequals(opptyList[0].Id,null);
    }
}