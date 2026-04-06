/**
* @Author : Ashwini Gnanamurthy
* @Created Date : 29th Oct 2019
* @Description : Controller CaseTriageFormController for the VF page CaseTriageForm to update the case and add triage comments
*                CS-314 : Case triaging through the button 'Triage Case' which would enable the support users to add their triaging comments, 
*                which would get added under unpublished case comments
**/

public with sharing class CaseTriageFormController {
    
    public Case thisCase {get; set;}
    public CaseComment caseComm {get; set;}
     
    public CaseTriageFormController(ApexPages.StandardController controller) {
        thisCase = (Case)controller.getRecord();
        thisCase = [Select Id,Triage_Status__c from Case where Id = :thisCase.Id];
        caseComm = new CaseComment();
    }
    
    
    public void updateTriageStatus(){
        system.debug('///CS-314: thisCase.Triage_Status__c'+thisCase.Triage_Status__c);
        if(thisCase.Triage_Status__c != 'Triage In Progress'){
            thisCase.Triage_Status__c = 'Triage In Progress';
            update thisCase;
        }
    }
    
    public PageReference saveForm(){
        system.debug('///CS-314:caseComm.CommentBody'+caseComm.CommentBody);
        
        thisCase.Triage_Status__c = 'Triage Complete';
        update thisCase;

        caseComm.ParentId = thisCase.Id;
        caseComm.CommentBody = '[Triager comment added to case]' +'\r\n'+caseComm.CommentBody;
        caseComm.IsPublished  = false;
        insert caseComm;
        
        PageReference casePage = new PageReference('/'+thisCase.Id);
        return casePage;
    }

}