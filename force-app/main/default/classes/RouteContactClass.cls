public class RouteContactClass implements Queueable{
    public set<Id> contactIds;
    public Map<Id, Contact> contactIdToContact;
    public Map<Id, Boolean> mapIdWithFalseFallback;
    
    public RouteContactClass(set<Id> contactIds, Map<Id, Contact> contactIdToContact, Map<Id, Boolean> mapIdWithFalseFallback) {
        this.contactIds = contactIds;
        this.contactIdToContact = contactIdToContact;
        this.mapIdWithFalseFallback = mapIdWithFalseFallback;  
    }
    public void execute(QueueableContext context){
        MQLRoutingService service = new MQLRoutingService(new Set<Id>(contactIds), 'Contact');
            List<Lead_Routing_Rule__mdt> allRules = service.getAllRules();
            Map<Id, Lead_Routing_Rule__mdt> contactToRule = service.stampRulesOnRecords(allRules);
            System.debug('#LeadTriggerHelper#assignOwner#leadToRule:'+contactToRule);
            if(!contactToRule.isEmpty()){
                MQLRoutingOwnerAssignService1 ownerService = new MQLRoutingOwnerAssignService1(new Set<Id>(contactIds), allRules);
                ownerService.assignOwners(contactToRule, contactIdToContact, mapIdWithFalseFallback);
            }
    }

}