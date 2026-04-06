trigger CaseCommentTrigger on CaseComment (before insert, after insert, after update, after delete) {

    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Case_Comment_Trigger__c){
        CaseCommentTriggerHandler handler1 = new CaseCommentTriggerHandler(Trigger.isExecuting, Trigger.size);

        //CS21_1086 To stop Validation rule on case record while adding first Public/Private Comment (Initial Response) 
        CaseTriggerHandler.stopValidation=false; 

        if( Trigger.isInsert && Trigger.isAfter){
            //handler1.OnAfterInsert(Trigger.new);
            handler1.caseOwnerChange(Trigger.new);
            // CS21-3005: New Field and Logic on Case Object: Last Customer Update
            handler1.updateLastCustomerUpdate(Trigger.new);
            //CS21-574
            CaseCommentUtil.rollupCaseCommentSummary(Trigger.new, trigger.oldMap);
            //CS21-574 - End
        } else if( Trigger.isInsert && Trigger.isBefore){
            handler1.OnBeforeInsert(Trigger.new);
        //CS21-574 - Private and Public case comment rollups
        } else if (Trigger.isUpdate && Trigger.isAfter) {
            CaseCommentUtil.rollupCaseCommentSummary(Trigger.new, trigger.oldMap);
        } else if (Trigger.isDelete && Trigger.isAfter) {
            CaseCommentUtil.rollupCaseCommentSummary(Trigger.old, trigger.oldMap);
        }
        //CS21-574 - End
    }
}