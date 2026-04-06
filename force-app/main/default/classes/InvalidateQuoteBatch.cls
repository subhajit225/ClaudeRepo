/**
 * Description: This batch Invalidates the Quotes with Status 'In review' or 'Approved' as part of CPQ22-3092
 *              if Opportunity is not moved to Stage 6 or 7 before the “Free HW Eligibility Expiration date”
 * 
 *              Can only be executed in PROD post August 1st 2024
 *
 * Author:      Mustakim Shaikh
 * Date:        May 2, 2024
 */
 
 global class InvalidateQuoteBatch implements Database.Batchable<sObject>, Database.Stateful {
    
  static Set<Id> qtIdsAlreadyProcessed = new Set<Id>();
    
    Map<String, Date> astSNvsExpDtMap = new Map<String, Date>();
    Set<Id> acIds = new Set<Id>();
    List<String> errorLogs;

    global InvalidateQuoteBatch(Map<String, Date> astSNvsExpDtMap, Set<Id> accIds) {
        this.astSNvsExpDtMap = astSNvsExpDtMap;
        this.acIds.addAll(accIds);
        this.errorLogs = new List<String>();
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, SBQQ__Opportunity2__r.StageName,SBQQ__Opportunity2__r.CloseDate, Name, SBQQ__Status__c,Show_Trade_Up_Discount__c, Trade_Up_Amounts__c, Trade_Up_Serial_Numbers__c FROM SBQQ__Quote__c WHERE (SBQQ__Status__c = \'Approved\' OR SBQQ__Status__c = \'In Review\' OR SBQQ__Status__c = \'Expired\') AND SBQQ__Opportunity2__r.StageName != \'6 PO With Channel\' AND SBQQ__Opportunity2__r.StageName != \'7 Closed Won\' AND SBQQ__Opportunity2__r.StageName != \'7 Closed Lost\' AND SBQQ__Account__c IN: acIds';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quotes) {
        
        Map<Id, SBQQ__Quote__c> quotesToUpdate = new Map<Id, SBQQ__Quote__c>();
        String recordTypeID = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get('Invalid_Quote').getRecordTypeId();
        
        
        for(SBQQ__Quote__c qt : quotes){
          for(String astSN : astSNvsExpDtMap.keySet()){
            //if(quotesToUpdate.containskey(qt.Id)){ break;}
            if(qtIdsAlreadyProcessed.contains(qt.Id) || qt.Trade_Up_Serial_Numbers__c == null){ 
                System.debug('MS inside break Qt Name '+qt.Name);
                break;
            }

            else if(qt.Trade_Up_Serial_Numbers__c != null && qt.Trade_Up_Serial_Numbers__c.contains(astSN)){
                System.debug('MS adding Quotes to quotesToUpdate Qt Name '+qt.Name);
                quotesToUpdate.put(qt.Id, qt);
                qtIdsAlreadyProcessed.add(qt.Id);
            }
          }
        }
        for (SBQQ__Quote__c qt : quotesToUpdate.values()) {
            qt.RecordTypeId = recordTypeID;
            qt.SBQQ__Status__c = 'Invalid';
            qt.Invalid_Reason__c = 'The related asset that was eligible for trade-up credit has expired, please create a new quote without trade up credit.';
            
            System.debug('MS Quote to be updated Id '+qt.Id);
        }

    try {
        List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();
            if(!quotesToUpdate.values().isEmpty()){

              SBQQ.TriggerControl.disable();
              TriggerControls.disableQuoteTrigger = true;
              TriggerControls.disableQuoteLineTrigger = true;
              LockQuoteValidationByPass.byPassValidation = true;
              //add Opp trigger bypass 

              Database.SaveResult[] quotesToUpdateResults = Database.update(quotesToUpdate.values(), false);

              for (Database.SaveResult qtUpdateResults : quotesToUpdateResults) {
                if (!qtUpdateResults.isSuccess()) {
                  Database.Error err = qtUpdateResults.getErrors()[0];
                  errorLogs.add(createErrorLog('invalidateQuoteBatch - Error while invalidating Quote',err.getMessage() + '\r\n' + err.getFields() + '\r\n' + 'Quote ID: ' + qtUpdateResults.getId(), qtUpdateResults.getId() ));
                }
              }
            }
            else {
                System.debug('MS found no Quotes to invalidate.');
            }
        if (!errorLogs.isEmpty()) {
          insert errorLogs;
        }
      } catch (Exception ex) {
        insert createErrorLog('invalidateQuoteBatch - Error while invalidating Quote', ex.getMessage() + '\r\n' + ex.getStackTraceString() + '\r\n' + 'Quote IDs are: ' + String.join(quotesToUpdate.values(), ',') ,null);
      }
    
    }

    global void finish(Database.BatchableContext BC) {

        System.debug('invalidateQuoteBatch Completed Processing.');
    }

  @TestVisible
  private static Error_Logs__c createErrorLog(String errorType, String message, String recordId) {
    return new Error_Logs__c(
      Error_Type__c = errorType,
      Error_Message__c = message,
      Type__c = 'SFDC',
      Object__c = 'SBQQ__Quote__c',
      RecordId__c = recordId
    );
  }
}