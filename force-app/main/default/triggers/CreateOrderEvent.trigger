trigger CreateOrderEvent on CreateOrder__e (after Insert) {
    Set<Id> setOppIds = new Set<Id>();
    Set<Id> setAutoSubmitOppIds = new Set<Id>();
    Set<Id> contractNegotiationAccIds = new Set<Id>();
    for(CreateOrder__e event : Trigger.new){
        if(String.isNotBlank(event.RecordId__c) && event.Business_Process__c == CONSTANTS.CONTRACT_IN_NEGOTIATION){
            contractNegotiationAccIds.add(event.RecordId__c);
        }
        else if(String.isNotBlank(event.RecordId__c) && event.Auto_Submit_Order__c){
            setAutoSubmitOppIds.add(event.RecordId__c);    
        }
        else if(String.isNotBlank(event.RecordId__c)){
            setOppIds.add(event.RecordId__c);
        }
    }
        if(!setOppIds.isEmpty()){
    updateOrderedOnOppo(setOppIds);
        }
        if(!setAutoSubmitOppIds.isEmpty()){
            for(Id oppId : setAutoSubmitOppIds){
                AcceptPOHelper.autoPoSubmission(oppId);    
            }    
        }
        if(!contractNegotiationAccIds.isEmpty()){
            updateOrderStatusAndHoldCode(contractNegotiationAccIds);
        }
        /**
       * @author Siva Kumar
       * @date 03-02-2026
       * @description When Contract Negotiation is set to TRUE on Account by Rubrik Legal Team user
       * then this method puts Revenue Orders, which as not Shipped, on hold with Hold code as Contract in negotiations
       * as Order Automation User
       * @param  contractNegotiationAccIds accountIds where Contract Negotiation is set to TRUE
       */
        public void updateOrderStatusAndHoldCode(Set<Id> contractNegotiationAccIds){
    
            List<Order> lstOrder = [SELECT Id, Hold_Code__c FROM Order  WHERE Type = 'Revenue' AND Order_Status__c IN ('On Hold', 'PO Received', 'Order Accepted', 'Pending') 
                        AND Status != 'Cancelled' AND Opportunity.AccountId IN :contractNegotiationAccIds];
            if(!lstOrder.isEmpty()){
                for(Order ord : lstOrder){
                    ord.Order_Status__c = 'On Hold';
                    if(String.isBlank(ord.Hold_Code__c)){
                        ord.Hold_Code__c = 'Contract in negotiations';
                    }
                    else if(!ord.Hold_Code__c.contains('Contract in negotiations')){
                        ord.Hold_Code__c += ';Contract in negotiations';
                    }
                }
                List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();
                Database.SaveResult[] results = Database.update(lstOrder);
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess() || Test.isRunningTest()) {
                        Database.Error error = Test.isRunningTest() ? null : results.get(i).getErrors().get(0);
                        String errorMsg = Test.isRunningTest() ? '' : error.getMessage();
                        errorLogs.add(
                            new Error_Logs__c(Error_Type__c = 'Order Error', Error_Message__c = errorMsg, Related_Order__c = lstOrder[i].Id, Type__c = 'SFDC')
                        );
                    }
                }
                if(!errorLogs.isEmpty()){
                    insert errorLogs;
                }
            }
    
        }
    public void updateOrderedOnOppo(Set<Id> setOppIds){
        List<Opportunity> lstUpdateOppo = new List<Opportunity>();
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        List<Custom_Error_Log__c> lstError = new List<Custom_Error_Log__c>();
        Map<Id,List<SBQQ__QuoteLine__c>> mapOppIdToQLILst = new Map<Id, List<SBQQ__QuoteLine__c>>();
        List<SBQQ__QuoteLine__c> qliList = [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c
                                               FROM SBQQ__QuoteLine__c
                                               WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c IN :setOppIds
                                                 AND SBQQ__Quote__r.SBQQ__Primary__c = true
                                                 AND SBQQ__Existing__c = false];
        if (!qliList.isEmpty()) {
    
            for(SBQQ__QuoteLine__c objQLI : qliList){
                if(mapOppIdToQLILst.containsKey(objQLI.SBQQ__Quote__r.SBQQ__Opportunity2__c)){
                    mapOppIdToQLILst.get(objQLI.SBQQ__Quote__r.SBQQ__Opportunity2__c).add(objQLI);
                }else{
                    mapOppIdToQLILst.put(objQLI.SBQQ__Quote__r.SBQQ__Opportunity2__c, new List<SBQQ__QuoteLine__c>{objQLI});
                }
    
            }
        }
    
        for(Id oppId : setOppIds){
            if(mapOppIdToQLILst.containsKey(oppId) && mapOppIdToQLILst.get(oppId).size() <= 200){
                lstUpdateOppo.add(new Opportunity(Id= oppId,SBQQ__Ordered__c = true));
            }else{
                lstOpportunity.add(new Opportunity(Id= oppId,SBQQ__Ordered__c = true)); 
            }
        }
    
        if(!lstOpportunity.IsEmpty()){
            System.enqueueJob(new OpportunityBulkUpdateQueueable(lstOpportunity));
        }
       
        if(!lstUpdateOppo.isEmpty()){
            
            for (Database.SaveResult sr : database.Update(lstUpdateOppo, false)){
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        lstError.add(LogError.CreateDMLErrorLog('CreateOrderEvent', sr.getId(), err.getMessage(),null));
                    }
                }
                }
            
        }
        if(!lstError.isEmpty()){
                insert lstError;
            }
    }
    
    }