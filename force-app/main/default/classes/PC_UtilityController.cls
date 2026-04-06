public class PC_UtilityController {
    
    /*******************************************************************************************************
* @description Returns User record
* @param N/A
* @return the User record for the login user
***********************************************************************************************************/
    @AuraEnabled
    public Static string getRecordType(string sObjectType, string recTypeName){
        RecordType recType = [SELECT Id 
                              FROM RecordType 
                              where RecordType.DeveloperName =:recTypeName and SobjectType =:sObjectType limit 1];
        return recType.Id;
    }
    /* test code */
      @AuraEnabled
    public Static User getUserDetails(){
        User partner = [select Id, Name, Email, Phone,AccountID,Contact.Account.Distributor__c, Contact.Account.Distributor__r.Name, 
                        Contact.Account.Name,SmallPhotoUrl,FullPhotoUrl,country,CompanyName,Contact.Account.Type,Contact.AccountId, IsActive,Contact.Primary_Role__c 
                        from User 
                        where id=:UserInfo.getUserId()];
        return partner;
    } 
}