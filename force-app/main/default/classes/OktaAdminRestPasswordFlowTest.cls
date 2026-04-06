@isTest
public with sharing class OktaAdminRestPasswordFlowTest {
    
    @TestSetup
    static void makeData(){
        
        User objUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'System Administrator' AND UserRoleId != null Limit 1];
        Account AccRecord = new Account();
        AccRecord.Name = 'Rubrik-Test';
        AccRecord.BillingStreet = 'Building 9, Cessna Business Park, Kadubeesanahalli';
        AccRecord.BillingCity = 'Bengaluru';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '560103';
        AccRecord.Type = 'Reseller';
        AccRecord.OwnerId = objUser.Id;
        INSERT AccRecord;
        
        Contact conObj = new Contact(LastName = 'Okta Test',
                                     FirstName = 'Portal Contact account',
                                     AccountId = AccRecord.Id,
                                     Email = 'testpartnerportal123@test.com',
                                     Primary_Role__c='Admin',Phone='1234567890',
                                     MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity,
                                     MailingCountry=AccRecord.BillingCountry,MailingPostalCode=AccRecord.BillingPostalCode );
        INSERT conObj;
        
        OktaUserUtilityTest.oktaCustomSettingsParams();
    }

    @isTest 
    static void oktaInvocableMethod(){
        
        Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
        Profile p = [select id, name from Profile where name='Rubrik Partner Community User' limit 1];
        System.debug('Profile-->'+p);
        List<Contact> conlist = new List<Contact>([SELECT id,FirstName,Primary_Role__c,Account.name,LastName,Email,Phone,MailingStreet,MailingCity,MailingCountry,MailingPostalCode from Contact LIMIT 1]);
        User newPortalUser = new User();
        newPortalUser.EmailEncodingKey = 'ISO-8859-1';
        newPortalUser.LanguageLocaleKey = 'en_US';
        newPortalUser.TimeZoneSidKey = 'America/New_York';
        newPortalUser.LocaleSidKey = 'en_US';
        newPortalUser.FirstName = conlist[0].FirstName;
        newPortalUser.LastName = conlist[0].LastName;
        newPortalUser.Username = 'rubrik.'+conlist[0].Email; 
        newPortalUser.CommunityNickname =String.ValueOf(Math.random());
        if(!String.isBlank(conlist[0].FirstName) && (!String.isBlank(conlist[0].LastName) && conlist[0].LastName.length()>2) ){
            newPortalUser.Alias = conlist[0].FirstName.substring(0, 1)+conlist[0].LastName.substring(0, 2);
        }
        else{
            newPortalUser.Alias ='puser';
        }
        newPortalUser.Email = conlist[0].Email;
        newPortalUser.IsActive = true;
        newPortalUser.ContactId = conlist[0].Id;
        newPortalUser.Phone = conlist[0].Phone;
        newPortalUser.Street= conlist[0].MailingStreet;
        newPortalUser.City = conlist[0].MailingCity;
        newPortalUser.Country = conlist[0].MailingCountry;
        newPortalUser.PostalCode = conlist[0].MailingPostalCode;
        newPortalUser.UserPermissionsSFContentUser= true;
        newPortalUser.CompanyName = conlist[0].Account.Name;
        newPortalUser.ProfileID = p.Id;
        newPortalUser.Okta_UserId__c = '00u7g07a5gnUuVoCy1d7';
        Test.startTest();
        insert newPortalUser;
        Test.stopTest();
        List<OktaAdminRestPasswordFlow.Requests> requestList = new List<OktaAdminRestPasswordFlow.Requests>();
        OktaAdminRestPasswordFlow.Requests objInst = new OktaAdminRestPasswordFlow.Requests();
        objInst.userRecord = newPortalUser;
        requestList.add(objInst);
        List<OktaAdminRestPasswordFlow.Response> responseval = OktaAdminRestPasswordFlow.oktapasswordEmail(requestList);
        System.debug('responseval--->'+responseval);
        System.assertNotEquals(responseval, null);
    }

}