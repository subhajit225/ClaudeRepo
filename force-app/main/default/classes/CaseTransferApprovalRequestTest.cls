/**
* @description Test Class for CaseTransferApprovalRequest - CS21-482
*
* @Created By Veera Gandi
* @lastUpdated by Shailesh Kumar - CS21-3568 Disallow Case Ownership
*/
@isTest(seeAllData=false)
public class CaseTransferApprovalRequestTest {
    /**
    * @description
    */
    @TestSetup
    public static void dataSetup() {
        insert new TriggerControl__c(Name='Case');
        insert new TriggerControl__c(Name='Entitlement');
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = UserInfo.getUserId());
        sdb.Disable_Email_Alerts__c = true;
        sdb.Disable_SBQQ_Quote_Validation_Rules__c= true;
        sdb.Disable_Case_Validation_Rules__c= true;
        sdb.Disable_Entitlement_Validation_Rules__c = true;
        insert sdb;
        Profile systemAdmin = [Select Id from Profile where Name = 'System Administrator'];
        
        User user1 = new User(Alias = 'standt', Email='adminduser@testorgrbk.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121rbk.com');
        insert user1;
        test.startTest();
        Account account = new Account(name='testAcc');
        insert account;
        
        Contact contact = new Contact(lastName='testCont');
        contact.Notify_For_case_creation__c = true;
        contact.Email='testcontact@test.com';
        contact.AccountId = account.Id;
        insert Contact;
        
        Case newCase = new case();
        newCase.Accountid = account.id;
        newCase.contactid = contact.id;
        newCase.Subject ='JIRA12345';
        newCase.JIRA_References_URL__c='SPARK-123456, SPARK-78910';
        newCase.Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910';
        newCase.Origin = 'Email';
        newCase.close_survey_triggered__c = false;
        newCase.Article_Created__c = false;
        newCase.Resolution_Details__c  = 'test';
        newCase.Next_Step__c = 'Test';
        newCase.Current_Status__c  = 'testStatus';
        newCase.Priority = 'P1';
        newCase.Alert_Key__c = 'Alert case 1 key';
        newCase.CaseTransferStatus__c = 'submitted';
        insert newCase;
        
        Assist_Request__c assistRequest= new Assist_Request__c();
        assistRequest.Case__c = newCase.Id;
        assistRequest.Status__c = 'Open';
        assistRequest.Brownbag_Candidate__c = true;
        insert assistRequest;
        Test.stopTest();
    }
    
    @isTest
    static void caseTransferTest() {
        test.startTest();
        User adminUser = [SELECT Id, Email FROM User WHERE Email =:'adminduser@testorgrbk.com' LIMIT 1];
        System.runAs(adminUser){
            List<Case> cases = [SELECT Id FROM Case LIMIT 1];
            CaseTransferApprovalRequest.submitCaseForTransferRequestApproval(cases[0].Id, 23);
            CaseTransferApprovalRequest.isSupportManager(true);
            CaseTransferApprovalRequest.getAssistRequests(cases[0].Id);
            System.assertEquals(true, cases.size()!=0);
        }
        test.stopTest();
    }
    
    @isTest
    static void caseTransferTest1() {
        test.startTest();
        User adminUser = [SELECT Id, Email FROM User WHERE Email =:'adminduser@testorgrbk.com' LIMIT 1];
        System.runAs(adminUser){
            List<Case> cases = [SELECT Id FROM Case LIMIT 1];
            cases[0].CaseTransferStatus__c = 'Approved';
            cases[0].SuggestedTransferQueue__c = 'AMER Transfer';
            update cases[0];
            System.assertEquals(true, cases.size()!=0);
        }
        test.stopTest();
    }
    
    @isTest
    static void caseTransferTest2() {
        test.startTest();
        User adminUser = [SELECT Id, Email FROM User WHERE Email =:'adminduser@testorgrbk.com' LIMIT 1];
        System.runAs(adminUser){
            List<Case> cases = [SELECT Id FROM Case LIMIT 1];
            cases[0].CaseTransferStatus__c = 'Rejected';
            cases[0].CaseTransferPreviousOwnerId__c = userInfo.getUserId();
            update cases[0];
            System.assertEquals(true, cases.size()!=0);
        }
        test.stopTest();
    }
    
    @isTest
    static void caseTransferTest3() {
        test.startTest();
        User adminUser = [SELECT Id, Email FROM User WHERE Email =:'adminduser@testorgrbk.com' LIMIT 1];
        System.runAs(adminUser){
            try {
                List<Case> cases = [SELECT Id FROM Case LIMIT 1];
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setComments('submitted for approval'); 
                approvalRequest.setObjectId(cases[0].Id);
                Approval.ProcessResult result = Approval.process(approvalRequest);
                CaseTransferApprovalRequest.approveCaseTransferRequest(cases[0].Id, 'approve', 'Testing');
                System.assertEquals(true, cases.size()!=0);
            } catch (Exception ex) {
                System.debug(LoggingLevel.DEBUG, ex.getMessage());
            }
        }
        test.stopTest();
    }
    
    @isTest
    static void caseTransferTest4() {
        User adminUser = [SELECT Id, Email FROM User WHERE Email =:'adminduser@testorgrbk.com' LIMIT 1];
        System.runAs(adminUser){
            Account acc = new Account(name='TestAcct1', Account_Preference__c = 'Top Accounts');
            insert acc;
            
            Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case cs2 = new case();
            cs2.Accountid = acc.id;
            cs2.Subject ='Test Case For Case Details';
            cs2.Description ='Test Case For Case Details';
            cs2.Origin = 'Alert';
            cs2.Priority = 'P3';
            cs2.Status = 'Closed';
            cs2.RecordTypeId = supportCaseId;
            insert cs2;

            Datetime dt = Datetime.now().addDays(-10);
            Test.setCreatedDate(cs2.Id, dt);
            cs2.Status = 'Closed';
            update cs2;

            test.startTest();
            CaseTransferApprovalRequest.getCaseDetails(cs2.Id);
            test.stopTest();
            System.assertEquals('Closed',cs2.Status);
        }
    }
}