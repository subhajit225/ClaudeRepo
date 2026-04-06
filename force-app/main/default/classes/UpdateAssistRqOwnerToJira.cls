/** 
* @Author      : Raveesh Layal
* @CreatedDate : 11th July 2023
* @Description : Add Jira Watchers upon new Assist Request or if a owner is changed.
* @TstClass    : AssistRequestTriggerTest
* @Jira		   : CS21-1713
* @Sharing	   : Without Sharing- As the class functionality is to sync the records from Salesforce to JIRA, should run in System Context to avoid any issues while syncing. 

* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
*  		           
* --------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class UpdateAssistRqOwnerToJira{
    public static String username; // JIRA username
    public static String password; // JIRA password // Constructs Basic Http Authentication header from provided credentials
    public static String baseUrl;   // Base URL of your JIRA instance
    public static Map<id,user> userIdToObjMap=new Map<id,user>();
    
    /**
* @description : Method to add the Watchers in JIRA
* @param  	: None
* @return 	: None
* @JIRA 	: CS21-1713
*/
    @future(callout=true)
    public static void updateWatchers(string arListString,string oldMapString, Boolean isInsert){
        getJiraCredential();
        list<Assist_Request__c > arList = (list<Assist_Request__c >)Json.deserialize(arListString,List<Assist_Request__c>.class);
        Map<Id, Assist_Request__c>oldMap=(Map<Id, Assist_Request__c>)Json.deserialize(oldMapString,Map<Id, Assist_Request__c>.class);
        Map<String,String> jiraReferenceToOwnerEmail=new map<String,String>();
        Map<id,set<id>> caseidToAssistRequestMap=new Map<id,set<id>>();
        map<id,id> CaseIdToOwnerId =new map<id,id>();
        for(Assist_Request__c arc:arList)
        {
            
            If (arc.ownerid.getsobjecttype() == User.sobjecttype && (isInsert|| (!isInsert && oldMap.containsKey(arc.Id) && ((arc.OwnerId!=oldMap.get(arc.Id).OwnerID) || (arc.JIRA_Reference__c!=oldMap.get(arc.Id).JIRA_Reference__c ))))) { 
                
                CaseIdToOwnerId.put(arc.Case__c,arc.OwnerId);
            } 
            
            
        }
        if(CaseIdToOwnerId.values().size()>0){
            userIdToObjMap=new Map<id,user>([SELECT id,email from User where Id IN: CaseIdToOwnerId.values()]);  
            
            for(Assist_Request__c arqq:[select id,case__c  from Assist_Request__c where case__c in:CaseIdToOwnerId.keyset() order by createddate asc])
            {
                if(caseidToAssistRequestMap.containskey(arqq.case__c))
                {
                    caseidToAssistRequestMap.get(arqq.case__c).add(arqq.id);
                }else{
                    caseidToAssistRequestMap.put(arqq.case__c,new set<id>{arqq.id});
                }
            }
            
        }
        
        for(Assist_Request__c ar:arList){
            If (ar.ownerid.getsobjecttype() == User.sobjecttype && (isInsert|| (!isInsert && ((ar.OwnerId!=oldMap.get(ar.Id).OwnerID) || (ar.JIRA_Reference__c!=oldMap.get(ar.Id).JIRA_Reference__c))))  && caseidToAssistRequestMap.containsKey(ar.case__c) && new list<id>(caseidToAssistRequestMap.get(ar.case__c))[0]==ar.id) { 
                List<String> JiraReferenceList=new list<string>();
                if(ar.JIRA_Reference__c!=null)
                {
                    JiraReferenceList = ar.JIRA_Reference__c.split(',');
                }
                for(integer i=0;i<JiraReferenceList.size();i++)
                {
                    String JIRA_Reference_value = JiraReferenceList[i].substring(JiraReferenceList[i].indexOf('">') + 2,JiraReferenceList[i].lastIndexOf('<'));
                    if(JIRA_Reference_value.startswith('CDM-') || JIRA_Reference_value.startswith('SPARK-'))
                    {
                        jiraReferenceToOwnerEmail.put(JIRA_Reference_value,userIdToObjMap.get(ar.OwnerId).Email);
                    }
                    
                }
                //Check if any Jira reference has been removed
                if(!isInsert && oldMap.get(ar.Id).JIRA_Reference__c!=null && ar.JIRA_Reference__c!=oldMap.get(ar.Id).JIRA_Reference__c){
                    for(String oldRef:oldMap.get(ar.Id).JIRA_Reference__c.split(',')){
                        if(oldRef!=null && !String.isEmpty(oldRef)){
                            String JIRA_Reference_value = oldRef.substring(oldRef.indexOf('">') + 2,oldRef.lastIndexOf('<'));
                        if((ar.JIRA_Reference__c!=null && JIRA_Reference_value!=null && !ar.JIRA_Reference__c.contains(JIRA_Reference_value)) || ar.JIRA_Reference__c==null){
                            jiraReferenceToOwnerEmail.put(JIRA_Reference_value,null);    
                        }
                    }
                    }
                }
            }
        }
        
        if(jiraReferenceToOwnerEmail.size()>0){
            addWatchersFromJira(jiraReferenceToOwnerEmail);
        }
        
        
        
        
    }
    
    
    /**
* @description : Method to sync the Watchers in JIRA
* @param  	: Map<String,Set<String>>jiraReferenceToOwnerEmail (Map of JIRA issues ID to user Email)
* @return 	: None
* @JIRA 	: CS21-1713
* @Dependencies: UpdateJiraIssueWatchers, AddAssistReqOwnersToJira
*/ 
    public static void addWatchersFromJira( Map<String,String>jiraReferenceToOwnerEmail)
    {
        String jiraField = Label.AssistRequestOwnerJiraField ; //label to store JIRA field api name. e.g., customfield_13178
        List<zsfjira.ZCBeans.IssueTemplate> jiraIssueTemplates = new List<zsfjira.ZCBeans.IssueTemplate>();
        for(string jiraReferenceValue :jiraReferenceToOwnerEmail.keyset())
        {
            zsfjira.ZCBeans.IssueTemplate template = new zsfjira.ZCBeans.IssueTemplate(jiraReferenceValue);
            template.addCustomField(jiraField, jiraReferenceToOwnerEmail.get(jiraReferenceValue));
            jiraIssueTemplates.add(template);
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
    
    public static void getJiraCredential()
    {
        List<Connection_Config__mdt> mdtList = [Select Id, URL__c, User_Name__c, Password__c from 
                                                Connection_Config__mdt where DeveloperName = 'Agile_Connect_JIRA_Config' LIMIT 1];
        if(mdtList != null && !mdtList.isEmpty()){
            Connection_Config__mdt mdt =  mdtList[0];
            baseUrl = mdt.URL__c;
            username = mdt.User_Name__c; // JIRA username
            password = mdt.Password__c; // JIRA password // Constructs Basic Http Authentication header from provided credentials
        }
    }
    
}