@isTest
public class attachmentInfoController_Test {
    
    @isTest static void test_method(){
        insert new TriggerControl__c(Name='Entitlement'); 
        Account acc = new Account();
        acc.Name = 'testing_account';
        insert acc;
        
        Contact cont = new Contact();
        cont.AccountId = acc.Id;
        cont.LastName = 'contact_lname';
        insert cont;
        
        Case cs = new Case();
        cs.AccountId = acc.Id;
        cs.ContactId = cont.Id;
        cs.Origin = 'my_origin';
        cs.Status = 'cs_status';
        cs.Priority = 'P1';
        insert cs;
        Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121saurv.com');
        insert u;
        
        System.runAs(u) {
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
            insert contentVersion;    
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            ContentDocument cd = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
            ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = cs.id,ContentDocumentId = cd.id,ShareType = 'V');
            insert cdl;
            }
            Test.startTest();
            attachmentInfoController obj = new attachmentInfoController();
            obj.caseId = cs.Id;
            obj.getCaseAndAttachInfo();
            Test.stopTest();
        }
    }