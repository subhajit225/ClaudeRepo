/**
* Author           :   Ashish Thakur
* Created Date     :   21-04-2022
* Description      :   Test class for CaseDetailControllerLWC  class
*/
@isTest
private class Test_CaseDetailControllerLWC {
    
    
    static testMethod void testgetClusterListLWC1(){
        Account ac = new account(name='test');
        insert ac; 
        list<case> cslist = new list<case>();
        Case cs = new Case();
        cs.AccountId = String.ValueOf(ac.id);
        cs.Status='New';
        cs.Subject = 'Rubrik';
        cs.Priority = 'P4';
        cs.Resolution__c = 'Configuration Assistance';
        cs.Ownerid = userinfo.getuserid();
        cs.RecordTypeId = '0126f0000014VBQAA2';
        cslist.add(cs);
        Case cs1 = new Case();
        cs1.AccountId = String.ValueOf(ac.id);
        cs1.Status='New';
        cs1.Subject = 'Rubrik';
        cs1.Priority = 'P4';
        cs1.Resolution__c = 'Configuration Assistance';
        cs1.Ownerid = userinfo.getuserid();
        cs1.RecordTypeId = '0126f0000014VBQAA2';
        cslist.add(cs1);
        insert cslist;
        
        Cluster__c cl = new Cluster__c();
        cl.Name = '3d04e794-c526-400b-b652-a513a0f07c83';
        cl.tag__c = 'VREC489FBC898';
        cl.software_version__c = '4.0.2-374';
        cl.archived__c = false;
        cl.account__c = cs.AccountId;
        cl.uuid__c = '3d04e794-c526-400b-b652-a513a0f07c83';
        insert cl;   
        
        Test.startTest();
        
        List<case> caseList = CaseDetailControllerLWC.getCaseRecLWC(cs.Id, 'LastModifiedDate','desc');
        List<case> caseList1 = CaseDetailControllerLWC.getFiveCaseRecordsLWC(cs.Id, 'LastModifiedDate','desc');
        Test.stopTest();
        
        System.assertEquals(caseList.size()>0, true);
    }
    
    static testMethod void testgetClusterListLWC2(){
        Account ac = new account(name='test');
        insert ac; 
        
        Case cs = new Case();
        cs.AccountId = String.ValueOf(ac.id);
        cs.Status='New';
        cs.Subject = 'Rubrik';
        cs.Priority = 'P4';
        cs.Resolution__c = 'Configuration Assistance';
        cs.Ownerid = userinfo.getuserid();
        cs.RecordTypeId = '0126f0000014VBQAA2';
        insert cs;
        
        Cluster__c cl = new Cluster__c();
        cl.Name = '3d04e794-c526-400b-b652-a513a0f07c83';
        cl.tag__c = 'VREC489FBC898';
        cl.software_version__c = '4.0.2-374';
        cl.archived__c = true;
        cl.account__c = cs.AccountId;
        cl.uuid__c = '3d04e794-c526-400b-b652-a513a0f07c83';
        insert cl;   
        
        Test.startTest();
        
        List<case> caseList = CaseDetailControllerLWC.getCaseRecLWC(cs.Id, 'LastModifiedDate','desc');
        List<case> caseList1 = CaseDetailControllerLWC.getFiveCaseRecordsLWC(cs.Id, 'LastModifiedDate','desc');
        Test.stopTest();
        
        System.assertEquals(caseList.size()>0, false);
    }
}