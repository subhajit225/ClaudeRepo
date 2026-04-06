@istest
public class HbxProxcyControllerTest {
    
    @testSetup 
    static void createTestData() {
        OktaUserUtilityTest.oktaCustomSettingsParams();

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Community Super User'].Id;
        
        account acct=new account(name='test account',AccountNumber='123456');
        insert acct;
        contact con=new contact(lastname='test contact',leadsource='web',
                                    email='testc@test.com',accountId=acct.id);
        insert con;
                    
        User user = new User(alias = 'mifam', email= 'mifarLand@muzitp.com',
                emailencodingkey='UTF-8', lastname='muzitp', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profileId, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='mifarLand@muzitp.com');
        
        insert user;
    }
    
    @isTest
    static void  processPostRequestTest() {

       User usr =[select id from user where ContactId!=null and isActive=true order by createddate desc limit 1];
        system.runAs(usr) {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new RestMock());
          RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            String JSONMsg = '{\"okta_creds\":{\"password\":\"Demo@0987\",\"username\":\"mifarLand@muzitp.com\"},\"hbx_data\":{\"endpoint\":\"node/register-server/RHPDL380PWWRH0JLMCO13F\",\"body\":{\"asset_id\":\"RHPDL380PWWRH0JLMCO13F\",\"chassis_id\":\"sdfsf\",\"vendor\":\"HPE\",\"system_uuid\":\"dasassd\",\"entitlement_id\":\"5501W000002w1WTQAY\",\"product_code\":\"ProLiantDL360Gen10\",\"user_id\":\"005Dy000003wZiqIAE\",\"asset\":\"2M2938031D\",\"bios_version\":\"U30\",\"board_serial\":\"RHPDL380PWWRH0JLMCO13F\",\"chassis\":\"2M2938031D\",\"cluster\":\"14f86cd2-9e20-42af-9c50-8b83512d2527\",\"cpu_model\":\"Intel(R)Xeon(R)Gold6130CPU@2.10GHz\",\"ipmi_mac_addr\":\"94:40:c9:1a:37:90\",\"mac_address_0\":\"94:40:c9:1a:37:92\",\"mac_address_1\":\"94:40:c9:1a:37:93\",\"manual_registration\":null,\"node_position\":null,\"manufactured_date\":\"2019-11-08T20:23:03\",\"model\":null,\"serial_number\":\"RHPDL380PWWRH0JLMCO13F\",\"software_version\":\"9.0-dev-22975\",\"teleport_token\":\"DAHAFXYWBVCBFR4MNZJUOHMHOB74QHG5PACHW34UTE7JOFYANXVQ-FOUPSR7K4XEEBXVID6KHQLS2AI3JF4DGLRH5YZTMZUJTFB4IVADQ\",\"tpm_present\":\"False\"}}}';
            req.requestURI = 'https://rubrikinc--rbkuat.sandbox.my.site.com/CustomerSupport/services/apexrest/hbxproxynew';  //Request URL
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(JSONMsg);
            req.addHeader('Content-Type', 'application/json'); 
            RestContext.request = req;
            RestContext.response = res;
            
            HbxProxcyController.processPostRequest();
        Test.stopTest();
        }
        RestResponse oresp =  RestContext.response;
        System.assertEquals(200, oresp.statusCode);
    } 

    // System.AssertException: Assertion Failed: unexpected endpoint https://sandbox.heartbeat.rubrik.com/node/register-server/RHPDL380PWWRH0JLMCO13F


    // positive response
    private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setStatusCode(200);
            res.setStatus('OK');

            // Pulic apex class res if Status is 200 from HBX Server
            if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/node/register-server/')) {
                res.setBody('eyJleHBpcmVzIjoxNjkyODg0NDU5LCJzaWduYXR1cmUiOiJNRVVDSUIxWGFtb3pNS1lSdW94YXdtbWNCdHE0VTdyK1FsZzdubXlUVkRpUW1Fa0NBaUVBc1BocEtBdDdNbGpETXV1YUNhQ1JXbzhNNkY3YXkxd0dtOVV0OU04T1BGYz0iLCJ0b2tlbl9kYXRhIjp7Im1hbnVmYWN0dXJpbmdfdGltZSI6IjIwMTktMTEtMDhUMjA6MjM6MDMifX0=');
                return res;
            } 
            // Okta User authn
            else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/api/v1/authn')) {
                res.setBody('{\"expiresAt\":\"2023-08-25T07:46:46.000Z\",\"status\":\"SUCCESS\",\"sessionToken\":\"201111QG3KsbfoX2SBam07DoCts2bxXpUZ_8bDfqty1WjW7mC3kI-vX\",\"_embedded\":{\"user\":{\"id\":\"00u98cx97srgK6ij71d7\",\"passwordChanged\":\"2023-08-01T06:57:59.000Z\",\"profile\":{\"login\":\"rowiwak978@kkoup.com\",\"firstName\":\"Rovio\",\"lastName\":\"AB\",\"locale\":\"en_US\",\"timeZone\":\"America/Los_Angeles\"}}},\"_links\":{\"cancel\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/authn/cancel\",\"hints\":{\"allow\":[\"POST\"]}}}}');
                return res;
            } 
            // Okta to get SupportPortalUserName
            else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/api/v1/users/')) {
                res.setBody('{\"id\":\"00u8yuijqxn3hT4m51d7\",\"status\":\"ACTIVE\",\"created\":\"2023-07-18T09:42:33.000Z\",\"activated\":\"2023-07-18T09:42:34.000Z\",\"statusChanged\":\"2023-07-18T09:43:20.000Z\",\"lastLogin\":\"2023-08-25T07:20:14.000Z\",\"lastUpdated\":\"2023-07-18T09:43:20.000Z\",\"passwordChanged\":\"2023-07-18T09:43:20.000Z\",\"type\":{\"id\":\"oty6gp7ph7DMongG61d7\"},\"profile\":{\"firstName\":\"Supportuser\",\"lastName\":\"18thjuly\",\"sfdcCustomerPortalUsername\":\"mifarLand@muzitp.com\",\"mobilePhone\":null,\"secondEmail\":null,\"login\":\"mifarLand@muzitp.com\",\"email\":\"mifarLand@muzitp.com\"},\"credentials\":{\"password\":{},\"provider\":{\"type\":\"OKTA\",\"name\":\"OKTA\"}},\"_links\":{\"suspend\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/suspend\",\"method\":\"POST\"},\"schema\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/meta/schemas/user/osc6gp7ph7DMongG61d7\"},\"resetPassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/reset_password\",\"method\":\"POST\"},\"forgotPassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/credentials/forgot_password\",\"method\":\"POST\"},\"expirePassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/expire_password\",\"method\":\"POST\"},\"changeRecoveryQuestion\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/credentials/change_recovery_question\",\"method\":\"POST\"},\"self\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7\"},\"resetFactors\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/reset_factors\",\"method\":\"POST\"},\"type\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/meta/types/user/oty6gp7ph7DMongG61d7\"},\"changePassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/credentials/change_password\",\"method\":\"POST\"},\"deactivate\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/deactivate\",\"method\":\"POST\"}}}');
                return res;
            }  else {
                System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
                return null;
            }
        }
    }

    @isTest
    static void  inValidOktaUserTest() {

        User usr =[select id from user where ContactId!=null and isActive=true order by createddate desc limit 1];
        system.runAs(usr) {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new FalseMockAuthn());
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            String JSONMsg = '{\"okta_creds\":{\"password\":\"Demo@0987\",\"username\":\"mifarLand@muzitp.com\"},\"hbx_data\":{\"endpoint\":\"node/register-server/RHPDL380PWWRH0JLMCO13F\",\"body\":{\"asset_id\":\"RHPDL380PWWRH0JLMCO13F\",\"chassis_id\":\"sdfsf\",\"vendor\":\"HPE\",\"system_uuid\":\"dasassd\",\"entitlement_id\":\"5501W000002w1WTQAY\",\"product_code\":\"ProLiantDL360Gen10\",\"user_id\":\"005Dy000003wZiqIAE\",\"asset\":\"2M2938031D\",\"bios_version\":\"U30\",\"board_serial\":\"RHPDL380PWWRH0JLMCO13F\",\"chassis\":\"2M2938031D\",\"cluster\":\"14f86cd2-9e20-42af-9c50-8b83512d2527\",\"cpu_model\":\"Intel(R)Xeon(R)Gold6130CPU@2.10GHz\",\"ipmi_mac_addr\":\"94:40:c9:1a:37:90\",\"mac_address_0\":\"94:40:c9:1a:37:92\",\"mac_address_1\":\"94:40:c9:1a:37:93\",\"manual_registration\":null,\"node_position\":null,\"manufactured_date\":\"2019-11-08T20:23:03\",\"model\":null,\"serial_number\":\"RHPDL380PWWRH0JLMCO13F\",\"software_version\":\"9.0-dev-22975\",\"teleport_token\":\"DAHAFXYWBVCBFR4MNZJUOHMHOB74QHG5PACHW34UTE7JOFYANXVQ-FOUPSR7K4XEEBXVID6KHQLS2AI3JF4DGLRH5YZTMZUJTFB4IVADQ\",\"tpm_present\":\"False\"}}}';
            req.requestURI = 'https://rubrikinc--rbkuat.sandbox.my.site.com/CustomerSupport/services/apexrest/hbxproxynew';  //Request URL
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(JSONMsg);
            req.addHeader('Content-Type', 'application/json'); 
            RestContext.request = req;
            RestContext.response = res;
            HbxProxcyController.processPostRequest();
        Test.stopTest();
        }
        RestResponse oresp =  RestContext.response;
        System.assertEquals(404, oresp.statusCode);
    } 

    // negetive response
    private class FalseMockAuthn implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setStatusCode(404);
            res.setStatus('NOT_FOUND');

            // Pulic apex class res if Status is 200 from HBX Server
            if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/node/register-server/')) {
                res.setBody('eyJleHBpcmVzIjoxNjkyODg0NDU5LCJzaWduYXR1cmUiOiJNRVVDSUIxWGFtb3pNS1lSdW94YXdtbWNCdHE0VTdyK1FsZzdubXlUVkRpUW1Fa0NBaUVBc1BocEtBdDdNbGpETXV1YUNhQ1JXbzhNNkY3YXkxd0dtOVV0OU04T1BGYz0iLCJ0b2tlbl9kYXRhIjp7Im1hbnVmYWN0dXJpbmdfdGltZSI6IjIwMTktMTEtMDhUMjA6MjM6MDMifX0=');
                return res;
            } 
            // Okta User authn
            else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/api/v1/authn')) {
                res.setBody('{\"expiresAt\":\"2023-08-25T07:46:46.000Z\",\"status\":\"SUCCESS\",\"sessionToken\":\"201111QG3KsbfoX2SBam07DoCts2bxXpUZ_8bDfqty1WjW7mC3kI-vX\",\"_embedded\":{\"user\":{\"id\":\"00u98cx97srgK6ij71d7\",\"passwordChanged\":\"2023-08-01T06:57:59.000Z\",\"profile\":{\"login\":\"rowiwak978@kkoup.com\",\"firstName\":\"Rovio\",\"lastName\":\"AB\",\"locale\":\"en_US\",\"timeZone\":\"America/Los_Angeles\"}}},\"_links\":{\"cancel\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/authn/cancel\",\"hints\":{\"allow\":[\"POST\"]}}}}');
                return res;
            } else {
                System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
                return null;
            }
        }
    }

    @isTest
    static void  portalUserNameNotFoundTest() {

        User usr =[select id from user where ContactId!=null and isActive=true order by createddate desc limit 1];
        system.runAs(usr) {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new FalseMockPortalUserName());
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            String JSONMsg = '{\"okta_creds\":{\"password\":\"Demo@0987\",\"username\":\"mifarLand@muzitp.com\"},\"hbx_data\":{\"endpoint\":\"node/register-server/RHPDL380PWWRH0JLMCO13F\",\"body\":{\"asset_id\":\"RHPDL380PWWRH0JLMCO13F\",\"chassis_id\":\"sdfsf\",\"vendor\":\"HPE\",\"system_uuid\":\"dasassd\",\"entitlement_id\":\"5501W000002w1WTQAY\",\"product_code\":\"ProLiantDL360Gen10\",\"user_id\":\"005Dy000003wZiqIAE\",\"asset\":\"2M2938031D\",\"bios_version\":\"U30\",\"board_serial\":\"RHPDL380PWWRH0JLMCO13F\",\"chassis\":\"2M2938031D\",\"cluster\":\"14f86cd2-9e20-42af-9c50-8b83512d2527\",\"cpu_model\":\"Intel(R)Xeon(R)Gold6130CPU@2.10GHz\",\"ipmi_mac_addr\":\"94:40:c9:1a:37:90\",\"mac_address_0\":\"94:40:c9:1a:37:92\",\"mac_address_1\":\"94:40:c9:1a:37:93\",\"manual_registration\":null,\"node_position\":null,\"manufactured_date\":\"2019-11-08T20:23:03\",\"model\":null,\"serial_number\":\"RHPDL380PWWRH0JLMCO13F\",\"software_version\":\"9.0-dev-22975\",\"teleport_token\":\"DAHAFXYWBVCBFR4MNZJUOHMHOB74QHG5PACHW34UTE7JOFYANXVQ-FOUPSR7K4XEEBXVID6KHQLS2AI3JF4DGLRH5YZTMZUJTFB4IVADQ\",\"tpm_present\":\"False\"}}}';
            req.requestURI = 'https://rubrikinc--rbkuat.sandbox.my.site.com/CustomerSupport/services/apexrest/hbxproxynew';  //Request URL
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(JSONMsg);
            req.addHeader('Content-Type', 'application/json'); 
            RestContext.request = req;
            RestContext.response = res;
            HbxProxcyController.processPostRequest();
        Test.stopTest();
        }
        RestResponse oresp =  RestContext.response;
        System.assertEquals(404, oresp.statusCode);
    } 

    // negetive response
    private class FalseMockPortalUserName implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            

            // Pulic apex class res if Status is 200 from HBX Server
            if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/node/register-server/')) {
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('eyJleHBpcmVzIjoxNjkyODg0NDU5LCJzaWduYXR1cmUiOiJNRVVDSUIxWGFtb3pNS1lSdW94YXdtbWNCdHE0VTdyK1FsZzdubXlUVkRpUW1Fa0NBaUVBc1BocEtBdDdNbGpETXV1YUNhQ1JXbzhNNkY3YXkxd0dtOVV0OU04T1BGYz0iLCJ0b2tlbl9kYXRhIjp7Im1hbnVmYWN0dXJpbmdfdGltZSI6IjIwMTktMTEtMDhUMjA6MjM6MDMifX0=');
                return res;
            } 
            // Okta User authn
            else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/api/v1/authn')) {
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('{\"expiresAt\":\"2023-08-25T07:46:46.000Z\",\"status\":\"SUCCESS\",\"sessionToken\":\"201111QG3KsbfoX2SBam07DoCts2bxXpUZ_8bDfqty1WjW7mC3kI-vX\",\"_embedded\":{\"user\":{\"id\":\"00u98cx97srgK6ij71d7\",\"passwordChanged\":\"2023-08-01T06:57:59.000Z\",\"profile\":{\"login\":\"rowiwak978@kkoup.com\",\"firstName\":\"Rovio\",\"lastName\":\"AB\",\"locale\":\"en_US\",\"timeZone\":\"America/Los_Angeles\"}}},\"_links\":{\"cancel\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/authn/cancel\",\"hints\":{\"allow\":[\"POST\"]}}}}');
                return res;
            }  
            // Okta to get SupportPortalUserName
            else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/api/v1/users/')) {
                res.setStatusCode(404);
                res.setStatus('NOT_FOUND');
                res.setBody('{\"id\":\"00u8yuijqxn3hT4m51d7\",\"status\":\"ACTIVE\",\"created\":\"2023-07-18T09:42:33.000Z\",\"activated\":\"2023-07-18T09:42:34.000Z\",\"statusChanged\":\"2023-07-18T09:43:20.000Z\",\"lastLogin\":\"2023-08-25T07:20:14.000Z\",\"lastUpdated\":\"2023-07-18T09:43:20.000Z\",\"passwordChanged\":\"2023-07-18T09:43:20.000Z\",\"type\":{\"id\":\"oty6gp7ph7DMongG61d7\"},\"profile\":{\"firstName\":\"Supportuser\",\"lastName\":\"18thjuly\",\"sfdcCustomerPortalUsername\":\"mifarLand@muzitp.com\",\"mobilePhone\":null,\"secondEmail\":null,\"login\":\"mifarLand@muzitp.com\",\"email\":\"mifarLand@muzitp.com\"},\"credentials\":{\"password\":{},\"provider\":{\"type\":\"OKTA\",\"name\":\"OKTA\"}},\"_links\":{\"suspend\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/suspend\",\"method\":\"POST\"},\"schema\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/meta/schemas/user/osc6gp7ph7DMongG61d7\"},\"resetPassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/reset_password\",\"method\":\"POST\"},\"forgotPassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/credentials/forgot_password\",\"method\":\"POST\"},\"expirePassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/expire_password\",\"method\":\"POST\"},\"changeRecoveryQuestion\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/credentials/change_recovery_question\",\"method\":\"POST\"},\"self\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7\"},\"resetFactors\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/reset_factors\",\"method\":\"POST\"},\"type\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/meta/types/user/oty6gp7ph7DMongG61d7\"},\"changePassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/credentials/change_password\",\"method\":\"POST\"},\"deactivate\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u8yuijqxn3hT4m51d7/lifecycle/deactivate\",\"method\":\"POST\"}}}');
                return res;
            }  else {
                System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
                return null;
            }
            
        }
    }
   
}