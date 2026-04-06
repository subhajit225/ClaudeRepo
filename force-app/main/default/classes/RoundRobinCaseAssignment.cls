/**
* @File Name : RoundRobinCaseAssignment.cls
* @Description : Used this class for assigning the Customer Success Cases in Round Robin fashion
* @Author : Shailesh Kumar
* @Modification Log :
********************Change Logs ********************************************
* User Story            Modified By          Date               Description
* CS21-3148             Shailesh Kumar	     August 3, 2025		Updated the code to assign cases on alternate days
* CS21-3767             Shailesh Kumar	     Nov 13, 2025		Removed Priority Queue and change in round robin logic
********************Change Logs Ends****************************************
**/
/**
 * @description Used this class for assigning the Customer Success Cases in Round Robin fashion
*/
public with sharing class RoundRobinCaseAssignment {
    public static List<User> csms = new List<User>();
    public static Set<Id> validCSMIds = new Set<Id>();
    public static Map<Id, List<Case>> accountOpenCasesMap = new Map<Id, List<Case>>();
    public static Set<Id> newCaseIds = new Set<Id>();
    public static Map<Id, Case> caseMap = new Map<Id, Case>();
    public static Map<Id, Integer> csmCaseCounts = new Map<Id, Integer>();
    public static Map<Id, Integer> csmToCaseCount = new Map<Id, Integer>();
    public static RoundRobinSetting__c setting = RoundRobinSetting__c.getInstance('LastCSMId');
    public static String lastCSMId = setting.Last_Assigned_CSM__c;
	//Public static Group priorityHighASV = [SELECT Id,Name,Type FROM Group WHERE DeveloperName ='Priority_Queue_Higher_ACV' AND Type = 'Queue' LIMIT 1];
	
	/**
     * @description : Get List of round robined cases with last CSM Id
     * @param  newCases  A list of Customer SUccess Cases going to be assigned to CSMs
     * @return  WrapperRoundRobin list of Cases with last CSM Id going to be updated in custom settings
    */
	public static WrapperRoundRobin assignCasesToCSM(List<Case> newCases) {
		WrapperRoundRobin roundRobinResult = new WrapperRoundRobin();
		roundRobinResult.cases = new List<Case>();

		if (newCases.isEmpty()) return roundRobinResult;

		preloadCSMsFromGroup('CSM_Group');//preload CSMs from Public Group defined for Round Robin 
		preloadOpenCases();//preload open cases

		List<Case> allOpenCases = new List<Case>();
		for (List<Case> clist : accountOpenCasesMap.values()) {
			allOpenCases.addAll(clist);
		}
		List<Case> casesList = [SELECT Id, CaseNumber, OwnerId, Account.Name, AccountId, Phase__c,Product_Name__c, Account.SumOfAcvCloseOpp__c FROM Case WHERE ID IN: newCases];

		for(Case csObj : casesList){
			if(csObj.AccountId!=null){
				caseMap.put(csObj.Id, csObj);
			}
		}

		// Build assignment reference maps
		Map<Id, Id> lastAccountCSMAssignments = new Map<Id, Id>();
		for (Case openCase : allOpenCases) {
			if (openCase.AccountId != null && openCase.OwnerId != null && validCSMIds.contains(openCase.OwnerId)) {
				lastAccountCSMAssignments.put(openCase.AccountId, openCase.OwnerId);
			}
		}

		// Assign incoming cases
		for (Case c : newCases) {
			if (c.Phase__c == 'Onboarding') {
				assignActivationCase(c, lastAccountCSMAssignments);
				lastAccountCSMAssignments.put(c.AccountId, c.OwnerId);
			} else if (c.Phase__c == 'Adoption') {
				assignAdoptionCase(c, lastAccountCSMAssignments);
				lastAccountCSMAssignments.put(c.AccountId, c.OwnerId);
			}
		}
		if(String.isNotBlank(lastCSMId)){
			setting.Last_Assigned_CSM__c = lastCSMId;
		    // if(isTrigger) update setting;
		}
		roundRobinResult.cases = newCases;
		roundRobinResult.lastCSMId = lastCSMId;
        roundRobinResult.csmToCaseCount = new Map<Id, Integer>(csmToCaseCount);
		return roundRobinResult;
	}

    /**
     * @description  Used to preload Open Cases related to account and fill the map
    */
	private static void preloadOpenCases() {
		Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
		for (Case c : [SELECT Id, AccountId, OwnerId, Phase__c, Product_Name__c FROM Case WHERE isClosed = false AND AccountId != null AND RecordTypeId=:successCaseId AND Phase__c IN ('Onboarding','Adoption') Order by CreatedDate ASC]) {
			if (c.AccountId != null) {
				if (!accountOpenCasesMap.containsKey(c.AccountId)) {
					accountOpenCasesMap.put(c.AccountId, new List<Case>());
				}
				accountOpenCasesMap.get(c.AccountId).add(c);
			}
		}
	}

    /**
     * @description Used to assign Cases with Onboarding Phase
     * @param  c  Case object
     * @param lastAccountCSMAssignments  existing accounts and their owners to match with current case
    */
	private static void assignActivationCase(Case c, Map<Id, Id> lastAccountCSMAssignments) {
		Id accountId = c.AccountId;
		List<Id> csmList = new List<Id>(validCSMIds);
		Case csObj = caseMap.get(c.Id);
		if (accountId != null && lastAccountCSMAssignments.containsKey(accountId)) {
			c.OwnerId = lastAccountCSMAssignments.get(accountId);
		} else {
			if(!csmCaseCounts.containsKey(c.OwnerId)){//true only if user is not having cases more than 200
				c.OwnerId =  getNextCSMId();//assign using Round Robin method, for the first time the value will be picked based on even odd method
				lastCSMId = c.OwnerId;
			}
		}
		
	}

	/**
     * @description Used to assign Cases with Adoption Phase
     * @param  c Case object
     * @param lastAccountCSMAssignments existing accounts and their owners to match with current case
    */
	private static void assignAdoptionCase(Case c, Map<Id, Id> lastAccountCSMAssignments) {
		List<Id> csmList = new List<Id>(validCSMIds);
		Case csObj = caseMap.get(c.Id);
		if (c.AccountId != null && lastAccountCSMAssignments.containsKey(c.AccountId)){
			c.OwnerId = lastAccountCSMAssignments.get(c.AccountId);
		}
		else {
			if(!csmCaseCounts.containsKey(c.OwnerId)){//true only if user is not having cases more than 200
				c.OwnerId = getNextCSMId();//assign using Round Robin method, for the first time the value will be picked based on even odd method
				lastCSMId = c.OwnerId;
			}
		}
	}

    /**
     * @description  Used to preload CSMs from Group
     * @param  groupName  CSM Public Group name which holds the list of users the cases will be assigned to
    */
	private static void preloadCSMsFromGroup(String groupName) {
		Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
		csms = [
			SELECT Id, Name FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName =:groupName) AND IsActive = TRUE
			ORDER BY CreatedDate DESC
		];
		
		csmCaseCounts = new Map<Id, Integer>();
		for (AggregateResult ar : [SELECT OwnerId, COUNT(Id) caseCount FROM Case WHERE isClosed = false AND RecordTypeId =: successCaseId  AND OwnerId IN : csms GROUP BY OwnerId]) {
            Integer count = (Integer) ar.get('caseCount');
            csmToCaseCount.put((Id)ar.get('OwnerId'), count);
			if (count > 200) csmCaseCounts.put((Id) ar.get('OwnerId'), count);
		}

		for (User u : csms) {
			validCSMIds.add(u.Id);
		}
	}

    /**
     * @description  Used to return the next CSM Id
     * @return  Id of the CSM going the cases will be assigned to
    */
	private static Id getNextCSMId() {
        Id nextCSMId;
        Integer todayDay = Date.today().day();
		Id lastId = String.isNotBlank(lastCSMId) ? lastCSMId : null; 
		Integer startIndex = 0;
		if(lastId == null && !csms.isEmpty()){
			lastId = Math.mod(todayDay , 2) == 0 ? csms[0].Id : csms[1].Id;
			return lastId;
		}
		if (lastId != null) {
			for (Integer i = 0; i < csms.size(); i++) {
				if (csms[i].Id == lastId) {
					startIndex = Math.mod((i + 1) , csms.size());
					break;
				}
			}
		}
		// Alternate subset daily
		List<User> dailySubset = new List<User>();
		for (Integer i = 0; i < csms.size(); i++) {
			if ((Math.mod(todayDay , 2) == 0 && Math.mod(i , 2) == 0) || (Math.mod(todayDay, 2) != 0 && Math.mod(i , 2) != 0)){
				dailySubset.add(csms[i]);
			}
		}
        /*Loop on CSM for alternate assignment as Each person will get new case assigned on alternate days*/
        for (Integer offset = 0; offset < csms.size(); offset++) {
            Integer idx = Math.mod((startIndex + offset), csms.size());
            User candidate = csms[idx];
            if (dailySubset.contains(candidate)) {
				if (!csmCaseCounts.containsKey(candidate.Id)) {
					updateLastAssignedCSM(candidate.Id);
					nextCSMId = candidate.Id;
					break;
				}
            }
        }
        return nextCSMId;
	}

    /**
     * @description To Update last CSM Id
     * @param csmId ID of the CSM being assigned to lastCMSId
    */
	private static void updateLastAssignedCSM(Id csmId) {
		lastCSMId = csmId; 
	}

	/**
     * @description : Wrapper Class used to return the cases and last CSM Id
    */
	public class WrapperRoundRobin{
        /**
         * @description : cases list to be returned
        */
        @AuraEnabled public List<Case> cases {get;set;}
        /**
         * @description : lastCSMId to be returned to update in custom setting
        */
        @AuraEnabled public String lastCSMId {get;set;}
        /**
         * @description : Map of CSM Id and Case Count
        */
        @AuraEnabled public Map<Id,Integer> csmToCaseCount {get;set;}
        
	}
}