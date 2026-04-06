/**
* @description Trigger handler class for EmailMessage object
*
* @CreatedDate 15th July 2021
* @Created By Veera Gandi
* 
*/
public with sharing class EmailMessageHandler {
    
    /**
    * @description method to navigation business logic
    * @param  newList - trigger context variable
    * @param  oldList - trigger context variable
    * @param  newMap - trigger context variable
    * @param  oldMap - trigger context variable
    * @param  oldMap - trigger context variable to get trigger event
    * @return void
    */
    public static void handleTrigger(List<EmailMessage> newList, 
                                     List<EmailMessage> oldList, 
                                     Map<Id, EmailMessage> newMap,
                                     Map<Id, EmailMessage> oldMap,
                                     System.TriggerOperation triggerEvent) 
    {       
        switch on triggerEvent {        
            when AFTER_INSERT {
                EmailMessageService.captureADPReferenceIdFromSupportEmail(newList);
            }
        }
    }
}