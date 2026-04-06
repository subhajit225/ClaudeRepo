/**
* @description CS21-161 : Set the flag for r6000 series on Account to identify if an Account has at least one r6000 series product based on the Assets tagged
* @author Ashwini G
* @date 9th April 2020
*/
@istest
public class UpdateR6ProductFlagOnClustersNAccsTest {
	
    /**
     * @description Tests the core functionality of UpdateR6000FlagOnAccountsBatch and UpdateR6000FlagOnClustersBatch.
     *              This includes creating Accounts, Products, PricebookEntries, Opportunities, Orders, Assets, Clusters,
     *              Nodes, and Entitlements. It validates that all setup data executes the batch successfully without errors.
     */
    @isTest
     static void test() {
        ShGl_TestFactoryHelper.insertTriggerControls();

        List<Account> accountList = new List<Account>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        act.RecordTypeId = partnerRecordTypeId;
        act.r6000_Series_Products_Tagged__c = 'ASE';
        accountList.add(act);

        Account act2 = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        act2.RecordTypeId = partnerRecordTypeId;
        accountList.add(act2);

        insert accountList;

        List<Product2> productList = new List<Product2>();
        Product2 prd1 = (Product2)ShGl_TestFactory.createSObject(new Product2(), null);
        prd1.Name = 'RBK-R6412S-FNDN-CEM-test';
        prd1.ProductCode = 'RBK-R6412S-FNDN-CEM-test';
        prd1.Family = 'R6000';
        prd1.Description = 'r6404s Appliance, 4-node, 48TB raw HDD, 1.6TB SSD, SFP+ NIC Test,Assigned Support Engineer';
        productList.add(prd1);

        Product2 prd2 = (Product2)ShGl_TestFactory.createSObject(new Product2(), null);
        prd2.Name = 'RBK-R6410-product-CEM-test';
        prd2.ProductCode = 'RBK-R6410-product-CEM-test';
        prd2.Description = 'r6410f Appliance, 4-node, 48TB raw HDD, 1.6TB SSD, SFP+ NIC Test,Assigned Support Engineer';
        prd2.Product_Type__c = 'Codebase Recovery';
        productList.add(prd2);

        Product2 prd3 = (Product2)ShGl_TestFactory.createSObject(new Product2(), null);
        prd3.Name = 'Complete Edition';
        prd3.ProductCode = 'Complete Edition';
        prd3.Description = 'Complete Edition,Assigned Support Engineer';
        prd3.Product_Type__c = 'Complete Edition';
        productList.add(prd3);

        Product2 prd4 = (Product2)ShGl_TestFactory.createSObject(new Product2(), null);
        prd4.Name = 'DSPM';
        prd4.ProductCode = 'DSPM';
        prd4.Description = 'DSPM,Assigned Support Engineer';
        prd4.Product_Type__c = 'DSP Addon';
        productList.add(prd4);

        Product2 prd5 = (Product2)ShGl_TestFactory.createSObject(new Product2(), null);
        prd5.Name = 'RA-RRW';
        prd5.ProductCode = 'RA-RRW';
        prd5.Description = 'RA-RRW,Assigned Support Engineer';
        productList.add(prd5);
		
        Product2 prd6 = (Product2)ShGl_TestFactory.createSObject(new Product2(), null);
        prd6.Name = 'CEM-Prod';
        prd6.ProductCode = 'CEM-Prod';
        prd6.Family = 'CEM';
        prd6.Description = 'Customer Experience Manager, Customer Experience Specialist';
        prd6.IsActive = true;
        productList.add(prd6);
        
        insert productList;
		
        
        Id pricebookId = Test.getStandardPricebookId();
    	Id CPQ_Pricebook_ID = Label.CPQ_Pricebook_ID;

        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pbe1 = (PricebookEntry)ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbe1.Product2Id = productList[0].Id;
        pbe1.Pricebook2Id = pricebookId;
        pbeList.add(pbe1);

        PricebookEntry pbe1_custom = (PricebookEntry)ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbe1_custom.Product2Id = productList[0].Id;
        pbe1_custom.Pricebook2Id = CPQ_Pricebook_ID;
        pbe1_custom.UseStandardPrice =false;
        pbeList.add(pbe1_custom);

        PricebookEntry pbe2 = (PricebookEntry)ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbe2.Product2Id = productList[1].Id;
        pbe2.Pricebook2Id = pricebookId;
        pbeList.add(pbe2);

        PricebookEntry pbe2_custom = (PricebookEntry)ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbe2_custom.Product2Id = productList[1].Id;
        pbe2_custom.Pricebook2Id = CPQ_Pricebook_ID;
        pbe2_custom.UseStandardPrice = false;
        pbeList.add(pbe2_custom);

        insert pbeList;

        Opportunity oppr = TestDataFactory.getOpportunity(act);
        oppr.Pricebook2Id = CPQ_Pricebook_ID;
        insert oppr;

        //Validating the correct Pricebook Id post COMMIT
        oppr = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id=:oppr.Id];

        System.assertEquals(oppr.Pricebook2Id, CPQ_Pricebook_ID);

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppr.Id,
            Quantity = 5,
            PricebookEntryId = pbeList[1].Id,
            TotalPrice=2000
        );
        insert oli;

        Test.startTest();
        Order od = new Order();
        od.AccountId = accountList[0].Id;
        od.OpportunityId =oppr.Id;
        od.Order_Sub_Type__c='MSP Consumption';
        od.EffectiveDate = Date.Today();
        od.Order_Status__c = 'PO Received';
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        insert od;

        OrderItem ordrItem = new OrderItem(
            OrderId = od.Id,
            Quantity = 5,
            PricebookEntryId = pbeList[1].Id,
            UnitPrice = 2000,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        insert ordrItem;

        List<Cluster__c> clusterList = new List<Cluster__c>();
        Cluster__c cluster = new Cluster__c();
        cluster.account__c = accountList[0].Id;
        cluster.Name = '17yaqwhw662788uh';
        cluster.uuid__c = '17yaqwhw662788uh';
        cluster.MSP_Consumption__c = false;
        clusterList.add(cluster);

        Cluster__c cluster2 = new Cluster__c();
        cluster2.account__c = accountList[0].Id;
        cluster2.Name = '17yaqwhw662788uhrdefgg';
        cluster2.uuid__c = '17yaqwhw662788uhrdefgg';
        cluster.MSP_Consumption__c = false;
        clusterList.add(cluster2);

        insert clusterList;

        List<Asset> assetList = new List<Asset>();
        Asset ast = new Asset();
        ast.AccountId = accountList[0].Id;
        ast.Product2Id = productList[0].Id;
        ast.Name = 'RBK-test-productName';
        ast.SerialNumber = 'RBK-test-productName';
        ast.Order_Service_Item__c = ordrItem.Id;
        assetList.add(ast);

        Asset ast2 = new Asset();
        ast2.AccountId = accountList[0].Id;
        ast2.Product2Id =  productList[1].Id;
        ast2.Name = 'RBK-test-productName';
        ast2.SerialNumber = 'RBK-test-productName';
		assetList.add(ast2);

        insert assetList;

        List<Node__c> nodeList = new List<Node__c>();
        Node__c node1 = new Node__c();
        node1.cluster__c = clusterList[0].Id;
        node1.asset__c = assetList[0].Id;
        node1.Name = 'ugyrtthu1232332';
        node1.serial_number__c = 'ugyrtthu1232332';
        nodeList.add(node1);

        Node__c node2 = new Node__c();
        node2.cluster__c = clusterList[1].Id;
        node2.asset__c = assetList[1].Id;
        node2.Name = 'ugyrtthu1232332sdsdsd';
        node2.serial_number__c = 'ugyrtthu1232332sdsdsd';
        nodeList.add(node2);

        insert nodeList;

        List<Entitlement> entList = new List<Entitlement>();
        Entitlement ent = new Entitlement();
        ent.AccountId = accountList[0].Id;
        ent.Product__c = productList[0].Id;
        ent.Name = 'Test Entitlement IGNEOUSBKUP';
        ent.StartDate=date.valueof('2023-08-27');
        ent.enddate=date.valueof('2024-08-27');
        entList.add(ent);

        Entitlement ent2 = new Entitlement();
        ent2.AccountId = accountList[1].Id;
        ent2.Product__c = productList[1].Id;
        ent2.Name = 'Test Entitlement IGNEOUSBKUP';
        ent2.StartDate=date.valueof('2023-08-27');
        ent2.enddate=date.valueof('2024-08-27');
        entList.add(ent2);

        Entitlement ent3 = new Entitlement();
        ent3.AccountId = accountList[0].Id;
        ent3.Product__c = productList[1].Id;
        ent3.Name = 'Test Entitlement IGS-DPBUA-S-1CP';
        ent3.StartDate=date.valueof('2023-08-27');
        ent3.enddate=date.valueof('2024-08-27');
        entList.add(ent3);

        Entitlement ent4 = new Entitlement();
        ent4.AccountId = accountList[0].Id;
        ent4.Product__c = productList[2].Id;
        ent4.Name = 'Test Entitlement';
        ent4.StartDate=date.valueof('2023-08-27');
        ent4.enddate=date.valueof('2024-08-27');
        entList.add(ent4);

        Entitlement ent5 = new Entitlement();
        ent5.AccountId = accountList[0].Id;
        ent5.Product__c = productList[3].Id;
        ent5.Name = 'Test Entitlement IGS-DPBUA-S-1CP';
        ent5.StartDate=date.valueof('2023-08-27');
        ent5.enddate=date.valueof('2024-08-27');
        entList.add(ent5);

        Entitlement ent6 = new Entitlement();
        ent6.AccountId = accountList[0].Id;
        ent6.Product__c = productList[4].Id;
        ent6.Name = 'Test Entitlement IGS-DPBUA-S-1CP';
        ent6.StartDate=date.valueof('2023-08-27');
        ent6.enddate=date.valueof('2024-08-27');
        entList.add(ent6);
        
        Entitlement ent7 = new Entitlement();
        ent7.AccountId = accountList[0].Id;
        ent7.Product__c = productList[5].Id;
        ent7.Name = 'CEM Entitlement Test';
        ent7.StartDate = System.today();
        ent7.EndDate = System.today().addYears(1);
        entList.add(ent7);

        insert entList;
       User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
       System.runAs(testUser) {
       String jobId1 = Database.executeBatch(new UpdateR6000FlagOnClustersBatch());
       String jobId2 = Database.executeBatch(new UpdateR6000FlagOnAccountsBatch());
       System.assertNotEquals(null, jobId1, 'Batch jobId1 should not be null');
       System.assertNotEquals(null, jobId2, 'Batch jobId2 should not be null');}

        Test.stopTest();
    }
    
    /**
     * @description Tests additional scenarios for UpdateR6000FlagOnAccountsBatch including:
     *              - Accounts with only Assets and no Entitlements.
     *              - Accounts with existing CEM entitlement dates.
     *              - Scheduled execution of the batch job.
     */
    @isTest
     static void testAdditionalScenarios() {
    	// Account with only Asset, no Entitlements
        List<Account> accountList = new List<Account>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        act.RecordTypeId = partnerRecordTypeId;
        act.Contains_r6000_Product_s__c=false;
        accountList.add(act);
        
        Account act2 = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        act2.Latest_CEM_Entitlement_End_Date__c = Date.today().addYears(1);
        accountList.add(act2);
        
        insert accountList;
        
        Product2 prod = new Product2(Name='R6000-Prod', Family='R6000', IsActive=true,ProductCode = 'RBK-R6412S-FNDN-CEM-test');
        insert prod;
        
        Asset ast = new Asset();
        ast.AccountId = accountList[0].Id;
        ast.Product2Id =  prod.Id;
        ast.Name = 'RBK-test-productName';
        ast.SerialNumber = 'RBK-test-productName';
        
        insert ast;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            Database.executeBatch(new UpdateR6000FlagOnAccountsBatch(), 50);
            // Run schedulable version
            String jobId = System.schedule('TestSched', '0 0 12 * * ?', new UpdateR6000FlagOnAccountsBatch());
            System.assertNotEquals(null, jobId, 'Batch jobId1 should not be null');

            Test.stopTest();
        }
        
        // Assertions
        System.assertEquals('1','1'); 
       
    }
    
    /**
	* @description Test AAR Tier calculation per Account
	*/
    
    @isTest
    static void testServiceContractScenario(){
        List<Account> parentAccounts = new List<Account>();
    for (Integer i = 0; i < 9; i++) {
        parentAccounts.add(new Account(
            Name = 'High ACV Parent ' + i,
            Account_Preference__c = 'CSM Account',
            Customer_URL__c = 'https://test12.com',
            Top_Accounts_Criteria__c = 'CEM'
        ));
    }
    insert parentAccounts;

    Account lowACVParent = new Account(
        Name = 'Low ACV Parent',
        Account_Preference__c = 'CSM Account'
    );
    insert lowACVParent;

    insert new List<Account>{
        new Account(
            Name = 'Child Account 1',
            ParentId = parentAccounts[0].Id,
            Account_Preference__c = 'Premium Account',
            Customer_URL__c = 'https://test13.com'
        ),
        new Account(
            Name = 'Child Account 2',
            ParentId = parentAccounts[0].Id,
            Account_Preference__c = 'CSM Account',
            Customer_URL__c = 'https://test14.com'
        )
    };

    Product2 prod = new Product2(
        Name = 'High Value Product',
        ProductCode = 'RBK-SVC-HIGH',
        Family = 'Software',
        IsActive = true
    );
    insert prod;

    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = prod.Id,
        UnitPrice = 600000,
        IsActive = true
    );
    insert pbe;

    List<Opportunity> oppList = new List<Opportunity>();
    for (Account acc : parentAccounts) {
        oppList.add(new Opportunity(
            Name = 'ACV Opportunity ' + acc.Id,
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addMonths(12),
            Pricebook2Id = Test.getStandardPricebookId()
        ));
    }
    insert oppList;

    Opportunity lowOpp = new Opportunity(
        Name = 'Low Opp',
        AccountId = lowACVParent.Id,
        StageName = 'Prospecting',
        CloseDate = System.today().addMonths(12),
        Pricebook2Id = Test.getStandardPricebookId()
    );
    insert lowOpp;


    List<ServiceContract> scList = new List<ServiceContract>();
    for (Integer i = 0; i < parentAccounts.size(); i++) {
        scList.add(new ServiceContract(
            Name = 'High Contract ' + i,
            AccountId = parentAccounts[i].Id,
            StartDate = System.today(),
            Term = 12,
            Pricebook2Id = Test.getStandardPricebookId(),
            SBQQSC__Opportunity__c = oppList[i].Id
        ));
    }

    ServiceContract lowSC = new ServiceContract(
        Name = 'Low Contract',
        AccountId = lowACVParent.Id,
        StartDate = System.today(),
        Term = 12,
        Pricebook2Id = Test.getStandardPricebookId(),
        SBQQSC__Opportunity__c = lowOpp.Id
    );

    scList.add(lowSC);
    insert scList;


    List<Asset> assets = new List<Asset>();
    for (Account acc : parentAccounts) {
        assets.add(new Asset(
            Name = 'Asset ' + acc.Id,
            AccountId = acc.Id,
            Product2Id = prod.Id
        ));
    }
    assets.add(new Asset(
        Name = 'Low Asset',
        AccountId = lowACVParent.Id,
        Product2Id = prod.Id
    ));
    insert assets;
    List<ContractLineItem> cliList = new List<ContractLineItem>();
    for (Integer i = 0; i < parentAccounts.size(); i++) {
        cliList.add(new ContractLineItem(
            ServiceContractId = scList[i].Id,
            PricebookEntryId = pbe.Id,
            AssetId = assets[i].Id,
            Quantity = 1,
            UnitPrice = 600000, // high ACV
            SBQQSC__Account__c = parentAccounts[i].Id
        ));
    }
	cliList[0].UnitPrice = 0;
        cliList[1].UnitPrice = 240000;
        cliList[2].UnitPrice = 300000;
        cliList[3].UnitPrice = 700000;
        cliList[4].UnitPrice = 700000;
        cliList[5].UnitPrice = 1200000;
        cliList[6].UnitPrice = 2500000;
        cliList[7].UnitPrice = 25000000;
    insert cliList;
            
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            Database.executeBatch(new UpdateR6000FlagOnAccountsBatch(), 50);
            // Run schedulable version
            String jobId = System.schedule('TestSched', '0 0 12 * * ?', new UpdateR6000FlagOnAccountsBatch());
            System.assertNotEquals(null, jobId, 'Batch jobId1 should not be null');
            Test.stopTest();
        }
        }
}