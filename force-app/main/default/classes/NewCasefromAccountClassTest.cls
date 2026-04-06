@IsTest()
public class NewCasefromAccountClassTest {
    @testSetup static void setup() {
        List<Account> accountList = new List<Account>();
        for(integer j=0 ; j< 3 ;j++){
            accountList.add(new Account(Name = 'abc'));
        }
        insert accountList;
        
        List<Case> caseList = new List<Case>();
        for(integer j=0 ; j< 3 ;j++){
            caseList.add(new Case(Status = 'New',Priority='P1 - Critical',AccountId = accountList[0].Id));
        }
        insert caseList;   
    }
    
    @isTest 
    static void testConstructor() {
        test.startTest();
        	List<Case> caseList = [SELECT id, AccountId FROM Case];
        	ApexPages.StandardController ap = new ApexPages.StandardController(caseList[0]);
        	NewCasefromAccountClass controller = new NewCasefromAccountClass(ap);
        Test.stopTest();
        Id classRecordId = controller.recordId;
        System.assertEquals('Case', classRecordId.getSObjectType().getDescribe().getName());
    }

    @isTest 
    static void testAccount() {
        test.startTest();
            Account acc = [SELECT Id FROM Account Limit 1]; 
            Case objCase = new Case(Status = 'New',Priority='P1 - Critical', AccountId = acc.Id);
        	ApexPages.StandardController ap = new ApexPages.StandardController(objCase);
        	NewCasefromAccountClass controller = new NewCasefromAccountClass(ap);
        Test.stopTest();
        Id classRecordId = controller.recordId;
        System.assertEquals('Account', classRecordId.getSObjectType().getDescribe().getName());
    }

    @isTest 
    static void testContact() {
        test.startTest();
            Account acc = [SELECT Id FROM Account Limit 1]; 
            Contact objCont = new Contact();
            objCont.LastName = 'test';
            objCont.AccountId = acc.Id;
            INSERT objCont;
            Case objCase = new Case(Status = 'New',Priority='P1 - Critical', ContactId = objCont.Id);
        	ApexPages.StandardController ap = new ApexPages.StandardController(objCase);
        	NewCasefromAccountClass controller = new NewCasefromAccountClass(ap);
        Test.stopTest();
        Id classRecordId = controller.recordId;
        System.assertEquals('Contact', classRecordId.getSObjectType().getDescribe().getName());
    }
    
}