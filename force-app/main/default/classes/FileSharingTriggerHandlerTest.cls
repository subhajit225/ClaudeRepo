@isTest
public class FileSharingTriggerHandlerTest {
	@isTest static void testMethodFileApexSharing() {
        
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        Account accRec = new Account();
        system.runas(u){
            accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            List<Contact> lstContact = ShGl_TestFactory.testMethod_PartnerContact(1,accRec);
            lstUserRec = ShGl_TestFactory.testMethod_PartnerUser(1,lstContact);
        }
		test.startTest();
        File_Sharing__c fs = new File_Sharing__c(Active__c=true,AccountIds__c=accRec.Id);
        insert fs;
        fs.AccountIds__c = '';
        update fs;
        FileSharingController.queryCVSharing();
        PC_ReCalculate_FileSharingBatch batch =  new PC_ReCalculate_FileSharingBatch();
        Database.executeBatch(batch,200);
        test.stopTest();
    }
}