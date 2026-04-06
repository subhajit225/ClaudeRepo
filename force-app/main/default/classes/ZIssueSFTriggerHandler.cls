/**
 * @description This class is used to handle the trigger events for ZIssueSF object
 * @author Shiva
 * @version 1.0
 * @date 01/06/2021
 */
public with sharing class ZIssueSFTriggerHandler {
    /**
     * @description This method is used to send the comment on jira issue
     * @param jiraRel
     */
    public void sendCommentOnJiraIssue(List<zsfjira__ZIssue_SF__c> jiraRel){
        Set<id> closedCaseIds = new Set<Id>();
        Map<id,string> caseIdWithCommentMap = new Map<id,string>();
        Set<ID> CaseID = new Set<ID>();
        List<ID> JiraRelationshipID= new List<ID>();
        Map<ID,Case> closedcaseIDToCaseMap=new Map<ID,case>();
        for(zsfjira__ZIssue_SF__c jRel : jiraRel){
            CaseID.add(jRel.zsfjira__Case__c);
            JiraRelationshipID.add(jRel.id);
        }
        
        for(case cs: [SELECT id,CaseNumber,Account_Name__c,Resolution__c,Subject from Case WHERE Status = 'Closed' AND ID In : CaseID]){
            closedCaseIds.add(cs.ID);
            closedcaseIDToCaseMap.put(cs.ID,cs);
        }
         for(zsfjira__ZIssue_SF__c jRel : jiraRel){
             
             if(!closedcaseIDToCaseMap.isEmpty() && closedcaseIDToCaseMap.containsKey(jRel.zsfjira__Case__c)){
                 if(!caseIdWithCommentMap.containskey(jRel.zsfjira__Case__c)){
                   
                    String commentBody = '1. Case Number '+closedcaseIDToCaseMap.get(jRel.zsfjira__Case__c).CaseNumber + ' was closed, Account Name : '+closedcaseIDToCaseMap.get(jRel.zsfjira__Case__c).Account_Name__c+' ,Case summary : '+closedcaseIDToCaseMap.get(jRel.zsfjira__Case__c).Subject+'. \n 2. Case Resolution : '+closedcaseIDToCaseMap.get(jRel.zsfjira__Case__c).Resolution__c +'\n 3. Please perform RCA before closing the jira.';
                    caseIdWithCommentMap.put(jRel.zsfjira__Case__c, commentBody);
                }
            }
        }
         
        if(closedCaseIds!=NULL && !closedCaseIds.IsEmpty() &&  !caseIdWithCommentMap.IsEmpty()){
            CaseTriggerHandler.SendCommentToJira(NULL,caseIdWithCommentMap,JiraRelationshipID);
        }
    }
    
    /**
     * @description This method is used to unlink the zissue account preference
     * @param caseIssues
     */
    public static void linkUnlinkZissue(List<zsfjira__ZIssue_SF__c > caseIssues){
        Set<Id> issueIds = new Set<Id>();
        List<zsfjira__ZIssue_SF__c > caseIssuesToProcess = new List<zsfjira__ZIssue_SF__c >();
        for(zsfjira__ZIssue_SF__c eachRecord : caseIssues){
            issueIds.add(eachRecord.zsfjira__ZIssue__c);
        }
        
        for(zsfjira__ZIssue_SF__c eachRecord : [SELECT zsfjira__Case__r.AccountId, zsfjira__ZIssue__c,zsfjira__ZIssue__r.zsfjira__IssueKey__c,zsfjira__ZIssue__r.zsfjira__IssueType__c FROM zsfjira__ZIssue_SF__c WHERE zsfjira__ZIssue__c IN : issueIds]){
            if(!supportedType(eachRecord)){
                issueIds.remove(eachRecord.zsfjira__ZIssue__c);
            }
        }
        
        if(!issueIds.isEmpty()){
            getIssueByRelatedissues(issueIds);
        }
    }
    
    /**
     * @description This method is used to get the supported projects and issue types
     */
    public static Set<String> supportedProjects = new Set<String>{'SPARK','CDM','ROCK','FLO','BRU'};
    /**
     * @description This method is used to get the supported issue types
     */
    public static Set<String> supportedIssueType = new Set<String>{'Customer Bug','Usability','Supportability'};
    
    

    
    
    /** 
     * @description This method is used to update the account preference count
     * @param accountIds
     */
    public static void updateCountByAccountPreference(Set<Id> accountIds){
       if(!accountIds.isEmpty()){
           getIssueByRelatedissues(accountIds);
        }
    }

    /**
     * @description This method is used to get the account preference count
     * @param issueIds
     */
    public  static void getIssueByRelatedissues(Set<Id> issueIds){
        if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Email_Notification_for_Top_Acn__c){
            if(System.isBatch() || system.isFuture() || System.isQueueable()){
                processIssues(issueIds);
            }
            else{
                processIssuesInFutureContext(issueIds);
            }
        }
    }
    /**
* @description Processes the given issues asynchronously using a Future method (supports callouts).
* @param issueIds
*/
    @future(callout=true)
    public static void processIssuesInFutureContext(Set<Id> issueIds){
        processIssues(issueIds);
    }
    /**
* @description This method is used to get the account preference count
* @param issueIds
*/
    public  static void processIssues(Set<Id> issueIds){
        String recordId = String.valueOf(new List<Id>(issueIds)[0]);
        if(recordId.startsWith('001')){
            Set<Id> accountIds = new Set<Id>();
            accountIds = issueIds;
            issueIds = new Set<Id>();
            for(zsfjira__ZIssue_SF__c eachRecord : [SELECT zsfjira__Case__r.AccountId, zsfjira__ZIssue__c,zsfjira__ZIssue__r.zsfjira__IssueKey__c,zsfjira__ZIssue__r.zsfjira__IssueType__c FROM zsfjira__ZIssue_SF__c WHERE zsfjira__Case__r.AccountId IN : accountIds AND zsfjira__ZIssue__r.zsfjira__Status__c != 'Resolved' AND zsfjira__ZIssue__r.zsfjira__Status__c != 'Completed']){
                if(!supportedType(eachRecord)){
                    continue;
                }
                issueIds.add(eachRecord.zsfjira__ZIssue__c);
            }
        }
        Map<Id,Set<String>> accountIdMap = new Map<Id,Set<String>>();
        for(zsfjira__ZIssue_SF__c eachRecord : [SELECT zsfjira__Case__r.AccountId, zsfjira__ZIssue__c,zsfjira__ZIssue__r.zsfjira__IssueKey__c FROM zsfjira__ZIssue_SF__c WHERE zsfjira__ZIssue__c IN :issueIds]){
            if(!accountIdMap.containsKey(eachRecord.zsfjira__Case__r.AccountId)){
                accountIdMap.put(eachRecord.zsfjira__Case__r.AccountId,new Set<String>());
            }
            accountIdMap.get(eachRecord.zsfjira__Case__r.AccountId).add(eachRecord.zsfjira__ZIssue__r.zsfjira__IssueKey__c);
        }

        Map<String,IssuePreferenceCount> accountPreferenceCountMap = new Map<String,IssuePreferenceCount>();
        if(!accountIdMap.isEmpty()){
            for(Account eachAccount : [SELECT id,Account_Preference__c FROM Account WHERE id IN : accountIdMap.keySet() AND Account_Preference__c includes ('Strategic Account','Premium Account','Top Accounts','Top Accounts (Manual exception)')]){
                for(String eachIssueId : accountIdMap.get(eachAccount.id)){
                    IssuePreferenceCount issuePreferenceCount = new IssuePreferenceCount();
                    if(accountPreferenceCountMap.containsKey(eachIssueId)){
                        issuePreferenceCount = accountPreferenceCountMap.get(eachIssueId);
                    }
                    if(eachAccount.Account_Preference__c.contains('Strategic Account')){
                        issuePreferenceCount.countStrategicAccount++;
                    }
                    if(eachAccount.Account_Preference__c.contains('Premium Account')){
                        issuePreferenceCount.countPremiumAccount++;
                    }
                    if(eachAccount.Account_Preference__c.contains('Top Accounts') || eachAccount.Account_Preference__c.contains('Top Accounts (Manual exception)')){
                        issuePreferenceCount.countTopAccount++;
                    }
                    accountPreferenceCountMap.put(eachIssueId,issuePreferenceCount);
                }
            }
        }
        if(accountPreferenceCountMap!=null && accountPreferenceCountMap.size()>0){
            List<zsfjira.ZCBeans.IssueTemplate> lstIssues = new List<zsfjira.ZCBeans.IssueTemplate>();
            for(String eachIssueId : accountPreferenceCountMap.keySet()){
                IssuePreferenceCount issuePreferenceCount = accountPreferenceCountMap.get(eachIssueId);
                zsfjira.ZCBeans.IssueTemplate issue = new zsfjira.ZCBeans.IssueTemplate(eachIssueId);
                
                issue.addCustomField('customfield_19228' , issuePreferenceCount.countTopAccount);
                issue.addCustomField('customfield_19229' , issuePreferenceCount.countPremiumAccount);
                issue.addCustomField('customfield_19230' , issuePreferenceCount.countStrategicAccount);
                lstIssues.add(issue);
            }
            try{
                if(!Test.isRunningTest())
                    List<zsfjira.ZCBeans.IssueUpsertResult> iresults = zsfjira.ZC.Issues.bulkUpdateIssues(lstIssues);
            }catch(Exception e){
                System.debug(LoggingLevel.INFO,e);
            }
            
        }
    }

    /**
     * @description This method is used to check if the issue is supported
     * @param eachRecord
     * @return Boolean
     */
    public static Boolean supportedType(zsfjira__ZIssue_SF__c eachRecord){
        Boolean isSupported = true;
        if(eachRecord.zsfjira__ZIssue__c != null && eachRecord.zsfjira__ZIssue__r.zsfjira__IssueKey__c != null && eachRecord.zsfjira__ZIssue__r.zsfjira__IssueKey__c.contains('-')){
                String projectKey = eachRecord.zsfjira__ZIssue__r.zsfjira__IssueKey__c.split('-')[0];
                if(!supportedProjects.contains(projectKey)){
                    isSupported = false;
                }
                if(eachRecord.zsfjira__ZIssue__r.zsfjira__IssueType__c != null &&!supportedIssueType.contains(eachRecord.zsfjira__ZIssue__r.zsfjira__IssueType__c)){
                     isSupported = false;
                }
        }
        return isSupported;
    }

    /** 
    * @description This is Wrapper to hold Account type count
    */
    public class IssuePreferenceCount{
        /** */
        public Integer countTopAccount;
        /** */
        public Integer countPremiumAccount;
        /** */
        public Integer countStrategicAccount;
        /**
        * @description This is Wrapper constructor to set default value
         */
        public IssuePreferenceCount(){
            this.countTopAccount = 0;
            this.countPremiumAccount = 0;
            this.countStrategicAccount = 0;
        }
    }
}