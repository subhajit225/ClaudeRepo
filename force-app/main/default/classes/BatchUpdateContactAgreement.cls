global class BatchUpdateContactAgreement implements Database.Batchable<sObject>, Schedulable {

	String query;

	global BatchUpdateContactAgreement() {
		this.query = '' +
            'SELECT ContactId ' +
            'FROM CampaignMember ' +
            'WHERE Status = \'Filled-out Form\' ' +
                'AND HasResponded = true ' +
                'AND ContactId != null ' +
                'AND Contact.Try_Buy_Agreement__c = false ';
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

    global void execute(SchedulableContext sc) {
        BatchUpdateContactAgreement b = new BatchUpdateContactAgreement();
        Database.executeBatch(b, 100);
    }

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<CampaignMember> result = (List<CampaignMember>)scope;
        Map<Id, Contact> toUpdate = new Map<Id, Contact>();

        for(CampaignMember cm : result) {
            Id contactId = cm.ContactId;
            toUpdate.put(contactId, new Contact(Id = contactId, Try_Buy_Agreement__c = true));
        }

        if(!toUpdate.isEmpty()) {
            Database.update(toUpdate.values(), false);
        }
	}

	global void finish(Database.BatchableContext BC) {

	}

}