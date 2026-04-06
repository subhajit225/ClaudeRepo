@isTest
public class OpportunityController_Test {
    
    static TriggerControl__c getTriggerControl(){
        TriggerControl__c tc= new TriggerControl__c();
        tc.Name='Opportunity';
        tc.DisableTrigger__c=true;
        return tc;
    }
    
    @testSetup
    static void setupTestData(){
        
        list<user> lstUser = new List<user>();
        String ProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Field Sales User'].Id;
        UserRole vUserRole = new UserRole(DeveloperName = 'RubrikDeveloper1', Name = 'My Role');
        insert vUserRole;
        
        for(integer i = 0; i<3; i++){
            //User u= TestDataFactory.getUser();
            //lstUser.add(u);
            User u = new User(
                ProfileId = ProfileId,
                LastName = 'last'+i,
                Email = 'TestUser' +i +'@rubrik.com',
                Username = 'TestUser' +i +'@rubrik.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'TestUser'.substring(0,5),
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = vUserRole.Id,
                Start_Date__c=System.Today().adddays(-30)            
            );
        }
        insert lstUser;
    }
    
    static testMethod void opportunityWithListItem(){
        // Test.startTest();
        
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        
        Account acc = TestDataFactory.getAccount();
        insert acc;
        /*Opportunity opp = TestDataFactory.getOpportunity(acc);
        //opp.Lead_Email_Hidden__c='test@email.com';
        // Opportunity opp= new Opportunity(name='Test Opp',accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert opp;
        Opportunity tempOpp= TestDataFactory.getOpportunity(acc);
        insert tempOpp;*/
        
        List<OpportunitySplitMapping__c> oppSplitMappingList = new List<OpportunitySplitMapping__c> ();
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'Name', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'StageName', Skip_Update_if_child_has_value__c=false));
        oppSplitMappingList.add(new OpportunitySplitMapping__c(Field__c = 'CloseDate', Skip_Update_if_child_has_value__c=false));
        insert oppSplitMappingList;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acc.Id
        };
            
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        Opportunity tempOpp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        List<Opportunity> opptyList = new List<Opportunity> ();
        opptyList.add(opp);
        opptyList.add(tempOpp);
        insert opptyList;
        
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode = 'OPTY-SPLIT');
        insert newProd;
        
        Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', isActive = true);
        insert priceBook;
        
        Id standardPBId = test.getStandardPricebookId();
        // PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = newProd.Id, UnitPrice = 300, IsActive = true);
        //insert standardPBE;
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 400,
            PriceBook2Id = standardPBId,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        opp.Pricebook2Id=standardPBId;
        opp.Split_percentage__c=25;
        opp.split_amount__c = 0.00;
        update opp;
        tempOpp.Pricebook2Id=standardPBId;
        update tempOpp;
        
        OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000,
                                                              Quantity = 2,OpportunityID = opp.Id
                                                             );
        insert oppLine;
        system.debug('Opportunity Line items:'+opp.OpportunityLineItems);
        
        PageReference pageRef = Page.OpportunityVFP;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('oId', String.valueOf(opp.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        OpportunityController oppCon = new OpportunityController(sc);
        
        Id emTId = oppCon.emailTemplateId;
        
        test.startTest();
        
        List<User> lstUser = [select id from User where Profile.Name='Rubrik Field Sales User' limit 3];
        opp.split_amount__c = 0.00;
        oppCon.User2Opty.split_amount__c = 0.00;
        oppCon.User3Opty.split_amount__c = 0.00;
        oppCon.User4Opty.split_amount__c = 0.00;
        oppCon.User2Opty.Split_percentage__c = 25;
        oppCon.User3Opty.Split_percentage__c = 25;
        oppCon.User4Opty.Split_percentage__c = 25;
        oppCon.User2Opty.OwnerId = lstUser[0].Id; //'0051k000000f6rs';
        oppCon.User3Opty.OwnerId = lstUser[1].Id; //'0051W000004FjsJ';
        oppCon.User4Opty.OwnerId = lstUser[2].Id; //'0051W000004Y67R';         
        
        oppCon.saveItem();
        oppCon.cancelAction();
        //oppCon.returnToOrigination();
        test.stopTest();
        PageReference pageRef1 = Page.OpportunityVFP;
        Test.setCurrentPage(pageRef1);
        pageRef1.getParameters().put('oId', String.valueOf(opp.Id));
        ApexPages.StandardController sc1 = new ApexPages.StandardController(opp);
        OpportunityController oppCon1 = new OpportunityController(sc);
        
        List<Opportunity> primaryOpportunity = [Select Id, 
            (Select Id, ProductCode From OpportunityLineItems), 
            (Select Id, Owner.Name, Split_percentage__c, Split_Amount__c, Split__c From Split_Opportunities__r) 
            From Opportunity ];
        system.debug('primaryOpportunity :: '+primaryOpportunity);
        
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE ProductCode='OPTY-SPLIT' LIMIT 1];
        oli.TotalPrice = -1;
        update oli;
        
        delete oli;
    }
    
    static testMethod void opportunityWithListItem_1(){
        // Test.startTest();
        
        ShGl_TestFactoryHelper.insertCustomSettings();

        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        
        Account acc= TestDataFactory.getAccount();
        insert acc;
        Opportunity opp = TestDataFactory.getOpportunity(acc);
        //opp.Lead_Email_Hidden__c='test@email.com';
        // Opportunity opp= new Opportunity(name='Test Opp',accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert opp;
        Opportunity tempOpp= TestDataFactory.getOpportunity(acc);
        insert tempOpp;
        
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode='OPTY-SPLIT');
        insert newProd;
        
        Pricebook2 pricebook= new Pricebook2(name='Test Price Book',isActive=true);
        insert priceBook;
        
        Id standardPBId = test.getStandardPricebookId();
        // PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = newProd.Id, UnitPrice = 300, IsActive = true);
        //insert standardPBE;
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 400,
            PriceBook2Id = standardPBId,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        opp.Pricebook2Id=standardPBId;
        opp.Split_percentage__c=25;
        opp.split_amount__c = 0.00;
        update opp;
        tempOpp.Pricebook2Id=standardPBId;
        update tempOpp;
        
        OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000,
                                                              Quantity = 2,OpportunityID = opp.Id
                                                             );
        insert oppLine;
        system.debug('Opportunity Line items:'+opp.OpportunityLineItems);
        
        PageReference pageRef = Page.OpportunityVFP;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('oId', String.valueOf(opp.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        OpportunityController oppCon = new OpportunityController(sc);
        
        test.startTest();
        
        List<User> lstUser = [select id from User where Profile.Name='Rubrik Field Sales User' limit 3];
        opp.split_amount__c = 0.00;
        oppCon.User2Opty.split_amount__c = 0.00;
        oppCon.User3Opty.split_amount__c = 0.00;
        oppCon.User4Opty.split_amount__c = 0.00;
        oppCon.User2Opty.Split_percentage__c = 25;
        oppCon.User3Opty.Split_percentage__c = 25;
        oppCon.User4Opty.Split_percentage__c = 25;
        oppCon.User2Opty.OwnerId = lstUser[0].Id; //'0051k000000f6rs';
        oppCon.User3Opty.OwnerId = lstUser[1].Id; //'0051W000004FjsJ';
        oppCon.User4Opty.OwnerId = lstUser[2].Id; //'0051W000004Y67R';         
        
        oppCon.saveItem();
        oppCon.cancelAction();
        //oppCon.returnToOrigination();
        test.stopTest();
        PageReference pageRef1 = Page.OpportunityVFP;
        Test.setCurrentPage(pageRef1);
        ApexPages.StandardController sc1 = new ApexPages.StandardController(opp);
        OpportunityController oppCon1 = new OpportunityController(sc);
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE ProductCode='OPTY-SPLIT' LIMIT 1];
        oli.TotalPrice = -1;
        update oli;
        
        delete oli;
    }
    
}