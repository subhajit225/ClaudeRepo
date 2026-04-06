@IsTest
public class CS_RiskProfileControllerTest {
    @testsetup static void setup(){
        /*Risk_Profile_Assignment__c customSetting = new Risk_Profile_Assignment__c(
            Last_Assigned_Index__c = 0
        );
        
        insert customSetting;*/
        
        Group riskGovernanceGroup = [ SELECT Id FROM Group WHERE DeveloperName = 'Risk_Governance_Team' LIMIT 1];
        
        // Add the current user as a member of the group
        GroupMember groupMember = new GroupMember(
            GroupId = riskGovernanceGroup.Id,
            UserOrGroupId = UserInfo.getUserId()
        );
        
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@testriskprofile.com',
            Username = System.now().millisecond() + 'testuser@testriskprofile.com',
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
    private static List<Map<String, Object>> createRiskProfileInput(Id AccountId,String Operation){
        String jsonString = '[{"Account__c":"'+AccountId+'","Risk_Type__c":"Account Risk","Primary_Risk_Reason__c":"Adoption","Secondary_Risk_Reason__c":"Activation","Risk_Reason_Additional_Comments__c":null,"Risk_Level__c":null,"Comments__c":null,"Risk_Status__c":null,"Risk_Priority__c":null,"ACV_At_Risk__c":null,"Action_Owner__c":null,"Risk_Category__c":null,"Entitlement__c":null,"objectApiName":"Risk_Profile__c","Operation":"'+Operation+'"}]';
        
        Object deserialized = JSON.deserializeUntyped(jsonString);
        
        List<Object> rawList = (List<Object>) deserialized;
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Object element : rawList) {
            result.add((Map<String, Object>) element);
        }
        return result;
        
    }
    // Helper Method: Create Account
    private static Account createTestAccount(String name) {
        Account testAccount = new Account(Name = name);
        insert testAccount;
        return testAccount;
    }


    @IsTest
    static void testCreateRiskProfile() {
        Account testAccount = createTestAccount('Test Account');
        String Operation='Create';
        List<Map<String, Object>> testObjects = createRiskProfileInput(testAccount.Id,Operation);
        
        User u = [SELECT Id FROM USer WHERE Email='testuser@testriskprofile.com' LIMIT 1];
        
        System.runAs(u){
            
            Test.startTest();
            CS_RiskProfileController.Response response = CS_RiskProfileController.createRiskProfile(testObjects);
            System.assertNotEquals(null,response.data,'Response should not be null');
            Test.stopTest();
        }
    }
    
    @isTest
    static void testCreateRiskProfileDMLException() {
        System.runAs(new User(Id = UserInfo.getUserId())){
        Account testAccount = createTestAccount('Test Account');
        List<Map<String, Object>> testObjects = createRiskProfileInput(testAccount.Id, 'Create');
    
        // Add faulty Risk_Profile_Component__c to trigger DMLException
        Map<String, Object> invalidPdm = new Map<String, Object>{
            'objectApiName' => 'Risk_Profile_Component__c',
            'Risk_Profile__c' => testObjects[0].get('Id'), // just to satisfy relationship
            'Some_User_Lookup__c' => '001FakeIdForUser'     // wrong ID format for user lookup
        };
        testObjects.add(invalidPdm);
    
        Test.startTest();
        CS_RiskProfileController.Response response = CS_RiskProfileController.createRiskProfile(testObjects);
        Test.stopTest();
    
        System.assertNotEquals(null, response.error, 'Should catch DMLException');
        System.debug(LoggingLevel.DEBUG,'DMLException: ' + response.error);
        }
    }

    
    @IsTest
    static void testCreateRiskProfile2() {
        Account testAccount = createTestAccount('Test Account');
        String Operation='Create';
        List<Map<String, Object>> testObjects = createRiskProfileInput(testAccount.Id,Operation);
        testObjects[0].put('objectApiName','Risk_Profile_Component__c');
        
        User u = [SELECT Id FROM USer WHERE Email='testuser@testriskprofile.com' LIMIT 1];
        
        System.runAs(u){
            
            Test.startTest();
            CS_RiskProfileController.Response response = CS_RiskProfileController.createRiskProfile(testObjects);
            System.assertEquals(null,response.data,'Response should be null');
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testupdateRiskProfile() {
        Account testAccount = createTestAccount('Test Account');
        String Operation='Update';
        List<Map<String, Object>> testObjects = createRiskProfileInput(testAccount.Id,Operation);
        testObjects[0].put('objectApiName','Risk_Profile_Component__c');
        User u = [SELECT Id FROM USer WHERE Email='testuser@testriskprofile.com' LIMIT 1];
        
        System.runAs(u){
            
            Test.startTest();
            CS_RiskProfileController.Response response = CS_RiskProfileController.createRiskProfile(testObjects);
            System.assertEquals(null,response.data,'Response should not be null');
            Test.stopTest();
            
        }
    }
    
    @isTest
    static void testUpdateRiskProfileGenericException() {
        System.runAs(new User(Id = UserInfo.getUserId())){
        List<Map<String, Object>> testObjects = new List<Map<String, Object>>();
    
        Map<String, Object> invalidInput = new Map<String, Object>{
            'objectApiName' => null 
        };
        testObjects.add(invalidInput);
    
        Test.startTest();
        CS_RiskProfileController.Response response = CS_RiskProfileController.updateRiskProfile(testObjects);
        Test.stopTest();
    
        System.assertNotEquals(null, response.error, 'Generic exception should be caught.');
        }
    }


    
    @IsTest
    static void testDeleteRiskProfile() {
        Account testAccount = createTestAccount('Test Account');
        String Operation='Delete';
        List<Map<String, Object>> testObjects = createRiskProfileInput(testAccount.Id,Operation);
        
        User u = [SELECT Id FROM USer WHERE Email='testuser@testriskprofile.com' LIMIT 1];
        
        System.runAs(u){
            Test.startTest();
            CS_RiskProfileController.Response response = CS_RiskProfileController.createRiskProfile(testObjects);
            System.assertNotEquals(null,response,'Response should not be null'); 
            Test.stopTest();
        }
       
    }

    @IsTest
    static void testParseValue() {
        User u = [SELECT Id FROM USer WHERE Email='testuser@testriskprofile.com' LIMIT 1];
        Test.startTest();
        System.runAs(u){
            // Integer conversion
            System.assertEquals(123, CS_RiskProfileController.parseValue('123', Schema.DisplayType.Integer));
            
            // Double conversion
            System.assertEquals(123.45, CS_RiskProfileController.parseValue('123.45', Schema.DisplayType.Double));
            
            // Boolean conversion
            System.assertEquals(true, CS_RiskProfileController.parseValue('true', Schema.DisplayType.Boolean));
            System.assertEquals(false, CS_RiskProfileController.parseValue('false', Schema.DisplayType.Boolean));
            
            // Date conversion
            System.assertEquals(Date.newInstance(2024, 11, 6), CS_RiskProfileController.parseValue('2024-11-06', Schema.DisplayType.Date));
            
            // DateTime conversion
            String isoDateTime = '2024-11-06T12:34:56.000Z';
            // Convert ISO format to normal format
            String normalDateTime = isoDateTime.replace('T', ' ').replace('Z', '');
            // Parse the converted DateTime
            DateTime expectedDateTime = DateTime.valueOf(normalDateTime);
            // Assert parsed DateTime
            System.assertEquals(expectedDateTime, CS_RiskProfileController.parseValue(normalDateTime, Schema.DisplayType.DateTime));
            
            
            // Currency and Percent
            System.assertEquals(1234.56, CS_RiskProfileController.parseValue('1234.56', Schema.DisplayType.Currency));
            System.assertEquals(45.67, CS_RiskProfileController.parseValue('45.67', Schema.DisplayType.Percent));
            
            
            // String types
            List<Schema.DisplayType> stringTypes = new List<Schema.DisplayType>{
                Schema.DisplayType.REFERENCE, Schema.DisplayType.String, Schema.DisplayType.TextArea,
                    Schema.DisplayType.Url, Schema.DisplayType.Phone, Schema.DisplayType.Id,
                    Schema.DisplayType.Email, Schema.DisplayType.Picklist, Schema.DisplayType.Location, Schema.DisplayType.MultiPicklist
                    };
                        for (Schema.DisplayType type : stringTypes) {
                            System.assertEquals('Test Value', CS_RiskProfileController.parseValue('Test Value', type));
                        }
            
            // Unsupported type
            System.assertEquals('UnknownType', CS_RiskProfileController.parseValue('UnknownType', Schema.DisplayType.AnyType));
        }
        Test.stopTest();
    }
    @isTest
    static void testGetProductPillarInformation() {
        List<Product2> productList = new List<Product2>();
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode = 'OPTY-SPLIT',Bundle_Features__c='test Bundle');
        productList.add(newProd);
        
        Product2 newProd2 = new Product2(Name = 'test product 2', family = 'test family', ProductCode = 'OPTY-SPLIT', Bundle_Features__c='test Bundle');
        productList.add(newProd2);
        
        insert productList;
        
        Test.startTest();
        
        List<Bundle_Components_Allocation__c> componentAllocationList = new List<Bundle_Components_Allocation__c>();
        Bundle_Components_Allocation__c bca1 = new Bundle_Components_Allocation__c();
        bca1.Product_Pillar_1_Component__c = 'test comp Pillar1';
        bca1.Product_Pillar_2_Component__c = 'test comp Pillar2';
        bca1.Product_Name__c = productList[0].Id;
        componentAllocationList.add(bca1);
        
        Bundle_Components_Allocation__c bca2 = new Bundle_Components_Allocation__c();
        bca2.Product_Pillar_1_Component__c = 'test comp2 Pillar1';
        bca2.Product_Pillar_2_Component__c = 'test comp2 Pillar2';
        bca2.Product_Name__c = productList[1].Id;
        componentAllocationList.add(bca2);
        
        insert componentAllocationList; 
        
        User u = [SELECT Id FROM USer WHERE Email='testuser@testriskprofile.com' LIMIT 1];
        
        System.runAs(u){
            List<Bundle_Components_Allocation__c> queriedProductFeatures = [
                SELECT Id, Product_Pillar_1_Component__c, Product_Pillar_2_Component__c, Product_Name__c,Product_Name__r.Product_Pillar_1_Component__c,
                Product_Name__r.Product_Pillar_2_Component__c,Product_Name__r.Bundle_Features__c
                FROM Bundle_Components_Allocation__c LIMIT 2];
            
            List<String> productFeatureIds = new List<String>();
            for (Bundle_Components_Allocation__c pf : queriedProductFeatures) {
                productFeatureIds.add(pf.Id);
            }
            
            
            CS_RiskProfileController.PillarInfoWrapper result = CS_RiskProfileController.getProductPillarInformation(new List<String>(),productFeatureIds);
            
            System.assertEquals(2,result.pillarInfoList.size(),'Pillar count should be 2');
            
        }
        Test.stopTest();
    }
    @isTest
    static void testUpdateRiskProfileMethod() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@testriskprofile2.com',
            Username = System.now().millisecond() + 'testuser@testriskprofile2.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            Test.startTest();
            // Prepare test data
            Risk_Profile__c riskProfile = new Risk_Profile__c(Risk_Type__c='Account Risk');
            insert riskProfile;
            
            // Create a valid update payload
            List<Map<String, Object>> updatePayload = new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Id' => riskProfile.Id,
                        'Comments__c' => 'Test Updated',
                        'objectApiName' => 'Risk_Profile__c',
                        'Operation' => 'Update'
                        }
            };
                
            CS_RiskProfileController.Response response = CS_RiskProfileController.updateRiskProfile(updatePayload);
            System.assertNotEquals(null,response.data,'Response should not be null');
            Test.stopTest();
        }
    }


}