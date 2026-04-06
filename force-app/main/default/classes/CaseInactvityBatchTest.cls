@isTest
public class CaseInactvityBatchTest {
  
    
    @testSetup static void methodName() {
 
      
        Case cs = new Case();
        cs.Status='Waiting for Rubrik Support';
        cs.Priority='P1';
        cs.Origin='Email';
        cs.Platform__c='Spam/Junk';
        cs.Subject='Test Rec';
        cs.Description='Test Description';
        insert cs;
      }    

    
     static testMethod void caseInactivityTest() {
         Test.startTest();
        Case cs =[select id from case   limit 1];
         system.debug('cs@@@@@@@@@@@@@@@@@@@'+cs);
       
         Database.executeBatch(new CaseInactivityBatch('select id,Backlog_Inactivity_KPI__c,Status,LastModifiedDate from Case where id =\''+cs.id+'\''), 200);

       Test.stopTest();
       
        
    }


}