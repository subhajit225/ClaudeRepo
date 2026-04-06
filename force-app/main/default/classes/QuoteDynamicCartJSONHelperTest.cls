/***********************************************************************************************************
 * Class Name           : QuoteDynamicCartJSONHelperTest
 * Date Created/Modified: 18/12/2025
 * Author               : Rahul Kappa
 * @description         : This test class is to cover test methods related to QuoteDynamicCartJSONHelper
 /**********************************************************************************************************/
@IsTest
private class QuoteDynamicCartJSONHelperTest {
/***********************************************************************************************************
 * Method Name           : setupData
 * Date Created/Modified: 18/12/2025
 * Author               : Rahul Kappa
 * @description         : test setup
 /**********************************************************************************************************/
    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
        String userName = 'admin';
		User u = new User(Alias = 'std'+userName, Email=userName+'testuserdetails@testorg1123.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='admintestuser@gmail.com'+userName);
        insert u;
		System.runAs(u){
                List<SBQQ__LookupData__c> lookupDataList = new List<SBQQ__LookupData__c>();
        
                lookupDataList.add(new SBQQ__LookupData__c(
                    
                    Category_Sub_Category_Link__c = 'software-rsv',
                    Dynamic_Cart_JSON__c = '{"Field1":{"VU":"T","expAllow":"T"}}',
                    Start_Date__c = system.today(),
                    End_Date__c = system.today()+10
                ));
        
                lookupDataList.add(new SBQQ__LookupData__c(
                    
                    Category_Sub_Category_Link__c = 'hardware-ond',
                    Dynamic_Cart_JSON__c = '{"Field2":{"VU":"F"}}',
                    Start_Date__c = system.today(),
                    End_Date__c = system.today()+10
                ));
        
                insert lookupDataList;
        }
    }
    
/***********************************************************************************************************
 * Method Name           : testQuoteDynamicCartJSONHelper_Positive
 * Date Created/Modified: 18/12/2025
 * Author               : Rahul Kappa
 * @description         : testQuoteDynamicCartJSONHelper_Positive
 /**********************************************************************************************************/
   testmethod static void testDynamicPositive() {
        User ur = [SELECT Id, Name, Email FROM User WHERE Email = 'admintestuserdetails@testorg1123.com' LIMIT 1];
        System.runAs(ur){ 
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.httpMethod = 'POST';
            req.requestURI = '/services/apexrest/QuoteDynamicCartJSONHelper';
            RestContext.request = req;
            RestContext.response = res;
    
            List<String> categoryKeys = new List<String>{
                'software-rsv',
                'hardware-ond'
            };
    
            Test.startTest();
            Map<String, String> result =
                QuoteDynamicCartJSONHelper.quoteDynamicCartJSONHelperPost(categoryKeys);
            Test.stopTest();
    
            System.assertNotEquals(null, result, 'Result map should not be null');
            System.assertEquals(2, result.size(), 'two matching entries');
    
            System.assert(result.containsKey('software-rsv'));
            System.assert(result.containsKey('hardware-ond'));
    
            System.assertEquals(
                '{"Field1":{"VU":"T","expAllow":"T"}}',
                result.get('software-rsv')
            );
        }
    }
/***********************************************************************************************************
 * Method Name           : testQuoteDynamicCartJSONHelper_NoMatch
 * Date Created/Modified: 18/12/2025
 * Author               : Rahul Kappa
 * @description         : testQuoteDynamicCartJSONHelper_NoMatch
 /**********************************************************************************************************/
    testmethod static void testDynamicNoMatch() {
        User ur = [SELECT Id, Name, Email FROM User WHERE Email = 'admintestuserdetails@testorg1123.com' LIMIT 1];
        System.runAs(ur){ 
            List<String> categoryKeys = new List<String>{ 'non-existing-key' };
            Test.startTest();
            Map<String, String> result =
            QuoteDynamicCartJSONHelper.quoteDynamicCartJSONHelperPost(categoryKeys);
            Test.stopTest();
            System.assertNotEquals(null, result);
            System.assertEquals(0, result.size(), 'No records should match');
        }
    }
}