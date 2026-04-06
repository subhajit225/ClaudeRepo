/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   08-08-2022
* @Jira Ticket  :   CS21-1100 - Forums 2.0 Rewards Redemption/Swag Store
* @Description  :   This class is the trigger handler for NetworkMemberTrigger.
* @TestClass    :   NetworkMemberTriggerHandlerTest
*/
public without sharing class NetworkMemberTriggerHandler {

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   08-08-2022
    * @Description  :   Calculate and update coins on the user record when points are added to a Support portal user
    */
    public static void updateUserCoins(List<NetworkMember> memberList, Map<Id, NetworkMember> oldMemberMap){
        Decimal coinValue = Decimal.valueOf(Label.Coin_Value);
        String customerCommunityId = Label.NetworkId;
        Set<Id> userIdSet = new Set<Id>();

        //Prepare user id set only for Support portal users
        for(NetworkMember member : memberList){
            if(member.NetworkId == customerCommunityId && member.ReputationPoints != oldMemberMap.get(member.Id).ReputationPoints
                && member.ReputationPoints != null && member.ReputationPoints > oldMemberMap.get(member.Id).ReputationPoints){
                    userIdSet.add(member.MemberId);
            }
        }

        if(!userIdSet.isEmpty()){
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Coins__c FROM User WHERE Id IN :userIdSet]);

            for(NetworkMember member : memberList){
                if(userMap.containsKey(member.MemberId)){
                    Integer currentReputationPoints = Integer.valueOf(member.ReputationPoints);
                    Integer oldReputationPoints = oldMemberMap.get(member.Id).ReputationPoints == null ? 0 : Integer.valueOf(oldMemberMap.get(member.Id).ReputationPoints);
                    userMap.get(member.MemberId).Coins__c = (userMap.get(member.MemberId).Coins__c + ((currentReputationPoints - oldReputationPoints)/coinValue)).round(System.RoundingMode.FLOOR);
                }
            }
            Database.update(userMap.values(), false);
        }
    }
}