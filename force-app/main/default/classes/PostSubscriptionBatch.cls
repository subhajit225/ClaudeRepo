global class PostSubscriptionBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global set<Id> userIds;
    global string defaultquery;
  
    global PostSubscriptionBatch(){
        userIds = new set<Id>();
    }
    
   public PostSubscriptionBatch(String q){
        userIds = new set<Id>();
        this.defaultquery=q;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){

        Date sevenDaysBackDate = System.today().addDays(-7) ;
        
        String query= 'SELECT CreatedById,CreatedDate,EntityId,EntityKeyPrefix,EntityType,Id,IsDeleted,NetworkId,SystemModstamp,TopicId,Topic.Name FROM TopicAssignment WHERE DAY_ONLY(CreatedDate) >=: sevenDaysBackDate';
        String finalQuery= string.isBlank(defaultquery)?query:this.defaultquery;
        system.debug('@@#'+finalQuery);
        return Database.getQueryLocator(finalQuery);
        
    }
    
    global void execute (Database.Batchablecontext BC, list<TopicAssignment> scope){
        
        system.debug('');
        Set<Id>topicId= new Set<Id>();
         //Set<Id>subscriberId= new Set<Id>();
        for(TopicAssignment ta : (List<TopicAssignment>)scope){            
            topicId.add(ta.topicId);
        } 
           //system.debug('topicId'+subscriberId);

        for(EntitySubscription esub: [SELECT CreatedById,CreatedDate,Id,IsDeleted,NetworkId,ParentId,SubscriberId FROM EntitySubscription where ParentId in:topicId AND NetworkId=:system.label.networkScope  ]){
           system.debug('Inside EntitySubscription'+esub );
            userIds.add(esub.SubscriberId); 
        }
        
        /*system.debug('subscriberId'+subscriberId);
        for(User us:[SELECT Id,Allow_weekly_notification__c from User WHERE Allow_weekly_notification__c=true AND ID IN: subscriberId]){
            system.debug('Inside User'+us);
            userIds.add(us.Id);
        }*/
    }
    
    global void finish(Database.Batchablecontext BC){
        
        List<OrgWideEmailAddress> fromId= [select Id,Address  from OrgWideEmailAddress WHERE Address = 'donotreply@rubrik.com' LIMIT 1];
        EmailTemplate templateId = [Select id from EmailTemplate where name = 'SubscibedTopicsEmailTemplate'];
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        System.debug(userIds);
        List<User> usersList = [Select Id from User WHERE Id IN :userIds AND Daily_Subscription__c = false];
       
        for(User user : usersList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateID(templateId.Id); 
            mail.setSaveAsActivity(false);
            if(!fromId.isEmpty()){
                mail.setOrgWideEmailAddressId(fromId[0].id);
            }
            system.debug('###%%%%% '+user.Id);
            mail.setTargetObjectId(user.Id);
            allmsg.add(mail);
        }
        
        if(!test.isRunningTest()){
            Messaging.sendEmail(allmsg);
        }
        
    }
}