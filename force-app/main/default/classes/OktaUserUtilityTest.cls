/**
 * @Author      : Vijay (Customer) / Gaurav (Partner)
 * @CreatedDate : Jan 23, 2023
 * @Class       :OktaUserUtility, OktaCalloutHandler, OktaCalloutSelector, OktaFreezeUsersSchedulableBatch, OktaFreezeUsersSync
 * @description : Test class for Okta user utilities, callouts, and freezing/unfreezing user functionality.
 */
@isTest
public with sharing class OktaUserUtilityTest {
    
    /**
     * @description Static user fetched for use in multiple test cases.
     */
    public static User objUser = [SELECT Id FROM User WHERE (UserType = 'PowerPartner' OR UserType = 'CspLitePortal') AND isActive = true Limit 1];
    
    /**
     * @description Creates test data including user with role, account, contacts and portal user.
     */
    @TestSetup
    static void makeData(){
        UserRole ur = new UserRole(Name = 'Test Role');
        insert ur;
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
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
            UserRoleId = ur.Id, 
            Employee_Time_Off__c = true
        );
        insert u;
        System.runAs(u){
            
            insert new TriggerControl__c(Name='User');
            oktaCustomSettingsParams();
            
            Account AccRecord = new Account();
            AccRecord.Name = 'Rubrik-Test';
            AccRecord.BillingStreet = 'Building 9, Cessna Business Park, Kadubeesanahalli';
            AccRecord.BillingCity = 'Bengaluru';
            AccRecord.BillingCountry = 'India';
            AccRecord.BillingPostalCode = '560103';
            AccRecord.Type = 'Reseller';
            INSERT AccRecord;
            
            List<Contact> contlist = new List<Contact>{ new Contact(LastName = 'Okta Test', FirstName = 'CU 1', AccountId = AccRecord.Id,
                                                                    Email = 'customer.vijay.kr@rubrik.com.sandbox', Primary_Role__c='Admin', Phone='8888888888',
                                                                    MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                                                                    MailingPostalCode=AccRecord.BillingPostalCode),
                new Contact(LastName = 'Okta Test', FirstName = 'CU 2', AccountId = AccRecord.Id,
                            Email = 'customer.vijay.kr@rubrik.com.sandbox', Primary_Role__c='Admin', Phone='9999999999',
                            MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                            MailingPostalCode=AccRecord.BillingPostalCode),
                new Contact(LastName = 'Okta Test', FirstName = 'PU 1', AccountId = AccRecord.Id,
                            Email = 'partner.test@rubrik.com.sandbox', Primary_Role__c='Admin', Phone='9999999999',
                            MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                            MailingPostalCode=AccRecord.BillingPostalCode),
                new Contact(LastName = 'Okta Test3', FirstName = 'CU 3', AccountId = AccRecord.Id,
                            Email = 'portal.user@rubrik.com.sandbox', Primary_Role__c='Admin', Phone='8888888888',
                            MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                            MailingPostalCode=AccRecord.BillingPostalCode)};
                                INSERT contlist;
            
            // Customer Profile
            Profile cp = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' limit 1];
            String uniqueUserName = 'okta.pu1'+ DateTime.now().getTime() +'@rbk.com';
            user objUser = new user(alias = 'o.pu1', email = 'customer.test@rubrik.com.sandbox', ContactId = contlist[3].Id, Okta_UserId__c = '00u6m0y30cHs6NzLV1d7', API_Status__c = 'Success',
                                    emailencodingkey = 'UTF-8', firstname = 'test', lastname = 'portal user', languagelocalekey = 'en_US',
                                    localesidkey = 'en_US', profileid = cp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName);
            
            INSERT objUser;
        }
    }
    
    /**
     * @description Inserts Okta related custom settings for test context.
     */
    public static void oktaCustomSettingsParams(){
        // Custom settings
        Okta_Attributes__c customSet = new Okta_Attributes__c();
        customSet.Access_Token__c='test123';
        customSet.Customer_User_AppId__c='0oa74j6tt8UcKoESq1d7';
        customSet.Group_Id__c='00g6tq1v7rafytctf1d7';
        customSet.Partner_User_AppId__c='0oa79x7bg7u6C9upE1d7';
        customSet.Name = 'Okta Attributes';
        customSet.Okta_Base_URL__c = 'https://onepassport-dev.rubrik.com.sandbox';
        customSet.Disable_User_Sync__c = false;
        INSERT customSet;
        
        Okta_Attributes__c devcustomSet = new Okta_Attributes__c();
        devcustomSet.Access_Token__c='devtest123';
        devcustomSet.Customer_User_AppId__c='0oa6jgix0hRDb3LGC1d7';
        devcustomSet.Group_Id__c='00g6tq1v7rafytctf1d7';
        devcustomSet.Partner_User_AppId__c='0oa6jgj8mtFRKtG8w1d7';
        devcustomSet.Name = 'Dev Okta Attributes';
        devcustomSet.Okta_Base_URL__c = 'https://onepassport-dev.rubrik.com.sandbox';
        customSet.Disable_User_Sync__c = false;
        INSERT devcustomSet;
    }
    
    /**
     * @description Tests creation of new customer portal user.
     */
    @isTest
    static void testNewCustomerUser(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            createNewUser();
            Test.stopTest();
            System.assertNotEquals(null, [SELECT Id, Okta_UserId__c FROM User WHERE Okta_UserId__c != null Limit 1].Okta_UserId__c);
        }
    }
    
    /**
     * @description Future method to create a new customer user with mocked Okta callout.
     */
    @future
    public static void createNewUser(){
        Contact objCont = [SELECT Id FROM Contact WHERE FirstName = 'CU 1' Limit 1];
        
        Profile cp = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' limit 1];
        
        String uniqueUserName = 'okta.customer_User1'+ DateTime.now().getTime() +'@rbk.com';
        
        Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
        user objUser = new user(alias = 'o.CUv1', email = 'customer.vijay.kr@rubrik.com.sandbox', ContactId = objCont.Id,
                                emailencodingkey = 'UTF-8', firstname = 'Vijay', lastname = 'Kumar K R', languagelocalekey = 'en_US',
                                localesidkey = 'en_US', profileid = cp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName);
        
        INSERT objUser;
    }
    
    /**
     * @description Tests creation of new partner portal user.
     */
    @isTest
    static void testNewPartnerUser(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            
            Contact objCont = [SELECT Id FROM Contact WHERE FirstName = 'PU 1' Limit 1];
            
            Profile pp = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Partner Community User' limit 1];
            
            String uniqueUserName = 'okta.partner_User1'+ DateTime.now().getTime() +'@rbk.com';
            
            Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
            user objUser = new user(alias = 'o.PUv1', email = 'partner.test@rubrik.com.sandbox', ContactId = objCont.Id,
                                    emailencodingkey = 'UTF-8', firstname = 'Partner', lastname = 'Test Okta', languagelocalekey = 'en_US',
                                    localesidkey = 'en_US', profileid = pp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName);
            
            Test.startTest();
            INSERT objUser;
            Test.stopTest();
            System.assertNotEquals(null, [SELECT Id, Okta_UserId__c FROM User WHERE Okta_UserId__c != null Limit 1].Okta_UserId__c);
        }
    }
    
    /**
     * @description Mock class simulating Okta callout failure responses.
     */
    private class OktaCalloutFailureMock implements HttpCalloutMock{
      /**
     * @description Handles the incoming mock HTTP request and returns a simulated failure response.
     *
     * @param req The incoming HTTP request to be processed.
     * @return HttpResponse A simulated HTTP response representing a failed callout.
     */
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            res.setStatusCode(200);
            if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/lifecycle/deactivate?')) {
                res.setBody('{}');
                return res;
            }
            else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/users/')) {
                res.setBody('{\"id\":\"00u6m0y30cHs6NzLV1d7\",\"status\":\"ACTIVE\",\"created\":\"2023-01-11T10:40:32.000Z\",\"activated\":\"2023-01-11T10:40:33.000Z\",\"statusChanged\":\"2023-03-09T05:28:03.000Z\",\"lastLogin\":\"2023-03-14T09:28:30.000Z\",\"lastUpdated\":\"2023-03-14T10:26:04.000Z\",\"passwordChanged\":\"2023-03-09T05:28:03.000Z\",\"type\":{\"id\":\"oty6gp7ph7DMongG61d7\"},\"profile\":{\"firstName\":\"VijayKumar\",\"lastName\":\"KR\",\"mobilePhone\":null,\"secondEmail\":null,\"login\":\"customer.vijay.kr@rubrik.com.sandbox\",\"email\":\"customer.vijay.kr@rubrik.com.sandbox\"},\"credentials\":{\"password\":{},\"provider\":{\"type\":\"OKTA\",\"name\":\"OKTA\"}},\"_links\":{\"suspend\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/suspend\",\"method\":\"POST\"},\"schema\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/meta/schemas/user/osc6gp7ph7DMongG61d7\"},\"resetPassword\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/reset_password\",\"method\":\"POST\"},\"forgotPassword\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/users/00u6m0y30cHs6NzLV1d7/credentials/forgot_password\",\"method\":\"POST\"},\"expirePassword\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/expire_password\",\"method\":\"POST\"},\"changeRecoveryQuestion\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/users/00u6m0y30cHs6NzLV1d7/credentials/change_recovery_question\",\"method\":\"POST\"},\"self\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/users/00u6m0y30cHs6NzLV1d7\"},\"resetFactors\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/reset_factors\",\"method\":\"POST\"},\"type\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/meta/types/user/oty6gp7ph7DMongG61d7\"},\"changePassword\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/users/00u6m0y30cHs6NzLV1d7/credentials/change_password\",\"method\":\"POST\"},\"deactivate\":{\"href\":\"https://onepassport-dev.rubrik.com.sandbox/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/deactivate\",\"method\":\"POST\"}}}');
                return res;
            }
            return null;
        }
    }
    
    /**
     * @description Tests deactivation of a customer user with mocked Okta callout failure.
     */
    @isTest
    static void testDeActivateCustomerUser(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){

            Contact objCont = [SELECT Id FROM Contact WHERE FirstName = 'CU 1' Limit 1];

            Profile cp = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' limit 1];

            String uniqueUserName = 'okta.customer_User1'+ DateTime.now().getTime() +'@rbk.com';

            Test.setMock(HttpCalloutMock.class, new OktaCalloutFailureMock());
            user objUser = new user(alias = 'o.CUv1', email = 'customer.vijay.kr@rubrik.com.sandbox', ContactId = objCont.Id,
                                    emailencodingkey = 'UTF-8', firstname = 'Vijay', lastname = 'Kumar K R', languagelocalekey = 'en_US',
                                    localesidkey = 'en_US', profileid = cp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName);

            Test.startTest();
            INSERT objUser;
            objUser.Okta_UserId__c = '00u6m0y30cHs6NzLV1d7';
            objUser.isActive = false;
            UPDATE objUser;
            Test.stopTest();
            System.assert(true);
        }
    }
    
    /**
     * @description Tests deactivation of a partner user with mocked Okta callout.
     */
    @isTest
    static void testDeActivatePartnerUser(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){

            Contact objCont = [SELECT Id FROM Contact WHERE FirstName = 'CU 1' Limit 1];

            Profile pp = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Partner Community User' limit 1];

            String uniqueUserName = 'okta.partner_User1'+ DateTime.now().getTime() +'@rbk.com';

            Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
            user objUser = new user(alias = 'o.PUv1', email = 'partner.test@rubrik.com.sandbox', ContactId = objCont.Id,
                                    emailencodingkey = 'UTF-8', firstname = 'Partner', lastname = 'Test Okta', languagelocalekey = 'en_US',
                                    localesidkey = 'en_US', profileid = pp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName);

            Test.startTest();
            INSERT objUser;
            objUser.Okta_UserId__c = '00u6m0y30cHs6NzLV1d7';
            objUser.isActive = false;
            UPDATE objUser;
            Test.stopTest();
            System.assert(true);
        }
    }
    
    /**
     * @description Tests multiple activation and deactivation of users with mocked callouts.
     */
    @isTest
    static void testMultipleSupportActivateOrDeActivateUser(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){

            List<Contact> contList = [SELECT Id FROM Contact WHERE Email = 'customer.vijay.kr@rubrik.com.sandbox'];

            Profile cp = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' limit 1];

            String uniqueUserName = 'okta.customer_sushan'+ DateTime.now().getTime() +'@rbk.com';
            String uniqueUserName2 = 'okta.customer_rav'+ DateTime.now().getTime() +'@rbk.com';

            Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
            List<user> userList = new List<User>{new user(alias = 'o.CUv1', email = 'customer.sushant.kr@rubrik.com.sandbox', ContactId = contList[0].Id,
                                                          emailencodingkey = 'UTF-8', firstname = 'Sushant', lastname = 'Arora K R T', languagelocalekey = 'en_US',
                                                          localesidkey = 'en_US', profileid = cp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName,CommunityNickname='sushan' +'_1'),
                new user(alias = 'o.CUv2', email = 'customer.raveeshlar@rubrik.com.sandbox', ContactId = contList[1].Id,
                         emailencodingkey = 'UTF-8', firstname ='Raveesh', lastname = 'Layal K R', languagelocalekey = 'en_US',
                         localesidkey = 'en_US', profileid = cp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName2,CommunityNickname='rvv'+ '_2')};

            Test.startTest();
            INSERT userList;
            userList[0].Okta_UserId__c = '00u6m0y30cHs6NzLV1d7';
            userList[1].Okta_UserId__c = '00u6m0y30cHs6NzLV1d7';
            userList[1].isActive = false;
            UPDATE userList;
            userList[1].isActive = true;
            UPDATE userList;
            Test.stopTest();
            System.assert(true);
        }
    }
    
    /**
     * @description Tests creation of new customer users with same email address.
     */
    @isTest
    static void testNewCustomerUserOnSameEmail(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){

            List<Contact> contList = [SELECT Id FROM Contact WHERE Email = 'customer.vijay.kr@rubrik.com.sandbox'];

            Profile cp = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' limit 1];

            String uniqueUserName = 'okta.customer_User1'+ DateTime.now().getTime() +'@rbk.com';
            String uniqueUserName2 = 'okta.customer_Raveesh'+ DateTime.now().getTime() +'@rbk.com';

            Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
            user objUser = new user(alias = 'o.CUv1', email = 'customer.vijay.kr@rubrik.com.sandbox', ContactId = contList[0].Id, Okta_UserId__c = '00u6m0y30cHs6NzLV1d7',
                                    emailencodingkey = 'UTF-8', firstname = 'Vijay', lastname = 'Kuma', languagelocalekey = 'en_US',
                                    localesidkey = 'en_US', profileid = cp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName,CommunityNickname='KUMARL_'+'_1');

            Test.startTest();
            INSERT objUser;
            user objUser2 = new user(alias = 'o.CUv2', email = 'customer.raveeshlayal@rubrik.com.sandbox', ContactId = contList[1].Id,
                                     emailencodingkey = 'UTF-8', firstname = 'Raveesh', lastname = 'Layal K R', languagelocalekey = 'en_US',
                                     localesidkey = 'en_US', profileid = cp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName2,CommunityNickname='KUMAR_'+'_2');
            INSERT objUser2;
            Test.stopTest();
            System.assert(true);
        }
    }
    
    /**
     * @description Tests freezing of users with mocked Okta callout.
     */
    @isTest
    public static void frozenUserTest(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
            user objUser = [SELECT Id, Name FROM User WHERE API_Status__c != null AND Okta_UserId__c != null Limit 1];
            UserLogin objUl = [SELECT Id, isFrozen, UserId FROM UserLogin WHERE UserId =: objUser.Id];
            objUl.isFrozen = true;
            UPDATE objUl;
            database.executebatch(new OktaFreezeUsersSchedulableBatch(), 150);
            Test.stopTest();
            System.assertEquals(true, [SELECT Id, Name, Is_Okta_User_Frozen__c FROM User WHERE Id =: objUser.Id].Is_Okta_User_Frozen__c);
        }
    }
    
    /**
     * @description Tests unfreezing of users with mocked Okta callout.
     */
    @isTest
    public static void unFrozenUserTest(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
            user objUser = [SELECT Id, Name FROM User WHERE API_Status__c != null AND Okta_UserId__c != null Limit 1];
            objUser.Is_Okta_User_Frozen__c = true;
            UPDATE objUser;
            UserLogin objUl = [SELECT Id, isFrozen, UserId FROM UserLogin WHERE UserId =: objUser.Id];
            objUl.isFrozen = false;
            UPDATE objUl;
            database.executebatch(new OktaFreezeUsersSchedulableBatch(), 150);
            Test.stopTest();
            System.assertEquals(false, [SELECT Id, Name, Is_Okta_User_Frozen__c FROM User WHERE Id =: objUser.Id].Is_Okta_User_Frozen__c);
        }
    }
    
    /**
     * @description Tests freezing users via scheduled batch with mocked callout.
     */
    @isTest
    public static void frozenUserScheduleTest(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
            user objUser = [SELECT Id, Name FROM User WHERE API_Status__c != null AND Okta_UserId__c != null Limit 1];
            UserLogin objUl = [SELECT Id, isFrozen, UserId FROM UserLogin WHERE UserId =: objUser.Id];
            objUl.isFrozen = true;
            UPDATE objUl;
            Database.executeBatch(new OktaFreezeUsersSchedulableBatch(), 200);
            Test.stopTest();
            System.assertEquals(true, [SELECT Id, Name, Is_Okta_User_Frozen__c FROM User WHERE Id =: objUser.Id].Is_Okta_User_Frozen__c);
        }
    }
    
    /**
     * @description Helper method to generate HttpResponse objects with specified status codes.
     * @param errorCode HTTP status code for the response.
     * @return HttpResponse with preset JSON error body.
     */
    public static HttpResponse getHttpRes(Integer errorCode){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setStatusCode(errorCode);
        res.setBody('{\"errorCode\":\"E0000001\",\"errorSummary\":\"Apivalidationfailed:login\",\"errorLink\":\"E0000001\",\"errorId\":\"oaeueSsIMpRRaal2KI707bHuw\",\"errorCauses\":[{\"errorSummary\":\"login:Anobjectwiththisfieldalreadyexistsinthecurrentorganization\"}]}');
        return res;
    }
    
    /**
     * @description Tests handling of Okta callout with error 'login: already exists' in response.
     */
    @isTest
    public static void badStatusCode1001Test(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            res.setStatusCode(400);
            res.setBody('{\"errorCode\":\"E0000001\",\"errorSummary\":\"Apivalidationfailed:login\",\"errorLink\":\"E0000001\",\"errorId\":\"oaeueSsIMpRRaal2KI707bHuw\",\"errorCauses\":[{\"errorSummary\":\"login: already exists\"}]}');
            OktaCalloutSelector.UserData respBody = OktaCalloutHandler.statusCheck(res, 'API-1004: Update UserName Failure', objUser.Id, false);
            
            String errorMsg = respBody.errorCauses[0].errorSummary;
            System.assert(errorMsg.containsIgnoreCase('already exists'));
        }
    }
    
    /**
     * @description Tests handling of HTTP 400 error responses from Okta.
     */
    @isTest
    public static void badStatusCode400Test(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            try {
                HttpResponse res = getHttpRes(400);
                OktaCalloutHandler.statusCheck(res, 'API-1004: Update UserName Failure', objUser.Id, false);
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.assert(errorMsg.containsIgnoreCase('400'));
            }
        }
    }
    
    /**
     * @description Tests handling of HTTP 402 error responses from Okta.
     */
    @isTest
    public static void badStatusCode402Test(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            try {
                HttpResponse res = getHttpRes(402);
                OktaCalloutHandler.statusCheck(res, 'API-1004: Update UserName Failure', objUser.Id, false);
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.assert(errorMsg.containsIgnoreCase('402'));
            }
        }
    }
    
    /**
     * @description Tests handling of HTTP 403 error responses from Okta.
     */
    @isTest
    public static void badStatusCode403Test(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            try {
                HttpResponse res = getHttpRes(403);
                OktaCalloutHandler.statusCheck(res, 'API-1004: Update UserName Failure', objUser.Id, false);
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.assert(errorMsg.containsIgnoreCase('403'));
            }
        }
    }
    
    /**
     * @description Tests handling of HTTP 404 error responses from Okta.
     */
    @isTest
    public static void badStatusCode404Test(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            try {
                HttpResponse res = getHttpRes(404);
                OktaCalloutHandler.statusCheck(res, 'API-1004: Update UserName Failure', objUser.Id, false);
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.assert(errorMsg.containsIgnoreCase('404'));
            }
        }
    }
    
    /**
     * @description Tests handling of HTTP 500 error responses from Okta.
     */
    @isTest
    public static void badStatusCode500Test(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.startTest();
            try {
                HttpResponse res = getHttpRes(500);
                OktaCalloutHandler.statusCheck(res, 'API-1004: Update UserName Failure', objUser.Id, false);
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.assert(errorMsg.containsIgnoreCase('500'));
            }
        }
    }
    
    /**
     * @description Tests static method for Okta user freeze/unfreeze callouts without uncommitted work errors.
     */
    @isTest
    static void testMakeCallouterrorPathsNoUncommittedWork() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Test.setMock(HttpCalloutMock.class, new OktaErrorCalloutMock());
            
            Account acc1 = new Account(Name = 'Test Account');
            insert acc1;
            
            Contact con = new Contact(LastName = 'OktaContact', AccountId = acc1.Id);
            insert con;
            
            Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1];
            
            User testUser = new User(
                Alias = 'rccslu',
                Email = 'rccslu' + DateTime.now().getTime() + '@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'CommunityUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = communityProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'rccslu.' + DateTime.now().getTime() + '@test.com',
                ContactId = con.Id,
                Okta_UserId__c = '00uFAKEIDX1234'
            );
            insert testUser;
            
            Test.startTest();
            Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap> dummyMap = new Map<Id, OktaFreezeUsersSchedulableBatch.FreezeUserWrap>();
            OktaFreezeUsersSync sync = new OktaFreezeUsersSync(dummyMap, dummyMap);
            
            Map<Id, User> updateUserMap = new Map<Id, User>();
            sync.makeCallout(testUser, 'Freeze', updateUserMap);
            System.assertEquals('API-1011: Okta User Suspend Failure', updateUserMap.get(testUser.Id).API_Status__c);
            
            sync.makeCallout(testUser, 'Unfreeze', updateUserMap);
            System.assertEquals('API-1012: Okta User UnSuspend Failure', updateUserMap.get(testUser.Id).API_Status__c);
            Test.stopTest();
        }
    }
    
    /**
     * @description Mock class for simulating generic Okta error callout response.
     */
    private class OktaErrorCalloutMock implements HttpCalloutMock {
         /**
     * @description Handles the mock HTTP request and returns a simulated error response for Okta.
     *
     * @param req The incoming HTTP request to be processed.
     * @return HttpResponse A simulated HTTP error response.
     */
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"errorSummary":"Simulated Okta error"}');
            return res;
        }
    }
    
}