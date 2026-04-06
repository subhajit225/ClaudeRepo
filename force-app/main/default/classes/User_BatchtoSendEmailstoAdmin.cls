/* Created By Shadab Hussain
   Purpose : To Send Email to Sales Ops for all for user which haven't logged in since 90 days
*/
global class User_BatchtoSendEmailstoAdmin implements Database.Batchable<sobject>, Database.stateful{
    
    Date tdate = System.today() - 90;  
    Map<Id,Profile> profileIds = new Map<id,profile>([SELECT Id,UserLicenseId FROM Profile where UserLicenseId  in (SELECT Id FROM UserLicense where name ='Salesforce')]);
    List<User> userIds = [SELECT Id FROM User WHERE profileId in:profileIds.Keyset() AND IsActive=True AND LastLoginDate <= :tdate];
    public List<User> processedUsers = new List<USer>();
    public String query = 'SELECT Id,Name,Email, Sales_Manager__c, Department FROM User WHERE Id IN :userIds';
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, LIST<sobject> InactiveUsers) {
        
        for(Sobject user:InactiveUsers){
            User user2 = (User)user;
            processedUsers.add(user2);
        }        
    }
    
    global void finish(Database.BatchableContext FreezeWarningtoUsers) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {System.Label.UserEmailRecipeint});
            email.setSaveAsActivity(false);
            system.debug('processd USers'+processedUsers);
            String subject = 'User inactive since 90 days';
            String allUSers='';
            for(User user : processedUsers){
                if(User.Sales_Manager__C==null){
                User.Sales_Manager__C = '';
                }
                if(User.Department==null){
                User.Department = '';
                }
               allUSers += '<tr><td style="text-align:center; vertical-align:middle;">'+user.Name+'</td><td style="text-align:center; vertical-align:middle;">'+User.Email+'</td><td style="text-align:center; vertical-align:middle;">'+User.Sales_Manager__C+'</td><td style="text-align:center; vertical-align:middle;">'+User.Department+'</td><td style="text-align:center; vertical-align:middle;"><a href='+system.URL.getSalesforceBaseUrl().toExternalForm()+'/'+user.Id+' target="_Blank">Link</a></td></tr>';
            }
            String tableBody ='<table border="1"><tbody><th>Name</th><th>Email</th><th>Sales Manager</th><th>Department</th><th>Detail Link</th>'+allUSers+'</tbody></table>';
            email.setHTMLBody(System.Label.User_Inactive_Batch_Message +'<br/><br/>'+ tableBody+'<br/><br/><br/> Thanks');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
    }
    
}