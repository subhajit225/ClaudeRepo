/**
* @Class Name :- TriggerFactory 
* 
* @description : Utility for Trigger to get the appropriate handler for the object type
*   
//********************Change Logs*****************************************************************************
* 
* Change Request            Modified By          Date           Description 
* CPQ22-5418            Mustakim Shaikh        24-7-2025        Removed removed references of Product Change Request related logic as its deprecated.
*  
//********************Change Logs Ends*************************************************************************
**/ 
public with sharing class TriggerFactory
{
    public static Integer iteration=0;
  
  /**
   * @description Public static method to create and execute a trigger handler. Throws a TriggerException if no handler has been coded.
   *
   * @param soType Object type to process (SObject.sObjectType)
   */
  public static void createHandler(Schema.sObjectType soType)
  {
    // Get a handler appropriate to the object being processed
    ITrigger handler = getHandler(soType);

    // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
    if (handler == null)
    {
      throw new TriggerException('No Trigger Handler registered for Object Type: ' + soType);
    }

    // Execute the handler to fulfil the trigger
    execute(handler);

  }

  /**
   * @description : private static method to control the execution of the handler
   *
   * @param handler : ITrigger, A Trigger Handler to execute
   */
  public static void execute(ITrigger handler)
  {
    iteration++;
    System.debug(LoggingLevel.INFO, '\n\n\n iteration: '+iteration+' -> Handler:'+handler+' -> triggerMap:'+Trigger.newMap+' --> opptyHandlerFlow:'+flowControll.opportunityTriggerHandler+'\n\n');
    //What's Changed
    // Before Trigger
    if (Trigger.isBefore)
    {
      // Call the bulk before to handle any caching of data and enable bulkification
      handler.bulkBefore();

      // Iterate through the records to be deleted passing them to the handler.
      if (Trigger.isDelete)
      {
        for (SObject so : Trigger.old)
        {
          handler.beforeDelete(so);
        }
      }
      // Iterate through the records to be inserted passing them to the handler.
      else if (Trigger.isInsert)
      {
        for (SObject so : Trigger.new)
        {
          handler.beforeInsert(so);
        }
      }
      // Iterate through the records to be updated passing them to the handler.
      else if (Trigger.isUpdate)
      {
        for (SObject so : Trigger.old)
        {
          handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
        }
      }
    }
    else
    {
      // Call the bulk after to handle any caching of data and enable bulkification
      handler.bulkAfter();

      // Iterate through the records deleted passing them to the handler.
      if (Trigger.isDelete)
      {
        for (SObject so : Trigger.old)
        {
          handler.afterDelete(so);
        }
      }
      // Iterate through the records inserted passing them to the handler.
      else if (Trigger.isInsert)
      {
        for (SObject so : Trigger.new)
        {
          handler.afterInsert(so);
        }
      }
      // Iterate through the records updated passing them to the handler.
      else if (Trigger.isUpdate)
      {
        for (SObject so : Trigger.old)
        {
          handler.afterUpdate(so, Trigger.newMap.get(so.Id));
        }
      }
    }

    // Perform any post processing
          handler.andFinally();
  }

  /**
   * @description : private static method to get the appropriate handler for the object type.
   * Modify this method to add any additional handlers.
   *
   * @param soType : Schema.sObjectType soType - Object type tolocate (SObject.sObjectType)
   *
   * @return  ITrigger - A trigger handler if one exists or null.
   */
  @TestVisible
  private static ITrigger getHandler(Schema.sObjectType soType)
  {
    
    
    if(soType == POC__c.sObjectType) {
        return new POCRequestTriggerHandler();
    }else if(soType == OpportunityLineItem.sObjectType){
          return new OpportunityLineItemTriggerHandler();
    }else if(soType == Entitlement.sObjectType){
          return new EntitlementTriggerHandler();
    }else if(soType==Contact.sObjectType){
              return new ContactTriggerHandler();
    }else if (soType==Account.sObjectType){
              return new AccountTriggerHandler();
    }else if (soType==Task.sObjectType){
              return new TaskHandler();
    }else if (soType == Product2.sObjectType){
        return new ProductTriggerHandler();
    }else if (soType == Custom_Upgrade_Source__c.sObjectType){
        return new UpgradeSourceTriggerHandler();
    }

    return null;
  }
}