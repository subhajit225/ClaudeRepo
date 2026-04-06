/**
 * Author           :   Saakshi Gupta
 * Created Date     :   25-01-2021
 * Description      :   Apex controller for caseAuditFormLwc Lightning Web component
 * Test Class       :   CaseAuditFormControllerTest
 */
public without sharing class CaseAuditFormController {

    /**
     * Author           :   Saakshi Gupta
     * Created Date     :   25-01-2021
     * Description      :   This method fetches the case record associated with the passed Case Id
     */
    @AuraEnabled(cacheable=true)
    public static Case getCaseAndCaseAuditRecord(Id caseId) {
        return [SELECT Id, CaseNumber, OwnerId, Owner.Name, Owner_s_Manager__c, Owner_s_Manager_s_Manager__c,
                    (SELECT Id, Case__c, Case_Audit_Timestamp__c, Auditor_Comments__c, Case_Auditor__c,
                    Case_Documentation__c, Case_Owner_s_Manager__c, Send_Email_to_Case_Owner_s_Manager__c,
                    Case_Field_Classification__c, Case_Owner__c, Final_Audit_Score__c, Overall_Case_management__c,
                    Resolution__c, Case_Owner_s_Manager_s_Manager__c FROM Case_Audits__r)
                FROM Case
                WHERE Id =: caseId];
    }
}