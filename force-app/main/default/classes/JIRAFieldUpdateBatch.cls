global class JIRAFieldUpdateBatch implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.stateful{
    
    global string timestamp;
    public Map<String, USer> userMap = new Map<String,User>();
    
    global Database.Querylocator start(Database.BatchableContext BC){
        timestamp = String.Valueof(datetime.now()); 
        String userQuery = system.Label.UserRecordQuery+(Test.isRunningTest()?' LIMIT 20':'');
        return Database.getQueryLocator(userQuery);
    }
 
    global void execute(Database.BatchableContext BC,List<User> scope){
        
        for(User  userRecord :Scope){
            userMap.put(userRecord.email, userRecord);
        }
        system.debug('usermap size()=='+userMap.size());
    }
 
    global void finish(Database.BatchableContext BC){
        
        JIRAIssueHelper.updateJIRAIssues(userMap,timestamp) ;
        /* Do the Callout
         try{
        List<JIRAIssueHelper.JIRAIssue> jiraIssues =new List<JIRAIssueHelper.JIRAIssue>();
        jiraIssues = JIRAIssueHelper.fetchJiraIssue();
        system.debug('usermap size()=='+userMap.size());
        system.debug('usermap=='+userMap);
        for(JIRAIssueHelper.JIRAIssue issue : jiraIssues){
        system.debug('JIRA issue ==='+issue);
            if(issue.key != null && issue.reporter != null){
                if((issue.theater == null || issue.theater == '')&& (issue.division == null|| issue.division== '') && userMap.containsKey(issue.reporter)){
                    system.debug('reporter=='+issue.reporter);
                    system.debug('user Record'+userMap.get(issue.reporter));
                    string sfdctheater =userMap.get(issue.reporter).Theatre__c != null?userMap.get(issue.reporter).Theatre__c: '';
                    string sfdcdivision =userMap.get(issue.reporter).Division != null ? userMap.get(issue.reporter).Division : '';
                    JIRAIssueHelper.buildRequest(issue.key,sfdctheater ,sfdcdivision );
                    System.debug('In PUT API');
                }
            }
        }
        }
        catch(Exception ex){
                    system.debug('Excpetion in JIRAFieldUpdateBatch Method'+ex);
                    EntitlementToSCHelperClass.createErrorRecord(ex.getMessage(),'JIRA Issue Sync','JIRAFieldUpdateBatch', ex.getTypeName(), ex.getLineNumber(),null,'',timestamp,'');
                    
        }
*/
        //AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =:BC.getJobId()];
 
        //system.debug(' Job Processing finished with ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
     
    }
    /* JIRA Issue Object.
    @testVisible class JIRAIssue {
        public boolean selected{get;set;}
        public String summary { get;set; }
        //public String project { get; }
        public String key { get; set;}
        public String id { get;set;}
        public String status { get;set; }
        public String url { get; set;}
        public String reporter { get; set;}
        //public String assignee { get; }
        
        public JIRAIssue(boolean selected,String summary,String project,String key,
            String status,String url,string email){
            this.selected= selected;
            this.summary = summary;
            this.id = id;
            this.key=key;
            this.status = status;
            this.url= url;
            this.reporter = email;
        }
    }*/
}