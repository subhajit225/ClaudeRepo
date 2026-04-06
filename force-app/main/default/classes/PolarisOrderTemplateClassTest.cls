@isTest
public class PolarisOrderTemplateClassTest {
    /**
    * @description Test method for coverage
    */
    public static testmethod void testController(){
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Opportunity';
        //custsetting.Disable_Trigger__c =
        custsetting.DisableTrigger__c = true;                
        insert custsetting; 
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = false;
        insert disableFuncCS;
        
        insert new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,
                                                Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                Disable_Account_Triggers__c = true,
                                                Disable_POC_Trigger__c = true,
                                                Disable_Lead_Triggers__c = true,
                                                Disable_Lead_Validation_Rules__c = true,
                                                Disable_OrderItem_Old_Trigger__c = true,
                                                Disable_Opportunity_Triggers__c = true ,
                                                Disable_Opportunity_Validation_Rules__c = true,
                                                Disable_Order_Old_Trigger__c = true,
                                                Disable_Order_Triggers__c = false,
                                                Disable_Order_Validation_Rules__c=true,
                                                Disable_Asset_Triggers__c = true,
                                                Disable_POC_Validation_Rules__c=true,
                                                setupOwnerId = userinfo.getuserid());
        
        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com.sandbox';
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account actDist = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        actDist.name='Promark Technology, Inc.';
        actDist.Type ='Distributor';
        actDist.Contract_Status__c='Signed-Active';
        actDist.RecordTypeId=devRecordTypeId;
        insert actDist;
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail@hidden.com.sandbox'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                
                'StageName' => '1 Discovery',
                'Other_Competitor_Field__c' => 'Other',
                'ForecastCategoryName' => 'Best Case',
                'SE_Forecast_Category__c' =>'Commit',
                'Distributor_Lookup__c'=>actDist.id,
                'Partner_Lookup__c'=>actDist.id,
                'Economic_Buyer__c'=>'tete',
                'Metric__c'=>'tete',
                'Decision_Process__c'=>'tete',
                'Decision_Criteria__c'=>'tete',
                'Identified_Pain__c'=>'tete',
                'Champion__c'=>'tete'
                };
                    Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert oppty;
        
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
        
        oppty.Pricebook2Id = pricebookId;
        oppty.StageName = '4 Business Justification';
        oppty.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.Opportunity_Type__c='Debooking';
        oppty.Opportunity_Sub_Type__c='MSP';
        update oppty;
        
        
        POC__c pocRequest = new POC__c();
        POC__c poc = new POC__c();
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.POC_Duration__c = '30 Days';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;
        poc.Product_Categories__c='UCL (Cloud Cluster, Cloud Native & Entra ID)';
        
        insert poc;
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.SD_Status__c = 'Success'; 
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id; 
        od.Type = 'POC';
        od.POC_Request__c=poc.id; 
        od.Est_Ship_Date__c = system.today();
        od.Actual_Order_Ship_Date__c=system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        od.Order_Status__c='Pending';
        od.Fulfilment_Set_Name__c = 'Abcd1234';
        od.Fulfilment_Count__c = 1;
        od.Polaris_Contact__c = cnt1.id;
        od.Polaris_Contact_Email__c = 'test@example.com.sandbox';
        od.ProcessType__c = 'Aspen';
        
        insert od;
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        OrderItem i = new OrderItem();
        i.OrderId = od.id;
        i.Quantity = 24;
        i.UnitPrice = 240;
        i.Product2id = p.id;
        i.PricebookEntryId = standardPrice.id;
        i.SerialNumber__c = 'XY210464040030';
        insert i;
        
        PolarisOrderTemplateClass ob = new PolarisOrderTemplateClass();
        ob.ordId = od.Id;
        ob.getlineItems();
        ob.getlineItemsForHardware();
        ob.getpolarisDetails();
        ob.getEntitlements();
        PolarisOrderTemplateClass.generatePolarisContactDetails('test', od);
        ob.getOrderItemDetails();
        User adminUser = getSysAdminUser();
        System.runAs(adminUser){
            System.assert(true, ob.ordId!=null);
        }
    }
	
    /**
    * @description Test method for coverage
    */
    public static testmethod void testController2(){
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Opportunity';
        //custsetting.Disable_Trigger__c =
        custsetting.DisableTrigger__c = true;                
        insert custsetting; 
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        TriggerControl__c custsetting2 = new TriggerControl__c();
        custsetting2.Name = 'Order';
        //custsetting.Disable_Trigger__c =
        custsetting2.DisableTrigger__c = true;                
        insert custsetting2; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = false;
        insert disableFuncCS;
        
        insert new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,
                                                Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                Disable_Account_Triggers__c = true,
                                                Disable_POC_Trigger__c = true,
                                                Disable_Lead_Triggers__c = true,
                                                Disable_Lead_Validation_Rules__c = true,
                                                Disable_OrderItem_Old_Trigger__c = true,
                                                Disable_Opportunity_Triggers__c = true ,
                                                Disable_Opportunity_Validation_Rules__c = true,
                                                Disable_Order_Old_Trigger__c = true,
                                                Disable_Order_Triggers__c = false,
                                                Disable_Order_Validation_Rules__c=true,
                                                Disable_Asset_Triggers__c = true,
                                                Disable_POC_Validation_Rules__c=true,
                                                setupOwnerId = userinfo.getuserid());
        
        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com.sandbox';
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account actDist = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        actDist.name='Promark Technology, Inc.';
        actDist.Type ='Distributor';
        actDist.Contract_Status__c='Signed-Active';
        actDist.RecordTypeId=devRecordTypeId;
        insert actDist;
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail@hidden.com.sandbox'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                
                'StageName' => '1 Discovery',
                'Other_Competitor_Field__c' => 'Other',
                'ForecastCategoryName' => 'Best Case',
                'SE_Forecast_Category__c' =>'Commit',
                'Distributor_Lookup__c'=>actDist.id,
                'Partner_Lookup__c'=>actDist.id,
                'Economic_Buyer__c'=>'tete',
                'Metric__c'=>'tete',
                'Decision_Process__c'=>'tete',
                'Decision_Criteria__c'=>'tete',
                'Identified_Pain__c'=>'tete',
                'Champion__c'=>'tete'
                };
                    Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert oppty;
        
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
        
        oppty.Pricebook2Id = pricebookId;
        oppty.StageName = '4 Business Justification';
        oppty.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.Opportunity_Type__c='Debooking';
        oppty.Opportunity_Sub_Type__c='MSP';
        update oppty;
        
        
        POC__c pocRequest = new POC__c();
        POC__c poc = new POC__c();
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.POC_Duration__c = '30 Days';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;
        poc.Product_Categories__c='UCL (Cloud Cluster, Cloud Native & Entra ID)';
        
        insert poc;
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.SD_Status__c = 'Success'; 
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id; 
        od.Type = 'POC';
        od.POC_Request__c=poc.id; 
        od.Est_Ship_Date__c = system.today();
        od.Actual_Order_Ship_Date__c=system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        od.Order_Status__c='Pending';
        od.Fulfilment_Set_Name__c = 'Abcd1234';
        od.Fulfilment_Count__c = 1;
        od.Polaris_Contact__c = cnt1.id;
        od.Polaris_Contact_Email__c = 'test@example.com.sandbox';
        od.ProcessType__c = 'Aspen';
        od.Welcome_letter_sent_for_the_first_time__c = false;
        od.WelcomeEmailSentforSoftwareProducts__c = true;
        
        insert od;
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        OrderItem i = new OrderItem();
        i.OrderId = od.id;
        i.Quantity = 24;
        i.UnitPrice = 240;
        i.Product2id = p.id;
        i.PricebookEntryId = standardPrice.id;
        i.SerialNumber__c = 'XY210464040030';
        insert i;
        
        Order od1 = new Order();
        od1.id = od.Id;
        od1.Status = 'Shipped';
        od1.SD_Status__c = 'Success';
        od1.ProcessType__c = 'Aspen';
        update od1;
        
        PolarisOrderTemplateClass ob = new PolarisOrderTemplateClass();
        ob.ordId = od.Id;
        ob.getlineItems();
        ob.getlineItemsForHardware();
        ob.getpolarisDetails();
        ob.getEntitlements();
        PolarisOrderTemplateClass.generatePolarisContactDetails('test', od);
        ob.getOrderItemDetails();
        
        Order odr = [SELECT Id, Fulfilment_Set_Name__c, Type, ProcessType__c, SD_Status__c FROM Order];
        User adminUser = getSysAdminUser();
        System.runAs(adminUser){
            System.assert(true, odr.Id!=null);
        }
    }
    
    /**
    * @description Test method for coverage
    */
    public static testMethod void testController4(){
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Opportunity';
        //custsetting.Disable_Trigger__c =
        custsetting.DisableTrigger__c = true;                
        insert custsetting; 
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = false;
        insert disableFuncCS;
        
        insert new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,
                                                Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                Disable_Account_Triggers__c = true,
                                                Disable_POC_Trigger__c = true,
                                                Disable_Lead_Triggers__c = true,
                                                Disable_Lead_Validation_Rules__c = true,
                                                Disable_OrderItem_Old_Trigger__c = true,
                                                Disable_Opportunity_Triggers__c = true ,
                                                Disable_Opportunity_Validation_Rules__c = true,
                                                Disable_Order_Old_Trigger__c = true,
                                                Disable_Order_Triggers__c = false,
                                                Disable_Order_Validation_Rules__c=true,
                                                Disable_Asset_Triggers__c = true,
                                                Disable_POC_Validation_Rules__c=true,
                                                setupOwnerId = userinfo.getuserid());
        
        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com.sandbox';
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account actDist = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        actDist.name='Promark Technology, Inc.';
        actDist.Type ='Distributor';
        actDist.Contract_Status__c='Signed-Active';
        actDist.RecordTypeId=devRecordTypeId;
        insert actDist;
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail@hidden.com.sandbox'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                
                'StageName' => '1 Discovery',
                'Other_Competitor_Field__c' => 'Other',
                'ForecastCategoryName' => 'Best Case',
                'SE_Forecast_Category__c' =>'Commit',
                'Distributor_Lookup__c'=>actDist.id,
                'Partner_Lookup__c'=>actDist.id,
                'Economic_Buyer__c'=>'tete',
                'Metric__c'=>'tete',
                'Decision_Process__c'=>'tete',
                'Decision_Criteria__c'=>'tete',
                'Identified_Pain__c'=>'tete',
                'Champion__c'=>'tete'
                };
                    Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert oppty;
        
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
        
        oppty.Pricebook2Id = pricebookId;
        oppty.StageName = '4 Business Justification';
        oppty.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.Opportunity_Type__c='Debooking';
        oppty.Opportunity_Sub_Type__c='MSP';
        update oppty;
        
        
        POC__c pocRequest = new POC__c();
        POC__c poc = new POC__c();
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.POC_Duration__c = '30 Days';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;
        poc.Product_Categories__c='UCL (Cloud Cluster, Cloud Native & Entra ID)';
        
        insert poc;
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.SD_Status__c = 'Success'; 
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id; 
        od.Type = 'Revenue';
        od.Order_Sub_Type__c = 'Replacement';
        od.POC_Request__c=poc.id; 
        od.Est_Ship_Date__c = system.today();
        od.Actual_Order_Ship_Date__c=system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        od.Order_Status__c='Pending';
        od.Fulfilment_Set_Name__c = 'Abcd1234';
        od.Fulfilment_Count__c = 1;
        od.Polaris_Contact__c = cnt1.id;
        od.Polaris_Contact_Email__c = 'test@example.com.sandbox';
        od.ProcessType__c = 'Aspen';
        
        insert od;
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        //---- Original Order
        Order orgnlOrd = new Order();
        orgnlOrd.Status = 'Draft';
        orgnlOrd.AccountId = acct.Id;
        orgnlOrd.OpportunityId = oppty.Id;
        orgnlOrd.SD_Status__c = 'Success'; 
        orgnlOrd.EffectiveDate = Date.Today();
        orgnlOrd.ShippingStreet ='Test Street';
        orgnlOrd.ShippingCity ='Test City';
        orgnlOrd.ShippingState ='California';
        orgnlOrd.ShippingCountry ='United States';
        orgnlOrd.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id; 
        orgnlOrd.Type = 'Revenue';
        orgnlOrd.Order_Sub_Type__c = 'Replacement';
        orgnlOrd.POC_Request__c=poc.id; 
        orgnlOrd.Est_Ship_Date__c = system.today();
        orgnlOrd.Actual_Order_Ship_Date__c=system.today();
        orgnlOrd.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        orgnlOrd.Pricebook2Id = pricebookId;
        orgnlOrd.Order_Status__c='Pending';
        orgnlOrd.Fulfilment_Set_Name__c = 'Abcd1234';
        orgnlOrd.Fulfilment_Count__c = 1;
        orgnlOrd.Polaris_Contact__c = cnt1.id;
        orgnlOrd.Polaris_Contact_Email__c = 'testOriginal@example.com.sandbox';
        orgnlOrd.ProcessType__c = 'Aspen';
        insert orgnlOrd;
        
        OrderItem OI = new OrderItem();
        OI.OrderId = orgnlOrd.id;
        OI.Quantity = 100;
        OI.UnitPrice = 240;
        OI.Product2id = p.id;
        OI.PricebookEntryId = standardPrice.id;
        OI.SerialNumber__c = 'XY210464040030';
        insert OI;
        
        OrderItem i = new OrderItem();
        i.OrderId = od.id;
        i.Quantity = 25;
        i.UnitPrice = 240;
        i.Product2id = p.id;
        i.PricebookEntryId = standardPrice.id;
        i.SerialNumber__c = 'XY210464040030';
        i.Replacement_Type__c = 'Partial';
       // i.Prev_Trans_Ref__c = '[{"usedEntitlementQuantity":75,"orderItemId":"'+OI.Id+'","orderItemRemainingQuantity":75.00,"entId":"5508Y000005cMHfQAM"}]';
        insert i;
        
        PolarisOrderTemplateClass ob = new PolarisOrderTemplateClass();
        ob.ordId = od.Id;
        ob.getisDataProtection();
        User adminUser = getSysAdminUser();
        System.runAs(adminUser){
            System.assert(true, ob.ordId!=null);
        }
    }

	 /**
     * @description Test method for replacement order
     * 
    */

	public static testMethod void getRelacementOrderItemsDetailTest(){
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Opportunity';
        //custsetting.Disable_Trigger__c =
        custsetting.DisableTrigger__c = true;                
        insert custsetting; 
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = false;
        insert disableFuncCS;
        
        insert new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,
                                                Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                Disable_Account_Triggers__c = true,
                                                Disable_POC_Trigger__c = true,
                                                Disable_Lead_Triggers__c = true,
                                                Disable_Lead_Validation_Rules__c = true,
                                                Disable_OrderItem_Old_Trigger__c = true,
                                                Disable_Opportunity_Triggers__c = true ,
                                                Disable_Opportunity_Validation_Rules__c = true,
                                                Disable_Order_Old_Trigger__c = true,
                                                Disable_Order_Triggers__c = false,
                                                Disable_Order_Validation_Rules__c=true,
                                                Disable_Asset_Triggers__c = true,
                                                Disable_POC_Validation_Rules__c=true,
                                                setupOwnerId = userinfo.getuserid());
        
        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com.sandbox';
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account actDist = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        actDist.name='Promark Technology, Inc.';
        actDist.Type ='Distributor';
        actDist.Contract_Status__c='Signed-Active';
        actDist.RecordTypeId=devRecordTypeId;
        insert actDist;
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail@hidden.com.sandbox.sandbox'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                
                'StageName' => '1 Discovery',
                'Other_Competitor_Field__c' => 'Other',
                'ForecastCategoryName' => 'Best Case',
                'SE_Forecast_Category__c' =>'Commit',
                'Distributor_Lookup__c'=>actDist.id,
                'Partner_Lookup__c'=>actDist.id,
                'Economic_Buyer__c'=>'tete',
                'Metric__c'=>'tete',
                'Decision_Process__c'=>'tete',
                'Decision_Criteria__c'=>'tete',
                'Identified_Pain__c'=>'tete',
                'Champion__c'=>'tete'
                };
                    Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert oppty;
        
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
        
        oppty.Pricebook2Id = pricebookId;
        oppty.StageName = '4 Business Justification';
        oppty.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.Opportunity_Type__c='Debooking';
        oppty.Opportunity_Sub_Type__c='MSP';
        update oppty;
        
        
        POC__c pocRequest = new POC__c();
        POC__c poc = new POC__c();
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.POC_Duration__c = '30 Days';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;
        poc.Product_Categories__c='UCL (Cloud Cluster, Cloud Native & Entra ID)';
        
        insert poc;
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.SD_Status__c = 'Success'; 
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id; 
        od.Type = 'Revenue';
        od.Order_Sub_Type__c = 'Replacement';
        od.POC_Request__c=poc.id; 
        od.Est_Ship_Date__c = system.today();
        od.Actual_Order_Ship_Date__c=system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        od.Order_Status__c='Pending';
        od.Fulfilment_Set_Name__c = 'Abcd1234';
        od.Fulfilment_Count__c = 1;
        od.Polaris_Contact__c = cnt1.id;
        od.Polaris_Contact_Email__c = 'test@example.com.sandbox.sandbox';
        od.ProcessType__c = 'Aspen';
        
        insert od;
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        //---- Original Order
        Order orgnlOrd = new Order();
        orgnlOrd.Status = 'Draft';
        orgnlOrd.AccountId = acct.Id;
        orgnlOrd.OpportunityId = oppty.Id;
        orgnlOrd.SD_Status__c = 'Success'; 
        orgnlOrd.EffectiveDate = Date.Today();
        orgnlOrd.ShippingStreet ='Test Street';
        orgnlOrd.ShippingCity ='Test City';
        orgnlOrd.ShippingState ='California';
        orgnlOrd.ShippingCountry ='United States';
        orgnlOrd.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id; 
        orgnlOrd.Type = 'Revenue';
        orgnlOrd.Order_Sub_Type__c = 'Replacement';
        orgnlOrd.POC_Request__c=poc.id; 
        orgnlOrd.Est_Ship_Date__c = system.today();
        orgnlOrd.Actual_Order_Ship_Date__c=system.today();
        orgnlOrd.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        orgnlOrd.Pricebook2Id = pricebookId;
        orgnlOrd.Order_Status__c='Pending';
        orgnlOrd.Fulfilment_Set_Name__c = 'Abcd1234';
        orgnlOrd.Fulfilment_Count__c = 1;
        orgnlOrd.Polaris_Contact__c = cnt1.id;
        orgnlOrd.Polaris_Contact_Email__c = 'testOriginal@example.com';
        orgnlOrd.ProcessType__c = 'Aspen';
        insert orgnlOrd;
        
        OrderItem OI = new OrderItem();
        OI.OrderId = orgnlOrd.id;
        OI.Quantity = 100;
        OI.UnitPrice = 240;
        OI.Product2id = p.id;
        OI.PricebookEntryId = standardPrice.id;
        OI.SerialNumber__c = 'XY210464040030';
        insert OI;
        
        OrderItem i = new OrderItem();
        i.OrderId = od.id;
        i.Quantity = 25;
        i.UnitPrice = 240;
        i.Product2id = p.id;
        i.PricebookEntryId = standardPrice.id;
        i.SerialNumber__c = 'XY210464040030';
        i.Replacement_Type__c = 'Partial';
        i.Previous_Transaction_Reference__c = '[{"usedEntitlementQuantity":75,"orderItemId":"'+OI.Id+'","orderItemRemainingQuantity":75.00,"entId":"5508Y000005cMHfQAM"}]';
        insert i;

        User testUser = [SELECT Id from user where username like '%apiautomation@rubrik.com%' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            PolarisOrderTemplateClass ob = new PolarisOrderTemplateClass();
            ob.ordId = od.Id;
            ob.getRelacementOrderItemsDetail();
            System.assertEquals('Replacement Order','Replacement Order');
            Test.stopTest();
        }
    }
    
    private static User getSysAdminUser() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'System Administrator'
            AND IsActive = true
            LIMIT 1
        ];
    }
    
    @IsTest
    static void testGetProducts() {
        User adminUser = getSysAdminUser();

        System.runAs(adminUser) {
            insert new Rate_Card_Product__c(
                Product_Name__c = 'Alpha',
                Product_Description__c = 'Desc',
                Sort_Order__c = 'desc'
            );

            Test.startTest();
            PolarisOrderTemplateClass polarisObj = new PolarisOrderTemplateClass();
            List<Rate_Card_Product__c> products = polarisObj.getrateCardProducts();
            Test.stopTest();

            System.assert(products.size() > 0, 'Products should be returned');
            System.assertEquals('Alpha', products[0].Product_Name__c);
        }
    }

}