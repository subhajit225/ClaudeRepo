/***********************************************************************************************************
* Method Name          : CustomRenewalTest
* Date Created/Modified: 
* @description         : 
* Test Class           :
/**********************************************************************************************************/
@isTest
public class CustomRenewalTest {
    /***********************************************************************************************************
    * Method Name          : testRenewalCustomContract
    * @description         : test method for code coverage
    /**********************************************************************************************************/
    static testMethod void  testRenewalCustomContract() {
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u1 = new User(Alias = 'standt', Email='test.testmethod@rubrik.com.invalid', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardusertestRC@testorg.com');
        
		List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
        ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Disable_SBQQ_Quote_Triggers__c = false
        );
        insert setting;

        ShGl_DisableBusinessLogic__c currentUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = UserInfo.getUserId(), 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true //FY25SR-2247
        );
        disableBusinessLogic.add(currentUserDB);
        // INSERT new ShGl_DisableBusinessLogic__c();

        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        //Deactivate triggers
        ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
        );
        disableBusinessLogic.add(runAsUserDB);
        insert disableBusinessLogic;
        
        System.runAs(usr1) {
            List<ServiceContract> sC = new List<ServiceContract>();
            //Generate the Account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
    
            Opportunity opp = TestDataFactory.getOpportunity(act);

        
            
            TriggerControl__c custsetting = new TriggerControl__c();
            custsetting.Name = 'Entitlement';
            custsetting.DisableTrigger__c = true;
            insert custsetting;
            
            insert act; 
            List<Account> accList = new List<Account>();
            accList.add(act);
            Assert.areEqual(1, accList.size());
        
        
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
                        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
            
            Id pbId = Test.getStandardPriceBookId();  
            
            
            opp.SBQQ__QuotePricebookId__c =pbId;     
            insert opp;
            
            Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};
                Map<String, Object> prdMap = new Map<String, Object> {
                    'Name' => 'HW',
                        'ProductCode' => 'RS-BT-EE-PE-PP',
                        'IsActive' => true,
                        'SBQQ__AssetConversion__c' => 'One per unit',
                        'SBQQ__SubscriptionType__c' => 'Renewable'
                        // 'SBQQ__RenewalProduct__c' => ''
                        };
                            
                            Map<String, Object> prdMap1 = new Map<String, Object> {
                                'Name' => 'HW',
                                    'ProductCode' => 'RH-6304S-01',
                                    'IsActive' => true, 
                                    'SBQQ__SubscriptionPricing__c' => null, 
                                    'SBQQ__SubscriptionTerm__c' => null, 
                                    'SBQQ__SubscriptionType__c' => 'Renewable' 
                                    //    'SBQQ__RenewalProduct__c' => null
                                    //          'SBQQ__RenewalProduct__c' => product2.SBQQ__RenewalProduct__r.
                                    }; 
                                        
                                        Map<String, Object> prdMap2 = new Map<String, Object> {
                                            'Name' => 'HWSupport',
                                                'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                'IsActive' => true, 
                                                'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                                'SBQQ__SubscriptionTerm__c' => 12,
                                                'SBQQ__SubscriptionType__c' => 'Renewable'
                                                //    'SBQQ__RenewalProduct__c' => null
                                                };
                                                    Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
            
            Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            
            Product2 prdSubsub = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
            
            List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
            prdList.add(prdHW);
            prdList.add(prdSubs);
            prdList.add(prdSubsub);
            insert prdList;
            
            List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeHW.Product2Id = prdHW.Id;
            pBList.add(pbeHW); 
            
            PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSubs.Product2Id = prdSubs.Id;
            pBList.add(pbeSubs);
            
            PricebookEntry pbeSubsub = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSubsub.Product2Id = prdSubsub.Id;
            pBList.add(pbeSubsub);
            insert pBList;
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__PriceBook__c = pbId;
            qt.ApprovalStatus__c = 'Approved';
            qt.SBQQ__Type__c = 'Renewal+Expansion';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            qt.Consolidate_Lines__c = false;
            insert qt;
        
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard');  
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli1.id, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard' ); 
            SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubsub.Id, SBQQ__RequiredBy__c = qli2.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli2.id,SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard' ); 
            qliList.add( qli1 );
            TriggerControls.disableQuoteLineTrigger = true;
            qliList.add( qli2 );
            TriggerControls.disableQuoteLineTrigger = false;
            qliList.add( qli3 );
            insert qliList;
            
            Order ord = new Order();
            ord.PoNumber = '12345';
            ord.ShippingPostalCode = '123455';
            ord.PO_Number__c = '123455';
            ord.Overage_PO__c = 'test';
            ord.Shipping_Address_Label__c = 'test';
            ord.ShippingCity = 'test';
            ord.ShippingCountry = 'Aland Islands';
            ord.ShippingCountryCode = 'AX';
            ord.Status = 'Draft';
            ord.accountId = act.Id;
            ord.EffectiveDate = Date.today();
            insert ord;
            Asset newAsset1 = new Asset(Name = 'AA165203480078', SerialNumber = 'AA165203480078', Product2Id = prdHW.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
            insert newAsset1;
            Asset newAsset2 = new Asset(Name = 'AA165203480079', SerialNumber = 'AA165203480079', Product2Id = prdSubs.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
            insert newAsset2;
            Asset newAsset3 = new Asset(Name = 'AA165203480080', SerialNumber = 'AA165203480080', Product2Id = prdSubsub.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
            insert newAsset3;
            
            ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                    PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150,SBQQSC__Quote__c = qt.id);
            ServiceContract serviceContractObj1 = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                    PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150,SBQQSC__Quote__c = qt.id);
            
            sc.add(serviceContractObj);
            sc.add(serviceContractObj1);
            insert sc;
            
            
            ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj.SBQQSC__Account__c = act.Id;
            ContractLineItemObj.PricebookEntryId = pbeHW.Id;
            ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj.Quantity = 10;
            ContractLineItemObj.AssetId = newAsset1.Id;
            ContractLineItemObj.UnitPrice = 100;
            ContractLineItemObj.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObj.SBQQSC__Product__c = prdHW.Id;
            ContractLineItemObj.Licensing_Model__c = 'Subscription';
            ContractLineItemObj.StartDate = System.today();
            ContractLineItemObj.EndDate =System.today() + 150;
            ContractLineItemObj.SBQQSC__RootId__c = newAsset1.Id;
            ContractLineItemObj.SBQQSC__ProductSubscriptionType__c='Renewable';
            ContractLineItemObj.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObj.SBQQSC__RenewalQuantity__c = 20;
            
            ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj1.SBQQSC__Account__c = act.Id;
            ContractLineItemObj1.PricebookEntryId = pbeSubs.Id;
            ContractLineItemObj1.ServiceContractId = serviceContractObj1.Id;
            ContractLineItemObj1.AssetId = newAsset2.Id;
            ContractLineItemObj1.Quantity = 10;
            ContractLineItemObj1.UnitPrice = 100;
            ContractLineItemObj1.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObj1.Licensing_Model__c = 'Subscription';
            ContractLineItemObj1.StartDate = System.today();
            ContractLineItemObj1.SBQQSC__RootId__c = newAsset2.Id;
            ContractLineItemObj1.EndDate =System.today() + 150;
            ContractLineItemObj1.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
            ContractLineItemObj1.SBQQSC__RenewalQuantity__c = 20;
            
            ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj2.SBQQSC__Account__c = act.Id;
            ContractLineItemObj2.PricebookEntryId = pbeSubsub.Id;
            ContractLineItemObj2.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj2.AssetId = newAsset3.iD;
            ContractLineItemObj2.SBQQSC__RootId__c = newAsset2.Id;
            ContractLineItemObj2.Quantity = 10;
            ContractLineItemObj2.UnitPrice = 100;
            ContractLineItemObj2.SBQQSC__SubscriptionPricing__c='Fixed Price';
            ContractLineItemObj2.SBQQSC__Product__c = prdSubsub.Id;
            ContractLineItemObj2.Licensing_Model__c = 'Subscription';
            ContractLineItemObj2.StartDate = System.today();
            //  ContractLineItemObj2.Subscription_Term__c = 12; 
            ContractLineItemObj2.EndDate =System.today() + 150;
            ContractLineItemObj2.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
            //   ContractLineItemObj2.SBQQSC__SubscriptionType__c = 'Renewable';
            ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 20;
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            insert ContractLineItemObj;
            newAsset1.SBQQSC__RequiredByLineItem__c = ContractLineItemObj.Id;
            insert ContractLineItemObj1;
            insert ContractLineItemObj2;
            newAsset2.SBQQSC__RequiredByLineItem__c = ContractLineItemObj1.Id;
            newAsset3.SBQQSC__RequiredByLineItem__c = ContractLineItemObj2.Id;
            update newAsset1;
            update newAsset2;
            update newAsset3;
            SBQQ.TriggerControl.enable();
            
            
            
            Entitlement enttitlementNewObj5 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj5.AssetId = newAsset1.Id;
            enttitlementNewObj5.AccountId = act.Id;
            enttitlementNewObj5.StartDate = Date.today().addDays(-365);
            enttitlementNewObj5.EndDate = Date.today().addDays(+900);
            // enttitlementNewObj5.AssetId = newAsset1.Id;
            enttitlementNewObj5.ContractLineItemId = ContractLineItemObj.Id;
            enttitlementNewObj5.Renewable__c = true;
            enttitlementNewObj5.Type = 'CS Admin';
            enttitlementNewObj5.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj5.Product__c = prdHW.Id;
            enttitlementNewObj5.Renewal_Category__c = 'Renew later';
            enttitlementNewObj5.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj5.ServiceContractId = serviceContractObj.Id;
            enttitlementNewObj5.RecordTypeId = Schema.getGlobalDescribe().get('Entitlement').getDescribe().getRecordTypeInfosByDeveloperName().get('CS_Admin').getRecordTypeId();
            insert enttitlementNewObj5; 
            
            Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            //  enttitlementNewObj6.AssetId = newAsset2.Id;
            enttitlementNewObj6.AccountId = act.Id;
            enttitlementNewObj6.StartDate = Date.today().addDays(-365);
            enttitlementNewObj6.EndDate = Date.today().addDays(+900);
            // enttitlementNewObj6.AssetId = newAsset2.Id;
            enttitlementNewObj6.ContractLineItemId = ContractLineItemObj1.Id;
            enttitlementNewObj6.Renewable__c = true;
            enttitlementNewObj6.Type = 'CS Admin';
            enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
            //   enttitlementNewObj6.Product__c = prdHW.Id;
            enttitlementNewObj6.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj6.ServiceContractId = serviceContractObj1.Id;
            //    lstEntitlement.add(enttitlementNewObj5);

            enttitlementNewObj6.RecordTypeId = Schema.getGlobalDescribe().get('Entitlement').getDescribe().getRecordTypeInfosByDeveloperName().get('CS_Admin').getRecordTypeId();
            insert enttitlementNewObj6; 
            
            Entitlement enttitlementNewObj7 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj7.AccountId = act.Id;
            enttitlementNewObj7.StartDate = Date.today().addDays(-365);
            enttitlementNewObj7.EndDate = Date.today().addDays(+900);
            // enttitlementNewObj7.AssetId = newAsset3.Id;
            enttitlementNewObj7.ContractLineItemId = ContractLineItemObj2.Id;
            enttitlementNewObj7.Renewable__c = true;
            enttitlementNewObj7.Type = 'Phone Support';
            enttitlementNewObj7.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj7.Product__c = prdHW.Id; 
            enttitlementNewObj7.Refreshed_Opportunity_Link__c = opp.Id;
            enttitlementNewObj7.ServiceContractId = serviceContractObj.Id;
            //    lstEntitlement.add(enttitlementNewObj5);

            insert enttitlementNewObj7; 
        	system.assert(enttitlementNewObj7.Id != null);
        
        
        Test.startTest(); 
        customRenewal.renewalCustomContract(sC,opp.Id);
        
        //customRenewal.renewalCustomContract(sC1,opp1.Id);
        //customRenewal.renewalCustomContractFromBatch(sC,opp.Id);
        //customRenewal.renewalCustomContractFromBatch(sC,opp.Id);
        Test.stopTest();    
       }
    }
    /***********************************************************************************************************
    * Method Name          : testRenewalCustomContractBatch
    * @description         : test method for code coverage
    /**********************************************************************************************************/
    static testMethod void  testRenewalCustomContractBatch() {
       Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u1 = new User(Alias = 'standt', Email='test.testmethod@rubrik.com.invalid', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg1.com');
        List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
        ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Disable_SBQQ_Quote_Triggers__c = false
        );
        insert setting;

        ShGl_DisableBusinessLogic__c currentUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = UserInfo.getUserId(), 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true //FY25SR-2247
        );
        disableBusinessLogic.add(currentUserDB);
        // INSERT new ShGl_DisableBusinessLogic__c();

        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        //Deactivate triggers
        ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
        );
        disableBusinessLogic.add(runAsUserDB);
        insert disableBusinessLogic;

        System.runAs(usr1) {
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Entitlement';
       custsetting.DisableTrigger__c = true;
       insert custsetting;
        
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act; 
        List<Account> accList = new List<Account>();
        accList.add(act);
        Assert.areEqual(1, accList.size());
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Id pbId = Test.getStandardPriceBookId();  
        
        Opportunity opp = TestDataFactory.getOpportunity(act);
        opp.SBQQ__QuotePricebookId__c =pbId;     
        insert opp;
        
        Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};
            Map<String, Object> prdMap = new Map<String, Object> {
                'Name' => 'HW',
                    'ProductCode' => 'RS-BT-EE-PE-PP',
                    'IsActive' => true,
                    'SBQQ__AssetConversion__c' => 'One per unit',
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    // 'SBQQ__RenewalProduct__c' => ''
                    };
                        
                        Map<String, Object> prdMap1 = new Map<String, Object> {
                            'Name' => 'HW',
                                'ProductCode' => 'RH-6304S-01',
                                'IsActive' => true, 
                                'SBQQ__SubscriptionPricing__c' => null, 
                                'SBQQ__SubscriptionTerm__c' => null, 
                                'SBQQ__SubscriptionType__c' => 'Renewable' 
                                //    'SBQQ__RenewalProduct__c' => null
                                //          'SBQQ__RenewalProduct__c' => product2.SBQQ__RenewalProduct__r.
                                }; 
                                    
                                    Map<String, Object> prdMap2 = new Map<String, Object> {
                                        'Name' => 'HWSupport',
                                            'ProductCode' => 'RS-HW-SVC-PE-S1',
                                            'IsActive' => true, 
                                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                            'SBQQ__SubscriptionTerm__c' => 12,
                                            'SBQQ__SubscriptionType__c' => 'Renewable'
                                            //    'SBQQ__RenewalProduct__c' => null
                                            };
                                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        Product2 prdSubsub = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prdSubsub);
        insert prdList;
        
        
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pBList.add(pbeHW); 
        
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        
        PricebookEntry pbeSubsub = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsub.Product2Id = prdSubsub.Id;
        pBList.add(pbeSubsub);
        insert pBList;
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__PriceBook__c = pbId;
        qt.ApprovalStatus__c = 'Approved';
        qt.SBQQ__Type__c = 'Renewal+Expansion';
        qt.SBQQ__StartDate__c = Date.today();
        qt.Manual_Billing__c = false;
        qt.Consolidate_Lines__c = false;
        insert qt;
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard');  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli1.id, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard' ); 
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubsub.Id, SBQQ__RequiredBy__c = qli2.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli2.id,SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard' ); 
        qliList.add( qli1 );
        TriggerControls.disableQuoteLineTrigger = true;
        qliList.add( qli2 );
        TriggerControls.disableQuoteLineTrigger = false;
        qliList.add( qli3 );
        insert qliList;
        
        Order ord = new Order();
        ord.PoNumber = '12345';
        ord.ShippingPostalCode = '123455';
        ord.PO_Number__c = '123455';
        ord.Overage_PO__c = 'test';
        ord.Shipping_Address_Label__c = 'test';
        ord.ShippingCity = 'test';
        ord.ShippingCountry = 'Aland Islands';
        ord.ShippingCountryCode = 'AX';
        ord.Status = 'Draft';
        ord.accountId = act.Id;
        ord.EffectiveDate = Date.today();
        insert ord;
       // ord.Status = 'Activated';
       // update ord;
        Asset newAsset1 = new Asset(Name = 'AA165203480078', SerialNumber = 'AA165203480078', Product2Id = prdHW.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset1;
        Asset newAsset2 = new Asset(Name = 'AA165203480079', SerialNumber = 'AA165203480079', Product2Id = prdSubs.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset2;
        Asset newAsset3 = new Asset(Name = 'AA165203480080', SerialNumber = 'AA165203480080', Product2Id = prdSubsub.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset3;
        List<ServiceContract> sC = new List<ServiceContract>();
        ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                 PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150,SBQQSC__Quote__c = qt.id);
        ServiceContract serviceContractObj1 = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                  PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150,SBQQSC__Quote__c = qt.id);
        
        sc.add(serviceContractObj);
        sc.add(serviceContractObj1);
        insert sC;
        
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = act.Id;
        ContractLineItemObj.PricebookEntryId = pbeHW.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.AssetId = newAsset1.Id;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.SBQQSC__SubscriptionPricing__c='Fixed Price';
        ContractLineItemObj.SBQQSC__Product__c = prdHW.Id;
        ContractLineItemObj.Licensing_Model__c = 'Subscription';
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate =System.today() + 150;
        ContractLineItemObj.SBQQSC__RootId__c = newAsset1.Id;
        ContractLineItemObj.SBQQSC__ProductSubscriptionType__c='Renewable';
        ContractLineItemObj.SBQQSC__SubscriptionType__c = 'Renewable';
        ContractLineItemObj.SBQQSC__RenewalQuantity__c = 20;
        
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = act.Id;
        ContractLineItemObj1.PricebookEntryId = pbeSubs.Id;
        ContractLineItemObj1.ServiceContractId = serviceContractObj1.Id;
        ContractLineItemObj1.AssetId = newAsset2.Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.SBQQSC__SubscriptionPricing__c='Fixed Price';
        ContractLineItemObj1.Licensing_Model__c = 'Subscription';
        ContractLineItemObj1.StartDate = System.today();
        ContractLineItemObj1.SBQQSC__RootId__c = newAsset2.Id;
        ContractLineItemObj1.EndDate =System.today() + 150;
        ContractLineItemObj1.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
        ContractLineItemObj1.SBQQSC__RenewalQuantity__c = 20;
        
        ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj2.SBQQSC__Account__c = act.Id;
        ContractLineItemObj2.PricebookEntryId = pbeSubsub.Id;
        ContractLineItemObj2.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj2.AssetId = newAsset3.iD;
        ContractLineItemObj2.SBQQSC__RootId__c = newAsset2.Id;
        ContractLineItemObj2.Quantity = 10;
        ContractLineItemObj2.UnitPrice = 100;
        ContractLineItemObj2.SBQQSC__SubscriptionPricing__c='Fixed Price';
        ContractLineItemObj2.SBQQSC__Product__c = prdSubsub.Id;
        ContractLineItemObj2.Licensing_Model__c = 'Subscription';
        ContractLineItemObj2.StartDate = System.today();
        //  ContractLineItemObj2.Subscription_Term__c = 12; 
        ContractLineItemObj2.EndDate =System.today() + 150;
        ContractLineItemObj2.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
        //   ContractLineItemObj2.SBQQSC__SubscriptionType__c = 'Renewable';
        ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 20;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        insert ContractLineItemObj;
        newAsset1.SBQQSC__RequiredByLineItem__c = ContractLineItemObj.Id;
        insert ContractLineItemObj1;
        insert ContractLineItemObj2;
        newAsset2.SBQQSC__RequiredByLineItem__c = ContractLineItemObj1.Id;
        newAsset3.SBQQSC__RequiredByLineItem__c = ContractLineItemObj2.Id;
        update newAsset1;
        update newAsset2;
        update newAsset3;
        SBQQ.TriggerControl.enable();
        
        
        
        Entitlement enttitlementNewObj5 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.AccountId = act.Id;
        enttitlementNewObj5.StartDate = Date.today().addDays(-365);
        enttitlementNewObj5.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj5.Renewable__c = true;
        enttitlementNewObj5.Type = 'CS Admin';
        enttitlementNewObj5.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj5.Product__c = prdHW.Id;
        enttitlementNewObj5.Renewal_Category__c = 'Renewed';
        enttitlementNewObj5.Refreshed_Opportunity_Link__c = opp.Id;
        enttitlementNewObj5.ServiceContractId = serviceContractObj.Id;  
        enttitlementNewObj5.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();
        insert enttitlementNewObj5; 
        
        Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        //  enttitlementNewObj6.AssetId = newAsset2.Id;
        enttitlementNewObj6.AccountId = act.Id;
        enttitlementNewObj6.StartDate = Date.today().addDays(-365);
        enttitlementNewObj6.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj6.AssetId = newAsset2.Id;
        enttitlementNewObj6.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlementNewObj6.Renewable__c = true;
        enttitlementNewObj6.Type = 'CS Admin';
        enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
        //   enttitlementNewObj6.Product__c = prdHW.Id;
        enttitlementNewObj6.Refreshed_Opportunity_Link__c = opp.Id;
        enttitlementNewObj6.ServiceContractId = serviceContractObj1.Id;
        enttitlementNewObj6.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();

        //    lstEntitlement.add(enttitlementNewObj5);
        insert enttitlementNewObj6; 
        system.assert(enttitlementNewObj6.Id != null);
        /*
        Entitlement enttitlementNewObj7 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj7.AccountId = act.Id;
        enttitlementNewObj7.StartDate = Date.today().addDays(-365);
        enttitlementNewObj7.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj7.AssetId = newAsset3.Id;
        enttitlementNewObj7.ContractLineItemId = ContractLineItemObj2.Id;
        enttitlementNewObj7.Renewable__c = true;
        enttitlementNewObj7.Type = 'Phone Support';
        enttitlementNewObj7.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj7.Product__c = prdHW.Id; 
        enttitlementNewObj7.Refreshed_Opportunity_Link__c = opp.Id;
        enttitlementNewObj7.ServiceContractId = serviceContractObj.Id;
        //    lstEntitlement.add(enttitlementNewObj5);
        insert enttitlementNewObj7; 
        */
        
        Test.startTest(); 
        //serviceContractListFromBatch.renewalCustomContractFromBatch(sC,opp.Id);
        customRenewal.renewalCustomContract(sC,opp.Id);
        try{
            customRenewal.renewalCustomContract(sC,enttitlementNewObj6.Id);    
        }catch(exception e){
            System.debug(LoggingLevel.DEBUG, e.getmessage());
        }
        
        //customRenewal.renewalCustomContractFromBatch(sC,opp.Id);
        //customRenewal.renewalCustomContractFromBatch(sC,opp.Id);
        Test.stopTest();   
        }
    }
    /***********************************************************************************************************
    * Method Name          : testMethodserviceContractBatch
    * @description         : test method for code coverage
    /**********************************************************************************************************/
    static testMethod void testMethodserviceContractBatch(){
   	List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
    User usr1 = Replacement_TestDataFactory.getUser();
            usr1.RBAC_Department__c = 'Service Account';
            usr1.RBAC_Group__c = 'System - IT';
            insert usr1;
            //Deactivate triggers
            ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
                setupownerid = usr1.Id, 
                Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
                Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
                Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
                Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
                Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
                Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
            );
            disableBusinessLogic.add(runAsUserDB);
            insert disableBusinessLogic;
            
            System.runAs(usr1) {
                List<ServiceContract> sC = new List<ServiceContract>();
                //Generate the Account
                Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        
                Opportunity opp = TestDataFactory.getOpportunity(act);
    
            
                
                TriggerControl__c custsetting = new TriggerControl__c();
                custsetting.Name = 'Entitlement';
                custsetting.DisableTrigger__c = true;
                insert custsetting;
                
                insert act; 
                List<Account> accList = new List<Account>();
                accList.add(act);
                Assert.areEqual(1, accList.size());
            
            
                //Generate the Contact
                Map<String, Object> cntMap = new Map<String, Object> {
                    'AccountId' => act.Id
                        };
                            Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
                insert cnt;
                
                Id pbId = Test.getStandardPriceBookId();  
                
                
                opp.SBQQ__QuotePricebookId__c =pbId;     
                insert opp;
                
                Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};
                    Map<String, Object> prdMap = new Map<String, Object> {
                        'Name' => 'HW',
                            'ProductCode' => 'RS-BT-EE-PE-PP',
                            'IsActive' => true,
                            'SBQQ__AssetConversion__c' => 'One per unit',
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            // 'SBQQ__RenewalProduct__c' => ''
                            };
                                
                                Map<String, Object> prdMap1 = new Map<String, Object> {
                                    'Name' => 'HW',
                                        'ProductCode' => 'RH-6304S-01',
                                        'IsActive' => true, 
                                        'SBQQ__SubscriptionPricing__c' => null, 
                                        'SBQQ__SubscriptionTerm__c' => null, 
                                        'SBQQ__SubscriptionType__c' => 'Renewable' 
                                        //    'SBQQ__RenewalProduct__c' => null
                                        //          'SBQQ__RenewalProduct__c' => product2.SBQQ__RenewalProduct__r.
                                        }; 
                                            
                                            Map<String, Object> prdMap2 = new Map<String, Object> {
                                                'Name' => 'HWSupport',
                                                    'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                    'IsActive' => true, 
                                                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                                    'SBQQ__SubscriptionTerm__c' => 12,
                                                    'SBQQ__SubscriptionType__c' => 'Renewable'
                                                    //    'SBQQ__RenewalProduct__c' => null
                                                    };
                                                        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
                
                Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
                
                Product2 prdSubsub = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
                
                List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
                prdList.add(prdHW);
                prdList.add(prdSubs);
                prdList.add(prdSubsub);
                insert prdList;
                
                List<PricebookEntry> pBList = new List<PricebookEntry> ();
                
                PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
                pbeHW.Product2Id = prdHW.Id;
                pBList.add(pbeHW); 
                
                PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
                pbeSubs.Product2Id = prdSubs.Id;
                pBList.add(pbeSubs);
                
                PricebookEntry pbeSubsub = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
                pbeSubsub.Product2Id = prdSubsub.Id;
                pBList.add(pbeSubsub);
                insert pBList;
                
                SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
                qt.SBQQ__Opportunity2__c = opp.Id;
                qt.SBQQ__Primary__c = true;
                qt.SBQQ__PriceBook__c = pbId;
                qt.ApprovalStatus__c = 'Approved';
                qt.SBQQ__Type__c = 'Renewal+Expansion';
                qt.SBQQ__StartDate__c = Date.today();
                qt.Manual_Billing__c = false;
                qt.Consolidate_Lines__c = false;
                insert qt;
            
                List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
                SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard');  
                SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli1.id, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard' ); 
                SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubsub.Id, SBQQ__RequiredBy__c = qli2.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli2.id,SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard' ); 
                qliList.add( qli1 );
                TriggerControls.disableQuoteLineTrigger = true;
                qliList.add( qli2 );
                TriggerControls.disableQuoteLineTrigger = false;
                qliList.add( qli3 );
                insert qliList;
                
                Order ord = new Order();
                ord.PoNumber = '12345';
                ord.ShippingPostalCode = '123455';
                ord.PO_Number__c = '123455';
                ord.Overage_PO__c = 'test';
                ord.Shipping_Address_Label__c = 'test';
                ord.ShippingCity = 'test';
                ord.ShippingCountry = 'Aland Islands';
                ord.ShippingCountryCode = 'AX';
                ord.Status = 'Draft';
                ord.accountId = act.Id;
                ord.EffectiveDate = Date.today();
                insert ord;
                Asset newAsset1 = new Asset(Name = 'AA165203480078', SerialNumber = 'AA165203480078', Product2Id = prdHW.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
                insert newAsset1;
                Asset newAsset2 = new Asset(Name = 'AA165203480079', SerialNumber = 'AA165203480079', Product2Id = prdSubs.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
                insert newAsset2;
                Asset newAsset3 = new Asset(Name = 'AA165203480080', SerialNumber = 'AA165203480080', Product2Id = prdSubsub.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
                insert newAsset3;
                
                ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                        PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150);
                ServiceContract serviceContractObj1 = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                        PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150);
                
                sc.add(serviceContractObj);
                sc.add(serviceContractObj1);
                insert sc;
                
                
                ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
                ContractLineItemObj.SBQQSC__Account__c = act.Id;
                ContractLineItemObj.PricebookEntryId = pbeHW.Id;
                ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
                ContractLineItemObj.Quantity = 10;
                ContractLineItemObj.AssetId = newAsset1.Id;
                ContractLineItemObj.UnitPrice = 100;
                ContractLineItemObj.SBQQSC__SubscriptionPricing__c='Fixed Price';
                ContractLineItemObj.SBQQSC__Product__c = prdHW.Id;
                ContractLineItemObj.Licensing_Model__c = 'Subscription';
                ContractLineItemObj.StartDate = System.today();
                ContractLineItemObj.EndDate =System.today() + 150;
                ContractLineItemObj.SBQQSC__RootId__c = newAsset1.Id;
                ContractLineItemObj.SBQQSC__ProductSubscriptionType__c='Renewable';
                ContractLineItemObj.SBQQSC__SubscriptionType__c = 'Renewable';
                ContractLineItemObj.SBQQSC__RenewalQuantity__c = 20;
                
                ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
                ContractLineItemObj1.SBQQSC__Account__c = act.Id;
                ContractLineItemObj1.PricebookEntryId = pbeSubs.Id;
                ContractLineItemObj1.ServiceContractId = serviceContractObj1.Id;
                ContractLineItemObj1.AssetId = newAsset2.Id;
                ContractLineItemObj1.Quantity = 10;
                ContractLineItemObj1.UnitPrice = 100;
                ContractLineItemObj1.SBQQSC__SubscriptionPricing__c='Fixed Price';
                ContractLineItemObj1.Licensing_Model__c = 'Subscription';
                ContractLineItemObj1.StartDate = System.today();
                ContractLineItemObj1.SBQQSC__RootId__c = newAsset2.Id;
                ContractLineItemObj1.EndDate =System.today() + 150;
                ContractLineItemObj1.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
                ContractLineItemObj1.SBQQSC__RenewalQuantity__c = 20;
                
                ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
                ContractLineItemObj2.SBQQSC__Account__c = act.Id;
                ContractLineItemObj2.PricebookEntryId = pbeSubsub.Id;
                ContractLineItemObj2.ServiceContractId = serviceContractObj.Id;
                ContractLineItemObj2.AssetId = newAsset3.Id;
                ContractLineItemObj2.SBQQSC__RootId__c = newAsset2.Id;
                ContractLineItemObj2.Quantity = 10;
                ContractLineItemObj2.UnitPrice = 100;
                ContractLineItemObj2.SBQQSC__SubscriptionPricing__c='Fixed Price';
                ContractLineItemObj2.SBQQSC__Product__c = prdSubsub.Id;
                ContractLineItemObj2.Licensing_Model__c = 'Subscription';
                ContractLineItemObj2.StartDate = System.today();
                //  ContractLineItemObj2.Subscription_Term__c = 12; 
                ContractLineItemObj2.EndDate =System.today() + 150;
                ContractLineItemObj2.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
                //   ContractLineItemObj2.SBQQSC__SubscriptionType__c = 'Renewable';
                ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 20;
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                SBQQ.TriggerControl.disable();
                insert ContractLineItemObj;
                system.assert(ContractLineItemObj.Id != null);
                newAsset1.SBQQSC__RequiredByLineItem__c = ContractLineItemObj.Id;
                insert ContractLineItemObj1;
                insert ContractLineItemObj2;
                newAsset2.SBQQSC__RequiredByLineItem__c = ContractLineItemObj1.Id;
                newAsset3.SBQQSC__RequiredByLineItem__c = ContractLineItemObj2.Id;
                update newAsset1;
                update newAsset2;
                update newAsset3;
                List<Entitlement> lstAdd = new List<Entitlement>();
        Entitlement enttitlementNewObj5 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.AccountId = act.Id;
        enttitlementNewObj5.StartDate = Date.today().addDays(-365);
        enttitlementNewObj5.EndDate = Date.today().addDays(+900);
        enttitlementNewObj5.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj5.Renewable__c = true;
        enttitlementNewObj5.Type = 'CS Admin';
        enttitlementNewObj5.Name = 'EntitlementTriggerHelper1';
        enttitlementNewObj5.Product__c = prdHW.Id;
        //enttitlementNewObj5.Renewal_Category__c = 'Renewed';
        enttitlementNewObj5.Refreshed_Opportunity_Link__c = opp.Id;
        enttitlementNewObj5.ServiceContractId = serviceContractObj1.Id;  
           enttitlementNewObj5.Product__c = prdHW.Id;     
        enttitlementNewObj5.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();
        lstAdd.add(enttitlementNewObj5); 
        
        Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj6.AssetId = newAsset2.Id;
        enttitlementNewObj6.AccountId = act.Id;
        enttitlementNewObj6.StartDate = Date.today().addDays(-365);
        enttitlementNewObj6.EndDate = Date.today().addDays(+900);
        enttitlementNewObj6.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlementNewObj6.Renewable__c = true;
        enttitlementNewObj6.Type = 'CS Admin';
        enttitlementNewObj6.Name = 'EntitlementTriggerHelper2';
        enttitlementNewObj6.Refreshed_Opportunity_Link__c = opp.Id;
        enttitlementNewObj6.ServiceContractId = serviceContractObj1.Id;
                enttitlementNewObj6.Product__c = prdHW.Id;
        enttitlementNewObj6.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();

        lstAdd.add(enttitlementNewObj6); 
        
        Entitlement enttitlementNewObj7 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj7.AssetId = newAsset3.Id;
        enttitlementNewObj7.AccountId = act.Id;
        enttitlementNewObj7.StartDate = Date.today().addDays(-365);
        enttitlementNewObj7.EndDate = Date.today().addDays(+900);
        enttitlementNewObj7.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj7.Renewable__c = true;
        enttitlementNewObj7.Type = 'CS Admin';
        enttitlementNewObj7.Name = 'EntitlementTriggerHelper3';
        enttitlementNewObj7.Product__c = prdHW.Id;
        //enttitlementNewObj7.Renewal_Category__c = 'Renewed';
        enttitlementNewObj7.Refreshed_Opportunity_Link__c = opp.Id;
        enttitlementNewObj7.ServiceContractId = serviceContractObj1.Id;  
        enttitlementNewObj7.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();
        lstAdd.add(enttitlementNewObj7);
        insert lstAdd;  
        Test.StartTest();
        customRenewal.renewalCustomContract(sC,opp.Id);
        Test.StopTest();
       }
    }  
    /***********************************************************************************************************
    * Method Name          : testMethodserviceContractBatchClone
    * @description         : test method for code coverage
    /**********************************************************************************************************/
    static testMethod void testMethodserviceContractBatchClone(){
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u1 = new User(Alias = 'standt', Email='Shivani.Rathi@rubrik.com.invalid', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardusertestSC@testorg.com');
        List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
        ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Disable_SBQQ_Quote_Triggers__c = false
        );
        insert setting;

        ShGl_DisableBusinessLogic__c currentUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = UserInfo.getUserId(), 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true //FY25SR-2247
        );
        disableBusinessLogic.add(currentUserDB);
        // INSERT new ShGl_DisableBusinessLogic__c();

        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        //Deactivate triggers
        ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
        );
        disableBusinessLogic.add(runAsUserDB);
        insert disableBusinessLogic;
        System.runAs(usr1) {
            SBQQ.TriggerControl.disable();
            TriggerControl__c setting1 = new TriggerControl__c();
            setting1.Name = 'Opportunity';
            setting1.DisableTrigger__c = TRUE;
            insert setting1;
            TriggerControl__c setting2 = new TriggerControl__c();
            setting2.Name = 'Renewal Case';
            setting2.DisableTrigger__c = FALSE;
            insert setting2;
            TriggerControl__c setting3 = new TriggerControl__c();
            setting3.Name = 'Entitlement';
            setting3.DisableTrigger__c = TRUE;
            insert setting3;
            
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            
            Account accObj = TestDataFactory.getAccount();
            insert accObj;
            Account accObj1 = TestDataFactory.getAccount();
            accObj1.Name = 'RUBRIK_ACC_NAME';
            insert accObj1;
            Account rbkAcc = new Account(Name='Rubrik');
            insert rbkAcc;

            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => accObj1.Id
                    };
                        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;

            Opportunity oppr = TestDataFactory.getOpportunity(accObj);
            oppr.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
            insert oppr;
            
            Id standardPriceBookId =  Test.getStandardPricebookId();
            
            PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
            insert pb1;
            
            Product2 prod1 = new Product2(
                Name = 'RBK-GO-BE-R6408',
                ProductCode = 'RBK-GO-BE-R6408',
                isActive = true,
                SBQQ__SubscriptionTerm__c = 1
                //Product_Type__c = 'HW Support'
            );
            Product2 prod2 = new Product2(
                Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
                ProductCode = 'RBK-SVC-PREM-R304',
                isActive = true,
                SBQQ__SubscriptionTerm__c = 1,
                Product_Type__c = 'HW Support'
            );
            Product2 prod3 = new Product2(
                Name = 'RH-6408SE-02',
                ProductCode = 'RH-6408SE-02',
                Category__c = 'Hardware',
                Product_Subtype__c = 'GO',
                SBQQ__AssetConversion__c = 'None',
                SBQQSC__EntitlementConversion__c = 'One per unit',
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable',
                IsActive = true,
                Asset_Priority__c = 1,
                New_CPQ_Product__c = true,
                Product_Level__c = 'Hardware'
            );
            insert new List<Product2>{prod1, prod2, prod3};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1,pbStanEntry2,pbStanEntry3,pbEntry1,pbEntry2,pbEntry3};
        
        Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        qt1.MetricsLastCalcOn__c = System.today()+1;
        //qt1.LastModifiedDate = System.today()+2;
        update qt1;
        
        quoteId.add(qt1.Id);

         Order ord = new Order();
        ord.PoNumber = '12345';
        ord.ShippingPostalCode = '123455';
        ord.PO_Number__c = '123455';
        ord.Overage_PO__c = 'test';
        ord.Shipping_Address_Label__c = 'test';
        ord.ShippingCity = 'test';
        ord.ShippingCountry = 'Aland Islands';
        ord.ShippingCountryCode = 'AX';
        ord.Status = 'Draft';
        ord.accountId = accObj1.Id;
        ord.EffectiveDate = Date.today();
        insert ord;
        
        Map<String, Object> prdMap = new Map<String, Object> {
                    'Name' => 'HW',
                        'ProductCode' => 'RS-BT-EE-PE-PP',
                        'IsActive' => true,
                        'SBQQ__AssetConversion__c' => 'One per unit',
                        'SBQQ__SubscriptionType__c' => 'Renewable'
                        // 'SBQQ__RenewalProduct__c' => ''
                        };
                            
                            Map<String, Object> prdMap1 = new Map<String, Object> {
                                'Name' => 'HW',
                                    'ProductCode' => 'RH-6304S-01',
                                    'IsActive' => true, 
                                    'SBQQ__SubscriptionPricing__c' => null, 
                                    'SBQQ__SubscriptionTerm__c' => null, 
                                    'SBQQ__SubscriptionType__c' => 'Renewable' 
                                    //    'SBQQ__RenewalProduct__c' => null
                                    //          'SBQQ__RenewalProduct__c' => product2.SBQQ__RenewalProduct__r.
                                    }; 
                                        
                                        Map<String, Object> prdMap2 = new Map<String, Object> {
                                            'Name' => 'HWSupport',
                                                'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                'IsActive' => true, 
                                                'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                                'SBQQ__SubscriptionTerm__c' => 12,
                                                'SBQQ__SubscriptionType__c' => 'Renewable'
                                                //    'SBQQ__RenewalProduct__c' => null
                                                };
                                                    Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            
        Product2 prdSubsub = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prdSubsub);
        insert prdList;

        Asset newAsset1 = new Asset(Name = 'AA165203480078', SerialNumber = 'AA165203480078', Product2Id = prod3.Id, AccountId = accObj1.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset1;
        Asset newAsset2 = new Asset(Name = 'AA165203480079', SerialNumber = 'AA165203480079', Product2Id = prdSubs.Id, AccountId = accObj1.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset2;
        Asset newAsset3 = new Asset(Name = 'AA165203480080', SerialNumber = 'AA165203480080', Product2Id = prdSubsub.Id, AccountId = accObj1.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset3;
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.AccountId = accObj.Id;
        serviceContractObj.StartDate = Date.Today().addmonths(-30);
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.SBQQSC__RenewalOpportunity__c = oppr.Id;
        serviceContractObj.EndDate = System.today().addDays(360);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        lstServiceContract.add(serviceContractObj);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        renewServiceContractObj.SBQQSC__Quote__c = qt1.Id;
        renewServiceContractObj.EndDate = System.today().addDays(360);
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = Date.Today().addmonths(-29);
        ContractLineItemObj.EndDate = Date.Today().addmonths(6);
        ContractLineItemObj.SBQQSC__RenewalQuantity__c = 1;
        ContractLineItemObj.SBQQSC__RootId__c = lstServiceContract[0].Id;
        
        insert ContractLineItemObj;
        
        ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj2.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj2.PricebookEntryId = pbStanEntry3.Id;
        ContractLineItemObj2.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj2.Quantity = 10;
        ContractLineItemObj2.UnitPrice = 100;
        ContractLineItemObj2.StartDate = Date.Today().addmonths(-29);
        ContractLineItemObj2.EndDate = Date.Today().addmonths(6);
        ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 1;
        ContractLineItemObj2.SBQQSC__RootId__c = lstServiceContract[0].Id;
        
        insert ContractLineItemObj2;
        
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj1.PricebookEntryId = pbEntry1.Id;
        ContractLineItemObj1.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
                 
        Entitlement enttitlementNewObj5 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.AccountId = accObj1.Id;
        enttitlementNewObj5.StartDate = Date.today().addDays(-365);
        enttitlementNewObj5.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj5.Renewable__c = true;
        enttitlementNewObj5.Type = 'CS Admin';
        enttitlementNewObj5.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj5.Product__c = prod3.Id;
        enttitlementNewObj5.Renewal_Category__c = 'Renewed';
        enttitlementNewObj5.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj5.ServiceContractId = lstServiceContract[0].Id;  
        enttitlementNewObj5.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();
        insert enttitlementNewObj5; 
        
        Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj6.AccountId = accObj1.Id;
        enttitlementNewObj6.StartDate = Date.today().addDays(-365);
        enttitlementNewObj6.EndDate = Date.today().addDays(+900);
        enttitlementNewObj6.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlementNewObj6.Renewable__c = true;
        enttitlementNewObj6.Type = 'CS Admin';
        enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj6.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj6.ServiceContractId = lstServiceContract[1].Id;
        enttitlementNewObj6.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();

        insert enttitlementNewObj6; 
        
        Test.startTest();
        String qIdStr = customRenewal.renewalCustomContract(lstServiceContract, oppr.Id);
        String fieldStr1 = customRenewal.allFields('Account');
        Test.stopTest();
        List<SBQQ__QuoteLine__c> listQLI = [SELECT ID FROM SBQQ__QuoteLine__c];
        System.AssertEquals(listQLI.size(), 0);
        }
    }
    /***********************************************************************************************************
     * Method Name          : testMethodserviceContractBatchCloneNew
     * Date Created/Modified: 28/03/2024
     * Author               :  
     * @description         : This covers customRenewalClone class               
    /**********************************************************************************************************/
    static testMethod void testMethodserviceContractBatchCloneNew(){
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u1 = new User(Alias = 'standt', Email='Shivani.Rathi@rubrik.com.invalid', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardusertestSC@testorg.com');
        List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
        ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Disable_SBQQ_Quote_Triggers__c = false
        );
        insert setting;

        ShGl_DisableBusinessLogic__c currentUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = UserInfo.getUserId(), 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true //FY25SR-2247
        );
        disableBusinessLogic.add(currentUserDB);
        // INSERT new ShGl_DisableBusinessLogic__c();

        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        //Deactivate triggers
        ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
        );
        disableBusinessLogic.add(runAsUserDB);
        insert disableBusinessLogic;
        System.runAs(usr1) {
            SBQQ.TriggerControl.disable();
            TriggerControl__c setting1 = new TriggerControl__c();
            setting1.Name = 'Opportunity';
            setting1.DisableTrigger__c = TRUE;
            insert setting1;
            TriggerControl__c setting2 = new TriggerControl__c();
            setting2.Name = 'Renewal Case';
            setting2.DisableTrigger__c = FALSE;
            insert setting2;
            TriggerControl__c setting3 = new TriggerControl__c();
            setting3.Name = 'Entitlement';
            setting3.DisableTrigger__c = TRUE;
            insert setting3;
            
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;

            
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            
            Account accObj = TestDataFactory.getAccount();
            insert accObj;
            Account accObj1 = TestDataFactory.getAccount();
            accObj1.Name = 'RUBRIK_ACC_NAME';
            insert accObj1;
            Account rbkAcc = new Account(Name='Rubrik');
            insert rbkAcc;

            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => accObj1.Id
                    };
                        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;

            Opportunity oppr = TestDataFactory.getOpportunity(accObj);
            oppr.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
            insert oppr;
            
            Id standardPriceBookId =  Test.getStandardPricebookId();
            
            PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
            insert pb1;
            
            Product2 prod1 = new Product2(
                Name = 'RBK-GO-BE-R6408',
                ProductCode = 'RBK-GO-BE-R6408',
                isActive = true,
                SBQQ__SubscriptionTerm__c = 1
                //Product_Type__c = 'HW Support'
            );
            Product2 prod2 = new Product2(
                Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
                ProductCode = 'RBK-SVC-PREM-R304',
                isActive = true,
                SBQQ__SubscriptionTerm__c = 1,
                Product_Type__c = 'HW Support'
            );
            Product2 prod3 = new Product2(
                Name = 'RH-6408SE-02',
                ProductCode = 'RH-6408SE-02',
                Category__c = 'Hardware',
                Product_Subtype__c = 'GO',
                SBQQ__AssetConversion__c = 'None',
                SBQQSC__EntitlementConversion__c = 'One per unit',
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable',
                IsActive = true,
                Asset_Priority__c = 1,
                New_CPQ_Product__c = true,
                Product_Level__c = 'Hardware'
            );
            insert new List<Product2>{prod1, prod2, prod3};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1,pbStanEntry2,pbStanEntry3,pbEntry1,pbEntry2,pbEntry3};
        
        Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        qt1.MetricsLastCalcOn__c = System.today()+1;
        //qt1.LastModifiedDate = System.today()+2;
        update qt1;
        
        quoteId.add(qt1.Id);

         Order ord = new Order();
        ord.PoNumber = '12345';
        ord.ShippingPostalCode = '123455';
        ord.PO_Number__c = '123455';
        ord.Overage_PO__c = 'test';
        ord.Shipping_Address_Label__c = 'test';
        ord.ShippingCity = 'test';
        ord.ShippingCountry = 'Aland Islands';
        ord.ShippingCountryCode = 'AX';
        ord.Status = 'Draft';
        ord.accountId = accObj1.Id;
        ord.EffectiveDate = Date.today();
        insert ord;
        
        Map<String, Object> prdMap = new Map<String, Object> {
                    'Name' => 'HW',
                        'ProductCode' => 'RS-BT-EE-PE-PP',
                        'IsActive' => true,
                        'SBQQ__AssetConversion__c' => 'One per unit',
                        'SBQQ__SubscriptionType__c' => 'Renewable'
                        // 'SBQQ__RenewalProduct__c' => ''
                        };
                            
                            Map<String, Object> prdMap1 = new Map<String, Object> {
                                'Name' => 'HW',
                                    'ProductCode' => 'RH-6304S-01',
                                    'IsActive' => true, 
                                    'SBQQ__SubscriptionPricing__c' => null, 
                                    'SBQQ__SubscriptionTerm__c' => null, 
                                    'SBQQ__SubscriptionType__c' => 'Renewable' 
                                    //    'SBQQ__RenewalProduct__c' => null
                                    //          'SBQQ__RenewalProduct__c' => product2.SBQQ__RenewalProduct__r.
                                    }; 
                                        
                                        Map<String, Object> prdMap2 = new Map<String, Object> {
                                            'Name' => 'HWSupport',
                                                'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                'IsActive' => true, 
                                                'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                                'SBQQ__SubscriptionTerm__c' => 12,
                                                'SBQQ__SubscriptionType__c' => 'Renewable'
                                                //    'SBQQ__RenewalProduct__c' => null
                                                };
                                                    Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            
        Product2 prdSubsub = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prdSubsub);
        insert prdList;

        Asset newAsset1 = new Asset(Name = 'AA165203480078', SerialNumber = 'AA165203480078',
                                    Product2Id = prod3.Id, AccountId = accObj1.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset1;
        Asset newAsset2 = new Asset(Name = 'AA165203480079', SerialNumber = 'AA165203480079', 
                                    Product2Id = prdSubs.Id, AccountId = accObj1.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset2;
        Asset newAsset3 = new Asset(Name = 'AA165203480080', SerialNumber = 'AA165203480080',
                                    Product2Id = prdSubsub.Id, AccountId = accObj1.Id, ContactId = cnt.Id,
                                    SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset3;
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.AccountId = accObj.Id;
        serviceContractObj.StartDate = Date.Today().addmonths(-30);
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.SBQQSC__RenewalOpportunity__c = oppr.Id;
        serviceContractObj.EndDate = System.today().addDays(360);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        serviceContractObj.Renew_to_Old_SKUs__c = true;
        lstServiceContract.add(serviceContractObj);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        renewServiceContractObj.SBQQSC__Quote__c = qt1.Id;
        renewServiceContractObj.EndDate = System.today().addDays(360);
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = Date.Today().addmonths(-29);
        ContractLineItemObj.EndDate = Date.Today().addmonths(6);
        ContractLineItemObj.SBQQSC__RenewalQuantity__c = 1;
        ContractLineItemObj.SBQQSC__RootId__c = lstServiceContract[0].Id;
        
        insert ContractLineItemObj;
        
        ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj2.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj2.PricebookEntryId = pbStanEntry3.Id;
        ContractLineItemObj2.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj2.Quantity = 10;
        ContractLineItemObj2.UnitPrice = 100;
        ContractLineItemObj2.StartDate = Date.Today().addmonths(-29);
        ContractLineItemObj2.EndDate = Date.Today().addmonths(6);
        ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 1;
        ContractLineItemObj2.SBQQSC__RootId__c = lstServiceContract[0].Id;
        
        insert ContractLineItemObj2;
        
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj1.PricebookEntryId = pbEntry1.Id;
        ContractLineItemObj1.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.EndDate = Date.Today().addmonths(6);
                 
        Entitlement enttitlementNewObj5 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.AccountId = accObj1.Id;
        enttitlementNewObj5.StartDate = Date.today().addDays(-365);
        enttitlementNewObj5.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj5.Renewable__c = true;
        enttitlementNewObj5.Type = 'CS Admin';
        enttitlementNewObj5.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj5.Product__c = prod3.Id;
        enttitlementNewObj5.Renewal_Category__c = 'Renewed';
        enttitlementNewObj5.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj5.ServiceContractId = lstServiceContract[0].Id;  
        enttitlementNewObj5.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();
        insert enttitlementNewObj5; 
            
            
            Entitlement enttitlementNewObj9 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            enttitlementNewObj9.AssetId = newAsset1.Id;
            enttitlementNewObj9.AccountId = accObj1.Id;
            enttitlementNewObj9.StartDate = Date.today().addDays(-365);
            enttitlementNewObj9.EndDate = Date.today().addDays(+900);
            // enttitlementNewObj5.AssetId = newAsset1.Id;
            enttitlementNewObj9.ContractLineItemId = ContractLineItemObj.Id;
            enttitlementNewObj9.Renewable__c = true;
            enttitlementNewObj9.Type = 'CS Admin';
            enttitlementNewObj9.Name = 'EntitlementTriggerHelper';
            enttitlementNewObj9.Product__c = prdHW.Id;
            enttitlementNewObj9.Renewal_Category__c = 'Renew later';
            enttitlementNewObj9.Refreshed_Opportunity_Link__c = oppr.Id;
            enttitlementNewObj9.ServiceContractId = lstServiceContract[0].Id;
            enttitlementNewObj9.RecordTypeId = Schema.getGlobalDescribe().get('Entitlement').getDescribe().getRecordTypeInfosByDeveloperName().get('CS_Admin').getRecordTypeId();
            insert enttitlementNewObj9; 
        
        Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj6.AccountId = accObj1.Id;
        enttitlementNewObj6.StartDate = Date.today().addDays(-365);
        enttitlementNewObj6.EndDate = Date.today().addDays(+900);
        enttitlementNewObj6.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlementNewObj6.Renewable__c = true;
        enttitlementNewObj6.Type = 'CS Admin';
        enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj6.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj6.ServiceContractId = lstServiceContract[1].Id;
        enttitlementNewObj6.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();

        insert enttitlementNewObj6; 
        
        Test.startTest();
        String qIdStr = customRenewal.renewalCustomContract(lstServiceContract, oppr.Id);
        String fieldStr1 = customRenewal.allFields('Account');
        Test.stopTest();
        List<SBQQ__QuoteLine__c> listQLI = [SELECT ID FROM SBQQ__QuoteLine__c];
        System.Assert(enttitlementNewObj6.Id != null);
        }
    }
    /***********************************************************************************************************
    * Method Name          : testMethodserviceContractBatchCloneRenewalTerm
    * @description         : test method for code coverage
    /**********************************************************************************************************/
    static testMethod void testMethodserviceContractBatchCloneRenewalTerm(){
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u1 = new User(Alias = 'standt', Email='Shivani.Rathi@rubrik.com.invalid', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p1.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardusertestSC@testorg.com');
       
        List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
        ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Disable_SBQQ_Quote_Triggers__c = false
        );
        insert setting;

        ShGl_DisableBusinessLogic__c currentUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = UserInfo.getUserId(), 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true //FY25SR-2247
        );
        disableBusinessLogic.add(currentUserDB);
        // INSERT new ShGl_DisableBusinessLogic__c();

        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        //Deactivate triggers
        ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
        );
        disableBusinessLogic.add(runAsUserDB);
        insert disableBusinessLogic;
        System.runAs(usr1) {
            SBQQ.TriggerControl.disable();
            TriggerControl__c setting1 = new TriggerControl__c();
            setting1.Name = 'Opportunity';
            setting1.DisableTrigger__c = TRUE;
            insert setting1;
            TriggerControl__c setting2 = new TriggerControl__c();
            setting2.Name = 'Renewal Case';
            setting2.DisableTrigger__c = FALSE;
            insert setting2;
            TriggerControl__c setting3 = new TriggerControl__c();
            setting3.Name = 'Entitlement';
            setting3.DisableTrigger__c = TRUE;
            insert setting3;
            
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            
            Account accObj = TestDataFactory.getAccount();
            insert accObj;
            Account accObj1 = TestDataFactory.getAccount();
            accObj1.Name = 'RUBRIK_ACC_NAME';
            insert accObj1;
            Account rbkAcc = new Account(Name='Rubrik');
            insert rbkAcc;

            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => accObj1.Id
                    };
                        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;

            Opportunity oppr = TestDataFactory.getOpportunity(accObj);
            oppr.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
            oppr.Contract_Renewal_Term__c = null;
            insert oppr;
            
            Id standardPriceBookId =  Test.getStandardPricebookId();
            
            PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
            insert pb1;
            
            Product2 prod1 = new Product2(
                Name = 'RBK-GO-BE-R6408',
                ProductCode = 'RBK-GO-BE-R6408',
                isActive = true,
                SBQQ__SubscriptionTerm__c = 1
                //Product_Type__c = 'HW Support'
            );
            Product2 prod2 = new Product2(
                Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
                ProductCode = 'RBK-SVC-PREM-R304',
                isActive = true,
                SBQQ__SubscriptionTerm__c = 1,
                Product_Type__c = 'HW Support'
            );
            Product2 prod3 = new Product2(
                Name = 'RH-6408SE-02',
                ProductCode = 'RH-6408SE-02',
                Category__c = 'Hardware',
                Product_Subtype__c = 'GO',
                SBQQ__AssetConversion__c = 'None',
                SBQQSC__EntitlementConversion__c = 'One per unit',
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__SubscriptionBase__c = 'List',
                SBQQ__SubscriptionType__c = 'Renewable',
                IsActive = true,
                Asset_Priority__c = 1,
                New_CPQ_Product__c = true,
                Product_Level__c = 'Hardware'
            );
            insert new List<Product2>{prod1, prod2, prod3};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1,pbStanEntry2,pbStanEntry3,pbEntry1,pbEntry2,pbEntry3};
        
        Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        qt1.MetricsLastCalcOn__c = System.today()+1;
        //qt1.LastModifiedDate = System.today()+2;
        update qt1;
        
        quoteId.add(qt1.Id);

         Order ord = new Order();
        ord.PoNumber = '12345';
        ord.ShippingPostalCode = '123455';
        ord.PO_Number__c = '123455';
        ord.Overage_PO__c = 'test';
        ord.Shipping_Address_Label__c = 'test';
        ord.ShippingCity = 'test';
        ord.ShippingCountry = 'Aland Islands';
        ord.ShippingCountryCode = 'AX';
        ord.Status = 'Draft';
        ord.accountId = accObj1.Id;
        ord.EffectiveDate = Date.today();
        insert ord;
        
        Map<String, Object> prdMap = new Map<String, Object> {
                    'Name' => 'HW',
                        'ProductCode' => 'RS-BT-EE-PE-PP',
                        'IsActive' => true,
                        'SBQQ__AssetConversion__c' => 'One per unit',
                        'SBQQ__SubscriptionType__c' => 'Renewable'
                        // 'SBQQ__RenewalProduct__c' => ''
                        };
                            
                            Map<String, Object> prdMap1 = new Map<String, Object> {
                                'Name' => 'HW',
                                    'ProductCode' => 'RH-6304S-01',
                                    'IsActive' => true, 
                                    'SBQQ__SubscriptionPricing__c' => null, 
                                    'SBQQ__SubscriptionTerm__c' => null, 
                                    'SBQQ__SubscriptionType__c' => 'Renewable' 
                                    //    'SBQQ__RenewalProduct__c' => null
                                    //          'SBQQ__RenewalProduct__c' => product2.SBQQ__RenewalProduct__r.
                                    }; 
                                        
                                        Map<String, Object> prdMap2 = new Map<String, Object> {
                                            'Name' => 'HWSupport',
                                                'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                'IsActive' => true, 
                                                'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                                'SBQQ__SubscriptionTerm__c' => 12,
                                                'SBQQ__SubscriptionType__c' => 'Renewable'
                                                //    'SBQQ__RenewalProduct__c' => null
                                                };
                                                    Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            
        Product2 prdSubsub = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prdSubsub);
        insert prdList;

        Asset newAsset1 = new Asset(Name = 'AA165203480078', SerialNumber = 'AA165203480078',
                                    Product2Id = prod3.Id, AccountId = accObj1.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset1;
        Asset newAsset2 = new Asset(Name = 'AA165203480079', SerialNumber = 'AA165203480079', 
                                    Product2Id = prdSubs.Id, AccountId = accObj1.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset2;
        Asset newAsset3 = new Asset(Name = 'AA165203480080', SerialNumber = 'AA165203480080',
                                    Product2Id = prdSubsub.Id, AccountId = accObj1.Id, ContactId = cnt.Id,
                                    SBQQ__CombineKey__c = 'AA165203480078');
        insert newAsset3;
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.AccountId = accObj.Id;
        serviceContractObj.StartDate = Date.Today().addmonths(-30);
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.SBQQSC__RenewalOpportunity__c = oppr.Id;
        serviceContractObj.EndDate = System.today().addDays(360);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        serviceContractObj.Renew_to_Old_SKUs__c = true;
        lstServiceContract.add(serviceContractObj);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        renewServiceContractObj.SBQQSC__Quote__c = qt1.Id;
        renewServiceContractObj.EndDate = System.today().addDays(360);
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = Date.Today().addmonths(-29);
        ContractLineItemObj.EndDate = Date.Today().addmonths(6);
        ContractLineItemObj.SBQQSC__RenewalQuantity__c = 1;
        ContractLineItemObj.SBQQSC__RootId__c = lstServiceContract[0].Id;
        
        insert ContractLineItemObj;
        
        ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj2.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj2.PricebookEntryId = pbStanEntry3.Id;
        ContractLineItemObj2.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj2.Quantity = 10;
        ContractLineItemObj2.UnitPrice = 100;
        ContractLineItemObj2.StartDate = Date.Today().addmonths(-29);
        ContractLineItemObj2.EndDate = Date.Today().addmonths(6);
        ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 1;
        ContractLineItemObj2.SBQQSC__RootId__c = lstServiceContract[0].Id;
        
        insert ContractLineItemObj2;
        
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj1.PricebookEntryId = pbEntry1.Id;
        ContractLineItemObj1.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.EndDate = Date.Today().addmonths(6);
                 
        Entitlement enttitlementNewObj5 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.AccountId = accObj1.Id;
        enttitlementNewObj5.StartDate = Date.today().addDays(-365);
        enttitlementNewObj5.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj5.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj5.Renewable__c = true;
        enttitlementNewObj5.Type = 'CS Admin';
        enttitlementNewObj5.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj5.Product__c = prod3.Id;
        enttitlementNewObj5.Renewal_Category__c = 'Renewed';
        enttitlementNewObj5.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj5.ServiceContractId = lstServiceContract[0].Id;  
        enttitlementNewObj5.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();
        insert enttitlementNewObj5; 
            
            
        Entitlement enttitlementNewObj9 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj9.AssetId = newAsset1.Id;
        enttitlementNewObj9.AccountId = accObj1.Id;
        enttitlementNewObj9.StartDate = Date.today().addDays(-365);
        enttitlementNewObj9.EndDate = Date.today().addDays(+900);
        // enttitlementNewObj5.AssetId = newAsset1.Id;
        enttitlementNewObj9.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj9.Renewable__c = true;
        enttitlementNewObj9.Type = 'CS Admin';
        enttitlementNewObj9.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj9.Product__c = prdHW.Id;
        enttitlementNewObj9.Renewal_Category__c = 'Renew later';
        enttitlementNewObj9.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj9.ServiceContractId = lstServiceContract[0].Id;
        enttitlementNewObj9.RecordTypeId = Schema.getGlobalDescribe().get('Entitlement').getDescribe().getRecordTypeInfosByDeveloperName().get('CS_Admin').getRecordTypeId();
        insert enttitlementNewObj9; 
        
        Entitlement enttitlementNewObj6 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj6.AccountId = accObj1.Id;
        enttitlementNewObj6.StartDate = Date.today().addDays(-365);
        enttitlementNewObj6.EndDate = Date.today().addDays(+900);
        enttitlementNewObj6.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlementNewObj6.Renewable__c = true;
        enttitlementNewObj6.Type = 'CS Admin';
        enttitlementNewObj6.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj6.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj6.ServiceContractId = lstServiceContract[1].Id;
        enttitlementNewObj6.RecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Manufacturing Entitlement').getRecordTypeId();

        insert enttitlementNewObj6; 
        system.assert(enttitlementNewObj6.Id != null);
        Test.startTest();
        String qIdStr = customRenewal.renewalCustomContract(lstServiceContract, oppr.Id);
        String fieldStr1 = customRenewal.allFields('Account');
        Test.stopTest();
        List<SBQQ__QuoteLine__c> listQLI = [SELECT ID FROM SBQQ__QuoteLine__c];
        System.Assert(enttitlementNewObj6.Id != null);
        }
    }
    /***********************************************************************************************************
    * Method Name          : testCustomRenewalContractNew
    * @description         : test method for code coverage
    /**********************************************************************************************************/
    static testMethod void  testCustomRenewalContractNew() {
    List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
    User usr1 = Replacement_TestDataFactory.getUser();
            usr1.RBAC_Department__c = 'Service Account';
            usr1.RBAC_Group__c = 'System - IT';
            insert usr1;
            //Deactivate triggers
            ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
                setupownerid = usr1.Id, 
                Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
                Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
                Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
                Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
                Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
                Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
            );
            disableBusinessLogic.add(runAsUserDB);
            insert disableBusinessLogic;
            
            System.runAs(usr1) {
                List<ServiceContract> sC = new List<ServiceContract>();
                //Generate the Account
                Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        
                Opportunity opp = TestDataFactory.getOpportunity(act);
    
            
                
                TriggerControl__c custsetting = new TriggerControl__c();
                custsetting.Name = 'Entitlement';
                custsetting.DisableTrigger__c = true;
                insert custsetting;
                
                insert act; 
                List<Account> accList = new List<Account>();
                accList.add(act);
                Assert.areEqual(1, accList.size());
            
            
                //Generate the Contact
                Map<String, Object> cntMap = new Map<String, Object> {
                    'AccountId' => act.Id
                        };
                            Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
                insert cnt;
                
                Id pbId = Test.getStandardPriceBookId();  
                
                
                opp.SBQQ__QuotePricebookId__c =pbId;     
                insert opp;
                
                Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => act.Id,'SBQQ__Opportunity2__c' => opp.Id};
                    Map<String, Object> prdMap = new Map<String, Object> {
                        'Name' => 'HW',
                            'ProductCode' => 'RS-BT-EE-PE-PP',
                            'IsActive' => true,
                            'SBQQ__AssetConversion__c' => 'One per unit',
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            // 'SBQQ__RenewalProduct__c' => ''
                            };
                                
                                Map<String, Object> prdMap1 = new Map<String, Object> {
                                    'Name' => 'HW',
                                        'ProductCode' => 'RH-6304S-01',
                                        'IsActive' => true, 
                                        'SBQQ__SubscriptionPricing__c' => null, 
                                        'SBQQ__SubscriptionTerm__c' => null, 
                                        'SBQQ__SubscriptionType__c' => 'Renewable' 
                                        //    'SBQQ__RenewalProduct__c' => null
                                        //          'SBQQ__RenewalProduct__c' => product2.SBQQ__RenewalProduct__r.
                                        }; 
                                            
                                            Map<String, Object> prdMap2 = new Map<String, Object> {
                                                'Name' => 'HWSupport',
                                                    'ProductCode' => 'RS-HW-SVC-PE-S1',
                                                    'IsActive' => true, 
                                                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                                    'SBQQ__SubscriptionTerm__c' => 12,
                                                    'SBQQ__SubscriptionType__c' => 'Renewable'
                                                    //    'SBQQ__RenewalProduct__c' => null
                                                    };
                                                        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
                
                Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
                
                Product2 prdSubsub = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
                
                List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
                prdList.add(prdHW);
                prdList.add(prdSubs);
                prdList.add(prdSubsub);
                insert prdList;
                
                List<PricebookEntry> pBList = new List<PricebookEntry> ();
                
                PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
                pbeHW.Product2Id = prdHW.Id;
                pBList.add(pbeHW); 
                
                PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
                pbeSubs.Product2Id = prdSubs.Id;
                pBList.add(pbeSubs);
                
                PricebookEntry pbeSubsub = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
                pbeSubsub.Product2Id = prdSubsub.Id;
                pBList.add(pbeSubsub);
                insert pBList;
                
                SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
                qt.SBQQ__Opportunity2__c = opp.Id;
                qt.SBQQ__Primary__c = true;
                qt.SBQQ__PriceBook__c = pbId;
                qt.ApprovalStatus__c = 'Approved';
                qt.SBQQ__Type__c = 'Renewal+Expansion';
                qt.SBQQ__StartDate__c = Date.today();
                qt.Manual_Billing__c = false;
                qt.Consolidate_Lines__c = false;
                insert qt;
            
                List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
                SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard');  
                SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli1.id, SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard' ); 
                SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubsub.Id, SBQQ__RequiredBy__c = qli2.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, required_by_ext_Id__c =qli2.id,SubscribedAssetNames__c = 'BB192863040046',Storage_Region_Bundle__c = 'Standard' ); 
                qliList.add( qli1 );
                TriggerControls.disableQuoteLineTrigger = true;
                qliList.add( qli2 );
                TriggerControls.disableQuoteLineTrigger = false;
                qliList.add( qli3 );
                insert qliList;
                
                Order ord = new Order();
                ord.PoNumber = '12345';
                ord.ShippingPostalCode = '123455';
                ord.PO_Number__c = '123455';
                ord.Overage_PO__c = 'test';
                ord.Shipping_Address_Label__c = 'test';
                ord.ShippingCity = 'test';
                ord.ShippingCountry = 'Aland Islands';
                ord.ShippingCountryCode = 'AX';
                ord.Status = 'Draft';
                ord.accountId = act.Id;
                ord.EffectiveDate = Date.today();
                insert ord;
                Asset newAsset1 = new Asset(Name = 'AA165203480078', SerialNumber = 'AA165203480078', Product2Id = prdHW.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
                insert newAsset1;
                Asset newAsset2 = new Asset(Name = 'AA165203480079', SerialNumber = 'AA165203480079', Product2Id = prdSubs.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
                insert newAsset2;
                Asset newAsset3 = new Asset(Name = 'AA165203480080', SerialNumber = 'AA165203480080', Product2Id = prdSubsub.Id, AccountId = act.Id, ContactId = cnt.Id,SBQQ__CombineKey__c = 'AA165203480078');
                insert newAsset3;
                
                ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                        PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150,SBQQSC__Quote__c = qt.id);
                ServiceContract serviceContractObj1 = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = opp.Id,AccountId = act.Id,StartDate = System.today(),
                                                                        PriceBook2Id = pbId,Term = 36, EndDate = System.today() + 150,SBQQSC__Quote__c = qt.id);
                
                sc.add(serviceContractObj);
                sc.add(serviceContractObj1);
                insert sc;
                
                
                ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
                ContractLineItemObj.SBQQSC__Account__c = act.Id;
                ContractLineItemObj.PricebookEntryId = pbeHW.Id;
                ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
                ContractLineItemObj.Quantity = 10;
                ContractLineItemObj.AssetId = newAsset1.Id;
                ContractLineItemObj.UnitPrice = 100;
                ContractLineItemObj.SBQQSC__SubscriptionPricing__c='Fixed Price';
                ContractLineItemObj.SBQQSC__Product__c = prdHW.Id;
                ContractLineItemObj.Licensing_Model__c = 'Subscription';
                ContractLineItemObj.StartDate = System.today();
                ContractLineItemObj.EndDate =System.today() + 150;
                ContractLineItemObj.SBQQSC__RootId__c = newAsset1.Id;
                ContractLineItemObj.SBQQSC__ProductSubscriptionType__c='Renewable';
                ContractLineItemObj.SBQQSC__SubscriptionType__c = 'Renewable';
                ContractLineItemObj.SBQQSC__RenewalQuantity__c = 20;
                
                ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
                ContractLineItemObj1.SBQQSC__Account__c = act.Id;
                ContractLineItemObj1.PricebookEntryId = pbeSubs.Id;
                ContractLineItemObj1.ServiceContractId = serviceContractObj1.Id;
                ContractLineItemObj1.AssetId = newAsset2.Id;
                ContractLineItemObj1.Quantity = 10;
                ContractLineItemObj1.UnitPrice = 100;
                ContractLineItemObj1.SBQQSC__SubscriptionPricing__c='Fixed Price';
                ContractLineItemObj1.Licensing_Model__c = 'Subscription';
                ContractLineItemObj1.StartDate = System.today();
                ContractLineItemObj1.SBQQSC__RootId__c = newAsset2.Id;
                ContractLineItemObj1.EndDate =System.today() + 150;
                ContractLineItemObj1.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
                ContractLineItemObj1.SBQQSC__RenewalQuantity__c = 20;
                
                ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
                ContractLineItemObj2.SBQQSC__Account__c = act.Id;
                ContractLineItemObj2.PricebookEntryId = pbeSubsub.Id;
                ContractLineItemObj2.ServiceContractId = serviceContractObj.Id;
                ContractLineItemObj2.AssetId = newAsset3.iD;
                ContractLineItemObj2.SBQQSC__RootId__c = newAsset2.Id;
                ContractLineItemObj2.Quantity = 10;
                ContractLineItemObj2.UnitPrice = 100;
                ContractLineItemObj2.SBQQSC__SubscriptionPricing__c='Fixed Price';
                ContractLineItemObj2.SBQQSC__Product__c = prdSubsub.Id;
                ContractLineItemObj2.Licensing_Model__c = 'Subscription';
                ContractLineItemObj2.StartDate = System.today();
                //  ContractLineItemObj2.Subscription_Term__c = 12; 
                ContractLineItemObj2.EndDate =System.today() + 150;
                ContractLineItemObj2.SBQQSC__ProductSubscriptionType__c='Renewable/Evergreen';
                //   ContractLineItemObj2.SBQQSC__SubscriptionType__c = 'Renewable';
                ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 20;
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                SBQQ.TriggerControl.disable();
                insert ContractLineItemObj;
                newAsset1.SBQQSC__RequiredByLineItem__c = ContractLineItemObj.Id;
                insert ContractLineItemObj1;
                system.assert(ContractLineItemObj1.Id != null);
                insert ContractLineItemObj2;
                newAsset2.SBQQSC__RequiredByLineItem__c = ContractLineItemObj1.Id;
                newAsset3.SBQQSC__RequiredByLineItem__c = ContractLineItemObj2.Id;
                update newAsset1;
                update newAsset2;
                update newAsset3;
                Test.StartTest();
                customRenewal.renewalCustomContract(sC,opp.Id);
                Test.StopTest();
            }
    }
}