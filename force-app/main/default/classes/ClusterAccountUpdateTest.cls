@isTest
public with sharing class ClusterAccountUpdateTest {
    @IsTest
    static void testPositiveScenario(){
        insert new list<TriggerControl__c> {
           new TriggerControl__c(Name='Cluster', DisableTrigger__c=false),
           new TriggerControl__c(Name='Asset', DisableTrigger__c=false)
        };
        
        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        Account acctUnassigned = new Account(
            Name = 'Unassigned',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert new List<Account>{acct, acctUnassigned};

        Cluster__c clus = new Cluster__c();
        clus.Name= 'test';
        clus.uuid__c= 'test';
        clus.software_version__c = '4.0';
        clus.Account__c = acctUnassigned.Id;
        insert clus;

        List<Product2> products = new List<Product2> {
            //apliance
            new Product2(
                Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
                Category__c = 'Platform',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(
                Name = 'RBK-R348S-UG-01',
                ProductCode = 'RBK-R348S-UG-01',
                Category__c = 'Software',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'RBK-R348S',
                Appliance_Model_HW__c = 'R348',
                Single_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(Name = 'RBK-R348-01-NFR',
                ProductCode = 'RBK-R348-01-NFR',
                Category__c = 'NFR',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            )
        };

        insert products;

        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN1', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = products[1].Id, Accountid = acct.Id),
            new Asset(Name = 'SN2', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = products[1].Id, Accountid = acct.Id),
            new Asset(Name = 'SN3', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN3', Serial_Number__c = 'SN3', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN4', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN4', Serial_Number__c = 'SN4', Product2Id = products[0].Id, Accountid = acct.Id)

        };
        insert assets;

        List<Node__c> nodes = new List<Node__c>{
            new Node__c(Name = 'TestNodeSer1', serial_number__c = 'TestNodeSer1', cluster__c = clus.Id, asset__c = assets[0].Id),
            new Node__c(Name = 'TestNodeSer2', serial_number__c = 'TestNodeSer2', cluster__c = clus.Id, asset__c = assets[1].Id),
            new Node__c(Name = 'TestNodeSer3', serial_number__c = 'TestNodeSer3', cluster__c = clus.Id, asset__c = assets[2].Id),
            new Node__c(Name = 'TestNodeSer4', serial_number__c = 'TestNodeSer4', cluster__c = clus.Id, asset__c = assets[3].Id)
        };
        insert nodes;

        Test.startTest();
        ClusterAccountUpdate ob = new ClusterAccountUpdate();
        Database.executeBatch(ob, 100);

        ClusterAccountUpdate sch1 = new ClusterAccountUpdate();
        String sch = '0 0 * * * ?';
        system.schedule('Test ClusterAccountUpdate', sch, sch1);

        Test.stopTest();
        Cluster__c cluster = [Select Id, Account__c from Cluster__c];
        System.assertEquals(acct.Id, cluster.Account__c);
    }

    @IsTest
    static void testNegativeScenario1(){
        insert new TriggerControl__c(Name='Cluster', DisableTrigger__c=false);
        
        Account acctUnassigned = new Account(
            Name = 'Unassigned',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert acctUnassigned;

        Cluster__c clus = new Cluster__c();
        clus.Name= 'test';
        clus.uuid__c= 'test';
        clus.software_version__c = '4.0';
        clus.Account__c = acctUnassigned.Id;
        insert clus;

        Test.startTest();
        ClusterAccountUpdate ob = new ClusterAccountUpdate();
        Database.executeBatch(ob, 100);
        Test.stopTest();
        Cluster__c cluster = [Select Id, Account__c from Cluster__c];
        System.assertEquals(acctUnassigned.Id, cluster.Account__c);
    }

    @IsTest
    static void testNegativeScenario2(){
        insert new TriggerControl__c(Name='Cluster', DisableTrigger__c=false);
        
        Account acctUnassigned = new Account(
            Name = 'Unassigned',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert acctUnassigned;

        Cluster__c clus = new Cluster__c();
        clus.Name= 'test';
        clus.uuid__c= 'test';
        clus.software_version__c = '4.0';
        clus.Account__c = acctUnassigned.Id;
        insert clus;

        List<Product2> products = new List<Product2> {
            //apliance
            new Product2(
                Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
                Category__c = 'Platform',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(
                Name = 'RBK-R348S-UG-01',
                ProductCode = 'RBK-R348S-UG-01',
                Category__c = 'Software',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'RBK-R348S',
                Appliance_Model_HW__c = 'R348',
                Single_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(Name = 'RBK-R348-01-NFR',
                ProductCode = 'RBK-R348-01-NFR',
                Category__c = 'NFR',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            )
        };

        insert products;

        List<Node__c> nodes = new List<Node__c>{
            new Node__c(Name = 'TestNodeSer1', serial_number__c = 'TestNodeSer1', cluster__c = clus.Id),
            new Node__c(Name = 'TestNodeSer2', serial_number__c = 'TestNodeSer2', cluster__c = clus.Id),
            new Node__c(Name = 'TestNodeSer3', serial_number__c = 'TestNodeSer3', cluster__c = clus.Id),
            new Node__c(Name = 'TestNodeSer4', serial_number__c = 'TestNodeSer4', cluster__c = clus.Id)
        };

        insert nodes;

        Test.startTest();
        ClusterAccountUpdate ob = new ClusterAccountUpdate();
        Database.executeBatch(ob, 100);
        Test.stopTest();
        Cluster__c cluster = [Select Id, Account__c from Cluster__c];
        System.assertEquals(acctUnassigned.Id, cluster.Account__c);
    }

    @IsTest
    static void testNegativeScenario3(){
        insert new list<TriggerControl__c> {
           new TriggerControl__c(Name='Cluster', DisableTrigger__c=false),
           new TriggerControl__c(Name='Asset', DisableTrigger__c=false)
        };
        
        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        Account acctUnassigned = new Account(
            Name = 'Unassigned',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert new List<Account>{acct, acctUnassigned};

        Cluster__c clus = new Cluster__c();
        clus.Name= 'test';
        clus.uuid__c= 'test';
        clus.software_version__c = '4.0';
        clus.Account__c = acctUnassigned.Id;
        insert clus;

        List<Product2> products = new List<Product2> {
            //apliance
            new Product2(
                Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
                Category__c = 'Platform',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(
                Name = 'RBK-R348S-UG-01',
                ProductCode = 'RBK-R348S-UG-01',
                Category__c = 'Software',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'RBK-R348S',
                Appliance_Model_HW__c = 'R348',
                Single_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(Name = 'RBK-R348-01-NFR',
                ProductCode = 'RBK-R348-01-NFR',
                Category__c = 'NFR',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            )
        };

        insert products;

        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN1', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = products[1].Id, Accountid = acct.Id),
            new Asset(Name = 'SN2', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = products[1].Id, Accountid = acct.Id),
            new Asset(Name = 'SN3', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN3', Serial_Number__c = 'SN3', Product2Id = products[0].Id, Accountid = acctUnassigned.Id),
            new Asset(Name = 'SN4', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN4', Serial_Number__c = 'SN4', Product2Id = products[0].Id, Accountid = acct.Id)

        };
        insert assets;

        List<Node__c> nodes = new List<Node__c>{
            new Node__c(Name = 'TestNodeSer1', serial_number__c = 'TestNodeSer1', cluster__c = clus.Id, asset__c = assets[0].Id),
            new Node__c(Name = 'TestNodeSer2', serial_number__c = 'TestNodeSer2', cluster__c = clus.Id, asset__c = assets[1].Id),
            new Node__c(Name = 'TestNodeSer3', serial_number__c = 'TestNodeSer3', cluster__c = clus.Id, asset__c = assets[2].Id),
            new Node__c(Name = 'TestNodeSer4', serial_number__c = 'TestNodeSer4', cluster__c = clus.Id, asset__c = assets[3].Id)
        };
        insert nodes;

        Test.startTest();
        ClusterAccountUpdate ob = new ClusterAccountUpdate();
        Database.executeBatch(ob, 100);
        Test.stopTest();
        Cluster__c cluster = [Select Id, Account__c from Cluster__c];
        System.assertEquals(acctUnassigned.Id, cluster.Account__c);
    }
}