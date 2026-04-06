/********************************************************************************************************
* Name              : RMAOrderMain_Test2
* Purpose           : RMAOrderMain_Test is Used for Testing RMAOrderMain Trigger
*********************************************************************************************************/
@isTest
public class RMAOrderMain_Test2{
    @TestSetUp
    static void createdata(){
        ShGl_DisableBusinessLogic__c disableFuncCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableFuncCS.Disable_RMA_Trigger__c = false;
        upsert disableFuncCS;
        
        
        CountryWithCode__c CountrySetting1 = new CountryWithCode__c();
        CountrySetting1.Name = 'United States';
        CountrySetting1.Code__c = 'US';
        insert CountrySetting1;
        StateCodeName__C stateSetting1 = new StateCodeName__C();
        stateSetting1.Name = 'US-AL';
        stateSetting1.State_Name__c = 'Alabama';
        insert stateSetting1;
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acc= new Account(Name='testacc',recordtypeId=devRecordTypeId);
        insert acc;
        Contact con = New Contact(LastName = 'Test', AccountID = acc.id, email= system.label.Invoices_Email);
        insert con;
        Case cs = new case(priority='P1',status='New',AccountId=acc.Id,Reason='New problem',Origin='Email',Type='Hardware');
        insert cs;
        List<Product2> sampleProducts = new List<Product2>{
            // 0
            new Product2( Name = 'CPQ Bundle Product',Family = 'r300',Product_NIC_Type__c='nictype',Appliance_Model__c='amodel', ProductCode = 'ssd',IsActive = true,SBQQ__Hidden__c = true,SBQQ__ExcludeFromOpportunity__c = true, New_CPQ_Product__c = true
                        ),
                // 1
                new Product2(Name = 'RBK-R344-01',ProductCode = 'memory',Category__c = 'Platform',Family = '{r300}',Product_Type__c = 'Appliance',Appliance_Model__c='RBK-R344', Appliance_Model_HW__c = 'RBK-R344',SBQQ__AssetConversion__c = null,SBQQSC__EntitlementConversion__c = 'None', Create_Asset_Entitlement__c = true,
                             IsActive = true,Asset_Priority__c = 0,New_CPQ_Product__c = true),
                new Product2(Name = 'RBK-R346-01',ProductCode = 'node',Category__c = 'Platform',Family = '{r300}',Product_Type__c = 'Appliance',Appliance_Model__c='RBK-R344', Appliance_Model_HW__c = 'RBK-R344',SBQQ__AssetConversion__c = null,SBQQSC__EntitlementConversion__c = 'None', Create_Asset_Entitlement__c = true,
                             IsActive = true,Asset_Priority__c = 0,New_CPQ_Product__c = true),
                new Product2(Name = 'RBK-R347-01',ProductCode = 'chassis',Category__c = 'Platform',Family = '{r300}',Product_Type__c = 'Appliance',Appliance_Model__c='RBK-R344', Appliance_Model_HW__c = 'RBK-R344',SBQQ__AssetConversion__c = null,SBQQSC__EntitlementConversion__c = 'None', Create_Asset_Entitlement__c = true,
                             IsActive = true,Asset_Priority__c = 0,New_CPQ_Product__c = true),
                new Product2(Name = 'RBK-R348-01',ProductCode = 'X-0056-01',Category__c = 'Platform',Family = '{r300}',Product_Type__c = 'Appliance',Appliance_Model__c='RBK-R344', Appliance_Model_HW__c = 'RBK-R344',SBQQ__AssetConversion__c = null,SBQQSC__EntitlementConversion__c = 'None', Create_Asset_Entitlement__c = true,
                             IsActive = true,Asset_Priority__c = 0,New_CPQ_Product__c = true),
                new Product2(Name = 'RBK-R345-01',ProductCode = 'hdd',Category__c = 'Platform',Family = '{r300}',Product_Type__c = 'Appliance',Appliance_Model__c='RBK-R344', Appliance_Model_HW__c = 'RBK-R344',SBQQ__AssetConversion__c = null,SBQQSC__EntitlementConversion__c = 'None', Create_Asset_Entitlement__c = true,
                             IsActive = true,Asset_Priority__c = 0,New_CPQ_Product__c = true),
                new Product2(Name = 'RBK-R3455-01',ProductCode = 'nic',Category__c = 'Platform',Family = '{r300}',Product_Type__c = 'Appliance',Appliance_Model__c='RBK-R344', Appliance_Model_HW__c = 'RBK-R344',SBQQ__AssetConversion__c = null,SBQQSC__EntitlementConversion__c = 'None', Create_Asset_Entitlement__c = true,
                             IsActive = true,Asset_Priority__c = 0,New_CPQ_Product__c = true),
                new Product2(Name = 'RBK-R3456-01',ProductCode = 'psu',Category__c = 'Platform',Family = '{r300}',Product_Type__c = 'Appliance',Appliance_Model__c='RBK-R344', Appliance_Model_HW__c = 'RBK-R344',SBQQ__AssetConversion__c = null,SBQQSC__EntitlementConversion__c = 'None', Create_Asset_Entitlement__c = true,
                             IsActive = true,Asset_Priority__c = 0,New_CPQ_Product__c = true),
                new Product2(Name = 'RBK-R3435-01',ProductCode = 'Other',Category__c = 'Platform',Family = '{r300}',Product_Type__c = 'Appliance',Appliance_Model__c='RBK-R344', Appliance_Model_HW__c = 'RBK-R344',SBQQ__AssetConversion__c = null,SBQQSC__EntitlementConversion__c = 'None', Create_Asset_Entitlement__c = true,
                             IsActive = true,Asset_Priority__c = 0,New_CPQ_Product__c = true)     };
                                 insert sampleProducts;
         Product2 product = new Product2(
            Name = 'X-SVC-TECH',
            ProductCode = 'X-SVC-TECH',
            Category__c = 'Platform',
            IsActive = true
        );
        insert product;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Product2Id = product.Id,
            IsActive = true,
            Pricebook2Id = System.label.RMA_PriceBookID,
            UnitPrice = 0.00
        );
        insert pricebookEntry;
        List<PricebookEntry>entries = new List<PricebookEntry>();
        List<Asset> astList = new List<Asset>();
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        insert entries;
        Asset ast1 = new Asset(AccountId=acc.Id,ContactId=con.Id,Name='SN1',serial_Number__C='SN1',Product2ID=sampleProducts[0].Id);
        insert ast1;
        Asset ast2 = new Asset(ParentId=ast1.id,AccountId=acc.Id,ContactId=con.Id,Name='childSN1',serial_Number__C='childSN1',Product2ID=sampleProducts[0].Id);
        insert ast2;
        astList.add(new Asset(AccountId=acc.Id,ContactId=con.Id,Name='SN2',serial_Number__C='CMOS Battery',Product2ID=sampleProducts[0].Id));
        astList.add(new Asset(AccountId=acc.Id,ContactId=con.Id,Name='SN3',serial_Number__C='nic',Product2ID=sampleProducts[0].Id));
        insert astList;
        Node__c nd1 = new Node__c(Name='SN1',Serial_Number__c='SN1',asset__c=ast2.Id);
        insert nd1;
        Node__c nd2 = new Node__c(Name='Other',Serial_Number__c='Other',asset__c=ast2.Id);
        insert nd2;
        Drive__c dr1 = new Drive__c(Name='SN1',Serial_Number__c='SN1',asset__c=ast1.Id,Node__c=nd1.Id);
        insert dr1;
        Chassis__c ch1 = new Chassis__c(Name='SN1',Serial_Number__c='SN1',asset__c=ast1.Id);
        insert ch1;
        Power_Supply__c ps1 = new Power_Supply__c(Name='SN1',Serial_Number__c='SN1',asset__c=ast1.Id);
        insert ps1;
        Memory__c m1 = new Memory__c(Name='SN1',Serial_Number__c='SN1',asset__c=ast1.Id,Node__c=nd1.Id);
        insert m1;
        NIC__c n1 = new NIC__c(Name='SN1',Serial_Number__c='SN1',asset__c=ast1.Id,Node__c=nd1.Id);
        insert n1;
        NIC__c n2 = new NIC__c(Name='SN2',Serial_Number__c='SN2',asset__c=ast1.Id,Node__c=nd1.Id);
        insert n2;
        List<Spares_Mapping__c> spmList = new List<Spares_Mapping__c>();
        Spares_Mapping__c spm1 = new Spares_Mapping__c(SSD__c='ssd',HDD__c='hdd',NIC__c='nic',cmos_Battery__c='CMOS Battery',
                                                       Memory__c='memory',Node__c='node',PSU__c='psu',Chassis__c='chassis',Product_Family__c='R300',NIC_Type__c='nictype',Appliance_Model__c='amodel');
        Spares_Mapping__c spm2 = new Spares_Mapping__c(SSD__c='SN1',HDD__c='SN1',NIC__c='SN1',cmos_Battery__c='SN1',
                                                       Memory__c='SN1',Node__c='SN1',PSU__c='SN1',Chassis__c='SN1',Product_Family__c='R300',NIC_Type__c='nictype',Appliance_Model__c='amodel');
        Spares_Mapping__c spm3 = new Spares_Mapping__c(SSD__c='Other',HDD__c='Other',NIC__c='Other',cmos_Battery__c='Other',
                                                       Memory__c='Other',Node__c='Other',PSU__c='Other',Chassis__c='Other',Product_Family__c='',NIC_Type__c='',Appliance_Model__c='');
        spmList.add(new Spares_Mapping__c(SSD__c='Other',HDD__c='Other',NIC__c='SN2',cmos_Battery__c='Other',
                                          Memory__c='Other',Node__c='Other',PSU__c='Other',Chassis__c='Other',Product_Family__c='R300',NIC_Type__c='',Appliance_Model__c=''));
        spmList.add(new Spares_Mapping__c(SSD__c='Other',HDD__c='Other',NIC__c='SN3',cmos_Battery__c='Other',
                                          Memory__c='Other',Node__c='Other',PSU__c='Other',Chassis__c='Other',Product_Family__c='',NIC_Type__c='nictype',Appliance_Model__c=''));
        spmList.add(new Spares_Mapping__c(SSD__c='Other',HDD__c='Other',NIC__c='Other',cmos_Battery__c='Other',
                                          Memory__c='Other',Node__c='Other',PSU__c='Other',Chassis__c='Other',Product_Family__c='',NIC_Type__c='',Appliance_Model__c='amodel'));
        spmList.add(new Spares_Mapping__c(SSD__c='Other',HDD__c='Other',NIC__c='Other',cmos_Battery__c='Other',
                                          Memory__c='Other',Node__c='Other',PSU__c='Other',Chassis__c='Other',Product_Family__c='R300',NIC_Type__c='nictype',Appliance_Model__c=''));
        spmList.add(new Spares_Mapping__c(SSD__c='Other',HDD__c='Other',NIC__c='Other',cmos_Battery__c='Other',
                                          Memory__c='Other',Node__c='Other',PSU__c='Other',Chassis__c='Other',Product_Family__c='R300',NIC_Type__c='',Appliance_Model__c='amodel'));
        spmList.add(new Spares_Mapping__c(SSD__c='Other',HDD__c='Other',NIC__c='Other',cmos_Battery__c='Other',
                                          Memory__c='Other',Node__c='Other',PSU__c='Other',Chassis__c='Other',Product_Family__c='',NIC_Type__c='nictype',Appliance_Model__c='amodel'));
        spmList.add(spm1);
        spmList.add(spm2);
        spmList.add(spm3);
        insert spmList;
        UpdateShippingCarrierServiceLevel__c serviceLevel = new UpdateShippingCarrierServiceLevel__c();
        serviceLevel.name='10:30amAUSTRALIA';
        serviceLevel.OrderServiceLevel__c   = 'Next Business day by 17:00 FGL';
        serviceLevel.OrderShippingCarrier__c   = 'Flash';
        serviceLevel.RMAServiceType__c   = 'Next Business Day: 10:30am';
        serviceLevel.SCAC__c   = 'FL17FG';
        serviceLevel.Shipping_Country__c   = 'United States';
        insert  serviceLevel;
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN1', Send_Smart_Hands_Service__c=true,
                                          Date_of_Smart_Hands_Arrival__c= system.Today() + 5,
                                          Time_of_Smart_Hands_Tech_Arrival__c= '15:00',Service_Type__c='Next Business Day: 10:30am',SSD__c='SN1',Memory__c='SN1',Power_Supply__c='SN1',Chassis__c='SN1',NIC__c='SN1',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1,SN2',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='pqr@rubrik.com',Valid_Support__c =True,status__c='Submitted',Smart_Hands_Change_Requested__c=false));
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN1', Send_Smart_Hands_Service__c=true,
                                          Date_of_Smart_Hands_Arrival__c= system.Today() + 5,
                                          Time_of_Smart_Hands_Tech_Arrival__c= '15:00',Service_Type__c='Next Business Day: 10:30am',SSD__c='SN1',Power_Supply__c='SN1',Chassis__c='SN1',NIC__c='SN1',Parent_Case__c=cs.Id,Memory__c='Other',ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1,SN2',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='pqr@rubrik.com',Valid_Support__c =True,status__c='Submitted',Smart_Hands_Change_Requested__c=true));
        
        //ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='Other',SSD__c='Other',Memory__c='Other',Power_Supply__c='Other',Chassis__c='Other',NIC__c='Other',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='def@rubrik.com',Valid_Support__c =True,status__c='Submitted',Smart_Hands_Change_Requested__c=true,Entitled_for_Smart_Hands_Service__c=true));
        //ramOrderList.add(new RMA_Order__c(Additional_Interested_Parties_RMA__c='abc@rubrik.com',Valid_Support__c =True,status__c='Submitted',Entitled_for_Smart_Hands_Service__c=true,Smart_Hands_Change_Requested__c=true));
        insert ramOrderList;
    }
    
    static testMethod void testRMAOrderMainTriggerHelper2(){
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS;
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        ramOrderList = [select Id,status__c,ShippingState__c,Additional_Interested_Parties_RMA__c,Resend_Flash_Email__c from RMA_Order__c ];
        Test.startTest();
        checkRecursive.runAfter = true;
        ramOrderList[0].status__c = 'Approved';
        ramOrderList[0].Additional_Interested_Parties_RMA__c = 'abc1@rubrik.com';
        ramOrderList[0].Smart_Hands_Change_Requested__c = true;
        ramOrderList[0].Send_Smart_Hands_Service__c =true;
        ramOrderList[0].Date_of_Smart_Hands_Arrival__c = system.Today() + 5;
        ramOrderList[0].Time_of_Smart_Hands_Tech_Arrival__c= '15:00';
        update ramOrderList[0];
        checkRecursive.runAfter = true;
        disableFuncCS.Disable_old_RMA_Trigger__c = false;
        upsert disableFuncCS;
        ramOrderList[1].status__c = 'Approved';
        ramOrderList[1].Additional_Interested_Parties_RMA__c = 'abc1@rubrik.com';
        ramOrderList[1].Smart_Hands_Change_Requested__c = true;
        ramOrderList[1].Send_Smart_Hands_Service__c =true;
        ramOrderList[1].Date_of_Smart_Hands_Arrival__c = system.Today() + 5;
        ramOrderList[1].Time_of_Smart_Hands_Tech_Arrival__c= '15:00';
        update ramOrderList[1];
        Test.stopTest();
    }
    static testMethod void testRMAOrderMainTriggerHelper2_2(){
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS;
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        ramOrderList = [select Id,status__c,ShippingState__c,Additional_Interested_Parties_RMA__c,Resend_Flash_Email__c from RMA_Order__c];
        Test.startTest();
        checkRecursive.runAfter = true;
        ramOrderList[0].status__c = 'Approved';
        ramOrderList[0].Additional_Interested_Parties_RMA__c = 'abc1@rubrik.com';
        ramOrderList[0].Smart_Hands_Change_Requested__c = true;
        // ramOrderList[0].Send_Smart_Hands_Service__c =false;
        // ramOrderList[0].Date_of_Smart_Hands_Arrival__c = null;
        // ramOrderList[0].Time_of_Smart_Hands_Tech_Arrival__c= '';	
        update ramOrderList[0];
        checkRecursive.runAfter = true;
        disableFuncCS.Disable_old_RMA_Trigger__c = false;
        upsert disableFuncCS;
        ramOrderList[1].status__c = 'Approved';
        ramOrderList[1].Additional_Interested_Parties_RMA__c = 'abc1@rubrik.com';
        ramOrderList[1].Smart_Hands_Change_Requested__c = true;
        // ramOrderList[1].Send_Smart_Hands_Service__c =false;
        // ramOrderList[1].Date_of_Smart_Hands_Arrival__c = null;
        // ramOrderList[1].Time_of_Smart_Hands_Tech_Arrival__c= '';	
        update ramOrderList[1];
        Test.stopTest();
    }
    static testMethod void testRMAOrderMainTriggerHelper3(){
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS;
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        ramOrderList = [select Id,status__c,ShippingState__c,Additional_Interested_Parties_RMA__c,Resend_Flash_Email__c from RMA_Order__c];
        Test.startTest();
        checkRecursive.runAfter = true;
        ramOrderList[0].Valid_Support__c = true;
        ramOrderList[0].Entitled_for_Smart_Hands_Service__c = true;
        ramOrderList[0].Smart_Hands_Change_Requested__c =true;
        ramOrderList[0].Send_Smart_Hands_Service__c = true;
        ramOrderList[0].Date_of_Smart_Hands_Arrival__c = system.Today() + 5;
        ramOrderList[0].Time_of_Smart_Hands_Tech_Arrival__c= '15:00';
        update ramOrderList[0];
        checkRecursive.runAfter = true;
        disableFuncCS.Disable_old_RMA_Trigger__c = false;
        upsert disableFuncCS;
        ramOrderList[1].Valid_Support__c = true;
        ramOrderList[1].Entitled_for_Smart_Hands_Service__c = true;
        ramOrderList[1].Smart_Hands_Change_Requested__c =true;
        ramOrderList[1].Send_Smart_Hands_Service__c = true;
        ramOrderList[1].Date_of_Smart_Hands_Arrival__c = system.Today() + 5;
        ramOrderList[1].Time_of_Smart_Hands_Tech_Arrival__c= '15:00';
        update ramOrderList[1];
        Test.stopTest();
    }
    static testMethod void testRMAOrderMainTriggerHelper3_2(){
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS;
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        ramOrderList = [select Id,status__c,ShippingState__c,Additional_Interested_Parties_RMA__c,Resend_Flash_Email__c from RMA_Order__c];
        Test.startTest();
        checkRecursive.runAfter = true;
        ramOrderList[0].Valid_Support__c = true;
        ramOrderList[0].Entitled_for_Smart_Hands_Service__c = true;
        ramOrderList[0].Smart_Hands_Change_Requested__c =true;
        // ramOrderList[0].Send_Smart_Hands_Service__c = false;
        // ramOrderList[0].Date_of_Smart_Hands_Arrival__c = null;
        // ramOrderList[0].Time_of_Smart_Hands_Tech_Arrival__c= '';	
        update ramOrderList[0];
        checkRecursive.runAfter = true;
        disableFuncCS.Disable_old_RMA_Trigger__c = false;
        upsert disableFuncCS;
        ramOrderList[1].Valid_Support__c = true;
        ramOrderList[1].Entitled_for_Smart_Hands_Service__c = true;
        ramOrderList[1].Smart_Hands_Change_Requested__c =true;
        // ramOrderList[1].Send_Smart_Hands_Service__c = false;
        // ramOrderList[1].Date_of_Smart_Hands_Arrival__c = null;
        // ramOrderList[1].Time_of_Smart_Hands_Tech_Arrival__c= '';	
        update ramOrderList[1];
        Test.stopTest();
    }
    static testMethod void testRMAOrderMainTriggerHelper4(){
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS;
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        ramOrderList = [select Id,status__c,ShippingState__c,Additional_Interested_Parties_RMA__c,Resend_Flash_Email__c from RMA_Order__c];
        Test.startTest();
        checkRecursive.runAfter = true;
        ramOrderList[0].Resend_Flash_Email__c = true;
        update ramOrderList[0];
        checkRecursive.runAfter = true;
        disableFuncCS.Disable_old_RMA_Trigger__c = false;
        upsert disableFuncCS;
        ramOrderList[1].Resend_Flash_Email__c = true;
        update ramOrderList[1];                
        Test.stopTest();
    }
     static testMethod void RMASparePartsMappingHelper1(){
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        List<Spares_Mapping__c> spmList = new List<Spares_Mapping__c>();
        case cs = [select Id from case limit 1];
        spmList = RMASparePartsMappingHelper.returnSparePartCodeQueryAll();
        Test.startTest();
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN1',SSD__c='SN1',Memory__c='SN1',Power_Supply__c='SN1',Chassis__c='SN1',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN1',cmos_Battery__c='cmo',Send_Smart_Hands_Service__c=true,Date_of_Smart_Hands_Arrival__c = system.Today() + 5,
        Time_of_Smart_Hands_Tech_Arrival__c= '15:00'));
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='Other',SSD__c='Other',Memory__c='Other',Power_Supply__c='Other',Chassis__c='Other',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='Other',cmos_Battery__c='cmo'));
		ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN3',SSD__c='SN3',Memory__c='SN3',Power_Supply__c='SN3',Chassis__c='SN3',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN3',cmos_Battery__c='cmo'));
        insert ramOrderList;
        RMASparePartsMappingHelper.returnSparePartRecord(spmList,'','','');
        RMASparePartsMappingHelper.returnSparePartRecord(spmList,'R300','','');
        RMASparePartsMappingHelper.returnSparePartRecord(spmList,'','nictype','');
        RMASparePartsMappingHelper.returnSparePartRecord(spmList,'','','amodel');
        RMASparePartsMappingHelper.returnSparePartRecord(spmList,'','nictype','amodel');
        RMASparePartsMappingHelper.returnSparePartRecord(spmList,'R300','nictype','');
        RMASparePartsMappingHelper.returnSparePartRecord(spmList,'R300','','amodel');
         RMASparePartsMappingHelper.returnSparePartRecord(spmList,'R300','nictype','amodel');
        Test.stopTest();
    }
     static testMethod void RMAOrderService1(){
        set<Id> idSet = new set<Id>();
        set<Id> orderidSet = new set<Id>(); 
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS; 
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        case cs = [select Id,AccountId from case limit 1];
        Test.startTest();
        //PRDOPS23-22
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Ship_To_Name__c=cs.AccountId, Drive__c='SN1',SSD__c='SN1',Memory__c='SN1',Power_Supply__c='SN1',Chassis__c='SN1',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN1',cmos_Battery__c='cmo',Send_Smart_Hands_Service__c=true,Date_of_Smart_Hands_Arrival__c = system.Today() + 5,
        Time_of_Smart_Hands_Tech_Arrival__c= '15:00'));
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Ship_To_Name__c=cs.AccountId, Drive__c='Other',SSD__c='Other',Memory__c='Other',Power_Supply__c='Other',Chassis__c='Other',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='Other',cmos_Battery__c='cmo'));
		ramOrderList.add(new RMA_Order__c(Node__c='SN1',Ship_To_Name__c=cs.AccountId, Drive__c='SN3',SSD__c='SN3',Memory__c='SN3',Power_Supply__c='SN3',Chassis__c='SN3',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN3',cmos_Battery__c='cmo'));
        insert ramOrderList;
        List<Order> ordList = [select Id from Order limit 1]; 
        orderidSet.add(ordList[0].Id); 
        idSet.add(ramOrderList[0].Id); 
        RMAOrderService.updateRelatedOrders(idSet);
        RMAOrderService.smartHandRemovedEmails(idSet);
        RMAOrderService.mailOnResendButton(idSet);
        RMAOrderService.updateResendField(idSet); 
        RMAOrderService.associateNodes(orderidSet); 
        RMAOrderService.generateOrderFromRMA(ramOrderList[0]);
        Test.stopTest();
    } 
     static testMethod void RMAOrderServiceWithoutPBE1(){
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        case cs = [select Id from case limit 1]; 
        List<PricebookEntry> pbe = [select id from PricebookEntry];
        delete pbe; 
        Test.startTest();
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN1',SSD__c='SN1',Memory__c='SN1',Power_Supply__c='SN1',Chassis__c='SN1',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN1',cmos_Battery__c='cmo',Send_Smart_Hands_Service__c=true,Date_of_Smart_Hands_Arrival__c = system.Today() + 5,
        Time_of_Smart_Hands_Tech_Arrival__c= '15:00'));
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='Other',SSD__c='Other',Memory__c='Other',Power_Supply__c='Other',Chassis__c='Other',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='Other',cmos_Battery__c='cmo'));
		ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN3',SSD__c='SN3',Memory__c='SN3',Power_Supply__c='SN3',Chassis__c='SN3',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN3',cmos_Battery__c='cmo'));
        insert ramOrderList;
        Test.stopTest();
    }
     static testMethod void RMAOrderServiceWithoutPBE2(){
        case cs = [select Id from case limit 1];
        List<PricebookEntry> pbe = [select id from PricebookEntry];
        delete pbe; 
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS; 
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        Test.startTest();
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN1',SSD__c='SN1',Memory__c='SN1',Power_Supply__c='SN1',Chassis__c='SN1',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN1',cmos_Battery__c='cmo',Send_Smart_Hands_Service__c=true,Date_of_Smart_Hands_Arrival__c = system.Today() + 5,
        Time_of_Smart_Hands_Tech_Arrival__c= '15:00'));
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='Other',SSD__c='Other',Memory__c='Other',Power_Supply__c='Other',Chassis__c='Other',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='Other',cmos_Battery__c='cmo'));
		ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN3',SSD__c='SN3',Memory__c='SN3',Power_Supply__c='SN3',Chassis__c='SN3',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN3',cmos_Battery__c='cmo'));
        insert ramOrderList;
        
        Test.stopTest();
    } 
}