@isTest
public class LCC_ButtonsControllerTest { 
    @testSetup
    static void setup() {

        insert new TriggerControl__c(name = 'Order', DisableTrigger__c = false);
        insert new TriggerControl__c(name = 'Entitlement', DisableTrigger__c = false);


        insert new ShGl_DisableBusinessLogic__c(Disable_Entitlement_Validation_Rules__c = true,Disable_Order_Email_Alerts__c = false, Disable_Order_Old_Trigger__c = true, Disable_Order_Triggers__c = false, setupOwnerId = userinfo.getuserid());

        insert new List<PS_Project_Manager_Mapping__c>{
            new PS_Project_Manager_Mapping__c(Name = 'United States Minor Outlying Islands', Project_Manager_User_Id__c = UserInfo.getUserId(), Project_Manager__c = 'Test', Unique_External_ID__c = 'US'),
                new PS_Project_Manager_Mapping__c(Name = 'testing DIEtestsalesforce 4/6/2015', Project_Manager_User_Id__c = UserInfo.getUserId(), Project_Manager__c = 'Test', Unique_External_ID__c = 'United States-Florida'),
                new PS_Project_Manager_Mapping__c(Name = 'NS', Project_Manager_User_Id__c = UserInfo.getUserId(), Project_Manager__c = 'Test', Unique_External_ID__c = 'Canada')
                };

                    insert new List<GTC_Screening__c>{
                        new GTC_Screening__c(Party_Name__c='Test', CountryCode__c = 'US', Type__c = 'Include', Address__c ='Test'),
                            new GTC_Screening__c(Party_Name__c='ABC', CountryCode__c = 'FR', Type__c = 'Exclude', Address__c ='ABC')
                            };

                                Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();

        Account act =new Account(BillingCountryCode = 'IN', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = devRecordTypeId, 
                                 BillingStreet = '87 Plot',
                                 BillingCity = 'Hyderabad',
                                 BillingState = 'Telangana',
                                 BillingPostalCode = '500068',
                                 ShippingPostalCode = '500068',
                                 ShippingCountry = 'India',
                                 BillingCountry = 'India',
                                 ShippingStreet = '87 Plot' ,
                                 ShippingState = 'Telangana' ,
                                 ShippingCity = 'Hyderabad',
                                 Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');

        insert act;

        insert new list<Rebate_Table__c>{
            new Rebate_Table__c( Rebate__c = 10,
                                ASPEN_Rebate__c = 8,
                                Distributor__c = act.id,
                                Rebate_Type__c ='Distributor Fee',
                                Rebate_Deal_Type__c='All',
                                Start_Date__c=system.Today()-10,
                                End_Date__c=system.Today() + 180,
                                Installation_Product__c = 'ABC_InstallType',
                                Value_Add_Distribution_fee__c = 3
                               ),
                new Rebate_Table__c( Rebate__c = 10,
                                    ASPEN_Rebate__c = 8,
                                    Distributor__c = act.id,
                                    Rebate_Type__c ='Velocity Partner Program Rebate',
                                    Rebate_Deal_Type__c='All',
                                    Start_Date__c=system.Today()-10,
                                    End_Date__c=system.Today() + 180,
                                    Installation_Product__c = 'ABC_InstallType',
                                    Value_Add_Distribution_fee__c = 3
                                   )
                };

                    PS_Project__c objPsProject = new PS_Project__c();
        objPsProject.Name = 'test project';
        objPsProject.Account__c = act.id;
        insert objPsProject;
	
	Id pricebookId = Test.getStandardPricebookId();
    	opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' ,pricebook2Id = pricebookId, Opportunity_Sub_Type__c = 'Regular', Distributor_Lookup__c = act.Id, Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                           Mosaic_Customer_Environment__c='AWS', CloseDate = Date.Today().addDays(10), Lead_Email_Hidden__c='', AccountId = act.Id, StageName = '1 Discovery',
                                           Rubrik_Sales_Engineer__c = UserInfo.getUserId(), Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal', Alliance_Source_Type_SW__c = 'Alliance Initiated Deal', Installation_Assigned_To__c ='FE Install',
                                           Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                           Identified_Pain__c = 'Test', Champion__c = 'Test', ForecastCategoryName = 'Best Case');

        insert oppr;

        test.startTest();

        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = oppr.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__ExpirationDate__c = date.today().addDays(-10);
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        qt.SBQQ__Type__c = 'Amendment';
        qt.Is_Refreshed__c = true;

        insert qt;

														
        SBQQ__Quote__c  qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c WHERE id =: qt.id ];

        test.stopTest();

        SBQQ__QuoteDocument__c doc = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c = qt.Id,
            SBQQ__Template__c = 'Standard Quote',
            SBQQ__Opportunity__c = oppr.Id
        );

        insert doc;

        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c = act.Id;
        pos.PO_Internal_Validation_Status__c = 'Success';
        pos.Payment_schedule_type__c='test';
        pos.Service_Level__c = Null;

        insert pos;
    }

    static testMethod void testInsertOder(){

        insert new RPS__c(SetupOwnerId = Userinfo.getOrganizationId(), Is_RPS_Required__c =false, Screening_Source__c ='Internal', Valid_HoldCodes__c ='Global Trade Compliance screening failed;Credit Check Failed');

        testDataFactoryClass.createCustomSettings();

        System.runAs(new User(Id=UserInfo.getUserId())) {

            Account acct = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];

            acct.Sync_to_NetSuite__c = false;
            update acct;
           /* Apttus__APTS_Agreement__c newAg = new Apttus__APTS_Agreement__c();
           comment
            newAg.Apttus__Account__c = acct.Id;
            newAg.Apttus__Status_Category__c ='Request';
            newAg.Apttus__Status__c = 'Request';
            insert newAg;*/
            Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId =: acct.Id LIMIT 1];
            oppr.pricebook2Id= Test.getStandardPricebookId();
	    update oppr;

            insert new Hold_Off_Tracking__c (Hold_Code__c = 'OM Internal Review', Release_Date_Time__c = datetime.newInstance(2021, 9, 15, 12, 30, 0), Related_Opportunity__c = oppr.Id, Is_Released__c = false);


            List<Product2> lstProds = new List<Product2>{
                new Product2(
                    Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344',Family='ASE', Appliance_Model_HW__c = 'RBK-R6408F',
                    isActive = true
                ),
                    new Product2(
                        Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344', Appliance_Model_HW__c = 'RBK-R640F',
                        isActive = true , Bundle_Features__c = 'Cloud Native Protection', Family ='POLARIS'
                    )
                    };

                        insert lstProds;

            List<PricebookEntry> lstPbEntry =new List<PricebookEntry>{
                new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = lstProds[0].Id,
                    UnitPrice = 100.00,
                    IsActive = true
                ),
                    new PricebookEntry(
                        Pricebook2Id = Test.getStandardPricebookId(),
                        Product2Id = lstProds[1].Id,
                        UnitPrice = 100.00,
                        IsActive = true
                    )
                    };

                        insert lstPbEntry;

            List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
                new OpportunityLineItem(
                    OpportunityId = oppr.Id,
                    Quantity = 5,
                    PricebookEntryId = lstPbEntry[0].Id,
                    TotalPrice = 5 *  lstPbEntry[0].UnitPrice
                ),
                    new OpportunityLineItem(
                        OpportunityId = oppr.Id,
                        Quantity = 5,
                        PricebookEntryId = lstPbEntry[1].Id,
                        TotalPrice = 5 *  lstPbEntry[1].UnitPrice
                    )
                    };

                        insert lstOlis;

            test.startTest();

            Map<String, Object>  OrderMap = new Map<String, Object> {
                'Type' => 'Revenue',
                    'AccountId' => acct.Id,
                    'OpportunityId' => oppr.Id,
                    'Sync_to_NetSuite__c' => true,
                    'EffectiveDate' => system.today(),
                    'Status' => 'Pending',
		    'Order_Status__c' => 'Shipped',
		    'Mosaic_SKUs__c' => 'RBK-MOSAIC',
                    'ShippingCountryCode' => 'US',
                    'Polaris_Fulfillment_Status__c' => 'Completed'
                    };

                        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            insert Ord;

            List<OrderItem> lstOrdrItems = new List<OrderItem>{
                new OrderItem(
                    OrderId = Ord.Id,
                    Quantity = 5,
                    PricebookEntryId = lstPbEntry[0].Id,
		    Trade_Up_SerialNumber__c = 'S3F4NXMM416324',
	            UnitPrice = lstPbEntry[0].UnitPrice,
                    SerialNumber__c = 'S3F4NXMM416324',
                    Failed_Serial_Number__c = 'S3F4NXM416324',
                    Support_End_Date__c = System.Today().addYears(1),
                    Support_Start_Date__c = System.Today()
                ),
                    new OrderItem(
                        OrderId = Ord.Id,
                        Quantity = 5,
                        PricebookEntryId = lstPbEntry[1].Id,
                        UnitPrice = lstPbEntry[1].UnitPrice,
                        SerialNumber__c = 'S3F4NXMM416324',
                        Failed_Serial_Number__c = 'S3F4NXM416324',
                        Support_End_Date__c = System.Today().addYears(1),
                        Support_Start_Date__c = System.Today(),
                        POC_Option__c = 'AWS'
                    )
                    };

                        insert lstOrdrItems;
            PO_Stage__c poId=[Select id,Opportunity__c,PO_Validation_Status__c, PO_Internal_Validation_Status__c from PO_Stage__c where Bill_To_Name__c=:acct.id];
            poId.PO_Validation_Status__c='success';
            poId.Opportunity__c=oppr.id;
            update poId;
            
            Order phantomOrd = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            phantomOrd.Order_Status__c = 'Pending';
            insert phantomOrd;
            List<OrderItem> phnatomOrdrItems = new List<OrderItem>{
                new OrderItem(
                    OrderId = phantomOrd.Id,
                    Quantity = 5,
                    PricebookEntryId = lstPbEntry[0].Id,
		    Trade_Up_SerialNumber__c = 'S3F4NXMM416324',
	            UnitPrice = lstPbEntry[0].UnitPrice,
                    SerialNumber__c = 'S3F4NXMM416324',
                    Failed_Serial_Number__c = 'S3F4NXM416324',
                    Support_End_Date__c = System.Today().addYears(1),
                    Support_Start_Date__c = System.Today()
                )};
             test.stopTest();
             insert phnatomOrdrItems; 
            List<Order> orders = [Select id,ordernumber,Associated_Order_Numbers__c,Hold_Code__c,Polaris_Fulfillment_Status__c,Order_Status__c from Order limit 2];
            orders[0].Associated_Order_Numbers__c = orders[1].orderNumber;
            for(order ordRec :  orders){
                ordRec.Hold_Code__c = null;
                ordRec.Polaris_Fulfillment_Status__c  = 'Completed';
                ordRec.Order_Status__c = 'Shipped';
            }
            update orders;
            LCC_ButtonsController.saveRecord(Ord);
            LCC_ButtonsController.saveOrderRecord(orders[0], new List<Object>{'SubmitPhantomOrder'});
            LCC_ButtonsController.getOrderItems(Ord.Id);
            LCC_ButtonsController.getRMAOrderItems(Ord.Id);
            LCC_ButtonsController.getSetupCompanyMaster();
            //LCC_ButtonsController.singleEmail(newAg);
            LCC_ButtonsController.resynEdi(poId.id);
	        LCC_ButtonsController.fetchAssetsWithOrderLines();
        }
    }

    /*
        @Author: Sukesh k
        @Description: DGWD-130
        covers: quotedString, getOrder, cancelOrder
    */
    @isTest
    static void cancelOrder() {
        insert  new List<CountryWithCode__c>{
            new CountryWithCode__c(Name = 'United States', Code__c = 'US'),
            new CountryWithCode__c(Name = 'India', Code__c = 'IN')
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
                status__c='Submitted',
                Send_Smart_Hands_Service__c=false
            )
        };

        insert rmaOrderList;


        Test.startTest();
        Order ord = LCC_ButtonsController.getOrder( rmaOrderList.get(0).Id, 'RMA', 'Part Order' );
        LCC_ButtonsController.cancelOrder(ord.Id);
        Test.stopTest();

        System.assertNotEquals(null, ord, 'Order doesn\'t Exists');
        ord = [SELECT Cancel_RMA__c, Id FROM Order WHERE Id = :ord.Id LIMIT 1 ];

        System.assertEquals(true, ord.Cancel_RMA__c, 'Order not Cancelled');
    }
    @isTest
    static void cancelOrderFail() {
        Test.startTest();
        Boolean hasFailedOnce = false;
        Boolean hasFailedSecond = false;
        try {
            Order ord = LCC_ButtonsController.getOrder( null, 'RMA', 'Part Order' );
        } catch (Exception e) {
            hasFailedOnce = true;
        }
        if (hasFailedOnce) {
            try {
                LCC_ButtonsController.cancelOrder(null);
            } catch (Exception e) {
                hasFailedSecond = true;
            }
        }
        Test.stopTest(); 

        System.assertEquals(true, hasFailedOnce, 'did not fail as expected');
        System.assertEquals(true, hasFailedSecond, 'did not fail as expected');
    }


    @isTest
    static void saveOpportunityTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc=[select id,name from Account where name='test'];
        LCC_ButtonsController.saveOpportunity(opp);
        //Lcc_ButtonsController.getAccountRec(acc.Id);
	Lcc_ButtonsController.getAccountRec(acc.Id, false);
        Lcc_ButtonsController.getAccountRec(acc.Id, true);
    }

    @isTest
    static void resyncPO(){
        PO_Stage__c po = [SELECT Id FROM PO_Stage__c LIMIT 1];
        po.PO_Validation_Status__c ='Success';
        update po;
        LCC_ButtonsController.resynEdi(po.id);
    }
    
    @isTest
    static void ContentDocumentLinkTest(){
        
        Account acc=[select id,name from Account where name='Test' limit 1];

        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=acc.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        Lcc_ButtonsController.getFiles(contentlink.id);        
        Lcc_ButtonsController.deleteFiles(contentlink.contentdocumentid);
    }
    @isTest
    static void createEntitlementSupportRecTest(){
         Cluster__c clus=new Cluster__c();
         clus.uuid__c='Test_uuid__c';
         clus.Name='Test_uuid__c';
         insert clus;
        
        
         Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act =new Account(BillingCountryCode = 'US', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = devRecordTypeId, Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');
        insert act;
        
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-SVC-test-product';
        prdHW.Product_Subtype__c = 'GO';
        insert prdHW;
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;
        
        Asset ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = act.Id;
        ast.Name = 'EntitlementTriggerHelperAsset';
        ast.Rubrik_Suite__c = 'Foundation';
        ast.Payment_Options__c = 'Annual';
        ast.SerialNumber = '123\\s+';
        ast.Support_Type__c = 'L3';
        ast.Licensing_Model__c = 'Perpetual';
        ast.Product2Id = prdHW.Id;
        insert ast;
        
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Amount = 100;
        opportunityObj.OppSubscriptionTermMonths__c = 12;
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        system.debug('opportunityObj is ###### ' + opportunityObj);
        insert opportunityObj;
        
        Entitlement secondEnt = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        secondEnt.AccountId = act.Id;
        secondEnt.StartDate = Date.today().addDays(-365);
        secondEnt.EndDate = Date.today().addDays(365);
        secondEnt.AssetId = ast.Id;
        secondEnt.Renewable__c = true;
        secondEnt.Type = 'Phone Support';
        secondEnt.Name = 'EntitlementTriggerHelper';
        secondEnt.Product__c = prdHW.Id;
        secondEnt.Refreshed_Opportunity_Link__c = opportunityObj.Id;
        insert secondEnt;
       
        
        Entitlement_Warranty_Details__c warrantyDetail=new Entitlement_Warranty_Details__c();
        warrantyDetail.Name='testwarranty';
        warrantyDetail.Entitlement__c = secondEnt.id;
        warrantyDetail.Cluster__c=clus.Id;
        insert warrantyDetail;
        Lcc_ButtonsController.createEntitlementSupportRec(warrantyDetail);
        
    }
	
	@isTest
    static void rscProcessTest(){
        Account partnerAcc = [Select Id, Name FROM Account Limit 1];
        insert new TriggerControl__c(name = 'Entitlement', DisableTrigger__c = false);
        Entitlement rscEnt = new Entitlement(); 
        rscEnt.Name = 'RSC';
        rscEnt.AccountId = partnerAcc.Id;
        rscEnt.Type = 'Admin';
        rscEnt.SubType__c = 'RSC';
        rscEnt.StartDate = Date.today();
        rscEnt.EndDate = Date.today().addDays(60);
        insert rscEnt;
        //EntitlementUpdate__e updateent=  new EntitlementUpdate__e(RecordId__c = rscEnt.id, RSC_Status__c = 'Fail');
        
        //EventBus.publish(updateent);
        RSC_Process__c recordsForUpdate = new RSC_Process__c();
        Map<String, String> fieldsMap = new Map<String, String>();
        String jsonResponse = '{"access_token":"test"}';
		Test.setMock(HttpCalloutMock.class, new PolarisAPIMock(200,jsonResponse));
        fieldsMap.put('AccountID__c', partnerAcc.Id);
        fieldsMap.put('Customer_Suggest_URL__c', 'CustomerURL');
        fieldsMap.put('Expiry_Date__c', String.valueOf(Date.today().addDays(30)));
        fieldsMap.put('PolarisRegion__c', 'US');
        fieldsMap.put('Polaris_Suggest_URL__c', 'PolarisURL');
        fieldsMap.put('RSC_Contact_Email__c', 'contact@email.com');
	
        LCC_ButtonsController.response_Wrapper res = LCC_ButtonsController.upsertRSCProcess(fieldsMap,true,true,partnerAcc);
        LCC_ButtonsController.response_Wrapper res2 = LCC_ButtonsController.upsertRSCProcess(fieldsMap,true,false,partnerAcc);

        test.startTest();
        LCC_ButtonsController.doCallout(res.rscRecId);
        test.stopTest();
    }
    
    @isTest
    static void rscProcessTest1(){
        Account partnerAcc = [Select Id, Name FROM Account Limit 1];
        insert new TriggerControl__c(name = 'Entitlement', DisableTrigger__c = false);
        Entitlement rscEnt = new Entitlement(); 
        rscEnt.Name = 'RSC';
        rscEnt.AccountId = partnerAcc.Id;
        rscEnt.Type = 'Admin';
        rscEnt.SubType__c = 'RSC';
        rscEnt.StartDate = Date.today();
        rscEnt.EndDate = Date.today().addDays(60);
        insert rscEnt;
        //EntitlementUpdate__e updateent=  new EntitlementUpdate__e(RecordId__c = rscEnt.id, RSC_Status__c = 'Fail');
        
        //EventBus.publish(updateent);
        RSC_Process__c recordsForUpdate = new RSC_Process__c();
        Map<String, String> fieldsMap = new Map<String, String>();
        String jsonResponse = '{"access_token":"test"}';
		Test.setMock(HttpCalloutMock.class, new PolarisAPIMock(400,jsonResponse));
        fieldsMap.put('AccountID__c', partnerAcc.Id);
        fieldsMap.put('Customer_Suggest_URL__c', 'CustomerURL');
        fieldsMap.put('Expiry_Date__c', String.valueOf(Date.today().addDays(30)));
        fieldsMap.put('PolarisRegion__c', 'US');
        fieldsMap.put('Polaris_Suggest_URL__c', 'PolarisURL');
        fieldsMap.put('RSC_Contact_Email__c', 'contact@email.com');
	
        LCC_ButtonsController.response_Wrapper res = LCC_ButtonsController.upsertRSCProcess(fieldsMap,true,true,partnerAcc);
        test.startTest();
        LCC_ButtonsController.doCallout(res.rscRecId);
        test.stopTest();
    }
    
@isTest
    static void testUpdateQuoteAndCreatePoStageError(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new ShGl_DisableBusinessLogic__c(Disable_Opportunity_Validation_Rules__c = true);
            Opportunity oppr = [SELECT Id,accountId,Opportunity_Sub_Type__c,Renewals_Forecast_Risk__c, pricebook2Id,stagename,RecordTypeId FROM Opportunity LIMIT 1];

            opportunity oppr1 = new opportunity(
                Name = 'testing DIEtestsalesforce 4/6/2015',
                CloseDate = Date.Today().addDays(10),
                AccountId = oppr.accountId,
                Renewals_Forecast_Risk__c = 'Subscription',
                stagename = '1 Discovery',
                Opportunity_Sub_Type__c = 'Renewal',
                RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
            );
            insert oppr1;

            oppr.Renewals_Forecast_Risk__c = 'Subscription';  
            oppr.stagename = '2 Consensus';  
            oppr.Opportunity_Sub_Type__c = 'Renewal'; 
            oppr.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
            update oppr;
            SBQQ__Quote__c quoteRec = [SELECT Id,Name,SBQQ__Primary__c,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.Name FROM SBQQ__Quote__c LIMIT 1];
            quoteRec.SBQQ__Opportunity2__c = oppr.Id;
 			update quoteRec;           
            String str = LCC_ButtonsController.updateQuoteAndCreatePoStageError(quoteRec);
            quoteRec.SBQQ__Primary__c = false;
            update quoteRec;
            String str1 = LCC_ButtonsController.updateQuoteAndCreatePoStageError(quoteRec);

            SBQQ__Quote__c quoteNew = quoteRec.clone();
            quoteNew.SBQQ__Primary__c = false;
            quoteNew.SBQQ__Status__c = 'Approved';
            quoteNew.SBQQ__Opportunity2__c = oppr1.Id;
            insert quoteNew;

            String str2 = LCC_ButtonsController.updateQuoteAndCreatePoStageError(quoteNew);
            
            try {
                // This should trigger the AuraHandledException
            String str3 = LCC_ButtonsController.updateQuoteAndCreatePoStageError(null);
                
                // If no exception is thrown, fail the test
                System.assert(false, 'Expected AuraHandledException was not thrown');
                
            } catch (AuraHandledException e) {
                // Verify exception message
                System.assertEquals(
                    'Script-thrown exception',
                    e.getMessage()
                );
            }
            LCC_ButtonsController.AssetDetailWrapper wrapper =
            new LCC_ButtonsController.AssetDetailWrapper();

        // Call the void method (not a constructor)
        wrapper.AssetDetailWrapper(
            null,
            'Test Account',
            'Test Asset',
            Date.today(),
            'Test Product',
            'TSN-001',
            'QT-001',
            'OI-001',
            'ORD-001'
        );
        try{
        LCC_ButtonsController.saveOpportunity(null);     
        }catch(Exception ex){
        System.assert(ex != null);
        }
        try{
        string saveRecordStr =  LCC_ButtonsController.saveRecord(null);
        }catch(Exception ex){
        System.assert(ex != null);
        }
        try{
        LCC_ButtonsController.cancelOrder(null);
        }catch(Exception ex){
        System.assert(ex != null);
        }
        try{
        LCC_ButtonsController.resynEdi(null);
        }catch(Exception ex){
        System.assert(ex != null);
        }
        Entitlement ett =  LCC_ButtonsController.createFreeEntitlementRecord(oppr.accountId);        
        system.Assert(str != NULL);
        }    
    }  
    
    
    
    
    
    
    @isTest
    static void testEntitlementUpdatePlatformEvent(){
        Account partnerAcc = [Select Id, Name FROM Account Limit 1];
        insert new TriggerControl__c(name = 'Entitlement', DisableTrigger__c = false);
        Entitlement rscEnt = new Entitlement(); 
        rscEnt.Name = 'RSC';
        rscEnt.AccountId = partnerAcc.Id;
        rscEnt.Type = 'Admin';
        rscEnt.SubType__c = 'RSC';
        rscEnt.StartDate = Date.today();
        rscEnt.EndDate = Date.today().addDays(60);
        insert rscEnt;
        EntitlementUpdate__e updateent=  new EntitlementUpdate__e(RecordId__c = rscEnt.id, RSC_Status__c = 'Fail');
        test.startTest();
        EventBus.publish(updateent);
    	test.stopTest();
    }
    
    @isTest
    static void testgetQuoteInsert(){
        Opportunity opp = [SELECT Id, OwnerId,                      
                     Initial_Contacts_Name__c,
                     AccountId,
                     Partner_Lookup__c,
                     Distributor_Lookup__c,                     
                     Account.BillingCountry,
                     Account.Name,
                     Account.BillingStreet,
                     Account.BillingCity,
                     Account.BillingState,
                     Account.BillingPostalCode,
                     Account.ShippingPostalCode,
                     Account.ShippingCountry,
                     Account.ShippingStreet,
                     Account.ShippingState,
                     Account.ShippingCity,
                     Opportunity_Sub_Type__c,
                     Installation_Assigned_To__c,
                     Account.Is_Refreshed__c
                     FROM Opportunity WHERE Name = 'testing DIEtestsalesforce 4/6/2015' LIMIT 1];
    
        if(opp.Id != NULL){
            Id sqId = LCC_ButtonsController.getQuoteInsert(
                Opp.Id, opp.OwnerId, opp.Initial_Contacts_Name__c, opp.AccountId, opp.Partner_Lookup__c,
                                                              opp.Distributor_Lookup__c , '01s1W0000003MzoQAE','01s1W0000003MzoQAE', opp.Account.BillingCountry, opp.Account.Name, opp.Account.BillingStreet,
                                                              opp.Account.BillingCity, opp.Account.BillingState, opp.Account.BillingPostalCode, opp.Account.ShippingPostalCode, opp.Account.ShippingCountry,
                                                              opp.Account.ShippingStreet, opp.Account.ShippingState, opp.Account.ShippingCity, opp.Opportunity_Sub_Type__c, opp.Installation_Assigned_To__c,
                                                              opp.Account.Is_Refreshed__c, FALSE
            );
            system.Assert(sqId != NULL);
        }    
	}
}