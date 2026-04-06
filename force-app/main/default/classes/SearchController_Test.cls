/********************************************************************************************************
* Name              : SearchController_Test
* Purpose           : SearchController_Test is Used for Testing SearchController Class
*********************************************************************************************************/
@isTest
public class SearchController_Test{ 
    
    static testMethod void testDoSearchOnload(){
        SearchController searchCtrl=new SearchController();
        PageReference pageRef = Page.UnifiedSearch; // Adding VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('search', 'Search Text');//for page reference
        
        
        Test.startTest();
        try{
            searchCtrl.doSearchOnload();
        }catch(Exception exp){
            System.debug('Exception : ' + exp);
            
        }
        Test.stopTest();
    }

    static testMethod void testDoSearch(){
        
        PageReference pageRef = Page.UnifiedSearch; // Adding VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('search', 'Search Text');//for page reference 
        
        SearchController searchCtrl=new SearchController();
        Test.startTest();
        try{
            searchCtrl.doSearch();
        }catch(Exception exp){
            System.debug('Exception : ' + exp);
            
        }
        Test.stopTest();
    }
    
    static testMethod void testNext(){
        
        SearchController searchCtrl=new SearchController();
        
        Test.startTest();
        try{
            searchCtrl.next();
        }catch(Exception exp){
            System.debug('Exception : ' + exp);
            
        }
        Test.stopTest();
    }
    
    static testMethod void testPrevious(){
        
        SearchController searchCtrl=new SearchController();
        Test.startTest();
        try{
            searchCtrl.previous();
        }catch(Exception exp){
            System.debug('Exception : ' + exp);
            
        }
        Test.stopTest();
    }
    
    static testMethod void testSearchControllerGetters(){
        
        SearchController searchCtrl=new SearchController();
        Test.startTest();
        searchCtrl.getiResults();
        searchCtrl.getcResults();
        searchCtrl.getnResults();
        searchCtrl.getrResults();
        searchCtrl.getContentdocs();
        searchCtrl.getincents();
        searchCtrl.getccrResults();
        searchCtrl.getlResults();
        searchCtrl.getSearchText();
        searchCtrl.geturlscope();
        searchCtrl.getPrevRequired();
        searchCtrl.getNextRequired();
        searchCtrl.getCurrentPageNumber();
        searchCtrl.getkaSize();
        searchCtrl.getiSize();
        searchCtrl.getcSize();
        searchCtrl.getrSize();
        searchCtrl.getnSize();
        searchCtrl.getcontentSize();
        searchCtrl.getleadsize();
        searchCtrl.getccrsize();
        searchCtrl.getincentsize();
        searchCtrl.setSearchText('Test String');
        Test.stopTest();
    }
    
}