/********************************************************************************************************
* Name              : UpdateNPMAccessOpportunityBatchTest 
* Purpose           : UpdateNPMAccessOpportunityBatchTest is Used for Testing UpdateNPMAccessOpportunityBatch Class
*********************************************************************************************************/
@isTest
public class UpdateNPMAccessOpportunityBatchTest{
    @isTest
    static void npmAccountUsersBatchTest(){
        ShGl_DisableBusinessLogic__c custSetDis = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        custSetDis.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        custSetDis.Disable_SBQQ_Quote_Triggers__c = true;
        custSetDis.Disable_Opportunity_Validation_Rules__c  = true;
        insert custSetDis;

        List<User> UsersList = new List<User>();
        Id profile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
        Id profile2 = [Select Id From Profile Where Name = 'Sales Operations'].Id;
        List<User> UsersList1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{profile1}, 1);
        List<User> UsersList2 = TestDataFactory.getUsers('testClassUser2', new Set<Id>{profile2}, 4);
        UsersList.addAll(UsersList1);
        UsersList.addAll(UsersList2);
        insert UsersList;
        Map<String, Schema.RecordTypeInfo> AccRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
        List<Account> accountsList = new List<Account>{
            new Account(Name = 'Test CP Test Account 1', RecordTypeId = AccRecTypeInfo.get('Customer/Prospect').getRecordTypeId()),
            new Account(Name = 'Test PD Test Account 1', Type = 'Distributor', RecordTypeId = AccRecTypeInfo.get('Partner/Distributor').getRecordTypeId()),
            new Account(Name = 'Test PD Test Account 2', Type = 'Distributor', RecordTypeId = AccRecTypeInfo.get('Partner/Distributor').getRecordTypeId()),
            new Account(Name = 'Test PD Test Account 3', Type = 'Distributor', RecordTypeId = AccRecTypeInfo.get('Partner/Distributor').getRecordTypeId())
        };
        insert accountsList;

        List<Account_To_Users__c> acctousrList = new List<Account_To_Users__c>();
        acctousrList.add(new Account_To_Users__c(Account__c = accountsList[1].Id, User__c = UsersList2[0].Id, Relationship_Type__c ='National Partner Manager'));
        acctousrList.add(new Account_To_Users__c(Account__c = accountsList[2].Id, User__c = UsersList2[1].Id, Relationship_Type__c ='National Partner Manager'));
        acctousrList.add(new Account_To_Users__c(Account__c = accountsList[3].Id, User__c = UsersList2[2].Id, Relationship_Type__c ='National Partner Manager'));
        insert acctousrList;
        
        List<Opportunity> opptyList = new List<Opportunity>();
        Opportunity oppty1 = TestDataFactory.getOpportunity(accountsList[0]);
        oppty1.StageName = '1 Discovery';
        oppty1.CloseDate = System.today() +2;
        oppty1.Partner_Lookup__c = accountsList[1].Id;
        oppty1.Sourcing_Partner__c = accountsList[2].Id;
        oppty1.Teaming_Partner__c = accountsList[3].Id;
        opptyList.add(oppty1);
        Opportunity oppty2 = oppty1.clone();
        opptyList.add(oppty2);
        insert opptyList;
        
        List<Account_To_Users__c> acctousrSyncList = [select Id from Account_To_Users__c where Sync_NationalPartnerManager__c = TRUE];
        system.assertEquals(acctousrSyncList.size(),3,'not matching');
        List<OpportunityShare> insertOppShareList = new List<OpportunityShare>();
        insertOppShareList.add(new OpportunityShare(OpportunityId = oppty1.Id, UserOrGroupId = UsersList2[0].Id, OpportunityAccessLevel = 'Edit', RowCause = Schema.OpportunityShare.RowCause.Manual));
        insertOppShareList.add(new OpportunityShare(OpportunityId = oppty1.Id, UserOrGroupId = UsersList2[1].Id, OpportunityAccessLevel = 'Edit', RowCause = Schema.OpportunityShare.RowCause.Manual));
        insertOppShareList.add(new OpportunityShare(OpportunityId = oppty2.Id, UserOrGroupId = UsersList2[0].Id, OpportunityAccessLevel = 'Edit', RowCause = Schema.OpportunityShare.RowCause.Manual));
        insertOppShareList.add(new OpportunityShare(OpportunityId = oppty2.Id, UserOrGroupId = UsersList2[1].Id, OpportunityAccessLevel = 'Edit', RowCause = Schema.OpportunityShare.RowCause.Manual));
        insert insertOppShareList;
       
        Test.startTest();
        acctousrList[0].Disable_Account_User_Relationship__c = true;
        acctousrList[1].User__c = UsersList2[3].Id;
        update acctousrList;
        UpdateNPMAccessOpportunityBatch npmBatch = new UpdateNPMAccessOpportunityBatch(null);
        DateTime testDate = Datetime.now().addminutes(1);
        String hour = String.valueOf(testDate.hour()); 
        String minute = String.valueOf(testDate.minute());
        String second = String.valueOf(testDate.second());  
        String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(Datetime.now().day()) + ' ' + String.valueOf(Datetime.now().month()) + ' ?' + ' ' + String.valueOf(Datetime.now().year());
        System.schedule('NPM_AccountUser_OpptyShare_Batch_' + String.valueOf(Datetime.now()), nextFireTime, npmBatch);
        Database.executeBatch(new UpdateNPMAccessOpportunityBatch(null),50);
        Test.stopTest();

        acctousrSyncList = [select Id, User__c, Old_User__c from Account_To_Users__c where Sync_NationalPartnerManager__c = FALSE];
        system.assertEquals(acctousrSyncList.size(),3,'not matching');
        system.assertEquals(acctousrSyncList[1].Old_User__c,null,'not matching');

        List<OpportunityShare> opptyShare1 = [select ID, UserOrGroupId from OpportunityShare where OpportunityId = :oppty1.Id and Rowcause = 'Manual'];
        List<OpportunityShare> opptyShare2 = [select ID, UserOrGroupId from OpportunityShare where OpportunityId = :oppty2.Id and Rowcause = 'Manual'];
        system.assertEquals(opptyShare1.size()==2,true,'not matching');
        system.assertEquals(opptyShare2.size()==2,true,'not matching');
    }
}