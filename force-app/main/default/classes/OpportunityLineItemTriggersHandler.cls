public without sharing class OpportunityLineItemTriggersHandler extends TriggerHandler  {   
    public static Boolean isDisabled = false;
    public static Set<ID> opportunityIdSet = new Set<ID>();
    public static Set<ID> OpprequiredSet = new Set<ID>();
    public static Boolean skipValidationDuringRenewalSplit = false;

public OpportunityLineItemTriggersHandler() {
    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    isDisabled = disabled.Disable_Opportunity_Triggers__c;

    ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
    Integer mxloopCount = Integer.valueOf(disabled.TriggerMaxLoopCount__c);
    this.setMaxLoopCount(mxloopCount);
}

public override void beforeInsert() {
    if(!isDisabled) {
        system.debug('Inside OpportunityLineItemTriggersHandler - beforeInsert');
        Map<Id,Opportunity> opptyMap = OpportunityLineItemTriggersHelper.getOpportunityMap((List<OpportunityLineItem>)Trigger.new);
         for(OpportunityLineItem oli : (List<OpportunityLineItem>)Trigger.new){ //SAL24-737
           if(oli.Subsumed_Renewal_Amount__c == null)
              oli.Subsumed_Renewal_Amount__c = oli.SubsRenAmt__c;
             
             //OPTYSPLIT-2
             if(oli.PricebookEntry.Product2Id != system.label.OPTY_SPLIT_Product2Id && oli.Productcode != 'OPTY-SPLIT' && oli.Line_Type__c != 'Renewal' && opptyMap.containskey(oli.OpportunityId)){ //OPPTYSPLIT-3
                 oli.Applied_Split__c = opptyMap.get(oli.OpportunityId).split_percentage__c;
             }
        }
        OpportunityLineItemTriggersHelper.validateOpportunityOnDelete((List<OpportunityLineItem>)Trigger.new, opptyMap);
        OpportunityLineItemTriggersHelper.updateProductType((List<OpportunityLineItem>)Trigger.new,null);
    }
}

public override void beforeUpdate() {    
    if(!isDisabled) {
        system.debug('Inside OpportunityLineItemTriggersHandler - beforeUpdate');   
        OpportunityLineItemTriggersHelper.updateProductType((List<OpportunityLineItem>)Trigger.new,(Map<Id,OpportunityLineItem>)Trigger.oldMap);
    }
}

public override void beforeDelete() {
    if(!isDisabled) {
        system.debug('Inside OpportunityLineItemTriggersHandler - beforeDelete');
        Map<Id,Opportunity> opptyMap = OpportunityLineItemTriggersHelper.getOpportunityMap((List<OpportunityLineItem>)Trigger.old);
        OpportunityLineItemTriggersHelper.validateOpportunityOnDelete((List<OpportunityLineItem>)Trigger.old, opptyMap);
    }
}

public override void afterInsert() {
    if(!isDisabled) {
        system.debug('Inside OpportunityLineItemTriggersHandler - afterInsert');
        for(OpportunityLineItem oli: (List<OpportunityLineItem>)Trigger.new){
            if(oli.ProductCode == 'OPTY-SPLIT') opportunityIdSet.add(oli.OpportunityId);
                if (oli.Required_by_opportunity_product__c == null || oli.Required_by_opportunity_product__c == '') {
                    OpprequiredSet.add(oli.OpportunityId);
                }
        }
        OpportunityLineItemTriggersHelper.afterOLITriggerMethods((List<OpportunityLineItem>)Trigger.new,null,null);
    }
}

public override void afterUpdate() {
    if(!isDisabled) {
        system.debug('Inside OpportunityLineItemTriggersHandler - afterUpdate');
        for(OpportunityLineItem oli: (List<OpportunityLineItem>)Trigger.new){
                if (oli.Required_by_opportunity_product__c == null || oli.Required_by_opportunity_product__c == '') {
                    OpprequiredSet.add(oli.OpportunityId);
                }
        }
        OpportunityLineItemTriggersHelper.afterOLITriggerMethods((List<OpportunityLineItem>)Trigger.new, (Map<Id,OpportunityLineItem>) Trigger.OldMap,null); //ARY-283
           
    }
}
public static void afterDeleteMethod() { //use this method for AFTER DELETE
    if(!isDisabled) {
         OpportunityLineItemTriggersHelper.afterOLITriggerMethods((List<OpportunityLineItem>)Trigger.old,null,null); //ARY-283
         OpportunityLineItemTriggersHelper.OppLineItemsAfterDelete((List<OpportunityLineItem>)trigger.old); ////OPPTYSPLIT
         system.debug('OppLineItemsAfterDelete called');
    } 
}
public override void afterDelete() {
    if(!isDisabled) {
        system.debug('Inside OpportunityLineItemTriggersHandler - afterDelete');
        OpportunityLineItemTriggersHelper.afterOLITriggerMethods((List<OpportunityLineItem>)Trigger.old,null,null); //ARY-283
    }
}

public override void afterUndelete() {}

}