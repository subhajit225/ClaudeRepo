@isTest
public class RMAOrderHandlerExtnClass_Test {
    
    /**
    * @author Prashant Kumar
    * @date 11-03-2025
    * @description Test Method For RMA Order.
    */
    public static testMethod void testRMAOrder() {
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
                //Product_NIC_Type__c='SFP+',
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
        
        List<Node__c> nodes = new List<Node__c> {
            //SN-1
            new Node__c(
                Cluster__c = clusters.get(0).Id,
                Asset__c = assets.get(0).Id,
                Serial_Number__c = 'SNN-1-1',
                software_version__c = '1.0.1',
                Name = 'SNN-1-1'
                //chassis__c = chassis[0].Id
            ),
            new Node__c(
                Cluster__c = clusters.get(0).Id,
                Asset__c = assets.get(0).Id,
                Serial_Number__c = 'SNN-1-2',
                software_version__c = '1.0.1',
                Name = 'SNN-1-2'
                //chassis__c = chassis[0].Id
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
        
          List<Power_Supply__c> psus = new List<Power_Supply__c>{
            new Power_Supply__c(Name = 'P2K22CI46AT3000', asset__c = assets[0].Id, revision__c = '1.3', serial_number__c = 'P2K22CI46AT3000', part_number__c = 'PWS-2K22A-1R', manufactured_date__c = System.now()),
            new Power_Supply__c(Name = 'P2K22CI46AT3001', asset__c = assets[0].Id, revision__c = '1.3', serial_number__c = 'P2K22CI46AT3001', part_number__c = 'PWS-2K22A-1R', manufactured_date__c = System.now())
        };

        insert psus;
        set<string> Asnumber= New Set<string>();
        Asnumber.add('SN1');
        Asnumber.add('SN2');
        
        List<string> Nodesrnumber= New List<string>();
        Nodesrnumber.add('SNN-1-1');
        Nodesrnumber.add('SNN-1-1');
        
        List<string> Memsrnumber= New List<string>();
        Nodesrnumber.add('0RV5MEM01');
        Nodesrnumber.add('0RV5MEM02');
        
        List<string> chassissrnumber= New List<string>();
        Nodesrnumber.add('C8270FH18NB0100');
        Nodesrnumber.add('C8270FH18NB0101');
        
        List<string> drivesrnumber= New List<string>();
        Nodesrnumber.add('0RV5SSD01');
        Nodesrnumber.add('0RV5SSD02');
        
        List<string> psusrnumber= New List<string>();
        Nodesrnumber.add('P2K22CI46AT3000');
        Nodesrnumber.add('P2K22CI46AT3001');
        
        CountryWithCode__c setting1 = new CountryWithCode__c(Name='India', Code__c = 'IN');
        insert setting1;
        Spares_Mapping__c mapping = new Spares_Mapping__c(Name='Mapping-R348', HDD__c = 'RBK-R348-01' ,SSD__c='RBK-R348-01', Product_Family__c = 'R300',
            Memory__c = 'RBK-R348-01', Chassis__c = 'RBK-R348-01', PSU__c = 'RBK-R348-01',Node__c = 'RBK-R348-01', Appliance_Model__c = 'R348');
        insert mapping;
       
        PageReference pageRef = Page.RMA_Order_Form;
        Test.setCurrentPage(pageRef);
        Case c = [Select Id from Case LIMIT 1];
        Account insertedAcct = [SELECT Id, Name FROM Account WHERE Id = :acct.Id];
        System.assertNotEquals(null, insertedAcct, 'Account should be created.');
    
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c);
        ApexPages.currentPage().getParameters().put('id', c.Id);
        ApexPages.currentPage().getParameters().put('jsonMapFailureReasonsSelection','{[RVMHM184S000014,RVMHM184S000515]}');
       
      /*  RMAOrderHandlerExtnClass rmaExtn = new RMAOrderHandlerExtnClass(sc);
        rmaExtn.SelectedAssetId=  assets[0].Id;
        rmaExtn.fetchAssetConfigs();
        rmaExtn.fetchSelectedComponent();
        rmaExtn.setAddress();
        rmaExtn.makeComponentInputSeletion();
        rmaExtn.makeAssetSeletion();
        rmaExtn.showClusterField();
        rmaExtn.SaveRMA();*/
       
        set<Id> RmaId = New Set<ID>();
        set<Id> RmaOrderId = New Set<ID>();
        drive__c drivenew = [select id, serial_number__c from drive__c where serial_number__c ='0RV5TST01' limit 1];
        Node__c node = [select id, serial_number__C from Node__c where serial_number__c='SNN-1-1' limit 1];
        Memory__c memoryNew = [select id, serial_number__C from Memory__c where serial_number__C ='0RV5MEM01' limit 1];
       
        RMA_Order__c rma = new RMA_Order__c(parent_case__c =c.id, appliance__c =assets[0].serialNumber, Appliance_Quantity__c=1,
             Service_Type__c='Next Business Day: 8am', ShippingCountry__c ='United States', ShippingState__c='CA',
             Shipping_Street__c='test', Shipping_City__c='palo Alto', Shipping_Zip_Postal_Code__c='12098',
             Ship_To_Contact_Name__c='test contact', Ship_To_Email__c='test@test.com', Ship_To_Name__c=acct.id,Send_Smart_Hands_Service__c = true,Date_of_Smart_Hands_Arrival__c= system.Today() + 5,Time_of_Smart_Hands_Tech_Arrival__c= '15:00');
        rma.drive__c = drivenew.serial_number__c;
        rma.Node__c = node.serial_number__c;
        rma.Memory__c = memoryNew.serial_number__c;
       
        rma.Drive_Quantity__c = 1;
        rma.Node_Quantity__c = 1;
        rma.Memory_Quantity__c = 1;
       
        rma.status__c = 'Submitted';
        insert rma;
        rma.Status__c = 'Approved';
        update rma;
        RmaId.add(rma.Id);
      //  rmaExtn.CompareCountries();
      //  rmaExtn.setsmartHandDate();
      //  RMAOrderHandlerExtnClass.getCounter();
        //RMAOrderService.getCounter();
        
        RMAOrderService.updateRelatedOrders(RmaId);
        RMAOrderService.smartHandRemovedEmails(RmaId);
        RMAOrderService.mailOnResendButton(RmaId);
        
       /* rmaExtn.getOtherProductCode('SNN-1-1','Drive');
        rmaExtn.getOtherProductCode('SN1','chassis');
        rmaExtn.getProductCode('SNN-1-1','Drive');
        rmaExtn.getProductCode('0RV5MEM01','Memory');
        rmaExtn.getProductCode('SNN-1-1','Node');
        rmaExtn.getProductCode('P2K22CI46AT3000','Power Supply');
        rmaExtn.getProductCode('C8270FH18NB0100','Chassis');
        rmaExtn.createOtherFailure(Asnumber,Nodesrnumber,'Drive');
        rmaExtn.createOtherFailure(Asnumber,Nodesrnumber,'Memory');
        rmaExtn.createOtherFailure(Asnumber,Nodesrnumber,'Chassis');
        rmaExtn.createOtherFailure(Asnumber,Nodesrnumber,'SSD');
        rmaExtn.createOtherFailure(Asnumber,Nodesrnumber,'PSU');*/
       
    }
    //Newly Added to cover RMAorderService
    @isTest(SeeAllData=true)
    static void testRMAOrderone() {
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
        Account insertedAcct = [SELECT Id, Name FROM Account WHERE Id = :acct.Id];
        System.assertNotEquals(null, insertedAcct, 'Account should be created.');
    
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
        Case caseRec = [select id, CaseNumber from Case where Account.Name = 'Test Account' LIMIT 1];
        Account accRec = [select id, ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode, ShippingCountry from Account where Name ='Test Account' LIMIT 1];
        List<Order> rmaOrder = [Select Id,RMA_Request__r.Node__c from Order where Type = 'RMA' AND RMA_Request__r.Node__c!='' LIMIT 5];
        set<ID> orderID = New set<ID>();
        for(order od1 : rmaOrder )
        {
        orderID.add(od1.ID);
        }
        List<RMA_Order__c> rmalist = New List<RMA_Order__c>();
        RMA_Order__c RMAOrdertest =new RMA_Order__c();
        RMAOrdertest =[select ID, Parent_Case__c,Parent_Case__r.AccountID, Ship_To_Phone_Number__c,Ship_To_Contact_Name__c,Ship_To_Name__c,Ship_To_Name__r.Name,Ship_To_Email__c, Parent_Case__r.Account.Distributor__c,Parent_Case__r.Account.Distributor__r.Payment_Term__c,
                                     Memory__c, Power_Supply__c, Status__c, Node__c, Drive__c,SSD__C, NIC__c,Chassis__c,Service_Type__c, Shipping_Street__c, Shipping_City__c, Shipping_Zip_Postal_Code__c,
                                    RMA_Country__c,RMA_State__c, Node_Quantity__c, Drive_Quantity__c, Chasis_Quantity__c,Memory_Quantity__c, Power_Supply_Quantity__c, NIC_Quantity__c, Appliance_Quantity__c, Cluster_ID__c, Appliance__c, CMOS_Battery__c, CMOS_Battery_Quantity__c,
                                     Parent_Case__r.Account.Distributor__r.Shipping_Carrier__c , Parent_Case__r.Account.Distributor__r.Shipping_Method__c , Parent_Case__r.Account.Distributor__r.Shipping_Account_Number__c,Parent_Case__r.Account.Distributor__r.IncoTerms__c
                                     from RMA_Order__C  where Appliance__c != null LIMIT 1];
                                     
          rmalist =[select ID, Parent_Case__c,Parent_Case__r.AccountID, Ship_To_Phone_Number__c,Ship_To_Contact_Name__c,Ship_To_Name__c,Ship_To_Name__r.Name,Ship_To_Email__c, Parent_Case__r.Account.Distributor__c,Parent_Case__r.Account.Distributor__r.Payment_Term__c,
                                     Memory__c, Power_Supply__c, Status__c, Node__c, Drive__c,SSD__C, NIC__c,Chassis__c,Service_Type__c, Shipping_Street__c, Shipping_City__c, Shipping_Zip_Postal_Code__c,
                                    RMA_Country__c,RMA_State__c, Node_Quantity__c, Drive_Quantity__c, Chasis_Quantity__c,Memory_Quantity__c, Power_Supply_Quantity__c, NIC_Quantity__c, Appliance_Quantity__c, Cluster_ID__c, Appliance__c, CMOS_Battery__c, CMOS_Battery_Quantity__c,
                                     Parent_Case__r.Account.Distributor__r.Shipping_Carrier__c , Parent_Case__r.Account.Distributor__r.Shipping_Method__c , Parent_Case__r.Account.Distributor__r.Shipping_Account_Number__c,Parent_Case__r.Account.Distributor__r.IncoTerms__c
                                     from RMA_Order__C  where Appliance__c != null LIMIT 5];
        //Create and Insert Asset
       Asset assetRec = new Asset(
       Name = 'Test Asset',
       serialNumber='Test Asset',
       Serial_Number__c = 'Test Asset',
       Status = 'Installed',
       AccountId = accRec.Id,
       InstallDate = System.Today(),
       Product2Id = system.label.ProductIdforTest,
       UsageEndDate = System.Today()
       );
       insert assetRec;
        
        PageReference pageRef = Page.RMA_Order_Form;
        Test.setCurrentPage(pageRef);
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(caseRec);
        ApexPages.currentPage().getParameters().put('id', CaseRec.Id);
        ApexPages.currentPage().getParameters().put('jsonMapFailureReasonsSelection','{[RVMHM184S000014,RVMHM184S000515]}');
       
    
        
       /* RMAOrderHandlerExtnClass rmaExtn = new RMAOrderHandlerExtnClass(sc);
        rmaExtn.SelectedAssetId= assetRec.Id;
        rmaExtn.fetchAssetConfigs();
        rmaExtn.fetchSelectedComponent();
        rmaExtn.setAddress();
        rmaExtn.makeComponentInputSeletion();
        rmaExtn.makeAssetSeletion();
        rmaExtn.showClusterField();
        rmaExtn.SaveRMA();*/
        RMAOrderService.associateNodes(orderID);
        RMAOrderService.sendEmailtoFlash(orderID);
        
        
        drive__c drive = [select id, serial_number__C from drive__c limit 1];
        Node__c node = [select id, serial_number__C from Node__c limit 1];
        Memory__c memory = [select id, serial_number__C from Memory__c limit 1];
        Power_Supply__c psu = [select id, serial_number__C from Power_Supply__c limit 1];
        NIC__c nic = [select id, serial_number__C from NIC__c limit 1];
        Chassis__c chassis = [select id, serial_number__C from Chassis__c limit 1];
        
        
        RMA_Order__c rma = new RMA_Order__c(Appliance__c = assetRec.serialNumber,Appliance_Quantity__c=1, Service_Type__c = 'Next Business Day: 8am', 
            Ship_To_Contact_Name__c = 'Gaurav Jain', Ship_To_Email__c = 'gaurav.j@rubrik.com', ShippingCountry__C = 'India',
            Ship_To_Name__c = acct.Id, Ship_To_Phone_Number__c = '8971371780', RMA_Country__c= 'India',RMA_State__c='Maharashtra',
            Shipping_City__c = 'Bengaluru', Shipping_Street__c = 'Bellandur', Parent_Case__c = caseRec.Id,
            Shipping_Zip_Postal_Code__c = '560103', Type__c = 'Advanced Replacement', Valid_Support__c = true);
        rma.drive__c = drive.serial_number__c;
        rma.Node__c = node.serial_number__c;
        rma.Memory__c = memory.serial_number__c;
        //rma.NIC__c = nic.serial_number__c;
        rma.Chassis__c = chassis.serial_number__c;
        rma.Power_Supply__c = psu.serial_number__c;
        
       rma.Drive_Quantity__c = 1;
        rma.Node_Quantity__c = 1;
        rma.Memory_Quantity__c = 1;
        rma.NIC_Quantity__c = 1;
        rma.Chasis_Quantity__c = 1;
        rma.Power_Supply_Quantity__c = 1;
        
        rma.status__c = 'Submitted';
        insert rma;
        rma.Status__c = 'Approved';
        update rma;
        test.startTest();
        RMAOrderService.createOrderWithOrderItems(rma.Id);
        //RMAOrderService.createOrder(rmalist);
        
        test.stopTest();
    }

       /**
    * @author Prashant Kumar
    * @date 11-03-2025
    * @description Test pagination On RMA Request..
    */
    
    public static testMethod void testPaginatedList() {
        PaginatedSelectList clusterIDOptionsList = new PaginatedSelectList();
         
                
                clusterIDOptionsList.add(new SelectOption('--None--','--None--'));
                for(integer i=0;i<20000;i++){
                    clusterIDOptionsList.add(new SelectOption('Other'+i,'Other'+i));
                }
                System.assertEquals(20001, clusterIDOptionsList.getSize(), 'Size of the list should be 20001 after adding 20000 items');

        clusterIDOptionsList.getSize();
        clusterIDOptionsList.get(1);
        clusterIDOptionsList.remove(2);
        clusterIDOptionsList.clear();
        clusterIDOptionsList.getSelectList();
        clusterIDOptionsList.get1();
clusterIDOptionsList.get2();
clusterIDOptionsList.get3();
clusterIDOptionsList.get4();
clusterIDOptionsList.get5();
clusterIDOptionsList.get6();
clusterIDOptionsList.get7();
clusterIDOptionsList.get8();
clusterIDOptionsList.get9();
clusterIDOptionsList.get10();
clusterIDOptionsList.get11();
clusterIDOptionsList.get12();
clusterIDOptionsList.get13();
clusterIDOptionsList.get14();
clusterIDOptionsList.get15();
clusterIDOptionsList.get16();
clusterIDOptionsList.get17();
clusterIDOptionsList.get18();
clusterIDOptionsList.get19();
        clusterIDOptionsList.getNthSubList(1);
        
        clusterIDOptionsList.getSubList(1, 10);
        // clusterIDOptionsList.
        // clusterIDOptionsList.
        // clusterIDOptionsList.
        
        RMASparePartsMappingHelper.returnSparePartCode('R6000', '10GBase-T', 'RBK-R6404S');
        //RMASparePartsMappingHelper.returnSparePartCode('R6000', '10GBase-T', '');
        RMASparePartsMappingHelper.returnSparePartCode('R6000', '', '');
        
       }
}