/**
* @File Name : CaseAssignmentController.cls
* @description : Used to manually assign the cases to Customer Success Managers
* @Modification Log :
********************Change Logs ********************************************
* User Story            Modified By          Date               Description
* CS21-3349             Shailesh Kumar	     April 28, 2025		Created this class
* CS21-3349             Shailesh Kumar	     May 13, 2025		Made a few changes after testing batch job from here.
* CS21-3767             Shailesh Kumar	     Nov 13, 2025		Removed Priority Queue and change in round robin logic
* CS21-3890				Shailesh Kumar		 10-Feb-2026		Added Number of Records parameter to get limited records.
********************Change Logs Ends****************************************
**/

public with sharing class CaseAssignmentController {
	/**
     * @description : Get List of round robined cases with last CSM Id
     * @param : noOfRecords
     * @return : list of Cases with last CSM Id goint to be updated in custom settings
    */
    @AuraEnabled(cacheable=false)
    public static WrapperRoundRobinResult getRoundRobinedCases(Integer noOfRecords) {
        WrapperRoundRobinResult roundRobinResult = new WrapperRoundRobinResult();
        roundRobinResult.roundRobinCases = new List<WrapperCaseDetails>();
        noOfRecords = noOfRecords > 100 ? 50 : noOfRecords;//Guardrails for SQL Injection
        Id customerSuccessQueue = [SELECT Id,Name,Type,Email FROM Group WHERE DeveloperName ='Customer_Success' AND Type = 'Queue'].Id;
        Set<String> phaseTypes = new Set<String>{'Onboarding','Adoption'};
        Map<Id,User> userMapInfo = getUserMap('CSM_Group');
        Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
        List<Case> existingCases = new List<Case>();
        Map<Id, Integer> csmToCaseCount = new Map<Id, Integer>();
        if(Schema.sObjectType.Case.isAccessible()){
            String soql = 'SELECT Id, CaseNumber, AccountId, Account.Name, OwnerId, Phase__c, ' +
                'Product_Name__c, Status, CreatedDate ' +
                'FROM Case ' +
                'WHERE OwnerId = :customerSuccessQueue ' +
                'AND AccountId != null ' +
                'AND RecordTypeId = :successCaseId ' +
                'AND Phase__c IN :phaseTypes ' +
                'AND IsClosed = false ORDER BY CreatedDate ASC ' +
                'LIMIT ' + noOfRecords;
            existingCases = Database.query(soql);
        }
        if(existingCases.size() == 0) return roundRobinResult;//Return empty object if no records available
        RoundRobinCaseAssignment.WrapperRoundRobin roundRobinedCasesResult = RoundRobinCaseAssignment.assignCasesToCSM(existingCases);//get Round Robined Cases with Last CSM Id
        if(roundRobinedCasesResult.cases!=null && !roundRobinedCasesResult.cases.isEmpty()){
            csmToCaseCount = roundRobinedCasesResult.csmToCaseCount;
            AggregateResult[] results = [SELECT COUNT(Id) total FROM Case WHERE isClosed = false AND AccountId != null AND OwnerId =:customerSuccessQueue AND RecordTypeId =:successCaseId AND Phase__c IN :phaseTypes];
            Integer totalCases = (Integer) results[0].get('total');
            for(Case cs : roundRobinedCasesResult.cases){
                WrapperCaseDetails wrapCSDetails = new WrapperCaseDetails();
                wrapCSDetails.id = cs.Id;
                wrapCSDetails.ownerId = cs.OwnerId;
                wrapCSDetails.accountName = cs.Account.Name;
                wrapCSDetails.status = cs.status;
                wrapCSDetails.caseNumber = cs.CaseNumber;
                wrapCSDetails.isEdit = false;
                wrapCSDetails.disabled = true;
                wrapCSDetails.hasQueue =  cs.OwnerId!=null && String.valueOf(cs.OwnerId).startsWith('00G') ? true : false;
                wrapCSDetails.caseLink = '/'+cs.Id;
                wrapCSDetails.productName = cs.Product_Name__c;
                wrapCSDetails.phase = cs.Phase__c;
                wrapCSDetails.csmName = wrapCSDetails.hasQueue ? wrapCSDetails.queueName :  userMapInfo.get(wrapCSDetails.ownerId)?.Name;
                wrapCSDetails.caseCount = (!csmToCaseCount.isEmpty() && csmToCaseCount.containsKey(cs.OwnerId)) ?  csmToCaseCount.get(cs.OwnerId) : 0;
                wrapCSDetails.caseCreatedDate = cs.CreatedDate;
                roundRobinResult.roundRobinCases.add(wrapCSDetails);
            }
            roundRobinResult.lastCSMId = roundRobinedCasesResult.lastCSMId;
            roundRobinResult.totalCaseCount = totalCases;
        }
        return roundRobinResult;
    }
	
    /**
     * @description Get List of round robined cases with last CSM Id
     * @param roundRobinCases  Wrapper of Cases assigned using RR
     * @param lastCSMId  Last Assigned CSM Id to check the index
    */
    @AuraEnabled
    public static void updateCaseOwners(List<WrapperCaseDetails> roundRobinCases, String lastCSMId){
        List<Case> caseListToUpdate = new List<Case>();
        for(WrapperCaseDetails rrCase : roundRobinCases){
            if (rrCase.ownerId != null) { 
                Case cs = new Case(Id = rrCase.id, OwnerId = rrCase.ownerId);
                caseListToUpdate.add(cs);
            }
        }
        if(Schema.sObjectType.Case.isUpdateable() && caseListToUpdate!=null && !caseListToUpdate.isEmpty())
            update caseListToUpdate;
        if(String.isNotBlank(lastCSMId)){
            RoundRobinSetting__c setting = RoundRobinSetting__c.getInstance('LastCSMId');
            setting.Last_Assigned_CSM__c = lastCSMId;
            update setting;
        }
    }

    /**
     * @description Wrapper for Case Details
     * @param csmGroupName
     * @return Map<Id, User> userMap
    */
    @AuraEnabled
    public static Map<Id, User> getUserMap(String csmGroupName) {
        Map<Id, User> userMap = new Map<Id, User>();
        if(Schema.sObjectType.User.isAccessible()){
            userMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName =: csmGroupName) AND IsActive = TRUE]);
        }
        return userMap;
    }
    
    /**
     * @description Get user name if user is changed on UI
     * @param userId
     * @return userName
    */
    @AuraEnabled
    public static String getUserName(String userId){
        String userName = '';
        if(Schema.sObjectType.User.isAccessible()){
            userName = [SELECT Id, Name FROM User WHERE Id=: userId].Name;
        }
        return userName;
    }
    /**
     * @description : Wrapper for Case Details
    */
    public class WrapperCaseDetails{
        /**
         * @description : Case Id
        */
        @AuraEnabled public String id {get;set;}
        /**
         * @description : Owner Id
        */
        @AuraEnabled public String ownerId {get;set;}
        /**
         * @description : account name
        */
        @AuraEnabled public String accountName {get;set;}
        /**
         * @description : Case Status
        */
        @AuraEnabled public String status {get;set;}
        /**
         * @description : Case Number
        */
        @AuraEnabled public String caseNumber {get;set;}
        /**
         * @description : to check the case is in edit mode
        */
        @AuraEnabled public Boolean isEdit {get;set;}
        /**
         * @description : To store Queue Name
        */
        @AuraEnabled public String queueName {get;set;}
        /**
         * @description : Is current case is assigned to a Queue
        */
        @AuraEnabled public Boolean hasQueue {get;set;}
        /**
         * @description : Disable the edit option
        */
        @AuraEnabled public Boolean disabled {get;set;}
        /**
         * @description : Case Link to show on Case Number
        */
        @AuraEnabled public String caseLink {get;set;}
        /**
         * @description : To show the Product Name
        */
        @AuraEnabled public String productName {get;set;}
        /**
         * @description : To store the value of Phase
        */
        @AuraEnabled public String phase {get;set;}
        /**
         * @description : To store CSM Name to be used in Exported File
        */
        @AuraEnabled public String csmName {get;set;}
        /**
         * @description : To store total number of Cases a CSM has
        */
        @AuraEnabled public Integer caseCount {get;set;}
        /**
         * @description : To store Created Date of the Case
        */
        @AuraEnabled public Datetime caseCreatedDate {get;set;}
    }
    /**
     * @description : Wrapper for RR Results
    */
    public class WrapperRoundRobinResult{
        /**
         * @description : List of Case Details
        */
        @AuraEnabled public List<WrapperCaseDetails> roundRobinCases {get;set;}
        /**
         * @description : Last Assigned CSM Id
        */
        @AuraEnabled public String lastCSMId {get;set;}
        /**
         * @description : Total Case Count
        */
        @AuraEnabled public Integer totalCaseCount {get;set;}
    }
}