global class Case_Update_Batch implements Database.Batchable<sObject> , Database.stateful{

 global Database.QueryLocator start(Database.BatchableContext BC){
     
    string name='Standard SLA';
    string dateval = '2099-11-10';
    string whereClause = ' Entitlement.name = \'' + name + '\' and Entitlement.enddate ='+dateval;
    //string query= 'Select id,name from Account where'+whereClause;
    string query= 'select id,casenumber, Entitlement.name from case where '+whereclause +(Test.isRunningTest()?' LIMIT 20':'');
      return Database.getQueryLocator(query);
   }
global void execute(Database.BatchableContext BC, List<Case> scope){
 List<Case> caseList = new List<Case>();
 for(case caserec : scope){
    caserec.EntitlementId = null;
    caseList.add(caserec);
}
system.debug('caseList =='+caseList.size()+caselist);
update caselist;
}
global void finish(Database.BatchableContext BC){
       
       System.debug('Compeleted');
   }
   }