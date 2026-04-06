@isTest
public class DealRegDetail_Test {
    
    static Deal_Registration__c deal;
    
    @testSetup static void methodName() {
        User u=TestDataFactory.getUser();
        u.LastName = 'TestUser101';
        insert u;
        UserRole vUserRole = new UserRole(DeveloperName = 'RubrikDeveloper2', Name = 'My Role');
        insert vUserRole;                
        //String uniqueName = getUniqueName();        
        User u2 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'TestUser102',
            Email = 'rubr1k@rubrik2.com',
            Username = 'rubr1k@rubrik2.com',
            CompanyName = 'TEST2',
            Title = 'title2',
            Alias = 'rubr1k',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = vUserRole.Id,
            Start_Date__c=System.Today().adddays(-30)            
        );
        insert u2;
    }
    static testMethod void test(){
        User ur=[Select userrole.Name from User where lastname='TestUser101'];
        User u2=[select userrole.Name from User where lastName='TestUser102'];
        System.runAs(ur){
            
            Account a= new account(name='TestAcc');
            insert a;
            EmailTemplate e = new EmailTemplate (developerName = 'testEmailTemplate', FolderId = UserInfo.getOrganizationId(), TemplateType= 'Text', Name = 'testEmailTemplate');
            insert e;
            //EmailHelper.sendEmail(e, System.UserInfo.getUserId(), a.Id);
            EmailHelper.sendEmail(e.Id, new List<Id>{System.UserInfo.getUserId()}, a.Id);
            
            PatchManagerSettings__c pm= new PatchManagerSettings__c(Route_on_Insert_Deal_Reg__c=true);
            insert pm;
            PatchManager.ROUTE_ON_INSERT_DEALREG=true;
            deal=new Deal_Registration__c(Alliance_Partner_Name__c='Cisco',Authority__c='Budget Owner',
                                          Budget__c='Not known',CDM__c=ur.id,City__c='Test',
                                          Company__c='Test',Country__c='Belgium',Primary__c=true, Title__c='11', FirstName__c='11');
            
            List<Lead> lstLeads = new List<Lead>();
            TestDataFactory.setWorkflowTriggerBypassCS(true);
            Lead l1 = TestDataFactory.insertLead();
            lstLeads.add(l1);
            Lead l2 = TestDataFactory.insertLead();
            lstLeads.add(l2);
            insert lstLeads;
            
            deal.Deal_Registration_Status__c='Submitted';
            deal.Lead__c=lstLeads[0].Id;
            insert deal;
            
            PageReference ObjDealReg = Page.DealRegDetail;
            Test.setCurrentPage(ObjDealReg);
            ObjDealReg.getParameters().put('id',deal.id);
            ApexPages.StandardController sc = new ApexPages.standardController(deal);
            DealRegDetail dealObj=new DealRegDetail(sc);
            deal.rerun_PatchManager_Assignments__c=true;
            update deal;
            deal.OwnerId=u2.Id;
            update deal;
            Test.startTest();            
            deal.Primary__c=false;
            update deal;
            deal.Lead__c=l2.Id;
            update deal;
            
            Task t=new Task();
            t.WhoId=l1.id;
            t.Subject='PID Meeting';            
            insert t;
            t.Post_Meeting_Status__c='Convert to Opportunity';
            update t;
            t.Post_Meeting_Status__c='Do Not Convert To Opportunity';
            t.Disqualified_Reason__c='Not a technical fit';
            update t;
            deal.Deal_Registration_Status__c='Pending';
            update deal;
            deal.Deal_Registration_Status__c='Approved';
            update deal;
            Test.StopTest();
            
        }
    }
}