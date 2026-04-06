public without sharing class MIPElementTriggerUtility {
    public MIPElementTriggerUtility(){
    }
    /*public static Map<String,MIP_Rebate_Distribution__mdt> getRebateDistributionConfigs(){
        Map<String,MIP_Rebate_Distribution__mdt> rebateConfigMap = new Map<String,MIP_Rebate_Distribution__mdt>();

        for(MIP_Rebate_Distribution__mdt config : [SELECT ID,Baseline_Percent__c,Rebate_Type__c,Tier_1__c,Tier_2__c,Tier_3__c
                                                    FROM MIP_Rebate_Distribution__mdt]){
            rebateConfigMap.put(config.Rebate_Type__c,config);
        }
        return rebateConfigMap;
    }*/

    /*public static Map<String,MIP_Rebate_Payout__mdt> getRebatePayoutConfigs(){
        Map<String,MIP_Rebate_Payout__mdt> rebatePayoutConfigMap = new Map<String,MIP_Rebate_Payout__mdt>();

        for(MIP_Rebate_Payout__mdt config : [SELECT ID,PSNL_Bookings__c,Rebate_Milestone__c,Rebate_Type__c,Total_Bookings__c
                                            FROM MIP_Rebate_Payout__mdt]){
            rebatePayoutConfigMap.put(config.Rebate_Type__c,config);
        }
        return rebatePayoutConfigMap;
    }*/
}