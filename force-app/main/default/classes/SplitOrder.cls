/*****************************************************************************
* @description       : SplitOrderBatch
Holds logic for Splitting EDI Orders
Max recursion
* Ver   Date          Author        Modification
* 1.0   10-01-2025   Prashant        Initial Version
******************************************************************************/
global class SplitOrder implements Database.Batchable<sObject> {  
    public static set<string> submittedReplOrd = new set<string>();

    public static boolean isNonEDISplit = false;
    
   /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Query All the Eligible Order and Orderitems For which Batch needs to be executed.
   * @param bc
   * @return Database.QueryLocator
   * */
    global Database.QueryLocator start(Database.BatchableContext bc) {  

        List<AsyncApexJob> currentRunningApex  = [select id,ApexClass.name,ExtendedStatus,Status  from AsyncApexJob where (status = 'Holding' OR Status ='Preparing'  OR Status ='Processing'  OR Status ='Queued') and ApexClass.name='SplitOrder'  and id !=: bc.getJobID() ];
        
        if(currentRunningApex != null && currentRunningApex.size() > 0){
            return Database.getQueryLocator('SELECT Id FROM Order WHERE Id = null'); 
        }
        
        String retQuery=getCreatableFieldsSOQL('Order','(Order_Status__c = \'Pending\' OR Order_Status__c = \'On Hold\') AND (Order_Split_Type__c = \'EDI\' OR Order_Split_Type__c = \'Non-EDI\' OR  Order_Split_Type__c = \'GC Offer Amendment\'  OR Order_Split_Type__c = \'Netapp\')');
        String retInnerQuery=getCreatableFieldsSOQL('OrderItem','');
        System.debug(LoggingLevel.DEBUG,retInnerQuery);
        System.debug(LoggingLevel.DEBUG,retQuery); 
        retInnerQuery = retInnerQuery.replace(
        ' FROM OrderItem',
        ',SBQQ__QuoteLine__r.SBQQ__NetPrice__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionTerm__c,Order.SBQQ__Quote__c,SBQQ__QuoteLine__r.SBQQ__StartDate__c,SBQQ__QuoteLine__r.SBQQ__EndDate__c,SBQQ__QuoteLine__r.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.Quote_additional_month__c,SBQQ__QuoteLine__r.SBQQ__Quote__r.Opportunity_Program__c,SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.Total_New_Hardware_Products__c,Order.ProcessType__c,SBQQ__QuoteLine__r.Line_Type__c,SBQQ__RequiredBy__r.product2.Name, SBQQ__QuoteLine__r.Special_Program__c, SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c, SBQQ__QuoteLine__r.SBQQ__Quote__c,Product2.License_Category__c, Product2.Product_Level__c, Product2.Family, Product2.Product_Subtype__c, Product2.Usable_Capacity__c, Product2.ProductCode, Product2.Product_Type__c, Product2.Appliance_Model_HW__c, Product2.Name, Product2.Product_Payment_Option__c, Product2.License_per_Qty__c,Product2.SBQQ__SubscriptionTerm__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,SBQQ__QuoteLine__r.Name, SBQQ__RequiredBy__r.Product2.ProductCode,SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c,Product2.Category__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,product2.Edition__c FROM OrderItems'
        );
        retQuery=retQuery.replace('FROM Order',' ,TotalAmount,is_Amendment_Order__c,OrderNumber,   ('+retInnerQuery+') FROM Order');
        system.debug(LoggingLevel.DEBUG,'test code push');
        return Database.getQueryLocator(retQuery);
    }
      /**
   * @date 05-03-2025
   * @description Query All the Eligible Order and Orderitems For which Batch needs to be executed.
   * @param bc
   * @param records
   * */ 
    global void execute(Database.BatchableContext bc, List<Order> records){
        
        
        //List<AsyncApexJob> currentRunningApex  = [select id,ApexClass.name,ExtendedStatus,Status  from AsyncApexJob where (status = 'Holding' OR Status ='Preparing'  OR Status ='Processing'  OR Status ='Queued') and ApexClass.name='SplitOrder' and id !=: bc.getJobID()];
        
        //if(currentRunningApex == null || (currentRunningApex != null && currentRunningApex.size() ==0)){
           
            // CreateMap between EDILine+ORderID & OrderLine record
            List<Order> netAppOrders = new List<Order>();
            Map<string, OrderItem> orderItemMap = new Map<string,OrderItem>();
            // Collect all the quote ids and create map between quote id and order record
            Map<id,order> quoteOrderMap = new Map<id,order>();
            Map<String, order> originalOrders = new Map<String, order>();
            Map<Id, OrderItem> upgradeSkusOrderLineSUForCloning = new Map<Id, OrderItem>(); // CSU-473
	    Map<id,Set<String>> oldOIEDINUMMap = new MAP<id,Set<string>>();
            Map<id,String> oldOIBuyersPartNumMap = new MAP<id,string>();
                        Map<Id,Orderitem> mapquoteLineOrderLine = new Map<Id,Orderitem>();
            Map<Id,Orderitem> mapIdOrderItem = new Map<Id,Orderitem>();
            Map<String, List<Orderitem>> orderItemsByType = new Map<String, List<Orderitem>>();
            Boolean isEdiOrder = false;
            OpportunityObjectTriggerHandler.isOppAutoManual = 'AutoGenerated';
            system.debug(LoggingLevel.DEBUG,'test code '+records);
        	Map<String,OrderItem> mapParentToRCDMOLI = new Map<String,OrderItem>();
        Map<String, X0_RCDM_Dates__mdt> rcdmMdt = new Map<String, X0_RCDM_Dates__mdt>();
           Map<Id,Replacement> QuoteIdReplDetail = new  Map<Id,Replacement>(); //CP
           List<string>PhtmOrdNum = new list<string>();
        for(X0_RCDM_Dates__mdt mdt : X0_RCDM_Dates__mdt.getAll().values()){
            if(mdt.Product_Name__c != null){
                rcdmMdt.put(mdt.Product_Name__c, mdt);
            }
        }
		Map<String, Order> mapOfOrder = new Map<String, Order>();
        
        for(Order obj: records){
            System.debug(LoggingLevel.DEBUG,'testing1aa '+obj.Order_Split_Type__c);
				if(obj.Order_Split_Type__c == 'EDI'){
	                mapOfOrder.put('EDI',obj);
	            }
                else if(obj.Order_Split_Type__c == 'Non-EDI'){
                	mapOfOrder.put('Non-EDI',obj);
            	}
	            else if(obj.Order_Split_Type__c == 'Netapp'){
	                mapOfOrder.put('Netapp',obj);
	            }
                if(obj.Order_Split_Type__c == 'EDI' || obj.Order_Split_Type__c == 'Non-EDI'){
                quoteOrderMap.put(obj.SBQQ__Quote__c,Obj);
                originalOrders.put(obj.OrderNumber, new order(id=obj.id));
                system.debug(LoggingLevel.DEBUG,'test code '+originalOrders);
                if(!QuoteIdReplDetail.containsKey(obj.SBQQ__Quote__c) && obj.Type == 'Revenue' && UtilityClass.isReplacementOrder(obj) && obj.Associated_Order_Numbers__c != null) {
                    replacement rpl = new replacement();
                    PhtmOrdNum.add(obj.Associated_Order_Numbers__c);
                    rpl.PhtmOrdNum = obj.Associated_Order_Numbers__c;
                    QuoteIdReplDetail.put(obj.SBQQ__Quote__c,rpl);
                }
                for(Orderitem oi: obj.orderitems){
                    String oiTypeKey = oi.Product2.Product_Subtype__c == 'FEDRAMP' ||
                        oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c == 'FEDRAMP' ||
                        oi.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c == 'FEDRAMP'
                        ? 'FEDRAMP'
                        : (oi?.Program__c != null &&
                            Constants.REPLACEMENT_PROGRAMS.contains(oi.Program__c) &&
                            oi.Order.ProcessType__c != 'Aspen' &&
                            oi?.Previous_Transaction_Reference__c != null &&
                            oi.SBQQ__QuoteLine__c != null &&
                            oi.SBQQ__QuoteLine__r.SBQQ__Quote__r.Total_New_Hardware_Products__c > 0)
                            ? 'Replacement'
                            : 'Non-Split';          
                    if(orderItemsByType.containskey(oiTypeKey)){
                        orderItemsByType.get(oiTypeKey).add(oi);

                    }else{
                        orderItemsByType.put(oiTypeKey, new List<OrderItem> {oi}); 
                    }
                    mapquoteLineOrderLine.put(oi.SBQQ__QuoteLine__c,oi);
                    mapIdOrderItem.put(oi.Id,oi);
                       
                }
            }else if(obj.Order_Split_Type__c == Constants.ORDER_SPLIT_TYPE_GC_OFFER_AMENDMENT){ // CSU-473 : Here we are checking if any orderitem is FUE line or upgraded skus 
        	mapOfOrder.put('gc_Offer_Amendment_Order', obj);
                for(Orderitem oi: obj.orderitems){
                        if(orderitemtriggerhelper.isScaleUtilityUpgradeSKU(oi.Product2)){
                               upgradeSkusOrderLineSUForCloning.put(oi.Order.SBQQ__Quote__c,oi);
                        }
                    }
        	}else{
                netAppOrders.add(obj);
            }
        }
        
            system.debug(LoggingLevel.DEBUG,'### netAppOrders:'+netAppOrders);

        
        
        
            for(String typeOfOrder : mapOfOrder.keySet()){
	    
                 if(typeOfOrder == 'Netapp' && !netAppOrders.isEmpty()){
	    	        SplitNetAppOrder(netAppOrders, bc.getJobID(), rcdmMdt?.keySet());
                }else if(Test.isRunningTest() || (typeOfOrder == 'Non-EDI' && !quoteOrderMap.isEmpty() && !orderItemsByType.isEmpty() && orderItemsByType.size() > 1)){
                    splitNonEDIOrder(orderItemsByType, quoteOrderMap);
                }else if(typeOfOrder == 'EDI' && !quoteOrderMap.isEmpty()){
                    isEdiOrder = true;
                }
            }
	
	/* CSU-473-Call cloneUpgradeSkusForAmendmentSU method
	* to clone the upgraded Skus based on RSV segment Quotelines Start and End Date
	*/
	if (!upgradeSkusOrderLineSUForCloning.isEmpty()) {
	cloneUpgradeSkusForAmendmentSU(upgradeSkusOrderLineSUForCloning, mapOfOrder.get('gc_Offer_Amendment_Order'));
	}

        if(isEdiOrder || Test.isRunningTest()){
            List<PO_Stage__c> stagePOs =[select id,name,Quote__c,Quote__r.SBQQ__Type__c,Quote__r.Renewal_Opportunity__c,Quote__r.Is_RWD_Polaris_Quote__c,ShippingCity__c,Hardware_PO_Id__c,Ship_To_Phone_Number__c,Payment_Terms__c,
                                     Shipping_Method__c,Ship_to_Account_Name__c,Ship_To_Contact_Name__c,ShippingCountry__c,ShippingPostalCode__c, ShippingCountryCode__c,
                                     ShippingState__c,ShippingStreet__c,ShippingStateCode__c,End_User_PO__c,PoDate__c,PoNumber__c,Shipping_Carrier__c,Service_Level__c ,
                                         (select Type__c,Quote_Line__c,Quote_Line__r.SBQQ__Product__r.Product_Level__c,Quote_Line__r.SBQQ__Product__r.Product_Type__c, Quote_Line__r.SBQQ__Product__r.ProductCode, Quote_Line__r.Special_Program__c, Quote_Line__r.SBQQ__Quote__r.ProcessType__c,
                                      Quote_Line__r.Line_Type__c, Quote_Line__r.SBQQ__Product__r.Product_Subtype__c,Quote_Line__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,Quote_Line__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c, Quote_Line__r.SBQQ__Quote__c, Quote_Line__r.SBQQ__Quote__r.SBQQ__Type__c, Quote_Line__r.SBQQ__Quote__r.Opportunity_Program__c, Quote_Line__r.SBQQ__Quote__r.Total_New_Hardware_Products__c,
                                      Quote_Line__r.SBQQ__EffectiveStartDate__c,Asset_Ids_Description__c,Buyer_Part_Number__c,Deliver_By__c,EDI_Line_Number__c,Est_Ship_Date__c,Product__c,
                                            ProductCode__c,Quantity__c,Stage_PO__c,Standard_Carrier_Alpha_Code__c,SubscriptionTerm__c,Subscription_Term_Description__c,UnitPrice__c,
                                            Quote_Line__r.SBQQ__RequiredBy__c,Quote_Line__r.SBQQ__RequiredBy__r.Special_Program__c,Quote_Line__r.SBQQ__RequiredBy__r.Line_Type__c,
                                            Quote_Line__r.SBQQ__RequiredBy__r.SBQQ__EffectiveStartDate__c
                                      from PO_Item_Stage__r where ProductCode__c NOT IN :Constants.DUMMY_PRODUCTS order by EDI_Line_Number__c  ) from PO_Stage__c where Quote__c in: quoteOrderMap.keyset() and 
                                     (PO_Validation_Status__c = 'Order Accepted' OR PO_Validation_Status__c = 'Order Accepted - 855 Sent' OR PO_Validation_Status__c ='Success' OR PO_Validation_Status__c ='Success - 855 Sent')];
    
            List<Sobject> newRecords = new List<sObject>();
            
            Map<id,List<orderItem>> mapOLDOINewOI = new Map<id,List<orderItem>>();
            Map<String,orderItem> ediLinesCreated = new MAp<String,orderItem>();
            Map<string,Boolean> needFieldUpdate = new Map<string,boolean>();
            system.debug(LoggingLevel.DEBUG,'test code '+oldOIEDINUMMap);
    
            Map<String,Order> newOrders = new Map<string,order>();
            Map<String,List<OrderItem>> newOrderswithOrderLines = new Map<string,List<OrderItem>>();
    
            Map<String,orderItem> newReqOrderItems = new Map<string,orderItem>();
            Map<String,List<orderItem>> newRequiredBywithOrderLines = new Map<string,List<orderItem>>();
            List<orderItem> updateOLDOI = new List<orderItem>();
            
            Map<Id,String> mapQuoteLineEdiLines = new Map<Id,String>();
            Map<Id,String> mapQuoteLineBuyersPartNumber = new Map<Id,String>();
        Map<String, List<PO_Item_Stage__c>> mapLineTypeToLines = new Map<String, List<PO_Item_Stage__c>>();
            String earlierEdiData;
            String earlierBuyersPartData;
        Map<String, Integer> totOrdCountbyType = new Map<String, Integer>();
        for(PO_Stage__c spo: stagePOs){
            Boolean hasRSCGEnabledProducts = false;
            if(quoteOrderMap?.get(spo.Quote__c)?.RSC_G_Enabled__c){
                hasRSCGEnabledProducts = true; 
            }
            for(PO_Item_Stage__c pi: spo.PO_Item_Stage__r){
                Order queriedOrder = quoteOrderMap?.get(pi?.Quote_Line__r?.SBQQ__Quote__c);
                String orderSubType = queriedOrder?.Order_Sub_Type__c;
                String orderType = queriedOrder?.Type;
                Boolean isrcdmProd = rcdmMdt?.containsKey(pi?.Quote_Line__r?.SBQQ__Product__r.ProductCode);
                Boolean isM365CreditSKU = pi?.Quote_Line__r.SBQQ__Product__r?.Product_Type__c == CPQ_Constants.Product_Type_M365_ZRS && pi?.Quote_Line__r.SBQQ__Product__r?.Product_Subtype__c == CPQ_Constants.Product_Subtype_Credit;//ITNPI-3372
                String tempKey;
                if(pi?.Quote_Line__r?.SBQQ__Quote__r?.SBQQ__Type__c == 'Renewal+Expansion'  
                   && ((orderType == 'Revenue' && orderSubType == 'Renewal' && 
                        ((isrcdmProd && pi?.Quote_Line__r?.SBQQ__RequiredBy__r?.Line_Type__c =='New')|| (!isrcdmProd && pi?.Quote_Line__r?.Line_Type__c =='New')))
                       || (orderType == 'Revenue' && (orderSubType == null || orderSubType == '') && 
                           ((isrcdmProd && pi?.Quote_Line__r?.SBQQ__RequiredBy__r?.Line_Type__c =='Renewal')|| (!isrcdmProd && pi?.Quote_Line__r?.Line_Type__c =='Renewal'))))){
                               continue;
                           }
                           if(hasRSCGEnabledProducts && 
                           (pi?.Quote_Line__r.SBQQ__Product__r?.Product_Subtype__c == 'FEDRAMP' || pi?.Quote_Line__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c == 'FEDRAMP' || 
                            pi?.Quote_Line__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c == 'FEDRAMP')){
                                tempKey = pi.Stage_PO__c+':'+'FEDRAMP';
                            }else if (pi?.Quote_Line__r?.SBQQ__Quote__r?.ProcessType__c != 'Aspen' 
                                && Constants.REPLACEMENT_PROGRAMS.contains(pi?.Quote_Line__r?.Special_Program__c)
                                && pi?.Quote_Line__r?.SBQQ__Quote__r?.Total_New_Hardware_Products__c > 0) {
                                tempKey = pi.Stage_PO__c + ':' + 'Replacement';
                            }else if(isrcdmProd){
                                tempKey = pi.Stage_PO__c+':'+pi.Quote_Line__r?.SBQQ__RequiredBy__r?.Line_Type__c;
                            }else if(isM365CreditSKU && pi?.Quote_Line__r?.SBQQ__Quote__r?.SBQQ__Type__c =='Renewal'){//ITNPI-3372
                                tempKey = pi.Stage_PO__c+':'+pi.Quote_Line__r?.SBQQ__Quote__r?.SBQQ__Type__c;
                            }else{
                                tempKey = pi.Stage_PO__c+':'+pi.Type__c; 
                            }
                        if(tempKey != null){
                            if(mapLineTypeToLines.containsKey(tempKey)){
                                mapLineTypeToLines.get(tempKey).add(pi);
                            }else{
                                mapLineTypeToLines.put(tempKey, new List<PO_Item_Stage__c>{pi});
                                if(pi.Type__c != null){
                                    String typeVal = pi.Type__c == 'Renewal' ? pi.Type__c : 'New';
                                    if(totOrdCountbyType.get(typeVal) != null){
                                        Integer i = totOrdCountbyType.get(typeVal);
                                        totOrdCountbyType.put(typeVal, i+1);
                                    }else{
                                        totOrdCountbyType.put(typeVal, 1);
                                    }
                        }
                    }
                }
            
                if(!mapQuoteLineEdiLines.containsKey(pi.Quote_Line__c)){
                    mapQuoteLineEdiLines.put(pi.Quote_Line__c,pi.EDI_Line_Number__c+'*'+pi.Stage_PO__c);
                }
                else{
                    earlierEdiData = mapQuoteLineEdiLines.get(pi.Quote_Line__c);
                    mapQuoteLineEdiLines.put(pi.Quote_Line__c,earlierEdiData+';'+pi.EDI_Line_Number__c+'*'+pi.Stage_PO__c);
                }

                mapQuoteLineBuyersPartNumber.put(pi.Quote_Line__c,pi.Buyer_part_Number__c);
            }
        }
            
            for(Id quoteLineId : mapQuoteLineEdiLines.keyset()){
                if(mapquoteLineOrderLine.containsKey(quoteLineId)){
                    oldOIEDINUMMap.put(mapquoteLineOrderLine.get(quoteLineId).Id,
                                        new Set<String>(mapQuoteLineEdiLines.get(quoteLineId).split(';')));
                    oldOIBuyersPartNumMap.put(mapquoteLineOrderLine.get(quoteLineId).Id,mapQuoteLineBuyersPartNumber.get(quoteLineId));
                    /*oldOIBuyersPartNumMap.put(mapquoteLineOrderLine.get(quoteLineId).Id,
                                        new Set<String>(mapQuoteLineBuyersPartNumber.get(quoteLineId).split(';')));*/
                }
            }
            integer indexOrder= 0;
        integer renewalOrd = 0;
        Map<Id,PO_Stage__c> stagePOsMap = new Map<Id,PO_Stage__c>(stagePOs);
        for(String key: mapLineTypeToLines.keySet()){
            PO_Stage__c spo;
            String piType;
            if(key != null && key.contains(':')){
              spo = stagePOsMap.get(key.Split(':')[0]);
              piType = key.Split(':')[1];
            }else{
              spo = stagePOsMap.get(key);
            }
                
                Order cloneOrder = quoteOrderMap.get(spo.Quote__c) != null?quoteOrderMap.get(spo.Quote__c).clone():null;
                //cloneOrder.ManualFulfilment__c = false;
                    if(spo.Quote__r.SBQQ__Type__c == 'Renewal+Expansion'){
                        if(key.contains('Renewal')){
                            renewalOrd++;
                            cloneOrder.Order_Index__c= renewalOrd;
                            cloneOrder.OpportunityId = null;
                            cloneOrder.Order_Sub_Type__c = null;
                        }else if(key.contains('New') || key.contains('FEDRAMP') || key.contains('Replacement')){
                        indexOrder++;
                        cloneOrder.Order_Index__c= indexOrder;
                        }
                        cloneOrder.Total_no_of_orders__c = piType != null && piType == 'Renewal' ? totOrdCountbyType.get(piType) : totOrdCountbyType.get('New');
                    }else{
            indexOrder++; 
            cloneOrder.Order_Index__c= indexOrder;
            cloneOrder.Total_no_of_orders__c = mapLineTypeToLines.size();
                    }
                    //if(UtilityClass.isReplacementOrder(cloneOrder)){
                        cloneOrder.Associated_Order_Numbers__c = null;
                        cloneOrder.Line_Types__c = null;
                    //}
                cloneOrder.Have_Polaris_Products__c = false;
                cloneOrder.ShippingCity=spo.ShippingCity__c;
                cloneOrder.ShippingCountry = spo.ShippingCountry__c;
                cloneOrder.ShippingCountryCode = '';
                cloneOrder.ShippingPostalCode = spo.ShippingPostalCode__c;
                cloneOrder.ShippingState = spo.ShippingState__c;
                cloneOrder.ShippingStateCode = '';
                cloneOrder.ShippingStreet  = spo.ShippingStreet__c;
                cloneOrder.End_User_PO__c = spo.End_User_PO__c;
                cloneOrder.PODate = spo.PoDate__c;
                cloneOrder.PONumber = spo.PoNumber__c;
                cloneOrder.HW_Order__c ='';
                cloneOrder.Related_Order__c ='';
                cloneOrder.Related_orders__c= '';  
                cloneOrder.Related_Order_Count__c = null;
                if(CloneOrder.RSC_G_Enabled__c) CloneOrder.Polaris_Fulfillment_Status__c = null;
                CloneOrder.RSC_G_Enabled__c = false;
                CloneOrder.Program__c = null;
                CloneOrder.Memo__c = null;              

                System.debug(LoggingLevel.DEBUG,'test shipping '+cloneOrder.ShippingCity);
                System.debug(LoggingLevel.DEBUG,'test shipping '+spo.ShippingCity__c);
                Cloneorder.Order_Split_Type__c = 'Split Completed';
                
                cloneorder.Shipping_Carrier__c = spo.Shipping_Carrier__c;
                cloneorder.Service_Level__c = spo.Service_Level__c;
                //cloneorder.Is_Order_Split__c =false;
                cloneOrder.Stage_PO__c = spo.id;
                cloneOrder.SBQQ__PaymentTerm__c = spo.Payment_Terms__c;
                if(spo.Ship_to_Account_Name__c != null){
                    cloneOrder.Ship_To_Name__c = spo.Ship_to_Account_Name__c;
                }
                cloneorder.Ship_To_Phone_Number__c = spo.Ship_To_Phone_Number__c;
                cloneorder.Shipping_Method__c = spo.Shipping_Method__c;
                cloneOrder.ShipToContactName__c =spo.Ship_To_Contact_Name__c;
                
                if(spo.Quote__r.Is_RWD_Polaris_Quote__c){
                    cloneOrder.Internal_Order_Stage__c = 'Validated';
                }
                
                //cloneOrder.Standard_Carrier_Alpha_Code__c = spo.Standard_Carrier_Alpha_Code__c
                Map<string,orderItem> tempOrderItemSet = new Map<string,orderItem>();
                Set<String> parentKeyset = new Set<string>();
                Set<String> annualEDINums = new Set<string>();
                
                if(cloneOrder != null){
                    
                    String distributorOnStagePo = '';
                    if(cloneOrder.Bill_To_Name__c!=null && Orderinserthelper.getDistributorMetadata(cloneOrder.Bill_To_Name__c)!=null)
                    distributorOnStagePo =    Orderinserthelper.getDistributorMetadata(cloneOrder.Bill_To_Name__c).Po_Disti_Type__c;	
                cloneOrder.OrderExtID__c =quoteOrderMap.get(spo.Quote__c).id+''+key;
                    //newRecords.add(cloneOrder);
                newOrders.put(quoteOrderMap.get(spo.Quote__c).id+''+key,cloneOrder);
                    system.debug(LoggingLevel.DEBUG,'test code '+spo.PO_Item_Stage__r);
                    
                    set<String> processedPoEdis = new Set<String>();
                for(PO_Item_Stage__c pi: mapLineTypeToLines.get(key)){
                    string Keycheck;
                        Keycheck = pi.EDI_Line_Number__c != null ? pi.EDI_Line_Number__c+'*'+pi.Stage_PO__c:'';
                        system.debug(LoggingLevel.DEBUG,'----------each stage poi---------'+Keycheck);
                        string EDIKey = pi.EDI_Line_Number__c != null ? pi.EDI_Line_Number__c:'';
                        string buyerPartNum = pi.Buyer_Part_Number__c != null ? pi.Buyer_Part_Number__c:'';
                        orderItem oldOI = null;
                        orderItem oi =null;
                        oldOI = mapquoteLineOrderLine.get(pi.Quote_Line__c);
                        system.debug(LoggingLevel.DEBUG,'-------old oi ---'+Json.serializePretty(oldOI));
                        List<string> annualEDINumsTempLst = new List<String>();
                        List<String> annualBuyerPartNums= new List<string>();
                        string annualBuyerPartNum = '';
                               
                        if(oldOI != null  && !annualEDINums.contains(Keycheck) && (distributorOnStagePo!=null && distributorOnStagePo == 'INGRAM')){
                            if(oldOI.Product2.Product_Payment_Option__c =='Annual'){
                                system.debug(LoggingLevel.DEBUG,'---------each stage poi Annual---------');
                                Set<String> tempEDINums = oldOIEDINUMMap.get(oldOI.id) != null? oldOIEDINUMMap.get(oldOI.id): new Set<string>();
                                Integer ediCount = 0;
                                Decimal expectedPoItems = (oldOI.SBQQ__SubscriptionTerm__c != null && oldOI.SBQQ__SubscriptionTerm__c != 0) ? (oldOI.SBQQ__SubscriptionTerm__c/ 12).round(System.RoundingMode.CEILING) : 1;
                                for(string EDI : tempEDINums){
                                    if(EDI.contains(pi.Stage_PO__c) && !processedPoEdis.contains(EDI)){
                                        ediCount++;
                                        if(ediCount <= (Integer) expectedPoItems){
                                            processedPoEdis.add(EDI);
                                            annualEDINumsTempLst.add(EDI.remove('*'+pi.Stage_PO__c));
                                            if(EDI != Keycheck){
                                                annualEDINums.add(EDI);
                                            }
                                        }
                                    }
                                }
                                /*
                                set<String> tempBPNums = oldOIBuyersPartNumMap.get(oldOI.id) != null? oldOIBuyersPartNumMap.get(oldOI.id): new set<string>();
                                for(string EDI : tempBPNums){
                                    if(EDI.contains(pi.Stage_PO__c)){
                                        annualBuyerPartNums.add(EDI.remove('*'+pi.Stage_PO__c));
                                    }
                                }*/
                                annualBuyerPartNum = oldOIBuyersPartNumMap.get(oldOI.id) != null? oldOIBuyersPartNumMap.get(oldOI.id) : '';
                            }
                        }
                        system.debug(LoggingLevel.DEBUG,'test palak circular '+Keycheck);
                        system.debug(LoggingLevel.DEBUG,'test palak circular '+annualEDINums);
                        if(annualEDINums.contains(Keycheck)){
                            system.debug(LoggingLevel.DEBUG,'----------each stage poi Annual continue---------');
                            continue;
                        }
    
    
                        if(needFieldUpdate.containsKey(keycheck) ){
                            system.debug(LoggingLevel.DEBUG,'----------update parent fields---------');
                            //oldOI =orderItemMap.get(Keycheck+spo.Quote__c);
                            oi =ediLinesCreated.get(Keycheck);
    
                            if(oi != null){
                                oi.orderId=null;
                                oi.SBQQ__OrderedQuantity__c = pi.Quantity__c;
                                oi.quantity = pi.Quantity__c;
                                oi.SBQQ__QuotedQuantity__c =oldOI.SBQQ__QuotedQuantity__c;
                                oldOI.SBQQ__OrderedQuantity__c = 0;
                                 // PRDOPS22-381-Prashant
                                if(cloneOrder.type =='Revenue' && oi.SBQQ__OrderedQuantity__c!=null && oi.product2.License_per_Qty__c!=null)
                                oi.User_license_count__c  = oi.SBQQ__OrderedQuantity__c*oi.product2.License_per_Qty__c;
                               
                                updateOLDOI.add(oldOI);
                                ediLinesCreated.put(keycheck,oi);
                                tempOrderItemSet.put(keycheck,oi);
                                parentKeyset.remove(keycheck);
                            }
                            
                        }
                        
                        if(Keycheck !='' && !ediLinesCreated.containsKey(Keycheck)){
                            system.debug(LoggingLevel.DEBUG,'----------normal processing---------');
                            System.debug(LoggingLevel.DEBUG,'test code exception');
                            //oldOI =orderItemMap.get(Keycheck+spo.Quote__c);
                            //oldOI.orderID= null;
                            //System.debug('test code old OI '+oldOI.orderID);
                            oi = oldOI != null? oldOI.clone():null;
                           
                            if(oi != null){
                                oi.orderId=null;
                                //oi.orderID=null;
                                oi.SBQQ__OrderedQuantity__c = pi.Quantity__c;
                                oi.SBQQ__QuotedQuantity__c =oldOI.SBQQ__QuotedQuantity__c;
                                oi.quantity = pi.Quantity__c;
                                
                                 // PRDOPS22-381-Prashant
                                if(cloneOrder.type =='Revenue' && oi.SBQQ__OrderedQuantity__c!=null && oi.product2.License_per_Qty__c!=null)
                                oi.User_license_count__c  = oi.SBQQ__OrderedQuantity__c*oi.product2.License_per_Qty__c;

                                //oi.order= new Order(OrderExtID__c =quoteOrderMap.get(spo.Quote__c)+''+SPO.id);
                                oi.OIExternalID__c   = Keycheck;
                                ediLinesCreated.put(Keycheck,oi);
                                tempOrderItemSet.put(keycheck,oi);
                                oldOI.SBQQ__OrderedQuantity__c = 0;
                                oi.EDI_Line_Number__c =EDIKey;
                                oi.Buyer_Part_Number__c = buyerPartNum;
                                if(oldOI.Product2.Product_Payment_Option__c =='Annual' && (distributorOnStagePo!=null && distributorOnStagePo == 'INGRAM')){
                                    oi.EDI_Line_Number__c =String.join(annualEDINumsTempLst,';');
                                    //oi.Buyer_Part_Number__c =String.join(annualBuyerPartNums,';');
                                    oi.Buyer_Part_Number__c = annualBuyerPartNum;
                                    System.debug(LoggingLevel.DEBUG,'---annualBuyerPartNum---'+annualBuyerPartNum);
                                }
                                updateOLDOI.add(oldOI);
                            }
                            
                            
                           
                            //newRecords.add(oi);
                        }
    
                        
                        if(oldOI != null && oldOI.SBQQ__RequiredBy__c != null && oi != null){
                                system.debug(LoggingLevel.DEBUG,'----------required by---------');
                                system.debug(LoggingLevel.DEBUG,'----------oldOI.SBQQ__RequiredBy__c---------'+oldOI.SBQQ__RequiredBy__c);
                                system.debug(LoggingLevel.DEBUG,'----------old quoteline oldOI.SBQQ__RequiredBy__c---------'+mapIdOrderItem.get(oldOI.SBQQ__RequiredBy__c).SBQQ__QuoteLine__r.Name);
                                
                                List<orderItem> parentoiList = mapOLDOINewOI.get(oldOI.SBQQ__RequiredBy__c);
                                List<String> EDINUMs = oldOIEDINUMMap.get(oldOI.SBQQ__RequiredBy__c) != null? new List<String>(oldOIEDINUMMap.get(oldOI.SBQQ__RequiredBy__c)): new List<string>();
                                //List<String> buyerPartNUMs = oldOIBuyersPartNumMap.get(oldOI.SBQQ__RequiredBy__c) != null? new List<String>(oldOIBuyersPartNumMap.get(oldOI.SBQQ__RequiredBy__c)): new List<string>();
                                system.debug(LoggingLevel.DEBUG,'----------EDINUMs ---------'+EDINUMs);
                                List<String> EDINUMList = new List<string>();
                                boolean foundParent = false;
                                String parentKey ='';
                                String buyersPartKey = '';
                                system.debug(LoggingLevel.DEBUG,'test req by '+oi.SBQQ__RequiredBy__c);
                                oi.SBQQ__RequiredBy__c = null;
                                Integer index = 0;
                                for(string en: EDINUMs){
                                    if(en.contains(pi.Stage_PO__c)){
                                        parentKey =en;
                                        //buyersPartKey = buyerPartNUMs[index]; 
                                        if(ediLinesCreated.containsKey(en)){
                                            //oi.putSObject('SBQQ__RequiredBy__r',ediLinesCreated.get(en));
                                            oi.ParentExtID__c = parentKey;
                                            system.debug(LoggingLevel.DEBUG,'test palak circular '+oi.OIExternalID__c+'---'+oi.ParentExtID__c);
                                            foundParent=true;
                                            break;
                                        }
                                    }
                                    index ++;
                                }
                                
                                system.debug(LoggingLevel.DEBUG,'-------foundParent -----'+foundParent);
                                system.debug(LoggingLevel.DEBUG,'-------parentKey -----'+parentKey);
                                system.debug(LoggingLevel.DEBUG,'-------buyersPartKey -----'+buyersPartKey );
                        set<String> standaloneProd = new set<String>{'Standalone Software Addon', 'SaaS Software Addon', 'Addon'};
                        if(!foundParent && parentKey !='' && !standaloneProd.contains(oldOI.Product2.Product_Level__c)){
                                    orderItem oldOIParent =mapIdOrderItem.get(oldOI.SBQQ__RequiredBy__c);
                                    orderItem oiParent = oldOIParent != null? oldOIParent.clone():null;
                                    
                                    if(oiParent != null){
                                        oiParent.OIExternalID__c = parentKey;
                                        oi.ParentExtID__c = parentKey;
                                        //oiParent.putSObject('order',cloneOrder);
                                        System.debug(LoggingLevel.DEBUG,'test code old OI '+oi.orderID);
                                        //oiParent.orderID=null;
                                        System.debug(LoggingLevel.DEBUG,'test code old OI '+oi.orderID);
                                        oiParent.orderID=null;
                                        oiParent.EDI_Line_Number__c =parentKey.remove('*'+pi.Stage_PO__c);
                                        //oiParent.Buyer_Part_Number__c = buyersPartKey.remove('*'+pi.Stage_PO__c);
                                         oiParent.Buyer_Part_Number__c = oldOIBuyersPartNumMap.get(oldOI.SBQQ__RequiredBy__c) != null ? oldOIBuyersPartNumMap.get(oldOI.SBQQ__RequiredBy__c) : '';
                                        System.debug(LoggingLevel.DEBUG,'------parent Buyers part number-------'+oiParent.Buyer_Part_Number__c);
                                        if(oldOIParent.Product2.Product_Payment_Option__c =='Annual' && (distributorOnStagePo!=null && distributorOnStagePo == 'INGRAM')){
                                            annualEDINums.add(parentKey);
                                            //annualEDINumsTempLst.clear();
                                            //annualBuyerPartNums.clear();
                                            for(string en: EDINUMs){
                                              if(en.contains(pi.Stage_PO__c)){
                                                system.debug(LoggingLevel.DEBUG,'Do nothing');
                                              }
                                                  //annualEDINumsTempLst.add(en.remove('*'+pi.Stage_PO__c));  
                                            }
                                            /*
                                            set<String> tempBPNums = oldOIBuyersPartNumMap.get(oldOIParent.Id) != null? oldOIBuyersPartNumMap.get(oldOIParent.Id): new set<string>();
                                            for(string EDI : tempBPNums){
                                                if(EDI.contains(pi.Stage_PO__c)){
                                                    annualBuyerPartNums.add(EDI.remove('*'+pi.Stage_PO__c));
                                                }
                                            }*/

                                            annualBuyerPartNum = oldOIBuyersPartNumMap.get(oldOIParent.Id) != null? oldOIBuyersPartNumMap.get(oldOIParent.Id): '';
                                            System.debug(LoggingLevel.DEBUG,'---annualEDINumsTempLst---'+annualEDINumsTempLst);
                                            oiParent.EDI_Line_Number__c =String.join(annualEDINumsTempLst,';');
                                            //oiParent.Buyer_Part_Number__c =String.join(annualBuyerPartNums,';');
                                            oiParent.Buyer_Part_Number__c = annualBuyerPartNum;
                                            System.debug(LoggingLevel.DEBUG,'---annualBuyerPartNum---'+annualBuyerPartNum);
                                        }
                                        ediLinesCreated.put(parentKey,oiParent);
                                        tempOrderItemSet.put(parentKey,oiParent);
                                        needFieldUpdate.put(parentKey,true);
                                        parentKeyset.add(parentKey);
                                        
                                    }
                                    
                                }
                                
                            }
                        system.debug(LoggingLevel.DEBUG,'\n\n\n\n\n\n');
                    }
                    ediLinesCreated.keyset().removeAll(parentKeyset);
                newOrderswithOrderLines.put(quoteOrderMap.get(spo.Quote__c).id+''+key,tempOrderItemSet.values());
                    tempOrderItemSet=null;
                }
                
                
            }
            
            if(ediLinesCreated != null && ediLinesCreated.size()>0){
                
                try{
                    
                    delete originalOrders.values(); 
                    List<orderItem> OIInsertList = new List<orderItem>();
                    List<Order> OrdertoUpdateList = new List<Order>();
                    insert newOrders.values();
                    Map<id ,Order> mapordersInserted = new map<id ,Order>();
                    Map<id,id> mapStageIdWithHWStage = new Map<id,id>();
                    Map<id,string> mapStageIdWithorderid = new Map<id,string>();
                    Map<string,set<String>> maphwOdrNoWithChildOrders = new Map<string,set<String>>();
                    //List<Order> lstOfRenewalOrd = new List<Order>();
                    Map<String, Order> orderNumberToOrder = new Map<String, Order> ();
                    Map<String, Order> ordToUpdate = new Map<String, Order>();
                    Map<id,order> mapidorders =new Map<id,order>([select id,Stage_PO__c,HW_Order__c,OrderExtID__c,Have_Hardware_Products__c,OpportunityId,SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.Renewal_Opportunity__c,Order_Sub_Type__c,OrderNumber, Associated_Order_Numbers__c, Type,NetSuite_Order__c,Sync_to_NetSuite__c from order where OrderExtID__c in :newOrderswithOrderLines.keyset() ]);
                    
                    //start Sku-53
                Map<String, Map<String, String>> mapLisenceSKutoOrderIdToCap_Asset = new Map<String, Map<String, String>>(); //Map<LicenseQLIId, => Map<orderId, TotalHwCapacity-AssetNumber>>  
                Map<String, List<OrderItem>> mapOrderIdToOLILst = new Map<String, List<OrderItem>>();//this needs to store OrderIds which having Licensce skus
                Set<String> setQuoteIds = new Set<String>();
                for(PO_Stage__c spo: stagePOs){
                    //Quote__c
                    if(!string.isblank(spo.Hardware_PO_Id__c)){
                        mapStageIdWithHWStage.put(spo.id, spo.Hardware_PO_Id__c);
                    }
                    if(!String.isBlank(spo.Quote__c)){
                        setQuoteIds.add(spo.Quote__c);
                    }
                }
                for(order ord : mapidorders.values()){
                    //ord.Have_Polaris_Products__c=false;
                    //OrdertoUpdateList.add(ord);
                    orderNumberToOrder.put(ord.OrderNumber, ord);
                    System.debug(LoggingLevel.DEBUG,'test code old OIN '+ord);
                    for(orderitem oi: newOrderswithOrderLines.get(ord.OrderExtID__c)){
                        System.debug(LoggingLevel.DEBUG,'new OI====='+oi);
                        oi.orderID = ord.id;
                        oi.OIExternalID__c = oi.OIExternalID__c != null ? oi.OIExternalID__c +'*'+ord.OrderNumber : ord.OrderNumber; 
                            OIInsertList.add(oi);
                            System.debug(LoggingLevel.DEBUG,'test code failure '+oi.OIExternalID__c);
                            System.debug(LoggingLevel.DEBUG,'test code failure '+oi.ParentExtID__c);
                            System.debug(LoggingLevel.DEBUG,'test code failure '+oi.SBQQ__RequiredBy__c);
                        }
                    }
                    System.debug(LoggingLevel.DEBUG,'test code failure '+OIInsertList);
   				TransactionalDataCollection.oppMainList.clear(); 
                TransactionalDataCollection.orderItemMainList.clear();
                TransactionalDataCollection.allOrderItems.clear();
                    insert OIInsertList;
                    //update OrdertoUpdateList;
                List<OrderItem> lstOrderItem = new List<OrderItem>();
                List<OrderItem> newOrderItems = new List<OrderItem>();
    
                if (!PhtmOrdNum.isEmpty()) {
                    for (Order po: [Select Id, OrderNumber From Order Where OrderNumber IN: PhtmOrdNum]){
                        orderNumberToOrder.put(po.OrderNumber, po);
                    }  
                }

                if(!setQuoteIds.isEmpty()){
                    newOrderItems = [SELECT Id,Replacement_Type__c,Credit_Amount__c,Product2Id, Product2.Product_Level__c, Product2.Product_Subtype__c, Product2.Product_Type__c, OIExternalID__c, Program__c,Order.Line_Types__c, Order.Id, Order.OrderNumber, Order.Order_Sub_Type__c, Order.Stage_PO__c, ParentExtID__c,SBQQ__RequiredBy__c, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__Quote__c, SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c, OrderId, SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,
                                     SBQQ__QuoteLine__r.Replacement_Details__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.Usable_Capacity__c, SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.Is_RWD_Polaris_Quote__c, Order.Related_Order__c, Order.Order_Index__c, order.Related_Orders__c, order.Related_Order_Count__c, order.HW_Order__c
                                     FROM OrderItem
                                     WHERE SBQQ__QuoteLine__r.SBQQ__Quote__c IN : setQuoteIds];
                }
                Set<String> EligibleToRealOrd = new Set<String>();
                Map<String, UtilityClass.RefreshPrgmWrapper> oldastToRefreshWrapper = new Map<String, UtilityClass.RefreshPrgmWrapper>();
                Map<Id, String> refreshHwToOldAst = new Map<Id, String>();
                Map<String, Order> OrdsByOrdNum = new Map<String, Order>();
                Set<String> replacedOrderNums = new Set<String>();
                if(!newOrderItems.isEmpty()){
                    set<string> PartialReplOrds = new set<string>();
                    for(OrderItem objOrderItem : newOrderItems){
                        if((objOrderItem.program__c == Constants.PROGRAM_UPGRADE || objOrderItem.program__c == Constants.PROGRAM_CONVERSION) && objOrderItem.SBQQ__QuoteLine__r.Replacement_Details__c != null){
                            replacedOrderNums.add(objOrderItem.Order.OrderNumber);
                            }
                        if(!OrdsByOrdNum.containskey(objOrderItem.Order.OrderNumber)){
                            OrdsByOrdNum.put(objOrderItem.Order.OrderNumber, objOrderItem.order);
                        }
                        if(objOrderItem.program__c == Constants.PROGRAM_REFRESH && objOrderItem.SBQQ__QuoteLine__r.Replacement_Details__c != null){
                            String typeofsku = UtilityClass.getTypeofSKU(objOrderItem); 
                            String selectedAst = UtilityClass.getSelectedAst(objOrderItem.SBQQ__QuoteLine__r);
                            if(selectedAst != null && typeofsku != null){
                                if(!oldastToRefreshWrapper.containskey(selectedAst)){
                                    oldastToRefreshWrapper.put(selectedAst, new UtilityClass.refreshPrgmWrapper(typeofsku, objOrderItem));
                                }
                                else{
                                    if(typeofsku == Constants.SKU_TYPE_HARDWARE){
                                        oldastToRefreshWrapper.get(selectedAst).hwLines.put(objOrderItem.id, objOrderItem.order.ordernumber);
                                    }
                                    else if(typeofsku == Constants.SKU_TYPE_LICENSE){
                                        oldastToRefreshWrapper.get(selectedAst).deltaLines.put(objOrderItem.id, objOrderItem.order.ordernumber);
                                    }
                                }
                                if(typeofsku == Constants.SKU_TYPE_HARDWARE){
                                    refreshHwToOldAst.Put(objOrderItem.id, selectedAst);
                                }
                            }
                            
                        }
                       
                        if(objOrderItem.Order.Order_Sub_Type__c != 'Renewal' && objOrderItem.Program__c != 'Conversion' && objOrderItem.Program__c != 'Upgrade'){
                            mapStageIdWithorderid.put(objOrderItem.Order.Stage_PO__c, objOrderItem.Order.OrderNumber);
                            EligibleToRealOrd.add(objOrderItem.Order.OrderNumber);
                        }
                                if(objOrderItem.Program__c != 'Conversion' && mapidorders.containsKey(objOrderItem.OrderId) && mapidorders.get(objOrderItem.OrderId) != null){	
                            mapordersInserted.put(objOrderItem.OrderId, mapidorders.get(objOrderItem.OrderId));
                        }
                        if(objOrderItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.Is_RWD_Polaris_Quote__c == true && objOrderItem.Program__c == 'Conversion' && String.isNotBlank(objOrderItem?.SBQQ__QuoteLine__r?.Arroyo_Subscribed_Asset_Name__c)){
                            if(objOrderItem?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__c != null){
                                if(mapLisenceSKutoOrderIdToCap_Asset.containsKey(objOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c)){
                                    if(mapLisenceSKutoOrderIdToCap_Asset.get(objOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c).containskey(objOrderItem.OrderId) &&
                                       mapLisenceSKutoOrderIdToCap_Asset.get(objOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c).get(objOrderItem.OrderId) != null){
                                           
                                           String refreshedSerialNumber = mapLisenceSKutoOrderIdToCap_Asset.get(objOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c).get(objOrderItem.OrderId).substringAfter('-');
                                           refreshedSerialNumber +=','+objOrderItem.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c;
                                           Decimal usableCapacity =  Decimal.ValueOf(mapLisenceSKutoOrderIdToCap_Asset.get(objOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c).get(objOrderItem.OrderId).substringBefore('-'));
                                           usableCapacity += objOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c;
                                           mapLisenceSKutoOrderIdToCap_Asset.get(objOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c).put(objOrderItem.OrderId, usableCapacity+'-'+refreshedSerialNumber);
                                           
                                       }
                                }else {
                                    mapLisenceSKutoOrderIdToCap_Asset.put(objOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,new Map<String, String> {objOrderItem.OrderId => objOrderItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c+'-'+objOrderItem.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c});
                                }
                                
                            }
                            if(objOrderItem?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__c == null){
                                if(!mapOrderIdToOLILst.containsKey(objOrderItem.OrderId))
                                    mapOrderIdToOLILst.put(objOrderItem.OrderId, new List<OrderItem>{});
                                mapOrderIdToOLILst.get(objOrderItem.OrderId).add(objOrderItem);
                            }
                        }
                        else if(objOrderItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.Is_RWD_Polaris_Quote__c == false){
                            if(ediLinesCreated.containsKey(objOrderItem.OIExternalID__c)){
                                lstOrderItem.add(objOrderItem);
                            }                                      
                        }
                        if(objOrderItem.Replacement_Type__c != null && objOrderItem.Replacement_Type__c.contains('Partial') && objOrderItem.Credit_Amount__c != null && objOrderItem.Credit_Amount__c > 0 && !PartialReplOrds.contains(objOrderItem.Order.OrderNumber)){
                            QuoteIdReplDetail.get(objOrderItem.SBQQ__QuoteLine__r.SBQQ__Quote__c).replmntOrds.add(objOrderItem.Order.OrderNumber);
                            PartialReplOrds.add(objOrderItem.Order.OrderNumber);
                        }
                    }
                }
                System.debug(LoggingLevel.DEBUG,'debug1a '+ mapStageIdWithorderid);
                System.debug(LoggingLevel.DEBUG,'debug1ab '+maphwOdrNoWithChildOrders);
                for(order ordRec : mapidorders.values()){
                    System.debug(LoggingLevel.DEBUG,'debug1ab '+ordRec);
                    
                    if(ordRec.Stage_PO__c != null && mapStageIdWithHWStage.containskey(ordRec.Stage_PO__c) && ordRec.Order_Sub_Type__c != 'Renewal' && EligibleToRealOrd.contains(ordRec.OrderNumber)){
                        System.debug(LoggingLevel.DEBUG,'debug1ac '+mapStageIdWithorderid.get(mapStageIdWithHWStage.get(ordRec.Stage_PO__c)));
                        ordRec.HW_Order__c = mapStageIdWithorderid.get(mapStageIdWithHWStage.get(ordRec.Stage_PO__c));
                        if(!maphwOdrNoWithChildOrders.containskey(ordRec.HW_Order__c))
                            maphwOdrNoWithChildOrders.put(ordRec.HW_Order__c, new set<String>());  
                        
                        maphwOdrNoWithChildOrders.get(ordRec.HW_Order__c).add(ordRec.OrderNumber);
                        
                    }
                }
                    List<orderItem> updateList = new List<orderItem>();

                if((!mapordersInserted.isEmpty() && !populateRequiredByOnQLI(mapordersInserted,maphwOdrNoWithChildOrders,refreshHwToOldAst,oldastToRefreshWrapper,replacedOrderNums,OrdsByOrdNum).isEmpty()) || refreshHwToOldAst.KeySet().Size() > 0 || !replacedOrderNums.isEmpty() ) {
                        updateList = populateRequiredByOnQLI(mapordersInserted,maphwOdrNoWithChildOrders,refreshHwToOldAst,oldastToRefreshWrapper,replacedOrderNums,OrdsByOrdNum);
                    }
                //List<orderItem> OIList = [select id,OIExternalID__c,ParentExtID__c,SBQQ__RequiredBy__c from orderitem where OIExternalID__c in: ediLinesCreated.keyset() AND SBQQ__QuoteLine__r.SBQQ__Quote__r.Is_RWD_Polaris_Quote__c = false];
                Map<string,id> oiIDMAP = new Map<string,id>();
                if(!lstOrderItem.isEmpty()){
                    for(orderItem OI : lstOrderItem){
                        System.debug(LoggingLevel.DEBUG,'new OI queried====='+OI );
                        oiIDMAP.put(oi.OIExternalID__c,oi.id);
                    }
                    //List<orderItem> updateList = new List<orderItem>();
                    for(orderItem OI: lstOrderItem){
                        System.debug(LoggingLevel.DEBUG,'LoggingLevel.DEBUG,new OI 3====='+OI );
                        if(oi.ParentExtID__c != null && oi.ParentExtID__c !='' && oiIDMAP.get(oi.ParentExtID__c) != null){
                            oi.SBQQ__RequiredBy__c = oiIDMAP.get(oi.ParentExtID__c);
                            updateList.add(oi);
                        }
                    }
                }
                
                if(!mapOrderIdToOLILst.isEmpty() && !mapLisenceSKutoOrderIdToCap_Asset.isEmpty()){
                    for(String strOrderId : mapOrderIdToOLILst.keySet()){
                        for(OrderItem objOLI : mapOrderIdToOLILst.get(strOrderId)){
                            if(mapLisenceSKutoOrderIdToCap_Asset.containskey(objOLI.SBQQ__QuoteLine__c) &&
                               mapLisenceSKutoOrderIdToCap_Asset.get(objOLI.SBQQ__QuoteLine__c).containskey(strOrderId)){
                                   String serialNumber = mapLisenceSKutoOrderIdToCap_Asset.get(objOLI.SBQQ__QuoteLine__c).get(strOrderId).substringAfter('-');
                                   updateList.add(new OrderItem(Id =objOLI.Id, SerialNumber__c = serialNumber));
                               }
                        }
                    }
                    
                }   
                if(!QuoteIdReplDetail.isEmpty()){
                    for(Id QuoteId : QuoteIdReplDetail.keyset()){
                        Replacement repl = QuoteIdReplDetail.get(QuoteId);
                        Boolean submitOrd = false;
                        if(repl.PhtmOrdNum != null && !repl.replmntOrds.isEmpty()){
                            Order phtmOrd = orderNumberToOrder.get(repl.PhtmOrdNum);
                            for(String replOrdNum : repl.replmntOrds){
                                Order replOrd = orderNumberToOrder.get(replOrdNum);
                                if(replOrd != null){
                                submitOrd = submittedReplOrd.contains(replOrd.OrderNumber) ? true :false;
                                    ordToUpdate.put(replOrd.OrderNumber, new Order(Id = replOrd.Id, Associated_Order_Numbers__c = phtmOrd.ordernumber));
                                }
                            }
                             if(phtmOrd != null){
                                ordToUpdate.put(phtmOrd.OrderNumber, new Order(Id = phtmOrd.Id, Associated_Order_Numbers__c = string.join(repl.replmntOrds,','), Sync_to_NetSuite__c = submitOrd));
                            }
                        }
                    }
                }
                
                if (!ordToUpdate.isEmpty()) {
                    TriggerHandler.bypass('OrderHandler');
                    update ordToUpdate.values();
                    TriggerHandler.clearbypass('OrderHandler');
                }   
                if(!updateList.isEmpty())
                    update updateList;
                
                
            }catch(Exception e){
                List<Batch_Error_Log__c> belList = new List<Batch_Error_Log__c>();
                for(Order o: originalOrders.values()){
                    Batch_Error_Log__c bel = new Batch_Error_Log__c();
                    bel.Failure_Job_ID__c = bc.getJobID();
                    bel.Object_ID__c = o.id;
                    bel.Failure_Message__c = e.getMessage();
                    belList.add(bel);
                }
                insert belList;
                
            }
        }
      }
    } 
      /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Calling Finish Method Executing All Processing After Batch completed   
   * @param bc
   * */
    global void finish(Database.BatchableContext bc){
     system.debug(LoggingLevel.DEBUG, ' Do Nothing in Finish');   
        
    }

     /*******************************polaris 2.O - Populating Required By: Ticket : RWD 95*************************************/
   /**
   * @date 05-03-2025
   * @description populate Required By Id For OrderLines.
   * @param mapordersInserted
   * @param maphwOdrNoWithChildOrders
   * @return List<OrderItem>
   * */ 

    public List<OrderItem> populateRequiredByOnQLI(Map<id ,Order> mapordersInserted, Map<string, set<string>> maphwOdrNoWithChildOrders, Map<Id, String> refreshHwToOldAst, Map<String, UtilityClass.refreshPrgmWrapper> oldastToRefreshWrapper, Set<String> replacedOrderNums, Map<String, Order> OrdsByOrdNum){
            
        Map<String, List<orderItem>> mapOrderNumberTochildOrderLines = new Map<String, List<orderItem>>();
         Map<String, orderItem> mapQuoteLineHWOrderToOLI = new Map<String, orderItem>();
        List<orderItem> updateLstOLIRequiredBy = new List<orderItem>();
        Map<String, String> mapHWOrderToRelatedOrder = new Map<String, String>();
        Map<Id, Order> ordersToUpdate = new Map<Id, Order>();
        String hwOrderNumber = '';
        Map<String, String> refHwOrdToLicenseOrd = new Map<String, String>();
        Map<String, String> licOrdToHwOrd = new Map<String, String>();
    for(orderItem objOLI : [SELECT Id,Program__c, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,Product2Id,Product2.Product_Level__c,Product2.Product_Type__c,Product2.ProductCode,SBQQ__QuoteLine__r.SBQQ__Quote__c,
                SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__ProductCode__c, SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__ProductCode__c,
                SBQQ__QuoteLine__r.SBQQ__Product__r.ProductCode,SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                OrderId, Order.Related_Order__c, Order.HW_Order__c, Order.OrderNumber
                FROM orderItem
                WHERE OrderId IN : mapordersInserted.keySet() AND
                SBQQ__QuoteLine__c != null
                AND SBQQ__QuoteLine__r.SBQQ__Quote__r.Is_RWD_Polaris_Quote__c = true]) {
        
            if(objOLI.Program__c == Constants.PROGRAM_REFRESH){
                List<String> licorderNums =new List<String>();
                if(!String.isBlank(objOLI.Product2Id) && (objOLI.Product2.Product_Level__c =='Hardware' && (objOLI.Product2.Product_Type__c =='Hardware' || objOLI.Product2.Product_Type__c == 'Add-On Node'))){
                    if(refreshHwToOldAst.containskey(objOLI.id) && oldastToRefreshWrapper.containskey(refreshHwToOldAst.get(objOLI.id))){
                        licorderNums = oldastToRefreshWrapper.get(refreshHwToOldAst.get(objOLI.id)).deltaLines.values();
                         
                        if(!refHwOrdToLicenseOrd.containskey(objOLI.order.ordernumber)){
                            refHwOrdToLicenseOrd.put(objOLI.order.ordernumber, String.join(licorderNums, ',')); 
                        }
                    }
                    for(String licOrd: licorderNums){
                        if(maphwOdrNoWithChildOrders.containskey(objOLI.order.ordernumber)){
                            maphwOdrNoWithChildOrders.get(objOLI.order.ordernumber).add(licOrd);
                        }
                        else{
                            maphwOdrNoWithChildOrders.put(objOLI.order.ordernumber, new Set<String>{licOrd});
                        }
                        licOrdToHwOrd.put(licOrd, objOLI.order.ordernumber);
                    }
                }
                
            }
            if(objOLI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c == null) {
                if(!mapQuoteLineHWOrderToOLI.containsKey(objOLI.SBQQ__QuoteLine__c  +'-' +objOLI.order.orderNumber))
                    mapQuoteLineHWOrderToOLI.put(objOLI.SBQQ__QuoteLine__c  +'-' +objOLI.order.orderNumber, objOLI);
            }

          if(mapordersInserted.containsKey(objOLI.OrderId) && !String.isBlank(mapordersInserted.get(objOLI.OrderId).HW_Order__c)) {
                hwOrderNumber = mapordersInserted.get(objOLI.OrderId).HW_Order__c;

                if(hwOrderNumber == objOLI.Order.OrderNumber) {
                    
                    if(!mapQuoteLineHWOrderToOLI.containsKey(objOLI.SBQQ__QuoteLine__c +'-' +objOLI.order.orderNumber))
                      mapQuoteLineHWOrderToOLI.put(objOLI.SBQQ__QuoteLine__c +'-' +objOLI.order.orderNumber, objOLI);
 
                 }
         
        if(!mapOrderNumberTochildOrderLines.containsKey(hwOrderNumber)) 
          mapOrderNumberTochildOrderLines.put(hwOrderNumber, new List<OrderItem>());
          mapOrderNumberTochildOrderLines.get(hwOrderNumber).add(objOLI);
        
        if(!mapQuoteLineHWOrderToOLI.containsKey(objOLI.SBQQ__QuoteLine__c+'-'+hwOrderNumber  +'-' +objOLI.order.orderNumber))
          mapQuoteLineHWOrderToOLI.put(objOLI.SBQQ__QuoteLine__c+'-'+hwOrderNumber  +'-' +objOLI.order.orderNumber, objOLI);

        
      }else {
        if(!mapOrderNumberTochildOrderLines.containsKey(objOLI.Order.OrderNumber))
          mapOrderNumberTochildOrderLines.put(objOLI.Order.OrderNumber, new List<OrderItem>());
          mapOrderNumberTochildOrderLines.get(objOLI.Order.OrderNumber).add(objOLI);
        
        //if(!mapQuoteLineHWOrderToOLI.containsKey(objOLI.SBQQ__QuoteLine__c))
          //mapQuoteLineHWOrderToOLI.put(objOLI.SBQQ__QuoteLine__c, objOLI);


      }
      
      
                
        }

        if(!mapOrderNumberTochildOrderLines.isEmpty()) {
            for(String strOrderNumber : mapOrderNumberTochildOrderLines.keySet()){
                 String OrderLineItem = '';

               for(orderItem objOrderitem : mapOrderNumberTochildOrderLines.get(strOrderNumber)) {
                 if(objOrderitem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c != null){
                OrderItem objOLI = new OrderItem(Id = objOrderitem.Id);
                if(mapQuoteLineHWOrderToOLI.containskey(objOrderitem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c+'-'+strOrderNumber +'-' +objOrderitem.order.orderNumber)){
                    OrderLineItem = mapQuoteLineHWOrderToOLI.get(objOrderitem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c+'-'+strOrderNumber +'-' +objOrderitem.order.orderNumber).Id;
                    objOLI.SBQQ__RequiredBy__c = OrderLineItem;
    
                }else if(mapQuoteLineHWOrderToOLI.containskey(objOrderitem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c +'-' +objOrderitem.order.orderNumber)){
    
                    OrderLineItem = mapQuoteLineHWOrderToOLI.get(objOrderitem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c +'-' +objOrderitem.order.orderNumber).Id;
                    objOLI.SBQQ__RequiredBy__c = OrderLineItem;    
                    
                 }
                updateLstOLIRequiredBy.add(objOLI);

                }else {
                     if(!mapHWOrderToRelatedOrder.containskey(strOrderNumber)) 
                        mapHWOrderToRelatedOrder.put(strOrderNumber, objOrderitem.Order.OrderNumber);
                    
                 } 
                continue;
      
               }
               
            }        
         }
        if(replacedOrderNums.size() > 0){
            Integer index = 0;
            for(String replacedOrdNumber : replacedOrderNums){
                index ++;
                if(OrdsByOrdNum.containskey(replacedOrdNumber)){
                    Order replacedOrd = OrdsByOrdNum.get(replacedOrdNumber);
                    replacedOrd.Order_Index__c = index;
                    replacedOrd.Related_Order__c = replacedOrd.Related_orders__c = string.join(new List<String>(replacedOrderNums),',');
                    replacedOrd.Related_Order_Count__c = replacedOrderNums.size();
                    ordersToUpdate.put(replacedOrd.id,replacedOrd);
                }
            }
        }
         for(Order objOrder : mapordersInserted.values()){
            Order objOrd = ordersToUpdate.containskey(objOrder.Id) ? ordersToUpdate.get(objOrder.Id) : new Order(Id = objOrder.Id);
                if(String.isNotBlank(objOrder.HW_Order__c)){
                    objOrd.HW_Order__c = objOrder.HW_Order__c;
                    
                    if(mapHWOrderToRelatedOrder.containskey(objOrder.HW_Order__c)) 
                        objOrd.Related_Order__c = mapHWOrderToRelatedOrder.get(objOrder.HW_Order__c);
                }
             if(refHwOrdToLicenseOrd.containskey(objOrder.orderNumber)){
                 objOrd.HW_Order__c = objOrder.orderNumber;
                 objOrd.Related_Order__c = refHwOrdToLicenseOrd.get(objOrder.orderNumber);
             }
             if(licOrdToHwOrd.containskey(objOrder.orderNumber)){
                 objOrd.HW_Order__c = licOrdToHwOrd.get(objOrder.orderNumber);
                 objOrd.Related_Order__c = refHwOrdToLicenseOrd.get(licOrdToHwOrd.get(objOrder.orderNumber));
                }
            
             if(maphwOdrNoWithChildOrders.containskey(objOrd.HW_Order__c) && objOrd.HW_Order__c !=null){
                    objOrd.Related_Order_Count__c= maphwOdrNoWithChildOrders.get(objOrd.HW_Order__c).size();
                 List<string> orderNumberList = new List<string>(maphwOdrNoWithChildOrders.get(objOrd.HW_Order__c));  
                    objOrd.Related_orders__c = string.join(orderNumberList,',');
                Integer index = 0;
                for(String relatedOrdNumber : orderNumberList){
                    index ++;
                    if(OrdsByOrdNum.containskey(relatedOrdNumber)){
                        Order realtedOrd = OrdsByOrdNum.get(relatedOrdNumber);
                        if(ordersToUpdate.containskey(realtedOrd.id)){
                            ordersToUpdate.get(realtedOrd.id).Order_Index__c =  index;
                        }
                        else{
                            realtedOrd.Order_Index__c = index;
                            ordersToUpdate.put(realtedOrd.id,realtedOrd);
                        }
                    }
                } 
            }
            if(!ordersToUpdate.containskey(objOrd.id)){
                ordersToUpdate.put(objOrd.id, objOrd);
            } 
            else{
                Order ordWithUpdatedVal = ordersToUpdate.get(objOrd.id);
                objOrd.Order_Index__c = ordWithUpdatedVal.Order_Index__c;
                ordersToUpdate.put(objOrd.Id, objOrd);                
             }
                            
            }

            if(!ordersToUpdate.values().isEmpty()) {
                
                TriggerHandler.bypass('OrderHandler');
                update ordersToUpdate.values();
                TriggerHandler.clearBypass('OrderHandler');
            }

            if(!updateLstOLIRequiredBy.isEmpty()) 
                return updateLstOLIRequiredBy;
            
                return new List<OrderItem>();
        
    }
    
    
    /******************************************************
     * Description : To split netapp order -PRDOPS23-46
     * ****************************************************** */
   /**
   * @date 05-03-2025
   * @description populate Required By Id For OrderLines.
   * @param netappOrd
   * @param jobId
   * @param rcdmSkus
   * */ 
    public void splitNetAppOrder(List<Order> netappOrd , Id jobId, Set<String> rcdmSkus){
        Map<string,SplitGroupClass> keyLineSplitCls = new Map<string,SplitGroupClass>();
        Map<id,List<Order>> orgOrdIdCloneOrds = new Map<id,List<Order>>();
        List<Order> ordToUpsert = new List<Order>();
        List<OrderItem> ordItmInsert = new List<OrderItem>();
        Map<id,orderItem> delOrderItms = new Map<id,orderItem>();
        Map<id,Integer> ordIdIndex = new map<id,Integer>();
        Map<id,id> oppIdEDIOrderId = new Map<id,id>();
        List<Batch_Error_Log__c> errorLogs = new List<Batch_Error_Log__c>();
        Set<id> setOfQutId = new Set<id>();
        Map<Id, OrderItem> mapOfLiscenseToRcdm = new Map<Id, Orderitem>();
        try{
            Integer splitByQuant = Integer.valueOf(System.Label.Netapp_Split_By_Quantity);
            for(Order ord : netappOrd){
                oppIdEDIOrderId.put(ord.opportunityId,null);
            }
            for(Order ord :[select id,opportunityId from order where opportunityId IN: oppIdEDIOrderId.keyset() and Order_Split_Type__c ='Not needed']){
                oppIdEDIOrderId.put(ord.opportunityId,ord.id);
            }
            
            for(Order ord : netappOrd){
                
                ord.Order_Split_Type__c = 'Split Completed';
                ord.Auto_Manual_Split__c = 'System Generated';
              	ord.Reason_For_Split__c = 'System Split based on Netapp rules';
                Boolean isPolarisOrd = ord.Is_RWD_Polaris_Quote__c;
                Boolean hasHWProd = ord.Have_Hardware_Products__c;
                Map<id,string> hwItmKey = new Map<id,string>();
                Map<id,set<string>> hwItmKeyforV2 = new Map<id,set<string>>();
                Map<string,string> hwKeyforSuppV2 = new Map<string,string>();
                Map<Id,String> hwSoftSupV2 = new Map<id,String>();
                Integer cloneOrdCount = 0;
                If(ord.SBQQ__Quote__c !=  null){
                    setOfQutId.add(ord.SBQQ__Quote__c);
                }
                if(ord.orderitems!= null){
                    for(OrderItem OI : ord.orderitems){
                        string key ='';
                        if(isPolarisOrd){
                            if(OI.Product2.Product_Level__c == 'Hardware' && (OI.Product2.Product_Type__c == 'Add-On Node' ||  OI.Product2.Product_Type__c == 'Hardware')){
                                key = ord.id+'-'+OI.Product2.ProductCode+'-'+OI.SBQQ__RequiredBy__r.Product2.ProductCode+'-'+OI.SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c;
                                if(keyLineSplitCls.containsKey(key)){
                                    Integer tempCount = (Integer) Math.abs((((keyLineSplitCls.get(key).totalQuantity + OI.quantity) / splitByQuant).round(System.RoundingMode.CEILING)) - (keyLineSplitCls.get(key).totalQuantity/ splitByQuant).round(System.RoundingMode.CEILING)); 
                                    cloneOrdCount += (tempCount * 2);
                                    keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                    keyLineSplitCls.get(key).parentIdBundleItms.put(OI.SBQQ__RequiredBy__c,new List<orderItem>{OI});
                                    keyLineSplitCls.get(key).hwLineItem.add(OI); 
                                }else{
                                    keyLineSplitCls.put(key, new SplitGroupClass(OI,'bundle',true));
                                    Integer tempCount1 = (Integer) Math.abs((OI.quantity / splitByQuant).round(System.RoundingMode.CEILING));  
                                    cloneOrdCount += (tempCount1 * 2);
                                }
                                
                                if(hwItmKeyforV2.get(OI.SBQQ__RequiredBy__c) != null){
                                    hwItmKeyforV2.get(OI.SBQQ__RequiredBy__c).add(key);
                                }else{
                                    hwItmKeyforV2.put(OI.SBQQ__RequiredBy__c, new set<string>{key});
                                }
                                hwKeyforSuppV2.put(OI.Product2.ProductCode+'-'+OI.SBQQ__RequiredBy__c,key);
                                hwSoftSupV2.put(OI.SBQQ__RequiredBy__c, key); 
                            }
                            if(rcdmSkus.contains(OI.Product2.ProductCode)){
                                mapOfLiscenseToRcdm.put(OI.SBQQ__RequiredBy__c, OI);
                            }
                        }
                        else{
                            if(OI.Product2.Product_Type__c == 'Foundation Edition' || OI.Product2.Product_Type__c=='Enterprise Edition'|| OI.Product2.Product_Type__c =='Premium Edition'|| OI.Product2.Product_Type__c =='Business Edition') {
                                key =  ord.id+'-'+OI.SBQQ__RequiredBy__r.Product2.ProductCode+'-'+OI.Product2.ProductCode+'-'+OI.SBQQ__SubscriptionTerm__c ;
                                if(keyLineSplitCls.containsKey(key)){
                                    cloneOrdCount += (Integer) Math.abs((((keyLineSplitCls.get(key).totalQuantity + OI.quantity) / splitByQuant).round(System.RoundingMode.CEILING)) - (keyLineSplitCls.get(key).totalQuantity/ splitByQuant).round(System.RoundingMode.CEILING)); 
                                    keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                    keyLineSplitCls.get(key).parentIdBundleItms.put(OI.SBQQ__RequiredBy__c,new List<orderItem>{OI});
                                }else{
                                    keyLineSplitCls.put(key, new SplitGroupClass(OI,'bundle',false));
                                    cloneOrdCount += (Integer) Math.abs((OI.quantity / splitByQuant).round(System.RoundingMode.CEILING)) ; 
                                }
                                hwItmKey.put(OI.SBQQ__RequiredBy__c,key);
                            }  
                            
                        }
                    }
                    for(OrderItem OI : ord.orderitems){
                        string key ='';
                        if(!isPolarisOrd && OI.Product2.Product_Type__c == 'O365'){
                            key = ord.id+'-'+OI.SBQQ__SubscriptionTerm__c+'-SAAS' ;
                            if(keyLineSplitCls.containsKey(key)){
                                keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                keyLineSplitCls.get(key).OIList.add(OI);
                            }else{
                                keyLineSplitCls.put(key, new SplitGroupClass(OI,'SAAS',false));
                                cloneOrdCount++;
                            }
                        }else if(rcdmSkus.contains(OI.Product2.ProductCode)){
                            delOrderItms.put(OI.id, OI);
                        }
                        else if(!isPolarisOrd && OI.Product2.Category__c =='Professional Services'){
                            key = ord.id+'-PS-SKU';
                            if(keyLineSplitCls.containsKey(key)){
                                keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                keyLineSplitCls.get(key).OIList.add(OI);
                            }else{
                                keyLineSplitCls.put(key, new SplitGroupClass(OI,'PS-SKU',false));
                                cloneOrdCount++;
                            }
                        }else if(isPolarisOrd && OI.Product2.Category__c =='Professional Services'){
                            key = ord.id+'-PS-SKU';
                            if(keyLineSplitCls.containsKey(key)){
                                keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                keyLineSplitCls.get(key).OIList.add(OI);
                            }else{
                                keyLineSplitCls.put(key, new SplitGroupClass(OI,'PS-SKU',true));
                                cloneOrdCount++;
                            }
                        }
                        else if(!isPolarisOrd && OI.Product2.Product_Type__c == 'Accessories'){
                            key = ord.id+'-Accessory';
                            if(keyLineSplitCls.containsKey(key)){
                                keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                keyLineSplitCls.get(key).OIList.add(OI);
                            }else{
                                keyLineSplitCls.put(key, new SplitGroupClass(OI,'Accessory',false));
                                cloneOrdCount++;
                            }
                        }
                        else if(isPolarisOrd && OI.Product2.Product_Level__c == 'Hardware' && OI.Product2.Product_Type__c == 'Accessories'){
                             key = ord.id+'-Accessory';
                            if(keyLineSplitCls.containsKey(key)){
                                keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                keyLineSplitCls.get(key).OIList.add(OI);
                            }else{
                                keyLineSplitCls.put(key, new SplitGroupClass(OI,'Accessory',true));
                                cloneOrdCount++;
                            }
                        }
                        else if(isPolarisOrd && OI.Product2.Product_Level__c == 'SaaS Software Addon'){
                             if(hasHWProd){
                                key = OI.SBQQ__RequiredBy__c; 
                                if(keyLineSplitCls.containsKey(hwSoftSupV2.get(key))){
                                    keyLineSplitCls.get(hwSoftSupV2.get(key)).parentIdBundleItms.get(key).add(OI);
                                }else{
                                    system.debug(LoggingLevel.DEBUG,'Couldnt find corresponding sw line'+OI.id);
                                    errorLogs.add(new Batch_Error_Log__c(Failure_Job_ID__c = jobId,Object_ID__c = ord.opportunityId,Failure_Message__c = 'Couldnt find corresponding sw line'+OI.id,Class_Name__c='SplitOrder'));
                                }
                                
                            }else{
                                key = ord.id+'-Addon';
                                if(keyLineSplitCls.containsKey(key)){
                                    keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                    keyLineSplitCls.get(key).OIList.add(OI);
                                }else{
                                    keyLineSplitCls.put(key, new SplitGroupClass(OI,'Addon',true));
                                    cloneOrdCount++;
                                } 
                            }
                        }else if(isPolarisOrd && OI.Product2.Family == 'Non-Returnable Disk Service'){
                            if(hasHWProd){
                                string keyforSupport = '';
                                if(OI.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c != null){
                                    keyforSupport = OI.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c;
                                    key = OI.SBQQ__RequiredBy__r.Product2.ProductCode +'-'+ OI.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c ;
                                }
                                else if(OI.SBQQ__RequiredBy__c != null){
                                    keyforSupport = OI.SBQQ__RequiredBy__c;
                                    key = OI.SBQQ__RequiredBy__r.Product2.ProductCode +'-'+ OI.SBQQ__RequiredBy__c ;
                                }
                                System.debug(LoggingLevel.DEBUG,'debug1 '+key);
                                System.debug(LoggingLevel.DEBUG,'debug2 '+hwKeyforSuppV2.get(key));
                                System.debug(LoggingLevel.DEBUG,'debug3 '+keyLineSplitCls.get(hwKeyforSuppV2.get(key)));
                                if(keyLineSplitCls.containsKey(hwKeyforSuppV2.get(key))){
                                    keyLineSplitCls.get(hwKeyforSuppV2.get(key)).parentIdBundleItms.get(keyforSupport).add(OI);
                                }else{
                                    system.debug(LoggingLevel.DEBUG,'Couldnt find corresponding sw line'+OI.id);
                                    errorLogs.add(new Batch_Error_Log__c(Failure_Job_ID__c = jobId,Object_ID__c = ord.opportunityId,Failure_Message__c = 'Couldnt find corresponding sw line'+OI.id,Class_Name__c='SplitOrder'));
                                }
                           }else{
                               key = ord.id+'-Addon';
                               if(keyLineSplitCls.containsKey(key)){
                                   keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                   keyLineSplitCls.get(key).OIList.add(OI);
                               }else{
                                   keyLineSplitCls.put(key, new SplitGroupClass(OI,'Addon',true));  
                                   cloneOrdCount++;
                               } 
                           }
                       }else if(isPolarisOrd &&(OI.Product2.Product_Type__c == 'HW Support' && OI.Product2.Product_Level__c == 'Support')){  
                            string keyforSupport = '';
                            if(OI.Product2.Product_Type__c == 'HW Support' && OI.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c != null){
                                keyforSupport = OI.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c;
                                key = OI.SBQQ__RequiredBy__r.Product2.ProductCode +'-'+ OI.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c ;
                            }
                            else if(OI.Product2.Product_Type__c == 'HW Support' && OI.SBQQ__RequiredBy__c != null){
                                keyforSupport = OI.SBQQ__RequiredBy__c;
                                key = OI.SBQQ__RequiredBy__r.Product2.ProductCode +'-'+ OI.SBQQ__RequiredBy__c ;
                            }
                            if(keyLineSplitCls.containsKey(hwKeyforSuppV2.get(key))){
                                keyLineSplitCls.get(hwKeyforSuppV2.get(key)).parentIdBundleItms.get(keyforSupport).add(OI);
                            }else{
                                system.debug(LoggingLevel.DEBUG,'Couldnt find corresponding sw line'+OI.id);
                                errorLogs.add(new Batch_Error_Log__c(Failure_Job_ID__c = jobId,Object_ID__c = ord.opportunityId,Failure_Message__c = 'Couldnt find corresponding sw line'+OI.id,Class_Name__c='SplitOrder'));
                            }
                        }
                        else if(isPolarisOrd && ((OI.Product2.Product_Level__c == 'Hybrid Software' || (OI.Product2.Product_Level__c == 'OnPrem' && (OI.Product2.Product_Type__c == 'Foundation Edition' || OI.Product2.Product_Type__c == 'Enterprise Edition' || OI.Product2.Product_Type__c == 'Business Edition') && OI?.Product2?.Product_Subtype__c == null) || OI.Product2.Product_Level__c == 'LOD Software') && OI.Product2.Product_Subtype__c != 'RCDM')){
                            key = OI.id;
                            Set<string> tempKey = hwItmKeyforV2.containsKey(key)?hwItmKeyforV2.get(key):new Set<String>();
                            for(string keyVal: tempKey){
                                if(keyLineSplitCls.containsKey(keyVal)){
                                    keyLineSplitCls.get(keyVal).parentIdBundleItms.get(key).add(OI);
                                }else{
                                    system.debug(LoggingLevel.DEBUG,'Couldnt find corresponding sw line'+OI.id);
                               		errorLogs.add(new Batch_Error_Log__c(Failure_Job_ID__c = jobId,Object_ID__c = ord.opportunityId,Failure_Message__c = 'Couldnt find corresponding sw line'+OI.id,Class_Name__c='SplitOrder'));
                                }
                            }
                        }
                        else if(isPolarisOrd && (OI.Product2.Product_Level__c == 'Standalone Software Addon' || OI.Product2.Product_Level__c == 'SaaS Software Addon') && OI.Product2.License_Category__c == 'SaaS'){
                            key = ord.id+'-'+OI.SBQQ__SubscriptionTerm__c+'-SAAS' ;
                            if(keyLineSplitCls.containsKey(key)){
                                keyLineSplitCls.get(key).totalQuantity+= OI.quantity;
                                keyLineSplitCls.get(key).OIList.add(OI);
                            }else{
                                keyLineSplitCls.put(key, new SplitGroupClass(OI,'SAAS',true));
                                cloneOrdCount++;
                            }  
                        }
                        else if(!isPolarisOrd && (OI.Product2.Product_Type__c == 'HW Support' || (OI.Product2.Product_Type__c == 'Hardware' && OI.Product2.Appliance_Model_HW__c != null))){
                            key = OI.Product2.Product_Type__c == 'HW Support' ? OI.SBQQ__RequiredBy__c : OI.id ;
                            if(OI.Product2.Product_Type__c == 'Hardware' && OI.Product2.Appliance_Model_HW__c != null && hwItmKey.containskey(key) && keyLineSplitCls.containskey(hwItmKey.get(key)) && keyLineSplitCls.get(hwItmKey.get(key))!=null ){
                                keyLineSplitCls.get(hwItmKey.get(key)).hwLineItem.add(OI); 
                            }
                            if(keyLineSplitCls.containsKey(hwItmKey.get(key))){ 
                                keyLineSplitCls.get(hwItmKey.get(key)).parentIdBundleItms.get(key).add(OI);
                            }else{
                                system.debug(LoggingLevel.DEBUG,'Couldnt find corresponding sw line'+OI.id);
                                errorLogs.add(new Batch_Error_Log__c(Failure_Job_ID__c = jobId,Object_ID__c = ord.opportunityId,Failure_Message__c = 'Couldnt find corresponding sw line'+OI.id,Class_Name__c='SplitOrder'));
                            }
                        }
                        else if(!isPolarisOrd && OI.Product2.Product_Type__c != 'Foundation Edition' && OI.Product2.Product_Type__c !='Enterprise Edition' && OI.Product2.Product_Type__c !='Premium Edition' && OI.Product2.Product_Type__c !='Business Edition') {
                            if(keyLineSplitCls.containsKey(ord.id+'-NoSplitLines')){
                                keyLineSplitCls.get(ord.id+'-NoSplitLines').OIList.add(OI);
                            }else{
                                keyLineSplitCls.put(ord.id+'-NoSplitLines',new SplitGroupClass(OI,'Other',false));
                                cloneOrdCount++;
                            }
                        }
                        else if(isPolarisOrd && OI.Product2.Product_Level__c != 'Hardware' && OI.Product2.Product_Type__c != 'Add-On Node' && OI.Product2.Product_Type__c != 'Hardware'){
                           if(keyLineSplitCls.containsKey(ord.id+'-NoSplitLines')){
                                keyLineSplitCls.get(ord.id+'-NoSplitLines').OIList.add(OI);
                            }else{
                                keyLineSplitCls.put(ord.id+'-NoSplitLines',new SplitGroupClass(OI,'Other',true));
                                cloneOrdCount++;
                            } 
                        }
                       
                    }
                    if(cloneOrdCount > 0){
                        ordIdIndex.put(ord.id,0);
                        List<Order> clnOrderList = new List<Order>();
                        Integer startIndx = 2 ;
                        if(oppIdEDIOrderId.get(ord.opportunityId)!= null){
                            startIndx = 3;
                            cloneOrdCount+= 1 ;
                            ordToUpsert.add(new order(id= oppIdEDIOrderId.get(ord.opportunityId), Order_Index__c = 2,Total_no_of_orders__c = cloneOrdCount));
                        } 
                        ord.Order_Index__c = 1;
                        ord.Related_Orders__c = '';
                        ord.Related_Order__c = '';
                        ord.Related_Order_Count__c = null;
                        ord.HW_Order__c = '';
                        ord.Total_no_of_orders__c = cloneOrdCount ; 
                        for(integer i=startIndx ; i<= cloneOrdCount ;i++){
                            Order clnOrder = new Order();
                            clnOrder = ord.clone();
                            clnOrder.Order_Index__c= i;
                            clnOrder.Total_no_of_orders__c = cloneOrdCount ;
                            clnOrderList.add(clnOrder);      
                        }
                        clnOrderList.add(ord); 
                        orgOrdIdCloneOrds.put(ord.id,clnOrderList);
                        ordToUpsert.addall(clnOrderList);
                    }
                }
            }
            if(!ordToUpsert.isEmpty()){
                upsert ordToUpsert;
            }
            Map<Id,Order> mapofOrders = new Map<Id,Order>([select id,ordernumber from order where SBQQ__Quote__c IN :setOfQutId]);
            List<Order> lstOrderUpdate = new List<Order>();
            for(SplitGroupClass SG : keyLineSplitCls.values()){
                List<OrderItem> HwLineItems = new List<OrderItem>();
                Integer cloneOrdIndex = ordIdIndex.get(SG.orignalOrdId);
                Order clnOrd = orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex);
                List<order> bundleCloneOrd = new List<order>();
                if(SG.OIList != null && !SG.OIList.isEmpty()){
                    for(orderItem orignalOI : SG.OIList){
                        integer totalQuant = 0;
                        system.debug(logginglevel.DEBUG,'Product Code'+orignalOI.Product2.ProductCode);
                        if(SG.type == 'bundle'){
                            system.debug(logginglevel.DEBUG,'bunldeItem'+SG.parentIdBundleItms.values());
                            if(SG.parentIdBundleItms.isEmpty()){continue ;}
                            integer j = SG.parentIdBundleItms.values().size() - 1;
                            if(!SG.hwLineItem.isEmpty()){
                                HwLineItems = SG.hwLineItem; 
                            }
                            for(List<OrderItem> OItmList : SG.parentIdBundleItms.values()){
                                Integer currentQuant =  0 ;
                                    Integer splitCount = (Integer) ((HwLineItems[0].quantity + totalQuant) / splitByQuant).round(System.RoundingMode.CEILING) ;
                                    for( integer i =0 ;i < splitCount;i++){
                                        if(HwLineItems[0].quantity + totalQuant <= splitByQuant){ 
                                            currentQuant = (Integer) HwLineItems[0].quantity ;
                                            totalQuant += (Integer) HwLineItems[0].quantity;
                                        }else{
                                            currentQuant = Math.abs(splitByQuant - totalQuant) ;
                                            totalQuant += currentQuant;
                                        }
                                        for(OrderItem OI : OItmList){
                                            if(SG.isPolaris && (OI.Product2.Product_Level__c == 'Hybrid Software' || (OI.Product2.Product_Level__c == 'OnPrem' && (OI.Product2.Product_Type__c == 'Foundation Edition' || OI.Product2.Product_Type__c == 'Enterprise Edition' || OI.Product2.Product_Type__c == 'Business Edition') && OI?.Product2?.Product_Subtype__c == null) ||  OI.Product2.Product_Level__c == 'LOD Software') && OI.Product2.Product_Subtype__c != 'RCDM'){
                                                Order tempOrd = new order(Id = orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex + 1).id);
                                                tempOrd.Related_Orders__c = mapofOrders.get(orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex + 1).Id).OrderNumber +','+mapofOrders.get(orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex).id).OrderNumber;
                                                tempOrd.Related_Order__c = mapofOrders.get(orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex + 1).id).OrderNumber;
                                                tempOrd.HW_Order__c = mapofOrders.get(orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex).id).OrderNumber;
                                                tempOrd.Related_Order_Count__c = tempOrd.Related_Orders__c.countMatches(',') + 1;
                                                lstOrderUpdate.add(tempOrd);

                                                OrderItem cloneOI = OI.clone();
                                                cloneOI.orderId = orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex + 1).id;
                                                cloneOI.quantity = cloneOI.SBQQ__OrderedQuantity__c = currentQuant * HwLineItems[0].Product2.Usable_Capacity__c ;
                                                cloneOI.SBQQ__RequiredBy__c = null;
                                                
                                                OrderItem orgRcdm = mapOfLiscenseToRcdm?.get(OI.Id);
                                                OrderItem rcdmOI = orgRcdm?.clone();
                                                if(rcdmOI != null){
                                                    rcdmOI.Quantity = rcdmOI.SBQQ__OrderedQuantity__c = currentQuant * HwLineItems[0].Product2.Usable_Capacity__c ;
                                                    rcdmOI.orderId = orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex + 1).id;
                                                    rcdmOI.SBQQ__RequiredBy__c = null;
                                                    ordItmInsert.add(rcdmOI);
                                                }
                                                ordItmInsert.add(cloneOI);
                                                delOrderItms.put(OI.id,OI);
                                                cloneOrdIndex++;
                                                ordIdIndex.put(SG.orignalOrdId,ordIdIndex.get(SG.orignalOrdId)+ 1);
                                                
                                            }else{
                                                If(SG.isPolaris && OI.Product2.Product_Level__c == 'Hardware' && (OI.Product2.Product_Type__c == 'Add-On Node' ||  OI.Product2.Product_Type__c == 'Hardware')){
                                                    Order tempOrd = new order(Id = clnOrd.id);
                                                    tempOrd.Related_Orders__c = mapofOrders.get(clnOrd.id).OrderNumber +','+mapofOrders.get(orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex + 1).id).OrderNumber;
                                                    tempOrd.Related_Order__c = mapofOrders.get(orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex + 1).id).OrderNumber;
                                                    tempOrd.HW_Order__c = mapofOrders.get(clnOrd.id).OrderNumber;
                                                    tempOrd.Related_Order_Count__c = tempOrd.Related_Orders__c.countMatches(',') + 1;
                                                    lstOrderUpdate.add(tempOrd);
                                                }
                                                OrderItem cloneOI = OI.clone();
                                                cloneOI.orderId = clnOrd.id;
                                                cloneOI.quantity = cloneOI.SBQQ__OrderedQuantity__c = currentQuant ;
                                                cloneOI.SBQQ__RequiredBy__c = null;
                                                ordItmInsert.add(cloneOI);
                                                delOrderItms.put(OI.id,OI);
                                            }
                                        }
                                        if(totalQuant == splitByQuant && (HwLineItems[0].quantity - currentQuant > 0 || j > 0)){
                                            clnOrd = orgOrdIdCloneOrds.get(SG.orignalOrdId).get(cloneOrdIndex + 1);
                                            ordIdIndex.put(SG.orignalOrdId,ordIdIndex.get(SG.orignalOrdId)+1);
                                            if(HwLineItems[0].quantity - currentQuant > 0){HwLineItems[0].quantity -= currentQuant;}
                                            if(SG.isPolaris){
                                                cloneOrdIndex++;
                                            } 
                                            totalQuant = 0;
                                        } 
                                    }
                                    j--;
                            }

                        }else{
                            OrderItem cloneOI = orignalOI.clone();
                            cloneOI.orderId = clnOrd.id;
                            cloneOI.SBQQ__RequiredBy__c = null;
                            ordItmInsert.add(cloneOI);
                            delOrderItms.put(orignalOI.id,orignalOI);
                        }
                    }
                    ordIdIndex.put(SG.orignalOrdId,ordIdIndex.get(SG.orignalOrdId)+1);
                }
            }
            If(!lstOrderUpdate.isEmpty()){
                update lstOrderUpdate;
            }
            system.debug(logginglevel.DEBUG,'delOrderItms'+delOrderItms);
            if(!delOrderItms.isEmpty()){
                delete delOrderItms.values() ;
            }
            system.debug(logginglevel.DEBUG,'ordItmInsert'+ordItmInsert);
            if(!ordItmInsert.isEmpty()){
                insert ordItmInsert;
            }
            

        }catch(Exception e){
            List<Batch_Error_Log__c> belList = new List<Batch_Error_Log__c>();
            for(Order ord : netappOrd){
                Batch_Error_Log__c bel = new Batch_Error_Log__c();
                bel.Failure_Job_ID__c = jobId;
                bel.Object_ID__c = ord.id;
                bel.Failure_Message__c = e.getMessage();
                bel.Class_Name__c = 'SplitOrder';
                errorLogs.add(bel);
            }
        }
        if(!errorLogs.isEmpty()){
            insert errorLogs;
        }
        
    }

    /******************************************************
     * Description : This method is to split the Non-EDI FedRamp or Replacement Order
     * ****************************************************** */
  /**
   * @date 05-03-2025
   * @description To split Non-EDI FedRamp Order
   * @param mapFedRampTolstOLI
   * @param quoteOrderMap
   * */ 

     public void splitNonEDIOrder(Map<String, List<OrderItem>>orderItemsByType, Map<Id, Order> quoteOrderMap){

        List<OrderItem> lstInitialUpdateOLI = new List<OrderItem>();
        Map<String,Order> allOrdersByOIType  = new Map<String,Order>();
        Map<String, Set<String>> lineTypesByOrderType = new Map<String, Set<String>>();
        Integer orderedIndex = 0;

        for (String oiTypeKey : orderItemsByType.keySet()) {
            for (OrderItem oi : orderItemsByType.get(oiTypeKey)) {
                String program = oi?.Program__c;
                if (program != null && (Constants.REPLACEMENT_PROGRAMS.contains(program) || program == Constants.PROGRAM_REFRESH) && oi.Previous_Transaction_Reference__c != null) {
                    if (!lineTypesByOrderType.containsKey(oiTypeKey)) {
                        lineTypesByOrderType.put(oiTypeKey, new Set<String>());
                    }
                    lineTypesByOrderType.get(oiTypeKey).add(program);
                }
            }
        }

        Boolean isInitialOrderProcessed = false;

        for(String oiTypeKey : orderItemsByType.keySet()){
            Boolean isFedrampOI = oiTypeKey.equalsIgnoreCase('FedRamp');
            Boolean isReplacementOI = oiTypeKey.equalsIgnoreCase('Replacement');
            orderedIndex++;
        
            String strQuote = orderItemsByType.get(oiTypeKey)[0].SBQQ__QuoteLine__r.SBQQ__Quote__c;
            if(isFedrampOI || isReplacementOI){
                Order initialOrder = quoteOrderMap.get(strQuote);
  				if(initialOrder == null){
                    continue;
                }
                
                // Create a new Order instance if both FedRamp and Replacement lines exist
                if (isInitialOrderProcessed) {
                    initialOrder = initialOrder.clone();
                }
                initialOrder.Order_Split_Type__c = 'Split Completed';
                initialOrder.Order_Index__c = orderedIndex;
                initialOrder.Total_no_of_orders__c = orderItemsByType.size();
                initialOrder.HW_Order__c = '';
                initialOrder.Related_Order__c = '';
                initialOrder.Related_Orders__c = '';
                initialOrder.Line_Types__c = lineTypesByOrderType.containsKey(oiTypeKey) 
                ? String.join(new List<String>(lineTypesByOrderType.get(oiTypeKey)), ';') 
                : null;
                allOrdersByOIType .put(oiTypeKey, initialOrder);
                OrderInsertHelper.PONonEDIOrdersAmtMap.put(initialOrder.Stage_PO__c,initialOrder.TotalAmount);
                if (!isInitialOrderProcessed) {
                    isInitialOrderProcessed = true;
                }
            }else {
               Order cloneOrder = quoteOrderMap.get(strQuote) != null?quoteOrderMap.get(strQuote).clone():null;
                if(cloneOrder != null){
                    CloneOrder.Total_no_of_orders__c = orderItemsByType.size();
                    CloneOrder.Order_Split_Type__c = 'Split Completed';
                    CloneOrder.Order_Index__c = orderedIndex;
                    CloneOrder.HW_Order__c = '';
                    CloneOrder.Related_Order__c = '';
                    CloneOrder.Related_Orders__c = '';
		            CloneOrder.RSC_G_Enabled__c = false;
                    CloneOrder.Memo__c = null;
                    CloneOrder.Program__c = null;
                    CloneOrder.Line_Types__c = lineTypesByOrderType.containsKey(oiTypeKey) 
                    ? String.join(new List<String>(lineTypesByOrderType.get(oiTypeKey)), ';') 
                    : null;
                    CloneOrder.Associated_Order_Numbers__c = null;
                    allOrdersByOIType.put(oiTypeKey, cloneOrder);
                }

            }

        }

        isNonEDISplit = true; //Prevents re-calculation of Line_Types__c in the Order Trigger in this particular transation

        if(!allOrdersByOIType.isEmpty()){
        	upsert allOrdersByOIType.values();
        }

        List<OrderItem> lstUpdateOLI = new List<OrderItem>();
        list<OrderItem> deleteOLI = new List<OrderItem>();

        for(string oiTypeKeyp : orderItemsByType.keySet()){
            system.debug('::oiTypeKeyp::'+oiTypeKeyp);
            for(OrderItem oi : orderItemsByType.get(oiTypeKeyp)){
                if(allOrdersByOIType .containskey(oiTypeKeyp) && allOrdersByOIType .get(oiTypeKeyp).Id != oi.OrderId){
                    deleteOLI.add(oi);
                    oi = oi != null ? oi.clone() : null;
                    if(oi != null){
                        oi.OrderId = allOrdersByOIType .get(oiTypeKeyp).Id;
                        oi.SBQQ__RequiredBy__c = null;
                        lstUpdateOLI.add(oi);
                    }
                }

            }

        }

        if(!deleteOLI.isEmpty()){
            delete deleteOLI;
        }
        if(!lstUpdateOLI.isEmpty() && !Test.isRunningTest()){
            insert lstUpdateOLI;
        }

       if(quoteOrderMap.keySet().size() > 0){
            linkOrdersForNonEdiSplit(quoteOrderMap);
        }
        isNonEDISplit = false;
    }
  /**
    * This method links and updates orders related to non-EDI splits.
    * This method ensures that each order in a quote split is linked properly with consistent metadata
    * for downstream processing or reporting.
    *
    * @param quoteOrderMap A map of Quote IDs to their corresponding Order records.
    * Date : 14/05/2025
    * Author : Naveen Selvaraj
    */
    public static void linkOrdersForNonEdiSplit(Map<Id, Order> quoteOrderMap){
        List<Order> ordersRelatedToQuote = [SELECT Id, Line_Types__c, Order_Sub_Type__c , HW_Order__c,Related_Order__c,OrderNumber, SBQQ__Quote__c, Order_Index__c, Total_no_of_orders__c,
                                            (SELECT Id,Product2Id, Product2.Product_Level__c,Product2.Product_Type__c, Product2.product_subtype__c
                                             FROM OrderItems) 
                                            FROM Order where SBQQ__Quote__c IN :quoteOrderMap.KeySet()];
        Map<String, List<Order>> ordersByQuoteId = new Map<String, List<Order>>();
        Boolean isQuotehasRefreshReplaceOrd = false;
        for(Order ord : ordersRelatedToQuote){
            if(UtilityClass.isReplacementOrder(ord) || (ord.Line_Types__c != null && ord.Line_Types__c.contains(Constants.PROGRAM_REFRESH))){
                isQuotehasRefreshReplaceOrd = true;
            }
            if(!ordersByQuoteId.containskey(ord.SBQQ__Quote__c+'-'+ord.Order_Sub_Type__c)){
                ordersByQuoteId.put(ord.SBQQ__Quote__c+'-'+ord.Order_Sub_Type__c, new List<Order>());
            }
            ordersByQuoteId.get(ord.SBQQ__Quote__c+'-'+ord.Order_Sub_Type__c).add(ord);
        }
        List<Order> ordersToupdate = new List<Order>();
        for(String quoteId :  ordersByQuoteId.KeySet()){
            for(Order ord : ordersByQuoteId.get(quoteId)){
                ord.HW_Order__c = null;
                for(OrderItem oi : ord.orderItems){
                    String typeofsku = UtilityClass.getTypeofSKU(oi); 
                    if(typeofsku == Constants.SKU_TYPE_HARDWARE){
                        ord.HW_Order__c = ord.Ordernumber;
                        break;
                    } 
                }
                ord.Related_Order__c = Ord.Related_Orders__c = ord.Ordernumber;
                if(isQuotehasRefreshReplaceOrd){
                    ord.Order_Index__c = ord.Related_Order_Count__c = 1;
                }
                ord.Total_no_of_orders__c = ordersByQuoteId.get(quoteId).size();
                ordersToupdate.add(ord);
            }
        }
        if(!ordersToupdate.isEmpty()){
            TriggerControl.stopOrderTrigger = true;
            update ordersToupdate;
            TriggerControl.stopOrderTrigger = false;
        }
    }
  /**
   * @date 05-03-2025
   * @description Dynamic Query To be used in Query locator Method.
   * @param objectName
   * @param whereClause
   * @return String
   * */ 
     public static string getCreatableFieldsSOQL(String objectName, String whereClause){
         
        String selects = '';
         
       // if (whereClause == null || whereClause == ''){ return null; }
         
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
        set<string> selectFieldsSet = new set<string>();
         
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                //if (fd.isCreateable()){ // field is creatable

            if (fd.getType() == Schema.DisplayType.Boolean ||
                fd.getType() == Schema.DisplayType.Combobox ||
                fd.getType() == Schema.DisplayType.Currency ||
                fd.getType() == Schema.DisplayType.Date ||
                fd.getType() == Schema.DisplayType.Double ||
                fd.getType() == Schema.DisplayType.Email ||
                fd.getType() == Schema.DisplayType.Integer ||
                fd.getType() == Schema.DisplayType.MultiPicklist ||
                fd.getType() == Schema.DisplayType.Percent ||
                fd.getType() == Schema.DisplayType.Phone ||
                fd.getType() == Schema.DisplayType.Picklist ||
                fd.getType() == Schema.DisplayType.String ||
                fd.getType() == Schema.DisplayType.TextArea ||
                fd.getType() == Schema.DisplayType.Time ||
                fd.getType() == Schema.DisplayType.URL  ||
               	fd.getType() == Schema.DisplayType.DateTime ||
                fd.getType() == Schema.DisplayType.REFERENCE 
               ) 
            {
                //don't add standard fields that are not necessary
                if (fd.getName() != 'CreatedDate' &&
                    fd.getName() != 'LastModifiedDate' &&
                    fd.getName() != 'SystemModstamp' &&
                    fd.getName() != 'ActivatedDate' &&
                    fd.getName() != 'ActivatedById' &&
                    fd.getName() != 'StatusCode' &&
                    fd.getName() != 'OrderNumber' &&
                    fd.getName() != 'TotalAmount' &&
                    fd.getName() != 'IsDeleted' &&
                    fd.getName() != 'LastViewedDate' &&
                    fd.getName() != 'LastReferencedDate' &&
                    fd.getName() != 'AvailableQuantity' &&
                    fd.getName() != 'TotalPrice' &&
                    fd.getName() != 'OrderItemNumber' &&
                    //do not add formula fields
                    !fd.isCalculated()
                    )
                {
                    selectFieldsSet.add(fd.getName());
                }
            }
            }
        }
         
        if (!selectFieldsSet.isEmpty()){
           //selectFieldsSet.remove('ShippingCountryCode');
           //selectFieldsSet.remove('ShippingStatecode');
           selectFields.addAll(selectFieldsSet);
           selects=String.join(selectFields,',');
           
             
        }
        if(whereClause !='') 
            return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
        else {
            return 'SELECT ' + selects + ' FROM ' + objectName;
        }
         
    }



     /******************************************************
   * Description : Logic  to Clone the Upgraded Skus
   * based on the RSV Segments' quoteline start and end Date For Amendment Order for Ticket CSU-473
   * Arguements :  Map<Id, OrderItem> and Order	   
   * Return : void 	   
   * Author : Prashant
   * CreatedDate : 29-Sep-2023
   * ******************************************************/
  /**
   * @date 05-03-2025
   * @description Logic  to Clone the Upgraded Skus
   * based on the RSV Segments' quoteline start and end Date For Amendment Order for Ticket CSU-473
   * @param upgradeSkusOrderLineSUForCloning
   * @param gcOfferAmendmentOrder
   * */ 
  public void cloneUpgradeSkusForAmendmentSU(Map<Id, OrderItem> upgradeSkusOrderLineSUForCloning, Order gcOfferAmendmentOrder) {
    Map<Id, OrderItem> upgradeOrderLinesBasedOnDate = new Map<Id, OrderItem>();
   // CSU-473 : Querying All the RSV segments and then compare its start and end date and clone the orderitems based on that 	
    for (SBQQ__QuoteLine__c quoteLine : [
      SELECT id, SBQQ__SegmentIndex__c, SBQQ__SegmentKey__c, SBQQ__SegmentLabel__c, SBQQ__Quote__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c
      FROM SBQQ__QuoteLine__c
      WHERE Product_Subtype__c = 'Scale MSP' AND License_Category__c = 'SaaS' AND Product_Type__c != 'Edition Upgrade' AND (NOT SBQQ__Product__r.Edition__c LIKE  '%Edition Upgrade') AND SBQQ__Quote__c IN :upgradeSkusOrderLineSUForCloning.keyset()  
    ]) {
      if (
        upgradeSkusOrderLineSUForCloning.containskey(quoteLine.SBQQ__Quote__c) &&
        upgradeSkusOrderLineSUForCloning.get(quoteLine.SBQQ__Quote__c).SBQQ__QuoteLine__r.SBQQ__StartDate__c <= quoteLine.SBQQ__StartDate__c &&
        upgradeSkusOrderLineSUForCloning.get(quoteLine.SBQQ__Quote__c).SBQQ__QuoteLine__r.SBQQ__EndDate__c >= quoteLine.SBQQ__EndDate__c
      ) {
        OrderItem OI = upgradeSkusOrderLineSUForCloning.get(quoteLine.SBQQ__Quote__c).clone();
        Boolean isGCOfferAmendmentWithAdditionalMonth =
          OI?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.SBQQ__Type__c == 'Amendment' &&
          OI?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.Amended_Renewed_Service_Contract__r?.Quote_additional_month__c == true &&
          OI?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.Amended_Renewed_Service_Contract__r?.Quote_additional_month__c != null &&
          OI.Order?.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER;
        OI.serviceDate = OI.Support_Start_Date__c = quoteLine.SBQQ__StartDate__c;
        if (isGCOfferAmendmentWithAdditionalMonth && (quoteLine.SBQQ__SegmentIndex__c == (OI.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c - 1) || Constants.SCALE_UTILITY_PRODUCT_SUBTYPES_ONDEMAND.contains(OI?.Product2?.Product_Subtype__c))) {
          Oi.endDate = OI.Support_End_Date__c = quoteLine.SBQQ__EndDate__c.addMonths(1);
        } else {
          Oi.endDate = OI.Support_End_Date__c = quoteLine.SBQQ__EndDate__c;
        }
        OI.SBQQ__OrderedQuantity__c = OI.Quantity = quoteLine.SBQQ__Quantity__c;
        system.debug(LoggingLevel.DEBUG,'product ' + OI.Product2.Name + 'Quoted Quantity ' + OI.SBQQ__QuotedQuantity__c + 'quoteline qty ' + quoteLine.SBQQ__Quantity__c);
        OI.SBQQ__SubscriptionTerm__c = quoteLine.SBQQ__SubscriptionTerm__c;
        OI.SBQQ__SegmentIndex__c = quoteLine.SBQQ__SegmentIndex__c;
        OI.SBQQ__SegmentKey__c = quoteLine.SBQQ__SegmentKey__c;
        OI.Segment_Label__c = quoteLine.SBQQ__SegmentLabel__c;
        OI.UnitPrice = ((upgradeSkusOrderLineSUForCloning.get(quoteLine.SBQQ__Quote__c)?.SBQQ__QuoteLine__r?.SBQQ__NetPrice__c) / (upgradeSkusOrderLineSUForCloning.get(quoteLine.SBQQ__Quote__c)?.SBQQ__QuoteLine__r?.SBQQ__SubscriptionTerm__c));
        upgradeOrderLinesBasedOnDate.put(quoteLine.Id, OI);
      }
    }

    if (!upgradeSkusOrderLineSUForCloning.isEmpty())
      delete upgradeSkusOrderLineSUForCloning.values();
    // CSU-473 Clone  All the Orderlines and Setting order Split Type as well.	
    if (!upgradeOrderLinesBasedOnDate.isEmpty()) {
      SBQQ.TriggerControl.disable();
      insert upgradeOrderLinesBasedOnDate.values();
      SBQQ.TriggerControl.enable();
    }
    gcOfferAmendmentOrder.Order_Split_Type__c = 'Split Completed';
    update gcOfferAmendmentOrder;
  }	

  /*******************************************************************
   * Wrapper class to store replacement and phantom orders per quote
   *******************************************************************/
   private class Replacement{
     String PhtmOrdNum = '';
     List<string> replmntOrds = new list<string>();
   }
    /****************************************************************
     * 
     */
    /*****************************************************************************
* @description       : SplitGroupClass 
* Modifications Log
* Ver   Date          Author        Modification
* 1.0   01-20-2021   Prashant        Initial Version
******************************************************************************/
    private class SplitGroupClass{
        Decimal totalQuantity;
        List<OrderItem> OIList;
        Map<id,List<OrderItem>> parentIdBundleItms;
        List<OrderItem> hwLineItem;
        string type;
        Boolean isPolaris;
        Id orignalOrdId;
        private SplitGroupClass( OrderItem OI , string type, Boolean isPolaris){
            totalQuantity = OI.quantity == null ? 0 : OI.quantity;
            OIList = new List<OrderItem>{OI};
            this.type = type;
            this.isPolaris = isPolaris;
            orignalOrdId = OI.orderId ;
            if(type == 'bundle'){
                hwLineItem = new List<OrderItem>();
                parentIdBundleItms = new Map<id,List<OrderItem>>{OI.SBQQ__RequiredBy__c => new List<OrderItem>{OI}};
                if((OI.Product2.Product_Type__c == 'Hardware' && OI.Product2.Appliance_Model_HW__c != null) || (OI.Product2.Product_Level__c == 'Hardware' && (OI.Product_Type__c == 'Add-On Node' ||  OI.Product_Type__c == 'Hardware'))){
                    hwLineItem.add(OI);
                }
            }
        }
        
    }
}