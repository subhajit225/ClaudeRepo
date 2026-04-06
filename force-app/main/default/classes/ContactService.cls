/*******************************************************************************************************
* @author Rubrik
* @date 2018
* @description Partner Community.
*******************************************************************************************************/
public without sharing class ContactService{
    public static List<Contact> conList = new List<Contact>();
    /*******************************************************************************************************
* @description create portal user
* @param contact id
* @return N/A
***********************************************************************************************************/
    @future
    public static void createPortalUser(List<Id> conIdList){
        try{
            List<User> userList = new List<User>();
            Id userRoleId;
            //for(UserRole role:[select Id, DeveloperName from UserRole where id='00ES0000000fOPOMA2']){
             //userRoleId= role.Id;
            //}
                       
            for(Contact conObj :  [select id,FirstName,LastName,Account.Name,Email,Primary_Role__c,MailingStreet,MailingCity,MailingState,MAilingCountry,MailingPostalCode,Phone from Contact where ID IN: conIdList]){
                
                /*Account a = new Account(Name='Test Account Name');
                  insert a;
                
                  Contact c = new Contact(LastName = 'Contact Last Name', AccountId = a.id);
                  insert c;
                  */
                
                  User newPortalUser = new User();
                  if(conObj.Primary_Role__c == 'Admin'){
                  	newPortalUser.ProfileID = ID.valueOf(system.label.PartnerManagerSFDCProfileId);
                  }else{
                    newPortalUser.ProfileID = ID.valueOf(system.label.PartnerSFDCProfileId);
                  }
                  newPortalUser.EmailEncodingKey = 'ISO-8859-1';
                  newPortalUser.LanguageLocaleKey = 'en_US';
                  newPortalUser.TimeZoneSidKey = 'America/New_York';
                  newPortalUser.LocaleSidKey = 'en_US';
                  newPortalUser.FirstName = conObj.FirstName;
                  newPortalUser.LastName = conObj.LastName;
                  newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email;   
                  newPortalUser.CommunityNickname =String.ValueOf(Math.random());
                  if(!String.isBlank(conObj.FirstName) && (!String.isBlank(conObj.LastName) && conObj.LastName.length()>2) ){
                     newPortalUser.Alias = conObj.FirstName.substring(0, 1)+conObj.LastName.substring(0, 2);
                    }
                    else{
                        newPortalUser.Alias ='puser';
                    }
                  newPortalUser.Email = conObj.Email;
                  newPortalUser.IsActive = true;
                  newPortalUser.ContactId = conObj.Id;
                  newPortalUser.Phone = conObj.Phone;
                  newPortalUser.Street= conObj.MailingStreet;
                  newPortalUser.City = conObj.MailingCity;
                  newPortalUser.State = conObj.MailingState;
                  newPortalUser.Country = conObj.MailingCountry;
                  newPortalUser.PostalCode = conObj.MailingPostalCode;
                  newPortalUser.UserPermissionsSFContentUser= true;
                  newPortalUser.CompanyName = conObj.Account.Name;
                  //insert newPortalUser;
                
                  
                
                
                /*User newPortalUser = new User( email=conObj.Email ,
                                              profileid = ID.valueOf(system.label.PartnerSFDCProfileId), 
                                              UserName=system.label.PortalUserNamePrefix+conObj.Email, 
                                              TimeZoneSidKey='America/Los_Angeles',
                                              EmailEncodingKey='ISO-8859-1',
                                              LocaleSidKey='en_US', 
                                              LanguageLocaleKey='en_US',
                                              ContactId = conObj.Id,
                                              //UserRoleId = userRoleId,
                                              //PortalRole = system.label.PartnerRole,
                                              FirstName = conObj.FirstName,
                                              LastName = conObj.LastName,
                                              CompanyName = conObj.Account.Name,
                                              Phone = conObj.Phone,
                                              Street= conObj.MailingStreet,
                                              City = conObj.MailingCity,
                                              State = conObj.MailingState,
                                              Country = conObj.MailingCountry,
                                              PostalCode = conObj.MailingPostalCode,
                                              UserPermissionsSFContentUser= true);
                if(!String.isBlank(conObj.FirstName) && (!String.isBlank(conObj.LastName)||conObj.LastName.length()>2) ){
                    newPortalUser.Alias = conObj.FirstName.substring(0, 1)+conObj.FirstName.substring(0, 2);
                }
                else{
                    newPortalUser.Alias ='puser';
                }*/
                system.debug('value in newPortalUser===='+newPortalUser.userroleId);
                userList.add(newPortalUser);
                system.debug('value in userList===='+userList+'==size==='+userList.size());
                
            }
			if(!userList.isEmpty()){
                insert userList;
              /* GroupMember libraryGroupMemeber = new GroupMember(GroupId=system.label.PartnerGroupId,UserOrGroupId=[select id from user where username=:userList[0].username].id);
               insert libraryGroupMemeber;*/
               
            }
            //return true;
        }catch(DMLException DMLEx){
            System.debug('DML Exception Occured in Method:createPortalUser className: ContactService');
            //return false;
        }
    }
    @future
    public static void deactivateCommunityUser(set<Id> newconIdSet){
        List<User> conuserList = new List<User>();
        if(!newconIdSet.isEmpty()){
            for(User conu: [select Id,isActive,contactId from User where ContactId IN:newconIdSet]){
                conu.isActive = false;
                conuserList.add(conu);
            }
        }
        if(!conuserList.isEmpty()){
            update conuserList;
        }
    }

    //PRIT25-91 - start
    @future
    public static void updateUserCompany(List<Id> contactIds)
    {   
        List<User> updateUserList = new List<User>();
            for(User u : [SELECT Id, ContactId, Contact.Account.Name, CompanyName FROM User WHERE ContactId IN :contactIds])
        {
            u.CompanyName = u.Contact.Account.Name;
            updateUserList.add(u);
        }
        
        update updateUserList;
    }
    //PRIT25-91 - end
}