/*
 * Class Name :- CustomerRegistrationRequestTrigger
 * Object :- Customer_Registration_Request__c
 * Handler Class :- CustomerRegistrationRequestTriggerHelper
 * Events :- Insert and Update
 * Author :- Shiva Sharma
 * Created Date :- 25-04-2018
 * Description : This Trigger will submit record for approval on Record Insert and will create user once record is approved
 * 
 // ********************Change Logs *****************************************************************************
 * 
 * Modified By          Date        Description 
 * 


 // ********************Change Logs Ends*************************************************************************
*/
trigger CustomerRegistrationRequestTrigger on Customer_Registration_Request__c (after insert,after update) {

    if(TriggerControl__c.getAll() != null && TriggerControl__c.getAll().containsKey('Customer Registration Request') && !TriggerControl__c.getInstance('Customer Registration Request').DisableTrigger__c){
        if(trigger.isInsert){
            CustomerRegistrationRequestTriggerHelper.afterInsert(trigger.new);
        }
        if(trigger.isUpdate){
            CustomerRegistrationRequestTriggerHelper.afterUpdate(trigger.new,trigger.oldMap);
        }
    }
}