public class JIRAIssueHelper{
    public static String username; // JIRA username
    public static String password; // JIRA password // Constructs Basic Http Authentication header from provided credentials
    public static String baseUrl;   // Base URL of your JIRA instance
    
    public void JIRAIssueHelper(){
        List<Connection_Config__mdt> mdtList = [Select Id, URL__c, User_Name__c, Password__c from 
            Connection_Config__mdt where DeveloperName = 'Agile_Connect_JIRA_Config' LIMIT 1];
        if(mdtList != null && !mdtList.isEmpty()){
            Connection_Config__mdt mdt =  mdtList[0];
            baseUrl = mdt.URL__c;
            username = mdt.User_Name__c; // JIRA username
            password = mdt.Password__c; // JIRA password // Constructs Basic Http Authentication header from provided credentials
        }
    }

    public static List<JIRAIssue> fetchJiraIssue(){
        List<JIRAIssue> jiraIssues =new List<JiraIssue>();
        try{
           Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            
            //Set HTTPRequest header properties
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type','application/json');
            Blob headerValue = Blob.valueOf(username+':'+password);
            request.setHeader('Authorization','Basic '+ EncodingUtil.base64Encode(headerValue));
            baseUrl = System.Label.JIRA_Query;    //'https://rubrik.atlassian.net/rest/api/latest/search?jql=project=SOSD+and+cf[12635]+is+EMPTY+and+cf[12636]+is+EMPTY';
             
            system.debug('baseUrl=='+baseUrl);
            request.setEndpoint(baseUrl);
            HttpResponse response = http.send(request);
            // Log the JSON content
            System.debug('JSON Response: ' + response.getBody());
            string JSONContent = response.getBody();
           
            system.debug(jiraGetIssueResponse.parse(JSONContent));
            JSONParser parserJira = JSON.createParser(JSONContent);
            
            JiraGetIssueResponse jiraIssue1 = (JiraGetIssueResponse)parserJira.readValueAs(JiraGetIssueResponse.class);
            if(jiraIssue1 != null && jiraIssue1.issues != null) {              
                system.debug('issues=='+jiraIssue1.issues);
                system.debug('issues size=='+jiraIssue1.issues.size());
                //searchedIssues.addAll(jiraIssue1.issues);
                //system.debug('issues ier=='+searchedIssues.size());
                if(jiraIssue1.issues.size()>0){
                    for(JiraGetIssueResponse.cls_issues issue : jiraIssue1.issues){
                        if(issue.key != null && issue.fields.summary != null && issue.fields.reporter != null ){
                        string theater_temp;
                        if(issue.fields.theater != null)
                         theater_temp = issue.fields.theater.value;
                         else 
                         theater_temp= '';
                         
                        String division_temp;
                        if(issue.fields.division!= null)
                        division_temp = issue.fields.division.value;
                        else
                        division_temp = '';
                        
                        system.debug('issue--'+issue);
                        jiraIssues.add(new JIRAIssue(false,issue.fields.summary,issue.id,issue.key,issue.fields.status.name,issue.self,issue.fields.reporter.emailAddress,theater_temp ,division_temp ));
                        
                        }/*else if(issue.key == null){
                            isKeyFound=false;
                        }
                        else if(issue.fields.summary == null){
                            isTextFound = false;
                        }*/
                    }
                    system.debug('jiraIssues=='+jiraIssues);
                }
                else  if(jiraIssue1.issues.size()==0){
                   // isTextFound = false;
                }
            }
        }
        catch(Exception ex){
        
        }
        return jiraIssues;
    }
    
    // Constructs request needed to fetch JIRA issues from provided parameters.
    public static void buildRequest(String JiraID,String theater, String division){    //(String baseUrl, String username, String password) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //Set HTTPRequest header properties
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type','application/json');
            request.setEndpoint(System.label.JIRA_Endpoint+JiraID);
            request.setMethod('PUT');
            Blob headerValue = Blob.valueOf(username+':'+password);
            request.setHeader('Authorization','Basic '+ EncodingUtil.base64Encode(headerValue));
            system.debug('baseUrl update=='+System.label.JIRA_Endpoint+JiraID);
            
            //request.setBody('{"update":{"labels":[{"add":"'+label+'"}]}}');
            if((theater != '' && theater != null)  && (division != '' && division != null)){
                request.setBody('{"fields" : {"customfield_12635": { "value": "'+theater+'" },"customfield_12636": { "value": "'+division+'" }}}');
                HttpResponse res  = http.send(request);
                
            // Log the JSON content
            System.debug('JSON Response: ' + res.getBody());
            }
            else if((theater == '' || theater == null) && (division != '' && division != null)){
                request.setBody('{"fields" : {"customfield_12636": { "value": "'+division+'" }}}');
                HttpResponse res  = http.send(request);
                // Log the JSON content
            System.debug('JSON Response: ' + res.getBody());
            }
            else if((theater != '' && theater != null) && (division == '' || division == null)){
                request.setBody('{"fields" : {"customfield_12635": { "value": "'+theater+'" }}}');
                HttpResponse res  = http.send(request);
                // Log the JSON content
                System.debug('JSON Response: ' + res.getBody());
            }
              //HttpRequest request = buildRequest(System.Label.JIRA_EndPoint,username ,password);
              //HttpResponse res  = http.send(request);
            //return res.getBody();
            // Log the JSON content
            //System.debug('JSON Response: ' + res.getBody());
            //return null;
    }
    // JIRA Issue Object.
    @testVisible public class JIRAIssue {
        public boolean selected{get;set;}
        public String summary { get;set; }
        //public String project { get; }
        public String key { get; set;}
        public String id { get;set;}
        public String status { get;set; }
        public String url { get; set;}
        public String reporter { get; set;}
        public String theater{ get; set;}
        public String division{ get; set;}
        //public String assignee { get; }
        
        public JIRAIssue(boolean selected,String summary,String project,String key,
            String status,String url,string email,String theater,String division){
            this.selected= selected;
            this.summary = summary;
            this.id = id;
            this.key=key;
            this.status = status;
            this.url= url;
            this.reporter = email;
            this.theater= theater;
            this.division= division;
        }
    }
    public static void updateJIRAIssues(Map<String, USer> userMap,string timestamp){
        try{
        List<JIRAIssue> jiraIssues =new List<JIRAIssue>();
        jiraIssues = fetchJiraIssue();
        system.debug('jiraIssues11=='+jiraIssues);
        system.debug('usermap size()=='+userMap.size());
        system.debug('usermap=='+userMap);
        for(JIRAIssue issue : jiraIssues){
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
    }
}