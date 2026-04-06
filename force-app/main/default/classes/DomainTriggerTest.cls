@isTest
public class DomainTriggerTest {
	@isTest
    public static void test(){
        TriggerControl__c trigCtrl = new TriggerControl__c(Name='AllowedDomain',DisableTrigger__c=false);
        insert trigCtrl;
        Account acc = new Account(Name='Test Account');
        insert acc;
        WL_Domain__c dom = new WL_Domain__c(Name='Asdf.com',Account__c = acc.Id);
        insert dom;
        WL_Domain__c dom2 = new WL_Domain__c(Name='test.com',Account__c = acc.Id);
        insert dom2;
        Test.startTest();
        WL_Domain__c dom1 = new WL_Domain__c(Name='Asdf.com',Account__c = acc.Id);
        Database.SaveResult result = Database.insert(dom1, false);
        dom2.Name = 'Asdf.com';
        Database.SaveResult result1 = Database.update(dom2, false);
        Test.stopTest();
        System.assertEquals('Domain Already Exist',result.getErrors()[0].getMessage());
    }
}