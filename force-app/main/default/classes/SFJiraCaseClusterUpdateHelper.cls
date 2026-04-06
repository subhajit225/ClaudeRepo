/**
* @Author      : Raveesh Layal
* @Description : CaseTriggerHandler to handle the methods that are being called at case events
* @TstClass    : CaseTriggerHandlerTest,ZSFJIRAZIssueCaseTriggerServiceTest
* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1859           Raveesh Layal     16th August, 2023      Custom Case Clusters Sync to Jira
* CS21-1893           Raveesh Layal     16th August, 2023      Check for first occurrence 
* --------------------------------------------------------------------------------------------------------------------------------
*/
public class SFJiraCaseClusterUpdateHelper { 
    /** 
* @Author       :   Raveesh Layal
* @Jira Ticket  :   CS21-1859(Custom Case Clusters Sync to Jira)
* @Description  :   Syncs the Cluster ID and Additional Cluster ID from Salesforce to JIRA.
**/
    @future (callout=true)
    public static void syncJIRAClusters(set<Id> caseIdSet,String oldCaseIssueData)
    {  
        List<zsfjira.ZCBeans.IssueTemplate> jiraIssueTemplates = new List<zsfjira.ZCBeans.IssueTemplate>();
        String Jira_Cluster_Field_API=Label.Jira_Cluster_Field_API;
        String Jira_Additional_Cluster_Field_API=Label.Jira_Additional_Cluster_Field_API;
        String JIRAClusterCDMTypes=Label.JIRAClusterCDMTypes;
        String Jira_cluster_SPARK_types=Label.Jira_cluster_SPARK_types;
        set<id> jiraIssueId=new set<id>();
        Map<String,id> IssuekeyToCaseIdMap=new  Map<String,id>(); 
        list<zsfjira__ZIssue_Case__c> ZIssueCaseData=[SELECT Id,zsfjira__ZIssueId__r.zsfjira__IssueKey__c,zsfjira__ZIssueId__r.zsfjira__IssueType__c,zsfjira__CaseId__r.Cluster__r.name ,zsfjira__CaseId__r.Additional_Cluster__r.name
                                                      FROM zsfjira__ZIssue_Case__c 
                                                      WHERE zsfjira__CaseId__c in:caseIdSet AND ((zsfjira__ZIssueId__r.zsfjira__IssueKey__c like '%CDM%' and zsfjira__ZIssueId__r.zsfjira__IssueType__c in:JIRAClusterCDMTypes.split(','))
                                                                                                 or 
                                                                                                 (zsfjira__ZIssueId__r.zsfjira__IssueKey__c like '%SPARK%' and zsfjira__ZIssueId__r.zsfjira__IssueType__c in:Jira_cluster_SPARK_types.split(',') ))
                                                      
                                                      Order by CreatedDate ASC];                                 
        Map<String, zsfjira__ZIssue_Case__c> issueDetails = new Map<String, zsfjira__ZIssue_Case__c>();
        Map<String, Id> issueFirstOccurrence = new Map<String, Id>();
        //JIRA Issue details for which Case Owner Email needs to be updated in JIRA
        if(ZIssueCaseData.size()>0)
        {
            for (zsfjira__ZIssue_Case__c  eachIssueCase : ZIssueCaseData) {
                if(!issueDetails.containsKey(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c)){
                    issueDetails.put(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c, eachIssueCase);
                }
                
            }
            //CS21-1893 by Raveesh
            for(zsfjira__ZIssue_Case__c  eachIssueCase: [SELECT Id,zsfjira__ZIssueId__r.zsfjira__IssueKey__c,zsfjira__ZIssueId__r.zsfjira__IssueType__c,zsfjira__CaseId__r.Cluster__r.name ,zsfjira__CaseId__r.Additional_Cluster__r.name
                                                         FROM zsfjira__ZIssue_Case__c where zsfjira__ZIssueId__r.zsfjira__IssueKey__c IN: issueDetails.keySet() order by createddate asc]){
                                                             if(!issueFirstOccurrence.containsKey(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c)){
                                                                 issueFirstOccurrence.put(eachIssueCase.zsfjira__ZIssueId__r.zsfjira__IssueKey__c,eachIssueCase.zsfjira__CaseId__c);
                                                             }
                                                             
                                                             
                                                         }
        }
        //CS21-1893 Ends
        // old data of Jira case issue
        
        if(oldCaseIssueData!=null)
        {
            Map<id,zsfjira__ZIssue_Case__c> jiraIssue_CaseMap = ( Map<id,zsfjira__ZIssue_Case__c>)Json.deserialize(oldCaseIssueData, Map<id,zsfjira__ZIssue_Case__c>.class);
            for(zsfjira__ZIssue_Case__c eachCaseIssue:jiraIssue_CaseMap.values())
            {
                if(eachCaseIssue.zsfjira__ZIssueId__c!=null)
                {
                    jiraIssueId.add(eachCaseIssue.zsfjira__ZIssueId__c);
                }
            }
        }
        if(jiraIssueId.size()>0)
        {
            
            for(zsfjira__ZIssue__c jiraIssue:[select id,zsfjira__IssueKey__c from zsfjira__ZIssue__c where id in:jiraIssueId AND
                                              ((zsfjira__IssueKey__c like '%CDM%' and zsfjira__IssueType__c in:JIRAClusterCDMTypes.split(','))
                                               or
                                               (zsfjira__IssueKey__c like '%SPARK%' and zsfjira__IssueType__c in:Jira_cluster_SPARK_types.split(',')))
                                             ])
            {
                issueDetails.put(jiraIssue.zsfjira__IssueKey__c,null);
            }
            
            
        }
        if (!issueDetails.isEmpty()) {
            //parse through jira issues to send case owner updates
            //get case owner from caseDetails Map and construct JIRA template to send owner updates
            
            for (String eachIssueCaseKey : issueDetails.keySet()) {
                //CaseNumber on Jira Issue in Salesforce Ticket field (Original Case of the JIRA Issue)
                if(String.isNotBlank(eachIssueCaseKey)){
                    zsfjira.ZCBeans.IssueTemplate template = new zsfjira.ZCBeans.IssueTemplate(eachIssueCaseKey);
                    //CS21-1893 Check added for first occurrence
                    if (issueDetails.get(eachIssueCaseKey)!=null && issueFirstOccurrence.containsKey(eachIssueCaseKey) && issueFirstOccurrence.get(eachIssueCaseKey)==issueDetails.get(eachIssueCaseKey).zsfjira__CaseId__c) {
                        template.addCustomField(Jira_Additional_Cluster_Field_API, issueDetails.get(eachIssueCaseKey).zsfjira__CaseId__r.Additional_Cluster__r.name!=null?issueDetails.get(eachIssueCaseKey).zsfjira__CaseId__r.Additional_Cluster__r.name:'N/A');
                        template.addCustomField(Jira_Cluster_Field_API, issueDetails.get(eachIssueCaseKey).zsfjira__CaseId__r.Cluster__r.name!=null?issueDetails.get(eachIssueCaseKey).zsfjira__CaseId__r.Cluster__r.name:'N/A'); 
                        
                    } 
                    else if(issueFirstOccurrence.containsKey(eachIssueCaseKey) && issueFirstOccurrence.get(eachIssueCaseKey)==issueDetails.get(eachIssueCaseKey).zsfjira__CaseId__c){
                        template.addCustomField(Jira_Additional_Cluster_Field_API,'N/A');
                        template.addCustomField(Jira_Cluster_Field_API,'N/A'); 
                        
                    } 
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
    
}