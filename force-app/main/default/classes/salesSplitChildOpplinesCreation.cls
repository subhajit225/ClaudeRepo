public without sharing class salesSplitChildOpplinesCreation implements Queueable{
    public Opportunity primaryOpp;
    public list<Opportunity> childoppList;
    public Set<Id> recordIds;
    public salesSplitChildOpplinesCreation(Opportunity parentOpp,list<Opportunity> childoppsList, Set<Id> childOppIds ){
        primaryOpp = new Opportunity();
        childoppList = new list<Opportunity>();
        recordIds = new Set<Id>();
        primaryOpp = parentOpp; 
        childoppList = childoppsList;
        recordIds = childOppIds; 
    }
    public void execute(QueueableContext context){
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
        Map<Id,Decimal> oppIdToTotalPrice = new Map<Id,Decimal>();
        List<OpportunityLineItem> parentOppLinesList = new List<OpportunityLineItem>();
        Set<Id> OppIdSet = new Set<Id>();
        
        if(!recordIds.isEmpty()){
            Id parentOppId = primaryOpp.Id;
            list<Opportunity> oppList = [SELECT Id,Split_percentage__c from Opportunity where Id IN:recordIds AND Opportunity_Split_Parent__c!=null];
            String strQuery = 'Select Id, ';
            if(primaryOpp.Id != null){
                List<String> lstAllFields = new List<String>(Schema.sObjectType.OpportunityLineItem.fields.getMap().keySet());
                for (OpportunityLineItem objOLI : database.query('Select ' + String.join(lstAllFields, ',') + ' FROM ' + 'OpportunityLineItem' + ' WHERE OpportunityId =:parentOppId')) {
                    if(objOLI.productcode != 'OPTY-SPLIT' && objOLI.Line_Type__c != 'Renewal'){
                        parentOppLinesList.add(objOLI);
                    }
                }
            }
            if(!parentOppLinesList.isEmpty()){
                for(Opportunity opp:oppList){
                    for(OpportunityLineItem vLineItem : parentOppLinesList) {
                        if(vLineItem.ProductCode != 'OPTY-SPLIT' && vLineItem.Line_Type__c != 'Renewal'){
                            OpportunityLineItem clonedLineItem = vLineItem.clone(false, true, false, false);
                            clonedLineItem.OpportunityId= opp.Id;
                            clonedLineItem.Product2Id = vLineItem.Product2Id;
                            clonedLineItem.Parent_split_Opplineitem_Id__c = vLineItem.Id;
                            clonedLineItem.UnitPrice = null;
                            clonedLineItem.Quantity = vLineItem.Quantity;
                            clonedLineItem.Applied_Split__c = opp.Split_percentage__c;
                            clonedLineItem.Line_Type_Text__c = vLineItem.Line_Type__c;
                            clonedLineItem.SBQQ__QuoteLine__c = null;
                            OppIdSet.add(opp.Id);
                            lineItems.add(clonedLineItem);
                        }
                    }
                }
            }
            for(Opportunity opp:childoppList){
                if(opp.Id != primaryOpp.Id && opp.Split_percentage__c!=null){
                    oppIdToTotalPrice.put(opp.Id,(primaryOpp.Amount * opp.Split_percentage__c)/100.00);
                }
            }
            for(OpportunityLineItem lineItem:lineItems){
                if (lineItem.OpportunityId != primaryOpp.Id && lineItem.ProductCode != null && lineItem.ProductCode != 'OPTY-SPLIT' && oppIdToTotalPrice.containsKey(lineItem.OpportunityId)){
                    Decimal totalPrice = oppIdToTotalPrice.get(lineItem.OpportunityId);
                    totalPrice -= lineItem.TotalPrice;
                    oppIdToTotalPrice.put(lineItem.OpportunityId,totalPrice);
                }
            }
            for(OpportunityLineItem lineItem:lineItems){
                if ((lineItem.ProductCode == 'OPTY-SPLIT') && oppIdToTotalPrice.containsKey(lineItem.OpportunityId)){
                    //lineItem.Applied_Split__c = null;
                    lineItem.TotalPrice = oppIdToTotalPrice.get(lineItem.OpportunityId);
                    
                }
            }
            FlowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = false;
            if(!lineItems.isEmpty()){
                insert lineItems;
                OppAnnualContractValueUtil.calculateAcvAmount(OppIdSet);
            }
            FlowControll.opportunityTriggerHandler = true;
            flowControll.opportunityLineItemHandler = true;
            OppAnnualContractValueUtil.OppACVRecursion = false;
        }
    }
}