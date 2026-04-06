/** 
* @Author      : Raveesh Layal
* @CreatedDate : 11th July 2023
* @Description : Add Jira Watchers upon new Assist Request or if a owner is changed.
* @TstClass    : AssistRequestTriggerTest
* @Jira		   : CS21-1713

* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
*  		           
* --------------------------------------------------------------------------------------------------------------------------------
*/
public class AddAssistReqOwnersToJira implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
    public String query;
    public set<string> jiraReferenceValueSet= new set<string>();
    
    public AddAssistReqOwnersToJira(String query)
    {
        this.query=query;
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator(query);
    }
    
    
    public void execute(Database.BatchableContext batchableContext, List<assist_request__c> arList){
        Map<String,String> jiraReferenceToOwnerEmail=new map<String,String>();
        
        for(Assist_request__c arc:arList)  
        {
            if(!String.isEmpty(arc.JIRA_Reference__c) )
            {               
               
                for(integer i=0;i<arc.JIRA_Reference__c.split(',').size();i++)
                {
                    String jiraValue=arc.JIRA_Reference__c.split(',')[i];
                    String JIRA_Reference_value = jiraValue.substring(jiraValue.indexOf('">') + 2,jiraValue.lastIndexOf('<'));
                    if(!jiraReferenceValueSet.contains(JIRA_Reference_value))
                    {
                        
                        if(JIRA_Reference_value.startswith('CDM-') || JIRA_Reference_value.startswith('SPARK-'))
                        {
                            jiraReferenceToOwnerEmail.put(JIRA_Reference_value,arc.owner.email);
                            jiraReferenceValueSet.add(JIRA_Reference_value);
                        } 
                    }
                    
                    
                }
            } 
            
            
        }
        
        if(jiraReferenceToOwnerEmail.size()>0){
            UpdateAssistRqOwnerToJira.addWatchersFromJira(jiraReferenceToOwnerEmail);
        }
        
    }
    
    public void finish(Database.BatchableContext batchableContext){
        System.debug(LoggingLevel.DEBUG, 'Salesforce to JIRA Case Owner updates.');
    }
    
}