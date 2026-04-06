/**
* @description Test Class for CaseCommentClass
* This class sets up test data and tests the CaseCommentClass functionality
* @test
* @author  Raveesh Layal
* @date 2025-08-01
*/
@isTest
public class CaseCommentClassTest {
    
    /**
* @description Test setup method to create required data:
* Account, Contact, Portal User, Case, CaseComment, Long Comments, and Comment Source Controllers.
*/
    @testSetup 
    public static void setup() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuserrubrik@test.com',
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
            insert new TriggerControl__c(Name='Case',DisableTrigger__c=true);
            insert new ShGl_DisableBusinessLogic__c(Disable_Case_Comment_Trigger__c=true, name='disableCaseComment');
            Account acc = new Account(name='testAcc');
            insert acc;
            
            Contact cont = new Contact(lastName='testCont');
            cont.Email='jira@rubrik.atlassian.net';
            insert cont;
            
            AccountTeamMember acctm = new AccountTeamMember();
            acctm.AccountId = acc.id;
            acctm.UserId= UserInfo.getUserId();
            acctm.TeamMemberRole = 'Customer Experience Manager';
            insert acctm;
            
            Case cs = new case();
            cs.Accountid = acc.id;
            cs.contactid = cont.id;
            cs.Subject ='JIRA12345';
            cs.JIRA_References_URL__c='SPARK-123456, SPARK-78910';
            cs.Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910';
            cs.Origin = 'Alert';
            cs.close_survey_triggered__c = false; 
            cs.Resolution__c = 'No Response';
            cs.Article_Created__c = false;
            cs.Resolution_Details__c  = 'test';
            cs.Next_Step__c = 'Test';
            cs.Current_Status__c  = 'testStatus';
            cs.Priority = 'P1 - Critical service impact';
            cs.ownerId=u.Id;
            insert cs;
                        
            CaseComment cs2 = new CaseComment(ParentId = cs.Id , CommentBody='tes <br> <br>',isPublished = true);
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
            LongCommentToInsert.E2CAdv__Has_Attachment__c = true;
            
            insert LongCommentToInsert;
            
            
            E2CAdv__CommentSourceControllers__c csc1 = new  E2CAdv__CommentSourceControllers__c();
            csc1.E2CAdv__Long_Comments_Id__c = LongCommentToInsert.Id;
            csc1.E2CAdv__CaseCommentId__c = cs2.id;
            csc1.E2CAdv__Comment_Source__c ='CaseComment';
            csc1.E2CAdv__Enhanced_Object_Id__c='';
            csc1.E2CAdv__Entity_Id__c =cs2.Id;
            
            insert csc1 ;
            
            CaseCommentClass.extractEmailsFromCC('Hello Team\nCc: test@example.com');
            CaseCommentClass.extractEmailsFromCC('Hello');
        }
    }
    /**
* @description Test method to verify CaseCommentClass.getCaseComment() functionality.
* Runs as the portal user and retrieves case comments for a sample case.
*/
    @isTest static void testMethod2(){
        
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'testuserrubrik@test.com' LIMIT 1];
        System.runAs(user1){
            Id caseId = [select id from case limit 1].Id;
            CaseCommentClass cs = new CaseCommentClass();
            cs.CaseId = caseId;
            cs.isPreview = true;//CS21-100 change
            List<CaseCommentClass.UserWrap> result = cs.getCaseComment();
            // Only one assertion, as requested
            System.assert(result != null && result.size() > 0, 'Expected at least one CaseComment to be returned.');
        }
    }
}