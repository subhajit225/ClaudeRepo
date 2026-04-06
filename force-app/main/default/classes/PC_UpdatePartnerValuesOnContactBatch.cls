public class PC_UpdatePartnerValuesOnContactBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id,Contact.Partner_Promo_Banner__c,UserType,ContactId
                                            FROM User
                                            WHERE UserType = 'PowerPartner'
                                         	AND Contact.Partner_Promo_Banner__c = true]);
    }

    public void execute(Database.BatchableContext bc, List<User> scope) {
        List<Contact> contactsToUpdate = new List<Contact>();
        for(User usr : scope) {
            Contact con = new Contact(Id = usr.ContactId);
            con.Partner_Promo_Banner__c = false;
            contactsToUpdate.add(con);
        }
        flowControll.contactTrigger = false;
        update contactsToUpdate;
        flowControll.contactTrigger = true;
    }

    public void finish(Database.BatchableContext bc) {
        if(!Test.isRunningTest())
        {
            Database.executeBatch(new PC_PortalUserDeactivationBatch(), 20);
        }
    }
}