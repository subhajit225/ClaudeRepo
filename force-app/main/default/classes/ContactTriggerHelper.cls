public without sharing class ContactTriggerHelper {
    public static void allowMax2PrimaryContactMail(List<Contact> newContacts, Map<Id, Contact> oldContacts){
        Map<Id, List<Contact>> accountIdsToContact = new Map<Id, List<Contact>>();
        for(Contact con: newContacts){
            if(con.Primary_Customer_Mailing_Contact__c
                && (
                    oldContacts == null
                    || con.Primary_Customer_Mailing_Contact__c != oldContacts.get(con.Id).Primary_Customer_Mailing_Contact__c
                )
            ){
                if(accountIdsToContact.containsKey(con.AccountId))
                    accountIdsToContact.get(con.AccountId).add(con);
                else 
                    accountIdsToContact.put(con.AccountId, new List<Contact>{con});
            }
        }
        for(AggregateResult ar : [SELECT AccountId, count(Id) 
                                FROM Contact 
                                WHERE AccountId IN :accountIdsToContact.keySet() 
                                AND Primary_Customer_Mailing_Contact__c=true
                                GROUP BY AccountId]){
            if(Integer.valueOF(ar.get('expr0'))>=2){
                for(Contact con : accountIdsToContact.get((Id)ar.get('AccountId'))){
                    con.addError('Cannot add more than 2 primary customer mailing contacts on an account');
                }
            }
        }
    }
    public static void getUpdatedContactRecord(set<id> AccountIdsList){
        List<Account> accList=[select id,Agreed_To_POC_terms__c from account where id IN:AccountIdsList];
        if(!accList.isEmpty()){
            List<Account> updateAccountTerms=new List<Account>();
            for(Account eachAccount:accList){
                eachAccount.Agreed_To_POC_terms__c=True;
                updateAccountTerms.add(eachAccount);
            }
            update updateAccountTerms;
        }
    }
    
    // CS21-1403 Start: Added by Ashish to update Phone on Support Portal User --
    public static void afterUpdate(Map<Id, Contact> newContacts, Map<Id, Contact> oldContacts){
        List<Id> conId = new List<Id>();
        List<User> updateUser = new List<User>();
        for(Id idd : newContacts.keyset()){
            Contact con = newContacts.get(idd);
            if(con.Phone != oldContacts.get(idd).Phone){
                conId.add(idd);
            }
        }
        for(User us : [SELECT Id, Name, Phone, ContactId from User where ContactId != null and ContactId IN: conId and isActive = true and UserType = 'CspLitePortal']){
            us.Phone = newContacts.get(us.ContactId).Phone;
            updateUser.add(us);
        }
        if(!updateUser.isEmpty()){
            update updateUser;
        }
    }
    // CS21-1403 End--
    
    /**
     * @description CS21-3111 REGRESSION on CS21-493: RASP Resources Container not auto-assigned
     * @param newContacts map of new Contact records
     * @param oldContacts map of old Contact records
     * @createdDate 4th Mar 2025
     * @author Vijay Kumar K R
     */
    public static void updateUserRelease(Map<Id, Contact> newContacts, Map<Id, Contact> oldContacts){
        Set<Id> accIdSet = new Set<Id>();
        List<User> updateUser = new List<User>();
        for(Id idd : newContacts.keyset()){
            Contact con = newContacts.get(idd);
            if(con.AccountId != oldContacts.get(idd).AccountId){
                accIdSet.add(con.AccountId);
            }
        }
        
        if(!accIdSet.isEmpty()){
            List<User> usersList = new List<User>();
            for(User eachUser : [SELECT Id, RASP__c, Releases__c
                                    FROM User
                                    WHERE IsActive = true
                                    AND Contact.AccountId =: accIdSet
                                    AND UserType = 'CspLitePortal' WITH SECURITY_ENFORCED]){
                if(eachUser.RASP__c && (String.isBlank(eachUser.Releases__c) || !eachUser.Releases__c.containsIgnoreCase('RASP Resources'))){
                    eachUser.Releases__c = String.isBlank(eachUser.Releases__c) ? 'RASP Resources' : eachUser.Releases__c + ';RASP Resources';
                    usersList.add(eachUser);
                }
                else if(!eachUser.RASP__c && !String.isBlank(eachUser.Releases__c)){
                    eachUser.Releases__c = eachUser.Releases__c.replace('RASP Resources', '');
                    usersList.add(eachUser);
                }
            }
            if(!usersList.isEmpty()){
                if (Schema.sObjectType.User.isUpdateable()) { 
                    Database.update(usersList, false);
                } else {
                    System.debug(LoggingLevel.WARN, 'User does not have permission to update User records.');
                }
            }
        }
    }
    // CS21-3111 End--
}