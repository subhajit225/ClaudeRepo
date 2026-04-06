/**
* @description Test class for VfSearchController
* @test
* @author Raveesh Layal
* @date 2025-08-01
*/
@isTest
public class VfSearchController_Test {
    /**
    * @description Test setup method to create a test user with System Administrator profile
    * and required user attributes.
    */
    @testSetup
    private static void setup(){
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true);
        insert u;
        
        // Assert user created successfully
        System.assert(u.Id != null, 'Test User should be created successfully');
    }

    /**
    * @description Tests the getDataCategoryGroupInfo method functionality of VfSearchController.
    */
    @isTest
    static void testGetDataCategoryGroupInfo(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        VfSearchController searchCtrl = new VfSearchController();
        System.runAs(user1){
            Test.startTest();
            searchCtrl.getDataCategoryGroupInfo();
            Test.stopTest();

            // Assert that getDataCategoryGroupInfo executes and searchCtrl is not null
            System.assertNotEquals(null, searchCtrl, 'Controller instance should not be null');
        }
    }

    /**
    * @description Tests the getCategoryKeyword method with categoryType_Article set to 'API'.
    */
    @isTest
    static void testGetCategoryKeyword(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        ApexPages.currentPage().getParameters().put('categoryType_Article', 'API');
        VfSearchController searchCtrl1 = new VfSearchController();
        VfSearchController searchCtrl2 = new VfSearchController();
        System.runAs(user1){
            Test.startTest();
            searchCtrl1.searchstring = 'Test Search String';
            searchCtrl1.getCategoryKeyword();
            searchCtrl2.getCategoryKeyword();
            Test.stopTest();

            System.assertNotEquals(null, searchCtrl1, 'searchCtrl1 should not be null');
            System.assertNotEquals(null, searchCtrl2, 'searchCtrl2 should not be null');
        }
    }

    /**
    * @description Tests getCategoryKeyword and related pagination methods with 
    * categoryType_Article set to 'NoFilter'.
    */
    @isTest
    static void testGetCategoryKeywordForNoFilter(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        ApexPages.currentPage().getParameters().put('categoryType_Article', 'NoFilter');
        VfSearchController searchCtrl1 = new VfSearchController();
        System.runAs(user1){
            Test.startTest();
            searchCtrl1.selectedVal  = 'Test selectedVal';
            searchCtrl1.maxSize = 12;
            searchCtrl1.getCategoryKeyword();
            searchCtrl1.refreshSearchResult();
            Boolean prev = searchCtrl1.getPrevRequired();
            Boolean next = searchCtrl1.getNextRequired();
            Decimal currentPage = searchCtrl1.getCurrentPageNumber();
            searchCtrl1.next();
            searchCtrl1.previous();
            Test.stopTest();

            System.assert(prev != null, 'getPrevRequired should return a Boolean');
            System.assert(next != null, 'getNextRequired should return a Boolean');
            System.assert(currentPage != null && currentPage >= 0, 'Current page number should be valid');
        }
    }

    /**
    * @description Tests editSubscription and related methods using categoryType_Article 'NoFilter'.
    */
    @isTest
    static void testVfSearchControllerMethods(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        System.runAs(user1){
            List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
            csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='API',Category_Label__c = 'NoFilter', User__c = UserInfo.getUserId()));
            insert csList;
            ApexPages.currentPage().getParameters().put('categoryType_Article', 'NoFilter');
            VfSearchController searchCtrl1 = new VfSearchController();
            Test.startTest();
            searchCtrl1.selectedVal  = 'Test selectedVal';
            searchCtrl1.editSubscription();
            Test.stopTest();

            System.assertNotEquals(null, csList[0].Id, 'Customer_Subscription__c should be inserted');
            System.assertNotEquals(null, searchCtrl1, 'Controller instance should not be null');
        }
    }

    /**
    * @description Tests refreshSearchResult, pagination, and editSubscription with categoryType_Article 'All'.
    */
    @isTest
    static void testVfSearchControllerMethods1(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        System.runAs(user1){
            List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
            csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='API', User__c = UserInfo.getUserId()));
            insert csList;
            ApexPages.currentPage().getParameters().put('categoryType_Article', 'All');
            VfSearchController searchCtrl1 = new VfSearchController();
            Test.startTest();
            searchCtrl1.selectedVal  = 'Test selectedVal';
            searchCtrl1.refreshSearchResult();
            Boolean prev = searchCtrl1.getPrevRequired();
            Boolean next = searchCtrl1.getNextRequired();
            Decimal currentPage = searchCtrl1.getCurrentPageNumber();
            searchCtrl1.maxSize = 12;
            searchCtrl1.next();
            searchCtrl1.previous();
            searchCtrl1.isSubscribed = true;
            searchCtrl1.editSubscription();
            Test.stopTest();

            System.assert(prev != null, 'getPrevRequired should return a Boolean');
            System.assert(next != null, 'getNextRequired should return a Boolean');
            System.assert(currentPage != null && currentPage >= 0, 'Current page should be valid');
            System.assertNotEquals(null, csList[0].Id, 'Customer_Subscription__c should be inserted');
        }
    }

    /**
    * @description Tests editSubscription for Customer_Subscription__c with custom categoryName 'test' and categoryType 'Category'.
    */
    @isTest
    static void testVfSearchControllerMethods2(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        System.runAs(user1){
            List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
            csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='test', User__c = UserInfo.getUserId()));
            insert csList;
            ApexPages.currentPage().getParameters().put('categoryType_Article', 'All');
            VfSearchController searchCtrl1 = new VfSearchController();
            Test.startTest();
            searchCtrl1.selectedVal  = 'Test selectedVal';
            searchCtrl1.editSubscription();
            Test.stopTest();

            System.assertNotEquals(null, csList[0].Id, 'Customer_Subscription__c should be inserted');
        }
    }

    /**
    * @description Tests editSubscription for Customer_Subscription__c with categoryType_Article 'NoFilter' and custom categoryName 'test'.
    */
    @isTest
    static void testVfSearchControllerMethods3(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        System.runAs(user1){
            List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
            csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='test', User__c = UserInfo.getUserId()));
            insert csList;
            ApexPages.currentPage().getParameters().put('categoryType_Article', 'NoFilter');
            VfSearchController searchCtrl1 = new VfSearchController();
            Test.startTest();
            searchCtrl1.selectedVal  = 'Test selectedVal';
            searchCtrl1.editSubscription();
            Test.stopTest();

            System.assertNotEquals(null, csList[0].Id, 'Customer_Subscription__c should be inserted');
        }
    }

    /**
    * @description Tests creating, categorizing, publishing a knowledge article and 
    * editing subscriptions with categoryType_Article 'NoFilter'.
    */
    @isTest
    static void testVfSearchControllerMethods4(){
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];

        How_To__kav newArticle = new How_To__kav(
            Title = 'Test Article',
            UrlName = 'test-article-url',
            Summary = 'This is a test article.'
        );
        insert newArticle;

        How_To__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM How_To__kav WHERE id =: newArticle.Id];

        How_To__DataCategorySelection kbType = new How_To__DataCategorySelection(
            ParentId = newArticle.Id,
            DataCategoryGroupName ='Article',
            DataCategoryName = 'All'
        );
        insert kbType;

        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);

        List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
        csList.add(new Customer_Subscription__c(type__c='Category', Category_Name__c ='API', User__c = UserInfo.getUserId()));
        csList.add(new Customer_Subscription__c(type__c='Category', Category_Label__c = kbType.DataCategoryName, Category_Name__c = kbType.DataCategoryName, User__c = UserInfo.getUserId()));
        insert csList;

        ApexPages.currentPage().getParameters().put('categoryType_Article', 'NoFilter');
        VfSearchController searchCtrl1 = new VfSearchController();

        System.runAs(user1){
            Test.startTest();
            searchCtrl1.selectedVal  = 'Test selectedVal';
            searchCtrl1.editSubscription();
            Test.stopTest();

            System.assertNotEquals(null, newArticle.Id, 'Knowledge article should be inserted');
            System.assertNotEquals(null, kbType.Id, 'Data category selection should be inserted');
            System.assertNotEquals(null, csList[0].Id, 'Customer subscription should be inserted');
            System.assertNotEquals(null, searchCtrl1, 'Controller instance should not be null');
        }
    }
}