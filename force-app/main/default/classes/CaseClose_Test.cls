/********************************************************************************************************
* Name              : CaseClose_Test 
* Purpose           : CaseClose_Test is Used for Testing caseClose Trigger
*********************************************************************************************************/
@isTest
public class CaseClose_Test{
    @testSetup
    static void setUpdata(){
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
            'close_survey_triggered__c' => false,
            'Resolution__c' => 'Hardware problem',
            'Special_Handling_Instructions__c' => act.Heads_Up_to_Support_Team__c,
            'AccountId' => act.Id
            
        };
        Case caseTest = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap);
        caseList.add(caseTest); 
        insert caseList;
    }
    
    static testMethod void testCaseAfterUpdate(){
        List<Case> caseList = [Select Id,Type,Status,close_survey_triggered__c From Case where Subject='testing one more' limit 1];
        
        caseList[0].Type = 'Duplicate/Spam/Junk';
        caseList[0].Status = 'Closed';
        caseList[0].close_survey_triggered__c = true;
        caseList[0].KCS_Article_Candidate__c = 'No Article required';
        caseList[0].KCS_or_Supportability_comments__c = 'test';
        try{
            update caseList;
        }catch(Exception exp){
            System.debug('Exception : '+Exp);
        }
    }
    
    static testMethod void testCaseAfterUpdateForClosed(){
        
        List<Case> caseList = [Select Id,Type,Status From Case LIMIT 1];
        
        caseList[0].Type = 'Administrative';
        caseList[0].Status = 'Closed';
        caseList[0].KCS_Article_Candidate__c = 'No Article required';
        caseList[0].KCS_or_Supportability_comments__c = 'test';
        try{
            update caseList;
        }catch(Exception exp){
            System.debug('Exception : '+Exp);
        }
    }
    
    static testMethod void testCaseAfterUpdateForFeedbackDate(){
        Contact con=[Select Id,FirstName,Last_GetFeedback_Date__c FROM Contact];
        con.Last_GetFeedback_Date__c = DateTime.now();
        update con;
        List<Case> caseList = [Select Id,Type,Status From Case LIMIT 1];
        
        caseList[0].Type = 'Administrative';
        caseList[0].Status = 'Closed';
        caseList[0].KCS_Article_Candidate__c = 'No Article required';
        caseList[0].KCS_or_Supportability_comments__c = 'test';
        try{
            update caseList;
        }catch(Exception exp){
            System.debug('Exception : '+Exp);
        }
    }
}