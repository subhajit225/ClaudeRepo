public class Assign_CRR_Controller {

    public Id recordId;
    public Customer_Registration_Request__c crr{get;set;}
    public Assign_CRR_Controller(ApexPages.StandardController sd){
        recordId = sd.getId();
        if(!test.isRunningTest())   sd.addFields(new List<String>{'ownerId','Status__c'});
        crr = (Customer_Registration_Request__c) sd.getRecord();
    }
    
    public PageReference updateApprover(){
        crr.OwnerId = userInfo.getUserId();
        update crr;
        if(crr.Status__c != 'Approved' || crr.Status__c != 'Rejected'){
            List<ProcessInstanceWorkItem> workItemList = [Select ProcessInstance.Status,ProcessInstance.TargetObjectId,ProcessInstanceId,OriginalActorId,Id,ActorId
                                                          From ProcessInstanceWorkitem  where ProcessInstance.TargetObjectId = :  recordId];
            
            if(!workItemList.isEmpty()){
                workItemList.get(0).OriginalActorId  = userInfo.getUserId();
                workItemList.get(0).ActorId  = userInfo.getUserId();
                update workItemList;
            }
            
            PageReference pref = new PageReference('/'+recordId);
            return pref;
        }
        return null;
    }
}