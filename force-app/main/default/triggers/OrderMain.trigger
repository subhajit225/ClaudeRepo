/**************************************************************************************************
 * @description       : Depreciated OrderMain  as PRDOPS26-287
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/
trigger OrderMain on Order (before insert, after insert, after update, before update) {
    // set ShGl_DisableBusinessLogic__c.Disable_Order_Old_Trigger__c = false to run this trigger
  /*  private Boolean isHoldOffLogicDisabled = false;
     ShGl_DisableFunctionalityLogic__c disabledFunctionality = ShGl_DisableFunctionalityLogic__c.getInstance();
     ShGl_DisableBusinessLogic__c disableBusLogic = ShGl_DisableBusinessLogic__c.getInstance();
     if(TriggerControl.stopOrderTrigger // Added by PALAK: IF trigger is called from task trigger
     || (TriggerControl__c.getInstance('Order') != null && TriggerControl__c.getInstance('Order').DisableTrigger__c)
     || disableBusLogic.Disable_Order_Triggers__c) {
        return;
    }

    try {
        //SF-656 Start -Shadab
        ShGl_DisableFunctionalityLogic__c disabledFunctionality = ShGl_DisableFunctionalityLogic__c.getInstance();
        isHoldOffLogicDisabled = disabledFunctionality.DisableHoldOffLogic__c; 
        // End SF-656
        OrderService.OrderInit(trigger.new);
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            if(trigger.isUpdate){
                OrderService.initOrderInfo(trigger.new, trigger.newMap, trigger.oldMap);
            }
            OrderService.syncOrderStatusForPOC_RMA_RT();
        }

        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            OrderService.checkIsOrderSubmitted();
        }

        if(Trigger.isBefore && Trigger.isInsert) {
            OrderService.ORIGIN_CONTEXT = 'Insert';
            OrderService.initCurrentEstShipDate();
        }

        if(Trigger.isBefore && Trigger.isInsert){
            OrderService.copyPODetails((List<Order>)Trigger.new);
        }
        
        if(Trigger.isBefore && Trigger.isUpdate) {
            OrderService.preventChangeOriginalEstShipDate();
            OrderService.countPolarisRecordOnUpdate((List<Order>)Trigger.new);
            OrderService.OrderStatusRecordUpdated(Trigger.new,trigger.oldMap);
             //PRDOPS21-230 START 
           DateTime currentTime = system.now();
           if(database.countQuery('select count() from BookingCutOff__c where StartDate__c <=: currentTime and EndDate__c >=: currentTime')==0 && OrderService.ORIGIN_CONTEXT =='Insert'){
              OrderService.autoSubmitOrder((List<Order>)Trigger.new, Trigger.oldMap);
            }
            OrderService.updateRPSScreening((List<Order>)Trigger.new, (Map<Id, Order>)Trigger.OldMap);
            OrderService.initCurrentEstShipDate();
            OrderService.creditCheckFailure((List<Order>)Trigger.new, (Map<Id, Order>)Trigger.OldMap);
            OrderService.acceptOrder((List<Order>)Trigger.new, (Map<Id, Order>)Trigger.OldMap);
        }

        // revert Order Type changes
        if(Trigger.isBefore && Trigger.isUpdate) {
            OrderService.revertOrderTypeChanges();
            OrderService.setHasASEProduct(trigger.newMap, trigger.oldMap);
        }

        if(Trigger.isBefore && Trigger.isInsert) {
            OrderService.setDefaultShippingCarrier();
            //START - SF-656 Hold Off Process
            system.debug('IN BEFORE METHOD===');
            if(!isHoldOffLogicDisabled) {
                HoldCodeTrackingHelper.syncHoldCodesOnInsertWithHoldCodesOnOpportunity((List<Order>)Trigger.new);
            }
            //END - SF-656 Hold Off Process
        }

        if(Trigger.isBefore && Trigger.isInsert) {
            OrderService.setDefaultOrderType();
        }

        // if(Trigger.isBefore && Trigger.isUpdate) {
        //     OrderService.setPOCSupportDates();
        // }

        if(Trigger.isBefore && Trigger.isUpdate) {
            OrderService.checkPOCShippedDates();
            //Put Order On HOLD -Added for PRDOPS21_324 
            OrderService.orderOnHoldForIF(trigger.new, trigger.oldMap);
            //end
        }


         List<Order> acceptedOrdesList = new List<Order>();
        if(Trigger.isBefore && Trigger.isUpdate) {
            OrderService.checkPOCShippedDates();
            for(Order order : Trigger.New){
                Order oldOrder = (Order)Trigger.OldMap.get(order.Id);
                system.debug('@@ new order.Order_Status__c '+order.Order_Status__c +' @@ old '+oldOrder.Order_Status__c);
                 //CHANGES EGN-169 START
                if(order.PS_Project__c == null && order.Order_Status__c != oldOrder.Order_Status__c && order.Order_Status__c == 'Order Accepted' && order.Have_PS_Products__c){
                //CHANGES EGN-169 END 
                    acceptedOrdesList.add(order);
              } 
            }
            if(!acceptedOrdesList.isEmpty()){
                PSProjectHelperClass.createPSProject(acceptedOrdesList);
            }
        }
        
        System.debug('Test Point 1');
        if(trigger.isAfter && trigger.isUpdate && !PSProjectHelperClass.createtaskrecurssion) {
            System.debug('Test Point 2');
            PSProjectHelperClass.createtaskrecurssion = true;
            //Start: SAL-1385 and SAL-1073 
            //Collect Order Ids to be passed to a method and to create Booking adjustment after validation
            Set<Id> orderIds = new Set<Id>();
            Set<Id> cancelledOrderIds = new Set<Id>();
            List<String> rebateList=new List<String>{'Distributor Fee','Velocity Partner Program Rebate'};
            for(Order ord : Trigger.new){ 
                Order oldOrder = (Order)Trigger.OldMap.get(ord.Id);
                if( ord.Type == 'Revenue' && ord.BookingStatus__c == 'Completed' && 
                    ord.BookingStatus__c != Trigger.oldMap.get(ord.Id).BookingStatus__c){
                            orderIds.add(ord.id);                       
                }
                else if( (ord.status != oldOrder.status  && ord.status=='Cancelled') 
                        || (ord.Order_Status__c != oldOrder.Order_Status__c && ord.Order_Status__c =='Rejected')){ 
                  cancelledOrderIds.add(ord.id);
                }
            }
            if(!orderIds.isEmpty()){
                OrderService.createBLIforRebate(orderIds,rebateList);
            }
            if(!cancelledOrderIds.isEmpty()){
               OrderService.CancelBooking(cancelledOrderIds); // SF-8170
            }
            //End: SAL-1385 and SAL-1073 End
            OrderService.contractOrders(trigger.new, trigger.oldMap);

            //This call to the future method createEntitlementsForOneTimeProducts() creates entitlement records related to the Account 
            //for all Products that are set as Single_Entitlement__c = true related to the current order
            
            //if(OrderMainCheckRecursive.runOnce()) {
               /* Commenting as part of -PRDOPS21-216
                Map<Id, Id> mapOrderId_AccountId = new Map<Id, Id>();
                for(Order eachOrder : trigger.new) {
                    if(eachOrder.Order_Status__c.equalsIgnoreCase('Shipped')) {
                        mapOrderId_AccountId.put(eachOrder.Id, eachOrder.AccountId);
                    }
                }
                
                if(!mapOrderId_AccountId.isEmpty()) {
                    OrderService.createEntitlementsForOneTimeProducts(mapOrderId_AccountId);
                } */
            //}
            
            /*String disableMissingAssetCheck = Label.Disable_Missing_Asset_Check;
            if(disableMissingAssetCheck != 'TRUE') {
                OrderTriggerHelper.sendAlertforMissingAssets((List<Order>)trigger.new, (Map<Id, Order>)trigger.oldMap);
            }
            //START - SF-656 Hold Off Process
            if(!isHoldOffLogicDisabled){
                HoldCodeTrackingHelper.recalculateHoldTrackingForOrders((Map<Id, Order>)Trigger.newMap, (Map<Id, Order>)Trigger.OldMap);
            }
            //END - SF-656 Hold Off Process
            
            //START SF-645
            Set<Id> allShippedOrderIds = new Set<Id>();
            List<Order_Event__e> psoOrderEvents = new List<Order_Event__e>(); 
            Set<Id> allOrderwithPSProjectIdsForCreate = new Set<Id>();
            Set<Id> acceptedOrderwithPSProjectIdsForCreate = new Set<Id>();
            Map<Id, Id> oldPSIdtoNewPSIdonOrderMap = new Map<Id, Id>();
            for(Order order : Trigger.New){
              Order oldOrder = (Order)Trigger.OldMap.get(order.Id);
              if(order.Order_Status__c == 'Shipped' && oldOrder.Order_Status__c != order.Order_Status__c) {
                  allShippedOrderIds.add(order.Id); 
                  //psoOrderEvents.add(new Order_Event__e(Order_Id__c = order.Id, Action_Type__c='CREATE_PSO_RECORD')); //ITMKT21-8
              }   
              if(order.PS_Project__c != null && oldOrder.PS_Project__c == null) {
                  //CHANGES EGN-169 START
                  if(order.Order_Status__c != oldOrder.Order_Status__c && order.Order_Status__c == 'Order Accepted' && order.Have_PS_Products__c){
                  //CHANGES EGN-169 END
                      acceptedOrderwithPSProjectIdsForCreate.add(order.Id);
                  }else{
                      allOrderwithPSProjectIdsForCreate.add(order.Id);
                  }
              } 
              if(order.PS_Project__c != null && oldOrder.PS_Project__c != null && oldOrder.PS_Project__c != order.PS_Project__c) {
                  oldPSIdtoNewPSIdonOrderMap.put(oldOrder.PS_Project__c, order.PS_Project__c);
                  //allOrderwithPSProjectIdsForUpdate.add(order.Id);
              }
                
            }
            SYSTEM.DEBUG('allShippedOrderIds==='+psoOrderEvents);
            SYSTEM.DEBUG('allOrderwithPSProjectIdsForCreate==='+allOrderwithPSProjectIdsForCreate);
            SYSTEM.DEBUG('allOrderwithPSProjectIdsForCreate size==='+allOrderwithPSProjectIdsForCreate.size());
            
            SYSTEM.DEBUG('oldPSIdtoNewPSIdonOrderMap==='+oldPSIdtoNewPSIdonOrderMap);
            SYSTEM.DEBUG('oldPSIdtoNewPSIdonOrderMap size==='+oldPSIdtoNewPSIdonOrderMap.size());
            if(!allShippedOrderIds.isEmpty()){
               OrderService.createUpdateEntitlements(allShippedOrderIds);
            }
            if(!psoOrderEvents.isEmpty()) {
                //createPSORecords(allShippedOrderIds);
                EventBus.publish(psoOrderEvents);
            }
             
            if(!allOrderwithPSProjectIdsForCreate.isEmpty()) {
                PSProjectHelperClass.createPSProjectWithRelatedRecords(allOrderwithPSProjectIdsForCreate,true);    
            }
            system.debug('@@acceptedOrderwithPSProjectIdsForCreate '+acceptedOrderwithPSProjectIdsForCreate);
            if(!acceptedOrderwithPSProjectIdsForCreate.isEmpty()){
                PSProjectHelperClass.createPSProjectWithRelatedRecords(acceptedOrderwithPSProjectIdsForCreate,true);
            }
            
            if(!oldPSIdtoNewPSIdonOrderMap.isEmpty()) {
                System.debug('oldPSIdtoNewPSIdonOrderMap=='+oldPSIdtoNewPSIdonOrderMap);
                PSProjectHelperClass.updatePSTaskOnProjectUpdate(oldPSIdtoNewPSIdonOrderMap);    
            }  
            //END SF-645
        }

        if(trigger.isAfter && trigger.isUpdate) {
             //added for SF-4311
            System.debug('Calling createNodeAssociation');
            OrderService.createNodeAssociation(Trigger.new, Trigger.oldMap);
            //end
            OrderService.processShippedOrders(trigger.new, trigger.oldMap);
            //OrderService.autoFulfillPOCOrders(trigger.new, trigger.oldMap);
            
            // START - SAL-135: Polaris order fulfillment
            /*if(Trigger.isUpdate) {
                Map<Id, Task> accIdTsksMap = POLARIS_OrderFulfillment.updateExistingTask(trigger.new, trigger.oldMap);
                POLARIS_OrderFulfillment.createTaskOnOrderActivation(trigger.new, trigger.oldMap, accIdTsksMap);
            } else if (Trigger.isInsert) {
                POLARIS_OrderFulfillment.createTaskOnOrderActivation(trigger.new, trigger.oldMap, null);
            }*/
            // END - SAL-135
             //Go Refresh
        /*    OrderService.IsRefreshedCheckOnAccount((List<Order>)Trigger.new, (Map<Id, Order>)Trigger.OldMap);
        }
        
        Set<Id> checkOpp = new Set<Id>();
        
        if(trigger.isafter && trigger.isInsert){
            
            Set<Id> oppIdSet = new Set<Id>();
            Map<Id, Id> mapOpportunityIdWithMosaicOrderId = new Map<Id, Id>();
            
            for(Order newOrder : Trigger.New){
                oppIdSet.add(newOrder.OpportunityId);
                checkOpp.add(newOrder.OpportunityId);
                
                // MOSAIC Changes
                if (
                        String.isNotBlank(newOrder.OpportunityId)
                        && String.isNotBlank(newOrder.Mosaic_SKUs__c)
                ) {
                    mapOpportunityIdWithMosaicOrderId.put(newOrder.OpportunityId, newOrder.Id);
                }
            }
            System.debug('### Values in OppIdSet=='+oppIdSet);
            Set<Id> oppIdSetToUpdate = new Set<Id>();
            Map<Id,integer> oppMap = new Map<Id,Integer>();
            for(Opportunity oppObj : [Select Id, Mosaic_Customer_Environment__c, (select id,OrderNumber from Orders) from Opportunity where Id IN: oppIdSet]){
                System.debug('### oppObj.Orders.size()--'+oppObj.Orders.size());
                System.debug('### oppObj.Orders--'+oppObj.Orders);
                if(oppObj.Orders.size()>1){
                    oppIdSetToUpdate.add(oppObj.Id);
                    oppMap.put(oppObj.Id,oppObj.Orders.size());
                }
                
                // MOSAIC Changes
                if (oppObj.Mosaic_Customer_Environment__c == null || !oppObj.Mosaic_Customer_Environment__c.equalsIgnoreCase('AWS')) {
                    mapOpportunityIdWithMosaicOrderId.remove(oppObj.Id);
                }
            }
            //START - SF-656 Hold Off Process
            if(!isHoldOffLogicDisabled){
                HoldCodeTrackingHelper.syncTrackingRecordOnInsertWithHoldCodesOnOpportunity((Map<Id, Order>)Trigger.newMap);
            }
            //END - SF-656 Hold Off Process
            
            // MOSAIC Changes
            if (!mapOpportunityIdWithMosaicOrderId.isEmpty()) {
                OrderService.processMosaicSkus(mapOpportunityIdWithMosaicOrderId.values());
            }
        }
        
        if(trigger.isbefore && trigger.isInsert){
            List<Id> insertedOrderOpps =new List<Id>();
            Map<Id, Id> OppPriceBookMap =new Map<Id,Id>();
            Map<Id, Id> oppPartnerMap = new Map<Id, Id>();  //EL-236
            Map<Id, Id> oppPolarisContact = new Map<Id, Id>();
            Map<Id, String> oppPolarisContactEmail = new Map<Id, String>();
            Map<Id, String> oppCompetitorMap = new Map<Id, String>();
            for(Order orderObj : Trigger.New){
                orderObj.Status ='Pending';
                orderObj.SBQQ__contracted__c = false;
                orderObj.Type = orderObj.Type=='New'?'Revenue':orderObj.Type;
                System.debug('### test--'+orderObj);
                insertedOrderOpps.add(orderObj.OpportunityId);
            }
            if(!insertedOrderOpps.isEmpty()){
                for(Opportunity opp: [SELECT Id, Name, PriceBook2.ID, Primary_Competitor__c, Pricebook2Id, Partner_Lookup__c, Polaris_Portal_Contact__c, Polaris_Portal_Contact__r.Email FROM opportunity WHERE Id IN :insertedOrderOpps]) {
                    //OppPriceBookMap.put(opp.id,opp.PriceBook2.ID);
                    OppPriceBookMap.put(opp.id, opp.Pricebook2Id);
                    oppCompetitorMap.put(opp.id, opp.Primary_Competitor__c);
                    oppPartnerMap.put(opp.id, opp.Partner_Lookup__c);   //EL-236
                    oppPolarisContact.put(opp.Id, opp.Polaris_Portal_Contact__c);
                    
                    if(opp.Polaris_Portal_Contact__c != null){
                        oppPolarisContactEmail.put(opp.Id, opp.Polaris_Portal_Contact__r.Email);
                    }
                }
            }
            
            for(Order orderObj : Trigger.New){
                if(orderObj.OpportunityId != null) {
                    orderObj.Pricebook2Id = OppPriceBookMap.get(orderObj.OpportunityId);
                    orderObj.Primary_Competitor__c = oppCompetitorMap.get(orderObj.OpportunityId);
                    System.debug(oppPartnerMap.get(orderObj.OpportunityId));
                    orderObj.Partner_Name__c = oppPartnerMap.get(orderObj.OpportunityId);   //EL-236
                    orderObj.Polaris_Contact__c = oppPolarisContact.get(orderObj.OpportunityId);
                    if(oppPolarisContactEmail.containsKey(orderObj.OpportunityId)){
                        orderObj.Polaris_Contact_Email__c = oppPolarisContactEmail.get(orderObj.OpportunityId);
                    }
                    System.debug(orderObj);
                }
            }
            OrderService.populateFieldsOnInsert(Trigger.new);
        }
        
        //EL-236 - Start
        if(trigger.isbefore && trigger.isupdate){
            OrderService.populateFieldsOnUpdate(Trigger.new, Trigger.oldMap);
            OrderService.updatePartnerName(Trigger.new, Trigger.oldMap);
            OrderService.generateEntitlementsForThirdPartyHardware();
            //updated for PRDOPS21_337
            OrderService.updateWelcomeEmailFields(Trigger.new,(Map<Id, Order>)Trigger.OldMap);
        }
        //EL-236 - End

        //EL-237 - Start
        if(Trigger.isAfter && Trigger.isUpdate){
            OrderService.updatePartnerNameAtEntitlement(Trigger.new, Trigger.oldMap);
        }
        //EL-237 - End

        //Set the Account Name off Ship To
        Set<Id> orderIdSet = new Set<Id>();
        // if(trigger.isInsert && trigger.isAfter) {
        //     for(Order newOrder : Trigger.New){
        //         if(newOrder.Ship_To_Name__c==null && newOrder.AccountID!=null)
        //             orderIdSet.add(newOrder.Id);
        //     }
        // }
        
        // if(trigger.isUpdate && trigger.isAfter) {
        //     for(Order updatedOrder : Trigger.New){
        //         // if conditon for null check for oldMap added by chandra
        //         if(trigger.OldMap.containsKey(updatedOrder.Id)){
        //             Order oldOrder = trigger.OldMap.get(updatedOrder.Id);
                    
        //             if(updatedOrder.Ship_To_Name__c==null && updatedOrder.AccountID!=null && updatedOrder.Ship_To_Name__c!=updatedOrder.AccountID && oldOrder.AccountID!=updatedOrder.AccountId) {
        //                 orderIdSet.add(updatedOrder.Id);
        //             }
                    
        //         }
        //     }
        // }

        //Start: SF-920, Update Netsuite flag on account when it is marked true on order
        if((Trigger.isUpdate || Trigger.isInsert) && Trigger.isAfter){
            OrderService.updateNetsuitFlagAtAccount(Trigger.new, Trigger.oldMap);
        }
        //End: SF-920

        //if(orderIdSet.size() > 0) OrderService.updateOrderAccounts(orderIdSet);
        if(checkOpp.size() > 0) OrderService.checkOrdersComplete(checkOpp, trigger.new );
        
        
        
    } catch(Exception e) {
        Error_Logs__c el = new Error_Logs__c(
            Error_Type__c = 'Order Error',
            Error_Message__c = e.getMessage() + '\r\n' + e.getStackTraceString(),
            Type__c = 'SFDC'
        );
        Database.insert(el);
    }
    
    //Start SF-645 - Shadab
    // public void createPSORecords(Set<Id> OrderIdSet) {
    //     List<OrderItem> updateOrderItemList = new List<OrderItem>();
    //     if(!OrderIdSet.isEmpty()) {
    //         for(OrderItem oItem : [select id, Initiate_PSO_Logic__c, PricebookEntry.Product2.Allow_PSO_Task_Creation__c from OrderItem where OrderId IN: OrderIdSet AND PricebookEntry.Product2.Allow_PSO_Task_Creation__c = TRUE]) {
    //             if(oItem.Initiate_PSO_Logic__c == false){
    //                 oItem.Initiate_PSO_Logic__c =true;
    //                 updateOrderItemList.add(oItem);
    //             }
    //         }
    //         SYSTEM.DEBUG('updateOrderItemList==='+updateOrderItemList);
    //         if(!updateOrderItemList.isEmpty()) {
    //             update updateOrderItemList;
    //         }
    //     }
    // }
    //END

    if(Trigger.isAfter && System.Label.Enable_Portal_User_Creation == 'TRUE') {
        
        system.debug('### PortalUserHelper processor ');
        if(trigger.isInsert) 
            PortalUserHelper.processOrdersForProvisioning(Trigger.newMap, Trigger.newMap, false);
        if(trigger.isUpdate) 
            PortalUserHelper.processOrdersForProvisioning(Trigger.newMap, trigger.oldMap, true);
        
    }

    //SF-2580, Keep it last in the trigger always
    if(Trigger.isBefore && Trigger.isUpdate){
        OrderService.orderValidation(Trigger.new);
    }
    
    IF(Trigger.isBefore && Trigger.isInsert){
     //Keep this always last in the before insert. This will auto submit EDI Order.
     OrderService.updateRPSScreening((List<Order>)Trigger.new,null);
    }
    
    //SF-6209    
    IF( Trigger.isInsert &&  Trigger.isAfter){ 
       OrderService.invalidateQuote((List<Order>)Trigger.new);
    }*/
}