trigger AhaIdeaLinkTrigger on Aha_Idea_Link__c (after insert,after delete) {
    if(Trigger.isInsert){
        AhaIdeaLinkHandler.updateIdeaReference(Trigger.new,'INSERT'); 
    }
    if(Trigger.isDelete){
        AhaIdeaLinkHandler.updateIdeaReference(Trigger.old,'DELETE');    
    }
}