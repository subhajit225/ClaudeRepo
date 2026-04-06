/***************************************************************************************
Author : Chaitra
Description : Third party asset tie back PRDOPS21-310 
Date : October 2020
*****************************************************************************************/

public class ThirdPartyAssetUpdateBatch implements Database.batchable<sObject>,Database.Stateful,Schedulable{ 
    public set<id> MonitorIds = new set<id>();
    public set<string> FailedOrderNumber = new set<string>(); 
    
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new ThirdPartyAssetUpdateBatch(),100);
        //Split Order Scheduled Job - Needs execution every day
        SplitOrder scbat = new SplitOrder();
        string jobID =Database.executeBatch(scbat,1);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        set<string> statusSet = new set<string>{'Internal Failure',''}; 
            List<ThirdPartyMonitor__c> monitor = [select id,Send_ASN_Acknowlegment_To__c from ThirdPartyMonitor__c where Status__c ='Start'];
        for(ThirdPartyMonitor__c TPM : monitor){ 
            TPM.Status__c = 'In Progress';
            monitorIds.add(TPM.id);
        }
        update monitor;  
        string query = 'Select id,Name,SerialNumber__c,OrderNumber__c,EDILineNumber__c,Quantity__c,Process_History__c,ShipDate__c,Status__c,JobId__c from ThirdPartyHardware__c where Status__c IN : statusSet'
            +' AND JobId__c IN: monitorIds order by OrderNumber__c,createddate';
        system.debug('Query'+query);
        
        return Database.getQueryLocator(query);
    }   
    
    public void execute(Database.BatchableContext BC, List<ThirdPartyHardware__c> ASNList){
        Map<string,Id> serialNumberAssetId = new Map<string,Id>();
        Map<string,ThirdPartyHardware__c> OI_ASN = new Map<string,ThirdPartyHardware__c>(); 
        List<OrderItem> updateOrderItem = new List<OrderItem>();
        List<Asset> updateAsset = new List<Asset>();
        List<Entitlement> updateEntList = new List<Entitlement>();
        set<string>orderNumbers = new set<string>();
        set<string> processedAsset = new set<string>();
        Integer counter;
        Map<Id,List<List<Entitlement>>> orderItemEntitlementsMap = new Map<Id,List<List<Entitlement>>>();          
          List<Scale_Entitlement__c> scaleAssetInsertList = new List<Scale_Entitlement__c>();        
        Map<string,OrderItem> OrderEdi_OrderItemMap = new Map<string,OrderItem>();
        for(ThirdPartyHardware__c asn : ASNList){
            asn.Process_History__c = '';
            asn.Status__c ='';
            if(asn.SerialNumber__c != null && asn.OrderNumber__c!=null && asn.EDILineNumber__c!=null){
                orderNumbers.add(asn.OrderNumber__c);
                if(string.isNotBlank(asn.OrderNumber__c) && string.isNotBlank(asn.EDILineNumber__c.replaceFirst('^0+', ''))){
                    OrderEdi_OrderItemMap.put(asn.OrderNumber__c+'_'+asn.EDILineNumber__c.replaceFirst('^0+', ''),null);
                }
                for(string SN : asn.SerialNumber__c.replaceAll('\\s+','').split('\\{')){
                    serialNumberAssetId.put(SN,null);
                }
            } 
        } 
        for(Asset asst :[select id,serialnumber from asset where SerialNumber IN: serialNumberAssetId.keyset() and account.Name = 'Unassigned']){
            serialNumberAssetId.put(asst.SerialNumber,asst.id);
        }
        system.debug('ASN orderNumbers'+orderNumbers);
        List<ThirdPartyHardware__c> updateThirdPartyHardware = new List<ThirdPartyHardware__c>();
        
       /****** ASN External validation START*********/
       
        for(OrderItem OI :[select id,order.EDI_Sync_Status__c,product2Id,product2.ProductCode,product2.SBQQ__SubscriptionPricing__c,product2.SBQQSC__EntitlementConversion__c, product2.Product_Level__c, product2.Product_Type__c, product2.Product_Subtype__c, order.OrderNumber,order.accountId,EDI_Line_Number__c,OrderItemNumber,SerialNumber__c,SBQQ__QuoteLine__c, Quantity,SBQQ__RequiredBy__r.Quantity,SBQQ__RequiredBy__c,
                           SBQQSC__ContractLineItem__c,SBQQ__RequiredBy__r.EDI_Line_Number__c,ServiceDate,EndDate,TPH_Quantity__c,TPH_OEM__c,TPH_Models_Gen__c,(select id,Order_Service_Item__c,Order_Service_Item__r.SBQQ__RequiredBy__c from Entitlements__r where Type='Phone Support' )   
                           from orderItem where order.OrderNumber IN : orderNumbers and EDI_Line_Number__c!=null order by SBQQ__RequiredBy__c desc NULLS FIRST]){ 
                              
                               system.debug('OI'+OI);
                               if(OrderEdi_OrderItemMap.containskey(OI.order.OrderNumber+'_'+OI.EDI_Line_Number__c.replaceFirst( '^0+', ''))){
                                   OrderEdi_OrderItemMap.put(OI.order.OrderNumber+'_'+OI.EDI_Line_Number__c.replaceFirst('^0+',''),OI);
                                   orderItemEntitlementsMap.put(OI.id,new List<List<Entitlement>>());
                                   if(!OI.Entitlements__r.isEmpty()){
                                       orderItemEntitlementsMap.get(OI.id).add(new List<Entitlement>(OI.Entitlements__r));
                                   } 
                                   else if(OI.product2.SBQQ__SubscriptionPricing__c!=null && OI.product2.SBQQSC__EntitlementConversion__c !=null){
                                       orderItemEntitlementsMap.get(OI.id).add(new List<Entitlement>{new Entitlement(Order_Service_Item__c=OI.id)});
                                   }    
                               }
                               else if(OI.SBQQ__RequiredBy__c!= null && OI.SBQQ__RequiredBy__r.EDI_Line_Number__c!=null && OrderEdi_OrderItemMap.containskey(OI.order.OrderNumber+'_'+OI.SBQQ__RequiredBy__r.EDI_Line_Number__c.replaceFirst( '^0+', ''))
                                       && orderItemEntitlementsMap.containsKey(OI.SBQQ__RequiredBy__c)){
                                           if(!OI.Entitlements__r.isEmpty()){
                                               orderItemEntitlementsMap.get(OI.SBQQ__RequiredBy__c).add(new List<Entitlement>(OI.Entitlements__r));   
                                           }
                                           else if(OI.product2.SBQQ__SubscriptionPricing__c!=null && OI.product2.SBQQSC__EntitlementConversion__c !=null){
                                               orderItemEntitlementsMap.get(OI.SBQQ__RequiredBy__c).add(new List<Entitlement>{new Entitlement(Order_Service_Item__c=OI.id)});
                                           } 
                                       }
                               orderNumbers.remove(OI.order.OrderNumber);
                           } 
        
        system.debug('OrderEdi_OrderItemMap'+OrderEdi_OrderItemMap);
        system.debug('Invalid orderNumbers'+orderNumbers);
        system.debug('orderItemEntitlementsMap'+JSON.SerializePretty(orderItemEntitlementsMap));
        set<string> serialNums ;
        for(ThirdPartyHardware__c asn : ASNList){
            system.debug('asn'+asn);
            if(asn.EDILineNumber__c==null ||asn.OrderNumber__c==null||asn.Quantity__c== null||asn.SerialNumber__c==null||asn.ShipDate__c==null){
                asn.Process_History__c += 'Mandatory fields are missing';
                asn.Status__c = 'Failed';
                updateThirdPartyHardware.add(asn); 
                continue;  
            }
            else if(orderNumbers.contains(asn.OrderNumber__c)){
                asn.Process_History__c += 'Order Number is invalid \n';
                asn.Status__c = 'Failed';
                updateThirdPartyHardware.add(asn);
                continue;  
            }
            try{
                date.parse(asn.ShipDate__c);
            }
            catch(exception e){
                asn.Process_History__c += 'Invalid date,valid date format mm/dd/yyyy';
                asn.Status__c = 'Failed';
                updateThirdPartyHardware.add(asn); 
                continue;  
            }
            string key = asn.OrderNumber__c+'_'+asn.EDILineNumber__c.replaceFirst('^0+', '');
            OrderItem OI  =  OrderEdi_OrderItemMap.get(key); 
            boolean iserror = false;
            if(OI == null){
                asn.Process_History__c += 'EDI # is invalid \n';
                updateThirdPartyHardware.add(asn);
                iserror = true ;
            }
            else{ 
                if(OI_ASN.containsKey(OI.id)){
                    //asn.Process_History__c += 'Duplicate record with ASN: '+OI_ASN.get(OI.id).id+'\n';
                    asn.Process_History__c += 'Asset is already assigned to order \n';
                    asn.Status__c = 'Failed';
                    updateThirdPartyHardware.add(asn); 
                    continue;       
                } 
                if(OI.order.EDI_Sync_Status__c!='N'){
                    asn.Process_History__c += 'Failed to send ASN for software order \n';
                    asn.Status__c = 'Internal Failure';
                    updateThirdPartyHardware.add(asn);
                    continue;       
                }
                else if(OI.SerialNumber__c!= null){
                    asn.Process_History__c += 'Asset is already assigned to order \n';
                    iserror = true ;
                }
                else if(!asn.Name.equalsIgnoreCase(OI.product2.ProductCode)){
                    asn.Process_History__c += 'Product Name mismatch with rubrik order " '+OI.product2.ProductCode+'" \n';
                    iserror = true ;
                }
                else{
                    asn.OrderItem__c = OI.id ;
                    if(OI.Quantity != asn.Quantity__c && OI.product2.Product_Level__c == null){ 
                        asn.Process_History__c += 'Quantity doesnt match with orderItem \n';
                        iserror = true ;
                    }
                    serialNums = new set<string>(asn.SerialNumber__c.replaceAll('\\s+','').split('\\{'));
                    system.debug('serialNum1'+serialNums.size()+'Quantity'+OI.Quantity);

                    //Jira#RWD-170
                    if(OI.product2.Product_Level__c == 'LOD Software' || OI.product2.Product_Level__c == 'Hybrid Software'){ 
                        TPH_Nodes__c TPHNodes = TPH_Nodes__c.getInstance(OI.TPH_OEM__c+'-'+OI.TPH_Models_Gen__c);
                        Integer nodesCount = (TPHNodes != null) ? (Integer)TPHNodes.Nodes_Count__c : 1; 
                        if(serialNums.size() != Integer.valueOf(OI.TPH_Quantity__c)/nodesCount){
                            asn.Process_History__c += '# of Quantity and Serial Number Mismatch \n';
                            iserror = true ;
                        }
                    }else{
                        if(serialNums.size() != OI.Quantity && OI.product2.Product_Level__c == null){ 
                            asn.Process_History__c += '# of Quantity and Serial Number Mismatch \n';
                            iserror = true ;
                        } 
                    }
                    for(string SN : serialNums){
                        if(serialNumberAssetId.get(SN) == null || processedAsset.contains(SN)){
                            asn.Process_History__c +='Serial Number '+SN+' is invalid or already in use \n';
                            iserror = true ;
                            break ;
                        }
                        else{
                            processedAsset.add(SN);
                        }
                    }
                }  
            }
            if(iserror){
                asn.Status__c = 'Failed';
                FailedOrderNumber.add(asn.OrderNumber__c);
            }
            if(OI != null){  
                OI_ASN.put(OI.id,asn);       
            }
        }
        
        for(ThirdPartyHardware__c asn : ASNList){
            if(asn.Status__c =='Failed' || asn.Status__c =='Internal Failure'){
                continue;
            }
            else if(FailedOrderNumber.contains(asn.OrderNumber__c)){
                asn.Status__c = 'Failed';
                asn.Process_History__c += 'Other lines of this order has failed to process';
            }
            else{
                string key = asn.OrderNumber__c+'_'+asn.EDILineNumber__c.replaceFirst('^0+', '');
                Boolean entSerialNumMatch = true;
                serialNums = new set<string>(asn.SerialNumber__c.replaceAll('\\s+','').split('\\{'));
                OrderItem OI  =  OrderEdi_OrderItemMap.get(key); 
                updateOrderItem.add(new orderItem(id=OI.id, SerialNumber__c= asn.SerialNumber__c.replaceAll('\\s+','').replaceall('\\{',',')));
                
                for(string SN: serialNums){
                    boolean scaleErr = false;
                    updateAsset.add(new asset(id = serialNumberAssetId.get(SN),
                                              Order_Service_Item__c=OI.id,
                                              SBQQ__QuoteLine__c= OI.SBQQ__QuoteLine__c,
                                              AccountId= OI.order.accountId,
                                              Status='Purchased' ,
                                              Product2Id=OI.Product2Id,
                                              SerialNumber =SN,
                                              Support_Start_Date__c = OI.ServiceDate,
                                              Premium_Support_End_Date__c= OI.EndDate,
                                              PurchaseDate = date.parse(asn.ShipDate__c),
                                              InstallDate = date.parse(asn.ShipDate__c))); 
                       if(OI != null && !scaleErr && (OI.product2.Product_Level__c == 'LOD Software' || OI.product2.Product_Level__c == 'Hybrid Software' ||
                                                     (OI?.Product2?.Product_Level__c == 'OnPrem' && (OI?.Product2?.Product_Type__c =='Foundation Edition' || OI?.Product2?.Product_Type__c =='Business Edition' || OI?.Product2?.Product_Type__c =='Enterprise Edition' ) && OI?.Product2?.Product_Subtype__c == null))){
                        Id entId = orderItemEntitlementsMap.containsKey(asn.orderItem__c) && !orderItemEntitlementsMap.get(asn.orderItem__c).isEmpty() && !orderItemEntitlementsMap.get(asn.orderItem__c)[0].isEmpty() ? orderItemEntitlementsMap.get(asn.orderItem__c)[0][0].id :null ;
                        if(entId == null){
                              scaleErr = true;
                              if(OI_ASN.containsKey(OI.id)){
                                OI_ASN.get(OI.id).Process_History__c += 'Entitlement is missing to create scale asset\n'; 
                                OI_ASN.get(OI.id).Status__c = 'Internal Failure';
                }
                        }else{
                            scaleAssetInsertList.add(new Scale_Entitlement__c(Asset__c = serialNumberAssetId.get(SN), 
                                                                    Type__c= 'Non-Scale',
                                                                    Sub_Type__c ='Third Party',
                                                                    Contract_Line_Item__c= OI.SBQQSC__ContractLineItem__c,
                                                                    Order_Product__c= OI.Id,
                                                                    Entitlement__c= entId));
                          }  
                       }                       
                }
                if(OI != null && OI.product2.Product_Level__c == null){  // skip entitlement update for v2 sku's
                for(List<Entitlement> entList: orderItemEntitlementsMap.get(asn.orderItem__c)){
                    if(entList.size()!= serialNums.size()){
                        asn.Process_History__c += entList[0].Order_Service_Item__c +' : # of Entitlement and Asset mismatch \n';
                        asn.Status__c = 'Internal Failure';        
                    }
                    else if(entList[0].id == null){
                        asn.Process_History__c += 'No Entitlement found for : '+entList[0].Order_Service_Item__c +'\n';
                        asn.Status__c = 'Internal Failure'; 
                    }
                    else{
                        integer j = 0;
                        for(string SN : serialNums){
                            entList[j].AssetId = serialNumberAssetId.get(SN);
                            updateEntList.add(entList[j]);
                            j++;
                        }  
                    }
                } 
                }

                
            }  
            
        }
        system.debug('Asset'+JSON.serialize(updateAsset)); 
        system.debug('updateOrderItem'+JSON.serialize(updateOrderItem)); 
        system.debug('updateEntList'+JSON.serialize(updateEntList));
        /****** ASN External validation END*********/ 
        
       
        // Update entitlements
        integer i= 0;
        if(!updateEntList.isEmpty()){
        for (Database.SaveResult sr: Database.update(updateEntList, false)) { 
            Id OrderItemId = OI_ASN.containskey(updateEntList[i].Order_Service_Item__c) ? updateEntList[i].Order_Service_Item__c:
            (updateEntList[i].Order_Service_Item__c!=null && OI_ASN.containskey(updateEntList[i].Order_Service_Item__r.SBQQ__RequiredBy__c))?updateEntList[i].Order_Service_Item__r.SBQQ__RequiredBy__c:null;
            system.debug('Ent orderItem'+updateEntList[i].Order_Service_Item__c);
            system.debug('Ent ASN'+OI_ASN.get(OrderItemId));
            if(OrderItemId!=null){
                if (!sr.isSuccess()) {    
                    for (Database.Error err: sr.getErrors()) {
                        if(OI_ASN.get(OrderItemId).Process_History__c==null){
                            OI_ASN.get(OrderItemId).Process_History__c = err.getMessage() ;
                        }
                        else{
                            OI_ASN.get(OrderItemId).Process_History__c += ';'+err.getMessage(); 
                        }
                        OI_ASN.get(OrderItemId).Status__c = 'Internal Failure';
                    }
                }
                else{
                    system.debug('Ent Success'+OrderItemId);
                    if(OI_ASN.get(OrderItemId).Status__c != 'Internal Failure'){
                        OI_ASN.get(OrderItemId).Status__c = 'Success'; 
                    }
                    OI_ASN.get(OrderItemId).Process_History__c += updateEntList[i].Order_Service_Item__c+' : Entitlements updated \n' ;                        
                }
            }
            else{
                system.debug('OI is null Entitlement '+sr.getId());
            }
            i++;
        }
        }
        i=0;
         if(!scaleAssetInsertList.isEmpty()){ 
           for (Database.SaveResult sr: Database.insert(scaleAssetInsertList, false)) { 
            Id OrderItemId = scaleAssetInsertList[i].Order_Product__c;
            if(OrderItemId!=null){
                if (!sr.isSuccess()) {    
                    for (Database.Error err: sr.getErrors()) {
                        if(OI_ASN.get(OrderItemId).Process_History__c==null){
                            OI_ASN.get(OrderItemId).Process_History__c = err.getMessage()+'\n' ;
                        }
                        else{
                            OI_ASN.get(OrderItemId).Process_History__c += ';'+err.getMessage()+'\n'; 
                        }
                        OI_ASN.get(OrderItemId).Status__c = 'Internal Failure';
                    }
                }
                else{
                    system.debug('ScaleEnt Success'+OrderItemId);
                    if(OI_ASN.get(OrderItemId).Status__c != 'Internal Failure'){
                        OI_ASN.get(OrderItemId).Status__c = 'Success'; 
                    }
                    OI_ASN.get(OrderItemId).Process_History__c += OrderItemId+'-'+scaleAssetInsertList[i].Asset__c +': Scale Asset is inserted \n' ;                        
                }
            }
            else{
                system.debug('OI is null Entitlement '+sr.getId());
            }
            i++;
        } 
        }
        
        // Update Asset
        i= 0;
        for (Database.SaveResult sr: Database.update(updateAsset, false)) {
            system.debug('OI is null Asset '+updateAsset[i].id+'orderItem'+updateAsset[i].Order_Service_Item__c);
            if (!sr.isSuccess()) {         
                for (Database.Error err: sr.getErrors()) {
                    if(OI_ASN.get(updateAsset[i].Order_Service_Item__c).Process_History__c==null){
                        OI_ASN.get(updateAsset[i].Order_Service_Item__c).Process_History__c = err.getMessage() ;
                    }
                    else{
                        OI_ASN.get(updateAsset[i].Order_Service_Item__c).Process_History__c += err.getMessage() ; 
                    }
                    
                }
                OI_ASN.get(updateAsset[i].Order_Service_Item__c).Status__c = 'Internal Failure';
            }
            else{
                if(OI_ASN.get(updateAsset[i].Order_Service_Item__c).Status__c != 'Internal Failure')
                    OI_ASN.get(updateAsset[i].Order_Service_Item__c).Status__c = 'Success'; 
                OI_ASN.get(updateAsset[i].Order_Service_Item__c).Process_History__c += updateAsset[i].SerialNumber+' Asset updated \n' ; 
            }
            i++;
        }
        
        // Update Order Product
        i=0;
        for (Database.SaveResult sr: Database.update(updateOrderItem, false)) { 
            system.debug('OI in OrderItem '+updateOrderItem[i].id); 
            if (!sr.isSuccess()) { 
                for (Database.Error err: sr.getErrors()) {
                    if(OI_ASN.get(updateOrderItem[i].id).Process_History__c==null){
                        OI_ASN.get(updateOrderItem[i].id).Process_History__c = err.getMessage() ;
                    }
                    else{
                        OI_ASN.get(updateOrderItem[i].id).Process_History__c += err.getMessage() ; 
                    }
                }
                OI_ASN.get(updateOrderItem[i].id).Status__c = 'Internal Failure';
            }
            else{
                if(OI_ASN.get(updateOrderItem[i].id).Status__c != 'Internal Failure')
                    OI_ASN.get(updateOrderItem[i].id).Status__c = 'Success';
                OI_ASN.get(updateOrderItem[i].id).Process_History__c += 'Order Product updated \n' ;               
            }
            i++;
        } 
        system.debug('Final TPH update'+JSON.serializepretty(OI_ASN.values()));
        updateThirdPartyHardware.addall(OI_ASN.values());
        for(ThirdPartyHardware__c TPH :updateThirdPartyHardware){
            if(TPH.Process_History__c.length()>131072){
                TPH.Process_History__c = TPH.Process_History__c.substring(0,131072);
            } 
        }
        Database.update(updateThirdPartyHardware,false);                  
  
        // #RWD-170 - END - Create Scale Entitlement Assets                   
                 
    }  
    
    public void finish(Database.BatchableContext BC){ 
        
        Map<id,AggregateResult> FailedResults = new Map<id,AggregateResult>([SELECT JobId__c Id,count(id) FROM ThirdPartyHardware__c where Status__c IN ('Internal Failure','Failed','')
                                                                             and JobId__c IN : MonitorIds GROUP BY JobId__c ]);
        List<ThirdPartyMonitor__c> updateMonitorLog = [select id,Send_ASN_Acknowlegment_To__c from ThirdPartyMonitor__c where id IN : MonitorIds];
        for(ThirdPartyMonitor__c TPM : updateMonitorLog){  
            if(TPM.Send_ASN_Acknowlegment_To__c != null && TPM.Send_ASN_Acknowlegment_To__c.contains('Distributor') &&  System.Label.Send_auto_ASN_acknowlegment.equalsIgnoreCase('true') && !TPM.Send_ASN_Acknowlegment_To__c.contains('Arrow-SFTP') ){
                TPM.Send_ASN_Acknowlegment_To__c+=';Arrow-SFTP';
            }
            TPM.Status__c = FailedResults.containskey(TPM.id) ? 'Failed' : 'Success';  
        }
        system.debug('updateMonitorLog'+updateMonitorLog);
        database.update(updateMonitorLog,false); 
        
        
    } 
}