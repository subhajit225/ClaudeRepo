/**
* @File Name : AccountDiscountHistoryUtility.cls
* @description : FY26WL-506 , FY26WL-507, FY26WL-508, FY26WL-588 - Account Discount History implementation
* @Author : Deepak Verma
* @Last Modified By : Deepak Verma 
* @Last Modified On :  january 19, 2026
* @Modification Log :
* Test Class : 
*************************************************************************************************/
public without sharing class AccountDiscountHistoryUtility {
    
    Map<String, Account_Discount_History__c> prodIdAccDisHistoryMap = new Map<String, Account_Discount_History__c>();
    Map<String, Entitlement> renewedEntitlementMap = new Map<String, Entitlement>();
    Set<Id> prodIdSet = new Set<Id>();
    
    /** 
* @description Apex method to handle create Update Account Discount history 
* @param closeWonOppSet
* @return Map of Product Id to Account Discount History record
* This method contains account discount history calculation.
*/
    
    public Map<String, Account_Discount_History__c> createUpdateAccountDiscountHistory(Set<Id> closeWonOppSet){            
        Set<Id> accIdSet = new Set<Id>();
        Set<String> ADH_Out_of_Scope_ProductSet = new Set<String>();
        ADH_Out_of_Scope_ProductSet.addAll(System.Label.ADH_Out_of_Scope_Product.split(';'));
        
        // Retrieve the query conditions from the custom label
        String queryConditions = System.Label.ADH_Quoteline_Query_Condition;
        
        // Retrieve the Run_for_All_Optys custom label
        String runForAllOptys = System.Label.Run_for_All_Optys;
        
        String dynamicQuery;
        if (runForAllOptys == 'Yes') {
            
            for(Opportunity opp : [Select AccountId, id from Opportunity where Id IN :closeWonOppSet]){
                accIdSet.add(opp.AccountId);
            }
            dynamicQuery = 
                'SELECT Id,SBQQ__ProductCode__c, SBQQ__Quote__c, SBQQ__Quantity__c, SBQQ__Product__c, SBQQ__Discount__c,SBQQ__Quote__r.SBQQ__Opportunity2__c,' +
                'SBQQ__Quote__r.SBQQ__Account__c, ACV__c, SBQQ__ListTotal__c, List_Total__c, Net_Unit_Price__c, SBQQ__SubscriptionTerm__c ' +
                'FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Opportunity2__r.AccountId IN :accIdSet  ' +
                queryConditions + 
                ' AND Product_Type__c NOT IN :ADH_Out_of_Scope_ProductSet ';
        }  if (runForAllOptys == 'No'){
            dynamicQuery = 
                'SELECT Id,SBQQ__ProductCode__c, SBQQ__Quote__c, SBQQ__Quantity__c, SBQQ__Product__c, SBQQ__Discount__c,SBQQ__Quote__r.SBQQ__Opportunity2__c,' +
                'SBQQ__Quote__r.SBQQ__Account__c, ACV__c, SBQQ__ListTotal__c, List_Total__c, Net_Unit_Price__c, SBQQ__SubscriptionTerm__c ' +
                'FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c IN :closeWonOppSet ' +
                queryConditions + 
                ' AND Product_Type__c NOT IN :ADH_Out_of_Scope_ProductSet ';
        }
        
        List<SBQQ__QuoteLine__c> qlList = Database.query(DynamicQuery);
        if(qlList != null && !qlList.isEmpty()){
            for(SBQQ__QuoteLine__c ql : qlList){
                accIdSet.add(ql.SBQQ__Quote__r.SBQQ__Account__c);
                String key = ql.SBQQ__Quote__r.SBQQ__Account__c + '_' + ql.SBQQ__Product__c;
                createUpdateADHRec(key,ql);
                prodIdSet.add(ql.SBQQ__Product__c);
            } 
        }
        for(Entitlement ent : [SELECT Id, Product__c , AccountId FROM Entitlement WHERE Product__c IN :prodIdSet 
                               AND AccountId IN :accIdSet
                               AND Renewal_Category__c = 'Renewed']){
                                   String key = ent.AccountId + '_' + ent.Product__c;
                                   if(!renewedEntitlementMap.containsKey(key)){
                                       renewedEntitlementMap.put(key, ent);
                                   }
                               }
        for(Account_Discount_History__c adh : [SELECT Id,Has_Been_Renewed__c, Account__c, Product__c,
                                               Quantity__c, NE_ACV_Total__c, Avg_Expansion_Discount__c, Total_List_Price__c, 
                                               Total_Price_after_Add_Discount__c
                                               FROM Account_Discount_History__c
                                               WHERE Account__c IN : accIdSet AND Product__c IN : prodIdSet]){
                                                   
                                                   
                                                   String key = adh.Account__c + '_' + adh.Product__c;
                                                   prodIdAccDisHistoryMap.put(key, mergeADH(key,adh));
                                                   
                                               }
        updateADHWithAggregates();
        return prodIdAccDisHistoryMap;
    }
    /** 
* @description Apex method to handle create Update Account Discount history with aggregation details 
* This method contains account discount history calculation.
*/
    public void updateADHWithAggregates(){
        
        for(String key : prodIdAccDisHistoryMap.keyset()){
            Account_Discount_History__c adhRec = prodIdAccDisHistoryMap.get(key);
            
            adhRec.Avg_Expansion_Discount__c = ((adhRec.Total_List_Price__c-adhRec.Total_Price_after_Add_Discount__c)/adhRec.Total_List_Price__c)*100;
            adhRec.Has_Been_Renewed__c = renewedEntitlementMap.containsKey(key);
            
            prodIdAccDisHistoryMap.put(key,adhRec);
        }
    }
    /** 
* @description Apex method to handle create Update Account Discount history 
* @param key
* @param ql
* This method contains account discount history calculation.
*/
    public void createUpdateADHRec(String key , SBQQ__QuoteLine__c ql){
        
        decimal discountVal = ql.SBQQ__Discount__c != null ? 100-(ql.SBQQ__Discount__c):100;
        
        if(!prodIdAccDisHistoryMap.isEmpty() && prodIdAccDisHistoryMap.containsKey(key)){
            Account_Discount_History__c adhRec = prodIdAccDisHistoryMap.get(key);
            
            adhRec.NE_ACV_Total__c += (ql.ACV__c != null ? ql.ACV__c : 0);
            adhRec.Total_List_Price__c += ql.SBQQ__ListTotal__c;
            adhRec.Quantity__c += ql.SBQQ__Quantity__c;
            adhRec.Total_Price_after_Add_Discount__c += ((ql.SBQQ__ListTotal__c * discountVal)/100);
            prodIdAccDisHistoryMap.put(key, adhRec);
            
        }else{
            Account_Discount_History__c adhRec = new Account_Discount_History__c();
            
            adhRec.Account__c = ql.SBQQ__Quote__r.SBQQ__Account__c;
            adhRec.Product__c = ql.SBQQ__Product__c;
            adhRec.Product_Code__c = ql.SBQQ__ProductCode__c;
            adhRec.NE_ACV_Total__c = ql.ACV__c != null ? ql.ACV__c : 0;
            adhRec.Total_List_Price__c = ql.SBQQ__ListTotal__c;
            adhRec.Quantity__c = ql.SBQQ__Quantity__c;
            adhRec.Total_Price_after_Add_Discount__c = (ql.SBQQ__ListTotal__c * discountVal)/100;
            prodIdAccDisHistoryMap.put(key, adhRec); 
        }
    }
    /** 
* @description Apex method to handle create Update Account Discount history 
* @return Account_Discount_History__c
* @param key
* @param adh
* This method contains account discount history calculation.
*/
    public Account_Discount_History__c mergeADH(String key , Account_Discount_History__c adh){
        Account_Discount_History__c adhRec = prodIdAccDisHistoryMap.get(key);
        
        if(System.Label.Run_for_All_Optys == 'No' || Test.isRunningTest()){
            //if(!System.isBatch()){
            adhRec.NE_ACV_Total__c += adh.NE_ACV_Total__c;
            adhRec.Total_List_Price__c += adh.Total_List_Price__c;
            adhRec.Quantity__c += adh.Quantity__c;
            adhRec.Total_Price_after_Add_Discount__c += adh.Total_Price_after_Add_Discount__c;
        }
        adhRec.ID = adh.ID;
        return adhRec;
    }
    
}