global class RSCEntitlementCreationBatch implements Database.Batchable<sObject>,Database.Stateful, Schedulable
{
    private Boolean callFirstTime = false;
    global List<string> accEmailLst = new List<string>();
    public RSCEntitlementCreationBatch(Boolean callValue) {
        callFirstTime = callValue;
    }
    global Database.QueryLocator start(Database.BatchableContext BC)
    {        
        // String fetchAccount = 'Select id,name,Primary_Contact_Email__c,(Select Id,Is_RWD_Polaris_Quote__c from orders where Is_RWD_Polaris_Quote__c = true),(select id,Type,Status, StartDate, EndDate from Entitlements where Status=\'Active\' limit 200) from Account  where (type=\'Customer\' OR type=\'MSP Customer\') LIMIT 100';// 
        String fetchAccount = 'Select id, name, Primary_Contact_Email__c from Account  where (type=\'Customer\' OR type=\'MSP Customer\')';
        return Database.getQueryLocator(fetchAccount);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) 
    {	
        List<Entitlement> entitlementList = new List<Entitlement>();
        boolean RSCexists = false;
        boolean checkOrderHasv2Sku = false;
        Set<Id> accountsWithOrder = new Set<Id>();
        Set<Id> accountsWithRSC = new Set<Id>();
        Map<Id, List<Entitlement>> accwithEntitlements = new Map<Id, List<Entitlement>>();
        Date rscStartDate = Date.newInstance(2022,8,15);
        Order_control__mdt mc = Order_control__mdt.getInstance('RSC_Start_Date');
        if(mc != null){
            rscStartDate = Date.valueOf(mc.Value__c);
        }
        for(Order ord : [SELECT Id, Is_RWD_Polaris_Quote__c, AccountId 
                         FROM order 
                         WHERE Is_RWD_Polaris_Quote__c = true AND AccountId IN :scope]){
                             accountsWithOrder.add(ord.AccountId); 
                         }
        for(Entitlement ent : [SELECT id, Type, Status, StartDate, EndDate, AccountId, RSC_Status__c, Product__c,
                               Product__r.Product_Type__c, Product__r.Product_Level__c,
                               Order_Service_Item__r.order.Order_Sub_Type__c, Order_Service_Item__r.order.Is_RWD_Polaris_Quote__c
                               FROM Entitlement 
                               WHERE (Status='Active' OR Type = 'RSC') AND AccountId IN :scope]){
                                   if(accwithEntitlements.containsKey(ent.AccountId)){
                                       accwithEntitlements.get(ent.AccountId).add(ent);
                                   }else{
                                       accwithEntitlements.put(ent.AccountId, new List<Entitlement>{ent});
                                   }
                                   if(ent.Type == 'RSC'){
                                       accountsWithRSC.add(ent.AccountId);
                                   }
                               }
        for(Account accRecord : scope){
            RSCexists = false;
            checkOrderHasv2Sku = false;
            Entitlement rscEntitlement = new Entitlement();
            if(accountsWithOrder.contains(accRecord.Id)){
                checkOrderHasv2Sku = true;
            }
            Date maxEndDate ;
            Date maxEndDateforUpdate ;
            if(accwithEntitlements.containsKey(accRecord.Id)){
                if(accountsWithRSC.contains(accRecord.Id)){
                    RSCexists = true;
                }
                for(Entitlement entRec : accwithEntitlements.get(accRecord.Id)){
                    
                    if(entRec.Type == 'RSC'){
                        rscEntitlement = entRec;
                    }
                    if(!RSCexists && entRec.Type=='Phone Support' && entRec.Status == 'Active' && entRec.EndDate != null){
                        if(maxEndDate == null)
                            maxEndDate = entRec.EndDate;
                        else
                            maxEndDate = maxEndDate > entRec.EndDate ? maxEndDate : entRec.EndDate;
                    }
                    if(RSCexists && entRec.Type=='Phone Support' && entRec.Status == 'Active' && entRec.EndDate != null && 
                       entRec.Order_Service_Item__r.order.Order_Sub_Type__c == 'renewal' && entRec.Order_Service_Item__r.order.Is_RWD_Polaris_Quote__c &&
                       ((entRec.Product__r.Product_Type__c == 'HW Support' || entRec.Product__r.Product_Type__c == 'RCDM Support' ) && entRec.Product__r.Product_Level__c == 'Support')){
                          if(maxEndDateforUpdate == null)
                            maxEndDateforUpdate = entRec.EndDate;
                        else
                            maxEndDateforUpdate = maxEndDateforUpdate > entRec.EndDate ? maxEndDateforUpdate : entRec.EndDate;
                       }
                }
                
                if(maxEndDate != null && maxEndDate > rscStartDate && 
                   ((!RSCexists && !checkOrderHasv2Sku && !callFirstTime) || 
                    (callFirstTime  && !RSCexists))){
                        accEmailLst.add(accRecord.Primary_Contact_Email__c);
                        Entitlement newEntitlementRecord = new Entitlement();
                        newEntitlementRecord.Name = 'RSC';
                        newEntitlementRecord.Type = 'RSC';
                        newEntitlementRecord.AccountId = accRecord.Id;
                        newEntitlementRecord.StartDate = rscStartDate;
                        newEntitlementRecord.EndDate = maxEndDate;
                        entitlementList.add(newEntitlementRecord);
                    } else if(RSCexists && !callFirstTime && rscEntitlement.EndDate < Date.newInstance(2023,1,31) &&
                              rscEntitlement.EndDate < maxEndDateforUpdate && rscEntitlement.RSC_Status__c != 'Success'){
                                  rscEntitlement.EndDate = maxEndDateforUpdate;
                                  entitlementList.add(rscEntitlement);
                              }
            }
        }
        
        if(entitlementList.size() > 0){
            upsert entitlementList;
        }
    }  
    global void finish(Database.BatchableContext BC)
    {
       
    }
    public void execute(SchedulableContext SC) {
        RSCEntitlementCreationBatch bat = new RSCEntitlementCreationBatch(false);
        database.executeBatch(bat, 5);
    }
}