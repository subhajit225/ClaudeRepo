/**
* @description Controller class for RubrikRecognitionBadges Aura Component,
* Class the badges awarded to the Forum Member
*
* @CreatedDate 5th August 2021
* @Created By Veera Gandi
* 
*/
public without sharing class RubrikRecognitionBadgeController {
    
	/**
    * @description method fetches logged in User Badges.
    * @param UserId of the currentUser
    * @return Wrapper
    */
    @AuraEnabled(cacheable=true)
    public static List<Badge> getRecognitionBadges(string userId) {
        String customerCommunityId = [SELECT Id FROM Network WHERE Name = :Label.ForumCommunityName].Id;
        Map<Id, Badge> badges = new Map<Id, Badge>();
        
        /* Commented for next phase
         * 
         for (WorkBadgeDefinition eachBadgeDefinition : [SELECT Id, Name, Description, ImageUrl 
                                                        FROM WorkBadgeDefinition
                                                        WHERE IsActive = true
                                                        AND NetworkId = :customerCommunityId
                                                        ORDER BY Name DESC]) 
        {
            badges.put(eachBadgeDefinition.Id, new Badge(eachBadgeDefinition.Name, eachBadgeDefinition.Description, eachBadgeDefinition.ImageUrl));
        }
        
        for (WorkBadge  eachBadge : [SELECT Id, DefinitionId
                                     FROM WorkBadge
                                     WHERE RecipientId = :userId
                                     AND NetworkID = :customerCommunityId
                                    ]) 
        {
            if (badges.containsKey(eachBadge.DefinitionId)) {
                badges.get(eachBadge.DefinitionId).isAwarded = true;
            }
        }*/
        
        for (WorkBadge  eachBadge : [SELECT Id, DefinitionId, Definition.Name, Definition.Description, Definition.ImageUrl
                                     FROM WorkBadge
                                     WHERE RecipientId = :userId
                                     AND NetworkID = :customerCommunityId
                                     AND Definition.IsActive = true
                                     ORDER BY Definition.Name DESC]) 
        {
            badges.put(eachBadge.DefinitionId, new Badge(eachBadge.Definition.Name, eachBadge.Definition.Description, eachBadge.Definition.ImageUrl));
            badges.get(eachBadge.DefinitionId).isAwarded = true;
            
        }
        
        return badges.values();
    }
    
    /**
    * @description Wrapper class to construct Forum User badges
    */
    public class Badge {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String imageurl;
        @AuraEnabled
        public Boolean isAwarded = false;
        
        public badge(string name, string description, string imageurl) {
            this.name = name;
            this.description = description;
            this.imageurl = imageurl;
        }
    }

}