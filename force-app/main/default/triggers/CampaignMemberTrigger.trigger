trigger CampaignMemberTrigger on CampaignMember (before insert, before update, before delete, after insert, after update, after delete) {
    Boolean recursion = true;
    if(Trigger.isUpdate && !CampaignMemberTriggerHelper.CampRecursionIdSet.isEmpty()){
        for(CampaignMember cmp : Trigger.New){
            if(!CampaignMemberTriggerHelper.CampRecursionIdSet.contains(cmp.Id)){
                recursion = false;
                break;
            }
        }
    }else if(CampaignMemberTriggerHelper.CampRecursionIdSet.isEmpty()){
        recursion = false;
    }
    if(!CampaignMemberTriggerHandler.campMemRecursion && !recursion){
    	new CampaignMemberTriggerHandler().run();
    }
}