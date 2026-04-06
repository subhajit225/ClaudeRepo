/*
Author:Akashdeep Singh
Date: 7 September 2020
Ticket No:  CS21-272
Description: Checks the Inactivity  on Case.If there has been no activity on case for last five days.
And if case status is one of the following values 
• Waiting for Rubrik Support
• In Progress
• New
• Waiting for Engineering .
Add the count in the field "Backlog Inactivity (KPI)"
Backlog_Inactivity_KPI__c
*/
global class CaseInactivityBatch  implements Database.Batchable<sObject> {
    
    public set<string> statusValues=new set<string> {'Waiting for Rubrik Support' ,'In Progress' , 'New' ,'Waiting for Engineering'};
    public string query;
    
    public CaseInactivityBatch( string querystr){
        
        this.query =querystr;
    }
    
     public CaseInactivityBatch(){
  
    }
        
        global Database.QueryLocator start(Database.BatchableContext BC){
            DateTime dt= Date.Today().addDays(-5);  
            if(string.isEmpty(query)){
                query='select id,Backlog_Inactivity_KPI__c,Status,LastModifiedDate from Case where LastModifiedDate <= :dt';
                system.debug('query1111'+query);
            }
            system.debug('query@@@'+query);
            return Database.getQueryLocator(query);
        }
    
    global void execute(Database.BatchableContext BC, List<case> caseList) {
        
        // process each batch of records default size is 200
        List<Case> caseListToUpdate = new List<Case>();
        for(Case cs : caseList) { 
            
           if(statusValues.contains(cs.Status) ){
                System.debug('cs@@@'+cs);
                
                if(NULL != cs.Backlog_Inactivity_KPI__c){
                    cs.Backlog_Inactivity_KPI__c +=1;
                }
               else{
                     cs.Backlog_Inactivity_KPI__c=0;
                     cs.Backlog_Inactivity_KPI__c +=1; 
                }
                
                caseListToUpdate.add(cs);
                
            } 
        }
        
        update  caseListToUpdate;
        system.debug('caseListToUpdate'+caseListToUpdate);
    }  
    
    global void finish(Database.BatchableContext BC) {
       
    }
    
}