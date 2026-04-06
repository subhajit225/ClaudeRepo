/**
* @description : Service class to create/update portal user, create/update portal contact from Partner_Registration_Request__c record
*/
public inherited sharing class PC_PartnerRegistrationRequestService{

	/**
    * @description : Dertermine PR request to:
    * 				Create contact and Create user if no matching email contact found
    * 				Update contact and Create user if matchng contact found with no associated user
    * 				Update user to activate/change profile if both contact and associated user found
    * @return : void
    */
	public void processPR(List<Partner_Registration_Request__c> PartRegList){
		Set<Id> updateUserProfileIds = new Set<Id>();
		Set<Id> activateUserIds = new Set<Id>();
		Set<Id> existingContactIdWithoutUser = new Set<Id>();
		Set<Id> existingUserContactIds = new Set<Id>();
		List<Partner_Registration_Request__c> createContactPRList = new List<Partner_Registration_Request__c>();
		List<User> existingPartnerUsers = new List<User>();
		Map<String,Boolean> emailAdminAccessMap = new Map<String,Boolean>();
		Map<String,Partner_Registration_Request__c> emailPRMap = new Map<String,Partner_Registration_Request__c>();

		//below for loop can be moved to trigger helper
		for(Partner_Registration_Request__c pr : PartRegList){
			emailPRMap.put(pr.Email__c,pr);
			
			if(pr.Related_Partner_Contact__c != null){
				existingUserContactIds.add(pr.Related_Partner_Contact__c);
			}
			
		}
		
        if(!existingUserContactIds.isEmpty()){
            existingPartnerUsers = getUserDetails(existingUserContactIds);
            
            for(User existingUser : existingPartnerUsers){
                if(emailPRMap.containsKey(existingUser.Email) && emailPRMap.get(existingUser.Email).Admin_Access__c && existingUser.Profile.Name != 'Rubrik Partner Community Manager'){
                    updateUserProfileIds.add(existingUser.Id);
                }

                if(!existingUser.isActive && !updateUserProfileIds.contains(existingUser.Id)){
                    activateUserIds.add(existingUser.Id);
                }

                if(emailPRMap.containsKey(existingUser.Email)){
                    emailPRMap.remove(existingUser.Email);
                }
            }
        }

        for(Partner_Registration_Request__c pr : emailPRMap.values()){
			if(pr.Related_Partner_Contact__c != null){
				emailAdminAccessMap.put(pr.Email__c,pr.Admin_Access__c);
				existingContactIdWithoutUser.add(pr.Related_Partner_Contact__c);
			}else{
				createContactPRList.add(pr);
			}
		}

        //Activate existing Users OR Update existing Partner Users to Manager
        if(!activateUserIds.isEmpty() || !updateUserProfileIds.isEmpty()){
            Id jobId = System.enqueueJob(new PC_PartnerRegistrationRequestQueueable(activateUserIds,updateUserProfileIds));
		}

		//Update existing Contacts by marking Create_Portal_User__c as True to create new Users
		if(!emailAdminAccessMap.isEmpty()){
			modifyContacts(emailAdminAccessMap,existingContactIdWithoutUser);
		}

		//Create new Contacts by marking Create_Portal_User__c as True to create new Users
		if(!createContactPRList.isEmpty()){
			createContacts(createContactPRList);
		}
	}

    /**
    * @description : Get associated User details of Contacts
    * @return : List of users
    */
	public List<User> getUserDetails(Set<Id> contactIds){
		return [SELECT Id, isActive, Profile.Name, ContactId,UserType, Email FROM User WHERE ContactId IN : contactIds AND UserType ='PowerPartner'];
	}
	
    /**
    * @description : Mark the contact's primary role if Admin and mark Create_Portal_User__c as true to further 
    * 				create a user from contact Trigger
    * @return : void
    */
	public void modifyContacts(Map<String, Boolean> emailAdminAccessMap,Set<Id> existingContactIdWithoutUser){
		List<Contact> contactList = new List<Contact>();
		for(Contact conObj :  [SELECT Id,Email,Primary_Role__c,Create_Portal_User__c FROM Contact WHERE ID IN :existingContactIdWithoutUser]){
			if(emailAdminAccessMap.containsKey(conObj.Email)){
				if(emailAdminAccessMap.get(conObj.Email)){
					conObj.Primary_Role__c = 'Admin';
				}
				conObj.Create_Portal_User__c = true;
			}
			contactList.add(conObj);
		}
		update contactList;
	}

    /**
    * @description : Create contacts for the PR request
    * @return : void
    */
	public void createContacts(List<Partner_Registration_Request__c> PRList){
		List<Contact> contactList = new List<Contact>();
		Map<String, CountryWithCode__c> mapStatusCounrtyCodeCustomSetting = CountryWithCode__c.getAll();
		for(Partner_Registration_Request__c pr : PRList){
			Contact newContact = new Contact(
				LastName = pr.Last_Name__c,
				FirstName = pr.First_Name__c,
				AccountId = pr.Partner_Account_Lookup__c,
				Email = pr.Email__c,
				Title = pr.Job_Title__c,
				Phone = pr.Phone_Number__c,
				MailingStreet = pr.Address__c,
				MailingCity = pr.City__c,
				MailingCountry = pr.Country__c,
				MailingPostalCode = pr.Postal_Code__c,
				Communication_Opt_in__c = pr.Communication_Opt_in__c,
				create_Portal_User__c=true,
				LeadSource = 'Channel Marketing'
			);
			if(mapStatusCounrtyCodeCustomSetting.containsKey(pr.Country__c) && pr.State__c != null){
				String uniqueCode = mapStatusCounrtyCodeCustomSetting.get(pr.Country__c).code__c+'-'+pr.State__c;
				newContact.MailingState = StateCodeName__c.getInstance(uniqueCode).State_Name__c;
			}
			else{
				newContact.MailingState = null;
			}
			contactList.add(newContact);
		}
		insert contactList;
	}
}