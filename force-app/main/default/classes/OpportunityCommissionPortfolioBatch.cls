public with sharing class OpportunityCommissionPortfolioBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    public Database.queryLocator start(Database.BatchableContext batchContext){
        Set<String> stageNameSet = new Set<String>{'7 Closed Won'};
        //Date startDate = Date.newInstance(2020, 2, 1);
        //Date endDate = Date.newInstance(2020, 10, 31);
        //String queryStr = 'SELECT Id FROM Opportunity WHERE StageName in :stageNameSet and Time_of_Last_Stage_Change__c >= :startDate ';
        //if(Test.isRunningTest())
        String queryStr = 'SELECT Id FROM Opportunity WHERE StageName in :stageNameSet and Time_of_Last_Stage_Change__c = YESTERDAY';
        return Database.getQueryLocator(queryStr); 
    }
    /**Update Opportunity, set Commission Portfolio Type as per below conditions:
     * Rule ranking		Commission Portfolio Type	 : 	Product attributes/Oppty attribute/Order attributes/Quote attribute
        1	 : 	Renewal	 : 	Oppty subtype = 'Renewal"
        2	 : 	MSP Consumption	 : 	order type = MSP Consumption"
        3	 : 	MSP Actual	 : 	order type = MSP Overage"
        4	 : 	Rubrik Go	 : 	Any Product: sub type= 'GO'
        5	 : 	Rubrik Complete	 : 	Product: sub type = 'Complete'
        6	 : 	LOD	 : 	Primary quote line "Licensing Type = Perpetual" 
        7	 : 	HW/PIT	 : 	Product Type equals “accessories,spares”
        8	 : 	HYB Bundle	 : 	product name contain “hyb”
        9	 : 	Pro Bundle	 : 	Product name contain “Sub-pro”, “Pro-bundle”
        10	 : 	Scale Order	 : 	oppty contains product "SCALE"?
        11	 : 	SaaS/Support Only	 : 	Product: item type = 'Non inventory" and oppty sub type is not "Renewal" and all the order lines with start and end date
        12   :  HW/PIT : Product: item type = 'Non inventory" and oppty sub type is not "Renewal" and if there is any line for Professional Services(Product_Type__c in ( 'Consulting','Training','Travel & Expense')
        99	 : 	Other	 : 	NA
            : 	Rubrik Business Edition	 : 	TBD
     */
    public void execute(Database.BatchableContext batchContext, List<Opportunity> oppList){
        system.debug('oppList**'+ oppList);
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Order> orderList = [Select ID, OpportunityId, (Select id, ServiceDate, EndDate from OrderItems where Product2.Item_Type__c = 'Non-inventory Item' AND (Support_Start_Date__c = null OR Support_End_Date__c = null)) from Order WHERE OpportunityId IN :oppList AND Opportunity.Opportunity_Sub_Type__c != 'Renewal'];
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>([Select ID, Commission_Portfolio_Type__c, StageName, Opportunity_Type__c, Opportunity_Sub_Type__c, Order_Sub_Type__c , SBQQ__PrimaryQuote__c,
                (Select ID, Product2.Name, Product2.Item_Type__c, Product2.Product_Type__c, Product2.Product_Subtype__c, Product2.License_Type__c, SBQQ__QuoteLine__r.Licensing_Model__c from OpportunityLineItems) 
            from Opportunity where ID in :oppList]);
        Set<ID> oppIdSetWithNullStartEndDate = new Set<ID>();
        for(Order orderObj : orderList){
            if(!orderObj.OrderItems.isEmpty()){
                oppIdSetWithNullStartEndDate.add(orderObj.OpportunityId);
            }
        }
        for(Opportunity opp : oppMap.values()){
            if(isCommissionPortfolioTypeChanged(opp, oppIdSetWithNullStartEndDate)){
                oppListToUpdate.add(opp);
            }
        }
        if(!oppListToUpdate.isEmpty()){
            FlowControll.opportunityTriggerHandler = false;
            update oppListToUpdate;
        }
        
    }
    
    public static boolean isCommissionPortfolioTypeChanged(Opportunity opp, Set<ID> oppIdSetWithNullStartEndDate){
        boolean isRule6Broken = false;
        List<String> rankWiseCPType = new List<String>{null, null, null, null, null, null, null, null, null, null, null, null, 'Other'};
        if(opp.Opportunity_Sub_Type__c == 'Renewal'){ //1	 : 	Renewal	 : 	Oppty subtype = 'Renewal"
            rankWiseCPType[0] = 'Renewal';
        }else if(opp.Order_Sub_Type__c  == 'MSP Consumption'){//2	 : 	MSP Consumption	 : 	order type = MSP Consumption"
            rankWiseCPType[1] = 'MSP Consumption';
        }else if(opp.Opportunity_Sub_Type__c  == 'MSP Overage'){//3	 : 	MSP Actual	 : 	Opp Sub-type = MSP Overage
            rankWiseCPType[2] = 'MSP Actual';
        }else if(!opp.OpportunityLineItems.isEmpty()){
            for(OpportunityLineItem oli : opp.OpportunityLineItems){
                if(oli.Product2.Product_Subtype__c == 'GO' || oli.Product2.Product_Subtype__c == 'Saas Cloud'){//4	 : 	Rubrik Go	 : 	Any Product: sub type= 'GO'
                    rankWiseCPType[3] = 'Rubrik Go';
                }
                if(oli.Product2.Product_Subtype__c == 'Complete' || oli.Product2.Product_Subtype__c == 'Complete Pro'){//5	 : 	Rubrik Complete	 : 	Product: sub type = 'Complete'
                    rankWiseCPType[4] = 'Rubrik Complete';
                }
                if(oli.SBQQ__QuoteLine__r.Licensing_Model__c == 'Perpetual'){//6	 : 	LOD	 : 	Primary quote line "Licensing Type = Perpetual" 
                    rankWiseCPType[5] = 'LOD';
                }
                if(oli.Product2.Product_Type__c == 'Accessories' || oli.Product2.Product_Type__c ==  'Spares' || oli.Product2.Product_Type__c == 'Consulting'  || oli.Product2.Product_Type__c == 'Training' || oli.Product2.Product_Type__c == 'Travel & Expense'){//7	 : 	HW/PIT	 : 	Product Type equals “accessories,spares”
                    //"Only if all the product's Product Type equals “accessories,spares,Consulting,Training" & no other product added:  
                   if(!isRule6Broken){
                        rankWiseCPType[6] = 'HW/PIT';
                   }
                }else{
                    isRule6Broken = true;
                    rankWiseCPType[6] = null;
                }
                if(oli.Product2.Name.contains('-HYB-')){//8	 : 	HYB Bundle	 : 	product name contain “hyb”
                    rankWiseCPType[7] = 'HYB Bundle';
                }
                if(oli.Product2.Name.contains('-SUB-PRO-') || oli.Product2.Name.contains('-PRO-BUNDLE-')){//9	 : 	Pro Bundle	 : 	Product name contain “Sub-pro”, “Pro-bundle”
                    rankWiseCPType[8] = 'Pro Bundle';
                }
                if(oli.Product2.Name.contains('-SCALE-')){//10	 : 	Scale Order	 : 	oppty contains product "SCALE" Katerina?
                    rankWiseCPType[9] = 'Scale Order';
                }
                if(opp.Opportunity_Sub_Type__c != 'Renewal' && oli.Product2.Item_Type__c == 'Non-inventory Item' && !oppIdSetWithNullStartEndDate.contains(opp.ID)){//11	 : 	SaaS/Support Only	 : 	Product: item type = 'Non inventory" and oppty sub type is not "Renewal" and all the order lines with start and end date
                    rankWiseCPType[10] = 'SaaS/Support Only';
                }
                if( opp.Opportunity_Sub_Type__c != 'Renewal' && oli.Product2.Item_Type__c == 'Non-inventory Item'  && (oli.Product2.Product_Type__c == 'Consulting'  || oli.Product2.Product_Type__c == 'Training' || oli.Product2.Product_Type__c == 'Travel & Expense')){//12    :   Product: item type = 'Non inventory" and oppty sub type is not "Renewal" and if there is any line for Professional Services(Product_Type__c in ( 'Consulting','Training','Travel & Expense')
                    rankWiseCPType[11] = 'HW/PIT';
                }
            }
        }
        for(String commissionPortfolioType: rankWiseCPType){
            if(String.isNotBlank(commissionPortfolioType)){
                if(opp.Commission_Portfolio_Type__c != commissionPortfolioType){
                    opp.Commission_Portfolio_Type__c = commissionPortfolioType;
                    return true;
                }
                break;
            }
        }
        return false;
    }
    public void finish(Database.BatchableContext batchContext){
    }
}