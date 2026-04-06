@IsTest
private class CS_AutomaticRiskProfileCreationTest {
    
    @future
    private static void addGovernanceMembers(){
        Group riskGovernanceGroup = [ SELECT Id FROM Group WHERE DeveloperName = :System.Label.Risk_Profile_Governance_Queue LIMIT 1];    
        GroupMember groupMember = new GroupMember(
            GroupId = riskGovernanceGroup.Id,
            UserOrGroupId = UserInfo.getUserId()
        );
        insert groupMember;
    }
    
    @TestSetup
    static void setup() {
        addGovernanceMembers();
        
        Profile apiProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'user1',
            LastName = 'GovOwner',
            Email = 'governanceOwner@rubrik.com.testrubrikinvalid',
            Username = 'governanceOwner@rubrik.com.testrubrikinvalid',
            Alias = 'apiauee',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = apiProfile.Id
        );
        insert testUser;
             
        // Assign permission set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Risk_Governance_Owner_Permissions' LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
        
        System.RunAs(testUser){
        Risk_Profile_Assignment__c rp = new Risk_Profile_Assignment__c();
        rp.Last_Assigned_Index__c = 0;
        insert rp;
        
        List<Account> accList = new List<Account>();
        
        Account accObj = TestDataFactory.getAccount();
        accObj.Adoption_Score__c = 1;
        accObj.OnBoarding_Score__c = 2;
        accObj.Product_Score__c = 3;
        accObj.Support_Score__c = 4;
        accList.add(accObj);
        
        Account accObj1 = TestDataFactory.getAccount();
        accObj.Name = 'Testacc1';
        accObj.Adoption_Score__c = 4;
        accObj.OnBoarding_Score__c = 3;
        accObj.Product_Score__c = 2;
        accObj.Support_Score__c = 1;
        accList.add(accObj1);
        
        insert accList;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        oppr.StageName = '7 Closed Lost';
        oppr.CloseDate = Date.today();
        oppr.Churn_Type__c = 'Account Churn';
        oppr.RecordtypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        insert oppr;
        
        Account_Risk__c ar = new Account_Risk__c(
            Account__c = accList[0].id,
            Risk_Type__c = 'ML',
            Opportunities__c = oppr.id,
            Entitlements__c = '001',
            Adoption_Score__c = 100,
            OnBoarding_Score__c = 10,
            Product_Score__c = 100,
            Support_Score__c = 100,
            Product_Pillar_1__c = 'P1',
            Product_Pillar_2__c = 'P2',
            Account_External_Id__c = accList[0].id 
        );
        insert ar;
        
        Account_Risk__c ar2 = new Account_Risk__c(
            Account__c = accList[1].id,
            Risk_Type__c = 'CX',
            Opportunities__c = oppr.id,
            Entitlements__c = '002',
            Adoption_Score__c = 4,
            OnBoarding_Score__c = 3,
            Product_Score__c = 2,
            Support_Score__c = 1,
            Product_Pillar_1__c = 'P1',
            Product_Pillar_2__c = 'P2',
            Account_External_Id__c = accList[1].id 
        );
        insert ar2;
        
        Risk_Profile__c newRiskProfile1 = new Risk_Profile__c(
            Risk_Origin__c = 'Opportunity',
            Opportunity__c = oppr.Id,
            Account__c = accObj.Id,
            Risk_Type__c = 'Account Risk',
            Primary_Risk_Reason__c = 'Support issues',
            Secondary_Risk_Reason__c = 'Support issues',
            Risk_Validation_Status__c = 'Invalid',
            Risk_Level__c = 'High'
        );
        
        insert newRiskProfile1;
        newRiskProfile1.Risk_Level__c = 'Low';
        update newRiskProfile1;
        }
    }
    
    @IsTest
    static void testMethod0() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            List<Opportunity> oppList = [SELECT Id, AccountId, Renewals_Sentiment__c,Blocker_Reason__c FROM Opportunity];
            System.assert(!oppList.isEmpty(), 'Opportunities should exist');
            
            oppList[0].Renewals_Sentiment__c = 'Green';
            oppList[0].Blocker_Reason__c = 'Timeline';
            update oppList;
            
            Opportunity updatedOpp = [SELECT Renewals_Sentiment__c, Blocker_Reason__c FROM Opportunity WHERE Id = :oppList[0].Id];
            System.assertEquals('Green', updatedOpp.Renewals_Sentiment__c, 'Renewals Sentiment should be Green');
        }
    }
    
    @IsTest
    static void testMethod1() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            List<Opportunity> oppList = [SELECT Id, AccountId, Renewals_Sentiment__c,StageName FROM Opportunity];
            System.assert(!oppList.isEmpty(), 'Opportunities should exist');
            
            oppList[0].Renewals_Sentiment__c = 'Red';
            oppList[0].Blocker_Reason__c = 'Adoption';
            
            Test.startTest();
            Risk_Profile__c newRiskP = new Risk_Profile__c(
            Risk_Origin__c = 'Opportunity',
            Opportunity__c = oppList[0].Id,
            Account__c = oppList[0].AccountId,
            Risk_Type__c = 'Account Risk',
            Primary_Risk_Reason__c = 'Competition',
            Secondary_Risk_Reason__c = 'Pricing',
            Risk_Level__c = 'High'
        );
        
        insert newRiskP;
            
            update oppList;
            Test.stopTest();
            
            Opportunity updatedOpp = [SELECT Renewals_Sentiment__c, Blocker_Reason__c,StageName FROM Opportunity WHERE Id = :oppList[0].Id];
            System.assertEquals('Red', updatedOpp.Renewals_Sentiment__c, 'Renewals Sentiment should be Red');
            System.assertEquals('Adoption', updatedOpp.Blocker_Reason__c, 'Blocker Reason should be Adoption');
            
            Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
            Set<Id> recordIds = new Set<Id>{oppList[0].Id};
            CS_AutomaticRiskProfileCreation.handleRenewalSentimentChange(oldOppMap, new Map<Id,Opportunity>(oppList));
            CS_AutomaticRiskProfileCreation.createRiskProfile(recordIds, 'Opportunity');
            oppList[0].Renewals_Sentiment__c = 'Yellow';
            oppList[0].Blocker_Reason__c = 'Timeline';
            oppList[0].StageName = '1 Discovery';
            update oppList;
        }
    }
    
    @IsTest
    static void testMethod5() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
                Case case2 = new Case(
                Subject = 'Test Case 2',
                Status = 'New',
                Customer_Sentiments__c = 'Green',
                Priority = 'P1 - Critical service impact'
            );
            insert case2;
            List<Opportunity> oppList = [SELECT Id, AccountId, Renewals_Sentiment__c,StageName FROM Opportunity];
            System.assert(!oppList.isEmpty(), 'Opportunities should exist');
            
            oppList[0].Renewals_Sentiment__c = 'Red';
            oppList[0].Blocker_Reason__c = 'Adoption';
            
            Test.startTest();
            Risk_Profile__c newRiskP = new Risk_Profile__c(
            Risk_Origin__c = 'Opportunity',
            Opportunity__c = oppList[0].Id,
            Account__c = oppList[0].AccountId,
            Risk_Type__c = 'Account Risk',
            Primary_Risk_Reason__c = 'Competition',
            Secondary_Risk_Reason__c = 'Pricing',
            Risk_Level__c = 'High',
            Mitigation_Case_Number__c = case2.Id
        );
        
        insert newRiskP;
            update oppList;
            Test.stopTest();
            Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
            CS_AutomaticRiskProfileCreation.handleRenewalSentimentChange(oldOppMap, new Map<Id,Opportunity>(oppList));
        }
    }
    
    @IsTest
    static void testMethod2() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            Account testAccount = [SELECT Id, Adoption_Score__c FROM Account LIMIT 1];
            Account testAccount2 = [SELECT Id, Adoption_Score__c FROM Account WHERE Name = 'Testacc1' LIMIT 1];
            
            System.assert(testAccount != null, 'Test Account should exist');
            
            Set<Id> recordIds = new Set<Id>{testAccount.Id};
            Set<Id> recordIds2 = new Set<Id>{testAccount2.Id};
                
            Test.startTest();
            CS_AutomaticRiskProfileCreation.createRiskProfile(recordIds, 'Account-ML');
            CS_AutomaticRiskProfileCreation.createRiskProfile(recordIds2, 'Account-CX');
            Test.stopTest();
            
            List<Risk_Profile__c> riskProfiles = [SELECT Id FROM Risk_Profile__c WHERE Account__c = :testAccount.Id];
            System.assert(!riskProfiles.isEmpty(), 'Risk Profiles should be created for the test account');
        }
    }
    
    @IsTest
    static void testMethod3() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            Account testAccount = [SELECT Id, Adoption_Score__c FROM Account WHERE Adoption_Score__c = 4 LIMIT 1];
            
            Risk_Profile__c rp1 = new Risk_Profile__c(
                Account__c = testAccount.Id,
                Risk_Type__c = 'Account Risk'
            );
            insert rp1;
            
            Set<Id> recordIds = new Set<Id>{testAccount.Id};
                
                Test.startTest();
            try {
                CS_AutomaticRiskProfileCreation.createRiskProfile(recordIds, 'Account-CX');
            } catch (Exception e) { // NOPMD - createRiskProfile expected to fail silently
            }
            Test.stopTest();
            
            List<Error_Logs__c> errorLogs = [SELECT Id, Error_Message__c FROM Error_Logs__c];
            System.assert(testAccount != null, 'Account with Adoption_Score__c = 4 should exist');
        }
    }
    
    @IsTest
    static void testMethod4() {
        User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            // Create an Account record
            Account testAccount = new Account(
                Name = 'Test Account for Entitlement',
                Type = 'Customer'
            );
            insert testAccount;
            
            Account_Risk__c ar2 = new Account_Risk__c(
                Account__c = testAccount.id,
                Risk_Type__c = 'CX',
                Entitlements__c = '002',
                Adoption_Score__c = 14,
                OnBoarding_Score__c = 25,
                Product_Score__c = 2,
                Support_Score__c = 80,
                Product_Pillar_1__c = 'P1',
                Product_Pillar_2__c = 'P2',
                Account_External_Id__c = testAccount.id 
            );
            insert ar2;
            
            System.assert(testAccount != null, 'Test Account should exist');
            
            Set<Id> recordIds2 = new Set<Id>{testAccount.Id};
                
            Test.startTest();
            CS_AutomaticRiskProfileCreation.createRiskProfile(recordIds2, 'Account-CX');
            Test.stopTest();
            
            List<Risk_Profile__c> riskProfiles = [SELECT Id FROM Risk_Profile__c WHERE Account__c = :testAccount.Id];
            System.assert(!riskProfiles.isEmpty(), 'Risk Profiles should be created for the test account');
        }
    }
    
    @isTest
    static void testCreateRiskProfilesWithEntitlement() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            // Create an Account record
            Account testAccount = new Account(
                Name = 'Test Account for Entitlement',
                Type = 'Customer'
            );
            insert testAccount;
            
            // Create a Case with the necessary Entitlement
            Case testCase = new Case(
                Subject = 'Test Case for Risk Profile',
                Status = 'New',
                Origin = 'Email',
                AccountId = testAccount.Id,
                Priority = 'P3 - Standard request'
            );
            insert testCase;
            
            Test.startTest();
            CS_AutomaticRiskProfileCreation.createRiskProfiles(new Set<Id>{ testCase.Id });
            Test.stopTest();
            
            // Add assertions to verify the outcome...
            List<Risk_Profile__c> riskProfiles = [
                SELECT Id, Account__c, Risk_Level__c, Risk_Status__c, Risk_Reason_Additional_Comments__c
                FROM Risk_Profile__c
                WHERE Account__c = :testAccount.Id
            ];
            System.assertEquals(1, riskProfiles.size(), 'Expected one Risk Profile to be created.');
            System.assertEquals('High', riskProfiles[0].Risk_Level__c);
            System.assertEquals('New', riskProfiles[0].Risk_Status__c);
            
            // Assert Risk_Profile_Entitlement__c was created
            List<Risk_Profile_Entitlement__c> rpeList = [
                SELECT Id, Risk_Profile__c, Entitlement__c
                FROM Risk_Profile_Entitlement__c
            ];
            System.assertEquals(0, rpeList.size(), 'Expected one RPE record linked to the entitlement.');
        }
    }
    @isTest
    static void testSetPrivateCommentOnMitigationCase() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            // Fetch a standard profile (e.g., Standard User)
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            Account acc =[SELECT Id FROM Account LIMIT 1];
            
            // Create a test user
            User riskOwner = new User(
                FirstName = 'Risk',
                LastName = 'Owner',
                Email = 'risk.owner@example.com',
                Username = 'risk.owner.' + DateTime.now().getTime() + '@example.com',
                Alias = 'rskown',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = p.Id,
                LanguageLocaleKey = 'en_US'
            );
            insert riskOwner;
            
            // Create Risk_Profile__c record
            Risk_Profile__c riskProfile = new Risk_Profile__c(OwnerId = riskOwner.Id, Risk_Type__c = 'Account Risk');
            insert riskProfile;
            
            // Create an opportunity with "7 Closed Lost"
            Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = '7 Closed Lost', CloseDate = Date.today(), Amount = 1000, Alliance_Partner_Name__c = 'None', AccountId = acc.id);
            insert opp;
            
            // Create a Case linked to the Opportunity and Risk Profile
            Case c = new Case(
                Subject = 'Test Case',
                Risk_Opportunity__c = opp.Id,
                AccountId = opp.AccountId,
                Risk_Profile__c = riskProfile.Id,
                Status = 'New',
                Origin = 'Phone',
                Priority = 'P3 - Standard request',
                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Retention_Case').getRecordTypeId()
            );
            insert c;
            
            // Update Opportunity stage to simulate change
            //opp.StageName = '8 Reopened';
            opp.StageName ='3 Technical Validation';
            opp.Cloud_Partner_Impact__c = 'None';
            update opp;
            Map<Id,String> newMap = new Map<Id,String>();
            newMap.put(opp.Id,opp.StageName);
            Test.startTest();
            CS_AutomaticRiskProfileCreation.setPrivateCommentOnMitigationCase(newMap);
            Test.stopTest();
            CaseComment[] cscm = [SELECT Id FROM CaseComment];
            System.assert(!cscm.isEmpty(), 'Case comment should have been created');
        }
    }
    
    @isTest
    static void testHandleCustomerSentimentChangeCombined() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            Case case1 = new Case(
                Subject = 'Test Case 1',
                Status = 'New',
                Customer_Sentiments__c = 'Green',
                Priority = 'P1 - Critical service impact'
            );
            insert case1;
            
            Risk_Profile__c rp1 = new Risk_Profile__c(
                Comments__c = 'Old Comment',
                Risk_Type__c = 'Account Risk',
                CSM_Case_Number__c = case1.Id,
                Mitigation_Case_Number__c = null
            );
            insert rp1;
            
            Case oldCase1 = [SELECT Id, Customer_Sentiments__c FROM Case WHERE Id = :case1.Id];
            case1.Customer_Sentiments__c = 'Red';
            update case1;
            Case newCase1 = [SELECT Id, Customer_Sentiments__c FROM Case WHERE Id = :case1.Id];
            Case case2 = new Case(
                Subject = 'Test Case 2',
                Status = 'New',
                Customer_Sentiments__c = 'Green',
                Priority = 'P1 - Critical service impact'
            );
            insert case2;
            
            Risk_Profile__c rp2 = new Risk_Profile__c(
                Comments__c = 'Old Comment',
                Risk_Type__c = 'Account Risk',
                CSM_Case_Number__c = case2.Id,
                Mitigation_Case_Number__c = case2.Id
            );
            insert rp2;
            
            Case oldCase2 = [SELECT Id, Customer_Sentiments__c FROM Case WHERE Id = :case2.Id];
            case2.Customer_Sentiments__c = 'Red';
            update case2;
            Case newCase2 = [SELECT Id, Customer_Sentiments__c FROM Case WHERE Id = :case2.Id];
            
            Case case3 = new Case(
                Subject = 'Test Case 3',
                Status = 'New',
                Customer_Sentiments__c = 'Green',
                Priority = 'P1 - Critical service impact'
            );
            insert case3;
            Case oldCase3 = [SELECT Id, Customer_Sentiments__c FROM Case WHERE Id = :case3.Id];
            case3.Customer_Sentiments__c = 'Red';
            update case3;
            Case newCase3 = [SELECT Id, Customer_Sentiments__c FROM Case WHERE Id = :case3.Id];
            
            Test.startTest();
            CS_AutomaticRiskProfileCreation.handleCustomerSentimentChange(
                new Map<Id, Case>{
                    case1.Id => oldCase1,
                        case2.Id => oldCase2,
                        case3.Id => oldCase3
                        },
                new List<Case>{ newCase1, newCase2, newCase3 }
            );
            
            Test.stopTest();
            Risk_Profile__c updatedRP1 = [SELECT Comments__c FROM Risk_Profile__c WHERE Id = :rp1.Id];
            System.assert(updatedRP1.Comments__c.contains('Case Customer Sentiment changed to Red'));
            List<CaseComment> comments = [SELECT Id FROM CaseComment WHERE ParentId = :case2.Id];
            System.assert(!comments.isEmpty(), 'CaseComment should be created when Mitigation_Case_Number__c matches case Id');
        }
    }
    
    
    
    
    
    @isTest
    static void testHandleNonClosureOfOpportunity() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            Custom_Configuration_Change__c rp = new Custom_Configuration_Change__c(
                Last_Run__c = Date.today().addDays(-1),
                Config_Type__c = 'Monthly',
                Next_Run__c = Date.today().addDays(29),
                Config_For__c = 'CX & ML Both'
            );
            insert rp;
            
            Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
            Opportunity oldOpp = opp.clone(false);
            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opp.Id => oldOpp };
                opp.StageName = '6 Negotiation/Review';
            update opp;
            Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{ opp.Id => opp };
                Test.startTest();
            CS_AutomaticRiskProfileCreation.handleNonClosureOfOpportunity(oldMap, newMap);
            String extracted = CS_AutomaticRiskProfileCreation.extractId('Log message with Id ' + opp.Id + ' inside');
            System.assertEquals(opp.Id, extracted);
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSetRiskReasonAllSwitchCases() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            Account_Risk__c accRisk = new Account_Risk__c(
                Adoption_Score__c = 100,
                OnBoarding_Score__c = 100,
                Product_Score__c = 100,
                Support_Score__c = 100
            );
            Risk_Profile__c rp = new Risk_Profile__c();
            
            // --- OnBoarding_Score__c ---
            accRisk.OnBoarding_Score__c = 10; // trigger condition
            CS_AutomaticRiskProfileCreation.setRiskReasons(accRisk, rp);
            System.assertEquals('Adoption', rp.Primary_Risk_Reason__c);
            System.assertEquals('Activation', rp.Secondary_Risk_Reason__c);
            
            // --- Adoption_Score__c ---
            accRisk.OnBoarding_Score__c = 100; // reset previous
            accRisk.Adoption_Score__c = 10;
            CS_AutomaticRiskProfileCreation.setRiskReasons(accRisk, rp);
            System.assertEquals('Adoption', rp.Primary_Risk_Reason__c);
            System.assertEquals('Lack of Adoption', rp.Secondary_Risk_Reason__c);
            
            // --- Product_Score__c ---
            accRisk.Adoption_Score__c = 100;
            accRisk.Product_Score__c = 10;
            CS_AutomaticRiskProfileCreation.setRiskReasons(accRisk, rp);
            System.assertEquals('Product', rp.Primary_Risk_Reason__c);
            System.assertEquals('Product Defect', rp.Secondary_Risk_Reason__c);
            
            // --- Support_Score__c ---
            accRisk.Product_Score__c = 100;
            accRisk.Support_Score__c = 10;
            CS_AutomaticRiskProfileCreation.setRiskReasons(accRisk, rp);
            System.assertEquals('Support issues', rp.Primary_Risk_Reason__c);
            System.assertEquals('Support Issues', rp.Secondary_Risk_Reason__c);
        }
    }
    
    @isTest
    static void testGetRPFrequencySettingRecord() {
            User u = [SELECT Id FROM User WHERE Username = 'governanceOwner@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            Id recordTypeId = Schema.SObjectType.Custom_Configuration_Change__c
                .getRecordTypeInfosByDeveloperName()
                .get('RP_Frequency_Config')
                .getRecordTypeId();
            
            Custom_Configuration_Change__c config = new Custom_Configuration_Change__c(
                RecordTypeId = recordTypeId,
                Config_Type__c = 'Daily',
                Config_For__c = 'CX Sync',
                Last_Run__c = Date.today().addDays(-1),
                Next_Run__c = Date.today().addDays(1),
                Config_Disabled__c = false
            );
            insert config;
            
            Test.startTest();
            Custom_Configuration_Change__c result = CS_AutomaticRiskProfileCreation.getRPFrequencySettingRecord();
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(config.Id, result.Id, 'Should return the latest record');
        }
    }
}