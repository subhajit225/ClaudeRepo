/**
 * Author       :   Abhishek Mahajan
 * CreatedDate  :   26th September 2023
 * Description  :   Controller for jiraAndAhaCases
 * TestClass    :   CasesWithJiraAhaRefrencesControllerTest
 */
public class CasesWithJiraAhaRefrencesController {
    
    /**
     * @description get with aha refrences associated with cases/opportunities of account
     * 
     * @param accountId The ID of the Account for which aha refrences are requested.
     * @param isClosed true for  closed aha refrences, false for aha jira refrences
     * @return List of Aha_Ideas__c
     */
    @AuraEnabled
    public static List<Aha_Ideas__c> getAhaRecords(String accountId, Boolean isClosed)
    {
        List<Aha_Ideas__c> ahaIdeasList = new List<Aha_Ideas__c>();
        List<String> closedAhaStatuses = System.Label.Closed_AHA_Status.split(',');
        try {
            if(isClosed){
                ahaIdeasList = [SELECT Id, Name, Aha_Idea_Number__c, Aha_Unique_ID__c, External_Unique_Id__c,
                                Idea_Category__c, Idea_Description__c, Impacted_Customers__c, Problem_Statement__c, 
                                Product_Area__c, Product_Component__c, Status__c FROM Aha_Ideas__c 
                                WHERE Id IN 
                                    (SELECT Aha_Ideas__c 
                                    FROM Aha_Idea_Link__c 
                                    WHERE  Opportunity_Name__r.AccountId = :accountId OR Case_Number__r.AccountId = :accountId)
                                AND (status__c IN :closedAhaStatuses)];
            }else {ahaIdeasList = [SELECT Id, Name, Aha_Idea_Number__c, Aha_Unique_ID__c, External_Unique_Id__c,
                                Idea_Category__c, Idea_Description__c, Impacted_Customers__c, Problem_Statement__c,
                                    Product_Area__c, Product_Component__c, Status__c FROM Aha_Ideas__c 
                                    WHERE Id IN 
                                    (SELECT Aha_Ideas__c 
                                    FROM Aha_Idea_Link__c 
                                    WHERE  Opportunity_Name__r.AccountId = :accountId OR Case_Number__r.AccountId = :accountId)
                                AND (NOT status__c IN :closedAhaStatuses)];} }
        catch (Exception ex) {throw new AuraHandledException('An error occurred: ' + ex.getMessage());} return ahaIdeasList;
    }
    /**
     * @description get jira refrences associated with cases of account
     * 
     * @param accountId The ID of the Account for which jira refrences are requested.
     * @param isClosed true for  closed jira refrences, false for open jira refrences
     * @return List of zsfjira__ZIssue__c
     */
    @AuraEnabled
    public static List<zsfjira__ZIssue__c> getJiraRecords(String accountId, Boolean isClosed)
    {
        List<zsfjira__ZIssue__c> jiraList = new List<zsfjira__ZIssue__c>();
        List<String> closedJiraStatuses = System.Label.Closed_Jira_Status.Split(',');
        
        List<String> issueKeys = System.Label.JIRA_Issue_Key.split(',');
        
        try{
            if(isClosed){
                jiraList= [SELECT Id, Name, zsfjira__Summary__c, zsfjira__Prioriy__c, Fixed_in_Version__c, zsfjira__Resolution__c, zsfjira__Status__c, Release_Notes_Candidate__c, Resolution_Details__c 
                            FROM zsfjira__ZIssue__c 
                            WHERE Id IN 
                                (SELECT zsfjira__ZIssueId__c 
                                FROM zsfjira__ZIssue_Case__c 
                                WHERE zsfjira__CaseId__r.AccountId = :accountId)
                            AND (zsfjira__Status__c IN :closedJiraStatuses)
                            AND zsfjira__IssueKey__c LIKE :issueKeys ];
            }else {
                jiraList= [SELECT Id, Name, zsfjira__Summary__c, zsfjira__Prioriy__c, Fixed_in_Version__c, zsfjira__Resolution__c, zsfjira__Status__c, Release_Notes_Candidate__c, Resolution_Details__c
                            FROM zsfjira__ZIssue__c 
                            WHERE Id IN 
                                (SELECT zsfjira__ZIssueId__c 
                                FROM zsfjira__ZIssue_Case__c 
                                WHERE zsfjira__CaseId__r.AccountId = :accountId) 
                            AND (NOT zsfjira__Status__c IN :closedJiraStatuses) 
                            AND zsfjira__IssueKey__c LIKE :issueKeys ]; }}
        catch (Exception ex) { throw new AuraHandledException('An error occurred: ' + ex.getMessage()); }return jiraList;
    }

    /**
     * @description get Checklists associated with the account's Playbook's Tasks
     * 
     * @param accountId The ID of the Account for which jira refrences are requested.
     
     * @return List of Checklist__c
     */
    @AuraEnabled
    public static List<Checklist__c> getChecklistRecords(String accountId)
    {
        return [SELECT Id, Name, Completed__c, Due_Date__c, Description__c, Sub_Task__r.Name  
                FROM Checklist__c 
                WHERE Sub_Task__r.Playbook__r.Account__c = :accountId 
                AND Completed__c = false ORDER BY Due_Date__c NULLS LAST];
    }
}