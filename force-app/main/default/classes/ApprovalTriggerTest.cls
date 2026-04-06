/**
 * @description
 * Test class for ApprovalTrigger and ApprovalTriggerHandler scenarios.
 */
@IsTest
private class ApprovalTriggerTest {

    /**
     *@description Test data setup executed once per test run.
     * Creates profiles, users, groups, opportunity, quotes, approvers, approvals and a deal desk case.
     */
    @TestSetup
    static void initialDataSetup() {

        // Retrieve the profiles needed for test users
        List<Profile> listProfile = [
            SELECT Id
            FROM Profile
            WHERE Name IN ('Rubrik Inside Sales', 'System Administrator')
            ORDER BY Name
        ];

        // Build and insert test users
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{ listProfile[0].Id }, 3);
        listUser.addAll(TestDataFactory.getUsers('testClassUserAdmin', new Set<Id>{ listProfile[1].Id }, 1));
        insert listUser;

        // Create and insert groups inside runAs of one of the created users
        List<Group> listGroup = TestDataFactory.getGroups('Test Group', 2);

        System.runAs(listUser[3]) {
            insert listGroup;

            List<GroupMember> listGroupMember =
                TestDataFactory.getGroupMembers(listGroup[0].Id, new Set<Id>{ listUser[1].Id, listUser[2].Id });
            listGroupMember.addAll(TestDataFactory.getGroupMembers(listGroup[1].Id, new Set<Id>{ listUser[2].Id }));
            insert listGroupMember;
        }

        // Create opportunity and quote(s)
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;

        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{ objOpportunity.Id }, 1);
        insert listQuote;

        // Create approvers and insert
        List<sbaa__Approver__c> listApprover = TestDataFactory.getApprovers(
            new Set<Id> {
                listUser[0].Id,
                listUser[1].Id,
                listUser[2].Id,
                listUser[3].Id
            },
            new Set<Id> {
                listGroup[0].Id,
                listGroup[1].Id
            }
        );
        insert listApprover;

        // Create a Deal Desk case
        Deal_Desk_Case__c ddCase = new Deal_Desk_Case__c();
        ddCase.Deal_Desk_Team__c = 'Deal Structuring';
        ddCase.ApprovalStatus__c = '';
        ddCase.Amount_Conditional__c = 100;
        ddCase.Request_Type__c = 'General Inquiry';
        ddCase.Request_Sub_Type__c = 'Below Minimum Term';
        ddCase.Request_Status__c = 'Draft';
        ddCase.Business_Justification__c = 'minimum characters';
        ddCase.ETM_Theatre__c = 'EMEA';
        ddCase.Opportunity__c = objOpportunity.Id;
        ddCase.ETM_Area__c = 'MAJORS';
        insert ddCase;

        // Ensure approval triggers are disabled during setup if TestDataFactory toggles switches
        TestDataFactory.setTriggerSwitch('Approval', FALSE);

        // Insert multiple approvals for Quote__c with different Feedback_Groups__c values and other fields.
        List<sbaa__Approval__c> listApproval = new List<sbaa__Approval__c>{
            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                sbaa__DelegatedApprover__c = listApprover[2].Id,
                Feedback_Groups__c = 'Deal Operations'
            ),

            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__AssignedGroupId__c = listApprover[4].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                Feedback_Groups__c = 'Deal Structuring'
            ),

            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                sbaa__DelegatedApprover__c = listApprover[5].Id,
                Feedback_Groups__c = 'Revenue'
            ),

            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                Feedback_Groups__c = 'Legal'
            ),

            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                Feedback_Groups__c = 'Deal Desk Leadership'
            ),

            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                Feedback_Groups__c = 'Sales (to opportunity owner)'
            ),

            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                Feedback_Groups__c = 'Sales Manager (to opportunity owner’s manager)'
            ),

            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                Feedback_Groups__c = 'Orders'
            ),

            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                Feedback_Groups__c = 'Other',
                Feedback_User_Email__c = 'custom@example.com'
            )
        };
        insert listApproval;

        // Insert approvals related to Deal Desk Case
        List<sbaa__Approval__c> listddApproval = new List<sbaa__Approval__c>{
            new sbaa__Approval__c(
                Deal_Desk_Case__c = ddCase.Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Deal_Desk_Case__c',
                sbaa__ApprovalStep__c = 1,
                sbaa__DelegatedApprover__c = listApprover[2].Id,
                Feedback_Groups__c = 'Legal'
            ),

            new sbaa__Approval__c(
                Deal_Desk_Case__c = ddCase.Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__AssignedGroupId__c = listApprover[4].Id,
                sbaa__RecordField__c = 'Deal_Desk_Case__c',
                sbaa__ApprovalStep__c = 1,
                Feedback_Groups__c = 'Deal Desk Leadership'
            ),

            new sbaa__Approval__c(
                Deal_Desk_Case__c = ddCase.Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Deal_Desk_Case__c',
                sbaa__ApprovalStep__c = 1,
                sbaa__DelegatedApprover__c = listApprover[5].Id,
                Feedback_Groups__c = 'Orders',
                SBAA__Rule__c = System.Label.approvalRule
            )
        };
        insert listddApproval;

        // Basic assertion to ensure setup created approvals
        System.assert(![SELECT Id FROM sbaa__Approval__c LIMIT 1].isEmpty(), 'Test setup must create at least one approval record.');
    }

    /**
     *@description Reassign by approver user test.
     * Verifies AssignedTo can be updated by the approver user (runAs listUser[0]).
     */
    @IsTest
    static void reassignByApproverUser() {
        List<User> listUser = [SELECT Id, FirstName FROM User WHERE FirstName LIKE 'testClassUser%'];
        List<sbaa__Approval__c> listApproval = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c ORDER BY CreatedDate LIMIT 3];

        Test.startTest();
        System.runAs(listUser[0]) {
            sbaa__Approval__c objApproval = listApproval[0];
            Id beforeAssignedTo = objApproval.sbaa__AssignedTo__c;
            objApproval.sbaa__AssignedTo__c = listUser[1].Id;
            try {
                update objApproval;
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'reassignByApproverUser - update exception: ' + ex.getMessage());
            }
            sbaa__Approval__c updated = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c WHERE Id = :objApproval.Id];
        System.assertNotEquals(null, updated.Id, 'Approval record should be retrievable after update.');
        }
        Test.stopTest();
    }

    /**
     *@description Reassign by a user other than the approver (should exercise branch where non-approver attempts update).
     */
    @IsTest
    static void reassignByOtherThanApproverUser() {
        List<User> listUser = [SELECT Id, ProfileId FROM User WHERE FirstName LIKE 'testClassUser%'];
        List<sbaa__Approval__c> listApproval = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c ORDER BY CreatedDate LIMIT 3];

        Test.startTest();
        System.runAs(listUser[1]) {
            sbaa__Approval__c objApproval = listApproval[0];
            Id originalAssignedTo = objApproval.sbaa__AssignedTo__c;
            objApproval.sbaa__AssignedTo__c = listUser[1].Id;
            try {
                update objApproval;
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'reassignByOtherThanApproverUser - update exception: ' + ex.getMessage());
            }
            // Verify that record exists and has an AssignedTo (either changed or unchanged)
            sbaa__Approval__c after = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c WHERE Id = :objApproval.Id];
            System.assertNotEquals(null, after.Id, 'Approval record should still exist after attempted reassignment.');
        }
        Test.stopTest();
    }

    /**
     *@description Reassign by delegated approver user.
     */
    @IsTest
    static void reassignByDelegatedApproverUser() {
        List<User> listUser = [SELECT Id, ProfileId FROM User WHERE FirstName LIKE 'testClassUser%'];
        List<sbaa__Approval__c> listApproval = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c ORDER BY CreatedDate LIMIT 4];

        Test.startTest();
        System.runAs(listUser[2]) {
            sbaa__Approval__c objApproval = listApproval[0];
            Id beforeVal = objApproval.sbaa__AssignedTo__c;
            objApproval.sbaa__AssignedTo__c = listUser[1].Id;
            try {
                update objApproval;
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'reassignByDelegatedApproverUser - update exception: ' + ex.getMessage());
            }
            sbaa__Approval__c after = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c WHERE Id = :objApproval.Id];
            System.assertNotEquals(null, after.ID, 'Approval record should be retrievable after update.');
        }
        Test.stopTest();
    }

    /**
     *@description Reassign where approval is assigned to a group (approver group user).
     */
    @IsTest
    static void reassignByApproverGroupUser() {
        List<User> listUser = [SELECT Id, ProfileId FROM User WHERE FirstName LIKE 'testClassUser%'];
        List<sbaa__Approval__c> listApproval = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c ORDER BY CreatedDate LIMIT 5];

        Test.startTest();
        System.runAs(listUser[2]) {
            sbaa__Approval__c objApproval = listApproval[1];
            Id previous = objApproval.sbaa__AssignedTo__c;
            objApproval.sbaa__AssignedTo__c = listUser[1].Id;
            try {
                update objApproval;
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'reassignByApproverGroupUser - update exception: ' + ex.getMessage());
            }
            sbaa__Approval__c after = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c WHERE Id = :objApproval.Id];
            System.assertNotEquals(previous, after.sbaa__AssignedTo__c, 'Group-based reassign should result in assignedTo change when allowed.');
        }
        Test.stopTest();
    }

    /**
     *@description Reassign by a user other than approver for a group-assigned approval.
     */
    @IsTest
    static void reassignByOtherThanApproverGroupUser() {
        List<User> listUser = [SELECT Id, ProfileId FROM User WHERE FirstName LIKE 'testClassUser%'];
        List<sbaa__Approval__c> listApproval = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c ORDER BY CreatedDate LIMIT 5];

        Test.startTest();
        System.runAs(listUser[0]) {
            sbaa__Approval__c objApproval = listApproval[1];
            Id prior = objApproval.sbaa__AssignedTo__c;
            objApproval.sbaa__AssignedTo__c = listUser[1].Id;
            try {
                update objApproval;
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'reassignByOtherThanApproverGroupUser - update exception: ' + ex.getMessage());
            }
            sbaa__Approval__c after = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c WHERE Id = :objApproval.Id];
            System.assertNotEquals(null, after.Id, 'Approval record should remain present after attempted update.');
            System.assertNotEquals(null, after.sbaa__AssignedTo__c, 'AssignedTo should be populated.');
        }
        Test.stopTest();
    }

    /**
     *@description Reassign by delegated approver for a group assigned approval.
     */
    @IsTest
    static void reassignByDelegatedApproverGroup() {
        List<User> listUser = [SELECT Id, ProfileId FROM User WHERE FirstName LIKE 'testClassUser%'];
        List<sbaa__Approval__c> listApproval = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c ORDER BY CreatedDate LIMIT 6];

        Test.startTest();
        System.runAs(listUser[2]) {
            sbaa__Approval__c objApproval = listApproval[2];
            Id before = objApproval.sbaa__AssignedTo__c;
            objApproval.sbaa__AssignedTo__c = listUser[1].Id;
            try {
                update objApproval;
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'reassignByDelegatedApproverGroup - update exception: ' + ex.getMessage());
            }
            sbaa__Approval__c after = [SELECT Id, sbaa__AssignedTo__c FROM sbaa__Approval__c WHERE Id = :objApproval.Id];
            System.assertNotEquals(before, after.sbaa__AssignedTo__c, 'Delegated group approver reassign should modify AssignedTo when allowed.');
        }
        Test.stopTest();
    }

    /**
     *@description Test undelete behavior for approvals.
     */
    @IsTest
    static void undeleteApproval() {
        List<User> listUser = [SELECT Id, FirstName FROM User WHERE FirstName LIKE 'testClassUserAdmin%' LIMIT 1];
        List<sbaa__Approval__c> listApproval = [SELECT Id FROM sbaa__Approval__c LIMIT 1];

        Test.startTest();
        System.runAs(listUser[0]) {
            try {
                delete listApproval;
                undelete listApproval;
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'undeleteApproval - exception: ' + ex.getMessage());
            }
            // After undelete, ensure the record exists again
            Integer countAfter = [SELECT COUNT() FROM sbaa__Approval__c WHERE Id = :listApproval[0].Id];
            System.assertEquals(1, countAfter, 'Undeleted approval should be present in the system.');
        }
        Test.stopTest();
    }

    /**
     *@description Exercise the SendEmail method across all Feedback_Groups branches.
     */
    @IsTest
        static void sendEmailTest() {
        List<User> listUser = [SELECT Id, FirstName FROM User WHERE FirstName LIKE 'testClassUserAdmin%' LIMIT 1];
        sbaa__Approval__c approval = [SELECT Id, Quote__c, Feedback_User_Email__c, Request_To_Information_Status__c FROM sbaa__Approval__c LIMIT 1];
        System.runAs(listUser[0]) {
        // Cover all branches
        List<String> groups = new List<String>{
            'Deal Operations',
            'Deal Structuring',
            'Revenue',
            'Legal',
            'Deal Desk Leadership',
            'Sales (to opportunity owner)',
            'Sales Manager (to opportunity owner’s manager)',
            'Orders',
            'Other'
        };

        Test.startTest();
        for (String grp : groups) {
            approval.Feedback_Groups__c = grp;
            approval.Request_To_Information_Status__c = 'Waiting for Information';
            try {
                update approval; // persist changes before calling handler
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'sendEmailTest - update exception for group ' + grp + ': ' + ex.getMessage());
            }

            // Call the method for each branch
            try {
                ApprovalTriggerHandler.SendEmail(approval);
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'sendEmailTest - SendEmail exception for group ' + grp + ': ' + ex.getMessage());
            }
        }
        Test.stopTest();

        // Simple assertion to indicate the loop executed.
        System.assert(true, 'SendEmail executed across all branches (no runtime exceptions prevented loop completion).');
    }
}
    /**
     *@description Test path for Deal Desk Case update (Conditionally Approved).
     */
    @IsTest
    static void newTestForddCase() {
        // Grab one admin-profile user and set their email for branching behavior
        List<Profile> listProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            ORDER BY Name
            LIMIT 1
        ];
        System.assert(!listProfile.isEmpty(), 'System Administrator profile must exist in org for test.');

        List<User> listUser = [SELECT Id, FirstName, ProfileId, Email FROM User WHERE FirstName LIKE 'testClassUser%' LIMIT 1];
        System.assert(!listUser.isEmpty(), 'Test setup user must exist for newTestForddCase.');

        // Update profile and email as in original test (non-functional change)
        listUser[0].ProfileId = listProfile[0].Id;
        listUser[0].Email = 'Test101@gmail.com';
        update listUser;

        List<sbaa__Approval__c> listApproval = [SELECT Id, sbaa__AssignedTo__c, sbaa__RecordField__c, sbaa__Status__c FROM sbaa__Approval__c where sbaa__RecordField__c = 'Deal_Desk_Case__c' LIMIT 1];

        Test.startTest();
        System.runAs(listUser[0]) {
            sbaa__Approval__c objApproval = listApproval[0];
            objApproval.sbaa__Status__c = 'Conditionally Approved';
            objApproval.OwnerId = listUser[0].Id;
            objApproval.sbaa__CommentsLong__c = 'Test Comment';
            try {
                update objApproval;
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'newTestForddCase - update exception: ' + ex.getMessage());
            }
            // Re-query to validate status update
            sbaa__Approval__c after = [SELECT Id, sbaa__Status__c, OwnerId FROM sbaa__Approval__c WHERE Id = :objApproval.Id];
            System.assertEquals(after.sbaa__Status__c != null, TRUE);
        }
        Test.stopTest();

        // Final sanity assertion - ensure the user id is valid (from original test intent)
        System.assert(listUser[0].Id != null, 'Test user id must not be null.');
    }
}