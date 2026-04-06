@isTest(seeAllData=false)
public class CaseCommentTrigger_Test {

    @TestSetup
    public static void dataSetup() {
        UserRole userrole = [Select Id From UserRole Where DeveloperName='CEO' Limit 1];
        User adminUser = [Select Id, UserRoleId, ProfileId From User Where Profile.Name='System Administrator' AND isActive = true AND UserRoleId != null Limit 1];
        
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(
        setupownerid = UserInfo.getUserId());
        sdb.Disable_Email_Alerts__c = true;
        sdb.Disable_Case_Validation_Rules__c= true;
        sdb.Disable_Entitlement_Validation_Rules__c = true;
        sdb.Disable_Case_Workflow_Rules__c = true;
        
        Test.startTest();
        
        System.runAs(adminUser) {
            insert sdb;
            insert new TriggerControl__c(Name='Case');
            insert new TriggerControl__c(Name='Entitlement');
        }
        
        adminUser.UserRoleId = userrole.Id;
        adminUser.Employee_Time_Off__c = true;
        adminUser.Automated_time_off_case_routing__c = 'Enable';
        adminUser.FirstName = 'Proactive';
        adminUser.LastName = 'campaign';
        update adminUser;
        
        Test.stopTest();     
        
        Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
        System.runAs(adminUser){
            adminUser.UserRoleId = userRole.Id;
            update adminUser;
            Account acc = new Account(name='testAcc', US_Federal_Account__c = true);
            insert acc;
            
            Contact cont = new Contact(lastName='testCont');
            cont.Notify_For_case_creation__c = true;
            cont.Email='testcontact@test.com';
            cont.AccountId = acc.Id;
            insert cont;
            
            Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Community Super User'].Id;
            Id itUserProfile = [SELECT Id FROM Profile WHERE Name ='Rubrik IT User']?.Id;
            List<User> userList = new List<User>();
            User u = new User(
                ProfileId = profileId,
                ContactId = cont.Id,
                FirstName = 'Test Contact',
                LastName = 'User',
                Email = 'testcontactuser@test.com',
                Username = System.now().millisecond() + 'testcontactuser@test.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                IsActive = true);
            userList.add(u);

            User u2 = new User(
                ProfileId = adminUser.ProfileId,
                FirstName = 'Test Contact',
                LastName = 'User',
                Email = 'testcontactuser3568@test.com',
                Username = System.now().millisecond() + 'testcontactuser3568@test.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                IsActive = true);
            userList.add(u2);
            
            insert userList;
            
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
            cs.Priority = 'P3';
            cs.Alert_Key__c = 'Alert case 1 key';
            cs.RecordTypeId = successCaseId;
            cs.Customer_First_Contact__c = null;
            insert cs;
        }
        
        User usr = [SELECT Id,Email FROM User WHERE Email=: 'testcontactuser3568@test.com'];
        Contact con1 = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Name=:'testCont' LIMIT 1];
        System.runAs(usr){
			Case cs1 = new case();
            cs1.Accountid = con1.AccountId;
            cs1.contactid = con1.id;
            cs1.Subject ='JIRA123456';
            cs1.RecordTypeId = successCaseId;
            cs1.Priority = 'P3';
            cs1.Automated_time_off_case_routing__c = 'Enable';
            cs1.Automated_time_off_case_routing__c = 'Automatic';
            cs1.Origin ='Phone';
            cs1.Customer_First_Contact__c = null;
            insert cs1;
            
            CaseComment cc = new CaseComment();
            cc.CommentBody = 'Test comment body';
            cc.ParentId = cs1.Id;
            cc.IsPublished = true;
            insert cc;
            
            CaseCommentTriggerHandler.ChangeInitialMilestoneFlagColor(
                new Map<Id, Case>{ cs1.Id => cs1},null
            );
            Case objCase = [SELECT Id, Last_Customer_Update__c FROM Case WHERE Id =: cs1.Id];
        } 
    }

    private static testmethod void testCaseCommentTrigger(){
        Case cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c  FROM Case WHERE Subject ='JIRA12345' Limit 1];

        CaseComment cm = new CaseComment(ParentId = cs.id, IsPublished = true, CommentBody = 'test comment');
        insert cm;
        
        cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c  FROM Case WHERE Subject ='JIRA12345' Limit 1];
        System.assertEquals(cs.CaseCommentsPublic__c, 1);
        
        cm.IsPublished = false;
        update cm;
        
        cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c, LastPrivateCommentCreatedDate__c FROM Case WHERE Subject ='JIRA12345' Limit 1];
        System.assertEquals(cs.CaseCommentsPublic__c, 0);
        System.assertEquals(cs.CaseCommentsPrivate__c, 1);
        List<CaseComment> caseComments = [SELECT CreatedDate FROM CaseComment LIMIT 1];
        System.assertNotEquals(null, cs.LastPrivateCommentCreatedDate__c);
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' AND isActive = true AND UserRole.DeveloperName ='CEO' Limit 1];
        System.runAs(adminUser){
            delete cm;
        }
        cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c  FROM Case WHERE Subject ='JIRA12345' Limit 1];
        System.assertEquals(cs.CaseCommentsPublic__c, 0);
        System.assertEquals(cs.CaseCommentsPrivate__c, 0);
    }

    private static testMethod void testCaseOwnerChange() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;

        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true,
            IsActive = true);

        insert u;
        System.runAs(u){
            insertCaseComment(String.valueOf(u.Id));
        }
        System.assertEquals(true,u.Id!=null);
    }

    @future
    static void insertCaseComment(String uId){

        Case caseRecord = [SELECT Id, OwnerId, Owner_Time_Off__c FROM Case WHERE Subject ='JIRA12345' Limit 1];
        caseRecord.OwnerId = uId;
        update caseRecord;

        User contactUser = [SELECT Id FROM User WHERE Name = 'Support Bot'];

        System.runAs(contactUser) {
            CaseComment cc = new CaseComment();
            cc.CommentBody = 'Test comment body';
            cc.ParentId = caseRecord.Id;
            cc.IsPublished = true;
            insert cc;
        }

        Case updatedCase = [SELECT Id, OwnerId , Initial_Case_Owner__c FROM Case WHERE Subject ='JIRA12345' Limit 1];
        System.assert(updatedCase.Id!=null,'Case Inserted');
        System.assertEquals(updatedCase.Initial_Case_Owner__c, uId);
    }
    
    static testmethod void testChangeInitialMilestone(){
        Case cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c ,CreatedDate, Priority,Initial_Milestone_Flag_Name__c FROM Case WHERE Subject ='JIRA12345' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' AND isActive = true AND UserRole.DeveloperName ='CEO' Limit 1];
        System.runAs(adminUser){
            Map<Id,Case> idToCaseMap = new Map<Id,Case>{cs.Id=>cs};
            CaseCommentTriggerHandler.changeInitialMilestoneFlagColor(idToCaseMap,idToCaseMap);
            CaseCommentTriggerHandler.changeInitialMilestoneFlagColor(idToCaseMap,null);
        }
        System.assertEquals(true,cs.Id!=null);
    }
    
    private static testmethod void testCaseCommentTrigger2(){
        Case cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c  FROM Case WHERE Subject ='JIRA12345' Limit 1];
        User usr = [SELECT Id,Email FROM User WHERE Email=: 'testcontactuser3568@test.com'];
        User usr2 = [SELECT Id,Email FROM User WHERE Email=: 'testcontactuser@test.com'];
        CaseComment cm = new CaseComment(ParentId = cs.id, IsPublished = true, CommentBody = 'test comment');
        CaseComment cm2 = new CaseComment(ParentId = cs.id, IsPublished = true, CommentBody = 'test comment 2');
        System.runAs(usr){
            insert cm;
        }
        Test.startTest();
        System.runAs(usr2){
            insert cm2;
        }
        
        List<CaseComment> caseComments = [SELECT CreatedDate FROM CaseComment LIMIT 1];
        
        cs = [SELECT Id, CaseCommentsPrivate__c, CaseCommentsPublic__c  FROM Case WHERE Subject ='JIRA12345' Limit 1];
        System.assertEquals(cs.CaseCommentsPublic__c, 2);
        Test.stopTest();
    }
}