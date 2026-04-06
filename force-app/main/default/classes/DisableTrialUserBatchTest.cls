@istest
public class DisableTrialUserBatchTest {
    @testSetup static void setup() {
        testDataFactoryClass.createUser();
        testDataFactoryClass.createCustomSettings();
        testDataFactoryClass.createTrialProduct();
    }
    
    
    static testmethod void test() {
        List<Contact> conList = testDataFactoryClass.createContact(testDataFactoryClass.createAccount());
        Contact con = conList[0];
        con.Agreed_to_Edge_Trial_Agreement__c = true;
        con.trial_Edge_End_Date__c = System.today();
        update con;
        String jobId = System.schedule('testBasicScheduledApex',   DisableTrialUserScheduler.CRON_EXP,   new DisableTrialUserScheduler());
        Database.executeBatch(new DisableTrialUserBatch());
        Util.getUserDetail(Userinfo.getUserId());
        User u = Util.CurrentUser;
        Util utilClass = new Util();
        User partnerUser = utilClass.getPartnerUser();
    }
}