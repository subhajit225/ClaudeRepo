@isTest(seeAllDAta=true)
public class Account_ClusterCapacityBatchTest 
{
    static testMethod void testMethodforBatch() 
    {
        Test.startTest();
            Account_ClusterCapacityBatch obj = new Account_ClusterCapacityBatch();
            DataBase.executeBatch(obj); 
            ClusterBatchSchedular sch1 = new ClusterBatchSchedular();
            String sch = '0  00 1 3 * ?';
            system.schedule('Test', sch, sch1);
        Test.stopTest();
    }
}