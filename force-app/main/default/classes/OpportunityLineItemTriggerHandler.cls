public without sharing class OpportunityLineItemTriggerHandler implements ITrigger {
    Set<Id> opportunitySet = new Set<Id>();
    Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
    
    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore(){
        for(SObject so : Trigger.isDelete == true?Trigger.old:Trigger.new){
            OpportunityLineItem olibject = (OpportunityLineItem)so;
            opportunitySet.add(olibject.OpportunityId);
        }
        if(opportunityMap.isEmpty()){
            opportunityMap.putAll([select id,stageName, split__c from opportunity where id IN: opportunitySet]);
        }
            system.debug('opportunityMap'+opportunityMap);

      //oppLineItemList=[select id, opportunityId,opportunity.stageName from OpportunityLineItem where id in: Trigger.new];
    }

    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkAfter(){}

    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public void beforeInsert(SObject so){
        OpportunityLineItem oliObject = (OpportunityLineItem)so;
        /*
         Set Record Type to Partner if Lead_Type__c is partner
        */
         system.debug('oliObject '+oliObject);
        system.debug('\n\n\n'+opportunityMap.get(oliObject.OpportunityId));
        if((opportunityMap.get(oliObject.OpportunityId).stageName=='6 PO With Channel' || opportunityMap.get(oliObject.OpportunityId).stageName=='7 Closed Won') && oliObject.isSplit__c==false){
            system.debug('in 6 stage');
            oliObject.addError('You cannot update quote in stage 6 or above');
        }
        
        
    }

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(SObject oldSo, SObject so){
        OpportunityLineItem oliObject = (OpportunityLineItem)so;
        }

    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so){
        OpportunityLineItem oliObject = (OpportunityLineItem)so;
        /*
         Set Record Type to Partner if Lead_Type__c is partner
        */
        system.debug('oliObject '+oliObject);
        system.debug('in 6 stage 11'+opportunityMap.get(oliObject.OpportunityId).stageName);
        if((opportunityMap.get(oliObject.OpportunityId).stageName=='6 PO With Channel' || opportunityMap.get(oliObject.OpportunityId).stageName=='7 Closed Won') && oliObject.isSplit__c==false){
            system.debug('in 6 stage');
            oliObject.addError('You cannot update quote in stage 6 or above');
        }
       // oliObject.addError('You cannot delete OPTY-SPLIT OpportunityLineItem');
      /*  if(oliObject.ProductCode=='OPTY-SPLIT' && oliObject.TotalPrice < 0.00){
            system.debug('You cannot delete split OpportunityLineItem');
            oliObject.addError('You cannot delete OPTY-SPLIT OpportunityLineItem');
            OpportunityLineItem oliInsert = oliObject.clone(false, false, false, false);
            insert oliInsert;
        }*/
    }

    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    public void afterInsert(SObject so){}

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(SObject oldSo, SObject so){}

    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    public void afterDelete(SObject so){
        OpportunityLineItem oliObject = (OpportunityLineItem)so;
        if(oliObject.ProductCode=='OPTY-SPLIT' && oliObject.TotalPrice < 0.00){            
            OpportunityLineItem oliInsert = oliObject.clone(false, false, false, false);
            system.debug('***oliInsert'+oliInsert);
            
            OpportunityLineItem optySplitProductLineItem = new OpportunityLineItem();
	        optySplitProductLineItem.PricebookEntryId  = oliObject.PricebookEntryId;
	        optySplitProductLineItem.OpportunityId = oliObject.OpportunityId;
	        optySplitProductLineItem.Quantity = 1;
	        optySplitProductLineItem.TotalPrice = oliObject.TotalPrice;
	        optySplitProductLineItem.isSplit__c=true;
            insert optySplitProductLineItem;
        }
    }

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally(){}
    
}