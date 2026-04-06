@isTest
public class generateDocument_Test {
    static testMethod void testDocumentUrl(){
        Test.startTest();
        Document document;
        document = new Document();
        document.Body = Blob.valueOf('Some Text');
        document.ContentType = 'application/pdf';
        document.DeveloperName = 'my_document';
        document.IsPublic = true;
        document.Name = 'My Document';
        document.FolderId = [select id from folder where name = 'Shared Documents'].id;
        insert document;
        generateDocument doc = new generateDocument();
        doc.docName = 'my_document';
        System.assertNotEquals(doc.urlGenerated, null);
        Test.stopTest();
    }
    
    
}