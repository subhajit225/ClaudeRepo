public class CampaignMemberTriggerHandler Extends TriggerHandler{
  private Boolean isDisabled = false;
  public static Boolean campMemRecursion = false;
  public CampaignMemberTriggerHandler() {
      ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
      isDisabled = disabled.Disable_Campaign_Member_Triggers__c;
     
      ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion  /////
      Integer mxloopCount = 10;//Integer.valueOf(disabled.TriggerMaxLoopCount__c);
      this.setMaxLoopCount(mxloopCount);
  }
  public override void beforeInsert() {
      if(!isDisabled){
          CampaignMemberTriggerHelper.populateFieldsOnInsert( (List<CampaignMember>) Trigger.New );
      }
  }
  public override void beforeUpdate() {}
  public override void beforeDelete() {}
  
  public override void afterInsert() {
      if(!isDisabled){
          CampaignMemberTriggerHelper.createOpportunityOnResponse((List<CampaignMember>) Trigger.New,
                                                              null,
                                                              true,
                                                              false);
          CampaignMemberTriggerHelper.updateLeadsAndContactsAfterInsert((List<CampaignMember>) Trigger.New);
          CampaignMemberTriggerHelper.updateFeatureRecommendationAfterInsert((List<CampaignMember>) Trigger.New);
      }
      
  }
  
  public override void afterUpdate() {
      if(!isDisabled){
          CampaignMemberTriggerHelper.createOpportunityOnResponse((List<CampaignMember>) Trigger.New,
                                                              (Map<Id, CampaignMember>) Trigger.OldMap,
                                                              false,
                                                              true);
          CampaignMemberTriggerHelper.updateContactAndLeadAfterUpdate((List<CampaignMember>) Trigger.New,(Map<Id, CampaignMember>) Trigger.OldMap);
          CampaignMemberTriggerHelper.updateFeatureRecommendationAfterUpdate((List<CampaignMember>) Trigger.New,(Map<Id, CampaignMember>) Trigger.OldMap);
          CampaignMemberTriggerHelper.triggerCapiNotificationEvent((List<CampaignMember>) Trigger.New,(Map<Id, CampaignMember>) Trigger.OldMap);
      }
  }
  public override void afterDelete() {}
}