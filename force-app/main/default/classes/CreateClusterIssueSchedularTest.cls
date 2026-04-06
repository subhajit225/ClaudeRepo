/**
 * Author       :   Saakshi Gupta
 * CreatedDate  :   3rd July 2020
 * Description  :   Test class for CreateClusterIssueBatchSchedular
 */
@isTest(seeAllData = false)
public class CreateClusterIssueSchedularTest {
    public static testMethod void testCreateClusterIssueSchedularTest(){
        CreateClusterIssueBatchSchedular ws = new CreateClusterIssueBatchSchedular();
        String sch = '0 15 * * * ?';
        System.schedule('Test schedule', sch, ws);
    }
}