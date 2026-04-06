public class LCC_Submit_for_Approval_CCR_Controller {
    @AuraEnabled
    public static string ccrApproval(String recId){  
        String validate  = SubmitCCRValidation.ApprovalValidation(recId);
        CCR__c ccrRec = [Select Id,Justifications__c,Number_of_Attchments__c  from CCR__c where Id =:recId];
        if(validate=='No error'){
            if(ccrRec.Justifications__c == 'Cohesity Specific Situation' && ccrRec.Number_of_Attchments__c < 2)
            {
                return 'CCR must be have 2 attachments before submitting for approval when Justification is Cohesity Specific Situation';
            }
            else{
                Approval.ProcessSubmitRequest reqApproval = new Approval.ProcessSubmitRequest();
                reqApproval.setComments('Submitting request for approval.');
                reqApproval.setObjectId(ccrRec.id);
                try{
                    Approval.ProcessResult result = Approval.process(reqApproval);
                }catch(Exception e)
                {
                    return e.getMessage();
                }
                
                return 'Approved';        
            }
        }else{
            return validate;
        }
    }
}