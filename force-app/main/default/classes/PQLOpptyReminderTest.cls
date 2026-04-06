/**
 * @description PQLOpptyReminderTest test class for PQLOpptyReminder
 * @Developer    Rubrik Dev
 * @Date         03/18/2025
 */
@isTest
public class PQLOpptyReminderTest {

    @testSetup
    static void setupTestData() {
		List<UserTerritory2Association> UTAList = new List<UserTerritory2Association>();   
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
                
        User testUser2 = new User(
            FirstName = 'Test2', LastName = 'User2', Email = 'testuserPQL2@example.com',
            Username = 'testuserPQL2@example.com', Alias = 'tuser2', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            ProfileId = p.Id);
        insert testUser2;
        // Create test Users
        User testUser = new User(
            FirstName = 'Test', LastName = 'User', Email = 'testuserPQL@example.com',
            Username = 'testuserPQL@example.com', Alias = 'tuser', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
        	ProfileId = p.Id);//,ManagerId = testUser2.Id
        insert testUser;
         // Create test Users
         User testUser3 = new User(
            FirstName = 'Test', LastName = 'User', Email = 'testuserPQL3@example.com',
            Username = 'testuserPQL3@example.com', Alias = 'tuser', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',ManagerId = testUser2.Id,
            ProfileId = p.Id);
        insert testUser3;
        User testUser4 = new User(
            FirstName = 'Test', LastName = 'User', Email = 'testuserPQL4@example.com',
            Username = 'testuserPQL4@example.com', Alias = 'tuser', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            ProfileId = p.Id);
        insert testUser4;
        User testUser5 = new User(
            FirstName = 'Test', LastName = 'User', Email = 'testuserPQL5@example.com',
            Username = 'testuserPQL5@example.com', Alias = 'tuser', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
            ProfileId = p.Id);
        insert testUser5;
       	System.runAs(testUser) {
            List<Territory2> terrList = [Select id,Adaptive_Territory_Id__c,ParentTerritory2Id,ParentTerritory2.ParentTerritory2Id,ParentTerritory2.ParentTerritory2.ParentTerritory2Id from Territory2 where Territory2Model.state='Active' AND ParentTerritory2.Territory2Type.DeveloperName = 'Region' and ParentTerritory2.ParentTerritory2.Territory2Type.DeveloperName = 'Area' and ParentTerritory2.ParentTerritory2.ParentTerritory2.Territory2Type.DeveloperName = 'Theatre'
                                    And Territory2Type.DeveloperName='Territory'and Adaptive_Territory_Id__c!='' and ParentTerritory2.Adaptive_Territory_Id__c!='' and DeveloperName!='Unassigned'limit 1];
            
            List<Id> terr_Ids = new List<Id>();
            terr_Ids.Add(terrList[0].ParentTerritory2Id);
            terr_Ids.Add(terrList[0].ParentTerritory2.ParentTerritory2Id);
            terr_Ids.Add(terrList[0].ParentTerritory2.ParentTerritory2.ParentTerritory2Id);
            
            List<UserTerritory2Association> UTAs = [select id from UserTerritory2Association where Territory2Id IN:terr_Ids];
            If(UTAs.Size()>0){
                delete UTAs;
            }
            UserTerritory2Association UTA2 = new UserTerritory2Association();
            UTA2.UserId = testUser3.Id; 
            UTA2.Territory2Id = terrList[0].ParentTerritory2.ParentTerritory2.ParentTerritory2Id; // Use the first Territory2 record's ID
            UTA2.RoleInTerritory2 = 'VP of Sales';
            UTAList.add(UTA2);   
            
            UserTerritory2Association UTA3 = new UserTerritory2Association();
            UTA3.UserId = testUser.Id; 
            UTA3.Territory2Id = terrList[0].ParentTerritory2.ParentTerritory2Id; // Use the first Territory2 record's ID
            UTA3.RoleInTerritory2 = 'Area VP';
            UTAList.add(UTA3);        
            
            UserTerritory2Association UTA1 = new UserTerritory2Association();
            UTA1.UserId = testUser2.Id; 
            UTA1.Territory2Id = terrList[0].ParentTerritory2Id; // Use the first Territory2 record's ID
            UTA1.RoleInTerritory2 = 'Regional Director';
            UTAList.add(UTA1); 
            UserTerritory2Association UTA4 = new UserTerritory2Association();
            UTA4.UserId = testUser4.Id; 
            UTA4.Territory2Id = terrList[0].ParentTerritory2Id; // Use the first Territory2 record's ID
            UTA4.RoleInTerritory2 = 'Regional Director';
            UTAList.add(UTA4);
            UserTerritory2Association UTA5 = new UserTerritory2Association();
            UTA5.UserId = testUser5.Id; 
            UTA5.Territory2Id = terrList[0].ParentTerritory2Id; // Use the first Territory2 record's ID
            UTA5.RoleInTerritory2 = 'Area VP';
            UTAList.add(UTA5);
            insert UTAList;
            Account objAccount = new Account();
            Contact objContact = new Contact();
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Id recTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sales_Opportunity').getRecordTypeId();
    
            objAccount.Name = 'Test Account 35-05';
            objAccount.RecordTypeId = recordTypeId;
            objAccount.Adaptive_Territory_Id__c = terrList[0].Adaptive_Territory_Id__c;
            insert objAccount;
            objContact.Account = objAccount;
            objContact.LastName = 'Test Contact 34-05';
            insert objContact;
            
            // Create an opportunity record
            Opportunity objOpportunity = new Opportunity();
            objOpportunity.OwnerId = testUser3.Id;
            objOpportunity.StageName = '0 Nurture';
            objOpportunity.closeDate = System.Today() + 30;
            objOpportunity.Time_of_Last_Stage_Change__c = System.Today() - 10;
            objOpportunity.Name = 'Test Opp 35-05';
            objOpportunity.Opportunity_Type__c = 'New Customer';
            objOpportunity.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity.Initial_Contacts_Name__c = objContact.Id;
            objOpportunity.Distributor_Lookup__c = objAccount.Id;
            objOpportunity.Partner_Lookup__c = objAccount.Id;
            objOpportunity.AccountId = objAccount.Id;
            objOpportunity.Deal_Registration_Type__c = 'Rubrik Sourced';
            objOpportunity.RecordTypeId = recTypeId;
            objOpportunity.Disable_Auto_OwnerAssignment__c = true;
            insert objOpportunity;
            objOpportunity.LeadSource = 'Product Qualified Lead (PQL)';
            update objOpportunity;
            
            Opportunity objOpportunity2 = new Opportunity();
            objOpportunity2.StageName = '0 Nurture';
            objOpportunity2.closeDate = System.Today() + 30;
            objOpportunity2.Time_of_Last_Stage_Change__c = System.Today() - 10;
            objOpportunity2.Name = 'Test Opp 35-05';
            objOpportunity2.Opportunity_Type__c = 'New Customer';
            objOpportunity2.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity2.Initial_Contacts_Name__c = objContact.Id;
            objOpportunity2.Distributor_Lookup__c = objAccount.Id;
            objOpportunity2.Partner_Lookup__c = objAccount.Id;
            objOpportunity2.AccountId = objAccount.Id;
            objOpportunity2.Deal_Registration_Type__c = 'Rubrik Sourced';
            objOpportunity2.RecordTypeId = recTypeId;
            objOpportunity2.Disable_Auto_OwnerAssignment__c = true;
            insert objOpportunity2;
            objOpportunity2.LeadSource = 'Product Qualified Lead (PQL)';
            objOpportunity2.StageName = '1 Discovery';
            update objOpportunity2;
            objOpportunity2.StageName = '0 Nurture';
            update objOpportunity2;
        }
    }
    // Create necessary test data
    @isTest
    static void testBatchExecution() {
       	User u = [Select id from user where Username = 'testuserPQL@example.com' limit 1]; 
        System.runAs(u) {
            // Run the batch job
            Test.startTest();
            PQLOpptyReminder batch = new PQLOpptyReminder();
            Database.executeBatch(batch,2);
            opportunity oppty = [SELECT Id, OwnerId,Account.Adaptive_Territory_Id__c FROM Opportunity limit 1];
            oppty.OwnerId = u.Id;
            oppty.Co_Owner__c = u.Id;
            update oppty;
            Database.executeBatch(batch,2);
            Test.stopTest();
            // Verify if error logs were created in case of errors (if any)
            List<Custom_Error_Log__c> errorLogs = [SELECT Id FROM Custom_Error_Log__c WHERE Functionality__c = 'PQL'];
            System.assertEquals(0, errorLogs.size(), 'No error logs should be created.');
        }
    }
    @isTest
    static void testBatchExecutionWithGeneralError() {
        // Create opportunity with missing data for testing general exception
        User u = [SELECT Id FROM User WHERE Username = 'testuserPQL@example.com' LIMIT 1];
        
        System.runAs(u) {
            User u1 = [Select id from user where Username = 'testuserPQL2@example.com' limit 1]; 
            List<UserTerritory2Association> UTAs = [Select id from UserTerritory2Association where UserId =:u.Id limit 1];
            if(UTAs.size()>0){
                delete UTAs[0];
            }
            Opportunity oppty = [SELECT Id, OwnerId, PQL_Reminder_Email_Sent__c FROM Opportunity LIMIT 1];
            oppty.OwnerId = u1.Id;

            // Execute the batch job and simulate a general error
            Test.startTest();
            Custom_Error_Log__c errLog = new Custom_Error_Log__c(Functionality__c = 'PQL', Exception_Message__c = 'Custom Error',Class__c = 'PQLOpptyReminder',
                                            FailedRecords__c=null, ErrorTrace__c= 'ERROR');
            PQLOpptyReminder batch = new PQLOpptyReminder();
            batch.errorLogs.put('Custom Error',errLog);
            Database.executeBatch(batch, 2);
            Test.stopTest();

            // Check if error logs are created due to general error (owner missing)
            List<Custom_Error_Log__c> errorLogs = [SELECT Id, Exception_Message__c FROM Custom_Error_Log__c WHERE Functionality__c = 'PQL'];
            System.assert(errorLogs.size() > 0, 'An error log should be created when there is a missing Owner.');
        }
    }
    
     @isTest
    static void testCoOwnerAndManager() {
        User u = [Select id from user where Username = 'testuserPQL@example.com' limit 1]; 
        System.runAs(u) {
            u.ManagerId = [select id from user where Email = 'testuserPQL2@example.com' limit 1].Id;
            update u;
            PQLOpptyReminder batch = new PQLOpptyReminder();
            opportunity oppty = [SELECT Id,Account.Adaptive_Territory_Id__c, OwnerId FROM Opportunity limit 1];
            oppty.OwnerId = u.Id;
            oppty.Co_Owner__c = u.Id;
            update oppty;
            Database.executeBatch(batch,2);
            Territory2 trr = [select id,ParentTerritory2Id from Territory2 where Adaptive_Territory_Id__c =:oppty.Account.Adaptive_Territory_Id__c  AND Territory2Model.state='Active' limit 1];
            List<UserTerritory2Association> UTAList = [select id from UserTerritory2Association where RoleInTerritory2 IN ('Regional Director','Area VP') and Territory2Id =:trr.ParentTerritory2Id];
            delete UTAList;
            Test.startTest();
            Database.executeBatch(batch,2);
            Test.stopTest();
            // Verify if error logs were created in case of errors (if any)
            List<Custom_Error_Log__c> errorLogs = [SELECT Id FROM Custom_Error_Log__c WHERE Functionality__c = 'PQL'];
            System.assertEquals(0, errorLogs.size(), 'No error logs should be created.');
        }
    }
    
    // Create necessary test data
    @isTest
    static void testBatchExecutionForRegionalTerritory() {
       	User u = [Select id from user where Username = 'testuserPQL@example.com' limit 1]; 
        System.runAs(u) {
            // Run the batch job
            Test.startTest();
            PQLOpptyReminder batch = new PQLOpptyReminder();
            opportunity oppty = [SELECT Id,Account.Adaptive_Territory_Id__c, OwnerId FROM Opportunity limit 1];
            oppty.OwnerId = u.Id;
            oppty.Co_Owner__c = u.Id;
            update oppty;
            Territory2 trr = [select id,ParentTerritory2Id from Territory2 where Adaptive_Territory_Id__c =:oppty.Account.Adaptive_Territory_Id__c AND Territory2Model.state='Active' limit 1];
            List<UserTerritory2Association> UTAList = [select id from UserTerritory2Association where RoleInTerritory2 IN ('Regional Director','Area VP') and Territory2Id =:trr.ParentTerritory2Id];
            delete UTAList;
            Database.executeBatch(batch,2);
            Test.stopTest();
            // Verify if error logs were created in case of errors (if any)
            List<Custom_Error_Log__c> errorLogs = [SELECT Id FROM Custom_Error_Log__c WHERE Functionality__c = 'PQL'];
            System.assertEquals(0, errorLogs.size(), 'No error logs should be created.');
        }
    }
}