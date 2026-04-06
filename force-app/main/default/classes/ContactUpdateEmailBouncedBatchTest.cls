/**
 * @description ContactUpdateEmailBouncedBatchTest is Used for Testing ContactUpdateEmailBouncedBatch Class
*/
@isTest
public class ContactUpdateEmailBouncedBatchTest {
    @isTest
    static void updateContactBounceFlagTest(){
        Map<String, Schema.RecordTypeInfo> accRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
        List<Account> accountsList = new List<Account>{
            new Account(Name = 'Test CP Test Account 1', RecordTypeId = accRecTypeInfo.get('Customer/Prospect').getRecordTypeId())
        };
        insert accountsList;

        List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 3, null);
        conList[0].AccountId=accountsList[0].Id;
        conList[1].AccountId=accountsList[0].Id;         
        conList[2].AccountId=accountsList[0].Id;         
        insert conList;
        conList[0].EmailBouncedReason = 'The recipient is invalid.';
        update conList[0];
        Test.startTest();
        
        ContactUpdateEmailBouncedBatch cbBatch = new ContactUpdateEmailBouncedBatch(null);
        DateTime testDate = Datetime.now().addminutes(1);
        String hour = String.valueOf(testDate.hour()); 
        String minute = String.valueOf(testDate.minute());
        String second = String.valueOf(testDate.second());  
        String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(Datetime.now().day()) + ' ' + String.valueOf(Datetime.now().month()) + ' ?' + ' ' + String.valueOf(Datetime.now().year());
        System.schedule('UpdateContactEmailBounceBatch - 1hr Test' + String.valueOf(Datetime.now()), nextFireTime, cbBatch);
        Database.executeBatch(new ContactUpdateEmailBouncedBatch(null),50);
        Test.stopTest();

        Contact conRes = [SELECT ID,IsEmailBounced FROM Contact WHERE Id = :conList[0].Id limit 1];
        system.assertEquals(FALSE, conRes.IsEmailBounced);
    }
}