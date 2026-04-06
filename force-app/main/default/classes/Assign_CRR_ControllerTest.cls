@isTest
public class Assign_CRR_ControllerTest {
    @testSetup static void setup() {
        List<Account> actList = new List<Account>();
        testDataFactoryClass.createCustomSettings();
        actList.add(new Account(Name = 'TestAcct1',Website='www.test3.com',OwnerId = UserInfo.getUserId(),type='Customer'));
        insert actList; 
        List<Contact> conList = testDataFactoryClass.createContact(actList);
        List<Customer_Registration_Request__c> csrList = testDataFactoryClass.createCustomerRegRequest(1,actList);
    }
    
    
    @isTest static void testMethod1() {
        Customer_Registration_Request__c crr = [select id,ownerId,Status__c from Customer_Registration_Request__c limit 1];
        
        ApexPages.StandardController st = new ApexPages.StandardController(crr);
        Assign_CRR_Controller arr = new Assign_CRR_Controller(st);
        arr.updateApprover();
    }
}