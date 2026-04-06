/**
 * @author Sushant Arora
 * @date 2024-11-19
 * @description This controller fetches and processes Case data along with related Risk Profile PDM Features.
 * @TestClass - CaseRetentionControllerTest
 */

public class CS_CaseRetentionController {
    
    public String recordId { get; set; }
    
    /**
     * @description Default constructor to initialize the record ID from the current page parameters.
     */
    public CS_CaseRetentionController() {
        recordId = ApexPages.currentPage().getParameters().get('recordId');
    }
    
    /**
     * @description Fetches a Case record and its related Risk Profile PDM Features wrapped in a CasePDMWrapper object.
     * @param caseId The ID of the Case record to fetch.
     * @return CasePDMWrapper A wrapper containing the Case record and related Risk Profile PDM Features.
     */
    @AuraEnabled
    public static CasePDMWrapper getRetentionCaseRecord(Id caseId) {
        
        Case caseRecord = [ 
            SELECT Id, Owner.Name, CaseNumber, Account.Name, CreatedDate, Contact.Name, 
            Workaround_Provided__c, Status, Risk_Status__c,
            Risk_Profile__r.Risk_Status__c, Risk_Profile__r.Governance_Owner__c, Phase__c,
            Sub_Phase__c, Risk_Profile__r.Name, Risk_Profile__r.Risk_Type__c,
            Risk_Profile__r.Entitlement__c,Risk_Profile__r.Entitlement__r.Name, Risk_Profile__r.Entitlement_ACV__c,
            Risk_Profile__r.Entitlement_Expiry_Date__c,Risk_Profile__r.Owner.Name,OwnerId,
            ACV_At_Risk__c,ACV_mitigated__c, Risk_Opportunity__r.Name,
            Subject, Description,Resolution__c, Resolution_Details__c,Current_Status_Next_Steps__c,
            Mitigation_Case_Closed__c
            FROM Case 
            WHERE Id = :caseId 
            LIMIT 1 
        ];
        List<Risk_Profile_PDM_Feature__c> pdmFeatureRecord = new List<Risk_Profile_PDM_Feature__c>();
        List<Risk_Profile_Entitlement__c> riskProfileEntitlements = new List<Risk_Profile_Entitlement__c>();
        if(caseRecord?.Risk_Profile__c != null){
            pdmFeatureRecord = [ 
                SELECT Id, Name, Feature__c 
                FROM Risk_Profile_PDM_Feature__c
                WHERE Risk_Profile__c = :caseRecord.Risk_Profile__c
            ];
            riskProfileEntitlements = [
                SELECT Id,Entitlement__c, Entitlement__r.Name, Entitlement__r.AnnualContractValue__c , Entitlement__r.EndDate
                FROM Risk_Profile_Entitlement__c
                WHERE Case__c = :caseId
                AND Risk_Profile__c = :caseRecord.Risk_Profile__c
            ];
        }
        return new CasePDMWrapper(caseRecord, pdmFeatureRecord, riskProfileEntitlements);
    }
    /**
     * @description Wrapper class to hold a Case record and its related Risk Profile PDM Features.
     */
    public class CasePDMWrapper {
        /**
        * @description The Case record associated with this wrapper, exposed to LWC or Aura components.
        */
        @AuraEnabled public Case caseRecord { get; set; }
        /**
        * @description List of related Risk Profile PDM Feature records, exposed to LWC or Aura components.
        */
        @AuraEnabled public List<Risk_Profile_PDM_Feature__c> pdmFeatureRecord { get; set; }
        /**
        * @description List of related Risk Profile Entitlement records, exposed to LWC or Aura components.
        */
        @AuraEnabled public List<Risk_Profile_Entitlement__c> riskProfileEntitlements { get; set; }
        
        /**
         * @description Constructor to initialize the CasePDMWrapper with a Case record, 
         *              related PDM Features, and Risk Profile Entitlements.
         * @param caseRecord The Case record to wrap.
         * @param pdmFeatureRecord The list of related Risk Profile PDM Features.
         * @param riskProfileEntitlements The list of related Risk Profile Entitlement records.
         */
        public CasePDMWrapper(Case caseRecord, List<Risk_Profile_PDM_Feature__c> pdmFeatureRecord, List<Risk_Profile_Entitlement__c> riskProfileEntitlements) {
            this.caseRecord = caseRecord;
            this.pdmFeatureRecord = pdmFeatureRecord;
            this.riskProfileEntitlements = riskProfileEntitlements;
        }
    }
}