@IsTest
public class POSReportTest {
    @IsTest
    static void populatePOSReportFieldsTest(){
        ShGl_DisableBusinessLogic__c businessLogic = new ShGl_DisableBusinessLogic__c(Name='test2', Disable_Account_Triggers__c= true , SetupOwnerId=UserInfo.getUserId());
        insert businessLogic;
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acct.ETM_Theatre__c ='TEST_Theatre';
        acct.ETM_Area__c ='TEST_Area';
        acct.ETM_Region__c ='TEST_Region';
        acct.ETM_Territory__c ='TEST_Territory';        
        Test.StartTest();
        insert acct;
        List<POS_Report__c> posList = new List<POS_Report__c>();
        POS_Report__c pos1 = new POS_Report__c(Name = 'Test 001', DR_Partner_of_Record_ID__c =acct.Id, Account__c=acct.Id);
        POS_Report__c pos2 = new POS_Report__c(Name = 'Test 002');
        posList.add(pos1);
        posList.add(pos2);
        insert posList;
        POS_Report__c posInsCheck1 = [Select Id,AE_Area__c,Area__c from POS_Report__c Where ID=:pos1.Id limit 1];
        POS_Report__c posInsCheck2 = [Select Id,AE_Area__c,Area__c from POS_Report__c Where ID=:pos2.Id limit 1];
        System.assertEquals('TEST_Area', posInsCheck1.Area__c);
        System.assertEquals(null, posInsCheck2.AE_Area__c);
        posList[0].DR_Partner_of_Record_ID__c = null;
        posList[0].Account__c = null;
        posList[1].DR_Partner_of_Record_ID__c = acct.Id;
        posList[1].Account__c = acct.Id;
        update posList;
        Test.StopTest();
        POS_Report__c posForCheck1 = [Select Id,AE_Area__c,Area__c from POS_Report__c Where ID=:pos1.Id limit 1];
        POS_Report__c posForCheck2 = [Select Id,AE_Area__c,Area__c from POS_Report__c Where ID=:pos2.Id limit 1];
        System.assertEquals(null, posForCheck1.AE_Area__c);
        System.assertEquals('TEST_Area', posForCheck2.Area__c);
        delete posList[1];
    }
}