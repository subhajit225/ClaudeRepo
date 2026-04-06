@isTest
public class ClusterMainTriggerTest {

    @testsetup
    static void setupmethod(){
        Account acc1 = new Account(Name = 'Test Account 1', Approved_software_program__c = 'Approved CDM 8.1 extension (28-FEB-2025)');
        Account acc2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{acc1, acc2};
        Contact createCon = new Contact(AccountId = acc2.Id,FirstName='test',LastName='TestContact01',Phone = '8971371780');
        Insert createCon;

        Opportunity opp = new Opportunity(AccountId = acc2.Id,Name = 'Test01',StageName = '1 Discovery',CloseDate = Date.today()+1);
        Insert opp;  
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = opp.Id;
        ocr.Role = 'Click-Thru Contact';
        ocr.ispRimary = true;
        ocr.ContactId = createCon.id;
        insert ocr; 

        Release_Version__c releaseVersion = new Release_Version__c(Name = '9.1.1-p1-27720', End_Of_Support_Date__c = Date.today().addMonths(6));
        insert releaseVersion;
        Releases__c release = new Releases__c(Version__c = '9.1.1-p1-27720', Release_Version__c = releaseVersion.Id);
        insert release;

        insert new TriggerControl__c(Name='Cluster');
        Cluster__c clus = new Cluster__c();
        clus.Name= 'test';
        clus.uuid__c= 'test';
        clus.software_version__c = '4.0';
        clus.Snooze_Alerts_Until__c = date.today();
        clus.Reason_for_alerts_snooze__c = 'Snoozing Proactive Alerts for EOS';
        clus.Email_Sent_for_80_Consumption__c = false;
        clus.Account__c = acc1.Id;
        insert clus;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'Rubrik System User' AND alias = 'oauto' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            clus.software_version__c = '5.0';
            clus.Enable_Email_Alert__c = true;
            clus.Email_Sent_for_80_Consumption__c = true;
            clus.Account__c = acc2.Id;
            update clus;
        }

        System.assertEquals('Sales', [select id, LeadSource from Contact where id =: createCon.Id].LeadSource);
    }

    static testmethod void softwareVersionTest(){
        Cluster__c objCls = [SELECT Id, Snooze_Alerts_Until__c, Reason_for_alerts_snooze__c, software_version__c
                                FROM Cluster__c
                                WHERE Name= 'test' Limit 1];
        objCls.software_version__c = '9.0';
        UPDATE objCls;
        Cluster__c objResCls = [SELECT Id, Snooze_Alerts_Until__c, Reason_for_alerts_snooze__c, software_version__c
                                FROM Cluster__c
                                WHERE Id =: objCls.Id Limit 1];
        System.assertEquals(null,objResCls.Snooze_Alerts_Until__c);
        System.assertEquals(null,objResCls.Reason_for_alerts_snooze__c);
    }

    // Supported Version
    @isTest
    static void testClsuterSftVeersionChange() {
        // Retrieve test data
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];

        Release_Version__c rv = [SELECT Id, End_Of_Support_Date__c FROM Release_Version__c WHERE Name = '9.1.1-p1-27720' LIMIT 1];

        Releases__c release = new Releases__c(Version__c = '8.1.3-p10-25441', Release_Version__c = rv.Id);
        insert release;

        // Create initial Cluster records
        Cluster__c cluster1 = new Cluster__c(UUID__c = 'Cluster 1', Name = 'Cluster 1', account__c = acc1.Id, Software_Version__c = '9.1.1-p1-27720');
        insert cluster1;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            cluster1.Software_Version__c = '8.1.3-p10-25441';
            UPDATE cluster1;
            Test.stopTest();
        }

        System.assertEquals('Supported CDM software version', [SELECT CDM_End_of_Support_Status__c FROM Cluster__c WHERE UUID__c = 'Cluster 1' Limit 1].CDM_End_of_Support_Status__c);
    }

    // UnSupported Version
    @isTest
    static void testClsuterSftVeersionChange1() {
        // Retrieve test data
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];

        Release_Version__c rv = [SELECT Id, End_Of_Support_Date__c FROM Release_Version__c WHERE Name = '9.1.1-p1-27720' LIMIT 1];
        rv.End_Of_Support_Date__c = Date.today().addDays(-5);
        UPDATE rv;
        Releases__c release = new Releases__c(Version__c = '8.1.3-p10-25441', Release_Version__c = rv.Id);
        insert release;

        // Create initial Cluster records
        Cluster__c cluster1 = new Cluster__c(UUID__c = 'Cluster 1', Name = 'Cluster 1', account__c = acc1.Id, Software_Version__c = '9.1.1-p1-27720');
        insert cluster1;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            cluster1.Software_Version__c = '8.1.3-p10-25441';
            UPDATE cluster1;
            Test.stopTest();
        }

        System.assertEquals('Unsupported CDM software version', [SELECT CDM_End_of_Support_Status__c FROM Cluster__c WHERE UUID__c = 'Cluster 1' Limit 1].CDM_End_of_Support_Status__c);
    }

    // When Approved_software_program__c = 'Approved CDM 8.1 extension (28-FEB-2025)'
    @isTest
    static void testClsuterSftVeersionChange2() {
        // Retrieve test data
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        Release_Version__c rv = [SELECT Id, End_Of_Support_Date__c FROM Release_Version__c WHERE Name = '9.1.1-p1-27720' LIMIT 1];
        rv.End_Of_Support_Date__c = Date.today().addDays(-5);
        UPDATE rv;
        Releases__c release = new Releases__c(Version__c = '8.1.3-p10-25441', Release_Version__c = rv.Id);
        insert release;

        // Create initial Cluster records
        Cluster__c cluster1 = new Cluster__c(UUID__c = 'Cluster 1', Name = 'Cluster 1', account__c = acc1.Id, Software_Version__c = '9.1.1-p1-27720');
        insert cluster1;
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            cluster1.Software_Version__c = '8.1.3-p10-25441';
            UPDATE cluster1;
            Test.stopTest();
        }
        
        String actualValue = [SELECT CDM_End_of_Support_Status__c FROM Cluster__c WHERE UUID__c = 'Cluster 1' Limit 1].CDM_End_of_Support_Status__c;
        System.assert(actualValue.contains('Approved CDM 8.1 extension'),  'Expected value not found in the field.');
        cluster1.Software_Version__c = '';
            UPDATE cluster1;
    }
}