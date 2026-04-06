public class LeadTriggerHandler extends TriggerManager.GenericTriggerHandler{
    LeadTriggerHelper helper; 

    public List<Lead> newList = (List<Lead>)Trigger.new;
    public List<Lead> oldList = (List<Lead>)Trigger.old;
    public Map<Id, Lead> newMap = (Map<Id, Lead>)Trigger.newMap;
    public Map<Id, Lead> oldMap = (Map<Id, Lead>)Trigger.oldMap;
	
    public LeadTriggerHandler() {
        helper = new LeadTriggerHelper(); 
    }
    public override void onBeforeInsert(List<sObject> newRecords) {
        helper.riffraffFilter(newList); 
        //helper.createSDRLedMeetingTask(newList, oldMap);
        helper.updateLastOwnershipUpdateDate(newList, oldMap);
        helper.onStatusChange(newList, oldMap);
        helper.setStatusToRaw(newList);
        helper.resetAgreedToEdgeTrailAgreement(newList, oldMap);
        helper.resetOwnershipChangeDate(newList, oldMap);
        helper.resetFields(newList);
        helper.setP0ResposeDate(newList, oldMap);
        helper.clearFCRReason(newList, oldMap);
        helper.setNurturetimeout(newList, oldMap);
        helper.populateUTMTerm(newList, null);
        helper.setPrivacyCompliance(newList, null);
        helper.setMarketingOptInAndOut(newList, null);
        helper.calculateLeadScore(newList, null);
        helper.calculateMQLPriority(newList, null);
    }
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        helper.populateUTMTerm(newList, oldMap);
        helper.mqlUpdatesBeforeUpdate(newList, oldMap);
        helper.uncheckDirectRouteToAECampaign(newList, oldMap);
        helper.updateLastOwnershipUpdateDate(newList, oldMap);
        helper.onStatusChange(newList, oldMap);
        helper.updateStatusToSalesLoft(newList, oldMap);
        helper.resetAgreedToEdgeTrailAgreement(newList, oldMap);
        helper.resetOwnershipChangeDate(newList, oldMap);
        helper.resetL2Astatus(newList, oldMap);
        helper.resetFields(newList);
        helper.setP0ResposeDate(newList, oldMap);
        helper.rerunPatchManager(newList, oldMap);
	    // Chnages related to Winl2A JIRA//
	    // moving out to the directly in Trigger
	    //helper.populateWinningL2AAccount(newList, oldMap);
        helper.unmqlLead(newList, oldMap);
        helper.setLeadRejectReasonBlank(newList, oldMap);
        helper.rerunLeadRamdomLogic(newList, oldMap);
        helper.runL2AafterZoomInfo(newList, oldMap);
        helper.clearFCRReason(newList, oldMap);
        helper.setNurturetimeout(newList, oldMap);
        //Chnages related to MKT25-77
        //moving out to the directly in Trigger
        //helper.uncheckL2AStatus(newList, oldMap);
        helper.setLeadShareExpirationDateMeetingSet(newList, oldMap);
        helper.updateLeadSharingDate(newList, oldMap);
        helper.captureOwnerProfile(newList, oldMap); 
        helper.updateRejectionReason(newList, oldMap);
        helper.setPrivacyCompliance(newList, oldMap);
        helper.setMarketingOptInAndOut(newList, oldMap);
        helper.calculateLeadScore(newList, oldMap);
        helper.calculateMQLPriority(newList, oldMap);
    }
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        helper.processContactForEdgeTrial(newList, oldMap);
        helper.insertLeadIntoCampaign(newList, newMap, true);
    }
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) { 
        helper.processContactForEdgeTrial(newList, oldMap);
        //helper.updateAllianceDealRegs(newList, oldMap);
        //MKT24-977: Stopping the async process for Mulesoft to process
        //helper.runL2AOnFlagCheck(newList, oldMap);
        helper.insertLeadIntoCampaign(newList, oldMap, false);
        helper.assignOwner(newMap, oldMap);
        //MKT23-665 // File Data Merge Data modified//
    }
}