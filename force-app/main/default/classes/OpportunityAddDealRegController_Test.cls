@isTest
public class OpportunityAddDealRegController_Test{
    @testSetup
    static void setupData(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        System.runAs(listUser[0]) {
            TestDataFactory.setWorkflowTriggerBypassCS(true);
            TriggerControl__c newCstm=new TriggerControl__c();
            newCstm.Name='Opportunity';
            newCstm.DisableTrigger__c=false;
            insert newCstm;
            Account acc=TestDataFactory.getAccount();
            acc.Name = 'Test Account1';
            insert acc;
            Contact con=TestDataFactory.getContact(acc);
            con.FirstName = 'Test Contact1';
            insert con;
            Lead ld1=TestDataFactory.insertLead();
            ld1.FirstName = 'test lead1';
            ld1.LastName = 'lastname';
            ld1.Email = 'testlead01@gmail.com';
            ld1.Deal_Reg_Approval_Status__c = 'Approved';
            ld1.Deal_Registration__c = true;
            ld1.IsConverted=false;
            insert ld1;
            Lead ld2=TestDataFactory.insertLead();
            ld2.FirstName = 'test lead2';
            ld2.LastName = 'lastname';
            ld2.Email = 'testlead02@gmail.com';
            ld2.Deal_Reg_Approval_Status__c = 'Approved';
            ld2.Deal_Registration__c = true;
            ld2.IsConverted=false;
            insert ld2;
            Lead ld3=TestDataFactory.insertLead();
            ld3.FirstName = 'test lead3';
            ld3.LastName = 'lastname';
            ld3.Email = 'testlead03@gmail.com';
            ld3.Deal_Reg_Approval_Status__c = 'Approved';
            ld3.Deal_Registration__c = true;
            ld3.IsConverted=false;
            insert ld3;
            Deal_Registration__c deal1=TestDataFactory.getDealRegistration();
            deal1.Deal_Registration_Status__c='Submitted';
            deal1.Primary__c = true;
            deal1.Lead__c=ld1.id;
            insert deal1;
            Deal_Registration__c deal2=TestDataFactory.getDealRegistration();
            deal2.Deal_Registration_Status__c='Submitted';
            deal2.Primary__c = true;
            deal2.Lead__c=ld2.id;
            insert deal2;
            Deal_Registration__c deal3=TestDataFactory.getDealRegistration();
            deal3.Deal_Registration_Status__c='Submitted';
            deal3.Primary__c = true;
            deal3.Lead__c=ld3.id;
            insert deal3;
            opportunity op=new opportunity();
            op.AccountId=acc.id;
            op.Name='Test oppty';
            op.StageName='Discovery';
            op.CloseDate= Date.today();
            op.Deal_Registration_Link__c=ld1.id;
            insert op;
            OpportunityContactRole ocr=new OpportunityContactRole();
            ocr.ContactId=con.id;
            ocr.IsPrimary=TRUE;
            ocr.OpportunityId=op.id;
            insert ocr;
        }
    }
    static testMethod void unitTest(){
        User u = [select id from user where FirstName Like '%testClassUser%' limit 1];
        System.runAs(u){
            Deal_Registration__c deal = [select id, Name from Deal_Registration__c where FirstName__c = 'Test' and LastName__c = 'Lead' limit 1];
            List<ProcessInstanceWorkitem> workItemList = [Select Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId=:deal.id];
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction('Approve');
            if(!workItemList.isEmpty()){
                ProcessInstanceWorkitem workItem= workItemList[0];
                req.setWorkitemId(workItem.Id);
                Approval.ProcessResult result = Approval.process(req);
                System.assertEquals('Approved', result.getInstanceStatus());
            }
            
            lead li=[select FirstName,company,lastname from lead where FirstName = 'test lead1' limit 1];
        opportunity oppty = [select id from opportunity where Name = 'Test oppty' limit 1];
            Test.startTest();
            PageReference pageRef=Page.OpportunityAddDealReg;
            Test.setCurrentPage(pageRef);
            String originalId=pageRef.getParameters().put('id',oppty.Id);
            OpportunityAddDealRegController testPlan=new OpportunityAddDealRegController();
            testPlan.originalId=originalId;
            testPlan.searchText=deal.Name;
            try{
                testPlan.Search();
                testPlan.beginning();
                testPlan.getDisableNext();
                testPlan.getDisablePrevious();
                testPlan.jsonHidden='[\"'+li.id+'"]';
                testPlan.convertLead();
                testPlan.convertLead();
                testPlan.cancel();            
                testPlan.previous();            	
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());
            }
            Test.stopTest();
            Lead conLead = [SELECT isConverted from Lead where id = :li.Id];
            system.assertEquals(true, conLead.IsConverted);
        }
    }
    static testMethod void unitTest1(){
        User u = [select id from user where FirstName Like '%testClassUser%' limit 1];
        System.runAs(u){
            TestDataFactory.setWorkflowTriggerBypassCS(true);
            list<lead> leadList=new list<lead>();
            for(integer i=1;i<40;i++){
                lead ld=new lead();
                ld.firstname='Test'+i;
                ld.LastName=i+'test'+i;
                ld.Email='TESTDATA'+i+'@test.com';
                ld.Company='TEST DATA LTD.';
                ld.Status='Open';
                ld.Deal_Registration__c=true;
                ld.LeadSource='Email';
                ld.IsConverted=false;
                ld.Country='United States';
                leadList.add(ld);
            }
            insert leadList;
            Opportunity opp = [select id from Opportunity where Name = 'Test oppty' limit 1];
            opp.Deal_Registration_Link__c = null;
            update opp;
            OpportunityAddDealRegController testPlan=new OpportunityAddDealRegController();
            testPlan.searchText='test lead';
            try{
                testPlan.search();
                testPlan.beginning();
                testPlan.getDisableNext();
                testPlan.getDisablePrevious();
                testPlan.next();       
                testPlan.last();         	
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG,'@@ exception '+e.getMessage());   
            }
            system.assertEquals(null, opp.Deal_Registration_Link__c);
        }
    }
    
}