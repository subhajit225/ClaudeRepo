public with sharing class POItemStageHandler  extends TriggerHandler {       
    private Boolean isDisabled = false;
    //....
    public POItemStageHandler() {
        this.setMaxLoopCount(2);
    }
    public override void beforeInsert() {
        if(!isDisabled) { 
        POItemStageHelperClass.populateFieldsOnInsert(Trigger.new,(Map<Id, PO_Item_Stage__c>)trigger.oldMap);
        }
    }
    
     public override void beforeUpdate() {
        if(!isDisabled) {
        //    POStageHelper.populateAccountDetails(Trigger.new,(Map<Id, PO_Stage__c>)trigger.oldMap);

           POItemStageHelperClass.populateFieldsOnInsert(Trigger.new,(Map<Id, PO_Item_Stage__c>)trigger.oldMap);       
        }
    }
    
    public override void afterInsert() {} 
    //PRDOPS25-734
    public override void beforeDelete(){
        if(!isDisabled) {
            system.debug('before delte logic starts');
          Map<Id, PO_Item_Stage__c>  oldStagePOItemMap = (Map<Id, PO_Item_Stage__c>)Trigger.oldMap; 
            system.debug('po item is ' + oldStagePOItemMap);
            POItemStageHelperClass.customValidationOnDeletePoItem(oldStagePOItemMap);
        }
        
    }
}