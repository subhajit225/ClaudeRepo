/**
 * @Author      : Veera Gandi
 * @Description : Class to handle business logic for zsfjira__ZIssue_Case__c object which is a junction object between JIRA Issues and Cases.
 * @TstClass    : ZSFJIRAZIssueCaseTriggerServiceTest
 * @CreatedDate 29th April 2021
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1192        Vijay Kumar K R        July 18, 2022    Redirecting JIRA Jira_Reference_urls__c Based on Org type
 * --------------------------------------------------------------------------------------------------------------------------------
 */
public without sharing class ZSFJIRAZIssueCaseTriggerService {
    
    @TestVisible
    private static final Boolean IS_SANDBOX = [SELECT IsSandbox FROM Organization].IsSandbox;
    @TestVisible
    private static final String JIRA_PROD_URL = 'https://rubrik.atlassian.net/browse/';

    /**
    * @description method to update jira reference field on case. Jira Issue's related to a case '
    * 			   are consolidated and are updated as hyperlink's on Case.
    * @param  caseIssues  List of case Issues.
    * @return void
    */
    public static void recalculateCaseJIRAReference(List<zsfjira__ZIssue_Case__c> caseIssues, Map<Id,zsfjira__ZIssue_Case__c> oldMap) {
        
        Set<Id> caseIds = new Set<Id>();
        Set<id> oldCaseIds=new Set<id>();
        List<Case> cases = new List<Case>();
        //CS21-749 Changes	
        Map<Id,Id> idsMap = new Map<Id,Id>();	
        Map<Id,String> JiraMap = new Map<Id,String>();	
        Map<Id,zsfjira__ZIssue_Case__c> newMap = new Map<Id,zsfjira__ZIssue_Case__c>();
        Map<Id,Assist_Request__c>  ARMap = new Map<Id,Assist_Request__c>();	
        Map<Id,String>  zJIRAReferenceMap = new Map<Id,String>();	
        List<Note> comments = new List<Note>();	
        User thisUser = [ select UserRoleId,UserRole.Name FROM User where Id =:UserInfo.getUserId()];	
        //CS21-749 Changes End
        for (zsfjira__ZIssue_Case__c newCaseIssue : caseIssues) {
            //fetch all the caseIds from case issue record.
            caseIds.add(newCaseIssue.zsfjira__CaseId__c);
            //CS21-749 Changes	
            //if(thisUser.UserRole.Name == 'APAC Support Engineer'){	
                idsMap.put(newCaseIssue.zsfjira__ZIssueId__c, newCaseIssue.zsfjira__CaseId__c);
                newMap.put(newCaseIssue.Id, newCaseIssue);
            //}	
            //CS21-749 Changes End
        }

        String jiraUrl = JIRA_PROD_URL;
        if(IS_SANDBOX){
            jiraUrl = System.Label.JIRA_Sandbox_Base_URL;
        }
        
        
       //CS21-1859 Sync Case Clusters to Jira
        if(oldMap!=null && oldMap.size()>0)
        {
      
         for(zsfjira__ZIssue_Case__c oldCaseIssue:oldMap.values())
            {
                if(oldCaseIssue.zsfjira__CaseId__c!=null)
                {
                    oldCaseIds.add(oldCaseIssue.zsfjira__CaseId__c);
                 
                }
                
            }
        }
        
        System.debug('ZSFJiraZissue caseIds:'+caseIds);
        if (!caseIds.isEmpty()) {
        
            //Query JIRA Issue details for the cases where jira reference url needs to be recalculated
            for (Case eachCase : [SELECT Id, Jira_Reference_urls__c, (SELECT zsfjira__ZIssueId__c, zsfjira__ZIssueId__r.zsfjira__IssueKey__c FROM zsfjira__ZIssue_Case__r) 
                                  FROM Case WHERE Id IN :caseIds]) {
                System.debug('ZSFJiraZissue Jira_Reference_urls__c:'+eachCase.Jira_Reference_urls__c);
                //reset Jira_Reference_urls__c for calculation 
                eachCase.Jira_Reference_urls__c = '';
                String referenceURL = '';
                
                //iterate through case issues to construct 
                for (zsfjira__ZIssue_Case__c eachJIRAIssue : eachCase.zsfjira__ZIssue_Case__r) {
                    System.debug('ZSFJiraZissue eachJIRAIssue:'+eachJIRAIssue);

                    if (string.isNotBlank(eachJIRAIssue.zsfjira__ZIssueId__r.zsfjira__IssueKey__c)) {
                        System.debug('ZSFJiraZissue zsfjira__IssueKey__c:'+eachJIRAIssue.zsfjira__ZIssueId__r.zsfjira__IssueKey__c);
                        referenceURL = '<a href="'+ jiraUrl + eachJIRAIssue.zsfjira__ZIssueId__r.zsfjira__IssueKey__c + '" target="_blank">';
                        referenceURL += eachJIRAIssue.zsfjira__ZIssueId__r.zsfjira__IssueKey__c + '</a>';
                        System.debug('ZSFJiraZissue referenceURL:'+referenceURL);
                        eachCase.Jira_Reference_urls__c += referenceURL + ',';
                    }
                    //CS21-749 Changes Start
                    if(!idsMap.isEmpty() && idsMap.values().contains(eachCase.Id) && idsMap.ContainsKey(eachJIRAIssue.zsfjira__ZIssueId__c)){
                        JiraMap.put(eachCase.Id,eachJIRAIssue.zsfjira__ZIssueId__r.zsfjira__IssueKey__c);
                    }
                    //CS21-749 Changes End
                }
                
                //set Jira_Reference_urls__c for calculation     
                System.debug('ZSFJiraZissue eachCase.Jira_Reference_urls__c:'+eachCase.Jira_Reference_urls__c);                  
                eachCase.Jira_Reference_urls__c = eachCase?.Jira_Reference_urls__c?.removeEnd(',');
                zJIRAReferenceMap.put(eachCase.Id,eachCase.Jira_Reference_urls__c);
                cases.add(eachCase);                
            } 
        }

        //CS21-749 Changes Start      
        List<Assist_Request__c>  arList = new List<Assist_Request__c>();
        if(!JiraMap.isEmpty()){
            for(Assist_Request__c AR:[Select Id,Case__c,Case__r.CaseNumber,JIRA_Reference__c from Assist_Request__c where Case__c IN: caseIds]){
                String Comment;
                if(trigger.isInsert){
                    Comment = 'Jira '+JiraMap.get(AR.Case__c)+' was created/linked for this case #'+AR.Case__r.CaseNumber+'. Please review/update the jira.';
                }else if(newMap.get(idsMap.get(AR.Case__c))?.zsfjira__CaseId__c != oldMap.get(idsMap.get(AR.Case__c))?.zsfjira__CaseId__c){
                    Comment = 'Jira '+JiraMap.get(AR.Case__c)+' was created/linked. Please check Jira comments.';
                }
                if(!String.isEmpty(Comment))
                    comments.add(new Note(ParentId = AR.Id,body = Comment,Title='JIRA linked to Case'));
                if(zJIRAReferenceMap.containsKey(AR.Case__c) && zJIRAReferenceMap.get(AR.Case__c) != AR.JIRA_Reference__c){
                    AR.JIRA_Reference__c = zJIRAReferenceMap.get(AR.Case__c);
                    arList.add(AR); 
                }
            }
            if(!comments.isEmpty()){
                insert comments;
            }
            if(!arList.isEmpty()){
                List<Database.SaveResult> results = Database.update(arList, false);
                
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug(LoggingLevel.ERROR, 'ZSFJIRAZIssueCaseTriggerService :: ' + error.getMessage());
                        }
                    }
                }
            }
        }
        //CS21-749 Changes End
        System.debug('ZSFJiraZissue cases:'+cases);   
        if (!cases.isEmpty()) {
            //update cases
            List<Database.SaveResult> results = Database.update(cases, false);
            
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'ZSFJIRAZIssueCaseTriggerService :: ' + error.getMessage());
                    }
                }
            }
        }

        // As part of CS21-1945 fix
        System.debug('isBatch:'+!System.isBatch()+' :isFuture: '+ !System.isFuture());   
        if(!System.isBatch() && !System.isFuture()){
            System.debug('INSIDE Async:'+caseIds);   
            if(oldCaseIds.size()>0){
                String OldIssueCaseData = json.serialize(oldMap);
                 if(trigger.isdelete && trigger.isafter)
                {  
                    SFJiraCaseClusterUpdateHelper.syncJIRAClusters(oldCaseIds,OldIssueCaseData);
                }
            }
    
            if (!caseIds.isEmpty()) {
                //CS21-1859 Sync Case Clusters to Jira
                SFJiraCaseClusterUpdateHelper.syncJIRAClusters(caseIds,null);
            }
        }   
    }
    
}