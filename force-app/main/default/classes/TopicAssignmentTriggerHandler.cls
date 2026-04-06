public class TopicAssignmentTriggerHandler {
    public static void createSubscriptionForOwner(List<TopicAssignment> newTopicAssignments){
        Set<Id> EntityIds = new Set<Id>();
        for(TopicAssignment ta : newTopicAssignments){
            if(ta.EntityType == 'FeedItem')
                EntityIds.add(ta.EntityId);
        }
        
        Map<Id,FeedItem> feedItemMap = new Map<Id,FeedItem>([SELECT Id, ParentId, Type, NetworkScope FROM FeedItem where Id IN : EntityIds ]);
        
        if(!feedItemMap.isEmpty()){
            for(TopicAssignment ta : newTopicAssignments){
                if(String.valueof(feedItemMap.get(ta.EntityId).ParentId).startsWith('005') && feedItemMap.get(ta.EntityId).Type == 'QuestionPost' && feedItemMap.get(ta.EntityId).NetworkScope == system.label.networkScope){
                    SubscribePostController.addBookMark(system.label.networkScope, ta.EntityId , true);
                }
            }
        }
    }
}