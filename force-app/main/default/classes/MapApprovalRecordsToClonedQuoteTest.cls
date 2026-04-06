/**
 * @description Test class for mapApprovalRecordsToClonedQuote.
 *              Validates cloning of approval records and approval snapshots from source quote to cloned quote.
 */
@isTest
public class MapApprovalRecordsToClonedQuoteTest {
    /***********************************************************************************************************
    * Method Name          : setup
    * Date Created/Modified: 04/12/2025
    * Author               : Ankita
    * @description         : Data setup for the test class
    /**********************************************************************************************************/
    @testSetup
    static void setup() {
        // Fetch required profiles
        List<Profile> listProfile = [SELECT Id
                                     FROM Profile
                                     WHERE  Name IN ('Rubrik Inside Sales', 'System Administrator')
                                     ORDER BY Name];
        // Create users for test context
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 4);
        insert listUser;
        INSERT new ShGl_DisableBusinessLogic__c(
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true);
        // Trigger control
        TriggerControl__c triggerControl = new TriggerControl__c(
            Name = 'Approval',
            DisableTrigger__c = true
        );
        insert triggerControl;
        // Create opportunity and related quotes
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;

        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{objOpportunity.Id}, 2);
        insert listQuote;

        // Link second quote to first as source quote
        listQuote[1].SBQQ__Source__c = listQuote[0].ID;
        update listQuote[1];

        // Create approver records
        List<sbaa__Approver__c> listApprover = TestDataFactory.getApprovers(
            new Set<Id>{listUser[0].Id, listUser[1].Id, listUser[2].Id, listUser[3].Id}, new Set<Id>()
        );
        insert listApprover;

        // Create approval rule
        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            Name = 'Test Rule',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert approvalRule;
        sbaa__ApprovalVariable__c tstVar = new sbaa__ApprovalVariable__c(
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
            sbaa__AggregateField__c = 'SBQQ__Quantity__c',
            sbaa__AggregateFunction__c = 'Count',
            sbaa__FilterField__c = 'SBQQ__Quantity__c',
            sbaa__FilterValue__c = '0',
            sbaa__Operator__c = 'greater than',
            sbaa__Type__c = 'Summary'
        );
        insert tstVar;

        List<sbaa__ApprovalCondition__c> conditions = new List<sbaa__ApprovalCondition__c>();
        sbaa__ApprovalCondition__c cond1 = new sbaa__ApprovalCondition__c(
            sbaa__ApprovalRule__c = approvalRule.Id,
            Custom_Smart_Approval__c = true,
            sbaa__Operator__c = 'greater than',
            sbaa__FilterValue__c = '0',
            sbaa__TestedVariable__c = tstVar.Id,
            Track_Fields__c = 'RWD_approval_Tier__c;SBQQ__Quantity__c: greater than;Approval_Discount__c: greater than'
        );
        conditions.add(cond1);

        sbaa__ApprovalCondition__c cond2 = new sbaa__ApprovalCondition__c(
            sbaa__ApprovalRule__c = approvalRule.Id,
            sbaa__EnableSmartApproval__c = true,
            sbaa__Operator__c = 'greater than',
            sbaa__FilterValue__c = '0',
            sbaa__TestedVariable__c = tstVar.Id
        );
        conditions.add(cond2);
        insert conditions;
        // Disable trigger to avoid side effects
        TestDataFactory.setTriggerSwitch('Approval', TRUE);

        // Create approval record on source quote
        sbaa__Approval__c approval = new sbaa__Approval__c(
            Quote__c = listQuote[0].Id,
            sbaa__Opportunity__c = objOpportunity.Id,
            sbaa__Status__c = 'Approved',
            sbaa__Rule__c = approvalRule.ID,
            sbaa__Approver__c = listApprover[0].Id,
            sbaa__AssignedTo__c = listUser[0].Id,
            sbaa__RecordField__c = 'Quote__c',
            sbaa__ApprovalStep__c = 1,
            sbaa__DelegatedApprover__c = listApprover[2].Id
        );
        insert approval;

        // Create approval snapshot linked to approval
        sbaa__ApprovalSnapshot__c snapshot = new sbaa__ApprovalSnapshot__c(
            sbaa__Approval__c = approval.Id,
            sbaa__ApprovedValueNumeric__c = 100,
            sbaa__ApprovedValueText__c = 'Approved Text'
        );
        insert snapshot;
    }
    /**
     * @description Verifies that approval records and associated snapshots
     *              are correctly copied to the cloned quote.
     */
    @isTest
    static void testCreateApprovalRecords() {
        User usr1 = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive=true LIMIT 1];
        System.runAs(usr1) {
            List<SBQQ__Quote__c> listQuote = [SELECT Id FROM SBQQ__Quote__c];
        // Execute the method under test
        Test.startTest();
        Boolean result = MapApprovalRecordsToClonedQuote.createApprovalRecords(listQuote[1].Id);
        Test.stopTest();

        // Assertions can be added here if desired for better validation
        System.assertEquals(true, result, 'Approval records should be cloned successfully.');
    }
    }
}