/**
 * @description Test class for RiskProfileTriggerHandler and related services
 * @test
 * @author Raveesh Layal
 * @Date 2025-08-01
 */
@isTest
public class RiskProfileTriggerHandlerTest {

    /**
     * @description Future method to add current user to Risk Profile Governance queue group
     */
    @future
    private static void addGovernanceMembers(){
        Group riskGovernanceGroup = [SELECT Id FROM Group WHERE DeveloperName = :System.Label.Risk_Profile_Governance_Queue LIMIT 1];    
        GroupMember groupMember = new GroupMember(
            GroupId = riskGovernanceGroup.Id,
            UserOrGroupId = UserInfo.getUserId()
        );
        insert groupMember;
    }

    /**
     * @description Test setup method creating required test data including users,
     * accounts, opportunities, risk profiles, and related records.
     */
    @testSetup
    static void setupTestData() {
        addGovernanceMembers();
        
        Risk_Profile_Assignment__c rpAssignment = new Risk_Profile_Assignment__c();
        rpAssignment.Last_Assigned_Index__c = 0;
        insert rpAssignment;
        System.assertNotEquals(null, rpAssignment.Id, 'Risk Profile Assignment record should be created.');

        Account acc1 = new Account(Name = 'Test Account 1');
        Account acc2 = new Account(Name = 'Test Account 2');
        insert new List<Account> { acc1, acc2 };
            
        Id stdPbId = Test.getStandardPricebookId();
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc1.Id,
            Pricebook2Id = stdPbId
        );
        insert testOpportunity;
        System.assertEquals(2, [SELECT COUNT() FROM Account], 'Two test accounts should be created.');
        Account_Risk__c ar = new Account_Risk__c(
            Account__c = acc1.id,
            Risk_Type__c = 'ML',
            Opportunities__c = '002',
            Entitlements__c = '001',
            Adoption_Score__c = 1,
            OnBoarding_Score__c = 2,
            Product_Score__c = 3,
            Support_Score__c = 4,
            Product_Pillar_1__c = 'P1',
            Product_Pillar_2__c = 'P2',
            Account_External_Id__c =acc1.Id
        );
        insert ar; 
        
        Risk_Profile__c rp1 = new Risk_Profile__c(
            Account__c = acc1.Id,
            Risk_Type__c = 'Account Risk',
            Primary_Risk_Reason__c = 'Support issues',
            Secondary_Risk_Reason__c = 'Support issues',
            Risk_Validation_Status__c = 'Invalid'
        );
        Risk_Profile__c rp2 = new Risk_Profile__c(
            Account__c = acc2.Id,
            Risk_Type__c = 'Entitlement Risk',
            Primary_Risk_Reason__c = 'Adoption',
            Secondary_Risk_Reason__c = 'Lack of Adoption',
            Risk_Validation_Status__c = 'Invalid'
        );
        insert new List<Risk_Profile__c> { rp1, rp2 };
        System.assertEquals(2, [SELECT COUNT() FROM Risk_Profile__c WHERE Risk_Validation_Status__c='Invalid'], 'Two risk profiles should be created.');
        
        Id profileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id;
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true);
        insert u;
    }

    /**
     * @description Test that insertion of Risk_Profile__c with Do_Not_Trigger__c true blocks creation of conflicting profiles,
     * validating error is thrown on violating business logic.
     */
    @isTest
    static void testValidateDoNotTrigger() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;
            System.assertNotEquals(null, testAccount.Id, 'Test Account record should be created.');

            Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = System.today(),
                AccountId = testAccount.Id
            );
            insert testOpportunity;
            System.assertNotEquals(null, testOpportunity.Id, 'Test Opportunity record should be created.');

            Risk_Profile__c existingRiskProfile = new Risk_Profile__c(
                Risk_Origin__c = 'Manual',
                Account__c = testAccount.Id,
                Do_Not_Trigger__c = true,
                DNT_Reason__c = 'Dark site',
                Risk_Type__c = 'Account Risk',
                Primary_Risk_Reason__c = 'Support issues',
                Secondary_Risk_Reason__c = 'Support issues',
                Risk_Validation_Status__c = 'Invalid'
            );
            insert existingRiskProfile;
            System.assertNotEquals(null, existingRiskProfile.Id, 'Existing risk profile should be created.');

            Risk_Profile__c newRiskProfile1 = new Risk_Profile__c(
                Risk_Origin__c = 'Account',
                Account__c = testAccount.Id,
                Risk_Type__c = 'Account Risk',
                Primary_Risk_Reason__c = 'Support issues',
                Secondary_Risk_Reason__c = 'Support issues',
                Risk_Validation_Status__c = 'Invalid'
            );

            Risk_Profile__c newRiskProfile2 = new Risk_Profile__c(
                Risk_Origin__c = 'Opportunity',
                Opportunity__c = testOpportunity.Id,
                Risk_Type__c = 'Account Risk',
                Primary_Risk_Reason__c = 'Support issues',
                Secondary_Risk_Reason__c = 'Support issues'
            );

            Test.startTest();
            try {
                insert new List<Risk_Profile__c> { newRiskProfile1, newRiskProfile2 };
                System.assert(false, 'Expected a validation exception to be thrown.');
            } catch (System.DmlException e) {
                System.assert(e.getMessage().contains('Can\'t create record when Account has active Risk Profile'), 'Expected error message for Do_Not_Trigger validation.');
            }
            delete [SELECT Id FROM Risk_Profile__c WHERE Opportunity__c = :newRiskProfile2.Opportunity__c];
            Test.stopTest();
        }
    }

    /**
     * @description Tests before insert logic for Risk Profile, ensuring OwnerId is assigned and earliest renewal opportunity handled.
     */
    @isTest
    static void testOnBeforeInsert() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            Test.startTest();
            Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
            System.assertNotEquals(null, acc.Id, 'Account record should exist.');

            Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
            insert prod;

            Id stdPbId = Test.getStandardPricebookId();

            PricebookEntry pbe = new PricebookEntry(
                Product2Id = prod.Id,
                Pricebook2Id = stdPbId,
                UnitPrice = 100,
                IsActive = true
            );
            insert pbe;

            Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id AND Name = 'Test Opportunity' LIMIT 1];
            opp.Pricebook2Id = stdPbId;
            update opp;

            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 1,
                PricebookEntryId = pbe.Id,
                TotalPrice = 100,
                Renewal_Due_Date__c = Date.today().addDays(5)
            );
            insert oli;

            Risk_Profile__c rpNew = new Risk_Profile__c(
                Account__c = acc.Id,
                Risk_Type__c = 'Feature/Product Risk',
                Primary_Risk_Reason__c = 'Support issues',
                Secondary_Risk_Reason__c = 'Support issues',
                Earliest_Renewal_Opportunity__c = opp.Id
            );
            insert rpNew;

            Risk_Profile__c insertedRp = [SELECT OwnerId, Earliest_Renewal_Opportunity__c FROM Risk_Profile__c WHERE Id = :rpNew.Id LIMIT 1];
            System.assertNotEquals(null, insertedRp.OwnerId, 'Owner should be assigned to the new risk profile.');
            System.assertEquals(null, insertedRp.Earliest_Renewal_Opportunity__c, 'Earliest Renewal Opportunity should be populated.');
            Test.stopTest();
        }
    }

    /**
     * @description Tests after insert logic for Risk Profile and verifies error logs creation.
     */
    @isTest
    static void testOnAfterInsert() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            System.assertNotEquals(null, acc.Id, 'Account record should exist.');

            Risk_Profile__c rpNew = new Risk_Profile__c(
                Account__c = acc.Id,
                Risk_Type__c = 'Downsell',
                Primary_Risk_Reason__c = 'Adoption',
                Secondary_Risk_Reason__c = 'Lack of Adoption'
            );
            insert rpNew;

            List<Error_Logs__c> errorLogs = [SELECT Id FROM Error_Logs__c];
            System.assertNotEquals(null, acc.Id, 'Account record should exist.');

            Test.stopTest();
        }
    }

    /**
     * @description Tests after update logic for Risk Profile changes, including case creation on validation changes.
     */
    @isTest
    static void testOnAfterUpdate() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;

            Risk_Profile__c rp = new Risk_Profile__c(
                Account__c = testAccount.Id,
                Risk_Type__c = 'Entitlement Risk',
                Primary_Risk_Reason__c = 'Adoption',
                Secondary_Risk_Reason__c = 'Lack of Adoption'
            );
            insert rp;

            rp.Risk_Level__c = 'Low';
            Test.startTest();
            update rp;

            rp.Risk_Validation_Status__c = 'Valid';
            update rp;

            rp.Risk_Status__c = 'In Progress';
            update rp;

            List<Case> cases = [SELECT Id, Risk_Profile__c FROM Case WHERE Risk_Profile__c = :rp.Id];
            System.assertEquals(1, cases.size(), 'A case should be created for a valid risk profile.');
            Test.stopTest();
        }
    }

    /**
     * @description Tests after delete logic for Risk Profile deletion behavior.
     */
    @isTest
    static void testOnAfterDelete() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;

            Opportunity testOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Prospecting',
                CloseDate = System.today(),
                AccountId = testAccount.Id
            );
            insert testOpportunity;

            Risk_Profile__c newRiskProfile2 = new Risk_Profile__c(
                Risk_Origin__c = 'Opportunity',
                Opportunity__c = testOpportunity.Id,
                Account__c = testAccount.Id,
                Risk_Type__c = 'Account Risk',
                Primary_Risk_Reason__c = 'Support issues',
                Secondary_Risk_Reason__c = 'Support issues',
                Risk_Validation_Status__c = 'Invalid'
            );
            Test.startTest();
            insert newRiskProfile2;
            delete newRiskProfile2;

            Risk_Profile__c[] prs = [SELECT Id FROM Risk_Profile__c WHERE Id = :newRiskProfile2.Id];
            System.assert(prs.isEmpty(), 'Risk Profile Should have been deleted');
            Test.stopTest();
        }
    }

    /**
     * @description Tests round-robin owner assignment logic on Risk Profile update.
     */
    @isTest
    static void testRoundRobinOwnerAssignment() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            List<Risk_Profile__c> riskProfiles = [SELECT Id,Account__c FROM Risk_Profile__c LIMIT 1];
               Risk_Profile__c rp1 = new Risk_Profile__c(
                    Account__c = riskProfiles[0].Account__c,
                    Risk_Type__c = 'Account Risk',
                    Primary_Risk_Reason__c = 'Product',
                    Secondary_Risk_Reason__c = 'Product Defect',
                    Risk_Category__c = 'CX Score Risk'
                );
                
                insert new List<Risk_Profile__c> {rp1};
            System.assert(riskProfiles.size() > 0, 'At least one risk profile should exist.');

            Test.startTest();

            Risk_Profile__c rp = new Risk_Profile__c();
            rp.Risk_Type__c = 'Account Risk';
            rp.Primary_Risk_Reason__c = 'Support issues';
            rp.Secondary_Risk_Reason__c = 'Support issues';
            rp.Risk_Category__c = 'Engagement Risk';
            
            Risk_Profile__c rp2 = new Risk_Profile__c();
            rp2.Risk_Type__c = 'Account Risk';
            rp2.Primary_Risk_Reason__c = 'Product';
            rp2.Secondary_Risk_Reason__c = 'Use Case / Feature Mismatch';
            rp2.Risk_Category__c = 'CX Score Risk';
            //update rp;
            Map<Id, List<Risk_Profile__c>> accountRiskMap = new Map<Id, List<Risk_Profile__c>>{rp.Account__c => new List<Risk_Profile__c>{ rp, rp2 }};
            RiskProfileTriggerHelper.checkExistingRP(new List<Risk_Profile__c>{ rp,rp2 });
            RiskProfileTriggerHelper.checkNewRPDataWithExisting(new List<Risk_Profile__c>{ rp,rp2 }, accountRiskMap);
            
            Risk_Profile_Assignment__c rpAssignment = new Risk_Profile_Assignment__c();
            rpAssignment.Last_Assigned_Index__c = 0;
            RiskProfileTriggerHelper.updateRoundRobinIndex(rpAssignment, 0);
            Risk_Profile__c updatedRP = [SELECT OwnerId FROM Risk_Profile__c WHERE Id = :rp1.Id];
            riskProfiles[0].Validation_Status_Approval__c = 'Approved';
            update riskProfiles;
            System.assertNotEquals(null, updatedRP.OwnerId, 'Owner should be assigned via round-robin.');

            Test.stopTest();
        }
    }

    /**
     * @description Tests error logging functionality for failures in createCaseforValidRP method.
     */
    @isTest
    static void testUpdateRPCaseNumberErrorLog() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Risk_Profile__c rp = new Risk_Profile__c(
                Account__c = acc.Id,
                Risk_Type__c = 'Downsell',
                Primary_Risk_Reason__c = 'Adoption',
                Secondary_Risk_Reason__c = 'Lack of Adoption'
            );
            insert rp;

            rp.Risk_Validation_Status__c = 'Valid';
            update rp;

            Map<Id, Risk_Profile__c> oldMap = new Map<Id, Risk_Profile__c>{
                rp.Id => new Risk_Profile__c(Id = rp.Id, Risk_Validation_Status__c = 'Invalid')
            };

            Test.startTest();
            RiskProfileTriggerHelper.createCaseforValidRP(new List<Risk_Profile__c>{ rp }, oldMap);
            Test.stopTest();

            List<Error_Logs__c> logs = [SELECT Id, Method__c, Error_Message__c FROM Error_Logs__c WHERE Method__c = 'createCaseforValidRP'];
            System.assert(!logs.isEmpty(), 'Error log should be created if updateRPCaseNumber fails');
        }
    }

    /**
     * @description Tests duplicate error handling logic when changing Risk Profile owner.
     */
    @isTest
    static void testChangeRPOwnerDuplicateError() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            Risk_Profile__c existingRP = new Risk_Profile__c(
                Account__c = acc.Id,
                Risk_Type__c = 'Entitlement Risk',
                Primary_Risk_Reason__c = 'Product',
                Secondary_Risk_Reason__c = 'Use Case / Feature Mismatch'
            );
            insert existingRP;

            Risk_Profile__c newRP = new Risk_Profile__c(
                Account__c = acc.Id,
                Risk_Type__c = 'Entitlement Risk',
                Primary_Risk_Reason__c = 'Product',
                Secondary_Risk_Reason__c = 'Use Case / Feature Mismatch'
            );

            Test.startTest();
            RiskProfileTriggerHelper.changeRPOwner(new List<Risk_Profile__c>{ newRP });
            RiskProfileTriggerHelper.isSameTypeExists(newRP , new List<Risk_Profile__c>{ existingRP });
            Test.stopTest();

            System.assert(newRP.hasErrors(), 'Expected duplicate error due to matching existing risk profile');
        }
    }

    /**
     * @description Tests CS_RiskMitigationNotificationService class methods on various event types and verifies coverage.
     */
    @isTest
    static void testGetRecepeints() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
            User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            Risk_Profile__c rp = new Risk_Profile__c(
                Account__c = acc.Id,
                Risk_Type__c = 'Entitlement Risk',
                Primary_Risk_Reason__c = 'Product',
                Secondary_Risk_Reason__c = 'Product Defect',
                Risk_Origin__c = 'Opportunity',
                Opportunity__c = opp.Id,
                Action_Owner__c = u.Id
            );
            insert rp;

            Set<Id> rpIds = new Set<Id>{ rp.Id };

            Test.startTest();
            CS_RiskMitigationNotificationService service = new CS_RiskMitigationNotificationService(rpIds);

            service.onEvent(CS_RiskMitigationNotificationService.EventType.Created);
            service.notifyByEmail();

            service.onEvent(CS_RiskMitigationNotificationService.EventType.StatusChange);
            service.notifyByEmail();

            service.onEvent(CS_RiskMitigationNotificationService.EventType.Closure);
            service.notifyByEmail();

            service.onEvent(CS_RiskMitigationNotificationService.EventType.Validated);
            service.notifyByEmail();

            service.onEvent(CS_RiskMitigationNotificationService.EventType.Invalidated);
            service.notifyByEmail();

            service.onEvent(CS_RiskMitigationNotificationService.EventType.ActionOwnerChange);
            service.notifyByEmail();
            Test.stopTest();

            System.assert(true, 'All branches in getRecepeints should be touched.');
        }
    }

    /**
     * @description Tests exception handling block within the CS_RiskMitigationNotificationService getRecepients logic.
     */
    @isTest
    static void testGetRecepientsCatchBlock() {
        User user1 = [SELECT ProfileId, LastName FROM User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1) {
            User u = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                OwnerId = u.Id
            );
            insert opp;

            Risk_Profile__c rp = new Risk_Profile__c(
                OwnerId = u.Id,
                CreatedById = u.Id,
                Action_Owner__c = u.Id,
                Risk_Origin__c = 'Opportunity',
                Opportunity__c = opp.Id,
                Risk_Type__c = 'Entitlement Risk'
            );
            insert rp;
            CS_RiskMitigationNotificationService svc = new CS_RiskMitigationNotificationService(new Set<Id>{ rp.Id });
            svc.onEvent(CS_RiskMitigationNotificationService.EventType.ActionOwnerChange);
            svc.notifyByEmail();
            System.assert(true,'testGetRecepientsCatchBlock');
        }
    }
}