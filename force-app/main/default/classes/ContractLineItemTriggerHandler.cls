/***********************************************************************************
Date            Name                Description
11-JAN-2022     Shiju Thomas        Initial Implementation


Testclass : ContractLineItemTriggerTests, ScaleUtilityOverageTriggerTest 
************************************************************************************/
public class ContractLineItemTriggerHandler extends TriggerHandler {
  private Boolean isDisabled = false;
  public static Boolean runHistoryTrackingOnUpdate = false;

  public ContractLineItemTriggerHandler() {
    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    isDisabled = disabled.Disable_Contract_Line_Item_Triggers__c;

    ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
    Integer mxloopCount = Integer.valueOf(disabled.TriggerMaxLoopCount__c);
    this.setMaxLoopCount(mxloopCount);
  }

  public override void beforeInsert() {
    runHistoryTrackingOnUpdate = true;

    //RWD-1181 : Rahul Agarwal : Users should be able to see the third-party hardware attributes (TPH OEM, TPH Model,
    //Drive Size, TPH Qty) in the QLE for renewals for all 3rd party Hybrid Cloud - Subscription

    //Logic starts  here
    ContractLineItemTriggerHelper.updateTPHFields((List<ContractLineItem>) Trigger.new);

    //CPQ22-1159
    ContractLineItemTriggerHelper.setContractLineItemFields((List<ContractLineItem>) Trigger.new);
  }

  public override void beforeUpdate() {
    //REEN-63
    ContractLineItemTriggerHelper.handleBeforeUpdate((List<ContractLineItem>) Trigger.new, (Map<Id, Contractlineitem>) Trigger.oldMap);
  }

  public override void beforeDelete() {
  }
  /***********************************************************************************
   * @description       : In this method afterinsert logic should be added
   * Project            : Scale Utility
   * JIRA(s)            : CSU-486
   * @author            : NaveenkumarSelvaraj
   * @last modified on  : 05-12-2023
   * @last modified by  : NaveenkumarSelvaraj
   * arguments          : NA
   * return             : void
   * Modifications Log
   *
   *******************************************************************************/
  public override void afterInsert() {
    Set<String> gcIds = new Set<String>();
    for (ContractLineItem cli : (List<ContractLineItem>) Trigger.new) {
      if (cli.Global_Commit_ID__c != null) {
        gcIds.add(cli.Global_Commit_ID__c);
      }
    }
    if (!gcIds.isEmpty()) {
      ContractLineItemTriggerHelper.updateCLIFieldforGCOfferLines(gcIds, (Map<Id, Contractlineitem>) Trigger.newMap);
    }
  }

  public override void afterUpdate() {
    Order_control__mdt DisableCustomHistoryTracker = Order_control__mdt.getInstance('Disable_CLI_Custom_History_Tracker');
    if (
      !CustomHistoryTracker.recurssionHandlerSobjectSet.contains('ContractLineitem') &&
      DisableCustomHistoryTracker?.Value__c != null &&
      !boolean.valueOf(DisableCustomHistoryTracker?.Value__c) &&
      !runHistoryTrackingOnUpdate
    ) {
      CustomHistoryTracker.trackFieldsHistory(Trigger.new, Trigger.oldMap, 'Contract_Line_Item__c');
    }
  }

  public override void afterDelete() {
  }

  public override void afterUndelete() {
  }
}