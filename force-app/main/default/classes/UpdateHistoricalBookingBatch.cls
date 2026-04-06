global class UpdateHistoricalBookingBatch implements Database.batchable<sObject>, Database.Stateful{
    
    global Database.QueryLocator start(Database.BatchableContext bc){
       string query = ' select id,Opportunity__r.closeDate from Booking__c where Opportunity__r.closeDate <= 2020-01-31' ;
        system.debug('query'+query);
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext bc, List<Booking__c> scope)
    {
         List<Booking__c> Updatebkg = new List<Booking__c>();
         for (Booking__c Bkg : scope){
             Updatebkg.add(new Booking__c(Field_Update_Status__c ='Freeze Completed',id=Bkg.id));
         }
         if(!Updatebkg.isEmpty())
             update Updatebkg ;
                  
    }
    
    global void finish(Database.BatchableContext BC)
    {          
                 
       
    }
}