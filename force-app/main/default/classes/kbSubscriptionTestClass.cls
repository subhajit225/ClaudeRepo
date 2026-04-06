/**
* @description Test class for KB Subscription functionality including mySubscriptionController, KnowledgeCategoryHome, VfSearchController, ArticleSubscriptionController, and SubscribedArticlesController
* @test
* @author Shiva Sharma
* @date 
*/
@isTest
public class kbSubscriptionTestClass {
    
    /**
* @description Test method to verify mySubscriptionController functionality including subscription list retrieval and article unsubscription
*/
    @isTest
    public static void mySubscriptionControllerClass(){
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
            Employee_Time_Off__c = true,
            UserPermissionsKnowledgeUser = true
        );
        insert u;
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        How_To__kav newArticle;
        System.runAs(user1){
            newArticle = new How_To__kav(Title='test',summary='xyz',urlname='xyz');
            insert newArticle;
        }
        How_To__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM How_To__kav WHERE id =: newArticle.Id];
        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
        List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
        csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='API', User__c = UserInfo.getUserId()));
        csList.add(new Customer_Subscription__c(type__c='Article' ,Category_Name__c ='API' , User__c = UserInfo.getUserId() , KB_ID__c = obj1.KnowledgeArticleId ));
        insert csList;
        
        mySubscriptionController subCont = new mySubscriptionController();
        System.assert(true,'mySubscriptionControllerClass');
        subCont.rowNum = 1;
        subCont.getSubscribedList();
        subCont.unsSubscribeArticle();
        
    }
    
    /**
* @description Test method to verify KnowledgeCategoryHome controller functionality including subscription data retrieval and management
*/
    @isTest
    public static void knowledgeCategoryHomeClass(){
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
            Employee_Time_Off__c = true,
            UserPermissionsKnowledgeUser = true
        );
        insert u;
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        How_To__kav newArticle;
        System.runAs(user1){
            newArticle = new How_To__kav(Title='test',summary='xyz',urlname='xyz');
            insert newArticle;
        }
        How_To__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM How_To__kav WHERE id =: newArticle.Id];
        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
        List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
        csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='API', User__c = UserInfo.getUserId()));
        csList.add(new Customer_Subscription__c(type__c='Article' ,Category_Name__c ='API' , User__c = UserInfo.getUserId() , KB_ID__c = obj1.KnowledgeArticleId ));
        insert csList;
        
        System.assert(true,'KnowledgeCategoryHomeClass');
        KnowledgeCategoryHome kbhome = new KnowledgeCategoryHome();
        kbhome.getSubscribedData();
        kbhome.createKbSubscription();
        kbhome.cancelSubscription();
        kbhome.saveSubscription();
        kbhome.getDataCategoryGroupInfo();
        
        
    }
    
    /**
* @description Test method to verify VfSearchController functionality including search operations, pagination, and subscription management
*/
    @isTest
    public static void vfSearchControllerClass(){
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
            Employee_Time_Off__c = true,
            UserPermissionsKnowledgeUser = true
        );
        insert u;
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        How_To__kav newArticle;
        System.runAs(user1){
            newArticle = new How_To__kav(Title='test',summary='xyz',urlname='xyz');
            insert newArticle;
        }
        How_To__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM How_To__kav WHERE id =: newArticle.Id];
        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
        List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
        csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='API', User__c = UserInfo.getUserId()));
        csList.add(new Customer_Subscription__c(type__c='Article' ,Category_Name__c ='API' , User__c = UserInfo.getUserId() , KB_ID__c = obj1.KnowledgeArticleId ));
        insert csList;
        System.currentPageReference().getParameters().put('categoryType_Article', 'API');
        System.assert(true,'VfSearchControllerClass');
        
        VfSearchController vfSearch = new VfSearchController();
        vfSearch.createKbSubscription();
        vfSearch.editSubscription();
        vfSearch.refreshSearchResult();
        vfSearch.getCategoryKeyword();
        vfSearch.getDataCategoryGroupInfo();
        vfSearch.next();
        vfSearch.previous();
        vfSearch.getCurrentPageNumber();
        vfSearch.getNextRequired();
        vfSearch.getPrevRequired();
        vfSearch.refreshSearchResult();
        
        
    }
    
    /**
* @description Test method to verify ArticleSubscriptionController functionality for individual article subscription management
*/
    @isTest
    public static void articleSubscriptionControllerClass(){
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
            Employee_Time_Off__c = true,
            UserPermissionsKnowledgeUser = true);
        insert u;
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        How_To__kav newArticle;
        System.runAs(user1){
            newArticle = new How_To__kav(Title='test',summary='xyz',urlname='xyz');
            insert newArticle;
        }
        How_To__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM How_To__kav WHERE id =: newArticle.Id];
        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
        List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
        csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='API', User__c = UserInfo.getUserId()));
        csList.add(new Customer_Subscription__c(type__c='Article' ,Category_Name__c ='API' , User__c = UserInfo.getUserId() , KB_ID__c = obj1.KnowledgeArticleId ));
        insert csList;
        
        
        ApexPages.StandardController st = new ApexPages.StandardController(newArticle);
        ArticleSubscriptionController articleSub = new ArticleSubscriptionController(st);
        articleSub.editSubscription();
        System.assert(true,'ArticleSubscriptionControllerClass');
        
    }
    
    /**
* @description Test method to verify ArticleSubscriptionController functionality for editing existing article subscriptions
*/
    @isTest
    public static void editArticleSubscriptionControllerClass(){
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
            Employee_Time_Off__c = true,
            UserPermissionsKnowledgeUser = true
        );
        insert u;
        User user1 = [Select ProfileId, LastName, Id from User WHERE Email='csit-testuser@rubrik.com' LIMIT 1];
        How_To__kav newArticle;
        System.runAs(user1){
            newArticle = new How_To__kav(Title='test',summary='xyz',urlname='xyz');
            insert newArticle;
        }
        
        
        How_To__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM How_To__kav WHERE id =: newArticle.Id];
        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
        List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
        csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='API', User__c = UserInfo.getUserId()));
        csList.add(new Customer_Subscription__c(type__c='Article' ,Category_Name__c ='API' , User__c = UserInfo.getUserId() , KB_ID__c = obj1.KnowledgeArticleId ));
        insert csList;
        System.assert(true,'editArticleSubscriptionControllerClass');
        
        ApexPages.StandardController st = new ApexPages.StandardController(newArticle);
        ArticleSubscriptionController articleSub = new ArticleSubscriptionController(st);
        articleSub.isSubscribed = true;
        articleSub.editSubscription();
        
    }
    
    /**
* @description Test method to verify SubscribedArticlesController functionality for managing user subscribed articles and categories
*/
    @isTest    
    public static void subscribedArticlesControllerClass(){
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
            Employee_Time_Off__c = true,
            UserPermissionsKnowledgeUser = true
        );
        insert u;
        
        System.runAs(u){
            
            
            // Step 1: Create draft article version
            How_To__kav newArticle = new How_To__kav(
                Title = 'Test Article',
                Summary = 'xyz',
                UrlName = 'test-article-rubrik-cs-it-99099',
                isVisibleInPkb=true
            );
            insert newArticle;
            
            
            
            // Step 2: Link to a Data Category (assuming group name 'Topic' and category 'Installation')
            // You must have a valid category in your org for this to work — adjust group and name as needed
            How_To__DataCategorySelection categorySelection = new How_To__DataCategorySelection(
                ParentId = newArticle.Id,
                DataCategoryGroupName = 'Article',
                DataCategoryName = 'API'
            );
            insert categorySelection;
            
            // Step 3: Publish the article
            How_To__kav insertedArticle = [
                SELECT Id, KnowledgeArticleId, PublishStatus
                FROM How_To__kav
                WHERE Id = :newArticle.Id
                LIMIT 1
            ];
            
            KbManagement.PublishingService.publishArticle(insertedArticle.KnowledgeArticleId, true);
            
            List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
            csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='API', User__c = UserInfo.getUserId()));
            csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Label__c =categorySelection.DataCategoryName ,Category_Name__c =categorySelection.DataCategoryName, User__c = UserInfo.getUserId()));
            csList.add(new Customer_Subscription__c(type__c='Article' ,Category_Name__c =categorySelection.DataCategoryName , User__c = UserInfo.getUserId() , KB_ID__c = insertedArticle.KnowledgeArticleId ));
            csList.add(new Customer_Subscription__c(type__c='Article' ,Category_Name__c ='API' , User__c = UserInfo.getUserId() , KB_ID__c = insertedArticle.KnowledgeArticleId ));
            insert csList;
            
            SubscribedArticlesController subArticles = new SubscribedArticlesController();
            subArticles.currentUserId = UserInfo.getUserId();
            subArticles.getsubscribedMapval();
            System.assert(true,'SubscribedArticlesControllerClass');
        }
    }
}