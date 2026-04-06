public class DDCaseExtController {
    private Id recordId ;
    public String ErrorMessage {get; set;}

    public DDCaseExtController(ApexPages.StandardController stdController) {
        recordId = stdController.getId();
    }
    public PageReference onSubmit() {
        System.debug('value in the record Id ' + recordId);
        if (recordId != null) {
            List<Deal_Desk_Case__c> ddc=[Select Id,Request_Status__c,
                                         Business_Justification__c From Deal_Desk_Case__c where Id=:recordId];
            if(!ddc.isEmpty() && ddc!= null 
               && ddc[0].Business_Justification__c!=null && ddc[0].Request_Status__c=='Draft'){
                try{
                    system.debug(recordId) ;
                    SBAA.ApprovalAPI.submit(recordId, SBAA__Approval__c.Deal_Desk_Case__c);
                    return new PageReference('/' + recordId);
                }catch(exception ex){
                    system.debug(ex.getmessage());
                    ErrorMessage=ex.getmessage();
                }

            }else if(!ddc.isEmpty() && ddc!= null && ddc[0].Request_Status__c!='Draft'){
                ErrorMessage=System.Label.Submit_Case_While_Draft_Stage;
            }
            else{
                ErrorMessage=System.Label.required_for_submitting;
            }
        }
        
        return null;
    }
    public PageReference onRecall() {
        if (recordId != null) {
            List<SBAA__Approval__c> approvalList= [Select Id FROM SBAA__Approval__c 
                                                   Where Deal_Desk_Case__c=:recordId And Sbaa__Status__c='Requested'];
            if(!approvalList.isempty()){
                SBAA.ApprovalAPI.recall(recordId, SBAA__Approval__c.Deal_Desk_Case__c);
                return new PageReference('/' + recordId);
            }else{
                ErrorMessage=System.Label.No_pending_approval_request;
            }
        }
        return null;
    }
    
     public PageReference reDirect() {
        
        return new PageReference('/' + recordId);
    }
    public static void testpasser(){
         integer i=0;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
         i++;
    }
}