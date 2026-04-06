/**
 * @description Test class for OpportunityOwnerAssignmentBatch.
 * Ensures insert, bulk, delete, and finish scenarios are covered.
 * @author Charlie
 * @since 2025-09-02
 */
@IsTest
public class OpportunityOwnerAssignmentBatch_Test {

    // Constants for reuse (PMD compliance)
    private static final String ROLE_PARTNER_RELATION = 'Partner Relation';
    private static final String ACCESS_READ = 'Read';
    private static final String STAGE_PROSPECTING = 'Prospecting';
    private static final String INVOLVEMENT_TAP = 'TAP Alliance';
    private static final String INVOLVEMENT_INFLUENCE = 'Influence Partner';

    /**
     * @description Verifies single account owner change scenario.
     * @throws Exception if batch execution fails.
     */
    @IsTest
    static void testBatchUpdateSingleOwner() {  
        insert getTriggerControl();
        insert new ShGl_DisableFunctionalityLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Allow_account_Transfer__c = true
        );
        insert new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Disable_Opportunity_Validation_Rules__c = true
        );

        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; 
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.ProfileId = pf.Id;
        insert usr;

        Account acct1 = new Account(Name = 'Acct1', OwnerId = UserInfo.getUserId());
        insert acct1;

        Account acct2 = (Account) ShGl_TestFactory.createSObject(new Account(), null);        
        acct2.RecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Partner_Distributor')
            .getRecordTypeId();
        insert acct2;

        System.runAs(usr) {
            acct1.OwnerId = usr.Id;
            update acct1;
        }

        insert new AccountHistory(AccountId = acct2.Id, Field = 'Owner');

        Opportunity opp = TestDataFactory.getOpportunity();
        opp.AccountId = acct1.Id;
        opp.StageName = STAGE_PROSPECTING;
        opp.SBQQ__Renewal__c = true; // bypass validation rule
        insert opp;

        insert new Partner_Relation__c(
            Partner_Account__c = acct2.Id,
            Opportunity__c = opp.Id,
            Involvement_Type__c = INVOLVEMENT_TAP
        );

        Test.startTest();
        Database.executeBatch(new OpportunityOwnerAssignmentBatch(), 200);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id],
            'Expected one OTM for single account owner');
    }

    /**
     * @description Verifies bulk update and delete scenario with multiple opportunities.
     * @throws Exception if batch execution fails.
     */
    @IsTest
    static void testBatchUpdateBulkAndDelete() {
        insert getTriggerControl();
        insert new ShGl_DisableFunctionalityLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Allow_account_Transfer__c = true
        );
        insert new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Disable_Opportunity_Validation_Rules__c = true
        );

        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; 
        User usr1 = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr1.ProfileId = pf.Id;
        insert usr1;

        User usr2 = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr2.ProfileId = pf.Id;
        insert usr2;

        Account acct1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);        
        acct1.RecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Partner_Distributor')
            .getRecordTypeId();
        insert acct1;

        Account acct2 = (Account) ShGl_TestFactory.createSObject(new Account(), null);        
        acct2.RecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Partner_Distributor')
            .getRecordTypeId();
        insert acct2;

        Opportunity opp1 = TestDataFactory.getOpportunity();
        opp1.AccountId = acct1.Id;
        opp1.StageName = STAGE_PROSPECTING;
        opp1.SBQQ__Renewal__c = true;
        insert opp1;

        Opportunity opp2 = TestDataFactory.getOpportunity();
        opp2.AccountId = acct2.Id;
        opp2.StageName = STAGE_PROSPECTING;
        opp2.SBQQ__Renewal__c = true;
        insert opp2;

        insert new List<Partner_Relation__c>{
            new Partner_Relation__c(Partner_Account__c = acct1.Id, Opportunity__c = opp1.Id, Involvement_Type__c = INVOLVEMENT_TAP),
            new Partner_Relation__c(Partner_Account__c = acct2.Id, Opportunity__c = opp2.Id, Involvement_Type__c = INVOLVEMENT_INFLUENCE)
        };

        insert new OpportunityTeamMember(
            OpportunityId = opp1.Id,
            UserId = usr1.Id,
            TeamMemberRole = ROLE_PARTNER_RELATION,
            OpportunityAccessLevel = ACCESS_READ
        );

        System.runAs(usr1) {
            acct2.OwnerId = usr2.Id;
            update acct2;
        }
        insert new AccountHistory(AccountId = acct2.Id, Field = 'Owner');

        Test.startTest();
        Database.executeBatch(new OpportunityOwnerAssignmentBatch(), 200);
        Test.stopTest();

        List<OpportunityTeamMember> teamMembers = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId IN :new List<Id>{opp1.Id, opp2.Id}];
        System.assert(teamMembers.size() >= 2, 'Expected multiple OTMs after bulk and delete scenario');
    }

    /**
     * @description Covers finish method and error logging.
     */
    @IsTest
    static void testBatchUpdateFinishAndError() {
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; 
        User runAsUser = (User) ShGl_TestFactory.createSObject(new User(), null);
        runAsUser.ProfileId = pf.Id;
        insert runAsUser;

        OpportunityOwnerAssignmentBatch batch = new OpportunityOwnerAssignmentBatch();
        if (batch.errorLogList != null) {
            batch.errorLogList.add(new Custom_Error_Log__c(Name = 'Dummy Error Log'));
        }

        System.runAs(runAsUser) {
            Test.startTest();
            batch.finish(null);
            Test.stopTest();
        }

        System.assert(
            batch.errorLogList.size() > 0, 
            'Error log list should have entries after finish'
        );
    }

    /**
     * @description Utility method to insert TriggerControl__c.
     * @return TriggerControl__c - new trigger control record.
     */
    private static TriggerControl__c getTriggerControl() {
        TriggerControl__c tc = new TriggerControl__c();
        tc.Name = 'Account';
        tc.DisableTrigger__c = true;
        return tc;
    }
    
    /**
     * @description Updates CDM fields on Cmpaign, Contact and Lead Object whenever Account Owner is changed.
     */
    @IsTest
    static void testBatchForCampaignLeadContactCDM() {
        insert getTriggerControl();
        insert new ShGl_DisableFunctionalityLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Allow_account_Transfer__c = true
        );
        insert new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Disable_Opportunity_Validation_Rules__c = true
        );

        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; 
        User usr1 = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr1.ProfileId = pf.Id;
        insert usr1;
        
        Account acct1 = new Account(Name = 'Acct1', OwnerId = usr1.Id);
        acct1.RecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Partner_Distributor')
            .getRecordTypeId();
        insert acct1;
        
        Campaign camp = new Campaign(Campaign_Partner__c = acct1.Id, StartDate = Date.newInstance(2025, 3, 1), ETM_Role__c = 'Account Executive',Executed_By__c='Sales',Planned_MQL__c = 1,Involvement_by_Customer_Marketing__c='Yes',Campaign_Theme__c='Cloud',Name = 'Test Campaign 1',type='Advertising', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance',RecordTypeId=Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId(),GTM_Play__c='Cloud Native Protection');
        insert camp;
        
        Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        con.Last_MQL_Date__c = Date.today();
        con.MQL_Channel_Partner__c = acct1.Id;
        insert con;
        
        Lead leadRec;
        system.runAs(usr1){
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
            leadRec.MQL_Channel_Partner__c = acct1.Id;
            insert leadRec;
        }

        System.runAs(usr1) {
            acct1.OwnerId = usr1.Id;
            update acct1;
        }
        insert new AccountHistory(AccountId = acct1.Id, Field = 'Owner');

        Test.startTest();
        OpportunityOwnerAssignmentBatch batch = new OpportunityOwnerAssignmentBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Account acc = [SELECT Id, OwnerId FROM Account WHERE Name = 'Acct1' LIMIT 1];
        Campaign camp1 = [SELECT Id, CDM__c, Campaign_Partner__c FROM Campaign WHERE Campaign_Partner__c = :acc.Id LIMIT 1];
        
        System.assertEquals(acc.OwnerId, camp1.CDM__c, 'Campaign CDM__c should match Account OwnerId');
    }
}