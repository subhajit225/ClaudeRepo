@isTest
public class downloadCaseAttachmentsTest {
    static testMethod void test(){
        Case cs = new Case();
        cs.Platform__c = 'Other';
        cs.Subject = 'Test';
        cs.Description = 'Testing Description';
        cs.Priority = 'P3';
        insert cs;
        Test.startTest();
        downloadCaseAttachments.checkfile(cs.Id);
        Test.stopTest();
    }
    static testMethod void test2(){
        Case cs = new Case();
        cs.Platform__c = 'Other';
        cs.Subject = 'Test';
        cs.Description = 'Testing Description';
        cs.Priority = 'P3';
        insert cs;
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = cs.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'Test Document';
        cv1.PathOnClient = 'TestDocument.pdf';
        cv1.VersionData = Blob.valueOf('Test Content');
        cv1.IsMajorVersion = true;
        Insert cv1;
        Id conDocId1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv1.Id].ContentDocumentId;
        ContentDocumentLink cdl1 = New ContentDocumentLink();
        cdl1.LinkedEntityId = cs.Id;
        cdl1.ContentDocumentId = conDocId1;
        cdl1.shareType = 'V';
        Insert cdl1;
        Test.startTest();
        downloadCaseAttachments.checkfile(cs.Id);
        downloadCaseAttachments.getAttachments(cs.Id);
        PageReference myVfPage = Page.downloadCaseAttachments;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('recId',cs.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(cs);
		downloadCaseAttachments controller = new downloadCaseAttachments(sc);
        Test.stopTest();
    }
}