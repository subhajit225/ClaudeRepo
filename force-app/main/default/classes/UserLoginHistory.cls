global with sharing class UserLoginHistory implements Schedulable{
    global void execute(SchedulableContext sc) {
        List<LoginHistory> logins = [select UserId, LoginTime, CountryIso from LoginHistory where LoginUrl in('rubrikinc.my.salesforce.com') and LoginTime > :System.now().addMinutes(-65) LIMIT 50000];

        Set<Id> userIds = new Set<Id>();

        for(LoginHistory hist: logins){
            userIds.add(hist.UserId);
        }

        Map<Id, User> userMap = new Map<Id, User>([Select Id, Name from User where Id in :userIds]);

        String htmlBody = '<html><body><table><tr><td>User Name</td><td>UserId</td><td>LoginTime (GMT)</td><td>CountryIso</td>';
        for(LoginHistory hist: logins){
            User u = userMap.get(hist.UserId);
            htmlBody += '<tr><td>'+u.Name+'</td><td>'+hist.UserId+'</td><td>'+hist.LoginTime+'</td><td>'+hist.CountryIso+'</td></tr>';
        }

        htmlBody += '</table></body></html>';

        List<String> toAddresses = new List<String>();
        toAddresses.add('gaurav.j@rubrik.com');
        toAddresses.add('sudheer.dhurjati@rubrik.com');
        toAddresses.add('ajay.sabhlok@rubrik.com');
        toAddresses.add('satish.mali@rubrik.com');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject('User Login History for Last Hour');
        mail.setSaveAsActivity(false);
        mail.setHTMLBody(htmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

   }
}