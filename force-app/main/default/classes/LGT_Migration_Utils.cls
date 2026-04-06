public class LGT_Migration_Utils {
    public static List<Case> getCaseRecForAllComponents(Id caseId){
        List<Case> caseList = [SELECT Id,Subject,Description,Owner.Name,Case_Severity__c,Case_Account_SAM__c,IsEscalated,Next_Step__c,CT_Temperature__c,Region__c,Contact_method__c,Status,Origin,Priority,Current_Status__c,
                            Platform__c,Problem_Type__c,Sub_Component__c,Software_Version__c,Account.Heads_Up_to_Support_Team__c,Account_Preference__c,Account.Account_Preference__c,
                            KCS_Article_Candidate__c,KCS_Article_Status__c,Supportability_Improvement_Requested__c,KCS_or_Supportability_comments__c,Resolution_Details__c,LastModifiedBy.Name,CreatedDate,Documentation_Type__c  
                            FROM Case Where Id =: caseId];  
        return caseList;
    }
}