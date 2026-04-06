public class salesSplitPopulateAppliedsplitController implements Queueable{
    public List<Opportunity> OpportunityList;
    public salesSplitPopulateAppliedsplitController(List<Opportunity> updateOpt){
        OpportunityList = new List<Opportunity>();
        OpportunityList = updateOpt;
    }
    public void execute(QueueableContext context){
        Set<Id> oppLineItemIds = new Set<Id>();
        List<Opportunitylineitem> opplineitemList = new List<Opportunitylineitem>();
        if(!OpportunityList.isEmpty()){
            for(Opportunitylineitem oli : [select Id,Productcode, Line_Type__c, Applied_Split__c, OpportunityId, Opportunity.Split_Percentage__c 
                                           from opportunitylineitem where
                                           OpportunityId IN:OpportunityList])
            {
                if(oli.Productcode != 'OPTY-SPLIT' && oli.Line_Type__c != 'Renewal' && oli.Applied_Split__c != oli.Opportunity.Split_Percentage__c)
                {
                    oli.Applied_Split__c = oli.Opportunity.Split_Percentage__c;
                }
                opplineitemList.add(oli);
                oppLineItemIds.add(oli.Id);
            }
        }
        if(!opplineitemList.isEmpty()){
            flowcontroll.opportunityTriggerHandler = false;
            flowcontroll.opportunityLineItemHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = true;
            update opplineitemList;
            OppAnnualContractValueUtil.OppACVRecursion = false;
            flowcontroll.opportunityTriggerHandler = true;
            flowcontroll.opportunityLineItemHandler = true;
        }
    }
}