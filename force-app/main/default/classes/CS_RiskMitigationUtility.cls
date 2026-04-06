/**
* @File Name : CS_RiskMitigationUtility.cls
* @Description : Get watchers and governance owners
* @Author : Sushant Arora
* @Last Modified By :
* @Last Modified On : September 18, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 18, 2024 |   | Initial Version
**/

public class CS_RiskMitigationUtility {
    public class CS_RiskMitigationUtilityException extends Exception {}
	
	/**
     * @Description Gets watcher related to the risk profile.
     * @param riskProfiles The risk profile to get watchers for.
     * @return Map<Id, Set<Id>> The map of risk profile to watchers.
     */
    public static Map<Id, Set<Id>> getWatchers(Risk_Profile__c[] riskProfiles) {
        Map<Id, Set<Id>> riskprofileToWatcherId = new Map<Id, Set<Id>>();
        for (Risk_Profile_Watcher__c watcher : [SELECT Watcher__c,Risk_Profile__c FROM Risk_Profile_Watcher__c WHERE Risk_Profile__c IN :riskProfiles]) {
            Set<Id> watcherIds = riskprofileToWatcherId.containsKey(watcher.Risk_Profile__c) ? riskprofileToWatcherId.get(watcher.Risk_Profile__c) : new Set<Id>();
            watcherIds.add(watcher.Watcher__c);
            riskprofileToWatcherId.put(watcher.Risk_Profile__c, watcherIds);
        }
        return riskprofileToWatcherId;
    }

    /**
     * @Description Gets the governance queue members
     * @return List<Id> The list of ids of members.
     */
    public static List<Id> getGovernanceOwners() {
        Group governanceGroup = [SELECT Id FROM Group WHERE DeveloperName = :System.Label.Risk_Profile_Governance_Queue LIMIT 1];
        List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :governanceGroup.Id];
        Set<Id> ownerIds = new Set<Id>();
        
        for (GroupMember gm : groupMembers) {
            ownerIds.add(gm.UserOrGroupId);
        }
        return new List<Id>(ownerIds);
    }
}