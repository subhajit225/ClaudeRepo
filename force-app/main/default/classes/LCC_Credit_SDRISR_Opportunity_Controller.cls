public class LCC_Credit_SDRISR_Opportunity_Controller {
    @AuraEnabled
    public static string opportunityApproval(String recId, String meetEvdLink, String notes){  
        try{ 
            Opportunity oppRec = [Select Id, SDR_Led__c, OriginalLeadOwner__c,Credit_SDR_ISR_Approval_Status__c, Credit_SDR_ISR_Meeting_link__c,Initial_Submitter_Name__c,Initial_Submitter_Email__c,SDR_Initial_Submitter_Name__c from Opportunity where Id =:recId];
            oppRec.Credit_SDR_ISR_Meeting_link__c = meetEvdLink;
            oppRec.Credit_SDR_ISR_Approval_Status__c = 'Sent for approval';
            oppRec.Initial_Submitter_Name__c = ''; //SAL26-486
            oppRec.Initial_Submitter_Email__c = ''; //SAL26-486
            oppRec.SDR_Initial_Submitter_Name__c = ''; //SAL26-486
            flowControll.opportunityTriggerHandler = false;
            update oppRec;
            flowControll.opportunityTriggerHandler = true;
                Approval.ProcessSubmitRequest reqApproval = new Approval.ProcessSubmitRequest();
                reqApproval.setComments( notes );
                reqApproval.setObjectId(oppRec.id);
                Approval.ProcessResult result = Approval.process(reqApproval);
                return 'Approved';

        }catch(Exception e){
            return e.getMessage();
        }
    }
}