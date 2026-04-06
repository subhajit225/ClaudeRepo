/*
* Class Name :- CPQ_CSATUtility
* Author :- Rubrik Dev
* Created Date :- July 5th , 2023
* Description : CPQ22-3109 :- Test Class for CPQ_CSATUtility
// ********************Mofification Log *****************************************************************************
* 
* Modified By          Date             Description (Include Jira Details)
* 
*           
*  
// ********************Modification Log *****************************************************************************
*/
@isTest
public class CPQ_CSATUtilityTest {
    
    static testMethod void  testCSATRenewal() {
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Entitlement';
       custsetting.DisableTrigger__c = true;
       insert custsetting;
        
        //Disable trigger
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Campaign_Member_Triggers__c = true,
                                                                            Disable_Campaign_Trigger__c = true,
                                                                            Disable_Campaign_Validation_Rules__c = true,
                                                                            Disable_Order_Validation_Rules__c=true, 
                                                                            Disable_ServiceContract_Trigger__c=true,
                                                                            Disable_Entitlement_Usage_Trigger__c=true,
                                                                            Disable_Entitlement_Trigger__c=true,
                                                                            Disable_Asset_Triggers__c=true);    
        insert cdf;
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
        
        system.debug('Renewable product print '+prdHW.SBQQ__RenewalProduct__c );
        system.debug('Renewable product print '+prdSubs.SBQQ__RenewalProduct__c );
        system.debug('Renewable product print '+prdSubsub.SBQQ__RenewalProduct__c );
        
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
        ord.Status = 'Activated';
        ord.accountId = act.Id;
        ord.EffectiveDate = Date.today();
        insert ord;
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

/*

        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = act.Id;
        ContractLineItemObj.PricebookEntryId = pbeHW.Id;
        ContractLineItemObj.ServiceContractId = sc[0].Id;
        ContractLineItemObj.Quantity = 10;
        //ContractLineItemObj.AssetId = newAsset1.Id;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.SBQQSC__SubscriptionPricing__c='Fixed Price';
        ContractLineItemObj.SBQQSC__Product__c = prdHW.Id;
        ContractLineItemObj.Licensing_Model__c = 'Subscription';
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate =System.today() + 150;
        //ContractLineItemObj.SBQQSC__RootId__c = newAsset1.Id;
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
        
        system.debug('Act '+ act );
        system.debug('sc[0].Id.  '=sc[0].Id);
        system.debug('Opp '+ opp);
        system.debug('Contact '+ cnt);
        system.debug('Asset 1'+ newAsset1);
        system.debug('Asset 2'+ newAsset2);
        system.debug('Sc '+ serviceContractObj);
        system.debug('CL 1 '+ ContractLineItemObj);
        system.debug('CL 1 '+ qt);
        system.debug('QL 1 '+ qli1);
        system.debug('QL 2 '+ qli2);*/
        
        Test.startTest(); 
        sc[0].CSAT_Quoted__c = true;
        update sC[0];
        CPQ_CSATUtility.RenewServiceContractForCSAT(new Set<ID>{serviceContractObj.ID},null);
        CPQ_CSATUtility.updateRenewalQuoteLines(new Set<ID>{serviceContractObj.ID});
        Test.stopTest();                                       
    }
    
    
    
}