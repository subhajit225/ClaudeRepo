@isTest
public class OpportunityAddDealRegLWCControllerTest{
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
            insert acc;
            Contact con=TestDataFactory.getContact(acc);
            con.FirstName = 'test contact1';
            con.LastName = 'lastname';
            insert con;
            Lead ld=TestDataFactory.insertLead();
            ld.FirstName = 'test lead1';
            ld.LastName = 'lastname';
            ld.Deal_Reg_Approval_Status__c = 'Approved';
            ld.Deal_Registration__c = true;
            ld.IsConverted=false;
            insert ld;
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c='Submitted';
            deal.StateCode__c = 'AL';
            deal.Primary__c = true;
            deal.Lead__c=ld.id;
            insert deal;
            List<ProcessInstanceWorkitem> workItemList = [Select Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId=:deal.id];
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction('Approve');
            if(!workItemList.isEmpty()){
                ProcessInstanceWorkitem workItem= workItemList[0];
                req.setWorkitemId(workItem.Id);
                Approval.ProcessResult result = Approval.process(req);
                System.assertEquals('Approved', result.getInstanceStatus());
            }
            opportunity op=new opportunity();
            op.AccountId=acc.id;
            op.Name='Test oppty1';
            op.StageName='Discovery';
            op.CloseDate= Date.today();
            op.Deal_Registration_Link__c=ld.id;
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
            lead li=[select FirstName,company,lastname,Deal_Reg_Approval_Status__c,Deal_Reg_Submitted_Date__c,Deal_Reg_Approval_Timestamp__c,
                    Deal_Reg_Exp_Date__c,Deal_Registration_Number__c,Partner_Rep_Phone_Number__c,Partner_Rep_Email_Address__c,Distributor_Rep_Phone_Number__c,
                    Distributor_Secondary_Email_Address__c,Partner_SE_Name__c,Partner_SE_Phone__c,Partner_SE_Email__c,Sell_to_Partner__c from lead where FirstName = 'test lead1' limit 1];
            Opportunity oppty = [select id,AccountId from Opportunity where Name ='Test oppty1' limit 1];
            Contact con = [select id from Contact where FirstName ='test contact1' limit 1];
            Test.startTest();
            OpportunityAddDealRegLWCController.getAccessDetails(oppty.Id);
            OpportunityAddDealRegLWCController.getLeads('test lead');
            OpportunityAddDealRegLWCController.convertLead(li,oppty,con.id);
            OpportunityAddDealRegLWCController.copyDealRegLeadToOpportunity(oppty,li);
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
            for(integer i=1;i<50;i++){
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
            OpportunityAddDealRegLWCController.getLeads('test lead');
            System.assert(leadList.size()>0, 'lead created');
        }
    }
    static testMethod void unitTest3(){
        User u = [select id from user where FirstName Like '%testClassUser%' limit 1];
        ShGl_DisableBusinessLogic__c businessLogic = new ShGl_DisableBusinessLogic__c(setupownerid = u.Id,Disable_Lead_Validation_Rules__c = true);
        insert businessLogic;
        System.runAs(u){
            lead li=[select FirstName,company,lastname,Deal_Reg_Approval_Status__c,Deal_Reg_Submitted_Date__c,Deal_Reg_Approval_Timestamp__c,
                    Deal_Reg_Exp_Date__c,Deal_Registration_Number__c,Partner_Rep_Phone_Number__c,Partner_Rep_Email_Address__c,Distributor_Rep_Phone_Number__c,
                    Distributor_Secondary_Email_Address__c,Partner_SE_Name__c,Partner_SE_Phone__c,Partner_SE_Email__c,Sell_to_Partner__c from lead where FirstName = 'test lead1' limit 1];
            li.Lead_Rejection_Reason__c = 'test reason';
            li.Status = 'Non-Qualified'; 
            update li;
            businessLogic.Disable_Lead_Validation_Rules__c = false;
            update businessLogic;
            Opportunity oppty = [select id,AccountId from Opportunity where Name = 'Test oppty1' limit 1];
            oppty.Deal_Registration_Link__c = null;
            update oppty;
            Contact con = [select id from Contact where FirstName ='test contact1' limit 1];
            Test.startTest();
            OpportunityAddDealRegLWCController.getAccessDetails(oppty.Id);
            OpportunityAddDealRegLWCController.getLeads('test lead');
            OpportunityAddDealRegLWCController.convertLead(li,oppty,con.id);
            Test.stopTest();
            Lead conLead = [SELECT isConverted from Lead where id = :li.Id];
            system.assertEquals(false, conLead.IsConverted);
        }
    } 
}