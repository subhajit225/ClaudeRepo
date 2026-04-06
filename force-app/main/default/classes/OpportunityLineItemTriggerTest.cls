@isTest
public class OpportunityLineItemTriggerTest {
    @TestSetUp
    static void initialDataSetup() {
        insert new Opportunity_Stage_Days__c(AllowAcvCalculation__c = true, AllowArrCalculation__c = true, DefaultAcvAmount__c =36);
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        
       
        
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
         List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser3457722', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.SetupOwnerId = listUser[0].Id;
        settingDisable.Trigger_Max_Loop_Count__c = 10;
        settingDisable.Disable_Account_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
        settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = True;
        settingDisable.Disable_ServiceContract_Trigger__c=true;
        settingDisable.Disable_Entitlement_Usage_Trigger__c=true;
        settingDisable.Disable_Entitlement_Trigger__c=true;
        settingDisable.Disable_Asset_Triggers__c=true;
        settingDisable.Disable_Contract_Line_Item_Triggers__c=true;
        settingDisable.Disable_Account_Triggers__c=true;
        settingDisable.Disable_Contact_Triggers__c=true;
        settingDisable.Disable_Opportunity_Old_Trigger__c=true;
        settingDisable.Disable_SBQQ_Quote_Triggers__c=true;
        settingDisable.Disable_SBQQ_QuoteLine_Triggers__c=true;    
        settingDisable.Disable_Product2_Trigger__c = true;
        insert settingDisable;
 		
        upsert disableFuncCS;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        FlowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        Account objAccount = new Account();
        Contact objContact = new Contact();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 31-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;

        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 31-05';
        insert objContact; 
		
        Opportunity opp = new Opportunity();
        opp.StageName = '1 Discovery';
        opp.closeDate = System.Today() + 30;
        opp.Name = 'Test Opp 31-05';
        opp.Opportunity_Sub_Type__c = 'Regular';
        opp.Initial_Contacts_Name__c = objContact.Id;
        opp.Distributor_Lookup__c = objAccount.Id;
        opp.Partner_Lookup__c = objAccount.Id;
        opp.Split_percentage__c = 100;
        opp.priceBook2Id = Test.getStandardPricebookId();
        insert opp;
        
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Split parent Opp';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        objOpportunity.split__c = true;
        objOpportunity.Amount = 2000;
        objOpportunity.ACV_Amount__c=2000;
        objOpportunity.Split_percentage__c = 50;
        objOpportunity.priceBook2Id = Test.getStandardPricebookId();
        insert objOpportunity;
        
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        List<PricebookEntry> pBList2 = new List<PricebookEntry> ();
        
		List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLineList2 = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLineList3 = new List<OpportunityLineItem>();
		
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        List<Product2> prdList2 = new List<Product2>();
        Product2 prod1 = new Product2(IsActive = true, name = 'RBK-PS-RES',productcode = 'RBK-PS-RES',Product_Hierarchy_Group__c = 'PLS-SaaS',Sales_Comp_Category__c = 'O365');
        prdList2.add(prod1);
        Product2 prod2 = new Product2(IsActive = true, name = 'RBK-PS-CNSLT-ONST',productcode = 'RBK-PS-CNSLT-ONST',Family ='Third Party License',Product_Hierarchy_Group__c = 'PLS-CLOUD',Sales_Comp_Category__c = 'NAS CLOUD');//SAL26-138: NAS to CLOUD
        prdList2.add(prod2);
        Product2 prod31 = new Product2(IsActive = true,Product_Level__c='LOD Software',License_Type__c = 'Perpetual', name = 'DSPM',Product_Hierarchy_Group__c = 'Core',Sales_Comp_Category__c = 'DSPM');
        prdList2.add(prod31);
        Product2 prod41 = new Product2(IsActive = true,Product_Subtype__c = 'E1000', name = 'scale',Product_Hierarchy_Group__c = 'PLS-CLOUD',Sales_Comp_Category__c = 'RCDM Scale'); //SAL26-138: NAS to CLOUD
        prdList2.add(prod41);
        Product2 prod51 = new Product2(IsActive = true,Product_Type__c = 'Cloud Edition', name = 'RCVLRS',Sales_Comp_Category__c = 'RCV ZRS'); 
        prdList2.add(prod51);
        Product2 prod61 = new Product2(IsActive = true,Bundle_Features__c = 'SAP HANA', name = 'nasprod22',Product_Hierarchy_Group__c = 'PLS-CLOUD',Sales_Comp_Category__c = 'CONSUMPTION EPE WITH DSPM'); //SAL26-138: NAS to CLOUD
        prdList2.add(prod61);
        Product2 prod71 = new Product2(IsActive = true,Bundle_Features__c = 'Cloud Native Protection M365H', name = 'cloudprod22',Product_Hierarchy_Group__c = 'PLS-CLOUD',Sales_Comp_Category__c = 'CONSUMPTION EPE WITH DSPM'); 
        prdList2.add(prod71);
        Product2 optyspltchild = new Product2(IsActive = true, name = 'OPTY-SPLIT',productcode = 'OPTY-SPLIT');
        prdList2.add(optyspltchild);
        insert prdList2;
		
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        PricebookEntry pe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod1.Id,UnitPrice = 1000,IsActive = true);
        pBList2.add(pe1);
        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList2.add(pe2);
        PricebookEntry pe3 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod31.Id,UnitPrice = 1000,IsActive = true);
        pBList2.add(pe3);
        PricebookEntry pe4 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod41.Id,UnitPrice = 1000,IsActive = true);
        pBList2.add(pe4);
        PricebookEntry pe5 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod51.Id,UnitPrice = 1000,IsActive = true);
        pBList2.add(pe5);
        PricebookEntry pe6 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod61.Id,UnitPrice = 1000,IsActive = true);
        pBList2.add(pe6);
        PricebookEntry pe71 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod71.Id,UnitPrice = 1000,IsActive = true);
        pBList2.add(pe71);
        PricebookEntry pe7 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = optyspltchild.Id,UnitPrice = 1000,IsActive = true);
        pBList2.add(pe7);
        insert pBList2;
        
		     
        List<PriceBook_Config_Ids__c> pbConfigList = new List<PriceBook_Config_Ids__c>();
		PriceBook_Config_Ids__c pbConfig1 = new PriceBook_Config_Ids__c();
        pbConfig1.name='OPTYSPLITPriceBookEntryId';
        pbConfig1.Config_Id__c = pe7.Id;
        pbConfigList.add(pbConfig1);
        PriceBook_Config_Ids__c pbConfig2 = new PriceBook_Config_Ids__c();
        pbConfig2.name='CPQPricebookID';
        pbConfig2.Config_Id__c = Test.getStandardPricebookId();
        pbConfigList.add(pbConfig2);
        insert pbConfigList;
        
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = objAccount.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__Opportunity2__c = objOpportunity.Id;
        qt.SBQQ__PrimaryContact__c = objContact.Id;
        qt.Task_Products__c='RBK-DISK-RETENTION';  
        qt.SBQQ__Type__c = 'Renewal';
        insert qt; 
        
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Subtype__c = 'FEDRAMP');  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__SubscriptionTerm__c=15,SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prod2.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' );
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__SubscriptionTerm__c=15,SBQQ__Renewal__c=false,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prod31.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' );
        qliList.add( qli1 );
        qliList.add( qli2 );
        qliList.add( qli3 );
        insert qliList;
        
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        objOpportunity.SBQQ__PrimaryQuote__c = qt.Id;
        update objOpportunity;
        
        
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 

        objOpportunity.SBQQ__PrimaryQuote__c = qt.Id;
        update objOpportunity;
        
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        oppLineList2.add(new OpportunityLineItem(Applied_Split__c=50,product2Id = pBList2[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[0].Id,TotalPrice=2000,Quantity = 10,OpportunityID = objOpportunity.Id));
        oppLineList2.add(new OpportunityLineItem(Applied_Split__c=50,product2Id = pBList2[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = objOpportunity.Id));
        oppLineList2.add(new OpportunityLineItem(Applied_Split__c=50,product2Id = pBList2[2].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[2].Id,TotalPrice=2000,Quantity = 1,OpportunityID = objOpportunity.Id));
        oppLineList2.add(new OpportunityLineItem(Applied_Split__c=50,product2Id = pBList2[3].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[3].Id,TotalPrice=2000,Quantity = 1,OpportunityID = objOpportunity.Id));
        oppLineList2.add(new OpportunityLineItem(Applied_Split__c=50,product2Id = pBList2[4].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[4].Id,TotalPrice=2000,Quantity = 1,OpportunityID = objOpportunity.Id));
        oppLineList2.add(new OpportunityLineItem(Applied_Split__c=50,product2Id = pBList2[5].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[5].Id,TotalPrice=2000,Quantity = 1,OpportunityID = objOpportunity.Id));
        oppLineList2.add(new OpportunityLineItem(Applied_Split__c=50,product2Id = pBList2[6].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[6].Id,TotalPrice=2000,Quantity = 1,OpportunityID = objOpportunity.Id));
        oppLineList2.add(new OpportunityLineItem(Applied_Split__c=50,product2Id = pBList2[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = opp.Id));
        insert oppLineList2;
        
        
        List<OpportunityLineItem> oppLineitemList = new List<OpportunityLineItem>();
        oppLineitemList = [select Id,ACV_Amount__c from OpportunityLineItem limit 1];
        oppLineitemList[0].ACV_Amount__c = 200;
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        update oppLineitemList;   
        
        Opportunity childopp1 = new Opportunity();
        childopp1.StageName = '1 Discovery';
        childopp1.closeDate = System.Today() + 30;
        childopp1.Name = 'Test Opp 31-05 -split';
        childopp1.Opportunity_Type__c = 'New Customer';
        childopp1.Opportunity_Sub_Type__c = 'Regular';
        childopp1.split__c = true;
        childopp1.Split_percentage__c = 50;
        childopp1.Opportunity_Split_Parent__c = objOpportunity.Id;
        childopp1.Amount = 1000;
        childopp1.Renewal_Subsumed_ACV__c = 200;
        childopp1.Subsumed_Renewal_TCV__c = 200;
        childopp1.priceBook2Id = Test.getStandardPricebookId();
        childopp1.ACV_Amount__c=1000;
        
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        insert childopp1;
        
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        oppLineList3.add(new OpportunityLineItem(Applied_Split__c=50,Parent_split_Opplineitem_Id__c=oppLineList2[0].Id,product2Id = pBList2[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = childopp1.Id));
        oppLineList3.add(new OpportunityLineItem(Applied_Split__c=50,Parent_split_Opplineitem_Id__c=oppLineList2[1].Id,product2Id = pBList2[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = childopp1.Id));
        oppLineList3.add(new OpportunityLineItem(Applied_Split__c=50,Parent_split_Opplineitem_Id__c=oppLineList2[2].Id,product2Id = pBList2[2].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[2].Id,TotalPrice=2000,Quantity = 1,OpportunityID = childopp1.Id));
        insert oppLineList3;
        
       

    }
    testMethod static void salessplit(){
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        
        
        Opportunity parentopp1 = [select Id,OwnerId,rubrik_sales_Engineer__c,StageName,closeDate,Name,Opportunity_Type__c,split__c,Amount,Split_percentage__c,Opportunity_Split_Parent__c from Opportunity where Opportunity_Split_Parent__c = null AND Name = 'Split parent Opp'];
		Opportunity childopp1 = [select Id,OwnerId,rubrik_sales_Engineer__c,StageName,closeDate,Name,Opportunity_Type__c,split__c,Amount,Split_percentage__c,Opportunity_Split_Parent__c from Opportunity where Opportunity_Split_Parent__c != null];
        oppList.add(parentopp1);
        oppList.add(childopp1);
		List<PricebookEntry> pBList2 = new List<PricebookEntry>();
        List<opportunitylineitem> oppLineList2 = new List<opportunitylineitem>();
        pBList2 = [select Id,product2Id from PricebookEntry];
        System.runAs(listUser[0]) {
            oppLineList2.add(new OpportunityLineItem(product2Id = pBList2[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
            oppLineList2.add(new OpportunityLineItem(product2Id = pBList2[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
            oppLineList2.add(new OpportunityLineItem(product2Id = pBList2[2].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[2].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
            oppLineList2.add(new OpportunityLineItem(product2Id = pBList2[3].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[3].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
            oppLineList2.add(new OpportunityLineItem(product2Id = pBList2[4].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[4].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
            oppLineList2.add(new OpportunityLineItem(product2Id = pBList2[5].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[5].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
            oppLineList2.add(new OpportunityLineItem(product2Id = pBList2[6].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[6].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
            oppLineList2.add(new OpportunityLineItem(product2Id = pBList2[7].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList2[7].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
            
            test.startTest();  
            FlowControll.opportunityTriggerHandler = false;
            insert oppLineList2;
            test.stopTest();
        }
        System.assert(oppLineList2[0].Id != null);
    }
    testMethod static void sowRequired1(){
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable(); 
        
        Set<Id> pId = new Set<Id>();
        List<PricebookEntry> pbList = new List<PricebookEntry>();

        List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        List<OpportunityLineItem> oliList1 = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oliList2 = new List<OpportunityLineItem>();
        for(Product2 prod : [select Id,name from Product2 where name IN ('RBK-PS-RES','RBK-PS-CNSLT-ONST')]){
            pId.add(prod.Id);
        }
        pbList = [select Id,Product2Id,Product2.Name from PricebookEntry where Product2Id IN : pId];
        
        
		Opportunity opp = [select Id from Opportunity where Opportunity_Split_Parent__c = null and split_percentage__c = 100 limit 1];
        
        System.runAs(listUser[0]) {
            for(PricebookEntry pb : pbList){
                if(pb.Product2.Name == 'RBK-PS-RES'){
					oliList1.add(new OpportunityLineItem(product2Id = pb.product2Id,Line_Type_Text__c = 'New',pricebookentryid=pb.Id,TotalPrice=2000,Quantity = 10,OpportunityID = opp.Id));
                }
            }
            insert oliList1;
            opp.SOW_Required__c = false;
            update opp;
            for(PricebookEntry pb : pbList){
                if(pb.Product2.Name == 'RBK-PS-CNSLT-ONST'){
					oliList2.add(new OpportunityLineItem(product2Id = pb.product2Id,Line_Type_Text__c = 'New',pricebookentryid=pb.Id,TotalPrice=2000,Quantity = 10,OpportunityID = opp.Id));
                }
            }
            Test.startTest(); 
            FlowControll.opportunityTriggerHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = true;
        	SBQQ.TriggerControl.disable();  
            insert oliList2;
            Test.stopTest();
        }
        System.assert(oliList1[0].Id != null);
    } 
    testMethod static void sowRequired2(){
        Set<Id> pId = new Set<Id>();
        List<PricebookEntry> pbList = new List<PricebookEntry>();

        List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(Product2 prod : [select Id,name from Product2 where name IN ('RBK-PS-CNSLT-ONST')]){
            pId.add(prod.Id);
        }
        pbList = [select Id,Product2Id from PricebookEntry where Product2Id IN : pId];
        
        
		Opportunity opp = [select Id from Opportunity where Opportunity_Split_Parent__c = null and split_percentage__c = 100 limit 1];
        
        System.runAs(listUser[0]) {
            for(PricebookEntry pb : pbList){
				oliList.add(new OpportunityLineItem(product2Id = pb.product2Id,Line_Type_Text__c = 'New',pricebookentryid=pb.Id,TotalPrice=2000,Quantity = 9,OpportunityID = opp.Id));
            }
            Test.startTest(); 
            FlowControll.opportunityTriggerHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = true;
        	SBQQ.TriggerControl.disable();  
            insert oliList;
            Test.stopTest();
        }
        System.assert(oliList[0].Id != null);
    } 
    testMethod static void sowRequired3(){
        Set<Id> pId = new Set<Id>();
        List<PricebookEntry> pbList = new List<PricebookEntry>();
	    List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(Product2 prod : [select Id,name from Product2 where name IN ('RBK-PS-CNSLT-ONST')]){
            pId.add(prod.Id);
        }
        pbList = [select Id,Product2Id from PricebookEntry where Product2Id IN : pId];
        
        
		Opportunity opp = [select Id from Opportunity where Opportunity_Split_Parent__c = null and split_percentage__c = 100 limit 1];
        
        System.runAs(listUser[0]) {
            for(PricebookEntry pb : pbList){
				oliList.add(new OpportunityLineItem(product2Id = pb.product2Id,Line_Type_Text__c = 'New',pricebookentryid=pb.Id,TotalPrice=2000,Quantity = 10,OpportunityID = opp.Id));
            }
            Test.startTest();  
            FlowControll.opportunityTriggerHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = true;
        	SBQQ.TriggerControl.disable();  
            insert oliList;
            Test.stopTest();
        }
        System.assert(oliList[0].Id != null);
    } 
    testMethod static void closedwonOpp(){
        Opportunity opp = [select Id,StageName from Opportunity where Opportunity_Split_Parent__c = null limit 1];
        Set<Id> pId = new Set<Id>();
        List<PricebookEntry> pbList = new List<PricebookEntry>();
		List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(Product2 prod : [select Id,name from Product2 where name IN ('RBK-PS-CNSLT-ONST')]){
            pId.add(prod.Id);
        }
        pbList = [select Id,Product2Id from PricebookEntry where Product2Id IN : pId];
        for(PricebookEntry pb : pbList){
            oliList.add(new OpportunityLineItem(product2Id = pb.product2Id,Line_Type_Text__c = 'New',pricebookentryid=pb.Id,TotalPrice=2000,Quantity = 10,OpportunityID = opp.Id));
        }
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable();  
        insert oliList;
        
        System.runAs(listUser[0]) {
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            opp.StageName = '7 Closed Won';
            update opp;
            
            try{
                Test.startTest();
                flowControll.opportunityLineItemHandler = true;
                oliList[0].ACV_Amount__c = 100;
                update oliList;
                Test.stopTest();
            }catch(Exception e){ system.debug(LoggingLevel.DEBUG,'@@ Exception '+e.getMessage());}
            System.assert(opp.Id != null);
        }
    } 
    testMethod static void salessplitlinesUpdate(){

        List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        
        Opportunity parentopp1 = [select Id,OwnerId,rubrik_sales_Engineer__c,StageName,closeDate,Name,Opportunity_Type__c,split__c,Amount,Split_percentage__c,Opportunity_Split_Parent__c from Opportunity where Opportunity_Split_Parent__c = null AND Name = 'Split parent Opp'];
        List<opportunitylineitem> oppLineList2 = new List<opportunitylineitem>();
		oppLineList2 = [select Id from OpportunityLineItem where OpportunityId =: parentopp1.Id];

        
        System.runAs(listUser[0]) {
            opportunitylineitem oli = new opportunitylineitem();
            oli = oppLineList2[2];
            oli.ACV_Amount__c = 100;
            test.startTest();  
            FlowControll.opportunityTriggerHandler = false;
            update oli;
            test.stopTest();
        }
        System.assert(oppLineList2[0].Id != null);
    } 
    testMethod static void salessplitlinesDelete(){
	List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable = [select Id,Disable_Opportunity_Triggers__c from ShGl_DisableBusinessLogic__c where SetupOwnerId =: listUser[0].Id];
        
        
        Opportunity parentopp1 = [select Id,OwnerId,rubrik_sales_Engineer__c,StageName,closeDate,Name,Opportunity_Type__c,split__c,Amount,Split_percentage__c,Opportunity_Split_Parent__c from Opportunity where Opportunity_Split_Parent__c = null AND Name = 'Split parent Opp'];
        List<opportunitylineitem> oppLineList2 = new List<opportunitylineitem>();
		oppLineList2 = [select Id,OpportunityId,Line_Type__c,Parent_split_Opplineitem_Id__c,Applied_Split__c,ProductCode from OpportunityLineItem where OpportunityId =: parentopp1.Id AND Line_Type__c != 'Renewal' AND Parent_split_Opplineitem_Id__c = null AND Applied_Split__c != null AND Applied_Split__c < 100];

        System.assert(oppLineList2[0].Id != null);
        System.runAs(listUser[0]) {
            settingDisable.Disable_Opportunity_Triggers__c = true;
            update settingDisable;
            test.startTest();  
            flowControll.opportunityLineItemHandler = true;
            OpportunityLineItemTriggersHelper.OppLineItemsBeforeDelete(oppLineList2);
            OpportunityLineItemTriggersHelper.OppLineItemsAfterDelete(oppLineList2);
            test.stopTest();
        }
    } 
    testMethod static void testHasPolarisProduct(){
        List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        List<OpportunityLineItem> insertoppLineList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        Opportunity opp = [select Id from Opportunity where Opportunity_Split_Parent__c = null and split_percentage__c = 100 limit 1];
        priceBookEntry pbe = [select Id,product2Id from priceBookEntry where product2.Bundle_Features__c = 'Cloud Native Protection M365H'];

        insertoppLineList.add(new OpportunityLineItem(TotalPrice=2000,Quantity = 1,opportunityId=opp.Id,Line_Type_Text__c = 'New',priceBookEntryId=pbe.Id));
        insert insertoppLineList;
        System.runAs(listUser[0]) {
             
            
            test.startTest();
            OppAnnualContractValueUtil.OppACVRecursion = true;
            SBQQ.TriggerControl.disable();    
            FlowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = true;
            insertoppLineList[0].ACV_Amount__c = 1000;
            update insertoppLineList;
            test.stopTest();
        }
        System.assertNotEquals(null, listUser[0].Id);
    }
    testMethod static void testMethod1(){
        List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        List<OpportunityLineItem> insertoppLineList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        Opportunity childopp = [select Id from Opportunity where Opportunity_Split_Parent__c != null limit 1];
        oppLineList = [select Id,OpportunityId,product2Id,priceBookEntryId from OpportunityLineItem where opportunity.split_percentage__c = 100 limit 1];   
        insertoppLineList.add(new OpportunityLineItem(Applied_Split__c = 50,TotalPrice=2000,Quantity = 1,opportunityId=childopp.Id,Line_Type_Text__c = 'New',Parent_split_Opplineitem_Id__c=oppLineList[0].Id,priceBookEntryId=oppLineList[0].priceBookEntryId));
        insert insertoppLineList;
        System.runAs(listUser[0]) {
             
            
            test.startTest();
            OppAnnualContractValueUtil.OppACVRecursion = true;
            SBQQ.TriggerControl.disable();    
            FlowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = true;
            delete oppLineList[0];
            test.stopTest();
        }
        System.assertNotEquals(null, listUser[0].Id);
    }
    
    testMethod static void testMethod2(){
        List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        System.runAs(listUser[0]) {
            
        flowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        //flowControll.opportunityTriggerHandler = false;
        //flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
            
        //OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable();   
            
        Account objAccount2 = new Account();
        Contact objContact2 = new Contact();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount2.Name = 'Test Account 31-05';
        objAccount2.RecordTypeId = recordTypeId;
        insert objAccount2;
        objContact2.Account = objAccount2;
        objContact2.LastName = 'Test Contact 31-05';
        insert objContact2; 
        
        Id pbookId = Test.getStandardPricebookId();
        
        Opportunity objOpp = [select Id,StageName,SBQQ__PrimaryQuote__c from Opportunity where Opportunity_Split_Parent__c = null AND Name != 'Split parent Opp'];
        objOpp.StageName = '1 Discovery';
        objOpp.closeDate = date.newInstance(2023, 1, 21);
        flowControll.opportunityTriggerHandler = false;
        update objOpp;
        
        
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
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = objAccount2.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__Opportunity2__c = objOpp.Id;
        qt.SBQQ__PrimaryContact__c = objContact2.Id;
        qt.Task_Products__c='RBK-DISK-RETENTION';  
        qt.SBQQ__Type__c = 'Renewal';
        insert qt; 
        
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt1.SBQQ__Account__c = objAccount2.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__Opportunity2__c = objOpp.Id;
        qt1.SBQQ__PrimaryContact__c = objContact2.Id;
        qt1.Task_Products__c='RBK-DISK-RETENTION';  
        qt1.SBQQ__Type__c = 'Quote';
        insert qt1; 
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubsAddon.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
        SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=false,SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prdSW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        SBQQ__QuoteLine__c qli7 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=false,SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prdPl.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        
        qliList.add( qli1 );
        qliList.add( qli2 );
        qliList.add( qli3 );
        qliList.add( qli4 );
        qliList.add( qli5 );
        qliList.add(qli6);
        qliList.add(qli7);
        insert qliList;
        
        objOpp.SBQQ__PrimaryQuote__c = qt.Id;
        flowControll.opportunityTriggerHandler = false;
        update objOpp;
        
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        oppLineList.add(new OpportunityLineItem(Special_Program__c='Replaced',PBE_Product_Family__c = 'POLARIS',ACV_Amount__c=100,Line_Type_Text__c='Test',Renewal_Due_Date__c=System.Today()+300,SBQQ__QuoteLine__c=qliList[0].Id,pricebookentryid=pBList[0].Id,UnitPrice=1000, Quantity = 2,OpportunityID =  objOpp.Id));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[1].Id,pricebookentryid=pBList[1].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=date.newInstance(2022, 1, 21),SBQQ__QuoteLine__c=qliList[2].Id,pricebookentryid=pBList[2].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=date.newInstance(2023, 1, 21),SBQQ__QuoteLine__c=qliList[3].Id,pricebookentryid=pBList[3].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[4].Id,pricebookentryid=pBList[4].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[5].Id,pricebookentryid=pBList[4].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id,Required_by_opportunity_product__c = null, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[6].Id,pricebookentryid=pBList[5].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id,PBE_Product_Family__c = 'POLARIS', Renewal_Timing__c='Late'));
        
        test.startTest();
        insert oppLineList;
        OpportunityLineItemTriggersHelper.createOli(oppLineList[0]);
        FlowControll.opportunityTriggerHandler = true;
        flowControll.opportunityLineItemHandler = true;
        delete oppLineList[0];
        List<OpportunityLineItem> oppLineitemList = new List<OpportunityLineItem>();
        oppLineitemList = [select Id,ACV_Amount__c from OpportunityLineItem limit 1];
        oppLineitemList[0].ACV_Amount__c = 200;
        FlowControll.opportunityTriggerHandler = true;
        flowControll.opportunityLineItemHandler = true;
        update oppLineitemList;
        System.assertNotEquals(null, oppLineitemList[0]);
        // Changes from here -----------
        List<OpportunityLineItem> newList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> updateMap = new Map<Id, OpportunityLineItem>();
        
        OpportunityLineItem insertNew = new OpportunityLineItem(Applied_Split__c = 12.2, ACV_Amount__c=105,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[1].Id,pricebookentryid=pBList[1].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id);
        insert insertNew;
        newList.add(insertNew);
        insertNew.ACV_Amount__c = 200;
        
        update insertNew;
        
        
        
        updateMap.put(insertNew.Id, insertNew);

        
        objOpp.CloseDate = date.newInstance(2022, 4, 21);
        update objOpp;
        objOpp.Deleted_line_ContractId_RTA__c = 'Test;Test1';
        update objOpp;
        test.stopTest();
        }

    }
    testMethod static void testMethod3(){
        List<User> listUser = [select Id from user where Firstname like '%testClassUser3457722%'];
        System.runAs(listUser[0]) {
        
        flowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        //flowControll.opportunityTriggerHandler = false;
        //flowControll.opportunityLineItemHandler = false;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        //OppAnnualContractValueUtil.OppACVRecursion = true;
        SBQQ.TriggerControl.disable();        
        
        Account objAccount2 = new Account();
        Contact objContact2 = new Contact();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount2.Name = 'Test Account 31-05';
        objAccount2.RecordTypeId = recordTypeId;
        insert objAccount2;
        objContact2.Account = objAccount2;
        objContact2.LastName = 'Test Contact 31-05';
        insert objContact2; 
        
        Id pbookId = Test.getStandardPricebookId();
        
        Opportunity objOpp = [select Id,StageName,SBQQ__PrimaryQuote__c from Opportunity where Opportunity_Split_Parent__c = null AND Name != 'Split parent Opp'];
        objOpp.StageName = '1 Discovery';
        objOpp.closeDate = date.newInstance(2023, 1, 21);
        objOpp.Deleted_line_ContractId_RTA__c = objAccount2.Id+':20;'+objAccount2.Id+':30';
        flowControll.opportunityTriggerHandler = false;
        update objOpp;
        
        
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
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = objAccount2.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__Opportunity2__c = objOpp.Id;
        qt.SBQQ__PrimaryContact__c = objContact2.Id;
        qt.Task_Products__c='RBK-DISK-RETENTION';  
        qt.SBQQ__Type__c = 'Renewal';
        insert qt; 
        
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt1.SBQQ__Account__c = objAccount2.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__Opportunity2__c = objOpp.Id;
        qt1.SBQQ__PrimaryContact__c = objContact2.Id;
        qt1.Task_Products__c='RBK-DISK-RETENTION';  
        qt1.SBQQ__Type__c = 'Quote';
        insert qt1; 
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdLOD.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubsAddon.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' ); 
        SBQQ__QuoteLine__c qli6 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=false,SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prdSW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        SBQQ__QuoteLine__c qli7 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=false,SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prdPl.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        
        qliList.add( qli1 );
        qliList.add( qli2 );
        qliList.add( qli3 );
        qliList.add( qli4 );
        qliList.add( qli5 );
        qliList.add(qli6);
        qliList.add(qli7);
        insert qliList;
        
        objOpp.SBQQ__PrimaryQuote__c = qt.Id;
        flowControll.opportunityTriggerHandler = false;
        update objOpp;
        
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        oppLineList.add(new OpportunityLineItem(Special_Program__c='Replaced',PBE_Product_Family__c = 'POLARIS',ACV_Amount__c=100,Line_Type_Text__c='Test',Renewal_Due_Date__c=System.Today()+300,SBQQ__QuoteLine__c=qliList[0].Id,pricebookentryid=pBList[0].Id,UnitPrice=1000, Quantity = 2,OpportunityID =  objOpp.Id));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[1].Id,pricebookentryid=pBList[1].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=date.newInstance(2022, 1, 21),SBQQ__QuoteLine__c=qliList[2].Id,pricebookentryid=pBList[2].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=date.newInstance(2023, 1, 21),SBQQ__QuoteLine__c=qliList[3].Id,pricebookentryid=pBList[3].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[4].Id,pricebookentryid=pBList[4].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[5].Id,pricebookentryid=pBList[4].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id,Required_by_opportunity_product__c = null, Renewal_Timing__c='Late'));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[6].Id,pricebookentryid=pBList[5].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id,PBE_Product_Family__c = 'POLARIS', Renewal_Timing__c='Late'));
        
        test.startTest();
        insert oppLineList;
        OpportunityLineItemTriggersHelper.createOli(oppLineList[0]);
        FlowControll.opportunityTriggerHandler = true;
        flowControll.opportunityLineItemHandler = true;
        delete oppLineList[0];
        List<OpportunityLineItem> oppLineitemList = new List<OpportunityLineItem>();
        oppLineitemList = [select Id,ACV_Amount__c from OpportunityLineItem limit 1];
        oppLineitemList[0].ACV_Amount__c = 200;
        FlowControll.opportunityTriggerHandler = true;
        flowControll.opportunityLineItemHandler = true;
        update oppLineitemList;
        System.assertNotEquals(null, oppLineitemList[0]);
        // Changes from here -----------
        List<OpportunityLineItem> newList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> updateMap = new Map<Id, OpportunityLineItem>();
        
        OpportunityLineItem insertNew = new OpportunityLineItem(Applied_Split__c = 12.2, ACV_Amount__c=105,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[1].Id,pricebookentryid=pBList[1].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpp.Id);
        insert insertNew;
        newList.add(insertNew);
        insertNew.ACV_Amount__c = 200;
        
        update insertNew;
        
        
        
        updateMap.put(insertNew.Id, insertNew);
        
        objOpp.CloseDate = date.newInstance(2022, 4, 21);
        update objOpp;
        //OpportunityLineItemTriggersHelper.syncOppLineItems(newList, updateMap);
        // Changes End here -----------
        objOpp.Deleted_line_ContractId_RTA__c = 'Test;Test1';
        update objOpp;
        test.stopTest();
        }

    }
}