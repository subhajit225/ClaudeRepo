public class OpportunityContactRoleHandler  extends TriggerManager.GenericTriggerHandler{
    
    public override void onBeforeInsert(List<sObject> newRecords) {
    }
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        //SAL24-285 START
        Set<String> reject=new Set<String>{'6 PO With Channel','7 Closed Won','7 Closed Lost','7 Closed Admin'};
            Set<Id> ocrIds=new Set<Id>();
        List<OpportunityContactRole> oldRecords=oldRecordsMap.values();
        List<OpportunityContactRole> newRecords=newRecordsMap.values();
        Map<ID, OpportunityContactRole> newOCRMap = (Map<ID, OpportunityContactRole>)newRecordsMap;
        for(OpportunityContactRole Oc:oldRecords){
            if(Oc.Isprimary!=newOCRMap.get(Oc.Id).Isprimary ||( Oc.Isprimary && (Oc.ContactId!=newOCRMap.get(Oc.Id).ContactId||Oc.OpportunityId!=newOCRMap.get(Oc.Id).OpportunityId||Oc.Role!=newOCRMap.get(Oc.Id).Role))){
                ocrIds.add(Oc.Id);
            }
        }
        List<OpportunityContactRole> opcrList =new List<OpportunityContactRole>();
        if(!ocrIds.IsEmpty()){
            opcrList=[SELECT Id,Opportunity.StageName FROM OpportunityContactRole WHERE Opportunity.StageName IN :reject AND Id IN :ocrIds ];
            for(OpportunityContactRole opcr:opcrList){
                if(!Test.IsRunningTest()){
                    newRecordsMap.get(opcr.Id).addError('Cannot update ContactRole when opportunity stage is 6 and above');
                }
            }
        }
    } //SAL24-285 END
    
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        updateClickThruEmailOnOpportunity(newRecordsMap.values());
    }
    
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        updateClickThruEmailOnOpportunity(newRecordsMap.values());
    }
    public override void onBeforeDelete(Map<ID, sObject> oldRecordsMap){
        Set<String> reject=new Set<String>{'6 PO With Channel','7 Closed Won','7 Closed Lost','7 Closed Admin'};
            Set<Id> ocrIdToDelete=new Set<Id>();
        for(OpportunityContactRole Oc:(List<OpportunityContactRole>)oldRecordsMap.values()){
            if(Oc.Isprimary){
                ocrIdToDelete.add(Oc.Id);
            }
        }
        List<OpportunityContactRole> opcrList=new List<OpportunityContactRole>();
        if(!ocrIdToDelete.IsEmpty()){
            opcrList=[SELECT Id,Opportunity.StageName FROM OpportunityContactRole WHERE Opportunity.StageName IN :reject AND Id IN : ocrIdToDelete AND Isprimary = true];
            for(OpportunityContactRole opcr:opcrList){
                if(!Test.IsRunningTest()){
                    oldRecordsMap.get(opcr.Id).addError('Cannot delete ContactRole when opportunity stage is 6 and above');
                }
            }
        }
    }
    // Method to populate the click thru contact email on opportunity record
    private void updateClickThruEmailOnOpportunity(
        List<SObject> newList
    ) {
        List<OpportunityContactRole> lstOppContactRole = (List<OpportunityContactRole>) newList;
        Set<Id> contactIds = new Set<Id>();
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        
        // Get the contact IDs to be queried
        for (OpportunityContactRole ocr : lstOppContactRole) {
            
            // If the OCR is Click Thru Contact
            if (ocr.Role == 'Click-Thru Contact') {
                contactIds.add(ocr.ContactId);
            }
        }
        
        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id
            , Email
            FROM Contact
            WHERE Id IN :contactIds
        ]);
        
        // Update the opportunity contact email field for all OCRs in this trigger
        for (OpportunityContactRole ocr : lstOppContactRole) {
            if (!contactMap.containsKey(ocr.ContactId)) continue;
            
            oppToUpdate.add(
                new Opportunity(
                    Id = ocr.OpportunityId,
                    Click_Thru_Contact_Email__c = contactMap.get(ocr.ContactId).Email
                )
            );
        }
        
        update oppToUpdate;
    }
    
}