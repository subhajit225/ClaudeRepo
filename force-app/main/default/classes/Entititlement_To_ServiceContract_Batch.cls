global class Entititlement_To_ServiceContract_Batch implements Database.Batchable<sObject>, Database.stateful{
    
    public Set<Opportunity> processedEntitlements = new Set<Opportunity>();
    global string timestamp;
    global Database.QueryLocator start(Database.BatchableContext BC){ //and OpportunityId = \'006S0000009yFdQ\' ,Order_Service_Item__r.Product2Id
       timestamp = String.Valueof(datetime.now()); 
      String query = 'select id , Name,Entitlement_Count__c from Account where Entitlement_Count__c >0 '+ (Test.isRunningTest()?' LIMIT 1':'');
      return Database.getQueryLocator(query);
    }
    // Execute Metjod to perform Logic on Batch
    global void execute(Database.BatchableContext BC, List<Account> scope){
         //timeStamp =BatchInfo.createdDate ;
        Set<ID> accountIds= new Set<Id>();
        for(Account acc: scope){
          
          accountIds.add(acc.Id);
        }
        accountIds.remove(null);
        //system.debug('accountIds=='+accountIds);
        Map<Id,List<Entitlement>> mapAccountwithEntls = new Map<Id,List<Entitlement>>();
        Map<String,Entitlement> mapDatewithEntls = new Map<String,Entitlement>();
        Map<Entitlement,Set<Entitlement>> mapEntwithMatchingEntls = new Map<Entitlement,Set<Entitlement>>();
        Map<Id,Map<Entitlement,List<Entitlement>>> mapAccwithMatchingEntls = new Map<ID,Map<Entitlement,List<Entitlement>>>();
        for(Account account : [select id ,(SELECT id , Base_Product__c, Account.Name,Account.OwnerID,isSCCreated__C,
                        Product__c,Product__r.Category__c,Product__r.ProductCode,Product__r.ExcludeFromSCCreation__c,Calculated_List_Price__c,PB_List_Price__c,
                        AssetId,StartDate, EndDate,Renewable__c,StartDAteEndDate__c ,Order_Number__c,
                        Order_Quantity__c, order_service_item__c,order_service_item__r.PricebookEntryId,order_service_item__r.OrderItemNumber, Order_Service_Item__r.PriceBookEntry.isActive,
                        order_service_item__r.OrderId,order_service_item__r.UnitPrice,
                        order_service_item__r.TotalPrice,order_service_item__r.Quantity,order_service_item__r.Actual_Sales_Price__c,
                        order_service_item__r.order.OpportunityId,order_service_item__r.Sales_Price__c,
                        order_service_item__r.order.Opportunity.Name,order_service_item__r.order.Opportunity.SBQQ__PrimaryQuote__C,
                        order_service_item__r.order.PriceBook2Id,ContractLineItemID, order_service_item__r.order.Type, 
                        order_service_item__r.Order.POC_Opportunity__c, order_service_item__r.Order.POC_Opportunity__r.Name
                        from Entitlements where Product__c != NULL AND order_service_item__r.Order.Type !='POC' AND (ContractLineItemID =null) AND Product__r.ExcludeFromSCCreation__c =false
                                           AND ((order_service_item__c = null) OR (order_service_item__c != null AND order_service_item__r.order.Opportunity.SBQQ__PrimaryQuote__C = null)) 
                                           AND Type !='Manufacturing Entitlement'
                        order by StartDAteEndDate__c ASC) from Account where Id IN:accountIds ]){
            
            mapDatewithEntls = new Map<String,Entitlement>();
            mapAccountwithEntls.put(account.Id,account.Entitlements);
            Date tempStartDate=null;
            Date tempEndDate = null;
            
            mapEntwithMatchingEntls = new Map<Entitlement,Set<Entitlement>>();
            Set<Entitlement> setEntl = new Set<Entitlement>();
            boolean matching= false;
            String tempDate = null;
            String OrderId = null;
            List<Entitlement> entToBeProcessed = new List<Entitlement>();
            
            system.debug('account.Entitlements=='+account.Entitlements);
            system.debug('account.Entitlements size=='+account.Entitlements.size());
            
            for(Entitlement ent : account.Entitlements){ 
             
             //system.debug('tempdate =='+tempdate );
             //system.debug('StartEndate=='+String.valueOf(ent.StartDate)+String.valueOf(ent.EndDate) == tempDate);
             //system.debug('mapEntwithMatchingEntls 1111=='+mapEntwithMatchingEntls);
                if(tempdate == null){
                    tempdate = String.valueOf(ent.StartDate)+String.valueOf(ent.EndDate)+ent.Order_Number__c;
                    system.debug(String.valueOf(ent.StartDate)+String.valueOf(ent.EndDate));
                    tempStartDate = ent.StartDate;
                    tempEndDate = ent.EndDate ;
                    if(ent.Order_Service_Item__c != null)
                    OrderId = ent.Order_Service_Item__r.orderId;
                    setEntl.add(ent);
                    matching= true;
                    //system.debug('setEntl 000=='+setEntl);
                    mapDatewithEntls.put(tempDate, ent);
                    //system.debug('mapEntwithMatchingEntls 000=='+mapEntwithMatchingEntls);
                }
                else if(String.valueOf(ent.StartDate)+String.valueOf(ent.EndDate)+ent.Order_Number__c == tempDate ){
                       setEntl.add(ent);
                       matching= true;   
                       tempdate = String.valueOf(ent.StartDate)+String.valueOf(ent.EndDate)+ent.Order_Number__c;
                       if(ent.Order_Service_Item__c != null)
                        OrderId = ent.Order_Service_Item__r.orderId;
                       //system.debug('mapEntwithMatchingEntls 111=='+mapEntwithMatchingEntls);
                       //system.debug('setEntl 111=='+setEntl);
                    }
                else{
                    tempdate = String.valueOf(ent.StartDate)+String.valueOf(ent.EndDate)+ent.Order_Number__c;
                    if(ent.Order_Service_Item__c != null)
                    OrderId = ent.Order_Service_Item__r.orderId;
                    //system.debug('setEntl before=='+setEntl);
                    setEntl = new Set<Entitlement>();
                    //system.debug('setEntl clear=='+setEntl);
                    setEntl.add(ent);
                    //system.debug('setEntl after=='+setEntl);
                    matching= false;
                    mapDatewithEntls.put(tempDate, ent);
                     mapEntwithMatchingEntls.put(ent, setEntl);
                    //system.debug('mapEntwithMatchingEntls 222=='+mapEntwithMatchingEntls);
                    //system.debug('setEntl 222=='+setEntl);
                   
                }
                if(matching == false ){
                 //system.debug('mapEntwithMatchingEntls-11111p00000-'+mapEntwithMatchingEntls);
                }
                else if(matching == true){
                    setEntl.add(mapDatewithEntls.get(tempDate));
                    mapEntwithMatchingEntls.put(mapDatewithEntls.get(tempDate), setEntl);
                    //system.debug('mapEntwithMatchingEntls-00000p00000-'+mapEntwithMatchingEntls);
                }
            }
            system.debug('mapEntwithMatchingEntls=='+mapEntwithMatchingEntls+'-- size--'+mapEntwithMatchingEntls.size());
        }
          EntitlementToSCHelperClass.createSCandSCLI(mapEntwithMatchingEntls,timestamp);
       
        
      }
      global void finish(Database.BatchableContext processedrecords) {
          AsyncApexJob a = [SELECT Id,Status,JobType,NumberOfErrors,JobItemsProcessed,TotalJobItems,CompletedDate,ExtendedStatus
          FROM AsyncApexJob WHERE Id =:processedrecords.getJobId()];
          List<String> toAddresses = new List<String>();
          toAddresses.add('shadab.hussain@rubrik.com');//toAddresses.add('mudit.agarwal@rubrik.com');
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
   mail.setToAddresses(toAddresses);
   //mail.setTargetObjectId(u.Id);
   mail.setSubject('Hourly Entititlement_To_Service_Contract_Batch - ' + a.Status);
   mail.setSaveAsActivity(false);
   mail.setPlainTextBody
   ('The batch Apex job completed on  ' + a.CompletedDate + ',\n\n' +
   'Job Status : ' + a.Status + '\n'+
   'Total Job Items processed : ' + a.TotalJobItems + '\n'+
   'Number of Job Items processed : ' + a.JobItemsProcessed + '\n' +
   'Number of Failures : '+ a.NumberOfErrors);
   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
}        

      
}