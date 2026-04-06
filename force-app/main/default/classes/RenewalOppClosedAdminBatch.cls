/**
* @description Batch Job to update the Opportunity stage to Closed Admin
*              FY25SR-1111  
* @modifiedDate 20th April 2025
**/
public class RenewalOppClosedAdminBatch implements Database.Batchable<SObject>, Database.Stateful{ //SAL24-526
    public string RENEWAL = 'Renewal';
    public string PartialReplacement='Partial Replacement';
    private static ShGl_DisableBusinessLogic__c csInstanceToUpdate,
        csInstanceToDelete = null;
    public List<Custom_Error_Log__c> customErrorLogs = new List<Custom_Error_Log__c> ();
    /**
    * @description Batch Job to update the Opportunity stage to Closed Admin-Strat method
    * @return query
    * @param BC
    **/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        string query = '';
        //String idd='810VI000003ZixJYAS';
        if(!Test.isRunningTest()){
            //query = 'select Id,StageName,Lost_Reason__c,Opportunity_Sub_Type__c,SBQQSC__RenewedServiceContract__c from Opportunity where Number_of_Opportunity_Products__c = 0 AND SBQQ__PrimaryQuote__c!= null AND SBQQ__PrimaryQuote__r.SBQQ__Uncalculated__c = false AND Opportunity_Sub_Type__c =: RENEWAL AND isClosed = false AND LastModifiedDate > 2022-12-01T00:00:00.000+0000';//REEN-25
            query = 'select Id,StageName,Lost_Reason__c,Opportunity_Sub_Type__c,Name,SBQQSC__RenewedServiceContract__c,Closed_Admin_Opporutinty__c,Number_of_Opportunity_Products__c from Opportunity where ((Closed_Admin_Opporutinty__c=:PartialReplacement AND Number_of_Opportunity_Products__c != 0) OR (Number_of_Opportunity_Products__c = 0 AND SBQQ__PrimaryQuote__c!= null AND SBQQ__PrimaryQuote__r.SBQQ__Uncalculated__c = false)) AND Opportunity_Sub_Type__c =: RENEWAL AND isClosed = false AND LastModifiedDate > 2022-12-01T00:00:00.000+0000';// AND ID=:idd
        }else if(Test.isRunningTest()){
            query = 'select Id,StageName,Lost_Reason__c,Opportunity_Sub_Type__c,SBQQSC__RenewedServiceContract__c,Closed_Admin_Opporutinty__c,Number_of_Opportunity_Products__c from Opportunity limit  2';
        }
        if(query != ''){
            return Database.getQueryLocator(query);
        }else{
            return null;
        }
    } 
    /**
    * @description Batch Job to update the Opportunity stage to Closed Admin-Execute method
    * @param BC
    * @param scope
    **/
    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<Opportunity> closedAminDuplicateOpp=new List<Opportunity>();//added  
        List<Opportunity> closedAminOpp=new List<Opportunity>();//added 
        
        for(Opportunity opp : scope){ //modified
            if(opp.Closed_Admin_Opporutinty__c!=null && opp.Closed_Admin_Opporutinty__c=='Partial Replacement' && opp.Number_of_Opportunity_Products__c != 0)
            {
                closedAminOpp.add(opp);  
            }
            else
            {
                closedAminDuplicateOpp.add(opp);
            }   
        }
        system.debug(LoggingLevel.DEBUG, '@@closedAminOpp'+closedAminOpp);
        system.debug(LoggingLevel.DEBUG, '@@closedAminDuplicateOpp'+closedAminDuplicateOpp); 
        
        List<Opportunity> opptyToUpdate = new List<Opportunity>();
        //start Khushboo
        if(closedAminOpp!=null && !closedAminOpp.isEmpty()){
            for(Opportunity op:closedAminOpp){
                opptyToUpdate.add(new Opportunity(Id = op.Id,Lost_Reason__c = 'Replaced',StageName = '7 Closed Admin',CloseDate = Date.Today()));
              }
        }
        
        if(closedAminDuplicateOpp!=null && !closedAminDuplicateOpp.isEmpty()){
            for (Opportunity op:closedAminDuplicateOpp) {
                opptyToUpdate.add(new Opportunity(Id = op.Id,Lost_Reason__c = 'Duplicate opp',StageName = '7 Closed Admin',CloseDate = Date.Today()));
              }
        }
        //end
        if (!opptyToUpdate.isEmpty()) {
            List<ShGl_DisableBusinessLogic__c> dflList = [SELECT Id, Disable_Opportunity_Validation_Rules__c, Name, SetupOwnerId FROM ShGl_DisableBusinessLogic__c WHERE SetupOwnerId = :UserInfo.getUserId()];
            if (dflList.isEmpty()) {
                csInstanceToDelete = new ShGl_DisableBusinessLogic__c();
                csInstanceToDelete.Disable_Opportunity_Validation_Rules__c = true;
                csInstanceToDelete.SetupOwnerId = userinfo.getUserId();
                insert csInstanceToDelete;
            } else {
                if (!dflList[0].Disable_Opportunity_Validation_Rules__c) {
                    csInstanceToUpdate = dflList[0];
                    csInstanceToUpdate.Disable_Opportunity_Validation_Rules__c = true;
                    csInstanceToUpdate.SetupOwnerId = userinfo.getUserId();
                    update csInstanceToUpdate;
                }
            }
            FlowControll.opportunityTriggerHandler = false;
            FlowControll.opportunityTriggerHandler = false;
            FlowControll.accountTrigger = false;
            OppAnnualContractValueUtil.OppACVRecursion = true;//REEN-25
            //Database.update(opptyToUpdate, false);
            List<Database.SaveResult> srList = Database.update(opptyToUpdate,false);
            List<Custom_Error_Log__c> errorLogList = LogError.createDMLErrorLogWithRetrunType((List<SObject>)opptyToUpdate, srList, 'RenewalOppClosedAdminBatch','RenewalOppClosedAdminBatch');
            System.debug(LoggingLevel.DEBUG, 'errorLogList '+errorLogList);
            customErrorLogs.addAll(errorLogList);
            if (csInstanceToUpdate != null) {
                csInstanceToUpdate.Disable_Opportunity_Validation_Rules__c = false;
                update csInstanceToUpdate;
            }
            if (csInstanceToDelete != null) {
                delete csInstanceToDelete;
            }
        }
    }
    /**
    * @description Batch Job to update the Opportunity stage to Closed Admin-Finish method
    * @param BC
    **/
    public void finish(Database.BatchableContext BC) {
        if(!customErrorLogs.IsEmpty() || Test.isRunningTest()){
            string emailDetail = EmailHelper.prepareEmailBodyForCustomErrorLog(customErrorLogs);
            EmailHelper.sendBatchErrorsEmail(new List<String>{System.Label.SalesApps_Support_Email},
                                             'RenewalOppClosedAdminBatch salesopsbatcherror - ' + Date.today().format(),
                                             emailDetail); 
        }
    }
}