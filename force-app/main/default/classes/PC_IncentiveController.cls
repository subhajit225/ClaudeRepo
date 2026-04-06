public class PC_IncentiveController {
    /** For Getting User Details **/
    @AuraEnabled
    public Static User getUserDetails(){
        User partner = [select Id, Name, Email, Phone,AccountID,Contact.Account.Distributor__c, Contact.Account.Distributor__r.Name, 
                        Contact.Account.Name,SmallPhotoUrl,FullPhotoUrl,country,CompanyName,Contact.Account.Type,Contact.AccountId, IsActive,Contact.Primary_Role__c 
                        from User 
                        where id=:UserInfo.getUserId()];
        return partner;
    }
    /**
    * @description This method is used for getting Incentive record.
    * @param incentiveId Get the incentive record based on Id.
    * @return Incentives__c record based on Id.
    */
    @AuraEnabled
    public Static Incentives__c getIncentiveForm(Id incentiveId){
        Incentives__c incentive = [select Id, Name, CCR_Type__c from Incentives__c where id =:incentiveId];
        return incentive;
    }
    
    /** Saving CCR record **/
    @AuraEnabled
    public static string saveCcrRecord(CCR__c record,string ccrtype){
        string result;
        record.CCR_Type__c = ccrtype;
        
        /** based on new form Change  **/
        //User loggedInUser = [Select id,contactId,Contact.AccountId from User where id=:UserInfo.getUserId()];
       // string partnerco = loggedInUser.Contact.AccountId;
       // record.Partner_Company_Name__c=partnerco;
        //record.CCR_Type__c = ccrtype;
        /*List<AccountTeamMember>  accTeamMember = [SELECT AccountId,Id,TeamMemberRole,UserId,User.Email,User.Name,User.Phone FROM AccountTeamMember WHERE
                                                  AccountId =:partnerco AND TeamMemberRole = 'Sales Engineer' LIMIT 1];
        if(accTeamMember.size()>0)   {
            record.Partner_SE_Name__c = accTeamMember[0].User.name;
            if(!string.isBlank(accTeamMember[0].User.email))
                record.Partner_SE_Email__c = accTeamMember[0].User.email;
            if(!string.isBlank(accTeamMember[0].User.Phone))
                record.Partner_SE_Phone__c = accTeamMember[0].User.Phone;
        }  */
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true; 
        Database.SaveResult sr = Database.insert(record, dml);
        
        //PRIT26-20 : Changed logic to show error
        if (sr.isSuccess()) {
            result = sr.getId();
        }else {
            for(Database.Error err : sr.getErrors()) {
                result = result != null? result + err.getMessage() + '\n' : err.getMessage() + '\n';
            }
        }
        
        return result;
    }
}