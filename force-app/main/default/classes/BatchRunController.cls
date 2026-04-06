public class BatchRunController {
    public string message{get;set;}
    public  string nextRunDetails{get;set;}
    public  string lastrunDetails{get;set;}
    public boolean batchProcessed{get;set;}
    public string messageSync{get;set;}
    public  string nextRunDetailsSync{get;set;}
    public  string lastrunDetailsSync{get;set;}
    public boolean batchProcessedSync{get;set;}

    public BatchRunController(){ 
        lastrunDetails = nextRunDetails = 'No run' ;
        message = 'Not Started';
        batchProcessed = false;   
        lastrunDetailsSync = nextRunDetailsSync = 'No run' ;
        messageSync = 'Not Started';
        batchProcessedSync = false;  
    }
    
    public void messages(){
            if(batchProcessed){
            for(AsyncApexJob a : [select Status,CreatedDate From AsyncApexJob where ApexClass.Name = 'BookingBatch' order by CreatedDate desc limit 1]){
                message= a.Status;
            } }             
            for(AsyncApexJob a : [select CompletedDate From AsyncApexJob where ApexClass.Name = 'BookingLineItemBatch' order by CompletedDate DESC NULLS LAST limit 1]){
                    lastrunDetails = a.CompletedDate!=null?a.CompletedDate.format('EEE, MMM d yyyy hh:mm:ss a'): 'No run';         
            }                             
            for(CronTrigger a : [ SELECT NextFireTime FROM CronTrigger where CronJobDetail.name LIKE 'ScheduleBookingBatch-Quarter%'  ORDER BY NextFireTime ASC limit 1])
            {
                nextRunDetails = a.NextFireTime!=null ? a.NextFireTime.format('EEE, MMM d yyyy hh:mm:ss a'):'No run' ;     
            } 
                 message= message != null ? message : 'Not Started'; 
                 lastrunDetails = lastrunDetails != null ? lastrunDetails : 'No run' ; 
                 nextRunDetails = nextRunDetails != null ? nextRunDetails : 'No run' ;         
    }                
    public PageReference process(){
        BookingBatch batch = new BookingBatch();
        batchProcessed = true;
        Database.executeBatch(batch);
        return null;
    }
    public void messagesSync(){
            if(batchProcessedSync){
            for(AsyncApexJob a : [select Status,CreatedDate From AsyncApexJob where ApexClass.Name = 'BookingSyncBatch' order by CreatedDate desc limit 1]){
                messageSync= a.Status;
            } }             
            for(AsyncApexJob a : [select CompletedDate From AsyncApexJob where ApexClass.Name = 'BookingSyncBatch' order by CompletedDate DESC NULLS LAST limit 1]){
                    lastrunDetailsSync = a.CompletedDate!=null?a.CompletedDate.format('EEE, MMM d yyyy hh:mm:ss a'): 'No run';         
            }                             
            for(CronTrigger a : [ SELECT NextFireTime FROM CronTrigger where CronJobDetail.name LIKE 'ScheduleBookingSyncBatch-Quarter%'  ORDER BY NextFireTime ASC limit 1])
            {
                nextRunDetailsSync = a.NextFireTime!=null ? a.NextFireTime.format('EEE, MMM d yyyy hh:mm:ss a'):'No run' ;     
            } 
                 messageSync= messageSync != null ? messageSync : 'Not Started'; 
                 lastrunDetailsSync = lastrunDetailsSync != null ? lastrunDetailsSync : 'No run' ; 
                 nextRunDetailsSync = nextRunDetailsSync != null ? nextRunDetailsSync : 'No run' ;         
    }                
    public PageReference processSync(){
        BookingSyncBatch batchSync = new BookingSyncBatch(Date.Today());
        batchProcessedSync = true;
        Database.executeBatch(batchSync);
        return null;
    }

}