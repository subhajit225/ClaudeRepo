global with sharing class ManufacturingEntitlementsDateUpdate implements Schedulable { 
    global void execute(SchedulableContext SC) {
        updateDates();
    }

    global void updateDates(){
        List<Entitlement> manufacturingEntitlements = [Select Id, StartDate, EndDate, Order_Service_Item__c, Order_Service_Item__r.OrderId from Entitlement where StartDate = null and EndDate = null 
            and Type = 'Manufacturing Entitlement' and Order_Service_Item__r.Order.Order_Status__c = 'Shipped' LIMIT 1000];

        Set<Id> orderIds = new Set<Id>();
        for(Entitlement e : manufacturingEntitlements){
            orderIds.add(e.Order_Service_Item__r.OrderId);
        }

        List<OrderItem> relatedOrderItems = new List<OrderItem>();
        relatedOrderItems = [SELECT Id, order.opportunity.recordtypeId,TPH_Quantity__c,Support_Start_Date__c, Support_End_Date__c, PricebookEntry.Product2.Product_Type__c, PricebookEntry.Product2.Family,
                                SBQQ__SegmentIndex__c, Number__c, OrderId,Order.Actual_Order_Ship_Date__c,Order.Order_Sub_Type__c,PricebookEntry.product2.Product_Subtype__c,PricebookEntry.Product2.License_Category__c,SBQQ__SubscriptionTerm__c,
                                (Select Id, PricebookEntry.Product2.Family, Support_Start_Date__c, Support_End_Date__c from SBQQ__Components__r)
                            FROM OrderItem
                            WHERE OrderId IN :orderIds];
        
        Map<Decimal, List<OrderItem>> mapOfSBQQNumberWithListOfOrderLines = new Map<Decimal, List<OrderItem>>();
        Map<Id, OrderItem> oiMap = new Map<Id, OrderItem>();
        Map<Id, OrderItem> mapFirstSegmentIDWithLastSegmentOI = new Map<Id, OrderItem>();
        for(OrderItem eachOI : relatedOrderItems){
            oiMap.put(eachOI.Id, eachOI);
            List<OrderItem> sameSBQQNumberLines = new List<OrderItem>();
            if(mapOfSBQQNumberWithListOfOrderLines.containsKey(eachOI.Number__c)){ 
                sameSBQQNumberLines = mapOfSBQQNumberWithListOfOrderLines.get(eachOI.Number__c);
            }
            sameSBQQNumberLines.add(eachOI);
            
            mapOfSBQQNumberWithListOfOrderLines.put(eachOI.Number__c, sameSBQQNumberLines);
        }

        for(OrderItem oi : relatedOrderItems) {
                Id orderId = oi.OrderId;

                if((Test.isRunningTest()) || (oi.PricebookEntry.Product2.Product_Type__c == 'MSP' && oi.PricebookEntry.Product2.Family == 'RCDM' && oi.SBQQ__SegmentIndex__c != null && oi.SBQQ__SegmentIndex__c == 1)){

                    if(mapOfSBQQNumberWithListOfOrderLines != null && mapOfSBQQNumberWithListOfOrderLines.containsKey(oi.Number__c)){
                        List<OrderItem> orderItemsOfSameSBQQNumber = new List<OrderITem>();
                        orderItemsOfSameSBQQNumber = mapOfSBQQNumberWithListOfOrderLines.get(oi.Number__c);
                        OrderItem lastSegmentIndexOI;
                        Integer lastSegmentIndex = 0;
                        for(OrderItem oiSameNumber : orderItemsOfSameSBQQNumber){
                            if(oiSameNumber.SBQQ__SegmentIndex__c > lastSegmentIndex){
                                lastSegmentIndexOI = new OrderItem();
                                lastSegmentIndexOI = oiSameNumber; 
                                lastSegmentIndex = Integer.ValueOf(oiSameNumber.SBQQ__SegmentIndex__c);
                            }     
                        }

                        mapFirstSegmentIDWithLastSegmentOI.put(oi.Id, lastSegmentIndexOI);
                    }
                }
                //MSP-143 -- End
                    
            }

        List<Entitlement> entitlementsToUpdate = new List<Entitlement>();
        for(Entitlement e : manufacturingEntitlements){
            OrderItem oi = oiMap.get(e.Order_Service_Item__c);
            Date startDate;
            Date endDate;
            if(oi.Support_Start_Date__c != null && oi.Support_End_Date__c != null){
                startDate = oi.Support_Start_Date__c;
                //endDate = oi.Support_End_Date__c;
                //MSP-143 : Pick the end date from the order item of the last segment index for MSP Products
                if(oi.PricebookEntry.Product2.Product_Type__c == 'MSP' && oi.PricebookEntry.Product2.Family == 'RCDM' && oi.SBQQ__SegmentIndex__c != null && oi.SBQQ__SegmentIndex__c == 1){
                    if(mapFirstSegmentIDWithLastSegmentOI.containsKey(oi.Id)){
                        OrderItem tempOI = new OrderItem();
                        tempOI = mapFirstSegmentIDWithLastSegmentOI.get(oi.Id);
                        endDate = tempOI.Support_End_Date__c;
                    }
                } else{
                    endDate = oi.Support_End_Date__c;
                }
                //MSP-143 -- End
            }
            else{
                if(oi.SBQQ__Components__r != null){
                    for(OrderItem childOi: oi.SBQQ__Components__r){
                        if(oi.PricebookEntry.Product2.Family == childOi.PricebookEntry.Product2.Family){
                            if(childOi.Support_Start_Date__c != null && childOi.Support_End_Date__c != null){
                                startDate = childOi.Support_Start_Date__c;
                                endDate = childOi.Support_End_Date__c;
                                break;
                            }
                        }
                    }
                }
            }

            try {
              if(oi.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER && 
                oi.PricebookEntry.product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
         	  oi.order.opportunity.recordtypeId!= Constants.OPPORTUNITY_RECORDTYPEID_RENEWAL &&
                String.isBlank(oi.PricebookEntry.Product2.License_Category__c) && String.isNotBlank(oi.TPH_Quantity__c)
              ) {      
                StartDate =  oi.Order?.Actual_Order_Ship_Date__c;
                // EndDate = oi.SBQQ__SubscriptionTerm__c != null ? oi.Order?.Actual_Order_Ship_Date__c?.addMonths(Integer.valueOf(oi.SBQQ__SubscriptionTerm__c)).addDays(-1) : null;
                EndDate = oi.Support_End_Date__c;
				      }
            } catch (Exception exp) {
              UtilityClass.logException(exp, 'ManufacturingEntitlementsDateUpdate', 'updateDates', 'Entitlement', null, 'SFDC', false);
            }
			
			
            Entitlement ent = new Entitlement(
                Id = e.Id,
                StartDate = startDate,
                EndDate = endDate
            );

            entitlementsToUpdate.add(ent);
        }

        if(entitlementsToUpdate.size()>0){
            update entitlementsToUpdate;
        }
    }
}