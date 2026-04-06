trigger LMSCourseEnrollmentTrigger on DOCEBO2_CO__c (After Insert,After Update) {
    
    if(Trigger.IsAfter){
        if(Trigger.isInsert){
            LMSCourseEnrollmentTriggerHandler.setAccreditation(Trigger.NewMap);
        }
        if(Trigger.isUpdate){
           LMSCourseEnrollmentTriggerHandler.setAccreditation(Trigger.NewMap);
        }
    }
}