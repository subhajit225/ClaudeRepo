/********************************************************************************************************
@ Name              : EmailHelper_Test
@ Description       : EmailHelper_Test is Used for Testing EmailHelper Class
*********************************************************************************************************/
@isTest
public class EmailHelper_Test{
    @testSetup
    static void setupTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())){           
            Account a= new account(name='TestAcc');
            insert a;
            Custom_Error_Log__c CaptureError = new Custom_Error_Log__c();
            CaptureError.Class__c = 'EmailHelper_Test';
            CaptureError.Functionality__c = 'test functionality';            
            CaptureError.Exception_Message__c= 'test error message';
            CaptureError.ErrorTrace__c= 'test error trace';            
            insert CaptureError;
            List<Custom_Error_Log__c> CaptureErrorLst = new List<Custom_Error_Log__c>();
            CaptureErrorLst.add(CaptureError);
            list<Contact> contacts = new list<Contact>();
            contacts.add(new Contact(FirstName='Test1', LastName='Contact1', AccountId=a.Id, Email='testUser1@test.com'));
            insert contacts;
            
            EmailTemplate e = new EmailTemplate (developerName = 'test34', FolderId = UserInfo.getOrganizationId(), TemplateType= 'Text', Name = 'test');
            insert e;
        }
    }
    static testMethod void testProductRegistrationController(){
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){       
            Account a = [Select id from Account limit 1];
            EmailTemplate e = [select id from EmailTemplate where developerName = 'test34' limit 1];
            Contact contact = [select id from contact where email ='testUser1@test.com' limit 1];
            List<Custom_Error_Log__c> CaptureErrorLst = [select id from Custom_Error_Log__c];
            EmailHelper emailHlper= new EmailHelper();
            Set<String> ccUserIds = new Set<string>{'test@gmail.com'};
            Set<String> bccUserIds = new set<string>{'test1@gmail.com'};
            try{
                String resString=emailHlper.NewLine;
                EmailHelper.sendEmail(e.Id, new List<Id>{System.UserInfo.getUserId()}, a.Id);
                EmailHelper.sendCDMAlert('test@any.com', null, contact.id);
                EmailHelper.sendEmailNotification(new Set<Id>{UserInfo.getUserId()}, 'subjectText', 'bodyText');
                EmailHelper.getSingleEmailMessageObj(new Set<String>{System.UserInfo.getUserId() }, ccUserIds, bccUserIds, ID.ValueOf(System.UserInfo.getUserId()), contact.id, e.Id);
                EmailHelper.setSingleEmailMessage(new List<String>{'test@gmail.com'}, e.Id, contact.id, a.Id, new List<Messaging.SingleEmailMessage>());
                string msg = EmailHelper.prepareEmailBodyForCustomErrorLog(CaptureErrorLst);
                EmailHelper.sendBatchErrorsEmail(new List<String>{'test@gmail.com'}, 'Error Subject', msg);
            }catch(Exception exp){
                system.debug(LoggingLevel.DEBUG, '@@ exception '+exp.getMessage());
            }
            system.assertEquals(1, CaptureErrorLst.size());
        }
        Test.stopTest();
    }
    
}