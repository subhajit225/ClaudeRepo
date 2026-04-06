public with sharing class SandboxRefreshEmailMaskInWorkFlowAlerts implements Database.Batchable<EmailAlertJSONParser.Records> , Database.Stateful, Database.AllowsCallouts{
    string sessionId = UserInfo.getSessionID();
    string domainUrl = URL.getSalesforceBaseUrl().toExternalForm();
    private ID sandboxRefreshConfigId;
    private Integer totalRecCounts = 0;
    private Integer totalFailureRecCounts = 0;
    private String errorMsg = '';
    private boolean isFailed = false; 
    
    //public static final map<Id, EmailTemplate> emailTemplatesMap = new map<Id, EmailTemplate>([SELECT Name, Id, FolderName, FolderId, Folder.DeveloperName, DeveloperName, Description FROM EmailTemplate LIMIT 20000]);  //WHERE IsActive = true
    
    public SandboxRefreshEmailMaskInWorkFlowAlerts(){}
    public SandboxRefreshEmailMaskInWorkFlowAlerts(ID sandboxRefreshConfigId){
        this.sandboxRefreshConfigId = sandboxRefreshConfigId;
    }
    public Iterable<EmailAlertJSONParser.Records> Start(Database.BatchableContext BC){   
        try{
            Organization orgInfo = [Select InstanceName, Name, NamespacePrefix, OrganizationType, IsSandbox, PrimaryContact  From Organization];
            if( !(orgInfo.IsSandbox || Test.isRunningTest()) ){
                return new List<EmailAlertJSONParser.Records>();
            }
            system.debug('********domainUrl:'+domainUrl);
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + sessionId);
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            String queryStr = 'SELECT+id,+EntityDefinitionId,+EntityDefinition.DeveloperName+,+DeveloperName,+CcEmails,+senderType,+TemplateId,+Description+FROM+WorkFlowAlert+WHERE+CcEmails+!=NULL';
            queryStr += Test.isRunningTest() ? '+LIMIT+1' : '+LIMIT+10000';
            req.setEndpoint(domainUrl+'/services/data/v51.0/tooling/query/?q=' + queryStr);
            req.setMethod('GET');
            req.setHeader('Accept','application/json');
            Http h = new Http();
            HttpResponse res = h.send(req);
            
            system.debug(res.getBody());
            //List<EmailAlertJSONParser> emailAlerts = (List<EmailAlertJSONParser>)System.JSON.deserialize('['+res.getBody().replace('&quotype"','"type__z"')+']', List<EmailAlertJSONParser>.class);
            List<EmailAlertJSONParser> emailAlerts = new List<EmailAlertJSONParser>();
            try{
                emailAlerts = (List<EmailAlertJSONParser>)System.JSON.deserialize('['+res.getBody()+']', List<EmailAlertJSONParser>.class);
            }catch(Exception e){
                errorMsg += e.getStackTraceString() + ' | ' + res.getBody();
                isFailed = true;
            }
            system.debug('emailAlerts '+emailAlerts);
            
            List<EmailAlertJSONParser.Records> emailAlertRecordList = new List<EmailAlertJSONParser.Records>();
            for(EmailAlertJSONParser ss : emailAlerts){
                system.debug('***EmailAlertJSONParser :'+ss);
                for(EmailAlertJSONParser.Records record : ss.records) {
                    if(record.attributes.type == 'WorkflowAlert') {
                        emailAlertRecordList.add(record);
                    }
                }
            }
            System.debug('emailAlertRecordList :: '+emailAlertRecordList);
            return emailAlertRecordList;
        }catch(Exception e){
            isFailed = true;
            errorMsg += e.getStackTraceString();
            SandboxRefreshUtil.updateSandboxRefreshConfig('Masking on Workflow Email Alerts', 'Failed', errorMsg);
        }
        return new List<EmailAlertJSONParser.Records>();
    }
    
    public void execute (Database.BatchableContext BC, List<EmailAlertJSONParser.Records> scope){    
        //System.debug('emailTemplatesMap :: '+emailTemplatesMap);
        Map<String, EmailAlertRecipientJSONParser> emailRecipientJSONParserMap = new Map<String, EmailAlertRecipientJSONParser>();
        for(EmailAlertJSONParser.Records record : scope) {
            if(record.attributes.type == 'WorkflowAlert' && record.attributes.url != null) {
                HttpRequest req = new HttpRequest();
                req.setHeader('Authorization', 'Bearer ' + sessionId);
                req.setHeader('Content-Type', 'application/json; charset=UTF-8');
                req.setEndpoint(domainUrl+record.attributes.url);
                req.setMethod('GET');
                req.setHeader('Accept','application/json');
                Http h = new Http();
                HttpResponse res = h.send(req);
                
                //system.debug(res.getBody());
                EmailAlertRecipientJSONParser emailAlertsRecipients = (EmailAlertRecipientJSONParser)System.JSON.deserialize(res.getBody(), EmailAlertRecipientJSONParser.class);
                //System.debug('emailAlertsRecipients :: '+emailAlertsRecipients);
                emailRecipientJSONParserMap.put(record.attributes.url, emailAlertsRecipients);
            }
        }
        if(!emailRecipientJSONParserMap.isEmpty()) {
            for(EmailAlertJSONParser.Records record : scope) {
                if(record.attributes.type == 'WorkflowAlert' && emailRecipientJSONParserMap.containsKey(record.attributes.url)) {
                    try{
                        system.debug('***EmailAlertJSONParser record :'+record.attributes); 
                        HttpRequest request = new HttpRequest();
                        request.setHeader('Authorization', 'Bearer ' +sessionId );
                        request.setHeader('Content-Type', 'application/json');
                        request.setEndPoint(domainUrl+record.attributes.url); 
                        String ccMails = record.CcEmails;
                        if(String.isNotBlank(ccMails)){
                            totalRecCounts++;
                            ccMails = ccMails.replaceAll(' ', '');
                            ccMails = ccMails.replaceAll('\n', ',');
                            ccMails = ccMails.replaceAll('\r', '');
                            ccMails = ccMails.replaceAll('\b', '');
                            ccMails = ccMails.replaceAll('.invalid', '');
                            ccMails = ccMails.replaceAll(';', ',');
                            List<String> recordccEmails = ccMails.split(',');
                            String ccEmails = '';
                            for(Integer i=0;i<recordccEmails.size();i++) {
                                String emailStr = recordccEmails[i].trim();
                                if(String.isNotBlank(emailStr)){
                                    ccEmails += (emailStr.endsWithIgnoreCase(SandboxRefreshUtil.EMAIL_SUFFIX) ? emailStr : emailStr + SandboxRefreshUtil.EMAIL_SUFFIX) + ', ';
                                }
                            }
                            ccEmails = ccEmails.removeEnd(', ').trim();
                            String recordTemplate = emailRecipientJSONParserMap.containsKey(record.attributes.url)?emailRecipientJSONParserMap.get(record.attributes.url).Metadata.template:'';
                            String recordRecipients = emailRecipientJSONParserMap.containsKey(record.attributes.url)?JSON.serialize(emailRecipientJSONParserMap.get(record.attributes.url).Metadata.recipients):'';
                            String recordSenderType = emailRecipientJSONParserMap.containsKey(record.attributes.url)?emailRecipientJSONParserMap.get(record.attributes.url).Metadata.senderType:'';
                            String recordSenderAddress = emailRecipientJSONParserMap.containsKey(record.attributes.url)?emailRecipientJSONParserMap.get(record.attributes.url).Metadata.senderAddress:'';
                            request.setMethod('PATCH');
                            String responseBody = '{"Metadata" : {"ccEmails" : ["'+ccEmails+'"],"description" : "'+record.Description+'","template" : "'+recordTemplate+'","senderAddress" : "'+recordSenderAddress+'","senderType" : "'+recordSenderType+'","recipients" : '+recordRecipients+'}}';
                            system.debug('responseBody :: '+responseBody);
                            request.setBody(responseBody);
                            Http http = new Http();
                            HttpResponse resp = http.send(request);
                            system.debug('resp :: '+resp);
                        }
                    }catch(Exception e){
                        errorMsg += e.getMessage() + ' | ';
                        totalFailureRecCounts++;
                    }
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        if(sandboxRefreshConfigId != null){
            update (new Sandbox_Refresh_Config__c(id=sandboxRefreshConfigId, Status__c = 'Completed', NoOfRecords__c = totalRecCounts, LastFailedRecordCount__c = totalFailureRecCounts, ErrorDetails__c = errorMsg));
        }else{
            if(isFailed){
                SandboxRefreshUtil.updateSandboxRefreshConfig('Masking on Workflow Email Alerts', 'Failed', errorMsg);
            }else{
                SandboxRefreshUtil.updateSandboxRefreshConfig('Masking on Workflow Email Alerts', 'Completed', errorMsg);
            }
        }
    }
    
    public class EmailAlertRecipientJSONParser {
        public cls_Metadata Metadata;
    }
    public class cls_Metadata {
        public cls_recipients[] recipients;
        public String senderAddress;
        public String senderType;	//CurrentUser
        public String template;	//Sales_Operations/Opportunity_Holdover_Request_Rejection
    }
    public class cls_recipients {
        public String field;
        public String recipient;	//pavan.m@rubrik.com
        public String type;	//user
    }
}