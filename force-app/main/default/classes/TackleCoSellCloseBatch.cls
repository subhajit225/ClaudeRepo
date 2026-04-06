/**
 * @description Class to close Tackle CoSell records when a realted opportunity is closed
*/
public with sharing class TackleCoSellCloseBatch  implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    String queryStr;
    public List<Custom_Error_Log__c> customErrorList = new List<Custom_Error_Log__c>();
    /**
     * @description constructor
    */
    public TackleCoSellCloseBatch(String queryStr){
        this.queryStr = queryStr;
    }
    /**
     * @description start method
    */
    public Database.queryLocator start(Database.BatchableContext batchContext){
        List<String> cloudPartner = new List<String>{'aws'};//'mspc'
        String queryStrStart = 'SELECT Id, tackle__Stage__c, tackle__ClosedLost_Reason__c, tackle__Opportunity__r.StageName, tackle__Opportunity__r.Amount, tackle__Opportunity__r.CloseDate, tackle__Opportunity__r.OppSubscriptionTermMonths__c FROM tackle__Tackle_Co_Sell__c WHERE tackle__Opportunity__r.isClosed = TRUE and (tackle__Is_Closed__c = false or tackle__SF_Stage__c != \'Closed\') and tackle__Cloud_Partner__c in :cloudPartner'; //SAL25-616 //SAL25-700
        queryStr = queryStr != null ? queryStr : queryStrStart;
        return Database.getQueryLocator(queryStr); 
    }
    /**
     * @description batch execute method
    */
    public void execute(Database.BatchableContext batchContext, List<tackle__Tackle_Co_Sell__c> tCoSellList){
        List<tackle__Tackle_Co_Sell__c> openTackleCoSellRecs = new List<tackle__Tackle_Co_Sell__c>();
        for(tackle__Tackle_Co_Sell__c tcs:tCoSellList){
            tcs.tackle__Is_Closed__c = TRUE;
            tcs.tackle__SF_Stage__c = 'Closed';
            tcs.tackle__Stage__c = tcs.tackle__Opportunity__r.StageName == '7 Closed Won' ? 'Closed Won' : 'Closed Lost';
            tcs.tackle__ClosedLost_Reason__c = tcs.tackle__Opportunity__r.StageName == '7 Closed Won' ? '' : 'Other';
            //SAL25-616
            if(tcs.tackle__Stage__c == 'Closed Won'){
                tcs.tackle__Customer_Software_Value__c = tcs.tackle__Opportunity__r.Amount;
                tcs.tackle__Contract_Start_Date__c = tcs.tackle__Opportunity__r.CloseDate;
                Integer ost = tcs.tackle__Opportunity__r.OppSubscriptionTermMonths__c != null ? (Integer)tcs.tackle__Opportunity__r.OppSubscriptionTermMonths__c : 12;
                tcs.tackle__Contract_End_Date__c = tcs.tackle__Opportunity__r.CloseDate.addMonths(ost);
                tcs.tackle__Customer_Software_Value_Currency__c = 'USD';
                tcs.tackle__V2_Procurement_Type__c = 'Subscription'; //SAL25-700
            }
            openTackleCoSellRecs.add(tcs);
        }
        //update tackle co-sell records
        if(!openTackleCoSellRecs.isEmpty()){
            List<Database.SaveResult> srList = Database.update(openTackleCoSellRecs, false);
            List<Custom_Error_Log__c> errorLogList = LogError.createDMLErrorLogWithRetrunType((List<SObject>)openTackleCoSellRecs, srList, 'TackleCoSellCloseBatch','Close Tackle Co-Sell Records in Batch'); //SAL25-717
            customErrorList.addAll(errorLogList); //SAL25-717
        }
    }
    /**
     * @description batch finish method
    */
    public void finish(Database.BatchableContext batchContext){
        /* Start SAL25-717 */
        if(!customErrorList.isEmpty()){
            string emailDetail = EmailHelper.prepareEmailBodyForCustomErrorLog(customErrorList);
            EmailHelper.sendBatchErrorsEmail(new List<String>{System.Label.SalesApps_Support_Email},
                                            'TackleCoSellCloseBatch tacklebatcherror - ' + Date.today().format(),
                                            emailDetail); 
        }
        /* End SAL25-717 */
    }
    /**
     * @description schedule execute method
    */
    public void execute(SchedulableContext sc){
		Database.executeBatch(new TackleCoSellCloseBatch(null), 200);
    }
}