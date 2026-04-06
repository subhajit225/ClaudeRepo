/**
 * @description class RenewalCaseHelper {

 */
public class RenewalCaseHelper {
    
    /**
    * @description Set of Account Id
    */
    public Set<Id> accountIds = new Set<Id>();
     /**
    * @description Set of Opportunity Id
    */
    public Set<Id> oppIds = new Set<Id>();
     /**
    * @description Set of Quote Id
    */
    public Set<Id> quoteIds = new Set<Id>();
     /**
    * @description Set of Strings
    */
    public Set<String> pFamily = new Set<String>{'R300','R500','R300S','RBK-R300','RBK-R500','R300/R6000'};
    /**
     * @description
    */
    public void createCase(){
        if(TriggerControl__c.getAll() != null && TriggerControl__c.getAll().containsKey('Renewal Case') && !TriggerControl__c.getInstance('Renewal Case').DisableTrigger__c){
            
            Map<Id,Case> caseMap = new Map<Id,Case>();
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Renewal Case').getRecordTypeId();
            Id queueId = [select Id from Group where  Type = 'Queue' AND developername= 'Renewal_Queue' LIMIT 1].Id;
            Map<Id,SBQQ__Quote__c> quoteMosacMap = new Map<Id,SBQQ__Quote__c>([select id ,(select id from SBQQ__LineItems__r where SBQQ__Product__r.Family = 'MOSAIC') from SBQQ__Quote__c where Id IN: quoteIds]);
            Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>([select id ,(select id from SBQQ__LineItems__r where Approval_Discount__c = 100 AND Category__c = 'Support') from SBQQ__Quote__c where Id IN: quoteIds]);
            Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([SELECT Id,StageName , SBQQ__Ordered__c ,Account.Name,Partner_Lookup__r.Name,Initial_Contacts_Name__c,Partner_SE_Phone__c,Partner_SE_Email__c,Partner_SE_Name__c, Partner_Lookup__c,Distributor_Rep_Phone_Number__c,Distributor_Rep_Name__c,Distributor_Rep_Email__c, Distributor_Lookup__c, Valooto_Quote__c,(select id from OpportunityLineItems where (Product2.Family = 'R300' OR Product2.Family = 'R500'))  FROM Opportunity where Id IN: oppIds]);
            Map<Id,Account> accountMap = new Map<Id,Account>([SELECT id,Name, Sum_of_Opportunities__c,US_Federal_Account__c from account where Id IN: accountIds]);
            Map<id,Id> contractCaseMap = new Map<id,Id>();
            for(Case cs : [SELECT id,ServiceContractId from case where ServiceContractId IN: trigger.NewMap.keyset()]){
                contractCaseMap.put(cs.ServiceContractId,cs.Id);
            }
            Map<Id,List<Entitlement>> contractsEntitlment = new Map<Id,List<Entitlement>>();
            for(Entitlement ent : [SELECT Id, ServiceContractId, AssetId,Asset.ProductFamily FROM Entitlement where ServiceContractId IN:Trigger.NewMap.keyset()  AND Asset.ProductFamily IN :pFamily]){
                if(!contractsEntitlment.containsKey(ent.ServiceContractId)){
                    contractsEntitlment.put(ent.ServiceContractId,new List<Entitlement>());
                }
                contractsEntitlment.get(ent.ServiceContractId).add(ent);
            }
            for(ServiceContract sc : (List<ServiceContract>)Trigger.New){
                ServiceContract oldRecord = (ServiceContract)Trigger.oldMap.get(sc.ID);
                Integer numberDaysDue;
                if(!Test.isRunningTest()){
                    if(sc.EndDate == null){
                        continue;
                    }
                    numberDaysDue = System.today().daysBetween(sc.EndDate);	
                }else{
                    numberDaysDue = 10;
                }

                if(numberDaysDue <= 120 && !contractCaseMap.containsKey(sc.Id) && sc.SBQQSC__RenewalQuoted__c  == true && sc.SBQQSC__RenewalQuoted__c != oldRecord.SBQQSC__RenewalQuoted__c &&
                   accountMap.containsKey(sc.AccountId) && accountMap.get(sc.AccountId).Sum_of_Opportunities__c < Integer.valueOf(System.Label.Renewal_Amount)){
                       String descVal = System.label.Renewal_Case_Desc;
                       Case cs = new Case(
                           RecordTypeId = recordTypeId,
                           OwnerId = queueId,
                           Priority = 'P4',
                           Status = 'New',
                           Description = descVal.replace('[[Account]]',accountMap.get(sc.AccountId).Name) ,
                           AccountId = sc.AccountId,
                           Renewal_Automated__c = true,
                           ServiceContractId = sc.Id
                       );
                       if(accountMap.get(sc.AccountId).US_Federal_Account__c || (quoteMap.containsKey(sc.SBQQSC__Quote__c) && quoteMap.get(sc.SBQQSC__Quote__c).SBQQ__LineItems__r != null && (quoteMap.get(sc.SBQQSC__Quote__c).SBQQ__LineItems__r.size() > 0 || quoteMosacMap.get(sc.SBQQSC__Quote__c).SBQQ__LineItems__r.size() > 0))){
                           Continue;
                       }
                       if(sc.SBQQSC__RenewalOpportunity__c  != null && opportunityMap.containsKey(sc.SBQQSC__RenewalOpportunity__c)){
                           Opportunity opp = opportunityMap.get(sc.SBQQSC__RenewalOpportunity__c);
                           if(opp.StageName == '7 Closed Won' || opp.StageName == '7 Closed Lost' || opp.StageName == '7 Closed Admin' || opp.SBQQ__Ordered__c){
                               continue;
                           }
                       }
                       if(opportunityMap.containsKey(sc.SBQQSC__Opportunity__c) && opportunityMap.get(sc.SBQQSC__Opportunity__c).OpportunityLineItems != null && opportunityMap.get(sc.SBQQSC__Opportunity__c).OpportunityLineItems.size() > 0){
                           Continue;
                       }
                       if(contractsEntitlment.containsKey(sc.Id) && contractsEntitlment.get(sc.Id).size() > 0 ){
                           Continue;
                       }
                       if(opportunityMap.containsKey(sc.SBQQSC__Opportunity__c  ) && opportunityMap.get(sc.SBQQSC__Opportunity__c).Valooto_Quote__c  == null){
                           Opportunity opp = opportunityMap.get(sc.SBQQSC__Opportunity__c);
                           cs.Distributer_Account_Name__c =  opp.Distributor_Lookup__c;
                           cs.Distributer_Contact_Phone__c =  opp.Distributor_Rep_Phone_Number__c;
                           cs.Distributer_Contact_Name__c = opp.Distributor_Rep_Name__c;
                           cs.Distributer_Contact_Email__c = opp.Distributor_Rep_Email__c;
                           cs.Partner_Contact_Email__c =  opp.Partner_SE_Email__c;
                           cs.Partner_Contact_Name__c = opp.Partner_SE_Name__c;
                           cs.Partner_Contact_Phone__c = opp.Partner_SE_Phone__c;
                           cs.Partner_Account_Name__c =  opp.Partner_Lookup__c;
                           cs.Subject = 'Renewal Case - '+opp.Account.Name;
                           cs.Subject += opp.Partner_Lookup__r.Name == null ? '' :' - '+opp.Partner_Lookup__r.Name;
                           caseMap.put(sc.Id,cs);
                       }
                   }
            }
            CaseTriggerHandler.isRepeat = false;
            if(!Test.isRunningTest())
                insert caseMap.values();
        }
    }
    
}