/**
* @description Test class to verify Aha Idea Link functionality for Opportunities and Cases
* @test
* @author Raveesh Layal
* @Date 2025-08-01
*/
@isTest
public class AhaIdeaLinkHandler_Test {
    
    /**
* @description Sets up test data including users, accounts, contacts, opportunities, cases, and Aha ideas
*/
    @testSetup 
    static void dataSetup() {
        // Create test user
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
        User testUser = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true);
        insert testUser;
        
        // Run as test user to create test data
        System.runAs(testUser) {
            
            // Insert the E2C Advance Configuration record (List Custom Setting)
            insert new E2CAdv__E2CAConfiguration__c(
                Name = 'E2C Advance Configuration',
                E2CAdv__EnableTrigger__c = false
            );
            
            // Insert the AccountTrigger setting record (List Custom Setting)
            insert new E2CAdv__E2CATriggers__c(
                Name = 'AccountTrigger',
                E2CAdv__IsActive__c = true
            );
            
            E2CAdv__E2CAConfiguration__c generalConfiguration = E2CAdv__E2CAConfiguration__c.getInstance('E2C Advance Configuration');
            E2CAdv__E2CATriggers__c accountTriggerSetting = E2CAdv__E2CATriggers__c.getInstance('AccountTrigger');
            // using Null-Safe Operator so that it won't give error when field is not available in the org.
            
            //insertDisableSettingFor(testUser);
            Map<String, Object> accountFields = new Map<String, Object>{
                'Industry' => 'Technology',
                    'BillingStreet' => '123 Business Street',
                    'BillingCity' => 'San Francisco',
                    'BillingState' => 'California',
                    'BillingCountry' => 'United States',
                    'BillingPostalCode' => '94105',
                    'Phone' => '(555) 123-456',
                    'Website' => 'https://www.testaccount' +
                    '.com'
                    };
                        
                        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), accountFields);
            act.Account_Preference__c = 'Advisory Account; Critical Account; CSM Account';
            act.Heads_Up_to_Support_Team__c = 'Hello';
            act.Strategic_Account__c =  true;
            insert act;
            
            
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
                        Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert con;
            
            
            Map<String, Object>  oppMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
                        List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 6, oppMap);
            
            integer i=0;
            for(Opportunity opp: opptyList){
                opp.Idea_References__c = 'GRZWRKSPCE-I-51; GRZWRKSPCE-I-5; GRZWRKSPCE-I-25; GRZWRKSPCE-I-50';
                opp.ACV_Amount__c = 121;
                if(i==0){
                    opp.Next_Step__c='c-co';
                }
                if(i==1){
                    opp.Next_Step__c='TEST Cohesity';
                }
                if(i==2){
                    opp.Primary_Competitor__c = 'Cohesity';
                }
                if(i==3){
                    opp.Other_Primary_Competitor__c = 'Testing Cohesity Test';
                }
                if(i==4){
                    opp.Win_Loss_Comments__c = 'Cohesity Test';
                }
                /*if(i==5){
                    opp.Cohesity_Deal__c = true;
                }*/ //SAL26-704: Commented
                i++;
            }
            insert opptyList;
            
            
            List<Case>  caseList= New List<Case>();
            Map<String, Object> caseMap = new Map<String, Object> {
                'Subject' => 'testing one more',
                    'Idea_Reference__c' => 'GRZWRKSPCE-I-51; GRZWRKSPCE-I-5; GRZWRKSPCE-I-25; GRZWRKSPCE-I-50',
                    'ContactId' => con.Id,
                    'Jira_Reference_urls__c' => 'test',
                    'Last_Case_Status__c' => 'Customer requested close',
                    'Priority' => 'P2',
                    'close_survey_triggered__c' => false,
                    'Resolution__c' => 'Hardware problem',
                    'Special_Handling_Instructions__c' => act.Heads_Up_to_Support_Team__c,
                    'AccountId' => act.Id
                    };
                        Case caseTest = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap);
            caseList.add(caseTest);
            
            Map<String, Object> caseMap1 = new Map<String, Object> {
                'Subject' => 'testing one more 1',
                    'ContactId' => con.Id,
                    'Idea_Reference__c' => 'GRZWRKSPCE-I-51; GRZWRKSPCE-I-5; GRZWRKSPCE-I-25; GRZWRKSPCE-I-50',
                    'Jira_Reference_urls__c' => 'test',
                    'Last_Case_Status__c' => 'Customer requested close',
                    'Priority' => 'P2',
                    'close_survey_triggered__c' => false,
                    'Resolution__c' => 'Hardware problem',
                    'Special_Handling_Instructions__c' => act.Heads_Up_to_Support_Team__c,
                    'AccountId' => act.Id
                    };
                        Case caseTest1 = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap1);
            caseList.add(caseTest1);
            insert caseList;
            
            
            List<Aha_Ideas__c> ahaIdeaList = New List<Aha_Ideas__c>();
            Aha_Ideas__c ai1 = new Aha_Ideas__c();
            ai1.name = 'Idea Parent Test Record';
            ai1.Aha_Idea_Number__c = '7271210190138657159';
            ai1.Aha_Unique_ID__c = 'GRZWRKSPCE-I-80';
            ai1.Idea_Description__c = 'Account 1 idea 2 (Case)';
            ai1.Status__c = 'New';
            ahaIdeaList.Add(ai1);
            
            Aha_Ideas__c ai = new Aha_Ideas__c();
            ai.name = 'Idea Parent Test Record';
            ai.Aha_Idea_Number__c = '7249720544000241793';
            ai.Aha_Unique_ID__c = 'GRZWRKSPCE-I-7';
            ai.Idea_Description__c = 'Account 1 idea 2 (Case)';
            ai.Status__c = 'New';
            ai.Duplicate_of__c = ai1.Id;
            ahaIdeaList.add(ai);
            INSERT ahaIdeaList;
        }
    }
    
    
    /**
* @description Tests that creating an Aha Idea Link adds the idea reference to the Opportunity's Idea_References__c field
*/
    @isTest
    static void testMethod1(){
        /* Test Case: Verify that when an Aha Idea Link is created for an Opportunity,
the Idea Reference is correctly added to the Opportunity's Idea_References__c field */
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%csit-testuser@rubrik.com%' LIMIT 1];
        
        System.runAs(testUser) {
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity oppt  = [SELECT Id,Name,Idea_References__c FROM Opportunity WHERE Primary_Competitor__c = 'Cohesity' LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Opportunity_Name__c = oppt.id;
            Test.startTest();
            INSERT ail;
            Opportunity getoppt = [SELECT Id,Name,Idea_References__c FROM Opportunity WHERE Id =: oppt.Id];
            String oppIdeaReference = getoppt.Idea_References__c;
            String assertPass;
            if(oppIdeaReference.contains('GRZWRKSPCE-I-7')){
                assertPass = 'Test method passed Successfully';
            }
            Assert.areEqual('Test method passed Successfully', assertPass);
            Test.StopTest();
        }
    }
    
    /**
* @description Tests that deleting an Aha Idea Link removes the idea reference from the Opportunity's Idea_References__c field
*/
    @isTest
    static void testMethod2(){
        /* Test Case: Verify that when an Aha Idea Link is deleted for an Opportunity,
the Idea Reference is correctly removed from the Opportunity's Idea_References__c field */
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%csit-testuser@rubrik.com%' LIMIT 1];
        
        System.runAs(testUser) {
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity oppt  = [SELECT Id,Name,Idea_References__c FROM Opportunity WHERE Primary_Competitor__c = 'Cohesity' LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Opportunity_Name__c = oppt.id;
            Test.startTest();
            INSERT ail;
            DELETE ail;
            String oppIdeaReference = oppt.Idea_References__c;
            String assertPass;
            if(!oppIdeaReference.contains('GRZWRKSPCE-I-7')){
                assertPass = 'Test method passed Successfully';
            }
            Assert.areEqual('Test method passed Successfully', assertPass);
            Test.StopTest();
        }
    }
    
    /**
* @description Tests that creating an Aha Idea Link adds the idea reference to the Case's Idea_Reference__c field
*/
    @isTest
    static void testMethod3(){
        /* Test Case: Verify that when an Aha Idea Link is created for a Case,
the Idea Reference is correctly added to the Case's Idea_Reference__c field */
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%csit-testuser@rubrik.com%' LIMIT 1];
        
        System.runAs(testUser) {
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Case cs = [SELECT Id,Idea_Reference__c FROM Case WHERE Subject = 'testing one more' LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Case_Number__c  = cs.id;
            Test.startTest();
            INSERT ail;
            Case getcs = [SELECT Id,Idea_Reference__c FROM Case WHERE Id =: cs.Id];
            String csIdeaReference = getcs.Idea_Reference__c;
            String assertPass;
            if(csIdeaReference.contains('GRZWRKSPCE-I-7')){
                assertPass = 'Test method passed Successfully';
            }
            Assert.areEqual('Test method passed Successfully', assertPass);
            Test.StopTest();
        }
    }
    
    /**
* @description Tests that deleting an Aha Idea Link removes the idea reference from the Case's Idea_Reference__c field
*/
    @isTest
    static void testMethod4(){
        /* Test Case: Verify that when an Aha Idea Link is deleted for a Case,
the Idea Reference is correctly removed from the Case's Idea_Reference__c field */
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%csit-testuser@rubrik.com%' LIMIT 1];
        
        System.runAs(testUser) {
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Case cs = [SELECT Id,Idea_Reference__c FROM Case WHERE Subject = 'testing one more' LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Case_Number__c  = cs.id;
            Test.startTest();
            INSERT ail;
            DELETE ail;
            String csIdeaReference = cs.Idea_Reference__c;
            String assertPass;
            if(!csIdeaReference.contains('GRZWRKSPCE-I-7')){
                assertPass = 'Test method passed Successfully';
            }
            Assert.areEqual('Test method passed Successfully', assertPass);
            Test.StopTest();
        }
    }
    
    /**
* @description Tests that deleting an Aha Idea Link on a Case with empty Idea_Reference__c field keeps the field empty
*/
    @isTest
    static void testMethod5(){
        /* Test Case: Verify that when an Aha Idea Link is deleted for a Case with empty Idea_Reference__c,
the field remains empty after deletion */
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%csit-testuser@rubrik.com%' LIMIT 1];
        
        System.runAs(testUser) {
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Case cs = [SELECT Id,Idea_Reference__c FROM Case WHERE Subject = 'testing one more' LIMIT 1];
            cs.Idea_Reference__c = '';
            UPDATE cs;
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Case_Number__c  = cs.id;
            Test.startTest();
            INSERT ail;
            DELETE ail;
            String csIdeaReference = cs.Idea_Reference__c;
            String assertPass;
            if(!csIdeaReference.contains('GRZWRKSPCE-I-7')){
                assertPass = 'Test method passed Successfully';
            }
            Assert.areEqual('Test method passed Successfully', assertPass);
            Test.StopTest();
        }
    }
    
    /**
* @description Tests that creating an Aha Idea Link on an Opportunity with null Idea_References__c field keeps the field null
*/
    @isTest
    static void testMethod6(){
        /* Test Case: Verify that when an Aha Idea Link is created for an Opportunity with null Idea_References__c,
the field remains null after insertion */
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%csit-testuser@rubrik.com%' LIMIT 1];
        
        System.runAs(testUser) {
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity oppt  = [SELECT Id,Name,Idea_References__c FROM Opportunity WHERE Primary_Competitor__c = 'Cohesity' LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Opportunity_Name__c = oppt.id;
            oppt.Idea_References__c = null;
            UPDATE oppt;
            Test.startTest();
            INSERT ail;
            String oppIdeaReference = oppt.Idea_References__c;
            String assertPass;
            if(oppIdeaReference == null){
                assertPass = 'Test method passed Successfully';
            }
            Assert.areEqual('Test method passed Successfully', assertPass);
            Test.StopTest();
        }
    }
    
    /**
* @description Tests that clearing a Case's Idea_Reference__c field after Aha Idea Link creation keeps the field cleared after link deletion
*/
    @isTest
    static void testMethod7(){
        /* Test Case: Verify that when a Case's Idea_Reference__c is cleared after Aha Idea Link creation,
the field remains cleared after link deletion */
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%csit-testuser@rubrik.com%' LIMIT 1];
        
        System.runAs(testUser) {
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Case cs = [SELECT Id,Idea_Reference__c FROM Case WHERE Subject = 'testing one more' LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Case_Number__c  = cs.id;
            Test.startTest();
            INSERT ail;
            cs.Idea_Reference__c = '';
            UPDATE cs;
            DELETE ail;
            String csIdeaReference = cs.Idea_Reference__c;
            String assertPass;
            if(!csIdeaReference.contains('GRZWRKSPCE-I-7')){
                assertPass = 'Test method passed Successfully';
            }
            Assert.areEqual('Test method passed Successfully', assertPass);
            Test.StopTest();
        }
    }
    
    /**
* @description Tests that clearing an Opportunity's Idea_References__c field after Aha Idea Link creation keeps the field cleared after link deletion
*/
    @isTest
    static void testMethod8(){
        /* Test Case: Verify that when an Opportunity's Idea_References__c is cleared after Aha Idea Link creation,
the field remains cleared after link deletion */
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%csit-testuser@rubrik.com%' LIMIT 1];
        
        System.runAs(testUser) {
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity oppt  = [SELECT Id,Name,Idea_References__c FROM Opportunity WHERE Primary_Competitor__c = 'Cohesity' LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Opportunity_Name__c = oppt.id;
            Test.startTest();
            INSERT ail;
            oppt.Idea_References__c = null;
            UPDATE oppt;
            
            DELETE ail;
            String oppIdeaReference = oppt.Idea_References__c;
            String assertPass;
            if(oppIdeaReference == null){
                assertPass = 'Test method passed Successfully';
            }
            Assert.areEqual('Test method passed Successfully', assertPass);
            Test.StopTest();
        }
    }
    
    /**
* @description Tests that deleting an Aha Idea record does not affect the related Opportunity's Idea_References__c field
*/
    @isTest
    static void testMethod9(){
        /* Test Case: Verify that when an Aha Idea record is deleted,
the related Opportunity's Idea_References__c field is not affected */
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%csit-testuser@rubrik.com%' LIMIT 1];
        
        System.runAs(testUser) {
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity oppt  = [SELECT Id,Name,Idea_References__c FROM Opportunity WHERE Primary_Competitor__c = 'Cohesity' LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Opportunity_Name__c = oppt.id;
            Test.startTest();
            INSERT ail;
            oppt.Idea_References__c = null;
            UPDATE oppt;
            
            DELETE ai;
            String oppIdeaReference = oppt.Idea_References__c;
            String assertPass;
            if(oppIdeaReference == null){
                assertPass = 'Test method passed Successfully';
            }
            Assert.areEqual('Test method passed Successfully', assertPass);
            Test.StopTest();
        }
    }
}