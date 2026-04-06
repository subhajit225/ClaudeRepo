/**
* @description Trigger handler class for Attachment object
*
* @CreatedDate 16th Jan 2024
* @Created By Shiva Sharma
* 
*/
public with sharing class AttachmentTriggerHandler {
    
    /**
    * @description method to navigation business logic
    * @param  newList - trigger context variable
    * @param  oldList - trigger context variable
    * @param  newMap - trigger context variable
    * @param  oldMap - trigger context variable
    * @param  oldMap - trigger context variable to get trigger event
    * @return void
    */
    public static void handleTrigger(List<Attachment> newList, 
                                     List<Attachment> oldList, 
                                     Map<Id, Attachment> newMap,
                                     Map<Id, Attachment> oldMap,
                                     System.TriggerOperation triggerEvent){       
        switch on triggerEvent {        
            when AFTER_INSERT {
                AttachmentService.createCommentOnAttachmentUpload(newList);
            }
        }
    }
}