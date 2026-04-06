/**
 * 
 */
trigger ZIssueSFTrigger on zsfjira__ZIssue_SF__c (after insert,after delete) {
    ZIssueSFTriggerHandler issueHandler = new ZIssueSFTriggerHandler();
    if(trigger.isInsert && trigger.isAfter){
        issueHandler.sendCommentOnJiraIssue(trigger.new);
        ZIssueSFTriggerHandler.linkUnlinkZissue(trigger.new);
    }
    
    if(trigger.isDelete && trigger.isAfter){
        ZIssueSFTriggerHandler.linkUnlinkZissue(trigger.old);
    }
}