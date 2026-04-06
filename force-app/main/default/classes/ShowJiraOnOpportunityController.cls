public class ShowJiraOnOpportunityController
{
    public String baseUrl;   // Base URL of your JIRA instance
    public String username; // JIRA username
    public String password; // JIRA password // Constructs Basic Http Authentication header from provided credentials
    public String jiraSearchText {get;set;}
    public String jiraSearchKey {get;set;}
    public List<JiraGetIssueResponse.cls_issues> testissues {get;set;}
    public List<JiraGetIssueResponse.cls_issues> searchedIssues {get;set;}
    public List<JiraGetIssueResponse.cls_issues> Issues {get;set;}
    public List<JIRAIssue> jiraIssues {get;set;}
    public String OppId {get;set;}
    Public boolean  isSuccess {get;set;}
    Public boolean  isKeyFound {get;set;}
    Public boolean  isTextFound {get;set;}
public String errorString {get;set;}
    
    public ShowJiraOnOpportunityController(ApexPages.StandardController stdController) {
        List<Connection_Config__mdt> mdtList = [Select Id, URL__c, User_Name__c, Password__c from 
            Connection_Config__mdt where DeveloperName = 'Agile_Connect_JIRA_Config' LIMIT 1];
        if(mdtList != null && !mdtList.isEmpty()){
            Connection_Config__mdt mdt =  mdtList[0];
            baseUrl = mdt.URL__c;
            username = mdt.User_Name__c; // JIRA username
            password = mdt.Password__c; // JIRA password // Constructs Basic Http Authentication header from provided credentials
        }
        Opportunity theopp = (Opportunity)stdController.getRecord();
        jiraSearchText = '';
        jiraSearchKey = '';
         searchedIssues = new List<JiraGetIssueResponse.cls_issues>();
         jiraIssues = new List<JiraIssue>();
         OppId = ID.valueOf(apexpages.currentpage().getparameters().get('id')) ;
         isSuccess = false;
        isKeyFound = true;
        isTextFound = true;
        errorString ='';
         
         //Execute();
        //system.debug('test'+issuesJson);
        //system.debug('test1'+getIssues());
        
    }
    
    public String authHeader()
    { 
        Blob headerValue = Blob.valueOf(username+':'+password); 
        return 'Basic ' + EncodingUtil.base64Encode(headerValue);        
    }
    public pagereference Execute()
    {    
        try{
        jiraIssues.clear();
        isSuccess=false;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        string fields   =   'key,'+
            'assignee,'+
            'project,'+
            'summary,'+
            'created,'+
            'updated,'+
            'priority,'+
            'status';
        system.debug(fields);
        integer startAt = 0;
        integer maxResults= 100;
        string searchProjectString='RFE';
        string searchStatusString='Unresolved';
        string searchtext='';
        if(jiraSearchText != '')
        searchtext= jiraSearchText;
        //String CreateIssueJsonJIra= '{"fields": {"summary":"test create jira1","description":"test create jira1" ,"issuetype":{"name": "Bug"}}} ';       
        //String CreateIssueJsonJIra= '{"fields": { "project":{  "key": "SUSTAIN"},"summary": "REST ye merry gentlemen2","description": "Creating of an issue using project keys and issue type names using the REST API2","issuetype": {"name": "Bug"}}}';
        request.setMethod('GET');
        //Set HTTPRequest header properties
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type','application/json');
        Blob headerValue = Blob.valueOf(username+':'+password);
        request.setHeader('Authorization','Basic '+ EncodingUtil.base64Encode(headerValue));
        //baseUrl='https://rubrik.atlassian.net/rest/api/latest/search?jql=summary~'+'"'+searchtext+'*"'+'&project='+searchProjectString+'&resolution='+searchStatusString+'&fields=key,summary,status,priority,status,created,updated,assignee,url';
        jiraSearchText = jiraSearchText.trim();
        jiraSearchKey = jiraSearchKey.trim();
        
        if(jiraSearchText != '' && jiraSearchKey != ''){
            jirasearchText ='"'+jirasearchText+'*"';
            baseUrl='https://rubrik.atlassian.net/rest/api/latest/search?jql=project=RFE%20AND%20%28summary~'+jiraSearchText+'%20AND%20KEY='+jiraSearchKey+'%29%20AND%20Resolution=Unresolved&fields=key,summary,status,priority,project,status,created,updated,assignee,url';
        }
        else if(jiraSearchText != '' && jiraSearchKey == ''){
            //jiraSearchText = '\\u002f.\\u002a'+jirasearchText+'\\u002a.\\u002f';
            jirasearchText ='"'+jirasearchText+'*"';
            baseUrl='https://rubrik.atlassian.net/rest/api/latest/search?jql=project=RFE%20AND%20%28summary~'+jiraSearchText+'%29%20AND%20Resolution=Unresolved&fields=key,summary,status,priority,project,status,created,updated,assignee,url';
        }
        else if(jiraSearchText == '' && jiraSearchKey != ''){
            baseUrl='https://rubrik.atlassian.net/rest/api/latest/search?jql=project=RFE%20AND%20%28KEY='+jiraSearchKey+'%29%20AND%20Resolution=Unresolved&fields=key,summary,status,priority,project,status,created,updated,assignee,url';
        }
        
        system.debug('baseUrl=='+baseUrl);
        //baseUrl=baseUrl+searchString+'"';
        //baseUrl=baseUrl+ '&fields=' + fields + '&startAt='+ startAt +'&maxResults='+maxResults;
        request.setEndpoint(baseUrl);
        HttpResponse response = http.send(request);
        // Log the JSON content
        System.debug('JSON Response: ' + response.getBody());
        string JSONContent = response.getBody();
       
        system.debug(jiraGetIssueResponse.parse(JSONContent));
        JSONParser parserJira = JSON.createParser(JSONContent);
        
        //system.debug('parserJira ='+parserJira);
        
        JiraGetIssueResponse jiraIssue1 = (JiraGetIssueResponse)parserJira.readValueAs(JiraGetIssueResponse.class);
        if(jiraIssue1 != null && jiraIssue1.issues != null) {              
            system.debug('issues=='+jiraIssue1.issues);
            system.debug('issues size=='+jiraIssue1.issues.size());
            //system.debug('issues key=='+jiraIssue1.issues[0].key);
            searchedIssues.addAll(jiraIssue1.issues);
            system.debug('issues ier=='+searchedIssues.size());
            if(jiraIssue1.issues.size()>0){
                for(JiraGetIssueResponse.cls_issues issue : jiraIssue1.issues){
                    if(issue.key != null && issue.fields.summary != null)
                    jiraIssues.add(new JIRAIssue(false,issue.fields.summary,issue.id,issue.key,issue.fields.status.name,issue.self));
                    else if(issue.key == null){
                        isKeyFound=false;
                    }
                    else if(issue.fields.summary == null){
                        isTextFound = false;
                    }
                }
                system.debug('jiraIssues=='+jiraIssues);
            }
            else  if(jiraIssue1.issues.size()==0){
                isTextFound = false;
            }
        }
        
        /*while (parserJira.nextToken() != null) 
        {
            // Start at the array of issues.
            if(parserJira.getCurrentToken() == JSONToken.START_ARRAY) 
            {
                while (parserJira.nextToken() != null) 
                {
                    if ((parserJira.getCurrentToken() == JSONToken.START_OBJECT))
                    {
                        JiraGetIssueResponse jiraIssue = (JiraGetIssueResponse)parserJira.readValueAs(JiraGetIssueResponse.class);
                        system.debug(jiraIssue);
                        system.debug('Current TOKEN:'+parserJira.getCurrentToken());
                        system.debug('Current TEXT:'+parserJira.getText());
                        //parserJira.nextToken();
                        //system.debug('**************');
                    }   
                }
                system.debug('**************');
                //system.debug('Current TOKEN:'+parserJira.getCurrentToken());
                //system.debug('Current TEXT:'+parserJira.getText());
                
            }
        }
        */
        //system.debug('JiraId='+jiraId+' JiraKey='+jirakey);
        }
        catch(Exception ex){
        
        }
        
        return null;
    }
    // JIRA Issue Object.
    @testVisible class JIRAIssue {
        public boolean selected{get;set;}
        public String summary { get;set; }
        //public String project { get; }
        public String key { get; set;}
        public String id { get;set;}
        public String status { get;set; }
        public String url { get; set;}
        //public String assignee { get; }
        
        public JIRAIssue(boolean selected,String summary,String project,String key,
            String status,String url){
            this.selected= selected;
            this.summary = summary;
            this.id = id;
            this.key=key;
            this.status = status;
            this.url= url;
        }
    }
    public pagereference UpdateOpportunity(){
         JIRAIssue selectedIssue ;
         List<JIRA_Issue__c> jiraIssueList = new List<JIRA_Issue__c>();
         Set<String> jiraKeySet = new Set<String>();
         errorString='';
         for(JIRAIssue issue: jiraIssues) {
            if(issue.selected == true) {
                //selectedIssue = issue;
                JIRA_Issue__c jIssue = new JIRA_Issue__c();
                jIssue.Jira_Link__c = System.Label.JIRA_URL+issue.Key;
                jIssue.Name = issue.Key;
                jissue.Summary__c = issue.summary;
                if(OppId != null && OppId != ''){
                    jIssue.Opportunity__c = oppId;
                }
                jiraIssueList.add(jissue);
                jiraKeySet.add(issue.Key);
            }
        }
        
        system.debug('jiraIssueList==='+jiraIssueList);
        if(OppId != null && OppId != ''){
            //JIRA_Issue__C existingJiraIssues = [select id, Name from JIRA_Issue__C where Opportunity__c =:oppId AND Name IN: JiraKeySet];
            errorString ='';
            for(Jira_Issue__c issue : [select id, Name from JIRA_Issue__C where Opportunity__c =:oppId AND Name IN: JiraKeySet]){
                errorString+=issue.Name+',';
            }
            errorString = errorString.removeEnd(',');
        }
        if(jiraIssueList.size()> 0 && errorString ==''){
            try{
            
            insert jiraIssueList;
                isSuccess =true;
            }
            catch(exception ex){
                isSuccess= false;
            }
        }
        //closePopup();
      return null;
    
    }
    public pagereference closePopup(){
        
        //return new PageReference('javascript:window.self.close();window.top.close();');
        return new PageReference('/'+oppId);
    }
}