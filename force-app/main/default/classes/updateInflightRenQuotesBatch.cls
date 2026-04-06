/*************************************************************************************************************
Description : Arroyo 2.0 Project
Developer : Shaloo
Date : 5-5-2025

Script to execute the Batch Class:
System.schedule('ShalTest', '0 45 16 * * ?', new updateInflightRenQuotesBatch());
************************************************************************************************************/

public with sharing class updateInflightRenQuotesBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {
    /**query */
    public String query;
    /**qliList */
    public List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
    
    /**Constructor */
    public updateInflightRenQuotesBatch(){
        query = 'SELECT Id, SBQQ__Quote__r.Name, SBQQ__ProductCode__c, Quote_Line_Type__c, SBQQSC__RenewedContractLine__c, CCLI__c, Arroyo_Subsumed_Old_Contract_Line_Items__c FROM SBQQ__QuoteLine__c WHERE SBQQSC__RenewedContractLine__c != null AND SBQQ__Quote__r.SBQQ__Type__c = \'Renewal\' ORDER BY SBQQ__Quote__r.CreatedDate DESC';
        //AND SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName != \'7 Closed Admin\' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName != \'7 Closed Lost\' 
        //AND SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName != \'7 Closed Won\'
    }
    
    /**Constructor */
    public updateInflightRenQuotesBatch(List<SBQQ__QuoteLine__c> qliList){
        query = 'SELECT Id, SBQQ__Quote__r.Name, SBQQ__ProductCode__c, Quote_Line_Type__c, SBQQSC__RenewedContractLine__c, CCLI__c, Arroyo_Subsumed_Old_Contract_Line_Items__c FROM SBQQ__QuoteLine__c WHERE Id IN: qliList';//\''+qliList+'\'';
    }
    
    /**Start Method */
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator(query);
    }
    
    /**Execute Method */
    public void execute(Database.BatchableContext batchableContext, List<SBQQ__QuoteLine__c> scope){
        Map<Id, SBQQ__QuoteLine__c> qliListToUpdateMap = new Map<Id, SBQQ__QuoteLine__c>();
        try{
            for(SBQQ__QuoteLine__c qli: scope)
            {
                //qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qli.CCLI__c == null ||  qli.CCLI__c == '') ? qli.SBQQSC__RenewedContractLine__c : qli.SBQQSC__RenewedContractLine__c + ',' + qli.CCLI__c;
                qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = (qli.CCLI__c == null ||  qli.CCLI__c == '') ? qli.SBQQSC__RenewedContractLine__c : (qli.CCLI__c.contains(qli.SBQQSC__RenewedContractLine__c)) ? qli.CCLI__c : qli.SBQQSC__RenewedContractLine__c + ',' + qli.CCLI__c;
                qliListToUpdateMap.put(qli.Id, qli);
            }
            system.debug('qliListToUpdateMap: ' + qliListToUpdateMap);
            
            /*List<ShGl_DisableBusinessLogic__c> recToUpdate = new List<ShGl_DisableBusinessLogic__c>();

system.debug('CPQ Admin Custom Label: ' + System.Label.CPQ_Admin_User_Name);

ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
if(System.Label.CPQ_Admin_User_Name != null){
system.debug('Inside Label Check: ' + System.Label.CPQ_Admin_User_Name);    
settingDisable = [SELECT Id, Disable_Opportunity_Validation_Rules__c, Disable_Opportunity_Triggers__c, 
Disable_SBQQ_Quote_Validation_Rules__c, Disable_SBQQ_Quote_Triggers__c, 
Disable_SBQQ_QuoteLine_Validation_Rules__c, Disable_SBQQ_QuoteLine_Triggers__c 
FROM ShGl_DisableBusinessLogic__c WHERE SetupOwner.Name =: System.Label.CPQ_Admin_User_Name];
}
system.debug('settingDisable B4: ' + settingDisable);

settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;
settingDisable.Disable_Opportunity_Triggers__c = TRUE;
settingDisable.Disable_SBQQ_Quote_Validation_Rules__c = TRUE;
settingDisable.Disable_SBQQ_Quote_Triggers__c = TRUE;
settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = TRUE;
settingDisable.Disable_SBQQ_QuoteLine_Triggers__c = TRUE;
recToUpdate.add(settingDisable);
update recToUpdate;

system.debug('settingDisable A4: ' + settingDisable);
system.debug('recToUpdate: ' + recToUpdate);*/
            system.debug('Size: ' + qliListToUpdateMap.values().size());
            if(qliListToUpdateMap.values().size() > 0){
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                update qliListToUpdateMap.values();
                SBQQ.TriggerControl.disable();
            }
            system.debug('qliListToUpdateMap : ' + qliListToUpdateMap.values());
            system.debug('qliListToUpdateMap Size: ' + qliListToUpdateMap.values().size());
        }
        catch(Exception ex){
            system.debug('Exception occured : ' + ex);
            system.debug(LoggingLevel.Error, 'err' + ex.getMessage());
            List<Batch_Error_Log__c> belList = new List<Batch_Error_Log__c>();
            for(SBQQ__QuoteLine__c qli: qliListToUpdateMap.values()){Batch_Error_Log__c bel = new Batch_Error_Log__c();bel.Failure_Job_ID__c = batchableContext.getJobID();bel.Object_ID__c = qli.Id;bel.Failure_Message__c = ex.getMessage();belList.add(bel);}
            insert belList;
        }
    }
    
    /**Finish Method */
    public void finish(Database.BatchableContext batchableContext){
        System.debug('Finish Method');
    }
    
    /**Execute Method */
    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(new updateInflightRenQuotesBatch());
    }
}