/**
* @File Name : AccountDiscountHistoryBatch.cls
* @description : FY26WL-506 , FY26WL-507, FY26WL-508, FY26WL-588 - Account Discount History implementation
* @Author : Deepak Verma
* @Last Modified By : Deepak Verma 
* @Last Modified On :  january 19, 2025
* @Modification Log :
* Test Class : AccountDiscountHistoryTest
*************************************************************************************************/
public class AccountDiscountHistoryBatch implements Database.Batchable<sObject> {    
    

    String sQuery;
     /** 
     * @description public AccountDiscountHistoryBatch
     * @param sQuery
     */
    public AccountDiscountHistoryBatch(String sQuery){
        this.sQuery = sQuery;
    }
    /** 
     * @description public Database.QueryLocator
     * @param BC
     * @return sQuery
     */
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(sQuery);
    }
    /** 
     * @description global Database.QueryLocator start
     * @param BC
     * @param accountDetails
     */
    public void execute(Database.BatchableContext BC, List<Account> accountDetails){
        try{   
            Set<Id> closeWonOppSet = new Set<Id>();
            for(Opportunity opp : [SELECT Id, Name, AccountId, StageName 
                 FROM Opportunity 
                WHERE AccountID IN : accountDetails 
                  and StageName = :Constants.OPP_STAGE_FINAL]){
                closeWonOppSet.add(opp.Id);
            }
            Map<String, Account_Discount_History__c> adhMap = new Map<String, Account_Discount_History__c>();
            accountDiscountHistoryUtility accountDiscountHistoryUtilityObj = new accountDiscountHistoryUtility();
            adhMap = accountDiscountHistoryUtilityObj.createUpdateAccountDiscountHistory(closeWonOppSet);
            if(!adhMap.isEmpty()){
                Database.UpsertResult[] results = Database.upsert(adhMap.values(),false);
                List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();
                for (Database.UpsertResult ar : results) {
                    if (!ar.isSuccess() || Test.isRunningTest()) {
                        for (Database.Error err : ar.getErrors()){
                            errorLogList.add(LogError.CreateDMLErrorLog(
                                'AccountDiscountHistoryQueuelable',
                                ar.getId(),
                                err.getMessage(), 
                                'Create account discount history records for all closed won opportunity associated to that account'
                            ));
                        }
                    }
                }
                if(!errorLogList.isEmpty()){
                    insert errorLogList;
                }
            }
        }
        catch(Exception ex){
            Custom_Error_Log__c exceptionErrorLog = LogError.CreateDMLErrorLog('AccountDiscountHistoryQueuelable', '', ex.getMessage()+' at line no. '+ex.getLineNumber() + ex.getStackTraceString(), 'Create account discount history records for all closed won opportunity associated to that account');
            insert exceptionErrorLog;
        }
    }
    /** 
     * @description public Database.QueryLocator start
     * @param BC
     */
    public void finish(Database.BatchableContext BC){
        System.debug(LoggingLevel.DEBUG, 'Finish method');
    }
    
}