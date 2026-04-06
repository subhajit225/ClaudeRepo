@isTest
private class PC_PartnerCaseControllerTest {
    
    @testSetup
    static void createTestData() {
        
        Account acc = new Account(name='testAcc');
        insert acc;
        
        Contact cont = new Contact(lastName='testCont');
        cont.Notify_For_case_creation__c = true;
        cont.Email =  'testusertest@test.com.invalid';
        cont.AccountId = acc.Id;
        insert cont;
        
        Id partnerCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();
        Case cs = new case();
        cs.Accountid = acc.id;
        cs.contactid = cont.id;
        cs.Subject ='Partner Case Test';
        cs.Origin = 'Email';
        cs.Priority = 'None';
        cs.RecordTypeId = partnerCaseId;
        cs.Type__c = 'LMS';
        insert cs;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;
    }
    
    @isTest
    static void testGetQueueAndUserInfo() {
        Test.startTest();
        PC_PartnerCaseController.CaseWrapper response = PC_PartnerCaseController.getCurrentUserInfo();
        Test.stopTest();
        System.assertNotEquals(null, response);
    }
    
    @isTest
    static void testCreateCase() {
        Test.startTest();
        PC_PartnerCaseController.CaseWrapper response = PC_PartnerCaseController.createCase(getCase());
        System.assertEquals(true, response.caseId != null,'New Partner Case should be created');
        
        PC_PartnerCaseController.CaseWrapper response1 = PC_PartnerCaseController.createCaseWithComment(getCase(), 'Test Body');
        System.assertEquals(true, response1.caseId != null,'New Partner Case should be created');
        Test.stopTest();
    }
    
    private static Case getCase(){
        Case cs = new case();
        cs.Subject ='Partner Case Test';
        cs.Origin = 'Email';
        cs.Priority = 'None';
        cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();
        cs.Type__c = 'LMS';
        return cs;
    }
    
    @isTest
    static void testCreateCaseError() {
        Case newCase = [SELECT Id, Subject, Status, Priority, Description, Type__c, Subtype__c FROM Case LIMIT 1];
        Test.startTest();
        try {
            PC_PartnerCaseController.CaseWrapper response = PC_PartnerCaseController.createCase(newCase);
        } catch (AuraHandledException e) {
            System.debug('Error == '+e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateCaseWithCommentError() {
        Case newCase = [SELECT Id, Subject, Status, Priority, Description, Type__c, Subtype__c FROM Case LIMIT 1];
        Test.startTest();
        try {
            PC_PartnerCaseController.CaseWrapper response = PC_PartnerCaseController.createCaseWithComment(newCase, 'Test Body');
        } catch (AuraHandledException e) {
            System.debug('Error == '+e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUploadFilesToCase() {
        Case newCase = [SELECT Id, Subject, Status, Priority, Description, Type__c, Subtype__c FROM Case LIMIT 1];
        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        
        Test.startTest();
        PC_PartnerCaseController.uploadFilesToCase(
            new List<Id>{contentVersion.ContentDocumentId}, newCase.Id
        );
        Test.stopTest();
    }
    
    @isTest
    static void testBlock1() {
        Case openCase = [SELECT Id, Subject FROM Case LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        try{
            PC_PartnerCaseController.logError('Case', 'Issue', 'Exception');
            PC_PartnerCaseController.getCaseDetails(openCase.Id);
            PC_PartnerCaseController.addMyComment(openCase.Id,'Test Body');
            PC_PartnerCaseController.reopen(openCase.Id,'Test Body');
            PC_PartnerCaseController.getCaseDetails(acc.Id);
        }catch(Exception e){
            System.debug('e ==='+e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testUploadFilesToCaseError(){
        Case openCase = [SELECT Id, Subject FROM Case LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = openCase.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        insert cdl;
        Test.startTest();
        try {
            PC_PartnerCaseController.deleteFile(contentVersion.ContentDocumentId);
            PC_PartnerCaseController.uploadFilesToCase(new List<Id>{contentVersion.ContentDocumentId}, openCase.Id);
        } catch (AuraHandledException e) {
            System.debug('Error == '+e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetFilteredCases() {
        Case openCase = [SELECT Id, Subject FROM Case LIMIT 1];
        
        Test.startTest();
        PC_PartnerCaseController.CaseWrapper response = PC_PartnerCaseController.getFilteredCases('Open Cases');
        System.assertEquals(1, response.caseList.size());
        response = PC_PartnerCaseController.getFilteredCases('Recently Viewed Cases');
        response = PC_PartnerCaseController.getFilteredCases('');
        response = PC_PartnerCaseController.getFilteredCases('Test Filter');
        response = PC_PartnerCaseController.getFilteredCases('Closed Cases');
        System.assertEquals(0, response.caseList.size(), 'List size should be zero');
        Test.stopTest();   
    }    
}