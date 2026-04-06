/********************************************************************************
 * @description       : AARLWCController to keep helper methods for AfterActionReviewLWC
 * @created on        : 21-12-2022
 * @created by        : Mustakim S
 * *****************************************************************************
 * History
 * Date                Modification           Author
 * 21-12-2022          SAL23-508              mustakim.shaikh@rubrik.com
 ********************************************************************************/
public with sharing class AARLWCController {
    
    @AuraEnabled
    public static Opportunity getOpportunity(String oppId) {
        Opportunity opp = [SELECT Id, StageName, After_Action_Required__c, After_Action_Form_Submitted__c, ETM_Theatre__c FROM Opportunity WHERE iD = :oppId ];
        
        return opp;
    }

    @AuraEnabled
    public static String getAARrecordTypeId(String region) {
        
        String recordTypeId;
        //String reg = region;

        if(region.startsWith('AMER')) {
            // If the Opportunity is in AMER, use the AMER RecordTypeId
            recordTypeId = Schema.SObjectType.After_Action_Review__c.getRecordTypeInfosByDeveloperName().get('AMER').getRecordTypeId();

        } else {
            // If the Opportunity is in Non-AMER, use the Non-AMER RecordTypeId
            recordTypeId = Schema.SObjectType.After_Action_Review__c.getRecordTypeInfosByDeveloperName().get('Non_AMER').getRecordTypeId();
        }
        
        return recordTypeId;
    }

    
    @AuraEnabled(cacheable=true)
    public static String getAARId(String oppId) {
        String aarId;
        List<After_Action_Review__c> aar = [SELECT Id FROM After_Action_Review__c where Opportunity__c = :oppId ];
        
        if (!aar.isEmpty()) {
            aarId = aar[0].Id;
        }

        return aarId;
    }
}