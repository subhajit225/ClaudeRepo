@isTest
public class CS_FieldHistoryTrackingTest {
    @isTest
    static void testTrackFieldsHistory() {
        // Create a new UserRole
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;

        // Create a new User associated with the UserRole
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'testuser@testt.com',
            Username = 'testuser001010122@testt.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = r.Id,
            Employee_Time_Off__c = false,
            Coins__c = 1
        );
        insert u;

        // Create a copy of the User record before update
        User uOld = new User(Id = u.Id, Employee_Time_Off__c = u.Employee_Time_Off__c, Coins__c = u.Coins__c);

        // Update User record
        u.Employee_Time_Off__c = true;
        u.Coins__c = 3;
        update u;

        // Run test as the user 'u'
        System.runAs(u) {
            // Create a new Case
            Case cs = new Case(Subject = 'Test', Automated_time_off_case_routing__c = 'Disable', Priority = 'P2');
            insert cs;

            // Create a copy of the Case record before update
            Case csOld = new Case(Id = cs.Id, Automated_time_off_case_routing__c = cs.Automated_time_off_case_routing__c);

            // Update Case record
            cs.Automated_time_off_case_routing__c = 'Automatic';
            update cs;

            // Set up a mock for HTTP callouts
            Test.setMock(HttpCalloutMock.class, new FieldHistoryTrackingMock());

            // Create lists and maps for history tracking
            List<sObject> newSobjectRecords = new List<sObject>{cs};
            Map<Id, sObject> oldSobjectRecords = new Map<Id, sObject>{csOld.Id => csOld};
            List<sObject> newSobjectRecordsUser = new List<sObject>{u};
            Map<Id, sObject> oldSobjectRecordsUser = new Map<Id, sObject>{uOld.Id => uOld};

            // Call the method to track field history
            CS_FieldHistoryTracking.trackFieldsHistory(newSobjectRecords, oldSobjectRecords);
            CS_FieldHistoryTracking.trackFieldsHistory(newSobjectRecordsUser, oldSobjectRecordsUser);

            // Query for history tracking records
            List<History_Tracking_Config__mdt> historyTrackingRecords = [SELECT Lookup_API__c, Object_API_Name__c, Field_Name_API__c, New_Value_API__c, Old_Value_API__c 
                                                                         FROM History_Tracking_Config__mdt where
                                                                         DeveloperName = 'User'];
            
            // Assert statements
            System.assert(r.Id != null, 'UserRole insertion failed');
            System.assert(u.Id != null, 'User insertion failed');
            System.assert(u.Employee_Time_Off__c == true, 'User update failed');
            System.assert(u.Coins__c == 3, 'User update failed');
            System.assert(cs.Automated_time_off_case_routing__c == 'Automatic', 'Case update failed');
            System.assertEquals(1, historyTrackingRecords.size(), 'Expected 1 records in historyTrackingRecords');
        }
    }
    
    public class FieldHistoryTrackingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"DeveloperName": "Case", "Lookup_API__c": "Case__c", "Object_API_Name__c": "Case", "Field_Name_API__c": "Field_Name__c", "New_Value_API__c": "New_Value__c", "Old_Value_API__c": "Old_Value__c", "Is_Active__c": "True"},{"DeveloperName": "User", "Lookup_API__c": "Parent_Id__c", "Object_API_Name__c": "User", "Field_Name_API__c": "Field__c", "New_Value_API__c": "New_Value__c", "Old_Value_API__c": "Old_Value__c"}');
            res.setStatusCode(200);
            return res;
        }
    }
}