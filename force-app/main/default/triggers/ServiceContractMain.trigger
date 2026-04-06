trigger ServiceContractMain on ServiceContract (before insert, before update, after update, after insert){
    /*
    if(Trigger.isAfter && Trigger.isUpdate) {
        Boolean isDisabled = false; 
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_ServiceContract_Trigger__c;
        if(!isDisabled ) {        
        List<Opportunity> updateOpportunity = new List<Opportunity>();
        set<Opportunity> updateOpportunitySet = new Set<Opportunity>();        
        Map<Id,Opportunity> updateOpportunityMap = new Map<id,Opportunity>();
        for(ServiceContract SC : Trigger.New){
            String Name = SC.Name.trim();
            if(SC.SBQQSC__RenewalOpportunity__c != null){
                opportunity opp = new Opportunity(id=SC.SBQQSC__RenewalOpportunity__c);
                if( Name.EndsWith('Contract')){
                opp.Name = Name.replace('Contract', 'Renewal');
                }
                else{
                    opp.Name = SC.Name+'- Renewal';
                }
                //updateOpportunitySet.add(opp);
                updateOpportunityMap.put(opp.id,opp);
            }
        }
        system.debug('updateOpportunityMap=='+updateOpportunityMap);
        system.debug('updateOpportunityMap=='+updateOpportunityMap.size());
        if(updateOpportunityMap.size()>0)
            updateOpportunity.AddAll(updateOpportunityMap.values());
        system.debug('updateOpportunity=='+updateOpportunity);
        if(!updateOpportunity.isEmpty()){
            update updateOpportunity;
            system.debug('updateOpportunity22=='+updateOpportunity);
        }
        }
    }
    */
    if(TriggerControl.stopSCTrigger){
        return; 
    }
    //RWD-1606 starts
   if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
            Boolean isDisabled = false;
            Map<Id, Id> contractQuoteMap = new Map<Id, Id>();
            List<SBQQ__Quote__c> quoteRecords = new List<SBQQ__Quote__c>();
            ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
            isDisabled = disabled.Disable_ServiceContract_Trigger__c;
            if(!isDisabled ) {
                //Added for PRDOPS26-984
                if(Trigger.isInsert){
                    ServiceContractTriggerHelper.insertTransaction = true;
                }
                //Added for PRDOPS26-984
                if(Trigger.isUpdate){
                    ServiceContractTriggerHelper.validateServiceContractUpdatePermissions(Trigger.newMap,Trigger.oldMap);               
                } 
                for(ServiceContract sContract : Trigger.new) {
                    if (sContract.SBQQSC__Quote__c != null) {
                        contractQuoteMap.put(sContract.SBQQSC__Quote__c, sContract.Id);
                    }
                }
                if (contractQuoteMap.size()>0) {
                    quoteRecords = [SELECT Id, MSP_SKUs_Count__c, OpportunitySubType__c, Amended_Renewed_Service_Contract__c FROM SBQQ__Quote__c WHERE Id IN : contractQuoteMap.keySet()];
                    for (ServiceContract sContract : Trigger.new) {
                        if(!quoteRecords.isEmpty()) {
                            for (SBQQ__Quote__c quoteRec : quoteRecords) {
                                if (contractQuoteMap.containsKey(quoteRec.Id) && sContract.SBQQSC__RenewalTerm__c != 12 && quoteRec.MSP_SKUs_Count__c != null && quoteRec.MSP_SKUs_Count__c <= 0) {
                                    sContract.SBQQSC__RenewalTerm__c = 12;
                                }
                            }
                        }
                    }
                }
            }
       }//RWD-1606 ends
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        Boolean isDisabled = false;
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_ServiceContract_Trigger__c;
        if(!isDisabled ) {
        RenewalCaseHelper rnwHelper = new RenewalCaseHelper();
        Set<Id> orderIds = new Set<Id>();
        Map<Id, Order> mapOrders = new Map<Id, Order>();
        List<ServiceContract> toUpdate = new List<ServiceContract>();

        for(ServiceContract sc : Trigger.new) {
            rnwHelper.accountIds.add(sc.AccountId);
            rnwHelper.oppIds.add(sc.SBQQSC__Opportunity__c);
            rnwHelper.quoteIds.add(sc.SBQQSC__Quote__c);
            ServiceContract oldSC = (Trigger.oldMap != null && Trigger.oldMap.containsKey(sc.Id))
                ? Trigger.oldMap.get(sc.Id) : null;

            if(oldSC == null && sc.SBQQSC__Order__c != null) {
                orderIds.add(sc.SBQQSC__Order__c);
            }  
            if(oldSC != null && sc.SBQQSC__Order__c != null && sc.SBQQSC__Order__c != oldSC.SBQQSC__Order__c) {
                orderIds.add(sc.SBQQSC__Order__c);
            }
        }

        if(!orderIds.isEmpty()) {
            List<Order> orders = [SELECT Id, Opportunity.Name FROM Order WHERE Id IN :orderIds];
            if(!orders.isEmpty()) {
                mapOrders.putAll(orders);
            }
        }

        for(ServiceContract sc : Trigger.new) {

            if(sc.SBQQSC__Order__c != null) {
                Order ord = (mapOrders.containsKey(sc.SBQQSC__Order__c)) ? mapOrders.get(sc.SBQQSC__Order__c) : null;

                if(ord != null && String.isNotBlank(ord.Opportunity.Name)) {
                    toUpdate.add(
                        new ServiceContract(Id = sc.Id, Name = ord.Opportunity.Name + ' - Contract')
                    );
                }

            }
        }

        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }
        if(Trigger.isAfter &&  Trigger.isUpdate){
            RenewalAndExpansionSplit.createRenewalOpportunityLinkage( trigger.new, trigger.oldMap );
            rnwHelper.createCase();
            // CSAT - CPQ22-3109 
            CPQ_CSATUtility.createCSATQuote(trigger.new, trigger.oldMap);
        }
      }
        
    }
}