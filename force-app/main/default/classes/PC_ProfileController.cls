/*******************************************************************************************************
* @author Rubrik
* @date 2018
* @description Partner Community - Deal registration page components controller.
*******************************************************************************************************/
public class PC_ProfileController {
    
    /*******************************************************************************************************
* @description Returns User record
* @param N/A
* @return the User record for the login user
***********************************************************************************************************/
    @AuraEnabled
    public Static User getUserDetails(){
        User partner = [select Id, Name,SmallPhotoUrl,FullPhotoUrl, IsActive, Contact.Name,Contact.Primary_Role__c,
                        Contact.Account.Type, Contact.Account.Name, Contact.Account.Program_Status__c 
                        from User 
                        where id=:UserInfo.getUserId()];
        return partner;
    }
}