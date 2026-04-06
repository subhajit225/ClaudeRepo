/*************************************************************************
Description : To clear partially insertted data into monitoring logs
              (monitoring logs with status init )
Author : Chaitra
**************************************************************************/
Public class ETMClearMonitoringLogs implements Database.Batchable<sObject>,schedulable{
   //pushed to qa  
   Public String WhereClause='where status__c = \'Init\' AND CreatedDate < today';
  
/**********************************************************
  Param : WhereClause
  sample : where status__c = \'New\' order by createddate 
************************************************************/   

   Public ETMClearMonitoringLogs(string WhereClause){
     if(String.isNotBlank(WhereClause))
      this.WhereClause = WhereClause;
     
   }

   Public Database.QueryLocator start(Database.BatchableContext BC){
      string query = 'Select id from ETMStage_Monitoring__c '+WhereClause ;
      system.debug('Monitoring Class query=>'+query);
      return Database.getQueryLocator(query);
   }

   Public void execute(Database.BatchableContext BC, List<ETMStage_Monitoring__c> monitoringLogs){
     try{
     
         Database.delete(monitoringLogs,false);
     }
     catch(exception e){
       insert LogError.CreateGenericErrorLog('ETMClearMonitoringLogs',e,'ETM');
     }
    }

   Public void finish(Database.BatchableContext BC){
   }
   
    Public void execute(SchedulableContext SC) {
        Database.ExecuteBatch(new ETMClearMonitoringLogs(WhereClause),1000);
    }
}