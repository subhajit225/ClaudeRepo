/**
 * @description Test class for StakeholderMapController
 */ 
@isTest
public class StakeholderMapControllerTest {

    /**
     * @description Test data setup
     */ 
    @TestSetUp
    static void initialDataSetup() {
        // Disable validation logic
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(
            Disable_Opportunity_Validation_Rules__c = true,
            Disable_Account_Validation_Rules__c = true
        );
        insert settingDisable;

        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Light Administrator'];
        List<User> listUser = TestDataFactory.getUsers('CVEUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;

        System.runAs(listUser[0]) {
            // Create a Permission Set
            PermissionSet ps = new PermissionSet(Label = 'TestPermissionSet', Name = 'TestPermissionSet');
            insert ps;
            
            // Assign the Custom Permission to the Permission Set
            SetupEntityAccess sea = new SetupEntityAccess(
                ParentId = ps.Id,
                SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Stakeholder_Persona_Access'][0].Id
            );
            insert sea;
            
            // Assign the Permission Set to the test user
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = listUser[0].Id,
                PermissionSetId = ps.Id
            );
            insert psa;
        }
        
        // Create Account
        Account acc = new Account(
            Name = 'Stakeholder Test Acc',
            RecordTypeId = Schema.SObjectType.Account
                .getRecordTypeInfosByName()
                .get('Partner/Distributor')
                .getRecordTypeId()
        );
        insert acc;

        // Create Opportunity just to simulate account activity
        Opportunity opp = new Opportunity(
            Name = 'StakeholderMap Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            AccountId = acc.Id,
            SBQQ__Renewal__c = true
        );
        insert opp;

        // Contacts for every bucket
        List<Contact> contacts = new List<Contact>{
            // CXO Stakeholders
            new Contact(LastName='CIO', AccountId=acc.Id,
                Key_CXO_Stakeholder_Title__c='Head of IT (CIO)', Email='cio@test.com'),
            new Contact(LastName='CISO', AccountId=acc.Id,
                Key_CXO_Stakeholder_Title__c='Head of Security (CISO)', Email='ciso@test.com'),
            new Contact(LastName='CTO', AccountId=acc.Id,
                Key_CXO_Stakeholder_Title__c='Head of Infrastructure (CTO)', Email='cto@test.com'),
            new Contact(LastName='DataHead', AccountId=acc.Id,
                Key_CXO_Stakeholder_Title__c='Head of Data', Email='data@test.com'),

            // Additional C-Suite
            new Contact(LastName='ChiefTech', AccountId=acc.Id,Title = 'CDO',
                Product_Persona__c='Chief Digital Officer', Email='chief@test.com'),

            // VP/Head
            new Contact(LastName='VPInfra', AccountId=acc.Id,Title = 'VP',
                Product_Persona__c='VP Infrastructure', Email='vp@test.com'),

            // Product Personas
            new Contact(LastName='InfraTech', AccountId=acc.Id,
                Product_Persona__c='Infrastructure Technology', Email='infra@test.com'),
            new Contact(LastName='TechArch', AccountId=acc.Id,
                Product_Persona__c='Technology Architecture', Email='arch@test.com'),
            new Contact(LastName='CloudEng', AccountId=acc.Id,
                Product_Persona__c='Cloud Engineering', Email='cloud@test.com'),
            new Contact(LastName='Sec', AccountId=acc.Id,
                Product_Persona__c='Security', Email='sec@test.com'),
            new Contact(LastName='AppOwner', AccountId=acc.Id,
                Product_Persona__c='App Owners', Email='app@test.com'),

            // Others
            new Contact(LastName='OtherContact', AccountId=acc.Id,
                Product_Persona__c='Random Persona', Email='other@test.com')
        };
        insert contacts;

        // Second account with no contacts for negative case
        Account emptyAcc = new Account(
            Name = 'Empty Account',
            RecordTypeId = Schema.SObjectType.Account
                .getRecordTypeInfosByName()
                .get('Partner/Distributor')
                .getRecordTypeId()
        );
        insert emptyAcc;
    }

    /**
     * @description test method for testGetCategorizedContacts
     */ 
    @isTest
    static void testGetCategorizedContactsAllBuckets() {
        
        User user = [SELECT Id FROM User WHERE Profile.Name = 'Rubrik Light Administrator' AND UserName LIKE '%CVEUser%' LIMIT 1];
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Stakeholder Test Acc' LIMIT 1];
        
        ResponseDTO res;
        Test.startTest();
        System.runAs(user){
            res = StakeholderMapController.getCategorizedContacts(acc.Id);
        }
        Test.stopTest();

        Map<String, List<Contact>> results = (Map<String, List<Contact>>)res.Data;
        System.assertNotEquals(null, res.Data);
        System.assertEquals(4, results.get('Key CXO Stakeholders').size());
        System.assertEquals(1, results.get('Additional C-Suite Personas').size());
        System.assertEquals(1, results.get('VP/Head Personas').size());
        System.assertEquals(1, results.get('Infrastructure Technology').size());
        System.assertEquals(1, results.get('Technology Architecture').size());
        System.assertEquals(1, results.get('Cloud Engineering').size());
        System.assertEquals(1, results.get('Security').size());
        System.assertEquals(1, results.get('App Owners').size());
        System.assertEquals(3, results.get('Others').size());
    }

    /**
     * @description test method for testGetCategorizedContacts
     */
    @isTest
    static void testGetCategorizedContactsNoContacts() {
        User user = [SELECT Id FROM User WHERE Profile.Name = 'Rubrik Light Administrator' AND UserName LIKE '%CVEUser%' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Empty Account' LIMIT 1];

        ResponseDTO res;
        Test.startTest();
        System.runAs(user){
            res = StakeholderMapController.getCategorizedContacts(acc.Id);
        }
        Test.stopTest();

        Map<String, List<Contact>> results = (Map<String, List<Contact>>)res.Data;
        System.assertNotEquals(null, results);
        for (String key : results.keySet()) {
            System.assertEquals(0, results.get(key).size(),
                'Expected no contacts for bucket ' + key);
        }
    }
}