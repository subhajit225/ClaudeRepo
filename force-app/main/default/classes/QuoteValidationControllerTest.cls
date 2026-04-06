/** @description 
* -------------------------- @History------------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* FY26WL-353         Asif Hussain          5-Dec-2025      Test for QuoteValidationController
* --------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class QuoteValidationControllerTest {
     /**
	* Name : initialDataSetup
	* Date : 1-Dec-2025
	* @description : TestSetUp method
	*/
    @TestSetUp
    public static void initialDataSetup() {
        
        List<OpportunitySplitMapping__c> oppSplitMappingList = new List<OpportunitySplitMapping__c> ();
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Name', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'StageName', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'CloseDate', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Risk_Identified__c', Default_Value__c='false'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Meeting_evidence_link__c', Default_Value__c='false'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Push_Counter__c', Default_Value__c='1'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'NextStep', From_Field__c='Order_Sub_Type__c'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'NextStep', Suffix__c='Split_percentage__c'));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'ETM_Theatre__c', Skip_Update_if_child_has_value__c=true));
        insert oppSplitMappingList;
        
        insert new Opportunity_Stage_Days__c(AllowAcvCalculation__c = true, AllowArrCalculation__c = true);
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Trigger_Max_Loop_Count__c = 10;
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        settingDisable.Disable_Account_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable.Disable_Account_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
        insert settingDisable;
        
        upsert disableFuncCS;
        
        Account objAccount = new Account();
        Contact objContact = new Contact();
        Contact objContact1 = new Contact();
        Account objAccount1 = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 31-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;
        objAccount1.Name = 'Test Account 01-06';
        objAccount1.RecordTypeId = recordTypeId;
        insert objAccount1;
        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 31-05';
        insert objContact; 
        
        objContact1.LastName = 'Test Contact 01-06';
        objContact1.Account = objAccount1;
        insert objContact1; 
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '2 Consensus';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 31-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        insert objOpportunity;
        
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = objOpportunity.Id;
        ocr.Role = 'Click-Thru Contact';
        ocr.ContactId = objContact1.id;
        insert ocr; 
    }
    
     /*
	* Name : testCompareEntitlementAllWithNewPrimaryQuote
	* Date : 1-Dec-2025
	* @description : Test method to cover compareEntitlementAllWithNewPrimaryQuote
	*/
    @isTest
    static void testCompareEntitlementAllWithNewPrimaryQuote() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id pbookId = Test.getStandardPricebookId();
            Map<String, Object> prdMap1 = new Map<String, Object> {
                'Name' => 'LOD',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
            };
            Map<String, Object> prdMap2 = new Map<String, Object> {
                'Name' => 'Subscription', 
                    'IsActive' => true, 
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
            Map<String, Object> prdMap3 = new Map<String, Object> {
                //'Name' => 'Hardware',
                'Name' => 'RBK-PS-RES',
                    'IsActive' => true,
                    'SBQQ__AssetConversion__c' => 'One per unit',
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
                Map<String, Object> prdMap4 = new Map<String, Object> {
                    'Name' => 'SW Support', 
                        'IsActive' => true, 
                        'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                        'SBQQ__SubscriptionTerm__c' => 12, 
                        'SBQQ__SubscriptionType__c' => 'Renewable'
                        };
                Map<String, Object> prdMap5 = new Map<String, Object> {
                    'Name' => 'Subscription Add-On', 
                        'IsActive' => true, 
                        'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                        'SBQQ__SubscriptionTerm__c' => 12, 
                        'SBQQ__SubscriptionType__c' => 'Renewable'
                        };
                                                                        
            Product2 prdLOD = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            prdLOD.License_Type__c = 'Perpetual';
            prdLOD.Product_Subtype__c = 'E1000';
            Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
            prdSubs.License_Type__c = 'Subscription';
            prdSubs.License_Subtype__c = 'ELA';
            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap3);
            prdHW.Product_Type__c = 'HW Support';
            Product2 prdSubsAddon = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap4);
            prdSubsAddon.License_Type__c = 'Subscription';
            prdSubsAddon.License_Subtype__c = 'Add-On';
            Product2 prdSW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap5);
            prdHW.Product_Type__c = 'RCDM Support';
            Product2 prdPl = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap5);
            prdPl.Product_Type__c = 'RCDM Support';
            prdPl.Product_Level__c='LOD Software';
            prdPl.Bundle_Features__c='Cloud Native Protection';
            List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap1);
            prdList.add(prdLOD);
            prdList.add(prdSubs);
            prdList.add(prdHW);
            prdList.add(prdSubsAddon);
            prdList.add(prdSW);
            prdList.add(prdPl);
            insert prdList;
            
            List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            PricebookEntry pbeLOD = new PricebookEntry();
            pbeLOD.Pricebook2Id = pbookId;
            pbeLOD.Product2Id = prdLOD.Id;
            pbeLOD.UnitPrice = 1000;
            pbeLOD.IsActive = true;
            pBList.add(pbeLOD);
            
            PricebookEntry pbeSubs = new PricebookEntry();
            pbeSubs.Pricebook2Id = pbookId;
            pbeSubs.UnitPrice = 1000;
            pbeSubs.Product2Id = prdSubs.Id;
            pbeSubs.IsActive = true;
            pBList.add(pbeSubs);
            
            PricebookEntry pbeHW = new PricebookEntry();
            pbeHW.Pricebook2Id = pbookId;
            pbeHW.UnitPrice = 1000;
            pbeHW.Product2Id = prdHW.Id;
            pbeHW.IsActive = true;
            pBList.add(pbeHW);
            
            PricebookEntry pbeSubsAddon = new PricebookEntry();
            pbeSubsAddon.Pricebook2Id = pbookId;
            pbeSubsAddon.UnitPrice = 1000;
            pbeSubsAddon.Product2Id = prdSubsAddon.Id;
            pbeSubsAddon.IsActive = true;
            pBList.add(pbeSubsAddon);
            
            PricebookEntry pbeSW = new PricebookEntry();
            pbeSW.Pricebook2Id = pbookId;
            pbeSW.UnitPrice = 1000;
            pbeSW.Product2Id = prdSW.Id;
            pbeSW.IsActive = true;
            pBList.add(pbeSW);
            
            PricebookEntry pbePl = new PricebookEntry();
            pbePl.Pricebook2Id = pbookId;
            pbePl.UnitPrice = 1000;
            pbePl.Product2Id = prdPl.Id;
            pbePl.IsActive = true;
            pBList.add(pbePl);
            insert pBList;
            
            Account accObj = TestDataFactory.getAccount();
            insert accObj;
            
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert vAccount;
            
            Opportunity oppr2 = TestDataFactory.getOpportunity(accObj);
            oppr2.Marketplace__c = 'Azure Marketplace';
            oppr2.Distributor_Lookup__c = vAccount.Id; 
            oppr2.Partner_Lookup__c = vAccount.Id; 
            insert oppr2;
            
            Opportunity oppr1 = TestDataFactory.getOpportunity(accObj);
            oppr1.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();     
            insert oppr1;
            
            
            ServiceContract serviceContractObj1 = new ServiceContract();
            serviceContractObj1.Name = 'EntitlementTriggerHelper Contract';
            serviceContractObj1.SBQQSC__Opportunity__c = oppr1.Id;
            serviceContractObj1.AccountId = accObj.Id;
            serviceContractObj1.StartDate = System.today();
            serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj1.Term = 36;
            insert serviceContractObj1;  
            
            ServiceContract serviceContractObj2 = new ServiceContract();
            serviceContractObj2.Name = 'EntitlementTriggerHelper Contract';
            serviceContractObj2.SBQQSC__Opportunity__c = oppr1.Id;
            serviceContractObj2.AccountId = accObj.Id;
            serviceContractObj2.StartDate = System.today();
            serviceContractObj2.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj2.Term = 36;
            insert serviceContractObj2;  
            
            Test.startTest();
            List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
            quoteList = TestDataFactory.getQuotes(new Set<Id>{oppr1.Id}, 2);
            quoteList[0].SBQQ__Primary__c = true;
            quoteList[0].SBQQ__Opportunity2__c = oppr1.Id;
            insert quoteList;
            
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
            qliList.add( qli1 );
            SBQQ__QuoteLine__c secondQuoteqli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[1].Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040041' );           
            qliList.add( secondQuoteqli1 );            
            insert qliList;
            List<ContractLineItem>clineList = new List<ContractLineItem>();
            ContractLineItem renewedContractLineItem1 = new ContractLineItem();
            renewedContractLineItem1.SBQQSC__Account__c = accObj.Id;
            renewedContractLineItem1.PricebookEntryId = pbeLOD.Id;
            renewedContractLineItem1.ServiceContractId = serviceContractObj1.Id;
            renewedContractLineItem1.SBQQSC__QuoteLine__c = qliList[0].Id;
            renewedContractLineItem1.Quantity = 10;
            renewedContractLineItem1.UnitPrice = 100;
            clineList.add(renewedContractLineItem1);
            
             ContractLineItem renewedContractLineItem2 = new ContractLineItem();
            renewedContractLineItem2.SBQQSC__Account__c = accObj.Id;
            renewedContractLineItem2.PricebookEntryId = pbeLOD.Id;
            renewedContractLineItem2.ServiceContractId = serviceContractObj2.Id;
            renewedContractLineItem2.SBQQSC__QuoteLine__c = qliList[1].Id;
            renewedContractLineItem2.Quantity = 10;
            renewedContractLineItem2.UnitPrice = 100;
            clineList.add(renewedContractLineItem2);
            insert clineList;
            
            qliList = new List<SBQQ__QuoteLine__c> ();
            
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id, Replacement_Details__c ='{"targetProductType":"Hardware","skuStorageTierVal":null,"skuSelectedName":null,"skuSelected":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":null,"selectedAssetList":{"02i6f00000IXXMQAA5":"AA220564080172"},"selectedAsset":"02i6f00000IXXMQAA5","rowId":"0.0.0","isMismatch":null,"isAutoDisposition":null,"inactiveLines":null,"entId":"5506f000004hJKbAAM","disposition":"Renewing"}],"renLine":true,"refreshCategoryId":null,"mode":"Dispose","lodToSaas":null,"dynamicFieldValues":null}' ); 
            SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
            SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSubsAddon.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
            SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
            
            qliList.add( qli2 );
            qliList.add( qli3 );
            qliList.add( qli4 );
            qliList.add( qli5 );
            SBQQ__QuoteLine__c secondQuoteqli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[1].Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = secondQuoteqli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040041',SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id, Replacement_Details__c ='{"targetProductType":"Hardware","skuStorageTierVal":null,"skuSelectedName":null,"skuSelected":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":null,"selectedAssetList":{"02i6f00000IXXMQAA5":"AA220564080172"},"selectedAsset":"02i6f00000IXXMQAA5","rowId":"0.0.0","isMismatch":null,"isAutoDisposition":null,"inactiveLines":null,"entId":"5506f000004hJKbPAM","disposition":"Renewing"}],"renLine":true,"refreshCategoryId":null,"mode":"Dispose","lodToSaas":null,"dynamicFieldValues":null}' ); 
            qliList.add( secondQuoteqli2 );
        
            insert qliList;
            try{
               quoteList[1].SBQQ__Primary__c = true;       
               update quoteList[1];
            }catch(Exception ex){
               System.debug(System.logginglevel.ERROR,'Error:'+ex.getMessage());
            }
            System.assertEquals( quoteList[1].SBQQ__Primary__c, true, 'Non Primary');
            Test.stopTest();
           
        }      
    }
    
     /*
	* Name : testCompareEntitlementAllWithNewPrimaryQuoteWithDuplicate
	* Date : 1-Dec-2025
	* @description : Test method to cover compareEntitlementAllWithNewPrimaryQuote
	*/
    @isTest
    static void testCompareEntitlementAllWithNewPrimaryQuoteWithDuplicate() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id pbookId = Test.getStandardPricebookId();
            Map<String, Object> prdMap1 = new Map<String, Object> {
                'Name' => 'LOD',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
            };
            Map<String, Object> prdMap2 = new Map<String, Object> {
                'Name' => 'Subscription', 
                    'IsActive' => true, 
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
            Map<String, Object> prdMap3 = new Map<String, Object> {
                //'Name' => 'Hardware',
                'Name' => 'RBK-PS-RES',
                    'IsActive' => true,
                    'SBQQ__AssetConversion__c' => 'One per unit',
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
                Map<String, Object> prdMap4 = new Map<String, Object> {
                    'Name' => 'SW Support', 
                        'IsActive' => true, 
                        'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                        'SBQQ__SubscriptionTerm__c' => 12, 
                        'SBQQ__SubscriptionType__c' => 'Renewable'
                        };
                Map<String, Object> prdMap5 = new Map<String, Object> {
                    'Name' => 'Subscription Add-On', 
                        'IsActive' => true, 
                        'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                        'SBQQ__SubscriptionTerm__c' => 12, 
                        'SBQQ__SubscriptionType__c' => 'Renewable'
                        };
                                                                        
            Product2 prdLOD = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            prdLOD.License_Type__c = 'Perpetual';
            prdLOD.Product_Subtype__c = 'E1000';
            Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap2);
            prdSubs.License_Type__c = 'Subscription';
            prdSubs.License_Subtype__c = 'ELA';
            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap3);
            prdHW.Product_Type__c = 'HW Support';
            Product2 prdSubsAddon = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap4);
            prdSubsAddon.License_Type__c = 'Subscription';
            prdSubsAddon.License_Subtype__c = 'Add-On';
            Product2 prdSW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap5);
            prdHW.Product_Type__c = 'RCDM Support';
            Product2 prdPl = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap5);
            prdPl.Product_Type__c = 'RCDM Support';
            prdPl.Product_Level__c='LOD Software';
            prdPl.Bundle_Features__c='Cloud Native Protection';
            List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap1);
            prdList.add(prdLOD);
            prdList.add(prdSubs);
            prdList.add(prdHW);
            prdList.add(prdSubsAddon);
            prdList.add(prdSW);
            prdList.add(prdPl);
            insert prdList;
            
            List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            PricebookEntry pbeLOD = new PricebookEntry();
            pbeLOD.Pricebook2Id = pbookId;
            pbeLOD.Product2Id = prdLOD.Id;
            pbeLOD.UnitPrice = 1000;
            pbeLOD.IsActive = true;
            pBList.add(pbeLOD);
            
            PricebookEntry pbeSubs = new PricebookEntry();
            pbeSubs.Pricebook2Id = pbookId;
            pbeSubs.UnitPrice = 1000;
            pbeSubs.Product2Id = prdSubs.Id;
            pbeSubs.IsActive = true;
            pBList.add(pbeSubs);
            
            PricebookEntry pbeHW = new PricebookEntry();
            pbeHW.Pricebook2Id = pbookId;
            pbeHW.UnitPrice = 1000;
            pbeHW.Product2Id = prdHW.Id;
            pbeHW.IsActive = true;
            pBList.add(pbeHW);
            
            PricebookEntry pbeSubsAddon = new PricebookEntry();
            pbeSubsAddon.Pricebook2Id = pbookId;
            pbeSubsAddon.UnitPrice = 1000;
            pbeSubsAddon.Product2Id = prdSubsAddon.Id;
            pbeSubsAddon.IsActive = true;
            pBList.add(pbeSubsAddon);
            
            PricebookEntry pbeSW = new PricebookEntry();
            pbeSW.Pricebook2Id = pbookId;
            pbeSW.UnitPrice = 1000;
            pbeSW.Product2Id = prdSW.Id;
            pbeSW.IsActive = true;
            pBList.add(pbeSW);
            
            PricebookEntry pbePl = new PricebookEntry();
            pbePl.Pricebook2Id = pbookId;
            pbePl.UnitPrice = 1000;
            pbePl.Product2Id = prdPl.Id;
            pbePl.IsActive = true;
            pBList.add(pbePl);
            insert pBList;
            
            Account accObj = TestDataFactory.getAccount();
            insert accObj;
            
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert vAccount;                       
            
            Opportunity oppr1 = TestDataFactory.getOpportunity(accObj);
            oppr1.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();     
            insert oppr1;
            
            
            ServiceContract serviceContractObj1 = new ServiceContract();
            serviceContractObj1.Name = 'EntitlementTriggerHelper Contract';
            serviceContractObj1.SBQQSC__Opportunity__c = oppr1.Id;
            serviceContractObj1.AccountId = accObj.Id;
            serviceContractObj1.StartDate = System.today();
            serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj1.Term = 36;
            insert serviceContractObj1;  
            
            ServiceContract serviceContractObj2 = new ServiceContract();
            serviceContractObj2.Name = 'EntitlementTriggerHelper Contract';
            serviceContractObj2.SBQQSC__Opportunity__c = oppr1.Id;
            serviceContractObj2.AccountId = accObj.Id;
            serviceContractObj2.StartDate = System.today();
            serviceContractObj2.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj2.Term = 36;
            insert serviceContractObj2;  
            
            
            List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
            quoteList = TestDataFactory.getQuotes(new Set<Id>{oppr1.Id}, 2);
            quoteList[0].SBQQ__Primary__c = true;
            quoteList[0].SBQQ__Opportunity2__c = oppr1.Id;
            insert quoteList;
            
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
            qliList.add( qli1 );
            SBQQ__QuoteLine__c secondQuoteqli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[1].Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040041' );           
            qliList.add( secondQuoteqli1 );            
            insert qliList;
            List<ContractLineItem>clineList = new List<ContractLineItem>();
            ContractLineItem renewedContractLineItem1 = new ContractLineItem();
            renewedContractLineItem1.SBQQSC__Account__c = accObj.Id;
            renewedContractLineItem1.PricebookEntryId = pbeLOD.Id;
            renewedContractLineItem1.ServiceContractId = serviceContractObj1.Id;
            renewedContractLineItem1.SBQQSC__QuoteLine__c = qliList[0].Id;
            renewedContractLineItem1.Quantity = 10;
            renewedContractLineItem1.UnitPrice = 100;
            clineList.add(renewedContractLineItem1);
            
             ContractLineItem renewedContractLineItem2 = new ContractLineItem();
            renewedContractLineItem2.SBQQSC__Account__c = accObj.Id;
            renewedContractLineItem2.PricebookEntryId = pbeLOD.Id;
            renewedContractLineItem2.ServiceContractId = serviceContractObj2.Id;
            renewedContractLineItem2.SBQQSC__QuoteLine__c = qliList[1].Id;
            renewedContractLineItem2.Quantity = 10;
            renewedContractLineItem2.UnitPrice = 100;
            clineList.add(renewedContractLineItem2);
            insert clineList;
            
            qliList = new List<SBQQ__QuoteLine__c> ();
            
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id, Replacement_Details__c ='{"targetProductType":"Hardware","skuStorageTierVal":null,"skuSelectedName":null,"skuSelected":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":null,"selectedAssetList":{"02i6f00000IXXMQAA5":"AA220564080172"},"selectedAsset":"02i6f00000IXXMQAA5","rowId":"0.0.0","isMismatch":null,"isAutoDisposition":null,"inactiveLines":null,"entId":"5506f000004hJKbAAP","disposition":"Renewing"}],"renLine":true,"refreshCategoryId":null,"mode":"Dispose","lodToSaas":null,"dynamicFieldValues":null}' ); 
            SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
            SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSubsAddon.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
            SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = prdSW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
            
            qliList.add( qli2 );
            qliList.add( qli3 );
            qliList.add( qli4 );
            qliList.add( qli5 );
            SBQQ__QuoteLine__c secondQuoteqli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList[1].Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = secondQuoteqli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040041',SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id, Replacement_Details__c ='{"targetProductType":"Hardware","skuStorageTierVal":null,"skuSelectedName":null,"skuSelected":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":null,"selectedAssetList":{"02i6f00000IXXMQAA5":"AA220564080172"},"selectedAsset":"02i6f00000IXXMQAA5","rowId":"0.0.0","isMismatch":null,"isAutoDisposition":null,"inactiveLines":null,"entId":"5506f000004hJKbPAM","disposition":"Renewing"}],"renLine":true,"refreshCategoryId":null,"mode":"Dispose","lodToSaas":null,"dynamicFieldValues":null}' ); 
            qliList.add( secondQuoteqli2 );
        
            insert qliList;
            Test.startTest();
            //--------------------------------------------------------
            Opportunity oppr2 = TestDataFactory.getOpportunity(accObj);
            oppr2.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();              
            insert oppr2;
            
             serviceContractObj2 = new ServiceContract();
            serviceContractObj2.Name = 'EntitlementTriggerHelper Contract';
            serviceContractObj2.SBQQSC__Opportunity__c = oppr2.Id;
            serviceContractObj2.AccountId = accObj.Id;
            serviceContractObj2.StartDate = System.today();
            serviceContractObj2.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj2.Term = 36;
            insert serviceContractObj2;               
            
            List<SBQQ__Quote__c> quoteList2 = new List<SBQQ__Quote__c>();
            quoteList2 = TestDataFactory.getQuotes(new Set<Id>{oppr2.Id}, 1);
            quoteList2[0].SBQQ__Primary__c = true;
            quoteList2[0].SBQQ__Opportunity2__c = oppr2.Id;
            insert quoteList2;
                    
             SBQQ__QuoteLine__c qli12 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList2[0].Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );         
            insert qli12;
            
             renewedContractLineItem2 = new ContractLineItem();
            renewedContractLineItem2.SBQQSC__Account__c = accObj.Id;
            renewedContractLineItem2.PricebookEntryId = pbeLOD.Id;
            renewedContractLineItem2.ServiceContractId = serviceContractObj2.Id;
            renewedContractLineItem2.SBQQSC__QuoteLine__c = qli12.Id;
            renewedContractLineItem2.Quantity = 10;
            renewedContractLineItem2.UnitPrice = 100;
            insert renewedContractLineItem2;
            
             SBQQ__QuoteLine__c qli21 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList2[0].Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli12.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',SBQQSC__RenewedContractLine__c = renewedContractLineItem2.Id, Replacement_Details__c ='{"targetProductType":"Hardware","skuStorageTierVal":null,"skuSelectedName":null,"skuSelected":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":null,"selectedAssetList":{"02i6f00000IXXMQAA5":"AA220564080172"},"selectedAsset":"02i6f00000IXXMQAA5","rowId":"0.0.0","isMismatch":null,"isAutoDisposition":null,"inactiveLines":null,"entId":"5506f000004hJKbAAM","disposition":"Renewing"}],"renLine":true,"refreshCategoryId":null,"mode":"Dispose","lodToSaas":null,"dynamicFieldValues":null}' );
            insert qli21;
           // Test.startTest();
             oppr1 = TestDataFactory.getOpportunity(accObj);
            oppr1.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();     
            insert oppr1;
            
             serviceContractObj1 = new ServiceContract();
            serviceContractObj1.Name = 'EntitlementTriggerHelper Contract';
            serviceContractObj1.SBQQSC__Opportunity__c = oppr1.Id;
            serviceContractObj1.AccountId = accObj.Id;
            serviceContractObj1.StartDate = System.today();
            serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj1.Term = 36;
            insert serviceContractObj1;
            
        
             List<SBQQ__Quote__c> quoteList21 = new List<SBQQ__Quote__c>();
            quoteList21 = TestDataFactory.getQuotes(new Set<Id>{oppr1.Id}, 1);
            quoteList21[0].SBQQ__Primary__c = true;
            quoteList21[0].SBQQ__Opportunity2__c = oppr1.Id;
            insert quoteList21;
            
             qliList = new List<SBQQ__QuoteLine__c> ();
             qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList21[0].Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
            qliList.add( qli1 );
            insert qliList;
            
             renewedContractLineItem1 = new ContractLineItem();
            renewedContractLineItem1.SBQQSC__Account__c = accObj.Id;
            renewedContractLineItem1.PricebookEntryId = pbeLOD.Id;
            renewedContractLineItem1.ServiceContractId = serviceContractObj1.Id;
            renewedContractLineItem1.SBQQSC__QuoteLine__c = qliList[0].Id;
            renewedContractLineItem1.Quantity = 10;
            renewedContractLineItem1.UnitPrice = 100;
            insert renewedContractLineItem1;
            
            qliList = new List<SBQQ__QuoteLine__c> ();
            
             qli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList21[0].Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',SBQQSC__RenewedContractLine__c = renewedContractLineItem1.Id, Replacement_Details__c ='{"targetProductType":"Hardware","skuStorageTierVal":null,"skuSelectedName":null,"skuSelected":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":null,"selectedAssetList":{"02i6f00000IXXMQAA5":"AA220564080172"},"selectedAsset":"02i6f00000IXXMQAA5","rowId":"0.0.0","isMismatch":null,"isAutoDisposition":null,"inactiveLines":null,"entId":"5506f000004hJKbAAM","disposition":"Renewing"}],"renLine":true,"refreshCategoryId":null,"mode":"Dispose","lodToSaas":null,"dynamicFieldValues":null}' ); 
             qli3 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList21[0].Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
             qli4 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList21[0].Id, SBQQ__Product__c = prdSubsAddon.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
             qli5 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = quoteList21[0].Id, SBQQ__Product__c = prdSW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
            
            qliList.add( qli2 );
            qliList.add( qli3 );
            qliList.add( qli4 );
            qliList.add( qli5 );
            
        
            insert qliList;
            
            
            
            try{
               
                oppr1.SBQQ__PrimaryQuote__c = quoteList21[0].Id;
                oppr1.Renewals_Forecast_Risk__c ='Invalid Duplicate';
                oppr1.Duplicate_Opportunity_Lookup__c = oppr2.Id;            
                update oppr1;
               quoteList[1].SBQQ__Primary__c = true;       
               update quoteList[1];
            }catch(Exception ex){
               System.debug(System.logginglevel.ERROR,'Error:'+ex.getMessage());
            }
            System.assertEquals( quoteList[1].SBQQ__Primary__c, true, 'Non Primary');
            Test.stopTest();
           
        }      
    }
}