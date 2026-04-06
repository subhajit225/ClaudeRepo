public with sharing class POItemStageHelperClass {         
    
  static Map<Id,PO_Item_Stage__c> poItemsToUpdate = new Map<Id,PO_Item_Stage__c>();  
  static Set<String> goProducts = new Set<String>(); 
  static Map<string,POValidation_ErrorCode__c> validationCodes = POValidation_ErrorCode__c.getAll();  
  public static set<Id> failedStgPOId = new set<id>();
  public static Boolean onlyValidate = false;
 public static void populateFieldsOnInsert(List<PO_Item_Stage__c> poItemsList,Map<Id, PO_Item_Stage__c> oldMap){ 
      map<string,SBQQ__QuoteLine__c> prodCodeIdMap = new map<string,SBQQ__QuoteLine__c>(); 
      set<id> stagePOId = new set<id>();
       String regexForGettingNumericValue;
       
        Map<String,Sfdc_Disti_Mapping__mdt> getMetadatBasedOnLabel = new Map<String,Sfdc_Disti_Mapping__mdt>();
        Map<String,Order_control__mdt> getOrderControlMetadatBasedOnLabel = new Map<String,Order_control__mdt>();
        for(Order_control__mdt ordermetadata : [Select Id,Value__c ,DeveloperName  from Order_control__mdt where DeveloperName = 'Regex_For_Subscription_Term' OR DeveloperName = 'Default_Price_Format']){
        getOrderControlMetadatBasedOnLabel.put(ordermetadata.DeveloperName,ordermetadata);
        }
        if(getOrderControlMetadatBasedOnLabel.containskey('Regex_For_Subscription_Term')){
        regexForGettingNumericValue = getOrderControlMetadatBasedOnLabel.get('Regex_For_Subscription_Term').Value__c;
        }
        Sfdc_Disti_Mapping__mdt getmeta = OrderInserthelper.getDistributorMetadata(null);
       
      for(PO_Item_Stage__c poItem: poItemsList){
         if(oldMap == null || oldMAp.get(poItem.id)!=null){

          if(poItem.ProductCode__c != null){ 
              prodCodeIdMap.put(poItem.ProductCode__c,null);
              stagePOId.add(poItem.Stage_PO__c);
          }
           /// Logic For getting integer from Subscription Term
           if(poItem.Item_Subscription_Term__c!=null){
              String subscriptionText = poItem.Item_Subscription_Term__c;
              subscriptionText = subscriptionText.replaceAll( regexForGettingNumericValue, '');
             if(!String.isBlank(subscriptionText)){
             Integer getintegerFromString = subscriptionText.isNumeric() ? Integer.valueOf(subscriptionText):Integer.valueOf(Decimal.valueOf(subscriptionText));
             poItem.SubscriptionTerm__c = getintegerFromString;
             }
             }  
          } 
      }
      Map<Id,PO_Stage__c> getStagePo = new Map<Id,PO_Stage__c>([Select Id,EDI_DISTI_ID__c,RecordType.DeveloperName,Distributor_Name__c   from PO_Stage__c where Id IN : stagePOId]);
      system.debug('prodCodeIdMap.keyset()' + prodCodeIdMap.keyset());
      system.debug('stagePOId' + stagePOId);
      
      for(SBQQ__QuoteLine__c qli:[select SBQQ__Product__c,SBQQ__ProductCode__c,SBQQ__Product__r.SBQQ__SubscriptionPricing__c from SBQQ__QuoteLine__c where SBQQ__ProductCode__c IN: prodCodeIdMap.keyset() and SBQQ__Quote__c IN (select Quote__c from PO_Stage__c where id IN: stagePOId)] ){
          prodCodeIdMap.put(qli.SBQQ__ProductCode__c.toLowercase(),qli);
          
      }
      for(PO_Item_Stage__c poItem: poItemsList){
           
             if(oldMap == null || oldMAp.get(poItem.id)!=null){
        if(getStagePo.containskey(PoItem.Stage_PO__c) && getStagePo.get(PoItem.Stage_PO__c).Distributor_Name__c!=null && getStagePo.get(PoItem.Stage_PO__c).EDI_DISTI_ID__c == 'PO PDF'){
        Sfdc_Disti_Mapping__mdt  metarecord = Orderinserthelper.distiMetadataMapBasedOnLabel.get(getStagePo.get(PoItem.Stage_PO__c).Distributor_Name__c.tolowercase().deleteWhitespace());
        String amountFormatt;
        String formattStringForQty;
        String formattStringForUnitPrice;

        String stringToBeParsed;
        if(metarecord!=null){
          if(poItem.quantityPoItem__c!=null){
            formattStringForQty = PostageHelper.getFormatBasedOnAmountByGlynt(poItem.quantityPoItem__c,metarecord);
        } 
         if(poItem.Item_Unit_Price__c!=null){
            formattStringForUnitPrice = PostageHelper.getFormatBasedOnAmountByGlynt(poItem.Item_Unit_Price__c,metarecord);
        }
            
      if(poItem.quantityPoItem__c!=null && formattStringForQty!=null){
      String quantityFormatt = POStageHelper.getamount(formattStringForQty , poItem.quantityPoItem__c);
      String convertStringToDecimal = Order_control__mdt.getInstance('Regex_For_Subscription_Term').Value__c;
      String qunatityWithCharacters = quantityFormatt.replaceAll(convertStringToDecimal, '');
      Decimal decimalValue = Decimal.valueOf(qunatityWithCharacters.deleteWhitespace());
      poItem.Quantity__c = decimalValue;
      }
  
            
      if(poItem.Item_Unit_Price__c!=null){
      amountFormatt = POStageHelper.getamount(formattStringForUnitPrice , poItem.Item_Unit_Price__c);
      poItem.UnitPrice__c = Decimal.valueOf(amountFormatt.deleteWhitespace());
      }else{
      poItem.UnitPrice__c = 0;
      }
        }
        }
           
           
           
          if(poItem.UnitPrice__c == 0.01 && getStagePo.get(poItem.Stage_PO__c).RecordType.DeveloperName == 'Promark'){ //PRDOPS23-74 Adding condition for Promark only
              poItem.UnitPrice__c = 0;
          }
                 system.debug('prodCodeIdMap is #### ' + prodCodeIdMap);
          if(prodCodeIdMap!=null && poItem?.ProductCode__c != null && prodCodeIdMap?.get(poItem?.ProductCode__c.toLowercase())!=null && prodCodeIdMap.containskey(poItem?.ProductCode__c.toLowercase())){
              system.debug('map is ' + prodCodeIdMap);
              system.debug('key is ' + prodCodeIdMap.get(poItem.ProductCode__c.trim().toLowercase()));
              poItem.Product__c = prodCodeIdMap?.get(poItem?.ProductCode__c.trim().toLowercase()).SBQQ__Product__c;
              SBQQ__QuoteLine__c qli = prodCodeIdMap?.get(poItem?.ProductCode__c.trim().toLowercase());
              if(qli.SBQQ__Product__r.SBQQ__SubscriptionPricing__c==null && getStagePo.containsKey(PoItem.Stage_PO__c) && getStagePo.get(PoItem.Stage_PO__c).EDI_DISTI_ID__c == 'PO PDF')
                  poItem.SubscriptionTerm__c = null;
          }
       }
     }   	
  } 
   public static void validationCheck(List<PO_Stage__c> poList, Map<Id, PO_Stage__c> oldMap, Map<id,opportunity> oppMap) {

      Map<Id, PO_Stage__c> poListUpdatedValues = new Map<id,PO_Stage__c>();
      List<PO_Stage__c> GPL_PO = new List<PO_Stage__c>();

      set<Id> GPLOppIds = new set<Id>();

       for(PO_Stage__c poStage : poList){
         system.debug('poStage.'+poStage.PO_Validation_Status__c);
          if((poStage.Expected_number_of_POs__c==1 || poStage.Expected_number_of_POs__c==null) && 
              poStage.PO_Validation_Status__c == 'Staged' && !failedStgPOId.contains(poStage.id) &&
              oldMap.get(poStage.id).PO_Validation_Status__c != poStage.PO_Validation_Status__c){
                      if(poStage.Opportunity__c!=null && oppMap != null && oppMap.get(poStage.Opportunity__c) != null && oppMap.get(poStage.Opportunity__c).Sell_to_Partner__c != null ){
                         GPL_PO.add(poStage); 
                         GPLOppIds.add(poStage.Opportunity__c);  
                      }
          } 
      }
      for(Product2 prod: [Select Id, Product_Subtype__c, ProductCode from Product2 where   Product_Payment_Option__c='Annual']){
          goProducts.add(prod.ProductCode);
      }
      if(!GPL_PO.isEmpty()){
          System.debug('CP GPL_PO :'+GPL_PO);
          ValidateStagePOWithOrder(GPL_PO,GPLOppIds);
      }else{
          // Stage Po Validation Part is shifted to SpliPoValidation class - PRDOPS22-165
          return;
      }
      
    }
    /***********************************************************************  
     Description : Fcus-9 , used to validate single stage PO with EDI Order 
   ***********************************************************************/
   
    public static void ValidateStagePOWithOrder(List<PO_Stage__c> stagePOList , set<Id> oppIds){
       set<PO_Stage__c> poStagesToUpdate = new set<PO_Stage__c>();
       set<Id>  succStgPOIds = new set<id>();
       set<Id>  excludeStgPOIds = new set<id>();
       set<Id>  multipleOrdStgIds = new set<id>();
       set<id> processedPOItem = new set<id>();
       set<id> processedOrderItemId = new set<id>();
       Map<String,String> poItemWithDiffMap = new Map<String,String>();
       Map<Id,OrderItem> OIToUpdate = new Map<Id,OrderItem>();
       Map<Id,id> ordStgPOId = new Map<id,id>();
       Map<Id,Order> stgPOOrdMap = new Map<id,Order>();
       Map<string,List<OrderItem>> ordIdProdCodeOrderItmMap = new Map<string,List<OrderItem>>();
       Map<string,List<PO_Item_Stage__c>> stagePOProdCodePOItmMap = new Map<string,List<PO_Item_Stage__c>>();
       Map<Id,Id>OppIdStgId = new Map<Id,Id>();
       List<PO_Item_Stage__c> poItemsList = new List<PO_Item_Stage__c>();
       List<PO_Stage_Errors__c> stageItemErrorCodes = new List<PO_Stage_Errors__c>();
       
       for(PO_Item_Stage__c poItem : [select Id,Quote_Line__c, Name, Stage_PO__c,Stage_PO__r.name,Stage_PO__r.Quote__c,Stage_PO__r.Opportunity__c,Stage_PO__r.Opportunity__r.Distributor_Lookup__c,Stage_PO__r.TotalAmount__c, Quantity__c, UnitPrice__c,
        Product__c, SubscriptionTerm__c, ProductCode__c,Buyer_Part_Number__c, EDI_Line_Number__c
          from PO_Item_Stage__c where Stage_PO__c in : stagePOList AND ProductCode__c NOT IN :Constants.DUMMY_PRODUCTS]){
            poItemsList.add(poItem);
            //OppIdStgId.put(poItem.Stage_PO__r.Opportunity__c,poItem.Stage_PO__c);
            string key = poItem.Stage_PO__c+'::'+poItem.ProductCode__c;
            if(stagePOProdCodePOItmMap.get(key)!=null){
                stagePOProdCodePOItmMap.get(key).add(poItem);
            }
            else{
                stagePOProdCodePOItmMap.put(key,new List<PO_Item_Stage__c>{poItem});
            }
          }
          for(PO_Stage__c stgPO:stagePOList){
              OppIdStgId.put(stgPO.Opportunity__c,stgPO.id);
          }
        for(Order ord: [SELECT Id, name, SBQQ__Quote__c, TotalAmount, OpportunityId,Sell_to_Partner__c,Bill_To_Name__c, 
          (SELECT Id, OrderId, Order.SBQQ__Quote__c, Quantity, ListPrice, SBQQ__SubscriptionTerm__c,Sales_Price__c,Product2.ProductCode,TotalPrice
          FROM OrderItems) FROM Order WHERE OpportunityId IN : oppIds])  {
          if(ord.Sell_to_Partner__c!=null && ord.Bill_To_Name__c != ord.Sell_to_Partner__c){
                Id stgPOId = OppIdStgId?.get(ord?.OpportunityId);
                if(stgPOId!=null){
                    if(stgPOOrdMap.containsKey(stgPOId)){
                       multipleOrdStgIds.add(stgPOId);
                    }
                    stgPOOrdMap.put(stgPOId,ord);
                    ordStgPOId.put(ord.id,stgPOId);
                }
                
                ordIdProdCodeOrderItmMap.put(ord.id,new List<OrderItem>());
                for(OrderItem OI : ord.OrderItems){
                  string key = ord.id+'::'+OI.Product2.ProductCode;
                  if(ordIdProdCodeOrderItmMap.get(key)!=null){
                      ordIdProdCodeOrderItmMap.get(key).add(OI);
                  }
                  else{
                      ordIdProdCodeOrderItmMap.put(key,new List<orderItem>{OI});
                  }
                } 
              }
          }
       for(PO_Stage__c stagePO : stagePOList){
           Order ord = stgPOOrdMap?.get(stagePO?.id);
           if(ord == null|| multipleOrdStgIds.contains(stagePO.id)){
             //stagePO.adderror('There is no Order to validate');
             string errmsg = ord == null ? 'EDI Order not found' : 'Multiple EDI Orders Found';
             excludeStgPOIds.add(stagePO.id);
             stageItemErrorCodes.add(new PO_Stage_Errors__c(Name = 'PO-100', Error_Code__c = 'PO-100', 
                       Error_Message__c = errmsg, 
                              PO_Stage_Id__c = stagePO.id,
                              Error_Type__c = 'System Error'));
             continue ;
           }
           if(!SplitPOValidation.isTolerableDifference(stagePO.TotalAmount__c,ord.TotalAmount)){
                  stageItemErrorCodes.add(new PO_Stage_Errors__c(Name = 'PO-16', Error_Code__c = 'PO-16', 
                              Error_Message__c = 'Price mismatch with Order.', 
                              PO_Stage_Id__c = stagePO.id,
                              Error_Type__c = 'External'
                          ));
                  poStagesToUpdate.add(new PO_Stage__c(Id = stagePO.id, PO_Validation_Status__c = 'Failure'));
                  failedStgPOId.add(stagePO.id);
              }
       }
       system.debug('stagePOProdCodePOItmMap'+JSON.SerializePretty(stagePOProdCodePOItmMap));
       system.debug('ordIdProdCodeOrderItmMap'+JSON.SerializePretty(ordIdProdCodeOrderItmMap));
        for(PO_Item_Stage__c poItem: poItemsList){
         system.debug('poItem start'+JSON.serialize(poItem));
         system.debug('poItem processedPOItem'+JSON.serialize(processedPOItem));
         system.debug('POItm prdCode:'+poItem.ProductCode__c);
         if(!processedPOItem.contains(poItem.id)){
          List<OrderItem> OIList = new List<OrderItem>();
          OIList =  ordIdProdCodeOrderItmMap?.get(stgPOOrdMap?.get(poItem.Stage_PO__c).id+'::'+poItem?.ProductCode__c) ;
          system.debug('OIList'+JSON.serialize(OIList));
          if(OIList ==null || OIList.isEmpty()){ 
             stageItemErrorCodes.add(new PO_Stage_Errors__c(Name ='PO-09', Error_Code__c ='PO-09', 
                                              Error_Message__c= validationCodes.get('PO-09') != null? validationCodes.get('PO-09').Error_Issue__c : system.label.Generic_Validation_Error_Mgs+':'+poItem.ProductCode__c , 
                                              PO_Stage_Id__c = poItem.Stage_PO__c,
                                              PO_Stage_Id__r = poItem.Stage_PO__r,
                                              PO_Stage_Item_Id__c = poItem.id,
                                              PO_Stage_Item_Id__r = poItem,
                                              Error_Type__c = 'External'));                                    
          }
          else{
              String distributorForOppty = '';
              String distributorForStagePo = ''; 
              String distioppty = poItem?.Stage_PO__r?.Opportunity__r?.Distributor_Lookup__c;
              String distystagePo = stgPOOrdMap?.get(poItem.Stage_PO__c)?.Bill_To_Name__c;
              if(distioppty!=null && OrderinsertHelper.getDistributorMetadata(distioppty)!=null)
              distributorForOppty =  OrderinsertHelper.getDistributorMetadata(distioppty).Po_Disti_Type__c;
              if(distystagePo!=null && OrderinsertHelper.getDistributorMetadata(distystagePo)!=null)
              distributorForStagePo =  OrderinsertHelper.getDistributorMetadata(distystagePo).Po_Disti_Type__c;

              if(goProducts.contains(poItem.ProductCode__c) && (distributorForOppty!=null && distributorForOppty == 'INGRAM') &&
              (distributorForStagePo!=null && distributorForStagePo == 'INGRAM')){
               Boolean isSuccess =validateGOProducts(OIList,stagePOProdCodePOItmMap.get(poItem.Stage_PO__c+'::'+poItem.ProductCode__c),processedPOItem,processedOrderItemId,poItem.Stage_PO__c,OIToUpdate,stageItemErrorCodes);  
               if(!isSuccess) {
                 failedStgPOId.add(poItem.Stage_PO__c);
                 poStagesToUpdate.add(new PO_Stage__c(Id = poItem.Stage_PO__c, PO_Validation_Status__c = 'Failure'));
               }
          }
         else { // non-go products
            set<string> errCodesFinal = new set<string>();
            Id OIMatchId;
            Id OrdMatchId;
            for(OrderItem OI : OIList){ 
              system.debug('OI::'+JSON.serialize(OI));
              set<string> errCodes = new set<string>(); 
              if(!processedOrderItemId.contains(OI.id)) {
                     if(OI.Quantity != poItem.Quantity__c) errCodes.add('quantityMismatch');
                     Decimal POITotalPrice = poItem.UnitPrice__c * poItem.Quantity__c;
                     if(!SplitPOValidation.isTolerableDifference(OI.TotalPrice,POITotalPrice) &&
                      !(OI.TotalPrice == POITotalPrice && OI.TotalPrice == 0 && POITotalPrice == 0)){   
                        errCodes.add('totalMismatch');  
                        poItemWithDiffMap.put(poItem.Id,String.valueOf(Math.abs(OI.TotalPrice - POITotalPrice).setScale(2, System.RoundingMode.HALF_UP))); 
                     }
                     if(OI.SBQQ__SubscriptionTerm__c != poItem.SubscriptionTerm__c)errCodes.add('subscriptionMismatch'); 
                 if(errCodes.isEmpty()){
                     processedOrderItemId.add(OI.id);
                     errCodesFinal.clear();
                     OIMatchId = OI.id ;
                     OrdMatchId = OI.orderId;
                     break;
                 }
                 system.debug('errCodes'+JSON.serialize(errCodes));
                 system.debug('errCodesFinal'+JSON.serialize(errCodesFinal));
                  if(errCodesFinal.isEmpty() || errCodes.size() < errCodesFinal.size()){
                     errCodesFinal =  errCodes;
                     OIMatchId = OI.id ;
                     OrdMatchId = OI.orderId;
                  }   
              } 
            }
            processedPOItem.add(poItem.id);
            if(OIMatchId != null){
                OIToUpdate.put(OIMatchId,new OrderItem(id=OIMatchId ,OrderId=OrdMatchId,EDI_Line_Number__c = poItem.EDI_Line_Number__c, Buyer_Part_Number__c = poItem.Buyer_Part_Number__c));
            }    
            if(!errCodesFinal.isEmpty()){
               if(errCodesFinal.contains('quantityMismatch')){
                    stageItemErrorCodes.add(new PO_Stage_Errors__c(Name = 'PO-11', Error_Code__c ='PO-11' , 
                                                              Error_Message__c= validationCodes.get('PO-11') != null? validationCodes.get('PO-11').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                              PO_Stage_Id__c = poItem.Stage_PO__c,
                                                              PO_Stage_Item_Id__c = poItem.Id,
                                                              PO_Stage_Id__r = poItem.Stage_PO__r,
                                                              PO_Stage_Item_Id__r = poItem,
                                                              Error_Type__c = 'External'
                                                             ));
               }
               if( errCodesFinal.contains('totalMismatch')){
                String additionDiffString =poItemWithDiffMap.get(poItem.Id)!= Null?+ ', Difference : '+ poItemWithDiffMap.get(poItem.Id):'';
                stageItemErrorCodes.add(new PO_Stage_Errors__c(Name = 'PO-10', Error_Code__c ='PO-10' , 
                                                             Error_Message__c= validationCodes.get('PO-10') != null? validationCodes.get('PO-10').Error_Issue__c + additionDiffString: system.label.Generic_Validation_Error_Mgs, 
                                                             PO_Stage_Id__c = poItem.Stage_PO__c,
                                                             PO_Stage_Item_Id__c = poItem.Id,
                                                             PO_Stage_Id__r = poItem.Stage_PO__r,
                                                             PO_Stage_Item_Id__r = poItem,
                                                             Error_Type__c = 'External'
                                                            ));
               }
               if(errCodesFinal.contains('subscriptionMismatch')){
                    stageItemErrorCodes.add(new PO_Stage_Errors__c(Name ='PO-12', Error_Code__c ='PO-12' , 
                                                              Error_Message__c= validationCodes.get('PO-12') != null? validationCodes.get('PO-12').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                              PO_Stage_Id__c = poItem.Stage_PO__c,
                                                              PO_Stage_Item_Id__c = poItem.Id,
                                                              PO_Stage_Id__r = poItem.Stage_PO__r,
                                                              PO_Stage_Item_Id__r = poItem,
                                                              Error_Type__c = 'External'
                                                             ));
               }
                poStagesToUpdate.add(new PO_Stage__c(Id = poItem.Stage_PO__c, PO_Validation_Status__c = 'Failure'));
                failedStgPOId.add(poItem.Stage_PO__c);
               
            }
            /*else{
                poStagesToUpdateIds.add(error.PO_Stage_Id__c);
                poStagesToUpdate.add(new PO_Stage__c(Id = error.PO_Stage_Id__c, PO_Validation_Status__c = 'Failure'));
            } */  
          }
          }
          
         }
         system.debug('stageItemErrorCodes::'+JSON.serializepretty(stageItemErrorCodes));
     }
     system.debug('stageItemErrorCodes::'+JSON.serialize(stageItemErrorCodes));
     for(String ordPC: ordIdProdCodeOrderItmMap.keyset()){
     system.debug('ordPC'+ordPC);
        list<string> strList = new List<string>(ordPC.split('::'));
        system.debug('strList'+strList);
        if(strList.size() == 2){
            Id stgPOId = ordStgPOId?.get(strList[0]);
            string stgPOKey = stgPOId+'::'+strList[1];
            system.debug('stgPOKey'+stgPOKey);
              if(stagePOProdCodePOItmMap.get(stgPOKey) == null || ordIdProdCodeOrderItmMap.get(ordPC).size() != stagePOProdCodePOItmMap.get(stgPOKey).size()){
                  failedStgPOId.add(stgPOId);
                  poStagesToUpdate.add(new PO_Stage__c(Id = stgPOId, PO_Validation_Status__c = 'Failure'));
                  string errMsg = validationCodes.get('PO-09') != null? validationCodes.get('PO-09').Error_Issue__c : system.label.Generic_Validation_Error_Mgs ;
                  stageItemErrorCodes.add(new PO_Stage_Errors__c(Name ='PO-09', Error_Code__c ='PO-09', 
                                                      Error_Message__c=  errMsg+':'+strList[1], 
                                                      PO_Stage_Id__c = stgPOId,
                                                      Error_Type__c = 'External'));   
  
              }
        }
        
     }
     system.debug('stageItemErrorCodes'+stageItemErrorCodes);
     set<id> failedOrderIds = new set<id>();
     system.debug('stgPOOrdMap:'+JSON.serializepretty(stgPOOrdMap)); 
     for(PO_Stage__c stagePO : stagePOList){
         if(!failedStgPOId.contains(stagePO.id) && !excludeStgPOIds.contains(stagePO.id)) {
          if(POStageHelper.poStagesToUpdateMap.containsKey(stagePO.id) && POStageHelper.poStagesToUpdateMap.get(stagePO.id).PO_Validation_Status__c == 'Failure'){
              poStagesToUpdate.add(POStageHelper.poStagesToUpdateMap.get(stagePO.id));
              failedOrderIds.add(stgPOOrdMap.get(stagePO.id).id);
          }else{
              poStagesToUpdate.add(new PO_Stage__c(Id = stagePO.id, PO_Validation_Status__c = 'Success'));
              succStgPOIds.add(stagePO.id);
          }
         }  
         else{
            system.debug('OIToUpdate removed'+OIToUpdate); 
  
             failedOrderIds.add(stgPOOrdMap.get(stagePO.id).id);
             system.debug('stgPOOrdMap.get(stagePO.id).id'+stgPOOrdMap.get(stagePO.id).id);
         }  
     }
      system.debug('failedOrderIds'+failedOrderIds);
     for(OrderItem OI: OIToUpdate.values()){
       if(failedOrderIds.contains(OI.OrderId)){
         OIToUpdate.remove(OI.id);
         system.debug('OIToUpdate'+OI.id+'update'+OIToUpdate);
       }
     }
     system.debug('CP OITOUPdate'+JSON.serialize(OIToUpdate));
     system.debug('CP poStagesToUpdate'+JSON.serialize(poStagesToUpdate));
      system.debug('CP stageItemErrorCodes'+JSON.serialize(stageItemErrorCodes));
     if(!stageItemErrorCodes.isEmpty() && onlyValidate == false){
         insert stageItemErrorCodes;
     }
     if(!poStagesToUpdate.isEmpty() && onlyValidate == false){
       update new list<PO_Stage__c>(poStagesToUpdate);
     }
      if(!OIToUpdate.isEmpty() && onlyValidate == false){
         update OIToUpdate.values() ;
     }
      if(onlyValidate){
          AcceptPOController.OIToUpdate = OIToUpdate.values();
          AcceptPOController.validationErrorCode = stageItemErrorCodes;
          system.debug('OIToUpdate'+OIToUpdate.values());
          system.debug('stageItemErrorCodes'+stageItemErrorCodes);
      }
      system.debug('### updateSuccessfulPOs :'+succStgPOIds);
  
      if(!succStgPOIds.isEmpty()&& onlyValidate == false){ 
          System.enqueueJob(new POValidateAmount(succStgPOIds, true));
      }
  }
   private static boolean validateGOProducts(List<OrderItem> goOIList , List<PO_Item_Stage__c>goPOItemList,set<id> processedPOItem,set<id> processedOrderItemId,
   Id stgPOId,Map<Id,OrderItem> OIToUpdate,List<PO_Stage_Errors__c> stageItemErrorCodes){
      Decimal ordSubscriptionTerm = 0;
      Decimal ordPrice = 0;
      Decimal ordQuant = 0;
      Decimal stgSubscriptionTerm = 0;
      Decimal stgPrice = 0;
      Decimal stgQuant = 0;
      set<Decimal> stgQuantSet = new set<Decimal>();
      Map<Id,string> OI_EDILineNum = new Map<Id,string>();
      boolean isSuccess = true;
      system.debug('goOIList.'+JSON.serialize(goOIList));
      system.debug('goPOItemList'+JSON.serialize(goPOItemList));
      for(PO_Item_Stage__c poItm : goPOItemList){
        if(poItm.SubscriptionTerm__c!=null) stgSubscriptionTerm += poItm.SubscriptionTerm__c ;
        if(poItm.UnitPrice__c!=null) stgPrice += poItm.UnitPrice__c ;
        if(poItm.Quantity__c!=null) {
          if(!stgQuantSet.contains(poItm.Quantity__c)){
             stgQuant+= poItm.Quantity__c ;
             stgQuantSet.add(poItm.Quantity__c);
          }
        }  
        processedPOItem.add(poItm.id);
      }
       Integer i,max ;
       i =0;
       max = goPOItemList.size();
       for(OrderItem OI : goOIList){
          if(OI.SBQQ__SubscriptionTerm__c!=null) ordsubscriptionTerm += OI.SBQQ__SubscriptionTerm__c ;
          if(OI.Sales_Price__c!=null) ordPrice += OI.Sales_Price__c ;
          if(OI.Quantity!=null) ordQuant+= OI.Quantity ;
          processedOrderItemId.add(OI.id);
          if(OI.SBQQ__SubscriptionTerm__c != null){
              Integer numberOfSplitLines =  Integer.valueOf(Math.floor(OI.SBQQ__SubscriptionTerm__c/12));
              Integer j = i+numberOfSplitLines;
              string ediLineNum ='';
              for(; i < j && i < max-1 ; i++){
                 ediLineNum += goPOItemList[i].EDI_Line_Number__c +';' ;
              }
              OI_EDILineNum.put(OI.id,ediLineNum.removeEnd(';'));
          }
         
      }
      if(stgSubscriptionTerm != ordsubscriptionTerm){
         stageItemErrorCodes.add(new PO_Stage_Errors__c(Name ='PO-12', Error_Code__c ='PO-12' , 
                                                  Error_Message__c= validationCodes.get('PO-12') != null? validationCodes.get('PO-12').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                  PO_Stage_Id__c = stgPOId,
                                                  PO_Stage_Item_Id__c = goPOItemList[0].Id,
                                                  PO_Stage_Id__r = goPOItemList[0].Stage_PO__r,
                                                  PO_Stage_Item_Id__r = goPOItemList[0],
                                                  Error_Type__c = 'External' 
                                                 ));
              isSuccess = false; 
      }
      if(!SplitPOValidation.isTolerableDifference(stgPrice,ordPrice)){
          stageItemErrorCodes.add(new PO_Stage_Errors__c(Name = 'PO-10', Error_Code__c ='PO-10' , 
                                                  Error_Message__c= validationCodes.get('PO-10') != null? validationCodes.get('PO-10').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                  PO_Stage_Id__c = stgPOId,
                                                  PO_Stage_Item_Id__c = goPOItemList[0].Id,
                                                  PO_Stage_Id__r = goPOItemList[0].Stage_PO__r,
                                                  PO_Stage_Item_Id__r = goPOItemList[0],
                                                  Error_Type__c = 'External'
                                                 ));  
            isSuccess = false; 
      }
      if(stgQuant != ordQuant){
           stageItemErrorCodes.add(new PO_Stage_Errors__c(Name = 'PO-11', Error_Code__c ='PO-11' , 
                                                  Error_Message__c= validationCodes.get('PO-11') != null? validationCodes.get('PO-11').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                  PO_Stage_Id__c = stgPOId,
                                                  PO_Stage_Item_Id__c = goPOItemList[0].Id,
                                                  PO_Stage_Id__r = goPOItemList[0].Stage_PO__r,
                                                  PO_Stage_Item_Id__r = goPOItemList[0],
                                                  Error_Type__c = 'External'
                                                 ));
              isSuccess = false; 
      }
      if(isSuccess){ 
      for(OrderItem OI : goOIList){
          if(OI_EDILineNum.containskey(OI.id)){
          OIToUpdate.put(OI.id,new OrderItem(id=OI.id,orderId=OI.orderId ,EDI_Line_Number__c = OI_EDILineNum.get(OI.id), Buyer_Part_Number__c = goPOItemList[0].Buyer_Part_Number__c)); 
         }
      }
      }
    return isSuccess;   
  }
//PRDOPS25-734
  public static void  customValidationOnDeletePoItem(Map<Id, PO_Item_Stage__c> oldStagePOItemMap) {
    system.debug('logic to prevent detetion');
     Boolean hasCustomPermission = FeatureManagement.checkPermission('Allow_Stage_PO_Delete');
     for(PO_Item_Stage__c stagePoRecord : oldStagePOItemMap.values()){
         system.debug('stagePoRecord is ####' + stagePoRecord);
                system.debug(' hasCustomPermission is ##### ' + hasCustomPermission);

         if (!hasCustomPermission && !Test.isRunningTest()) {
             stagePoRecord.adderror('You are not authorized to delete this PO Item Stage data, hence please create support ticket with ProdOps Support or email "ProdOpsapps@rubrik.com" with details.');
         }
     }
 }
  }