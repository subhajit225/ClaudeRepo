trigger RmaRequestEvent on RMA_Event__e (after insert) {

    Map<string,RMA_Order__c > updateRmaRecordMap = New Map<string,RMA_Order__c >();
    for(RMA_Event__e event : Trigger.new){
        system.debug('IN RMA EVENT FLASH MESSAGE'+event.Flash_Message__c);
       RMA_Order__c rma = new RMA_Order__c (Id = event.RMA_Id__c, Flash_Email_History__c = event.Flash_Message__c);
       updateRmaRecordMap .put(event.RMA_Id__c, rma );
    }
    if(updateRmaRecordMap .size()>0){
        update updateRmaRecordMap.values();
    }
    


}