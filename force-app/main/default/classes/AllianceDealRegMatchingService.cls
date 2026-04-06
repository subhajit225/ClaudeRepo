public inherited sharing class AllianceDealRegMatchingService {
    public Map<String,Contact> getMatchingContact(Set<String> emails){
        Map<String, Contact> contactEmailToAccountId = new Map<String, Contact>();
        if(!emails.isEmpty()){
            for(Contact con : [SELECT Id, AccountId, Email FROM Contact WHERE Account.RecordType.Name = 'Customer/Prospect' AND Email IN :emails]){
                contactEmailToAccountId.put(con.Email.tolowerCase(), con);
            }
        }
        return contactEmailToAccountId;
    }
    public Map<String,Contact> getMatchingDomain(Set<String> emails){
        Map<String, Contact> contactEmailToAccountId = new Map<String, Contact>();
        if(!emails.isEmpty()){
            //get the public domains
            Set<String> publicDomains = new Set<String>();
            for(Email_Public_Domain__mdt publicDomain : [SELECT DomainName__c FROM Email_Public_Domain__mdt]) {
                publicDomains.add(publicDomain.DomainName__c);
            }
            //get the domains
            Map<String, Set<String>> domainToEmails = new Map<String, Set<String>>();
            for(String email : emails){
                String domain = email.subStringAfter('@').tolowerCase();
                if(!publicDomains.contains(domain)){
                    if(domainToEmails.containsKey(domain))
                        domainToEmails.get('%'+domain).add(email);
                    else 
                        domainToEmails.put('%'+domain, new Set<String>{email});
                }
            }
            if(!domainToEmails.isEmpty()){
                Set<String> domains = domainToEmails.keySet();
                for(Contact con : [SELECT Id, AccountId, Email FROM Contact WHERE Account.RecordType.Name = 'Customer/Prospect' AND Email LIKE :domains]){
                    String domain = '%'+con.Email.subStringAfter('@').tolowerCase();
                    if(domainToEmails.containsKey(domain)){
                        for(String email: domainToEmails.get(domain))
                            contactEmailToAccountId.put(email, con);
                    }
                }
            }
        }
        return contactEmailToAccountId;
    }
    public Map<String, Lead> getMatchingLead(Set<String> emails){
        Map<String, Lead> leadEmailToId = new Map<String, Lead>();
        if(!emails.isEmpty()){
            for(Lead led : [SELECT Id, Email FROM Lead WHERE Email IN :emails]){
                leadEmailToId.put(led.Email.tolowerCase(), led);
            }
        }
        return leadEmailToId;    
    }
    public Map<String, Id> getMatchingAccount(Set<String> accountIds){
        Map<String, Id> validAccountIds = new Map<String, Id>();
        if(!accountIds.isEmpty()){
            for(Account acc : [SELECT Id FROM Account WHERE Id IN : accountIds]){
                validAccountIds.put(acc.Id, acc.Id);
            }
        }
        return validAccountIds;
    }
}