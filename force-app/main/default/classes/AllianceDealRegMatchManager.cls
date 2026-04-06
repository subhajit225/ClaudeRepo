public inherited sharing class AllianceDealRegMatchManager 
                                        implements Queueable{

    private Set<Id> dealRegIds;
    public AllianceDealRegMatchManager(Set<Id> dealRegIds){
        this.dealRegIds = dealRegIds;
    }
    public void execute(QueueableContext qc){
        Map<String, List<Id>> emailToDealRegIds = new Map<String, List<Id>>();
        Map<Id, String> dealIdToAccountId = new Map<Id, String>();
        Map<Id, Alliance_Deal_Registration__c> updateDealRegs = new Map<Id, Alliance_Deal_Registration__c>();
        for(Alliance_Deal_Registration__c deal : [SELECT Id, Email__c, Account_Id__c FROM Alliance_Deal_Registration__c 
                                                    WHERE Id IN :dealRegIds]){
            //get the emails
            if(deal.Email__c!=null){
                String email = deal.Email__c.tolowerCase();
                if(emailToDealRegIds.containsKey(email))
                    emailToDealRegIds.get(email).add(deal.Id);
                else 
                    emailToDealRegIds.put(email, new List<Id>{deal.Id});
            }
            if(deal.Account_Id__c != null){
                dealIdToAccountId.put(deal.Id, deal.Account_Id__c);
            }
            if(deal.Email__c == null && deal.Account_Id__c== null)
                updateDealRegs.put(
                    deal.Id,
                    new Alliance_Deal_Registration__c(
                        Id = deal.Id,
                        Match_Status__c = 'Net New Lead'
                    )
                );
        }
        AllianceDealRegMatchingService matchService = new AllianceDealRegMatchingService();
        //check for matching contacts
        Map<String, Contact> emailToContact = matchService.getMatchingContact(emailToDealRegIds.keySet());
        for(String email : emailToContact.keySet()){
            Contact con = emailToContact.get(email);
            //if match is found, update it on the deal reg and update the status
            for(Id dealId : emailToDealRegIds.get(email)){
                updateDealRegs.put(dealId,
                    new Alliance_Deal_Registration__c(
                        Id = dealId,
                        Contact__c = con.Id,
                        Account__c = con.AccountId,
                        Match_Status__c = 'Contact Match'
                    )
                );
            }
            emailToDealRegIds.remove(email);
        }
        //check for the domain match
        emailToContact = matchService.getMatchingDomain(emailToDealRegIds.keySet());
        for(String email : emailToContact.keySet()){
            Contact con = emailToContact.get(email);
            //if match is found, update it on the deal reg and update the status
            for(Id dealId : emailToDealRegIds.get(email)){
                updateDealRegs.put(dealId,
                    new Alliance_Deal_Registration__c(
                        Id = dealId,
                        Account__c = con.AccountId,
                        Match_Status__c = 'Domain Match'
                    )
                );
            }
            emailToDealRegIds.remove(email);
        }
        //add accounts whose emails are not present
        for(Id dealId : dealIdToAccountId.keySet()){
            //add only those for which match is not found
            if(updateDealRegs.containsKey(dealId)){
                dealIdToAccountId.remove(dealId);
            }
        }
        Map<String, Id> validAccountIds = matchService.getMatchingAccount(new Set<String>(dealIdToAccountId.values()));
        Map<String, String> accountIdToEmail = new Map<String, String>();
        for(String email : emailToDealRegIds.keySet()){
            for(Id dealId : emailToDealRegIds.get(email)){
                if(dealIdToAccountId.containsKey(dealId)) {
                    accountIdToEmail.put(dealIdToAccountId.get(dealId), email);
                }
            }
        }
        for(Id dealId : dealIdToAccountId.keySet()){
            if(validAccountIds.containsKey(dealIdToAccountId.get(dealId))){
                String accountId = dealIdToAccountId.get(dealId);
                updateDealRegs.put(dealId,
                    new Alliance_Deal_Registration__c(
                        Id = dealId,
                        Account__c = accountId,
                        Match_Status__c = 'Account Match'
                    )
                );
                if(emailToDealRegIds.containsKey(accountIdToEmail.get(accountId)))
                    emailToDealRegIds.remove(accountIdToEmail.get(accountId));
            } 
        }
        Map<String, Lead> emailToLead = matchService.getMatchingLead(emailToDealRegIds.keySet());
        for(String email : emailToLead.keySet()){
            Lead led = emailToLead.get(email);
            //if match is found, update it on the deal reg and update the status
            for(Id dealId : emailToDealRegIds.get(email)){
                updateDealRegs.put(dealId,
                    new Alliance_Deal_Registration__c(
                        Id = dealId,
                        Lead__c = led.Id,
                        Match_Status__c = 'Lead Match'
                    )
                );
            }
            emailToDealRegIds.remove(email);
        }   
        for(String email : emailToDealRegIds.keySet()){
            for(Id dealId : emailToDealRegIds.get(email)){
                updateDealRegs.put(dealId,
                    new Alliance_Deal_Registration__c(
                        Id = dealId,
                        Match_Status__c = 'Net New Lead'
                    )
                );
            }
        }
        if(!updateDealRegs.isEmpty()){
            List<Alliance_Deal_Registration__c> updateDealRegsList = updateDealRegs.values();
            List<Alliance_Deal_Registration__c> erroredRecords = new List<Alliance_Deal_Registration__c>();
            List<Database.SaveResult> results =  Database.update(updateDealRegsList, false);
            
            for(Integer i=0; i<results.size(); i++){
                if(!results[i].isSuccess()){
                    Alliance_Deal_Registration__c erroredRecord = new Alliance_Deal_Registration__c(Id = updateDealRegsList[i].Id, Error_Message__c='');
                    for(Database.Error error : results[i].getErrors()){
                        erroredRecord.Error_Message__c  += (error.getMessage()+'\n');
                    }
                    erroredRecords.add(erroredRecord);
                }
            }
            if(!erroredRecords.isEmpty())
                Database.update(erroredRecords, false);
        }
    }
}