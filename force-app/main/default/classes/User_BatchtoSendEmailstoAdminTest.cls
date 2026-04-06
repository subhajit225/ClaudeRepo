@isTest(seeAllDAta=true)
public class User_BatchtoSendEmailstoAdminTest 
{
    static testMethod void testMethodforBatch() 
    {
        Test.startTest();
            User_BatchtoSendEmailstoAdmin obj = new User_BatchtoSendEmailstoAdmin();
            DataBase.executeBatch(obj); 
            User_BatchtoSendEmailstoAdmin_Schedular   sch1 = new User_BatchtoSendEmailstoAdmin_Schedular();
            String sch = '0  00 1 3 * ?';
            system.schedule('Test', sch, sch1);
        Test.stopTest();
    }
}