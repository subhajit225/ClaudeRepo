@isTest
public with sharing class GetFeedbackSurveyResponseHandlerTest {
    
    @TestSetup
    static void makeData(){
        insert new TriggerControl__c(Name='GetFeedbackSurveyResponses');
        Account acc = new Account(name='testAcc');
        INSERT acc;

        Contact cont = new Contact(lastName='testCont');
        cont.AccountId=acc.Id;
        INSERT cont;

        User supUser = [SELECT Id FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND isActive = true Limit 1];
        Group openQueue = [SELECT Id, Name, DeveloperName FROM group where DeveloperName = 'Unassigned_Cases' Limit 1];

        List<Case> caseList = new List<Case>{ new case(Accountid = acc.id, contactid = cont.id, Subject ='JIRA12345', JIRA_References_URL__c='SPARK-123456, SPARK-78910',
                                                Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910', Origin = 'Alert', close_survey_triggered__c = false, Resolution__c = 'No Response',
                                                Article_Created__c = false, Resolution_Details__c  = 'test', Next_Step__c = 'Test', Current_Status__c  = 'testStatus',
                                                Priority = 'P1', CT_Rating__c = 'Gold', JIRA_Status__c = 'test', OwnerId = supUser.Id),
                                            new case(Accountid = acc.id, contactid = cont.id, Subject ='JIRA54321', JIRA_References_URL__c='SPARK-654321, SPARK-098765',
                                                Jira_Reference_urls__c= 'SPARK-654321, SPARK-09876544', Origin = 'Alert', close_survey_triggered__c = false, Resolution__c = 'No Response',
                                                Article_Created__c = false, Resolution_Details__c  = 'test', Next_Step__c = 'Test', Current_Status__c  = 'testStatus',
                                                Priority = 'P1', CT_Rating__c = 'Gold', JIRA_Status__c = 'test', OwnerId = openQueue.Id)};
        INSERT caseList;

        test.startTest();
        GetFeedback_Survey_Response__c objGetFdbk = new GetFeedback_Survey_Response__c();
        objGetFdbk.Name = 'GetFeedback Survey Response: Greetings [ContactName]!';
        objGetFdbk.Case_ID__c = caseList[0].Id;
        INSERT objGetFdbk;
        test.stopTest();
        System.assertEquals(caseList[0].OwnerId, [SELECT Id, Survey_Owner__c FROM GetFeedback_Survey_Response__c WHERE Id =: objGetFdbk.Id].Survey_Owner__c);
    }
    
    @isTest
    static void updateGetFeedbackSurveyResponse(){
        
        Case objCase = [SELECT Id, OwnerId FROM Case WHERE Subject ='JIRA12345'];
        User sysUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true Limit 1];

        test.startTest();
        GetFeedback_Survey_Response__c objGetFdbk = [SELECT Id FROM GetFeedback_Survey_Response__c WHERE Name = 'GetFeedback Survey Response: Greetings [ContactName]!'];
        objGetFdbk.Name = 'Updated GetFeedback Survey Response: Greetings [ContactName]!';
        objGetFdbk.Case_ID__c = objCase.Id;
        UPDATE objGetFdbk;
        test.stopTest();
        System.assertEquals(objCase.OwnerId, [SELECT Id, Survey_Owner__c FROM GetFeedback_Survey_Response__c WHERE Id =: objGetFdbk.Id].Survey_Owner__c);
        
    }

    @isTest
    static void updateQueueGetFeedbackSurveyResponse(){
        try {
            Case objCase = [SELECT Id FROM Case WHERE Subject ='JIRA54321'];
            test.startTest();
                GetFeedback_Survey_Response__c objGetFdbk = [SELECT Id FROM GetFeedback_Survey_Response__c WHERE Name = 'GetFeedback Survey Response: Greetings [ContactName]!'];
                objGetFdbk.Name = 'Updated GetFeedback Survey Response: Greetings [ContactName]!';
                objGetFdbk.Case_ID__c = objCase.Id;
                UPDATE objGetFdbk;
            test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Group Can\'t be assigned to Survey Owner'),'Group Can\'t be assigned to Survey Owner');    
        }
        
    }

    @isTest
    static void batchGetFeedbackSurveyResponseTest(){
        
        test.startTest();
        GetFeedback_Survey_Response__c objgf = [SELECT Id, Case_ID__c, Case_ID__r.OwnerId, Case_ID__r.Owner.ProfileId, Survey_Owner__c  FROM GetFeedback_Survey_Response__c Limit 1];
        objgf.Survey_Owner__c = null;
        UPDATE objgf;

        BatchPopulateGetFeedbackSurveyOwner objBatch = new BatchPopulateGetFeedbackSurveyOwner(); 
        Database.QueryLocator ql = objBatch.start(null);
        objBatch.execute(null,new List<GetFeedback_Survey_Response__c>{objgf});
        objBatch.Finish(null);
        test.stopTest();

        System.assertNotEquals(null, [SELECT Id, Survey_Owner__c FROM GetFeedback_Survey_Response__c WHERE Id =: objgf.Id].Survey_Owner__c);
        
    }
    
}