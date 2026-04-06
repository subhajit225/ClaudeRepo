@isTest
public class CreateSuccessPlansQueueableTest {
    
    @testSetup
    static void setupTestData() {
        
        User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Entitlement_Create_and_Edit_Access' LIMIT 1];

            insert new PermissionSetAssignment(
                AssigneeId = sysAdmin.Id,
                PermissionSetId = ps.Id
            );

        System.runAs(sysAdmin){

            TriggerControl__c tc = new TriggerControl__c( Name = 'Entitlement', DisableTrigger__c = true );
            insert tc;

            Id supportRtId = Schema.SObjectType.Entitlement.getRecordTypeInfosByDeveloperName().get('Admin').getRecordTypeId();

            // Create test Accounts
            Account testAccount1 = new Account(Name = 'Test Account 1');
            insert testAccount1;

            Integer currentYear = Date.today().year();

            Success_Plan__c sp = new Success_Plan__c( Name = 'Test Class SP - '+(currentYear+1),  Account__c = testAccount1.Id );
            insert sp;
            Success_Plan__c sp1 = new Success_Plan__c( Name = 'QBR / RBR / EBC - 2020',  Account__c = testAccount1.Id );
            insert sp1;

            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
            prdHW.ProductCode = 'RBK-SVC-test-product';
            prdHW.Product_Subtype__c = 'GO';
            prdHW.SBQQSC__EntitlementConversion__c = 'One per unit';
            insert prdHW;

            // Set<Id> entitlementIds = new Set<Id>{testEntitlements[0].Id, testEntitlements[1].Id};

            
            // CreateSuccessPlansQueueable queueableJob = new CreateSuccessPlansQueueable(entitlementIds);
            // System.enqueueJob(queueableJob);
            // Create Entitlements with various start and end years
            List<Entitlement> testEntitlements = new List<Entitlement>{
                new Entitlement(
                    Name = 'RA-CEM-PA',
                    AccountId = testAccount1.Id,
                    Type = 'Manufacturing Entitlement',
                    RecordTypeId = supportRtId,
                    Product__c = prdHW.Id,
                    Quantity__c = 5,
                    StartDate = Date.newInstance(currentYear, 1, 1),
                    EndDate = Date.newInstance(currentYear+2, 12, 31)
                ),
                new Entitlement(
                    Name = 'RA-CES-PP',
                    AccountId = testAccount1.Id,
                    Type = 'Manufacturing Entitlement',
                    RecordTypeId = supportRtId,
                    Product__c = prdHW.Id,
                    Quantity__c = 5,
                    StartDate = Date.newInstance(currentYear, 1, 1),
                    EndDate = Date.newInstance(currentYear+3, 12, 31)
                )
            };
            Test.startTest();
            insert testEntitlements;
            Test.stopTest();
        }
    }

    @isTest
    static void testCreateSuccessPlansQueueable() {
        List<Entitlement> entils = [SELECT StartDate, EndDate, Id, Name, AccountId, Type FROM Entitlement];
        User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        System.runAs(sysAdmin){
            
            Test.startTest();
            CreateSuccessPlansForEntitlements.processEntitlementIdsForSucessPlan(new Set<Entitlement>{entils[0], entils[1]});
            Test.stopTest();
            // Each year creates 4 plans → 4 * 4 = 17 total plans + 1 renewal touch 
            List<Success_Plan__c> plans = [SELECT Id, Name, Account__c FROM Success_Plan__c WHERE (NOT Name like '%Test Class SP - %') AND (NOT Name like '%Existing SP%')];
            System.assertEquals(18, plans.size());
            
            for (Success_Plan__c plan : plans) {
                Boolean nameCheck = (plan.Name.containsIgnoreCase('QBR / RBR / EBC') || plan.Name.containsIgnoreCase('CEM Renewal Touch'));
                System.assert(nameCheck, 'Unexpected name format');
            }
        }
    }
}