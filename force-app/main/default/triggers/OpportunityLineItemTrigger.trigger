trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, before delete, after insert, after update, after delete) {
    ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if(!disableBusinessLogicCS.Disable_Opportunity_Triggers__c){
    if(flowControll.opportunityLineItemHandler){
            System.debug('Inside Trigger Code Block OpportunityLineItemTrigger');
            //New combined Code - based on different trigger framework
                new OpportunityLineItemTriggersHandler().run();   
            }
        if(trigger.isBefore && trigger.isDelete){ 
            OpportunityLineItemTriggersHelper.OppLineItemsBeforeDelete(trigger.old); //OPPTYSPLIT
            system.debug('OppLineItemsBeforeDelete called');
        }
        // SAL24-359
        if(trigger.isAfter && trigger.isDelete){ 
            // On Renewal subscription because of loopcount exceeds 2 its not running AfterDelete, So calling it separately
            OpportunityLineItemTriggersHandler.afterDeleteMethod();
  }

    }
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){ //SAL25-145
        /* Calling trackFieldsHistory method of CustomHistoryTracker class to track the hitsory of fields defined in the Field Set */
        String disabledHistorytracking = System.label.Disable_Opp_History_tracking;
        if(disabledHistorytracking == 'No' || disabledHistorytracking == 'no'){ 
        CustomHistoryTracker.trackFieldsHistory(trigger.new, Trigger.oldMap, 'Opportunity_Product__c'); //SAL25-145
    }
    }
}