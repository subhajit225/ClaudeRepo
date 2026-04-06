trigger ConsolidatedContractLinesTrigger on Consolidated_Contract_Lines__c (before insert,before update, after insert, after update) {
    if(!TriggerControls.disableCCLITrigger){
        new ConsolidatedContractLinesTriggerHandler().run();    
    }
}