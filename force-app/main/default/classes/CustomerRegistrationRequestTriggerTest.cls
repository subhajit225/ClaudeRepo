@isTest
public class CustomerRegistrationRequestTriggerTest {
    
     @testSetup static void setup() {
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        testDataFactoryClass.createUser();
        testDataFactoryClass.createCustomSettings();
        testDataFactoryClass.createContactWithUser(2);
        testDataFactoryClass.createProduct();
    }
    
    /*    @isTest static void testMethod0() {
        test.startTest();
        //testDataFactoryClass.createCustomSettings();
        List<Account> actList = testDataFactoryClass.createAccount(1,0);
        List<Contact> conList = testDataFactoryClass.createContact(actList);
        testDataFactoryClass.createExpiredOpporunitywithAccountEntitlement(actList);
        List<Customer_Registration_Request__c> csrList = testDataFactoryClass.createCustomerRegRequest(3,actList);
        for(Customer_Registration_Request__c csr : csrList){
            csr.status__c = 'Approved';
            csr.Extended_By_Date__c = System.today();
            if(csr.Account__c == null){
                csr.Account__c = actList[0].id;
            }
        }
        update csrList;
        test.stopTest();
        //System.assertEquals(8, [select count() from Contact]);
    }
    */

     @isTest static void testMethod1() {
         test.startTest();
         //testDataFactoryClass.createCustomSettings();
         List<Account> actList = testDataFactoryClass.createAccount(1,0);
         List<Contact> conList = testDataFactoryClass.createContact(actList);
         testDataFactoryClass.createOpporunitywithAccountEntitlement(actList);
         List<Customer_Registration_Request__c> csrList = testDataFactoryClass.createCustomerRegRequest(3,actList);
         for(Customer_Registration_Request__c csr : csrList){
             csr.status__c = 'Approved';
             csr.has_Domain__c = false;
             csr.Extended_By_Date__c = System.today();
             if(csr.Account__c == null){
                 csr.Account__c = actList[0].id;
             }
         }
         update csrList;
         test.stopTest();
         //System.assertEquals(8, [select count() from Contact]);
    }
    
    @isTest static void testMethod2() {
         test.startTest();
         //testDataFactoryClass.createCustomSettings();
         List<Account> actList = testDataFactoryClass.createAccount(1,0);
         List<Contact> conList = testDataFactoryClass.createContact(actList);
         List<Customer_Registration_Request__c> csrList = testDataFactoryClass.createCustomerRegRequest(3,actList);
         for(Customer_Registration_Request__c csr : csrList){
             csr.status__c = 'Approved';
             csr.has_Domain__c = false;
             csr.Extended_By_Date__c = System.today();
             if(csr.Account__c == null){
                 csr.Account__c = actList[0].id;
             }
         }
         update csrList;
         test.stopTest();
         //System.assertEquals(8, [select count() from Contact]);
    }
}