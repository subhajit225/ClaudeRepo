public class ConsolidatedContractLinesTriggerHandler extends TriggerHandler{
    public override void afterInsert() {
        
        
        ConsolidatedContractLinesTriggerHelper.populatePriorNetTotalFields(Trigger.New);
    
    
    }
}