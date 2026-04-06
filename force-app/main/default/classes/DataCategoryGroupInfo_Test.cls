/********************************************************************************************************
* Name              : DataCategoryGroupInfo_Test
* Purpose           : DataCategoryGroupInfo_Test is Used for Testing DataCategoryGroupInfo Class
*********************************************************************************************************/
@isTest
public class DataCategoryGroupInfo_Test{
    static testMethod void testDataCategoryGroupInfo(){
        DataCategoryInfo[] structure = new DataCategoryInfo[1];
        structure.add(new DataCategoryInfo('TestName','TestLabel','TestDisplayName'));
        
        Test.startTest();
        DataCategoryGroupInfo datCatInfo= new DataCategoryGroupInfo('TestName','TestLabel','TestDescription',structure);
        String name = datCatInfo.getName();
        String label = datCatInfo.getLabel();
        String description =datCatInfo.getDescription();
        DataCategoryInfo[] groupStructure = datCatInfo.getGroupStructure();
        Test.stopTest();
        
    }
}