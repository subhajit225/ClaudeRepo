@isTest(seeAllData=false)
public class CS_RegisterThirdPartyHWControllerTest {

    @testSetup static void setup() {
        insert new TriggerControl__c(Name='Entitlement');
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = UserInfo.getUserId());
        sdb.Disable_Email_Alerts__c = true;
        sdb.Disable_Entitlement_Validation_Rules__c = true;
        insert sdb;
        Profile systemAdmin = [Select Id from Profile where Name = 'System Administrator'];
        
        User user1 = new User(Alias = 'standt', Email='adminduser@testorgrbk.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121rbk.com');
        insert user1;
        test.startTest();
        List<Account> accountList = new List<Account>();

        Account acc = new Account(name='Test Account 1');
        accountList.add(acc);

        acc = new Account(name='Test Account 2');
        accountList.add(acc);
        insert accountList;
		RecordType rt = [SELECT Id,DeveloperName  FROM RecordType WHERE SobjectType='Entitlement' AND DeveloperName = 'Manufacturing_Entitlement' LIMIT 1];

        List<Contact> contactList = new List<Contact>();
        Contact cont = new Contact(lastName='Test Contact 1');
        cont.Notify_For_case_creation__c = true;
        cont.Email = 'testContact1@test.com';
        cont.AccountId = accountList[0].Id;
        contactList.add(cont);

        cont = new Contact(lastName='Test Contact 2');
        cont.Notify_For_case_creation__c = true;
        cont.Email = 'testContact2@test.com';
        cont.AccountId = accountList[1].Id;
        contactList.add(cont);
        insert contactList;

        List<Product2> productList = new List<Product2>();
        Product2 prod = (Product2)ShGl_TestFactory.createSObject(new Product2(), null);
        prod.Name = 'RBK-HPE380S96FPAS';
        prod.ProductCode = 'RBK-HPE380S96FPAS';
        prod.Category__c = 'Support';
        prod.Support_Type__c = 'L3';
        productList.add(prod);

        prod = (Product2)ShGl_TestFactory.createSObject(new Product2(), null);
        prod.Name = 'RBK-DELL-6420';
        prod.ProductCode = 'RBK-DELL-6420';
        prod.Category__c = 'Support';
        prod.Support_Type__c = 'L3';
        productList.add(prod);
        insert productList;

        List<Entitlement> entitlementList = new List<Entitlement>();
        Entitlement ent = (Entitlement)ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent.AccountId = accountList[0].Id;
        ent.Product__c = productList[0].Id;
        ent.Name = productList[0].Name;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        ent.Type = 'Manufacturing Entitlement';
        ent.RecordTypeId = rt.Id;
        entitlementList.add(ent);

        ent = (Entitlement)ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent.AccountId = accountList[0].Id;
        ent.Product__c = productList[0].Id;
        ent.Name = productList[0].Name;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(-10);
        ent.Type = 'Manufacturing Entitlement';
        ent.RecordTypeId = rt.Id;
        entitlementList.add(ent);

        ent = (Entitlement)ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent.AccountId = accountList[1].Id;
        ent.Product__c = productList[1].Id;
        ent.Name = productList[1].Name;
        ent.RecordTypeId = rt.Id;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        ent.Type = 'Manufacturing Entitlement';
        entitlementList.add(ent);
        insert entitlementList;

        Id communityprofileId = [select Id from Profile where name = 'Rubrik Customer Community Super Login User'].id;

        List<User> userList = new List<User>();
        User supportPortalUser = new User(alias = 'testCon1', email='testContact1@test.com',
                                           emailencodingkey='UTF-8', lastname='Contact 1', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = contactList[0].Id, FirstName = 'Test',
                                           timezonesidkey='America/Los_Angeles', username='testContact1@test.com', isAuthorizedUser__c=true);
        userList.add(supportPortalUser);

        supportPortalUser = new User(alias = 'testCon2', email='testContact2@test.com',
                                           emailencodingkey='UTF-8', lastname='Contact 2', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = contactList[1].Id, FirstName = 'Test',
                                           timezonesidkey='America/Los_Angeles', username='testContact2@test.com', isAuthorizedUser__c=true);
        userList.add(supportPortalUser);
        insert userList;
        Test.stopTest();
    }
	/**
    * @description
    */
    public static testmethod void testInvalidEntitlementAndValidNodeId(){
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = '5507h000000345';
        formFieldsWrapper.manufacturingTime = '';
        formFieldsWrapper.nodeId = 'RHPDL380GOEPRSDV';
        formFieldsWrapper.serialNumber = '';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id FROM User WHERE Username = 'testContact1@test.com'];
        System.runAs(u){
            resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
        }

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(true, resultWrapper[0].internalError);
        System.assertEquals(System.Label.No_Entitlement_Error + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text, resultWrapper[0].message);
    }
	/**
    * @description
    */
    public static testmethod void testInvalidEntitlementAndNodeId(){
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = '5507h000000345';
        formFieldsWrapper.manufacturingTime = '';
        formFieldsWrapper.nodeId = '';
        formFieldsWrapper.serialNumber = '';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id FROM User WHERE Username = 'testContact1@test.com'];
        System.runAs(u){
            resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
        }

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(true, resultWrapper[0].internalError);
        System.assertEquals(System.Label.No_Entitlement_Error + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text, resultWrapper[0].message);
        //System.assertEquals(true, resultWrapper[1].internalError);
        //System.assertEquals(System.Label.Invalid_Node_Id_Error, resultWrapper[1].message);
    }
	/**
    * @description
    */
    public static testmethod void testValidEntitlementAndInvalidNodeId(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' AND Status = 'Active' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '';
        formFieldsWrapper.nodeId = 'RCC20ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = '';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id FROM User WHERE Username = 'testContact1@test.com'];
        System.runAs(u){
            resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
        }

        System.assertEquals(1, resultWrapper.size());
        //System.assertEquals(true, resultWrapper[1].internalError);
        //System.assertEquals(System.Label.Invalid_Node_Id_Error, resultWrapper[1].message);
    }
	/**
    * @description
    */
    public static testmethod void testExpiredEntitlementAndValidNodeId(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' AND Status != 'Active' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = '';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id FROM User WHERE Username = 'testContact1@test.com'];
        System.runAs(u){
            resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
        }

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(true, resultWrapper[0].internalError);
        System.assertEquals(System.Label.Expired_Entitlement_Error + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text, resultWrapper[0].message);
    }
	/**
    * @description
    */
    public static testmethod void testExpiredEntitlementAndInvalidNodeId(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' AND Status != 'Active' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '';
        formFieldsWrapper.nodeId = 'AK220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = '';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id FROM User WHERE Username = 'testContact1@test.com'];
        System.runAs(u){
            resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
        }

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(true, resultWrapper[0].internalError);
        System.assertEquals(System.Label.Expired_Entitlement_Error + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text,  resultWrapper[0].message);
        //System.assertEquals(true, resultWrapper[1].internalError);
        //System.assertEquals(System.Label.Invalid_Node_Id_Error, resultWrapper[1].message);
    }
	/**
    * @description
    */
    public static testmethod void testActiveEntitlementAndInvalidNodeId(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' AND Status = 'Active' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '';
        formFieldsWrapper.nodeId = 'GO220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = '';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        EntitlementContact entContact = new EntitlementContact();
        entContact.ContactId = u.ContactId;
        entContact.EntitlementId = ent.Id;
        insert entContact;

        System.runAs(u){
            String mockResponse = '123';
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json', mockResponse, 101));
            resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
        }

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(false, resultWrapper[0].internalError);
        //System.assertEquals(System.Label.Invalid_Node_Id_Error, resultWrapper[0].message);
    }

    /*public static testmethod void testEntitlementNotOnAccount(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-DELL-6420' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = '';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        EntitlementContact entContact = new EntitlementContact();
        entContact.ContactId = u.ContactId;
        entContact.EntitlementId = ent.Id;
        insert entContact;

        System.runAs(u){
            resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
        }

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(true, resultWrapper[0].internalError);
        System.assertEquals('', resultWrapper[0].message);
        System.assertEquals(true, resultWrapper[0].entitlementVerificationResult[0].error);
        System.assertEquals(false, resultWrapper[0].entitlementVerificationResult[1].error);
    }*/
	/**
    * @description
    */
    public static testmethod void testEntitlementNotOnContact(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' AND Status = 'Active' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = '';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        System.runAs(u){
            resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
        }

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(true, resultWrapper[0].internalError);
        System.assertEquals('', resultWrapper[0].message);
        System.assertEquals(true, resultWrapper[0].entitlementVerificationResult[0].error);
        //System.assertEquals(true, resultWrapper[0].entitlementVerificationResult[1].error);
    }

    /*public static testmethod void testEntitlementNotOnContactAndAccount(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-DELL-6420' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = '';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        System.runAs(u){
            resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
        }

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(true, resultWrapper[0].internalError);
        System.assertEquals('', resultWrapper[0].message);
        System.assertEquals(true, resultWrapper[0].entitlementVerificationResult[0].error);
        System.assertEquals(true, resultWrapper[0].entitlementVerificationResult[1].error);
    }*/
	/**
    * @description
    */
    public static testmethod void testFirstHbxCalloutConnectionError(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '2021-02-02T12:02:02';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = 'ASDFJWE2321';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '5ac8e20d-21e0-44d9-8d0a-0f48fda6e341';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        EntitlementContact entContact = new EntitlementContact();
        entContact.ContactId = u.ContactId;
        entContact.EntitlementId = ent.Id;
        insert entContact;

        Test.startTest();
            System.runAs(u){
                String mockResponse = 'Error in connection';
                Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json', mockResponse, 500));
                resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
            }
        Test.stopTest();

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(false, resultWrapper[0].internalError);
        System.assertEquals(true, resultWrapper[0].integrationError);
        System.assertEquals(System.Label.Heartbeat_not_responding_error + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text, resultWrapper[0].message);
    }
	/**
    * @description
    */
    public static testmethod void testFirstHbxCalloutValidationError(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '2021-02-02T12:02:02';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = 'ASDFJWE2321';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '5ac8e20d-21e0-44d9-8d0a-0f48fda6e341';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        EntitlementContact entContact = new EntitlementContact();
        entContact.ContactId = u.ContactId;
        entContact.EntitlementId = ent.Id;
        insert entContact;

        Test.startTest();
            System.runAs(u){
                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse mockResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse();
                mockResponseObject.message = 'Validation failure';
                String mockResponse = JSON.serialize(mockResponseObject);
                Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json', mockResponse, 400));
                resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
            }
        Test.stopTest();

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(false, resultWrapper[0].internalError);
        System.assertEquals(true, resultWrapper[0].integrationError);
        System.assertEquals('Validation failure', resultWrapper[0].message);
    }
	/**
    * @description
    */
    public static testmethod void testTeleportCalloutSuccess(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '2021-02-02T12:02:02';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = 'ASDFJWE2321';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '5ac8e20d-21e0-44d9-8d0a-0f48fda6e341';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        EntitlementContact entContact = new EntitlementContact();
        entContact.ContactId = u.ContactId;
        entContact.EntitlementId = ent.Id;
        insert entContact;

        Test.startTest();
            System.runAs(u){
                String mockResponse = '123';
                Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json', mockResponse, 200));
                resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
            }
        Test.stopTest();

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(false, resultWrapper[0].internalError);
        System.assertEquals(false, resultWrapper[0].integrationError);
        System.assertEquals('123', resultWrapper[0].message);
    }
    /*
    public static testmethod void testSecondHbxCalloutConnectionError(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '2021-02-02T12:02:02';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = 'ASDFJWE2321';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '5ac8e20d-21e0-44d9-8d0a-0f48fda6e341';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        EntitlementContact entContact = new EntitlementContact();
        entContact.ContactId = u.ContactId;
        entContact.EntitlementId = ent.Id;
        insert entContact;

        Test.startTest();
            System.runAs(u){
                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse firstCalloutResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse();
                firstCalloutResponseObject.message = 'First call successful';
                firstCalloutResponseObject.serial_number = formFieldsWrapper.serialNumber;
                String firstCalloutResponse = JSON.serialize(firstCalloutResponseObject);
                GenericMockHttpResponseGenerator firstCallout = new GenericMockHttpResponseGenerator('application/Json', firstCalloutResponse, 200);

                String mockResponse = 'Error in connection';
                GenericMockHttpResponseGenerator secondCallout = new GenericMockHttpResponseGenerator('application/Json', mockResponse, 500);

                HTTPCalloutServiceMultiMock multiMock = new HTTPCalloutServiceMultiMock();
                multiMock.addCalloutMock('heartbeatPost', firstCallout);
                multiMock.addCalloutMock('heartbeatPatch', secondCallout);

                Test.setMock(HttpCalloutMock.class, multiMock);
                //Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json', mockResponse, 200));
                resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
            }
        Test.stopTest();

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(false, resultWrapper[0].internalError);
        System.assertEquals(true, resultWrapper[0].integrationError);
        System.assertEquals(System.Label.Heartbeat_not_responding_error + ' ' + System.Label.Open_a_Case_Text + ' ' + System.Label.With_Rubrik_Support_Text, resultWrapper[0].message);
    }

    public static testmethod void testSecondHbxCalloutValidationError(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '2021-02-02T12:02:02';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = 'ASDFJWE2321';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '5ac8e20d-21e0-44d9-8d0a-0f48fda6e341';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        EntitlementContact entContact = new EntitlementContact();
        entContact.ContactId = u.ContactId;
        entContact.EntitlementId = ent.Id;
        insert entContact;

        Test.startTest();
            System.runAs(u){
                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse firstCalloutResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse();
                firstCalloutResponseObject.message = 'First call successful';
                firstCalloutResponseObject.serial_number = formFieldsWrapper.serialNumber;
                String firstCalloutResponse = JSON.serialize(firstCalloutResponseObject);
                GenericMockHttpResponseGenerator firstCallout = new GenericMockHttpResponseGenerator('application/Json', firstCalloutResponse, 200);

                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse secondCalloutResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse();
                secondCalloutResponseObject.message = 'Validation failure';
                String mockResponse = JSON.serialize(secondCalloutResponseObject);
                GenericMockHttpResponseGenerator secondCallout = new GenericMockHttpResponseGenerator('application/Json', mockResponse, 400);

                HTTPCalloutServiceMultiMock multiMock = new HTTPCalloutServiceMultiMock();
                multiMock.addCalloutMock('heartbeatPost', firstCallout);
                multiMock.addCalloutMock('heartbeatPatch', secondCallout);

                Test.setMock(HttpCalloutMock.class, multiMock);
                resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
            }
        Test.stopTest();

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(false, resultWrapper[0].internalError);
        System.assertEquals(true, resultWrapper[0].integrationError);
        System.assertEquals('Validation failure', resultWrapper[0].message);
    }

    public static testmethod void testTeleportCalloutError(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '2021-02-02T12:02:02';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = 'ASDFJWE2321';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '5ac8e20d-21e0-44d9-8d0a-0f48fda6e341';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        EntitlementContact entContact = new EntitlementContact();
        entContact.ContactId = u.ContactId;
        entContact.EntitlementId = ent.Id;
        insert entContact;

        Test.startTest();
            System.runAs(u){
                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse firstCalloutResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse();
                firstCalloutResponseObject.message = 'First call successful';
                firstCalloutResponseObject.serial_number = formFieldsWrapper.serialNumber;
                String firstCalloutResponse = JSON.serialize(firstCalloutResponseObject);
                GenericMockHttpResponseGenerator firstCallout = new GenericMockHttpResponseGenerator('application/Json', firstCalloutResponse, 200);

                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse secondCalloutResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse();
                secondCalloutResponseObject.message = 'Second call successful';
                String secondCalloutResponse = JSON.serialize(secondCalloutResponseObject);
                GenericMockHttpResponseGenerator secondCallout = new GenericMockHttpResponseGenerator('application/Json', secondCalloutResponse, 200);

                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareTeleportResponse thirdCalloutResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareTeleportResponse();
                thirdCalloutResponseObject.status = 'Teleport error';
                thirdCalloutResponseObject.entitlement_token = '';
                thirdCalloutResponseObject.node_id = formFieldsWrapper.nodeId;
                String mockResponse = JSON.serialize(new List<CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareTeleportResponse>{thirdCalloutResponseObject});
                System.debug('mockresponse====='+mockResponse);
                GenericMockHttpResponseGenerator thirdCallout = new GenericMockHttpResponseGenerator('application/Json', mockResponse, 200);

                HTTPCalloutServiceMultiMock multiMock = new HTTPCalloutServiceMultiMock();
                multiMock.addCalloutMock('heartbeatPost', firstCallout);
                multiMock.addCalloutMock('heartbeatPatch', secondCallout);
                multiMock.addCalloutMock('teleport', thirdCallout);

                Test.setMock(HttpCalloutMock.class, multiMock);
                resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
            }
        Test.stopTest();

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(false, resultWrapper[0].internalError);
        System.assertEquals(true, resultWrapper[0].integrationError);
        System.assertEquals('Teleport error', resultWrapper[0].message);
    }

    public static testmethod void testTeleportCalloutSuccess(){
        Entitlement ent = [SELECT Id FROM Entitlement WHERE Name = 'RBK-HPE380S96FPAS' LIMIT 1];
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFieldsWrapper = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm();
        formFieldsWrapper.entitlementId = ent.Id;
        formFieldsWrapper.manufacturingTime = '2021-02-02T12:02:02';
        formFieldsWrapper.nodeId = 'RC220ASDFEWEJDSI';
        formFieldsWrapper.serialNumber = 'ASDFJWE2321';
        formFieldsWrapper.teleportToken = '';
        formFieldsWrapper.uuid = '5ac8e20d-21e0-44d9-8d0a-0f48fda6e341';

        String formFieldsString = JSON.serialize(formFieldsWrapper);
        List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper> resultWrapper = new List<CS_RegisterThirdPartyHWController.ThirdPartyHardwareResultWrapper>();

        User u = [SELECT Id, ContactId FROM User WHERE Username = 'testContact1@test.com'];

        EntitlementContact entContact = new EntitlementContact();
        entContact.ContactId = u.ContactId;
        entContact.EntitlementId = ent.Id;
        insert entContact;

        Test.startTest();
            System.runAs(u){
                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse firstCalloutResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse();
                firstCalloutResponseObject.message = 'First call successful';
                firstCalloutResponseObject.serial_number = formFieldsWrapper.serialNumber;
                firstCalloutResponseObject.authorization_keys = '';
                firstCalloutResponseObject.error = '';
                firstCalloutResponseObject.hbx_session_api_token = '';
                firstCalloutResponseObject.rksupport_creds = '';
                firstCalloutResponseObject.success = '';
                String firstCalloutResponse = JSON.serialize(firstCalloutResponseObject);
                GenericMockHttpResponseGenerator firstCallout = new GenericMockHttpResponseGenerator('application/Json', firstCalloutResponse, 200);

                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse secondCalloutResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareNodeResponse();
                secondCalloutResponseObject.message = 'Second call successful';
                String secondCalloutResponse = JSON.serialize(secondCalloutResponseObject);
                GenericMockHttpResponseGenerator secondCallout = new GenericMockHttpResponseGenerator('application/Json', secondCalloutResponse, 200);

                CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareTeleportResponse thirdCalloutResponseObject = new CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareTeleportResponse();
                thirdCalloutResponseObject.status = '';
                thirdCalloutResponseObject.entitlement_token = '';
                thirdCalloutResponseObject.node_id = formFieldsWrapper.nodeId;
                String mockResponse = JSON.serialize(new List<CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareTeleportResponse>{thirdCalloutResponseObject});
                GenericMockHttpResponseGenerator thirdCallout = new GenericMockHttpResponseGenerator('application/Json', mockResponse, 200);

                HTTPCalloutServiceMultiMock multiMock = new HTTPCalloutServiceMultiMock();
                multiMock.addCalloutMock('heartbeatPost', firstCallout);
                multiMock.addCalloutMock('heartbeatPatch', secondCallout);
                multiMock.addCalloutMock('teleport', thirdCallout);

                Test.setMock(HttpCalloutMock.class, multiMock);
                resultWrapper = CS_RegisterThirdPartyHWController.registerThirdPartyHardware(formFieldsString);
            }
        Test.stopTest();

        System.assertEquals(1, resultWrapper.size());
        System.assertEquals(false, resultWrapper[0].internalError);
        System.assertEquals(false, resultWrapper[0].integrationError);
        System.assertEquals('eyJleHBpcmVzIjoxNjM3MTM4NzExLCJzaWduYXR1cmUiOUdyS0VNeWp', resultWrapper[0].message);
    }*/
}