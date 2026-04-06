@isTest
public class AttachmentRelatedListControllerTest {
    @testSetup 
    public static void setup() {
        insert new TriggerControl__c(Name='Case'); 
        List<Case> caseList = new List<Case>();
        for(integer j=0 ; j< 1 ;j++){
            caseList.add(new Case(Status = 'New',Priority='P3',Subject ='test1234'));
        }
        insert caseList;
        Blob b = Blob.valueOf('Test Data');
        
        Attachment attachment = new Attachment();
        attachment.ParentId = caseList[0].Id;
        attachment.Name = 'Test Attachment for Parent';
        attachment.Body = b;
        
        insert(attachment);
    }
    @isTest static void testAttachmentRelatedList(){
        Case cs = [Select id from Case limit 1];

        Assist_Request__c ar = new Assist_Request__c();
        ar.Case__c = cs.Id;
        insert ar;
        ApexPages.StandardController stdCaseController = new ApexPages.StandardController(ar);
        AttachmentRelatedListController arLC = new AttachmentRelatedListController(stdCaseController);
        String attId = Apexpages.currentpage().getParameters().put('attId','1234'); 
        arLC.viewAtt();
    }
}