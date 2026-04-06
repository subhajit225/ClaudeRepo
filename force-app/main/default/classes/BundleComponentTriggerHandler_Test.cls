/**
 * @description Test class for the BundleComponentTriggerHandler.
 * Contains unit tests to validate trigger handler logic and ensure coverage.
 *
 * @author Shailesh Kumar
 * @lastmodifieddate   03 June 2025
 * @lastModifiedBy Shailesh Kumar
 */
@IsTest
public class BundleComponentTriggerHandler_Test {
    /**
     * @description This method creates test data.
     * 
     */
    @testSetup 
    public static void setupMethod() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;

        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Access_to_RRM_and_CX_Objects'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        
    }
    /**
     * @description Unit test for the BundleComponent trigger handler.Verifies expected behavior during before insert operation.
     */
    static testmethod void testBundleComponent(){
        ShGl_DisableBusinessLogic__c objCustomSetting = new ShGl_DisableBusinessLogic__c();
        objCustomSetting.Disable_Opportunity_Triggers__c = true;
        objCustomSetting.Disable_Product2_Trigger__c = true;
        insert objCustomSetting;
        SBQQ.TriggerControl.Disable();
        
        User u = [SELECT Id FROM User WHERE Email ='testuser@test.com'];
        
        List<Product2> prodList = new List<Product2>();
        Product2 prod = new Product2();
        prod.Name = 'RBK-R6412SE-HW-01';
        prod.Description = 'testtest';
        prod.ProductCode = 'RBK-R6412SE-HW-01';
        prod.Product_Type__c = 'Hardware';
        prod.License_Type__c = 'Perpetual';
        prod.Family = 'R6000';
        prod.Product_NIC_Type__c = 'SFP+';
        prod.Support_Type__c = '';
        prod.Support_Tier__c = 'SE1';
        prod.Usable_Capacity__c = 90.0;
        prod.Capacity__c = '144TB';
        prod.RWD_Version__c = '';
        prod.Category__c = 'Support';
        prod.Product_Level__c = '';
        prod.IsActive = True; 
        prodList.add(prod);
        
        insert prodList;
        Test.startTest();
        Bundle_Components_Allocation__c compObj = new Bundle_Components_Allocation__c();
        System.runAs(u){
            compObj.Product_SKU__c = prodList[0].ProductCode;
            insert compObj;
        }
        System.assertNotEquals(null,compObj.Id,'Component Record should have an Id');
        Test.stopTest();
    }
}