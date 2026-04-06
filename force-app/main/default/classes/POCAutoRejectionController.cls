/**
* @File Name : POCAutoRejectionController.cls
* @Description : Automatically rejects any pending extension approval work items when the POC's Approval Status field is manually set to 'Extension Rejected'.
* @Author : Gaurav Rawat
* @Last Modified By : Gaurav Rawat
* @Last Modified On : September 19, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 19, 2025 | Gaurav Rawat  | Initial Version
**/

/**
* @description A class that contains an invocable method to automatically reject pending approval work items.
*/
public class POCAutoRejectionController {
    
    /**
    * @description Automatically rejects any pending approval work items associated with the provided POC records.
    * This method is designed to be called from a Salesforce Flow.
    * @param pocIdList A required List<Id> of the POC__c records for which associated pending approval work items should be rejected.
    */
    @InvocableMethod(label='Auto Reject Extension Request' description='Rejects pending approval work items for the specified POC records.')
    public static void autoRejectExtensionRequest(List<Id> pocIdList){
        List<Approval.ProcessWorkitemRequest> lstPOCsApprovalsToReject = new List<Approval.ProcessWorkitemRequest>();
        for(ProcessInstanceWorkitem processInstWorkItem : [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN : pocIdList AND ProcessInstance.Status = 'Pending']){
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(processInstWorkItem.Id);
            req.setAction('Reject');
            req.setComments('Auto Rejected by System');
            lstPOCsApprovalsToReject.add(req);
        }
        if( !lstPOCsApprovalsToReject.isEmpty() ) {
			List<Approval.ProcessResult> results = Approval.process(lstPOCsApprovalsToReject);
		}
        
    }
}