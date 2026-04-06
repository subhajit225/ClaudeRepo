/**
* @description Test class for LinkAhaController
* @test
* @author Raveesh Layal
* @date 2025-08-01
*/
@isTest
public class LinkAhaController_Test {
    
    /**
* @description Test setup method to create test data including Account, Contact, Opportunities, Cases, and Aha Ideas.
*/
    @testSetup static void dataSetup() {
        //Creating Account
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        User u = new User(
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
        insert u;
        System.runAs(u){
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
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.Account_Preference__c = 'Advisory Account; Critical Account; CSM Account';
            act.Heads_Up_to_Support_Team__c = 'Hello';
            act.Strategic_Account__c =  true;
            insert act;
            
            //Creating Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
                        Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert con;
            
            //Creating Opportunities
            Map<String, Object>  oppMap = new Map<String, Object> {
                'AccountId' => act.Id
                    };
                        List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 6, oppMap);
            
            integer i=0;
            for(Opportunity opp: opptyList){
                if(i==0){
                    opp.Next_Step__c='c-co';
                    opp.ACV_Amount__c = 121;
                }
                if(i==1){
                    opp.Next_Step__c='TEST Cohesity';
                    opp.ACV_Amount__c = 121;
                }
                if(i==2){
                    opp.Primary_Competitor__c = 'Cohesity';
                    opp.ACV_Amount__c = 121;
                }
                if(i==3){
                    opp.Other_Primary_Competitor__c = 'Testing Cohesity Test';
                    opp.ACV_Amount__c = 121;
                }
                if(i==4){
                    opp.Win_Loss_Comments__c = 'Cohesity Test';
                    opp.ACV_Amount__c = 121;
                }
                if(i==5){
                    //opp.Cohesity_Deal__c = true; //SAL26-704:Commented
                    opp.ACV_Amount__c = 121;
                }
                i++;
            }
            insert opptyList;
            
            //Creating Cases
            List<Case>  caseList= New List<Case>();
            Map<String, Object> caseMap = new Map<String, Object> {
                'Subject' => 'testing one more',
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
            
            //Creating Aha Idea records
            Aha_Ideas__c ai1 = new Aha_Ideas__c();
            ai1.name = 'Idea Parent Test Record';
            ai1.Aha_Idea_Number__c = '7252627131616179867';
            ai1.Aha_Unique_ID__c = 'GRZWRKSPCE-I-16';
            ai1.Idea_Description__c = 'Account 1 idea 2 (Case)';
            ai1.Status__c = 'New';
            insert ai1;
            
            Aha_Ideas__c ai = new Aha_Ideas__c();
            ai.name = 'Idea Parent Test Record';
            ai.Aha_Idea_Number__c = '7252627131616179867';
            ai.Aha_Unique_ID__c = 'GRZWRKSPCE-I-7';
            ai.Idea_Description__c = 'Account 1 idea 2 (Case)';
            ai.Status__c = 'New';
            ai.Duplicate_of__c = ai1.Id;
            insert ai;
        }
    }
    
    /**
* @description Test searching Opportunity records linked to an Aha Idea via searchRecords method.
*/
    @isTest
    static void testMethodForOpportunity(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity opptyList  = [SELECT Id,Name FROM Opportunity WHERE Primary_Competitor__c = 'Cohesity' LIMIT 1];
            Opportunity opptyList1  = [SELECT Id,Name FROM Opportunity WHERE Other_Primary_Competitor__c = 'Testing Cohesity Test' LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Opportunity_Name__c = opptyList.id;
            INSERT ail;
            
            Test.startTest();
            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = opptyList1.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            List<LinkAhaController.SearchResult> result = LinkAhaController.searchRecords('Test Opportunity',ai.Id);
            String oppName = result[0].Name;
            System.assertEquals('Test Opportunity3',oppName);
            Test.stopTest();
        }
    }
    
    /**
* @description Test searching Case records linked to an Aha Idea via searchRecords method.
*/
    @isTest
    static void testMethodForCase(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Case cs = [SELECT Id FROM Case WHERE Subject = 'testing one more' LIMIT 1];
            Case caseTest = [SELECT Id FROM Case WHERE Subject = 'testing one more 1' LIMIT 1];
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Case_Number__c = cs.id;
            INSERT ail;
            
            Test.startTest();
            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = caseTest.Id;
            Test.setFixedSearchResults(fixedSearchResults);
            List<LinkAhaController.SearchResult> result = LinkAhaController.searchRecords('testing',ai.Id);
            String CssName = result[0].Subject;
            System.assertEquals('testing one more 1',CssName);
            Test.stopTest();
        }
    }
    
    /**
* @description Test linking Aha Idea with Opportunity record and verify Account Preference update.
*/
    @isTest
    static void testMethodForOpportunityLink() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account act = [SELECT Id FROM Account LIMIT 1];
            Aha_Ideas__c ai = [SELECT Id,Aha_Unique_ID__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity opptyList  = [SELECT Id FROM Opportunity LIMIT 1];
            
            Map<String,String> objectRecordIdAndAccountId = New Map<String,String>();
            objectRecordIdAndAccountId.put(opptyList.Id,act.Id);
            
            Test.startTest();
            LinkAhaController.linkAhaIdeaRecord(ai.Id,objectRecordIdAndAccountId);
            Aha_Ideas__c ai1 = [SELECT Id,Aha_Unique_ID__c,Account_Preference__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            System.assertNotEquals('',ai1.Account_Preference__c);
            Test.stopTest();
        }
    }
    
    /**
* @description Test linking Aha Idea with Case record and verify Account Preference update.
*/
    @isTest
    static void testMethodForCaseLink() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account act = [SELECT Id,Heads_Up_to_Support_Team__c,Account_Preference__c,Strategic_Account__c FROM Account WHERE Strategic_Account__c = true];
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Case cs = [SELECT Id FROM Case LIMIT 1];
            
            Map<String,String> objectRecordIdAndAccountId = New Map<String,String>();
            objectRecordIdAndAccountId.put(cs.Id,act.Id);
            
            Test.startTest();
            LinkAhaController.linkAhaIdeaRecord(ai.Id,objectRecordIdAndAccountId);
            Aha_Ideas__c ai1 = [SELECT Id,Aha_Unique_ID__c,Account_Preference__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            System.assertNotEquals('',ai1.Account_Preference__c);
            Test.stopTest();
        }
    }
    
    /**
* @description Test linking Aha Idea record functionality with Opportunity data.
*/
    @isTest
    static void testMethodForlinkAhaIdeaRecord() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account act = [SELECT Id,Heads_Up_to_Support_Team__c,Account_Preference__c,Strategic_Account__c FROM Account WHERE Strategic_Account__c = true];
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity opptyList  = [SELECT Id FROM Opportunity LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Opportunity_Name__c = opptyList.id;
            INSERT ail;
            
            Map<String,String> objectRecordIdAndAccountId = New Map<String,String>();
            objectRecordIdAndAccountId.put(opptyList.Id,act.Id);
            List<Opportunity> recordlist = New List<Opportunity>();
            recordlist.add(opptyList);
            Test.startTest();
            LinkAhaController.linkAhaIdeaRecord(ai.Id,objectRecordIdAndAccountId);
            Aha_Ideas__c ai1 = [SELECT Id,Aha_Unique_ID__c,Account_Preference__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            System.assertNotEquals('',ai1.Account_Preference__c);
            Test.stopTest();
        }
    }
    
    /**
* @description Test linking Aha Idea record functionality with Case data.
*/
    @isTest
    static void testMethodForCaselinkAhaIdeaRecord() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account act = [SELECT Id,Heads_Up_to_Support_Team__c,Account_Preference__c,Strategic_Account__c FROM Account WHERE Strategic_Account__c = true];
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Case cs = [SELECT Id FROM Case LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Case_Number__c = cs.id;
            INSERT ail;
            
            Map<String,String> objectRecordIdAndAccountId = New Map<String,String>();
            objectRecordIdAndAccountId.put(cs.Id,act.Id);
            List<case> recordlist = New List<case>();
            recordlist.add(cs);
            Test.startTest();
            LinkAhaController.linkAhaIdeaRecord(ai.Id,objectRecordIdAndAccountId);
            Aha_Ideas__c ai1 = [SELECT Id,Aha_Unique_ID__c,Account_Preference__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            System.assertNotEquals('',ai1.Account_Preference__c);
            Test.stopTest();
        }
    }
    
    /**
* @description Test fetching Opportunity and Case records linked to a given Aha Idea.
*/
    @isTest
    static void testMethodForGetOpptyRecords(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account act = [SELECT Id,Heads_Up_to_Support_Team__c,Account_Preference__c,Strategic_Account__c FROM Account WHERE Strategic_Account__c = true];
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity opptyList  = [SELECT Id FROM Opportunity LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Opportunity_Name__c = opptyList.id;
            INSERT ail;
            Test.startTest();
            List<LinkAhaController.SearchResult> result = LinkAhaController.getOpptyandCaseRecords(ai.Id);
            System.assertEquals(opptyList.id,result[0].Id);
            Test.stopTest();
        }
    }
    
    /**
* @description Test fetching Case records and Account details for given Aha Idea.
*/
    @isTest
    static void testMethodForGetCaseRecords(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account act = [SELECT Id,Heads_Up_to_Support_Team__c,Account_Preference__c,Strategic_Account__c FROM Account WHERE Strategic_Account__c = true];
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Case cs = [SELECT Id FROM Case LIMIT 1];
            
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Case_Number__c = cs.id;
            INSERT ail;
            
            Set<String> accIds = New Set<String>();
            accIds.add(act.Id);
            Test.startTest();
            LinkAhaController.getOpptyandCaseRecords(ai.Id);
            LinkAhaController.getAccountDetails(accIds);
            List<LinkAhaController.SearchResult> result = LinkAhaController.getOpptyandCaseRecords(ai.Id);
            System.assertEquals(cs.id,result[0].Id);
            Test.stopTest();
        }
    }
    
    /**
* @description Test unlinking Aha Idea from multiple Opportunities via unlinkIdeaWithCaseOrOppty method.
*/
    @isTest
    static void testMethodForunlinkIdeaWithOppty() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account act = [SELECT Id,Heads_Up_to_Support_Team__c,Account_Preference__c,Strategic_Account__c FROM Account WHERE Strategic_Account__c = true];
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Opportunity opptyList  = [SELECT Id FROM Opportunity WHERE Primary_Competitor__c = 'Cohesity' LIMIT 1];
            Opportunity opptyList1  = [SELECT Id FROM Opportunity WHERE Other_Primary_Competitor__c = 'Testing Cohesity Test' LIMIT 1];
            
            List<Aha_Idea_Link__c> ailList = New List<Aha_Idea_Link__c>();
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Opportunity_Name__c = opptyList1.id;
            ailList.add(ail);
            
            Aha_Idea_Link__c ail1 = new Aha_Idea_Link__c();
            ail1.Aha_Ideas__c = ai.id;
            ail1.Opportunity_Name__c = opptyList.id;
            ailList.add(ail1);
            INSERT ailList;
            
            Map<String,String> objectRecordIdAndAccountId = New Map<String,String>();
            objectRecordIdAndAccountId.put(opptyList.Id,act.Id);
            List<Opportunity> recordlist = New List<Opportunity>();
            recordlist.add(opptyList);
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HTTPMockTestFactory());
            LinkAhaController.unlinkIdeaWithCaseOrOppty(ai.Id,recordlist,objectRecordIdAndAccountId);
            System.assertEquals(1, [SELECT COUNT() FROM Aha_Idea_Link__c WHERE Id = :ail.id]);
            Test.stopTest();
        }
    }
    
    /**
* @description Test unlinking Aha Idea from multiple Cases via unlinkIdeaWithCaseOrOppty method.
*/
    @isTest
    static void testMethodForunlinkIdeaWithCase() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account act = [SELECT Id,Heads_Up_to_Support_Team__c,Account_Preference__c,Strategic_Account__c FROM Account WHERE Strategic_Account__c = true];
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Case cs = [SELECT Id FROM Case WHERE Subject = 'testing one more' LIMIT 1];
            Case caseTest = [SELECT Id FROM Case WHERE Subject = 'testing one more 1' LIMIT 1];
            
            List<Aha_Idea_Link__c> ailList = New List<Aha_Idea_Link__c>();
            Aha_Idea_Link__c ail = New Aha_Idea_Link__c();
            ail.Aha_Ideas__c = ai.id;
            ail.Case_Number__c = cs.id;
            ailList.add(ail);
            
            Aha_Idea_Link__c ail1 = New Aha_Idea_Link__c();
            ail1.Aha_Ideas__c = ai.id;
            ail1.Case_Number__c = caseTest.id;
            ailList.add(ail1);
            INSERT ailList;
            
            Map<String,String> objectRecordIdAndAccountId = New Map<String,String>();
            objectRecordIdAndAccountId.put(cs.Id,act.Id);
            List<case> recordlist = New List<case>();
            recordlist.add(cs);
            
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HTTPMockTestFactory());
            LinkAhaController.unlinkIdeaWithCaseOrOppty(ai.Id,recordlist,objectRecordIdAndAccountId);
            System.assertEquals(1, [SELECT COUNT() FROM Aha_Idea_Link__c WHERE Id = :ail1.id]);
            Test.stopTest();
        }
    }
    
    /**
* @description Test unlinking Aha Idea when no links exist via unlinkIdeaWithCaseOrOppty method.
*/
    @isTest
    static void testMethodForunlinkIdeaWithCaseNoLinks() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account act = [SELECT Id,Heads_Up_to_Support_Team__c,Account_Preference__c,Strategic_Account__c FROM Account WHERE Strategic_Account__c = true];
            Aha_Ideas__c ai = [SELECT Id FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-7'];
            Case cs = [SELECT Id FROM Case WHERE Subject = 'testing one more' LIMIT 1];
            Case caseTest = [SELECT Id FROM Case WHERE Subject = 'testing one more 1' LIMIT 1];
            
            Map<String,String> objectRecordIdAndAccountId = New Map<String,String>();
            objectRecordIdAndAccountId.put(cs.Id,act.Id);
            List<case> recordlist = New List<case>();
            recordlist.add(cs);
            
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HTTPMockTestFactory());
            LinkAhaController.unlinkIdeaWithCaseOrOppty(ai.Id,recordlist,objectRecordIdAndAccountId);
            System.assertEquals(1, [SELECT COUNT() FROM Aha_Ideas__c WHERE Id = :ai.id]);
            Test.stopTest();
        }
    }
    
}