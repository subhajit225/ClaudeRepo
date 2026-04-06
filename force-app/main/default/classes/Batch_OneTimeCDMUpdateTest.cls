@IsTest
public class Batch_OneTimeCDMUpdateTest {
    
    @TestSetup
    static void setupData() {
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr1 = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr1.ProfileId = pf.Id;
        usr1.LastName = 'user1';
        usr1.isActive = true;
        
        User usr2 = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr2.ProfileId = pf.Id;
        usr2.isActive = true;
        
        insert new List<User>{usr1, usr2};
        
            Id devRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        
        Account acc1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acc1.OwnerId = usr1.Id;
        acc1.RecordTypeId = devRecordTypeId;
        insert acc1;
        
        ShGl_DisableFunctionalityLogic__c bypassSetting =
            new ShGl_DisableFunctionalityLogic__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                Allow_account_Transfer__c = true
            );
        insert bypassSetting;
        
        Campaign camp1 = new Campaign(Campaign_Partner__c = acc1.Id, Override_Channel_CDM__c = true, ETM_Role__c = 'Account Executive',Executed_By__c='Sales',Planned_MQL__c = 1,Involvement_by_Customer_Marketing__c='Yes',Campaign_Theme__c='Cloud',Name = 'Test Campaign 1',type='Advertising', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance',RecordTypeId=Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId(),GTM_Play__c='Cloud Native Protection', StartDate = system.today());
        insert camp1;
    }
    
    /**
     * @description - Update respective CDM field in Campaign, Lead and Contact
     */
    @IsTest
    static void testBatchForCampaignLeadContactCDM() {
        User usr1 = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND LastName = 'user1' LIMIT 1];
        User usr2 = [SELECT Id FROM User WHERE Profile.Name = 'Rubrik Marketing Ops User' LIMIT 1];
        Account acc1 = [SELECT Id, OwnerId FROM Account LIMIT 1];
        
        system.runAs(usr1){
            acc1.OwnerId = usr2.Id;
            update acc1;
            
        List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 1, null);
        conList[0].Last_MQL_Date__c = system.today();
        conList[0].MQL_Channel_Partner__c = acc1.Id;
        insert conList[0];
            
            Lead leadRec;
            WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
                
            leadRec = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
            leadRec.firstName = 'Test';
            leadRec.lastName = 'Lead';
            leadRec.Status = 'Open';
            leadRec.CountryCode = 'US';
            leadRec.Routing_Rule_Applied__c ='test';
            leadRec.Last_MQL_Date__c = Date.today();
            leadRec.Privacy_Compliance__c = true;
            leadRec.MQL_Channel_Partner__c = acc1.Id;
            insert leadRec;
        
        Test.startTest();
        system.enqueueJob(new Queueable_OneTimeCDMUpdateInCampaign());
        Test.stopTest();
        }

        Lead updatedLead = [SELECT MQL_Channel_CDM__c FROM Lead WHERE LastName = 'Lead' LIMIT 1];
        System.assertEquals(usr2.Id, updatedLead.MQL_Channel_CDM__c, 'Lead MQL_Channel_CDM__c should be equal to usr2');
    }
    
}