public with sharing class QuoteAndOrderStagingTriggerHandler extends TriggerHandler {
  private Boolean isDisabled = false;
  public QuoteAndOrderStagingTriggerHandler() {
    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    isDisabled = disabled.Disable_QuoteAndStaging_Trigger__c;
  }

  public override void beforeInsert() {
    if (!isDisabled) {
      Map<Id, Quote_and_Order_Staging__c> AccountIdToQuoteAndStageObj = new Map<Id, Quote_and_Order_Staging__c>();
      List<Quote_and_Order_Staging__c> quoteAndStagingList = (List<Quote_and_Order_Staging__c>) Trigger.new;
      for (Quote_and_Order_Staging__c quoteAndStagingObj : quoteAndStagingList) {
        if (
          quoteAndStagingObj.Account_OM__c != null &&
          quoteAndStagingObj.EOL_EndDate__c != null &&
          quoteAndStagingObj.Processing_Date__c != null &&
          quoteAndStagingObj.Process_Type__c == constants.RCDMT_EXT_INITIAL_PROCESS_TYPE &&
          !AccountIdToQuoteAndStageObj.containskey(quoteAndStagingObj.Account_OM__c)
        ) {
          AccountIdToQuoteAndStageObj.put(quoteAndStagingObj.Account_OM__c, quoteAndStagingObj);
        }
      }

      system.debug('AccountIdToDateMap is ' + AccountIdToQuoteAndStageObj);
      if (!AccountIdToQuoteAndStageObj.isempty())
        QuoteAndOrderStagingTriggerHelper.QuoteAndOrderStagingMethod(AccountIdToQuoteAndStageObj);
    }
  }

  public override void afterInsert() {
    QuoteAndOrderStagingTriggerHelper.loadAllQuoteAndStagingOrderAfterInsert();
  }
}