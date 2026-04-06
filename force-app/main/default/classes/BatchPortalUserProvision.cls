global class BatchPortalUserProvision implements Database.Batchable<sObject> {
    
    public Integer batchSize = Test.isRunningTest() ? 1 : 100;
    
    global Set<Id> conSet {get; set;}
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        
        String soql = 'SELECT Id, Email, FirstName, LastName ';
        soql += ' FROM Contact ';
        if(conSet != null && conSet.size() > 0) soql += ' WHERE Id IN: conSet ';
        if(Test.isRunningTest()) soql += ' LIMIT 1';
        system.debug(' ### soql ' + soql);

        return Database.getQueryLocator(soql);
                              
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> cons) {
        handleconsToMatch(cons);
    }

    public static void startJob() {
        BatchPortalUserProvision bul = new BatchPortalUserProvision();
        Database.executeBatch(bul, bul.batchSize);
    }

    global void finish(Database.BatchableContext BC) {

        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, LastProcessedOffset, JobItemsProcessed,TotalJobItems, CreatedBy.Email, ExtendedStatus FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        
        if (a.NumberOfErrors > 0 || Test.isRunningTest()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {Label.PortalProvisionErrors};
            mail.setToAddresses(toAddresses);
             
            mail.setSubject('Batch Provision Users job failed');

            String bodyText = 'The Batch Provision Users job processed ' + a.LastProcessedOffset + ' items with '+ a.NumberOfErrors + ' failures.\n\n';
            bodyText += a.ExtendedStatus;
            mail.setPlainTextBody(bodyText);            
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    
    public static void handleconsToMatch(list<Contact> cons) {
        if (cons == null) 
            return;
        
        if (!cons.isEmpty() ) {
            for(Contact con : cons) { 
                PortalUserHelper.provisionPortalUser(con.Id, Label.CommunityProfileAutoProvision, false);
            }
        }
    }

}