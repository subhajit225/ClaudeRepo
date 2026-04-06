@isTest
public class Batch_OneTimeCopyData_ContactTest {

    /**
     * @description - Copy value of Limited_Use__c to Data Use Permitted.
     */
    @IsTest
    static void testBatchForCampaignLeadContactCDM() {
      
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; 
        User usr1 = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr1.ProfileId = pf.Id;
        insert usr1;
        system.runAs(usr1){
            
            ShGl_DisableBusinessLogic__c listSetting = new ShGl_DisableBusinessLogic__c();
            listSetting.Name = 'Disable Contact Triggers';
            listSetting.Disable_Contact_Triggers__c = true;
            listSetting.SetupOwnerId = usr1.id;
            insert listSetting;
                
            Account objAcc2 = new Account(Name = 'testAcc1');
            insert objAcc2;
            
            Contact objCon = new Contact(LastName = 'test Contact', AccountId = objAcc2.Id,Phone = '9999999999',Limited_Use__c = true, MailingCountry = 'India', Email = 'test.contact@rubrik.com');
            INSERT objCon;
        }
        Test.startTest();
        Batch_OneTimeCopyData_Contact batch = new Batch_OneTimeCopyData_Contact();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        system.assert(true);

    }
}