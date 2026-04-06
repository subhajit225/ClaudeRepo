/* Class Name:- QuoteRollupBatch_Test
* Author: Shubham Bansal
* Description: Test Class for QuoteRollupBatch and RbobAcvInflightUpdate Classes.
* CreatedDate: 08/01/2026
*/
@isTest
public class QuoteRollupBatch_Test {
    @isTest
    static void testMethod1() {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Entitlement_Validation_Rules__c=true);
        insert cdf;
        system.assert(cdf.Id != null);
        TriggerControl__c TC = new TriggerControl__c();
        TC.Name = 'Entitlement';
        TC.DisableTrigger__c = true;
        TC.DisableTrigger__c = true;
        TC.Last_Batch_Run_Date__c = Date.newInstance(2021,04,30);
        TC.SendEmail__c = false;
        insert TC;
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = true;
        
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Contact';
        setting2.DisableTrigger__c = true;
        TriggerControl__c setting3 = new TriggerControl__c();
        setting3.Name = 'OrderItemExtension';
        setting3.DisableTrigger__c = true;
        setting3.Disable_Trigger__c = true;
        TriggerControl__c setting4 = new TriggerControl__c();
        setting4.Name = 'Order';
        setting4.Disable_Trigger__c = true;
        setting4.DisableTrigger__c = true;
        
        insert new List<TriggerControl__c>{setting1, setting2,setting3,setting4};
            User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        System.runAs(usr1) {
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            system.assert(act.Id != null);
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            accountList.add(vAccount);
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            
            Account vAccount2 = new Account();
            vAccount2.Name = 'Test Account';
            vAccount2.recordTypeId = vAccount.recordTypeId;
            accountList.add(vAccount2);
            insert accountList;
            Assert.areEqual(2, accountList.size());
            
            Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
            opp.AccountId = act.Id;
            opp.CloseDate = Date.newInstance(2021,04,30);
            opp.Partner_Lookup__c = vAccount2.id;
            opp.Opportunity_Type__c = 'New Customer';
            opp.Opportunity_Sub_Type__c = 'Regular';
            opp.Distributor_Lookup__c = vAccount.id;
            opp.Pricebook2Id  = Test.getStandardPricebookId();
            insert opp;

            Map<String, Object> prdMap1 = new Map<String, Object> {
                'Name' => 'Subscription', 
                    'IsActive' => true, 
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable'
                    };
                        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
            insert prdSubs;
            
            Product2 prdHW = new Product2(Name='Pord-GO-B',ProductCode='Product-GO-123XYZ',isActive=true,Eligible_For_Trade_Up__c=true, Product_Type__c = 'Hardware', Product_Level__c = 'Hardware', Eligible_HW_for_Expansion__c = 'R6416S,R6416SE', Usable_Capacity__c = 12,Appliance_Model_HW__c='R6416S',Trade_Up_HW_Value__c=10 );
            prdHW.IsActive = true;
            insert prdHW;
            
            Product2 prdLic = new Product2(Name='Pord-GO-B',ProductCode='Product-GO-123XZ',isActive=true, Product_Level__c = 'Hybrid Software', Category__c = 'Bundle', Trade_Up_Multiplier__c = 1.00,Eligible_For_Trade_Up__c=true,Tradeup_Pattern__c = 'License');
            prdLic.IsActive = true;
            insert prdLic;
            
            List<PricebookEntry> pBList = new List<PricebookEntry> ();
            
            Id stdPbId = Test.getStandardPricebookId();
            
            PricebookEntry pbeHW = new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = prdHW.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            );
            
            PricebookEntry pbeLic = new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = prdLic.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            );
            
            PricebookEntry pbeSubs = new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = prdSubs.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            );
            pBList.add(pbeSubs);
            pBList.add(pbeHW);
            pBList.add(pbeLic);
            
            insert pBList;
            
            Assert.areEqual(3, pBList.size());   
            Asset asst = new Asset(
                Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prdHW.Id,
                Accountid =act.Id, Rubrik_Suite__c = 'Business', Free_HW_Refresh_Forfeited__c = false, Eligible_for_Free_HW__c = 'True'
            );
            Asset asst2 = new Asset(
                Name= 'XYX', SerialNumber= 'XYX',Serial_Number__c= 'XYX',Product2ID=prdHW.Id,
                Accountid =act.Id, Rubrik_Suite__c = 'Business', Free_HW_Refresh_Forfeited__c = false, Eligible_for_Free_HW__c = 'True'
            );
            insert new List<Asset>{asst,asst2};
 
            List<ServiceContract> contractList = new List<ServiceContract>();
            ServiceContract serviceContractObj = new ServiceContract();
            serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdateTests';
            serviceContractObj.SBQQSC__Opportunity__c = opp.Id;
            serviceContractObj.StartDate = System.today();
            serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj.Term = 36;
            serviceContractObj.EndDate = System.today().addDays(365);
            serviceContractObj.SBQQSC__RenewalForecast__c = false;
            serviceContractObj.SBQQSC__RenewalTerm__c = 12;
            
            
            contractList.add(serviceContractObj);
            insert contractList;
            Assert.areEqual(1, contractList.size());        
            List<contractLineItem> cliList = new List<contractLineItem>(); 
            ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj.SBQQSC__Account__c = vAccount2.Id;
            ContractLineItemObj.PricebookEntryId = pbeHW.Id;
            ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj.Quantity = 10;
            ContractLineItemObj.UnitPrice = 100;
            ContractLineItemObj.StartDate = System.today();
            ContractLineItemObj.EndDate = System.today().addDays(120);
            cliList.add(ContractLineItemObj);
            
            ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
            ContractLineItemObj1.SBQQSC__Account__c = vAccount2.Id;
            ContractLineItemObj1.PricebookEntryId = pbeHW.Id;
            ContractLineItemObj1.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj1.Quantity = 10;
            ContractLineItemObj1.UnitPrice = 100;
            ContractLineItemObj1.StartDate = System.today();
            ContractLineItemObj1.EndDate = System.today().addDays(120);
            cliList.add(ContractLineItemObj1);
            
            insert cliList;
            Assert.areEqual(2, cliList.size());
            
            Test.starttest();
            Entitlement ent = new Entitlement(Name='Testing', 
                                              AccountId=act.Id,
                                              AssetId = asst.Id,
                                              ServiceContractId = serviceContractObj.id,
                                              ContractLineItemId = ContractLineItemObj.id,
                                              Product__c =prdHW.id,
                                              Quantity__c = 5,
                                              Entitlement_ACV__c =100,
                                              Entitlement_RAMP_EXIT_ACV__c=200,
                                              StartDate = Date.today(),
                                              EndDate = Date.today().addDays(365));
            insert ent;
            
            Entitlement ent1 = new Entitlement(Name='Testing', 
                                               AccountId=act.Id,
                                               AssetId = asst2.Id,
                                               Entitlement_ACV__c=12,
                                               ServiceContractId = serviceContractObj.id,
                                               ContractLineItemId = ContractLineItemObj1.id,
                                               Entitlement_RAMP_EXIT_ACV__c=250,
                                               Quantity__c = 6,
                                               Product__c =prdHW.id,
                                               StartDate = Date.today(),
                                               EndDate = Date.today().addDays(365));
            insert ent1;
            
            String replacementDetails1 = '{"rowValues":[{"entId":"'+ent.Id+'"}]}';
            String replacementDetails = JSON.serialize(
                new Map<String, Object>{
                    'rowValues' => new List<Object>{
                        new Map<String, Object>{
                            'entId' => ent1.Id
                                },
                                    new Map<String, Object>{
                                        'selectedQty' => 300
                                            },
                                                new Map<String, Object>{
                                                    'upgradeLines' => new List<Object>{
                                                        new Map<String, Object>{
                                                            'childEntId' => ent1.Id 
                                                                },
                                                                    new Map<String, Object>{
                                                                        'childEntId' => ent.Id 
                                                                            }
                                                    }
                                                }
                    }
                }
            );
            String replacementDetails2 = '{"targetProductType" : "Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"upgradeLines":[{"childrowId":null,"childQnty":270,"childEntId":"'+ent.Id+'"}],"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","inactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"entId":"'+ent1.Id+'","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
            List<SBQQ__Quote__c>lstQuote = new List<SBQQ__Quote__c>();
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qt.SBQQ__Account__c = act.Id;
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__SubscriptionTerm__c = 12;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__Type__c = 'Renewal';
            qt.RecordTypeId=Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
            qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
            lstQuote.add(qt);
            
            
            insert qt;
            system.assert(qt.Id != null);
            
            List<SBQQ__QuoteLine__c> quotelineList = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(Replacement_Details__c=replacementDetails,Replacement_Motion__c='Upgrade',SBQQ__Quote__c = qt.Id,Max_Prorate_Multiplier__c=12,Category__c = 'Bundle',Expected_Trade_Up_Discount__c=10,Trade_Up_Discount__c = 10,SBQQ__NetPrice__c =20, SBQQ__Product__c = prdLic.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12,Trade_Up_Serial_Number__c='XYX' );  
            quotelineList.add(qli2);
            SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(Replacement_Details__c=replacementDetails2,Replacement_Motion__c='Arroyo Dispose',SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',Max_Prorate_Multiplier__c=12,SBQQ__RequiredBy__c=qli2.Id,Expected_Trade_Up_Discount__c=10,SBQQ__NetPrice__c =20,Trade_Up_Discount__c = 10, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12 );  
            quotelineList.add(qli1);
            
            SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(Replacement_Motion__c='Upgrade',SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',Max_Prorate_Multiplier__c=12,Expected_Trade_Up_Discount__c=10,Trade_Up_Discount__c = 10, SBQQ__NetPrice__c =20,SBQQ__Product__c = prdLic.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12,Trade_Up_Serial_Number__c='XYX', Trade_Up_Serial_Number_on_HW__c = 'XYX' );  
            quotelineList.add(qli3);
            insert quotelineList;
            
            RbobAcvInflightUpdate batch = new RbobAcvInflightUpdate(new List<id>{qt.Id});
            Database.executeBatch(batch);
            RbobAcvInflightUpdate batch2 = new RbobAcvInflightUpdate();
            Database.executeBatch(batch2);
            RbobAcvInflightUpdate batch3 = new RbobAcvInflightUpdate(true, false);
            Database.executeBatch(batch3);
            RbobAcvInflightUpdate batch4 = new RbobAcvInflightUpdate(true, true);
            Database.executeBatch(batch4);
            RbobAcvInflightUpdate batch5 = new RbobAcvInflightUpdate(true, 'Approved');
            Database.executeBatch(batch5);
            RbobAcvInflightUpdate batch6 = new RbobAcvInflightUpdate(Date.valueof('2021-01-01'), Date.valueof('2029-12-31'), true, false);
            Database.executeBatch(batch6);
            RbobAcvInflightUpdate batch7 = new RbobAcvInflightUpdate(Date.valueof('2021-01-01'), Date.valueof('2029-12-31'), true, true);
            Database.executeBatch(batch7);
            RbobAcvInflightUpdate batch8 = new RbobAcvInflightUpdate(true); //Custom Label - RbobInflightBatchWhere
            Database.executeBatch(batch8);
            Test.stoptest();
        }
    }
    
}