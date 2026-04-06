/**
 * @Author      : Vijay Kumar K R
 * @CreatedDate : Mar 7, 2023 
 * @Class    : CommunityTemplateController
 */
@isTest
public with sharing class CommunityTemplateControllerTest {

    @TestSetup
    static void makeData(){

        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'CEO' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' AND isActive = true AND UserRoleId != null Limit 1];
        adminUser.UserRoleId = userRole.Id;
        update adminUser;

		System.runAs (adminUser) {
        Account AccRecord = new Account();
        AccRecord.Name = 'Rubrik-Test';
        AccRecord.BillingStreet = 'Building 9, Cessna Business Park, Kadubeesanahalli';
        AccRecord.BillingCity = 'Bengaluru';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '560103';
        AccRecord.Type = 'Reseller';
        INSERT AccRecord;

        List<Contact> contlist = new List<Contact>{ new Contact(LastName = 'Okta Test', FirstName = 'CU 1', AccountId = AccRecord.Id,
                                                                Email = 'customer.vijay.kr@rubrik.com', Primary_Role__c='Admin',Phone='8888888888',
                                                                MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                                                                MailingPostalCode=AccRecord.BillingPostalCode),
                                                    new Contact(LastName = 'Okta Test', FirstName = 'CU 2', AccountId = AccRecord.Id,
                                                                Email = 'customer.vijay.kr@rubrik.com', Primary_Role__c='Admin',Phone='9999999999',
                                                                MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                                                                MailingPostalCode=AccRecord.BillingPostalCode),
                                                    new Contact(LastName = 'Okta Test', FirstName = 'CU 3', AccountId = AccRecord.Id,
                                                                Email = 'customer.vijay.kr@rubrik.com', Primary_Role__c='Admin',Phone='9999999999',
                                                                MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                                                                MailingPostalCode=AccRecord.BillingPostalCode)};
        INSERT contlist;

        String uniqueUserName1 = 'okta.customer_User1@rbk.com';
        String uniqueUserName2 = 'okta.customer_User2@rbk.com';
        String uniqueUserName3 = 'okta.customer_User3@rbk.com';
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Partner Community Manager' limit 1];
        Profile csup = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' limit 1];
        List<User> userList = new List<User>{   new user(alias = 'vkumar', email = 'customer.vijay.kr@rubrik.com', ContactId = contlist[0].Id, Okta_UserId__c = '00u6m0y30cHs6NzLV1d7',
                                                    emailencodingkey = 'UTF-8', firstname = 'Vijay', lastname = 'Kumar K R', languagelocalekey = 'en_US',
                                                    localesidkey = 'en_US', profileid = p.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName1),
                                                new user(alias = 'vkumar', email = 'customer.vijay.kr@rubrik.com', ContactId = contlist[1].Id, Okta_UserId__c = '00u6m0y30cHs6NzLV1d7',
                                                    emailencodingkey = 'UTF-8', firstname = 'Vijay', lastname = 'Kumar K R', languagelocalekey = 'en_US',
                                                    localesidkey = 'en_US', profileid = p.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName2),
                                                new user(alias = 'vkumar', email = 'customer.vijay.kr@rubrik.com', ContactId = contlist[2].Id, Okta_UserId__c = '00u6m0y30cHs6NzLV1d7',
                                                    emailencodingkey = 'UTF-8', firstname = 'Vijay', lastname = 'Kumar K R', languagelocalekey = 'en_US',
                                                    localesidkey = 'en_US', profileid = csup.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName3)};
        INSERT userList;
		}

        fetchData();
        
    }

    @future
    static void fetchData(){
    OktaUserUtilityTest.oktaCustomSettingsParams();
    CommunityTemplateController.getOktaAttributesCustomSettings();
    }


    
    @isTest
    static void fetchMultipleUsersTest(){
        CommunityTemplateController.fetchMultipleUsers();
        System.assertEquals(3, [SELECT COUNT() FROM Contact WHERE Email = 'customer.vijay.kr@rubrik.com']);
    }

    @isTest
    static void updateUserinOktaToAccessPortalTest(){

        String uniqueUserName1 = 'okta.customer_User3@rbk.com';
        Set<String> userFieldSet = new Set<String>();

        System.debug('test userQueryString:: '+[SELECT Id, Okta_UserId__c
                                FROM User
                                WHERE Email = 'customer.vijay.kr@rubrik.com']);

        for(SF_Okta_Field_Mapping__mdt objMtd : SF_Okta_Field_Mapping__mdt.getAll().values()){
            // Customer Support Fields                                            
            if(objMtd.Common_Field__c 
                || (!objMtd.isPartner_Field__c && !objMtd.Common_Field__c)){
                    userFieldSet.add(objMtd.SF_Field_API_Name__c);
            }
        }
            
        String userQueryString = 'SELECT UserType, Okta_UserId__c, '+ String.escapeSingleQuotes(String.join(new List<String>(userFieldSet), ', ')) + ' FROM ';
                userQueryString += 'User WHERE UserName =\''+uniqueUserName1+'\' Limit 1';
        List<User> supportUserList = Database.query(userQueryString);
        
        String returnURL = null;
        Test.startTest();
            System.runAs(supportUserList[0]){
                Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
                CommunityTemplateController.wrapper returnWrapper = CommunityTemplateController.updateUserinOktaToAccessPortal('okta.customer_User3@rbk.com');
                returnURL = returnWrapper.SAML_URL;
            }
        Test.stopTest();
        System.assertNotEquals(returnURL, null);
    }
}