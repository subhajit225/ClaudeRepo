@isTest
public class RelatedListStatusTrackerControllerTest {
    @testSetup static void setup() {
        List<Case> caseList = new List<Case>();
        for(integer j=0 ; j< 3 ;j++){
            caseList.add(new Case(Status = 'New',Priority='P1 - Critical'));
        }
        insert caseList;
        
    }
    
    @isTest static void testMethod0() {
        test.startTest();
        	List<Case> caseList = [select id from case];
        	ApexPages.StandardController ap = new ApexPages.StandardController(caseList[0]);
        	RelatedListStatusTrackerController controller = new RelatedListStatusTrackerController(ap);
        	controller.caseTrackerListAction();
        Test.stopTest();
    }
}