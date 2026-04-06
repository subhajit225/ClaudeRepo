public class requestToInformationController {
    @AuraEnabled( cacheable = true )
    public static List<sbaa__Approval__c> fetchApprovalRecord(String recordId) {
        return [SELECT Id FROM sbaa__Approval__c WHERE Id =:recordId LIMIT 100];
    }
}