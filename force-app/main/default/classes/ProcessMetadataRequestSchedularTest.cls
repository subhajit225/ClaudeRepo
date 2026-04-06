/**
 * Author       :   Saakshi Gupta
 * CreatedDate  :   30th July 2020
 * Description  :   Test class for ProcessMetadataRequestsBatchSchedular
 */
@isTest(seeAllData = false)
public class ProcessMetadataRequestSchedularTest {
    public static testMethod void testProcessMetadataRequestSchedularTest(){
        ProcessMetadataRequestsBatchSchedular ws = new ProcessMetadataRequestsBatchSchedular();
        String sch = '0 15 * * * ?';
        System.schedule('Test schedule', sch, ws);
    }
}