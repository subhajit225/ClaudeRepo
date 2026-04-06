@isTest
public with sharing class RMAOrderEventHandlerTest {
    @testSetup
    static void testSetup() {

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
        insert acct;

        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id
        };
        Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert con;
        
        Map<String, Object> caseMap = new Map<String, Object> {
            'Subject' => 'RMA Test',
            'ContactId' => con.Id,
            'Jira_Reference_urls__c' => 'test',
            'Priority' => 'P2',
            'AccountId' => acct.Id
            
        };
        Case caseTest = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap);
        insert caseTest;

        List<Product2> products = new List<Product2> {
            //apliance
            new Product2(Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
                Category__c = 'Platform',
                Family = 'R300',
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
            new Asset(Name = 'SN1', SW_Version__c = '0.1', SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN2', SW_Version__c = '0.2', SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN3', SW_Version__c = '0.3', SerialNumber = 'SN3', Serial_Number__c = 'SN3', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN4', SW_Version__c = '0.4', SerialNumber = 'SN4', Serial_Number__c = 'SN4', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN5', SW_Version__c = '0.5', SerialNumber = 'SN5', Serial_Number__c = 'SN5', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN6', SW_Version__c = '0.6', SerialNumber = 'SN6', Serial_Number__c = 'SN6', Product2Id = products[0].Id, Accountid = acct.Id)
        };
        insert assets;

        List<Cluster__c> clusters = new List<Cluster__c> {
            new Cluster__c(UUID__c = 'Test1', Name = 'Test1'),
            new Cluster__c(UUID__c = 'Test2', Name = 'Test2')
        };
        insert clusters;

        List<Chassis__c> chassis = new List<Chassis__c>{
            new Chassis__c(Name = 'C8270FH18NB0100', serial_number__c = 'C8270FH18NB0100', asset__c = assets[0].Id, manufactured_date__c = System.now()),
            new Chassis__c(Name = 'C8270FH18NB0101', serial_number__c = 'C8270FH18NB0101', asset__c = assets[1].Id, manufactured_date__c = System.now())
        };

        insert chassis;

        List<Power_Supply__c> psus = new List<Power_Supply__c>{
            new Power_Supply__c(Name = 'P2K22CI46AT3000', asset__c = assets[0].Id, revision__c = '1.3', serial_number__c = 'P2K22CI46AT3000', part_number__c = 'PWS-2K22A-1R', manufactured_date__c = System.now()),
            new Power_Supply__c(Name = 'P2K22CI46AT3001', asset__c = assets[0].Id, revision__c = '1.3', serial_number__c = 'P2K22CI46AT3001', part_number__c = 'PWS-2K22A-1R', manufactured_date__c = System.now())
        };

        insert psus;
        
       

        List<Node__c> nodes = new List<Node__c> {
            //SN-1
            new Node__c(
                Cluster__c = clusters.get(0).Id,
                Asset__c = assets.get(0).Id,
                Serial_Number__c = 'SNN-1-1',
                software_version__c = '1.0.1',
                Name = 'SNN-1-1',
                chassis__c = chassis[0].Id
            ),
            new Node__c(
                Cluster__c = clusters.get(0).Id,
                Asset__c = assets.get(0).Id,
                Serial_Number__c = 'SNN-1-2',
                software_version__c = '1.0.1',
                Name = 'SNN-1-2',
                chassis__c = chassis[0].Id
            )
        };
        insert nodes;
        //inserting HDD
        List<Drive__c> Hdddrives = new List<Drive__c>{
            new Drive__c(Name = '0RV5TST01', asset__c = assets[0].Id,serial_number__c = '0RV5TST01', node__c = nodes[0].Id ,type__c='HDD',manufactured_date__c = System.now()),
            new Drive__c(Name = '0RV5TST02', asset__c = assets[0].Id,serial_number__c = '0RV5TST02', node__c=nodes[0].Id,type__c='HDD', manufactured_date__c = System.now())
        };
        insert Hdddrives;
        // inserting SSD
        List<Drive__c> ssddrives = new List<Drive__c>{
            new Drive__c(Name = '0RV5SSD01', asset__c = assets[0].Id,serial_number__c = '0RV5SSD01', node__c = nodes[0].Id ,type__c='SSD',manufactured_date__c = System.now()),
            new Drive__c(Name = '0RV5SSD02', asset__c = assets[0].Id,serial_number__c = '0RV5SSD02', node__c=nodes[0].Id,type__c='SSD', manufactured_date__c = System.now())
        };
        
        insert ssddrives;
        
        //inserting memory
         List<Memory__c> memory = new List<Memory__c>{
            new Memory__c(Name = '0RV5MEM01', asset__c = assets[0].Id,serial_number__c = '0RV5MEM01', node__c = nodes[0].Id ,manufactured_date__c = System.now()),
            new Memory__c(Name = '0RV5MEM02', asset__c = assets[0].Id,serial_number__c = '0RV5MEM02', node__c=nodes[0].Id,manufactured_date__c = System.now())
        };
        insert memory;
        
        
        


        CountryWithCode__c setting1 = new CountryWithCode__c(Name='India', Code__c = 'IN');
        insert setting1;
        Spares_Mapping__c mapping = new Spares_Mapping__c(Name='Mapping-R348', HDD__c = 'RBK-R348-01' ,SSD__c='RBK-R348-01', Product_Family__c = 'R300',
            Memory__c = 'RBK-R348-01', Chassis__c = 'RBK-R348-01', PSU__c = 'RBK-R348-01',Node__c = 'RBK-R348-01', Appliance_Model__c = 'R348');
        insert mapping;
    }

    public @IsTest
    static void testRMAOrderChassisReplacement(){
        Cluster__c cluster = [Select Id from Cluster__c where Name='Test1'];
        Account acc = [Select Id from Account];
        Case c = [Select Id from Case LIMIT 1];
        RMA_Order__c ord = new RMA_Order__c(Appliance__c = 'SN1', Chasis_Quantity__c = 1, Chassis__c = 'C8270FH18NB0100', 
            Cluster_ID__c = cluster.Id, Cluster__c = 'SNN-1-1', Service_Type__c = 'Next Business Day: 8am', 
            Ship_To_Contact_Name__c = 'Gaurav Jain', Ship_To_Email__c = 'gaurav.j@rubrik.com', 
            Ship_To_Name__c = acc.Id, Ship_To_Phone_Number__c = '8971371780', ShippingCountry__c = 'India', 
            Shipping_City__c = 'Bengaluru', Shipping_Street__c = 'Bellandur', Parent_Case__c = c.Id,
            Shipping_Zip_Postal_Code__c = '560103', Type__c = 'Advanced Replacement', Valid_Support__c = true);

        insert ord;

        ord.Status__c = 'Submitted';
        update ord;

        System.debug([Select Id, Status__c from RMA_Order__c]);
        Test.startTest();
        List<Order> rmaOrder = [Select Id from Order where Type = 'RMA'];
        System.assertEquals(1, rmaOrder.size());
        OrderItem oi = [Select Id, SerialNumber__c from OrderItem LIMIT 1];
        oi.SerialNumber__c = 'C8270FH18NB0102';
        update oi;
        rmaOrder[0].Order_Status__c = 'Shipped';
        update rmaOrder[0];
        Test.stopTest();
        List<Chassis__c> chassis = [Select Id from Chassis__c where Name='C8270FH18NB0102'];
        System.assertEquals(1, chassis.size());
        
    }

    public @IsTest
    static void testRMAOrderPSUReplacement(){
        Cluster__c cluster = [Select Id from Cluster__c where Name='Test1'];
        Account acc = [Select Id from Account];
        Case c = [Select Id from Case LIMIT 1];
        RMA_Order__c ord = new RMA_Order__c(Appliance__c = 'SN1', Power_Supply_Quantity__c = 1, Power_Supply__c = 'P2K22CI46AT3000', 
            Cluster_ID__c = cluster.Id, Cluster__c = 'SNN-1-1', Service_Type__c = 'Next Business Day: 8am', 
            Ship_To_Contact_Name__c = 'Gaurav Jain', Ship_To_Email__c = 'gaurav.j@rubrik.com', 
            Ship_To_Name__c = acc.Id, Ship_To_Phone_Number__c = '8971371780', ShippingCountry__c = 'India', 
            Shipping_City__c = 'Bengaluru', Shipping_Street__c = 'Bellandur', Parent_Case__c = c.Id,
            Shipping_Zip_Postal_Code__c = '560103', Type__c = 'Advanced Replacement', Valid_Support__c = true);

        insert ord;

        ord.Status__c = 'Submitted';
        update ord;

        System.debug([Select Id, Status__c from RMA_Order__c]);
        Test.startTest();
        List<Order> rmaOrder = [Select Id from Order where Type = 'RMA'];
        System.assertEquals(1, rmaOrder.size());
        OrderItem oi = [Select Id, SerialNumber__c from OrderItem LIMIT 1];
        oi.SerialNumber__c = 'P2K22CI46AT3000';
        update oi;
        rmaOrder[0].Order_Status__c = 'Shipped';
        update rmaOrder[0];
        Test.stopTest();
        List<Power_Supply__c> psu = [Select Id from Power_Supply__c where Name='P2K22CI46AT3000'];
        System.assertEquals(1, psu.size());
        
    }
    public @IsTest
    static void testRMAOrderHDDReplacement(){
        Cluster__c cluster = [Select Id from Cluster__c where Name='Test1'];
        Account acc = [Select Id from Account];
        Case c = [Select Id from Case LIMIT 1];
        RMA_Order__c ord = new RMA_Order__c(Appliance__c = 'SN1', Drive_Quantity__c = 1,Drive__c = '0RV5TST01', 
            Cluster_ID__c = cluster.Id, Cluster__c = 'SNN-1-1', Service_Type__c = 'Next Business Day: 8am', 
            Ship_To_Contact_Name__c = 'Gaurav Jain', Ship_To_Email__c = 'gaurav.j@rubrik.com', 
            Ship_To_Name__c = acc.Id, Ship_To_Phone_Number__c = '8971371780', ShippingCountry__c = 'India', 
            Shipping_City__c = 'Bengaluru', Shipping_Street__c = 'Bellandur', Parent_Case__c = c.Id,
            Shipping_Zip_Postal_Code__c = '560103', Type__c = 'Advanced Replacement', Valid_Support__c = true);

        insert ord;

        ord.Status__c = 'Submitted';
        update ord;

        System.debug([Select Id, Status__c from RMA_Order__c]);
        Test.startTest();
        List<Order> rmaOrder = [Select Id from Order where Type = 'RMA'];
        System.assertEquals(1, rmaOrder.size());
        OrderItem oi = [Select Id, SerialNumber__c from OrderItem LIMIT 1];
        oi.SerialNumber__c = '0RV5TST01';
        update oi;
        rmaOrder[0].Order_Status__c = 'Shipped';
        update rmaOrder[0];
        Test.stopTest();
        List<Drive__c> hdddrive = [Select Id from Drive__c where Name='0RV5TST01'];
        System.assertEquals(1, hdddrive.size());
        
    }
    
    //COMMENTING SSD
    public @IsTest
    static void testRMAOrderSSDReplacement(){
        Cluster__c cluster = [Select Id from Cluster__c where Name='Test1'];
        Account acc = [Select Id from Account];
        Case c = [Select Id from Case LIMIT 1];
        RMA_Order__c ord = new RMA_Order__c(Appliance__c = 'SN1', SSD_Quantity__c = 1,SSD__c = '0RV5SSD01', 
            Cluster_ID__c = cluster.Id, Cluster__c = 'SNN-1-1', Service_Type__c = 'Next Business Day: 8am', 
            Ship_To_Contact_Name__c = 'Gaurav Jain', Ship_To_Email__c = 'gaurav.j@rubrik.com', 
            Ship_To_Name__c = acc.Id, Ship_To_Phone_Number__c = '8971371780', ShippingCountry__c = 'India', 
            Shipping_City__c = 'Bengaluru', Shipping_Street__c = 'Bellandur', Parent_Case__c = c.Id,
            Shipping_Zip_Postal_Code__c = '560103', Type__c = 'Advanced Replacement', Valid_Support__c = true);

        insert ord;

        ord.Status__c = 'Submitted';
        update ord;

        System.debug([Select Id, Status__c from RMA_Order__c]);
        Test.startTest();
        List<Order> rmaOrder = [Select Id from Order where Type = 'RMA'];
        System.assertEquals(1, rmaOrder.size());
        OrderItem oi = [Select Id, SerialNumber__c from OrderItem LIMIT 1];
        oi.SerialNumber__c = '0RV5SSD01';
        update oi;
        rmaOrder[0].Order_Status__c = 'Shipped';
        update rmaOrder[0];
        Test.stopTest();
        List<Drive__c> ssddrive = [Select Id from Drive__c where Name='0RV5SSD01'];
        System.assertEquals(1, ssddrive.size());
        
    }
    // Added for Memory
    public @IsTest
    static void testRMAOrderMemoryReplacement(){
        Cluster__c cluster = [Select Id from Cluster__c where Name='Test1'];
        Account acc = [Select Id from Account];
        Case c = [Select Id from Case LIMIT 1];
        RMA_Order__c ord = new RMA_Order__c(Appliance__c = 'SN1', Memory_Quantity__c = 1,Memory__c = '0RV5MEM01', 
            Cluster_ID__c = cluster.Id, Cluster__c = 'SNN-1-1', Service_Type__c = 'Next Business Day: 8am', 
            Ship_To_Contact_Name__c = 'Gaurav Jain', Ship_To_Email__c = 'gaurav.j@rubrik.com', 
            Ship_To_Name__c = acc.Id, Ship_To_Phone_Number__c = '8971371780', ShippingCountry__c = 'India', 
            Shipping_City__c = 'Bengaluru', Shipping_Street__c = 'Bellandur', Parent_Case__c = c.Id,
            Shipping_Zip_Postal_Code__c = '560103', Type__c = 'Advanced Replacement', Valid_Support__c = true);

        insert ord;

        ord.Status__c = 'Submitted';
        update ord;

        System.debug([Select Id, Status__c from RMA_Order__c]);
        Test.startTest();
        List<Order> rmaOrder = [Select Id from Order where Type = 'RMA'];
        System.assertEquals(1, rmaOrder.size());
        OrderItem oi = [Select Id, SerialNumber__c from OrderItem LIMIT 1];
        oi.SerialNumber__c = '0RV5MEM01';
        update oi;
        rmaOrder[0].Order_Status__c = 'Shipped';
        update rmaOrder[0];
        Test.stopTest();
        List<Memory__c> memorylist = [Select Id from Memory__c where Name='0RV5MEM01'];
        System.assertEquals(1, memorylist.size());
        
    }
    
}