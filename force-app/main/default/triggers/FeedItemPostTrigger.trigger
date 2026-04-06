trigger FeedItemPostTrigger on FeedItem (after insert) {
    Set<Id> ddcIds = new Set<Id>(); //DD25-13
    User u = [SELECT Id,Profile.Name,UserType FROM User WHERE Id =: userinfo.getUserId()];
    if(Trigger.isAfter && u.Profile.Name.contains('Community') && u.UserType=='CspLitePortal'){
        List<id> feedItemIdSet = new list<Id>();
        for(feedItem fi : trigger.new){
            if(fi.Type=='QuestionPost'){
                feedItemIdSet.add(fi.Id);
            }
        }
        
        if( feedItemIdSet!=NULL && !feedItemIdSet.isEmpty()){
            FeedPostCommonHandler.getIdFromTrigger(feedItemIdSet);
        }
    }
    //DD25-13 start
    for(feedItem fi : trigger.new){
            if(fi.ParentId.getSObjectType() == Deal_Desk_Case__c.SObjectType && !fi.body.contains('with follwing comments :')){
               ddcIds.add(fi.ParentId); 
            }
        }
    if(ddcIds != null && !ddcIds.isEmpty()){
        DDCaseTriggerHandler.reOpenCase(ddcIds);
    }
    //DD25-13 end  
}