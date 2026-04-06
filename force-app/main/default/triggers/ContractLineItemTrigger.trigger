trigger ContractLineItemTrigger on ContractLineItem (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {
	
	  ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
	  if(disabled.Disable_Contract_Line_Item_Triggers__c || TriggerControl.stopCLITrigger){
            return; 
          }

		new ContractLineItemTriggerHandler().run();

		if (Trigger.isInsert || Trigger.isUpdate){

            Map<Id, SObject> oldMap = Trigger.oldMap;
            List<SObject> newList = Trigger.new;

            System.debug(LoggingLevel.ERROR, '----ContractLineItem--Trigger.isInsert-'+json.serialize(Trigger.isInsert));
            System.debug(LoggingLevel.ERROR, '----ContractLineItem--Trigger.isUpdate-'+json.serialize(Trigger.isUpdate));

            System.debug(LoggingLevel.ERROR, '----ContractLineItem--newList-'+json.serialize(newList));
            System.debug(LoggingLevel.ERROR, '----ContractLineItem--oldMap-'+json.serialize(oldMap));

		}
}