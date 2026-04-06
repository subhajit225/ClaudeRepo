trigger POStageTrigger on PO_Stage__c (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {
		new POStageHandler().run();   

}