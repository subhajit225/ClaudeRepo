global class UpdateCSATOnQuoteOppBatch  implements Database.Batchable<SObject> {

    Set<Id> contractlineIds = new Set<Id>();
    Set<Id> servcontractIdSet = new Set<Id>();
    global UpdateCSATOnQuoteOppBatch(Set<Id> contractlineIdSet){
        contractlineIds = contractlineIdSet;
        for(contractlineitem cli : [select Id,ServiceContractID from ContractLineItem where Id IN: contractlineIds AND New_Extended_End_Date__c !=null]){
            servcontractIdSet.add(cli.ServiceContractID);
            
        }
        system.debug('called servcontractIdSet' + servcontractIdSet);
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        string query = 'select Id,SBQQSC__Opportunity__c,SBQQSC__RenewalOpportunity__c from ServiceContract where Id IN: servcontractIdSet AND SBQQSC__Opportunity__c != null AND SBQQSC__RenewalOpportunity__c != null';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<ServiceContract> scope) {
        Map<Id,Date> csatDateOppMap = new Map<Id,Date>();
        List<Opportunity> renewaloppList = new List<Opportunity>();
        Set<Id> scIdSet = new Set<Id>();

        for(ServiceContract sc : scope){
            scIdSet.add(sc.Id);
        }

        //CPQ22-3347 - Start - Update Renewal Lines Start Date to include New_Extended_End_Date__c updates. This will be moved outside for loop on july24th afternoon
        if(!scIdSet.isEmpty()){
        system.debug('called CPQ_CSATUtility' + servcontractIdSet);
            CPQ_CSATUtility.updateRenewalQuoteLines(scIdSet);
            system.debug('returned CPQ_CSATUtility' + servcontractIdSet);
        }
        //CPQ22-3347 - End
        if(!scIdSet.isEmpty()){
            for(contractlineitem cli : [select Id,New_Extended_End_Date__c,ServiceContractID,ServiceContract.SBQQSC__Opportunity__c,ServiceContract.SBQQSC__RenewalOpportunity__c from ContractLineItem where ServiceContractID IN: scIdSet]){
                if(csatDateOppMap.isEmpty() || (csatDateOppMap.get(cli.ServiceContract.SBQQSC__RenewalOpportunity__c) > cli.New_Extended_End_Date__c)){
                    csatDateOppMap.put(cli.ServiceContract.SBQQSC__RenewalOpportunity__c,cli.New_Extended_End_Date__c);
                }
            }
        }
        //SAL24-329 - Opp closedate extension on CSAT
        for(Opportunity opp : [select Id,closeDate,stagename from opportunity where Id IN : csatDateOppMap.keySet() AND Opportunity_Sub_Type__c != 'CSAT' AND isclosed = false]){
            if(csatDateOppMap.containskey(opp.Id) && opp.closeDate < csatDateOppMap.get(opp.Id)){
                opp.closeDate = csatDateOppMap.get(opp.Id);
                renewaloppList.add(opp);
            }
        }
        if(!renewaloppList.isEmpty()){
            Database.update(renewaloppList,false);
        }
    }
    global void finish(Database.BatchableContext BC) {
    }
}