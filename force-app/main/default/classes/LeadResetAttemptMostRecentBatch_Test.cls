/********************************************************************************************************
* Name              : LeadResetAttemptMostRecentBatch_Test
* Purpose           : LeadResetAttemptMostRecentBatch_Test is Used for Testing LeadResetAttemptMostRecentBatch Class
*********************************************************************************************************/
@isTest
public class LeadResetAttemptMostRecentBatch_Test {

    static testMethod void testBacth(){
    
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        List<Lead> ldList = new List<Lead>{TestDataFactory.insertLead(), TestDataFactory.insertLead()};
        
        ldList.get(0).Most_Recent_Activity_Date__c = Date.today() - 26;
        
        ldList.get(1).Most_Recent_Activity_Date__c = Date.today() - 24;
        ldList.get(1).Email = 'Test@REdSky1.com';

        insert ldList;
        
        List<Lead> ldList1 = [SELECT Id, No_Activity_for_24_Days__c FROM Lead WHERE No_Activity_for_24_Days__c > 24 ];
        system.debug('ldList1 :: '+ldList1);
        
        Test.startTest();

        LeadResetAttemptMostRecentBatch queryStrBatch = new LeadResetAttemptMostRecentBatch();
        String qryStr = queryStrBatch.query;
        LeadResetAttemptMostRecentBatch exeBatch = new LeadResetAttemptMostRecentBatch(qryStr);
        exeBatch.start(null);
        exeBatch.execute(null);
        exeBatch.execute(null,ldList);
        exeBatch.finish(null);
        
        Test.stopTest();
        
    }
    
}