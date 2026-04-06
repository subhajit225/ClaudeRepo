trigger AhaIdeaTrigger on Aha_Ideas__c (before insert, before update,after insert, after update , before delete) {
    if(trigger.isInsert && trigger.isAfter){
        ManageAhaIdeaController.afterInsertAhaIdea(trigger.newmap);
    }
    if(trigger.isInsert && trigger.isBefore){
        ManageAhaIdeaController.beforeInsertAhaIdea(trigger.new);
    }
    if(trigger.isDelete && trigger.isBefore){
        List<Aha_Idea_Link__c> ahaIdeaLinkList = New List<Aha_Idea_Link__c>();
        ahaIdeaLinkList = [SELECT Id, Case_Number__c, Aha_Ideas__c, Opportunity_Name__c FROM Aha_Idea_Link__c
                           WHERE Aha_Ideas__c IN : trigger.old];
        if(ahaIdeaLinkList.size()>0){
            AhaIdeaLinkHandler.updateIdeaReference(ahaIdeaLinkList,'DELETE');
        }
    }
}