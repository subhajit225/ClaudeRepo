/**
 * @description TackleCoSellCloseBatchTest is Used for Testing TackleCoSellCloseBatch Class
*/
@isTest
public class TackleCoSellCloseBatchTest {
    @isTest
    static void closeCoSellBatchTest(){
        ShGl_DisableBusinessLogic__c custSetDis = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        custSetDis.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        custSetDis.Disable_SBQQ_Quote_Triggers__c = true;
        custSetDis.Disable_Opportunity_Validation_Rules__c  = true;
        insert custSetDis;

        List<User> usersList = new List<User>();
        Id profile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
        List<User> usersList1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{profile1}, 1);
        usersList.addAll(usersList1);
        insert usersList;

        Map<String, Schema.RecordTypeInfo> accRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
        List<Account> accountsList = new List<Account>{
            new Account(Name = 'Test CP Test Account 1', RecordTypeId = accRecTypeInfo.get('Customer/Prospect').getRecordTypeId())
        };
        insert accountsList;

        List<Opportunity> opptyList = new List<Opportunity>();
        Opportunity oppty1 = TestDataFactory.getOpportunity(accountsList[0]);
        oppty1.StageName = '1 Discovery';
        oppty1.CloseDate = System.today() + 12;
        oppty1.Opportunity_Sub_Type__c = 'Regular';
        opptyList.add(oppty1);
        insert opptyList;

        //insert tackle co-sell record
        List<tackle__Tackle_Co_Sell__c> tcsList = new List<tackle__Tackle_Co_Sell__c>();
        tackle__Tackle_Co_Sell__c tcs1 = new tackle__Tackle_Co_Sell__c();
        tcs1.Name = 'TEST Co-Sell 1';
        tcs1.tackle__Opportunity__c = opptyList[0].Id;
        tcs1.tackle__Cloud_Partner__c = 'aws';
        tcs1.tackle__DeliveryModel__c = 'SaaS or PaaS';
        tcs1.tackle__Industry__c = 'Other';
        tcs1.tackle__Opportunity_Owner_Email__c = 'test@awstest.test';
        tcs1.tackle__Partner_Need_Type__c = 'Deal Support';
        tcs1.tackle__Stage__c = 'Draft';
        tcs1.tackle__Target_Close_Date__c = system.today()+30;
		tcs1.tackle__Customer_Company_Name__c = 'Example Test Company';
		tcs1.tackle__Expected_Monthly_Revenue__c = 1000;
		tcs1.tackle__ProjectDescription__c = 'test test test 123456789123456789123456789123456789123456789123456789';
        tcsList.add(tcs1);
        insert tcsList;

        Test.startTest();
        
        opptyList[0].StageName = '7 Closed Won';
        opptyList[0].Lost_To_Won_Against__c ='Actifio';
        update opptyList[0];

        TackleCoSellCloseBatch tcsBatch = new TackleCoSellCloseBatch(null);
        DateTime testDate = Datetime.now().addminutes(1);
        String hour = String.valueOf(testDate.hour()); 
        String minute = String.valueOf(testDate.minute());
        String second = String.valueOf(testDate.second());  
        String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(Datetime.now().day()) + ' ' + String.valueOf(Datetime.now().month()) + ' ?' + ' ' + String.valueOf(Datetime.now().year());
        System.schedule('TackleCoSellCloseBatch - 1hr Test' + String.valueOf(Datetime.now()), nextFireTime, tcsBatch);
        Database.executeBatch(new TackleCoSellCloseBatch(null),50);
        Test.stopTest();

        tackle__Tackle_Co_Sell__c tcsRes = [SELECT ID,tackle__Is_Closed__c,tackle__Stage__c,tackle__SF_Stage__c from tackle__Tackle_Co_Sell__c where Id = :tcsList[0].Id limit 1];
        system.assertEquals(TRUE, tcsRes.tackle__Is_Closed__c);
        system.assertEquals('Closed Won', tcsRes.tackle__Stage__c);
        system.assertEquals('Closed', tcsRes.tackle__SF_Stage__c);
    }
}