@isTest
private class CampaignTriggerTest {
    @testSetup static void testDataSetup() {
        List<CamapignMemberStatus__mdt> mdtList = new List<CamapignMemberStatus__mdt>();   
        mdtList = [select Id,MasterLabel,HasResponded__c,Campaign_Record_Type_Name__c from CamapignMemberStatus__mdt]; 
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        User sysAdmin = [SELECT Id, UserRoleId FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true And UserRoleId != null LIMIT 1];
        Id pid = [SELECT id FROM profile WHERE name='Rubrik Customer Community Login User'].id;
        ID cid = [Select PortalType, PortalAccountId From UserRole where PortalType ='CustomerPortal' limit 1].id;
        System.runAs(sysAdmin){
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
            pfrec.Campaign_Focus__c = 'Expansion';
            pfrec.Budget_Code__c = '5700 - Partner Marketing - 64003 - Channel Marketing'; 
            pfrec.Alliances__c = 'Cisco';
            pfrec.Activity_Start_Date__c = system.today().addDays(-1);
            pfrec.Activity_End_Date__c = system.today().addDays(-1);
            pfrec.RequestedAmount = 1000;
            pfrec.Description = 'gbjhsad';
            pfrec.Amount = 1;
            pfrec.Campaign_Focus__c = 'General';
            pfrec.Segment__c = 'FED';
            pfrec.AllocationId = al.id;
            pfrec.ChannelPartnerId = acc.Id;
            insert pfrec;
        }
        Campaign cmp = TestDataFactory.insertCampaign('TriggerTest');
        cmp.Planned_MQL__c  = 0;
        cmp.Campaign_Theme__c = 'Cloud';
        cmp.GTM_Play__c = 'General Cloud';
        insert cmp;
    }
    @isTest static void testCampaignInsert(){
        Test.startTest();
        Id camprecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program').getRecordTypeId();
        Campaign c = TestDataFactory.insertCampaign('TriggerTest');
        c.Planned_MQL__c  = 0;
        c.Campaign_Theme__c = 'Cloud';
        c.GTM_Play__c = 'General Cloud';
        insert c;
        Test.stopTest();
    }
    @isTest static void testPopulateCDM(){
        Campaign cmp = [SELECT Id FROM Campaign LIMIT 1];
        Account acc = [SELECT Id,OwnerId FROM Account LIMIT 1];
        Test.startTest();
        cmp.Campaign_Partner__c = acc.Id;
        update cmp;
        Test.stopTest();
        Assert.areEqual(acc.Id, cmp.Campaign_Partner__c);
    }
    @isTest static void testPopulateActualCost(){
        Campaign cmp = [SELECT Id FROM Campaign LIMIT 1];
        PartnerFundRequest pfr = [SELECT Id FROM PartnerFundRequest LIMIT 1];
        User u = [Select Id from User Where Id =: userInfo.getUserId()];
        Test.startTest();
        System.runAs(u) {
            cmp.Partner_Fund_Request__c = pfr.Id;
            update cmp;
        }
        
        Test.stopTest();
        Assert.areEqual(pfr.Id, cmp.Partner_Fund_Request__c);
    }
}