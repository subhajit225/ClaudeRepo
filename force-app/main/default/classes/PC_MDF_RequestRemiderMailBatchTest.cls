@isTest
public class PC_MDF_RequestRemiderMailBatchTest {
    @isTest static void testMethod1() {
        UserRole ur = [SELECT Id from userrole where name ='CEO'];
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        User uu=new User(firstname = 'Alan', 
                         lastName = 'McCarthy', 
                         email = 'HG@gmail.com', 
                         Username = 'HG79879@gmail.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'GAA', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id,
                         UserRoleId = ur.Id); 
        UserRole urCDM = [SELECT Id from userrole where name ='Channel Development Manager'];
        Profile prCDM = [Select Id from profile where Name='Channel Development Manager']; 
        User uCDM1 = new User(firstname = 'James', 
                              lastName = 'Webb', 
                              email = 'JamWeb00098990@gmail.com', 
                              Username = 'JamWeb00098990@gmail.com', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = 'GAA', 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = prCDM.Id,
                              UserRoleId = urCDM.Id); 
        insert uCDM1;
        System.RunAs(uu) {
            Id pid = [select id from profile where name='Rubrik Customer Community Login User'].id;
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account acc= new Account(Name='testacc',recordtypeId=devRecordTypeId);
            insert acc;
            Contact c = New Contact(LastName = 'Test', AccountID = acc.id, email= system.label.Invoices_Email);
            insert c;
            User u1 = new User( email='fgh@gmail.com',
                               profileid = pid, 
                               UserName='gjhgj456546@gmail.com', 
                               Alias = 'GDS',
                               TimeZoneSidKey='America/New_York',
                               EmailEncodingKey='ISO-8859-1',
                               LocaleSidKey='en_US', 
                               LanguageLocaleKey='en_US',
                               ContactId = c.Id,
                               PortalRole = 'Manager',
                               FirstName = 'Genelia',
                               LastName = 'Dsouza');
            insert u1;
            acc.isPartner = true;
            update acc;

            PartnerMarketingBudget budgt = new PartnerMarketingBudget(Amount=1000,ChannelPartnerId=acc.Id,EndDate=system.today()+1,StartDate=system.today(),Title='test',IsIgnoreValidation=true);
            insert budgt;
            PartnerFundAllocation al = new PartnerFundAllocation(Amount=1000,ChannelPartnerId=acc.Id,Title='test', BudgetId= budgt.id);
            insert al;
            PartnerFundRequest pfrec = new PartnerFundRequest();
            pfrec.Status = 'Draft';
            pfrec.title = 'test';
            pfrec.Activity = 'Digital Advertising';
            pfrec.Activity_Objective__c = 'Enablement';
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing';
            pfrec.Alliances__c = 'Cisco';
            pfrec.Activity_Start_Date__c = system.today().addDays(-1);
            pfrec.Activity_End_Date__c = system.today().addDays(-1);
            pfrec.RequestedAmount = 1000;
            pfrec.Description = 'gbjhsad';
            pfrec.Amount = 1000;
            pfrec.AllocationId = al.id;
            pfrec.ChannelPartnerId = acc.Id;
            pfrec.Campaign_Focus__c = 'SFDC';
            pfrec.Segment__c = 'FED';
            pfrec.CDM__c = uCDM1.Id;
			pfrec.Planned_Inquiries__c = 0;
            insert pfrec;

            
            Approval.ProcessSubmitRequest testapproval = new Approval.ProcessSubmitRequest();
            testapproval.setComments('Submitting request for approval');
            testapproval.setObjectId(pfrec.Id);
            Approval.process(testapproval);
            Id jobId;
            Test.startTest();
            	jobId = Database.executeBatch(new PC_MDF_RequestRemiderMailBatch());
            Test.stopTest();
            
            AsyncApexJob job = [SELECT TotalJobItems, JobItemsProcessed, CompletedDate, Status FROM AsyncApexJob WHERE Id = :jobId];
            System.assertEquals(job.Status, 'Completed','Batch job finished successfully');
    	}
    }
}