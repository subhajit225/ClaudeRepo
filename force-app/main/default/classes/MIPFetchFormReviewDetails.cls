public with sharing class MIPFetchFormReviewDetails {
    @AuraEnabled(cacheable=true)
    public static List<MIP_Element__c> getFHRecs(String mipcontractId){
        return [SELECT Id, Partner_Account__r.Name, Name, Payout_Type__c, Head_Count__c, Roles__c, Max_Funded_Head_Payout__c FROM MIP_Element__c WHERE MIP_Contract__c =:mipcontractId AND Element_Type__c = 'Funded Head' LIMIT 20];
    }

    @AuraEnabled(cacheable=true)
    public static List<MIP_Element__c> getRMRecs(String mipcontractId){
        return [SELECT Id, Name, Payout_Type__c, Max_Milestone_Payout__c FROM MIP_Element__c WHERE MIP_Contract__c =:mipcontractId AND Element_Type__c = 'Rebate Milestone' LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static List<MIP_Element__c> getPSNLRecs(String mipcontractId){
        return [SELECT Id, Name, Prior_Year_Bookings_ACV__c, Baseline_Bookings_Expected_Growth__c, Tier_1_Bookings_Expected_Growth__c, Tier_2_Bookings_Expected_Growth__c, Tier_3_Bookings_Expected_Growth__c, 
        Baseline_Bookings_Rebate_Distribution__c, Tier_1_Bookings_Rebate_Distribution__c, Tier_2_Bookings_Rebate_Distribution__c, Tier_3_Bookings_Rebate_Distribution__c FROM MIP_Element__c WHERE MIP_Contract__c =:mipcontractId AND Element_Type__c = 'PSNL Bookings' LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static List<MIP_Element__c> getTotalRecs(String mipcontractId){
        return [SELECT Id, Name, Prior_Year_Bookings_ACV__c, Baseline_Bookings_Expected_Growth__c, Tier_1_Bookings_Expected_Growth__c, Tier_2_Bookings_Expected_Growth__c, Tier_3_Bookings_Expected_Growth__c ,
        Baseline_Bookings_Rebate_Distribution__c, Tier_1_Bookings_Rebate_Distribution__c, Tier_2_Bookings_Rebate_Distribution__c, Tier_3_Bookings_Rebate_Distribution__c FROM MIP_Element__c WHERE MIP_Contract__c =:mipcontractId AND Element_Type__c = 'Total Bookings' LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static List<MIP_Element__c> getEnrollRecs(String mipcontractId){
        return [SELECT Id, Name, Element_Type__c, Enrollment_Payout_Rate__c, Max_Enrollment_Payout__c FROM MIP_Element__c WHERE MIP_Contract__c =:mipcontractId AND Element_Type__c = 'Enrollment' LIMIT 10];
    }

    @AuraEnabled(cacheable=false)
    public static List<MIP_Milestone__c> getMilestoneRecs(String mipElementId, Datetime currentTime){
        return [SELECT Id, Name, Milestone_Type__c, Milestone_Element_Type__c, Quantity__c, Role__c, Status__c, Target_Completion_Date__c FROM MIP_Milestone__c WHERE MIP_Element__c =:mipElementId LIMIT 100];
    }
    
}