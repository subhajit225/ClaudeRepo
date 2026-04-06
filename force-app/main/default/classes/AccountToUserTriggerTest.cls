/********************************************************************************************************
* Name              : AccountToUserTriggerTest 
* Purpose           : AccountToUserTriggerTest is Used for Testing AccountToUserTrigger and AccountToUserTriggerHandler Class
*********************************************************************************************************/
@isTest
public class AccountToUserTriggerTest{
    @isTest
    static void npmAccountUsersTest(){
        List<User> userList = new List<User>();
        Id profileId1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
        Id profileId2 = [Select Id From Profile Where Name = 'Sales Operations'].Id;
        List<User> userList1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{profileId1}, 1);
        List<User> userList2 = TestDataFactory.getUsers('testClassUser2', new Set<Id>{profileId2}, 3);
        userList.addAll(userList1);
        userList.addAll(userList2);
        insert userList;
        Map<String, Schema.RecordTypeInfo> AcctRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test CP Account 1', RecordTypeId = AcctRecTypeInfo.get('Customer/Prospect').getRecordTypeId()),
            new Account(Name = 'Test PD Account 1', Type = 'Distributor', RecordTypeId = AcctRecTypeInfo.get('Partner/Distributor').getRecordTypeId()),
            new Account(Name = 'Test PD Account 2', Type = 'Distributor', RecordTypeId = AcctRecTypeInfo.get('Partner/Distributor').getRecordTypeId()),
            new Account(Name = 'Test PD Account 3', Type = 'Distributor', RecordTypeId = AcctRecTypeInfo.get('Partner/Distributor').getRecordTypeId())
        };
        insert accounts;

        List<Account_To_Users__c> listATU = new List<Account_To_Users__c>();
        listATU.add(new Account_To_Users__c(Account__c = accounts[1].Id, User__c = userList2[0].Id, Relationship_Type__c ='National Partner Manager'));
        listATU.add(new Account_To_Users__c(Account__c = accounts[2].Id, User__c = userList2[1].Id, Relationship_Type__c ='National Partner Manager'));
        listATU.add(new Account_To_Users__c(Account__c = accounts[3].Id, User__c = userList2[2].Id, Relationship_Type__c ='National Partner Manager'));
        insert listATU;

        List<Account_To_Users__c> atuSyncList = [select Id from Account_To_Users__c where Sync_NationalPartnerManager__c = TRUE];
        system.assertEquals(atuSyncList.size(),3,'not matching');
        listATU[0].Sync_NationalPartnerManager__c = false;
        listATU[1].Sync_NationalPartnerManager__c = false;
        listATU[2].Sync_NationalPartnerManager__c = false;
        
        Test.startTest();
        update listATU;
        atuSyncList = [select Id from Account_To_Users__c where Sync_NationalPartnerManager__c = TRUE];
        system.assertEquals(atuSyncList.size(),0,'not matching');
        listATU[0].Disable_Account_User_Relationship__c = true;
        listATU[1].User__c = userList2[2].Id;
        listATU[2].Disable_Account_User_Relationship__c = true;
        update listATU;
        atuSyncList = [select Id, User__c, Old_User__c from Account_To_Users__c where Sync_NationalPartnerManager__c = TRUE];
        system.assertEquals(atuSyncList.size(),3,'not matching');
        system.assertEquals(atuSyncList[1].User__c,userList2[2].Id,'not matching');
        system.assertEquals(atuSyncList[1].Old_User__c,userList2[1].Id,'not matching');
        
        System.runAs(userList[1]){
            List<Database.DeleteResult> drList = Database.delete(listATU, false);
            LogError.deleteDMLErrorLog((List<SObject>)listATU, drList, 'AccountToUserTriggerTest','Delete ATU failed');
        }
        Test.stopTest();
        List<Custom_Error_Log__c> errLogs = [select Id from Custom_Error_Log__c where Class__c = 'AccountToUserTriggerTest'];
        system.assertEquals(errLogs.size(),1,'not matching');
        
    }
}