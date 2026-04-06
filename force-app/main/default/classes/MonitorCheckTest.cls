@isTest
public class MonitorCheckTest {
static testmethod void MonitorCheckTest1() {
  insert new RPS__c(SetupOwnerId=UserInfo.getOrganizationId(), Is_RPS_Required__c =false , Valid_HoldCodes__c ='Global Trade Compliance screening failed;Credit Check Failed');
  SchedulableContext sc = null;
MonitorCheck tsc = new MonitorCheck();
tsc.execute(sc);
   DateTime scheduleTime = Datetime.now().addminutes(1);
                String hour = String.valueOf(scheduleTime.hour()); 
                String minute = String.valueOf(scheduleTime.minute());
                String second = String.valueOf(scheduleTime.second());  
                String nextFireTime = '0 ' + minute + ' ' + hour + ' ' + String.valueOf(scheduleTime.day()) + ' ' + String.valueOf(scheduleTime.month()) + ' ?' + ' ' + String.valueOf(scheduleTime.year());
             //    System.schedule('MonitorChek_' + String.valueOf(Datetime.now()), nextFireTime, new MonitorCheck());

 
}

}