/********************************************************************
 * $Id$: Docebo_CourseEnrollmentTrigger 
 * $Created Date$: 24-Sept-2019
 * $Author$: Santosh
 * $Description$ : Trigger on object docebo_v3__CourseEnrollment
 ********************************************************************/

trigger Docebo_CourseEnrollmentTrigger on docebo_v3__CourseEnrollment__c (before insert, after insert, after update) {
    
   try {
        
        //To skip execution
        if(TriggerControl__c.getInstance('docebo_v3__CourseEnrollment') != null && TriggerControl__c.getInstance('docebo_v3__CourseEnrollment').DisableTrigger__c) {
            return;
        }
        
        if(Trigger.isbefore) {
            
            if(Trigger.isInsert) {
                Docebo_CourseEnrollmentTriggerService.populateContactOnCE(Trigger.New);
            }
    
        } else if(Trigger.isAfter) {
        
            if(Trigger.isInsert) {
                Docebo_CourseEnrollmentTriggerService.setAccreditationOnContact(Trigger.newMap);
            } else if (Trigger.isUpdate) {
                Docebo_CourseEnrollmentTriggerService.setAccreditationOnContact(Trigger.newMap);
            }
        }
    } catch(Exception ex){ Error_Logs__c el = new Error_Logs__c( Error_Type__c = 'docebo_v3__CourseEnrollment',Error_Message__c = ex.getMessage() + '\r\n' + ex.getStackTraceString(),Type__c = 'SFDC');
        Database.insert(el);
    }  
}