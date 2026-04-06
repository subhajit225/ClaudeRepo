public without sharing class TopicInfoController {
    
    @AuraEnabled
    public static Topic  getTopicInfo(String networkId,String topicId ){
        
        Topic selectedTopic;
        if(string.isNotEmpty(networkId) && string.isNotEmpty(topicId)){
            
            selectedTopic=[SELECT Id, NetworkId, Name, Description, ManagedTopicType, SystemModstamp, TalkingAbout FROM Topic WHERE  Id=:topicId and NetworkId=:networkId];
            
        }
        
        
        return selectedTopic;
        
    }
    
}