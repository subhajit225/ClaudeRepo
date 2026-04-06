@isTest(seeAllData=false)
public class ShGl_CommonUtility_Test {
    
    //Test Opportunity - Creation
    static testMethod void testMethod_CodeCoverage() {
        
        ShGl_TestFactoryHelper.insertCustomSettings();
        
        //Generate the Account
        List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(), 10, null);
        insert newActList;
        
        ShGl_CommonUtility.convertListToMap(newActList, 'Id');
        ShGl_CommonUtility.convertListToIdMap(newActList);
        
        
        ShGl_CommonUtility.convertListToFieldMap(newActList, 'Name');
    }
    
    
}