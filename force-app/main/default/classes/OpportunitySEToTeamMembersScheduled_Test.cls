/**
 * @description test class for OpportunitySEToTeamMembersScheduled
 */  
@isTest
public class OpportunitySEToTeamMembersScheduled_Test {
    
    /**
     * @description test method 1 
     */ 
    public static testmethod void testScheduledClass(){
        User user = getUser();
        System.assert(user.Id != null);
        
        System.runAs(user){
            ShGl_TestFactoryHelper.insertCustomSettings();
            ShGl_DisableBusinessLogic__c businessLogic1 = new ShGl_DisableBusinessLogic__c(Name='Test1',Disable_Opportunity_Triggers__c=true, Disable_Opportunity_Validation_Rules__c= true , SetupOwnerId=UserInfo.getUserId());
            insert businessLogic1;
            
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            
            Pricebook2 pbk1 = new Pricebook2(Name = 'Test Pricebook Entry 1', Description = 'Test Pricebook Entry 1', isActive = true);
            insert pbk1;
            
            Product2 prd1 = new Product2(Name = 'Test Product Entry 1', Description = 'Test Product Entry 1', productCode = 'OPTY-SPLIT', isActive = true);
            insert prd1;
            
            PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prd1.Id, UnitPrice = 40, IsActive = true, UseStandardPrice = false);
            insert standardPrice;
            
            Id standardPBId = test.getStandardPricebookId();
            PriceBookEntry pbEntry = new PriceBookEntry(
                UnitPrice = 300,
                PriceBook2Id = standardPBId,
                Product2Id = prd1.Id,
                IsActive = true,
                UseStandardPrice = false);
            
            
            //Generate the Contact
            Map < String, Object > cntMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Email' => 'leademail@hidden.com'
                    };
                        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt1;
            
            //Generate the Opportunity
            Map < String, Object > oppMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Initial_Contacts_Name__c' => cnt1.Id,
                    'StageName' => '4 Business Justification'
                    };
                        
                        List < Opportunity > opptyList = (List < Opportunity > ) ShGl_TestFactory.createSObjectList(new Opportunity(), 3, oppMap);
            opptyList[0].Lead_Email_Hidden__c = 'leademail@hidden.com';
            opptyList[0].Converted_From_Lead__c = true;
            opptyList[0].SBQQ__Ordered__c = true;
            opptyList[0].Pricebook2Id = Test.getStandardPricebookId();
            opptyList[0].Primary_Competitor__c = 'Other';
            opptyList[0].ForecastCategoryName = 'Best Case';
            opptyList[0].Other_Competitor_Field__c = 'Testing';
            opptyList[0].Rubrik_Sales_Engineer__c = UserInfo.getUserId();
            opptyList[0].Rubrik_Co_Sales_Engineer__c = [SELECT Id FROM User WHERE isActive = TRUE AND UserType = 'Standard' LIMIT 1].Id;
            opptyList[0].SecondaryOwner__c = UserInfo.getUserId();
            insert opptyList;
            
            OpportunityTeamMember oppTeam = new OpportunityTeamMember();
            oppTeam.OpportunityId =  opptyList[0].Id;
            oppTeam.TeamMemberRole = 'Co-Owner';
            oppTeam.UserId = UserInfo.getUserId();
            oppTeam.OpportunityAccessLevel = 'Edit';
            insert oppTeam;
            
            OpportunityTeamMember coSEotm = new OpportunityTeamMember();
            coSEotm.OpportunityId =  opptyList[0].Id;
            coSEotm.TeamMemberRole = 'Co-Sales Engineer';
            coSEotm.UserId = opptyList[0].Rubrik_Co_Sales_Engineer__c;
            coSEotm.OpportunityAccessLevel = 'Edit';
            insert coSEotm;
            
            OpportunityTeamMember sEotm = new OpportunityTeamMember();
            sEotm.OpportunityId =  opptyList[0].Id;
            sEotm.TeamMemberRole = 'Sales Engineer';
            sEotm.UserId = opptyList[0].Rubrik_Sales_Engineer__c;
            sEotm.OpportunityAccessLevel = 'Edit';
            insert sEotm;
            
            String CRON_EXP = '0 0 * * * ?';
            Test.startTest();
            System.schedule('TestJob', CRON_EXP, new OpportunitySEToTeamMembersScheduled());
            Test.stopTest();
        }
    }
    
    /**
     * @description test method 2
     */ 
    public static testmethod void testScheduledClass2(){
        User user = getUser();
        System.assert(user.Id != null);
        System.runAs(user){
            ShGl_TestFactoryHelper.insertCustomSettings();
            ShGl_DisableBusinessLogic__c businessLogic1 = new ShGl_DisableBusinessLogic__c(Name='Test1',Disable_Opportunity_Triggers__c=true, Disable_Opportunity_Validation_Rules__c= true , SetupOwnerId=UserInfo.getUserId());
            insert businessLogic1;
            
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            
            Pricebook2 pbk1 = new Pricebook2(Name = 'Test Pricebook Entry 1', Description = 'Test Pricebook Entry 1', isActive = true);
            insert pbk1;
            
            Product2 prd1 = new Product2(Name = 'Test Product Entry 1', Description = 'Test Product Entry 1', productCode = 'OPTY-SPLIT', isActive = true);
            insert prd1;
            
            PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prd1.Id, UnitPrice = 40, IsActive = true, UseStandardPrice = false);
            insert standardPrice;
            
            Id standardPBId = test.getStandardPricebookId();
            PriceBookEntry pbEntry = new PriceBookEntry(
                UnitPrice = 300,
                PriceBook2Id = standardPBId,
                Product2Id = prd1.Id,
                IsActive = true,
                UseStandardPrice = false);
            
            Map < String, Object > cntMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Email' => 'leademail@hidden.com'
                    };
                        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt1;
            
            Map < String, Object > oppMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Initial_Contacts_Name__c' => cnt1.Id,
                    'StageName' => '4 Business Justification'
                    };
                        
                        List < Opportunity > opptyList = (List < Opportunity > ) ShGl_TestFactory.createSObjectList(new Opportunity(), 3, oppMap);
            opptyList[0].Lead_Email_Hidden__c = 'leademail@hidden.com';
            opptyList[0].Converted_From_Lead__c = true;
            opptyList[0].SBQQ__Ordered__c = true;
            opptyList[0].Pricebook2Id = Test.getStandardPricebookId();
            opptyList[0].Primary_Competitor__c = 'Other';
            opptyList[0].ForecastCategoryName = 'Best Case';
            opptyList[0].Other_Competitor_Field__c = 'Testing';
            opptyList[0].Rubrik_Sales_Engineer__c = UserInfo.getUserId();
            opptyList[0].SecondaryOwner__c = UserInfo.getUserId();
            opptyList[0].Co_Owner__c = [SELECT Id FROM User WHERE isActive = TRUE AND UserType = 'Standard' LIMIT 1].Id;
            opptyList[0].Rubrik_Co_Sales_Engineer__c = [SELECT Id FROM User WHERE isActive = TRUE AND UserType = 'Standard' LIMIT 1].Id;
            insert opptyList;
            
            OpportunityTeamMember oppTeam = new OpportunityTeamMember();
            oppTeam.OpportunityId =  opptyList[0].Id;
            oppTeam.TeamMemberRole = 'Co-Owner';
            oppTeam.UserId = UserInfo.getUserId();
            oppTeam.OpportunityAccessLevel = 'Edit';
            insert oppTeam;
            
            OpportunityTeamMember coSEotm = new OpportunityTeamMember();
            coSEotm.OpportunityId =  opptyList[0].Id;
            coSEotm.TeamMemberRole = 'Co-Sales Engineer';
            coSEotm.UserId = UserInfo.getUserId();
            coSEotm.OpportunityAccessLevel = 'Edit';
            insert coSEotm;
            
            String CRON_EXP = '0 0 * * * ?';
            Test.startTest();
            System.schedule('TestJob', CRON_EXP, new OpportunitySEToTeamMembersScheduled());
            Test.stopTest();
        }
    }
    
    /**
     * @description test method 3
     */ 
    public static testmethod void testScheduledClass3(){
        User user = getUser();
        System.assert(user.Id != null);
        
        System.runAs(user){
            ShGl_TestFactoryHelper.insertCustomSettings();
            ShGl_DisableBusinessLogic__c businessLogic1 = new ShGl_DisableBusinessLogic__c(Name='Test1',Disable_Opportunity_Triggers__c=true, Disable_Opportunity_Validation_Rules__c= true , SetupOwnerId=UserInfo.getUserId());
            insert businessLogic1;
            
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            
            Map < String, Object > cntMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Email' => 'leademail@hidden.com'
                    };
                        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt1;
            
            Map < String, Object > oppMap = new Map < String, Object > {
                'AccountId' => act.Id,
                    'Initial_Contacts_Name__c' => cnt1.Id,
                    'StageName' => '4 Business Justification'
                    };
                        
                        List <Opportunity> opptyList = (List < Opportunity > ) ShGl_TestFactory.createSObjectList(new Opportunity(), 3, oppMap);
            opptyList[0].Lead_Email_Hidden__c = 'leademail@hidden.com';
            opptyList[0].Converted_From_Lead__c = true;
            opptyList[0].SBQQ__Ordered__c = true;
            opptyList[0].Pricebook2Id = Test.getStandardPricebookId();
            opptyList[0].Primary_Competitor__c = 'Other';
            opptyList[0].ForecastCategoryName = 'Best Case';
            opptyList[0].Other_Competitor_Field__c = 'Testing';
            opptyList[0].Rubrik_Sales_Engineer__c = UserInfo.getUserId();
            opptyList[0].SecondaryOwner__c = UserInfo.getUserId();
            opptyList[0].Co_Owner__c = [SELECT Id FROM User WHERE isActive = TRUE AND UserType = 'Standard' LIMIT 1].Id;
            opptyList[0].Rubrik_Co_Sales_Engineer__c = [SELECT Id FROM User WHERE isActive = TRUE AND UserType = 'Standard' LIMIT 1].Id;
            insert opptyList;
            
            OpportunityTeamMember oppTeam1 = new OpportunityTeamMember();
            oppTeam1.OpportunityId =  opptyList[0].Id;
            oppTeam1.TeamMemberRole = 'Co-Owner';
            oppTeam1.UserId = opptyList[0].Co_Owner__c;
            oppTeam1.OpportunityAccessLevel = 'Edit';
            insert oppTeam1;
            
            String CRON_EXP = '0 0 * * * ?';
            Test.startTest();
            System.schedule('TestJob', CRON_EXP, new OpportunitySEToTeamMembersScheduled());
            Test.stopTest();
        }
    }
    
    /**
     * @description get user
     * @return User
     */  
    static User getUser(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        listUser[0].IsActive = true;
        flowControll.UserTriggerHandler = false;
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Sales_IT_Data_Migration_User'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        Return listUser[0];
    }
}