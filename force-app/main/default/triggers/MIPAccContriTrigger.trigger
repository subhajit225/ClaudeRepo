trigger MIPAccContriTrigger on MIP_Account_Contribution__c (after insert, after delete) {
    if(flowControll.MIPAccContriTrigger){
    	TriggerManager.invokeHandler(new MIPAccContriTriggerHandler());
    }
    
}