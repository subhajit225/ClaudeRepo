trigger AccountTeamMemberTrigger on AccountTeamMember (after insert,after Update, after delete) {
    if((trigger.isInsert && trigger.isAfter) || (trigger.isUpdate && trigger.isAfter)){
        AccountTeamMemberTriggerHandler.CEMRoleAccountTeamMembers(trigger.new,trigger.old,trigger.isUpdate);
    }
	if(trigger.isDelete && trigger.isAfter){
        AccountTeamMemberTriggerHandler.CEMRoleAccountTeamMembersAfterDelete(trigger.old);
    }
}