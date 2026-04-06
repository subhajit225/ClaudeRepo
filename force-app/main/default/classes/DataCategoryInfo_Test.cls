/********************************************************************************************************
* Name              : DataCategoryInfo_Test
* Purpose           : DataCategoryInfo_Test is Used for Testing DataCategoryInfo Class
*********************************************************************************************************/
@isTest
public class DataCategoryInfo_Test{
    private static DataCategoryInfo dataCatInfo = new DataCategoryInfo('Test Name','Test label','Test displayName');
    
    static testMethod void testGetName(){
        Test.startTest();
        String returnedName = dataCatInfo.getName();
        Test.stopTest();
    }
    
    static testMethod void testGetLabel(){
        Test.startTest();
        String returnedLabel = dataCatInfo.getLabel();
        Test.stopTest();
    }
    
    static testMethod void testGetDisplayName(){
        Test.startTest();
        String returnedDisplayName = dataCatInfo.getDisplayName();
        Test.stopTest();
    }
}