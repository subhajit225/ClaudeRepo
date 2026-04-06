@isTest
public class TestJsonQueuable {
  @isTest
  static void testExecuteWithValidInput() {
    System.runAs(new user(Id = UserInfo.getUserId())) {
      // Step 1: Create a test Account record
      Account testAccount = new Account(Name = 'Initial Name');
      insert testAccount;

      // Step 2: Create a JSON string to update the Account name
      Map<String, Object> jsonData = new Map<String, Object>{ 'sObjectType' => 'Account', 'Id' => testAccount.Id, 'fields' => new Map<String, Object>{ 'Name' => 'Updated Name' } };
      String jsonString = JSON.serialize(jsonData);

      // Step 3: Enqueue the JsonQueuable job
      Test.startTest();
      System.enqueueJob(new JsonQueuable(jsonString));
      Test.stopTest(); // This forces execution of the queueable job

      // Step 4: Query the updated Account
      Account updatedAccount = [SELECT Name FROM Account WHERE Id = :testAccount.Id];

      // Step 5: Assert the update occurred
      System.assertEquals('Updated Name', updatedAccount.Name);
    }
  }

  @isTest
  static void testExecuteWithMissingFields() {
    System.runAs(new user(Id = UserInfo.getUserId())) {
      // Step 1: Create a test Account record
      Account acc = new Account(Name = 'No Update');
      insert acc;

      // Step 2: Provide JSON with missing fields
      Map<String, Object> badData = new Map<String, Object>{
        'sObjectType' => 'Account',
        'Id' => acc.Id
        // 'fields' key is missing
      };
      String badJson = JSON.serialize(badData);

      // Step 3: Run the queueable
      Test.startTest();
      System.enqueueJob(new JsonQueuable(badJson));
      Test.stopTest();

      // Step 4: Ensure the record was not updated
      Account sameAccount = [SELECT Name FROM Account WHERE Id = :acc.Id];
      System.assertEquals('No Update', sameAccount.Name);
    }
  }
}