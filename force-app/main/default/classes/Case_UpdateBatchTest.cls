/********************************************************************************************************
* Name              : Case_UpdateBatchTest
* Purpose           : Case_UpdateBatchTest is Used for Testing Case_Update_Batch Class
*********************************************************************************************************/
@isTest(seeAllDAta=false)
public class Case_UpdateBatchTest{
    static testMethod void testMethodforBatch(){
        List<Case> caseList = new List<Case>();
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.Heads_Up_to_Support_Team__c = 'Hello';
        insert act;
        
        
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert con;
        
        Map<String, Object> caseMap = new Map<String, Object> {
            'Subject' => 'testing one more',
            'ContactId' => con.Id,
            'Jira_Reference_urls__c' => 'test',
            'Last_Case_Status__c' => 'Customer requested close',
            'Priority' => 'P2',
            'Special_Handling_Instructions__c' => act.Heads_Up_to_Support_Team__c,
            'AccountId' => act.Id
            
        };
        Case caseTest = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap);
        caseList.add(caseTest);
        insert caseList;
        
        Test.startTest();
            Case_Update_Batch obj = new Case_Update_Batch();
            DataBase.executeBatch(obj); 
            
            obj.execute(null,caseList);
            
        Test.stopTest();
    }
}