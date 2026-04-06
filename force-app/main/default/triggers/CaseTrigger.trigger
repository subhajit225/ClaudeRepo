trigger CaseTrigger on Case (before insert, after insert, before update, after update, after delete) {
    
    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Case_Triggers__c && TriggerControl__c.getAll() != null && TriggerControl__c.getAll().containsKey('Case') && !TriggerControl__c.getInstance('Case').DisableTrigger__c){
        if(CaseTriggerHandler.isRepeat){
            CaseTriggerHandler caseHandler = new CaseTriggerHandler();
            if(Trigger.isInsert && Trigger.isAfter){
                caseHandler.afterInsert();
                RollupSummaryUtility.rollupCasesOnAccount(trigger.new,trigger.oldMap);  //CS-428
            }
            
            if(trigger.isDelete && trigger.isAfter){
                RollupSummaryUtility.rollupCasesOnAccount(trigger.old,null);    //CS-428
            }
            
            if(Trigger.isUpdate && Trigger.isBefore){
                caseHandler.beforeUpdate();
                caseHandler.changeDeactiveCaseOwnerToQueue(trigger.new,trigger.oldMap);
                // <Reason>
                //<Modifications - 23 oct, 2019>
                //To update cem/tsm field on case level if its value does not match with cem/tsm field value on account level when a case is manually updated
                CaseTriggerHandler.AccountCemTsmToCase(trigger.new,trigger.oldMap);
                //</Reason>
                //</Modifications>
              //  CaseTriggerHandler.setInitialPriority(trigger.new);     //CS21-525
            }
            
            if(Trigger.isInsert && Trigger.isBefore){
                caseHandler.beforeInsert();
                // <Reason>
                //<Modifications - 23 oct, 2019>
                // To Update CEM/TSM Field on case Level in newly created cases if there is value in CEM/TSM field on account level
                CaseTriggerHandler.AccountCemTsmToCase(trigger.new,NULL);
                //</Reason>
                //</Modifications>
               // CaseTriggerHandler.setInitialPriority(trigger.new);     //CS21-525
            }
            
            if(Trigger.isUpdate && Trigger.isAfter && !System.isFuture() && !System.isBatch()){
                caseHandler.afterUpdate();
                RollupSummaryUtility.rollupCasesOnAccount(trigger.new,trigger.oldMap);  //CS-428
            }
            
            if(Trigger.isAfter)
                CaseTriggerHandler.isRepeat = false;
        }
        //CS21-1252 - Case Status Tracker issue fix
        if(Trigger.isUpdate && Trigger.isAfter){
            CaseTriggerHandler.UpdateStatusTracking(trigger.newMap,trigger.oldMap);
        }
        if((Trigger.isUpdate || Trigger.isInsert) && Trigger.isBefore){
            CaseTriggerHandler.setInitialPriority(trigger.new);
            // CS21-3033: US ASE / FED queue and routing changes FY25
            CaseTriggerHandler.processUsFedAndAseQueueAssignment(Trigger.isInsert);
        }
    }
}