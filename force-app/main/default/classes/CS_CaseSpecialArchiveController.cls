/**
* @author Sushant Arora
* @date 2024-01-31
* @description Controller to CS_ArchivePage vf page
* @TestClass - CS_CaseSpecialArchiveControllerTest
*/

public with sharing class CS_CaseSpecialArchiveController {
     /**
* @description variable to navigate back to the page
*/
    public boolean navBack {get; set;}  
    /**
* @description store the record ids
*/
    public List<Id> selectedRecordIds {get; set;} 
    public ApexPages.StandardSetController ssc;
    /**
* @description declearing constructor and set navBack variable value False
*/
    public CS_CaseSpecialArchiveController(){
        navBack=false;
    }
    
 /**
 * @description Constructor for the CS_CaseSpecialArchiveController class.
 * @param setController The StandardSetController that provides the set of records to work with.
 */
    public CS_CaseSpecialArchiveController(ApexPages.StandardSetController setController) { 
        ssc=setController;
        setController.setSelected(setController.getSelected());
        selectedRecordIds = new List<Id> ();
        for (Case_Special_Handling__c record: (List<Case_Special_Handling__c>)setController.getSelected()) {
            selectedRecordIds.add(record.Id);
        }
    }
    
/**
 * @description Archives the selected records by setting their Is_Archived__c field to true.
 * @return PageReference the page reference for redirection, currently set to null
 */
    public PageReference archiveRecords() {
        PageReference pageRef = null;
        if (FeatureManagement.checkPermission('Case_Special_Handling_Object_Edit_Permission')){
        if (selectedRecordIds != null && !selectedRecordIds.isEmpty()) {
            try {
                List<Case_Special_Handling__c> recordsToUpdate = [SELECT Id, Is_Archived__c,Account_Id__c FROM Case_Special_Handling__c WHERE Id IN: selectedRecordIds WITH SECURITY_ENFORCED];
                for(Case_Special_Handling__c record: recordsToUpdate) {
                    record.Is_Archived__c = true;
                }
                update as user recordsToUpdate;
                // Show success toast
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Records archived successfully.'));
            } catch (Exception e) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error archiving records: ' + e.getMessage()));} 
        } else { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No records selected for archiving.'));}
        }else{ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have access to archive the records.')); }
        navBack = true;return pageRef;
    }
    /**
 * @description This method is intended to redirect the user back to a previous page.
 * @return PageReference result of the ssc.save() method or list on record page depends on conditions.
 */
    public PageReference redirectBack() {
    PageReference pageRef = null;
    String value = ApexPages.currentPage().getParameters().get('Id');
    if (String.isBlank(value)) {return new ApexPages.Action('{!list}').invoke();
    } else { return ssc.save(); }}   
}