/** 
 * @Author      : Veera Gandi
 * @CreatedDate : 7th Nov 2021
 * @Description : Batch Job to update Case Owner in JIRA.This is a one time job to sync Case Owner Email in JIRA with salesforce Case Owner
 * @TstClass    : RollupCaseCommentsCountOnCaseBatchTest
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * on Cases - JIRA - CS21-791
 * CS21-1261   		  Vijay Kumar K R        May 23, 2023     Enable Case Owner Manager from SFDC to display in JIRA 
 * --------------------------------------------------------------------------------------------------------------------------------
 */
public class SFJIRACaseOwnerUpdateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
    public String query;
    
    /**
    * @description Constructor to get batch job query to be executed in start method.
    * query eg: SELECT SalesforceTicket__c, zsfjira__IssueKey__c FROM zsfjira__ZIssue__c WHERE zsfjira__IssueType__c = 'Customer Bug'
    * 1261: Using Below Query: Since Some of SalesforceTicket__c can have multiple caseNumbers
    * query eg: SELECT Id, zsfjira__CaseId__c, zsfjira__CaseId__r.CaseNumber,  zsfjira__ZIssueId__r.zsfjira__IssueKey__c, zsfjira__ZIssueId__r.SalesforceTicket__c, CreatedDate  
                FROM zsfjira__ZIssue_Case__c 
                WHERE zsfjira__ZIssueId__r.zsfjira__IssueType__c = 'Customer Bug' 
                Order by CreatedDate ASC
        SFJIRACaseOwnerUpdateBatch objBatch = new SFJIRACaseOwnerUpdateBatch(query); 
        database.executeBatch(objBatch); 
    */
    public SFJIRACaseOwnerUpdateBatch(string query){       
        this.query = query;
    }
    
    /**
    * @description start method runs at the beginning of a batch Apex job which collects the records or objects to pass to the execute method. 
    * @param  BatchableContext - Database.BatchableContext
    * @return Database.QueryLocator - List of JIRA Issues
    */
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description execute method is called for each batch of records that you pass to it
    * @param  BatchableContext - Database.BatchableContext
    * @param  accounts - List of JIRA Issues
    * @return void
    */
    public void execute(Database.BatchableContext batchableContext, List<zsfjira__ZIssue_Case__c> zIssueCases){
        List<zsfjira.ZCBeans.IssueTemplate> jiraIssueTemplates = new List<zsfjira.ZCBeans.IssueTemplate>();
        String jiraField = Label.ZJiraCustomCaseOwnerManagerEmailField ; //label to store JIRA field api name. e.g., customfield_13178
        
        Map<String, String> caseDetails = new Map<String, String>();
        Map<String, String> issueDetails = new Map<String, String>();
        
        //JIRA Issue details for which Case Owner Email needs to be updated in JIRA
        for (zsfjira__ZIssue_Case__c  eachIssueCase : zIssueCases) {
            if(!issueDetails.containsKey(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c)){
                issueDetails.put(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c, eachIssueCase.zsfjira__CaseId__r.CaseNumber);
            }
        }
        
        //collects Case Owner details to be sent to JIRA
        for (Case  eachCase : [SELECT CaseNumber, Owner_s_Email__c, Owner_Manager_Email__c
                               FROM Case
                               WHERE CaseNumber IN :issueDetails.values()]) 
        {
            caseDetails.put(eachCase.CaseNumber, eachCase.Owner_Manager_Email__c);
        }
        
        if (!issueDetails.isEmpty()) {
            //parse through jira issues to send case owner updates
            //get case owner from caseDetails Map and construct JIRA template to send owner updates
            for (String eachIssueCaseKey : issueDetails.keySet()) {
                //CaseNumber on Jira Issue in Salesforce Ticket field (Original Case of the JIRA Issue)
                String salesforceTicket = issueDetails.get(eachIssueCaseKey);
                String caseOwnerEmail = caseDetails.containsKey(salesforceTicket) ? caseDetails.get(salesforceTicket) : '';
                
                //if Case Owner is not blank
                if (String.isNotBlank(caseOwnerEmail)) {
                    zsfjira.ZCBeans.IssueTemplate template = new zsfjira.ZCBeans.IssueTemplate(eachIssueCaseKey);
                    template.addCustomField(jiraField, caseDetails.get(salesforceTicket)); 
                    jiraIssueTemplates.add(template);
                } 
            }  
        }
        
        if (!jiraIssueTemplates.isEmpty() && !Test.isRunningTest()) {
            //JIRA callout
            List<zsfjira.ZCBeans.IssueUpsertResult> upsertResults = zsfjira.ZC.Issues.bulkUpdateIssues(jiraIssueTemplates);
            
            for (zsfjira.ZCBeans.IssueUpsertResult result : upsertResults) {
                if(result.hasError()){ 
                    System.debug(System.LoggingLevel.ERROR, JSON.serialize(result.getErrorMessages())); 
                }
            }
        }
    }
    
    /**
    * @description finish is to execute post-processing operations
    * @param  batchableContext - Database.BatchableContext
    * @return void
    */
    public void finish(Database.BatchableContext batchableContext){
        System.debug(LoggingLevel.DEBUG, 'Salesforce to JIRA Case Owner updates.');
    }
}