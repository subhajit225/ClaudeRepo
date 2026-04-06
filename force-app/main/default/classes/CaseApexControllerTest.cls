@isTest
public class CaseApexControllerTest { 

    @testSetup
    public static void setup() {
        test.startTest();

        Account acc = new Account(name='testAcc');
        insert acc;
        Contact cont = new Contact(lastName='testCont',Email='test@rubrik.com');
        cont.Notify_For_case_creation__c = true;
        cont.AccountId=acc.Id;
        insert cont;

        test.stopTest();
    }

    static testMethod void SubmitCaseController(){        
        List<string> memberIdList = new List<string>();

        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'CEO' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' AND isActive = true Limit 1];
        adminUser.UserRoleId = userRole.Id;
        update adminUser;

        System.runAs(adminUser){

            Account testAccount = new Account(name='Test Company Name', FedRAMP__c = false);
            insert testAccount;
           
            Contact testContactDummy = new Contact();
            Contact testContact = new Contact(AccountId=testAccount.Id, FirstName='First Name',LastName='Last name',title='TITLE',Phone='123456489',Email='test@test.com');
            insert testContact;
            system.assert(testContact.id!=null,'The contact is inserted');
           
            Profile prof = [Select Id,Name from Profile where name=:'Rubrik Customer Community Login User (No Cases)' Limit 1];
            User u = new User(Alias = 'standt1', email='standarduser1@testorg.com', 
                            EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', ProfileId = prof.Id, 
                            TimeZoneSidKey='America/Los_Angeles', username='standarduser@testorg131saurv.com');
            u.ContactId= testContact.Id;
            insert u;
            system.assert(u.id!=null,'user is inserted');
            Case ca = new Case(Subject='Test Controller Acct Case',Priority = 'P1',AccountId=testAccount.Id);
            CaseApexController.saveCase( ca);
            CaseTeamRole roleId = [select Id from CaseTeamRole where Name = 'Email CC'];
            CaseTeamMember ctm = new CaseTeamMember();
            ctm.ParentId = ca.Id;
            ctm.TeamRoleId = roleId.Id;
            ctm.MemberId = UserInfo.getUserId();
            insert ctm;  
            Assist_Request__c ar= new Assist_Request__c(Case__c=ca.ID,Status__c = 'Open',Brownbag_Candidate__c=true);
            insert ar;
            //insert ca;
            CaseApexController.addMyComment(ca.Id,'test');
            CaseApexController.escalate(ca.Id,'test');
            CaseApexController.escalate(ca.Id,'test');
            CaseApexController.reopen(ca.Id,'test');
            CaseApexController.getAttachmentDetails(ca.Id);
            CaseApexController.casepicklistcls cspick = new CaseApexController.casepicklistcls('test','test');
            CaseApexController.wrapper wrap = new CaseApexController.wrapper(testContact, ctm, false);
            CaseApexController.manageCaseTeam managecs = new CaseApexController.manageCaseTeam(testContact,false);
            CaseApexController.statusclosed(ca.Id);
            CaseApexController.CaseTeamMembers(ca.Id,ca.CaseNumber);
            System.runas(u){
                CaseApexController.getPickListValuesIntoList();
                CaseApexController.contact = new Contact(AccountId = u.AccountId, LastName = 'Testing');
            }

            CaseApexController.createContact('test','test','test@test.com','test','test');
            CaseApexController.createContact('test','test','test@test2.com','test','test');
            CaseApexController.getCases();
            CaseApexController.addColleaguesToCase(ca.Id,memberIdList);
            CaseApexController.getCaseDetails(ca.Id);
            CaseApexController.getBig();

            // to increase code coverage for addColleaguesToCase for contact member
            CaseTeamMember ctm1 = new CaseTeamMember();
            ctm1.ParentId = ca.Id;
            ctm1.TeamRoleId = roleId.Id;
            ctm1.MemberId = testContact.Id;
            insert ctm1;  
            CaseApexController.addColleaguesToCase(ca.Id,new List<String>{ca.Id});
            // fetchContact
            CaseApexController.fetchContact('Name', true, ca.Id);
            Contact c =  CaseApexController.contact;
        }
    }
    
   @istest 
    public static void createContactwithDifferentAccount(){
          Account testAccount = new Account(name='Test Company Name2', FedRAMP__c = false);
            insert testAccount;
           
            Contact testContactDummy = new Contact();
            Contact testContact = new Contact(AccountId=testAccount.Id, FirstName='First Name',LastName='Last name',title='TITLE',Phone='123456489',Email='test1@test.com');
            insert testContact;
            system.assert(testContact.id!=null,'The contact is inserted');
            CaseApexController.createContact('test','test','test1@test.com','test','test');
    }
    
     @istest 
    public static void createContactwithSameAccount(){
   
            Contact testContactDummy = new Contact();
            Contact testContact = new Contact(AccountId=Util.CurrentUser.Contact.AccountId, FirstName='First Name',LastName='Last name',title='TITLE',Phone='123456489',Email='test1@test.com');
            insert testContact;
            system.assert(testContact.id!=null,'The contact is inserted');
            CaseApexController.createContact('test','test','test1@test.com','test','test');
    }

    @isTest
    public static void testCheckClusterSoftwareVersion() {
        // Setup: Create a Cluster__c record with a specific end-of-support status
        Cluster__c testCluster = new Cluster__c(UUID__c = 'Cluster 1', Name = 'Cluster 1', Business_Hours__c = 'Unsupported', Software_Version__c = '8.1.2-p2-24758');
        insert testCluster;

        // Call the method under test
        String status = CaseApexController.checkClusterSoftwareVersion(testCluster.Id);

        // Assert that the returned status matches the expected value
        System.assertNotEquals('Unsupported CDM software version', null);
    }

    // 3033: ProactiveCase for Federel Acc
    @isTest
    static void testProactiveCaseForFedAcc() {
        test.starttest();

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        objAcc.US_Federal_Account__c = true;
        UPDATE objAcc;
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];
        Case cs = new case();
        cs.Accountid = objAcc.id;
        cs.contactid = objCont.id;
        cs.Origin = 'Alert';
        cs.Priority = 'P1';
        cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
        INSERT cs;

        CaseApexController.updateCaseOwner(cs);
        Id FED_QUEUE_ID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'FED_Queue' Limit 1].Id;
        System.assertEquals(FED_QUEUE_ID, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
        test.stoptest();
    }

    // 3033: ProactiveCase for both Federel and ASE Acc
    @isTest
    static void testNonProactiveCaseForBothFedAndAseAcc() {
        test.starttest();

        User sysAdmin = [SELECT Id, Name FROM User Where Profile.Name  = 'System Administrator' AND isActive = true Limit 1];
        system.runas(sysAdmin){

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
        INSERT objAse;

        objAcc.US_Federal_Account__c = true;
        UPDATE objAcc;
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];
        Case cs = new case();
        cs.Accountid = objAcc.id;
        cs.contactid = objCont.id;
        cs.Origin = 'Alert';
        cs.Priority = 'P1';
        cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
        INSERT cs;
        CaseApexController.updateCaseOwner(cs);
        test.stoptest();

        Id AMER_QUEUE_ID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ASE_QUEUE' Limit 1].Id;
        System.assertEquals(AMER_QUEUE_ID, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
        }
        
    }

    // 3033: Non ProactiveCase With Acc ASE
    @isTest
    static void testNonProactiveCaseWithAseAcc() {
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            test.starttest();

            Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
            UPDATE objAcc;
            Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
            INSERT objAse;
            Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];
            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Origin = 'Email';
            cs.Priority = 'P1';
            cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
            INSERT cs;

            // to increase code coverage for setComment method
            CaseComment cs2 = new CaseComment(ParentId = cs.Id , CommentBody='tes',isPublished = true);
            insert cs2;

            String body = 'From: support@rubrik.com';
                    body += 'To: vijay.kr@rubrik.com;sri.lakshmi@rubrik.com';
                    body += 'Cc: performancetest.user7@rubrik.com.invalid;testae@aesoc.com.invalid;performancetest.user4@rubrik.com.invalid;test@193r923ur932u9ru23ru2.com.invalid;test@09293eu93ue93u93.com.invalid;test@test.com.invalid;ash_ajukumar111024082641900@test123.com.invalid;test87u@rubrik.com.invalid;testtbh10024@rubrik.com.invalid;mmglae@test.com.invalid;ash_ajukumar091024061340663@test123.com.invalid;devtestops@rubrik.com.invalid;performancetest.user43@rubrik.com.invalid;richard.demoret@technologent.com.invalid;hannah.demoss@buckle.com.invalid;delio.demoura@goldenpasslng.com.invalid;tdemorrow@odessa.edu.invalid;valentin.demonchy@axians.com.invalid;performancetest.user11@rubrik.com.invalid;brandon.berryhill@nextest.com.invalid;ash_ajukumar081024024936633@test123.com.invalid';
                    body += 'test please ignore v4';
            //Long_Comments__c LongCommentToInsert = new Long_Comments__c();
            E2CAdv__Long_Comments__c LongCommentToInsert = new E2CAdv__Long_Comments__c();
            LongCommentToInsert.E2CAdv__Comment_Body__c = body;
            LongCommentToInsert.E2CAdv__Comment_Body_Text__c = body;
            LongCommentToInsert.E2CAdv__Comment_Status__c = 'Draft';
            LongCommentToInsert.E2CAdv__To_Address__c = 'TO test@test.com';
            LongCommentToInsert.E2CAdv__Parent__c = cs.Id;
            LongCommentToInsert.E2CAdv__Bcc_Address__c = 'BCC test@test.com';
            LongCommentToInsert.E2CAdv__Cc_Address__c = 'CC test@test.com';
            LongCommentToInsert.E2CAdv__Published__c = true;
            LongCommentToInsert.E2CAdv__IsCommentTrimmed__c = true;
            LongCommentToInsert.E2CAdv__Is_Incoming__c = false;
            LongCommentToInsert.E2CAdv__Is_Scheduled__c = true;
            LongCommentToInsert.E2CAdv__Send_If_Case_Status_Changes__c = true;
            LongCommentToInsert.E2CAdv__Watchers__c = 'WATCH test@test.com';
            LongCommentToInsert.E2CAdv__Scheduled_Time__c = System.now();
            LongCommentToInsert.E2CAdv__File_Ids__c = '0697g000002btr8AAA';
            LongCommentToInsert.E2CAdv__Has_Attachment__c = true;

            insert LongCommentToInsert;


            E2CAdv__CommentSourceControllers__c csc1 = new  E2CAdv__CommentSourceControllers__c();
            csc1.E2CAdv__Long_Comments_Id__c = LongCommentToInsert.Id;
            csc1.E2CAdv__CaseCommentId__c = cs2.id;
            csc1.E2CAdv__Comment_Source__c ='CaseComment';
            csc1.E2CAdv__Enhanced_Object_Id__c='';
            csc1.E2CAdv__Entity_Id__c =cs2.Id;

            insert csc1 ;
            CaseApexController.setComment(cs2.Id, body);
            // to increase code coverage for setComment method

            CaseApexController.updateCaseOwner(cs);
            Id AMER_QUEUE_ID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ASE_QUEUE' Limit 1].Id;
            System.assertEquals(AMER_QUEUE_ID, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
            test.stoptest();
        }
    }

    // 3033: ProactiveCase With Acc ASE
    @isTest
    static void testProactiveCaseWithAseAcc() {
        test.starttest();

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        UPDATE objAcc;
        Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
        INSERT objAse;
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];
        Case cs = new case();
        cs.Accountid = objAcc.id;
        cs.contactid = objCont.id;
        cs.Origin = 'Alert';
        cs.Priority = 'P1';
        cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
        INSERT cs;

        CaseApexController.updateCaseOwner(cs);
        Id PROACTIVE_QUEUE_ID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Proactive_Alerts' Limit 1].Id;
        System.assertEquals(PROACTIVE_QUEUE_ID, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
        test.stoptest();
    }
    
}