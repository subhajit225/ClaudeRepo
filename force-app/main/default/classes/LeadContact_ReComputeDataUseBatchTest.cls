@isTest
public class LeadContact_ReComputeDataUseBatchTest {
    
    /**
     * @description - Update respective CDM field in Campaign, Lead and Contact
     */
    @IsTest
    static void testBatchForLeadAndContactReComputeDataUsePermitted() {
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        List<User> usr1 = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert usr1;
        
        system.runAs(usr1[0]){
            List<Contact> conList = MarketingTestDataUtility.createContacts(1, null, new Map<String, Object>{'Email_Opt_In__c' => false});
            conList[0].MailingCountryCode = 'CN';
            conList[0].LeadSource = 'Advertising';
            insert conList[0];
            
            List<Lead> leadRec;
            
            WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
                
            leadRec = MarketingTestDataUtility.createLeads(1, null, new Map<String, Object>{'Email_Opt_In__c' => false});
            leadRec[0].CountryCode = 'CN';
            leadRec[0].LeadSource = 'Advertising';
            insert leadRec;
            
            
            Test.startTest();
            List<String> leadSources = new List<String>{'Advertising'};
                List<String> countryCodes = new List<String>{'CN'};
                    Database.executeBatch(new Batch_LeadReComputeDataUsePermitted(leadSources, countryCodes));
            Database.executeBatch(new Batch_LeadReComputeDataUsePermitted(leadSources, new List<String>()));
            Database.executeBatch(new Batch_LeadReComputeDataUsePermitted(new List<String>(), countryCodes));
            
            Database.executeBatch(new Batch_ContactReComputeDataUsePermitted(leadSources, countryCodes));
            Database.executeBatch(new Batch_ContactReComputeDataUsePermitted(leadSources, new List<String>()));
            Database.executeBatch(new Batch_ContactReComputeDataUsePermitted(new List<String>(), countryCodes));
            Test.stopTest();
        }
        
        List<Lead> leads = [SELECT Data_Use_Permitted__c, IsConverted FROM Lead ORDER BY LastName];
        System.assertEquals(false, leads[0].Data_Use_Permitted__c);
    }

}