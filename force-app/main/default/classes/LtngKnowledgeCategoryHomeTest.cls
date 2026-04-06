@isTest
public class LtngKnowledgeCategoryHomeTest{
    public static testMethod void getSubscription(){
        Customer_Subscription__c newCS = new Customer_Subscription__c();
        newCs.User__c = UserInfo.getUserId();
        newCs.Category_Label__c = 'Test';
        newCs.Type__c = 'Category';
        newCs.KB_ID__c = 'test';
        newCs.Category_Name__c = 'test';
        insert newCs;
        
        Customer_Subscription__c newCS1 = new Customer_Subscription__c();
        newCs1.User__c = UserInfo.getUserId();
        newCs1.Category_Label__c = 'Test';
        newCs1.Type__c = 'Article';
        newCs1.KB_ID__c = 'test';
        newCs1.Category_Name__c = 'test';
        insert newCs1;
        
        how_to__kav article = new how_to__kav();
        article.UrlName = 'testunique';
        article.title = 'test';
        insert article;
        
        how_to__kav articleToPublish = [select id,KnowledgeArticleId from how_to__kav where Id =: article.Id];
        
        KbManagement.PublishingService.publishArticle(articleToPublish .KnowledgeArticleId, true);
        
        //DescribeDataCategoryGroupResult[] results = Schema.describeDataCategoryGroups(new String[] { 'Article__kav'});
        How_To__DataCategorySelection dataCat = new How_To__DataCategorySelection();
        
        datacat.DataCategoryName = 'API';
        datacat.DataCategoryGroupName='Article';
        datacat.parentid = articleToPublish.id;
        insert dataCat;
        
        
        
        LtngKnowledgeCategoryHome.getSubscription();
        List<LtngKnowledgeCategoryHome.SubscribedCustomer> newlist = new List<LtngKnowledgeCategoryHome.SubscribedCustomer>();
        LtngKnowledgeCategoryHome.SubscribedCustomer wrapperCls = new LtngKnowledgeCategoryHome.SubscribedCustomer();
        wrapperCls.api = 'test';
        wrapperCls.isSubscribed = true;
        wrapperCls.categoryName = 'API';
        
        LtngKnowledgeCategoryHome.SubscribedCustomer wrapperCls1 = new LtngKnowledgeCategoryHome.SubscribedCustomer();
        wrapperCls1.api = 'test';
        wrapperCls1.isSubscribed = false;
        wrapperCls1.categoryName = 'API';
        
        newlist.add(wrapperCls);
        
        LtngKnowledgeCategoryHome.saveSubscription(newlist);
        LtngKnowledgeCategoryHome.createKbSubscription();    
        
        
        
    }    
}