/**
 * @description Trigger handler class to navigate to service classes for zsfjira__ZIssue_Case__c Object 
 * business logic
 *
 * @CreatedDate 29th April 2021
 * @Created By Veera Gandi
 * 
 */
public Inherited sharing class ZSFJIRAZIssueCaseTriggerHandler {
    
    /**
    * @description method to direct and call service class meathods based on the trigger context
    * @param  newList  Trigger context variable - Trigger.new for zsfjira__ZIssue_Case__c
    * @param  oldList  Trigger context variable - Trigger.old for zsfjira__ZIssue_Case__c
    * @param  triggerEvent  Trigger context variable - enum values for Trigger events
    * @return void
    */
    public static void run(List<zsfjira__ZIssue_Case__c> newList, List<zsfjira__ZIssue_Case__c> oldList, Map<Id,zsfjira__ZIssue_Case__c> oldMap, System.TriggerOperation triggerEvent ) {
        //custom setting to on/off zsfjira__ZIssue_Case__c trigger
        if(TriggerControl__c.getAll().containsKey('ZissueCaseJiraReferenceHyper') 
           && !TriggerControl__c.getInstance('ZissueCaseJiraReferenceHyper').DisableTrigger__c) {
               
               switch on triggerEvent {                  
                   when AFTER_INSERT {
                       ZSFJIRAZIssueCaseTriggerService.recalculateCaseJIRAReference(newList,null);
                   }
                       when AFTER_UPDATE {
                       ZSFJIRAZIssueCaseTriggerService.recalculateCaseJIRAReference(newList,oldMap);
                   }
                   when AFTER_DELETE {
                       ZSFJIRAZIssueCaseTriggerService.recalculateCaseJIRAReference(oldList,oldMap);
                   }
               }
           }
    }
    
}