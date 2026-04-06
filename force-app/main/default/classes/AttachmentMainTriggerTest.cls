@isTest
public class AttachmentMainTriggerTest{ 
    
    //Method
    static testMethod void InsertAttachment() {
        
        CCR__c ccr = new CCR__c ();
        
        ccr.RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId(); 
        ccr.Affective_Person__c = UserInfo.getUserId();   
        ccr.User__c = 'Pending';
        ccr.CCR_Type__c = 'Other';
        ccr.CCR_Type_Other__c = 'Bonus';
        ccr.Justifications__c = 'Other';
        ccr.Comment__c = 'test';
        ccr.Effective_Date__c=System.Today();
        ccr.Effective_End_Date__c = System.Today().addDays(90);
        ccr.Number_of_Attchments__c = 0;
        insert ccr;
        
        Attachment attach = new Attachment();
        
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.ParentId=ccr.id;
        insert attach;
        
        List<Attachment> attachments=[select id, name from Attachment where ParentId =:ccr.id];
        System.assertEquals(1, attachments.size());
        
        attach = [SELECT Id, name from Attachment where parent.id=:ccr.id];
        
        delete attach;  
    }
    static testMethod Void caseAttachmentTest(){
        Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121saurv.com');
        insert u;

        Account acc = new Account(name='testAcc');
        insert acc;
        
        Contact cont = new Contact(lastName='testCont');
        insert cont;
        Case cs = TestDataFactory.getCase(acc, cont);
        cs.OwnerId = userInfo.getUserId();
        insert cs;
        
        
        System.runAs(u) {
            Attachment at = new Attachment();
            at.Name='Unit Test Attachment';
            Blob bb=Blob.valueOf('Unit Test Attachment Body');
            at.body=bb;
            at.parentId=cs.id;
            at.OwnerId = u.id;
            insert at;
        }
    }
}