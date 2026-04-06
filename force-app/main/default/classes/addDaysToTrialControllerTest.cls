/********************************************************************************************************
* Name              : addDaysToTrialControllerTest 
* Purpose           : addDaysToTrialControllerTest is Used for Testing addDaysToTrialController Class
*********************************************************************************************************/
@isTest
public class addDaysToTrialControllerTest {
    @testSetup static void setup() {
        testDataFactoryClass.createUser();
        testDataFactoryClass.createCustomSettings();
        testDataFactoryClass.createTrialProduct();
    }
    
    static testmethod void testDaysToExtend(){
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt.AccountId=act.id;
        insert cnt;
        List<Contact> conList = new List<Contact>();//testDataFactoryClass.createContact(testDataFactoryClass.createAccount());
        conList.add(cnt);
        Contact con = conList[0];
        con.Agreed_to_Edge_Trial_Agreement__c = true;
        ApexPages.StandardController st = new ApexPages.StandardController(conList[0]);
        addDaysToTrialController atc = new addDaysToTrialController(st);
        atc.daysToExtend = 2;
        atc.extendDays();
    }
    
    static testmethod void testExtendDays(){
        //List<Contact> conList = testDataFactoryClass.createContact(testDataFactoryClass.createAccount());
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt.AccountId=act.id;
        insert cnt;
        List<Contact> conList = new List<Contact>();//testDataFactoryClass.createContact(testDataFactoryClass.createAccount());
        conList.add(cnt);
        
        ApexPages.StandardController st = new ApexPages.StandardController(conList[0]);
        addDaysToTrialController atc = new addDaysToTrialController(st);
        atc.daysToExtend = 2;
        atc.extendDays();
    }
}