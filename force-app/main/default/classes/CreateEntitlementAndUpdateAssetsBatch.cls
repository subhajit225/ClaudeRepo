Global class CreateEntitlementAndUpdateAssetsBatch  implements Database.Stateful, Database.batchable<contractLineItem>,System.Schedulable{
    
    global List<contractLineItem> start(Database.BatchableContext info){        
        List<contractLineItem> lstContractLineItem = [SELECT 
                                                        Id,
                                                        ServiceContractID,
                                                        ServiceContract.Term,
                                                        ServiceContract.StartDate,
                                                        ServiceContract.EndDate,
                                                        SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,
                                                        SBQQSC__QuoteLine__r.SubscribedAssetNames__c,
                                                        SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c,
                                                        SBQQSC__Account__c,
                                                        SBQQSC__Product__c,
                                                        SBQQSC__OrderProduct__c,
                                                        SBQQSC__OrderProduct__r.OrderId,
                                                        SBQQSC__OrderProduct__r.Product2Id,
                                                        SBQQSC__OrderProduct__r.Product2.ProductCode,
                                                        SBQQSC__OrderProduct__r.SerialNumber__c,          
                                                        SBQQSC__OrderProduct__r.SBQQ__RequiredBy__c,
                                                        SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c, 
                                                        SBQQSC__OrderProduct__r.ServiceDate,
                                                        SBQQSC__OrderProduct__r.Support_Start_Date__c,
                                                        SBQQSC__OrderProduct__r.Quote_Subscription_Term__c,
                                                        ServiceContract.SBQQSC__Opportunity__c,
                                                        ServiceContract.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c, 
                                                        SBQQSC__RequiredById__c,
                                                        SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c,
                                                        SBQQSC__OrderProduct__r.Order.Initial_Order_Number__c,
                                                        (SELECT 
                                                           Id,
                                                           StartDate,
                                                           EndDate,
                                                           AssetId
                                                         FROM
                                                           Entitlements)   
                                                      FROM 
                                                        contractLineItem 
                                                      WHERE 
                                                        MSP_Segment_Product__c = true
                                                      AND
                                                        SBQQSC__OrderProduct__r.SBQQ__Segmentindex__c = 1
                                                    //  AND
                                                     // ServiceContractID ='8101W000000PWsJQAW' 
                                                      //CreatedDate= today
                                                     ];
        return lstContractLineItem;
    }//End of Start

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new CreateEntitlementAndUpdateAssetsBatch(), 1);
    }
    
    global void execute(Database.BatchableContext BC, list<contractLineItem> scope){
        system.debug('processed_ContractLines' + scope); 
        Map<string,String> mapContractLineItemId = new Map<string,String>();
        Map<String,ServiceContract> mapIdAndContract = new Map<String,ServiceContract>();
        List<Entitlement> lstEntitlement = new List<Entitlement>();
        Set<String> setSerialNumber = new Set<String>();
        Map<String,Entitlement> mapEntitlementUpdate = new Map<String,Entitlement>();
        Map<String,String> mapSerialAndId = new Map<String,String>(); 
        Map<String,Asset> mapAsset = new Map<String,Asset>();
        Set<Id> clisSet = new Set<Id>();
        Set<Id> contractIdsSet = new Set<Id>();
        Set<String> subscribedAssetIds = new Set<String>();
        Map<String,Id> actualAssetIds = new Map<String,Id>();
        Set<String> setCLIRequiredByIds = new Set<String>();
        //Map<Id,Entitlement> mapAddOnEntitlement = new Map<Id,Entitlement>();
        Map<Id,List<Entitlement>> mapSCWithAddOnEntitlement = new Map<Id,List<Entitlement>>();
        try{
        for(contractLineItem objcontract : Scope){
            if(objcontract.Entitlements.size()>0){
                continue;
            }
            if(objcontract.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c!= null){
                setSerialNumber.addAll(objcontract.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c.split(','));
            }
            if(objcontract.SBQQSC__OrderProduct__r.SerialNumber__c!=null){
                setSerialNumber.addAll(objcontract.SBQQSC__OrderProduct__r.SerialNumber__c.split(','));
            } 
            if(objcontract.SBQQSC__QuoteLine__r.SubscribedAssetNames__c!=null){
                subscribedAssetIds.addAll(objcontract.SBQQSC__QuoteLine__r.SubscribedAssetNames__c.split(','));
            } 
            if(objcontract.SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c!=null){
                subscribedAssetIds.addAll(objcontract.SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c.split(','));
            }       
            system.debug('Ashwini objcontract.SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c : '+objcontract.SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c);
            if( objcontract.SBQQSC__OrderProduct__r.Order.Initial_Order_Number__c != null && objcontract.SBQQSC__RequiredById__c != null){
                setCLIRequiredByIds.add(objcontract.SBQQSC__RequiredById__c);
            }
            system.debug('Ashwini setCLIRequiredByIds : '+setCLIRequiredByIds);
            
            clisSet.add(objcontract.Id);
            contractIdsSet.add(objcontract.ServiceContractID);
            
        }
        
        if(contractIdsSet.size()>0){
            for(ServiceContract sc : [Select Id, (Select Id,StartDate, EndDate, AssetId,ContractLineItem.ServiceContractId from Entitlements) from ServiceContract where Id IN :contractIdsSet]){
                if(sc.Entitlements.size()>0){
                    mapSCWithAddOnEntitlement.put(sc.Id,sc.Entitlements);
                }
            }
        }
        
        for(Asset objAsset : [select
                                Id,
                                Name 
                             from 
                                Asset 
                             Where 
                                Name IN : setSerialNumber
                             OR 
                                Id IN : setCLIRequiredByIds
                             OR
                                Name IN :subscribedAssetIds]){
            mapSerialAndId.put(objAsset.Name,objAsset.Id);
            actualAssetIds.put(objAsset.Name,objAsset.Id);                                             
        }
        system.debug('Ashwini mapSerialAndId : '+mapSerialAndId);
        for(Entitlement objentitle : [select
                                            Id,
                                            ContractLineItemId,
                                            Order_Service_Item__c
                                         from 
                                            Entitlement 
                                         Where 
                                            //CreatedDate= today
                                            ContractLineItemId IN :clisSet 
                                          AND
                                            ContractLineItem.MSP_Segment_Product__c = true
                                          AND
                                            ContractLineItemId != null]){
            mapContractLineItemId.put(objentitle.ContractLineItemId,objentitle.id);
        }
        
        Set<Id> setOrders = new Set<Id>();
        for(contractLineItem objcontract : Scope){
            if(objcontract.Entitlements.size()>0){
                continue;
            }
            if(objcontract.SBQQSC__OrderProduct__c != null && objcontract.SBQQSC__OrderProduct__r.OrderId != null){
                setOrders.add(objcontract.SBQQSC__OrderProduct__r.OrderId);
            }
        }
        system.debug('Ashwini setOrders:' +setOrders);
        Map<Id, AggregateResult> mapOrderIdWithDateInformation = new Map<Id, AggregateResult>();
        if(setOrders.size()>0){
            for(AggregateResult ar : [Select OrderId, MIN(Support_Start_Date__c) minStartDate, MAX(Support_End_Date__c) maxEndDate from OrderItem where orderid IN :setOrders Group By OrderId]){
                mapOrderIdWithDateInformation.put((Id)ar.get('OrderId'), ar);
            }
        }
        system.debug('Ashwini mapOrderIdWithDateInformation:' +mapOrderIdWithDateInformation);
        
        for(contractLineItem objcontract : Scope){
            if(objcontract.Entitlements.size()>0){
                continue;
            }
        system.debug('Ashwini Term line objcontract '+objcontract);
        system.debug('Ashwini Term line objcontract.ServiceContract.SBQQSC__Opportunity__c '+objcontract.ServiceContract.SBQQSC__Opportunity__c);
        system.debug('Ashwini Term line objcontract.ServiceContract.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c '+objcontract.ServiceContract.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c);
        system.debug('Ashwini Term line objcontract.ServiceContract.Term '+objcontract.ServiceContract.Term);
       
           ServiceContract objServiceContract = new ServiceContract();
           objServiceContract.id = objcontract.ServiceContractID;
            
           if(objcontract.SBQQSC__OrderProduct__c != null && 
               objcontract.SBQQSC__OrderProduct__r.OrderId != null &&
               mapOrderIdWithDateInformation.containsKey(objcontract.SBQQSC__OrderProduct__r.OrderId)){
                   AggregateResult tempAr = mapOrderIdWithDateInformation.get(objcontract.SBQQSC__OrderProduct__r.OrderId);
                   system.debug('Ashwini tempAr :  '+tempAr);
                   objServiceContract.StartDate = (Date)tempAr.get('minStartDate');
                   objServiceContract.EndDate = (Date)tempAr.get('maxEndDate');
                   if(objServiceContract.StartDate!= null && objServiceContract.EndDate != null){
                    objServiceContract.Term = objServiceContract.StartDate.monthsBetween(objServiceContract.EndDate);
                    objServiceContract.Term = objServiceContract.Term + 1;
                   }
                   
           }
          
           system.debug('Ashwini objServiceContract.StartDate:' +objServiceContract.StartDate);
            system.debug('Ashwini objServiceContract.EndDate:' +objServiceContract.EndDate);
            system.debug('Ashwini objcontract.ServiceContract.Term:' +objcontract.ServiceContract.Term);
            system.debug('Ashwini objServiceContract.Term:' +objServiceContract.Term);
            system.debug('Ashwini objServiceContract.SBQQSC__RenewalTerm__c before:' +objServiceContract.SBQQSC__RenewalTerm__c);
            
           /*if((objcontract.ServiceContract.Term != 60 && objcontract.ServiceContract.Term != 62)){
               objServiceContract.SBQQSC__RenewalTerm__c = 62 - objcontract.ServiceContract.Term;
           }else if(objcontract.ServiceContract.Term == 60 || objcontract.ServiceContract.Term == 62){
               objServiceContract.SBQQSC__RenewalTerm__c = 60;
           }*/
           if(objServiceContract.Term != null && (objServiceContract.Term != 60 && objServiceContract.Term != 62)){
               objServiceContract.SBQQSC__RenewalTerm__c = 62 - objServiceContract.Term;
           }else if(objServiceContract.Term == 60 || objServiceContract.Term == 62){
               objServiceContract.SBQQSC__RenewalTerm__c = 60;
           }
           
            system.debug('Ashwini objServiceContract.SBQQSC__RenewalTerm__c after:' +objServiceContract.SBQQSC__RenewalTerm__c);
            
           mapIdAndContract.put(objcontract.ServiceContractID,objServiceContract);
            
            system.debug('Ashwini mapIdAndContract' +mapIdAndContract);
            system.debug('Ashwini mapContractLineItemId' +mapContractLineItemId);
            system.debug('Ashwini objcontract.id' +objcontract.id);
            
           if(!mapContractLineItemId.containsKey(objcontract.id)){
               List<ContractLineItem> otherContractlines = new List<ContractLineItem>();
               if(objcontract.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__c!=null && 
               objcontract.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c!=null){
               
               
                 
               List<String> serialnames = objcontract.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c.split(',');    
               for(Integer i=0;i<serialnames.size();i++){
               
               Entitlement objEntitlement = new Entitlement();
               objEntitlement.AccountId = objcontract.SBQQSC__Account__c;
               if(objcontract.SBQQSC__OrderProduct__c != null){
                   objEntitlement.Product__c = objcontract.SBQQSC__OrderProduct__r.Product2Id;
               }
               objEntitlement.ContractLineItemId = objcontract.id;
               objEntitlement.ServiceContractId = objcontract.ServiceContractID;
               objEntitlement.Name = objcontract.SBQQSC__OrderProduct__r.Product2.ProductCode;
               //objEntitlement.status = 'Inactive';
               objEntitlement.Order_Service_Item__c = objcontract.SBQQSC__OrderProduct__c;
               

               system.debug('Ashwini objServiceContract.StartDate before :' +objServiceContract.StartDate);
               system.debug('Ashwini objServiceContract.EndDate before :' +objServiceContract.EndDate);
               system.debug('Ashwini objEntitlement.StartDate before :' +objEntitlement.StartDate);
               system.debug('Ashwini objEntitlement.EndDate before : ' +objEntitlement.EndDate);
               
               
               if(objcontract.SBQQSC__OrderProduct__c != null &&
                  objServiceContract.StartDate != null &&
                  objServiceContract.EndDate != null){
                   //objEntitlement.StartDate = objcontract.SBQQSC__OrderProduct__r.Support_Start_Date__c;
                   objEntitlement.StartDate = objServiceContract.StartDate;
                   objEntitlement.EndDate = objServiceContract.EndDate;
                    system.debug('In hereeee');
               }else{
               
                   objEntitlement.StartDate = objcontract.ServiceContract.StartDate; 
                   objEntitlement.EndDate = objcontract.ServiceContract.EndDate;
               }
               
               system.debug('Ashwini objServiceContract.StartDate after :' +objServiceContract.StartDate);
               system.debug('Ashwini objServiceContract.EndDate after :' +objServiceContract.EndDate);
               system.debug('Ashwini objEntitlement.StartDate after :' +objEntitlement.StartDate);
               system.debug('Ashwini objEntitlement.EndDate after : ' +objEntitlement.EndDate);
               system.debug('Ashwini mapSerialAndId : ' +mapSerialAndId);
               system.debug('Ashwini objcontract.SBQQSC__RequiredById__c : ' +objcontract.SBQQSC__RequiredById__c);
               system.debug('Ashwini objcontract.SBQQSC__RequiredById__c : ' +objcontract.SBQQSC__RequiredById__c);
               
               if(mapSerialAndId.containsKey(serialnames[i])){
                   objEntitlement.AssetId = mapSerialAndId.get(serialnames[i]);
                   Asset objAsset = new Asset();
                   objAsset.id = mapSerialAndId.get(serialnames[i]);
                   objAsset.AccountId = objcontract.SBQQSC__Account__c;
                   objAsset.Order_Service_Item__c = objcontract.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__c; 
                   objAsset.Status ='Purchased';
                   objAsset.PurchaseDate = Date.today();
                   objAsset.Support_Start_Date__c = objcontract.ServiceContract.StartDate;
                   objAsset.Premium_Support_End_Date__c = objcontract.ServiceContract.EndDate;
                   objAsset.InstallDate = Date.today();
                   objAsset.SBQQ__QuoteLine__c = objcontract.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c;
                   mapAsset.put(objAsset.id, objAsset);
               } 
                 lstEntitlement.add(objEntitlement);
              }
            } else if(objcontract.SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c == 'MSP Consumption Renewal' && 
                 (objcontract.SBQQSC__OrderProduct__r.SerialNumber__c!=null || objcontract.SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c!=null || objcontract.SBQQSC__QuoteLine__r.SubscribedAssetNames__c!=null)){ 
             
                   if(objcontract.SBQQSC__OrderProduct__r.SerialNumber__c!=null){
                      system.debug('inside Order Product Serial Number ' + objcontract.Id);
                       List<String> serialnames = objcontract.SBQQSC__OrderProduct__r.SerialNumber__c.split(',');
                       for(Integer i=0;i<serialnames.size();i++){
                           Entitlement objEntitlement = new Entitlement();
                           objEntitlement.AccountId = objcontract.SBQQSC__Account__c;
                           if(objcontract.SBQQSC__OrderProduct__c != null){
                               objEntitlement.Product__c = objcontract.SBQQSC__OrderProduct__r.Product2Id;
                           }
                           objEntitlement.ContractLineItemId = objcontract.id;
                           objEntitlement.ServiceContractId = objcontract.ServiceContractID;
                           objEntitlement.Name = objcontract.SBQQSC__OrderProduct__r.Product2.ProductCode;
                           //objEntitlement.status = 'Inactive';
                           objEntitlement.Order_Service_Item__c = objcontract.SBQQSC__OrderProduct__c;
                           
                           if(objcontract.SBQQSC__OrderProduct__c != null &&
                              objServiceContract.StartDate != null &&
                              objServiceContract.EndDate != null){
                               //objEntitlement.StartDate = objcontract.SBQQSC__OrderProduct__r.Support_Start_Date__c;
                               objEntitlement.StartDate = objServiceContract.StartDate;
                               objEntitlement.EndDate = objServiceContract.EndDate;
                                system.debug('In hereeee');
                           }else{
                               objEntitlement.StartDate = objcontract.ServiceContract.StartDate; 
                               objEntitlement.EndDate = objcontract.ServiceContract.EndDate;
                           }
                           objEntitlement.AssetId = mapSerialAndId.get(serialnames[i]);
                           Asset objAsset = new Asset();
                           objAsset.id = mapSerialAndId.get(serialnames[i]);
                           objAsset.Premium_Support_End_Date__c = objcontract.ServiceContract.EndDate;
                           mapAsset.put(objAsset.id, objAsset);
                           lstEntitlement.add(objEntitlement);                     
                    }
                   } else if(objcontract.SBQQSC__QuoteLine__r.SubscribedAssetNames__c!=null || objcontract.SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c!=null){
                         system.debug('inside MSP Consumption Renewal' + objcontract.Id);
                         List<String> assestNames = new List<String>();
                        if(objcontract.SBQQSC__QuoteLine__r.SubscribedAssetNames__c!=null){ 
                            assestNames.addAll(objcontract.SBQQSC__QuoteLine__r.SubscribedAssetNames__c.split(','));
                        }
                        if(objcontract.SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c!=null){ 
                            assestNames.addAll(objcontract.SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c.split(','));
                        }
                         for(Integer i=0;i< assestNames.size();i++){
                          if(actualAssetIds.containsKey(assestNames.get(i))){
                          system.debug('Ashwini in else if required by');
                           Entitlement objEntitlement = new Entitlement();
                           objEntitlement.AccountId = objcontract.SBQQSC__Account__c;
                           if(objcontract.SBQQSC__OrderProduct__c != null){
                               objEntitlement.Product__c = objcontract.SBQQSC__OrderProduct__r.Product2Id;
                           }
                           objEntitlement.ContractLineItemId = objcontract.id;
                           objEntitlement.ServiceContractId = objcontract.ServiceContractID;
                           objEntitlement.Name = objcontract.SBQQSC__OrderProduct__r.Product2.ProductCode;
                           //objEntitlement.status = 'Inactive';
                           objEntitlement.Order_Service_Item__c = objcontract.SBQQSC__OrderProduct__c;
                           if(objcontract.SBQQSC__OrderProduct__c != null &&
                              objServiceContract.StartDate != null &&
                              objServiceContract.EndDate != null){
                               //objEntitlement.StartDate = objcontract.SBQQSC__OrderProduct__r.Support_Start_Date__c;
                               objEntitlement.StartDate = objServiceContract.StartDate;
                               objEntitlement.EndDate = objServiceContract.EndDate;
                                system.debug('In hereeee');
                           }else{
                               objEntitlement.StartDate = objcontract.ServiceContract.StartDate; 
                               objEntitlement.EndDate = objcontract.ServiceContract.EndDate;
                           }
                           objEntitlement.AssetId = actualAssetIds.get(assestNames.get(i));
                           lstEntitlement.add(objEntitlement);
                           Asset objAsset = new Asset();
                           objAsset.id = actualAssetIds.get(assestNames.get(i));
                           objAsset.Premium_Support_End_Date__c = objcontract.ServiceContract.EndDate;
                           mapAsset.put(objAsset.id, objAsset);                              
                         }
                       } 
                    }
                }else{
                   system.debug('inside entitlement without asset' + objcontract.Id);
                   Entitlement objEntitlement = new Entitlement();
                   objEntitlement.AccountId = objcontract.SBQQSC__Account__c;
                           if(objcontract.SBQQSC__OrderProduct__c != null){
                               objEntitlement.Product__c = objcontract.SBQQSC__OrderProduct__r.Product2Id;
                           }
                           objEntitlement.ContractLineItemId = objcontract.id;
                           objEntitlement.ServiceContractId = objcontract.ServiceContractID;
                           objEntitlement.Name = objcontract.SBQQSC__OrderProduct__r.Product2.ProductCode;
                           //objEntitlement.status = 'Inactive';
                           objEntitlement.Order_Service_Item__c = objcontract.SBQQSC__OrderProduct__c;
                           if(objcontract.SBQQSC__OrderProduct__c != null &&
                              objServiceContract.StartDate != null &&
                              objServiceContract.EndDate != null){
                               //objEntitlement.StartDate = objcontract.SBQQSC__OrderProduct__r.Support_Start_Date__c;
                               objEntitlement.StartDate = objServiceContract.StartDate;
                               objEntitlement.EndDate = objServiceContract.EndDate;
                                system.debug('In hereeee');
                           }else{
                               objEntitlement.StartDate = objcontract.ServiceContract.StartDate; 
                               objEntitlement.EndDate = objcontract.ServiceContract.EndDate;
                           }
                      lstEntitlement.add(objEntitlement);
                   }
                }   
 
           /*for(Entitlement objEntitlement :objcontract.Entitlements){
               objEntitlement.startDate =  objcontract.ServiceContract.StartDate;
               objEntitlement.endDate =  objcontract.ServiceContract.EndDate; 
               system.debug('In second date loop objEntitlement.Id: ' +objEntitlement.Id);
               system.debug('In second date loop objEntitlement.AssetId: ' +objEntitlement.AssetId);
               system.debug('In second date loop objcontract.SBQQSC__RequiredById__c: ' +objcontract.SBQQSC__RequiredById__c);
               
               if(objEntitlement.AssetId == null && objcontract.SBQQSC__RequiredById__c != null){ 
                   objEntitlement.AssetId = objcontract.SBQQSC__RequiredById__c;
               }
               
              
               mapEntitlementUpdate.put(objEntitlement.id,objEntitlement);      
           }*/
            
            if(contractIdsSet.size()>0 && mapSCWithAddOnEntitlement != null && mapSCWithAddOnEntitlement.containsKey(objcontract.ServiceContractID)){
                
            for(Entitlement entAddon : mapSCWithAddOnEntitlement.get(objcontract.ServiceContractID)){
                entAddon.startDate =  objcontract.ServiceContract.StartDate;
                entAddon.endDate =  objcontract.ServiceContract.EndDate; 
                system.debug('In second date loop objEntitlement.Id: ' +entAddon.Id);
                system.debug('In second date loop objEntitlement.AssetId: ' +entAddon.AssetId);
                system.debug('In second date loop objcontract.SBQQSC__RequiredById__c: ' +objcontract.SBQQSC__RequiredById__c);
               
                if(entAddon.AssetId == null && objcontract.SBQQSC__RequiredById__c != null){ 
                    entAddon.AssetId = objcontract.SBQQSC__RequiredById__c;
                }
                mapEntitlementUpdate.put(entAddon.id,entAddon); 
            }
          }
        }
       
        Database.insert(lstEntitlement, false); 
        Database.update(mapAsset.values(), false);
        Database.update(mapIdAndContract.values(), false);
        Database.update(mapEntitlementUpdate.values(), false);
        }
        Catch(exception ex){
            system.debug('@@ Error Details '+ex.getMessage());
            Batch_Error_Log__c bel =new Batch_Error_Log__c(Failure_Job_ID__c =bc.getJobID() ,Failure_Message__c =ex.getMessage(),Class_Name__c='CreateEntitlementAndUpdateAssetsBatch',Failure_Date__c=Date.today()); 
			try{insert bel;}
            catch(Exception e){
             system.debug('@@ Error Details '+e.getMessage());   
            }
          }
    }//End of execute

    global void finish(Database.BatchableContext info){
      system.debug('@@ finish method');
        
    }//End of finish 
}