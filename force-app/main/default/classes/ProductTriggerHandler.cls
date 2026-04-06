public class ProductTriggerHandler implements ITrigger{
    public void bulkBefore(){
        if (Trigger.isUpdate){
            ProductTriggerHelper.beforeProductUpdate((Map<ID, Product2>)Trigger.oldMap, (Map<ID, Product2>)Trigger.newMap);
            ProductTriggerHelper.handleBundleFeatureUpdate((List<Product2>)Trigger.new, (Map<ID, Product2>)Trigger.oldMap); // added for CS21-865
            ProductTriggerHelper.populatePricebookDetailsOnProduct((List<Product2>)Trigger.new); //added for SF-29398
            ProductTriggerHelper.onUpdateProductHistory(Trigger.new, (Map<Id, Product2>) Trigger.oldMap); //Added as part of GLCR-80
            ProductTriggerHelper.populateQuotingRestriction((List<Product2>)Trigger.new); //added for CPQ22-4821
        }
        if (Trigger.isInsert){
            ProductTriggerHelper.beforeProductInsert((List<Product2>)Trigger.new);
        }
    }
    
    public void bulkAfter(){}
    public void beforeInsert(SObject so){}
    public void beforeUpdate(SObject oldSo, SObject so){}
    public void beforeDelete(SObject so){}
    public void afterInsert(SObject so){}
    public void afterUpdate(SObject oldSo, SObject so){}
    public void afterDelete(SObject so){}
    public void andFinally(){}

}