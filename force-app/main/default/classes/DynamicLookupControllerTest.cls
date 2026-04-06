/**
* @Author      : Vijay Kumar K R
* @CreatedDate : Aug 1, 2022 
* @Class       : DynamicLookupController
*/
@isTest
public with sharing class DynamicLookupControllerTest {
    
    @TestSetup
    static void testSetup(){
        
        //test.starttest();
        User u; 
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
        
        u = new User(
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
            Employee_Time_Off__c = true
        );
        insert u;
        System.runAs(u){
            // Create custom setting
            E2CAdv__E2CAConfiguration__c setting = new E2CAdv__E2CAConfiguration__c();
            setting.name='E2C Advance Configuration';
            setting.E2CAdv__EnableTrigger__c = true;
            setting.E2CAdv__Enable_Watchers__c = false;
            setting.E2CAdv__Update_Case_watcher_on_account_Update__c = false;
            insert setting;
            // Insert the AccountTrigger setting record (List Custom Setting)
            insert new E2CAdv__E2CATriggers__c(
                Name = 'AccountTrigger',
                E2CAdv__IsActive__c = true
            );
            Account objAcc = new Account(Name = 'testAcc');
            INSERT objAcc;
            INSERT new Contact(AccountId = objAcc.Id, LastName = 'testCont', Email = 'test@gmail.com');
            String fields = 'Id, Name';
            DynamicLookupController.fetchLookupData(fields, '', 'Contact', '', '');
            DynamicLookupController.fetchLookupData(fields, 'test', 'Contact', '', '');
            DynamicLookupController.fetchLookupData(fields, 'test', 'Contact', '', 'LastName');
            DynamicLookupController.fetchLookupData(fields, '', 'Contact', 'AccountId = \''+objAcc.Id+'\'', '');
            DynamicLookupController.fetchLookupData(fields, '', 'Contact', 'AccountId = \''+objAcc.Id+'\'', 'LastName');
            //test.stoptest();
        }
        
        
    }
    
    @isTest
    public static void testLookupRecordById(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Contact objCont = [SELECT Id FROM Contact WHERE LastName = 'testCont' LIMIT 1]; 
            sObject obj = DynamicLookupController.fetchRecordById(objCont.Id, 'Contact');
            System.assertNotEquals(obj, null);
        }
    }
    
    @isTest
    public static void testLookupRecordByIdException(){ 
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            try {
                sObject obj = DynamicLookupController.fetchRecordById(UserInfo.getUserId(), 'Contact');
            } catch (Exception e) {
                System.assertNotEquals(e.getMessage(), null);   
            }
        }
    }
    /**
     * @description Verifies that fetchFilteredRecords returns non-null results
     * for a standard user when called with no add-on fields, a single add-on
     * field, and multiple add-on fields.
     */
    @isTest
    public static void testFetchFilteredRecords_StandardUser() {
        User standardUser = [SELECT Id FROM User WHERE Email = 'csit-testuser@rubrik.com' LIMIT 1];
        
        System.runAs(standardUser) {
            Test.startTest();
            List<sObject> noAddon = DynamicLookupController.fetchFilteredRecords('Id, Name', 'test', 'Account', 'Name != null', '');
            System.assertNotEquals(null, noAddon);
            
            List<sObject> singleAddon = DynamicLookupController.fetchFilteredRecords('Id, Name', 'test', 'Contact', 'LastName != null', 'Email');
            System.assertNotEquals(null, singleAddon);
            
            List<sObject> multiAddon = DynamicLookupController.fetchFilteredRecords('Id, Name', 'test', 'Contact', 'LastName != null', 'Email;Phone');
            System.assertNotEquals(null, multiAddon);
            Test.stopTest();
        }
    }
}