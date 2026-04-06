/*******************************************************************************************************************
* @description       : MissingEntitlementsEmailAlert 
* @last modified on  : 06-19-2025
* @last modified by  : Shrutika
********************************************************************************************************************/
public without sharing class MissingEntitlementsEmailAlert implements Schedulable {
 public Date currentDate = Date.Today();
    /**
   * @description execute method
   * @param sc
   */
    public void execute(SchedulableContext sc) {
        List<OrderItem> orderItems =new List<OrderItem>();
        String MissingEntitlements;
        String MissingContracts;

        //Scheduled Batch 1st day of each quarter 
        if(test.isRunningTest()){
            currentDate = Date.newInstance(Date.Today().Year(), 8, 1);
        }
        Integer currentMonth = currentDate.Month();
        Integer currentDay = currentDate.Day();
        if( currentDay ==  1 && (currentMonth == 2 || currentMonth == 5 || currentMonth == 8 || currentMonth == 11 )){
            BookedOrdersPerQuarterBatch bob=new BookedOrdersPerQuarterBatch();
            database.executeBatch(bob, 1);
        }

        List<StoreSOQLQuery__mdt> RetriveData = new List <StoreSOQLQuery__mdt>();
        RetriveData=[Select Id,label,Query__c from StoreSOQLQuery__mdt where label IN ('RetriveMissingContracts','RetriveMissingEntitlementsQuery')];
        if(RetriveData.size()> 0){
            for(StoreSOQLQuery__mdt queryData:RetriveData){
                if(queryData.label=='RetriveMissingEntitlementsQuery' && queryData.Query__c != NULL )
                {
                    MissingEntitlements = queryData.Query__c.trim();
                }
                else if(queryData.label=='RetriveMissingContracts'&& queryData.Query__c != NULL)
                {
                    MissingContracts = queryData.Query__c.trim();
                }
            }
        }
        orderItems = Database.query(MissingEntitlements);
        
        if(orderItems == null || orderItems.size() == 0){
            orderItems = Database.query(MissingContracts);
        }
        
        if(orderItems != null && orderItems.size() > 0) {
            User u;
            EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Missing_Entitlements_Alert'];
            Email_Preferences__mdt mdt = [Select Id, Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'Entitlement' LIMIT 1];
            if(!test.isRunningTest()){
                u = [Select Id from User where IsActive = true and Email = :mdt.Receipient__c LIMIT 1];
            }
            else{
                u = [Select Id from User where IsActive = true and Email like '%noreply-sfdc@rubrik.com%' LIMIT 1];
            }
            Messaging.SingleEmailMessage email = 
                Messaging.renderStoredEmailTemplate(et.Id, u.Id, orderItems[0].Id);
            List<String> ccAddresses = new List<String>();
            if(mdt.cc__c != null){
                for(String address: mdt.cc__c.split(',')){
                    ccAddresses.add(address.trim());
                }
            }
            email.setCcAddresses(ccAddresses);
            email.setSaveAsActivity(false);
            try{
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }catch(exception e){
                //apexpages.addmessage(new apexpages.message(apexpages.severity.error,e.getMessage()));
                System.debug(LoggingLevel.debug,'error'+e.getMessage());
            }
        }
        scheduleBatchHelper();
        try{
            sendEmail();
            sendAssetSetEligibleFreeHWBatchFailureReport();
        }catch(Exception ex){
            System.debug(LoggingLevel.debug,'error'+ex.getMessage()+':::>'+ex.getLineNumber());
        }
    }
    /**
   * @description scheduleBatchHelper
   */
    private static void scheduleBatchHelper() {
        // scheduling AssetSetEligibleFreeHWBatch to set Eligible For Free HW field on the Assets
        AssetSetEligibleFreeHWBatch setHwFlagBatch = new AssetSetEligibleFreeHWBatch();
        Database.executeBatch(setHwFlagBatch, 20);
        try{ 
            Database.executeBatch(new GTC_ScreenAccountsBatch(), 500);
        }
        catch(exception e){
            System.debug(LoggingLevel.debug,'error'+e.getMessage());
        } 
    }

    /**
   * @description Send email
   */
    public static void sendEmail() {
        final String PRODUCT_SUBTYPE = 'Start UP';
        Map<Id, List<OrderHistory>> orderIdAndOrderHistory = new Map<Id, List<OrderHistory>>();
        Map<Id, Boolean> idOrderMap = new Map<Id, Boolean>();
        Map<Id, String> clusterIdandReason = new Map<Id, String>();
        List<Order> lstOfOrders = [Select id,ordernumber,Name, BookingStatus__c ,LastModifiedDate,(select id from bookings__r) from order where type = 'Revenue' and (Order_Status__c = 'Order Accepted' OR Order_Status__c = 'Shipped') and (Order_Accepted_Timestamp__c = LAST_N_DAYS:2 and  Order_Accepted_Timestamp__c != TODAY) and Order_Status__c !='rejected'];
        System.debug(LoggingLevel.debug,'lstOfOrders :::>'+lstOfOrders);
        List<Cluster__c> lstOfClusters = [SELECT Id,Name, MSP_Consumption__c,createddate, (SELECT Id, Asset__r.Product2.Product_Subtype__c, Asset__r.Third_Party_MSP__c FROM Nodes__r) FROM Cluster__c WHERE CreatedDate = LAST_N_DAYS:2];
        Map<String,String> attachFiles = new  Map<String,String>();
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        if(lstOfOrders != null && !lstOfOrders.isEmpty()){
            List<OrderHistory> ordersHistory = [Select OrderId, Field, NewValue, OldValue, CreatedDate From OrderHistory Where OrderId IN: lstOfOrders AND Field =:'BookingStatus__c'];
            if(ordersHistory != null && !ordersHistory.isEmpty() && !Test.isRunningTest()){
                for(OrderHistory oOrderHistory :ordersHistory){
                    if(orderIdAndOrderHistory.containskey(oOrderHistory.OrderId)){
                        orderIdAndOrderHistory.get(oOrderHistory.OrderId).add(oOrderHistory);
                    }
                    else{
                        orderIdAndOrderHistory.put(oOrderHistory.OrderId, new List<OrderHistory>{oOrderHistory});
                    }
                }
                for(Id oOrderId : orderIdAndOrderHistory.keySet()){
                    boolean IsBookingCreated= false;
                    boolean IsBookingCompleted= false;
                    for(OrderHistory oHistory : orderIdAndOrderHistory.get(oOrderId)){
                        
                        if(oHistory.NewValue == 'Completed'){
                            
                            IsBookingCompleted=true;
                        }
                        if(oHistory.NewValue == 'Booking Created'){
                            IsBookingCreated= true;
                        }
                        
                    }
                    if(!IsBookingCompleted || !IsBookingCreated){
                        idOrderMap.put(oOrderId, true);
                    }
                }
            }
            string finalstr = ''; 
            string recordString = '';
            if(lstOfOrders !=null && lstOfOrders.size()>0){
                
                for(Order oOrder : lstOfOrders){
                    if((oOrder.bookings__r == null || oOrder.bookings__r.isEmpty()) || (idOrderMap.containsKey(oOrder.Id) && idOrderMap?.get(oOrder.Id))){
                        String sRecord = oOrder?.Id+','+oOrder?.ordernumber+','+'These Orders does not have any Booking Associated\n';
                        recordString = recordString + sRecord;
                        //
                    }
                }
                if(!String.isBlank(recordString)){
                    string header = 'Order Id, Order Number, Reason\n';
                    finalstr = header;
                    finalstr = finalstr +recordString;
                }
            }
            if(!String.isBlank(finalstr)){
                attachFiles.put('Booking',finalstr);
            }
        }
        Map<Id, Cluster__c> idAndCLusterMap =new Map<Id, Cluster__c>();
        if(lstOfClusters.size()>0){
            string header = 'Id, Cluster Name, MSP_Consumpton__c, Reason\n';
            string finalstr = header; 
            if(lstOfClusters !=null && lstOfClusters.size()>0){
                for(Cluster__c oCluster : lstOfClusters){
                    Boolean isProductSubTypeIsBlank = false;
                    boolean isFalsevalid = true;
                    boolean isTrueValid = false;
                    if(oCluster.MSP_Consumption__c){
                        if(!oCluster.Nodes__r.isEmpty()){
                            for(Node__c oNodes : oCluster.Nodes__r){
                                if(oNodes.Asset__c != null && ((!String.isBlank(oNodes.Asset__r.Product2id) && oNodes.Asset__r.Product2.Product_Subtype__c == PRODUCT_SUBTYPE) || oNodes.Asset__r.Third_Party_MSP__c) ){
                                    isTrueValid= true;
                                }    
                            }
                        }
                    }
                    
                    else if(!oCluster.MSP_Consumption__c){
                        isTrueValid= true;
                        if(!oCluster.Nodes__r.isEmpty()){
                            for(Node__c oNodes : oCluster.Nodes__r){
                                if(oNodes.Asset__c != null && ((!String.isBlank(oNodes.Asset__r.Product2id) && oNodes.Asset__r.Product2.Product_Subtype__c == PRODUCT_SUBTYPE) || oNodes.Asset__r.Third_Party_MSP__c) ){
                                    isFalsevalid = false;
                                }
                            }
                            
                        }
                    }
                    if(!isFalsevalid || !isTrueValid){
                        idAndCLusterMap.put(oCluster.Id, oCluster);
                    }
                }
                if(!idAndCLusterMap.isEmpty()){
                    for(Id keyId : idAndCLusterMap.keySet()){
                        string recordString = keyId+','+idAndCLusterMap.get(keyId).Name+','+idAndCLusterMap.get(keyId).MSP_Consumption__c+','+'Please check the Nodes, Assets and Product Subtype for this Cluster\n';
                        finalstr = finalstr +recordString;
                    }
                    if(!String.isBlank(finalstr)){
                        attachFiles.put('MSPConsumption',finalstr);
                    }
                }
                
            }
        }
        if(!attachFiles.isEmpty()){
            Email_Preferences__mdt mdt = [Select Id, Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'BookingMSPConsumptionNotificationBatch' LIMIT 1];
            for (String name : attachFiles.keySet()){                
                Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                blob csvBlob = Blob.valueOf(attachFiles.get(name));
                System.debug(LoggingLevel.debug,'csvBlob :::>'+csvBlob);
                string csvname=name+'.csv';
                csvAttc.setContentType('text/csv');
                csvAttc.setFileName(csvname);
                csvAttc.setBody(csvBlob);
                attachments.add(csvAttc);
            }
            
            
            Messaging.SingleEmailMessage oEmail = new Messaging.SingleEmailMessage();
            oEmail.setSubject('Booking and MSP Batch failures');
            oEmail.setToAddresses(new List<String>{mdt.Receipient__c});
            oEmail.setSenderDisplayName('IT-ProdOpps');
            oEmail.setHtmlBody('Hello, <br/><br/> Here is attached Report.<br/><br/>Thank You.<br/>Admin');
            List<String> ccAddresses = new List<String>();
            if(mdt.cc__c != null){
                for(String address: mdt.cc__c.split(',')){
                    ccAddresses.add(address.trim());
                }
            }
            oEmail.setCcAddresses(ccAddresses);
            oEmail.setFileAttachments(attachments);
            try{
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { oEmail });
            }catch(exception e){
                System.debug(LoggingLevel.debug,'Error' +e.getMessage());
            }
        }
    }
    /**
   * @description sendAssetSetEligibleFreeHWBatchFailureReport
   */
    public static void sendAssetSetEligibleFreeHWBatchFailureReport(){
        Map<String,String> attachFiles = new  Map<String,String>();
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Map<Id, Error_Logs__c> idAndErrorLogMap = new Map<Id, Error_Logs__c>([Select Id, Error_Type__c, Error_Message__c, Object__c, RecordId__c, CreatedDate From 
                                                                              Error_Logs__c Where CreatedDate = LAST_N_DAYS:2 AND Error_Type__c LIKE '%AssetSetEligibleFreeHWBatch - %']);
        //
        //Object__c =:'Asset' AND 
        //
        
        string finalstr = ''; 
        string recordString = '';
        if(!idAndErrorLogMap.isEmpty() && idAndErrorLogMap != null){
            for(Id errorlogId : idAndErrorLogMap.keySet()){
                System.debug(LoggingLevel.debug,'idAndErrorLogMap.get(errorlogId)?.Error_Type__c :::>');
                if(idAndErrorLogMap.get(errorlogId)?.Error_Type__c.contains('AssetSetEligibleFreeHWBatch')){
                    String sRecord = idAndErrorLogMap.get(errorlogId)?.RecordId__c+','+idAndErrorLogMap.get(errorlogId)?.Error_Type__c+','+idAndErrorLogMap.get(errorlogId)?.Error_Message__c+'\n';
                    recordString = recordString + sRecord;
                }
                
            }
        }
        
        if(!String.isBlank(recordString)){
            string header = 'Asset Id, Error Type, Error Message\n';
            finalstr = header;
            finalstr = finalstr +recordString;
        }
        if(!String.isBlank(finalstr)){
            attachFiles.put('AssetSetEligibleFreeHWBatch',finalstr);
        }
        
        if(!attachFiles.isEmpty()){
            Email_Preferences__mdt mdt = [Select Id, Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'BookingMSPConsumptionNotificationBatch' LIMIT 1];
            for (String name : attachFiles.keySet()){                
                Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                blob csvBlob = Blob.valueOf(attachFiles.get(name));
                System.debug(LoggingLevel.debug,'csvBlob :::>'+csvBlob);
                string csvname=name+'.csv';
                csvAttc.setContentType('text/csv');
                csvAttc.setFileName(csvname);
                csvAttc.setBody(csvBlob);
                attachments.add(csvAttc);
            }
            
            
            Messaging.SingleEmailMessage oEmail = new Messaging.SingleEmailMessage();
            oEmail.setSubject('Assets Failed FreeHW Check');
            oEmail.setToAddresses(new List<String>{mdt.Receipient__c});
            oEmail.setSenderDisplayName('IT-ProdOpps');
            oEmail.setHtmlBody('Hello, <br/><br/> Here is attached Report.<br/><br/>Thank You.<br/>Admin');
            List<String> ccAddresses = new List<String>();
            if(mdt.cc__c != null){
                for(String address: mdt.cc__c.split(',')){
                    ccAddresses.add(address.trim());
                }
            }
            oEmail.setCcAddresses(ccAddresses);
            oEmail.setFileAttachments(attachments);
            try{
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { oEmail });
            }catch(exception e){
                System.debug(LoggingLevel.debug,'emessage'+e.getMessage());
            }
        }
    }
}