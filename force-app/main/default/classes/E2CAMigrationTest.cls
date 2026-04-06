@isTest
public class E2CAMigrationTest {
    @testSetup
    static void setup(){
        E2CAdv__E2CATriggers__c caseCommentTrigger = new E2CAdv__E2CATriggers__c(Name='CaseCommentTrigger', E2CAdv__IsActive__c=false);
        insert caseCommentTrigger;

        E2CAdv__E2CAConfiguration__c eAdvance = new E2CAdv__E2CAConfiguration__c();
        eAdvance.Name = 'E2C Advance Configuration';
        eAdvance.E2CAdv__EmailLoopingBreakTime__c = '1';
        eAdvance.E2CAdv__CaseCountToBreakEmailLoop__c = '5';
        List<OrgWideEmailAddress> orgWideEmailList = [select Id, Address from OrgWideEmailAddress where address like 'emailtocaseadvanced%'];
        //eAdvance.E2CAdv__OrgWideAddress__c = [select Id, Address from OrgWideEmailAddress where address like 'emailtocaseadvanced%'].Id;
        if (orgWideEmailList != null && !orgWideEmailList.isEmpty()) {
            eAdvance.E2CAdv__OrgWideAddress__c = orgWideEmailList[0].Id;
        }
        eAdvance.E2CAdv__ArticleDomain__c = 'https://ap4.salesforce.com/articles/E2CAdv__Knowledge__kav';
        eAdvance.E2CAdv__ArticleSOSL__c = 'RETURNING Knowledge__kav (Id, title, UrlName WHERE PublishStatus=\'Online\') limit 10';
        eAdvance.E2CAdv__CleanCaseComments__c = true;
        eAdvance.E2CAdv__CaseUpdateFields__c ='status;priority;ownerid;createddate';
        eAdvance.E2CAdv__EnableAdditionalRecipient__c = true;
        eAdvance.E2CAdv__CaseSummaryFields__c = 'status;priority;ownerid;createddate';
        eAdvance.E2CAdv__EmailLoopHandling__c = true;
        eAdvance.E2CAdv__EnableSuggestedArticle__c = true;
        eAdvance.E2CAdv__EnableNewCaseComment__c = true;
        eAdvance.E2CAdv__Show_Summary_on_Add_Comment__c = true;
        eAdvance.E2CAdv__CloseCaseHandling__c = 'New Case';
        eAdvance.E2CAdv__NonCustomersCaseHandling__c = true;
        eAdvance.E2CAdv__TypeofCaseHandling__c = 'Create New Contact';
        eAdvance.E2CAdv__CaseClosedHandling__c = true;
        eAdvance.E2CAdv__EnableTrigger__c = true;
        eAdvance.E2CAdv__EnableTSEComment__c = true;
        eAdvance.E2CAdv__Enable_Comment_for__c = 'Incoming Emails';
        eAdvance.E2CAdv__FilesorAttachments__c = 'Attachments';
        eAdvance.E2CAdv__Enable_RichText_Comment__c = true;
        eAdvance.E2CAdv__Enable_Team_Looping__c = true;
        eAdvance.E2CAdv__LoopTeamAsCCBCC__c = 'BCC';
        eAdvance.E2CAdv__AddTeamAsCaseTeam__c = true;
        eAdvance.E2CAdv__CaseTeamRolesToLoop__c = 'Test;Test2';
        eAdvance.E2CAdv__Enhanced_Comment_Body_API_Name__c='E2CAdv__Comment_Body__c';
        eAdvance.E2CAdv__Enhanced_Comment_Published_Checkbox_API__c='E2CAdv__Published__c';
        eAdvance.E2CAdv__ParentCaseAPIName__c ='E2CAdv__Parent__c';
        eAdvance.E2CAdv__Enhanced_Comment_Object_API_Name__c = 'E2CAdv__Long_Comments__c';
        eAdvance.E2CAdv__EnableLongComments__c=true;
        eAdvance.E2CAdv__Enable_Watchers__c = true;
        eAdvance.E2CAdv__Enable_Case_History__c=true;
        boolean recordtypeEnabled = Schema.SObjectType.case.getRecordTypeInfosByName().size()>1 ? true : false;
        Map<String,Schema.RecordTypeInfo> aMap = new Map<String,Schema.RecordTypeInfo>();
        aMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        id recordtypeId;
        for(Schema.RecordTypeInfo sch : aMap.values()){
            if(sch.getDeveloperName() != 'Master' && recordtypeEnabled){
                RecordtypeId = sch.getRecordTypeId();
                eAdvance.E2CAdv__EmailtoCaseAddresses__c = sch.getRecordTypeId();
                eAdvance.E2CAdv__ForwardingEmailAddress__c = sch.getRecordTypeId();
            }
        }
        eAdvance.E2CAdv__CaseClosure__c = true;
        eAdvance.E2CAdv__AutoAttachAttachment__c = true;
        eAdvance.E2CAdv__CaseClosureTemplateId__c = '';
        eAdvance.E2CAdv__CaseCommentTemplateId__c = '';
        eAdvance.E2CAdv__CaseCreateTemplateId__c = '';
        eAdvance.E2CAdv__EmailNotificationAction__c ='Apex';
        eAdvance.E2CAdv__ManageForwardCaseByEngineer__c = true;
        insert eAdvance;

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
        Case cas1 = new Case();
        cas1.accountid = acc.id;
        cas1.contactid = cont.id;
        cas1.status='new';
        cas1.subject ='Testing';
        cas1.E2CAdv__Watchers__c = 'test@test.com';
        cas1.E2CAdv__AdditionalTO__c = 'test@test.com';
        cas1.E2CAdv__AdditionalCC__c = 'test@test.com';
        cas1.E2CAdv__Additional_BCC__c = 'test@test.com';
        cas1.Priority = 'P1';
        insert cas1;

        CaseHistory ch=new CaseHistory();
        ch.CaseId = cas.Id;
        ch.Field = 'created';
        insert ch;

        CaseComment cst1=new CaseComment();
        cst1.parentid=cas.id;
        cst1.isPublished=true;
        cst1.commentbody= cas.Id+';';
        CaseComment cst2=new CaseComment();
        cst2.parentid=cas.id;
        cst2.isPublished=false;
        cst2.commentbody= cas.Id+';';
        insert new List<CaseComment>{cst1, cst2};

            E2CAdv__Long_Comments__c LongCommentToInsert1 = new E2CAdv__Long_Comments__c();
        LongCommentToInsert1.E2CAdv__Comment_Body__c = cas.Id+';'+cas1.Id;
        LongCommentToInsert1.E2CAdv__Comment_Status__c = 'Sent';
        LongCommentToInsert1.E2CAdv__Parent__c = cas.Id;
        LongCommentToInsert1.E2CAdv__Published__c = true;
        LongCommentToInsert1.purpose__c = '';

            E2CAdv__Long_Comments__c LongCommentToInsert2 = new E2CAdv__Long_Comments__c();
        LongCommentToInsert2.E2CAdv__Comment_Body__c = cas.Id+';'+cas1.Id;
        LongCommentToInsert2.E2CAdv__Comment_Status__c = 'Sent';
        LongCommentToInsert2.E2CAdv__Parent__c = cas.Id;
        LongCommentToInsert2.E2CAdv__Published__c = true;
        LongCommentToInsert2.purpose__c = '';
        LongCommentToInsert2.E2CAdv__Has_Attachment__c = false;

            E2CAdv__Long_Comments__c LongCommentToInsert3 = new E2CAdv__Long_Comments__c();
        LongCommentToInsert3.E2CAdv__Comment_Body__c = cas.Id+';'+cas1.Id;
        LongCommentToInsert3.E2CAdv__Comment_Status__c = 'Sent';
        LongCommentToInsert3.E2CAdv__Parent__c = cas.Id;
        LongCommentToInsert3.E2CAdv__Published__c = true;
        LongCommentToInsert3.purpose__c = '';
        insert new List<E2CAdv__Long_Comments__c>{LongCommentToInsert1, LongCommentToInsert2, LongCommentToInsert3};


    }

    @isTest
    static void caseCommentMigration1(){

        Case cs = [Select Id from Case LIMIT 1];
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
        EmailMessage em=new EmailMessage();
        em.parentid=cs.id;
        em.subject='xyz';
        em.Textbody=cs.Id+';';
        em.BccAddress='test@test.com';
        em.ccaddress='test@test.com';
        em.ToAddress ='test@test.com';
        em.fromaddress ='test@test.com';
        EmailMessage em1=new EmailMessage();
        em1.parentid=cs.id;
        em1.subject='xyz';
        em1.Textbody=cs.Id+';';
        em1.BccAddress='test@test.com';
        em1.ccaddress='test@test.com';
        em1.ToAddress ='test@test.com';
        em1.fromaddress ='test@test.com';

        Test.startTest();
        insert new List<EmailMessage>{em,em1};
        Database.executeBatch(new E2CAMigrationBatch('where Id=\'' + cs.Id + '\'',new List<String>(),String.valueOf(lc.id),cs.Id,56000,14000000));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void caseCommentMigration2(){
        Case cs = [Select Id from Case LIMIT 1];
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
        EmailMessage em1=new EmailMessage();
        em1.parentid=cs.id;
        em1.subject='xyz';
        em1.Textbody='Test Body';
        em1.BccAddress='test@test.com';
        em1.ccaddress='test@test.com';
        em1.ToAddress ='test@test.com';
        em1.fromaddress ='test@test.com';

        Test.startTest();
        insert new List<EmailMessage>{em1};
        Database.executeBatch(new E2CAMigrationBatch('where Id=\'' + cs.Id + '\'',new List<String>(),String.valueOf(lc.id),cs.Id,56000,14000000));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void caseCommentMigration3(){
        Case cas1 = new Case();
        cas1.status='new';
        cas1.subject ='Testing';
        cas1.Priority = 'P1';
        Case cs = [Select Id from Case LIMIT 1];
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];

        EmailMessage em2=new EmailMessage();
        em2.parentid=cs.id;
        em2.subject='xyz';
        em2.Textbody=null;
        em2.BccAddress='test@test.com';
        em2.ccaddress='test@test.com';
        em2.ToAddress ='test@test.com';
        em2.fromaddress ='test@test.com';

        Test.startTest();
        insert cas1;
        CaseComment cst1=new CaseComment();
        cst1.parentid=cas1.id;
        cst1.isPublished=true;
        cst1.commentbody= 'Great';
        insert cst1;

        insert new List<EmailMessage>{em2};
        Database.executeBatch(new E2CAMigrationBatch('where Id=\'' + cas1.Id + '\'',new List<String>(),String.valueOf(lc.id),cs.Id,56000,14000000));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void caseCommentMigration4(){
        Case cs = [Select Id from Case LIMIT 1];
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
        EmailMessage em=new EmailMessage();
        em.parentid=cs.id;
        em.subject='xyz';
        em.Textbody='Test Body';
        em.BccAddress='test@test.com';
        em.ccaddress='test@test.com';
        em.ToAddress ='test@test.com';
        em.fromaddress ='test@test.com';
        EmailMessage em1=new EmailMessage();
        em1.parentid=cs.id;
        em1.subject='xyz';
        em1.Textbody='Test Body';
        em1.BccAddress='test@test.com';
        em1.ccaddress='test@test.com';
        em1.ToAddress ='test@test.com';
        em1.fromaddress ='test@test.com';

        Test.startTest();
        insert new List<EmailMessage>{em,em1};
        Database.executeBatch(new E2CAMigrationBatch('where Id=\'' + cs.Id + '\'',new List<String>(),String.valueOf(lc.id),cs.Id,100,100));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void caseCommentMigration5(){
        Case cs = [Select Id from Case LIMIT 1];
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
        EmailMessage em=new EmailMessage();
        em.parentid=cs.id;
        em.subject='xyz';
        em.Textbody='Test Body';
        em.BccAddress='test@test.com';
        em.ccaddress='test@test.com';
        em.ToAddress ='test@test.com';
        em.fromaddress ='test@test.com';
        EmailMessage em1=new EmailMessage();
        em1.parentid=cs.id;
        em1.subject='xyz';
        em1.Textbody='Test Body';
        em1.BccAddress='test@test.com';
        em1.ccaddress='test@test.com';
        em1.ToAddress ='test@test.com';
        em1.fromaddress ='test@test.com';

        Test.startTest();
        insert new List<EmailMessage>{em,em1};
        Database.executeBatch(new E2CAMigrationBatch('where Id=\'' + cs.Id + '\'',new List<String>(),String.valueOf(lc.id),cs.Id,55000,12000000));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void historyMigration(){
        Case cs = [Select Id from Case LIMIT 1];
        //E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c where E2CAdv__Parent__c=:cs.Id LIMIT 1];

        CaseHistory ch = [SELECT CaseId, CreatedDate, Field, OldValue,CreatedById, NewValue FROM CaseHistory where CaseId=:cs.Id limit 1];
        Test.startTest();
        Database.executeBatch(new E2CAHistoryMigrationBatch('where Id=\'' + cs.Id + '\'','created',NULL,cs.Id, 10, 10));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void historyMigration1(){
        Case cs = [Select Id from Case LIMIT 1];
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
            CaseHistory ch = [SELECT CaseId, CreatedDate, Field, OldValue,CreatedById, NewValue FROM CaseHistory where CaseId=:cs.Id limit 1];
        Test.startTest();
        Database.executeBatch(new E2CAHistoryMigrationBatch('where Id=\'' + cs.Id + '\'','created',lc.Id,cs.Id, 100, 100));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void historyMigration2(){
        Case cs = [Select Id from Case LIMIT 1];
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
        CaseHistory ch = [SELECT CaseId, CreatedDate, Field, OldValue,CreatedById, NewValue FROM CaseHistory where CaseId=:cs.Id limit 1];
        Test.startTest();
        Database.executeBatch(new E2CAHistoryMigrationBatch('where Id=\'' + cs.Id + '\'','created',lc.Id,cs.Id, 55000, 12000000));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void leftOverCaseCommentMigration1(){

        Case cas = new Case();
        cas.status='new';
        cas.subject ='Testing';
        cas.Priority = 'P1';
        insert cas;
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
        EmailMessage em=new EmailMessage();
        em.parentid=cas.id;
        em.subject='xyz';
        em.Textbody='nothing';
        em.BccAddress='test@test.com';
        em.ccaddress='test@test.com';
        em.ToAddress ='test@test.com';
        em.fromaddress ='test@test.com';
        EmailMessage em1=new EmailMessage();
        em1.parentid=cas.id;
        em1.subject='xyz';
        em1.Textbody='Test Body';
        em1.BccAddress='test@test.com';
        em1.ccaddress='test@test.com';
        em1.ToAddress ='test@test.com';
        em1.fromaddress ='test@test.com';
        CaseComment cst2=new CaseComment();
        cst2.parentid=cas.id;
        cst2.isPublished=false;
        cst2.commentbody= 'Testing comment test@test.com From: test@test.com Test Body';

        Test.startTest();
        insert new List<CaseComment>{cst2};
        insert new List<EmailMessage>{em,em1};
            Database.executeBatch(new E2CAMigrationBatchForRemRecords(new List<String>{cas.Id},String.ValueOf(lc.Id),cas.Id,57000,12000000));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cas.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void leftOverCaseCommentMigration2(){
        Case cas = new Case();
        cas.status='new';
        cas.subject ='Testing';
        cas.Priority = 'P1';
        insert cas;
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
        EmailMessage em1=new EmailMessage();
        em1.parentid=cas.id;
        em1.subject='xyz';
        em1.Textbody='Test Body';
        em1.BccAddress='test@test.com';
        em1.ccaddress='test@test.com';
        em1.ToAddress ='test@test.com';
        em1.fromaddress ='test@test.com';
        CaseComment cst2=new CaseComment();
        cst2.parentid=cas.id;
        cst2.isPublished=false;
        cst2.commentbody= 'Testing comment test@test.com From: test@test.com Test Body';

        Test.startTest();
        insert new List<CaseComment>{cst2};
        insert new List<EmailMessage>{em1};
            Database.executeBatch(new E2CAMigrationBatchForRemRecords(new List<String>{cas.Id},String.ValueOf(lc.Id),cas.id,57000,12000000));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cas.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void leftOverCaseCommentMigration3(){

        Case cs = [Select Id from Case LIMIT 1];
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
        EmailMessage em=new EmailMessage();
        em.parentid=cs.id;
        em.subject='xyz';
        em.Textbody='Test Body';
        em.BccAddress='test@test.com';
        em.ccaddress='test@test.com';
        em.ToAddress ='test@test.com';
        em.fromaddress ='test@test.com';

        Test.startTest();
        insert new List<EmailMessage>{em};
            Database.executeBatch(new E2CAMigrationBatchForRemRecords(new List<String>{cs.Id},String.ValueOf(lc.Id),'5005C00000BApYl',100,100));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

    @isTest
    static void leftOverCaseCommentMigration4(){

        Case cs = [Select Id from Case LIMIT 1];
        E2CAdv__Long_Comments__c lc = [Select Id from E2CAdv__Long_Comments__c LIMIT 1];
        EmailMessage em=new EmailMessage();
        em.parentid=cs.id;
        em.subject='xyz';
        em.Textbody='Test Body';
        em.BccAddress='test@test.com';
        em.ccaddress='test@test.com';
        em.ToAddress ='test@test.com';
        em.fromaddress ='test@test.com';

        Test.startTest();
        insert new List<EmailMessage>{em};
            Database.executeBatch(new E2CAMigrationBatchForRemRecords(new List<String>{cs.Id},String.ValueOf(lc.Id),'5005C00000BApYl',56000,12000000));
        Test.stopTest();
        List<E2CAdv__CommentSourceControllers__c> cscList = [select id,E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c
                                                             from E2CAdv__CommentSourceControllers__c
                                                             where E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c=:cs.Id];
        System.assertEquals(cscList.size()>0, true);
    }

}