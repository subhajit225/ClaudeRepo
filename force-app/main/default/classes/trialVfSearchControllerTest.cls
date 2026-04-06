@isTest
public class trialVfSearchControllerTest {
     @testSetup static void setup() {
         testDataFactoryClass.createUser();
         testDataFactoryClass.createCustomSettings();
         testDataFactoryClass.createContactWithPartnerUser(1);
    }
    
    public static testmethod void testmethod1(){
        ApexPages.currentPage().getParameters().put('categoryType_Article', 'API');

        trialVfSearchController obj = new trialVfSearchController();
        obj.getDataCategoryName();
        obj.getCategoryKeyword();
        obj.next();
        obj.previous();
        obj.getCurrentPageNumber();
        obj.getNextRequired();
        obj.getPrevRequired();
        obj.refreshSearchResult();
    }
    
    public static testmethod void testmethod2(){
        ApexPages.currentPage().getParameters().put('categoryType_Article', 'ALL');

        trialVfSearchController obj = new trialVfSearchController();
        obj.getDataCategoryName();
        obj.getCategoryKeyword();
        obj.next();
        obj.previous();
        obj.getCurrentPageNumber();
        obj.getNextRequired();
        obj.getPrevRequired();
        obj.refreshSearchResult();
    }
    
    
    static testMethod void test_CommunityHomeController() {
        User userRecord =[select id,contact.AccountId,name from user where Profile.Name ='Rubrik Partner Community User' AND isACtive = true AND Contact.AccountId != null LIMIT 1];
        categoryClass ct = new categoryClass();
        ct.getDescribeDataCategoryGroupStructureResults();
        ct.getDescribeDataCategoryGroupStructureResultsSingle();
        System.runAs(userRecord){
            ApexPages.currentPage().getParameters().put('terms', 'true');
            CommunityHomeController hp = new CommunityHomeController();
            
            hp.getTopSolutions();
            hp.getNewArticles();
            hp.getPortalNews();
            hp.getRankedSolutions();
            hp.forwardToCustomPage();
        }
       
        
    }
}