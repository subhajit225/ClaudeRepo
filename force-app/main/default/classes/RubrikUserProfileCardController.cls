/**
* @description Controller class for RubrikUserProfileCard Aura Component,
* Class fetches logged in user details
*
* @CreatedDate 5th August 2021
* @Created By Veera Gandi
* 
*/
public without sharing class RubrikUserProfileCardController {
    
    /**
    * @description method fetches logged in user details and reputation points.
    * @param UserId of the currentUser
    * @return Wrapper
    */
    @AuraEnabled(cacheable=true)
    public static CommunityUserProfileInformation getUserDetails(String userId) {
        try {
            String customerCommunityId = Label.NetworkId;
            List<String> moderatorPermissionSetIds = label.ForumModerators.split(',');
            Id rcsaBadgeDefinitionId = Label.RCSABadgeId;
            
            
            List<ReputationLevel> reputationLevels = [SELECT Id, Label, Threshold, LevelNumber FROM ReputationLevel 
                                                      WHERE ParentId = :customerCommunityId
                                                      ORDER BY Threshold DESC];
            
            List<NetworkMember> networkMembers = [SELECT Id, NetworkId, Member.Name, Member.CommunityNickname, ReputationPoints,
                                                  Member.Account.Name, Member.Alias, Member.SmallPhotoUrl, MemberId
                                                  FROM NetworkMember 
                                                  WHERE MemberId = :userId
                                                  AND NetworkId = :customerCommunityId
                                                  LIMIT 1];
            
            CommunityUserProfileInformation profileInformation = new CommunityUserProfileInformation();
            profileInformation.fullName = networkMembers[0].Member.CommunityNickname;
            profileInformation.reputationPoints = (Integer) networkMembers[0].ReputationPoints;
            profileInformation.photoURL = (String) networkMembers[0].Member.SmallPhotoUrl;
            profileInformation.userId = (String) networkMembers[0].MemberId;
            
            List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id, AssigneeId 
                                                                      FROM PermissionSetAssignment 
                                                                      WHERE PermissionSetId IN :moderatorPermissionSetIds
                                                                      AND AssigneeId = :userId
                                                                      AND IsActive = true
                                                                      LIMIT 1];
            if (!permissionSetAssignments.isEmpty()){
                profileInformation.isModerator = true;
            }
            
            if (!reputationLevels.isEmpty()) {
                for (ReputationLevel reputation : reputationLevels) {
                    if (networkMembers[0].ReputationPoints >= reputation.Threshold) {
                        profileInformation.reputationLevelNumber = reputation.LevelNumber;
                        profileInformation.reputationName = reputation.Label;
                        break;
                    }
                }                
            }
            
            if (networkMembers[0].ReputationPoints > 9999) {
                List<WorkBadge> badges = [SELECT Id FROM WorkBadge WHERE NetworkID = :customerCommunityId 
                                          AND RecipientId = :userId
                                          AND DefinitionId = :rcsaBadgeDefinitionId];
                
                if (!badges.isEmpty()) {
                    profileInformation.reputationName = Label.RubrikGrandMaster;
                }
            }
            
            return profileInformation;
        } catch (exception ex) {
            throw new AuraHandledException('Error : ' + ex.getMessage());
        }
    }
    
    /**
    * @description Wrapper class to construct Community User Profile Object
    */
    public class CommunityUserProfileInformation {
        @AuraEnabled
        public String fullName;
        @AuraEnabled
        public Integer reputationLevelNumber;
        @AuraEnabled
        public String reputationName;
        @AuraEnabled
        public Integer reputationPoints;
        @AuraEnabled
        Public Boolean isModerator;
        @AuraEnabled
        Public String photoURL;
        @AuraEnabled
        Public String userId;
    }

}