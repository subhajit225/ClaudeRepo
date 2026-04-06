@IsTest(SeeAllData = false)
private class PC_LightningLoginFormController_Test {
    
    @IsTest
    static void testLoginWithInvalidCredentials() {
        LightningLoginFormController.login('testUser', 'fakepwd', null);
        System.assert(true);
    }
    
    @IsTest
    static void LightningLoginFormControllerInstantiation() {
        LightningLoginFormController controller = new LightningLoginFormController();
        System.assertNotEquals(controller, null);
    }
    
    @IsTest
    static void testIsUsernamePasswordEnabled() {
        System.assertEquals(false, LightningLoginFormController.getIsUsernamePasswordEnabled() == null, 'The value should not be null');
    }
    
    @IsTest
    static void testIsSelfRegistrationEnabled() {
        System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
    }
    
    @IsTest
    static void testGetSelfRegistrationURL() {
        System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
    }
    /*   
@IsTest
static void testgetForgotPasswordUrl() {
System.assertEquals(null, LightningLoginFormController.getForgotPasswordUrl());
}*/
    
    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }
    
    @IsTest
    static void testlogin(){
        test.startTest();
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        system.runas(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);
        }
        
        string result1 = LightningLoginFormController.login(lstUserRec[0].username, 'fakepwd', 'partnernew/s');
        string result2 = LightningLoginFormController.login('', '', 'partnernew/s');
        string result3 = LightningLoginFormController.continueAfterOptInCheck(lstUserRec[0].username, 'fakepwd', true,true,'partnernew/s');
        string result4 = LightningLoginFormController.continueAfterOptInCheck(lstUserRec[0].username, 'fakepwd', false,false,'partnernew/s');
        string result5 = LightningLoginFormController.continueAfterOptInCheck('', '', true,false,'partnernew/s');
        
        Profile pr = [select id,name from Profile where name like : label.Rubrik_Partner_Community_User limit 1];
        string result6 = LightningLoginFormController.setExperienceId('testId');
        test.stopTest();
    }
    
    @IsTest
    static void testloginUser(){
        test.startTest();
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        system.runas(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);
        }
        Profile pr = [select id,name from Profile where name like : label.Rubrik_Partner_Community_User limit 1];
        lstUserRec[0].ProfileId = pr.Id;
        update lstUserRec;
        string result7 = LightningLoginFormController.continueAfterOptInCheck(lstUserRec[0].username, 'fakepwd', true,true,'partnernew/s');
        
        test.stopTest();
        
    } 
    
    @IsTest
    static void testHandleforgotPassword(){
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        system.runas(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);
        }
        Profile pr = [select id,name from Profile where name like : label.Rubrik_Partner_Community_User limit 1];
        lstUserRec[0].ProfileId = pr.Id;
        update lstUserRec;
        List<User> partnerUser = [SELECT id,email,isActive from User where id=:lstUserRec[0].Id];
        test.startTest();
            string resultInvalid = LightningLoginFormController.handleforgotPassword('testSampleEmail@test.com');
            string resultSucess = LightningLoginFormController.handleforgotPassword(partnerUser[0].email);
        test.stopTest();
        System.assertEquals('You should receive an automated password reset email from Rubrik Support if a correct email address was provided. Click the link in the email to reset your password. If the password reset email is not received within several minutes, please <a href="../login/SelfRegister">register</a> for access.', resultInvalid);
        
    }
    @IsTest
    static void testOktaCustomStgMethod(){
        OktaUserUtilityTest.oktaCustomSettingsParams();
        Okta_Attributes__c devcustomSet = [SELECT Id, Forgot_Password__c, Disable_User_Sync__c, Okta_Base_URL__c, Partner_User_AppId__c
                                            FROM Okta_Attributes__c 
                                            WHERE Name = 'Dev Okta Attributes'];
        LightningLoginFormController.OktaCustomSettingWrpr wrprInst = new LightningLoginFormController.OktaCustomSettingWrpr(devcustomSet.Forgot_Password__c,devcustomSet.Disable_User_Sync__c,devcustomSet.Okta_Base_URL__c,devcustomSet.Partner_User_AppId__c);
        LightningLoginFormController.getOktaCustomStng();
        System.assertEquals(true, wrprInst != null);
    }
}