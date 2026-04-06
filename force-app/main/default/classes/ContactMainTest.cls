/*
 * Class Name :- ContactMainTest
 * Trigger :- ContactMain.apxt
 * Author :- Shiva Sharma
 * Created Date :- 11-06-2018
 * Description : This Controller Test class for ContactMain.
 * 
 // ********************Change Logs *****************************************************************************
 * 
 * Modified By          Date        Description 
 * 
 * 
 * 
 // ********************Change Logs Ends*************************************************************************
*/
@isTest
public class ContactMainTest {

    @testSetup 
    static void setup() {
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        testDataFactoryClass.createUser();
        testDataFactoryClass.createTrialProduct();
        testDataFactoryClass.createCustomSettings();
        
        ShGl_DisableBusinessLogic__c profSetting = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getProfileId());
        profSetting.Disable_Entitlement_Validation_Rules__c = true;
		upsert profSetting;
    }
    
    @isTest static void testMethod0() {
        test.startTest();
        testDataFactoryClass.createContactCustomEmail(testDataFactoryClass.createAccount(1,0),'rent@row',true);
        List<Contact> conList = testDataFactoryClass.createContactCustomEmail(testDataFactoryClass.createAccount(),'rent@rows',false);
        for(Contact con: conList){
            con.Agreed_to_Edge_Trial_Agreement__c = true;
            con.Create_Portal_User__c = true;
        }
        update conList;
        test.stopTest();
    }
    
    @isTest static void testMethod1() {
        test.startTest();
        testDataFactoryClass.createContactCustomEmail(testDataFactoryClass.createAccount(1,0),'rent@row',true);
        List<Contact> conList = testDataFactoryClass.createContactCustomEmail(testDataFactoryClass.createAccountwithEntitlement(),'rent12@rows',false);
        for(Contact con: conList){
            con.Create_Portal_User__c = true;
        }
        update conList;
        ContactTriggerHandler.trialEdgeContact(new Set<Id>{conList[0].Id});
        test.stopTest();
    }
    
    @isTest static void testMethod2() {
        test.startTest();
            testDataFactoryClass.createContactCustomEmail(testDataFactoryClass.createAccount(1,0),'rent@row',true);
            List<Contact> conList = testDataFactoryClass.createContactCustomEmail(testDataFactoryClass.createAccount(),'rent@rows',false);
            Contact cn = new Contact(accountid=conList[0].AccountId,firstName='test demo',lastname='test con',email='lnarasimha823@gmail.com');
            insert cn;
            conList.add(cn);
            for(Contact con: conList){
                con.Agreed_to_Edge_Trial_Agreement__c = true;
                con.Create_Portal_User__c = true;
            }
            update conList;
        test.stopTest();
    }

    @isTest static void testMethod3() {
        test.starttest();
        List<Contact> conList = testDataFactoryClass.createContact(testDataFactoryClass.createAccount(1,0));
        for(Contact con: conList){
            con.PSE_Shadow_Completed__c=System.Today();
            con.PSE_Shadow_2_Completed__c=System.Today();
        }
        update conList;
        test.stoptest();
    }

    @isTest static void testrollupAccrediated(){
        List<Contact> conList = testDataFactoryClass.createContact(testDataFactoryClass.createAccount(1,0));
        for(Contact con: conList){
            //con.RCIE_Certified__c=System.Today();
            con.RTP_Accredited__c = System.today()-1;
        }
        Test.startTest();
            update conList;
        Test.stopTest();
        Account acc = [SELECT Id, RTP_Accredited__c/*, RCIE_Certified__c*/ FROM Account WHERE Id = :conList[0].AccountId];
        System.assertEquals(1, acc.RTP_Accredited__c);
        //System.assertEquals(1, acc.RCIE_Certified__c);
    }
    
    
    @isTest static void testunMQLContact(){
        List<Contact> conList = testDataFactoryClass.createContact(testDataFactoryClass.createAccount(1,0));
        for(Contact con: conList){
            con.MQL__c=true;
            con.Contact_Status__c = 'Open';
        }
        update conList;

        for(Contact con: conList){
            con.Contact_Status__c = 'Non-Qualified';
        }
        Test.startTest();
            update conList;
        Test.stopTest();
        for(Contact con : [SELECT Id, MQL__c, Partner_MQL__c FROM Contact WHERE id IN :conList]){
            System.assert(!con.MQL__c);
            System.assert(!con.Partner_MQL__c);
        }
    }

    @isTest static void testContactTrigger(){
        new ContactTriggerHandler().bulkBefore();
        new ContactTriggerHandler().bulkAfter();
        new ContactTriggerHandler().beforeInsert(new Contact());
       	new ContactTriggerHandler().afterInsert(new Contact());
        new ContactTriggerHandler().afterUpdate(new Contact(), new Contact());
        new ContactTriggerHandler().afterDelete(new Contact());
    }
}