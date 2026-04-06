/** 
* @Author      : Raveesh Layal
* @CreatedDate : 18th July 2023
* @Description : Add Cluster Id and Additional Cluster ID information on JIRA for legacy cases
* @TstClass    : SFJIRACaseClusterUpdateBatchTest
* @Jira		   : CS21-1820 

* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1893         Raveesh Layal     16th August, 2023      Check for first occurrence 		           
* --------------------------------------------------------------------------------------------------------------------------------
*/
public class SFJIRACaseClusterUpdateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
 public String query;
    
    /**
    * @description Constructor to get batch job query to be executed in start method.
    * query eg: SELECT SalesforceTicket__c, zsfjira__IssueKey__c FROM zsfjira__ZIssue__c WHERE zsfjira__IssueType__c = 'Customer Bug'
    * 1261: Using Below Query: Since Some of SalesforceTicket__c can have multiple caseNumbers
       * query eg: 'SELECT Id, zsfjira__CaseId__c, zsfjira__CaseId__r.CaseNumber, ' +
                        'zsfjira__ZIssueId__r.zsfjira__IssueKey__c, zsfjira__ZIssueId__r.SalesforceTicket__c, ' +
                        'CreatedDate, zsfjira__ZIssueId__r.zsfjira__Project__c, zsfjira__ZIssueId__r.zsfjira__IssueType__c ' +
                        'FROM zsfjira__ZIssue_Case__c ' +
                        'WHERE (zsfjira__ZIssueId__r.zsfjira__IssueKey__c LIKE \'%CDM%\' AND ' +
                        'zsfjira__ZIssueId__r.zsfjira__IssueType__c IN (\'Customer bugs\', \'Customer Impact analysis\', ' +
                        '\'CLA\', \'Supportability\', \'Usability\', \'Improvement\')) OR ' +
                        '(zsfjira__ZIssueId__r.zsfjira__IssueKey__c LIKE \'%SPARK%\' AND ' +
                        'zsfjira__ZIssueId__r.zsfjira__IssueType__c IN (\'Customer bugs\', \'Customer Impact analysis\', ' +
                        '\'CLA\', \'Supportability\', \'Usability\')) ' +
                        'ORDER BY CreatedDate ASC';
        SFJIRACaseClusterUpdateBatch objBatch = new SFJIRACaseClusterUpdateBatch(query); 
        database.executeBatch(objBatch); 
    */
    public SFJIRACaseClusterUpdateBatch(string query){       
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
        String Jira_Cluster_Field_API=Label.Jira_Cluster_Field_API;
        String Jira_Additional_Cluster_Field_API=Label.Jira_Additional_Cluster_Field_API;
 
        Map<String, String> issueDetails = new Map<String, String>();
        Map<string,case> caseNumberToCluster= new  Map<string,case>(); 
           Map<String, Id> issueFirstOccurrence = new Map<String, Id>();
   
        
        //JIRA Issue details for which Case Owner Email needs to be updated in JIRA
        for (zsfjira__ZIssue_Case__c  eachIssueCase : zIssueCases) {
            if(!issueDetails.containsKey(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c)){
                issueDetails.put(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c, eachIssueCase.zsfjira__CaseId__r.CaseNumber);
            }
        }
        
        //collects Case Owner details to be sent to JIRA
        for (Case  eachCase : [SELECT CaseNumber,Additional_Cluster__r.name,Cluster__r.name
                               FROM Case
                               WHERE CaseNumber IN :issueDetails.values()]) 
        {
           
            caseNumberToCluster.put(eachCase.CaseNumber,eachCase);
        }
         
           if (!issueDetails.isEmpty()) 
           {
               //CS21-1893
               for(zsfjira__ZIssue_Case__c  eachIssueCase: [SELECT Id,zsfjira__ZIssueId__r.zsfjira__IssueKey__c,zsfjira__ZIssueId__r.zsfjira__IssueType__c,zsfjira__CaseId__r.Cluster__r.name ,zsfjira__CaseId__r.Additional_Cluster__r.name
                                                            FROM zsfjira__ZIssue_Case__c where zsfjira__ZIssueId__r.zsfjira__IssueKey__c IN: issueDetails.keySet() order by createddate asc]){
                                                                if(!issueFirstOccurrence.containsKey(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c)){
                                                                    issueFirstOccurrence.put(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c,eachIssueCase.zsfjira__CaseId__c);
                                                                }
                                                                
                                                                
                                                            }
               //CS21-1893 Ends
            //parse through jira issues to send case owner updates
            //get case owner from caseDetails Map and construct JIRA template to send owner updates
           
            for (String eachIssueCaseKey : issueDetails.keySet()) {
                //CaseNumber on Jira Issue in Salesforce Ticket field (Original Case of the JIRA Issue)
                String salesforceTicket = issueDetails.get(eachIssueCaseKey);

                   if (String.isNotBlank(salesforceTicket) && issueFirstOccurrence.containsKey(eachIssueCaseKey) && issueFirstOccurrence.get(eachIssueCaseKey)==caseNumberToCluster.get(salesforceTicket).Id) {
                    zsfjira.ZCBeans.IssueTemplate template = new zsfjira.ZCBeans.IssueTemplate(eachIssueCaseKey);
                    template.addCustomField(Jira_Additional_Cluster_Field_API, caseNumberToCluster.get(salesforceTicket).Additional_Cluster__r.name);
                    template.addCustomField(Jira_Cluster_Field_API, caseNumberToCluster.get(salesforceTicket).Cluster__r.name); 
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