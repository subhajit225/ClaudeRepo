public without sharing class PC_PartnerAgreementController {
    public static string EXPIRED = 'Expired';
    public static string OUTDATED = 'Outdated';
    public static string ACTIVE ='Signed-Active';
@AuraEnabled
    public static string getEmail(){
        system.debug('@@ userInfo.getUserEmail() '+userInfo.getUserEmail());
        return userInfo.getUserEmail();
    }
 @AuraEnabled
    public static string getpartnerType(){
        string partnerType = '';
        User u = [select Id,AccountId,Account.Type,Account.Contract_Status__c,ContactId from user where Id=:userInfo.getUserId() ];
        system.debug('@@ u.Account.Contract_Status__c '+u.Account.Contract_Status__c);
        if(u.Account.Contract_Status__c == EXPIRED){
            partnerType = u.Account.Type;
        }
        return partnerType;
    }
  @AuraEnabled
    public static void save(){
		List<Account> accList = new List<Account>();
        
        User u = [select Id,AccountId,Account.Type,Account.Contract_Status__c,Account.Name,Email,ContactId from user where Id=:userInfo.getUserId() ];
        system.debug('@@ u.Account.Contract_Status__c '+u.Account.Contract_Status__c);
        if(u.Account.Contract_Status__c == EXPIRED || u.Account.Contract_Status__c == OUTDATED){
            Account acc = new Account(Id=u.AccountId,Contract_Status__c=ACTIVE,Partner_Agreement_Status__c='Signed - Active');
            accList.add(acc);
        }
        if(!accList.isEmpty()){
            update accList;
            PC_PactsafeCalloutAgremmentController.callpactsafe(u.AccountId,u.Account.Name,u.Account.Type,u.Email,u.ContactId);
            
        }
    }   
}