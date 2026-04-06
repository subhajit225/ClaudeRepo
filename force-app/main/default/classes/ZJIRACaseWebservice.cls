/** 
 * @Author      : Veera Gandi
 * @CreatedDate : 25th August 2021
 * @Description : Class handles API calls to JIRA from Salesforce
 * @TstClass    : ZJIRACaseWebserviceTest
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1261   		  Vijay Kumar K R        May 23, 2023     Enable Case Owner Manager from SFDC to display in JIRA 
 * --------------------------------------------------------------------------------------------------------------------------------
 */
public class ZJIRACaseWebservice {
    
    @TestVisible
    private static boolean byPassCallout = false; //boolean to use in test classes
    
    /**
    * @description method invoked from zIssue Object on after insert/update, to construct a map of Jira Issue Key > Salesforce Case Number.
    * and send case owner updates to JIRA 
    * @param newList - Trigger context variable trigger.new
    * @param oldMap - Trigger context variable trigger.oldMap
    * @return void
    */
    public static void sendCaseDetailsToJira(List<zsfjira__ZIssue__c> newList, 
                                             Map<Id, zsfjira__ZIssue__c> oldMap) {
        Map<String, String> issueDetails = new Map<String, String>();
        Map<String, String> caseDetails;
        
        for (zsfjira__ZIssue__c eachIssue : newList) {
            //when case is inserted
            //updated and salesforce ticket number is changed
            if ((trigger.isInsert || (trigger.isUpdate && eachIssue.SalesforceTicket__c != oldMap.get(eachIssue.Id).SalesforceTicket__c))
                && eachIssue.zsfjira__IssueType__c == 'Customer Bug') {
                    issueDetails.put(eachIssue.zsfjira__IssueKey__c, eachIssue.SalesforceTicket__c);
            }
        }
        
        if (!issueDetails.isEmpty()
            && !system.isFuture() 
            && !system.isBatch()
            && !system.isQueueable() 
            && !system.isScheduled()) {
                sendCaseOwnerDetailsToJira(issueDetails);
        } 
    }
    
    /**
    * @description method is called from JIRA issue trigger, when Jira Issue is created/Updated.
    * collects the required Case details to sends updates to JIRA accordingly
    * @param  issueDetails  map with JiraIssueKey (Key) > CaseNumber(Value).
    * @return void
    */
    @future(Callout=true)
    public static void sendCaseOwnerDetailsToJira(Map<String, String> issueDetails) {
        try {
            //construct case details map with CaseNumber(key) > CaseOwnerEmail(Value)
            Map<String, Object> caseDetails = getCaseNumberAndCaseOwnerDetails(new Set<String>(issueDetails.values()));
            sendUpdatesToJIRA(issueDetails, caseDetails);
        } catch (exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error ::' + ex.getStackTraceString() + ' : ' + ex.getMessage());
        }
    }
    
    /**
    * @description method to get Case owner details of each case.
    * and construct a map of Salesforce Case Number > Case Owner.
    * @param  caseNumbers  set of case ids.
    * @return void
    */
    private static Map<String, Object> getCaseNumberAndCaseOwnerDetails(Set<String> caseNumbers) {
        Map<String, Object> caseDetails = new Map<String, Case>();
        
        //collects all the jira issue details associated with the case
        for (Case eachCase : [SELECT CaseNumber, Owner_s_Email__c, Owner_Manager_Email__c
                               FROM Case
                               WHERE CaseNumber IN :caseNumbers]) {
            caseDetails.put(eachCase.CaseNumber, eachCase);
        }
        
        return caseDetails;
    }
    
    /**
    * @description method is called from case trigger when case owner is updated on the case.
    * collects the required jira issue details to sends updates to JIRA accordingly
    * @param  caseDetails  map with CaseNumber (Key) > Case Owner(Value).
    * @return void
    */
    @future(Callout=true)
    public static void sendCaseOwnerUpdatesToJira(String caseDetails) {
        try {
            Map<String, Object> caseDetailObj = (Map<String, Object>)JSON.deserializeUntyped(caseDetails);
            //construct jira details map with JiraIssueKey(key) > CaseNumber(Value)
            Map<String, String> issueDetails = getJIRAIssueAndSalesforceTicketDetails(caseDetailObj.keySet());
            sendUpdatesToJIRA(issueDetails, caseDetailObj);
        } catch (exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error ::' + ex.getStackTraceString() + ' : ' + ex.getMessage());
        }
    }
    
    /**
    * @description method to get all the Jira issues where salesforce cases is associated as the original case (Salesforce Ticket in JIRA).
    * and construct a map of Jira Issue Key > Salesforce Case Number.
    * @param  caseNumbers  set of case ids.
    * @return void
    */
    private static Map<String, String> getJIRAIssueAndSalesforceTicketDetails(Set<String> caseNumbers) {
        Map<String, String> issueDetails = new Map<String, String>();
        
        //collects all the jira issue details associated with the case
        for (zsfjira__ZIssue__c  eachIssue : [SELECT SalesforceTicket__c, zsfjira__IssueKey__c
                                              FROM zsfjira__ZIssue__c
                                              WHERE SalesforceTicket__c IN :caseNumbers]) {
            issueDetails.put(eachIssue.zsfjira__IssueKey__c, eachIssue.SalesforceTicket__c);
        }
        
        return issueDetails;
    }
    
    /**
    * @description method will collects details required to be sent to JIRA and makes callout to JIRA.
    * @param  issueDetails  map of jira issue id and issue key.
    * @return void
    */
    private static void sendUpdatesToJIRA(Map<String, String> issueDetails, Map<String, Object> caseDetails) {
        List<zsfjira.ZCBeans.IssueTemplate> jiraIssueTemplates = new List<zsfjira.ZCBeans.IssueTemplate>();
        String jiraField = Label.ZJiraCustomField ; //label to store JIRA field api name. e.g., customfield_13178
        // CS21-1261: Jira Case Owner Manager Email Field API
        String jiraCaseOwnerManagerField = Label.ZJiraCustomCaseOwnerManagerEmailField ; //label to store JIRA field api name. e.g., customfield_13460

        if (!issueDetails.isEmpty()) {
            //parse through jira issues to send case owner updates
            //get case owner from caseDetails Map and construct JIRA template to send owner updates
            for (String eachIssueKey : issueDetails.keySet()) {
                //CaseNumber on Jira Issue in Salesforce Ticket field (Original Case of the JIRA Issue)
                String salesforceTicket = issueDetails.get(eachIssueKey);
                
                Object objTyp = caseDetails.get(salesforceTicket);
                Case objCase = (Case)JSON.deserialize(JSON.serialize(objTyp), Case.class);
                
                zsfjira.ZCBeans.IssueTemplate template = new zsfjira.ZCBeans.IssueTemplate(eachIssueKey);

                // if Case Owner is not blank
                if (String.isNotBlank(objCase.Owner_s_Email__c)) {
                    template.addCustomField(jiraField, objCase.Owner_s_Email__c);
                } 
                // CS21-1261: if Customer Case Owner Manager Email is not blank
                if (String.isNotBlank(objCase.Owner_Manager_Email__c)) {
                    template.addCustomField(jiraCaseOwnerManagerField, objCase.Owner_Manager_Email__c); 
                } 
                jiraIssueTemplates.add(template);
            }  
        }
        System.debug('jiraIssueTemplates:: '+jiraIssueTemplates);
        
        if (!jiraIssueTemplates.isEmpty() && !byPassCallout) {
            // JIRA callout
            List<zsfjira.ZCBeans.IssueUpsertResult> upsertResults = zsfjira.ZC.Issues.bulkUpdateIssues(jiraIssueTemplates);
            
            for (zsfjira.ZCBeans.IssueUpsertResult result : upsertResults) {
                if(result.hasError()){ 
                    System.debug(System.LoggingLevel.ERROR, JSON.serialize(result.getErrorMessages())); 
                }
            }
        }
    }
}