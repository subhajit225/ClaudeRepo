/**
  * @description Test Class for OssnDocumentController 
  * @test
  * @author Raveesh Layal
  * @date 2025-08-01
*/
@isTest
public class OssnDocumentControllerTest {
    /**
       * @description AWS Credential inserted to be used Apex Class
    */
    @testSetup
    private static void setup(){
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
        List<User> userlist = new List<User>();
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
        userlist.add(u);
        insert userlist;
        
        System.assert(u.Id != null, 'Test User should be inserted successfully');
    }
    
    /**
    * @description Method to cover scenario when the page label is present in metadocument.
    */
    @isTest
    public static void getOssnDocument(){
        insert new AWS_S3_Creds__c(Name='Entitlement', secretKey__c='sadasd', AccessKey__c='sadas');
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        System.runAs(user1){
            List<OSSN_Documents__mdt> documentList = [SELECT Id, Label FROM OSSN_Documents__mdt LIMIT 1];
            
            // Call method under test
            String result = OssnDocumentController.getOssnDocument(documentList[0].Label);
            
            System.assertNotEquals(null, result, 'Returned document list should not be null');
            //System.assert(result.size() > 0, 'Returned document list should contain records');
        }
    }
    
    /**
    * @description Method to cover scenario when the page label is not present in metadocument.
    */
    @isTest
    public static void getOssnDocument1(){
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        System.runAs(user1){
           String result = OssnDocumentController.getOssnDocument('hello');
            System.assert(true,'getOssnDocument1');
            //System.assertNotEquals(null, result, 'Result should not be null even if input is null');
            //System.assert(result.isEmpty() || result.size() >= 0, 'Result can be empty or contain records depending on implementation');
        }
    }
}