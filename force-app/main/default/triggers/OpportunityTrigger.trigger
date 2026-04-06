trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete) {

    ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
      if(!disableBusinessLogicCS.Disable_Opportunity_Triggers__c){
          if(FlowControll.opportunityTriggerHandler && TriggerManager.isTriggerExecutionAllowed('Opportunity')){
              TriggerManager.invokeHandler(new OpportunityObjectTriggerHandler());
          }else{
              if(Trigger.isAfter && Trigger.isUpdate){
                  System.debug('\n' + ' Opportunity Trigger got blocked. \n\n');
                  OppAnnualContractValueUtil.calculateAcvOnAmountChange(Trigger.new, Trigger.oldMap); // This is an special case which we moved out of Trigger framework due to ACV-27
              }
          }
      }else {
      // Added as fix for SF-23481
          System.debug('User Name '+UserInfo.getName());
          System.debug('Custom Setting '+disableBusinessLogicCS.Disable_Opportunity_Triggers__c);
          if(disableBusinessLogicCS.Disable_Opportunity_Triggers__c && UserInfo.getName() == 'CPQ Admin'){
              System.debug('Entered into IF');
              TriggerManager.invokeHandler(new OpportunityObjectTriggerHandler()); 
          }
      
           
      }
      if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){ //SAL25-145
          /* Calling trackFieldsHistory method of CustomHistoryTracker class to track the hitsory of fields defined in the Field Set */
            String disabledHistorytracking = System.label.Disable_Opp_History_tracking;
            if(disabledHistorytracking == 'No' || disabledHistorytracking == 'no'){  
                CustomHistoryTracker.trackFieldsHistory(trigger.new, Trigger.oldMap, 'Opportunity__c');
            }
      }
      //SAL25-748
      if(Trigger.isBefore && Trigger.isDelete){
            OpportunityObjectTriggerHelper.validateOpportunityOnDelete(Trigger.old);
      }
  }