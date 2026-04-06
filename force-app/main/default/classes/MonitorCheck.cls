/*******************************
Author : Chaitra
*****************************/

global class MonitorCheck implements Schedulable {

 global integer DELAY_MIN = 5;
   global void execute(SchedulableContext SC) {
     boolean sendemail =false;
     Map<string,Custom_Error_Log__c>User_error = new Map<string,Custom_Error_Log__c>();
for(Custom_Error_Log__c cerr : [select id,Name,Response_Time__c from Custom_Error_Log__c where Functionality__c='GTCBypassCheck']){
    User_error.put(cerr.Name,cerr);
}
set<Custom_Error_Log__c> UpsertErrLog = new set<Custom_Error_Log__c>();
for(RPS__c rps :[select id,LastModifiedDate, LastModifiedBy.name,Is_RPS_Required__c from RPS__c where Is_RPS_Required__c=false]){
        system.debug('rps'+rps.LastModifiedBy.name);
        if(User_error.containsKey(rps.LastModifiedBy.name)){
            if(User_error.get(rps.LastModifiedBy.name).Response_Time__c != rps.LastModifiedDate.format('yyyy-MM-dd HH:mm:ss','IST')){
            User_error.get(rps.LastModifiedBy.name).Response_Time__c = rps.LastModifiedDate.format('yyyy-MM-dd HH:mm:ss','IST');
            UpsertErrLog.add(User_error.get(rps.LastModifiedBy.name));
            }
        }
        else{
            sendemail = true;
            UpsertErrLog.add(new Custom_Error_Log__c(Name=string.valueof(rps.LastModifiedBy.name),Response_Time__c=rps.LastModifiedDate.format('yyyy-MM-dd HH:mm:ss','IST'),Functionality__c='GTCBypassCheck'));
        }
       

    
}
system.debug('UpsertErrLog'+UpsertErrLog);
List<Custom_Error_Log__c> UpsertErrLog1 = new list<Custom_Error_Log__c>();
UpsertErrLog1.addall(UpsertErrLog);
system.debug('UpsertErrLog1'+UpsertErrLog1);
if(!UpsertErrLog1.isEmpty()){
upsert UpsertErrLog1 ;   
if(sendemail || Test.isRunningTest()){
 Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
message.toAddresses = new String[] { 'chaitra.padashetty@rubrik.com' };

message.subject = 'GTC Bypass enabled';
message.plainTextBody = 'IST timeZone'+JSON.serialize(UpsertErrLog) ;
Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

} 
}


if(System.Label.Stop_TestMonitor != 'true'){
 DateTime scheduleTime = Datetime.now().addminutes(DELAY_MIN);
                String hour = String.valueOf(scheduleTime.hour()); 
                String minute = String.valueOf(scheduleTime.minute());
                String second = String.valueOf(scheduleTime.second());  
                String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(scheduleTime.day()) + ' ' + String.valueOf(scheduleTime.month()) + ' ?' + ' ' + String.valueOf(scheduleTime.year());
                 if(!Test.isRunningTest()){
                 System.schedule('MonitorChek_' + String.valueOf(Datetime.now()), nextFireTime, new MonitorCheck());
                 }
}
   }
}