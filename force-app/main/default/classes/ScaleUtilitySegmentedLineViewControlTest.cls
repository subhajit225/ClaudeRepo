/**
* Class Name :- ScaleUtilitySegmentedLineViewControlTest
* Author :- Rubrik Dev
* @description : This test class is used to test the ScaleUtilitySegmentedLineViewController.
*/
@isTest
public class ScaleUtilitySegmentedLineViewControlTest {
    
    @TestSetup
    static void setupData() {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,

                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Entitlement_Validation_Rules__c=true);
        insert cdf;
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        //Deactivate triggers

        System.runAs(usr1) {
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account acct = new Account(Name='testAccount', RecordTypeId = partnerRecordTypeId, Account_Deal_Desk_Notes__c = 'Test Notes');
            Account acc = new Account(Name='testAccount1');
            insert new List<Account>{acct, acc};
                
                Opportunity oppr = TestDataFactory.getOpportunity(acct);
            insert oppr;
            
            Id standardPriceBookId =  Test.getStandardPricebookId();
            
            PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
            insert pb1;
            
            //Create your product
            Product2 prod1 = new Product2(
                Name = 'RBK-GO-BE-R6408',
                ProductCode = 'RBK-GO-BE-R6408',
                isActive = true
            );
            Product2 prod2 = new Product2(
                Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
                ProductCode = 'RBK-SVC-PREM-R304',
                isActive = true
            );
            //Create your product
            Product2 prod3 = new Product2(
                Name = 'RBK-GO-BE-R6408',
                ProductCode = 'RBK-GO-BE-R6408',
                isActive = true
            );
            //Create your product
            Product2 prod4 = new Product2(
                Name = 'RBK-RCDM-10-MO-CLON',
                ProductCode = 'RBK-RCDM-AWS-MO',
                Product_Type__c = 'HW Support',
                isActive = true
            );
            
            Product2 prod5 = new Product2(
                Name = 'RS-BE-GO-PE-PP',
                ProductCode = 'RS-BE-GO-PE-PP',
                Product_Type__c = 'Hardware',
                RWD_Version__c = 'Aspen_HW',
                Product_level__c = 'Hardware',
                isActive = true
            );
            
            Product2 prodNew = new Product2(
                Name = 'RS-TB-EE-AR-PE',
                ProductCode = 'RS-TB-EE-AR-PE',
                Product_Type__c = 'Foundation Edition',
                RWD_Version__c = 'v21.0',
                isActive = true
            ); 
            Product2 prodNew1 = new Product2(
                Name = 'RS-TB-EE-SR-PE',
                ProductCode = 'RS-TB-EE-SR-PE',
                Product_Type__c = 'Foundation Edition',
                RWD_Version__c = 'v21.0',
                isActive = true
            ); 
            Product2 prodPrentNew = new Product2(
                Name = 'RS-TB-FE-RSV-PE',
                ProductCode = 'RS-TB-FE-RSV-PE',
                Product_Type__c = 'Foundation Edition',
                RWD_Version__c = 'v21.0',
                isActive = true
            );
            Product2 prodPrentNew1 = new Product2(
                Name = 'RS-TB-FUE-RSV-PE',
                ProductCode = 'RS-TB-FUE-RSV-PE',
                Product_Type__c = 'Foundation Edition',
                RWD_Version__c = 'v21.0',
                isActive = true
            ); 
            insert new List<Product2>{prod1, prod2, prod3, prod4, prod5, prodNew, prodNew1, prodPrentNew, prodPrentNew1};
                
                //Create your pricebook entry
                PricebookEntry pbStanEntry1 = new PricebookEntry(
                    Pricebook2Id = standardPriceBookId,
                    Product2Id = prod1.Id,
                    UnitPrice = 100.00,
                    IsActive = true
                );
            //Create your pricebook entry
            PricebookEntry pbStanEntry2 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod2.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            //Create your pricebook entry
            PricebookEntry pbStanEntry3 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod3.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            //Create your pricebook entry
            PricebookEntry pbStanEntry4 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod4.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            
            PricebookEntry pbStanEntry5 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod5.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            PricebookEntry pbStanEntryNew = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prodNew.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            PricebookEntry pbStanEntryNew1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prodNew1.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            PricebookEntry pbStanEntryParentNew = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prodPrentNew.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            PricebookEntry pbStanEntryParentNew1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prodPrentNew1.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            //Create your pricebook entry
            PricebookEntry pbEntry1 = new PricebookEntry(
                Pricebook2Id = pb1.id,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            //Create your pricebook entry
            PricebookEntry pbEntry2 = new PricebookEntry(
                Pricebook2Id = pb1.id,
                Product2Id = prod2.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            //Create your pricebook entry
            PricebookEntry pbEntry3 = new PricebookEntry(
                Pricebook2Id = pb1.id,
                Product2Id = prod3.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            //Create your pricebook entry
            PricebookEntry pbEntry4 = new PricebookEntry(
                Pricebook2Id = pb1.id,
                Product2Id = prod4.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            
            PricebookEntry pbEntry5 = new PricebookEntry(
                Pricebook2Id = pb1.id,
                Product2Id = prod5.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            PricebookEntry pbEntryNew = new PricebookEntry(
                Pricebook2Id = pb1.id,
                Product2Id = prodNew.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            PricebookEntry pbEntryNew1 = new PricebookEntry(
                Pricebook2Id = pb1.id,
                Product2Id = prodNew1.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            PricebookEntry pbEntryParentNew = new PricebookEntry(
                Pricebook2Id = pb1.id,
                Product2Id = prodPrentNew.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            PricebookEntry pbEntryParentNew1 = new PricebookEntry(
                Pricebook2Id = pb1.id,
                Product2Id = prodPrentNew1.Id,
                UnitPrice = 1000.00,
                IsActive = true
            );
            insert new List<PricebookEntry>{
                pbStanEntry1,
                    pbStanEntry2,
                    pbStanEntry3,
                    pbStanEntry4,
                    pbStanEntry5,
                    pbStanEntryNew,
                    pbStanEntryNew1,
                    pbStanEntryParentNew,
                    pbStanEntryParentNew1,
                    pbEntry1,
                    pbEntry2,
                    pbEntry3,
                    pbEntry4,
                    pbEntry5,
                    pbEntryNew,
                    pbEntryNew1,
                    pbEntryParentNew,
                    pbEntryParentNew1
                    };
                        
                        Map<String, Object>  quoteMap = new Map<String, Object> {
                            'SBQQ__Account__c' => acct.Id,
                                'SBQQ__Opportunity2__c' => oppr.Id
                                };
                                    
                                    SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt1.SBQQ__Opportunity2__c = oppr.Id;
            qt1.SBQQ__Primary__c = false;
            qt1.SBQQ__PriceBook__c = pb1.Id;
            //qt1.ApprovalStatus__c = 'Draft';
            qt1.SBQQ__Type__c = 'Quote';
            qt1.SBQQ__StartDate__c = Date.today();
            qt1.Manual_Billing__c = false;
            qt1.Consolidate_Lines__c = false;
            qt1.SBQQ__SubscriptionTerm__c = 24;
            qt1.Metering__c = 'FETB';
            insert qt1;

            
            SBQQ__QuoteLineGroup__c objQLG = new SBQQ__QuoteLineGroup__c();
            objQLG.Name = 'Quote';
            objQLG.SBQQ__Quote__c = qt1.Id;
            objQLG.SBQQ__SubscriptionTerm__c = 26;
            insert objQLG;
            
            /*********************************/
            Opportunity opprAmend1 = TestDataFactory.getOpportunity(acct);
            insert opprAmend1;
            SBQQ__Quote__c qnew = new SBQQ__Quote__c();
            qnew.SBQQ__Opportunity2__c = opprAmend1.Id;
            qnew.SBQQ__Type__c = 'Amendment';
            qnew.SBQQ__Account__c = acct.Id;
            qnew.SBQQ__StartDate__c = System.today().addDays(10);
            qnew.SBQQ__EndDate__c = System.today().addDays(375);
            qnew.SBQQ__SubscriptionTerm__c = 12;
            qnew.AddOn_Date_Check__c = true;
            insert qnew;
            SBQQ__QuoteLine__c qlNew = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qnew.Id,
                SBQQ__Product__c = prodNew.Id,
                SBQQ__Quantity__c = 10,
                SubscribedAssetNames__c = 'BB192863040046',
                Scale_Utility_Product_Identifier__c = 'OND SR',
                OnDemand_Discount__c = 5.00,
                SBQQ__ListPrice__c = 1000
            );
            insert qlNew;
            
            ServiceContract serviceContractObj = new ServiceContract();
            serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdateTests';
            serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
            serviceContractObj.StartDate = System.today();
            serviceContractObj.PriceBook2Id = standardPriceBookId;
            serviceContractObj.Term = 36;
            serviceContractObj.EndDate = System.today().addDays(365);
            serviceContractObj.SBQQSC__RenewalForecast__c = false;
            serviceContractObj.SBQQSC__RenewalTerm__c = 12;
            insert serviceContractObj;
            
            List<contractLineItem> cliList = new List<contractLineItem>();
            ContractLineItem ContractLineItemObj = new ContractLineItem();
            ContractLineItemObj.SBQQSC__Account__c = acct.Id;
            ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
            ContractLineItemObj.Quantity = 10;
            ContractLineItemObj.UnitPrice = 100;
            ContractLineItemObj.StartDate = System.today();
            ContractLineItemObj.EndDate = System.today().addDays(365);
            ContractLineItemObj.PricebookEntryId = pbStanEntryNew.Id;
            cliList.add(ContractLineItemObj);
            insert cliList;
            
            Opportunity opprAmend = TestDataFactory.getOpportunity(acct);
            insert opprAmend;
            SBQQ__Quote__c qtAmend = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qtAmend.SBQQ__Account__c = acct.Id;
            qtAmend.SBQQ__Opportunity2__c = opprAmend.Id;
            qtAmend.SBQQ__Type__c = 'Amendment';
            qtAmend.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
            qtAmend.SBQQ__StartDate__c = System.today().addDays(10);
            insert qtAmend;
            SBQQ__QuoteLine__c qlAmend = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtAmend.Id, Scale_Utility_Product_RSV_OND__c = 'RSV',SBQQ__PriorQuantity__c = 10, Prior_Net_Total__c = 10, SBQQ__Product__c = prod1.Id, No_of_TBs_Cloud__c = 10,TPH_Quantity__c='5',TPH_OEM__c = 'DELL',TPH_Models_Gen__c = 'C6420',TPH_Drive_Size__c = '120-BETB:75',SBQQ__Discount__c=5,Trade_Up_Discount__c=2,Promo_Disc__c=1,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__SubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__UpgradedContractLine__c = cliList[0].Id, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046' );
            insert qlAmend;
            SBQQ__QuoteLine__c qlAmend1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtAmend.Id, SBQQ__RequiredBy__c = qlAmend.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c = 2, SBQQ__SegmentLabel__c = 'Month 2',Prior_Net_Total__c = 10, SBQQ__Product__c = prod1.Id, No_of_TBs_Cloud__c = 10,TPH_Quantity__c='5',TPH_OEM__c = 'DELL',TPH_Models_Gen__c = 'C6420',TPH_Drive_Size__c = '120-BETB:75',SBQQ__Discount__c=5,Trade_Up_Discount__c=2,Promo_Disc__c=1,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cliList[0].Id, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046' );
            SBQQ__QuoteLine__c qlAmend2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtAmend.Id, SBQQ__RequiredBy__c = qlAmend.Id, Total_Discount__c = 0, Prior_Net_Total__c = 0, SBQQ__Product__c = prodNew.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SegmentLabel__c= 'Month 1', SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__UpgradedContractLine__c = cliList[0].Id, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047');
            SBQQ__QuoteLine__c qlAmend3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtAmend.Id, SBQQ__RequiredBy__c = qlAmend.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =3, SBQQ__SegmentLabel__c = 'Month 3',SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__UpgradedContractLine__c = cliList[0].Id, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040048');
            
            /**********************************/
            Order ordr = new Order(Type='Revenue' ,  AccountId= acct.Id,OpportunityId =oppr.Id,ShippingStreet ='Test Street',
                                   ShippingCity ='Test City',
                                   ShippingState =null,
                                   ShippingCountry ='Austria',
                                   ShippingPostalcode ='94820',
                                   EffectiveDate=system.Today(), Status='Pending',
                                   Pricebook2Id = pb1.Id
                                  );
            insert ordr;
            
            Asset asst = new Asset(
                Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prod3.Id,
                Accountid =acct.Id
            );
            Asset asst3 = new Asset(
                Name= 'Test1234567Asset3', SerialNumber= 'Test1234567Asset3',Serial_Number__c= 'Test1234567Asset3',Product2ID=prod3.Id,
                Accountid =acct.Id
            );
            Asset asst4 = new Asset(
                Name= 'Test1234567Asset4', SerialNumber= 'Test1234567Asset4',Serial_Number__c= 'Test1234567Asset4',Product2ID=prod3.Id,
                Accountid =acct.Id
            );
            Asset asst2 = new Asset(
                Name= 'Test1234567Asset2', SerialNumber= 'Test1234567Asset2',Serial_Number__c= 'Test1234567Asset2',Product2ID=prod3.Id,
                Accountid =acct.Id
            );
            insert new List<Asset>{asst, asst3, asst4, asst2};
                
                oppr.StageName ='6 PO Recieved';
            //update oppr;
            
            //ordr.Ship_To_Name__c = acct.id;
            ordr.ShipToContactName__c = 'sh';
            ordr.Shipping_Method__c ='EXW';
            ordr.Shipping_Carrier__c ='AIT';
            ordr.Service_Level__c ='Same Day';
            ordr.Bill_To_Name__C =acct.id;
            ordr.est_Ship_Date__C =System.Today().addDays(7);
            ordr.Status='Order Accepted' ;
            
            //update ordr;
            //create your opportunity line item.  This assumes you already have an opportunity created, called opp
            OrderItem oli1 = new OrderItem(
                
                OrderId = ordr.Id,
                Quantity = 5,
                PricebookEntryId = pbEntry1.Id,
                UnitPrice = pbEntry1.UnitPrice,
                SerialNumber__c = 'Test1234567Asset2',
                Support_End_Date__c = System.Today().addYears(1),
                Support_Start_Date__c = System.Today()
            );
            //create your opportunity line item.  This assumes you already have an opportunity created, called opp
            OrderItem oli2 = new OrderItem(
                OrderId = ordr.Id,
                Quantity = 5,
                PricebookEntryId = pbEntry2.Id,
                UnitPrice =  pbEntry2.UnitPrice,
                SerialNumber__c = 'Test1234567Asset',
                Support_End_Date__c = System.Today().addYears(1),
                Support_Start_Date__c = System.Today()
            );
            OrderItem oli3 = new OrderItem(
                OrderId = ordr.Id,
                Quantity = 5,
                PricebookEntryId = pbEntry3.Id,
                UnitPrice =  pbEntry3.UnitPrice,
                SerialNumber__c = 'Test1234567Asset',
                Support_End_Date__c = System.Today().addYears(1),
                Support_Start_Date__c = System.Today()
            );
            OrderItem oli4 = new OrderItem(
                OrderId = ordr.Id,
                Quantity = 5,
                PricebookEntryId = pbEntryNew.Id,
                UnitPrice =  pbEntryNew.UnitPrice,
                SerialNumber__c = 'Test1234567AssetAR',
                Support_End_Date__c = System.Today().addYears(1),
                Support_Start_Date__c = System.Today()
            );
            ServiceContract objSC = new ServiceContract(Name = 'ServiceContract Test', AccountId = acct.Id, StartDate = Date.today(),
                                                        Term = 36, pricebook2Id = pb1.Id, SBQQSC__Opportunity__c = oppr.Id, SBQQSC__Order__c= ordr.Id,  SBQQSC__Quote__c = qt1.Id);
            
            insert objSC;
            qt1.Amended_Renewed_Service_Contract__c=objSC.Id;
            update qt1;
            
            List<ContractLineItem> lstCli = new List<ContractLineItem>(); 
            ContractLineItem cli = new ContractLineItem();
            cli.Quantity = 5;
            cli.PricebookEntryId = pbEntry1.Id;
            cli.ServiceContractId= objSC.id;
            cli.UnitPrice=100; 
            cli.StartDate = date.today();
            lstCli.add(cli);
            
            ContractLineItem cli2 = new ContractLineItem();
            cli2.Quantity =5;
            cli2.PricebookEntryId = pbEntry2.Id;
            cli2.ServiceContractId= objSC.id;
            cli2.UnitPrice= 200; 
            cli2.StartDate = date.today();
            lstCli.add(cli2);
            
            ContractLineItem cli3 = new ContractLineItem();
            cli3.Quantity = 5;
            cli3.PricebookEntryId = pbEntry3.Id;
            cli3.ServiceContractId= objSC.id;
            cli3.UnitPrice= 100; 
            cli3.StartDate = date.today();
            lstCli.add(cli3);
            
            ContractLineItem cli4 = new ContractLineItem();
            cli4.Quantity = 5;
            cli4.PricebookEntryId = pbEntryNew.Id;
            cli4.ServiceContractId= objSC.id;
            cli4.UnitPrice= 100; 
            cli4.StartDate = date.today();
            lstCli.add(cli4);
            insert lstCli;
            Test.startTest();
            /************************************/
            List<SBQQ__QuoteLine__c> qtlines = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 10,SBQQ__Product__c = prod1.Id, No_of_TBs_Cloud__c = 10,TPH_Quantity__c='5',TPH_OEM__c = 'DELL',TPH_Models_Gen__c = 'C6420',TPH_Drive_Size__c = '120-BETB:75',SBQQ__Discount__c=5,Trade_Up_Discount__c=2,Promo_Disc__c=1,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__SubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli.Id, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046' );
            insert ql;
            SBQQ__QuoteLine__c qlRSV = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 10, SBQQ__RequiredBy__c = ql.Id, SBQQ__Product__c = prodPrentNew.Id, No_of_TBs_Cloud__c = 10,TPH_Quantity__c='5',TPH_OEM__c = 'DELL',TPH_Models_Gen__c = 'C6420',TPH_Drive_Size__c = '120-BETB:75',SBQQ__Discount__c=5,Trade_Up_Discount__c=2,Promo_Disc__c=1,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli.Id, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046',Scale_Utility_Product_Identifier__c = 'OND SR' );
          qtlines.add(qlRSV);
            SBQQ__QuoteLine__c qlFUE = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 10, SBQQ__RequiredBy__c = ql.Id, SBQQ__Product__c = prodPrentNew1.Id, No_of_TBs_Cloud__c = 10,TPH_Quantity__c='5',TPH_OEM__c = 'DELL',TPH_Models_Gen__c = 'C6420',TPH_Drive_Size__c = '120-BETB:75',SBQQ__Discount__c=5,Trade_Up_Discount__c=2,Promo_Disc__c=1,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli.Id, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', Scale_Utility_Product_Identifier__c = 'OND AR' );
            qtlines.add(qlFUE);
            insert qtlines;
            
            List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c = 2, SBQQ__SegmentLabel__c = 'Month 2',Prior_Net_Total__c = 10, SBQQ__Product__c = prod1.Id, No_of_TBs_Cloud__c = 10,TPH_Quantity__c='5',TPH_OEM__c = 'DELL',TPH_Models_Gen__c = 'C6420',TPH_Drive_Size__c = '120-BETB:75',SBQQ__Discount__c=5,Trade_Up_Discount__c=2,Promo_Disc__c=1,SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli.Id, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', Product_Payment_Option__c = 'Annual' );
            SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, Prior_Net_Total__c = 0, SBQQ__Product__c = prod2.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__Segmentindex__c  =1, SBQQ__SegmentLabel__c= 'Month 1', SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli.Id, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047', Storage_Tier__c = '5 FEGB per user');
            SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =3, SBQQ__SegmentLabel__c = 'Month 3',SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040048');
            
            SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =4, SBQQ__SegmentLabel__c = 'Month 4',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =5, SBQQ__SegmentLabel__c = 'Month 5',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =6, SBQQ__SegmentLabel__c = 'Month 6',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c ql7 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =7, SBQQ__SegmentLabel__c = 'Month 7',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c ql8 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =8, SBQQ__SegmentLabel__c = 'Month 8',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c ql9 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =9, SBQQ__SegmentLabel__c = 'Month 9',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c ql10 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =10, SBQQ__SegmentLabel__c = 'Month 10',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c ql11 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =11, SBQQ__SegmentLabel__c = 'Month 11',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c ql12 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentIndex__c =12, SBQQ__SegmentLabel__c = 'Month 12',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            SBQQ__QuoteLine__c ql13 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentLabel__c = 'Month 13',Scale_Utility_Product__c = true, Scale_Utility_Product_RSV_OND__c='OND',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            SBQQ__QuoteLine__c ql14 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentLabel__c = 'Month 14',Scale_Utility_Product_RSV_OND__c='RSV',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            SBQQ__QuoteLine__c ql15 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentLabel__c = 'Month 15',Product_Type__c = 'HW Support',RWD_Version__c = 'Aspen_HW', Scale_Utility_Product_RSV_OND__c='RSV',SBQQ__Product__c = prod5.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            SBQQ__QuoteLine__c ql16 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, SBQQ__SegmentLabel__c = 'Month 16',Scale_Utility_Product_RSV_OND__c='RSV',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 26, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 222, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            SBQQ__QuoteLine__c ql17 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0, Scale_Utility_Product_Identifier__c='SU FUE',SBQQ__Product__c = prod4.Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 26, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 222, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c ql18 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Total_Discount__c = 0, OnDemand_Discount__c = 5.00, SBQQ__RequiredBy__c = qlFUE.Id, Prior_Net_Total__c = 100, Scale_Utility_Product_Identifier__c = 'OND AR', SBQQ__Product__c = prodNew.Id, SBQQ__Quantity__c = 20,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__SubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200.00, SBQQ__NetPrice__c = 200.00, SBQQSC__RenewedContractLine__c = cli2.Id, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047'); // Req RBK-GO-BE-R6408 -> RS-TB-EE-AR-PE
            SBQQ__QuoteLine__c ql19 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql.Id, Total_Discount__c = 0,Product_Type__c = 'Hardware',Product_level__c ='Hardware',RWD_Version__c = 'Aspen_HW',SBQQ__Product__c = prod5.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049', Subscribed_Asset_Name__c = 'BB192863040049');
             insert ql19;
            SBQQ__QuoteLine__c ql20 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__RequiredBy__c = ql19.Id, Total_Discount__c = 0,Product_Type__c = 'HW Support',SBQQ__Product__c = prod4.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQSC__RenewedContractLine__c = cli2.Id, SubscribedAssetNames__c = 'BB192863040049');
            
            SBQQ__QuoteLine__c qlNew1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Total_Discount__c = 0, OnDemand_Discount__c = 5.00, SBQQ__RequiredBy__c = ql.Id, Prior_Net_Total__c = 100, Scale_Utility_Product_Identifier__c = 'OND AR', SBQQ__Product__c = prodNew.Id, SBQQ__Quantity__c = 20,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__SubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200.00, SBQQ__NetPrice__c = 200.00, SBQQSC__RenewedContractLine__c = cli2.Id, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047');
            SBQQ__QuoteLine__c qlNew2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Total_Discount__c = 0, OnDemand_Discount__c = 5.00, SBQQ__RequiredBy__c = ql.Id, Prior_Net_Total__c = 100, Scale_Utility_Product_Identifier__c = 'OND SR', SBQQ__Product__c = prodNew1.Id, SBQQ__Quantity__c = 20,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__SubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200.00, SBQQ__NetPrice__c = 200.00, SBQQSC__RenewedContractLine__c = cli2.Id, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047');
            SBQQ__QuoteLine__c qlNew3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Total_Discount__c = 0, OnDemand_Discount__c = 5.00, SBQQ__RequiredBy__c = ql.Id, Prior_Net_Total__c = 100, Scale_Utility_Product_Identifier__c = 'SU RSVX', SBQQ__Product__c = prodPrentNew.Id, SBQQ__Quantity__c = 20,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__SubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200.00, SBQQ__NetPrice__c = 200.00, SBQQSC__RenewedContractLine__c = cli2.Id, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047');
            SBQQ__QuoteLine__c qlNew4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Total_Discount__c = 0, OnDemand_Discount__c = 5.00, SBQQ__RequiredBy__c = ql.Id, Prior_Net_Total__c = 100, Scale_Utility_Product_Identifier__c = 'SU FUE', SBQQ__Product__c = prodPrentNew1.Id, SBQQ__Quantity__c = 20,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__SubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200.00, SBQQ__NetPrice__c = 200.00, SBQQSC__RenewedContractLine__c = cli2.Id, SBQQ__StartDate__c =  Date.today(), SubscribedAssetNames__c = 'BB192863040047');

            lines.add(ql1);
            lines.add(ql2);
            lines.add(ql3);
            lines.add(ql4);
            lines.add(ql5);
            lines.add(ql6);
            lines.add(ql7);
            lines.add(ql8);
            lines.add(ql9);
            lines.add(ql10);
            lines.add(ql11);
            lines.add(ql12);
            lines.add(ql13);
            lines.add(ql14);
            lines.add(ql15);
            lines.add(ql16);
            lines.add(ql17);
            lines.add(ql18);
            //lines.add(ql19);
            lines.add(ql20);
            lines.add(qlNew1);
            lines.add(qlNew2);
            lines.add(qlNew3);
            lines.add(qlNew4);
            insert lines;
            Test.stopTest();
        }
    }
    /**
* @description  : This test method is used to test the ScaleUtilitySegmentedLineViewController.
*/
    @isTest
    static void testSUCOntrlMethod(){  
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            
            List<SBQQ__QuoteLine__c> qList =  [SELECT ID, Name, SBQQ__ProductCode__c,SBQQ__Description__c,SBQQ__Quantity__c,
                                               SBQQ__Product__c,SBQQ__ListPrice__c,
                                               SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                                               SBQQ__Quote__r.Total_Commit__c,
                                               SBQQ__Quote__r.Total_Commit_for_SW_DR__c,
                                               SBQQ__Quote__r.SBQQ__NetAmount__c,
                                               CPQ_MSP_Sales_Price__c,
                                               SBQQ__Product__r.Product_Type__c,
                                               SBQQ__NetTotal__c,
                                               SBQQ__RequiredBy__c,
                                               SBQQ__SegmentIndex__c,
                                               SBQQ__SegmentLabel__c,
                                               SBQQ__EffectiveQuantity__c,
                                               Feature_Name__c,
                                               Back_End_Capacity_TB__c,
                                               SBQQ__RequiredBy__r.Back_End_Capacity_TB__c,
                                               SBQQ__RequiredBy__r.SBQQ__Quantity__c,                                                         
                                               SBQQ__Number__c,
                                               Scale_Utility_Product_RSV_OND__c,
                                               Scale_Utility_Product__c,
                                               SBQQ__NetPrice__c,
                                               Payment_Options__c, Quantity_TB__c,
                                               SBQQ__Hidden__c,Usable_Capacity__c,
                                               Product_Payment_Option__c,
                                               SBQQ__Quote__r.SBQQ__Type__c,
                                               SBQQ__RequiredBy__r.SBQQ__Product__r.Name, SBQQ__SubscriptionTerm__c,                                                           
                                               SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c,
                                               Trade_Up_Discount__c,Promo_Disc__c,SBQQ__Discount__c,
                                               SBQQ__Quote__r.Metering__c,No_of_TBs_Cloud__c,Total_Discount__c,
                                               TPH_OEM__c,TPH_Models_Gen__c,
                                               TPH_Quantity__c,TPH_Drive_Size__c, Subscribed_Asset_Name__c,SBQQ__Quote__r.Has_SubscribedAssetNames__c,
                                               SBQQ__RequiredBy__r.Total_Discount__c,SBQQ__AdditionalDiscountAmount__c
                                               FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Type__c != 'Amendment'
                                               limit 100];
            
            Id quoteRecId = qList[0].SBQQ__Quote__c; 
            ScaleUtilitySegmentedLineViewController suVcn = new ScaleUtilitySegmentedLineViewController();
            Test.startTest();
            suVcn.getMDQLines(quoteRecId);
            Test.stopTest();
            System.assertEquals(27, qList.size());
        }
    }
    /**
* @description  : This test method is used to test the ScaleUtilitySegmentedLineViewController.
*/
    @isTest
    static void testSUCOntrlMethod1(){  
        System.runAs(new user(ID = UserInfo.getUserID())){ 
            Test.startTest();
            List<SBQQ__QuoteLine__c> qList1 =  [SELECT ID, Name, SBQQ__ProductCode__c,SBQQ__Description__c,SBQQ__Quantity__c,
                                                SBQQ__Product__c,SBQQ__ListPrice__c,
                                                SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                                                SBQQ__Quote__r.Total_Commit__c,
                                                SBQQ__Quote__r.Total_Commit_for_SW_DR__c,
                                                SBQQ__Quote__r.SBQQ__NetAmount__c,
                                                CPQ_MSP_Sales_Price__c,
                                                SBQQ__Product__r.Product_Type__c,
                                                SBQQ__NetTotal__c,
                                                SBQQ__RequiredBy__c,
                                                SBQQ__SegmentIndex__c,
                                                SBQQ__SegmentLabel__c,
                                                SBQQ__EffectiveQuantity__c,
                                                Feature_Name__c,
                                                Back_End_Capacity_TB__c,
                                                SBQQ__RequiredBy__r.Back_End_Capacity_TB__c,
                                                SBQQ__RequiredBy__r.SBQQ__Quantity__c,
                                                SBQQ__Number__c,
                                                Scale_Utility_Product_RSV_OND__c,
                                                Scale_Utility_Product__c,
                                                SBQQ__NetPrice__c,
                                                Payment_Options__c, Quantity_TB__c,
                                                SBQQ__Hidden__c,Usable_Capacity__c,
                                                Product_Payment_Option__c,
                                                SBQQ__RequiredBy__r.SBQQ__Product__r.Name, SBQQ__SubscriptionTerm__c,
                                                SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c,
                                                Trade_Up_Discount__c,Promo_Disc__c,SBQQ__Discount__c,
                                                SBQQ__Quote__r.Metering__c,No_of_TBs_Cloud__c,Total_Discount__c,
                                                TPH_OEM__c,TPH_Models_Gen__c, SBQQ__Quote__r.SBQQ__Type__c,
                                                TPH_Quantity__c,TPH_Drive_Size__c, Subscribed_Asset_Name__c,SBQQ__Quote__r.Has_SubscribedAssetNames__c,
                                                SBQQ__RequiredBy__r.Total_Discount__c,SBQQ__AdditionalDiscountAmount__c
                                                FROM SBQQ__QuoteLine__c where SBQQ__Quote__r.SBQQ__Type__c = 'Amendment'
                                                limit 100];
            
            Id quoteRecId = qList1[0].SBQQ__Quote__c; 
            ScaleUtilitySegmentedLineViewController suVcn = new ScaleUtilitySegmentedLineViewController();
            suVcn.getMDQLines(quoteRecId);
            Test.stopTest();
            System.assertEquals(2, qList1.size());
        }
    } 
}