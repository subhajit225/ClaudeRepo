/***************************************************************************************
Description : Test class for Third party asset tie back PRDOPS21-310
Date : October 2020
***************************************************************************************** */
@isTest
public class ThirdPartyAssetUpdateBatchTest{
 @testSetup 
       static void setup() {
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
        Account acct = new Account(Name='Unassigned', RecordTypeId = partnerRecordTypeId);
        Account acc = new Account(Name='testAccount1');
        insert new List<Account>{acct, acc};

        Contact con = new Contact(FirstName='john', LastName='doe', Email='john@doe.com', AccountId=acct.Id);
        insert con;
        Opportunity oppr = TestDataFactory.getOpportunity(acct, con);
        insert oppr;

        Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true, Product_Level__c = 'LOD Software');
        insert pd;

        Id standardPriceBookId =  Test.getStandardPricebookId();

        Id pricebookId = Test.getStandardPricebookId();

        List<product2> prodList = new List<product2>();
        prodList.add(new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            SBQQ__SubscriptionPricing__c ='Fixed Price',
            SBQQSC__EntitlementConversion__c ='One per unit',
            isActive = true,
            Product_Level__c = 'OnPrem',
            Product_Type__c = 'Enterprise Edition'
        ));
        prodList.add(new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            SBQQ__SubscriptionPricing__c ='Fixed Price',
            SBQQSC__EntitlementConversion__c ='One per unit',
            isActive = true
        ));
        prodList.add(new Product2(
            Name = 'RBK-REDGE-10-MO-CLOUT',
            ProductCode = 'RBK-REDGE-10-MO',
            SBQQ__SubscriptionPricing__c ='Fixed Price',
            SBQQSC__EntitlementConversion__c ='One per unit',
            isActive = true
        ));
        prodList.add(new Product2(
            Name = 'RBK-RCDM-10-MO-CLON',
            ProductCode = 'RBK-RCDM-AWS-MO',
            SBQQ__SubscriptionPricing__c ='Fixed Price',
            SBQQSC__EntitlementConversion__c ='One per unit',
            isActive = true,
            Product_Level__c = 'LOD Software'

        ));
         insert prodList ;
        List<PricebookEntry> PBEList = new List<PricebookEntry>();
        PBEList.add(new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prodList[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        ));
        PBEList.add(new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prodList[1].Id,
            UnitPrice = 1000.00,
            IsActive = true
        ));
        PBEList.add(new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prodList[2].Id,
            UnitPrice = 1000.00,
            IsActive = true
        ));
        PBEList.add(new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prodList[3].Id,
            UnitPrice = 1000.00,
            IsActive = true
        ));
                insert PBEList;
        List<Order> ordrList = new List<Order>();
        ordrList.add(new Order(Type='Revenue' ,  AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
            ShippingCity ='Test City',
            ShippingState =null,
            EDI_Sync_Status__c ='N',
            ShippingCountry ='Austria',
            ShippingPostalcode ='94820',
            Pricebook2Id =standardPriceBookId,
            EffectiveDate=system.Today(), Status='Pending'
        ));

        ordrList.add(new Order(Type='Revenue',AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
            ShippingCity ='Test City',
            ShippingState =null,
            EDI_Sync_Status__c ='N',
            ShippingCountry ='Austria',
            ShippingPostalcode ='94820',
            Pricebook2Id = standardPriceBookId,
            EffectiveDate=system.Today(), Status='Pending'
        ));

        ordrList.add(new Order(Type='Revenue',AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
            ShippingCity ='Test City',
            ShippingState =null,
            EDI_Sync_Status__c ='E',
            ShippingCountry ='Austria',
            ShippingPostalcode ='94820',
            Pricebook2Id = standardPriceBookId,
            EffectiveDate=system.Today(), Status='Pending'
        ));
        insert ordrList;

        ordrList[0].Pricebook2Id = ordrList[1].Pricebook2Id = standardPriceBookId;
        update ordrList ;
        
        List<Asset> assetList = new List<Asset>();
        assetList.add(new Asset(
            Name= 'TestSuccAsst00A', SerialNumber= 'TestSuccAsst00A',Serial_Number__c= 'TestSuccAsst00A',Product2ID=prodList[0].Id,
            Accountid =acct.Id
        ));
        assetList.add(new Asset(
            Name= 'TestSuccAsst00A1', SerialNumber= 'TestSuccAsst00A1',Serial_Number__c= 'TestSuccAsst00A1',Product2ID=prodList[1].Id,
            Accountid =acct.Id
        ));
        assetList.add(new Asset(
            Name= 'TestSuccAsst00A2', SerialNumber= 'TestSuccAsst00A2',Serial_Number__c= 'TestSuccAsst00A2',Product2ID=prodList[2].Id,
            Accountid =acct.Id
        ));
        assetList.add(new Asset(
            Name= 'TestSuccAsst00A3', SerialNumber= 'TestSuccAsst00A3',Serial_Number__c= 'TestSuccAsst00A3',Product2ID=prodList[3].Id,
            Accountid =acct.Id
        ));
        assetList.add(new Asset(
            Name= 'TestSuccAsst00B', SerialNumber= 'TestSuccAsst00B',Serial_Number__c= 'TestSuccAsst00B',Product2ID=prodList[3].Id,
            Accountid =acct.Id
        ));
        assetList.add(new Asset(
            Name= 'TestSuccAsst00B1', SerialNumber= 'TestSuccAsst00B1',Serial_Number__c= 'TestSuccAsst00B1',Product2ID=prodList[3].Id,
            Accountid =acct.Id
        ));
        assetList.add(new Asset(
            Name= 'TestErrAsst01', SerialNumber= 'TestErrAsst01',Serial_Number__c= 'TestErrAsst01',Product2ID=prodList[3].Id,
            Accountid =acct.Id
        ));
        assetList.add(new Asset(
            Name= 'TestErrAsst02', SerialNumber= 'TestErrAsst02',Serial_Number__c= 'TestErrAsst02',Product2ID=prodList[3].Id,
            Accountid =acct.Id
        ));
        assetList.add(new Asset(
            Name= 'TestErrAsst03', SerialNumber= 'TestErrAsst03',Serial_Number__c= 'TestErrAsst03',Product2ID=prodList[3].Id,
            Accountid =acct.Id
        ));
        insert assetList;
        List<orderItem> OIList = new List<OrderItem>();
        Test.startTest(); 
            OIList.add(new OrderItem(
            OrderId = ordrList[0].Id,
            Quantity = 1,
            PricebookEntryId = PBEList[0].Id,
            UnitPrice = PBEList[0].UnitPrice,
            EDI_Line_Number__c = '00A',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));
        OIList.add(new OrderItem(
            OrderId = ordrList[0].Id,
            Quantity = 1,
            PricebookEntryId = PBEList[1].Id,
            UnitPrice =  PBEList[1].UnitPrice,
            EDI_Line_Number__c = '00A1' ,
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));      
        OIList.add(new OrderItem(
            OrderId = ordrList[0].Id,
            Quantity = 1,
            EDI_Line_Number__c = '00A2',
            PricebookEntryId = PBEList[2].Id,
            UnitPrice =  PBEList[2].UnitPrice,
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));
         OIList.add(new OrderItem(
            OrderId = ordrList[0].Id,
            Quantity = 1,
            EDI_Line_Number__c = '00A3',
            PricebookEntryId = PBEList[2].Id,
            UnitPrice =  PBEList[2].UnitPrice,
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'
        ));
         OIList.add(new OrderItem(
            OrderId = ordrList[0].Id,
            Quantity = 2,
            EDI_Line_Number__c = '00A4',
            PricebookEntryId = PBEList[2].Id,
            UnitPrice =  PBEList[2].UnitPrice,
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));
         OIList.add(new OrderItem( 
            OrderId = ordrList[1].Id,
            Quantity = 1,
            EDI_Line_Number__c = '00B',
            PricebookEntryId = PBEList[2].Id,
            UnitPrice =  PBEList[2].UnitPrice, 
            SerialNumber__c = 'SerialNumberAssigned',  
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));
        OIList.add(new OrderItem(
            OrderId = ordrList[1].Id,
            Quantity = 1,
             EDI_Line_Number__c = '00B1',
            PricebookEntryId = PBEList[3].Id,
            UnitPrice =  PBEList[3].UnitPrice,
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));
       OIList.add(new OrderItem(
            OrderId = ordrList[1].Id,
            Quantity = 1,
             EDI_Line_Number__c = 'ErrorDateFormat',
            PricebookEntryId = PBEList[3].Id,
            UnitPrice =  PBEList[3].UnitPrice,
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));
        OIList.add(new OrderItem( 
            OrderId = ordrList[1].Id,
            Quantity = 1,
            EDI_Line_Number__c = 'ProductNameMismatcherr',
            PricebookEntryId = PBEList[1].Id,
            UnitPrice =  PBEList[1].UnitPrice, 
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));
        OIList.add(new OrderItem( 
            OrderId = ordrList[1].Id,
            Quantity = 12,
            EDI_Line_Number__c = 'QuantityMismatch',
            PricebookEntryId = PBEList[1].Id,
            UnitPrice =  PBEList[1].UnitPrice, 
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));
        OIList.add(new OrderItem( 
            OrderId = ordrList[1].Id,
            Quantity = 2,
            EDI_Line_Number__c = 'SerialMismatch',
            PricebookEntryId = PBEList[1].Id,
            UnitPrice =  PBEList[1].UnitPrice, 
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        )); 
        OIList.add(new OrderItem(
            OrderId = ordrList[2].Id,
            Quantity = 1,
            EDI_Line_Number__c = 'FailedtoSend855',
            PricebookEntryId = PBEList[2].Id,
            UnitPrice =  PBEList[2].UnitPrice,
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            TPH_Quantity__c = '3'

        ));
        insert OIList;
        OIList[1].SBQQ__RequiredBy__c =OIList[2].SBQQ__RequiredBy__c= OIList[0].id ;
        update new List<OrderItem>{OIList[1],OIList[2]} ;
        List<Entitlement> entList = new List<Entitlement>();
        entList.add(new Entitlement(Name='Testing', AccountId=acct.Id, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)), Product__C = prodList[0].id,Order_Service_Item__c = OIList[0].id));
        entList.add(new Entitlement(Name='Testing', AccountId=acct.Id, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)), Product__C = prodList[1].Id,Order_Service_Item__c = OIList[1].id));
        entList.add(new Entitlement(Name='test2', AccountId=acct.Id, StartDate=Date.valueof(System.now().addDays(-10)), EndDate=Date.valueof(System.now().addMonths(4)), Product__C = prodList[3].Id,Order_Service_Item__c = OIList[4].id));
        entList.add(new Entitlement(Name='test2', AccountId=acct.Id, StartDate=Date.valueof(System.now().addDays(-10)), EndDate=Date.valueof(System.now().addMonths(4)), Product__C = prodList[3].Id,Order_Service_Item__c = OIList[5].id));
        insert entList;

        ThirdPartyMonitor__c TPM = new ThirdPartyMonitor__c(Status__c='Start',Send_ASN_Acknowlegment_To__c='Distributor;OM Team');
        insert TPM ;
        List<ThirdPartyHardware__c> TPH = new List<ThirdPartyHardware__c>();
        Map<Id,string>OrdIdNumber = new Map<Id,string>();
        for(Order ord :[select id,ordernumber from order]){
          OrdIdNumber.put(ord.id,ord.ordernumber);
        }
        for(OrderItem OI :[select id,order.ordernumber,Product2.productcode,Quantity, EDI_Line_Number__c from orderItem where EDI_Line_Number__c NOT IN ('00A1','00A2')]){
          if(OI.EDI_Line_Number__c =='ProductNameMismatcherr'){
             TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,EDILineNumber__c=OI.EDI_Line_Number__c,FileName__c='ProductNameMismatcherr',OrderNumber__c=OI.order.ordernumber,Name='TestErr',Quantity__c=OI.Quantity,SerialNumber__c='TestErrAsst01',ShipDate__c=string.valueof(system.today().format())));
          }
          else if(OI.EDI_Line_Number__c=='QuantityMismatch'){
              TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,EDILineNumber__c=OI.EDI_Line_Number__c,FileName__c='QuantityMismatch',OrderNumber__c=OI.order.ordernumber,Name=OI.Product2.productcode,Quantity__c=1,SerialNumber__c='TestErrAsst02',ShipDate__c=string.valueof(system.today().format())));
              TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,EDILineNumber__c=OI.EDI_Line_Number__c,FileName__c='Duplicate record',OrderNumber__c=OI.order.ordernumber,Name=OI.Product2.productcode,Quantity__c=OI.Quantity,SerialNumber__c='TestErrAsst02A',ShipDate__c=string.valueof(system.today().format())));

          }
          else if(OI.EDI_Line_Number__c=='SerialMismatch'){
              TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,EDILineNumber__c=OI.EDI_Line_Number__c,FileName__c=OI.Product2.productcode,OrderNumber__c=OI.order.ordernumber,Name=OI.Product2.productcode,Quantity__c=OI.Quantity,SerialNumber__c='TestErrAsst03',ShipDate__c=string.valueof(system.today().format())));
          }
          else if(OI.EDI_Line_Number__c=='00B1'){ // 
          TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,FileName__c='ErrorOtherLinesFailed',EDILineNumber__c=OI.EDI_Line_Number__c,OrderNumber__c=OI.order.ordernumber,Name=OI.Product2.productcode,Quantity__c=OI.Quantity,SerialNumber__c='TestErrAsst03',ShipDate__c=string.valueof(system.today().format())));
        }
        else if(OI.EDI_Line_Number__c=='00A4'){
           TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,FileName__c=' # of Entitlement and Asset mismatch',EDILineNumber__c=OI.EDI_Line_Number__c,OrderNumber__c=OI.order.ordernumber,Name=OI.Product2.productcode,Quantity__c=OI.Quantity,SerialNumber__c='TestErrAsst01{TestErrAsst02',ShipDate__c=string.valueof(system.today().format())));
        }
        else if(OI.EDI_Line_Number__c=='ErrorDateFormat'){
        TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,FileName__c='ErrorDateFormat',EDILineNumber__c=OI.EDI_Line_Number__c,OrderNumber__c=OI.order.ordernumber,Name=OI.Product2.productcode,Quantity__c=OI.Quantity,SerialNumber__c='TestErrAsst03',ShipDate__c='2020-10-10'));
        }
        else if(OI.EDI_Line_Number__c=='FailedtoSend855'){
        TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,FileName__c='FailedtoSend855',EDILineNumber__c=OI.EDI_Line_Number__c,OrderNumber__c=OI.order.ordernumber,Name=OI.Product2.productcode,Quantity__c=OI.Quantity,SerialNumber__c='TestErrAsst03',ShipDate__c=string.valueof(system.today().format())));
        } 
          else{
          TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,EDILineNumber__c=OI.EDI_Line_Number__c,FileName__c='test1',OrderNumber__c=OI.order.ordernumber,Name=OI.Product2.productcode,Quantity__c=OI.Quantity,SerialNumber__c='TestSuccAsst'+OI.EDI_Line_Number__c,ShipDate__c=string.valueof(system.today().format())));
         } 
        }
        TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,FileName__c='MandatoryFieldsMissing', SerialNumber__c='12',EDILineNumber__c='012',Name='TestProduct',ShipDate__c=string.valueof(system.today().format())));
        TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,FileName__c='ErrorInvalidOrder', SerialNumber__c='12',EDILineNumber__c='0123',OrderNumber__c='testFailOrder',Quantity__c=2.00,Name='TestProduct',ShipDate__c=string.valueof(system.today().format())));
        TPH.add(new ThirdPartyHardware__c(JobId__c=TPM.id,FileName__c='ErrorInvalidEdi',EDILineNumber__c='ABC',OrderNumber__c=OrdIdNumber.get(ordrList[1].id),Name='TestProduct1',Quantity__c=2.00,SerialNumber__c='Test1234567Asset{Test1234567Asset3{Test1234567Asset4{Test1234567Asset2',ShipDate__c=string.valueof(system.today().format())));
        insert TPH ;
        Test.stopTest(); 
        
       }
       public static testMethod void ASNTieBackTest() {
          Database.executeBatch(new ThirdPartyAssetUpdateBatch());
          Test.startTest(); 
          Test.stopTest(); 
       }

}