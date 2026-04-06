/********************************************************************************************************
* Name              : RMAOrderMain_Test
* Purpose           : RMAOrderMain_Test is Used for Testing RMAOrderMain Trigger
*********************************************************************************************************/
@isTest
public class RMAOrderMain_Test{
    @TestSetUp
    static void createdata(){
        ShGl_DisableBusinessLogic__c disableFuncCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableFuncCS.Disable_RMA_Trigger__c = false;
        upsert disableFuncCS;
        
        
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
        UpdateShippingCarrierServiceLevel__c serviceLevel = new UpdateShippingCarrierServiceLevel__c();
        serviceLevel.name='10:30amAUSTRALIA';
        serviceLevel.OrderServiceLevel__c   = 'Next Business day by 17:00 FGL';
        serviceLevel.OrderShippingCarrier__c   = 'Flash';
        serviceLevel.RMAServiceType__c   = 'Next Business Day: 10:30am';
        serviceLevel.SCAC__c   = 'FL17FG';
         serviceLevel.Shipping_Country__c   = 'UNITED STATES';
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
    static testMethod void testRMAOrderMainTriggerBulk4(){
        Test.startTest();
        //RMAOrderService.getCounter();
        Test.stopTest();
    }
    static testMethod void testRMAOrderMainTriggerBulk1(){
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS;
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        ramOrderList = [select Id,status__c,ShippingState__c,Additional_Interested_Parties_RMA__c,Resend_Flash_Email__c from RMA_Order__c ];
        Test.startTest();
        for(RMA_Order__c rma : ramOrderList){
            if(rma.Additional_Interested_Parties_RMA__c != 'abc@rubrik.com')
                rma.status__c = 'Approved';
            else
                rma.Additional_Interested_Parties_RMA__c = 'abc1@rubrik.com';
        }
        update ramOrderList;
        Test.stopTest();
    }

    static testMethod void testRMAOrderMainTriggerBulk2(){
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS;
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        case cs = [select Id from case limit 1];
        Test.startTest();
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN1',SSD__c='SN1',Memory__c='SN1',Power_Supply__c='SN1',Chassis__c='SN1',NIC__c='SN1',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,cmos_Battery__c='cmo'));
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='Other',SSD__c='Other',Memory__c='Other',Power_Supply__c='Other',NIC__c='Other',Chassis__c='Other',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved'));

        insert ramOrderList;

        Test.stopTest();
    }
     static testMethod void testRMAOrderMainTriggerBulk3(){
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_old_RMA_Trigger__c = true;
        upsert disableFuncCS;
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        case cs = [select Id from case limit 1];
        Test.startTest();
        ramOrderList.add(new RMA_Order__c(Node__c='SN2',Drive__c='SN2',SSD__c='SN2',Memory__c='SN2',Power_Supply__c='SN2',Chassis__c='SN2',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN2',cmos_Battery__c='cmo'));
        //ramOrderList.add(new RMA_Order__c(Node__c='SN3',Drive__c='SN3',SSD__c='SN3',Memory__c='SN3',Power_Supply__c='SN3',Chassis__c='SN3',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,NIC__c='SN3',cmos_Battery__c='cmo'));

        insert ramOrderList;

        Test.stopTest();
    }
    static testMethod void testRMAOrderMainTriggerFive(){
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        ramOrderList = [select Id,status__c,ShippingState__c,Additional_Interested_Parties_RMA__c,Resend_Flash_Email__c from RMA_Order__c];
        Test.startTest();
        for(RMA_Order__c rma : ramOrderList){
            if(rma.Additional_Interested_Parties_RMA__c != 'abc@rubrik.com')
                rma.status__c = 'Approved';
            else
                rma.Additional_Interested_Parties_RMA__c = 'abc2@rubrik.com';
        }
        update ramOrderList;
        Test.stopTest();
    }
    static testMethod void testRMAOrderMainTriggerFour(){
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        case cs = [select Id from case limit 1];
        Test.startTest();
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='SN1',SSD__c='SN1',Memory__c='SN1',Power_Supply__c='SN1',Chassis__c='SN1',NIC__c='SN1',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,status__c='Approved',Node_Quantity__c=1,cmos_Battery__c='CMOS Battery'));
        ramOrderList.add(new RMA_Order__c(Node__c='SN1',Drive__c='Other',SSD__c='Other',Memory__c='Other',Power_Supply__c='Other',Chassis__c='Other',Parent_Case__c=cs.Id,ShippingState__c='AL',ShippingCountry__C='United States',Appliance__c='SN1',status__c='Approved'));

        insert ramOrderList;

        Test.stopTest();
    }
    
    static testMethod void testRMAOrderMainTrigger(){


        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();

        Test.startTest();
        ramOrderList.add(new RMA_Order__c(status__c='Submitted'));
        ramOrderList.add(new RMA_Order__c(status__c='Approved'));

        insert ramOrderList;

        ramOrderList[0].status__c = 'Approved';

        update ramOrderList;
        Test.stopTest();
    }
    static testMethod void testRMAOrderMainTriggerOne(){


        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        Set<Id> ramOrderIdSet = new Set<Id>();
        Set<Id> ramOrderIdSet1 = new Set<Id>();
        case cs = [select Id from case limit 1];
		CountryWithCode__c CountrySetting1 = new CountryWithCode__c();
        CountrySetting1.Name = 'United States';
        CountrySetting1.Code__c = 'US';
        CountrySetting1.Phone__c = '7656545456';
        insert CountrySetting1;
        StateCodeName__C stateSetting1 = new StateCodeName__C();
        stateSetting1.Name = 'US-AL';
        stateSetting1.State_Name__c = 'Alabama';
        insert stateSetting1;
        Test.startTest();
        ramOrderList.add(new RMA_Order__c(Node__c='SN2',Drive__c='SN2',SSD__c='SN2',Memory__c='SN2',
        Power_Supply__c='SN2',Chassis__c='SN2',Parent_Case__c=cs.Id,ShippingState__c='AL',
        ShippingCountry__C='United States',Appliance__c='SN1',Appliance_Quantity__c=1,
        Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Vendor_message__c=null,
        Valid_Support__c =True,Date_of_Smart_Hands_Arrival__c=date.today(),Send_Smart_Hands_Service__c = true,
        Time_of_Smart_Hands_Tech_Arrival__c='08:00',
        status__c='Approved',Node_Quantity__c=1,NIC__c='SN2',cmos_Battery__c='cmo'));

        ramOrderList.add(new RMA_Order__c(Additional_Interested_Parties_RMA__c='varsha.chechare@Rubrik.com,test@Rubrik.com',Smart_Hands_Change_Requested__c = true,Send_Smart_Hands_Service__c = true,Date_of_Smart_Hands_Arrival__c= system.Today() + 5,Time_of_Smart_Hands_Tech_Arrival__c= '15:00',status__c='Submitted'));
        ramOrderList.add(new RMA_Order__c(Additional_Interested_Parties_RMA__c='varsha.chechare@Rubrik.com,test@Rubrik.com',Smart_Hands_Change_Requested__c = true,Send_Smart_Hands_Service__c = false,status__c='Submitted'));

        insert ramOrderList;
        ramOrderList[1].status__c = 'Approved';
        ramOrderList[2].status__c = 'Approved';

        update ramOrderList;
        ramOrderIdSet.add(ramOrderList[0].Id);
        RMAOrderService.associateNodes(ramOrderIdSet);
        RMAOrderService.updateResendField(ramOrderIdSet);
        RMAOrderService.mailOnResendButton(ramOrderIdSet);
        RMAOrderService.updateRelatedOrders(ramOrderIdSet);
        RMAOrderService.upsertTechOrders(ramOrderIdSet);
        RMAOrderService.generateOrderFromRMA(ramOrderList[0]);

        Test.stopTest();
    }
   /* static testMethod void testRMAOrderMainTriggerTwo(){
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();

        Test.startTest();
        ramOrderList.add(new RMA_Order__c(Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',status__c='Submitted'));

        insert ramOrderList;
        ramOrderList[0].status__c = 'Approved';

        update ramOrderList;
        Test.stopTest();
    } */
    static testMethod void testRMAOrderMainTriggerThree(){
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();


        ramOrderList.add(new RMA_Order__c(Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,Entitled_for_Smart_Hands_Service__c =true,Smart_Hands_Change_Requested__c = true,Send_Smart_Hands_Service__c = false,status__c='Submitted'));
        ramOrderList.add(new RMA_Order__c(Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,Resend_Flash_Email__c =true,status__c='Submitted',Smart_Hands_Change_Requested__c=false));
        insert ramOrderList;
        Test.startTest();
        ramOrderList[0].status__c = 'Approved';

        update ramOrderList;
        RMA_Event__e eve = new RMA_Event__e(RMA_Id__c=ramOrderList[0].Id,Flash_Message__c='hnkjsd');
        EventBus.publish(eve);
        Test.stopTest();
    }
     static testMethod void testRMAOrderMainTriggerSeven(){
        List<RMA_Order__c> ramOrderList = new List<RMA_Order__c>();
        ramOrderList.add(new RMA_Order__c(Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,Entitled_for_Smart_Hands_Service__c =true,Smart_Hands_Change_Requested__c = true,status__c='Submitted',Send_Smart_Hands_Service__c=false));
        ramOrderList.add(new RMA_Order__c(Additional_Interested_Parties_RMA__c='varsha.chechare@rubrik.com',Valid_Support__c =True,Entitled_for_Smart_Hands_Service__c =true,Smart_Hands_Change_Requested__c = true,status__c='Submitted',Send_Smart_Hands_Service__c=true,Date_of_Smart_Hands_Arrival__c= system.Today() + 5,Time_of_Smart_Hands_Tech_Arrival__c= '15:00'));
        insert ramOrderList;
        Test.startTest();
        ramOrderList[0].status__c = 'Approved';

        update ramOrderList;

        Test.stopTest();
    }
        /*
        @Author: Sukesh K
        @Description: for DGWD-128
        Check Vendor Message
    */
    @IsTest
    static void populateVendorMessage() {
        ShGl_DisableBusinessLogic__c disableFuncCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableFuncCS.Disable_RMA_Trigger__c = false;
        upsert disableFuncCS;
        insert  new List<CountryWithCode__c>{
            new CountryWithCode__c(Name = 'United States', Code__c = 'US', Phone__c = '6754343232'),
            new CountryWithCode__c(Name = 'India', Code__c = 'IN', Phone__c = '6754343232')
        };
        insert new StateCodeName__C(
            Name = 'US-AL',
            State_Name__c = 'Alabama'
        );

        Account ac = new Account(Name = 'Test Account');
        insert ac;
        Case caseTest = (Case) ShGl_TestFactory.createSObject(
            new Case(),
            new Map<String, Object>{
                'Subject' => 'Test',
                'Priority' => 'P2',
                'AccountId' => ac.Id
            }
        );
        insert caseTest;
       	//insert new CountryWithCode__c(Name = 'India', Code__c = 'IN', Phone__c = '6754343232');

        List<RMA_Order__c> rmaOrderList = new List<RMA_Order__c>{
            new RMA_Order__c(
                Vendor_Message__c = 'vendorMessage',
                Additional_Interested_Parties_RMA__c='test@rubrik.com',
                Valid_Support__c =true,
                Entitled_for_Smart_Hands_Service__c =true,
                Smart_Hands_Change_Requested__c = true,
                status__c='Submitted',
                Send_Smart_Hands_Service__c=false
            ),
            new RMA_Order__c(
                Vendor_Message__c = 'vendorMessage',
                Additional_Interested_Parties_RMA__c='test@rubrik.com',
                Valid_Support__c =true,
                Entitled_for_Smart_Hands_Service__c =true,
                Smart_Hands_Change_Requested__c = true,
                status__c='Submitted',
                Send_Smart_Hands_Service__c=true,
                Date_of_Smart_Hands_Arrival__c= system.Today() + 5,
                Time_of_Smart_Hands_Tech_Arrival__c= '15:00'
            ),
            new RMA_Order__c(
                Additional_Interested_Parties_RMA__c='test@rubrik.com',
                Valid_Support__c =true,
                Entitled_for_Smart_Hands_Service__c =true,
                Smart_Hands_Change_Requested__c = true,
                status__c='Submitted',
                Send_Smart_Hands_Service__c=false
            ),
            new RMA_Order__c(
                Additional_Interested_Parties_RMA__c='test@rubrik.com',
                Valid_Support__c =true,
                Entitled_for_Smart_Hands_Service__c =true,
                Smart_Hands_Change_Requested__c = true,
                status__c='Submitted',
                Send_Smart_Hands_Service__c=true,
                Date_of_Smart_Hands_Arrival__c= system.Today() + 5,
                Time_of_Smart_Hands_Tech_Arrival__c= '15:00'
            )
        };

        insert rmaOrderList;
        Map<Id, RMA_Order__c> mapRma = new Map<Id, RMA_Order__c>(rmaOrderList);
        Test.startTest();

        List<Order> lstOrder = [
            SELECT Id, Vendor_Message__c, RMA_Request__c
            FROM Order
            WHERE RMA_Request__c IN :mapRma.keySet()
        ];

        Test.stopTest();

        for (Order ord : lstOrder) {
            System.assertEquals(
                mapRma.get(ord.RMA_Request__c).Vendor_Message__c,
                ord.Vendor_Message__c,
                'Vendor Message incorrectly populated for Order: ' + ord.Id
            );
        }
    }

    /*
        @Author: Sukesh K
        @Description: for DGWD-17
        Check Tech Orders After Insert
    */
    @IsTest
    static void techOrderAfterInsert() {
        ShGl_DisableBusinessLogic__c disableFuncCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableFuncCS.Disable_RMA_Trigger__c = false;
        upsert disableFuncCS;
        insert  new List<CountryWithCode__c>{
            new CountryWithCode__c(Name = 'United States', Code__c = 'US', Phone__c = '6754343232'),
            new CountryWithCode__c(Name = 'India', Code__c = 'IN', Phone__c = '6754343232')
        };
        insert new StateCodeName__C(
            Name = 'US-AL',
            State_Name__c = 'Alabama'
        );

        Account ac = new Account(Name = 'Test Account');
        insert ac;
        Case caseTest = (Case) ShGl_TestFactory.createSObject(
            new Case(),
            new Map<String, Object>{
                'Subject' => 'Test',
                'Priority' => 'P2',
                'AccountId' => ac.Id
            }
        );
        insert caseTest;
        //insert new CountryWithCode__c(Name = 'India', Code__c = 'IN');
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

        List<RMA_Order__c> rmaOrderList = new List<RMA_Order__c>{
            new RMA_Order__c(
                Parent_Case__c=caseTest.Id,
                ShippingState__c='AL',
                ShippingCountry__C='United States',
                Appliance__c='SN1',
                Appliance_Quantity__c=1,
                Vendor_Message__c = 'vendorMessage',
                Additional_Interested_Parties_RMA__c='test@rubrik.com',
                Valid_Support__c =true,
                Entitled_for_Smart_Hands_Service__c =true,
                Smart_Hands_Change_Requested__c = true,
                status__c='Submitted',
                Send_Smart_Hands_Service__c=false
            ),
            new RMA_Order__c(
                Parent_Case__c=caseTest.Id,
                ShippingState__c='AL',
                ShippingCountry__C='United States',
                Appliance__c='SN1',
                Appliance_Quantity__c=1,
                Vendor_Message__c = 'vendorMessage',
                Additional_Interested_Parties_RMA__c='test@rubrik.com',
                Valid_Support__c =true,
                Entitled_for_Smart_Hands_Service__c =true,
                Smart_Hands_Change_Requested__c = true,
                status__c='Submitted',
                Send_Smart_Hands_Service__c=true,
                Date_of_Smart_Hands_Arrival__c= system.Today() + 5,
                Time_of_Smart_Hands_Tech_Arrival__c= '15:00'
            )
        };

        insert rmaOrderList;
        Map<Id, RMA_Order__c> mapRma = new Map<Id, RMA_Order__c>(rmaOrderList);

        Test.startTest();

        Map<Id, List<Order>> mapRmaIdLstOrder = new Map<Id, List<Order>>();
        for (Order ord : [
            SELECT Id, Order_Sub_Type__c ,RMA_Request__c, Support_End_Date__c, Support_Start_Date__c,
                (SELECT Id, unitPrice FROM OrderItems)
            FROM Order
            WHERE RMA_Request__c IN :mapRma.keySet()
        ]) {
            if (!mapRmaIdLstOrder.containsKey(ord.RMA_Request__c)) {
                mapRmaIdLstOrder.put(ord.RMA_Request__c, new List<Order>());
            }
            mapRmaIdLstOrder.get(ord.RMA_Request__c).add(ord);
        }
        Test.stopTest();

        for (RMA_Order__c rma : rmaOrderList) {
            List<Order> relatedOrders = new List<Order>(mapRmaIdLstOrder.get(rma.Id));
            Order techOrder;
            Order partOrder;
            for (Order ord : relatedOrders) {
                if (ord.Order_Sub_Type__c == 'Part Order') {
                    partOrder = ord;
                    continue;
                } else if (ord.Order_Sub_Type__c == 'Tech Order') {
                    techOrder = ord;
                    continue;
                }
            }
            if (rma.Send_Smart_Hands_Service__c) {
            /*
                System.debug('rma.Send_Smart_Hands_Service__c');
                System.assertNotEquals(null, techOrder, 'only 1 Tech Order Should be Populated for Tech Order' );
                System.assertEquals(1, techOrder.OrderItems.size(), 'only 1 Order Item Allowed for Tech Order');
                System.assertEquals(System.today(), techOrder.Support_Start_Date__c, 'Support Start Date different');
                System.assertEquals(
                    DateTime.newInstance(
                        rma.Date_of_Smart_Hands_Arrival__c,
                        Time.newInstance(
                            Integer.valueOf(rma.Time_of_Smart_Hands_Tech_Arrival__c.split(':')[0]),
                            Integer.valueOf(rma.Time_of_Smart_Hands_Tech_Arrival__c.split(':')[1]),
                            0,
                            0
                        )
                    ),
                    techOrder.Support_Start_Date__c,
                    'Support End Date different'
                );
            */
            }
        }
    }

    /*
        @Author: Sukesh K
        @Description: for DGWD-17
        Check Tech Orders After Insert
    */
    @IsTest
    static void techOrderAfterUpdate() {
        ShGl_DisableBusinessLogic__c disableFuncCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableFuncCS.Disable_RMA_Trigger__c = false;
        upsert disableFuncCS;
        insert  new List<CountryWithCode__c>{
           new CountryWithCode__c(Name = 'United States', Code__c = 'US', Phone__c = '6754343232'),
            new CountryWithCode__c(Name = 'India', Code__c = 'IN', Phone__c = '6754343232')
        };
        insert new StateCodeName__C(
            Name = 'US-AL',
            State_Name__c = 'Alabama'
        );

        Account ac = new Account(Name = 'Test Account');
        insert ac;
        Case caseTest = (Case) ShGl_TestFactory.createSObject(
            new Case(),
            new Map<String, Object>{
                'Subject' => 'Test',
                'Priority' => 'P2',
                'AccountId' => ac.Id
            }
        );
        insert caseTest;
       // insert new CountryWithCode__c(Name = 'India', Code__c = 'IN');
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

        List<RMA_Order__c> rmaOrderList = new List<RMA_Order__c>{
            new RMA_Order__c(
                Parent_Case__c=caseTest.Id,
                ShippingState__c='AL',
                ShippingCountry__C='United States',
                Appliance__c='SN1',
                Appliance_Quantity__c=1,
                Vendor_Message__c = 'vendorMessage',
                Additional_Interested_Parties_RMA__c='test@rubrik.com',
                Valid_Support__c =true,
                Entitled_for_Smart_Hands_Service__c =true,
                Smart_Hands_Change_Requested__c = true,
                status__c='Submitted',
                Send_Smart_Hands_Service__c=false
            ),
            new RMA_Order__c(
                Parent_Case__c=caseTest.Id,
                ShippingState__c='AL',
                ShippingCountry__C='United States',
                Appliance__c='SN1',
                Appliance_Quantity__c=1,
                Vendor_Message__c = 'vendorMessage',
                Additional_Interested_Parties_RMA__c='test@rubrik.com',
                Valid_Support__c =true,
                Entitled_for_Smart_Hands_Service__c =true,
                Smart_Hands_Change_Requested__c = true,
                status__c='Submitted',
                Send_Smart_Hands_Service__c=true,
                Date_of_Smart_Hands_Arrival__c= system.Today() + 5,
                Time_of_Smart_Hands_Tech_Arrival__c= '15:00'
            )
        };

        insert rmaOrderList;
        rmaOrderList[0].Send_Smart_Hands_Service__c=true;
        rmaOrderList[0].Date_of_Smart_Hands_Arrival__c= system.Today() + 5;
        rmaOrderList[0].Time_of_Smart_Hands_Tech_Arrival__c= '15:00';
        update rmaOrderList[0];
        Map<Id, RMA_Order__c> mapRma = new Map<Id, RMA_Order__c>(rmaOrderList);

        Test.startTest();

        Map<Id, List<Order>> mapRmaIdLstOrder = new Map<Id, List<Order>>();
        for (Order ord : [
            SELECT Id, Order_Sub_Type__c ,RMA_Request__c, Support_End_Date__c, Support_Start_Date__c,
                (SELECT Id, unitPrice FROM OrderItems)
            FROM Order
            WHERE RMA_Request__c IN :mapRma.keySet()
        ]) {
            if (!mapRmaIdLstOrder.containsKey(ord.RMA_Request__c)) {
                mapRmaIdLstOrder.put(ord.RMA_Request__c, new List<Order>());
            }
            mapRmaIdLstOrder.get(ord.RMA_Request__c).add(ord);
        }
        Test.stopTest();

        for (RMA_Order__c rma : rmaOrderList) {
            List<Order> relatedOrders = new List<Order>(mapRmaIdLstOrder.get(rma.Id));
            Order techOrder;
            Order partOrder;
            for (Order ord : relatedOrders) {
                if (ord.Order_Sub_Type__c == 'Part Order') {
                    partOrder = ord;
                    continue;
                } else if (ord.Order_Sub_Type__c == 'Tech Order') {
                    techOrder = ord;
                    continue;
                }
            }
            if (rma.Send_Smart_Hands_Service__c) {
            /*
                System.debug('rma.Send_Smart_Hands_Service__c');
                System.assertNotEquals(null, techOrder, 'only 1 Tech Order Should be Populated for Tech Order' );
                System.assertEquals(1, techOrder.OrderItems.size(), 'only 1 Order Item Allowed for Tech Order');
                System.assertEquals(System.today(), techOrder.Support_Start_Date__c, 'Support Start Date different');
                System.assertEquals(
                    DateTime.newInstance(
                        rma.Date_of_Smart_Hands_Arrival__c,
                        Time.newInstance(
                            Integer.valueOf(rma.Time_of_Smart_Hands_Tech_Arrival__c.split(':')[0]),
                            Integer.valueOf(rma.Time_of_Smart_Hands_Tech_Arrival__c.split(':')[1]),
                            0,
                            0
                        )
                    ),
                    techOrder.Support_Start_Date__c,
                    'Support End Date different'
                );
            */
            }
        }
    }

}