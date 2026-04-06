trigger POItemStageTrigger on PO_Item_Stage__c(after insert, after update, before insert, before update,before delete){
    new POItemStageHandler().run();
}