/**
* @File Name : AccountDiscountHistoryQueuelable.cls
* @description : FY26WL-506 , FY26WL-507, FY26WL-508, FY26WL-588 - Account Discount History queueable
* @Author : Deepak Verma
* @Last Modified By : Deepak Verma 
* @Last Modified On :  January 19, 2026
* @Modification Log :
* Test Class : AccountDiscountHistoryTest
*************************************************************************************************/
public with sharing class AccountDiscountHistoryQueuelable implements Queueable {
    @TestVisible static Boolean forceExecuteError = false;
    private Set<Id> closeWonOppSet;

    /** 
     * @description Apex method to pass parameter. 
     * @param closeWonOppSet
     * This method contains account discount history calculation.
     */
    
    public accountDiscountHistoryQueuelable(Set<Id> closeWonOppSet){
        this.closeWonOppSet = closeWonOppSet;
    }

    /** 
     * @description Apex method to handle create upsert Discount history 
     * @param context
     * This method contains account discount history calculation.
     */
    
    public void execute(QueueableContext context) {
        try{
            accountDiscountHistoryUtility accountDiscountHistoryUtilityObj = new accountDiscountHistoryUtility();
            Map<String, Account_Discount_History__c> adhMap = accountDiscountHistoryUtilityObj.createUpdateAccountDiscountHistory(closeWonOppSet);
            if(!adhMap.isEmpty()){
                upsert adhMap.values();
            }
            if(forceExecuteError){
                throw new DMLException('Test Class Error');
            }
        }catch(Exception ex){
            if (!Test.isRunningTest() && AsyncInfo.getCurrentQueueableStackDepth() < 2) { System.enqueueJob(new accountDiscountHistoryQueuelable(closeWonOppSet), 5);
            }else{
                LogError.logCustomError('accountDiscountHistoryQueuelable',ex.getMessage()+' at line no. '+ex.getLineNumber(),ex.getStackTraceString(),'Create account discount history records for all closed won opportunity associated to that account');
            }
        }
    }
}