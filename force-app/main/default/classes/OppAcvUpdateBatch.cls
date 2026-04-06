public with sharing class OppAcvUpdateBatch implements Database.Batchable<SObject>, Database.Stateful{

    public String queryStr = 'SELECT Id, name FROM Opportunity WHERE Opportunity_Split_Parent__c = null and ((isClosed = true AND CloseDate >= :startDate) OR isClosed = false) '; 
    public boolean isSalesCompCategoryBatch = false;
    private List<Batch_Error_Log__c> errorLog = new List<Batch_Error_Log__c>();
    private Integer errorCount = 0;
    public Database.queryLocator start(Database.BatchableContext batchContext){
        Date startDate = Date.newInstance(2020, 2, 1);
        //Date endDate = Date.newInstance(2020, 10, 31);
        Set<Id> oppIdSet = new Set<Id>();
        if(isSalesCompCategoryBatch){
            queryStr = 'SELECT Id, name FROM Opportunity WHERE ID IN (Select OpportunityId from OpportunityLineItem where Opportunity.IsClosed = false AND Product2.SalesCompCategoryChangedDate__c = YESTERDAY)';
        }
        return Database.getQueryLocator(queryStr); 
    }
    public void execute(Database.BatchableContext batchContext, List<Opportunity> oppList){
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>(oppList);
        System.debug('\n++++Opportunity for ACV: ' + oppMap);
        flowControll.opportunityTriggerHandler = false;
        try{
            OppAnnualContractValueUtil.calculateAcvAmount(oppMap.keySet());
        }catch(Exception ex){
            String errorDetails =  '<b>' + ++errorCount + '  - ' + oppMap.keySet() + '  : </b> - ' + ex.getMessage() + '<br/>\n' + ex.getStackTraceString() + '<p/>';
            errorLog.add(new Batch_Error_Log__c(Name = oppMap.values()[0].name, Object_ID__c = oppMap.values()[0].id, Class_Name__c = 'OppAcvUpdateBatch', Failure_Job_ID__c = batchContext.getJobId(), Failure_Message__c = errorDetails));
        }
    }
    
    public void finish(Database.BatchableContext batchContext){
        if(!errorLog.isEmpty()){
            Database.insert(errorLog, false);
            notifyEmail(errorLog);
        }
    }
    public void notifyEmail(List<Batch_Error_Log__c> errorLog){
        String errorDetails = 'Hi ' + UserInfo.getFirstName() + ',<p/> ACV/ARR calculation is getting failed for below records. Please review these errors:<p/> ';
        for(Batch_Error_Log__c err: errorLog){
            errorDetails += err.Failure_Message__c;
        }
        errorDetails += '<p/>Thanks.<br/>Rubrik SFDC Admin';
        EmailHelper.sendBatchErrorsEmail(new List<String>{System.Label.SalesApps_Support_Email},
                                         'ACV/ARR calculation batch Errors - ' + Date.today().format(),
                                         errorDetails);
    }

}