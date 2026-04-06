trigger AssetTrigger on Asset(before insert, before update, before delete, after insert, after update, after delete) {
  AssetTriggerHandler handler = new AssetTriggerHandler();
  handler.run(); 
  handler.explicitMethodHandler(Trigger.new, Trigger.oldMap, Trigger.OperationType);
}