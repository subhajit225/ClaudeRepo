/********************************************************************************************************
* Name              : OpportunitiesPaginationController_Test
* Purpose           : OpportunitiesPaginationController_Test is Used for Testing OpportunitiesPaginationController Class
*********************************************************************************************************/
@isTest
public class OpportunitiesPaginationController_Test{
    
    static testMethod void testSearch(){
        testDataFactoryClass.createCustomSettings();
        List<Account> actList = new List<Account>();

        //ID userId = [select id from user where Alias ='tUser'].Id;

        Account act =new Account(Name = 'TestAcct1',Website='www.test3.com',/* OwnerId = userId, */type='Customer');
        insert act;

        actList.add(act);

        List<opportunity> oppList =  testDataFactoryClass.createOpporunity(actList);

        PageReference pageRef = Page.OpportunitiesPaginationVFP;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', oppList[0].Id);

        Test.startTest();
        
        OpportunitiesPaginationController oppPaginationCtrl = new OpportunitiesPaginationController();
        oppPaginationCtrl.opp = oppList[0];
        oppPaginationCtrl.hasNext=true;
        oppPaginationCtrl.hasPrevious=false ;
        oppPaginationCtrl.pageNumber=1;
        List<Opportunity> lstOppWithNoValue = oppPaginationCtrl.lstOpportunity ;
        oppPaginationCtrl.Search();
        Boolean hsNxt = oppPaginationCtrl.hasNext;
        Boolean hsPrev = oppPaginationCtrl.hasPrevious;
        Integer pgNum = oppPaginationCtrl.pageNumber;
        List<Opportunity> lstOppWithValue = oppPaginationCtrl.lstOpportunity ;
        oppPaginationCtrl.previous();
        oppPaginationCtrl.next();
        
        Test.stopTest();
    }
}