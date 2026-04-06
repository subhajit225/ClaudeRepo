public class CS_KCS_Controller {
    
     @AuraEnabled(cacheable=true)
    public static Id getKCSId(String processId) {
        // Query for Account records
        return [SELECT id,ProcessInstance.TargetObjectId from ProcessInstanceWorkitem WHERE id =: processId]?.ProcessInstance.TargetObjectId;
    }
    
    
    

}