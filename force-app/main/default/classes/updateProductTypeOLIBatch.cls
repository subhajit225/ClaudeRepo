global class updateProductTypeOLIBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Map<Id,string> prodIdTypeMap = new Map<Id,string>();
    public Set<Id> prodIdSet = new Set<Id>();
    public List<Custom_Error_Log__c> customErrorList = new List<Custom_Error_Log__c>();
    public updateProductTypeOLIBatch(){
        Map<Id,product2history> prodHisMap = new Map<Id,product2history>();
        String prodType = 'Product_Type__c';
        Set<Id> phIdSet = new Set<Id>();
        
        for(product2history ph : [SELECT Product2Id, OldValue, NewValue, Id, Field From product2history where Field =:prodType AND CreatedDate = LAST_N_DAYS:2  order by CreatedDate asc]){
            prodHisMap.put(ph.Product2Id,ph);
        }
        for(Id prodId : prodHisMap.keySet()){
            phIdSet.add(prodHisMap.get(prodId).Id);
        }
        
        if(!phIdSet.isEmpty()){
            for(product2history ph : [SELECT Product2Id, OldValue, NewValue, Id, Field From product2history where Id IN:phIdSet]){
                prodIdTypeMap.put(ph.Product2Id,String.valueOf(ph.NewValue));
                prodIdSet.add(ph.Product2Id);
            }   
        }
    }
    global Database.queryLocator start(Database.BatchableContext batchContext){
        //SAL23-947 Start
        List<String> closedStage= new List<String>{'7 Closed Won','7 Closed Lost','7 Closed Admin'};
        String queryStr = 'select Id, Product2.Support_Type__c, Support_Type__c,Product2.Product_Type__c, Prod_Type__c,Product2Id,OpportunityId,Opportunity.StageName from OpportunityLineItem where Opportunity.StageName NOT IN :closedStage  AND ((((Support_Type__c = null  AND Product2.Support_Type__c!= null ) OR (Prod_Type__c = null AND Product2.Product_Type__c!= null))AND CreatedDate = LAST_N_DAYS:2) OR Product2Id IN:prodIdSet)';
        //SAL23-947 End
        return Database.getQueryLocator(queryStr); 
    }
    global void execute(Database.BatchableContext batchContext, List<OpportunityLineItem> queriedOliList){
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        if(!prodIdTypeMap.isEmpty() || !queriedOliList.isEmpty()){
            for(OpportunityLineItem oli : queriedOliList){
                    //SAL23-947 Start
                if((prodIdTypeMap.containsKey(oli.Product2Id) && oli.Prod_Type__c != prodIdTypeMap.get(oli.Product2Id))||(oli.Support_Type__c == null  || oli.Prod_Type__c == null)){
                    if(prodIdTypeMap.containsKey(oli.Product2Id) && oli.Prod_Type__c != prodIdTypeMap.get(oli.Product2Id))
                        oli.Prod_Type__c = prodIdTypeMap.get(oli.Product2Id);
                    if(oli.Support_Type__c==null && oli.Product2.Support_Type__c !=null)
                        oli.Support_Type__c=oli.Product2.Support_Type__c;
                    if(oli.Prod_Type__c==null && oli.Product2.Product_Type__c != null)
                        oli.Prod_Type__c=oli.Product2.Product_Type__c; 
                    oliList.add(oli);
                }
                //SAL23-947 End
            }
        }
        if(!oliList.isEmpty()){
            flowControll.opportunityTriggerHandler = false;
            flowControll.opportunityLineItemHandler = false;
            List<Database.SaveResult> srList = Database.update(oliList,false);
            List<Custom_Error_Log__c> errorLogList = LogError.createDMLErrorLogWithRetrunType((List<SObject>)oliList, srList, 'updateProductTypeOLIBatch','Update Product Type OLI Batch'); //SAL25-717 
            customErrorList.addAll(errorLogList); //SAL25-717 
        }
    }
    global void finish(Database.BatchableContext batchContext){
        /* Start SAL25-717 */
        if(!customErrorList.isEmpty()){
            string emailDetail = EmailHelper.prepareEmailBodyForCustomErrorLog(customErrorList);
            EmailHelper.sendBatchErrorsEmail(new List<String>{System.Label.SalesApps_Support_Email},
                                            'updateProductTypeOLIBatch - ' + Date.today().format(),
                                            emailDetail); 
        }
        /* End SAL25-717 */
    }
}