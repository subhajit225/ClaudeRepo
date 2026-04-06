/** 
* @Author      :  
* @Optimized   : Vijay Kumar K R
* @Description : 
* @Trigger     : TasksTrigger
* @TestClass   : UpdatingSupportManagerTest
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1923        Vijay Kumar K R        Oct 10 2023      Escalation Task assignment - Not in CSE queue or OPEN
* -------------------------------------------------------------------------
*/ 
public class UpdatingSupportManager extends TriggerHandler{
    public override void beforeInsert() {
        updateSupportManager();
    }

    public override void beforeUpdate() {
        updateSupportManager();
    }

    public void  updateSupportManager(){
        Set<Id> suppUserIdSet = new Set<Id>();
        
        // Map<Id, Id> suppUserIdSet = new Map<Id, Id>();
        for(Tasks__c task : (List<Tasks__c>) Trigger.new) {
            if(isChanged('Owner_ID__c', task)
                && task.Owner_ID__c != null  
                && String.valueof(task.Owner_ID__c).startsWith('005')) {
                    suppUserIdSet.add(task.Owner_ID__c);
               }           
        }

        if(!suppUserIdSet.isEmpty()){
            Map<Id, User> userMap = new Map<Id, User>();
            for(User objUser : [SELECT Id, ManagerId FROM User WHERE Id IN: suppUserIdSet]){
                userMap.put(objUser.Id, objUser);
            }

            for(Tasks__c objTask : (List<Tasks__c>) Trigger.new) {
                if(userMap.containsKey(objTask.Owner_ID__c)){
                    objTask.Support_Manager__c = userMap.get(objTask.Owner_ID__c).ManagerId;    
                }                
            }
        }
    }
}