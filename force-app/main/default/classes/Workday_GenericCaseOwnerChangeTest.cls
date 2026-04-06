/**
 * Author       :   Saakshi Gupta
 * CreatedDate  :   29th May 2020
 * Description  :   Test class for Workday_GenericCaseOwnerChange
 */
@isTest(seeAllData=false)
public class Workday_GenericCaseOwnerChangeTest {

    @TestSetup
    public static void dataSetup() {
        insert new TriggerControl__c(Name='Case');
        insert new TriggerControl__c(Name='Entitlement');
        List<Case> caseList = new List<Case>();

        Account acc = new Account(name='testAcc');
        insert acc;

        Contact cont = new Contact(lastName='testCont');
        cont.Notify_For_case_creation__c = true;
        cont.Email='testcontact@test.com';
        cont.AccountId = acc.Id;
        insert cont;

        Case cs = new case();
        cs.Accountid = acc.id;
        cs.contactid = cont.id;
        cs.Subject ='JIRA12345';
        cs.JIRA_References_URL__c='SPARK-123456, SPARK-78910';
        cs.Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910';
        cs.Origin = 'Alert';
        cs.close_survey_triggered__c = false;
        cs.Article_Created__c = false;
        cs.Resolution_Details__c  = 'test';
        cs.Next_Step__c = 'Test';
        cs.Current_Status__c  = 'testStatus';
        cs.Priority = 'P1';
        cs.Alert_Key__c = 'Alert case 1 key';

        insert cs;

        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
        User u = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];

        // User u = new User(
        //     ProfileId = profileId,
        //     FirstName = 'Test User',
        //     LastName = 'last',
        //     Email = 'testuser@test.com',
        //     Username = System.now().millisecond() + 'testuser@test.com',
        //     CompanyName = 'TEST',
        //     Title = 'title',
        //     Alias = 'alias',
        //     TimeZoneSidKey = 'America/Los_Angeles',
        //     EmailEncodingKey = 'UTF-8',
        //     LanguageLocaleKey = 'en_US',
        //     LocaleSidKey = 'en_US',
        //     Employee_Time_Off__c = true,
        //     IsActive = true,
        //     ManagerId = UserInfo.getUserId());

        // insert u;
        updateCaseOwner1(u.Id);
    }

    // 3033: Common method for Case Update and asserts
    @future
    static void updateCaseOwner1(String uId){
        Case objCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'JIRA12345' Limit 1];
        objCase.OwnerId = uId;
        UPDATE objCase;
    }

    public static testMethod void testWorkday_GenericCaseOwnerChange() {
        Case caseRecord = [SELECT Id, US_Federal_Account__c, Owner.FirstName, Owner.LastName, Owner.Email, AccountId, 
                            Owner_Manager_Email__c, OwnerId, Automated_time_off_case_routing__c, Platform__c,Is_TA_Case__c
                            FROM Case];

        User currentUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];

        System.runAs(currentUser) {
            CaseComment cc = new CaseComment();
            cc.CommentBody = 'Test comment body';
            cc.ParentId = caseRecord.Id;
            cc.IsPublished = true;
            insert cc;
        }

        CaseComment cc = [SELECT Id, ParentId, CreatedDate FROM CaseComment];

        Map<Id, Case> caseMap = new Map<Id, Case>();
        Map<Id, DateTime> caseToCreatedDateMap = new Map<Id, DateTime>();
        caseMap.put(cc.ParentId, caseRecord);
        caseToCreatedDateMap.put(cc.ParentId, cc.CreatedDate);

        Test.startTest();

        Workday_GenericCaseOwnerChange.updateCaseOwnerToQueue(caseMap, caseToCreatedDateMap);

        Test.stopTest();

        Case updatedCase = [SELECT Id, OwnerId FROM Case];
        System.assert(updatedCase.OwnerId != caseRecord.OwnerId);
    }

    public static testMethod void testWorkday_GenericCaseOwnerChange2() {
        Account acc = [SELECT Id, US_Federal_Account__c FROM Account];
        acc.US_Federal_Account__c = true;
        update acc;

        Case caseRecord = [SELECT Id, US_Federal_Account__c, Owner.FirstName, Owner.LastName, Owner.Email, AccountId, 
                            Owner_Manager_Email__c, OwnerId, Automated_time_off_case_routing__c, Platform__c, Is_TA_Case__c
                            FROM Case];

        CaseComment cc = new CaseComment();
        cc.CommentBody = 'Test comment body';
        cc.ParentId = caseRecord.Id;
        cc.IsPublished = true;
        insert cc;

        CaseComment queriedCC = [SELECT Id, ParentId, CreatedDate FROM CaseComment];

        Map<Id, Case> caseMap = new Map<Id, Case>();
        Map<Id, DateTime> caseToCreatedDateMap = new Map<Id, DateTime>();
        caseMap.put(queriedCC.ParentId, caseRecord);
        caseToCreatedDateMap.put(queriedCC.ParentId, queriedCC.CreatedDate);

        Test.startTest();

        Workday_GenericCaseOwnerChange.updateCaseOwnerToQueue(caseMap, caseToCreatedDateMap);

        Test.stopTest();

        Case updatedCase = [SELECT Id, OwnerId FROM Case];
        System.assert(updatedCase.OwnerId != caseRecord.OwnerId);
    }

    // 3033: PTO User logic for both Federel and ASE Acc
    @isTest
    static void testPtoUserCheckForFederelAndAseAcc() {
        test.starttest();

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        objAcc.US_Federal_Account__c = true;
        UPDATE objAcc;

        Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
        INSERT objAse;

        User u = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];
        u.Employee_Time_Off__c = true;
        UPDATE u;
        Case caseRecord = [SELECT Id, US_Federal_Account__c, Owner.FirstName, Owner.Lastname, AccountId, 
                            Owner.Email, Owner_Manager_Email__c, Automated_time_off_case_routing__c, Platform__c,
                            is_Digital_Case__c, Is_TA_Case__c,Account.US_Federal_Account__c FROM Case WHERE Subject ='JIRA12345' Limit 1];
        test.stoptest();
        updateCaseOwner(u.Id, caseRecord.Id);
    }

    // 3033: PTO User logic for Federel Acc
    @isTest
    static void testPtoUserCheckForFederelAcc() {
        test.starttest();

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        objAcc.US_Federal_Account__c = true;
        UPDATE objAcc;
        
        User u = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];
        u.Employee_Time_Off__c = true;
        UPDATE u;
        Case caseRecord = [SELECT Id, US_Federal_Account__c, Owner.FirstName, Owner.Lastname, AccountId, 
                            Owner.Email, Owner_Manager_Email__c, Automated_time_off_case_routing__c, Platform__c,
                            is_Digital_Case__c, Is_TA_Case__c,Account.US_Federal_Account__c FROM Case WHERE Subject ='JIRA12345' Limit 1];
        test.stoptest();
        updateCaseOwner(u.Id, caseRecord.Id);
    }

    // 3033: PTO User logic for ASE Acc
    @isTest
    static void testPtoUserCheckForAseAcc() {
        test.starttest();

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        objAcc.US_Federal_Account__c = false;
        UPDATE objAcc;

        Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
        INSERT objAse;

        User u = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];
        u.Employee_Time_Off__c = true;
        UPDATE u;
        Case caseRecord = [SELECT Id, US_Federal_Account__c, Owner.FirstName, Owner.Lastname, AccountId, 
                            Owner.Email, Owner_Manager_Email__c, Automated_time_off_case_routing__c, Platform__c,
                            is_Digital_Case__c, Is_TA_Case__c,Account.US_Federal_Account__c FROM Case WHERE Subject ='JIRA12345' Limit 1];
        test.stoptest();
        updateCaseOwner(u.Id, caseRecord.Id);
    }
    
    // 3033: Common method for Case Update and asserts
    @future
    static void updateCaseOwner(Id seUserId, String caseId){

        Case objCase = [SELECT Id, OwnerId FROM Case WHERE Id =: caseId];
        objCase.OwnerId = seUserId;
        UPDATE objCase;
        User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];
        System.runAs(rubProfSerUser){
            CaseComment cc = new CaseComment();
            cc.CommentBody = 'Test comment body';
            cc.ParentId = objCase.Id;
            cc.IsPublished = true;
            insert cc;
            System.assertEquals(seUserId, [SELECT Id, OwnerId FROM Case WHERE Id =: objCase.Id].OwnerId);
        }
    }
}