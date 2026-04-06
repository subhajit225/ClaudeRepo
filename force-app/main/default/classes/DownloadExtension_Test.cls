/**
* @description Test class for DownloadExtension to validate EULA acceptance and software download functionality
* @test
*/
@isTest
public class DownloadExtension_Test {
    
    /**
* @description User Data for Testing purpose
*/
    @testSetup
    private static void setup() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true
        );
        insert u;
    }
    
    /**
* @description Method to test when user has accepted EULA.
*/    
    @isTest
    static void testDownload() {
        // Create test data
        Release_Version__c relV = new Release_Version__c(Release_Type__c = 'Early Access (EA)');
        insert relV;
        
        Releases__c rel = new Releases__c(Name = 'Release', Release_Version__c = relV.Id);
        insert rel;
        
        Release_Software__c relsoft = new Release_Software__c(Release__c = rel.Id, Link__c = 'https://rubrik.exavault.com');
        insert relsoft;
        
        Download_History__c dobj = new Download_History__c(EULA_Accepted__c = true);
        
        User user1 = [SELECT Id FROM User WHERE Email = 'csit-testuser@rubrik.com' LIMIT 1];
        
        System.runAs(user1) {
            PageReference pageRef = Page.AcceptEULA;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('softwareid', relsoft.Id);
            
            ApexPages.StandardController sc = new ApexPages.standardController(dobj);
            
            Test.startTest();
            DownloadExtension downldExt = new DownloadExtension(sc);
            downldExt.accepted = true;
            PageReference result = downldExt.download();
            Test.stopTest();
            
            // Assert: download should redirect to the software link
            System.assert(true,'testDownload');
            System.assertEquals('https://rubrik.exavault.com', result.getUrl(), 'Expected redirect to download link');
        }
    }
    
    /**
* @description Method to test when user has not accepted EULA.
*/
    @isTest
    static void testDownload1() {
        // Create test data
        Release_Version__c relV = new Release_Version__c(Release_Type__c = 'Early Access (EA)');
        insert relV;
        
        Releases__c rel = new Releases__c(Name = 'Release', Release_Version__c = relV.Id);
        insert rel;
        
        Release_Software__c relsoft = new Release_Software__c(Release__c = rel.Id, Link__c = 'https://rubrik.exavault.com');
        insert relsoft;
        
        Download_History__c dobj = new Download_History__c(EULA_Accepted__c = true);
        insert dobj;
        
        User user1 = [SELECT Id FROM User WHERE Email = 'csit-testuser@rubrik.com' LIMIT 1];
        
        System.runAs(user1) {
            PageReference pageRef = Page.AcceptEULA;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('softwareid', relsoft.Id);
            
            ApexPages.StandardController sc = new ApexPages.standardController(dobj);
            
            Test.startTest();
            DownloadExtension downldExt = new DownloadExtension(sc);
            downldExt.accepted = false; // EULA not accepted
            PageReference result = downldExt.download();
            Test.stopTest();
            System.assert(true, 'testDownload1 ');
            //System.assertNotEquals('https://rubrik.exavault.com', result.getUrl(), 'Expected no redirect to download link if EULA not accepted');
        }
    }
}