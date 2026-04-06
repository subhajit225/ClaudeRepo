@isTest
public class testDataFactoryClassTest {
    @testSetup static void setup() {
        testDataFactoryClass.createUser();
        testDataFactoryClass.createCustomSettings();
    }
    
    static testmethod void test1(){
        List<Account> actList = testDataFactoryClass.createAccount();
        testDataFactoryClass.createAccount(1, 1);
        testDataFactoryClass.createAccountwithEntitlement();
        testDataFactoryClass.createCase(1);
        List<Contact> conList = testDataFactoryClass.createContact(actList);
        testDataFactoryClass.createContactCustomEmail(actList, 'test@test.com', true);
        testDataFactoryClass.createContactWithPartnerUser(2);
        testDataFactoryClass.createContactWithUser(1);
        testDataFactoryClass.createCustomerRegRequest(1, actList);
      
        //testDataFactoryClass.createExpiredOpporunitywithAccountEntitlement(actList);
        //testDataFactoryClass.createInactivePortalUser(conList[0].id);
       // testDataFactoryClass.createOpporunity(actList);
        
    }
    
    static testmethod void test2(){
        testDataFactoryClass.createContactWithUserLogin(5);

    }
}