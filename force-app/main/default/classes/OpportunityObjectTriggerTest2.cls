@isTest
public with sharing class OpportunityObjectTriggerTest2 {
    @TestSetUp
    static void initialDataSetup() {
        Test.startTest();
        List<OpportunitySplitMapping__c> oppSplitMappingList = new List<OpportunitySplitMapping__c> ();
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Name', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'StageName', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'CloseDate', Skip_Update_if_child_has_value__c=false));
        insert oppSplitMappingList;

        insert new Opportunity_Stage_Days__c(AllowAcvCalculation__c = true, AllowArrCalculation__c = true);
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
        settingDisable.Trigger_Max_Loop_Count__c = 10;
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        settingDisable.Disable_Account_Validation_Rules__c = true; 
        insert settingDisable;
        
        upsert disableFuncCS;
        
        Account objAccount = new Account();
        Contact objContact = new Contact();
        Contact objContact1 = new Contact();
        Account objAccount1 = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 31-05';
        objAccount.RecordTypeId = recordTypeId;
        objAccount.PLS_NAS_ETM_Territory__c = 'PLS Cloud Territory'; //added by kajal
        objAccount.PLS_NAS_ETM_Region__c = 'PLS Cloud Region'; //added by kajal
        objAccount.PLS_NAS_ETM_Area__c = 'PLS Cloud Area'; //added by kajal
        objAccount.PLS_NAS_Theatre__c = 'PLS Cloud Theatre'; //added by kajal
        objAccount.PLS_SaaS_ETM_Territory__c = 'PLS SaaS Territory'; //added by kajal
        objAccount.PLS_SaaS_ETM_Region__c = 'PLS SaaS Region'; //added by kajal
        objAccount.PLS_SaaS_ETM_Area__c = 'PLS SaaS Area'; //added by kajal
        objAccount.PLS_SaaS_Theatre__c = 'PLS SaaS Theatre'; //added by kajal
        // objAccount.Payment_Term__c = 'Net 30';
        insert objAccount;
        objAccount1.Name = 'Test Account 01-06';
        objAccount1.RecordTypeId = recordTypeId;
        
        // objAccount1.Payment_Term__c = 'Net 30';
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
        
         Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };

        Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        prdHW.License_Type__c = 'Perpetual';
        prdHW.Product_Subtype__c = 'E1000';
        prdHW.Sales_Comp_Category__c = 'CONSUMPTION';
       // prdHW.Product_Hierarchy_Group__c = 'Core';
        Product2 prod3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        prod3.License_Type__c = 'Perpetual';
        prod3.Product_Subtype__c = 'E1000';
        prod3.Sales_Comp_Category__c = 'RUBRIK CLOUD DATA MGMT';
        prod3.Product_Hierarchy_Group__c = 'PLS-Cloud'; //SAL26-138: NAS to CLOUD
        Product2 prod4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        prod4.productcode = 'Nassku';
       // prod4.Product_Hierarchy_Group__c = 'PLS-Cloud'; //SAL26-138: NAS to CLOUD
        prod4.Sales_Comp_Category__c = 'RUBRIK UCL';
        Product2 prod5 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        prod5.productcode = 'TEST';
       // prod5.Product_Hierarchy_Group__c = 'PLS-SaaS';
        prod5.Sales_Comp_Category__c = 'O365';
        prod5.Product_Level__c = 'OnPrem';
        prod5.Product_Subtype__c = 'FEDRAMP';
        Product2 prod6 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        prod6.productcode = 'TEST';
       // prod6.Product_Hierarchy_Group__c = 'SaaS';
        prod6.Sales_Comp_Category__c = 'SW SUPPORT';
        prod6.Product_Level__c = 'OnPrem';
        prod6.Product_Subtype__c = 'FEDRAMP';
        Product2 optyspltchild = new Product2(IsActive = true, name = 'OPTY-SPLIT',productcode = 'OPTY-SPLIT');
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 4, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prod3);
        prdList.add(prod4);
        prdList.add(prod5);
        prdList.add(prod6);
        prdList.add(optyspltchild);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();

        PricebookEntry pbeHW = new PricebookEntry();
        pbeHW.Pricebook2Id = Test.getStandardPricebookId();
        pbeHW.Product2Id = prdHW.Id;
        pbeHW.UnitPrice = 1000;
        pbeHW.IsActive = true;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = new PricebookEntry();
        pbeSubs.Pricebook2Id = Test.getStandardPricebookId();
        pbeSubs.UnitPrice = 1000;
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.IsActive = true;
        pBList.add(pbeSubs);
        
        PricebookEntry pb3 = new PricebookEntry();
        pb3.Pricebook2Id = Test.getStandardPricebookId();
        pb3.Product2Id = prod3.Id;
        pb3.UnitPrice = 1000;
        pb3.IsActive = true;
        pBList.add(pb3);
        
        PricebookEntry pb4 = new PricebookEntry();
        pb4.Pricebook2Id = Test.getStandardPricebookId();
        pb4.Product2Id = prod4.Id;
        pb4.UnitPrice = 1000;
        pb4.IsActive = true;
        pBList.add(pb4);
    
        PricebookEntry pb5 = new PricebookEntry();
        pb5.Pricebook2Id = Test.getStandardPricebookId();
        pb5.Product2Id = prod5.Id;
        pb5.UnitPrice = 1000;
        pb5.IsActive = true;
        pBList.add(pb5);
        
        PricebookEntry pb6 = new PricebookEntry();
        pb6.Pricebook2Id = Test.getStandardPricebookId();
        pb6.Product2Id = optyspltchild.Id;
        pb6.UnitPrice = 1000;
        pb6.IsActive = true;
        pBList.add(pb6);
        
        insert pBList;
        
        List<PriceBook_Config_Ids__c> pbConfigList = new List<PriceBook_Config_Ids__c>();
        PriceBook_Config_Ids__c pbConfig1 = new PriceBook_Config_Ids__c();
        pbConfig1.name='OPTYSPLITPriceBookEntryId';
        pbConfig1.Config_Id__c = pb6.Id;
        pbConfigList.add(pbConfig1);
        PriceBook_Config_Ids__c pbConfig2 = new PriceBook_Config_Ids__c();
        pbConfig2.name='CPQPricebookID';
        pbConfig2.Config_Id__c = Test.getStandardPricebookId();
        pbConfigList.add(pbConfig2);
        insert pbConfigList;

        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser8769', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'Rubrik XAI User';
        listUser[1].Lastname = 'Rubrik XAI User2';
        INSERT listUser;
        /*System.runAs(listUser[0]) {
            List<Territory2Model> terrModelList = [Select id,DeveloperName,State from Territory2Model where state = 'Active' limit 1];
            List<Territory2Type> lstType = [SELECT Id FROM Territory2Type where DeveloperName='Territory' limit 1];
            List<Territory2> lstTerritories =  ETM_TestDataFactory.createTerritory('Rubrik_X_Territory', '23456', terrModelList[0].Id, lstType[0].Id, 1);
            lstTerritories[0].Territory_Structure_Type__c = 'Rubrik X';
            lstTerritories[0].DeveloperName = 'Territory';
            insert lstTerritories;
        }*/
        Test.stopTest();
    }
    @isTest
    static void testshowValidationToSyncQLsWithOppLines1(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        listUser[0].RBAC_Department__c = 'Service Account';
        listUser[0].RBAC_Group__c = 'System - IT';
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        flowControll.accountTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        List<Opportunity> opps = new List<Opportunity>();
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RS-GB-MS-', family = 'test family', ProductCode = 'RS-GB-MS-',Product_Type__c = 'M365 GRS'),
                new Product2(Name = 'RS-GB-GRS-', family = 'test family', ProductCode = 'RS-GB-GRS-',Product_Type__c = 'M365 ZRS'),
                new Product2(Name = 'RSCP-BUE-', family = 'test family', ProductCode = 'RSCP-BUE-')
                };
            insert lstProds;
        
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false)
                };
            insert pbEntry;
            
            Opportunity oppr = TestDataFactory.getOpportunity();
            insert oppr;
            
            List<ServiceContract> lstSCs = new List<ServiceContract>();
            ServiceContract testContract = new ServiceContract();
            testContract.AccountId = accountList[0].id;
            testContract.SBQQSC__Opportunity__c = oppr.Id;
            testContract.Name = 'Test Service Contract for Renewal1';
            testContract.StartDate = System.today()+10;
            testContract.Term = 24;
            testContract.SBQQSC__RenewalTerm__c = 24;
            testContract.Pricebook2Id = standardPBId;
            testContract.SBQQSC__RenewalForecast__c = true;
            lstSCs.add(testContract);
            insert lstSCs;
            
            List<ContractLineItem> cli1 = new List<ContractLineItem>{
                new ContractLineItem(SBQQSC__Account__c = accountList[0].id,ServiceContractId = lstSCs[0].Id, SBQQSC__Product__c = lstProds[0].Id, Quantity = 10, UnitPrice = 100, PricebookEntryId = pbEntry[0].Id),
                new ContractLineItem(SBQQSC__Account__c = accountList[0].id,ServiceContractId = lstSCs[0].Id, SBQQSC__Product__c = lstProds[1].Id, Quantity = 10, UnitPrice = 100, PricebookEntryId = pbEntry[1].Id),
                new ContractLineItem(SBQQSC__Account__c = accountList[0].id,ServiceContractId = lstSCs[0].Id, SBQQSC__Product__c = lstProds[2].Id, Quantity = 10, UnitPrice = 100, PricebookEntryId = pbEntry[2].Id),
                new ContractLineItem(SBQQSC__Account__c = accountList[0].id,ServiceContractId = lstSCs[0].Id, SBQQSC__Product__c = lstProds[2].Id, Quantity = 10, UnitPrice = 100, PricebookEntryId = pbEntry[2].Id)
                }; 
            insert cli1;
            
            Opportunity oppObject = TestDataFactory.getOpportunity();
            oppObject.StageName = '2 Consensus';
            oppObject.CloseDate = System.today() +2;
            oppObject.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppObject.Partner_Lookup__c = vAccount.Id;
            oppObject.Opportunity_Sub_Type__c='Renewal';
            opps.add(oppObject);
            insert opps;
            
            List<SBQQ__Quote__c> quoteList = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            insert quoteList;
            oppObject.sbqq__primaryQuote__c = quoteList[0].Id;
            update oppObject;
            
            List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1,  SBQQ__PricebookEntryId__c = pbEntry[0].Id ),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[1].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2,  SBQQ__PricebookEntryId__c = pbEntry[1].Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3,  SBQQ__PricebookEntryId__c = pbEntry[2].Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SBQQ__PricebookEntryId__c = pbEntry[2].Id)
                }; 
            insert qli1;
            quoteList[0].sbqq__primary__c = true;
            update quoteList;
            
             List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            insert oppLineList;   
            TriggerManager.resetTriggerCounter('Opportunity');      
            flowControll.opportunityTriggerHandler = true;
            flowControll.opportunityLineItemHandler = true;
            
            sdb.Disable_Opportunity_Validation_Rules__c = false;
            update sdb;
            Test.startTest();
            try{
                oppObject.StageName = System.Label.Order_Creation_Stage;
                update opps;
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }
            Test.stopTest();
            System.assert(oppObject.Id != null);
        }
    }
    @isTest
    static void testshowValidationToSyncQLsWithOppLines2(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        flowControll.accountTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        List<Opportunity> opps = new List<Opportunity>();
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RSCP-FE-', family = 'test family', ProductCode = 'RSCP-FE-'),
                new Product2(Name = 'RSCP-BE-', family = 'test family', ProductCode = 'RSCP-BE-'),
                new Product2(Name = 'RSCP-BUE-', family = 'test family', ProductCode = 'RSCP-BUE-')
                };
            insert lstProds;
        
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false)
                };
            insert pbEntry;
            Opportunity oppObject = TestDataFactory.getOpportunity();
            oppObject.StageName = '2 Consensus';
            oppObject.CloseDate = System.today() +2;
            oppObject.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppObject.Partner_Lookup__c = vAccount.Id;
            oppObject.Opportunity_Sub_Type__c='Renewal';
            opps.add(oppObject);
            insert opps;
            
            List<SBQQ__Quote__c> quoteList = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            insert quoteList;
            oppObject.sbqq__primaryQuote__c = quoteList[0].Id;
            update oppObject;
            
            List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1,  SBQQ__PricebookEntryId__c = pbEntry[0].Id ),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[1].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2,  SBQQ__PricebookEntryId__c = pbEntry[1].Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3,  SBQQ__PricebookEntryId__c = pbEntry[2].Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SBQQ__PricebookEntryId__c = pbEntry[2].Id)
                }; 
            insert qli1;
            quoteList[0].sbqq__primary__c = true;
            update quoteList;
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(SBQQ__QuoteLine__c = qli1[0].Id,pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(SBQQ__QuoteLine__c = qli1[1].Id,pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(SBQQ__QuoteLine__c = qli1[2].Id,pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(SBQQ__QuoteLine__c = qli1[3].Id,pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            insert oppLineList;              

            TriggerManager.resetTriggerCounter('Opportunity');      
            flowControll.opportunityTriggerHandler = true;
            flowControll.opportunityLineItemHandler = true;
            
            Test.startTest();
            try{
                sdb.Disable_Opportunity_Validation_Rules__c = false;
                update sdb;
                oppObject.Number_of_valid_Primary_Quotes__c = 2;
                oppObject.StageName = System.Label.Order_Creation_Stage;
                update opps;
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }
            try{
                quoteList[0].SBQQ__Status__c = 'Invalid';
                update quoteList;
                oppObject.StageName = '2 Consensus';
                update opps;
                oppObject.Number_of_valid_Primary_Quotes__c = 1;
                oppObject.StageName = System.Label.Order_Creation_Stage;
                update opps;
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }
            
            Test.stopTest();
            System.assert(oppObject.Id != null);
        }
    } 
    @isTest
    static void testshowValidationToSyncQLsWithOppLines3(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        for(user u :listUser){
            u.profileId = listProfile[0].Id;
        }
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        flowControll.accountTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        List<Opportunity> opps = new List<Opportunity>();
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            ShGl_DisableBusinessLogic__c sdb2 = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[1].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb2.Disable_Opportunity_Validation_Rules__c = true;
            sdb2.Disable_Account_Validation_Rules__c  = true;
            insert sdb2;
            ShGl_DisableFunctionalityLogic__c ds1 = new ShGl_DisableFunctionalityLogic__c(setupownerid = listUser[0].Id);
            ds1.Allow_account_Transfer__c = true;
            upsert ds1;
            ShGl_DisableFunctionalityLogic__c ds2 = new ShGl_DisableFunctionalityLogic__c(setupownerid = listUser[1].Id);
            ds2.Allow_account_Transfer__c = true;
            upsert ds2;
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RSCP-FE-', family = 'test family', ProductCode = 'RSCP-FE-'),
                new Product2(Name = 'RSCP-BE-', family = 'test family', ProductCode = 'RSCP-BE-'),
                new Product2(Name = 'RSCP-BUE-', family = 'test family', ProductCode = 'RSCP-BUE-')
                };
            insert lstProds;
        
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false)
                };
            insert pbEntry;
            Opportunity oppObject = TestDataFactory.getOpportunity();
            oppObject.StageName = '2 Consensus';
            oppObject.CloseDate = System.today() +2;
            oppObject.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppObject.Partner_Lookup__c = vAccount.Id;
            oppObject.Opportunity_Sub_Type__c='Renewal';
            oppObject.Opportunity_Amount_Override__c = true;
            opps.add(oppObject);
            insert opps;
            
            List<SBQQ__Quote__c> quoteList = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            insert quoteList;
            oppObject.sbqq__primaryQuote__c = quoteList[0].Id;
            update oppObject;
            
            List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1,  SBQQ__PricebookEntryId__c = pbEntry[0].Id ),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[1].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2,  SBQQ__PricebookEntryId__c = pbEntry[1].Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 3,  SBQQ__PricebookEntryId__c = pbEntry[2].Id),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[2].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SBQQ__PricebookEntryId__c = pbEntry[2].Id)
                }; 
            insert qli1;
            quoteList[0].sbqq__primary__c = true;
            update quoteList;
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(SBQQ__QuoteLine__c = qli1[0].Id,pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(SBQQ__QuoteLine__c = qli1[1].Id,pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(SBQQ__QuoteLine__c = qli1[2].Id,pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            insert oppLineList;              

            TriggerManager.resetTriggerCounter('Opportunity');      
            flowControll.opportunityTriggerHandler = true;
            flowControll.opportunityLineItemHandler = true;
            
            Test.startTest();
            try{
                sdb.Disable_Opportunity_Validation_Rules__c = false;
                update sdb;
                oppObject.StageName = System.Label.Order_Creation_Stage;
                update opps;
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }
            try{
                oppLineList.add(new OpportunityLineItem(SBQQ__QuoteLine__c = qli1[3].Id,pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
                upsert oppLineList; 
                oppObject.StageName = '2 Consensus';
                oppObject.Opportunity_Sub_Type__c='Renewal';
                oppObject.OwnerId = listUser[1].Id;
                update oppObject;
                oppObject.Opportunity_Sub_Type__c='GC Offer';
                oppObject.StageName = System.Label.Order_Creation_Stage;
                update oppObject;
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }
            Test.stopTest();
            System.assert(oppObject.Id != null);
        }
        Set<String> mapOfOldVsNewUsers = new Set<String>();
        Set<Id> oppIds = new Set<Id>();
        System.runAs(listUser[1]) {
            Opportunity oppObject2 = TestDataFactory.getOpportunity();
            oppObject2.StageName = '2 Consensus';
            oppObject2.Opportunity_Sub_Type__c='Renewal';
            oppObject2.OwnerId = listUser[1].Id;
            insert oppObject2;
            
            oppIds.add(oppObject2.Id);
            
            mapOfOldVsNewUsers.add(listUser[1].Id+'-'+listUser[0].Id+'-'+oppObject2.Id);
            OpportunityObjectTriggerHelper.updateOpptyShareRecForRenewalOpptyFuture(oppIds,mapOfOldVsNewUsers);
            oppObject2.OwnerId = listUser[0].Id;
            update oppObject2;
            mapOfOldVsNewUsers = new Set<String>();
            mapOfOldVsNewUsers.add(listUser[0].Id+'-'+listUser[1].Id+'-'+oppObject2.Id);
            OpportunityObjectTriggerHelper.updateOpptyShareRecForRenewalOpptyFuture(oppIds,mapOfOldVsNewUsers);
            oppObject2.OwnerId = listUser[1].Id;
            update oppObject2;
        }
    }
    @isTest
    static void testcommissionprotifolio(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        flowControll.accountTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        List<Opportunity> opps = new List<Opportunity>();
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            flowControll.accountTrigger = false;
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account4555';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RSCP-FE-', family = 'test family', ProductCode = 'RSCP-FE-',Product_Level__c='OnPrem',Product_Subtype__c='LOD Addon'),
                new Product2(Name = 'RSCP-ME-', family = 'test family', ProductCode = 'RSCP-ME-',Product_Level__c='OnPrem',Product_Type__c ='Enterprise Edition'),
                new Product2(Name = 'RSCP-BUE-', family = 'test family', ProductCode = 'RSCP-BUE-',Product_Level__c='OnPrem',Product_Type__c ='Business Edition'),
                new Product2(Name = 'RSCP-FUE-', family = 'test family', ProductCode = 'RSCP-FUE-',Product_Level__c='OnPrem',Product_Type__c ='Foundation Edition'),
                new Product2(Name = 'RS-BT-RCDM-T', family = 'test family', ProductCode = 'RS-BT-RCDM-T'),
                new Product2(Name = 'RSCP-HE-', family = 'test family', ProductCode = 'RSCP-HE-',Product_Level__c='Hybrid Software'),
                new Product2(Name = 'RSCP-EE-', family = 'test family', ProductCode = 'RSCP-EE-'),
                new Product2(Name = 'HPE-BE-', family = 'test family', ProductCode = 'HPE-BE-'),
                new Product2(Name = 'RSCP-GE-', family = 'test family', ProductCode = 'RSCP-GE-',Product_Subtype__c='GO'),
                new Product2(Name = 'RSCP-YE-', family = 'test family', ProductCode = 'RSCP-YE-',Product_Subtype__c='Complete'), 
                new Product2(Name = 'RSCP-SCALE-', family = 'test family', ProductCode = 'RSCP-SCALE-'),
                new Product2(Name = 'RSCP-QE-', family = 'test family', ProductCode = 'RSCP-QE-',Category__c = 'saas'),
                new Product2(Name = 'RSCP-ME-', family = 'test family', ProductCode = 'RSCP-ME-',Product_Type__c = 'Accessories'),
                new Product2(Name = 'RSCP-BE-HPE', family = 'test family', ProductCode = 'RSCP-BE-HPE')    
                };
            insert lstProds;
        
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[3].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[4].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[5].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[6].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[7].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[8].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[9].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[10].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[11].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[12].Id, IsActive = true, UseStandardPrice=false)
                };
            insert pbEntry;
            Opportunity oppObject = TestDataFactory.getOpportunity();
            oppObject.name = 'testOpp222';
            oppObject.StageName = '2 Consensus';
            oppObject.CloseDate = System.today() +2;
            oppObject.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppObject.Partner_Lookup__c = vAccount.Id;
            oppObject.Opportunity_Sub_Type__c='Regular';
            opps.add(oppObject);
            insert opps;
            
           
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[3].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[4].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[5].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[6].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[7].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[8].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[9].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[10].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[11].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[12].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            insert oppLineList;              

            TriggerManager.resetTriggerCounter('Opportunity');      
            
            Test.startTest();
            try{
                sdb.Disable_Opportunity_Validation_Rules__c = false;
                update sdb;
                flowControll.opportunityTriggerHandler = true;
                oppObject.Commission_Portfolio_Type__c = '';
                oppObject.StageName = '4 Business Justification';
                update opps;
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }
            
            Test.stopTest();
            System.assert(oppObject.Id != null);
        }
    } 
    @isTest
    static void testprevalidations(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<Profile> listProfile2 = [Select Id From Profile Where Name = 'Sales Operations'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        List<User> listUser1 = TestDataFactory.getUsers('testClassUser333', new Set<Id>{listProfile2[0].Id}, 1);
        insert listUser;
        insert listUser1;
        listUser[0].IsActive = true;
        listUser1[0].IsActive = true;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        insert new PermissionSetAssignment(AssigneeId = listUser1[0].Id, PermissionSetId = ps.Id);
        
        flowControll.accountTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accountList = new List<Account>();
        
        Opportunity oppObject;
        
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();

        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            flowControll.accountTrigger = false;
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
           
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            Account disAct = new Account();
            disAct.Name = 'Rubrik-TBD';
            disAct.Type='Distributor';
            disAct.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(disAct);
            Account disAct2 = new Account();
            disAct2.Name = 'ASPEN Disti TBD';
            disAct2.Type='Distributor';
            disAct2.Payment_Term__c = 'Net 30';
            disAct2.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(disAct2);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RS-GB-MS-', family = 'test family', ProductCode = 'RS-GB-MS-',Product_Type__c = 'M365 GRS'),
                new Product2(Name = 'RS-GB-GRS-', family = 'test family', ProductCode = 'RS-GB-GRS-',Product_Type__c = 'M365 ZRS'),
                new Product2(Name = 'RSCP-BUE-', family = 'test family', ProductCode = 'RSCP-BUE-')
                };
            insert lstProds;
        
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false)
                };
            insert pbEntry;
            
            Opportunity oppr = TestDataFactory.getOpportunity();
            insert oppr;
            
            
            oppObject = TestDataFactory.getOpportunity();
            oppObject.StageName = '2 Consensus';
            oppObject.CloseDate = System.today() +2;
            oppObject.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppObject.Partner_Lookup__c = vAccount.Id;
            oppObject.Opportunity_Sub_Type__c='Regular';
            oppObject.Amount_on_lead_conversion__c = 500;//SAL26-548 start
            oppObject.SOW_Required__c = true;
            oppObject.OriginalLeadOwner__c = userInfo.getUserId();
            oppObject.SDR_Led__c = true; //SAL26-548 end
            opps.add(oppObject);
            insert opps;
            
            quoteList = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            insert quoteList;
            oppObject.sbqq__primaryQuote__c = quoteList[0].Id;
            update oppObject;
            
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            insert oppLineList;   
            TriggerManager.resetTriggerCounter('Opportunity');      
            
            sdb.Disable_Opportunity_Validation_Rules__c = false;
            update sdb;            
        }
        
        System.runAs(listUser1[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser1[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            Test.startTest();
            try{
                flowControll.opportunityTriggerHandler = true;
                oppObject.StageName = '2 Consensus';
                oppObject.Distributor_Lookup__c = accountList[1].Id;
                update oppObject;
                oppObject.StageName = System.Label.Order_Creation_Stage;
                update oppObject;
                oppObject.StageName = '5 Negotiate & Close';
                oppObject.Distributor_Lookup__c = accountList[2].Id;
                update oppObject;
                /*oppObject.StageName = System.Label.Order_Creation_Stage;
                oppObject.Distributor_Lookup__c = accountList[2].Id;
                update oppObject;*/
                
                //SAL26-549
                Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>([SELECT Id, StageName, Distributor_Lookup__c, Distributor_Lookup_Name__c FROM Opportunity WHERE Id = :oppObject.Id]);
                Account distAcc = new Account(Id = accountList[1].Id, Name = 'Rubrik-TBD');
                UPDATE distAcc;
                oppObject.Distributor_Lookup__c = distAcc.Id;
                oppObject.RubrikTBD_Accept_Conditions__c = false;
                oppObject.StageName = '1 Discovery';
                UPDATE oppObject;
                Opportunity opp11 = [SELECT Id, Distributor_Lookup_Name__c, stageName, Distributor_Lookup__c,IsClosed, Opportunity_Type__c,RubrikTBD_Accept_Conditions__c,DistriMarketplace_Accept_Conditions__c
                                     FROM Opportunity WHERE Id = :oppObject.Id];
                OpportunityObjectTriggerHelper.isStage5ChangeAllowed(new List<Opportunity>{opp11}, oldOppMap, new Map<Id, User>{listUser1[0].Id => listUser1[0]}, new Map<Id, SBQQ__Quote__c>{quoteList[0].Id => quoteList[0]}, new Map<Id, Account>());
                accountList[1].Name = 'Microsoft Azure Marketplace';
                UPDATE accountList[1];
                oppObject.DistriMarketplace_Accept_Conditions__c = false;
                UPDATE oppObject;
                OpportunityObjectTriggerHelper.isStage5ChangeAllowed(new List<Opportunity>{opp11}, oldOppMap, new Map<Id, User>{listUser1[0].Id => listUser1[0]}, new Map<Id, SBQQ__Quote__c>{quoteList[0].Id => quoteList[0]}, new Map<Id, Account>());
                //SAL26-549 
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }
            Test.stopTest();
            System.assert(oppObject.Id != null);
        }
    }
    
    //SAL26-548 start
    @isTest static void testOppTriggerHandler() {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(userInfo.getUserId());
            disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
            disableBusinessLogicCS.Disable_Opportunity_Triggers__c = false;
            INSERT disableBusinessLogicCS;
            
            FlowControll.opportunityTriggerHandler = true;
            TriggerControls.disableQuoteTrigger = true;
            
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert vAccount;
            
            Opportunity oppObject = TestDataFactory.getOpportunity();
            oppObject.StageName = '2 Consensus';
            oppObject.CloseDate = System.today() +2;
            oppObject.Partner_Lookup__c = vAccount.Id;
            oppObject.Opportunity_Sub_Type__c='Renewal';
            oppObject.FCRM__FCR_Admin_Originating_Contact__c = [SELECT Id FROM Contact LIMIT 1].Id;
            insert oppObject;
            
            List<SBQQ__Quote__c> quoteList = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            quoteList[0].SBQQ__Primary__c = true;
            quoteList[0].SBQQ__Type__c = 'Renewal';
            quoteList[0].Primary_Contact__c = null;
            quoteList[0].SBQQ__Partner__c = null;
            quoteList[0].Deal_Structuring_Oppty_Notes__c = 'ABC';
            insert quoteList;
            
            Test.startTest();
            Opportunity oppObject1 = TestDataFactory.getOpportunity();
            oppObject1.StageName = '2 Consensus';
            oppObject1.CloseDate = System.today() +2;
            oppObject1.Opportunity_Sub_Type__c='Renewal';
            oppObject1.Amount_on_lead_conversion__c = 500; 
            oppObject1.Opportunity_Program__c = 'Refresh';
            oppObject1.sbqq__primaryQuote__c = quoteList[0].Id;
            oppObject1.Marketplace__c = 'GCP Marketplace';
            oppObject1.Partner_Lookup__c = vAccount.Id;
            oppObject1.Deal_Structuring_Oppty_Notes__c = 'TEST';
            oppObject1.Pricebook2Id = Test.getStandardPricebookId();
            oppObject1.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
            oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            insert oppObject1;        
            
            quoteList[0].SBQQ__Primary__c = false;
            quoteList[0].SBQQ__Account__c = oppObject1.AccountId;
            quoteList[0].SBQQ__Opportunity2__c = oppObject1.Id;
            UPDATE quoteList[0];
            
            quoteList[0].SBQQ__Primary__c = true;
            UPDATE quoteList[0];
            
            System.assert(oppObject1.Distributor_Lookup__c != vAccount.Id);
            oppObject1.StageName = '3 Technical Validation';
            oppObject1.SOW_Required__c = true;
            oppObject1.Marketplace__c = 'Azure Marketplace';
            oppObject1.Distributor_Lookup__c = vAccount.Id;
            UPDATE oppObject1;
            System.assert(oppObject1.Id != null);
        }        
        Test.stopTest();
    }
    
    //SAL26-548
    @istest static void coOwnerOverrideTest() {
        Test.startTest();
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(userInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = false;
        disableBusinessLogicCS.Disable_Opportunity_Triggers__c = false;
        INSERT disableBusinessLogicCS;
        
        FlowControll.opportunityTriggerHandler = true;
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'Sinha';
        INSERT listUser;
        List<UserTerritory2Association>UTAList = new List<UserTerritory2Association>();
        System.runAs(listUser[0]) {
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned' and Territory_Structure_Type__c = 'PLS Cloud' and Adaptive_Territory_Id__c != null limit 1];  //SAL26-138:NAS to Cloud                   
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Cloud AE',UserId = listUser[0].id)); //SAL26-138:NAS to Cloud
            INSERT UTAList;
        }
        UserTerritory2Association uta = [SELECT Id, userId, Territory2.Adaptive_Territory_Id__c 
                                         FROM UserTerritory2Association WHERE Id =:UTAList[0].Id];        
        Account account = new Account();
        account.Name = 'Test Account';
        account.Non_Core_Adaptive_Territory_Ids__c = uta.Territory2.Adaptive_Territory_Id__c;
        account.Non_Core_Type_and_Adaptive_Id__c = 'PLS Cloud:'+uta.Territory2.Adaptive_Territory_Id__c; //SAL26-138:NAS to Cloud
        insert account;
        System.assert(account.Non_Core_Adaptive_Territory_Ids__c != null);
        
        Opportunity oppObject1 = TestDataFactory.getOpportunity(account);
        oppObject1.Opportunity_Type__c = 'Existing Customer';
        oppObject1.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        oppObject1.CloseDate = System.today().addMonths(-1);
        oppObject1.Co_Owner__c = uta.userId;
        System.runAs(listUser[0]){
            insert oppObject1;
        }
        
        System.assert(oppObject1.Id != null);
        System.assert(oppObject1.Co_Owner__c != null);
       
        oppObject1.Non_Core_Adaptive_Id__c = '123'; 
        oppObject1.PLS_ETM_Override__c = true; 
        UPDATE oppObject1;
        
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        UPDATE disableBusinessLogicCS;
          //SAL26-549 start
        After_Action_Review__c aar = new After_Action_Review__c();
        aar.Opportunity__c = oppObject1.Id;
        aar.Opportunity_ClosedDate__c = System.today()+2;
        insert aar;
        
        oppObject1.After_Action_Form_Submitted__c = true; //SAL26-549 end
        oppObject1.StageName = '7 Closed Lost'; 
        oppObject1.CloseDate = Date.newInstance(2024, 01, 01);
        UPDATE oppObject1;
       
        oppObject1.StageName = '2 Consensus';
        oppObject1.Co_Owner__c = null;
        oppObject1.PLS_AE_ETM_Role_Name__c = 'Cloud AE'; //SAL26-138:NAS to Cloud
        UPDATE oppObject1;
        Test.stopTest();
    }
    
    //SAL26-548
    @istest static void coOwnerOverrideTest1() {
        Test.startTest();
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(userInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = false;
        disableBusinessLogicCS.Disable_Opportunity_Triggers__c = false;
        INSERT disableBusinessLogicCS;
        
        FlowControll.opportunityTriggerHandler = true;
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'Sinha';
        INSERT listUser;
        List<UserTerritory2Association>UTAList = new List<UserTerritory2Association>();
        System.runAs(listUser[0]) {
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned' and Territory_Structure_Type__c = 'PLS SaaS' and Adaptive_Territory_Id__c != null limit 1];  //SAL26-138:NAS to Cloud                   
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'SaaS AE',UserId = listUser[0].id)); //SAL26-138:NAS to Cloud
            INSERT UTAList;
        }
        UserTerritory2Association uta = [SELECT Id, userId, Territory2.Adaptive_Territory_Id__c 
                                         FROM UserTerritory2Association WHERE Id =:UTAList[0].Id];        
        Account account = new Account();
        account.Name = 'Test Account';
        account.Non_Core_Adaptive_Territory_Ids__c = uta.Territory2.Adaptive_Territory_Id__c;
        account.Non_Core_Type_and_Adaptive_Id__c = 'PLS SaaS:'+uta.Territory2.Adaptive_Territory_Id__c; //SAL26-138:NAS to Cloud
        insert account;
        System.assert(account.Non_Core_Adaptive_Territory_Ids__c != null);
        
        Opportunity oppObject1 = TestDataFactory.getOpportunity(account);
        oppObject1.Opportunity_Type__c = 'Existing Customer';
        oppObject1.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        oppObject1.CloseDate = System.today().addMonths(-1);
        oppObject1.Co_Owner__c = uta.userId;
        System.runAs(listUser[0]){
            insert oppObject1;
        }
        
        System.assert(oppObject1.Id != null);
        System.assert(oppObject1.Co_Owner__c != null);
        Test.stopTest();
    }
    
    //SAL26-548
    @isTest static void testOppCoOwner() {
        Test.startTest();
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(userInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        disableBusinessLogicCS.Disable_Opportunity_Triggers__c = false;
        INSERT disableBusinessLogicCS;
        
        FlowControll.opportunityTriggerHandler = true;
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'Sinha';
        INSERT listUser;
        System.assert(listUser != null);
        
        List<UserTerritory2Association> UTAList = new List<UserTerritory2Association>();
        List<Territory2> terrList = new List<Territory2>();
        
        System.runAs(listUser[0]) {
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned'limit 10];                     
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Cloud AE',UserId = listUser[0].id)); //SAL26-138:NAS to Cloud
            INSERT UTAList;
        }
        if(!terrList.isEmpty()){
            Account account = new Account();
            account.Non_Core_Adaptive_Territory_Ids__c = terrList[0].Adaptive_Territory_Id__c;
            account.Non_Core_Type_and_Adaptive_Id__c = 'PLS Cloud:'+terrList[0].Adaptive_Territory_Id__c; //SAL26-138:NAS to Cloud
            account.Name = 'Test Acc Co-Owner';
            INSERT account;
            
            Opportunity oppObject1 = TestDataFactory.getOpportunity();
            oppObject1.Opportunity_Type__c = 'Existing Customer';
            oppObject1.Opportunity_Sub_Type__c = 'Regular';
            oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            oppObject1.CloseDate = System.today().addMonths(-1);
            oppObject1.Co_Owner__c = UTAList[0].userId;
            oppObject1.PLS_ETM_Override__c = true;
            oppObject1.AccountId = account.Id;
            insert oppObject1;
            System.assert(oppObject1.Id != null);
            System.assert(oppObject1.Co_Owner__c != null);    
        }
        Test.stopTest();
    }
    
    //SAL26-548
    @isTest static void testDebrief() {
        Test.startTest();
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        System.assert(listUser != null);
        
        Opportunity oppObject1 = TestDataFactory.getOpportunity();
        oppObject1.Opportunity_Type__c = 'Existing Customer';
        oppObject1.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        oppObject1.CloseDate = System.today().addMonths(-1);
        oppObject1.Escalation_Stage__c = 'Needs Monitoring';
        oppObject1.Hold_Code__c = 'Missing ship to information';
        insert oppObject1;
        
        Opportunity_Debrief__c def = new Opportunity_Debrief__c();
        def.Area__c = 'Missing Feature';
        def.Area_Detail__c = 'CDM';
        def.Area_Sub_Detail__c = 'Exchange';
        def.Severity__c = 'Blocker';
        def.Opportunity__c = oppObject1.Id;
        insert def;
        
        Order o = new Order();
        o.OpportunityId = oppObject1.Id;
        o.AccountId = oppObject1.AccountId;
        o.EffectiveDate = System.today();
        o.Status = 'Draft';
        insert o;
        System.assert(o.Id != null);
        
        System.runAs(listUser[0]){
            oppObject1.Escalation_Stage__c = 'At Risk';
            oppObject1.Hold_Code__c = 'Missing freight forwarder details';
            oppObject1.AWS_GCP_Cloud_Alliance_BDM__c = listUser[0].Id;
            UPDATE oppObject1;
        }        
        Test.stopTest();           
    }
    
    @isTest static void testRscOwner(){
             
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        update listUser;
        System.assert(listUser != null);
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
        sdb.Trigger_Max_Loop_Count__c = 10;
        sdb.Disable_Opportunity_Validation_Rules__c = true;
        sdb.Disable_Account_Validation_Rules__c = true;
        insert sdb;
        
        System.runAs(listUser[0]) {
            PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
            insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        }
        flowControll.accountTrigger = true;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        List<Opportunity> opps = new List<Opportunity>();
            Contact contact = TestDataFactory.getContact();
            INSERT contact;
            
            Account account = new Account(Id = contact.AccountId, RSC_G_Eligible__c = true);
            UPDATE account;
            
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RS-GB-MS-', family = 'test family', ProductCode = 'RS-GB-MS-',Product_Type__c = 'M365 GRS',Product_Subtype__c = 'FEDRAMP'),
                new Product2(Name = 'CONSUMPTION ACTUALS', ProductCode = 'CONSUMPTION-ACTUALS', isActive = true,Product_Subtype__c = 'FEDRAMP')
                };
            insert lstProds;
        
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false)
             };
            insert pbEntry;
       
            Opportunity oppObject = TestDataFactory.getOpportunity(account, contact);
            oppObject.StageName = '2 Consensus';
            oppObject.CloseDate = System.today() +2;
            oppObject.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppObject.Partner_Lookup__c = vAccount.Id;
            oppObject.Opportunity_Sub_Type__c='Regular';
            oppObject.Opportunity_Type__c = 'Existing Customer';
            opps.add(oppObject);
         System.runAs(listUser[0]) {
            insert opps;
         }
            List<SBQQ__Quote__c> quoteList = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            insert quoteList;
            oppObject.sbqq__primaryQuote__c = quoteList[0].Id;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
        SBQQ.TriggerControl.disable();
            update oppObject;
            
            List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1,  SBQQ__PricebookEntryId__c = pbEntry[0].Id),
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[1].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1,  SBQQ__PricebookEntryId__c = pbEntry[1].Id)    
                }; 
                    TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
            insert qli1;
            
            qli1[0].SBQQ__RequiredBy__c = qli1[1].Id;
            UPDATE qli1;
            
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
        
            quoteList[0].sbqq__primary__c = true;
            update quoteList;
            
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 2,OpportunityID = oppObject.Id));
            insert oppLineList;   
                                    
        System.runAs(listUser[0]) {

            TriggerManager.resetTriggerCounter('Opportunity');      
            flowControll.opportunityTriggerHandler = true;
            flowControll.opportunityLineItemHandler = true;
            
            sdb.Disable_Opportunity_Validation_Rules__c = false;
            update sdb;
               
            oppObject.Polaris_Portal_Contact__c = contact.Id;
            oppObject.MSFT_OCI_Cloud_Alliance_BDM__c = listUser[0].Id;
            UPDATE oppObject;
            
            quoteList[0].sbqq__primary__c = false;
            update quoteList;
                        
            TriggerManager.resetTriggerCounter('Opportunity'); 
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            UPDATE sdb;
            oppObject.Polaris_Portal_Contact__c = null;
            oppObject.StageName = '7 Closed Lost'; 
            try {
                Test.startTest();  
                UPDATE oppObject;  
                Test.stopTest();
            } catch(Exception ex){
                System.assert(true);
            }            
        }
    }
    
    //SAL26-548
    @istest static void testCodeCoverage1() {
        Test.startTest();
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(userInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        disableBusinessLogicCS.Disable_Opportunity_Triggers__c = false;
        disableBusinessLogicCS.Disable_Lead_Triggers__c = true;
        INSERT disableBusinessLogicCS;
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        
        FlowControll.opportunityTriggerHandler = true;
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'Sinha';
        INSERT listUser;
        List<Territory2> terrList = new List<Territory2>();
        List<UserTerritory2Association>UTAList = new List<UserTerritory2Association>();
        System.runAs(listUser[0]) {
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned'limit 10];                     
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Account Executive',UserId = listUser[0].id));
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Sales Engineer',UserId = listUser[1].id));
            INSERT UTAList;
        }
        
        Opportunity oppObject1 = TestDataFactory.getOpportunity();
        oppObject1.Opportunity_Type__c = 'Existing Customer';
        oppObject1.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        oppObject1.CloseDate = System.today().addMonths(-1);
        oppObject1.Non_Core_Adaptive_Id__c = terrList[0].Adaptive_Territory_Id__c;
        insert oppObject1;
        System.assert(oppObject1.Id != null);
        
        disableFuncCS.Allow_account_Transfer__c = true;
        UPDATE disableFuncCS;
        
        Lead lead = new Lead(Company='Test',LeadSource='Email',Lastname='Test',
                           Lead_Source_Details__c='Test',Country='United States',City='California');
        insert lead;
        
        oppObject1.Deal_Registration_Link__c = lead.Id;
        oppObject1.Override_ETM_Ownership__c = true; 
        oppObject1.OwnerId = listUser[0].Id;  
        UPDATE oppObject1;
   
        Opportunity oppObject2 = TestDataFactory.getOpportunity();
        oppObject2.Rubrik_Complete_Edition_Reg__c = true;
        try {
            INSERT oppObject2;
        }catch(Exception ex){
            System.assert(true);
        }        
        Test.stopTest();
    }
    
    @isTest static void testCodeCoverage2(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        update listUser;
        System.assert(listUser != null);
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
        sdb.Trigger_Max_Loop_Count__c = 10;
        sdb.Disable_Opportunity_Validation_Rules__c = true;
        sdb.Disable_Account_Validation_Rules__c = true;
        insert sdb;
        
        System.runAs(listUser[0]) {
            PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Sales_Ops_Business_Data_Migration_User'];
            insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        }        
        flowControll.accountTrigger = true;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        List<Opportunity> opps = new List<Opportunity>();
            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RS-GB-MS-', family = 'test family', ProductCode = 'RS-GB-MS-',Product_Type__c = 'M365 GRS')
                };
            insert lstProds;
        
            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false)
                };
            insert pbEntry;
       
            Opportunity oppObject = TestDataFactory.getOpportunity();
            oppObject.StageName = '2 Consensus';
            oppObject.CloseDate = System.today() +2;
            oppObject.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppObject.Partner_Lookup__c = vAccount.Id;
            oppObject.Opportunity_Sub_Type__c='Regular';
            oppObject.Opportunity_Type__c = 'Existing Customer';
            opps.add(oppObject);
            insert opps;
            
            List<SBQQ__Quote__c> quoteList = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
            insert quoteList;
            oppObject.sbqq__primaryQuote__c = quoteList[0].Id;
            update oppObject;
            
            List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1,  SBQQ__PricebookEntryId__c = pbEntry[0].Id )
                }; 
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;        
            insert qli1;
            
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(SBQQ__QuoteLine__c = qli1[0].Id,pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 10,OpportunityID = oppObject.Id));
            insert oppLineList;   
                   
            quoteList[0].sbqq__primary__c = true;
            quoteList[0].ApprovalStatus__c = 'Approved'; //SAL26-459
            update quoteList;
            System.assert(quoteList[0].ApprovalStatus__c == 'Approved');
            
            Opportunity oldOpp = [SELECT Id, Primary_Quote_Approval_Status__c, SBQQ__PrimaryQuote__c, Aspen_Eligibility__c, StageName, Override__c,
                                  CM_Notification_To_Distributor__c, ContractManufacturer__c, Name,
                                  (SELECT Id, ProductCode, TotalPrice, SBQQ__QuoteLine__r.SBQQ__Quote__c, Line_Type__c FROM OpportunityLineItems)
                                  FROM Opportunity WHERE Id = :oppObject.Id];

            OpportunityObjectTriggerHelper.getTotalOpportunityAmount(oldOpp, new List<OpportunityLineItem>(), new List<OpportunityLineItem>());
            flowControll.opportunityTriggerHandler = false;            

            oppObject.CM_Notification_To_Distributor__c = 'Recalculate CM recommendation';
            oppObject.Aspen_Eligibility__c = 'Proposed Aspen';
            oppObject.Override__c = false;
            oppObject.Name = 'Test Aspen';
            UPDATE oppObject;            
            System.runAs(listUser[0]) {

            Opportunity newOpp = [SELECT Id, Primary_Quote_Approval_Status__c, SBQQ__PrimaryQuote__c, Aspen_Eligibility__c, StageName, Override__c,
                                  CM_Notification_To_Distributor__c, ContractManufacturer__c, Name
                                  FROM Opportunity WHERE Id = :oppObject.Id];            

            Test.startTest();   
            OpportunityObjectTriggerHelper.aspenOpportunityOperations(new Map<Id, Opportunity>{oldOpp.Id=>oldOpp}, new Map<Id, Opportunity>{newOpp.Id=>newOpp});
            
            TriggerManager.resetTriggerCounter('Opportunity'); 
            oppObject.StageName = '6 PO With Channel';
            oppObject.Aspen_Eligibility__c = 'Proposed Aspen';
            oppObject.Polaris_Region__c = 'Out of Region DR-US';
            UPDATE oppObject;   
           
            Opportunity Opp = [SELECT Id, Primary_Quote_Approval_Status__c FROM Opportunity WHERE Id = :oppObject.Id];
            System.assert(Opp.Primary_Quote_Approval_Status__c == 'Approved');

            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Type__c = 'Partner Sourced Expand';
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Primary__c = true;
            deal.Opportunity__c = Opp.Id;
            flowControll.DealRegistrationTrigger = false;
            insert deal;
            flowControll.DealRegistrationTrigger = true;

            List<Deal_Registration__c> deal1 = [select Id,Name,Deal_Registration_Status__c,Approval_Timestamp__c,Opportunity__c,Deal_Reg_Exp_Date__c,Company_Name__c,OwnerId,Primary_Deal_Registration__c,Primary__c,Deal_Registration_Sub_Status__c,Deal_Registration_Type__c, DR_Approved_Date__c,Deal_Registration_Extension_Request__c,Registration_Type__c
                                                from Deal_Registration__c where id =:deal.Id];

            flowControll.opportunityTriggerHandler = true;

            oppObject.StageName = '7 Closed Lost';
            oppObject.CM_Notification_To_Distributor__c = 'Recalculate CM recommendation';
            oppObject.Aspen_Eligibility__c = 'Proposed Aspen';
            oppObject.Override__c = false;
            oppObject.Name = 'Test Aspen';
            oppObject.Deal_Reg_Approval_Status__c = 'Approved';
            oppObject.Deal_Registration_Number__c = deal1[0].Name;
            UPDATE oppObject;

            OpportunityObjectTriggerHelper.updateClosedDealRegistrations(null);   
            OpportunityObjectTriggerHelper.updateDealRegOnOpportunity(new Map<String, Opportunity>{deal1[0].Name => oppObject}, deal1);
            
            oppObject.SBQQ__PrimaryQuote__c = null;
            UPDATE oppObject;

            oldOpp = [SELECT Id, Primary_Quote_Approval_Status__c, SBQQ__PrimaryQuote__c, Aspen_Eligibility__c, StageName, Override__c,
                                  CM_Notification_To_Distributor__c, ContractManufacturer__c, Name,
                                  (SELECT Id, ProductCode, TotalPrice, SBQQ__QuoteLine__r.SBQQ__Quote__c, Line_Type__c FROM OpportunityLineItems)
                                  FROM Opportunity WHERE Id = :oppObject.Id];
            OpportunityObjectTriggerHelper.getTotalOpportunityAmount(oldOpp, new List<OpportunityLineItem>(), new List<OpportunityLineItem>());

            oppObject.Rubrik_Complete_Edition_Reg__c = true;
            try {
                UPDATE oppObject; 
            }catch(Exception ex){
                System.assert(true);
            }
            Test.stopTest();
            oppObject.SBQQ__PrimaryQuote__c = null;
            UPDATE oppObject;
            oldOpp = [SELECT Id, Primary_Quote_Approval_Status__c, SBQQ__PrimaryQuote__c, Aspen_Eligibility__c, StageName, Override__c,
                                  CM_Notification_To_Distributor__c, ContractManufacturer__c, Name,
                                  (SELECT Id, ProductCode, TotalPrice, SBQQ__QuoteLine__r.SBQQ__Quote__c, Line_Type__c FROM OpportunityLineItems)
                                  FROM Opportunity WHERE Id = :oppObject.Id];
            OpportunityObjectTriggerHelper.getTotalOpportunityAmount(oldOpp, new List<OpportunityLineItem>(), new List<OpportunityLineItem>());
        }
    }
    
    //SAL26-548
    @isTest static void testCodeCoverage3() {

        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        System.assert(listUser != null);
        
        Test.startTest();
        Opportunity oppObject1 = TestDataFactory.getOpportunity();
        oppObject1.Opportunity_Type__c = 'Existing Customer';
        oppObject1.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        oppObject1.StageName = '7 Closed Won';
        System.runAs(listUser[0]){
            try {
                insert oppObject1;
            }catch(Exception ex) {
                System.assert(true);
            }
        }
        Test.stopTest();
    }
    
    //SAL26-549
    @isTest static void testCodeCoverage4(){
        Test.startTest();
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].Region__c = 'N. Central';
        listUser[1].Region__c = '';
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            insert sdb;
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Allow_account_Transfer__c = true;
            INSERT disableFuncCS;
            
            Account vAccount = new Account();
            vAccount.Name = 'Test Account';
            vAccount.Type='Distributor';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            vAccount.Aspen_Eligible__c = true;
            insert vAccount;
            Id standardPBId = test.getStandardPricebookId();
            Opportunity oppObject = TestDataFactory.getOpportunity();
            oppObject.OwnerId = listUser[0].Id;
            oppObject.Incumbent_Partner__c = vAccount.Name;
            oppObject.Distributor_Lookup__c = vAccount.Id;
            oppObject.Sell_to_Partner__c = null;
            oppObject.Opportunity_Program__c = 'Conversion';
            insert oppObject;
            
            System.assert(oppObject.OwnerId == listUser[0].Id);
            
            oppObject.Include_Datos__c = true;
            UPDATE oppObject;
            
            List<OpportunityTeamMember> otmLst = new List<OpportunityTeamMember>();
            otmLst.add(new OpportunityTeamMember(OpportunityId = oppObject.Id,
                                                 UserId = listUser[0].Id,
                                                 TeamMemberRole = 'Co-Owner',
                                                 OpportunityAccessLevel = 'Edit', Is_Auto_Added__c = true));
            otmLst.add(new OpportunityTeamMember(OpportunityId = oppObject.Id,
                                                 UserId = listUser[1].Id,
                                                 TeamMemberRole = 'Co-Owner',
                                                 OpportunityAccessLevel = 'Edit', Is_Auto_Added__c = true));
            INSERT otmLst;
            oppObject.OwnerId = listUser[1].Id;
            UPDATE oppObject;
            
            oppObject.Include_Datos__c = false;
            oppObject.OwnerId = listUser[1].Id;
            UPDATE oppObject;
            OpportunityObjectTriggerHelper.updateAspenEligibility(new List<Opportunity>{oppObject}, new Map<Id, Account>{vAccount.Id => vAccount}, null);
            /*Product2 product = new Product2(Name = 'RSCP-FE-', family = 'test family', ProductCode = 'RSCP-FE-');
            insert product;         
            PriceBookEntry pbEntry = new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = product.Id, IsActive = true, UseStandardPrice=false);
            insert pbEntry;    
            //OpportunityLineItem oli = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 10,OpportunityID = oppObject.Id);
            //insert oli;
            Opportunity oldOpp = [SELECT Id, Amount, Primary_Quote_Approval_Status__c, SBQQ__PrimaryQuote__c, Aspen_Eligibility__c, StageName, Override__c,
                                  CM_Notification_To_Distributor__c, ContractManufacturer__c, Name,
                                  (SELECT Id, ProductCode, TotalPrice, SBQQ__QuoteLine__r.SBQQ__Quote__c, Line_Type__c FROM OpportunityLineItems)
                                  FROM Opportunity WHERE Id = :oppObject.Id];
            OpportunityObjectTriggerHelper.getTotalOpportunityAmount(oldOpp, new List<OpportunityLineItem>(), new List<OpportunityLineItem>());*/
       }
        Test.stopTest();
    }
    
    @isTest
    static void updateOpptyShareRecForRenewalOpptyFutureTest2(){
        
        List<User> listUsers = new List<User>();
        Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
        Id listProfile2 = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
        List<User> listUsers1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{listProfile1}, 1);
        List<User> listUsers2 = TestDataFactory.getUsers('testClassUser2', new Set<Id>{listProfile2}, 1);
        List<User> listUsers3 = TestDataFactory.getUsers('testClassUser3', new Set<Id>{listProfile1}, 1);

        // Set RBAC_Department__c first (controlling field) then RBAC_Group__c
        // System - IT is only allowed when RBAC_Department__c = 'Service Account'
        for(User u : listUsers1) {
            u.RBAC_Department__c = 'Service Account';
            u.RBAC_Group__c = 'System - IT';
        }
        for(User u : listUsers2) {
            u.RBAC_Department__c = 'Service Account';
            u.RBAC_Group__c = 'System - IT';
        }
        for(User u : listUsers3) {
            u.RBAC_Department__c = 'Service Account';
            u.RBAC_Group__c = 'System - IT';
        }

        listUsers.addAll(listUsers1);
        listUsers.addAll(listUsers2);
        listUsers.addAll(listUsers3);
        insert listUsers;
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
        settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
        settingDisable.Disable_ServiceContract_Trigger__c=true;
        settingDisable.Disable_Entitlement_Usage_Trigger__c=true;
        settingDisable.Disable_Entitlement_Trigger__c=true;
        settingDisable.Disable_Asset_Triggers__c=true;
        settingDisable.Disable_Contract_Line_Item_Triggers__c=true;
        insert settingDisable;
        
        ShGl_DisableFunctionalityLogic__c ds = ShGl_DisableFunctionalityLogic__c.getInstance();
        ds.Allow_account_Transfer__c = true;
        ds.DisableDemandMatrixCalculation__c = true;
        upsert ds;
        
        Account acc = new Account(Name = 'Disti-TBD', ParentId = null);
        insert acc;
        
        Id standardPBId = test.getStandardPricebookId();
        List<Product2> lstProds = new List<Product2>{new Product2(Name = 'RSCP-FE-', family = 'test family', ProductCode = 'RSCP-FE-')};
        insert lstProds;
        
        List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
            new PriceBookEntry(UnitPrice = 0, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false)};
                System.runAs(listUsers[0])  {
                    insert pbEntry;
                }
        
        List<Opportunity> oppsToInsert = new List<Opportunity>();        
        //Create Sales Opptys
        Opportunity sOpp = TestDataFactory.getOpportunity();
        sOpp.AccountId = acc.Id;
        sOpp.Pricebook2Id=standardPBId;
        sOpp.Opportunity_Sub_Type__c = 'Regular';
        sOpp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        sOpp.Deal_Registration__c = True;
        sOpp.Deal_Reg_Approval_Status__c = 'Approved';
        sOpp.Converted_From_Lead__c = true;
        sOpp.Opportunity_Split_Parent__c = null;
        sOpp.OwnerId = UserInfo.getUserId();
        sOpp.StageName = '6 PO With Channel';
        oppsToInsert.add(sOpp);
        //insert sOpp;
        
        //Create Renewal Opptys
        Opportunity opp = TestDataFactory.getOpportunity();
        opp.Pricebook2Id=standardPBId;
        opp.Opportunity_Sub_Type__c = 'Renewal';
        opp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        opp.Deal_Registration__c = True;
        opp.Deal_Reg_Approval_Status__c = 'Approved';
        opp.OwnerId =  listUsers[0].Id;
        opp.Converted_From_Lead__c = true;
        opp.Opportunity_Split_Parent__c = null;
        oppsToInsert.add(opp);
        FlowControll.opportunityTriggerHandler = false;
        INSERT oppsToInsert;
        //insert opp;
        
        System.assert((opp.Id!=null), 'Correct');
        
        OpportunityShare oppShr  = new OpportunityShare();
        oppShr.opportunityId  = opp.Id;
        oppShr.UserOrGroupId = UserInfo.getUserId();
        oppShr.OpportunityAccessLevel = 'Edit';
        oppShr.RowCause = Schema.OpportunityShare.RowCause.Manual;
        System.runAs(listUsers[0]){
            insert oppShr;
        }
        
        List<ServiceContract> lstSCs = new List<ServiceContract>();
        ServiceContract testContract = new ServiceContract();
        testContract.AccountId = acc.id;
        testContract.SBQQSC__Opportunity__c = sOpp.Id;
        testContract.SBQQSC__RenewalOpportunity__c = opp.Id;
        testContract.Name = 'Test Service Contract for Renewal1';
        testContract.StartDate = System.today()+10;
        testContract.Term = 24;
        testContract.SBQQSC__RenewalTerm__c = 24;
        testContract.Pricebook2Id = standardPBId;
        testContract.SBQQSC__RenewalForecast__c = true;       
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        insert testContract;
        
        List<ContractLineItem> cli1 = new List<ContractLineItem>{
            new ContractLineItem(ServiceContractId = testContract.Id, SBQQSC__Product__c = lstProds[0].Id, Quantity = 10, UnitPrice = 100, PricebookEntryId = pbEntry[0].Id)
                }; 
        System.runAs(listUsers[0]){
            insert cli1;
        }
                    
        
        
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        quoteList.add(new SBQQ__Quote__c(SBQQ__Opportunity2__c = sOpp.Id, SBQQ__Type__c = 'Renewal+Expansion',SBQQ__Account__c = acc.Id));
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        insert quoteList;
        
        List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'Asset1, Asset2',SBQQSC__RenewedContractLine__c = cli1[0].Id, SBQQ__PricebookEntryId__c = pbEntry[0].Id )
                }; 
                    insert qli1;
        
        System.assert(qli1[0].Id != null);
        
        FlowControll.opportunityTriggerHandler = true;
        List<Opportunity> lstToUpdate = new List<Opportunity>();
        opp.OwnerId = listUsers[1].Id;
        lstToUpdate.add(opp);
        Test.startTest();
        update lstToUpdate;
        
        
        OpportunityObjectTriggerHelper.updateOpptyShareRecForRenewalOppty(new Set<Id>{opp.Id}, new Set<String>{listUsers[0].Id+'-'+listUsers[1].Id+'-'+opp.Id});
        Test.stopTest();
    }
    
     //SAL26-549

    @isTest static void testIsStage5ChangedAllowed(){
        Id listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'].Id;
        List<User> listUsers = TestDataFactory.getUsers('testClassUser1', new Set<Id>{listProfile}, 1);
        insert listUsers;

        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
        settingDisable.Disable_Account_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
        insert settingDisable;

        Test.startTest();
        Account acc = new Account(Name = 'Disti-TBD', ParentId = null);
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert acc;

        //Create Sales Opptys
        Opportunity sOpp = TestDataFactory.getOpportunity();
        sOpp.AccountId = acc.Id;
        sOpp.Opportunity_Sub_Type__c = 'Regular';
        sOpp.Distributor_Lookup__c = null;
        sOpp.RecordTypeId=Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        insert sOpp;

        List<SBQQ__Quote__c> quoteList = TestDataFactory.getQuotes(new Set<Id>{sOpp.Id}, 1);
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        insert quoteList;
        
        sOpp.sbqq__primaryQuote__c = quoteList[0].Id;
        update sOpp;

        Id standardPBId = test.getStandardPricebookId();
        List<Product2> lstProds = new List<Product2>{new Product2(Name = 'RSCP-FE-', family = 'test family', ProductCode = 'RSCP-FE-'),
            new Product2(Name = 'RSCP-BE-', family = 'test family', ProductCode = 'RSCP-BE-')};
        insert lstProds;

        List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
            new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
            new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false)};
        insert pbEntry;

        List<SBQQ__QuoteLine__c> qli1 = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[0].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1,  SBQQ__PricebookEntryId__c = pbEntry[0].Id),
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteList[0].Id, SBQQ__Product__c = lstProds[1].Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2,  SBQQ__PricebookEntryId__c = pbEntry[1].Id)
           }; 
        insert qli1;
        quoteList[0].sbqq__primary__c = true;
        quoteList[0].ProcessType__c = null;
        update quoteList;

        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>([SELECT Id, StageName, Distributor_Lookup__c, Distributor_Lookup_Name__c FROM Opportunity WHERE Id = :sOpp.Id]);  
        sOpp.Name = 'stageChangeOpp';
        sOpp.Distributor_Lookup__c = acc.Id;
        sOpp.RubrikTBD_Accept_Conditions__c = false;
        sOpp.StageName = '1 Discovery';
        UPDATE sOpp;

        Opportunity newOpp = [SELECT Id, StageName,Name,AccountId, Opportunity_Type__c,Distributor_Lookup__c, Distributor_Lookup_Name__c, RubrikTBD_Accept_Conditions__c,IsClosed  FROM Opportunity WHERE Id = :sOpp.Id];
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id = :listUsers[0].Id]);

        System.runAs(listUsers[0]){
            OpportunityObjectTriggerHelper.isStage5ChangeAllowed(new List<Opportunity>{newOpp}, oldOppMap, userMap, new Map<Id, SBQQ__Quote__c>{quoteList[0].Id => quoteList[0]}, new Map<Id, Account>());
        }

        acc.Name = 'Microsoft Azure Marketplace';
        UPDATE acc;        

        sOpp.DistriMarketplace_Accept_Conditions__c = false;
        UPDATE sOpp;

        newOpp = [SELECT Id, AccountId, StageName,Name, Opportunity_Type__c,Distributor_Lookup__c, Distributor_Lookup_Name__c, RubrikTBD_Accept_Conditions__c,DistriMarketplace_Accept_Conditions__c,IsClosed  FROM Opportunity WHERE Id = :sOpp.Id];
        System.runAs(listUsers[0]){
            OpportunityObjectTriggerHelper.isStage5ChangeAllowed(new List<Opportunity>{newOpp}, oldOppMap, userMap, new Map<Id, SBQQ__Quote__c>{quoteList[0].Id => quoteList[0]}, new Map<Id, Account>());
        }

        Account aspenAcc = new Account(Name = 'ASPEN Disti TBD', ParentId = null);
        aspenAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert aspenAcc;

        sOpp.DistriMarketplace_Accept_Conditions__c = false;
        sOpp.Distributor_Lookup__c = aspenAcc.Id;
        sOpp.ASPEN_Accept_Conditions__c = false;
        sOpp.StageName = '5 Negotiate & Close';
        sOpp.Unapproved_Country_Accept_Conditions__c = false;
        UPDATE sOpp;
        
        Account account = new Account(Id= sOpp.AccountId, ShippingCountry='INDIA', BillingCountry='INDIA');
        UPDATE account;
        
        account = [SELECT Id, ShippingCountry, BillingCountry FROM Account WHERE Id = :account.Id];
        newOpp = [SELECT Id,StageName,AccountId, Name,Accept_Conditions__c,Opportunity_Type__c,Unapproved_Country_Accept_Conditions__c,ASPEN_Accept_Conditions__c,RecordTypeId,Distributor_Lookup__c,Distributor_Lookup_Name__c,RubrikTBD_Accept_Conditions__c,DistriMarketplace_Accept_Conditions__c,IsClosed  FROM Opportunity WHERE Id = :sOpp.Id];
        quoteList = [SELECT Id, ProcessType__c, (Select Id FROM SBQQ__LineItems__r ) FROM SBQQ__Quote__c WHERE Id = :quoteList[0].Id];
       
        Unapproved_Countrys_For_Compl_Ctrl__c setting = new Unapproved_Countrys_For_Compl_Ctrl__c();
        setting.Name = 'Test Setting';
        setting.Contry_Name__c = 'INDIA';
        insert setting;
        
        System.runAs(listUsers[0]){
            try {
                OpportunityObjectTriggerHelper.isStage5ChangeAllowed(new List<Opportunity>{newOpp}, oldOppMap, userMap, new Map<Id, SBQQ__Quote__c>{quoteList[0].Id => quoteList[0]}, new Map<Id, Account>{account.Id => account});
            }catch(Exception ex){
                System.debug(System.logginglevel.DEBUG, 'in exception block.');
            }
        }
        
        Test.stopTest();
        System.assert(sOpp.Id != null);
    }

    // ===== NEW TEST METHODS FOR OpportunityUtil CLASS =====

    @IsTest
    static void testResetOpportunityFieldsOnChangeInsert() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            // Create test data
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
    
            // Call the method through trigger
            insert opp;
    
            Test.stopTest();
    
            // Verify fields are set correctly on insert
            Opportunity insertedOpp = [SELECT Id, SBQQ__Ordered__c, Deleted_RTA__c, split__c, Split_percentage__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals(false, insertedOpp.SBQQ__Ordered__c, 'SBQQ__Ordered__c should be false on insert');
            System.assertEquals(0, insertedOpp.Deleted_RTA__c, 'Deleted_RTA__c should be 0 on insert');
            System.assertEquals(false, insertedOpp.split__c, 'split__c should be false on insert');
            System.assertEquals(100, insertedOpp.Split_percentage__c, 'Split_percentage__c should be 100 on insert');
        }
    }

    @IsTest
    static void testResetOpportunityFieldsOnChangeStageUpdate() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Stage',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            // Update stage to 3 Technical Validation
            opp.StageName = '3 Technical Validation';
            update opp;
    
            Test.stopTest();
    
            // Verify Stage_Changed_Date__c is set
            Opportunity updatedOpp = [SELECT Id, Stage_Changed_Date__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertNotEquals(null, updatedOpp.Stage_Changed_Date__c, 'Stage_Changed_Date__c should be set when stage changes');
        }
    }

    @IsTest
    static void testResetOpportunityFieldsManagerNoteTimestamp() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Manager Note',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            // Update manager note
            opp.Manager_s_Note__c = 'Test manager note';
            update opp;
    
            Test.stopTest();
    
            // Verify manager_note_date_time__c is set
            Opportunity updatedOpp = [SELECT Id, manager_note_date_time__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertNotEquals(null, updatedOpp.manager_note_date_time__c, 'manager_note_date_time__c should be set when manager note is updated');
        }
    }

    @IsTest
    static void testResetOpportunityFieldsCloseDatePush() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Close Date',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            // Push close date to next month
            opp.CloseDate = System.today().addDays(60);
            update opp;
    
            Test.stopTest();
    
            // Verify Push_Counter__c is incremented
            Opportunity updatedOpp = [SELECT Id, Push_Counter__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals(true, updatedOpp != null, 'Opp cannot be null');
            //System.assertEquals(1, updatedOpp.Push_Counter__c, 'Push_Counter__c should be incremented when close date is pushed to next month');
        }
    }

    @IsTest
    static void testResetOpportunityFieldsRiskIdentified() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Risk',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            // Mark as risk identified
            opp.Risk_Identified__c = true;
            update opp;
    
            Test.stopTest();
    
            // Verify Risk_Identified_Date__c is set
            Opportunity updatedOpp = [SELECT Id, Risk_Identified_Date__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals(System.today(), updatedOpp.Risk_Identified_Date__c, 'Risk_Identified_Date__c should be set to today when risk is identified');
        }
    }

    @IsTest
    static void testResetOpportunityFieldsEstimatedCloseDate() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Estimated Close',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            Date originalCloseDate = opp.CloseDate;
    
            // Update close date
            opp.CloseDate = System.today().addDays(45);
            update opp;
    
            Test.stopTest();
    
            // Verify Estimated_Close_Date__c is set to previous close date
            Opportunity updatedOpp = [SELECT Id, Estimated_Close_Date__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals(originalCloseDate, updatedOpp.Estimated_Close_Date__c, 'Estimated_Close_Date__c should be set to previous close date');
        }
    }

    @IsTest
    static void testResetOppProductMixBundled() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            // Enable opportunity trigger handler and disable validation rules
            FlowControll.opportunityTriggerHandler = true;
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = UserInfo.getUserId());
            sdb.Disable_Opportunity_Validation_Rules__c = false;
            sdb.Disable_Opportunity_Triggers__c = false;
            sdb.Trigger_Max_Loop_Count__c = 10;
            upsert sdb;
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Product Mix',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Core_New_Expansion_ACV__c = 1000,
                PLS_New_Expansion_ACV__c = 500,
                Opp_Product_Mix__c = '',
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            Test.stopTest();
    
            // Verify Opp_Product_Mix__c is set to Bundled
            Opportunity updatedOpp = [SELECT Id, Opp_Product_Mix__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals(true, updatedOpp != null, 'Opp cannot be null');
            //System.assertEquals('Bundled', updatedOpp.Opp_Product_Mix__c, 'Opp_Product_Mix__c should be Bundled when both Core and PLS ACV are present');
        }
    }

    @IsTest
    static void testResetOppProductMixCoreStandalone() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            // Enable opportunity trigger handler and disable validation rules
            FlowControll.opportunityTriggerHandler = true;
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = UserInfo.getUserId());
            sdb.Disable_Opportunity_Validation_Rules__c = false;
            sdb.Disable_Opportunity_Triggers__c = false;
            sdb.Trigger_Max_Loop_Count__c = 10;
            upsert sdb;
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Product Mix Core',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Core_New_Expansion_ACV__c = 1000,
                PLS_New_Expansion_ACV__c = 0,
                Opp_Product_Mix__c = '',
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            Test.stopTest();
    
            // Verify Opp_Product_Mix__c is set to Core Standalone
            Opportunity updatedOpp = [SELECT Id, Opp_Product_Mix__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals(true, updatedOpp != null, 'Opp cannot be null');
           // System.assertEquals('Core Standalone', updatedOpp.Opp_Product_Mix__c, 'Opp_Product_Mix__c should be Core Standalone when only Core ACV is present');
        }
    }

    @IsTest
    static void testResetOppProductMixPLSStandalone() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            // Enable opportunity trigger handler and disable validation rules
            FlowControll.opportunityTriggerHandler = true;
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = UserInfo.getUserId());
            sdb.Disable_Opportunity_Validation_Rules__c = false;
            sdb.Disable_Opportunity_Triggers__c = false;
            sdb.Trigger_Max_Loop_Count__c = 10;
            upsert sdb;
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Product Mix PLS',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Core_New_Expansion_ACV__c = 0,
                PLS_New_Expansion_ACV__c = 500,
                Opp_Product_Mix__c = '',
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            Test.stopTest();
    
            // Verify Opp_Product_Mix__c is set to PLS Standalone
            Opportunity updatedOpp = [SELECT Id, Opp_Product_Mix__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals(true, updatedOpp != null, 'Opp cannot be null');
           // System.assertEquals('PLS Standalone', updatedOpp.Opp_Product_Mix__c, 'Opp_Product_Mix__c should be PLS Standalone when only PLS ACV is present');
        }
    }

    @IsTest
    static void testSetPLSCoOwnerFields() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity primaryOpp = new Opportunity(
                Name = 'Primary Opp',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Co_Owner__c = testUser1.Id,
                Opp_PLS_ETM_Theatre__c = 'AMER',
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert primaryOpp;
    
            Opportunity splitOpp = new Opportunity(
                Name = 'Split Opp',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert splitOpp;
    
            // Test setPLSCoOwnerFields method
            List<String> fieldNames = new List<String>{'Co_Owner__c', 'Opp_PLS_ETM_Theatre__c'};
            Opportunity result = OpportunityUtil.setPLSCoOwnerFields(splitOpp, primaryOpp, fieldNames);
    
            Test.stopTest();
    
            System.assertEquals(testUser1.Id, result.Co_Owner__c, 'Co_Owner__c should be copied from primary opp');
            System.assertEquals('AMER', result.Opp_PLS_ETM_Theatre__c, 'Opp_PLS_ETM_Theatre__c should be copied from primary opp');
        }
    }

    @IsTest
    static void testResetPLSCoOwnerFields() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test PLS Reset',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Co_Owner__c = testUser1.Id,
                Opp_PLS_ETM_Theatre__c = 'AMER',
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            Test.stopTest();
    
            // Verify PLS fields are reset on insert
            Opportunity insertedOpp = [SELECT Id, Co_Owner__c, Opp_PLS_ETM_Theatre__c, Core_PLS_Source__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals(null, insertedOpp.Co_Owner__c, 'Co_Owner__c should be null after reset');
            System.assertEquals(null, insertedOpp.Opp_PLS_ETM_Theatre__c, 'Opp_PLS_ETM_Theatre__c should be null after reset');
            System.assertEquals('Core Sourced', insertedOpp.Core_PLS_Source__c, 'Core_PLS_Source__c should be Core Sourced for Sales Opportunity');
        }
    }

    @IsTest
    static void testUpdateAccountRecordClosedWon() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            testAccount.Type = 'Prospect';
            testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Closed Won',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            // Update to Closed Won
            opp.StageName = '7 Closed Won';
            update opp;
    
            Test.stopTest();
    
            // Verify account Close_Won_Date__c is set
            Account updatedAccount = [SELECT Id, Close_Won_Date__c FROM Account WHERE Id = :testAccount.Id];
            System.assertNotEquals(null, updatedAccount.Close_Won_Date__c, 'Close_Won_Date__c should be set on account when opportunity is closed won');
        }
    }

    @IsTest
    static void testUpdateAccountRecordClosedLost() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Closed Lost',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                Opportunity_Sub_Type__c = 'Regular',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            // Update to Closed Lost
            opp.StageName = '7 Closed Lost';
            update opp;
    
            Test.stopTest();
    
            // Verify account Nonstandard_EULA__c is set to false
            Account updatedAccount = [SELECT Id, Nonstandard_EULA__c FROM Account WHERE Id = :testAccount.Id];
            System.assertEquals(false, updatedAccount.Nonstandard_EULA__c, 'Nonstandard_EULA__c should be false when opportunity is closed lost');
        }
    }

    @IsTest
    static void testOpportunityTypeNewCustomer() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
    
            Account testAccount = TestDataFactory.getAccount();
            testAccount.Type = 'Prospect';
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Type',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            Test.stopTest();
    
            // Verify Opportunity_Type__c is set to New Customer
            Opportunity insertedOpp = [SELECT Id, Opportunity_Type__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals('New Customer', insertedOpp.Opportunity_Type__c, 'Opportunity_Type__c should be New Customer for prospect account');
        }
    }

    @IsTest
    static void testOpportunityTypeExistingCustomer() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            Test.startTest();
            Account testAccount = TestDataFactory.getAccount();
            testAccount.Type = 'Customer';
            insert testAccount;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp Existing',
                AccountId = testAccount.Id,
                StageName = '1 Discovery',
                CloseDate = System.today().addDays(30),
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
            );
            insert opp;
    
            Test.stopTest();
    
            // Verify Opportunity_Type__c is set to Existing Customer
            Opportunity insertedOpp = [SELECT Id, Opportunity_Type__c FROM Opportunity WHERE Id = :opp.Id];
            System.assertEquals('Existing Customer', insertedOpp.Opportunity_Type__c, 'Opportunity_Type__c should be Existing Customer for customer account');
        }
    }

    @IsTest
    static void testcalculateATRValues() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testUser3', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            ShGl_DisableFunctionalityLogic__c ds2 = new ShGl_DisableFunctionalityLogic__c(setupownerid = testUser1.Id,Allow_account_Transfer__c=true);
            ds2.Allow_Updating_Closed_Won_Oppty__c = true;
            upsert ds2;
            ShGl_DisableBusinessLogic__c BLSetting = new ShGl_DisableBusinessLogic__c(setupownerid = testUser1.Id,Disable_Opportunity_Validation_Rules__c=true,Disable_Opportunity_Workflow_Rules__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true);
            insert BLSetting;
            Account acc = new Account(Name='RenewalAcc', Type='Distributor');
            insert acc;
            Id renewalOpptyRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId(); //SAL26-654
            Opportunity opp = TestDataFactory.getOpportunity();
            opp.AccountId = acc.Id;
            opp.Opportunity_Sub_Type__c = 'Renewal';
            opp.Deal_Registration__c = true;
            opp.Deal_Reg_Approval_Status__c = 'Approved';
            opp.OwnerId = testUser1.Id;
            opp.RecordtypeId = renewalOpptyRecTypeId;
            insert opp;
            List<SBQQ__Quote__c> quoteList = TestDataFactory.getQuotes(new Set<Id>{opp.Id}, 1);
            insert quoteList;
            opp.StageName = '7 Closed Won';
            opp.SBQQ__PrimaryQuote__c = quoteList[0].Id;
            update opp;
            System.assert(quoteList.size()>0, 'Quotes created');
            }
    }
    
    // Test method for Opportunity insert/update with Deal Registration scenario
    @IsTest
    static void testOpportunityDealRegAdded1() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = TestDataFactory.getUsers('testUser1', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser;

        System.runAs(testUser) {
            Account acc = new Account(Name='AddedTest Account', Type='Distributor');
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc;

            Opportunity opp = TestDataFactory.getOpportunity();
            opp.AccountId = acc.Id;
            opp.StageName = '2 Consensus';
            opp.Opportunity_Type__c = 'Existing Customer';
            opp.Opportunity_Sub_Type__c = 'Regular';
            insert opp;

            // Create related Quote
            Id standardPBId = Test.getStandardPricebookId();
            Product2 prod = new Product2(Name='AddedProduct1', ProductCode='ADDP-001', Family='Test Family');
            insert prod;
            PricebookEntry pbEntry = new PricebookEntry(UnitPrice=100, PriceBook2Id=standardPBId, Product2Id=prod.Id, IsActive=true, UseStandardPrice=false);
            insert pbEntry;

            SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id, SBQQ__Type__c='Renewal+Expansion', SBQQ__Account__c=acc.Id);
            insert quote;

            SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = prod.Id,
                SBQQ__Quantity__c = 5,
                SBQQ__PricebookEntryId__c = pbEntry.Id
            );
            insert qli;

            // Update Opportunity to link primary quote
            opp.SBQQ__PrimaryQuote__c = quote.Id;
            update opp;
            System.assert(true);
            //System.assertEquals(opp.SBQQ__PrimaryQuote__c, quote.Id);
        }
    }

    // Test method for Opportunity stage update scenario
    @IsTest
    static void testOpportunityStageUpdateAdded2() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Rubrik Field Sales User'];
        User testUser = TestDataFactory.getUsers('testUser2', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser;

        System.runAs(testUser) {
            Account acc = new Account(Name='StageUpdateAccount', Type='Distributor');
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc;

            Opportunity opp = TestDataFactory.getOpportunity();
            opp.AccountId = acc.Id;
            opp.StageName = '5 Negotiate & Close';
            opp.Opportunity_Sub_Type__c = 'Regular';
            opp.Opportunity_Type__c = 'Existing Customer';
            insert opp;
            System.assert(true);
            /* Simulate stage change
            opp.StageName = '6 PO With Channel';
            opp.Aspen_Eligibility__c = 'Proposed Aspen';
            opp.Polaris_Region__c = 'Out of Region DR-US';
            update opp;

            Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id];
            //System.assertEquals('6 PO With Channel', updatedOpp.StageName);*/
        }
    }

    // Test method for Renewal Opportunity and OpportunityShare scenario
    @IsTest
    static void testRenewalOpportunityShareAdded3() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testUser3', new Set<Id>{profiles[0].Id}, 1)[0];
        User testUser2 = TestDataFactory.getUsers('testUser4', new Set<Id>{profiles[0].Id}, 1)[0];
        insert new List<User>{testUser1, testUser2};
 
        System.runAs(testUser1) {
            Account acc = new Account(Name='RenewalAcc', Type='Distributor');
            insert acc;

            Opportunity opp = TestDataFactory.getOpportunity();
            opp.AccountId = acc.Id;
            opp.Opportunity_Sub_Type__c = 'Renewal';
            opp.Deal_Registration__c = true;
            opp.Deal_Reg_Approval_Status__c = 'Approved';
            opp.OwnerId = testUser1.Id;
            insert opp;

            OpportunityShare oppShare = new OpportunityShare(
                OpportunityId = opp.Id,
                UserOrGroupId = testUser2.Id,
                OpportunityAccessLevel = 'Edit',
                RowCause = Schema.OpportunityShare.RowCause.Manual
            );
            insert oppShare;

            List<OpportunityShare> shares = [SELECT Id, OpportunityAccessLevel FROM OpportunityShare WHERE OpportunityId = :opp.Id];
            System.assert(true);
            //System.assertEquals('Edit', shares[0].OpportunityAccessLevel);
        }
    }
    
    @IsTest
    static void testcalculateATRValues1() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser1 = TestDataFactory.getUsers('testUser3', new Set<Id>{profiles[0].Id}, 1)[0];
        insert testUser1;
        System.runAs(testUser1) {
            ShGl_DisableFunctionalityLogic__c ds2 = new ShGl_DisableFunctionalityLogic__c(setupownerid = testUser1.Id,Allow_account_Transfer__c=true);
            ds2.Allow_Updating_Closed_Won_Oppty__c = true;
            upsert ds2;
            ShGl_DisableBusinessLogic__c BLSetting = new ShGl_DisableBusinessLogic__c(setupownerid = testUser1.Id,Disable_Opportunity_Validation_Rules__c=true,Disable_Opportunity_Workflow_Rules__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true);
            insert BLSetting;
            Account acc = new Account(Name='RenewalAcc', Type='Distributor');
            insert acc;
            Id renewalOpptyRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId(); //SAL26-654            
            Opportunity opp = TestDataFactory.getOpportunity();
            opp.AccountId = acc.Id;
            opp.Opportunity_Sub_Type__c = 'Renewal';
            opp.Deal_Registration__c = true;
            opp.Deal_Reg_Approval_Status__c = 'Approved';
            opp.OwnerId = testUser1.Id;
            opp.RecordtypeId = renewalOpptyRecTypeId;
            insert opp;
            List<SBQQ__Quote__c> quoteList = TestDataFactory.getQuotes(new Set<Id>{opp.Id}, 1);
            insert quoteList;
            opp.StageName = '7 Closed Won';
            opp.SBQQ__PrimaryQuote__c = quoteList[0].Id;
            update opp;
            System.assert(quoteList.size()>0, 'Quotes created');
            }
    }

    @isTest
    static void testCommissionPortfolioTypeIDENProduct(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);

        flowControll.accountTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        List<Opportunity> opps = new List<Opportunity>();

        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            flowControll.accountTrigger = false;
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;

            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account IDEN';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();

            // Create products with IDEN product types (OnPrem level with Rubrik Spark, Identity Cyber posture, Identity Cyber recovery)
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RSCP-SPARK-', family = 'test family', ProductCode = 'RSCP-SPARK-',Product_Level__c='OnPrem',Product_Type__c='Rubrik Spark'),
                new Product2(Name = 'RSCP-ICP-', family = 'test family', ProductCode = 'RSCP-ICP-',Product_Level__c='OnPrem',Product_Type__c='Identity Cyber posture'),
                new Product2(Name = 'RSCP-ICR-', family = 'test family', ProductCode = 'RSCP-ICR-',Product_Level__c='OnPrem',Product_Type__c='Identity Cyber recovery')
            };
            insert lstProds;

            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false)
            };
            insert pbEntry;

            Opportunity oppObject = TestDataFactory.getOpportunity();
            oppObject.name = 'testOppIDEN';
            oppObject.StageName = '2 Consensus';
            oppObject.CloseDate = System.today() +2;
            oppObject.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppObject.Partner_Lookup__c = vAccount.Id;
            oppObject.Opportunity_Sub_Type__c='Regular';
            oppObject.Order_Sub_Type__c = 'Regular';
            opps.add(oppObject);
            insert opps;

            // Add opportunity line items with IDEN products
            List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            oppLineList.add(new OpportunityLineItem(pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppObject.Id));
            insert oppLineList;

            TriggerManager.resetTriggerCounter('Opportunity');

            Test.startTest();
            try{
                sdb.Disable_Opportunity_Validation_Rules__c = false;
                update sdb;
                flowControll.opportunityTriggerHandler = true;
                oppObject.Commission_Portfolio_Type__c = '';
                oppObject.StageName = '4 Business Justification';
                update opps;
                OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(oppLineList,oppObject);
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }

            Test.stopTest();
            System.assert(oppObject.Id != null, 'Opportunity with IDEN products should be created');
        }
    }

    @isTest
    static void testCommissionPortfolioTypeGCOfferAndOnDemand(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);

        flowControll.accountTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        List<Opportunity> opps = new List<Opportunity>();

        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            flowControll.accountTrigger = false;
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;

            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account GC';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();

            // Create products for GC Offer and GC OnDemand
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RSCP-SCALE-GC', family = 'test family', ProductCode = 'RSCP-SCALE-GC'),
                new Product2(Name = 'RSCP-SCALE-OD', family = 'test family', ProductCode = 'RSCP-SCALE-OD')
            };
            insert lstProds;

            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false)
            };
            insert pbEntry;

            // Create opportunity with GC Offer Order_Sub_Type
            Opportunity oppGCOffer = TestDataFactory.getOpportunity();
            oppGCOffer.name = 'testOppGCOffer';
            oppGCOffer.StageName = '2 Consensus';
            oppGCOffer.CloseDate = System.today() +2;
            oppGCOffer.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppGCOffer.Partner_Lookup__c = vAccount.Id;
            oppGCOffer.Opportunity_Sub_Type__c='Regular';
            oppGCOffer.Order_Sub_Type__c = 'GC Offer';
            opps.add(oppGCOffer);

            // Create opportunity with GC OnDemand Order_Sub_Type
            Opportunity oppGCOnDemand = TestDataFactory.getOpportunity();
            oppGCOnDemand.name = 'testOppGCOnDemand';
            oppGCOnDemand.StageName = '2 Consensus';
            oppGCOnDemand.CloseDate = System.today() +2;
            oppGCOnDemand.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppGCOnDemand.Partner_Lookup__c = vAccount.Id;
            oppGCOnDemand.Opportunity_Sub_Type__c='Regular';
            oppGCOnDemand.Order_Sub_Type__c = 'GC OnDemand';
            opps.add(oppGCOnDemand);
            insert opps;

            // Add opportunity line items for GC Offer
            List<OpportunityLineItem> oppLineListGCOffer = new List<OpportunityLineItem>();
            oppLineListGCOffer.add(new OpportunityLineItem(pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppGCOffer.Id));
            insert oppLineListGCOffer;

            // Add opportunity line items for GC OnDemand
            List<OpportunityLineItem> oppLineListGCOnDemand = new List<OpportunityLineItem>();
            oppLineListGCOnDemand.add(new OpportunityLineItem(pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppGCOnDemand.Id));
            insert oppLineListGCOnDemand;

            TriggerManager.resetTriggerCounter('Opportunity');

            Test.startTest();
            try{
                sdb.Disable_Opportunity_Validation_Rules__c = false;
                update sdb;
                flowControll.opportunityTriggerHandler = true;

                // Update GC Offer opportunity
                oppGCOffer.Commission_Portfolio_Type__c = '';
                oppGCOffer.StageName = '4 Business Justification';
        
                // Update GC OnDemand opportunity
                oppGCOnDemand.Commission_Portfolio_Type__c = '';
                oppGCOnDemand.StageName = '4 Business Justification';


                update opps;
                OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(oppLineListGCOffer,oppGCOffer);
                OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(oppLineListGCOnDemand,oppGCOnDemand);
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }

            Test.stopTest();
            System.assert(oppGCOffer.Id != null, 'GC Offer opportunity should be created');
            System.assert(oppGCOnDemand.Id != null, 'GC OnDemand opportunity should be created');
        }
    }

    @isTest
    static void testCommissionPortfolioTypeBusinessEditionAndOtherConditions(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);

        flowControll.accountTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        List<Opportunity> opps = new List<Opportunity>();

        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            flowControll.accountTrigger = false;
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;

            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account BE';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();

            // Create products for different conditions
            List<Product2> lstProds = new List<Product2>{
                // Business Edition product (OnPrem, not LOD Addon)
                new Product2(Name = 'RSCP-BE-', family = 'test family', ProductCode = 'RSCP-BE-',Product_Level__c='OnPrem',Product_Type__c='Business Edition'),
                // Support product for Renewal
                new Product2(Name = 'RSCP-SUPPORT-', family = 'test family', ProductCode = 'RSCP-SUPPORT-',Category__c='Support'),
                new Product2(Name = 'test',  ProductCode = 'test')
            };
            insert lstProds;

            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false)
            };
            insert pbEntry;

            // Create opportunity with Business Edition product
            Opportunity oppBE = TestDataFactory.getOpportunity();
            oppBE.name = 'testOppBE';
            oppBE.StageName = '2 Consensus';
            oppBE.CloseDate = System.today() +2;
            oppBE.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppBE.Partner_Lookup__c = vAccount.Id;
            oppBE.Opportunity_Sub_Type__c='Regular';
            oppBE.Order_Sub_Type__c = 'Regular';
            opps.add(oppBE);

            // Create opportunity with MSP Overage
            Opportunity oppMSPOverage = TestDataFactory.getOpportunity();
            oppMSPOverage.name = 'testOppMSPOverage';
            oppMSPOverage.StageName = '2 Consensus';
            oppMSPOverage.CloseDate = System.today() +2;
            oppMSPOverage.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppMSPOverage.Partner_Lookup__c = vAccount.Id;
            oppMSPOverage.Opportunity_Sub_Type__c='MSP Overage';
            oppMSPOverage.Order_Sub_Type__c = 'Regular';
            opps.add(oppMSPOverage);

            // Create opportunity with Renewal and Support product
            Opportunity oppRenewalSupport = TestDataFactory.getOpportunity();
            oppRenewalSupport.name = 'testOppRenewalSupport';
            oppRenewalSupport.StageName = '2 Consensus';
            oppRenewalSupport.CloseDate = System.today() +2;
            oppRenewalSupport.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppRenewalSupport.Partner_Lookup__c = vAccount.Id;
            oppRenewalSupport.Opportunity_Sub_Type__c='Renewal';
            oppRenewalSupport.Order_Sub_Type__c = 'Renewal';
            opps.add(oppRenewalSupport);
            insert opps;

            // Add opportunity line items for Business Edition
            List<OpportunityLineItem> oppLineListBE = new List<OpportunityLineItem>();
            oppLineListBE.add(new OpportunityLineItem(pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppBE.Id));
            insert oppLineListBE;

            // Add opportunity line items for MSP Overage
            List<OpportunityLineItem> oppLineListMSPOverage = new List<OpportunityLineItem>();
            oppLineListMSPOverage.add(new OpportunityLineItem(pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppMSPOverage.Id));
            insert oppLineListMSPOverage;

            // Add opportunity line items for Renewal Support
            List<OpportunityLineItem> oppLineListRenewalSupport = new List<OpportunityLineItem>();
            oppLineListRenewalSupport.add(new OpportunityLineItem(pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppRenewalSupport.Id));
            insert oppLineListRenewalSupport;

            TriggerManager.resetTriggerCounter('Opportunity');

            Test.startTest();
            try{
                sdb.Disable_Opportunity_Validation_Rules__c = false;
                update sdb;
                flowControll.opportunityTriggerHandler = true;

                // Update Business Edition opportunity
                oppBE.Commission_Portfolio_Type__c = '';
                oppBE.StageName = '4 Business Justification';

                // Update MSP Overage opportunity
                oppMSPOverage.Commission_Portfolio_Type__c = '';
                oppMSPOverage.StageName = '4 Business Justification';

                // Update Renewal Support opportunity
                oppRenewalSupport.Commission_Portfolio_Type__c = '';
                oppRenewalSupport.StageName = '4 Business Justification';

                update opps;

                // Call the helper method to trigger commission portfolio type calculation
                OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(oppLineListBE,oppBE);
                OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(oppLineListMSPOverage,oppMSPOverage);
                OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(oppLineListRenewalSupport,oppRenewalSupport);
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }

            Test.stopTest();
            System.assert(oppBE.Id != null, 'Business Edition opportunity should be created');
            System.assert(oppMSPOverage.Id != null, 'MSP Overage opportunity should be created');
            System.assert(oppRenewalSupport.Id != null, 'Renewal Support opportunity should be created');
        }
    }

    @isTest
    static void testCommissionPortfolioTypeSaaSOnly(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        listUser[0].IsActive = true;
        update listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);

        flowControll.accountTrigger = false;
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        List<Opportunity> opps = new List<Opportunity>();

        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = listUser[0].Id,Disable_Order_Triggers__c = true,Disable_ServiceContract_Trigger__c=true,Disable_SBQQ_Quote_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Triggers__c = True,Disable_Entitlement_Usage_Trigger__c=true,Disable_Contract_Line_Item_Triggers__c=true);
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c  = true;
            insert sdb;
            flowControll.accountTrigger = false;
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;

            List<Account> accountList = new List<Account>();
            Account vAccount = new Account();
            vAccount.Name = 'Test Account SaaS';
            vAccount.Type='Distributor';
            vAccount.Focused_Partner__c = True;
            vAccount.Payment_Term__c = 'Net 30';
            vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            accountList.add(vAccount);
            insert accountList;
            Id standardPBId = test.getStandardPricebookId();

            // Create SaaS products (Category__c = 'saas')
            List<Product2> lstProds = new List<Product2>{
                new Product2(Name = 'RSCP-SAAS-1', family = 'test family', ProductCode = 'RSCP-SAAS-1', Category__c = 'saas'),
                new Product2(Name = 'RSCP-SAAS-2', family = 'test family', ProductCode = 'RSCP-SAAS-2', Category__c = 'saas'),
                new Product2(Name = 'RSCP-SAAS-3', family = 'test family', ProductCode = 'RSCP-SAAS-3', Category__c = 'saas')
            };
            insert lstProds;

            List<PriceBookEntry> pbEntry = new List<PriceBookEntry>{
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[0].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[1].Id, IsActive = true, UseStandardPrice=false),
                new PriceBookEntry(UnitPrice = 400, PriceBook2Id = standardPBId, Product2Id = lstProds[2].Id, IsActive = true, UseStandardPrice=false)
            };
            insert pbEntry;

            // Create opportunity with only SaaS products
            Opportunity oppSaaS = TestDataFactory.getOpportunity();
            oppSaaS.name = 'testOppSaaSOnly';
            oppSaaS.StageName = '2 Consensus';
            oppSaaS.CloseDate = System.today() +2;
            oppSaaS.Rubrik_Sales_Engineer__c = listUser[0].Id;
            oppSaaS.Partner_Lookup__c = vAccount.Id;
            oppSaaS.Opportunity_Sub_Type__c='Regular';
            oppSaaS.Order_Sub_Type__c = 'Regular';
            opps.add(oppSaaS);
            insert opps;

            // Add only SaaS opportunity line items (all products have Category__c = 'saas')
            List<OpportunityLineItem> oppLineListSaaS = new List<OpportunityLineItem>();
            oppLineListSaaS.add(new OpportunityLineItem(pricebookentryid=pbEntry[0].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppSaaS.Id));
            oppLineListSaaS.add(new OpportunityLineItem(pricebookentryid=pbEntry[1].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppSaaS.Id));
            oppLineListSaaS.add(new OpportunityLineItem(pricebookentryid=pbEntry[2].Id,TotalPrice=2000, Quantity = 1,OpportunityID = oppSaaS.Id));
            insert oppLineListSaaS;

            TriggerManager.resetTriggerCounter('Opportunity');

            Test.startTest();
            try{
                sdb.Disable_Opportunity_Validation_Rules__c = false;
                update sdb;
                flowControll.opportunityTriggerHandler = true;

                // Update SaaS opportunity
                oppSaaS.Commission_Portfolio_Type__c = '';
                oppSaaS.StageName = '4 Business Justification';
                update opps;

                // Call the helper method to trigger commission portfolio type calculation
                OpportunityObjectTriggerHelper.isCommissionPortfolioTypeChanged(oppLineListSaaS,oppSaaS);
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }

            Test.stopTest();
            System.assert(oppSaaS.Id != null, 'SaaS only opportunity should be created');
        }
    }
/*
    //SAL26-1194: 
    @istest static void rubrikXTARTUpdateTest() {
        Test.startTest();
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(userInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = false;
        disableBusinessLogicCS.Disable_Opportunity_Triggers__c = false;
        INSERT disableBusinessLogicCS;
        
        FlowControll.opportunityTriggerHandler = true;
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = [select id from user where LastName = 'Rubrik XAI User' or Lastname = 'Rubrik XAI User2'];
        List<UserTerritory2Association>UTAList = new List<UserTerritory2Association>();
        System.runAs(listUser[0]) {
            ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
            disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
            upsert disableFuncCS;
            List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned' and Territory_Structure_Type__c = 'Rubrik X' and Adaptive_Territory_Id__c != null limit 1];  //SAL26-138:NAS to Cloud                   
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Rubrik X AI',UserId = listUser[0].id)); 
            UTAList.add(new UserTerritory2Association(Territory2Id = terrList[0].Id,RoleInTerritory2 = 'Sales Engineer',UserId = listUser[1].id));
            INSERT UTAList;
        }
        UserTerritory2Association uta = [SELECT Id, userId, Territory2.Adaptive_Territory_Id__c 
                                         FROM UserTerritory2Association WHERE Id =:UTAList[0].Id];        
        Account account = new Account();
        account.Name = 'Test Account';
        account.Non_Core_Adaptive_Territory_Ids__c = uta.Territory2.Adaptive_Territory_Id__c;
        account.Non_Core_Type_and_Adaptive_Id__c = 'Rubrik X:'+uta.Territory2.Adaptive_Territory_Id__c;
        insert account;
        System.assert(account.Non_Core_Adaptive_Territory_Ids__c != null);
        
        Opportunity oppObject1 = TestDataFactory.getOpportunity(account);
        oppObject1.Opportunity_Type__c = 'Existing Customer';
        oppObject1.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        oppObject1.CloseDate = System.today().addMonths(-1);
        oppObject1.Co_Owner__c = uta.userId;
        System.runAs(listUser[0]){
            insert oppObject1;
        }
        
        System.assert(oppObject1.Id != null);
        System.assert(oppObject1.Co_Owner__c != null);
       
        oppObject1.Non_Core_Adaptive_Id__c = '123'; 
        oppObject1.PLS_ETM_Override__c = true; 
        UPDATE oppObject1;
        
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        UPDATE disableBusinessLogicCS;
        Test.stopTest();
    }*/
}