public class DomainTriggerHelper {
    public static void checkDomain(List<WL_Domain__c> domains,Map<Id,WL_Domain__c> oldMap){
        Set<Id> accounts = new Set<Id>();
        for(WL_Domain__c dom:domains){
            accounts.add(dom.Account__c);
        }
        Map<Id,List<String>> domainMap = new Map<Id,List<String>>();
        for(WL_Domain__c dom:[Select Name, Account__c from WL_Domain__c where Account__c IN:accounts]){
            if(!domainMap.containsKey(dom.Account__c)){
                domainMap.put(dom.Account__c,new List<String>());
            }
            domainMap.get(dom.Account__c).add(dom.Name.toLowerCase());
        }
        if(!domainMap.isEmpty()){
            for(WL_Domain__c dom:domains){
                if((domainMap?.containsKey(dom.Account__c) && trigger.isInsert) || dom.Name != oldMap.get(dom.Id).Name){
                    if(domainMap.get(dom.Account__c).contains(dom.Name.toLowerCase())){
                        dom.addError('Domain Already Exist');
                    }
                }
            }
        }
    }
}