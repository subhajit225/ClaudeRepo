global class ProcessUnApprovedSEMisalignments implements Schedulable {
	global void execute(SchedulableContext sc) {
		
		processPendingRequests();
		processRejectedRecalledRequests();
	}

	private void processPendingRequests(){
		Integer noOfDays = 7;
		if(Test.isRunningTest()){
			noOfDays = -1;
		}
		List<ProcessInstance> pis = [select TargetObjectId from ProcessInstance where Status='Pending' and 
			ElapsedTimeInDays > :noOfDays and ProcessDefinition.DeveloperName = 'Request_SE_Misalignment'];

		Set<Id> opportunityIds = new Set<Id>();
		Set<Id> piIds = new Set<Id>();
		for(ProcessInstance pi : pis){
			opportunityIds.add(pi.TargetObjectId);
			piIds.add(pi.Id);
		}

		Map<Id, Id> oppportunitySEManagerMap = new Map<Id, Id>();
		for(Opportunity opp: [Select Id, SE_Misalignment_Manager__c from Opportunity where Id in :opportunityIds and SE_Misalignment_Manager__c!=null]){
			oppportunitySEManagerMap.put(opp.Id, opp.SE_Misalignment_Manager__c);
		}

		List<OpportunityTeamMember> membersToRemove = new List<OpportunityTeamMember>();
		for(OpportunityTeamMember member: [select Id, OpportunityId, UserId from OpportunityTeamMember 
			where UserId in :oppportunitySEManagerMap.values() and 
			OpportunityId in :oppportunitySEManagerMap.keySet()]){

			if(oppportunitySEManagerMap.get(member.OpportunityId) == member.UserId){
				membersToRemove.add(member);
			}
		}

		if(membersToRemove.size()>0){
			delete membersToRemove;
		}

		for(ProcessInstanceWorkitem piw: [Select Id from ProcessInstanceWorkitem 
			where ProcessInstance.Id in :piIds]){

			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
	        req.setComments('Auto Rejected');
	        req.setAction('Reject');
        
            req.setWorkitemId(piw.Id);
            // Submit the request for approval
            Approval.ProcessResult result =  Approval.process(req);
		}
	}

	private void processRejectedRecalledRequests(){
		Integer noOfDays = 2;
		List<ProcessInstance> pis = [select TargetObjectId from ProcessInstance where Status in ('Rejected','Removed') and 
			ElapsedTimeInDays < :noOfDays and ProcessDefinition.DeveloperName = 'Request_SE_Misalignment'];

		Set<Id> opportunityIds = new Set<Id>();
		Set<Id> piIds = new Set<Id>();
		for(ProcessInstance pi : pis){
			opportunityIds.add(pi.TargetObjectId);
			piIds.add(pi.Id);
		}

		Map<Id, Id> oppportunitySEManagerMap = new Map<Id, Id>();
		for(Opportunity opp: [Select Id, SE_Misalignment_Manager__c from Opportunity where Id in :opportunityIds and SE_Misalignment_Manager__c!=null]){
			oppportunitySEManagerMap.put(opp.Id, opp.SE_Misalignment_Manager__c);
		}

		List<OpportunityTeamMember> membersToRemove = new List<OpportunityTeamMember>();
		for(OpportunityTeamMember member: [select Id, OpportunityId, UserId from OpportunityTeamMember 
			where UserId in :oppportunitySEManagerMap.values() and 
			OpportunityId in :oppportunitySEManagerMap.keySet() and TeamMemberRole = 'SE Manager']){

			if(oppportunitySEManagerMap.get(member.OpportunityId) == member.UserId){
				membersToRemove.add(member);
			}
		}

		if(membersToRemove.size()>0){
			delete membersToRemove;
		}
	}
}