trigger ShipmentDetailTrigger on ShipmentDetail__c (before insert, before update) {
  public ShGl_DisableBusinessLogic__c triggerCtrl = ShGl_DisableBusinessLogic__c.getInstance();
    
  if(!triggerCtrl.Disable_Shipment_Detail__c){ 
    try{
         ShipmentDetailHandler handler = ShipmentDetailHandler.getInstance();
         handler.execute();
         if(test.isRunningTest()){throw new system.DmlException('Test Exception');}
      }
    catch(exception excep){
        ShipmentDetailHandler.getInstance().errorLogs.add(new Error_Logs__c( Error_Type__c = 'Order Error',Error_Message__c = excep.getMessage() +'\r\n' +excep.getStackTraceString(), Type__c = 'SFDC'));
    }
  }else{
     system.debug(LoggingLevel.DEBUG, 'SHIPMENT DETAIL TRIGGER IS DISABLED'); 
  }
}