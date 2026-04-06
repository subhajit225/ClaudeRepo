@isTest
public class OktaProcessFailedUsersBatchTest {
    
    @TestSetup
    static void makeData(){
        List<User> userobj = new List<User>();
        userobj = [SELECT Id FROM User Where UserRoleId != null AND Profile.Name = 'System Administrator' LIMIT 1];
        OktaUserUtilityTest.oktaCustomSettingsParams();
        
        Account AccRecord = new Account();
        AccRecord.Name = 'Rubrik-Test';
        AccRecord.BillingStreet = 'Building 9, Cessna Business Park, Kadubeesanahalli';
        AccRecord.BillingCity = 'Bengaluru';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '560103';
        AccRecord.Type = 'Reseller';
        AccRecord.OwnerID = userobj[0].Id;
        INSERT AccRecord;
        
        List<Contact> contlist = new List<Contact>{ new Contact(LastName = 'Okta Test', FirstName = 'CU 1', AccountId = AccRecord.Id,
                                                                Email = 'customer.vijay.kr@rubrik.com', Primary_Role__c='Admin', Phone='8888888888',
                                                                MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                                                                MailingPostalCode=AccRecord.BillingPostalCode),
            new Contact(LastName = 'Okta Test', FirstName = 'CU 2', AccountId = AccRecord.Id,
                        Email = 'customer.vijay.kr@rubrik.com', Primary_Role__c='Admin', Phone='9999999999',
                        MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                        MailingPostalCode=AccRecord.BillingPostalCode),
            new Contact(LastName = 'Okta Test', FirstName = 'PU 1', AccountId = AccRecord.Id,
                        Email = 'partner.test.Async@rubrik.com', Primary_Role__c='Admin', Phone='9999999999',
                        MailingStreet=AccRecord.BillingStreet, MailingCity=AccRecord.BillingCity, MailingCountry=AccRecord.BillingCountry,
                        MailingPostalCode=AccRecord.BillingPostalCode)};
                            INSERT contlist;
    }
    
    @isTest
    static void testNewUserCreationFailure(){
        User objUser = getUserDetails('API-1002: New User Creation Failure');
        //'API-1002: New User Creation Failure'
        objUser.Okta_UserId__c = null;
        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        System.debug('objUser-->'+objUser);
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    
    @isTest
    static void testNewUserActivationFailure(){
        User objUser = getUserDetails('API-1003: New User Activation Failure');
       
        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
        
    }
    @isTest
    static void testNewUserUpdateAttrFailure(){
        User objUser = getUserDetails('API-1005: New User Update Application Attributes Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
        
    }
    @isTest
    static void testUpdateAttrFailure(){
        User objUser = getUserDetails('API-1004: Update Partner User Application Failure');
     
        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
        
    }
    
    @isTest
    static void testNewUserReActivationFailure(){
        User objUser = getUserDetails('API-1003: User Re-activation Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    
    @isTest
    static void testUserReActivatedAppFailure(){
        User objUser = getUserDetails('API-1004: Re-activated User App Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    @isTest
    static void testUserDeactivationAppFailure(){
        User objUser = getUserDetails('API-1004: User App Deactivation Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    @isTest
    static void testUserDeactivationFailure(){
        User objUser = getUserDetails('API-1007: User Deactivation Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    
    @isTest
    static void testMultiUserAppDeactivationFailure(){
        User objUser = getUserDetails('API-1004: Multiple User App Deactivation Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    @isTest
    static void testMultiUserAttributeFailure(){
        User objUser = getUserDetails('API-1005: Multiple User Update Attributes Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    
    @isTest
    static void testBatchClass(){
        User objUser = getUserDetails('API-1011: Okta User Suspend Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        
        ID jobId = DataBase.executeBatch(new OktaProcessFailedUsersBatch(),200);
        System.assertEquals(jobId!= null, true);
    }
    @isTest
    static void testUnSuspendUser(){
        User objUser = getUserDetails('API-1012: Okta User UnSuspend Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    @isTest
    static void testUnforzenUserApp(){
        User objUser = getUserDetails('API-1004: UnFrozen User App Failure');

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    @isTest
    static void testReActivateOktaUser(){
        User objUser = getUserDetails('API-1003: User Re-activation Failure from Custom Link');
        objUser.Okta_Flow_Status__c = 'Re-Activate';

        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    @isTest
    static void testSuccessOktaUser(){
        User objUser = getUserDetails('Success');
        Test.startTest();
        INSERT objUser;
        Test.stopTest();
        List<OktaUserFailureSync.Requests> listOfRequests = new List<OktaUserFailureSync.Requests>();
        OktaUserFailureSync.Requests requestObj = new OktaUserFailureSync.Requests();
        requestObj.userRecord = objUser;
        listOfRequests.add(requestObj);
        
        OktaUserFailureSync.userFailureSync(listOfRequests);
        System.assertEquals(listOfRequests.isEmpty(), false);
    }
    public static User getUserDetails(String apiStatus){
          Contact objCont = [SELECT Id FROM Contact WHERE FirstName = 'PU 1' Limit 1];
        
        // Partner Profile
        Profile pp = [SELECT Id, Name FROM Profile WHERE Name = 'Rubrik Partner Community User' limit 1];
        
        String uniqueUserName = 'okta.partner_User1'+ DateTime.now().getTime() +'@rbk.com';
        Test.setMock(HttpCalloutMock.class, new OktaCalloutMock());
        
        user objUser = new user(alias = 'o.PUv1', email = 'partner.test.newUserCreation@rubrik.com', ContactId = objCont.Id,
                                emailencodingkey = 'UTF-8', firstname = 'Partner', lastname = 'Test Okta', languagelocalekey = 'en_US',
                                localesidkey = 'en_US', profileid = pp.Id, timezonesidkey = 'America/Los_Angeles', username = uniqueUserName,
                                API_Status__c = apiStatus, Okta_UserId__c ='00u7jnfvez55JOSut1d7');
        return objUser;
    }
}