@isTest
public class PortalUserHelperTests {
    
    static testMethod void createPortalUserTest(){
        
        FlowControll.opportunityTriggerHandler = false;
        TriggerControl__c OpportunityTC = new TriggerControl__c();
        OpportunityTC.Name = 'Opportunity';
        // PortalUserCreation.DisableTrigger__c = true;
        insert OpportunityTC; 
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail@hidden.com'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                'Other_Competitor_Field__c' => 'Other'
                };
                    
                    Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert oppty;
        
        OpportunityContactRole contactRole = new OpportunityContactRole();
        contactRole.OpportunityId = oppty.Id;
        contactRole.ContactId = cnt1.Id;
        contactRole.IsPrimary = true;
        insert contactRole;
        
        
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'Appliance'
                };
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        prodlist.add(pd);
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'GPS'
                };
                    Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);  
        //prodlist.add(pd2);
        Map<String, Object>  prodMap3 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
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
        FlowControll.opportunityTriggerHandler = true;
        
        oppty.Pricebook2Id = pricebookId;
        oppty.StageName = '4 Business Justification';
        oppty.Partner_Level_Of_Involvement__c = '2.Partner initiated opportunity, but had little involvement in sales cycle';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.ForecastCategoryName = 'Best Case';
        update oppty;
        
		test.startTest();

        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id;
        od.Type = 'POC';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
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
        
        od.Polaris_Fulfillment_Status__c = 'Completed';  
        od.Actual_Order_Ship_Date__c= system.today();
        od.Order_Status__c = 'Shipped';  
        od.SBQQ__Contracted__c = false;  
        update od;
        
        test.stopTest();
        
        
    }
    
    static testMethod void testUtilsClass() {
        Util.getUserDetail(null);
        
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        system.debug('usr :: '+usr);
        insert usr;
        
        Util.getUserDetail(usr.Id);
        
        String userType = Util.UserType;
        User usr1 = Util.CurrentUser;
        
        Util ut = new Util();
        ut.getPartnerUser();
        
        Util.sendEmail(null, null, null, null, null, null);
    }
    
    static testMethod void testBatchPortalUserProvision () {
        
        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        //Generate the Contact
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt.AccountId = act.Id;
        insert cnt;

        Map<Id, Contact> conToProvision = new Map<Id, Contact>();
        conToProvision.put(cnt.Id, cnt);
        
        BatchPortalUserProvision scriptBatch = new BatchPortalUserProvision();
        BatchPortalUserProvision scriptBatch1 = new BatchPortalUserProvision();
        scriptBatch.conSet = conToProvision.keyset();
        
        Test.startTest();
        Database.executeBatch(scriptBatch); 
        Database.executeBatch(scriptBatch1); 
        
        BatchPortalUserProvision.startJob();
        Test.stopTest();
        
    }
    
}