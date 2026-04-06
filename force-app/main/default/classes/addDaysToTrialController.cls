public class addDaysToTrialController {

    public Integer daysToExtend{get;set;}
    public Contact con{get;set;}
    public addDaysToTrialController(Apexpages.StandardController sc){
        if(!test.isRunningTest())sc.addFields(new List<String>{'trial_Edge_End_Date__c','Agreed_to_Edge_Trial_Agreement__c'});
        con = (Contact) sc.getRecord();
            
    }
    
    public void extendDays(){
        if(!con.Agreed_to_Edge_Trial_Agreement__c){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'This contact is not a trial edge user. '));
        }else{
            con.trial_Edge_End_Date__c = con.trial_Edge_End_Date__c == null ? System.today().addDays(daysToExtend): con.trial_Edge_End_Date__c.addDays(daysToExtend);
            update con;
           	updateUser(con.Id);
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'You have extended this user validation.'));

        }
    }
    
    @future
    public static void updateUser(Id conId){
        List<User> userList = [SELECT id from user where contactId =: conId AND Profile.Id =: Label.Trial_Edge_Profile And isActive = false];
        if(!userList.isEmpty()){
            User u = userList[0];
            u.IsActive = true;
            update u;
        }
    }
}