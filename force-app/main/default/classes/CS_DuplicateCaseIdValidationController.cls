/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   13-02-2020
* @Jira Ticket  :   CS-474 - Allow only one alert key per case
* @Description  :   This class is the apex extension for CS_DuplicateCaseIdValidation page. The class is responsible for displaying warning message
if the duplicate case id used on a proactive case is already used on another proactive case saying that the alert key will not
be copied onto the reactive case.
*/
public with sharing class CS_DuplicateCaseIdValidationController {
    public Case caseRecord {get; set;}
    public Boolean isEdit {get; set;}
    public Boolean isWarningDisplayed {get; set;}
    Id originalDuplicateCaseId = null;
    public String duplicateCaseName {get; set;}
    
    /**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   13-02-2020
* @Description  :   Constructor for the class defining default values
*/
    public CS_DuplicateCaseIdValidationController(ApexPages.StandardController caseObject) {
        caseRecord = (Case)caseObject.getRecord();
        originalDuplicateCaseId = caseRecord.Duplicate_Case_Id__c;
        isEdit = false;
        isWarningDisplayed = false;
        duplicateCaseName = '';
        
        if(originalDuplicateCaseId != null) {
            Case currentDuplicateCase = [Select Id, CaseNumber from Case where Id =: originalDuplicateCaseId];
            duplicateCaseName = currentDuplicateCase.CaseNumber;
        }
    }
    
    /**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   13-02-2020
* @Description  :   Action method for Edit button
*/
    public Pagereference changeToEditMode() {
        isEdit = true;
        return null;
    }
    
    /**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   13-02-2020
* @Description  :   Action method for Cancel button
*/
    
    public Pagereference Cancel() {
        isEdit = false;
        PageReference pageRef = Page.CS_DuplicateCaseIdValidation;
        //pageRef.setRedirect(true);
        return pageRef;
    }
    
    /**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   13-02-2020
* @Description  :   Action method for Save button. If the selected duplicate case Id is already used on another proactive case,
a warning message is displayed else updates the case
*/
    public void validateDuplicateCaseId() {
        Case currentCaseRecord = [Select Id, Alert_Key__c from Case where Id =: caseRecord.Id];
        
        List<String> caseIdList = new List<String>();
        String caseIdString = '';
        Id duplicateCaseId = caseRecord.Duplicate_Case_Id__c;
        List<Case> caseList = new List<Case>();
        String alertKeyOnParentCase = '';
        String alertKeyOnCurrentCase = currentCaseRecord.Alert_Key__c;
        
        //Fetch the cases where the selected Duplicate case is already used on existing proactive cases
        if(duplicateCaseId != null) {
            caseList = [SELECT Id, CaseNumber, Alert_Key__c
                        FROM Case
                        WHERE ((Duplicate_Case_Id__c =: duplicateCaseId)
                               OR (Id =: duplicateCaseId))];
        }
        
        for(Case eachCase : caseList) {
            //Fetch case numbers where the seelcted duplicate case Id has been already used
            if(eachCase.Id != duplicateCaseId) {
                caseIdList.add(eachCase.CaseNumber);
            }
            //Fetch the alert key on the selected Duplicate case Id
            else {
                alertKeyOnParentCase = eachCase.Alert_Key__c;
            }
        }
        
        caseIdString = String.join(caseIdList, ', ');
        
        //Display the warning message if there are proactive cases where selected duplicate case id is already used
        if(caseList.size() > 1) {
            String warningMessage = System.Label.Duplicate_Case_Id_warning + ' ' + caseIdString;
            
            //Display the warning message if selected duplicate case id and current case record have Alert keys
            if(!String.isEmpty(alertKeyOnParentCase) && !String.isEmpty(alertKeyOnCurrentCase)) {
                warningMessage = warningMessage + System.Label.Duplicate_Case_Id_warning_2;
            }
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, warningMessage));
            isWarningDisplayed = true;
        }
        //Display the warning message if there are no proactive cases where selected duplicate case id is already used
        else if(caseList.size() == 1) {
            
            //Display the warning message if selected duplicate case id and current case record have Alert keys
            if(!String.isEmpty(alertKeyOnParentCase) && !String.isEmpty(alertKeyOnCurrentCase)) {
                String warningMessage = '';
                warningMessage = System.Label.Duplicate_Case_Id_warning_3 + System.Label.Duplicate_Case_Id_warning_2;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, warningMessage));
                isWarningDisplayed = true;
            } else {
                updateCase();
            }
        }
        //Update the case if there are no proactive cases where selected duplicate case is already used
        else {
            updateCase();
        }
    }
    
    /**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   13-02-2020
* @Description  :   Updates the case with new duplicate case id
*/
    public Pagereference updateCase() {
        try {
            update caseRecord;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, System.Label.Case_save_success_message));
            
            if(caseRecord.Duplicate_Case_Id__c != null) {
                Case currentDuplicateCase = [Select Id, CaseNumber from Case where Id =: caseRecord.Duplicate_Case_Id__c];
                duplicateCaseName = currentDuplicateCase.CaseNumber;
            } else {
                duplicateCaseName = '';
            }
            
            isEdit = false;
            isWarningDisplayed = false;
        } catch(Exception e) {
            isWarningDisplayed = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getDmlMessage(0)));
        }
        return null;
    }
}