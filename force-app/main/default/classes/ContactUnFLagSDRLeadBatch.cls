public with sharing class ContactUnFLagSDRLeadBatch implements Database.Batchable<sObject>, Schedulable{
 
    String query = 'SELECT Id,Contact_Status__c,MeetingDate__c FROM Contact WHERE'
                    +'  MeetingDate__c !=null '
                    +' AND ((MeetingDate__c < LAST_N_DAYS :60 AND SDRLed__c  = TRUE) OR MeetingDate__c < LAST_N_DAYS :30)';
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this);
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Contact> ContactList){
        for(Contact l : ContactList){
             if(l.MeetingDate__c.date()+60<Date.today()) {
                l.SDRLed__c = False;
             }
             if(l.MeetingDate__c.date()+30<Date.today()) {
                  l.Contact_Status__c='Nurture';
                  l.ContactRejectReason__c='Contacted/No Interest';
                   
              }
        }
        update ContactList;
    }
    public void finish(Database.BatchableContext bc){

    }
    
}