@isTest
public class UpdateEmailMessageBatchTest {

    @testSetup static void setup() {
        EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = Userinfo.getUserId(), TemplateType= 'Text', Name = 'test'); // plus any other fields that you want to set
        insert e;
    }

    @isTest
    static void getCommentsTestMethod(){

        Account acc=new Account();
        acc.name='Test acc';
        insert acc;

        Contact cont= new Contact();
        cont.lastname='Test con';
        cont.AccountId = acc.id;
        cont.email='Test@test.com';
        insert cont;

        Case cas = new Case();
        cas.accountid = acc.id;
        cas.contactid = cont.id;
        cas.status='new';
        cas.subject ='Testing';
        cas.E2CAdv__Watchers__c = 'test@test.com';
        cas.E2CAdv__AdditionalTO__c = 'test@test.com';
        cas.E2CAdv__AdditionalCC__c = 'test@test.com';
        cas.E2CAdv__Additional_BCC__c = 'test@test.com';
        cas.Priority = 'P1';
        insert cas;


        CaseComment cst1=new CaseComment();
        cst1.parentid=cas.id;
        cst1.isPublished=true;
        cst1.commentbody= 'To: test@test.com From: test@test.com Test Bodydyyyyy';


        insert new List<CaseComment>{cst1};

            //Long_Comments__c LongCommentToInsert = new Long_Comments__c();
            E2CAdv__Long_Comments__c LongCommentToInsert = new E2CAdv__Long_Comments__c();
        LongCommentToInsert.E2CAdv__Comment_Body__c = 'test';
        LongCommentToInsert.E2CAdv__Comment_Status__c = 'Draft';
        LongCommentToInsert.E2CAdv__To_Address__c = 'test@test.com';
        LongCommentToInsert.E2CAdv__Parent__c = cas.Id;
        LongCommentToInsert.E2CAdv__Bcc_Address__c = 'test@test.com';
        LongCommentToInsert.E2CAdv__Cc_Address__c = 'test@test.com';
        LongCommentToInsert.E2CAdv__Published__c = true;
        LongCommentToInsert.E2CAdv__Is_Incoming__c = false;
        LongCommentToInsert.E2CAdv__Is_Scheduled__c = true;
        LongCommentToInsert.E2CAdv__Send_If_Case_Status_Changes__c = true;
        LongCommentToInsert.E2CAdv__Watchers__c = 'test@test.com';
        LongCommentToInsert.E2CAdv__Scheduled_Time__c = System.now();
        LongCommentToInsert.E2CAdv__File_Ids__c = '0697g000002btr8AAA';
        LongCommentToInsert.E2CAdv__Has_Attachment__c = true;

        insert LongCommentToInsert;


        E2CAdv__CommentSourceControllers__c csc1 = new  E2CAdv__CommentSourceControllers__c();
        csc1.E2CAdv__Long_Comments_Id__c = LongCommentToInsert.Id;
        csc1.E2CAdv__CaseCommentId__c = cst1.id;
        csc1.E2CAdv__Comment_Source__c ='CaseComment';
        csc1.E2CAdv__Enhanced_Object_Id__c='';
        csc1.E2CAdv__Entity_Id__c =cst1.Id;

        insert csc1 ;




        Test.StartTest();

        E2CAdv__E2CAConfiguration__c setting=new E2CAdv__E2CAConfiguration__c();
        setting.Name='E2C Advance Configuration';
        setting.E2CAdv__CaseCommentTemplateId__c=[Select id from EmailTemplate where developerName ='test' limit 1].id;
        insert setting;

        String query='';
        UpdateEmailMessageBatch cs1 = new UpdateEmailMessageBatch(query);
        Database.executeBatch(cs1);

        Test.StopTest();
    }
}