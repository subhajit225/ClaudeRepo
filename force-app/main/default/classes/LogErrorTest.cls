@isTest()
public class LogErrorTest {
    /**
     * @description test class to cover the Account History batch
     */
    public static testMethod void createErrorLog() {  
        String uniqueUserName = 'LogErrorTest' + DateTime.now().getTime() + '@testclass.com';           
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{p.Id}, 2);
        insert listUser;
        System.runAs(listUser[0]) {
            string className ='testClass';
            string recIds ='23423';
            string message ='errortest';
            string Functionality='Bookings'; 
            Exception e ;
            Test.startTest();
            Custom_Error_Log__c err = LogError.CreateDMLErrorLog(className,recIds,message,Functionality);
            Custom_Error_Log__c err1 =LogError.CreateGenericErrorLog(className,e,Functionality);
            LogError.logCustomError('className', 'errorMsg', 'errorDetail', 'functionality');
            Test.stopTest();
        system.assertEquals('testClass', err.Class__c);
        }
    }
/**
     * @description test class to cover the Account History batch
     */    
    public static testMethod void testDMLErrorLog() { 
        List<Custom_Error_Log__c> errorLogs = new List<Custom_Error_Log__c> ();
        String uniqueUserName = 'LogErrorTest' + DateTime.now().getTime() + '@testclass.com';           
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{p.Id}, 2);
        insert listUser;
        Id customerRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','BillingpostalCode'=>'809','BillingStreet'=>'sdf','RecordTypeId'=>customerRecId};
        List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,accMap);
        insert newActList;
        System.runAs(listUser[0]) {
            Test.startTest();
            List<AccountShare> asList = new List<AccountShare>(); 
            List<AccountShare> upsrtList = new List<AccountShare>(); 
            asList.add(new AccountShare(AccountId = newActList[0].Id,
                                        UserOrGroupId = listUser[1].Id, 
                                        AccountAccessLevel = 'Edit', 
                                        OpportunityAccessLevel = 'ReadOnly'));
            asList.add(new AccountShare(AccountId = newActList[1].Id,
                                        UserOrGroupId = listUser[1].Id, 
                                        AccountAccessLevel = 'Edit', 
                                        OpportunityAccessLevel = 'ReadOnly'));
            upsrtList.add(new AccountShare(AccountId = newActList[2].Id,
                                        UserOrGroupId = listUser[1].Id, 
                                        AccountAccessLevel = 'Edit', 
                                        OpportunityAccessLevel = 'ReadOnly'));
            List<Database.SaveResult> srList = Database.insert(asList, false);
            LogError.CreateDMLErrorLog((List<SObject>)asList, srList, 'TestAccShare','Insert-Test');
            
            List<AccountShare> asDelList = new List<AccountShare>();
            asDelList = [select Id from AccountShare];
           /* string shareIdFirst = '00r6f0000F63ts1';
            string shareIdSecond = '00r6f0000F63ts2';
            string shareIdThird = '00r6f0000F63ts3';
            asDelList.add(new AccountShare(Id = shareIdFirst));
            asDelList.add(new AccountShare(Id = shareIdSecond));
            asDelList.add(new AccountShare(Id = shareIdThird));*/
            
            List<Database.SaveResult> updateList = Database.update(asList, false);
            errorLogs= LogError.createDMLErrorLogWithRetrunType((List<SObject>)asList, updateList, 'TestAccShare','Update-Test');
            List<Database.UpsertResult> upsertList = Database.upsert(upsrtList, false);
            errorLogs = LogError.createUpsertDMLErrorLogWithRetrunType((List<SObject>)upsrtList, upsertList, 'TestAccShare','Upsert-Test');
            List<Database.DeleteResult> drList = Database.delete(asDelList, false);
            LogError.DeleteDMLErrorLog((List<SObject>)asDelList, drList, 'TestAccShare','Delete-Test');
            Test.stopTest();
            system.assertEquals(2, updateList.size());
        }
    }
}