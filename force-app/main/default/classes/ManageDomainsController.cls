public class ManageDomainsController {
    
    
    @AuraEnabled
    public static List<domainClass> getDomains(){
        List<domainClass> domains = new List<domainClass>();
        List<DomainsUpdate__c> domainsList = [select id ,Name,DomainAPI__c,Action__c  from DomainsUpdate__c];
        Set<String> selectedDomains = new Set<String>();
        if(!domainsList.isEmpty())
            for(DomainsUpdate__c dm : domainsList){
                if(dm.Action__c != 'REMOVE'){
                    domains.add(new domainClass(dm.Name,dm.DomainAPI__c)); 
                }else if(dm.Action__c == 'REMOVE'){
                    selectedDomains.add(dm.DomainAPI__c);
                }
            }
        for(Ignored_Domain__mdt mdt : [SELECT Id, DeveloperName,Label, MasterLabel, isIgnored__c FROM Ignored_Domain__mdt WHERE isIgnored__c = true]){
            if(!selectedDomains.contains(mdt.DeveloperName))
                domains.add(new domainClass(mdt.Label,mdt.DeveloperName));
        }
        return domains;
    }
    
    @AuraEnabled
    public static void addDomains(List<domainClass> updatedDomains){
        List<DomainsUpdate__c> domainsList = [select Id ,Name,DomainAPI__c,Action__c  from DomainsUpdate__c];
        Map<String,DomainsUpdate__c> domainMap = new Map<String,DomainsUpdate__c>();
        for(DomainsUpdate__c dm : domainsList){
            domainMap.put(dm.DomainAPI__c,dm);
        }
        List<DomainsUpdate__c> domainList = new List<DomainsUpdate__c>();
        for(domainClass dm : updatedDomains){
            DomainsUpdate__c dm1 = new DomainsUpdate__c(Name = dm.domainName,DomainAPI__c = dm.domainAPI,Action__c = dm.domainMethod);
            if(domainMap.containsKey(dm.domainAPI)){
                dm1.Id = domainMap.get(dm.domainAPI).Id;
                dm1.Action__c = domainMap.get(dm.domainAPI).Action__c == 'REMOVE' ? 'ADD' : 'REMOVE';
            }
            domainList.add(dm1);
        }
        upsert domainList;
    }
    
    public class domainClass{
        @AuraEnabled public string domainName{get;set;}
        @AuraEnabled public string domainAPI{get;set;}
        @AuraEnabled public string domainMethod{get;set;}
        public domainClass(string domainName,String domainAPI){
            this.domainName = domainName;
            this.domainAPI = domainAPI;
            this.domainMethod = '';
        }
        public domainClass(){}
    }

}