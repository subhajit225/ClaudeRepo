@isTest
public class PC_DealRegExtnReqControllerTest {
    @TestSetup
    static void makeData(){
    
        List<WorkflowTriggerBypass__c> wtList = new List<WorkflowTriggerBypass__c>();
        WorkflowTriggerBypass__c wt = new WorkflowTriggerBypass__c(name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
        wtList.add(wt);
        WorkflowTriggerBypass__c wt1 = new WorkflowTriggerBypass__c(name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
        wtList.add(wt1);
        WorkflowTriggerBypass__c wt2 = new WorkflowTriggerBypass__c(name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
        wtList.add(wt2);
        WorkflowTriggerBypass__c wt3 = new WorkflowTriggerBypass__c(name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
        wtList.add(wt3);
        WorkflowTriggerBypass__c wt4 = new WorkflowTriggerBypass__c(name='updateOpportunitySource',ByPassTrigger__c=false);
        wtList.add(wt4);
        WorkflowTriggerBypass__c wt5 = new WorkflowTriggerBypass__c(name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
        wtList.add(wt5);
        WorkflowTriggerBypass__c wt6 = new WorkflowTriggerBypass__c(name='salesOperationsSetEUResident',ByPassTrigger__c=false);
        wtList.add(wt6);
        insert wtList;
        
        Map<String, String> mapOfMapping = new Map<String, String>();
        Account acc=TestDataFactory.getAccount();
        insert acc;
        
        Contact con = TestDataFactory.getContact(acc);
        insert con;
        
        Opportunity opp = TestDataFactory.getOpportunity(acc,con);
        insert opp;
        
    }
    static testMethod void testMethod1(){
        
        User sysuser2  = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'lastNameDRTest',
            Email = 'uniqueName1233' +'@rubrik.com',
            Username = 'uniqueName1233' +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'uniqueName'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Start_Date__c=System.Today().adddays(-30)
        );
        
        
        Opportunity opp = [Select Id from Opportunity LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        System.runAs(sysuser2){
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=UserInfo.getUserId(),CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=UserInfo.getUserId(),AccountExecutive__c=UserInfo.getUserId());
            insert pm;
            
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            system.debug(cc);
            
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            Id ResellerRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal.Deal_Registration_Status__c = 'Approved';
            deal.Opportunity__c = opp.Id;
            deal.RecordTypeId = ResellerRecordTypeId;
            system.debug('>>>>'+CountryWithCode__c.getAll());
            insert deal;
            
            Test.startTest();    
            PC_DealRegExtnReqController.getStatus(string.valueOf(deal.Id));    
            PC_DealRegExtnReqController.setExtension(string.valueOf(deal.Id));
            
            //already extension req processed
            PC_DealRegExtnReqController.setExtension(string.valueOf(deal.Id));
            Test.stopTest();    
        }
    }
    
    static testMethod void testMethod2(){
        
        User sysuser2  = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'lastNameDRTest',
            Email = 'uniqueName1233' +'@rubrik.com',
            Username = 'uniqueName1233' +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'uniqueName'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Start_Date__c=System.Today().adddays(-30)
        );
        
                
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        System.runAs(sysuser2){
            Id georecId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
            PatchManager__c pm = new PatchManager__c(recordtypeId=georecId,CDM__c=UserInfo.getUserId(),CountryGlobal__c='United States',City__c='City',State__c='AK',StateGlobal__c='AK',Zip_code__c='421302',SDR__c=UserInfo.getUserId(),AccountExecutive__c=UserInfo.getUserId());
            insert pm;
            
            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            system.debug(cc);
            
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            Id ResellerRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal.Deal_Registration_Status__c = 'Approved';
            deal.RecordTypeId = ResellerRecordTypeId;
            insert deal;
            deal.Deal_Registration_Status__c = 'Expired';
            update deal;
            Test.startTest();    
            	PC_DealRegExtnReqController.setExtension(string.valueOf(deal.Id));            
            Test.stopTest();    
        }
    }
}