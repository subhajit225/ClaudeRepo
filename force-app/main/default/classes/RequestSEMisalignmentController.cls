public class RequestSEMisalignmentController {

    private Opportunity oppty;

    public RequestSEMisalignmentController(ApexPages.StandardController stdController) {
        this.oppty = (Opportunity)stdController.getRecord();
    }

    public PageReference save() {
        try{
            if(this.oppty.SE_Misalignment_User__c == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please Choose new Sales Engineer'));
                return null;
            }
    
            User seManager = [Select ManagerId from User where Id = :this.oppty.SE_Misalignment_User__c];
            if(seManager.ManagerId == null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Manager not found for this User. Please get Manager updated in User record.'));
                return null;
            }
            this.oppty.SE_Misalignment_Manager__c = seManager.ManagerId;
            this.oppty.SE_Misalignment_Requested__c = true;
            this.oppty.SE_Misaligned__c = false;
            this.oppty.SE_Manager_Approved__c = false;
    
            update this.oppty;
    
            addToOpportunityTeam(seManager.ManagerId);
    
            submitForApproval();
    
            this.oppty.SE_Misalignment_Requested__c = false;
    
            update this.oppty;
    
            Approval.unlock(this.oppty.Id);
            return new PageReference('/'+this.oppty.Id);
         }catch(Exception e){ //SAL-956 - Added try&catch
            string errorMsg = e.getMessage();
            if(!errorMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
            }
            return null;
        }
    }

    private void addToOpportunityTeam(Id managerId) {
        List<OpportunityTeamMember> members = [Select Id from OpportunityTeamMember 
            where OpportunityId = :this.oppty.Id and UserId = :managerId];

        if(members.size()>0){
            return;
        }
        OpportunityTeamMember member = new OpportunityTeamMember(
            //OpportunityAccessLevel = 'Edit', 
            OpportunityId = this.oppty.Id, 
            TeamMemberRole = 'SE Manager',
            UserId = managerId);
        insert member;

        // get all of the team members' sharing records
        List<OpportunityShare> shares = [select Id, OpportunityAccessLevel, 
          RowCause from OpportunityShare where OpportunityId = :this.oppty.Id 
          and RowCause = 'Team' and UserOrGroupId =:managerId];
          
        // set all team members access to read/write
        for (OpportunityShare share : shares) 
          share.OpportunityAccessLevel = 'Edit';

        update shares;
    }

    private void submitForApproval() {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        //SAL-1276
        req.setComments(this.oppty.SE_Misalignment_Comments__c);
        req.setObjectId(this.oppty.Id);
        req.setProcessDefinitionNameOrId('Request_SE_Misalignment');
        Approval.ProcessResult result = Approval.process(req);
    }

    @future
    public static void unlockRecord(Id recordId){
        Approval.unlock(recordId);
    }

    public PageReference cancel() {
        return new PageReference('/'+this.oppty.Id);
    }
}