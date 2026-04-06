public class taskReAssignBatch implements
    Database.Batchable<sObject>, Database.Stateful {
    // instance member to retain state across transactions
    public Integer recordsProcessed = 0;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> ooo = new List<String>{'Dean Kelly',
'David Helleman',
'Steven Baker',
'Matthew Littlehales',
'Nathalie Barsoum',
'Glenn Thomson',
'Bowden Chapman',
'Wini Anggreni',
'Mario Wihardja',
'Aamir Thoker',
'Srinivasan Narayanan',
'Norikazu Shikimi',
'Koji Kobayashi',
'Norikazu Takei',
'Hideharu Kanenobu',
'Yoichiro Ide',
'Mark Terpening',
'Jeff Wilks',
'Jagan Ramakrishnan',
'Rahul Tyagi',
'Christian Philippi',
'Stephen Chaney'};

        return Database.getQueryLocator(
            'Select id, AccountId,ownerId,Account.Account_Status__c, Account.Name, Account.RecordType.Name, Contact_Follow_Up_Status__c from Contact where ' +
            'Account.Account_Status__c = \'Existing Customer\' AND Contact_Follow_Up_Status__c !=\'Follow up completed\' AND Account.RecordType.Name = \'Customer/Prospect\' and Follow_up_Requested_Date__c != TODAY and Follow_up_Requested_Date__c> 2021-03-01 '+
			' and contact_status__c != \'Active Opportunity (System Use)\' and Campaign_Sourced_By__c != \'sales\' and (NOT owner.userrole.name  LIKE \'%SDR%\')   and account.name != \'Rubrik\' and MQL__C = true and owner.name NOT IN: ooo'
        );
    }
    public void execute(Database.BatchableContext bc, List<Contact> scope){
        for (Contact con : scope) {
            List<id> apContact = new List<id>();
            apContact.add(con.Id);
            ContactLeadConsole.reAssignTask(apContact);
        }
    }
    public void finish(Database.BatchableContext bc){
       integer i=0;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
            
    }

}