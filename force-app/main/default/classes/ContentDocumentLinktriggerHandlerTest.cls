@isTest
public class ContentDocumentLinktriggerHandlerTest {
    static testMethod void ContentDocumentLinkTest() {
        /*comment*/	
        insert new TriggerControl__c(Name='ContentDocumentLink');
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        Case cs = new Case(Subject='test case',Priority='P1');
        insert cs;
        Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121saurv.com');
        insert u;
        CCR__c ccr = new CCR__c ();
        
        ccr.RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId(); 
        ccr.Affective_Person__c = UserInfo.getUserId();   
        ccr.User__c = 'Pending';
        ccr.CCR_Type__c = 'Other';
        ccr.Justifications__c = 'Other';
        ccr.Comment__c = 'test';
        ccr.Effective_Date__c=System.Today();
        ccr.Effective_End_Date__c = System.Today().addDays(90);
        ccr.Number_of_Attchments__c = 0;
        insert ccr;
        
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
        ContentDocumentLink cdl2 = new ContentDocumentLink(LinkedEntityId = ccr.id,ContentDocumentId = cd.id,ShareType = 'V');
        insert cdl2;    
        System.debug('cdl'+cdl);
        cdlList.add(cdl);
        cdlList.add(cdl2);    
        ContentDocumentLinkTriggerHandler cdlth = new ContentDocumentLinkTriggerHandler();
        cdlth.beforeInsert(cdlList);
        cdlth.afterInsert(cdlList);
        cdlth.afterDelete(cdlList);    
        }
    }
    static testMethod void KnowledgeArticleTest() {
        insert new TriggerControl__c(Name='ContentDocumentLink');
        
        How_To__kav kav = new How_To__kav();
        kav.UrlName = 'test-123';
        kav.Title = 'test article';
        insert kav;
        
        ContentVersion contentVersion = new ContentVersion(
          Title = 'Penguins',
          PathOnClient = 'Penguins.jpg',
          VersionData = Blob.valueOf('Test Content'),
          IsMajorVersion = true
        );
        insert contentVersion; 
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocument cd = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = kav.id,ContentDocumentId = cd.id,ShareType = 'V');
        insert cdl;
        
        ContentDocumentLinkTriggerHandler cdlth = new ContentDocumentLinkTriggerHandler();
        cdlth.afterInsert(new List<ContentDocumentLink>{cdl});
    }
}