@isTest
public with sharing class OktaUserMigrationCsvBatchableTest {
    
    @TestSetup
    static void makeData(){
        Document document;

        document = new Document();
        String csvContentStr = 'Email,Okta_UserId_c,API_Status__c\r\n';
        csvContentStr += 'customer.vijay.kr@rubrik.com,00u72s65a9UOwZMhi1d7,succes\r\n';
        csvContentStr += 'vijay.kr+12@rubrik.com,00u72sa32utiHVGzL1d7,succes';
        document.Body = Blob.valueOf(csvContentStr);
        document.ContentType = 'application/pdf';
        document.DeveloperName = 'Okta_users';
        document.IsPublic = true;
        document.Name = 'Okta users';
        document.FolderId = [SELECT Id FROM Folder WHERE DeveloperName = 'Public_Documents'].Id;
        INSERT document;

        Account AccRecord = new Account();
        AccRecord.Name = 'Rubrik-Test';
        AccRecord.BillingStreet = 'Building 9, Cessna Business Park, Kadubeesanahalli';
        AccRecord.BillingCity = 'Bengaluru';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '560103';
        AccRecord.Type = 'Reseller';
        INSERT AccRecord;

        Contact objCont = new Contact(LastName = 'Okta Test', FirstName = 'CU 1', AccountId = AccRecord.Id,
                                        Email = 'customer.vijay.kr@rubrik.com', Primary_Role__c='Admin', Phone='8888888888',
                                        MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                                        MailingPostalCode=AccRecord.BillingPostalCode);
        INSERT objCont;
    }

    @isTest
    static void processTest(){

        test.startTest();
        Contact objCont = [SELECT Id FROM Contact WHERE FirstName = 'CU 1' Limit 1];
        // Customer Profile
        Profile cp = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' limit 1];
        String uniqueUserName = 'okta.customer_User1'+ DateTime.now().getTime() +'@rbk.com';

        user objUser = new user(alias = 'o.CUv1', email = 'customer.vijay.kr@rubrik.com', ContactId = objCont.Id, Okta_UserId__c = null, API_Status__c = null,
                                emailencodingkey = 'UTF-8', firstname = 'Vijay', lastname = 'Kumar K R', languagelocalekey = 'en_US',
                                localesidkey = 'en_US', profileid = cp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName);
        
        
        INSERT objUser;
        database.executebatch(new OktaUserMigrationCsvBatchable(), 1000);
        test.stopTest();
        System.assertEquals('00u72s65a9UOwZMhi1d7', [SELECT Id, Okta_UserId__c FROM User WHERE email = 'customer.vijay.kr@rubrik.com' Limit 1].Okta_UserId__c);
        System.assertEquals('Success', [SELECT Id, API_Status__c FROM User WHERE email = 'customer.vijay.kr@rubrik.com' Limit 1].API_Status__c);
    }
}