/**
 * @description created as part of SAL26-1326, calculate CLOUD/NCD ACV based on RCV sku and Account customer type field
 */ 
public class OpportunityACVCalculationsQueueable implements Queueable {
    
    public Set<Id> recordIdsSet;
    /**
     * @description constructor to invoke class
     * @param recordIdsSet set of account ids or opportunity ids - whose Customer Type/PLS AE ETM Role Name is changed
     */ 
    public OpportunityACVCalculationsQueueable(Set<Id> recordIdsSet) {
        this.recordIdsSet = recordIdsSet;
    }
    
    /**
     * @description execute method of queueable 
     * @param context
     */ 
    public void execute(QueueableContext context) {
        
        List<Product_Hierarchy_Group_mapping__mdt> prodHierarchyGrpLst = [SELECT PLS_NE_ACV_Sales_Comp__c 
                                                                          FROM Product_Hierarchy_Group_mapping__mdt 
                                                                          WHERE Bucket__c IN ('Cloud Consumption', 'NAS NCD')];
        Set<String> cloudNcdSalesCompCatSet = new Set<String>();
        for(Product_Hierarchy_Group_mapping__mdt phg : prodHierarchyGrpLst){
            cloudNcdSalesCompCatSet.addAll(phg.PLS_NE_ACV_Sales_Comp__c.split(','));
        }
        
        //get opportunities linked to recordIdsSet
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, AccountId, Account.Customer_Type_Without_RCV__c, Split_percentage__c, Co_Owner__c, NCD_Co_Owner__c,
                                                                PLS_NCD_New_Expansion_ACV__c, Core_New_Expansion_ACV__c, SaaS_New_Expansion_ACV__c, NAS_New_Expansion_ACV__c, PLS_New_Expansion_ACV__c, 
                                                                (SELECT Id, Sales_Comp_Category__c, Core_New_Expansion_ACV__c, SaaS_New_Expansion_ACV__c, NAS_New_Expansion_ACV__c, 
                                                                 PLS_New_Expansion_ACV__c, PLS_NCD_New_Expansion_ACV__c, New_Expansion_ACV__c FROM OpportunityLineItems 
                                                                 WHERE productCode != 'OPTY-SPLIT' AND Line_Type__c = 'New' AND Sales_Comp_Category__c LIKE '%RCV%' AND New_Expansion_ACV__c > 0)
                                                                FROM Opportunity 
                                                                WHERE IsClosed = false AND Opportunity_Type__c != 'Debooking'
                                                                AND (UCL_Scale_Percentage__c = null OR UCL_Scale_Percentage__c = 0)
                                                                AND Id IN (SELECT opportunityId FROM OpportunityLineItem WHERE Sales_Comp_Category__c LIKE '%RCV%')
                                                                AND Id NOT IN (SELECT opportunityId FROM OpportunityLineItem WHERE Sales_Comp_Category__c IN :cloudNcdSalesCompCatSet)
                                                                AND (AccountId IN :recordIdsSet OR Id IN :recordIdsSet)]);
        
        List<OpportunityLineItem> oppLinesToUpdate = new List<OpportunityLineItem>();
        List<Opportunity> oppLstToUpdate = new List<Opportunity>();
        Boolean updateOpp = false;
        for(Opportunity opp : oppMap.values()){
            updateOpp = false;
            opp.PLS_NCD_New_Expansion_ACV__c = opp.NAS_New_Expansion_ACV__c = opp.PLS_New_Expansion_ACV__c = opp.Core_New_Expansion_ACV__c = 0; //set NCD/CLOUD/PLS/Core acv to 0
            for(OpportunityLineItem oli : opp.OpportunityLineItems){
                updateOpp = true;
                OppAnnualContractValueUtil.assignRCVSkuAcv(opp, oli); //populate CLOUD/NCD/Core acv 
                oppLinesToUpdate.add(oli);
                if(opp.Split_percentage__c == null || opp.Split_percentage__c == 0) opp.Split_percentage__c = 100;
                opp.PLS_NCD_New_Expansion_ACV__c += oli.PLS_NCD_New_Expansion_ACV__c*opp.Split_percentage__c/100;
                opp.NAS_New_Expansion_ACV__c += oli.NAS_New_Expansion_ACV__c*opp.Split_percentage__c/100;
                opp.PLS_New_Expansion_ACV__c += oli.PLS_New_Expansion_ACV__c*opp.Split_percentage__c/100;
                opp.Core_New_Expansion_ACV__c += oli.Core_New_Expansion_ACV__c*opp.Split_percentage__c/100;
            }
            if(updateOpp){
                oppLstToUpdate.add(opp);
            }
        }
        if(!oppLinesToUpdate.isEmpty()){
            flowControll.opportunityLineItemHandler = false;
            UPDATE oppLinesToUpdate;
        }
        if(!oppLstToUpdate.isEmpty()){
            FlowControll.opportunityTriggerHandler = false;
            UPDATE oppLstToUpdate;
        }
    }
}