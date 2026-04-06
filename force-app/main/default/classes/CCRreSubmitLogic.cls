/*****************************************************************************************************
* @description : SAL-1770 Created Re-Submit Detail page button on CCR for failed Debooking Opportunity/Order
              If Debooking Opportunity created and Order Not created, then creates Order
              If both Debooking Opportunity and Order Not Created, then create both
              Logic runs for single CCR record on click on Re-submit button
              Author: Shrutika - SFDCSOX-618- resubmit detail page button on CCR for failed debook Opportunity/Order only order Lined Based
              If Debook Opportunity and Opportunity Products created then it will create only Order and OrderItems
* @author Aneeja
******************************************************************************************************/
public without sharing class CCRreSubmitLogic {
     
    List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
    final String className ='CCRreSubmitLogic';
    final String ERROR_FUNCTIONALITY = 'Bookings';
    final string RETURNREFUNDERROR1 ='Re-Submit is only for LineItem based debooking';
    final string RETURNREFUNDERROR2 ='CCR must be approved ';
    final string RETURNREFUNDERROR3 ='Debooking Opp and Order already created and Re-submit discarded';
    CCR__c ccrRecord=new CCR__c();
    List<Opportunity> debookingOpp = new List<Opportunity>(); //List Of one Debooking Order
    List<Order> DebookingOrder=new List<Order>(); //List Of one Debooking Order
    Map<Id,Opportunity> mapOfOppIdAndOpp;
    Id CCRId;
    ApexPages.StandardController stdController;
    /**
     * @description alertMessage
     */
    public String alertMessage {get;set;}
    PageReference tempPage;
  /**
  * @description CCRreSubmitLogic
  * @param stdController
  */
  public CCRreSubmitLogic(ApexPages.StandardController stdController){
      CCRId = stdController.getId();
      this.stdController = stdController;
  }
  /**
   * @description ReSubmitValidation
   */
  public  void ReSubmitValidation(){        
      
      Set<Id> oppIdSet = New Set<Id>(); 
      ccrRecord = [SELECT id,name,Booking__r.id,Booking__r.Order__r.id,Opportunity__r.id,Opportunity__r.Amount, Amount__c,CCR_Type__c,User__c,Re_submitted__c,Customer_Returns_Type__c,
                                   (SELECT OrderLineItemId__c,Quantity__c, Opportunity_Line_Item__c, Opportunity_Line_Item__r.Subsumed_Renewal_Amount__c, Opportunity_Line_Item__r.Subsumed_Renewal_TCV__c from Booking_AdjustmentItems__r),
                                   (SELECT Id,CCR__c,name,Territory2Id,closedate, Focused_Partner_Calc__c, National_Partner_Calc__c, Territory2Id__c,accountid,StageName,ForecastCategoryName,Initial_Contacts_Name__c,Business_Unit__c,ownerid,
                                          Deal_Registration_Type__c,SE_Forecast_Category__c,Pricebook2Id,Partner_Lookup__c,Distributor_Lookup__c,In_Forecast_CRO__c, //SAL24-534
                                          Future_State__c,Compelling_Bus_Driver__c,Current_State__c,Cloud_Environment__c,
                                          Negative_Consequences__c/*,Help_Needed_From__c*/,Rubrik_Sales_Engineer__c,Lost_To_Won_Against__c,Positive_Business_Outcomes__c,
                                          Rubrik_CDM_Release_on_source_cluster__c,Customer_AWS_Account_Number__c,Customer_AWS_Account_Region__c,Number_of_CluodON_Products__c,
                                          amount,Referral_Program__c,DB_Type__c,Number_of_TB__c,Cloud_Type__c,Holdover_Extension_End_Date__c,Holdover_Extension_Reason__c,
                                          Installation_Assigned_To__c,Lost_Reason__c,Lost_To__c,Primary_Competitor__c,POC_Stage__c,
                                          Polaris_Region__c,Technical_Validation_Next_Step__c ,Win_Loss_Comments__c,RenewalOwner__c,Alliance_HW_Partner__c,Alliance_Source_Type_SW__c, //SAL22-327
                                          ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c,CDM_Theatre__c,
                                          Alliance_Partner_Name__c,ISR_SDR_Oppty_Credit_Total__c,Account.R2K_All__c,SecondaryOwner__c,SE_Misaligned__c,Strategic_Account__c, Security_Alliance_Contribution__c, Direct_Marketplace__c  
                                          FROM Opportunities__r LIMIT 1) 
                                   FROM CCR__c where id = :ccrId LIMIT 1];// removing VM_Count__c from query SAL24-157
      if(ccrRecord.Opportunities__r.size() != 0){
           debookingOpp = ccrRecord.Opportunities__r;
           oppIdSet.add(debookingOpp[0].id);
       }
       if(ccrRecord.Opportunity__r.id != NULL){
          oppIdSet.add(ccrRecord.Opportunity__r.id);
       }
       
       if(!oppIdSet.isEmpty()){
           mapOfOppIdAndOpp = New Map<Id,Opportunity>([Select id,name,
                        (SELECT id,Order_Status__c,Opportunity.StageName, Opportunity.Partner_Level_Of_Involvement__c,Opportunity.VM_Count__c FROM Orders LIMIT 1),
                        (SELECT Id,OpportunityId FROM OpportunityLineItems) ,Champion__c,Forward_Pass_Contact_Mail__c,Forward_Pass_Contact__c,
                                          ccr__c,accountid,StageName,Economic_Buyer__c,CloseDate,ForecastCategoryName,Partner_Level_Of_Involvement__c,VM_Count__c,Initial_Contacts_Name__c,Business_Unit__c,ownerid,
                                          Deal_Registration_Type__c,SE_Forecast_Category__c,Polaris_Portal_Contact__c,Pricebook2Id,Partner_Lookup__c,Distributor_Lookup__c,
                                          Future_State__c,Compelling_Bus_Driver__c,Current_State__c,Cloud_Environment__c,Deal_Impact__c,Key_Feature_Needs__c,In_Forecast_CRO__c, //SAL24-534 
                                          Negative_Consequences__c,/*Help_Needed_From__c,*/Rubrik_Sales_Engineer__c,Lost_To_Won_Against__c,Positive_Business_Outcomes__c,
                                          Rubrik_CDM_Release_on_source_cluster__c,Customer_AWS_Account_Number__c,Customer_AWS_Account_Region__c,Number_of_CluodON_Products__c,
                                          amount,Referral_Program__c,DB_Type__c,Number_of_TB__c,Cloud_Type__c,Holdover_Extension_End_Date__c,Holdover_Extension_Reason__c,Holdover_Extension__c,
                                          Holdover_Requested__c,Installation_Assigned_To__c,Lost_Reason__c,Lost_To__c,Primary_Competitor__c,POC_Stage__c,
                                          Polaris_Region__c,Technical_Validation_Next_Step__c ,Win_Loss_Comments__c,SDR_Led__c,RenewalOwner__c,Alliance_HW_Partner__c,Alliance_Source_Type_SW__c, //SAL22-327 //SAL24-279 //SAL24-387
                                          ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,CDM_Area__c,CDM_Region__c,CDM_Territory__c,CDM_Theatre__c, //SAL24-279
                                            Alliance_Partner_Name__c,ISR_SDR_Oppty_Credit_Total__c,OriginalLeadOwner__c,Account.R2K_All__c,SecondaryOwner__c,SE_Misaligned__c,Strategic_Account__c,Core_PLS_Source__c,Opp_PLS_ETM_Theatre__c,Opp_PLS_ETM_Area__c,Opp_PLS_ETM_Region__c,Opp_PLS_ETM_Territory__c,Opp_PLS_NCD_ETM_Area__c, Opp_PLS_NCD_ETM_Region__c, Opp_PLS_NCD_ETM_Territory__c, Opp_PLS_NCD_ETM_Theatre__c, Opp_PLS_SaaS_ETM_Area__c, Opp_PLS_SaaS_ETM_Region__c, Opp_PLS_SaaS_ETM_Territory__c, Opp_PLS_SaaS_ETM_Theatre__c,Co_Owner__c,SaaS_Co_Owner__c,NCD_Co_Owner__c,Managed_Services_Deal_type__c,//PRDOPS26-325:added field Managed_Services_Deal_type__c        
                                            PLS_Gap_Deal__c,Rubrik_Co_Sales_Engineer__c, UCL_Scale_Percentage__c,PLS_SE_Update__c,UK_Govt_Security_Clearance_Required__c //SAL26-173 //SAL26-393 //SAL26-282 //SAL26-153
                       from Opportunity where Id IN :oppIdSet ]); // removing VM_Count__c from query SAL24-157
      }
      if(mapOfOppIdAndOpp != NULL){
          if( debookingOpp.size() >0){ 
              if(mapOfOppIdAndOpp.containsKey(debookingOpp[0].id) && mapOfOppIdAndOpp.get(debookingOpp[0].id) != NULL
                  && mapOfOppIdAndOpp.get(debookingOpp[0].id).Orders.size() != 0){
                DebookingOrder=mapOfOppIdAndOpp.get(debookingOpp[0].id).Orders;
               }
          }
      }
      if(!(
        Constants.CCR_TYPES.contains(ccrRecord.CCR_Type__c)
        && ccrRecord.Customer_Returns_Type__c =='LineItem Based')
        ){
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,RETURNREFUNDERROR1 +
             '<a href="/' + ccrId +'">Return to CCR</a>'));
      }
      else{
          if(ccrRecord.User__c != 'Approved'){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,RETURNREFUNDERROR2 +
                               '<a href="/' + ccrId +'">Return to CCR</a>'));                 
          }else if(DebookingOrder.size() != 0 && DebookingOrder[0].Order_Status__c == 'Order Accepted' && DebookingOrder[0].Opportunity.StageName == '7 Closed Won'){
                   ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,RETURNREFUNDERROR3 +
                                  '<a href="/' + ccrId +'">Return to CCR</a>'));
          }else {
                  CCRreSubmit(CCRId);
                  ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info,'Re-submit Process completed' +
                                 '<a href="/' + ccrId +'">Return to CCR</a>'));
         }
      }
          
  }
  /** 
  * @description CCRreSubmit
  * @param ccrId
  **/
  public void CCRreSubmit(Id ccrId)
  {
      
        ID OriginalOrderId;
        ID OriginalOppId;
        List<OpportunityLineItem> oppLines=new List<OpportunityLineItem>();
        Set<ID> orderItemIds=new Set<ID>();
        Map<ID,Decimal> orderItemIdsqnty=new Map<ID,Decimal>();
        Map<Id, Booking_AdjustmentItems__c> mapOrderLineIdBkgAdjItem = new Map<Id, Booking_AdjustmentItems__c>();
        Opportunity originalOpp = new Opportunity();
        Order originalOrder = new Order();
        List<OpportunityLineItem> OppLinesToDel=New List<OpportunityLineItem>();
        List<OrderItem> adjustedOrderItems = new List<OrderItem>();
        List<OrderItem> orderLinesList=new List<OrderItem>();
        Id successOppUpsertId;
        Id successOppUpdateId;
        Id successOppstageUpdateId;
        Set<Id> successOppLineDeleteIdSet = new Set<Id>();
        Id successOrderInsertId;
        Set<Id> successOrderLineInsertId = new Set<Id>();
        Id successOrderUpdateId;
        Set<Id> successOppLineInsertId = new Set<Id>();
        String unProcessedRecord ='';
        String errorMessage ='';
        Date currentDate = Date.Today();
        Map<String, BookingDebookingFields__c> oppFieldsMap= BookingDebookingFields__c.getAll();
        List<String> fieldsToIncludeList = new List<String>();
        Set<String> fieldsToInclude = new Set<String>();
          Map<Id, OpportunityLineItem> mapOrderItemIdToOppLineItem = new Map<Id, OpportunityLineItem>();
        try
        {           
           OpportunityObjectTriggerHandler.bypassClosedWonUpdateValidation = true;//SAL26-1054  
  BookingHelper.bypassBookingValidationRule = true;
           for(BookingDebookingFields__c fieldsSet : oppFieldsMap.Values()) 
           {   
               for(String fld : (fieldsSet.fields__c).split(','))
                 fieldsToInclude.add(fld);
           }
           
           if(ccrRecord != NULL)
           {               
               OriginalOrderId = ccrRecord.Booking__r.Order__r.id;
               OriginalOppId = ccrRecord.Opportunity__r.id;
               //collect orderItemIds
               for(Booking_AdjustmentItems__c bkgAdjItem : ccrRecord.Booking_AdjustmentItems__r)
               {
                      orderItemIdsqnty.put(bkgAdjItem.OrderLineItemId__c,bkgAdjItem.Quantity__c); 
                      mapOrderLineIdBkgAdjItem.put(bkgAdjItem.OrderLineItemId__c, bkgAdjItem);
                      orderItemIds.add(bkgAdjItem.OrderLineItemId__c);       
               }

              //Collect Original Opps from Opportunity Ids collected
              
              if(!mapOfOppIdAndOpp.isEmpty() && OriginalOppId != NULL && mapOfOppIdAndOpp.containsKey(OriginalOppId) && mapOfOppIdAndOpp.get(OriginalOppId) != NULL){
                  originalOpp = mapOfOppIdAndOpp.get(OriginalOppId);
              }
              
              //If Debooking Opp haven't created yet, create one
              if(originalOpp != NULL)
              {

                  if(  debookingOpp.size() == 0 ){
                       
                       Opportunity debookOpp=new Opportunity();
                       debookOpp = originalOpp.clone();
                       debookOpp.name=originalOpp.name+' - '+'Debooking'+' - '+ccrRecord.CCR_Type__c;
                       debookOpp.stageName='1 Discovery';
                       debookOpp.CloseDate=currentDate;
                       if(debookOpp.Polaris_Portal_Contact__c == NULL)
                          debookOpp.Has_Polaris_Product__c=False;
                       debookingOpp.add(debookOpp);
                  }
                  if(debookingOpp.size() != 0 && debookingOpp[0].Id == null)
                  {
                       Database.saveresult OppInsertSR = Database.insert(debookingOpp[0], false);
                       if(!OppInsertSR.isSuccess())
                       {
                           for(Database.Error err : OppInsertSR.getErrors()){
                                ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                            }
                            UnProcessedRecord+= 'Error with inserting Debooking Opportunity::'+debookingOpp[0].Name+',';
                        }else{
                             successOppUpsertId=OppInsertSR.getId();
                        }
                  }      
              } 
              if(successOppUpsertId != NULL){
              //Link CCR to debooking Opportunity
              if( successOppUpsertId == debookingOpp[0].Id && debookingOpp[0].CCR__c == NULL)
              {
                  debookingOpp[0].CCR__c = ccrId;
                 debookingOpp[0].Amount = ccrRecord.Amount__c ;
                  debookingOpp[0].Opportunity_Type__c='Debooking';
                  if(ccrRecord?.Opportunity__r?.Amount != null && ccrRecord?.Opportunity__r?.Amount == ccrRecord.Amount__c ){
                      debookingOpp[0].Opportunity_Sub_Type__c='Full';
                  }else{                         
                      debookingOpp[0].Opportunity_Sub_Type__c='Partial';
                  }
                  
                  
                  Database.saveResult OppUpdateUR = Database.update(debookingOpp[0], false);
                  if(!OppUpdateUR.isSuccess()){
                      for(Database.Error err : OppUpdateUR.getErrors()){
                                  ErrorMessage +=err.getFields()+'::'+ err.getMessage() +',';
                                                   

                       }
                       UnProcessedRecord+= 'Error with updating CCR on Opportunity::'+debookingOpp[0].Name+',';
                
                   }else{
                       SuccessOppUpdateId = OppUpdateUR.getId();
                   }
                  
              }
              
              if( debookingOpp.size() != 0 && debookingOpp[0].CCR__c != NULL)
              {
                  if(mapOfOppIdAndOpp != NULL && mapOfOppIdAndOpp.containsKey(debookingOpp[0].id) && mapOfOppIdAndOpp.get(debookingOpp[0].id) != NULL)
                  if(mapOfOppIdAndOpp.get(debookingOpp[0].id).OpportunityLineItems.size() > 0  ){
                      OppLinesToDel = mapOfOppIdAndOpp.get(debookingOpp[0].id).OpportunityLineItems;
                  }
                  if(!OppLinesToDel.isEmpty())
                  {
                       Database.deleteResult[] OppLineDeleteDR = Database.Delete(OppLinesToDel, false);
                       for(Integer i=0;i<OppLineDeleteDR.size();i++)
                       {
                              if(!OppLineDeleteDR[i].isSuccess())
                              {
                                  for(Database.Error err : OppLineDeleteDR[i].getErrors()){
                                      ErrorMessage +=err.getFields()+'::'+ err.getMessage() +',';
                                  }
                                  UnProcessedRecord+= 'Error with deleting Opp Line:: '+ OppLinesToDel[i].Id + ' Of Opportuntunity::'+OppLinesToDel[i].OpportunityId;
                              }else{
                                  SuccessOppLineDeleteIdSet.add(OppLineDeleteDR[i].getId());
                              }
                        } 
                      
                  }
                  
              }
              }
              //Insert Opp Lines

               if(!orderItemIds.isEmpty() && OriginalOppId != NULL)
               {
                   //Collect all Order and OrderItems form IDs collected           
                   Map<String,Schema.SObjectField> mapFields = Order.getSObjectType().getDescribe().fields.getMap(); 
                   List<String> fieldNames = new List<String>();
                      for( String fieldName : mapFields.keySet() ) {
                          fieldNames.add( fieldName );
                           // For relationship fields
                           if( Schema.DisplayType.Reference == mapFields.get(fieldName).getDescribe().getType() )
                               fieldNames.add( mapFields.get(fieldName).getDescribe().getRelationshipName() + '.id' ); 
                      } 
                      
                   Map<String,Schema.SObjectField> mapFields1 = OrderItem.getSObjectType().getDescribe().fields.getMap(); 
                   List<String> fieldNames1 = new List<String>();
                   for( String fieldName1 : mapFields1.keySet() ) {
                              fieldNames1.add( fieldName1 );
                              // For relationship fields
                              if( Schema.DisplayType.Reference == mapFields1.get(fieldName1).getDescribe().getType() )
                                  fieldNames1.add( mapFields1.get(fieldName1).getDescribe().getRelationshipName() + '.id' ); 
                   } 
                   String query = 'SELECT ' + String.escapeSingleQuotes(String.join(fieldNames, ',' )) + 
                      ' , Account.ShippingCountry,Account.ShippingCountryCode,Account.ShippingState,Account.ShippingStatecode,Account.ShippingPostalCode,Account.ShippingCity,Account.ShippingStreet, ' +
                          ' (SELECT ' + String.escapeSingleQuotes(String.join(fieldNames1, ',' )) + 
                             ' FROM OrderItems WHERE Id IN :orderItemIds) FROM Order WHERE Id = :OriginalOrderId LIMIT 1 ';
           
                  originalOrder = Database.query( query );
                         
                  if(originalOrder != NULL && originalOrder.OrderItems.size() != 0){
                      orderLinesList = originalOrder.OrderItems ;
                  }
                  for(OrderItem orderLine: orderLinesList)
                  {
                      if(orderItemIdsqnty.containsKey(orderLine.id))
                      {                 if( debookingOpp.size() > 0 && successOppUpsertId != NULL)
                                        {
                                          OpportunityLineItem oppLine = new OpportunityLineItem();
                                          //Create Opp Lines from Order Lines and attach under debooking Opportunity 
                                          oppLine.OpportunityId = debookingOpp[0].id;
                                          oppLine.PriceBookEntryId = orderLine.PriceBookEntryId;
                                          oppLine.UnitPrice = orderLine.UnitPrice * -1;
                                          oppLine.Description = orderLine.Description;
                                          oppLine.Quantity = orderItemIdsqnty.get(orderLine.id);
                                          if(orderLine.Opportunity_Product__c != null){
                                            oppLine.Original_OpplineitemId__c = Id.valueOf(orderLine.Opportunity_Product__c); //SAL25-145
                                          }
                                          if(mapOrderLineIdBkgAdjItem.containsKey(orderLine.id)){
                                              if(mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r?.Subsumed_Renewal_Amount__c != null){
                                                  Decimal renwalAmt = mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r?.Subsumed_Renewal_Amount__c * -1;
                                                  oppLine.Subsumed_Renewal_Amount__c = renwalAmt > 0 ? 0.00 : renwalAmt;
                                              }
                                              if(mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r?.Subsumed_Renewal_TCV__c != null){

                                                  Decimal renewalTCV= mapOrderLineIdBkgAdjItem.get(orderLine.id).Opportunity_Line_Item__r?.Subsumed_Renewal_TCV__c * -1;
                                                  oppLine.Subsumed_Renewal_TCV__c = renewalTCV > 0 ? 0.00 : renewalTCV;
                                              }
                                          }
                                          oppLine.Debooking_Subscription_Term__c = orderLine.SBQQ__SubscriptionTerm__c; //SAL24-164
                                            if(!mapOrderItemIdToOppLineItem.containsKey(orderLine.Id)){
                                                mapOrderItemIdToOppLineItem.put(orderLine.Id, oppLine);
                                            }
                                          oppLines.add(oppLine);     
                                         }
                       }
                   }
                                       //debookingOpp[0].pricebook2Id = originalOpp.pricebook2Id;
              }
              if(!oppLines.isEmpty())
               {
                   //insert oppLines;     
                   Database.saveResult[] OppLineInsertSR = Database.Insert(oppLines, true);
                   // Iterate through each returned result
                   for(Integer i=0;i<oppLines.size();i++)
                   {
                        if(OppLineInsertSR[i].isSuccess()){
                                SuccessOppLineInsertId.add(OppLineInsertSR[i].getId());
                         }
                    } 
              }      
              
              //insert new debooking order
              if(OriginalOrderId != NULL  && (DebookingOrder.size() == 0))
              //if(OriginalOrderId != NULL  && (DebookingOrder.size() == 0)  )
              {
                  
                      //Change some fields on cloned debooking Order
                          Order ordy = originalOrder.clone();
                          ordy.RecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByName().get('Booking Adjustment Order').getRecordTypeId();
                          ordy.Type='Booking Adjustment'; 
                          ordy.Sync_to_NetSuite__c = FALSE;                            
                          ordy.Order_Accepted_Timestamp__c = null;
                          ordy.BookingStatus__c= ' '; 
                          ordy.Auto_Manual_Split__c = null;
                          ordy.Reason_For_Split__c = null;
                          //ordy.Order_Status__c='Pending';  
                          ordy.Order_Status__c='Order Accepted';
                          ordy.status='Draft';  
                          ordy.SBQQ__Contracted__c = false;       
                          ordy.Quote=null;   
                          ordy.SBQQ__Quote__c =null;
                          ordy.ShippingCountry=ordy.Account.ShippingCountry;
                          ordy.ShippingCountryCode=ordy.Account.ShippingCountryCode;
                          ordy.ShippingState=ordy.Account.ShippingState;
                          ordy.ShippingStatecode=ordy.Account.ShippingStatecode;
                          ordy.ShippingPostalCode=ordy.Account.ShippingPostalCode;
                          ordy.ShippingCity=ordy.Account.ShippingCity;
                          ordy.ShippingStreet=ordy.Account.ShippingStreet;
                          if(debookingOpp[0].Id != null)
                          ordy.opportunityId=debookingOpp[0].Id;         
                          DebookingOrder.add(ordy);
                          if(  debookingOpp.size() != 0)
                          {
                               Database.saveResult ordInsertSR = Database.Insert(DebookingOrder[0], false);
                               if(!ordInsertSR.isSuccess())
                               {
                                   for(Database.Error err : ordInsertSR.getErrors()){
                                        ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                   }
                                   unProcessedRecord+= 'Error with inserting Debooking Order::'+DebookingOrder[0].OrderNumber+',';
                               }else{
                                   successOrderInsertId=ordInsertSR.getId();
                               }
                          } 
                      
                  }
                  
                  //Insert Order Lines
                  if(successOrderInsertId != NULL)
                  {
                      for(OrderItem orderLine: orderLinesList)
                      {
                             OrderItem oitem= orderLine.clone(false,true);
                             if(orderItemIdsqnty.containsKey(orderLine.id))
                             {
                                 //Change quantity on the cloned order Items and attach them under debooking Order created
                                 oitem.Quantity=orderItemIdsqnty.get(orderLine.id);
                                 oitem.Orderid=DebookingOrder[0].id ;
                                 oitem.UnitPrice=oitem.UnitPrice*-1;
                                 oitem.SBQQ__QuoteLine__c = null;
                                 oitem.SBQQ__Contracted__c= false; 
                                    if(mapOrderItemIdToOppLineItem.containsKey(orderLine.id)){
                                    oitem.Opportunity_Product__c = mapOrderItemIdToOppLineItem.get(orderLine.id).Id;
                                    }
                               }
                             adjustedOrderItems.add(oitem);           
                       }
                       if(!adjustedOrderItems.isEmpty())
                       {
                              //insert adjustedItems;
                              Database.SaveResult[] ordLineInsertSR = Database.insert(adjustedOrderItems, true);
                              // Iterate through each returned result
                              for(Integer i=0;i<ordLineInsertSR.size();i++){
                                  if(ordLineInsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                                      SuccessOrderLineInsertId.add(ordLineInsertSR[i].getId());
                                  }    
                              }  
                       }
                   }
                   //Update Order status to Accepted
                   if(!SuccessOrderLineInsertId.isEmpty())
                   {
                       //DebookingOrder[0].Order_Status__c='Order Accepted';  
                       DebookingOrder[0].opportunityId=debookingOpp[0].Id;
                       FlowControll.opportunityTriggerHandler = false;
                       Database.saveResult ordupdateSR = Database.update(DebookingOrder[0], false);
                       FlowControll.opportunityTriggerHandler = true;
                       if(!ordupdateSR.isSuccess())
                        {
                                   for(Database.Error err : ordupdateSR.getErrors()){
                                        ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                   }
                                   unProcessedRecord+= 'Error with updating status of Debooking Order ::'+DebookingOrder[0].OrderNumber+',';
                         }else{
                                   successOrderUpdateId=ordupdateSR.getId();
                         }
                   }
                   
                   //Update Debooking Opp stage to ClosedWon
                   if(successOrderUpdateId != NULL){
                          debookingOpp[0].StageName='7 Closed Won';
                       if(!debookingOpp.isEmpty())
                       {
                            Database.saveResult OppUpdateSR = Database.Update(debookingOpp[0], false);
                            if(!OppUpdateSR.isSuccess()){//only look at failures, or NOT Successes
                                for(Database.Error err : OppUpdateSR.getErrors()){
                                    ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                }
                                UnProcessedRecord+= 'Error with updating Opportunity to ClosedWon Stage for::'+debookingOpp[0].Name+',';
                             }else{
                                 successOppstageUpdateId=OppUpdateSR.getId();
                             }
                        }                           
                   }
                   //Update Re-Submitted? checkbox on CCR to TRUE
                   if(successOppstageUpdateId != NULL){
                       ccrRecord.Re_submitted__c=TRUE;
                          Database.saveResult ccrUpdateSR = Database.update(ccrRecord, false);
                          if(!ccrUpdateSR.isSuccess())
                          {
                                   for(Database.Error err : ccrUpdateSR.getErrors()){
                                        ErrorMessage += err.getFields()+'::'+err.getMessage() +',';
                                   }
                                   unProcessedRecord+= 'Error with updating CCR Record ::'+ccrRecord.Name+',';
                         }
                   }
                   

          }
              if(String.isNotBlank(UnProcessedRecord))
          {
              if(UnProcessedRecord.length()>255)
                  UnProcessedRecord = UnProcessedRecord.substring(0,255);
              if(ErrorMessage.length()>131072)
                  ErrorMessage = ErrorMessage.substring(0,131072);
              errLog.add(LogError.CreateDMLErrorLog(className,UnProcessedRecord,ErrorMessage,ERROR_FUNCTIONALITY));
          } 
       }catch(Exception e) {
          errLog.add(LogError.CreateGenericErrorLog(className,e,ERROR_FUNCTIONALITY));
      }
      if(!errLog.isEmpty())
      {
          insert errLog ;  
      }
      
  }

}