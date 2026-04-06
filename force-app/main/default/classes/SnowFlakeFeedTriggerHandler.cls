public class SnowFlakeFeedTriggerHandler extends TriggerHandler{
    //TODO: change to false 
     private Boolean isDisabled = true;

  public SnowFlakeFeedTriggerHandler() { 
    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    isDisabled = disabled.Disable_SnowFlake_Feed_Triggers__c;
    ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
    //this.setMaxLoopCount(2);
  }

  public override void beforeInsert() {
  }
  public override void beforeUpdate() {
   
  }
  public override void beforeDelete() {
  }
  /***********************************************************************************
  * @description       : In this method afterinsert logic should be added 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : NA
  * return             : void
  * Modifications Log
  * 
  *******************************************************************************/
  public override void afterInsert() {  
      if (!isDisabled) {
           Map<Id, Snowflake_Feed__c> newSnowFlakeRecordsById = (Map<Id, Snowflake_Feed__c>) Trigger.newMap;
           Map<Id, Snowflake_Feed__c> oldSnowFlakeRecordsById = (Map<Id, Snowflake_Feed__c>) Trigger.oldMap;
           Set<Id> setofOverageIds = new Set<Id>();
           set<Id> serviceContractIds = new set<Id>();
          for(Snowflake_Feed__c snowflake : newSnowFlakeRecordsById.values()){
              if(snowflake.Origin__c == Constants.SNOWFLAKE_ORIGIN_SFDC && (snowflake.Type__c == Constants.SNOWFLAKE_TYPE_CNP  || snowflake.Type__c == Constants.SNOWFLAKE_TYPE_M365H) && snowflake.Scale_Utility_Overage_ID__c != null){
                  setofOverageIds.add(snowflake.Scale_Utility_Overage_ID__c);
                  }
          }
          List<Scale_Utility_Overage__c> lstOfSUO = [Select id,Service_Contract__c from Scale_Utility_Overage__c where Id IN :setofOverageIds];
          for(Scale_Utility_Overage__c suo: lstOfSUO){
              serviceContractIds.add(suo.Service_Contract__c);
          }
          if(!serviceContractIds.isEmpty()){
               Database.executeBatch(new ScaleUtilityOverageBatchWithCLI('ProcessManualSnowFlake', null, serviceContractIds), 1);
          }
      }
  }
  public override void afterUpdate() { 
      
  }
  public override void afterDelete() {
      
  }

  public override void afterUndelete() {
  }

}