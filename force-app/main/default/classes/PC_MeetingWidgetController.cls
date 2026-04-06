public without sharing class PC_MeetingWidgetController {

    @AuraEnabled
    public static void createMeeting(DateTime meetStart, Datetime meetEnd, String leadId){
        try {
            system.debug('a :'+meetStart+' b :'+meetEnd);
            system.debug('format :'+meetStart.format() + '\n time :'+meetStart.time());
            User userDetails = [SELECT Id, Name, Contact.Account.Name FROM User Where Id =: UserInfo.getUserId()];
            Event ev = new Event();
            ev.Subject = 'Partner Shared Lead Meeting';
            ev.OwnerId = userDetails.Id;
            ev.StartDateTime = meetStart;
            ev.EndDateTime = meetEnd;
            ev.Meeting_Type__c = 'Net New';
            ev.Type = 'Marketing Generated Meeting';
            ev.WhoId = leadId;
            ev.Description = userDetails.Name + ' from ' + userDetails.Contact.Account.Name + ' logged meeting through Lead Sharing Program';
            insert ev;
            system.debug(ev);
            
        } catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException('Meeting not scheduled due to technical error');
        }
    }

    @AuraEnabled
    public static Event getLatestMeeting(String leadId){
        try {
            return [SELECT Id, StartDateTime, EndDateTime, Post_Meeting_Status__c, Cancellation_Reason__c, Disqualified_Reason__c FROM Event WHERE OwnerId =: Userinfo.getUserId() AND 
            Subject ='Partner Shared Lead Meeting' AND Type = 'Marketing Generated Meeting' AND WhoId =: leadId 
            ORDER BY CreatedDate DESC LIMIT 1];
            
        } catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException('Unable to fetch meeting');
        }
    }

    @AuraEnabled
    public static void rescheduleMeeting(DateTime meetStart, Datetime meetEnd, String eventId){
        try {
            Event ev = new Event();
            ev.Id = eventId;
            ev.StartDateTime = meetStart;
            ev.EndDateTime = meetEnd;
            update ev;
            system.debug('Rescheduled Meet : '+ev);

        } catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException('Unable to reschedule meeting due to technical error');
        }
    }

    @AuraEnabled
    public static void updateOutcome(String outcome, String noConvertReason, String cancelReason, String eventId){
        try {
            Event ev = new Event();
            ev.Id = eventId;
            ev.Post_Meeting_Status__c = outcome;
            ev.Disqualified_Reason__c = noConvertReason;
            ev.Cancellation_Reason__c = cancelReason;
            update ev;
        } catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException('Unable to save meeting outcome due to technical error');
        }
    }
}