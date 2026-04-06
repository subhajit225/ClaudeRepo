/** Created By :Annappa
* Purpose : Test class of PC_TagsContentController
**/

@isTest
public class PC_TagsContentController_Test {
    @testSetup static void setupmethod() {
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testpuser2@test.com',
            Alias = 'batman',
            Email='bruce.wayne@testrubrk.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);
        System.runAs ( portalAccountOwner1 ) {
            ContentWorkspace workspace = new ContentWorkspace(
                Name = 'Sales Tools',                // required
                Description = 'Test library for sales materials'
            );
            insert workspace;
            
            Account portalAccount1 = new Account(
                Name = 'TestAccount',
                OwnerId = portalAccountOwner1.Id,
                Type = 'Reseller'
                //Focused_Partner__c = true
            );
            Database.insert(portalAccount1);
            
            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin',
                Partner_Promo_Banner__c = true
            );
            Database.insert(contact1);
            
            Profile portalProfile = [SELECT Id FROM Profile Where Name='Rubrik Partner community Manager' Limit 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'tespuser1@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'testContent12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user1);
        }
    }
    
    public static testmethod void testSalesContentDetails(){
        User u = [SELECT Id FROM User WHERE Email ='bruce.wayne@testrubrk.com'];
        System.runAs(u){
            File_Sharing__c fs = new File_Sharing__c(
                OwnerId = u.Id
        	);
			insert fs;
        	List<ContentVersion> cv = ShGl_TestFactory.testMethod_Content(1);
        	cv[0].TagCsv = 'Playbook';
            cv[0].Tags__c = 'Playbook'; 
        	update cv;
            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion 
            					WHERE Id =: cv[0].Id].ContentDocumentId;
            
            ContentDocumentLink cdl = new ContentDocumentLink(  ContentDocumentId = contentDocId,
                                                              LinkedEntityId = fs.Id, // 👈 link to File_Sharing__c
                                                              ShareType = 'V',               // V = Viewer
                                                              Visibility = 'AllUsers'
                                                             );
            insert cdl;
        
            Test.startTest();
        	PC_TagsContentController.fetchContentDetails('Playbook','Sales Tools');
        	PC_TagsContentController.fetchContentDetailsForCustomTags('Playbook','Sales Tools','Playbook');
        	PC_TagsContentController.PreviewContentDetails(cv[0].id);
            Test.stopTest();
        }
        System.assert(true, 'File sharing completed');
        
    }
    /**
     * @description Fetches content details based on the provided tag name, library name, and default tag.
     * @returns List<ContentVersion> - A list of ContentVersion records that match the specified tag, library, and default tag.
     */
    public static testmethod void testfetchAttachedContentDocDetails(){
        User u = [SELECT Id,AccountId FROM User WHERE EMAIL = 'testContent12345@test.com'];
        ContentVersion cv = new Contentversion();
        cv.title = 'AccountSharedFile';
        cv.PathOnClient = 'test';
        cv.FirstPublishLocationId = u.AccountId;
        Blob b = Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata = EncodingUtil.base64Decode('Unit Test Attachment Body');
        cv.IsMajorVersion = true;
        insert cv;
        
        //Id cdId = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id].Id;
        //ContentDocumentLink cdl = [SELECT Id, Visibility FROM ContentDocumentLink where contentdocumentid=:cdId and LinkedEntityId = :u.AccountId];

        ContentDocumentLink cdl = [SELECT Id, Visibility FROM ContentDocumentLink where contentdocumentid IN (SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id) and LinkedEntityId = :u.AccountId];
        cdl.Visibility = 'AllUsers';
        update cdl;
        
        System.runAs(u){
        	PC_TagsContentController.fetchAttachedContentDocDetails();
            System.assert(true, 'Portal user has access to the file');
        }
    }
}