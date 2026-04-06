@isTest
private class PC_PactsafeCalloutController_Test {
    @isTest static void testCalloutMSP() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new PC_PactsafeCalloutMockup_Test());
        List<Partner_Onboarding_Request__c> pc = ShGl_TestFactory.testMethod_PartnerOnBoarding(1);
        PC_PactsafeCalloutController.callpactsafe(pc[0].Id,'MSP','test@rubrik.com');
        
    }
    
    @isTest static void testCalloutPartnerMSP() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new PC_PactsafeCalloutMockup_Test());
        List<Partner_Onboarding_Request__c> pc = ShGl_TestFactory.testMethod_PartnerOnBoarding(1);
        PC_PactsafeCalloutController.callpactsafe(pc[0].Id,'MSP-Reseller','test@rubrik.com');
        
    }
    @isTest static void testCalloutPartnerMSPError() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new PC_PactsafeCalloutMockupError_Test());
        List<Partner_Onboarding_Request__c> pc = ShGl_TestFactory.testMethod_PartnerOnBoarding(1);
        PC_PactsafeCalloutController.callpactsafe(pc[0].Id,'MSP-Reseller','test@rubrik.com');
        
    }
   @isTest static void testCalloutMasterReseller() {
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acc = new Account(Name='test',recordtypeId=devRecordTypeId);
        insert acc;
        Contact con = new Contact(lastname='test1',email='test@rubrik.com',accountId=acc.Id);
        insert con;
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new PC_PactsafeCalloutMockup_Test());
        PC_PactsafeCalloutAgremmentController.callpactsafe(acc.Id,acc.Name,'Reseller','test@rubrik.com',con.Id);
        
    }
}