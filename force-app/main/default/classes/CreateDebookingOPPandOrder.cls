/*************************************************************************
@description This class creates De-booking Opportunity and Order for CCR 
**************************************************************************/
public class CreateDebookingOPPandOrder implements Queueable{ 
    
    public static List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
    public static final string className ='CreateDebookingOPPandOrder';
    public static final string ERROR_FUNCTIONALITY = 'Bookings';
    public static string UnProcessedRecord ='';
    public static List<String> fieldsRemoved = new List<String>();
    public static string ErrorMessage ='';
    public static Set<Id> SuccessOppInsertIdSet=new Set<Id>();
    public static Set<Id> SuccessOppUpdateIdSet=new Set<Id>();
    public static Set<Id> SuccessOrderInsertIdSet=new Set<Id>();
    public static Set<Id> SuccessOrderLineInsertIdSet=new Set<Id>();
    public static Set<Id> SuccessOrderUpdateIdSet=new Set<Id>();
    public static Set<Id> SuccessOppLineInsertIdSet=new Set<Id>();
    public List<Id> ccrIds;
    
    /**
     * @description This is the constructor method for the class
     * @param ccrIds
     */
    public CreateDebookingOPPandOrder(List<Id> ccrIds){
    	this.ccrIds = ccrIds;
    }
    /**
     * @description This is the execute method for the QueueableContext
     * @param context
     */
    public void execute(QueueableContext context){
        
        CreateNegativeOrder(ccrIds);
    }
    /**
     * @description This method creates the Opportunity and Order
     * @param ccrIds
     */
    public static void createNegativeOrder(List<Id> ccrIds){
        try{
                 // PRDOPS23-521
                FCRM.FCR_SupportAPI.DisableApplicationForContext();
                String labelForFieldsToRemove = System.Label.FieldsToRemoveForDebooking.tolowercase();
                if(labelForFieldsToRemove.contains(',')){
                fieldsRemoved =  labelForFieldsToRemove.split(',');
                }else{
                fieldsRemoved.add(labelForFieldsToRemove);
                }
            
                List<Order> deBookingOrders=new List<Order>();
                List<Opportunity> debookingOppsList=new List<Opportunity>();          
                Map<ID,ID> orderIds=new Map<ID,ID>();
                Set<ID> orderIdSet = new Set<ID>();
                Set<ID> oppIdSet = new Set<ID>();
                List<ID> orderIdList=new List<ID>();
                Map<ID,ID> oppIds=new Map<ID,ID>();
                Date currentDate = Date.Today();
                Map<Id,CCR__c> MapOfccrIdAndCCRrecord=new Map<Id,CCR__c>();            
                Set<Id> setOfpartialCCRIds = new Set<Id>();   //PRDOPS26-21           
                Map<ID,List<Booking_AdjustmentItems__c>> ccrIDbookingAdjItems=new Map<ID,List<Booking_AdjustmentItems__c>>();
                Map<ID,Decimal> mapOfCCRIdAndOriginalOrdAmount=new Map<Id,Decimal>();
            	Map<Id,Opportunity> newDebookingOpptyMap = new Map<Id,Opportunity>(); //SAL26-72
                List<CCR__c> ccrList=[SELECT Amount__c,Booking__r.Order__r.id,Booking__r.Order__r.TotalAmount,Opportunity__r.id,Effective_Date__c, CCR_Type__c,Effective_End_Date__c,(SELECT OrderLineItemId__c,CCR__r.Return_Amount_Type__c,Unit_Price__c,Quantity__c, Opportunity_Line_Item__c,Opportunity_Line_Item__r.TotalPrice, Opportunity_Line_Item__r.Subsumed_Renewal_Amount__c,Opportunity_Line_Item__r.Subsumed_Renewal_TCV__c, CCR__r.CCR_Type__c from Booking_AdjustmentItems__r) 
                       from CCR__c where id IN :ccrIds]; 
                       
                //Iterate over CCR records and collect original Order and Opportunity Ids
                if(!ccrList.isEmpty()){
                    for(CCR__c ccr : ccrList){
                        ccrIDbookingAdjItems.put(ccr.id,ccr.Booking_AdjustmentItems__r);
                        orderIds.put(ccr.id,ccr.Booking__r.Order__r.id);
                        oppIds.put(ccr.id,ccr.Opportunity__r.id);
                        MapOfccrIdAndCCRrecord.put(ccr.id,ccr);
                        mapOfCCRIdAndOriginalOrdAmount.put(ccr.id,ccr.Booking__r.Order__r.TotalAmount);
                    }
                } 
                AccountTriggersHandler.disablePatchManagerUpdate = true; 
                orderIdSet.addAll(orderIds.values());
                oppIdSet.addAll(oppIds.values());
                
                //Collect Original Opps from Opportunities Ids collected
                Map<id,Opportunity> oldIdnewOpp =new Map<id,Opportunity>(); 
                //PRDOPS25-947: Removal of Cloud_Partner_Led_Activity__c, Polaris_Portal_Contact__c ,Cloud_Type__c, Holdover_Requested__c ,Holdover_Extension__c field reference from debooking opportunity for specific fields
                List<Opportunity> originalOppsList=[SELECT id,name,Territory2Id,closedate, Focused_Partner_Calc__c, National_Partner_Calc__c, Territory2Id__c,accountid,StageName,ForecastCategoryName,Initial_Contacts_Name__c,Business_Unit__c,ownerid,
                                            Deal_Registration_Type__c,SE_Forecast_Category__c,Pricebook2Id,Partner_Lookup__c,Distributor_Lookup__c,In_Forecast_CRO__c, //SAL24-534
                                            Future_State__c,Compelling_Bus_Driver__c,Current_State__c,Cloud_Environment__c,
                                            Negative_Consequences__c/*,Help_Needed_From__c*/,Rubrik_Sales_Engineer__c,Lost_To_Won_Against__c,Positive_Business_Outcomes__c,
                                            Rubrik_CDM_Release_on_source_cluster__c,Customer_AWS_Account_Number__c,Customer_AWS_Account_Region__c,Number_of_CluodON_Products__c,
                                            amount,Referral_Program__c,DB_Type__c,Number_of_TB__c,Cloud_Type__c,Holdover_Extension_End_Date__c,Holdover_Extension_Reason__c,
                                            Installation_Assigned_To__c,Lost_Reason__c,Lost_To__c,Primary_Competitor__c,POC_Stage__c,
                                            Polaris_Region__c,Technical_Validation_Next_Step__c ,Win_Loss_Comments__c,RenewalOwner__c,Alliance_HW_Partner__c,Alliance_Source_Type_SW__c, //SAL22-327
                                            ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c,CDM_Theatre__c,
                                            Alliance_Partner_Name__c,ISR_SDR_Oppty_Credit_Total__c,Account.R2K_All__c,SecondaryOwner__c,SE_Misaligned__c,Strategic_Account__c, Security_Alliance_Contribution__c, Direct_Marketplace__c,Core_PLS_Source__c,Opp_PLS_ETM_Theatre__c,Opp_PLS_ETM_Area__c,Opp_PLS_ETM_Region__c,Opp_PLS_ETM_Territory__c,Opp_PLS_NCD_ETM_Area__c, Opp_PLS_NCD_ETM_Region__c, Opp_PLS_NCD_ETM_Territory__c, Opp_PLS_NCD_ETM_Theatre__c, Opp_PLS_SaaS_ETM_Area__c, Opp_PLS_SaaS_ETM_Region__c, Opp_PLS_SaaS_ETM_Territory__c, Opp_PLS_SaaS_ETM_Theatre__c,Co_Owner__c,SaaS_Co_Owner__c,NCD_Co_Owner__c, PLS_Gap_Deal__c,Managed_Services_Deal_type__c,
                                            Rubrik_Co_Sales_Engineer__c, UCL_Scale_Percentage__c, PLS_SE_Update__c,UK_Govt_Security_Clearance_Required__c //SAL26-173   //SAL26-282 //SAL26-153 
                                            from Opportunity WHERE  Id IN :oppIdSet];             // removing VM_Count__c from query SAL24-157 //SAL24-387 //SAL24-784 //SAL26-393
                for(Opportunity opp : originalOppsList){ 
                    Opportunity oppy = opp.clone();
                    //oppy.name=opp.name+' - '+'Debooking'+' - '+'Returns/Refunds';
                    oppy.stageName='1 Discovery';
                    oppy.Opportunity_Type__c='Debooking';
                    String opptyName = oppy.name;
                    if(opptyName.length() > 60 ){
                    oppy.Name = opptyName.substring(0, 50) + '...';
                    }
                    oppy.Has_Polaris_Product__c=False;
                    oldIdnewOpp.put(opp.id,oppy);
                    debookingOppsList.add(oppy);
                }                
                if(!debookingOppsList.isEmpty()){

					OpportunityObjectTriggerHandler.bypassClosedWonUpdateValidation = true;//SAL26-1054
                    //insert debookingOppsList;
                    system.debug(logginglevel.DEBUG,'Before-DebookingOpps'+debookingOppsList);
                    Database.SaveResult[] OppInsertSR = Database.insert(debookingOppsList, false);
                    // Iterate through each returned result
                    for(Integer i=0;i<OppInsertSR.size();i++){
                        if(!OppInsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                            for(Database.Error err : OppInsertSR[i].getErrors()){
                                ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                            }
                            UnProcessedRecord+= 'Error with inserting Debooking Opportunity::'+debookingOppsList[i].Name+',';
                        }else{
                            successOppInsertIdSet.add(OppInsertSR[i].getId());
                        }
                    }    
                }   
                                                                                 
                //Attach CCR on new debooking Opportunity
                if(!successOppInsertIdSet.isEmpty()){
                    List<Opportunity> oppWithCCR =new List<Opportunity>();
                    for(Id ccrId : oppIds.keySet()){
                        if(oldIdnewOpp.containsKey(oppIds.get(ccrId))){
                            Opportunity newOpp = oldIdnewOpp.get(oppIds.get(ccrId));
                            newOpp.CCR__c = ccrId;
                            newOpp.Opportunity_Type__c='Debooking';
                            if(MapOfccrIdAndCCRrecord.containsKey(ccrId) && mapOfCCRIdAndOriginalOrdAmount.containsKey(ccrId) ){
                                if(mapOfCCRIdAndOriginalOrdAmount.get(ccrId) == MapOfccrIdAndCCRrecord.get(ccrId).Amount__c ){
                                     newOpp.Opportunity_Sub_Type__c='Full';
                                }else{                         
                                     newOpp.Opportunity_Sub_Type__c='Partial';
                                 }
                                 newOpp.Amount = MapOfccrIdAndCCRrecord.get(ccrId).Amount__c ;
                                 newOpp.name=newOpp.name+' - '+'Debooking'+' - '+ MapOfccrIdAndCCRrecord.get(ccrId).CCR_Type__c;
                             } 
                            if(newOpp.id != NULL && successOppInsertIdSet.contains(newOpp.id)){
                                 oppWithCCR.add(newOpp);
                                 newDebookingOpptyMap.put(newOpp.Id,newOpp); //SAL26-72
                            }
                        }               
                    }    
                    if(!oppWithCCR.isEmpty()){
                        //upsert oppWithCCR;
             		FlowControll.opportunityTriggerHandler = false;
			Database.UpsertResult[] OppUpsertSR = Database.upsert(oppWithCCR, false);
                        FlowControll.opportunityTriggerHandler = true;
                        // Iterate through each returned result
                        for(Integer i=0;i<OppUpsertSR.size();i++){
                            if(!OppUpsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                                for(Database.Error err : OppUpsertSR[i].getErrors()){
                                    ErrorMessage +=err.getFields()+'::'+ err.getMessage() +',';
                                }
                                UnProcessedRecord+= 'Error with updating CCR on Opportunity::'+oppWithCCR[i].Name+',';
                            }else{
                                SuccessOppUpdateIdSet.add(OppUpsertSR[i].getId());
                            }
                        } 
                        //SAL26-72 : Line based debooking calling this method from here since at the time of debook opp creation there won't be CCR attched
                        OpportunityObjectTriggerHelper.createPartnerRelation(newDebookingOpptyMap);
                    }
             
                   //insert new debooking order
                     if(!SuccessOppUpdateIdSet.isEmpty()){
                        //Collect original orders from Order Ids set collected          
                        Map<String,Schema.SObjectField> mapFields = Order.getSObjectType().getDescribe().fields.getMap(); 
                        List<String> fieldNames = new List<String>();
                        for( String fieldName : mapFields.keySet() ) {
                           if(!fieldsRemoved.contains(fieldName)){

                            fieldNames.add( fieldName );
                             // For relationship fields
                             if( Schema.DisplayType.Reference == mapFields.get(fieldName).getDescribe().getType() )
                                 fieldNames.add( mapFields.get(fieldName).getDescribe().getRelationshipName() + '.id' );
                           }   
                        } 
                        String query = ' SELECT ' + String.escapeSingleQuotes(String.join( fieldNames, ',' )) + 
                        ' , Account.ShippingCountry,Account.ShippingCountryCode,Account.ShippingState,Account.ShippingStatecode,Account.ShippingPostalCode,Account.ShippingCity,Account.ShippingStreet ' +
                        ' FROM Order WHERE  Id IN :orderIdSet ';
             
                        List<Order> originalOrdersList = Database.query( query );
                
                        //Change some fields on cloned debooking Order
                        Map<ID,Order> oldIDnewOrder=new Map<ID,Order>();           
                            for(Order ord : originalOrdersList){
                            Order ordy = ord.clone();
                            ordy.RecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByName().get('Booking Adjustment Order').getRecordTypeId();
                            ordy.Type='Booking Adjustment'; 
                            ordy.Sync_to_NetSuite__c = FALSE;
                            ordy.Order_Accepted_Timestamp__c = null;
                            ordy.BookingStatus__c= ' ';  
                            ordy.Order_Status__c='Order Accepted';  
                            ordy.status='Draft';
                            ordy.Auto_Manual_Split__c = null;
                            ordy.Reason_For_Split__c = null;
                            //ordy.Order_Status__c='Pending'; 
                            ordy.SBQQ__Contracted__c = false;       
                            oldIDnewOrder.put(ord.id,ordy);                   
                            ordy.SBQQ__Quote__c =null;
                            ordy.Quote=null;    
                            ordy.ShippingCountry=ordy.Account.ShippingCountry;
                            ordy.ShippingCountryCode=ordy.Account.ShippingCountryCode;
                            ordy.ShippingState=ordy.Account.ShippingState;
                            ordy.ShippingStatecode=ordy.Account.ShippingStatecode;
                            ordy.ShippingPostalCode=ordy.Account.ShippingPostalCode;
                            ordy.ShippingCity=ordy.Account.ShippingCity;
                            ordy.ShippingStreet=ordy.Account.ShippingStreet;            
                            ordy.OpportunityId=oldIdnewOpp.get(ord.OpportunityId).id;
                            deBookingOrders.add(ordy);
                        }
                        if(!deBookingOrders.isEmpty()){
                            //insert deBookingOrders;
                            Database.SaveResult[] OrderInsertSR = Database.insert(deBookingOrders, false);               
                            // Iterate through each returned result
                            for(Integer i=0;i<OrderInsertSR.size();i++){
                                if(!OrderInsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                                    for(Database.Error err : OrderInsertSR[i].getErrors()){
                                        ErrorMessage +=err.getFields()+'::'+ err.getMessage() +',';
                                    }
                                    UnProcessedRecord+= 'Error with cloning Order:: '+deBookingOrders[i].Order_Number__c+',';
                                }else{
                                    SuccessOrderInsertIdSet.add(OrderInsertSR[i].getId());
                                }
                            } 
                        }
               
                        //insert order line items  
                        if(!SuccessOrderInsertIdSet.isEmpty()){          
                            Map<ID,Set<ID>> ccridLinesid=new Map<ID,Set<ID>>();
                            Map<ID,Decimal> orderItemIdsqnty=new Map<ID,Decimal>();
                            Map<Id, Booking_AdjustmentItems__c> mapOrderLineIdBkgAdjItem = new Map<Id, Booking_AdjustmentItems__c>();
                            for(ID ccrId2:ccrIDbookingAdjItems.keySet()){
                                Set<ID> orderItemIds=new Set<ID>();
                                //Collect all adjusted order Item Ids and their quantity
                                for(Booking_AdjustmentItems__c bkgAdjItem : ccrIDbookingAdjItems.get(ccrId2)){
                                    orderItemIdsqnty.put(bkgAdjItem.OrderLineItemId__c,bkgAdjItem.Quantity__c);   
                                    orderItemIds.add(bkgAdjItem.OrderLineItemId__c);       
                                    mapOrderLineIdBkgAdjItem.put(bkgAdjItem.OrderLineItemId__c, bkgAdjItem);
                                    //Start PRDOPS26-21
                                    if(bkgAdjItem.CCR__r.Return_Amount_Type__c == 'Partial'){
                                        setOfpartialCCRIds.add(bkgAdjItem.Id);
                                    }
                                    //End PRDOPS26-21
                                }
                                ccridLinesid.put(ccrId2,orderItemIds);
                                 }
            
                            //Collect order Item Ids to a set
                            Set<ID> linesid =New Set<ID>();
                            for(Set<ID> orderLineIdsSet : ccridLinesid.values()){
                                for(ID orderLineId : orderLineIdsSet){
                                    linesid.add(orderLineId);
                                }
                            }
                
                            //Collect all Order Items form Lines Item IDs collected           
                            Map<String,Schema.SObjectField> mapFields1 = OrderItem.getSObjectType().getDescribe().fields.getMap(); 
                            List<String> fieldNames1 = new List<String>();
                            for( String fieldName1 : mapFields1.keySet() ) {
                                if(!fieldsRemoved.contains(fieldName1)){

                                fieldNames1.add( fieldName1 );
                                // For relationship fields
                                if( Schema.DisplayType.Reference == mapFields1.get(fieldName1).getDescribe().getType() )
                                    fieldNames1.add( mapFields1.get(fieldName1).getDescribe().getRelationshipName() + '.id' ); 
                                }    
                            } 
                            String query1 = ' SELECT ' + String.escapeSingleQuotes(String.join( fieldNames1, ',' )) + ' FROM OrderItem  WHERE  Id IN :linesid ';
                            List<OrderItem> orderLinesList = Database.query( query1 );
                
                            
 
                            if(!orderIds.isEmpty()){     
                                //Attach new Debooking Opportunity on new Debooking Order
                                List<Order> newadjustedOrds = new List<Order>();
                                Map<Order,Opportunity> newOppNewOrder =  New Map<Order,Opportunity>();
                                for(ID ccrId1:orderIds.keySet()){
                                    if(oppIds.containsKey(ccrId1)){
                                        Order ordd=oldIdnewOrder.get(OrderIds.get(ccrId1));
                                        ordd.OpportunityId=oldIdnewOpp.get(OppIds.get(ccrId1)).id;
                                        newadjustedOrds.add(ordd);                       
                                        newOppNewOrder.put(oldIdnewOrder.get(OrderIds.get(ccrId1)),oldIdnewOpp.get(OppIds.get(ccrId1)));   
                                     }
                                }               
                                //if(!newadjustedOrds.isEmpty()){
                                    //upsert newadjustedOrds;
                                   // Database.UpsertResult[] OrderUpdateSR = Database.Upsert(newadjustedOrds, false);
                                    // Iterate through each returned result
                                    /*for(Integer i=0;i<OrderUpdateSR.size();i++){
                                        if(!OrderUpdateSR[i].isSuccess()){//only look at failures, or NOT Successes
                                            for(Database.Error err : OrderUpdateSR[i].getErrors()){
                                                ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                            }
                                            UnProcessedRecord+= 'Error with linking Opportunity to Order ::'+newadjustedOrds[i].OrderNumber+',';
                                        }else{
                                            SuccessOrderUpdateIdSet.add(OrderUpdateSR[i].getId());
                                        }
                                    } */
                                //}
                              Map<Id, OpportunityLineItem> mapOrderItemIdToOppLineItem = new Map<Id, OpportunityLineItem>();
                                if(!newOppNewOrder.isEmpty()){
                                    //insert opplines
                                    List<OpportunityLineItem> oppLines=new List<OpportunityLineItem>();
                                    for(OrderItem orderLine: orderLinesList){
                                        if(orderItemIdsqnty.containsKey(orderLine.id)){
                                            OpportunityLineItem oppLine = new OpportunityLineItem();   
                                            //Create Opp Lines from Order Lines and attach under debooking Opportunity 
                                            oppLine.OpportunityId = (newOppNewOrder.get(oldIDnewOrder.get(orderLine.Order.id))).id;
                                            oppLine.PriceBookEntryId = orderLine.PriceBookEntryId;
                                            oppLine.UnitPrice = orderLine.UnitPrice * -1; 
                                            oppLine.Description = orderLine.Description;
                                            oppLine.Line_Type_Text__c = orderLine.Line_Type__c;
                                            oppLine.Quantity = orderItemIdsqnty.get(orderLine.id);
                                            if(orderLine.Opportunity_Product__c != null){
                                                oppLine.Original_OpplineitemId__c = Id.valueOf(orderLine.Opportunity_Product__c); //SAL25-145
                                            }
                                            if(mapOrderLineIdBkgAdjItem.containsKey(orderLine.id)){
                                                if(mapOrderLineIdBkgAdjItem.get(orderLine.id).CCR__r.CCR_Type__c != Constants.UNPAID_REPLACEMENT_DEBOOK
                                                    && mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r?.Subsumed_Renewal_Amount__c != null){
                                                    Decimal renwalAmt = mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r?.Subsumed_Renewal_Amount__c * -1;
                                                    oppLine.Subsumed_Renewal_Amount__c = renwalAmt > 0 ? 0.00 : renwalAmt;
                                                }
                                                if(mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r?.Subsumed_Renewal_TCV__c != null){

                                                    Decimal renewalTCV= mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r?.Subsumed_Renewal_TCV__c * -1;
                                                    oppLine.Subsumed_Renewal_TCV__c = renewalTCV > 0 ? 0.00 : renewalTCV;
                                                }
                                                //Start PRDOPS26-21
                                                if(setOfpartialCCRIds.contains(mapOrderLineIdBkgAdjItem.get(orderLine.id).Id)){
                                                    oppLine.UnitPrice = ((mapOrderLineIdBkgAdjItem.get(orderLine.id).Unit_Price__c)*-1).setScale(2);
                                                    Decimal totalPrice=mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r!=null ? mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r.TotalPrice : null;
                                                    oppLine.Subsumed_Renewal_Amount__c=totalPrice!=null && oppLine.Subsumed_Renewal_Amount__c!=null ? oppLine.Subsumed_Renewal_Amount__c*(((oppLine.UnitPrice*-1)*oppLine.Quantity)/totalPrice) : 0; //Added for SAL26-588
                                                    oppLine.Subsumed_Renewal_TCV__c=totalPrice!=null && oppLine.Subsumed_Renewal_TCV__c!=null ?oppLine.Subsumed_Renewal_TCV__c*(((oppLine.UnitPrice*-1)*oppLine.Quantity)/totalPrice) : 0; //Added for SAL26-588
                                                }
                                                //End PRDOPS26-21
                                            }
                                            oppLine.Debooking_Subscription_Term__c = orderLine.SBQQ__SubscriptionTerm__c; //SAL24-164
                                            if(!mapOrderItemIdToOppLineItem.containsKey(orderLine.Id)){
                                                mapOrderItemIdToOppLineItem.put(orderLine.Id, oppLine);
                                            }
                                            oppLines.add(oppLine);
                                        }
                                     }
                
                                    if(!oppLines.isEmpty()){
                                        //insert oppLines;     
                                        Database.UpsertResult[] OppLineInsertSR = Database.Upsert(oppLines, false);
                                        // Iterate through each returned result
                                        for(Integer i=0;i<OppLineInsertSR.size();i++){
                                             if(!OppLineInsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                                                  for(Database.Error err : OppLineInsertSR[i].getErrors()){
                                                       ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                                  }
                                                   UnProcessedRecord+= 'Error with inserting Lines of Opportunity::'+oppLines[i].OpportunityId+',';
                                             }else{
                                                 SuccessOppLineInsertIdSet.add(OppLineInsertSR[i].getId());
                                             }
                                        } 
                                    }               
                                     //insert adjusted order items under new debooking Order
                            List<OrderItem> adjustedItems = new List<OrderItem>();
                            for(OrderItem orderLine: orderLinesList){
                               OrderItem oitem= orderLine.clone(false,true);
                                system.debug(logginglevel.DEBUG,'orderLine::'+orderLine.Line_Type__c);
                               if(orderItemIdsqnty.containsKey(orderLine.id)){
                                   //Change quantity on the cloned order Items and attach them under debooking Order created
                                   oitem.Quantity=orderItemIdsqnty.get(orderLine.id);
                                   oitem.Orderid=oldIDnewOrder.get(orderLine.Order.id).id ;
                                   oitem.UnitPrice=oitem.UnitPrice*-1;
                                   oitem.SBQQ__QuoteLine__c = null;
                                   oitem.SBQQ__Contracted__c= false; 
                               }
                                system.debug(logginglevel.DEBUG,'::mapOrderItemIdToOppLineItem::'+mapOrderItemIdToOppLineItem);
                                if(mapOrderItemIdToOppLineItem.containsKey(orderLine.id)){
                                    oitem.Opportunity_Product__c = mapOrderItemIdToOppLineItem.get(orderLine.id).Id;
                                    oitem.UnitPrice = mapOrderItemIdToOppLineItem.get(orderLine.id).UnitPrice;  //PRDOPS26-21
                                                   }
                               adjustedItems.add(oitem);           
                                            }
                            if(!adjustedItems.isEmpty()){
                                //insert adjustedItems;
                                Database.SaveResult[] SR3 = Database.insert(adjustedItems, false);
                                // Iterate through each returned result
                                for(Integer i=0;i<SR3.size();i++){
                                    if(!SR3[i].isSuccess()){//only look at failures, or NOT Successes
                                        for(Database.Error err : SR3[i].getErrors()){
                                            ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                        }
                                        UnProcessedRecord+= 'Error with inserting Lines of Order::'+adjustedItems[i].Orderid+',';
                                    }else{
                                        SuccessOrderLineInsertIdSet.add(SR3[i].getId());
                                    }    
                                }  
                            }
                                    if(!SuccessOppLineInsertIdSet.isEmpty()){
                                        //Update debooking Opps stage to Closed Won
                                        for(Opportunity op : debookingOppsList){   
                                                    op.StageName='7 Closed Won';
                                                    op.ForecastCategoryName='Closed';
                                                    if(MapOfccrIdAndCCRrecord.containskey(op.CCR__c))
                                                    op.closedate = MapOfccrIdAndCCRrecord.get(op.CCR__c).Effective_End_Date__c;
                                        }
                                        if(!debookingOppsList.isEmpty()){
                                            //upsert debookingOppsList;
                                            Database.UpsertResult[] OppUpsertSR = Database.Upsert(debookingOppsList, false);
                                            // Iterate through each returned result
                                            for(Integer i=0;i<OppUpsertSR.size();i++){
                                                if(!OppUpsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                                                    for(Database.Error err : OppUpsertSR[i].getErrors()){
                                                                ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                                    }
                                                    UnProcessedRecord+= 'Error with updating Opportunity to ClosedWon Stage for::'+debookingOppsList[i].Name+',';
                                                }
                                            }    
                                        } 
                                    }
                                }
                            }
                        }
                    }
                    //OppAnnualContractValueUtil.calculateAcvAmount(successOppInsertIdSet);
                } 
                if(String.isNotBlank(UnProcessedRecord)){
                    UnProcessedRecord= UnProcessedRecord.removeEnd(',');
                    ErrorMessage = ErrorMessage.removeEnd(',');
                    errLog.add(LogError.CreateDMLErrorLog(className,UnProcessedRecord,ErrorMessage,ERROR_FUNCTIONALITY));
                }  
                 
        }catch(Exception e) {
            errLog.add(LogError.CreateGenericErrorLog(className,e,ERROR_FUNCTIONALITY));
        }
        if(!errLog.isEmpty()){
            system.debug(logginglevel.DEBUG,errLog);
            insert errLog ;  
        }
    }
     
}