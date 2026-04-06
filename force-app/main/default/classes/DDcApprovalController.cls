public with sharing class DDcApprovalController {
    
       private Deal_Desk_Case__c ddCase;
    
    public SBAA__Approval__c[] approvals {
        get {
           
            if (approvals == null) {
                approvals = SBAA.ApprovalAPI.preview(ddCase.Id, SBAA__Approval__c.Deal_Desk_Case__c);
            }else{
                approvals =new list<SBAA__Approval__c>();
            }
            return approvals;
        } 
        set;
    }

    public Boolean isReadyForApproval {get; set;}

    public DDcApprovalController(ApexPages.StandardController stdController) {

        this.ddCase = (Deal_Desk_Case__c)stdController.getRecord();


    }

}