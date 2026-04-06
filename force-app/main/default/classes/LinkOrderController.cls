public class LinkOrderController { 
    private static List<OrderItem> orderItemsToUpdate = new List<OrderItem>(); 
    private static Map<id, Order> orderHwWithParentMap = new Map<id, Order>();
    private static Map<id, Order> mapParentIdWithHWOrder = new Map<id, Order>();
    private static Map<id, List<Order>> mapParentIdWithSWSupportOrder = new Map<id, List<Order>>();
    private static Map<id, id> orderHwSupportWithParentMap = new Map<id, id>();
    private static Map<id, List<id>> mapOfOIwithChildQuoteLine = new Map<id, List<id>>();
    private static Map<string, integer> mapOfQuoteLineWithQuantityAddedinOrders = new Map<string, integer>();
    private static Map<string, integer> mapOfQuoteLineWithAcutalQuantityAdded = new Map<string, integer>();
    private static Map<string, Set<string>> mapRelatedOrderIdWithOrdersId = new Map<string, Set<string>>();
    private static set<id> oiRecordLinkedWithSWSupport = new set<id>();
    private static set<id> hwOrderItemIds = new set<id>();
    private static set<id> reqByIds = new set<id>();
    @AuraEnabled
    public static response_Wrapper updateHWAndRelatedOrder(string orderId){
        response_Wrapper response = new response_Wrapper();
        try {
        List<Order> ordersUpdated = new List<Order>();
        List<Order> ordersToUpdate = new List<Order>();
         
        List<id> quoteIds = new List<Id>();
        set<id> prodIdsInQuote = new set<Id>();  
        Map<id, List<Order>> mapQuoteWithOrders = new Map<id, List<Order>>();
        Map<id, List<id>> mapQuoteIdWithHardwareOrder = new Map<id, List<id>>();
        Map<id, id> mapOrderIdWithOrderId = new Map<id, id>();
        Map<string, Order> mapOrderNumberWithOrder = new Map<string, Order>();
        List<orderItem> allRootHWHSOI = new  List<orderItem>(); 
        boolean allOppoertunityOrdersEligible = true;
        boolean allOppoertunityOrdersRenewalOrAmendment = true;
        Boolean isAspenOpportunity = false;
        Map<Id, Order> replacementOrdsByOrdId = new Map<Id, Order>();
        Order updatedOrder = [select id,OrderNumber,Related_Order__c,SBQQ__Quote__c,SBQQ__Quote__r.Is_RWD_Polaris_Quote__c,OpportunityId from order where id=: orderId];   
        List<SBQQ__QuoteLine__c> quoteLines = [select id,SBQQ__Product__r.Product_Level__c,SBQQ__Product__r.Product_Type__c,Replacement_Details__c,Special_Program__c,
                                                SBQQ__Product__r.Product_Subtype__c,SBQQ__Existing__c,SBQQ__Optional__c,SBQQ__Product__r.SBQQ__Optional__c,SBQQ__Product__c,SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c, 
                                                SBQQ__Product__r.name, SBQQ__Product__r.Description from SBQQ__QuoteLine__c where SBQQ__Quote__c =: updatedOrder.SBQQ__Quote__c] ;
        
       Map<Id, Order> ordersByOrdId = new Map<Id, Order>([SELECT Id,Type,Line_Types__c,Order_Sub_Type__c , HW_Order__c,Order_Status__c,Related_Order__c,Stage_PO__c,OrderNumber, SBQQ__Quote__c, ProcessType__c, 
                                    (SELECT Id,Program__c, SBQQ__QuoteLine__r.Replacement_Details__c,SBQQ__RequiredBy__c, SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,Product2Id, Product2.Product_Level__c,Product2.Usable_Capacity__c,Product2.Name,
                                    Product2.Product_Type__c, Product2.product_subtype__c, Order.OrderNumber, SBQQ__RequiredBy__r.orderId, SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c,SBQQ__QuoteLine__c,SBQQ__QuoteLine__r.SBQQ__Quantity__c, SBQQ__QuoteLine__r.SBQQ__Product__r.name,
                                    SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Description, SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c  ,OrderId, Quantity,SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c, OrderItemNumber FROM OrderItems) 
                                    FROM Order WHERE OpportunityId =: updatedOrder.OpportunityId AND Order_Status__c != 'Returned' AND Order_Status__c != 'Rejected' ORDER BY CreatedDate ASC]);
        for(SBQQ__QuoteLine__c ql : quoteLines){
            if(ql.SBQQ__Existing__c == false && ql.SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c == false && ql.SBQQ__Product__r.SBQQ__Optional__c == false && ql.SBQQ__Optional__c == false)
                prodIdsInQuote.add(ql.SBQQ__Product__c);
        }      
       Integer orderIndex = 0;
       for(order ordRec : ordersByOrdId.values()){
            orderIndex++;
            ordRec.Internal_Order_Stage__c='Validated';
            ordRec.Order_Index__c = orderIndex;
            ordRec.Total_no_of_orders__c = ordersByOrdId.values().size();
            ordRec.HW_Order__c = null;
            ordRec.Related_Order__c = null;
            ordRec.Related_Orders__c = null;
            ordRec.Related_Order_Count__c = null;
            if(UtilityClass.isReplacementOrder(ordRec)){
                replacementOrdsByOrdId.put(ordRec.id, ordRec);
            }
            if(ordRec.ProcessType__c == 'Aspen') {
                isAspenOpportunity = true;
            }
            if((ordRec.Order_Status__c !='Pending' && ordRec.Order_Status__c !='PO Received') || ordRec.Stage_PO__c != null || (!string.isBlank(ordRec.Order_Sub_Type__c) && ordRec.Order_Sub_Type__c!= 'Renewal' && ordRec.Order_Sub_Type__c!= 'Amendment' && ordRec.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_OFFER))
                allOppoertunityOrdersEligible = false;

            if(ordRec.Order_Sub_Type__c!= 'Renewal' && ordRec.Order_Sub_Type__c!= 'Amendment')
                allOppoertunityOrdersRenewalOrAmendment = false;

          	if(!mapQuoteWithOrders.containsKey(ordRec.SBQQ__Quote__c)) 
          	 	mapQuoteWithOrders.put(ordRec.SBQQ__Quote__c, new List<Order>());
                
            mapQuoteWithOrders.get(ordRec.SBQQ__Quote__c).add(ordRec);
            
            
            if(!mapRelatedOrderIdWithOrdersId.containskey(ordRec.OrderNumber))
                	mapRelatedOrderIdWithOrdersId.put(ordRec.OrderNumber, new Set<string>());
            
            mapOrderNumberWithOrder.put(ordRec.OrderNumber, ordRec);
        }
            if(!updatedOrder.SBQQ__Quote__r.Is_RWD_Polaris_Quote__c || !allOppoertunityOrdersEligible ) {   
                response.isSuccess = false;
                response.errorMessage = 'Orders are not eligible for linking';
                return response;
            }
            if(allOppoertunityOrdersRenewalOrAmendment || isAspenOpportunity){
                TriggerHandler.bypass('OrderHandler');
                update ordersByOrdId.values();
                TriggerHandler.clearbypass('OrderHandler');
                return response;    
            }
           
        for(Id quoteId: mapQuoteWithOrders.keyset()){
            Map<id, List<orderItem>> mapProductIdWithOI = new Map<id, List<orderItem>>();
            Map<string, orderItem> mapProductWithQuoteIdWithOI = new Map<string, orderItem>();
            Map<String, UtilityClass.RefreshPrgmWrapper> oldastToRefreshWrapper = new Map<String, UtilityClass.RefreshPrgmWrapper>();
            Map<Id, String> refreshHwToOldAst = new Map<Id, String>();
            Boolean replaceOrRefreshOrdExists = false;
            for(order ord: mapQuoteWithOrders.get(quoteId)){
                for(orderItem oi: ord.orderItems){
                	if(!mapProductIdWithOI.containsKey(oi.Product2Id)) 
                        mapProductIdWithOI.put(oi.Product2Id, new List<OrderItem>());
                        
                    mapProductIdWithOI.get(oi.Product2Id).add(oi);
                    
                    mapProductWithQuoteIdWithOI.put(oi.Product2Id+''+oi.SBQQ__QuoteLine__c, oi);

                    if(oi.program__c == Constants.PROGRAM_REFRESH && oi.SBQQ__QuoteLine__r.Replacement_Details__c != null){
                        String typeofsku = UtilityClass.getTypeofSKU(oi); 
                        String selectedAst = UtilityClass.getSelectedAst(oi.SBQQ__QuoteLine__r);
                        if(selectedAst != null && typeofsku != null){
                            if(!oldastToRefreshWrapper.containskey(selectedAst)){
                                oldastToRefreshWrapper.put(selectedAst, new UtilityClass.refreshPrgmWrapper(typeofsku, oi));
                            }
                            else{
                                if(typeofsku == Constants.SKU_TYPE_HARDWARE){
                                    oldastToRefreshWrapper.get(selectedAst).hwLines.put(oi.id, oi.order.ordernumber);
                                }
                                else if(typeofsku == Constants.SKU_TYPE_LICENSE){
                                    oldastToRefreshWrapper.get(selectedAst).deltaLines.put(oi.id, oi.order.ordernumber);
                                }
                            }
                            if(typeofsku == Constants.SKU_TYPE_HARDWARE){
                                refreshHwToOldAst.Put(oi.id, selectedAst);
                            }
                        }

                    }
                }
            }
            if(!mapProductIdWithOI.keyset().containsAll(prodIdsInQuote)){ //condition to check all products are available
                response.isSuccess = false;
                response.errorMessage = 'All the Products are not added in the orders';
                return response;
            }
            if(refreshHwToOldAst.keySet().size() > 0 ){
                replaceOrRefreshOrdExists = true;
                mappingForRefreshLines(mapQuoteWithOrders.get(quoteId),refreshHwToOldAst,oldastToRefreshWrapper);
            }
            if(replacementOrdsByOrdId.KeySet().size() > 0){
                replaceOrRefreshOrdExists = true;
                mappingForReplacedLines(mapQuoteWithOrders.get(quoteId), replacementOrdsByOrdId);
            }
            for(order ord: mapQuoteWithOrders.get(quoteId)){
                string errorMsg ;
                errorMsg = hwAndRootValidation(ord, mapQuoteWithOrders.get(quoteId));
                if(errorMsg == '')  
                    errorMsg =  supportAndHWValidation(ord, mapQuoteWithOrders.get(quoteId));
                if(errorMsg == '')  
                    errorMsg = supportAndHWValidationForSingleSupportPerOrderClone(ord, mapQuoteWithOrders.get(quoteId), mapProductIdWithOI);
                if(errorMsg == '')  
                    errorMsg = RelatedOrderDetailsForRCDM(ord, mapQuoteWithOrders.get(quoteId), mapOrderNumberWithOrder);  
                if(errorMsg != ''){
                        response.isSuccess = false;
                        response.errorMessage = errorMsg;
                        return response;
                }
               RelatedOrderDetailsForTPH(ord, mapQuoteWithOrders.get(quoteId));
            }
            //private static Map<id, integer> mapOfQuoteLineWithQuantityAddedinOrders = new Map<id, integer>();
    //private static Map<id, integer> mapOfQuoteLineWithAcutalQuantityAdded = new Map<id, integer>();
            for(string prodName : mapOfQuoteLineWithQuantityAddedinOrders.keyset()){
                if(mapOfQuoteLineWithQuantityAddedinOrders.get(prodName) != mapOfQuoteLineWithAcutalQuantityAdded.get(prodName)){
                    response.isSuccess = false;
            		response.errorMessage = 'Quantity for Software Support not matching with parent for Product-'+ prodName;
                    return response;
                }
            }
            
            Map<String, String> mapOrderWithRelatedOrder = new Map<String, String>();
            for(order ord: mapQuoteWithOrders.get(quoteId)){
                if(ord.Related_Order__c != null){
                    mapOrderWithRelatedOrder.put(ord.OrderNumber,ord.Related_Order__c);
                }
            }
            for(order ord: mapQuoteWithOrders.get(quoteId)){
                if(ord.Related_Order__c != null && mapOrderWithRelatedOrder.containskey(ord.Related_Order__c) && ord.Related_Order__c != mapOrderWithRelatedOrder.get(ord.Related_Order__c) ){
                    ord.Related_Order__c= mapOrderWithRelatedOrder.get(ord.Related_Order__c);
                    if(ord.Related_Order__c == null || ord.Related_Order__c == ''){
                        continue;
                    } 
                    mapRelatedOrderIdWithOrdersId.get(ord.Related_Order__c).add(ord.OrderNumber);
                }
            }
            for(order ord: mapQuoteWithOrders.get(quoteId)){
                if(mapParentIdWithHWOrder.containsKey(ord.id) && ord.HW_Order__c == null){
                    ord.HW_Order__c = mapParentIdWithHWOrder.get(ord.id).orderNumber;
                    if(mapParentIdWithSWSupportOrder!= null && mapParentIdWithSWSupportOrder.get(ord.id) != null ){
                        for(order ordRecSW: mapParentIdWithSWSupportOrder.get(ord.id)){
                            ordRecSW.HW_Order__c = mapParentIdWithHWOrder.get(ord.id).orderNumber;
                        }
                    }
                }
                    
                if(ord.Related_Order__c != null && ord.Related_Order__c != ''){
                    ord.Related_Order_Count__c = mapRelatedOrderIdWithOrdersId.get(ord.Related_Order__c).size();  
                    List<string> orderNumberList = new List<string>(mapRelatedOrderIdWithOrdersId.get(ord.Related_Order__c));
                    ord.Related_orders__c = string.join(orderNumberList,',');
                    if(replaceOrRefreshOrdExists){
                        Integer index = 0;
                        for(String ordernum : orderNumberList){
                            if(mapOrderNumberWithOrder.containskey(ordernum)){
                                index++;
                                ordersByOrdId.get(mapOrderNumberWithOrder.get(ordernum).Id).Order_Index__c = index;
                            }
                        }
                    }                
                }
                else if(replaceOrRefreshOrdExists) {
                    ord.Order_Index__c = ord.Related_Order_Count__c = 1;
                }
                for(orderItem oi: ord.orderItems){
                    if(oi.SBQQ__RequiredBy__c != null && oI.Product2.Product_Level__c == 'Support' && oI.SBQQ__QuoteLine__r != null && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c != 'LOD Software' )
                        reqByIds.add(oi.SBQQ__RequiredBy__c);
                    if(!(!String.isBlank(oI.Product2Id) && ((oI.Product2.Product_Level__c =='Hardware' && (oI.Product2.Product_Type__c =='Hardware' || oI.Product2.Product_Type__c == 'Add-On Node'))
                       || (oI.Product2.Product_Level__c == 'Hybrid Software' || 
                            (OI?.Product2?.Product_Level__c == 'OnPrem' && (OI?.Product2?.Product_Type__c =='Foundation Edition' || OI?.Product2?.Product_Type__c =='Business Edition' || OI?.Product2?.Product_Type__c =='Enterprise Edition' ) && OI?.Product2?.Product_Subtype__c == null) ||
                            oI.Product2.Product_Level__c == 'LOD Software') ||
                                                           (oI.Product2.Product_Level__c == 'Support' )))){

                        if(oi.SBQQ__RequiredBy__c == null && oi.SBQQ__QuoteLine__r != null && oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null && oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c != null){
                            if(mapProductIdWithOI.get(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c) != null && mapProductIdWithOI.get(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c).size()> 0){
                                oi.SBQQ__RequiredBy__c = mapProductWithQuoteIdWithOI.get(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c+''+oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c).id;
                                
                                orderItemsToUpdate.add(oi);
                            }else if(mapProductIdWithOI.get(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c) == null && oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Description != 'Wrapper'){
                                response.isSuccess = false;
                                response.errorMessage = 'Parent is not found for OrderItem-'+ oi.Product2.Name;
                                return response;
                            }
                        }                                       
                    }
                }
            }
            
            if(!reqByIds.containsAll(hwOrderItemIds)){
                response.isSuccess = false;
            	response.errorMessage = 'Support is not present for all added Hardwares';
                return response;
            }
            
        }
         
        TriggerHandler.bypass('OrderHandler');
        update orderItemsToUpdate;
        update ordersByOrdId.values();
        TriggerHandler.clearbypass('OrderHandler');
        } catch (DmlException e) {
            
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;    
        
    }
    
     /**
    * Maps Orders that contain replaced lines to their related (replacing) orders.
    * 
    * For each Order in `allOrders`, if it's in the replaced orders map, and its 
    * OrderItems match specific product criteria, it sets the `Related_Order__c` field
    * and populates a global map (`mapRelatedOrderIdWithOrdersId`) with the mapping of
    * related order numbers.
    *
    * @param allOrdersbyQuote    List of Orders derived from Quotes.
    * @param replacedOrds    Map of Order IDs to Order records that represent replaced orders.
    *
    * Note: This method references a global/static map called `mapRelatedOrderIdWithOrdersId`, 
    * which must be declared elsewhere in the class.
    * @author : Naveen Selvaraj
    * @date   : 22-04-2025
    */
    public static void mappingForReplacedLines(
        List<Order> allOrdersbyQuote, 
        Map<Id, Order> replacementOrdsByOrdId
    ) {
        Map<String, Set<String>> replacedOrdToRelatedOrds = new Map<String, Set<String>>();
        List<String> replaceOrdNums = new List<String>();
        for (Order eachOrd : replacementOrdsByOrdId.Values()) {
          replaceOrdNums.add(eachOrd.OrderNumber);
        }
        for (order eachOrd : allOrdersbyQuote) {
          if (!replacementOrdsByOrdId.containskey(eachOrd.id)) {
            continue;
          }
          for (orderitem oi : eachord.orderitems) {
            if (String.isNotBlank(oI.Product2Id) && UtilityClass.getTypeofSKU(oi) == Constants.SKU_TYPE_LICENSE) {
              eachOrd.Related_Order__c = String.join(replaceOrdNums, ',');
              break;
            }
          }
          if (eachOrd.Related_Order__c != null && eachOrd.Related_Order__c != '') {
            if (mapRelatedOrderIdWithOrdersId.containskey(eachOrd.Related_Order__c)) {
              if (!mapRelatedOrderIdWithOrdersId.get(eachOrd.Related_Order__c).contains(eachOrd.ordernumber)) {
                mapRelatedOrderIdWithOrdersId.get(eachOrd.Related_Order__c).add(eachOrd.ordernumber);
              }
            } else {
              mapRelatedOrderIdWithOrdersId.put(eachOrd.Related_Order__c, new Set<String>{ eachOrd.OrderNumber });
              mapRelatedOrderIdWithOrdersId.get(eachOrd.Related_Order__c).add(eachOrd.ordernumber);
            }
          }
        }
    }
     /***************************************************************************************
    * Description   : Finds Related orders for the Refreshed lines
    * Input Params  : 
    * refreshHwToOldAst :Hw Orderitem id to SelectedAsset
    * oldastToRefreshWrapper : Selected Old Assset to Refreshlines wapper info.
    ****************************************************************************************/
    
    Public static void mappingForRefreshLines(List<order> orderlist,Map<Id, String> refreshHwToOldAst, Map<String, UtilityClass.refreshPrgmWrapper> oldastToRefreshWrapper){
        for(order eachOrd : orderlist){
            for(orderitem oi : eachord.orderitems){
                if(oi.Program__c != Constants.PROGRAM_REFRESH) continue;
                if(!String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c =='Hardware' && (oI.Product2.Product_Type__c =='Hardware' || oI.Product2.Product_Type__c == 'Add-On Node'))){
                    List<String> licenseorderNums = new List<String>();
                    eachOrd.HW_Order__c = eachOrd.ordernumber;
                    if(refreshHwToOldAst.containskey(oi.id) && oldastToRefreshWrapper.containskey(refreshHwToOldAst.get(oi.id)) 
                       && oldastToRefreshWrapper.get(refreshHwToOldAst.get(oi.id)).deltaLines != null 
                       && !oldastToRefreshWrapper.get(refreshHwToOldAst.get(oi.id)).deltaLines.values().isEmpty()){
                        //here we found its related license ordernumber 
                        licenseorderNums = oldastToRefreshWrapper.get(refreshHwToOldAst.get(oi.id)).deltaLines.values();
                        eachOrd.Related_Order__c =  String.join(licenseorderNums, ',');
                    }
                    for(String licOrdNum : licenseorderNums){
                        if(!string.isBlank(licOrdNum)){
                            if(mapRelatedOrderIdWithOrdersId.containskey(licOrdNum)){
                                mapRelatedOrderIdWithOrdersId.get(licOrdNum).add(eachOrd.OrderNumber);
                                if(!mapRelatedOrderIdWithOrdersId.get(licOrdNum).contains(licOrdNum)){
                                    mapRelatedOrderIdWithOrdersId.get(licOrdNum).add(licOrdNum);
                                }
                            }
                            else{
                                mapRelatedOrderIdWithOrdersId.put(licOrdNum, new Set<String>{eachOrd.OrderNumber});
                                mapRelatedOrderIdWithOrdersId.get(licOrdNum).add(licOrdNum);
                            } 
                        }
                    }  
                }
                if(!String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c == 'Hybrid Software' || (oI.Product2.Product_Level__c == 'OnPrem' && (oI.Product2.Product_Type__c == 'Enterprise Edition' || oI.Product2.Product_Type__c == 'Business Edition' || oI.Product2.Product_Type__c == 'Foundation Edition') && OI?.Product2?.Product_Subtype__c == null) || oI.Product2.Product_Level__c == 'LOD Software')){
                    eachOrd.Related_Order__c = eachOrd.ordernumber;
                }
            }
        }
    }
    public static string hwAndRootValidation(order orderRec, List<order> orderlist){
        
        Map<id,decimal> mapHWRequiredByCount = new Map<id,decimal>();
        id selectOrder;
        for(orderItem oi: orderRec.orderItems){
            if(!String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c =='Hardware' && (oI.Product2.Product_Type__c =='Hardware' || oI.Product2.Product_Type__c == 'Add-On Node'))){
                hwOrderItemIds.add(oI.id);
                
                //if OI has hw and reqBy is populated, it has its parent
                if(!string.isblank(oi.SBQQ__RequiredBy__c) && oi.orderId == oi.SBQQ__RequiredBy__r.Orderid){
                    orderRec.HW_Order__c = orderRec.OrderNumber;
                    orderRec.Related_Order__c = orderRec.OrderNumber; 
                    
                    if(!string.isBlank(orderRec.Related_Order__c))
                        mapRelatedOrderIdWithOrdersId.get(orderRec.Related_Order__c).add(orderRec.OrderNumber);
                }else if(oi.Program__c != Constants.PROGRAM_REFRESH && oi.Program__c != Constants.PROGRAM_CONVERSION && oi.Program__c != Constants.PROGRAM_UPGRADE){
                    // Map of Root Product ,with the quantity added. r1 is the parent of H1 and h2 , map will have {r1 => H1*q1 + H2*q2}
                    if(!mapHWRequiredByCount.containskey(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c))
                        mapHWRequiredByCount.put(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c, 0);
                        
                    mapHWRequiredByCount.put(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c, mapHWRequiredByCount.get(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c)+(oi.Quantity* oi.Product2.Usable_Capacity__c));
        
                }
            }
            
        }
        //if mapHWRequiredByCount is empty, then this don't have any hw with reqby blank
        if(mapHWRequiredByCount.keyset().size()== 0) return '';
        for(order odrRec : orderlist){
            if(orderHwWithParentMap.values().contains(odrRec) || selectOrder != null || odrRec.id == orderRec.id) continue;
            boolean orderMatched = true;
            boolean hasHardware = false;
            Map<id,decimal> mapRootProductWithCount = new Map<id,decimal>();
            Map<id,id> mapRootProductWithOI = new Map<id,id>();
            for(orderItem oi: odrRec.orderItems){
                if(!String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c =='Hardware' && (oI.Product2.Product_Type__c =='Hardware' || oI.Product2.Product_Type__c == 'Add-On Node')) && string.isblank(oi.SBQQ__RequiredBy__c)){
                    hasHardware= true;
                }
                if(!String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c == 'Hybrid Software' || (oI.Product2.Product_Level__c == 'OnPrem' && (oI.Product2.Product_Type__c == 'Enterprise Edition' || oI.Product2.Product_Type__c == 'Business Edition' || oI.Product2.Product_Type__c == 'Foundation Edition') && OI?.Product2?.Product_Subtype__c == null) || oI.Product2.Product_Level__c == 'LOD Software')){
                    mapRootProductWithCount.put(oI.Product2Id, oi.Quantity);
                    mapRootProductWithOI.put(oI.Product2Id, oi.id);
                    odrRec.Related_Order__c =odrRec.OrderNumber;
                    
                    if(!string.isBlank(odrRec.Related_Order__c))
                        mapRelatedOrderIdWithOrdersId.get(odrRec.Related_Order__c).add(odrRec.OrderNumber);
                }
            }
            //if has hardware with reqid blank, this means either this doesnot have any root or root of some other , which is not allowed
            if(hasHardware) continue;
            if(mapRootProductWithCount.keyset().equals(mapHWRequiredByCount.keyset()) && !mapRootProductWithCount.keyset().isEmpty()){
                for(id prodId : mapHWRequiredByCount.keyset()){
                    if(mapHWRequiredByCount.get(prodId) != mapRootProductWithCount.get(prodId)){
                        orderMatched = false;
                    }
                }
            }else{
                orderMatched = false;                
            }
            if(orderMatched== true){
               selectOrder = odrRec.id;
               orderHwWithParentMap.put(orderRec.id,odrRec);
               mapParentIdWithHWOrder.put(odrRec.id, orderRec);
               orderRec.HW_Order__c = orderRec.OrderNumber;
               orderRec.Related_Order__c = odrRec.OrderNumber; 
                
               if(!string.isBlank(orderRec.Related_Order__c))
                   mapRelatedOrderIdWithOrdersId.get(orderRec.Related_Order__c).add(orderRec.OrderNumber); 
                
               for(orderItem oi: orderRec.orderItems){
                   if(!String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c =='Hardware' && (oI.Product2.Product_Type__c =='Hardware' || oI.Product2.Product_Type__c == 'Add-On Node')) && string.isblank(oi.SBQQ__RequiredBy__c)){
                       oi.SBQQ__RequiredBy__c = mapRootProductWithOI.get(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c);
                       orderItemsToUpdate.add(oi);
                    }
                }
            }
            
        }
        if(selectOrder == null){
            return 'Cannot find matching Parent record for the order - '+ orderRec.OrderNumber;
        }
        return '';
    }
    
    public static string supportAndHWValidation(order orderRec, List<order> orderlist){
        Map<string,decimal> mapSupportRequiredByCount = new Map<string,decimal>();
        id selectOrder;
        boolean hasHybrid = false;
        if(orderRec.orderItems != null && orderRec.orderItems.size()<2) return '';
        for(orderItem oi: orderRec.orderItems){
            if(oi.Program__c == Constants.PROGRAM_REFRESH || oi.Program__c == Constants.PROGRAM_CONVERSION || oi.Program__c == Constants.PROGRAM_UPGRADE){
                continue;
            }
            if(!String.isBlank(oi.Product2Id) && (oi.Product2.Product_Level__c == 'Hybrid Software' || (oI.Product2.Product_Level__c == 'OnPrem' && (oI.Product2.Product_Type__c == 'Enterprise Edition' || oI.Product2.Product_Type__c == 'Business Edition' || oI.Product2.Product_Type__c == 'Foundation Edition') && OI?.Product2?.Product_Subtype__c == null) ||  oi.Product2.Product_Level__c == 'LOD Software')){
                hasHybrid = true;
            }
            if(!String.isBlank(oI.Product2Id) && oI.Product2.Product_Level__c == 'Support' && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null  && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c != 'LOD Software'   && (string.isblank(oi.SBQQ__RequiredBy__c) || oi.orderId != oi.SBQQ__RequiredBy__r.Orderid)){
                mapSupportRequiredByCount.put(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c+''+oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c , oi.Quantity);
            }
            if(!String.isBlank(oI.Product2Id) && oI.Product2.Product_Level__c == 'Support' && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c != 'LOD Software'  && !string.isblank(oi.SBQQ__RequiredBy__c) && oi.orderId == oi.SBQQ__RequiredBy__r.Orderid ){
                orderRec.HW_Order__c = orderRec.OrderNumber;
                orderRec.Related_Order__c = orderHwWithParentMap.containskey(orderRec.id) ? orderHwWithParentMap.get(orderRec.id).OrderNumber: orderRec.OrderNumber;
            	
                if(!string.isBlank(orderRec.Related_Order__c))
                   mapRelatedOrderIdWithOrdersId.get(orderRec.Related_Order__c).add(orderRec.OrderNumber); 
            }
        }
        if(mapSupportRequiredByCount.keyset().size() == 0)  return '';
        for(order odrRec : orderlist){
            if(orderHwSupportWithParentMap.values().contains(odrRec.id)) continue;
            if(selectOrder != null || odrRec.id == orderRec.id) continue;
            boolean orderMatched = true;
            boolean hasHardwareSupport = false;
            Map<String,decimal> mapHWProductWithCount = new Map<string,decimal>();
            Map<String,id> mapHWProductWithOI = new Map<string,id>(); 
            for(orderItem oi: odrRec.orderItems){
                if(!String.isBlank(oI.Product2Id) && oI.Product2.Product_Level__c == 'Support' && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c != 'LOD Software'  && string.isblank(oi.SBQQ__RequiredBy__c) ){
                    hasHardwareSupport = true;
                }
                if(!String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c =='Hardware' && (oI.Product2.Product_Type__c =='Hardware' || oI.Product2.Product_Type__c == 'Add-On Node'))){
                    mapHWProductWithCount.put(oI.Product2Id+''+oI.SBQQ__QuoteLine__c, oi.Quantity);
                    mapHWProductWithOI.put(oI.Product2Id+''+oI.SBQQ__QuoteLine__c, oi.id);
                }
            }
            if(hasHardwareSupport) continue;
            if(mapHWProductWithCount.keyset().equals(mapSupportRequiredByCount.keyset())){
                for(string prodId : mapSupportRequiredByCount.keyset()){
                    if(mapSupportRequiredByCount.get(prodId) != mapHWProductWithCount.get(prodId)){
                        orderMatched = false;
                    }
                }
            }else{
                orderMatched = false;
            }
                        
            if(orderMatched== true ){
                selectOrder = odrRec.id;
                orderHwSupportWithParentMap.put(orderRec.id,odrRec.id);
               // write logic to populate reqby 
               orderRec.HW_Order__c = odrRec.OrderNumber;
               orderRec.Related_Order__c = orderHwWithParentMap.containskey(odrRec.id) ? orderHwWithParentMap.get(odrRec.id).OrderNumber: odrRec.OrderNumber; 
               if(!string.isBlank(orderRec.Related_Order__c))
                   mapRelatedOrderIdWithOrdersId.get(orderRec.Related_Order__c).add(orderRec.OrderNumber); 
                
               for(orderItem oi: orderRec.orderItems){
                   if(!String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c =='Support' && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c != 'LOD Software' ) && string.isblank(oi.SBQQ__RequiredBy__c)){
                       if(hasHybrid && String.isBlank(oI.SBQQ__RequiredBy__c)){
                            selectOrder = null;
                        }
                       oi.SBQQ__RequiredBy__c = mapHWProductWithOI.get(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c+''+oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c );
                       if(!mapOfOIwithChildQuoteLine.containsKey(oi.Id)) 
                            mapOfOIwithChildQuoteLine.put(oi.SBQQ__RequiredBy__c, new List<Id>());
                            
                       mapOfOIwithChildQuoteLine.get(oi.SBQQ__RequiredBy__c).add(oi.SBQQ__QuoteLine__c);
                       orderItemsToUpdate.add(oi);
                   }}
            }
        }
        if(selectOrder == null){
            return 'Cannot find matching Parent record for the order- '+ orderRec.OrderNumber;
        }
        return '';
    }
    
    public static string supportAndHWValidationForSingleSupportPerOrderClone(order orderRec, List<order> orderlist, Map<id, List<orderItem>> mapProductIdWithOI){
        
        id selectOrder;
        if(orderRec.orderItems != null && orderRec.orderItems.size()!=1) return '';
        orderItem ordrItemRec = new orderItem();
        ordrItemRec = orderRec.orderItems[0];
        boolean isHWFound = false;
        if(String.isBlank(ordrItemRec.Product2Id) || ordrItemRec.Program__c == Constants.PROGRAM_REFRESH || ordrItemRec.Program__c == Constants.PROGRAM_CONVERSION || ordrItemRec.Program__c == Constants.PROGRAM_UPGRADE ||ordrItemRec.Product2.Product_Level__c != 'support' ||  ordrItemRec.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r == null || ordrItemRec.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c == 'LOD Software' ){
            return '';
        }
        if(mapProductIdWithOI.get(ordrItemRec.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c) != null){
            for(orderItem oiRec : mapProductIdWithOI.get(ordrItemRec.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c)){
                if(oiRec.Quantity == (ordrItemRec.Quantity) && (!mapOfOIwithChildQuoteLine.containskey(oiRec.Id) || !mapOfOIwithChildQuoteLine.get(oiRec.Id).contains(ordrItemRec.SBQQ__QuoteLine__c))){
                    ordrItemRec.SBQQ__RequiredBy__c = oiRec.Id;
                    orderRec.HW_Order__c = oiRec.Order.OrderNumber;
                    orderRec.Related_Order__c = orderHwWithParentMap.containskey(oiRec.OrderId) ? orderHwWithParentMap.get(oiRec.OrderId).OrderNumber: oiRec.Order.OrderNumber;
                    isHWFound = true;
                    if(!mapOfOIwithChildQuoteLine.containsKey(orderRec.orderItems[0].Id)) 
                            mapOfOIwithChildQuoteLine.put(orderRec.orderItems[0].Id, new List<Id>());
                            
                    mapOfOIwithChildQuoteLine.get(orderRec.orderItems[0].Id).add(ordrItemRec.SBQQ__QuoteLine__c);
                    orderItemsToUpdate.add(ordrItemRec);
                    
                    if(!string.isBlank(orderRec.Related_Order__c))
                       mapRelatedOrderIdWithOrdersId.get(orderRec.Related_Order__c).add(orderRec.OrderNumber); 
                    break;
                }
            }
        }
               
        if(!isHWFound){
            return 'Cannot find matching Parent record for the order-'+ orderRec.OrderNumber;
        }
        return '';
    }
    
    public static void RelatedOrderDetailsForTPH(order orderRec, List<order> orderlist){
        if(!String.isBlank(orderRec.Related_Order__c))
           return;
        for(orderItem oi: orderRec.orderItems){
            if(!String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c == 'Hybrid Software' || (oI.Product2.Product_Level__c == 'OnPrem' && (oI.Product2.Product_Type__c == 'Enterprise Edition' || oI.Product2.Product_Type__c == 'Business Edition' || oI.Product2.Product_Type__c == 'Foundation Edition') && OI?.Product2?.Product_Subtype__c == null) ||  oI.Product2.Product_Level__c == 'LOD Software')){
                orderRec.Related_Order__c = orderRec.OrderNumber;
                orderRec.Related_Orders__c = orderRec.OrderNumber;
                orderRec.Related_Order_Count__c= 1;
                
                mapRelatedOrderIdWithOrdersId.get(orderRec.Related_Order__c).add(orderRec.OrderNumber); 
            }
        }
    }
    
    public static string RelatedOrderDetailsForRCDM(order orderRec,List<order> orderlist, Map<string, Order> mapOrderNumberWithOrder){
        for(orderItem oI :orderRec.orderItems){
            if(!String.isBlank(oI.Product2Id) && oI.Product2.Product_Level__c == 'support' && oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r != null &&  oI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c == 'LOD Software' ){
                oi.SBQQ__RequiredBy__c =  null;
                list<order> odrListToIterate = new list<order>();
                if(!String.isBlank(orderRec.Related_Order__c) && ( orderRec.Related_Order__c != orderRec.orderNumber && orderRec.HW_Order__c != orderRec.orderNumber )){
                    return 'Cannot find matching Parent record for the order-'+ orderRec.OrderNumber + ' for Software Support';
                }
                if(!String.isBlank(orderRec.Related_Order__c)){
                    odrListToIterate.add(mapOrderNumberWithOrder.get(orderRec.Related_Order__c));
                }else
                    odrListToIterate= orderlist;
                for(order odrRec : odrListToIterate){
                    for(orderItem oiRec: odrRec.orderItems){
                        if(oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c == oIRec.SBQQ__QuoteLine__c && oi.Quantity== oIRec.Quantity && !oiRecordLinkedWithSWSupport.contains(oIRec.Id)){
                            oiRecordLinkedWithSWSupport.add(oIRec.Id);
                            oi.SBQQ__RequiredBy__c =  oIRec.Id;
                            orderRec.Related_Order__c = odrRec.OrderNumber;
                            orderRec.HW_Order__c= odrRec.HW_Order__c;
                            mapRelatedOrderIdWithOrdersId.get(orderRec.Related_Order__c).add(orderRec.OrderNumber);
                                if(!mapOfQuoteLineWithQuantityAddedinOrders.containsKey(oIRec.SBQQ__QuoteLine__r.SBQQ__Product__r.name)) 
                                    mapOfQuoteLineWithQuantityAddedinOrders.put(oIRec.SBQQ__QuoteLine__r.SBQQ__Product__r.name, 0);
                                    
                                mapOfQuoteLineWithQuantityAddedinOrders.put(oIRec.SBQQ__QuoteLine__r.SBQQ__Product__r.name, mapOfQuoteLineWithQuantityAddedinOrders.get(oIRec.SBQQ__QuoteLine__r.SBQQ__Product__r.name )+ integer.valueof(oi.Quantity));    
                                
                                if(!mapParentIdWithSWSupportOrder.containsKey(odrRec.Id)) 
                                    mapParentIdWithSWSupportOrder.put(odrRec.id, new List<Order>());
                                    
                                mapParentIdWithSWSupportOrder.get(odrRec.Id).add(orderRec);
                            
                            
                            mapOfQuoteLineWithAcutalQuantityAdded.put(oIRec.SBQQ__QuoteLine__r.SBQQ__Product__r.name, integer.valueof(oIRec.SBQQ__QuoteLine__r.SBQQ__Quantity__c));
                            orderItemsToUpdate.add(oi);
                        }
                    }
                } 
                
                if(String.isBlank(oi.SBQQ__RequiredBy__c))
                    return 'Cannot find matching Parent record for the order-'+ orderRec.OrderNumber + ' for Software Support';
            }
        }
        
        return '';
    }
    
    public class response_Wrapper {
        @auraEnabled public boolean isSuccess{get;set;}
        @auraEnabled public string errorMessage  {get;set;}
        
        public response_Wrapper(){
            this.isSuccess = true;
            this.errorMessage = '';
        } 
    }

}