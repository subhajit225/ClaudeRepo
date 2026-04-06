/*  
Test Class For: RegisterProduct
Developer Name: Grazitti
Created Date: 16/04/2016
*/
@isTest
public class RegisterProductTest{

    @TestSetup
    static void makeData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'CEO' Limit 1];

        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' AND isActive = true Limit 1];

        adminUser.UserRoleId = userRole.Id;
        update adminUser;

        System.runAs(adminUser){
            insert new TriggerControl__c(Name='Entitlement');
            Account acc = new Account(); 
                acc.name = ProductRegistrationPortalCallout.TEST_ACC_NAME;
            acc.type = 'Partner';
            insert acc ;
            
            Contact con = new Contact();
            con.lastName = 'Test Last';
            con.AccountId = acc.Id;
            con.Email = 'test@Hbx.com';
            insert con;

            Entitlement ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
            ent.AccountId = acc.Id;
            ent.StartDate = Date.today().addDays(-365);
            ent.EndDate = Date.today().addDays(365);
            ent.Entitlement_Usage__c = 34;
            insert ent;

            Node__c nodeObj = new Node__c(Name = 'RDL64208YHB9N2CNWS30081F000X02', serial_number__c = 'RDL64208YHB9N2CNWS30081F000X02');
            insert nodeObj;

            Entitlement_Use__c entuse = new Entitlement_Use__c();
            entuse.serial_number__c='39373638-3835-584D-5138-333830304B57';
            entuse.Name ='39373638-3835-584D-5138-333830304B57';
            entuse.entitlement__c = ent.id;
            entuse.Node__c = nodeObj.Id;
            entuse.contact__c = con.Id;
            insert entuse;
            
            Id userLicenseId = [ select Id from UserLicense where NAME = 'Customer Community Login' LIMIT 1].id;
            Id communityprofileId = [select Id from Profile where name = 'Rubrik Customer Community Super Login User' and UserLicenseId=:userLicenseId LIMIT 1].id;
            
            User portalAccountOwner = new User(alias = 'test123', email='test123@noemail.com',
                                            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                            localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                            ContactId = con.Id, FirstName = 'Test First',
                                                timezonesidkey='America/Los_Angeles', username='tester'+DateTime.now().getTime()+'@noemail.com', isAuthorizedUser__c=true);
            
            Database.insert(portalAccountOwner);
            
            Test.startTest();
            system.runAs(portalAccountOwner) {
                registerProduct.registerProduct('VRC2206TEST1','5ac8e20d-21e0-44d9-8d0a-0f48fda6e856', '2022-02-02T02:02:02', '54321', true);
                registerProduct.registerProduct('VRC2206TEST1','5ac8e20d-21e0-44d9-8d0a-0f48fda6e856', '2022-02-02T02:02:02', '54321', false);
                registerProduct.registerProduct('VRC2206TEST1','', '2022-02-02T02:02:02', '54321', false);
                registerProduct.registerMosacProduct('1234-1234-1234');
            }
            String errorMsg ='{ "message": { "error_code": "RBK11300102",'+
                                ' "error": "The cluster UUID 12345 is associated with a different customer/organization. For assistance with verifying that the Cluster UUID for your organization, open a case with Rubrik Support.",'+
                                '"cause": "The cluster UUID is associated with a different customer/organization.",'+
                                '"remedy": "Please contact Rubrik customer support for further assistance."}}';
            HeartbeatUtility.getHeartbeatErrorMessage(errorMsg, null);
            String errorMsg2 ='{ "message": { "error_code": "RBK11300104",'+
                                ' "error": "Teleport registration failed for VRC2206TEST1",'+
                                '"cause": "Teleport registration failed with message unable to register node with the teleport: ERROR:failed to parse registration token: invalid key in the token.",'+
                                '"remedy": "Please contact Rubrik customer support for further assistance."}}';
            HeartbeatUtility.getHeartbeatErrorMessage(errorMsg2, null);
            Test.stopTest();
        }
    }
    
    public static testMethod void getHeartbeatErrorMessageTest(){
        String errorMsg3 ='{ "message": { "error_code": "RBK11300104",'+
                                ' "error": "Teleport registration failed for VRC2206TEST1",'+
                                '"cause": "Teleport registration failed with message with node re-registration: ERROR:node RDL64208YHB9N2CNWS30081F000X02 is already registered, re-registration is not permitted: Node (RDL64208YHB9N2CNWS30081F000X02) is registered at 2023-05-19T20:12:17Z and after it was manufactured (2023-02-0212:02:022), hence overriding isn\'t allowead.",'+
                                '"remedy": "Please contact Rubrik customer support for further assistance."}}';
        String inpString = '{"uuid":"39373638-3835-584D-5138-333830304B57"}';
        CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm formFields = (CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm)JSON.deserialize(inpString, CS_ThirdPartyHWRegistrationHelper.ThirdPartyHardwareForm.class);
        HeartbeatUtility.getHeartbeatErrorMessage(errorMsg3, formFields);
        Entitlement_Use__c entUse = [SELECT Id, Name FROM Entitlement_Use__c Limit 1];
        System.assertEquals(entUse.Name, formFields.uuid);
    }
}