global class AssetStatusDispatched implements Database.Batchable<sObject>,Schedulable {

     global void execute(SchedulableContext sc) {
      AssetStatusDispatched ASDis = new AssetStatusDispatched(); 
      database.executebatch(ASDis);
      
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
         
        String query = 'SELECT Id,Name,Status FROM Asset WHERE account.Name != \'Unassigned\'  AND Order_Service_Item__c != null AND Order_Product_Name__c LIKE \'X-%\' AND Order_Service_Item__r.Order.Type = \'RMA\'';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Asset> AssetList) {
        
        
        for(Asset ass : AssetList){        
            ass.Status = 'Dispatched';
        }
        
            update AssetList;
         
         
    }   
     
    global void finish(Database.BatchableContext BC) {
       
  }
  
  global void Schedulingmethod(){
    string SchdlTime = '0 0 5 ? * *';
    System.schedule('AssetStatusDispatched',SchdlTime, new AssetStatusDispatched());    
      
  }
}