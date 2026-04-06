/**
 * Author       :   Saakshi Gupta
 * CreatedDate  :   3rd July 2020
 * Description  :   Test class for UpdateClusterIssueBatchSchedular
 */
@isTest(seeAllData = false)
public class UpdateClusterIssueSchedularTest {
    public static testMethod void testUpdateClusterIssueBatchSchedular(){
        UpdateClusterIssueBatchSchedular ws = new UpdateClusterIssueBatchSchedular();
        String sch = '0 15 * * * ?';
        System.schedule('Test schedule', sch, ws);
    }
}