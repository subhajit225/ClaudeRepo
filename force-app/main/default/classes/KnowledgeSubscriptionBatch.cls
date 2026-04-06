global class KnowledgeSubscriptionBatch implements Database.Batchable<sObject>, Database.Stateful{

    global set<Id> userIds;
    
    global KnowledgeSubscriptionBatch(){
        userIds = new set<Id>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        try{
            Date todayDate = System.today().addDays(-7) ;
            String query ='SELECT Id, IsDeleted, CreatedDate, CreatedById,LastPublishedDate FROM KnowledgeArticle where DAY_ONLY(LastPublishedDate) >=: todayDate';
            return Database.getQueryLocator(query);
        }catch(Exception e){
            System.debug(e);
        }
        return null;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<id> kbIds = new Set<Id>();
        for(KnowledgeArticle kb : (List<KnowledgeArticle>)scope){
            kbIds.add(kb.Id);
        }
        System.debug(kbIds);
        Set<String> catName = new Set<String>();
        Set<Id> filteredKbIds = new Set<Id>();
        for(How_To__DataCategorySelection howto : [SELECT Id, ParentId, DataCategoryGroupName, DataCategoryName,Parent.KnowledgeArticleId FROM How_To__DataCategorySelection where (Parent.KnowledgeArticleId IN: kbIds OR ParentId IN: kbIds) AND Parent.isVisibleInPkb = true AND Parent.IsLatestVersion = true]){
            catName.add(howto.DataCategoryName );
            filteredKbIds.add(howto.Parent.KnowledgeArticleId);
        }
        System.debug(catName);
        for(Customer_Subscription__c kbSub : [SELECT Id, Type__c, KB_ID__c, User__c, Category_Name__c, Category_Label__c FROM Customer_Subscription__c WHERE  User__r.isActive = true AND ( KB_ID__c IN: filteredKbIds OR  (Category_Label__c IN: catName AND Type__c = 'Category'))] ){
            userIds.add(kbSub.User__c);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        List<OrgWideEmailAddress> fromId= [select Id,Address  from OrgWideEmailAddress WHERE Address = 'donotreply@rubrik.com' LIMIT 1];
        EmailTemplate templateId = [Select id from EmailTemplate where name = 'SubscibedArticlesEmailTemplate'];
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        System.debug(userIds);
        for(Id ids : userIds){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateID(templateId.Id); 
            mail.setSaveAsActivity(false);
            if(!fromId.isEmpty())
                mail.setOrgWideEmailAddressId(fromId[0].id);
            mail.setTargetObjectId(ids);
            allmsg.add(mail);
        }
        
        Messaging.sendEmail(allmsg,false);
   }
}