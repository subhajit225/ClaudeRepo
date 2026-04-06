/**
 * @Author      : Vijay Kumar K R
 * @CreatedDate : May 5, 2023
 * @Class       : EscalationManagementTeamController
 */
@isTest
public with sharing class EscalationManagementTeamControllerTest {
    
    @TestSetup
    public static void makeData(){
        
        test.startTest();
        List<TriggerControl__c> triggerCntlList = new List<TriggerControl__c>{
                                                    new TriggerControl__c(Name = 'Escalation', DisableTrigger__c = false),
                                                    new TriggerControl__c(Name = 'LessonsLearned', DisableTrigger__c = false)};
        INSERT triggerCntlList;

        Account accRbk = new Account(name='Rubrik-Test', Heads_up_to_support_team__c = 'Acc Support text');
        insert accRbk;

        Contact cont = new Contact(lastName='testCont');
        cont.Lastname = 'EMAT_test';
        cont.Email='test@gmail.com';
        cont.AccountId=accRbk.Id;
        insert cont;

        Case objCase = new case();
        objCase.Accountid = accRbk.id;
        objCase.contactid = cont.id;
        objCase.Subject ='JIRA12345';
        objCase.JIRA_References_URL__c='SPARK-123456, SPARK-78910';
        objCase.Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910';
        objCase.Origin = 'Alert';
        objCase.close_survey_triggered__c = false;
        objCase.Resolution__c = 'No Response';
        objCase.Article_Created__c = false;
        objCase.Resolution_Details__c  = 'test';
        objCase.Next_Step__c = 'Test';
        objCase.Current_Status__c  = 'testStatus';
        objCase.Priority = 'P1';
        objCase.CT_Rating__c = 'Gold';
        objCase.JIRA_Status__c = 'test';
        
        INSERT objCase;

        //create contentVersion  record
        ContentVersion contentVersion = new ContentVersion(Title = 'EMT Pic', PathOnClient = 'Pic.jpg', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
        insert contentVersion;

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = objCase.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        Escalation__c objEsc = new Escalation__c(Case__c = objCase.Id, Status__c = 'Open');
        INSERT objEsc;

        objEsc.RecordTypeId = EscalationManagementTeamController.RANSOMWARE_RTID;
        objEsc.isDraft__c = true;
        UPDATE objEsc;
        EscalationManagementTeamController.draftEscalation objWarp = EscalationManagementTeamController.getDraftEscalation();

        INSERT new Lessons_Learned__c(isDraft__c = true, Case__c = objCase.Id, Escalation__c = objEsc.Id, Lessons_Learnt_Status__c = 'Open');

        test.stopTest();
        System.assertNotEquals(null, objWarp.ransomwareEsc);

        List<Lessons_Learned__c> objLldraft = EscalationManagementTeamController.getDraftLessonsLearned(objEsc.Id);
        System.assertNotEquals(null, objLldraft[0]);

        // EscalationTriggerHandlerTest beforeInsert Code covergae
        try{
            Escalation__c objEsc2 = new Escalation__c(Case__c = objCase.Id);
            INSERT objEsc2;
        }catch(DMLexception e){
            System.assert(e.getMessage().contains('Open Escalation already existing under this Case'),'Open Escalation already existing under this Case');                       
        }

        // LessonsLearnedTriggerHandler Code covergae
        try{
            INSERT new Lessons_Learned__c(Case__c = objCase.Id, Escalation__c = objEsc.Id);
        }catch(DMLexception e){
            System.assert(e.getMessage().contains('Lessons Learned already existing under this Escalation'),'Lessons Learned already existing under this Escalation');                       
        }

        INSERT new Note__c(Escalation__c = objEsc.Id, Area_Of_Improvement__c = 'Initial text');

        // EscalationTriggerHandlerTest beforeUpdate Code covergae
        try{
            UPDATE new Escalation__c(Id = objEsc.Id, Case__c = objCase.Id, Status__c = 'Closed');
        }catch(DMLexception e){
            System.assert(e.getMessage().contains('Please close Lessons Learned prior to close this Escalation'),'Please close Lessons Learned prior to close this Escalation');                    
        }
    }

    @isTest
    static void getCaseDetailsTest(){
        Case objCase = [SELECT Id FROM Case Limit 1];
        EscalationManagementTeamController.caseDetails objWrapper = EscalationManagementTeamController.getCaseDetails(objCase.Id);
        System.assertEquals('Acc Support text', objWrapper.headsUpString);
    }

    @isTest
    static void attachCaseNotesTest(){
        Escalation__c objEsc = [SELECT Id FROM Escalation__c Limit 1];
        Case objCase = [SELECT Id FROM Case Limit 1];
        EscalationManagementTeamController.attachCaseNotes(objCase.Id, objEsc.Id);
        System.assertEquals(1, [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId = :objEsc.Id]);
    }

    @isTest
    static void getEscalationDetailsTest(){
        Escalation__c objEsc = [SELECT Id FROM Escalation__c Limit 1];
        Escalation__c objEsclnt = EscalationManagementTeamController.getEscalationDetails(objEsc.Id);
        System.assertEquals(objEsclnt.Id, [SELECT Id FROM Escalation__c WHERE Id = :objEsc.Id].Id);
    }

    @isTest
    static void recentOpenCaseListActionTest(){
        Escalation__c objEsc = [SELECT Id FROM Escalation__c Limit 1];
        Case objCase = [SELECT Id FROM Case Limit 1];
        objCase.Status = 'Open';
        UPDATE objCase;

        List<Case> caseList = EscalationManagementTeamController.recentCaseListAction(objEsc.Id, 'OpenCases');
        System.assertEquals(1, caseList.size());
    }

    @isTest
    static void recentClosedCaseListActionTest(){
        Escalation__c objEsc = [SELECT Id FROM Escalation__c Limit 1];
        Case objCase = [SELECT Id FROM Case Limit 1];
        objCase.Status = 'Closed';
        UPDATE objCase;

        List<Case> caseList = EscalationManagementTeamController.recentCaseListAction(objEsc.Id, 'ClosedCases');
        System.assertEquals(1, caseList.size());
    }

    @isTest
    static void recentRelatedCaseListActionTest(){
        Escalation__c objEsc = [SELECT Id FROM Escalation__c Limit 1];
        Case objCase = [SELECT Id FROM Case Limit 1];
        objCase.Subject = 'EMY Case';
        UPDATE objCase;

        List<Case> caseList = EscalationManagementTeamController.recentCaseListAction(objEsc.Id, 'RelatedCases');
        System.assertEquals(1, caseList.size());
    }

    @isTest
    static void createCaseTeamMemberTest(){
        Case objCase = [SELECT Id FROM Case Limit 1];
        EscalationManagementTeamController.createCaseTeamMember(objCase.Id);
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember WHERE ParentId =: objCase.Id]);
    }

    @isTest
    static void sendEscalatiojnCaseCommentTest(){
        Escalation__c objEsc = [SELECT Id FROM Escalation__c Limit 1];
        EscalationManagementTeamController.sendCaseComment(objEsc.Id, 'next steps notes');
        System.assertEquals(1, [SELECT count() FROM CaseComment WHERE CommentBody = 'next steps notes']);
    }

    @isTest
    static void sendLessonsLearnedCaseCommentTest(){
        Lessons_Learned__c objll = [SELECT Id FROM Lessons_Learned__c Limit 1];
        EscalationManagementTeamController.sendCaseComment(objll.Id, 'next steps notes');
        System.assertEquals(1, [SELECT count() FROM CaseComment WHERE CommentBody = 'next steps notes']);
    }

    @isTest
    static void getDraftNoteTest(){
        Escalation__c objEsc = [SELECT Id FROM Escalation__c Limit 1];
        Note__c objNt = new Note__c();
        objNt.Section_Type__c = 'LL_Background_Timeline';
        objNt.Escalation__c = objEsc.Id;
        objNt.isDraft__c = true;
        INSERT objNt;
        EscalationManagementTeamController.getDraftNote('LL_Background_Timeline', objEsc.Id);
        System.assertEquals(1, [SELECT count() FROM Note__c WHERE  Section_Type__c = 'LL_Background_Timeline']);
    }
}