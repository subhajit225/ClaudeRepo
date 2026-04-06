@isTest(seeAllDAta=False)
public class UserTenureBatchTest 
{
    static testMethod void testMethodforBatch2() 
    {
        Test.startTest();
            //USer user1 = new USer(LastName='TestLastNAme', ,isActive=true,email='test@test.com',);
            UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
            insert r;

            User u = new User(
                 ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                 LastName = 'last',
                 Email = 'puser000@amamama.com',
                 Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                 CompanyName = 'TEST',
                 Title = 'title',
                 Alias = 'alias',
                 TimeZoneSidKey = 'America/Los_Angeles',
                 EmailEncodingKey = 'UTF-8',
                 LanguageLocaleKey = 'en_US',
                 LocaleSidKey = 'en_US',
                 UserRoleId = r.Id,
                 Start_Date__c=System.Today().adddays(-30)
            );
            insert u;
            User_tenure_Batch_simplified obj = new User_tenure_Batch_simplified();
            DataBase.executeBatch(obj,20); 
            
        Test.stopTest();
        
        
        UserTenureBatchSchedular sch1 = new UserTenureBatchSchedular();
            String sch = '0  00 2 4 * ?';
            system.schedule('Test', sch, sch1);
    }

}