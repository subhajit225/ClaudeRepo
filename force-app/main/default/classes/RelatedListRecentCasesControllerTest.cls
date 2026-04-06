/********************************************************************************************************
* Name              : RelatedListRecentCasesControllerTest 
* Purpose           : RelatedListRecentCasesControllerTest is Used for Testing RelatedListRecentCasesController Class
*********************************************************************************************************/
@isTest
public class RelatedListRecentCasesControllerTest {
    private static List<Case> caseList = new List<Case>();
    
    @testSetup
    static void setup() {
        Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',type='Customer');
        insert act;
        
        for(integer j=0 ; j< 3 ;j++){
            caseList.add(new Case(Status = 'New',Priority='P1 - Critical',AccountId=act.id,Origin='Email',Subject='Test'));
        }
        insert caseList;        
    }
    
    @isTest static void testMethod0() {
        test.startTest();
          List<Case> caseList = [select id from case];
          ApexPages.StandardController ap = new ApexPages.StandardController(caseList[0]);
          RelatedListRecentCasesController controller = new RelatedListRecentCasesController(ap);
          controller.recentCaseListAction();
        Test.stopTest();
    }
    
    @isTest static void getClosedCases() {
        test.startTest();
          List<Case> caseList = [select id from case];
          ApexPages.StandardController ap = new ApexPages.StandardController(caseList[0]);
          RelatedListRecentCasesController controller = new RelatedListRecentCasesController(ap);
          controller.getClosedCases();
        Test.stopTest();
    }
    
    @isTest static void getOpenCases() {
        test.startTest();
          List<Case> caseList = [select id from case];
          ApexPages.StandardController ap = new ApexPages.StandardController(caseList[0]);
          RelatedListRecentCasesController controller = new RelatedListRecentCasesController(ap);
          controller.getOpenCases();
          setup();
        Test.stopTest();
    }
    
    @isTest static void getRelatedCases() {
        test.startTest();
          List<Case> caseList = [select id from case];
          ApexPages.StandardController ap = new ApexPages.StandardController(caseList[0]);
          RelatedListRecentCasesController controller = new RelatedListRecentCasesController(ap);
          controller.getRelatedCases();
        Test.stopTest();
    }
    
    @isTest static void testRelatedListRecentCasesControllerForNullReturn() {
        test.startTest();
          List<Case> caseList = [select id,AccountId from case];
          caseList[0].AccountId = null;
          update caseList;
          ApexPages.StandardController ap = new ApexPages.StandardController(caseList[0]);
          RelatedListRecentCasesController controller = new RelatedListRecentCasesController(ap);
          controller.recentCaseListAction();
          controller.getClosedCases();
          controller.getOpenCases();
          controller.getRelatedCases();
        Test.stopTest();
    }
}