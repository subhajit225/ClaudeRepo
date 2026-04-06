/**
* @Author      : Sai Kishore
*/
@IsTest
public class PSTimeCardTriggerHandler_test {
    
    @TestSetup
    public static void setupData(){
        List<Account> accLst = CustomTestDataFactory.testAccounts(1);
        List<Contact> conLst = CustomTestDataFactory.createcont(accLst);
        List<PS_Project__c> projectLst = CustomTestDataFactory.createPS_Project(conLst,accLst);        
        CustomTestDataFactory.CreatTimecard(projectLst);
    }
    
    @IsTest
    public static void testBefore(){
        PS_Time_Card__c timeCard = [SELECT Id FROM PS_Time_Card__c limit 1];
        timeCard.status__c = 'Approved';
        try {
            UPDATE timeCard;
            Assert.Fail();
        }
        catch(DMLException ex)
        {
            Assert.isTrue(ex.getMessage().contains('Operation not permitted. Please contact your manager for assistance.'));
        }
    }
}