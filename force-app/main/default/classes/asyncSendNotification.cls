/**asyncSendNotification */
public class asyncSendNotification implements Queueable {
    /**quoteIds */
    Private Set<Id> quoteIds;
    /**createdQuoteMap */
    Private Map<Id, SBQQ__Quote__c> createdQuoteMap = new Map<Id, SBQQ__Quote__c>();
    /**approvedQuoteMap */
    Private Map<Id, SBQQ__Quote__c> approvedQuoteMap = new Map<Id, SBQQ__Quote__c>();
            
    /**asyncSendNotification */
    public asyncSendNotification(Map<Id, SBQQ__Quote__c> cQuoteMap, Map<Id, SBQQ__Quote__c> appQuoteMap, Set<Id> qIds){
        this.createdQuoteMap = cQuoteMap;
        this.approvedQuoteMap = appQuoteMap;
        this.quoteIds = qIds;
    }
    /**execute Method */
    public void execute (QueueableContext context){

        Set<Id> opportunityOwnerIdSet = new Set<Id>();
        Map<Id, SBQQ__QuoteLine__c> quotelines = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
        Map<Id, Set<String>> QuoteIdEmailSet = new Map<Id, Set<String>>();
        Map<Id, SBQQ__Quote__c> opptyOwnerQuoteIdMap = new Map<Id, SBQQ__Quote__c>();
        String source;
        
        if(quoteIds != null && !quoteIds.isEmpty()){
            quoteMap = getquotes(quoteIds);
            quotelines = QuoteTriggerHelper.getquotelines(quoteIds);
        }
        
        if(quotelines != null && !quotelines.IsEmpty()){
            for(SBQQ__QuoteLine__c qlns: quotelines.values())
            {
                if(createdQuoteMap.keySet() != null && createdQuoteMap.keySet().contains(qlns.SBQQ__Quote__c))
                {
                    if(qlns.SBQQSC__RenewedContractLine__c != null && qlns.SBQQSC__RenewedContractLine__r.ServiceContractId != null 
                       && qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__c != null){
                           if(QuoteIdEmailSet.containsKey(qlns.SBQQ__Quote__c)){
                               QuoteIdEmailSet.get(qlns.SBQQ__Quote__c).add(qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.Owner.Email);
                           }
                           else{
                               QuoteIdEmailSet.put(qlns.SBQQ__Quote__c, 
                                                   new Set<String>{qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.Owner.Email});
                           }
                           opportunityOwnerIdSet.add(qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.OwnerId);
                           opptyOwnerQuoteIdMap.put(qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.OwnerId,
                                                    quoteMap.get(qlns.SBQQ__Quote__c));
                           source = 'Created';
                           system.debug('MS >> inside created send notification');
                       }
                }
                
                if(approvedQuoteMap.KeySet() != null && approvedQuoteMap.KeySet().contains(qlns.SBQQ__Quote__c))
                {
                    if(qlns.SBQQSC__RenewedContractLine__c != null && qlns.SBQQSC__RenewedContractLine__r.ServiceContractId != null 
                       && qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__c != null){
                           if(qlns.Disposition_Reason__c == 'Converted' || qlns.Disposition_Reason__c =='Refreshed'){
                               if(QuoteIdEmailSet.containsKey(qlns.SBQQ__Quote__c)){
                                   QuoteIdEmailSet.get(qlns.SBQQ__Quote__c).add(qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.Owner.Email);
                               }
                               else {
                                   QuoteIdEmailSet.put(qlns.SBQQ__Quote__c,
                                                       new Set<String>{qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.Owner.Email});
                               }
                               opportunityOwnerIdSet.add(qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.OwnerId);
                               opptyOwnerQuoteIdMap.put(qlns.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.OwnerId,
                                                        approvedQuoteMap.get(qlns.SBQQ__Quote__c));
                               source = 'Approved';
                               system.debug('MS >> inside Approved send notification ');
                           }
                       }
                }
            }
        }
        
        system.debug('quoteMap>> ' + quoteMap);
        //system.debug('opportunityOwnerIdSet>> ' + opportunityOwnerIdSet);
        if(opportunityOwnerIdSet != null && !opportunityOwnerIdSet.isEmpty()){
            SendChatterNotification.sendNotification(opportunityOwnerIdSet, opptyOwnerQuoteIdMap, source);
        }
        if(QuoteIdEmailSet != null && !QuoteIdEmailSet.isEmpty() && quoteMap != null && !quoteMap.isEmpty() && !system.isBatch()){
            SendChatterNotification.sendEmailNotification(QuoteIdEmailSet,source,quoteMap);
        }
    }
    
    /** getquotes*/
    public static Map<Id, SBQQ__Quote__c> getquotes(Set<Id> quoteids){
        Map<Id, SBQQ__Quote__c> quotesmap = new Map<Id, SBQQ__Quote__c> ([SELECT Id, Name, Email_Sent__c, SBQQ__Account__r.Name FROM SBQQ__Quote__c WHERE Id IN: quoteids]);
        return quotesmap;
    }
}